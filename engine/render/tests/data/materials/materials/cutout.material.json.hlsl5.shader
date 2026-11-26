{
  "format": "factoria.shader/1",
  "engine": "0.38.0",
  "template": "fb558641ba41b387123470d76b096bf8c235ebdf6b030355e6627097d00c66b9",
  "slang": "hlsl5",
  "params": [
    "alphaCutoff"
  ],
  "textures": [
    "mask"
  ],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _269 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _269;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _276 = _160.world_pos;\n    fa_world_pos = _276;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_276, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _4559[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _602_fa_camera_pos : packoffset(c0);\n    float4 _602_fa_ambient : packoffset(c1);\n    float4 _602_fa_base_color : packoffset(c2);\n    float4 _602_fa_emissive : packoffset(c3);\n    float4 _602_fa_model_emissive : packoffset(c4);\n    float4 _602_fa_pbr : packoffset(c5);\n    float4 _602_fa_maps : packoffset(c6);\n    float4 _602_fa_fog : packoffset(c7);\n    float4 _602_fa_fog_b : packoffset(c8);\n    float4 _602_fa_fog_c : packoffset(c9);\n    float4 _602_fa_counts : packoffset(c10);\n    float4 _602_fa_env_sky : packoffset(c11);\n    float4 _602_fa_env_horizon : packoffset(c12);\n    float4 _602_fa_time : packoffset(c13);\n    float4 _602_fa_cl_vpx : packoffset(c14);\n    float4 _602_fa_cl_vpy : packoffset(c15);\n    float4 _602_fa_cl_vpw : packoffset(c16);\n    float4 _602_fa_cl_fwd : packoffset(c17);\n    float4 _602_fa_cl_grid : packoffset(c18);\n    float4 _602_fa_cl_info : packoffset(c19);\n    float4 _602_fa_layers_a : packoffset(c20);\n    float4 _602_fa_layers_b : packoffset(c21);\n    float4 _602_fa_layers_c : packoffset(c22);\n    float4 _602_fa_layers_d : packoffset(c23);\n    float4 _602_fa_ct_a : packoffset(c24);\n    float4 _602_fa_ct_b : packoffset(c25);\n    float4 _602_fa_ct_vpx : packoffset(c26);\n    float4 _602_fa_ct_vpy : packoffset(c27);\n    float4 _602_fa_ct_vpw : packoffset(c28);\n    float4 _602_fa_ct_fwd : packoffset(c29);\n    float4 _602_fa_tr_a : packoffset(c30);\n    float4 _602_fa_tr_b : packoffset(c31);\n    float4 _602_fa_probe_sh[9] : packoffset(c32);\n    float4 _602_fa_atlas : packoffset(c41);\n    float4 _602_fa_rpa_tile : packoffset(c42);\n    float4 _602_fa_rpa_pos : packoffset(c43);\n    float4 _602_fa_rpa_bx : packoffset(c44);\n    float4 _602_fa_rpa_by : packoffset(c45);\n    float4 _602_fa_rpa_bz : packoffset(c46);\n    float4 _602_fa_rpb_tile : packoffset(c47);\n    float4 _602_fa_rpb_pos : packoffset(c48);\n    float4 _602_fa_rpb_bx : packoffset(c49);\n    float4 _602_fa_rpb_by : packoffset(c50);\n    float4 _602_fa_rpb_bz : packoffset(c51);\n    float4 _602_fa_gi : packoffset(c52);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2346_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2346_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2346_fa_shadow_info[4] : packoffset(c20);\n    float4 _2346_fa_shadow_split : packoffset(c24);\n    float4 _2346_fa_shadow_cfg : packoffset(c25);\n    float4 _2346_fa_shadow_bias : packoffset(c26);\n    float4 _2346_fa_shadow_eye : packoffset(c27);\n    float4 _2346_fa_shadow_fwd : packoffset(c28);\n    float4 _2346_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _8421_alphaCutoff : packoffset(c0);\n    float _8421_fa_pad0 : packoffset(c0.y);\n    float _8421_fa_pad1 : packoffset(c0.z);\n    float _8421_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t11);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_screen_tex : register(t12);\nTexture2D<float4> fa_probe_atlas : register(t7);\nTexture2D<float4> mask : register(t6);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t10);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1628 = _602_fa_cl_info.x < 0.0f;\n    bool _1635;\n    if (!_1628)\n    {\n        _1635 = _602_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1635 = _1628;\n    }\n    bool _1643;\n    if (!_1635)\n    {\n        _1643 = _602_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1643 = _1635;\n    }\n    bool _1650;\n    if (!_1643)\n    {\n        _1650 = _602_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1650 = _1643;\n    }\n    bool _1657;\n    if (!_1650)\n    {\n        _1657 = _602_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1657 = _1650;\n    }\n    if (_1657)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1667 = float4(world_pos, 1.0f);\n    float _1673 = dot(_602_fa_cl_vpw, _1667);\n    if (!(_1673 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1695 = float2(dot(_602_fa_cl_vpx, _1667), dot(_602_fa_cl_vpy, _1667)) / _1673.xx;\n    int _1699 = int(_602_fa_cl_grid.x);\n    int _1703 = int(_602_fa_cl_grid.y);\n    int param = (int(_602_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_602_fa_cl_fwd.xyz, world_pos) + _602_fa_cl_fwd.w, _602_fa_cl_grid.w) / _602_fa_cl_grid.w) * _602_fa_cl_grid.z)), 0, int(_602_fa_cl_info.y) - 1) * _1703) + clamp(int(floor(((_1695.y * 0.5f) + 0.5f) * _602_fa_cl_grid.y)), 0, _1703 - 1)) * _1699)) + clamp(int(floor(((_1695.x * 0.5f) + 0.5f) * _602_fa_cl_grid.x)), 0, _1699 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1779 = fa_cluster_texel(param);\n    return int2(int(_1779.x), int(_1779.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_602_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _6193 = fa_cluster_lookup(param);\n    fa_cl_slot = _6193.x;\n    fa_cl_local = _6193.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _7363 = fa_linear_to_srgb(param);\n        c = _7363;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _7371 = fa_srgb_to_linear(param_1);\n            c = _7371;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _534;\n    if (i.front_facing)\n    {\n        _534 = i.world_normal;\n    }\n    else\n    {\n        _534 = -i.world_normal;\n    }\n    float3 _558 = normalize(i.world_tangent.xyz - (_534 * dot(_534, i.world_tangent.xyz)));\n    float3 _585 = normalize(((_558 * m.x) + ((cross(_534, _558) * i.world_tangent.w) * m.y)) + (_534 * m.z));\n    float3 _588;\n    if (i.front_facing)\n    {\n        _588 = _585;\n    }\n    else\n    {\n        _588 = -_585;\n    }\n    return _588;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _602_fa_env_horizon.w);\n    float param = _602_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _7403 = fa_tex_fix(param_2, param_3);\n    float4 _9700 = base_t;\n    _9700.x = _7403.x;\n    _9700.y = _7403.y;\n    _9700.z = _7403.z;\n    base_t = _9700;\n    float4 _7417 = (_9700 * _602_fa_base_color) * i.vertex_color;\n    float3 _9460 = i.world_normal;\n    if (_602_fa_maps.z > 0.5f)\n    {\n        float param_4 = _602_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _602_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _7451 = fa_tex_fix(param_6, param_7);\n        float3 _7454 = (_7451 * 2.0f) - 1.0f.xxx;\n        float2 _7459 = _7454.xy * _602_fa_maps.x;\n        float3 _9708 = _7454;\n        _9708.x = _7459.x;\n        _9708.y = _7459.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _9708;\n        _9460 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _602_fa_env_horizon.w);\n    float param_10 = _602_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _7489 = fa_tex_fix(param_12, param_13);\n    float4 _9711 = mrt;\n    _9711.x = _7489.x;\n    _9711.y = _7489.y;\n    _9711.z = _7489.z;\n    mrt = _9711;\n    float4 _7519 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _602_fa_env_horizon.w);\n    float param_14 = _602_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _7519.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _7530 = fa_tex_fix(param_16, param_17);\n    float param_18 = _602_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _602_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _7562 = fa_tex_fix(param_20, param_21);\n    float _9465 = _602_fa_layers_a.x;\n    float _9466 = _602_fa_layers_a.y;\n    float _9469 = _602_fa_layers_a.z;\n    float _9468 = _602_fa_layers_b.w;\n    float _9471 = _602_fa_layers_c.x;\n    if (_602_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_602_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _9465 *= _7530.y;\n            _9466 *= _7530.z;\n            _9468 *= _7519.w;\n        }\n        if (_602_fa_layers_c.z > 1.5f)\n        {\n            _9469 *= mrt.x;\n            _9471 *= mrt.w;\n        }\n    }\n    Surface _9498 = { _7417.xyz, _7417.w, _9460, clamp(_602_fa_pbr.x * _7489.z, 0.0f, 1.0f), clamp(_602_fa_pbr.y * _7489.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_602_fa_maps.y * (_7530.x - 1.0f)), _602_fa_emissive.xyz + (_602_fa_model_emissive.xyz * _7562), _9465, _9466, _602_fa_layers_b.xyz, _9468, _9469, _602_fa_layers_a.w, _9471, _602_fa_layers_c.y, _602_fa_layers_d.xyz, _602_fa_tr_a.x, _602_fa_tr_a.y, _602_fa_tr_b.xyz, _602_fa_tr_a.z };\n    return _9498;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1859 = rect.zw - rect.xy;\n    float2 _1863 = _1859 * atlas;\n    float2 _1867 = ddx * _1863;\n    float2 _1871 = ddy * _1863;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1859), clamp(0.5f * log2(max(max(dot(_1867, _1867), dot(_1871, _1871)), 9.9999999392252902907785028219223e-09f)), 0.0f, 3.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1904 = _602_fa_counts.y < 0.5f;\n    bool _1911;\n    if (!_1904)\n    {\n        _1911 = _602_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1911 = _1904;\n    }\n    if (_1911)\n    {\n        return;\n    }\n    float3 _1917 = ddx(world_pos);\n    float3 _1920 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1924 = fa_cluster_texel(param);\n    int _1928 = int(_1924.w);\n    if (_1928 < 1)\n    {\n        return;\n    }\n    int _1938 = int(_602_fa_counts.y + 0.5f);\n    int param_1 = _1938;\n    float4 _1942 = fa_light_texel(param_1);\n    float2 _1945 = _1942.yz;\n    int _1949 = int(_1942.w);\n    int param_2 = _1938 + 1;\n    float4 _1954 = fa_light_texel(param_2);\n    float _1955 = _1954.x;\n    int _1961 = int(_602_fa_counts.w + 0.5f) - 1;\n    int _1965 = int(_1924.z);\n    float3 _2230;\n    for (int k = 0; k < _1928; k++)\n    {\n        int _1978 = _1965 + k;\n        int param_3 = _1949 + (_1978 >> 2);\n        int _1995 = (_1938 + 2) + (int(fa_light_texel(param_3)[_1978 & 3]) * 7);\n        int param_4 = _1995 + 6;\n        float4 _2000 = fa_light_texel(param_4);\n        if (((int(_2000.w + 0.5f) >> _1961) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1995;\n        float4 _2015 = fa_light_texel(param_5);\n        int param_6 = _1995 + 1;\n        float4 _2020 = fa_light_texel(param_6);\n        int param_7 = _1995 + 2;\n        float4 _2025 = fa_light_texel(param_7);\n        float3 _2028 = _2015.xyz;\n        float _2033 = dot(_2028, world_pos) + _2015.w;\n        float3 _2035 = _2020.xyz;\n        float _2040 = dot(_2035, world_pos) + _2020.w;\n        float3 _2042 = _2025.xyz;\n        float _2047 = dot(_2042, world_pos) + _2025.w;\n        bool _2052 = abs(_2033) > 0.5f;\n        bool _2060;\n        if (!_2052)\n        {\n            _2060 = abs(_2040) > 0.5f;\n        }\n        else\n        {\n            _2060 = _2052;\n        }\n        bool _2068;\n        if (!_2060)\n        {\n            _2068 = abs(_2047) > 0.5f;\n        }\n        else\n        {\n            _2068 = _2060;\n        }\n        if (_2068)\n        {\n            continue;\n        }\n        float _2083 = clamp(dot(geo_normal, normalize(_2042)) * _2000.z, 0.0f, 1.0f);\n        if (_2083 <= 0.0f)\n        {\n            continue;\n        }\n        float _2103 = (clamp((0.5f - abs(_2047)) * 10.0f, 0.0f, 1.0f) * _2083) * _2000.x;\n        float2 _2111 = float2(_2033 + 0.5f, 0.5f - _2040);\n        float2 _2121 = float2(dot(_2028, _1917), dot(_2035, _1917));\n        float2 _2131 = float2(dot(_2028, _1920), dot(_2035, _1920));\n        int param_8 = _1995 + 5;\n        float4 _2136 = fa_light_texel(param_8);\n        int param_9 = _1995 + 3;\n        float4 _2141 = fa_light_texel(param_9);\n        int param_10 = _1995 + 4;\n        float4 _2146 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _2136.xyz;\n        bool _2156 = _2141.z > _2141.x;\n        if (_2156)\n        {\n            float4 param_11 = _2141;\n            float2 param_12 = _2111;\n            float2 param_13 = _1945;\n            float2 param_14 = _2121;\n            float2 param_15 = _2131;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1955 > 0.5f) && (_1955 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _2182 = fa_dc_to_linear(param_16);\n                float4 _9548 = tx;\n                _9548.x = _2182.x;\n                _9548.y = _2182.y;\n                _9548.z = _2182.z;\n                tx = _9548;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_2103 * tex_a) * _2136.w, 0.0f, 1.0f).xxx);\n        if (_2146.z > _2146.x)\n        {\n            float4 param_17 = _2146;\n            float2 param_18 = _2111;\n            float2 param_19 = _1945;\n            float2 param_20 = _2121;\n            float2 param_21 = _2131;\n            float4 _2226 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1955 > 1.5f)\n            {\n                float3 param_22 = _2226.xyz;\n                float3 _2236 = fa_dc_to_srgb(param_22);\n                _2230 = _2236;\n            }\n            else\n            {\n                _2230 = _2226.xyz;\n            }\n            float3 _2245 = (_2230 * 2.0f) - 1.0f.xxx;\n            float2 _2250 = _2245.xy * _2000.y;\n            float3 _2272 = (normalize(_2028) * _2250.x) + (normalize(_2035) * _2250.y);\n            float3 _2275 = normalize(normal);\n            normal = normalize(lerp(_2275, normalize((_2275 * max(_2245.z, 0.0500000007450580596923828125f)) + (_2272 - (_2275 * dot(_2275, _2272)))), clamp(_2103 * (_2156 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nvoid fa_lod_dither()\n{\n    if (_602_fa_gi.w != 0.0f)\n    {\n        float _624 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n        bool _627;\n        if (_602_fa_gi.w > 0.0f)\n        {\n            _627 = _624 >= _602_fa_gi.w;\n        }\n        else\n        {\n            _627 = _624 < (-_602_fa_gi.w);\n        }\n        if (_627)\n        {\n            discard;\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4484 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _4492 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _4495 = int(_4484);\n    int _4498 = int(_4492);\n    float _4508 = _4492 - float(_4498);\n    int _4563 = (_4495 * 9) + _4498;\n    int _4583 = ((_4495 + 1) * 9) + _4498;\n    return lerp(lerp(_4559[_4563], _4559[_4563 + 1], _4508), lerp(_4559[_4583], _4559[_4583 + 1], _4508), _4484 - float(_4495));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _9383 = false;\n    float _9384 = 1.0f;\n    float _9385 = 1.0f;\n    float _9386 = 1.0f;\n    float _9387 = 0.0f;\n    float _9388 = 0.0f;\n    float _9389 = 0.0f;\n    float _9390 = 0.0f;\n    float _9392 = 1.0f;\n    bool _9393 = false;\n    float3 _9394 = 0.0f.xxx;\n    float _9395 = 1.0f;\n    float _9396 = 1.0f;\n    float _9397 = 1.0f;\n    float _9398 = 0.0f;\n    float _9399 = 0.0f;\n    float3 _9400 = float3(1.0f, 0.0f, 0.0f);\n    float3 _9401 = float3(0.0f, 0.0f, 1.0f);\n    float _9402 = 1.0f;\n    float _9403 = 1.0f;\n    float _4634 = clamp(s.specular, 0.0f, 1.0f);\n    float _4638 = clamp(s.ior, 1.0f, 3.0f);\n    bool _4643 = (_4634 != 1.0f) || (_4638 != 1.5f);\n    bool _4652;\n    if (!_4643)\n    {\n        _4652 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _4652 = _4643;\n    }\n    if (_4652)\n    {\n        float _4660 = (_4638 - 1.0f) / (_4638 + 1.0f);\n        f0 = lerp(min((_4660 * _4660).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _4634, s.albedo, metallic.xxx);\n        _9384 = lerp(_4634, 1.0f, metallic);\n        _9383 = true;\n    }\n    float _4687 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_4687 > 0.0f)\n    {\n        float _4695 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _9387 = _4687;\n        _9388 = _4695;\n        float _4702 = _4695 * _4695;\n        _9389 = _4702;\n        _9390 = _4702 * _4702;\n        float _4714 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _9392 = _4714;\n        _9385 = 1.0f - (_4687 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _4714, 0.0f, 1.0f), 5.0f))));\n        _9383 = true;\n    }\n    float3 _4733 = max(s.sheen_color, 0.0f.xxx);\n    float _4742 = max(_4733.x, max(_4733.y, _4733.z));\n    if (_4742 > 0.0f)\n    {\n        float _4750 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _9393 = true;\n        _9394 = _4733;\n        _9395 = _4750;\n        _9396 = _4750 * _4750;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _4750;\n        float _4767 = fa_sheen_albedo(param, param_1);\n        _9398 = _4767;\n        _9397 = 1.0f - min(_4742 * _4767, 1.0f);\n        _9383 = true;\n    }\n    _9386 = _9385 * _9397;\n    float _4786 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_4786 != 0.0f)\n    {\n        float3 _4801 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _4801;\n        if (dot(_4801, _4801) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _4813 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_4813.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _4813.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _4813.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _4817 = t;\n        float3 _4818 = normalize(_4817);\n        t = _4818;\n        float3 _4843 = normalize((_4818 * cos(s.anisotropy_rotation)) + ((cross(n, _4818) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _9400 = _4843;\n        _9401 = cross(n, _4843);\n        float _4853 = roughness * roughness;\n        float _4859 = lerp(_4853, 1.0f, _4786 * _4786);\n        bool _4861 = _4786 > 0.0f;\n        _9402 = _4861 ? _4859 : _4853;\n        _9403 = _4861 ? _4853 : _4859;\n        _9399 = _4786;\n        _9383 = true;\n    }\n    FaLayers _9425 = { _9383, _9384, _9385, _9386, _9387, _9388, _9389, _9390, i.world_normal, _9392, _9393, _9394, _9395, _9396, _9397, _9398, _9399, _9400, _9401, _9402, _9403 };\n    return _9425;\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3712_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3712_dummy_parameter)));\n}\n\nfloat3 fa_probe_sh_coef(float2 origin, float res, int k)\n{\n    float3 v = fa_probe_atlas.SampleLevel(fa_env_smp, (origin + float2(float(k) + 0.5f, res + 2.5f)) / fa_atlas_size(), 0.0f).xyz;\n    if (_602_fa_atlas.y > 0.5f)\n    {\n        v = ((v * 255.0f) - 128.0f.xxx) * 0.03149606287479400634765625f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3653 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3653;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    float _4265 = (1.0f - _602_fa_rpa_tile.w) - _602_fa_rpb_tile.w;\n    float3 amb = 0.0f.xxx;\n    bool _4270 = _602_fa_env_sky.w > 0.5f;\n    float3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = 0.0f.xxx;\n    }\n    if (_4265 > 0.0005000000237487256526947021484375f)\n    {\n        if (_4270)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _602_fa_atlas.zw;\n                float param_1 = 128.0f;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4265;\n            }\n        }\n        else\n        {\n            amb = _602_fa_ambient.xyz * _4265;\n        }\n    }\n    bool _4321 = _602_fa_rpa_tile.w > 0.0f;\n    if (_4321)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _602_fa_rpa_tile.xy;\n            float param_4 = _602_fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * _602_fa_rpa_tile.w);\n        }\n    }\n    bool _4352 = _602_fa_rpb_tile.w > 0.0f;\n    if (_4352)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _602_fa_rpb_tile.xy;\n            float param_7 = _602_fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * _602_fa_rpb_tile.w);\n        }\n    }\n    if ((_4270 || _4321) || _4352)\n    {\n        float3 param_9[9] = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nfloat4 fa_gi_fetch(float2 texel)\n{\n    return fa_probe_atlas.SampleLevel(fa_env_smp, texel / fa_atlas_size(), 0.0f);\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3673 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3676 = _3673.x;\n    float _3678 = _3673.z;\n    float2 e = float2(_3676, _3678);\n    if (_3673.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3678)) * ((_3676 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3676)) * ((_3678 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat3 fa_gi_grid(int rec, float3 n, float3 v, out float cover)\n{\n    cover = 0.0f;\n    int param = rec;\n    float4 _7672 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    float4 _7677 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    float4 _7682 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    float4 _7687 = fa_light_texel(param_3);\n    bool _7690 = _7687.z < 0.5f;\n    bool _7698;\n    if (!_7690)\n    {\n        _7698 = fa_atlas_size().y < 1155.0f;\n    }\n    else\n    {\n        _7698 = _7690;\n    }\n    if (_7698)\n    {\n        return 0.0f.xxx;\n    }\n    float _7705 = max(_7672.w, 9.9999997473787516355514526367188e-05f);\n    float3 _7708 = _7677.xyz;\n    float3 _7712 = _7672.xyz;\n    float3 _7716 = (fa_world_pos - _7712) / _7705.xxx;\n    float3 _7725 = min(_7716 + 0.5f.xxx, (_7708 - 0.5f.xxx) - _7716);\n    float _7734 = min(_7725.x, min(_7725.y, _7725.z));\n    if (!(_7734 > 0.0f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _7749 = _7708 - 1.0f.xxx;\n    float3 _7750 = clamp(_7716, 0.0f.xxx, _7749);\n    float3 _7758 = min(floor(_7750), max(_7708 - 2.0f.xxx, 0.0f.xxx));\n    float3 _7762 = _7750 - _7758;\n    float3 _7773 = fa_world_pos + (((n * 0.800000011920928955078125f) + (v * 0.20000000298023223876953125f)) * (0.20000000298023223876953125f * _7705));\n    int _7778 = int(_7682.y + 0.5f);\n    float _7783 = 0.3257350027561187744140625f * n.y;\n    float _7787 = 0.3257350027561187744140625f * n.z;\n    float _7791 = 0.3257350027561187744140625f * n.x;\n    float _7798 = (0.2731371223926544189453125f * n.x) * n.y;\n    float _7805 = (0.2731371223926544189453125f * n.y) * n.z;\n    float _7814 = 0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f);\n    float _7821 = (0.2731371223926544189453125f * n.x) * n.z;\n    float _7834 = 0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y));\n    float3 acc = 0.0f.xxx;\n    float wsum = 0.0f;\n    int _7841 = 8 + int(_7687.w);\n    float _7868;\n    float _7881;\n    float _7895;\n    for (int k = 0; k < _7841; k++)\n    {\n        float _7854 = float(k & 1);\n        float _7858 = float((k >> 1) & 1);\n        float _7862 = float((k >> 2) & 1);\n        if (_7854 > 0.5f)\n        {\n            _7868 = _7762.x;\n        }\n        else\n        {\n            _7868 = 1.0f - _7762.x;\n        }\n        if (_7858 > 0.5f)\n        {\n            _7881 = _7762.y;\n        }\n        else\n        {\n            _7881 = 1.0f - _7762.y;\n        }\n        if (_7862 > 0.5f)\n        {\n            _7895 = _7762.z;\n        }\n        else\n        {\n            _7895 = 1.0f - _7762.z;\n        }\n        float _7905 = (_7868 * _7881) * _7895;\n        if (!(_7905 > 0.0f))\n        {\n            continue;\n        }\n        float3 _7918 = min(_7758 + float3(_7854, _7858, _7862), _7749);\n        int _7938 = int(((_7682.x + _7918.x) + (_7677.x * (_7918.y + (_7677.y * _7918.z)))) + 0.5f);\n        float2 _7953 = float2(float(_7938 % _7778) * 10.0f, 1024.0f + (float(_7938 / _7778) * 11.0f));\n        float2 param_4 = _7953 + float2(9.5f, 10.5f);\n        float4 _7961 = fa_gi_fetch(param_4);\n        bool _7964 = _7961.y < 0.5f;\n        bool _7973;\n        if (!_7964)\n        {\n            _7973 = _7961.x > _7687.y;\n        }\n        else\n        {\n            _7973 = _7964;\n        }\n        if (_7973)\n        {\n            continue;\n        }\n        float3 _7985 = _7773 - (_7712 + (_7918 * _7705));\n        float _7988 = length(_7985);\n        float3 _7994 = _7985 / max(_7988, 9.9999997473787516355514526367188e-05f).xxx;\n        float _8004 = max(9.9999997473787516355514526367188e-05f, (dot(-_7994, n) + 1.0f) * 0.5f);\n        float w = _7905 * (_8004 * _8004);\n        float3 param_5 = _7994;\n        float2 param_6 = (_7953 + 1.0f.xx) + (((fa_oct_encode(param_5) * 0.5f) + 0.5f.xx) * 8.0f);\n        float4 _8023 = fa_gi_fetch(param_6);\n        float _8030 = _7988 / max(_7682.z, 9.9999997473787516355514526367188e-05f);\n        float _8033 = _8023.x;\n        if (_8030 > _8033)\n        {\n            float _8046 = max(_8023.y - (_8033 * _8033), 0.0f);\n            float _8051 = _8030 - _8033;\n            float _8060 = _8046 / max(_8046 + (_8051 * _8051), 9.9999999600419720025001879548654e-13f);\n            w *= ((_8060 * _8060) * _8060);\n        }\n        if (!(w > 0.0f))\n        {\n            continue;\n        }\n        float2 param_7 = _7953 + float2(0.5f, 10.5f);\n        float2 param_8 = _7953 + float2(1.5f, 10.5f);\n        float2 param_9 = _7953 + float2(2.5f, 10.5f);\n        float2 param_10 = _7953 + float2(3.5f, 10.5f);\n        float2 param_11 = _7953 + float2(4.5f, 10.5f);\n        float2 param_12 = _7953 + float2(5.5f, 10.5f);\n        float2 param_13 = _7953 + float2(6.5f, 10.5f);\n        float2 param_14 = _7953 + float2(7.5f, 10.5f);\n        float2 param_15 = _7953 + float2(8.5f, 10.5f);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375f) + (fa_gi_fetch(param_8).xyz * _7783)) + (fa_gi_fetch(param_9).xyz * _7787)) + (fa_gi_fetch(param_10).xyz * _7791)) + (fa_gi_fetch(param_11).xyz * _7798)) + (fa_gi_fetch(param_12).xyz * _7805)) + (fa_gi_fetch(param_13).xyz * _7814)) + (fa_gi_fetch(param_14).xyz * _7821)) + (fa_gi_fetch(param_15).xyz * _7834)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06f))\n    {\n        return 0.0f.xxx;\n    }\n    cover = smoothstep(0.0f, 1.0f, clamp(_7734 * 2.0f, 0.0f, 1.0f)) * smoothstep(0.0f, 0.0199999995529651641845703125f, wsum);\n    float _8184;\n    if (_602_fa_gi.z > 0.5f)\n    {\n        _8184 = _7687.x;\n    }\n    else\n    {\n        _8184 = 1.0f;\n    }\n    return max(acc / wsum.xxx, 0.0f.xxx) * (_7682.w * _8184);\n}\n\nfloat3 fa_gi_light(float3 n, inout float left)\n{\n    left = 1.0f;\n    float3 acc = 0.0f.xxx;\n    float3 _8208 = normalize(_602_fa_camera_pos.xyz - fa_world_pos);\n    int _8213 = int(_602_fa_gi.x + 0.5f);\n    int _8218 = int(_602_fa_gi.y + 0.5f);\n    float param_3;\n    for (int k = 0; (k < _8218) && (k < 8); k++)\n    {\n        int param = _8213 + (4 * k);\n        float3 param_1 = n;\n        float3 param_2 = _8208;\n        float3 _8243 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _8248 = param_3 * left;\n        acc += (_8243 * _8248);\n        left -= _8248;\n        if (left < 0.001000000047497451305389404296875f)\n        {\n            left = 0.0f;\n            break;\n        }\n    }\n    return acc;\n}\n\nfloat3 fa_realtime_or_ambient(float3 n)\n{\n    float3 gi = 0.0f.xxx;\n    float left = 1.0f;\n    if (_602_fa_gi.y > 0.5f)\n    {\n        float3 param = n;\n        float param_1;\n        float3 _8277 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _8277;\n    }\n    if (left <= 0.0f)\n    {\n        return gi;\n    }\n    float3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_602_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _602_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_602_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_602_fa_cl_info.x) + int(_602_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_602_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _6163;\n    if (fa_lm.z > 0.5f)\n    {\n        _6163 = 0.0f;\n    }\n    else\n    {\n        _6163 = 1.0f - clamp(_602_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _6174 = _6163 < 1.0f;\n    bool _6180;\n    if (_6174)\n    {\n        int param = li;\n        _6180 = fa_light_baked(param);\n    }\n    else\n    {\n        _6180 = _6174;\n    }\n    return _6180 ? _6163 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _758_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _758_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _877 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _890 = (c - (ru * hx)) - p;\n        float3 _896 = ru * (2.0f * hx);\n        float _902 = max(dot(_896, _896), 9.9999999392252902907785028219223e-09f);\n        float _906 = dot(_890, _896);\n        float t = clamp((-_906) / _902, 0.0f, 1.0f);\n        if (_877)\n        {\n            float _921 = dot(r, _896);\n            float _927 = _902 - (_921 * _921);\n            if (abs(_927) > (9.9999997473787516355514526367188e-06f * _902))\n            {\n                t = clamp(((dot(r, _890) * _921) - _906) / _927, 0.0f, 1.0f);\n            }\n        }\n        return (p + _890) + (_896 * t);\n    }\n    float3 q = p;\n    float _959 = dot(r, axis);\n    bool _967;\n    if (_877)\n    {\n        _967 = abs(_959) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _967 = _877;\n    }\n    if (_967)\n    {\n        float _977 = dot(c - p, axis) / _959;\n        if (_977 > 0.0f)\n        {\n            q = p + (r * _977);\n        }\n    }\n    float3 _990 = q - c;\n    float2 xy = float2(dot(_990, ru), dot(_990, uu));\n    if (shape > 0.5f)\n    {\n        float _1005 = length(xy);\n        if (_1005 > hx)\n        {\n            xy *= (hx / _1005);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _644 = abs(d);\n    float _646 = _644.x;\n    float _648 = _644.y;\n    bool _649 = _646 >= _648;\n    bool _657;\n    if (_649)\n    {\n        _657 = _646 >= _644.z;\n    }\n    else\n    {\n        _657 = _649;\n    }\n    int _658;\n    if (_657)\n    {\n        _658 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _672;\n        if (_648 >= _644.z)\n        {\n            _672 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _672 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _658 = _672;\n    }\n    return _658;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _797 = dot(d, right);\n    float _801 = dot(d, up);\n    float _812;\n    if (((_797 * _797) + (_801 * _801)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _812 = atan2(_801, _797) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _812 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_812 - floor(_812)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _1043 = fa_light_base(param);\n    bool _1047 = _602_fa_ambient.w > 4.5f;\n    int param_1 = _1043;\n    float4 _1051 = fa_light_texel(param_1);\n    int param_2 = _1043 + 1;\n    float4 _1056 = fa_light_texel(param_2);\n    float _1059 = _1056.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _1071 = _1047 && (_1059 > 2.5f);\n    fa_light_is_area = _1071;\n    bool _1073 = _1059 < 0.5f;\n    float3 l;\n    if (_1073)\n    {\n        l = normalize(_1051.xyz);\n        if (_1047)\n        {\n            int param_3 = _1043 + 6;\n            float4 _1087 = fa_light_texel(param_3);\n            if (_1087.z > 0.5f)\n            {\n                int param_4 = _1043 + 4;\n                float4 _1097 = fa_light_texel(param_4);\n                int param_5 = _1043 + 5;\n                float4 _1102 = fa_light_texel(param_5);\n                float2 param_6 = _1087.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _1097.xyz) * _1097.w, (-dot(world_pos, _1102.xyz)) * _1102.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _1132 = _1051.xyz;\n        float3 _1134 = _1132 - world_pos;\n        float3 to_light = _1134;\n        float _1137 = length(_1134);\n        float reach = _1137;\n        bool front = true;\n        if (_1071)\n        {\n            int param_8 = _1043 + 7;\n            reach = max(_1137 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _1043 + 4;\n            float4 _1161 = fa_light_texel(param_9);\n            int param_10 = _1043 + 5;\n            float4 _1166 = fa_light_texel(param_10);\n            int param_11 = _1043 + 6;\n            float4 _1171 = fa_light_texel(param_11);\n            float _1172 = _1171.w;\n            int param_12 = _1043 + 2;\n            float3 _1179 = normalize(fa_light_texel(param_12).xyz);\n            bool _1181 = _1172 > 1.5f;\n            bool _1189;\n            if (!_1181)\n            {\n                _1189 = dot(_1179, to_light) < 0.0f;\n            }\n            else\n            {\n                _1189 = _1181;\n            }\n            front = _1189;\n            float3 r = 0.0f.xxx;\n            float3 _1198 = _602_fa_camera_pos.xyz - world_pos;\n            bool _1202 = dot(n, n) > 0.5f;\n            bool _1210;\n            if (_1202)\n            {\n                _1210 = dot(_1198, _1198) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _1210 = _1202;\n            }\n            if (_1210)\n            {\n                r = reflect(-normalize(_1198), normalize(n));\n            }\n            float3 param_13 = _1132;\n            float3 param_14 = _1179;\n            float3 param_15 = _1161.xyz;\n            float3 param_16 = _1166.xyz;\n            float param_17 = _1161.w;\n            float param_18 = _1166.w;\n            float param_19 = _1172;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1246 = length(to_light);\n        dist = _1246;\n        l = to_light / max(_1246, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1260 = reach / max(_1051.w, 0.001000000047497451305389404296875f);\n        float _1266 = clamp(1.0f - (_1260 * _1260), 0.0f, 1.0f);\n        float _1268;\n        if (front)\n        {\n            _1268 = _1266 * _1266;\n        }\n        else\n        {\n            _1268 = 0.0f;\n        }\n        atten = _1268;\n        bool _1279 = _1059 < 2.5f;\n        if ((_1059 > 1.5f) && _1279)\n        {\n            int param_22 = _1043 + 2;\n            float4 _1287 = fa_light_texel(param_22);\n            float _1297 = _1287.w;\n            int param_23 = _1043 + 3;\n            float4 _1302 = fa_light_texel(param_23);\n            float _1303 = _1302.x;\n            float cos_inner = _1303;\n            if (_1303 > 1.5f)\n            {\n                cos_inner = lerp(_1297, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1297, cos_inner, dot(-l, normalize(_1287.xyz)));\n        }\n        if (_1047 && (_1059 < 1.5f))\n        {\n            int param_24 = _1043 + 6;\n            float4 _1327 = fa_light_texel(param_24);\n            if (_1327.z > 0.5f)\n            {\n                float3 _1335 = -to_light;\n                int param_25 = _1043 + 4;\n                int param_26 = _1043 + 5;\n                float3 _1349 = fa_light_texel(param_25).xyz;\n                float3 _1353 = fa_light_texel(param_26).xyz;\n                float3 _1362 = float3(dot(_1335, _1349), dot(_1335, _1353), dot(_1335, cross(_1349, _1353)));\n                float3 param_27 = _1362;\n                int _1366 = fa_cube_face(param_27);\n                int param_28 = _1366;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1393 = float2(dot(_1362, cross(param_29, param_30)), dot(_1362, param_30)) / max(dot(_1362, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1397 = _1366 / 3;\n                float2 param_31 = _1327.xy + (float2(float(_1366 - (_1397 * 3)), float(_1397)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1393.x), 0.5f - (0.5f * _1393.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1043 + 7;\n            float4 _1427 = fa_light_texel(param_33);\n            if (_1427.z > 0.5f)\n            {\n                int param_34 = _1043 + 2;\n                int param_35 = _1043 + 4;\n                int param_36 = _1043 + 5;\n                float2 param_37 = _1427.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1047 && _1279)\n            {\n                int param_42 = _1043 + 6;\n                float4 _1474 = fa_light_texel(param_42);\n                int param_43 = _1043 + 7;\n                float4 _1479 = fa_light_texel(param_43);\n                bool _1482 = _1474.z > 0.5f;\n                bool _1489;\n                if (!_1482)\n                {\n                    _1489 = _1479.z > 0.5f;\n                }\n                else\n                {\n                    _1489 = _1482;\n                }\n                if (_1489)\n                {\n                    int param_44 = _1043 + 2;\n                    float4 _1496 = fa_light_texel(param_44);\n                    float3 _1500 = normalize(_1496.xyz);\n                    int param_45 = _1043 + 4;\n                    float4 _1505 = fa_light_texel(param_45);\n                    int param_46 = _1043 + 5;\n                    float4 _1510 = fa_light_texel(param_46);\n                    if (_1482)\n                    {\n                        float3 _1518 = -to_light;\n                        float _1525 = _1496.w;\n                        float _1541 = 0.5f / max(dot(_1518, _1500) * (sqrt(max(1.0f - (_1525 * _1525), 0.0f)) / max(_1525, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1474.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1518, _1505.xyz) * _1541), 0.5f - (dot(_1518, _1510.xyz) * _1541));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1479.z > 0.5f)\n                    {\n                        float2 param_49 = _1479.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1500;\n                        float3 param_52 = _1505.xyz;\n                        float3 param_53 = _1510.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _9371 = _1056.xyz * atten;\n    if (_1047)\n    {\n        _9371 *= fa_light_tint;\n    }\n    int _1610;\n    if (_1073)\n    {\n        _1610 = 0;\n    }\n    else\n    {\n        _1610 = ((_1059 > 1.5f) && (_1059 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _9382 = { l, _9371, atten, 1.0f, dist, _1610 };\n    return _9382;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2336;\n    if (i == 0)\n    {\n        _2336 = _2346_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2352;\n        if (i == 1)\n        {\n            _2352 = _2346_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2360;\n            if (i == 2)\n            {\n                _2360 = _2346_fa_shadow_split.z;\n            }\n            else\n            {\n                _2360 = _2346_fa_shadow_split.w;\n            }\n            _2352 = _2360;\n        }\n        _2336 = _2352;\n    }\n    return _2336;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2393 = fa_shadow_depth(param, param_1);\n    float _2397;\n    if (conv.x < 0.5f)\n    {\n        _2397 = _2393;\n    }\n    else\n    {\n        _2397 = (conv.y * conv.z) / (conv.z - (_2393 * (conv.z - conv.y)));\n    }\n    return _2397;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel_turn(float2 d)\n{\n    return float2((d.x * (-0.737368881702423095703125f)) - (d.y * 0.675490319728851318359375f), (d.y * (-0.737368881702423095703125f)) + (d.x * 0.675490319728851318359375f));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2443 = fa_shadow_noise() * 6.283185482025146484375f;\n    float2 _2449 = float2(cos(_2443), sin(_2443));\n    float2 dir = _2449;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2458;\n        if (k < 0.0f)\n        {\n            _2458 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2458 = k;\n        }\n        float _2477 = clamp((_2458 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2496 = sqrt((float(i) + 0.5f) * 0.0625f) * _2477;\n            float2 param_3 = uv + (dir * (_2346_fa_shadow_bias.zw * _2496));\n            float4 param_4 = rect;\n            float3 param_5 = conv;\n            float _2510 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2510 < (zr - (_2496 * plane)))\n            {\n                sum += _2510;\n                cnt += 1.0f;\n            }\n            float2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2538 = sum / cnt;\n        float _2548;\n        if (k < 0.0f)\n        {\n            _2548 = (-k) / max(_2538, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2548 = k;\n        }\n        radius = clamp(((max(zr - _2538, 0.0f) * unit) * _2548) / texel_m, 1.5f, 16.0f);\n        dir = _2449;\n    }\n    float lit = 0.0f;\n    int _2574 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2574; i_1++)\n    {\n        float _2593 = sqrt((float(i_1) + 0.5f) / float(_2574)) * radius;\n        float2 param_7 = uv + (dir * (_2346_fa_shadow_bias.zw * _2593));\n        float4 param_8 = rect;\n        float3 param_9 = conv;\n        lit += float((zr - (_2593 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        float2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2574);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2639 = max(_2346_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2644 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2650 = sqrt(1.0f - (_2644 * _2644));\n    float _2658 = min(_2650 / max(_2644, 0.20000000298023223876953125f), 4.0f);\n    float _2663;\n    if (_2346_fa_shadow_bias.y > 0.0f)\n    {\n        _2663 = _2346_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2663 = 1.5f * _2346_fa_shadow_info[ci].x;\n    }\n    float4 _2688 = mul(float4(world + (n * (_2663 * _2650)), 1.0f), _2346_fa_shadow_mat[ci]);\n    float _2695 = _2688.x;\n    bool _2698 = _2695 < _2346_fa_shadow_rect[ci].x;\n    bool _2707;\n    if (!_2698)\n    {\n        _2707 = _2695 > _2346_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2707 = _2698;\n    }\n    bool _2716;\n    if (!_2707)\n    {\n        _2716 = _2688.y < _2346_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2716 = _2707;\n    }\n    bool _2725;\n    if (!_2716)\n    {\n        _2725 = _2688.y > _2346_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2725 = _2716;\n    }\n    bool _2732;\n    if (!_2725)\n    {\n        _2732 = _2688.z > 1.0f;\n    }\n    else\n    {\n        _2732 = _2725;\n    }\n    if (_2732)\n    {\n        return -1.0f;\n    }\n    float _2740;\n    if (_2346_fa_shadow_bias.x > 0.0f)\n    {\n        _2740 = _2346_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2740 = 1.5f * _2346_fa_shadow_info[ci].x;\n    }\n    float2 param = _2688.xy;\n    float4 param_1 = _2346_fa_shadow_rect[ci];\n    float param_2 = _2688.z - ((_2740 * (1.0f + (0.5f * _2658))) / _2639);\n    float param_3 = _2346_fa_shadow_info[ci].x;\n    float param_4 = _2639;\n    float param_5 = _2639 * 0.25f;\n    float param_6 = ((_2346_fa_shadow_info[ci].x * min(_2658, 3.0f)) * 0.5f) / _2639;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2346_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2346_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_602_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _3118 = int(_2346_fa_shadow_cfg.x + 0.5f);\n    if (_3118 < 1)\n    {\n        return 1.0f;\n    }\n    float _3133 = dot(world - _2346_fa_shadow_eye.xyz, _2346_fa_shadow_fwd.xyz);\n    int param = _3118 - 1;\n    if (_3133 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _3145 = _3118 > 1;\n    bool _3152;\n    if (_3145)\n    {\n        _3152 = _3133 > _2346_fa_shadow_split.x;\n    }\n    else\n    {\n        _3152 = _3145;\n    }\n    if (_3152)\n    {\n        ci = 1;\n    }\n    bool _3156 = _3118 > 2;\n    bool _3163;\n    if (_3156)\n    {\n        _3163 = _3133 > _2346_fa_shadow_split.y;\n    }\n    else\n    {\n        _3163 = _3156;\n    }\n    if (_3163)\n    {\n        ci = 2;\n    }\n    bool _3167 = _3118 > 3;\n    bool _3174;\n    if (_3167)\n    {\n        _3174 = _3133 > _2346_fa_shadow_split.z;\n    }\n    else\n    {\n        _3174 = _3167;\n    }\n    if (_3174)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    float s2 = -1.0f;\n    float t = 0.0f;\n    int _3185 = min(_3118, 4);\n    float _3226;\n    for (int c = ci; c < _3185; c++)\n    {\n        int param_1 = c;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _3205 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0f)\n        {\n            s2 = _3205;\n            break;\n        }\n        if (_3205 < 0.0f)\n        {\n            continue;\n        }\n        s = _3205;\n        ci = c;\n        if (_2346_fa_shadow_cfg.y > 0.0f)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3226 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3226 = _2346_fa_shadow_fwd.w;\n            }\n            int param_6 = ci;\n            float _3245 = _2346_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3226, 9.9999997473787516355514526367188e-05f);\n            int param_7 = ci;\n            t = clamp((_3133 - (fa_shadow_split_at(param_7) - _3245)) / _3245, 0.0f, 1.0f);\n        }\n        if (t <= 0.0f)\n        {\n            break;\n        }\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (t > 0.0f)\n    {\n        float _3277;\n        if ((ci + 1) < _3118)\n        {\n            _3277 = (s2 < 0.0f) ? s : s2;\n        }\n        else\n        {\n            _3277 = 1.0f;\n        }\n        s = lerp(s, _3277, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    bool _3382 = _602_fa_ct_b.y > 0.5f;\n    bool _3388;\n    if (_3382)\n    {\n        _3388 = _602_fa_pbr.z > 0.5f;\n    }\n    else\n    {\n        _3388 = _3382;\n    }\n    if (_3388)\n    {\n        float _3402 = dot(_602_fa_ct_fwd.xyz, fa_world_pos) + _602_fa_ct_fwd.w;\n        float _3405 = fwidth(_3402);\n        float4 _3415 = float4(fa_world_pos, 1.0f);\n        float _3421 = dot(_602_fa_ct_vpw, _3415);\n        if (_3421 > 9.9999997473787516355514526367188e-05f)\n        {\n            float2 _3440 = float2(dot(_602_fa_ct_vpx, _3415), dot(_602_fa_ct_vpy, _3415)) / _3421.xx;\n            float _3445 = (_3440.x * 0.5f) + 0.5f;\n            float _3449;\n            if (_602_fa_ct_a.y > 0.5f)\n            {\n                _3449 = (_3440.y * 0.5f) + 0.5f;\n            }\n            else\n            {\n                _3449 = 0.5f - (_3440.y * 0.5f);\n            }\n            bool _3465 = _3445 >= 0.0f;\n            bool _3471;\n            if (_3465)\n            {\n                _3471 = _3445 < 1.0f;\n            }\n            else\n            {\n                _3471 = _3465;\n            }\n            bool _3477;\n            if (_3471)\n            {\n                _3477 = _3449 >= 0.0f;\n            }\n            else\n            {\n                _3477 = _3471;\n            }\n            bool _3483;\n            if (_3477)\n            {\n                _3483 = _3449 < 1.0f;\n            }\n            else\n            {\n                _3483 = _3477;\n            }\n            if (_3483)\n            {\n                float4 _3509 = fa_screen_tex.Load(int3(clamp(int2(float2(_3445, _3449) * _602_fa_ct_a.zw), int2(0, 0), int2(_602_fa_ct_a.zw) - int2(1, 1)), 0));\n                bool _3512 = _3509.w > 0.5f;\n                bool _3528;\n                if (_3512)\n                {\n                    _3528 = abs(_3402 - _3509.x) <= (((0.00200000009499490261077880859375f * _3402) + 0.00999999977648258209228515625f) + min(1.5f * _3405, 0.100000001490116119384765625f * _3402));\n                }\n                else\n                {\n                    _3528 = _3512;\n                }\n                if (_3528)\n                {\n                    float _3534;\n                    if (_602_fa_ct_b.z > 0.5f)\n                    {\n                        float3 param = fa_world_pos;\n                        float3 param_1 = n;\n                        float3 param_2 = l;\n                        _3534 = min(_3509.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3534 = _3509.y;\n                    }\n                    return _3534;\n                }\n            }\n        }\n    }\n    float3 param_3 = fa_world_pos;\n    float3 param_4 = n;\n    float3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2798 = _602_fa_pbr.z < 0.5f;\n    bool _2805;\n    if (!_2798)\n    {\n        _2805 = _2346_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2805 = _2798;\n    }\n    if (_2805)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2346_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2818 = fa_light_texel(param);\n    float _2819 = _2818.x;\n    if (_2819 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2828 = int(_2819 + 0.5f);\n    int param_1 = _2828;\n    float4 _2832 = fa_light_texel(param_1);\n    int param_2 = _2828 + 1;\n    float4 _2837 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2840 = _2832.y;\n    if (_2840 > 0.0f)\n    {\n        float _2857 = 1.0f - smoothstep(0.75f * _2840, _2840, length(world - _2346_fa_shadow_eye.xyz));\n        fade = _2857;\n        if (_2857 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2832.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2881 = (_2828 + 2) + (face * 6);\n    int param_4 = _2881;\n    int param_5 = _2881 + 1;\n    int param_6 = _2881 + 3;\n    float4 _2895 = fa_light_texel(param_6);\n    int param_7 = _2881 + 4;\n    float4 _2900 = fa_light_texel(param_7);\n    int param_8 = _2881 + 5;\n    float4 _2905 = fa_light_texel(param_8);\n    float _2917 = _2905.x * max(dot(_2895, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2922 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2945 = clamp(dot(n, _2895.xyz), -1.0f, 1.0f);\n    float _2964 = min(sqrt(1.0f - (_2945 * _2945)) / max(abs(dot(n, world - lpos)) / max(dot(_2895, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2967 = _2837.y;\n    float _2969;\n    if (_2967 > 0.0f)\n    {\n        _2969 = _2967;\n    }\n    else\n    {\n        _2969 = 1.5f * _2917;\n    }\n    float4 _2989 = float4(world + (n * (_2969 * sqrt(1.0f - (_2922 * _2922)))), 1.0f);\n    float _2993 = dot(_2895, _2989);\n    float _2996 = _2905.y;\n    if (_2993 < _2996)\n    {\n        return 1.0f;\n    }\n    float2 _3011 = float2(dot(fa_light_texel(param_4), _2989), dot(fa_light_texel(param_5), _2989)) / _2993.xx;\n    float _3013 = _3011.x;\n    bool _3016 = _3013 < _2900.x;\n    bool _3025;\n    if (!_3016)\n    {\n        _3025 = _3013 > _2900.z;\n    }\n    else\n    {\n        _3025 = _3016;\n    }\n    bool _3034;\n    if (!_3025)\n    {\n        _3034 = _3011.y < _2900.y;\n    }\n    else\n    {\n        _3034 = _3025;\n    }\n    bool _3043;\n    if (!_3034)\n    {\n        _3043 = _3011.y > _2900.w;\n    }\n    else\n    {\n        _3043 = _3034;\n    }\n    if (_3043)\n    {\n        return 1.0f;\n    }\n    float _3049 = _2837.x;\n    float _3051;\n    if (_3049 > 0.0f)\n    {\n        _3051 = _3049;\n    }\n    else\n    {\n        _3051 = 1.5f * _2917;\n    }\n    float2 param_9 = _3011;\n    float4 param_10 = _2900;\n    float param_11 = _2993 - (_3051 * (1.0f + (0.5f * _2964)));\n    float param_12 = _2917;\n    float param_13 = 1.0f;\n    float param_14 = _2905.z * 0.25f;\n    float param_15 = (_2917 * min(_2964, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2996, _2905.z);\n    int param_17 = int(_2832.z + 0.5f);\n    float param_18 = _2832.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _5377 = _602_fa_ct_a.x < 0.5f;\n    bool _5384;\n    if (!_5377)\n    {\n        _5384 = _2346_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _5384 = _5377;\n    }\n    if (_5384)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2346_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _5397 = fa_light_texel(param);\n    float _5398 = _5397.y;\n    float len = _5398;\n    if (_5398 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _5410 = length(world - _602_fa_camera_pos.xyz);\n    float _5419 = 1.0f - smoothstep(0.5f * _602_fa_ct_b.x, _602_fa_ct_b.x, _5410);\n    if (_5419 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _5425 = len;\n    float _5428 = min(_5425, 0.89999997615814208984375f * dist);\n    len = _5428;\n    float _5433 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _5410);\n    float _5438 = _5433 + (0.5f * _5428);\n    float3 _5444 = world + (gn * _5433);\n    float _5446 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _5507;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5461 = (float(k) + _5446) * 0.083333335816860198974609375f;\n        float3 _5469 = _5444 + (l * (_5461 * len));\n        float4 _5475 = float4(_5469, 1.0f);\n        float _5480 = dot(_602_fa_ct_vpw, _5475);\n        if (_5480 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _5498 = float2(dot(_602_fa_ct_vpx, _5475), dot(_602_fa_ct_vpy, _5475)) / _5480.xx;\n        float _5502 = _5498.x * 0.5f;\n        float _5503 = _5502 + 0.5f;\n        if (_602_fa_ct_a.y > 0.5f)\n        {\n            _5507 = (_5498.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _5507 = 0.5f - (_5498.y * 0.5f);\n        }\n        bool _5523 = _5503 < 0.0f;\n        bool _5530;\n        if (!_5523)\n        {\n            _5530 = _5503 >= 1.0f;\n        }\n        else\n        {\n            _5530 = _5523;\n        }\n        bool _5537;\n        if (!_5530)\n        {\n            _5537 = _5507 < 0.0f;\n        }\n        else\n        {\n            _5537 = _5530;\n        }\n        bool _5544;\n        if (!_5537)\n        {\n            _5544 = _5507 >= 1.0f;\n        }\n        else\n        {\n            _5544 = _5537;\n        }\n        if (_5544)\n        {\n            break;\n        }\n        float4 _5568 = fa_screen_tex.Load(int3(clamp(int2(float2(_5503, _5507) * _602_fa_ct_a.zw), int2(0, 0), int2(_602_fa_ct_a.zw) - int2(1, 1)), 0));\n        if (_5568.w < 0.5f)\n        {\n            continue;\n        }\n        float _5586 = (dot(_602_fa_ct_fwd.xyz, _5469) + _602_fa_ct_fwd.w) - _5568.x;\n        if ((_5586 > _5433) && (_5586 < _5438))\n        {\n            occ = max(occ, (1.0f - (_5461 * _5461)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_5503, 0.5f - _5502), min(_5507, 1.0f - _5507))));\n        }\n    }\n    return 1.0f - (occ * _5419);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _6219 = fa_baked_keep(param);\n    if (_6219 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _9438 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _9438;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _6245 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _9440 = _6245.color;\n    float _9441 = _6245.attenuation;\n    float _9442 = _6245.shadow;\n    bool _6248 = _6245.type == 0;\n    if (_6248 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _6245.direction;\n        float _6259 = fa_shadow_factor(param_5, param_6);\n        _9442 = _6259;\n        _9440 *= _6259;\n    }\n    else\n    {\n        bool _6270 = _6245.type != 0;\n        bool _6276;\n        if (_6270)\n        {\n            _6276 = _9441 > 0.0f;\n        }\n        else\n        {\n            _6276 = _6270;\n        }\n        if (_6276)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _6245.direction;\n            float _6295 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _9442 = _6295;\n            _9440 *= _6295;\n        }\n    }\n    bool _6305 = _602_fa_ct_a.x > 0.5f;\n    bool _6311;\n    if (_6305)\n    {\n        _6311 = _9441 > 0.0f;\n    }\n    else\n    {\n        _6311 = _6305;\n    }\n    if (_6311)\n    {\n        float _6318;\n        if (_6248)\n        {\n            _6318 = 1000000000.0f;\n        }\n        else\n        {\n            _6318 = _6245._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _6245.direction;\n        float param_18 = _6318;\n        float _6336 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9442 *= _6336;\n        _9440 *= _6336;\n    }\n    float _6349 = _9441;\n    float _6350 = _6349 * _6219;\n    _9441 = _6350;\n    float3 _6354 = _9440;\n    float3 _6355 = _6354 * _6219;\n    _9440 = _6355;\n    LightSample _9457 = { _6245.direction, _6355, _6350, _9442, _6245._distance, _6245.type };\n    return _9457;\n}\n\nfloat3 fa_ltc_tangent(float3 n, float3 v)\n{\n    float3 _6389 = v - (n * dot(v, n));\n    float3 t = _6389;\n    float _6393 = dot(_6389, _6389);\n    float l2 = _6393;\n    if (_6393 < 1.0000000133514319600180897396058e-10f)\n    {\n        float3 _6403;\n        if (abs(n.z) < 0.999000012874603271484375f)\n        {\n            _6403 = cross(n, float3(0.0f, 0.0f, 1.0f));\n        }\n        else\n        {\n            _6403 = cross(n, float3(1.0f, 0.0f, 0.0f));\n        }\n        t = _6403;\n        l2 = dot(_6403, _6403);\n    }\n    return t * rsqrt(l2);\n}\n\nfloat3 fa_ltc_local(float3 t1, float3 n, float3 p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nfloat2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((float2(clamp((roughness - 0.0500000007450580596923828125f) * 1.0526316165924072265625f, 0.0f, 1.0f), sqrt(clamp(1.0f - ndv, 0.0f, 1.0f))) * 63.0f) + 0.5f.xx) * 0.015625f.xx;\n}\n\nfloat3 fa_oct_vertex(int j, float3 pc, float3 ex, float3 ey)\n{\n    float _6790;\n    if ((j == 0) || (j == 7))\n    {\n        _6790 = 0.92387950420379638671875f;\n    }\n    else\n    {\n        float _6800;\n        if ((j == 3) || (j == 4))\n        {\n            _6800 = -0.92387950420379638671875f;\n        }\n        else\n        {\n            _6800 = ((j == 1) || (j == 6)) ? 0.3826834261417388916015625f : (-0.3826834261417388916015625f);\n        }\n        _6790 = _6800;\n    }\n    float _6821;\n    if ((j == 1) || (j == 2))\n    {\n        _6821 = 0.92387950420379638671875f;\n    }\n    else\n    {\n        float _6830;\n        if ((j == 5) || (j == 6))\n        {\n            _6830 = -0.92387950420379638671875f;\n        }\n        else\n        {\n            _6830 = ((j == 0) || (j == 3)) ? 0.3826834261417388916015625f : (-0.3826834261417388916015625f);\n        }\n        _6821 = _6830;\n    }\n    return (pc + (ex * _6790)) + (ey * _6821);\n}\n\nfloat3 fa_ltc_edge_vector(float3 a, float3 b)\n{\n    float _6438 = dot(a, a);\n    float _6442 = dot(b, b);\n    if ((_6438 < 1.0000000195414813782625560981111e-24f) || (_6442 < 1.0000000195414813782625560981111e-24f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _6456 = a * rsqrt(_6438);\n    float3 _6461 = b * rsqrt(_6442);\n    float _6465 = dot(_6456, _6461);\n    float _6468 = abs(_6465);\n    float g = (((((((((((0.0416471660137176513671875f * _6468) - 0.1924748718738555908203125f) * _6468) + 0.4179156124591827392578125f) * _6468) - 0.616057217121124267578125f) * _6468) + 0.777722418308258056640625f) * _6468) - 0.999542415142059326171875f) * _6468) + 1.570791721343994140625f;\n    if (_6465 < 0.0f)\n    {\n        g = (3.1415927410125732421875f * rsqrt(max(1.0f - (_6465 * _6465), 1.0000000116860974230803549289703e-07f))) - g;\n    }\n    return cross(_6456, _6461) * g;\n}\n\nvoid fa_ltc_clip_edge(float3 a, float3 b, inout float3 sum, inout float3 leave, inout float3 enter, inout float2 seen)\n{\n    bool _6525 = a.z > 0.0f;\n    bool _6529 = b.z > 0.0f;\n    if (_6525 && _6529)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6525 != _6529)\n        {\n            float3 _6564 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6564.z = 0.0f;\n            if (_6525)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _6564;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6564;\n                seen.x = 1.0f;\n            }\n            else\n            {\n                float3 param_4 = _6564;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6564;\n                seen.y = 1.0f;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(float4 abcd, float3 p0, float3 p1, float3 p2, float3 p3)\n{\n    float3 _6613 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _6639 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _6665 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _6691 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = 0.0f.xxx;\n    float3 leave = 0.0f.xxx;\n    float3 enter = 0.0f.xxx;\n    float3 param = _6613;\n    float3 param_1 = _6639;\n    float3 param_2 = 0.0f.xxx;\n    float3 param_3 = 0.0f.xxx;\n    float3 param_4 = 0.0f.xxx;\n    float2 param_5 = 0.0f.xx;\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _6639;\n    float3 param_7 = _6665;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _6665;\n    float3 param_13 = _6691;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _6691;\n    float3 param_19 = _6613;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5f)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875f;\n}\n\nfloat2 fa_area_forms(float4 m, float shape, float3 pc, float3 ex, float3 ey)\n{\n    int _6859 = ((shape < 0.5f) || (shape > 1.5f)) ? 1 : 3;\n    float2 sum = 0.0f.xx;\n    int _6877;\n    for (int k = 0; k < (2 * _6859); k++)\n    {\n        bool _6874 = k >= _6859;\n        if (_6874)\n        {\n            _6877 = k - _6859;\n        }\n        else\n        {\n            _6877 = k;\n        }\n        float3 p0 = (pc - ex) - ey;\n        float3 p1 = (pc + ex) - ey;\n        float3 p2 = (pc + ex) + ey;\n        float3 p3 = (pc - ex) + ey;\n        if (_6859 == 3)\n        {\n            int param = 0;\n            float3 param_1 = pc;\n            float3 param_2 = ex;\n            float3 param_3 = ey;\n            p0 = fa_oct_vertex(param, param_1, param_2, param_3);\n            int _6923 = 2 * _6877;\n            int param_4 = _6923 + 1;\n            float3 param_5 = pc;\n            float3 param_6 = ex;\n            float3 param_7 = ey;\n            p1 = fa_oct_vertex(param_4, param_5, param_6, param_7);\n            int param_8 = _6923 + 2;\n            float3 param_9 = pc;\n            float3 param_10 = ex;\n            float3 param_11 = ey;\n            p2 = fa_oct_vertex(param_8, param_9, param_10, param_11);\n            int param_12 = _6923 + 3;\n            float3 param_13 = pc;\n            float3 param_14 = ex;\n            float3 param_15 = ey;\n            p3 = fa_oct_vertex(param_12, param_13, param_14, param_15);\n        }\n        bool4 _6960 = _6874.xxxx;\n        float4 param_16 = float4(_6960.x ? m.x : float4(1.0f, 0.0f, 0.0f, 1.0f).x, _6960.y ? m.y : float4(1.0f, 0.0f, 0.0f, 1.0f).y, _6960.z ? m.z : float4(1.0f, 0.0f, 0.0f, 1.0f).z, _6960.w ? m.w : float4(1.0f, 0.0f, 0.0f, 1.0f).w);\n        float3 param_17 = p0;\n        float3 param_18 = p1;\n        float3 param_19 = p2;\n        float3 param_20 = p3;\n        float _6971 = fa_ltc_quad(param_16, param_17, param_18, param_19, param_20);\n        if (_6874)\n        {\n            float2 _9683 = sum;\n            _9683.y = _9683.y + _6971;\n            sum = _9683;\n        }\n        else\n        {\n            float2 _9686 = sum;\n            _9686.x = _9686.x + _6971;\n            sum = _9686;\n        }\n    }\n    return abs(sum);\n}\n\nfloat3 fa_area_shade(int li, float3 world_pos, float3 n, float3 v, float3 diffuse_color, float3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _6995 = fa_light_base(param);\n    int param_1 = _6995;\n    int param_2 = _6995 + 1;\n    int param_3 = _6995 + 2;\n    int param_4 = _6995 + 4;\n    float4 _7017 = fa_light_texel(param_4);\n    int param_5 = _6995 + 5;\n    float4 _7022 = fa_light_texel(param_5);\n    int param_6 = _6995 + 6;\n    float4 _7027 = fa_light_texel(param_6);\n    float _7028 = _7027.w;\n    float3 _7033 = fa_light_texel(param_1).xyz - world_pos;\n    bool _7035 = _7028 < 1.5f;\n    bool _7042;\n    if (_7035)\n    {\n        _7042 = dot(normalize(fa_light_texel(param_3).xyz), _7033) >= 0.0f;\n    }\n    else\n    {\n        _7042 = _7035;\n    }\n    if (_7042)\n    {\n        return 0.0f.xxx;\n    }\n    bool _7051 = (_7028 > 0.5f) && _7035;\n    float _7055 = _7051 ? 1.0539000034332275390625f : 1.0f;\n    float3 _7058 = _7017.xyz;\n    float _7060 = _7017.w;\n    float3 _7066 = _7022.xyz;\n    float _7068 = _7022.w;\n    float3 up = _7066 * (_7068 * _7055);\n    float _7074;\n    if (_7051)\n    {\n        _7074 = (3.1415927410125732421875f * _7060) * _7060;\n    }\n    else\n    {\n        _7074 = (4.0f * _7060) * _7068;\n    }\n    if (_7028 > 1.5f)\n    {\n        float3 _7100 = cross(_7058, -_7033);\n        float3 perp = _7100;\n        float _7104 = dot(_7100, _7100);\n        float3 _7107;\n        if (_7104 > 1.0000000133514319600180897396058e-10f)\n        {\n            _7107 = perp * rsqrt(_7104);\n        }\n        else\n        {\n            _7107 = _7066;\n        }\n        perp = _7107;\n        up = _7107 * _7068;\n    }\n    float _7128 = max(_7074, 9.9999999747524270787835121154785e-07f);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _7138 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _7138;\n    float3 param_10 = n;\n    float3 param_11 = _7033;\n    float3 param_12 = _7138;\n    float3 param_13 = n;\n    float3 param_14 = _7058 * (_7060 * _7055);\n    float3 param_15 = _7138;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float param_18 = roughness;\n    float param_19 = ndv;\n    float2 _7169 = fa_ltc_uv(param_18, param_19) * 64.0f;\n    float2 param_20 = _7169;\n    float2 param_21 = _7169 + float2(64.0f, 0.0f);\n    float4 _7179 = fa_atlas_fetch(param_21);\n    float4 param_22 = fa_atlas_fetch(param_20);\n    float param_23 = _7028;\n    float3 param_24 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_25 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_26 = fa_ltc_local(param_15, param_16, param_17);\n    float2 _7191 = fa_area_forms(param_22, param_23, param_24, param_25, param_26);\n    return (((diffuse_color * _7191.x) + (((f0 * _7179.x) + ((f90.xxx - f0) * _7179.y)) * _7191.y)) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875f * dot(_7033, _7033)) + _7128) / _7128) * window);\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _5114 = 1.0f / alpha;\n    return ((2.0f + _5114) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _5114)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat fa_layers_coat(FaLayers L, float3 l, float3 h, float vdh)\n{\n    float _5149 = max(dot(L.nc, l), 0.0f);\n    float _5155 = max(dot(L.nc, h), 0.0f);\n    float _5164 = ((_5155 * _5155) * (L.coat_a2 - 1.0f)) + 1.0f;\n    return (((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _5164) * _5164)) * (0.5f / max(lerp((2.0f * _5149) * L.coat_ndv, _5149 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _5149)) * _5149;\n}\n\nfloat3 fa_area_layers(FaLayers L, float3 base, int li, float3 n, float3 v, float3 l, float ndv, float window)\n{\n    float _7228;\n    if (L.sheen_on)\n    {\n        _7228 = L.sheen_scale;\n    }\n    else\n    {\n        _7228 = 1.0f;\n    }\n    float3 result = base * (L.keep * _7228);\n    float3 _7241 = normalize(l + v);\n    int param = li;\n    float3 _7252 = fa_light_rgb(param) * window;\n    if (L.sheen_on)\n    {\n        float _7261 = max(dot(n, l), 0.0f);\n        float param_1 = L.sheen_alpha;\n        float param_2 = max(dot(n, _7241), 0.0f);\n        float param_3 = _7261;\n        float param_4 = ndv;\n        result += ((L.sheen * _7252) * (((((fa_d_charlie(param_1, param_2) * fa_v_ashikhmin(param_3, param_4)) * 3.1415927410125732421875f) * step(9.9999997473787516355514526367188e-05f, _7261)) * _7261) * L.keep));\n    }\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_5 = L;\n        float3 param_6 = l;\n        float3 param_7 = _7241;\n        float param_8 = max(dot(v, _7241), 0.0f);\n        result += (_7252 * fa_layers_coat(param_5, param_6, param_7, param_8));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _5017 = tdh / at;\n    float _5021 = bdh / ab;\n    float _5033 = ((_5017 * _5017) + (_5021 * _5021)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _5033) * _5033);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5213 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5292 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _5292) * _5292);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _5213);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _5213));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_17 = L;\n        float3 param_18 = l;\n        float3 param_19 = h;\n        float param_20 = vdh;\n        result += fa_layers_coat(param_17, param_18, param_19, param_20).xxx;\n    }\n    return result;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _4416 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _4419 = _4416.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_4419 * _4419, exp2((-9.27999973297119140625f) * ndv)) * _4419) + _4416.y)) + _4416.zw;\n}\n\nfloat3 fa_probe_level(float2 origin, float res, int lv, float2 e)\n{\n    float _3725;\n    if (lv == 0)\n    {\n        _3725 = 0.0f;\n    }\n    else\n    {\n        _3725 = res + 2.0f;\n    }\n    float _3735;\n    if (lv == 0)\n    {\n        _3735 = 0.0f;\n    }\n    else\n    {\n        _3735 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0f * float(lv - 1));\n    }\n    return fa_probe_atlas.SampleLevel(fa_env_smp, (((origin + float2(_3725, _3735)) + 1.0f.xx) + (((e * 0.5f) + 0.5f.xx) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0f).xyz;\n}\n\nfloat3 fa_probe_radiance(float2 origin, float res, float3 d, float rough)\n{\n    float _3781;\n    if (res > 64.5f)\n    {\n        _3781 = 5.0f;\n    }\n    else\n    {\n        _3781 = (res > 32.5f) ? 4.0f : 3.0f;\n    }\n    float _3796 = clamp(rough, 0.0f, 1.0f) * (_3781 - 1.0f);\n    int _3803 = int(min(floor(_3796), _3781 - 2.0f));\n    float _3808 = _3796 - float(_3803);\n    float3 param = d;\n    float2 _3812 = fa_oct_encode(param);\n    float2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3803;\n    float2 param_4 = _3812;\n    float3 _3822 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3808 < 0.00200000009499490261077880859375f)\n    {\n        return _3822;\n    }\n    float2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3803 + 1;\n    float2 param_8 = _3812;\n    return lerp(_3822, fa_probe_level(param_5, param_6, param_7, param_8), _3808.xxx);\n}\n\nfloat3 fa_probe_box_dir(float3 d, float4 posw, float4 bx, float4 by, float4 bz)\n{\n    if (posw.w < 0.5f)\n    {\n        return d;\n    }\n    float _3894 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3901 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3908 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3914 = dot(bx.xyz, d);\n    float _3918 = dot(by.xyz, d);\n    float _3922 = dot(bz.xyz, d);\n    float _3928;\n    if (_3914 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3928 = (1.0f - _3894) / _3914;\n    }\n    else\n    {\n        float _3942;\n        if (_3914 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3942 = ((-1.0f) - _3894) / _3914;\n        }\n        else\n        {\n            _3942 = 1000000015047466219876688855040.0f;\n        }\n        _3928 = _3942;\n    }\n    float tx = _3928;\n    float _3959;\n    if (_3918 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3959 = (1.0f - _3901) / _3918;\n    }\n    else\n    {\n        float _3972;\n        if (_3918 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3972 = ((-1.0f) - _3901) / _3918;\n        }\n        else\n        {\n            _3972 = 1000000015047466219876688855040.0f;\n        }\n        _3959 = _3972;\n    }\n    float ty = _3959;\n    float _3988;\n    if (_3922 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3988 = (1.0f - _3908) / _3922;\n    }\n    else\n    {\n        float _4001;\n        if (_3922 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _4001 = ((-1.0f) - _3908) / _3922;\n        }\n        else\n        {\n            _4001 = 1000000015047466219876688855040.0f;\n        }\n        _3988 = _4001;\n    }\n    float _4013 = tx;\n    float _4016 = (_4013 > 0.0f) ? _4013 : 1000000015047466219876688855040.0f;\n    tx = _4016;\n    float _4017 = ty;\n    float _4020 = (_4017 > 0.0f) ? _4017 : 1000000015047466219876688855040.0f;\n    ty = _4020;\n    float _4030 = min(_4016, min(_4020, (_3988 > 0.0f) ? _3988 : 1000000015047466219876688855040.0f));\n    if (_4030 > 100000001504746621987668885504.0f)\n    {\n        return d;\n    }\n    float3 _4046 = (fa_world_pos + (d * _4030)) - posw.xyz;\n    float3 _4051;\n    if (dot(_4046, _4046) > 1.0000000133514319600180897396058e-10f)\n    {\n        _4051 = normalize(_4046);\n    }\n    else\n    {\n        _4051 = d;\n    }\n    return _4051;\n}\n\nfloat3 fa_probe_environment(float4 tile, float4 posw, float4 bx, float4 by, float4 bz, inout float3 d, float rough)\n{\n    float3 param = d;\n    float4 param_1 = posw;\n    float4 param_2 = bx;\n    float4 param_3 = by;\n    float4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    float2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    float3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _4097 = (1.0f - _602_fa_rpa_tile.w) - _602_fa_rpb_tile.w;\n    float3 outc = 0.0f.xxx;\n    if (_4097 > 0.0005000000237487256526947021484375f)\n    {\n        float3 base;\n        if (_602_fa_env_sky.w > 0.5f)\n        {\n            float2 param = _602_fa_atlas.zw;\n            float param_1 = 128.0f;\n            float3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _4125 = rough * rough;\n            float _4156 = 0.60000002384185791015625f * _4125;\n            base = lerp(lerp(_602_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_602_fa_env_horizon.xyz, _602_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _4125)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _4156, 0.0500000007450580596923828125f + _4156, d.y).xxx), ((_602_fa_env_sky.xyz + _602_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_4125 * 0.60000002384185791015625f).xxx);\n        }\n        outc = base * _4097;\n    }\n    if (_602_fa_rpa_tile.w > 0.0f)\n    {\n        float4 param_4 = _602_fa_rpa_tile;\n        float4 param_5 = _602_fa_rpa_pos;\n        float4 param_6 = _602_fa_rpa_bx;\n        float4 param_7 = _602_fa_rpa_by;\n        float4 param_8 = _602_fa_rpa_bz;\n        float3 param_9 = d;\n        float param_10 = rough;\n        float3 _4215 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4215 * _602_fa_rpa_tile.w);\n    }\n    if (_602_fa_rpb_tile.w > 0.0f)\n    {\n        float4 param_11 = _602_fa_rpb_tile;\n        float4 param_12 = _602_fa_rpb_pos;\n        float4 param_13 = _602_fa_rpb_bx;\n        float4 param_14 = _602_fa_rpb_by;\n        float4 param_15 = _602_fa_rpb_bz;\n        float3 param_16 = d;\n        float param_17 = rough;\n        float3 _4247 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4247 * _602_fa_rpb_tile.w);\n    }\n    return outc;\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness, float occlusion)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _4894;\n        if (L.aniso >= 0.0f)\n        {\n            _4894 = L.b;\n        }\n        else\n        {\n            _4894 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_4894, v), _4894), (abs(L.aniso) * smoothstep(0.0f, 0.25f, roughness)).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4930 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _4930.x) + (L.f90.xxx * _4930.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _4988 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _4988.x) + _4988.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4458 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4458.x) + _4458.y.xxx);\n}\n\nfloat2 fa_xm_size(int k)\n{\n    return max(floor(_602_fa_ct_a.zw / float(1 << k).xx), 1.0f.xx);\n}\n\nfloat2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return 0.0f.xx;\n    }\n    float y = 0.0f;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return float2(_602_fa_ct_a.z, y);\n}\n\nfloat3 fa_xm_texel(float2 size, float2 origin, float2 p)\n{\n    return fa_screen_tex.Load(int3(int2(origin + clamp(p, 0.0f.xx, size - 1.0f.xx)), 0)).xyz;\n}\n\nfloat3 fa_xm_level(int k, float2 uv)\n{\n    int param = k;\n    float2 _5690 = fa_xm_size(param);\n    int param_1 = k;\n    float2 _5694 = fa_xm_origin(param_1);\n    float2 _5700 = (uv * _5690) - 0.5f.xx;\n    float2 _5703 = frac(_5700);\n    float2 _5706 = floor(_5700);\n    float2 param_2 = _5690;\n    float2 param_3 = _5694;\n    float2 param_4 = _5706;\n    float2 param_5 = _5690;\n    float2 param_6 = _5694;\n    float2 param_7 = _5706 + float2(1.0f, 0.0f);\n    float2 param_8 = _5690;\n    float2 param_9 = _5694;\n    float2 param_10 = _5706 + float2(0.0f, 1.0f);\n    float2 param_11 = _5690;\n    float2 param_12 = _5694;\n    float2 param_13 = _5706 + 1.0f.xx;\n    float3 _5748 = _5703.x.xxx;\n    return lerp(lerp(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _5748), lerp(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _5748), _5703.y.xxx);\n}\n\nfloat3 fa_xm_sample(float2 uv, float lod)\n{\n    float _5767 = max(_602_fa_tr_b.w - 1.0f, 0.0f);\n    float _5771 = clamp(lod, 0.0f, _5767);\n    int _5775 = int(floor(_5771));\n    int param = _5775;\n    float2 param_1 = uv;\n    float3 c = fa_xm_level(param, param_1);\n    float _5785 = float(_5775);\n    float _5786 = _5771 - _5785;\n    bool _5788 = _5786 > 0.001000000047497451305389404296875f;\n    bool _5795;\n    if (_5788)\n    {\n        _5795 = _5785 < _5767;\n    }\n    else\n    {\n        _5795 = _5788;\n    }\n    if (_5795)\n    {\n        int param_2 = _5775 + 1;\n        float2 param_3 = uv;\n        c = lerp(c, fa_xm_level(param_2, param_3), _5786.xxx);\n    }\n    return c;\n}\n\nfloat3 fa_transmitted(Surface s, float3 n, float3 v, float roughness, float3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _5821 = fa_env_brdf(param, param_1);\n    float3 _5845 = ((1.0f.xxx - clamp((f0 * _5821.x) + (f90.xxx * _5821.y), 0.0f.xxx, 1.0f.xxx)) * s.albedo) * (tr * keep);\n    float3 through = _5845;\n    float _5851 = max(s.thickness, 0.0f);\n    bool _5856 = _5851 > 0.0f;\n    if ((s.attenuation_distance > 0.0f) && _5856)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, 9.9999997473787516355514526367188e-05f.xxx, 1.0f.xxx))) / s.attenuation_distance.xxx)) * _5851);\n    }\n    bool _5881 = _602_fa_tr_a.w > 1.5f;\n    bool _5887;\n    if (_5881)\n    {\n        _5887 = _602_fa_tr_a.w < 2.5f;\n    }\n    else\n    {\n        _5887 = _5881;\n    }\n    bool _5894;\n    if (!_5887)\n    {\n        _5894 = _602_fa_tr_a.w < 0.5f;\n    }\n    else\n    {\n        _5894 = _5887;\n    }\n    if (_5894)\n    {\n        blend = clamp(dot(through, 0.3333333432674407958984375f.xxx), 0.0f, 0.980000019073486328125f);\n        return 0.0f.xxx;\n    }\n    float4 _5909 = float4(fa_world_pos, 1.0f);\n    float _5914 = dot(_602_fa_ct_vpw, _5909);\n    float2 uv0 = 0.5f.xx;\n    if (_5914 > 9.9999997473787516355514526367188e-05f)\n    {\n        float2 _5932 = float2(dot(_602_fa_ct_vpx, _5909), dot(_602_fa_ct_vpy, _5909)) / _5914.xx;\n        float _5940;\n        if (_602_fa_ct_a.y > 0.5f)\n        {\n            _5940 = (_5932.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _5940 = 0.5f - (_5932.y * 0.5f);\n        }\n        uv0 = float2((_5932.x * 0.5f) + 0.5f, _5940);\n    }\n    if (_602_fa_tr_a.w > 2.5f)\n    {\n        int param_2 = 0;\n        float2 _5961 = fa_xm_size(param_2);\n        float2 _5969 = floor(clamp(uv0, 0.0f.xx, 0.99989998340606689453125f.xx) * _5961);\n        if (fa_screen_tex.Load(int3(int2(_5969), 0)).w > 0.5f)\n        {\n            int _5989 = int(floor((clamp(roughness, 0.0f, 1.0f) * 2.0f) + 0.5f));\n            float3 acc = 0.0f.xxx;\n            float cnt = 0.0f;\n            for (int dy = -2; dy <= 2; dy++)\n            {\n                for (int dx = -2; dx <= 2; dx++)\n                {\n                    bool _6012 = abs(dx) > _5989;\n                    bool _6020;\n                    if (!_6012)\n                    {\n                        _6020 = abs(dy) > _5989;\n                    }\n                    else\n                    {\n                        _6020 = _6012;\n                    }\n                    if (_6020)\n                    {\n                        continue;\n                    }\n                    float4 _6041 = fa_screen_tex.Load(int3(int2(clamp(_5969 + float2(float(dx), float(dy)), 0.0f.xx, _5961 - 1.0f.xx)), 0));\n                    if (_6041.w > 0.5f)\n                    {\n                        acc += _6041.xyz;\n                        cnt += 1.0f;\n                    }\n                }\n            }\n            return _5845 * (acc / max(cnt, 1.0f).xxx);\n        }\n    }\n    float2 uv = uv0;\n    if (_5856)\n    {\n        float4 _6089 = float4(fa_world_pos + (refract(-v, n, 1.0f / max(s.ior, 1.0f)) * _5851), 1.0f);\n        float _6094 = dot(_602_fa_ct_vpw, _6089);\n        uv = 0.5f.xx;\n        if (_6094 > 9.9999997473787516355514526367188e-05f)\n        {\n            float2 _6111 = float2(dot(_602_fa_ct_vpx, _6089), dot(_602_fa_ct_vpy, _6089)) / _6094.xx;\n            float _6119;\n            if (_602_fa_ct_a.y > 0.5f)\n            {\n                _6119 = (_6111.y * 0.5f) + 0.5f;\n            }\n            else\n            {\n                _6119 = 0.5f - (_6111.y * 0.5f);\n            }\n            uv = float2((_6111.x * 0.5f) + 0.5f, _6119);\n        }\n    }\n    float2 param_3 = clamp(uv, 0.0f.xx, 1.0f.xx);\n    float param_4 = (clamp(roughness, 0.0f, 1.0f) * clamp((2.0f * s.ior) - 2.0f, 0.0f, 1.0f)) * max(_602_fa_tr_b.w - 1.0f, 0.0f);\n    return through * fa_xm_sample(param_3, param_4);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2346_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3305 = int(_2346_fa_shadow_cfg.x + 0.5f);\n    float _3315 = dot(world - _2346_fa_shadow_eye.xyz, _2346_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3320 = _3305 > 0;\n    bool _3329;\n    if (_3320)\n    {\n        int param = _3305 - 1;\n        _3329 = _3315 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3329 = _3320;\n    }\n    if (_3329)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3335 = _3305 > 1;\n        bool _3342;\n        if (_3335)\n        {\n            _3342 = _3315 > _2346_fa_shadow_split.x;\n        }\n        else\n        {\n            _3342 = _3335;\n        }\n        if (_3342)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3348 = _3305 > 2;\n        bool _3355;\n        if (_3348)\n        {\n            _3355 = _3315 > _2346_fa_shadow_split.y;\n        }\n        else\n        {\n            _3355 = _3348;\n        }\n        if (_3355)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3361 = _3305 > 3;\n        bool _3368;\n        if (_3361)\n        {\n            _3368 = _3315 > _2346_fa_shadow_split.z;\n        }\n        else\n        {\n            _3368 = _3361;\n        }\n        if (_3368)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _9099 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _9099 = -_9099;\n    }\n    float3 _8385 = normalize(_602_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _9112 = { fa_world_pos, _9099, fa_world_tangent, fa_uv, fa_vertex_color, _8385, gl_FrontFacing };\n    SurfaceInput param_1 = _9112;\n    Surface _8393 = fa_standard_surface(param_1);\n    float3 _9130 = _8393.albedo;\n    float _9131 = _8393.alpha;\n    float3 _9132 = _8393.normal;\n    float _9133 = _8393.metallic;\n    float _9134 = _8393.roughness;\n    float _9135 = _8393.occlusion;\n    float3 _9136 = _8393.emission;\n    float _9137 = _8393.clearcoat;\n    float _9138 = _8393.clearcoat_roughness;\n    float3 _9139 = _8393.sheen_color;\n    float _9140 = _8393.sheen_roughness;\n    float _9141 = _8393.anisotropy;\n    float _9142 = _8393.anisotropy_rotation;\n    float _9143 = _8393.specular;\n    float _9144 = _8393.ior;\n    float3 _9145 = _8393.specular_color;\n    float _9146 = _8393.transmission;\n    float _9147 = _8393.thickness;\n    float3 _9148 = _8393.attenuation_color;\n    float _9149 = _8393.attenuation_distance;\n    SurfaceInput _9120 = { fa_world_pos, _9099, fa_world_tangent, fa_uv, fa_vertex_color, _8385, gl_FrontFacing };\n    SurfaceInput param_2 = _9120;\n    Surface param_3 = _8393;\n    surface(param_2, param_3);\n    _9130 = param_3.albedo;\n    _9131 = param_3.alpha;\n    _9132 = param_3.normal;\n    _9133 = param_3.metallic;\n    _9134 = param_3.roughness;\n    _9135 = param_3.occlusion;\n    _9136 = param_3.emission;\n    _9137 = param_3.clearcoat;\n    _9138 = param_3.clearcoat_roughness;\n    _9139 = param_3.sheen_color;\n    _9140 = param_3.sheen_roughness;\n    _9141 = param_3.anisotropy;\n    _9142 = param_3.anisotropy_rotation;\n    _9143 = param_3.specular;\n    _9144 = param_3.ior;\n    _9145 = param_3.specular_color;\n    _9146 = param_3.transmission;\n    _9147 = param_3.thickness;\n    _9148 = param_3.attenuation_color;\n    _9149 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _9099;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _9130 = param_6;\n    _9132 = param_7;\n    if (_9131 < _8421_alphaCutoff)\n    {\n        discard;\n    }\n    fa_lod_dither();\n    float fa_tr_blend = 0.0f;\n    float3 result;\n    if (_602_fa_emissive.w > 0.5f)\n    {\n        result = _9130;\n    }\n    else\n    {\n        float3 _8445 = normalize(_9132);\n        float _8452 = clamp(_9133, 0.0f, 1.0f);\n        float _8456 = clamp(_9134, 0.0500000007450580596923828125f, 1.0f);\n        float _8460 = _8456 * _8456;\n        float _8464 = _8460 * _8460;\n        float _8469 = max(dot(_8445, _8385), 9.9999997473787516355514526367188e-05f);\n        float _8475 = 1.0f - _8452;\n        float _8476 = clamp(_9146, 0.0f, 1.0f) * _8475;\n        float3 _8485 = (_9130 * _8475) * (1.0f - _8476);\n        float3 _8492 = lerp(0.039999999105930328369140625f.xxx, _9130, _8452.xxx);\n        float3 f0 = _8492;\n        SurfaceInput _9128 = { fa_world_pos, _9099, fa_world_tangent, fa_uv, fa_vertex_color, _8385, gl_FrontFacing };\n        SurfaceInput param_8 = _9128;\n        Surface _9231 = { _9130, _9131, _9132, _9133, _9134, _9135, _9136, _9137, _9138, _9139, _9140, _9141, _9142, _9143, _9144, _9145, _9146, _9147, _9148, _9149 };\n        Surface param_9 = _9231;\n        float3 param_10 = _8445;\n        float3 param_11 = _8385;\n        float param_12 = _8452;\n        float param_13 = _8456;\n        float3 param_14 = _8492;\n        FaLayers _8508 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _8445;\n        float3 lit = (fa_indirect_diffuse(param_15) * _8485) * _9135;\n        if (_8508.on)\n        {\n            lit *= _8508.base_scale;\n        }\n        int _8530 = fa_cl_ndir + fa_cl_local;\n        float _8595;\n        for (int ln = 0; ln < _8530; ln++)\n        {\n            int param_16 = ln;\n            int _8543 = fa_cl_light(param_16);\n            int param_17 = _8543;\n            if (fa_baked_keep(param_17) <= 0.0f)\n            {\n                continue;\n            }\n            int param_18 = _8543;\n            float3 param_19 = fa_world_pos;\n            float3 param_20 = _9099;\n            LightSample _8559 = fa_light_shadowed(param_18, param_19, param_20);\n            float _8567 = max(dot(_8445, _8559.direction), 0.0f);\n            float _8573 = _8559.attenuation * _8559.shadow;\n            float3 _8578 = normalize(_8559.direction + _8385);\n            float _8583 = max(dot(_8445, _8578), 0.0f);\n            float _8588 = max(dot(_8385, _8578), 0.0f);\n            if (fa_light_is_area)\n            {\n                if (_8508.on)\n                {\n                    _8595 = _8508.f90;\n                }\n                else\n                {\n                    _8595 = 1.0f;\n                }\n                int param_21 = _8543;\n                float3 param_22 = fa_world_pos;\n                float3 param_23 = _8445;\n                float3 param_24 = _8385;\n                float3 param_25 = _8485;\n                float3 param_26 = f0;\n                float param_27 = _8595;\n                float param_28 = _8456;\n                float param_29 = _8469;\n                float param_30 = _8573;\n                float3 area = fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n                if (_8508.on)\n                {\n                    FaLayers param_31 = _8508;\n                    float3 param_32 = area;\n                    int param_33 = _8543;\n                    float3 param_34 = _8445;\n                    float3 param_35 = _8385;\n                    float3 param_36 = _8559.direction;\n                    float param_37 = _8469;\n                    float param_38 = _8573;\n                    area = fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38);\n                }\n                lit += area;\n            }\n            else\n            {\n                if (_8508.on)\n                {\n                    FaLayers param_39 = _8508;\n                    float3 param_40 = _8485;\n                    float3 param_41 = f0;\n                    float3 param_42 = _8445;\n                    float3 param_43 = _8385;\n                    float3 param_44 = _8559.direction;\n                    float3 param_45 = _8578;\n                    float param_46 = _8567;\n                    float param_47 = _8469;\n                    float param_48 = _8583;\n                    float param_49 = _8588;\n                    float param_50 = _8460;\n                    float param_51 = _8464;\n                    int param_52 = _8543;\n                    lit += (fa_layers_light(param_39, param_40, param_41, param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51) * ((fa_light_rgb(param_52) * fa_light_tint) * _8573));\n                }\n                else\n                {\n                    float _8697 = ((_8583 * _8583) * (_8464 - 1.0f)) + 1.0f;\n                    int param_53 = _8543;\n                    lit += (((_8485 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _8588, 5.0f))) * (((_8464 / ((3.1415927410125732421875f * _8697) * _8697)) * (0.5f / max(lerp((2.0f * _8567) * _8469, _8567 + _8469, _8460), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _8567))) * (fa_light_rgb(param_53) * fa_light_tint)) * (_8567 * _8573));\n                }\n            }\n        }\n        if (_8508.on)\n        {\n            FaLayers param_54 = _8508;\n            float3 param_55 = _8445;\n            float3 param_56 = _8385;\n            float3 param_57 = f0;\n            float param_58 = _8456;\n            float param_59 = _9135;\n            lit += fa_layers_ibl(param_54, param_55, param_56, param_57, param_58, param_59);\n        }\n        else\n        {\n            float3 param_60 = _8445;\n            float3 param_61 = _8385;\n            float3 param_62 = f0;\n            float param_63 = _8456;\n            lit += (fa_sky_reflection(param_60, param_61, param_62, param_63) * _9135);\n        }\n        if (_8476 > 0.0f)\n        {\n            float _8795;\n            if (_8508.on)\n            {\n                _8795 = _8508.f90;\n            }\n            else\n            {\n                _8795 = 1.0f;\n            }\n            float _8803;\n            if (_8508.on)\n            {\n                _8803 = _8508.base_scale;\n            }\n            else\n            {\n                _8803 = 1.0f;\n            }\n            Surface _9252 = { _9130, _9131, _9132, _9133, _9134, _9135, _9136, _9137, _9138, _9139, _9140, _9141, _9142, _9143, _9144, _9145, _9146, _9147, _9148, _9149 };\n            Surface param_64 = _9252;\n            float3 param_65 = _8445;\n            float3 param_66 = _8385;\n            float param_67 = _8456;\n            float3 param_68 = f0;\n            float param_69 = _8795;\n            float param_70 = _8803;\n            float param_71 = _8476;\n            float param_72 = fa_tr_blend;\n            float3 _8827 = fa_transmitted(param_64, param_65, param_66, param_67, param_68, param_69, param_70, param_71, param_72);\n            fa_tr_blend = param_72;\n            lit += _8827;\n        }\n        result = lit;\n    }\n    float3 _8834 = result;\n    float3 _8835 = _8834 + _9136;\n    result = _8835;\n    float3 param_73 = _8835;\n    float3 param_74 = fa_world_pos;\n    result = fa_shadow_debug(param_73, param_74);\n    bool _8844 = _602_fa_fog.w > 0.0f;\n    bool _8851;\n    if (!_8844)\n    {\n        _8851 = _602_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _8851 = _8844;\n    }\n    if (_8851)\n    {\n        float3 _8860 = fa_world_pos - _602_fa_camera_pos.xyz;\n        float _8866 = dot(_8860, _602_fa_fog_c.xyz);\n        bool _8870 = _602_fa_fog_c.w > 0.5f;\n        float _8871;\n        if (_8870)\n        {\n            _8871 = _8866;\n        }\n        else\n        {\n            _8871 = length(_8860);\n        }\n        float _8883 = _8871 - _602_fa_fog_b.x;\n        if (_8883 > 0.0f)\n        {\n            float _8892 = _602_fa_fog.w * _8883;\n            float tau = _8892 * _8892;\n            if (_602_fa_fog_b.y > 0.0f)\n            {\n                float _8908;\n                if (_8870)\n                {\n                    _8908 = fa_world_pos.y - (_602_fa_fog_c.y * _8866);\n                }\n                else\n                {\n                    _8908 = _602_fa_camera_pos.y;\n                }\n                float _8929 = lerp(_8908, fa_world_pos.y, clamp(_602_fa_fog_b.x / _8871, 0.0f, 1.0f));\n                float _8933 = fa_world_pos.y - _8929;\n                float _8938 = _8929 - _602_fa_fog_b.z;\n                float _8943 = fa_world_pos.y - _602_fa_fog_b.z;\n                bool _8946 = _8938 <= 0.0f;\n                bool _8947 = !_8946;\n                bool _8953;\n                if (_8947)\n                {\n                    _8953 = _602_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _8953 = _8946;\n                }\n                float _8954;\n                if (_8953)\n                {\n                    _8954 = _602_fa_fog_b.y;\n                }\n                else\n                {\n                    _8954 = _602_fa_fog_b.y * exp(-min(_602_fa_fog_b.w * _8938, 80.0f));\n                }\n                bool _8981;\n                if (_8947)\n                {\n                    _8981 = _602_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _8981 = _8946;\n                }\n                float _8982;\n                if (_8981)\n                {\n                    _8982 = _602_fa_fog_b.y * _8938;\n                }\n                else\n                {\n                    _8982 = (_602_fa_fog_b.y * (1.0f - exp(-min(_602_fa_fog_b.w * _8938, 80.0f)))) / _602_fa_fog_b.w;\n                }\n                bool _9007 = _8943 <= 0.0f;\n                bool _9014;\n                if (!_9007)\n                {\n                    _9014 = _602_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _9014 = _9007;\n                }\n                float _9015;\n                if (_9014)\n                {\n                    _9015 = _602_fa_fog_b.y * _8943;\n                }\n                else\n                {\n                    _9015 = (_602_fa_fog_b.y * (1.0f - exp(-min(_602_fa_fog_b.w * _8943, 80.0f)))) / _602_fa_fog_b.w;\n                }\n                float _9042;\n                if (abs(_8933) < 0.001000000047497451305389404296875f)\n                {\n                    _9042 = _8954;\n                }\n                else\n                {\n                    _9042 = (_9015 - _8982) / _8933;\n                }\n                tau += (_8883 * max(_9042, 0.0f));\n            }\n            result = lerp(result, _602_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    if (fa_tr_blend > 0.0f)\n    {\n        float _9078 = 1.0f - fa_tr_blend;\n        result /= _9078.xxx;\n        _9131 *= _9078;\n    }\n    fa_frag_color = float4(result, _9131);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_602",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2346",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_8421",
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
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 6
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
              "hlsl_register_t_n": 7
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
              "hlsl_register_t_n": 8
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
              "hlsl_register_t_n": 9
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
              "hlsl_register_t_n": 10
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
              "hlsl_register_t_n": 11
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
              "hlsl_register_t_n": 12
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
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 2
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
            "sampler_slot": 10
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10
          },
          {
            "slot": 11,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1
          },
          {
            "slot": 12,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _390 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _390;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _397 = _273.world_pos;\n    fa_world_pos = _397;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_397, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _4559[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _602_fa_camera_pos : packoffset(c0);\n    float4 _602_fa_ambient : packoffset(c1);\n    float4 _602_fa_base_color : packoffset(c2);\n    float4 _602_fa_emissive : packoffset(c3);\n    float4 _602_fa_model_emissive : packoffset(c4);\n    float4 _602_fa_pbr : packoffset(c5);\n    float4 _602_fa_maps : packoffset(c6);\n    float4 _602_fa_fog : packoffset(c7);\n    float4 _602_fa_fog_b : packoffset(c8);\n    float4 _602_fa_fog_c : packoffset(c9);\n    float4 _602_fa_counts : packoffset(c10);\n    float4 _602_fa_env_sky : packoffset(c11);\n    float4 _602_fa_env_horizon : packoffset(c12);\n    float4 _602_fa_time : packoffset(c13);\n    float4 _602_fa_cl_vpx : packoffset(c14);\n    float4 _602_fa_cl_vpy : packoffset(c15);\n    float4 _602_fa_cl_vpw : packoffset(c16);\n    float4 _602_fa_cl_fwd : packoffset(c17);\n    float4 _602_fa_cl_grid : packoffset(c18);\n    float4 _602_fa_cl_info : packoffset(c19);\n    float4 _602_fa_layers_a : packoffset(c20);\n    float4 _602_fa_layers_b : packoffset(c21);\n    float4 _602_fa_layers_c : packoffset(c22);\n    float4 _602_fa_layers_d : packoffset(c23);\n    float4 _602_fa_ct_a : packoffset(c24);\n    float4 _602_fa_ct_b : packoffset(c25);\n    float4 _602_fa_ct_vpx : packoffset(c26);\n    float4 _602_fa_ct_vpy : packoffset(c27);\n    float4 _602_fa_ct_vpw : packoffset(c28);\n    float4 _602_fa_ct_fwd : packoffset(c29);\n    float4 _602_fa_tr_a : packoffset(c30);\n    float4 _602_fa_tr_b : packoffset(c31);\n    float4 _602_fa_probe_sh[9] : packoffset(c32);\n    float4 _602_fa_atlas : packoffset(c41);\n    float4 _602_fa_rpa_tile : packoffset(c42);\n    float4 _602_fa_rpa_pos : packoffset(c43);\n    float4 _602_fa_rpa_bx : packoffset(c44);\n    float4 _602_fa_rpa_by : packoffset(c45);\n    float4 _602_fa_rpa_bz : packoffset(c46);\n    float4 _602_fa_rpb_tile : packoffset(c47);\n    float4 _602_fa_rpb_pos : packoffset(c48);\n    float4 _602_fa_rpb_bx : packoffset(c49);\n    float4 _602_fa_rpb_by : packoffset(c50);\n    float4 _602_fa_rpb_bz : packoffset(c51);\n    float4 _602_fa_gi : packoffset(c52);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2346_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2346_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2346_fa_shadow_info[4] : packoffset(c20);\n    float4 _2346_fa_shadow_split : packoffset(c24);\n    float4 _2346_fa_shadow_cfg : packoffset(c25);\n    float4 _2346_fa_shadow_bias : packoffset(c26);\n    float4 _2346_fa_shadow_eye : packoffset(c27);\n    float4 _2346_fa_shadow_fwd : packoffset(c28);\n    float4 _2346_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _8421_alphaCutoff : packoffset(c0);\n    float _8421_fa_pad0 : packoffset(c0.y);\n    float _8421_fa_pad1 : packoffset(c0.z);\n    float _8421_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t11);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_screen_tex : register(t12);\nTexture2D<float4> fa_probe_atlas : register(t7);\nTexture2D<float4> mask : register(t6);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t10);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1628 = _602_fa_cl_info.x < 0.0f;\n    bool _1635;\n    if (!_1628)\n    {\n        _1635 = _602_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1635 = _1628;\n    }\n    bool _1643;\n    if (!_1635)\n    {\n        _1643 = _602_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1643 = _1635;\n    }\n    bool _1650;\n    if (!_1643)\n    {\n        _1650 = _602_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1650 = _1643;\n    }\n    bool _1657;\n    if (!_1650)\n    {\n        _1657 = _602_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1657 = _1650;\n    }\n    if (_1657)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1667 = float4(world_pos, 1.0f);\n    float _1673 = dot(_602_fa_cl_vpw, _1667);\n    if (!(_1673 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1695 = float2(dot(_602_fa_cl_vpx, _1667), dot(_602_fa_cl_vpy, _1667)) / _1673.xx;\n    int _1699 = int(_602_fa_cl_grid.x);\n    int _1703 = int(_602_fa_cl_grid.y);\n    int param = (int(_602_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_602_fa_cl_fwd.xyz, world_pos) + _602_fa_cl_fwd.w, _602_fa_cl_grid.w) / _602_fa_cl_grid.w) * _602_fa_cl_grid.z)), 0, int(_602_fa_cl_info.y) - 1) * _1703) + clamp(int(floor(((_1695.y * 0.5f) + 0.5f) * _602_fa_cl_grid.y)), 0, _1703 - 1)) * _1699)) + clamp(int(floor(((_1695.x * 0.5f) + 0.5f) * _602_fa_cl_grid.x)), 0, _1699 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1779 = fa_cluster_texel(param);\n    return int2(int(_1779.x), int(_1779.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_602_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _6193 = fa_cluster_lookup(param);\n    fa_cl_slot = _6193.x;\n    fa_cl_local = _6193.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _7363 = fa_linear_to_srgb(param);\n        c = _7363;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _7371 = fa_srgb_to_linear(param_1);\n            c = _7371;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _534;\n    if (i.front_facing)\n    {\n        _534 = i.world_normal;\n    }\n    else\n    {\n        _534 = -i.world_normal;\n    }\n    float3 _558 = normalize(i.world_tangent.xyz - (_534 * dot(_534, i.world_tangent.xyz)));\n    float3 _585 = normalize(((_558 * m.x) + ((cross(_534, _558) * i.world_tangent.w) * m.y)) + (_534 * m.z));\n    float3 _588;\n    if (i.front_facing)\n    {\n        _588 = _585;\n    }\n    else\n    {\n        _588 = -_585;\n    }\n    return _588;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _602_fa_env_horizon.w);\n    float param = _602_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _7403 = fa_tex_fix(param_2, param_3);\n    float4 _9700 = base_t;\n    _9700.x = _7403.x;\n    _9700.y = _7403.y;\n    _9700.z = _7403.z;\n    base_t = _9700;\n    float4 _7417 = (_9700 * _602_fa_base_color) * i.vertex_color;\n    float3 _9460 = i.world_normal;\n    if (_602_fa_maps.z > 0.5f)\n    {\n        float param_4 = _602_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _602_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _7451 = fa_tex_fix(param_6, param_7);\n        float3 _7454 = (_7451 * 2.0f) - 1.0f.xxx;\n        float2 _7459 = _7454.xy * _602_fa_maps.x;\n        float3 _9708 = _7454;\n        _9708.x = _7459.x;\n        _9708.y = _7459.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _9708;\n        _9460 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _602_fa_env_horizon.w);\n    float param_10 = _602_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _7489 = fa_tex_fix(param_12, param_13);\n    float4 _9711 = mrt;\n    _9711.x = _7489.x;\n    _9711.y = _7489.y;\n    _9711.z = _7489.z;\n    mrt = _9711;\n    float4 _7519 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _602_fa_env_horizon.w);\n    float param_14 = _602_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _7519.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _7530 = fa_tex_fix(param_16, param_17);\n    float param_18 = _602_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _602_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _7562 = fa_tex_fix(param_20, param_21);\n    float _9465 = _602_fa_layers_a.x;\n    float _9466 = _602_fa_layers_a.y;\n    float _9469 = _602_fa_layers_a.z;\n    float _9468 = _602_fa_layers_b.w;\n    float _9471 = _602_fa_layers_c.x;\n    if (_602_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_602_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _9465 *= _7530.y;\n            _9466 *= _7530.z;\n            _9468 *= _7519.w;\n        }\n        if (_602_fa_layers_c.z > 1.5f)\n        {\n            _9469 *= mrt.x;\n            _9471 *= mrt.w;\n        }\n    }\n    Surface _9498 = { _7417.xyz, _7417.w, _9460, clamp(_602_fa_pbr.x * _7489.z, 0.0f, 1.0f), clamp(_602_fa_pbr.y * _7489.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_602_fa_maps.y * (_7530.x - 1.0f)), _602_fa_emissive.xyz + (_602_fa_model_emissive.xyz * _7562), _9465, _9466, _602_fa_layers_b.xyz, _9468, _9469, _602_fa_layers_a.w, _9471, _602_fa_layers_c.y, _602_fa_layers_d.xyz, _602_fa_tr_a.x, _602_fa_tr_a.y, _602_fa_tr_b.xyz, _602_fa_tr_a.z };\n    return _9498;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1859 = rect.zw - rect.xy;\n    float2 _1863 = _1859 * atlas;\n    float2 _1867 = ddx * _1863;\n    float2 _1871 = ddy * _1863;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1859), clamp(0.5f * log2(max(max(dot(_1867, _1867), dot(_1871, _1871)), 9.9999999392252902907785028219223e-09f)), 0.0f, 3.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1904 = _602_fa_counts.y < 0.5f;\n    bool _1911;\n    if (!_1904)\n    {\n        _1911 = _602_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1911 = _1904;\n    }\n    if (_1911)\n    {\n        return;\n    }\n    float3 _1917 = ddx(world_pos);\n    float3 _1920 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1924 = fa_cluster_texel(param);\n    int _1928 = int(_1924.w);\n    if (_1928 < 1)\n    {\n        return;\n    }\n    int _1938 = int(_602_fa_counts.y + 0.5f);\n    int param_1 = _1938;\n    float4 _1942 = fa_light_texel(param_1);\n    float2 _1945 = _1942.yz;\n    int _1949 = int(_1942.w);\n    int param_2 = _1938 + 1;\n    float4 _1954 = fa_light_texel(param_2);\n    float _1955 = _1954.x;\n    int _1961 = int(_602_fa_counts.w + 0.5f) - 1;\n    int _1965 = int(_1924.z);\n    float3 _2230;\n    for (int k = 0; k < _1928; k++)\n    {\n        int _1978 = _1965 + k;\n        int param_3 = _1949 + (_1978 >> 2);\n        int _1995 = (_1938 + 2) + (int(fa_light_texel(param_3)[_1978 & 3]) * 7);\n        int param_4 = _1995 + 6;\n        float4 _2000 = fa_light_texel(param_4);\n        if (((int(_2000.w + 0.5f) >> _1961) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1995;\n        float4 _2015 = fa_light_texel(param_5);\n        int param_6 = _1995 + 1;\n        float4 _2020 = fa_light_texel(param_6);\n        int param_7 = _1995 + 2;\n        float4 _2025 = fa_light_texel(param_7);\n        float3 _2028 = _2015.xyz;\n        float _2033 = dot(_2028, world_pos) + _2015.w;\n        float3 _2035 = _2020.xyz;\n        float _2040 = dot(_2035, world_pos) + _2020.w;\n        float3 _2042 = _2025.xyz;\n        float _2047 = dot(_2042, world_pos) + _2025.w;\n        bool _2052 = abs(_2033) > 0.5f;\n        bool _2060;\n        if (!_2052)\n        {\n            _2060 = abs(_2040) > 0.5f;\n        }\n        else\n        {\n            _2060 = _2052;\n        }\n        bool _2068;\n        if (!_2060)\n        {\n            _2068 = abs(_2047) > 0.5f;\n        }\n        else\n        {\n            _2068 = _2060;\n        }\n        if (_2068)\n        {\n            continue;\n        }\n        float _2083 = clamp(dot(geo_normal, normalize(_2042)) * _2000.z, 0.0f, 1.0f);\n        if (_2083 <= 0.0f)\n        {\n            continue;\n        }\n        float _2103 = (clamp((0.5f - abs(_2047)) * 10.0f, 0.0f, 1.0f) * _2083) * _2000.x;\n        float2 _2111 = float2(_2033 + 0.5f, 0.5f - _2040);\n        float2 _2121 = float2(dot(_2028, _1917), dot(_2035, _1917));\n        float2 _2131 = float2(dot(_2028, _1920), dot(_2035, _1920));\n        int param_8 = _1995 + 5;\n        float4 _2136 = fa_light_texel(param_8);\n        int param_9 = _1995 + 3;\n        float4 _2141 = fa_light_texel(param_9);\n        int param_10 = _1995 + 4;\n        float4 _2146 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _2136.xyz;\n        bool _2156 = _2141.z > _2141.x;\n        if (_2156)\n        {\n            float4 param_11 = _2141;\n            float2 param_12 = _2111;\n            float2 param_13 = _1945;\n            float2 param_14 = _2121;\n            float2 param_15 = _2131;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1955 > 0.5f) && (_1955 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _2182 = fa_dc_to_linear(param_16);\n                float4 _9548 = tx;\n                _9548.x = _2182.x;\n                _9548.y = _2182.y;\n                _9548.z = _2182.z;\n                tx = _9548;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_2103 * tex_a) * _2136.w, 0.0f, 1.0f).xxx);\n        if (_2146.z > _2146.x)\n        {\n            float4 param_17 = _2146;\n            float2 param_18 = _2111;\n            float2 param_19 = _1945;\n            float2 param_20 = _2121;\n            float2 param_21 = _2131;\n            float4 _2226 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1955 > 1.5f)\n            {\n                float3 param_22 = _2226.xyz;\n                float3 _2236 = fa_dc_to_srgb(param_22);\n                _2230 = _2236;\n            }\n            else\n            {\n                _2230 = _2226.xyz;\n            }\n            float3 _2245 = (_2230 * 2.0f) - 1.0f.xxx;\n            float2 _2250 = _2245.xy * _2000.y;\n            float3 _2272 = (normalize(_2028) * _2250.x) + (normalize(_2035) * _2250.y);\n            float3 _2275 = normalize(normal);\n            normal = normalize(lerp(_2275, normalize((_2275 * max(_2245.z, 0.0500000007450580596923828125f)) + (_2272 - (_2275 * dot(_2275, _2272)))), clamp(_2103 * (_2156 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nvoid fa_lod_dither()\n{\n    if (_602_fa_gi.w != 0.0f)\n    {\n        float _624 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n        bool _627;\n        if (_602_fa_gi.w > 0.0f)\n        {\n            _627 = _624 >= _602_fa_gi.w;\n        }\n        else\n        {\n            _627 = _624 < (-_602_fa_gi.w);\n        }\n        if (_627)\n        {\n            discard;\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4484 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _4492 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _4495 = int(_4484);\n    int _4498 = int(_4492);\n    float _4508 = _4492 - float(_4498);\n    int _4563 = (_4495 * 9) + _4498;\n    int _4583 = ((_4495 + 1) * 9) + _4498;\n    return lerp(lerp(_4559[_4563], _4559[_4563 + 1], _4508), lerp(_4559[_4583], _4559[_4583 + 1], _4508), _4484 - float(_4495));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _9383 = false;\n    float _9384 = 1.0f;\n    float _9385 = 1.0f;\n    float _9386 = 1.0f;\n    float _9387 = 0.0f;\n    float _9388 = 0.0f;\n    float _9389 = 0.0f;\n    float _9390 = 0.0f;\n    float _9392 = 1.0f;\n    bool _9393 = false;\n    float3 _9394 = 0.0f.xxx;\n    float _9395 = 1.0f;\n    float _9396 = 1.0f;\n    float _9397 = 1.0f;\n    float _9398 = 0.0f;\n    float _9399 = 0.0f;\n    float3 _9400 = float3(1.0f, 0.0f, 0.0f);\n    float3 _9401 = float3(0.0f, 0.0f, 1.0f);\n    float _9402 = 1.0f;\n    float _9403 = 1.0f;\n    float _4634 = clamp(s.specular, 0.0f, 1.0f);\n    float _4638 = clamp(s.ior, 1.0f, 3.0f);\n    bool _4643 = (_4634 != 1.0f) || (_4638 != 1.5f);\n    bool _4652;\n    if (!_4643)\n    {\n        _4652 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _4652 = _4643;\n    }\n    if (_4652)\n    {\n        float _4660 = (_4638 - 1.0f) / (_4638 + 1.0f);\n        f0 = lerp(min((_4660 * _4660).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _4634, s.albedo, metallic.xxx);\n        _9384 = lerp(_4634, 1.0f, metallic);\n        _9383 = true;\n    }\n    float _4687 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_4687 > 0.0f)\n    {\n        float _4695 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _9387 = _4687;\n        _9388 = _4695;\n        float _4702 = _4695 * _4695;\n        _9389 = _4702;\n        _9390 = _4702 * _4702;\n        float _4714 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _9392 = _4714;\n        _9385 = 1.0f - (_4687 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _4714, 0.0f, 1.0f), 5.0f))));\n        _9383 = true;\n    }\n    float3 _4733 = max(s.sheen_color, 0.0f.xxx);\n    float _4742 = max(_4733.x, max(_4733.y, _4733.z));\n    if (_4742 > 0.0f)\n    {\n        float _4750 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _9393 = true;\n        _9394 = _4733;\n        _9395 = _4750;\n        _9396 = _4750 * _4750;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _4750;\n        float _4767 = fa_sheen_albedo(param, param_1);\n        _9398 = _4767;\n        _9397 = 1.0f - min(_4742 * _4767, 1.0f);\n        _9383 = true;\n    }\n    _9386 = _9385 * _9397;\n    float _4786 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_4786 != 0.0f)\n    {\n        float3 _4801 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _4801;\n        if (dot(_4801, _4801) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _4813 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_4813.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _4813.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _4813.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _4817 = t;\n        float3 _4818 = normalize(_4817);\n        t = _4818;\n        float3 _4843 = normalize((_4818 * cos(s.anisotropy_rotation)) + ((cross(n, _4818) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _9400 = _4843;\n        _9401 = cross(n, _4843);\n        float _4853 = roughness * roughness;\n        float _4859 = lerp(_4853, 1.0f, _4786 * _4786);\n        bool _4861 = _4786 > 0.0f;\n        _9402 = _4861 ? _4859 : _4853;\n        _9403 = _4861 ? _4853 : _4859;\n        _9399 = _4786;\n        _9383 = true;\n    }\n    FaLayers _9425 = { _9383, _9384, _9385, _9386, _9387, _9388, _9389, _9390, i.world_normal, _9392, _9393, _9394, _9395, _9396, _9397, _9398, _9399, _9400, _9401, _9402, _9403 };\n    return _9425;\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3712_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3712_dummy_parameter)));\n}\n\nfloat3 fa_probe_sh_coef(float2 origin, float res, int k)\n{\n    float3 v = fa_probe_atlas.SampleLevel(fa_env_smp, (origin + float2(float(k) + 0.5f, res + 2.5f)) / fa_atlas_size(), 0.0f).xyz;\n    if (_602_fa_atlas.y > 0.5f)\n    {\n        v = ((v * 255.0f) - 128.0f.xxx) * 0.03149606287479400634765625f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3653 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3653;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    float _4265 = (1.0f - _602_fa_rpa_tile.w) - _602_fa_rpb_tile.w;\n    float3 amb = 0.0f.xxx;\n    bool _4270 = _602_fa_env_sky.w > 0.5f;\n    float3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = 0.0f.xxx;\n    }\n    if (_4265 > 0.0005000000237487256526947021484375f)\n    {\n        if (_4270)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _602_fa_atlas.zw;\n                float param_1 = 128.0f;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4265;\n            }\n        }\n        else\n        {\n            amb = _602_fa_ambient.xyz * _4265;\n        }\n    }\n    bool _4321 = _602_fa_rpa_tile.w > 0.0f;\n    if (_4321)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _602_fa_rpa_tile.xy;\n            float param_4 = _602_fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * _602_fa_rpa_tile.w);\n        }\n    }\n    bool _4352 = _602_fa_rpb_tile.w > 0.0f;\n    if (_4352)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _602_fa_rpb_tile.xy;\n            float param_7 = _602_fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * _602_fa_rpb_tile.w);\n        }\n    }\n    if ((_4270 || _4321) || _4352)\n    {\n        float3 param_9[9] = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nfloat4 fa_gi_fetch(float2 texel)\n{\n    return fa_probe_atlas.SampleLevel(fa_env_smp, texel / fa_atlas_size(), 0.0f);\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3673 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3676 = _3673.x;\n    float _3678 = _3673.z;\n    float2 e = float2(_3676, _3678);\n    if (_3673.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3678)) * ((_3676 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3676)) * ((_3678 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat3 fa_gi_grid(int rec, float3 n, float3 v, out float cover)\n{\n    cover = 0.0f;\n    int param = rec;\n    float4 _7672 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    float4 _7677 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    float4 _7682 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    float4 _7687 = fa_light_texel(param_3);\n    bool _7690 = _7687.z < 0.5f;\n    bool _7698;\n    if (!_7690)\n    {\n        _7698 = fa_atlas_size().y < 1155.0f;\n    }\n    else\n    {\n        _7698 = _7690;\n    }\n    if (_7698)\n    {\n        return 0.0f.xxx;\n    }\n    float _7705 = max(_7672.w, 9.9999997473787516355514526367188e-05f);\n    float3 _7708 = _7677.xyz;\n    float3 _7712 = _7672.xyz;\n    float3 _7716 = (fa_world_pos - _7712) / _7705.xxx;\n    float3 _7725 = min(_7716 + 0.5f.xxx, (_7708 - 0.5f.xxx) - _7716);\n    float _7734 = min(_7725.x, min(_7725.y, _7725.z));\n    if (!(_7734 > 0.0f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _7749 = _7708 - 1.0f.xxx;\n    float3 _7750 = clamp(_7716, 0.0f.xxx, _7749);\n    float3 _7758 = min(floor(_7750), max(_7708 - 2.0f.xxx, 0.0f.xxx));\n    float3 _7762 = _7750 - _7758;\n    float3 _7773 = fa_world_pos + (((n * 0.800000011920928955078125f) + (v * 0.20000000298023223876953125f)) * (0.20000000298023223876953125f * _7705));\n    int _7778 = int(_7682.y + 0.5f);\n    float _7783 = 0.3257350027561187744140625f * n.y;\n    float _7787 = 0.3257350027561187744140625f * n.z;\n    float _7791 = 0.3257350027561187744140625f * n.x;\n    float _7798 = (0.2731371223926544189453125f * n.x) * n.y;\n    float _7805 = (0.2731371223926544189453125f * n.y) * n.z;\n    float _7814 = 0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f);\n    float _7821 = (0.2731371223926544189453125f * n.x) * n.z;\n    float _7834 = 0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y));\n    float3 acc = 0.0f.xxx;\n    float wsum = 0.0f;\n    int _7841 = 8 + int(_7687.w);\n    float _7868;\n    float _7881;\n    float _7895;\n    for (int k = 0; k < _7841; k++)\n    {\n        float _7854 = float(k & 1);\n        float _7858 = float((k >> 1) & 1);\n        float _7862 = float((k >> 2) & 1);\n        if (_7854 > 0.5f)\n        {\n            _7868 = _7762.x;\n        }\n        else\n        {\n            _7868 = 1.0f - _7762.x;\n        }\n        if (_7858 > 0.5f)\n        {\n            _7881 = _7762.y;\n        }\n        else\n        {\n            _7881 = 1.0f - _7762.y;\n        }\n        if (_7862 > 0.5f)\n        {\n            _7895 = _7762.z;\n        }\n        else\n        {\n            _7895 = 1.0f - _7762.z;\n        }\n        float _7905 = (_7868 * _7881) * _7895;\n        if (!(_7905 > 0.0f))\n        {\n            continue;\n        }\n        float3 _7918 = min(_7758 + float3(_7854, _7858, _7862), _7749);\n        int _7938 = int(((_7682.x + _7918.x) + (_7677.x * (_7918.y + (_7677.y * _7918.z)))) + 0.5f);\n        float2 _7953 = float2(float(_7938 % _7778) * 10.0f, 1024.0f + (float(_7938 / _7778) * 11.0f));\n        float2 param_4 = _7953 + float2(9.5f, 10.5f);\n        float4 _7961 = fa_gi_fetch(param_4);\n        bool _7964 = _7961.y < 0.5f;\n        bool _7973;\n        if (!_7964)\n        {\n            _7973 = _7961.x > _7687.y;\n        }\n        else\n        {\n            _7973 = _7964;\n        }\n        if (_7973)\n        {\n            continue;\n        }\n        float3 _7985 = _7773 - (_7712 + (_7918 * _7705));\n        float _7988 = length(_7985);\n        float3 _7994 = _7985 / max(_7988, 9.9999997473787516355514526367188e-05f).xxx;\n        float _8004 = max(9.9999997473787516355514526367188e-05f, (dot(-_7994, n) + 1.0f) * 0.5f);\n        float w = _7905 * (_8004 * _8004);\n        float3 param_5 = _7994;\n        float2 param_6 = (_7953 + 1.0f.xx) + (((fa_oct_encode(param_5) * 0.5f) + 0.5f.xx) * 8.0f);\n        float4 _8023 = fa_gi_fetch(param_6);\n        float _8030 = _7988 / max(_7682.z, 9.9999997473787516355514526367188e-05f);\n        float _8033 = _8023.x;\n        if (_8030 > _8033)\n        {\n            float _8046 = max(_8023.y - (_8033 * _8033), 0.0f);\n            float _8051 = _8030 - _8033;\n            float _8060 = _8046 / max(_8046 + (_8051 * _8051), 9.9999999600419720025001879548654e-13f);\n            w *= ((_8060 * _8060) * _8060);\n        }\n        if (!(w > 0.0f))\n        {\n            continue;\n        }\n        float2 param_7 = _7953 + float2(0.5f, 10.5f);\n        float2 param_8 = _7953 + float2(1.5f, 10.5f);\n        float2 param_9 = _7953 + float2(2.5f, 10.5f);\n        float2 param_10 = _7953 + float2(3.5f, 10.5f);\n        float2 param_11 = _7953 + float2(4.5f, 10.5f);\n        float2 param_12 = _7953 + float2(5.5f, 10.5f);\n        float2 param_13 = _7953 + float2(6.5f, 10.5f);\n        float2 param_14 = _7953 + float2(7.5f, 10.5f);\n        float2 param_15 = _7953 + float2(8.5f, 10.5f);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375f) + (fa_gi_fetch(param_8).xyz * _7783)) + (fa_gi_fetch(param_9).xyz * _7787)) + (fa_gi_fetch(param_10).xyz * _7791)) + (fa_gi_fetch(param_11).xyz * _7798)) + (fa_gi_fetch(param_12).xyz * _7805)) + (fa_gi_fetch(param_13).xyz * _7814)) + (fa_gi_fetch(param_14).xyz * _7821)) + (fa_gi_fetch(param_15).xyz * _7834)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06f))\n    {\n        return 0.0f.xxx;\n    }\n    cover = smoothstep(0.0f, 1.0f, clamp(_7734 * 2.0f, 0.0f, 1.0f)) * smoothstep(0.0f, 0.0199999995529651641845703125f, wsum);\n    float _8184;\n    if (_602_fa_gi.z > 0.5f)\n    {\n        _8184 = _7687.x;\n    }\n    else\n    {\n        _8184 = 1.0f;\n    }\n    return max(acc / wsum.xxx, 0.0f.xxx) * (_7682.w * _8184);\n}\n\nfloat3 fa_gi_light(float3 n, inout float left)\n{\n    left = 1.0f;\n    float3 acc = 0.0f.xxx;\n    float3 _8208 = normalize(_602_fa_camera_pos.xyz - fa_world_pos);\n    int _8213 = int(_602_fa_gi.x + 0.5f);\n    int _8218 = int(_602_fa_gi.y + 0.5f);\n    float param_3;\n    for (int k = 0; (k < _8218) && (k < 8); k++)\n    {\n        int param = _8213 + (4 * k);\n        float3 param_1 = n;\n        float3 param_2 = _8208;\n        float3 _8243 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _8248 = param_3 * left;\n        acc += (_8243 * _8248);\n        left -= _8248;\n        if (left < 0.001000000047497451305389404296875f)\n        {\n            left = 0.0f;\n            break;\n        }\n    }\n    return acc;\n}\n\nfloat3 fa_realtime_or_ambient(float3 n)\n{\n    float3 gi = 0.0f.xxx;\n    float left = 1.0f;\n    if (_602_fa_gi.y > 0.5f)\n    {\n        float3 param = n;\n        float param_1;\n        float3 _8277 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _8277;\n    }\n    if (left <= 0.0f)\n    {\n        return gi;\n    }\n    float3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_602_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _602_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_602_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_602_fa_cl_info.x) + int(_602_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_602_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _6163;\n    if (fa_lm.z > 0.5f)\n    {\n        _6163 = 0.0f;\n    }\n    else\n    {\n        _6163 = 1.0f - clamp(_602_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _6174 = _6163 < 1.0f;\n    bool _6180;\n    if (_6174)\n    {\n        int param = li;\n        _6180 = fa_light_baked(param);\n    }\n    else\n    {\n        _6180 = _6174;\n    }\n    return _6180 ? _6163 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _758_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _758_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _877 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _890 = (c - (ru * hx)) - p;\n        float3 _896 = ru * (2.0f * hx);\n        float _902 = max(dot(_896, _896), 9.9999999392252902907785028219223e-09f);\n        float _906 = dot(_890, _896);\n        float t = clamp((-_906) / _902, 0.0f, 1.0f);\n        if (_877)\n        {\n            float _921 = dot(r, _896);\n            float _927 = _902 - (_921 * _921);\n            if (abs(_927) > (9.9999997473787516355514526367188e-06f * _902))\n            {\n                t = clamp(((dot(r, _890) * _921) - _906) / _927, 0.0f, 1.0f);\n            }\n        }\n        return (p + _890) + (_896 * t);\n    }\n    float3 q = p;\n    float _959 = dot(r, axis);\n    bool _967;\n    if (_877)\n    {\n        _967 = abs(_959) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _967 = _877;\n    }\n    if (_967)\n    {\n        float _977 = dot(c - p, axis) / _959;\n        if (_977 > 0.0f)\n        {\n            q = p + (r * _977);\n        }\n    }\n    float3 _990 = q - c;\n    float2 xy = float2(dot(_990, ru), dot(_990, uu));\n    if (shape > 0.5f)\n    {\n        float _1005 = length(xy);\n        if (_1005 > hx)\n        {\n            xy *= (hx / _1005);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _644 = abs(d);\n    float _646 = _644.x;\n    float _648 = _644.y;\n    bool _649 = _646 >= _648;\n    bool _657;\n    if (_649)\n    {\n        _657 = _646 >= _644.z;\n    }\n    else\n    {\n        _657 = _649;\n    }\n    int _658;\n    if (_657)\n    {\n        _658 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _672;\n        if (_648 >= _644.z)\n        {\n            _672 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _672 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _658 = _672;\n    }\n    return _658;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _797 = dot(d, right);\n    float _801 = dot(d, up);\n    float _812;\n    if (((_797 * _797) + (_801 * _801)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _812 = atan2(_801, _797) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _812 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_812 - floor(_812)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _1043 = fa_light_base(param);\n    bool _1047 = _602_fa_ambient.w > 4.5f;\n    int param_1 = _1043;\n    float4 _1051 = fa_light_texel(param_1);\n    int param_2 = _1043 + 1;\n    float4 _1056 = fa_light_texel(param_2);\n    float _1059 = _1056.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _1071 = _1047 && (_1059 > 2.5f);\n    fa_light_is_area = _1071;\n    bool _1073 = _1059 < 0.5f;\n    float3 l;\n    if (_1073)\n    {\n        l = normalize(_1051.xyz);\n        if (_1047)\n        {\n            int param_3 = _1043 + 6;\n            float4 _1087 = fa_light_texel(param_3);\n            if (_1087.z > 0.5f)\n            {\n                int param_4 = _1043 + 4;\n                float4 _1097 = fa_light_texel(param_4);\n                int param_5 = _1043 + 5;\n                float4 _1102 = fa_light_texel(param_5);\n                float2 param_6 = _1087.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _1097.xyz) * _1097.w, (-dot(world_pos, _1102.xyz)) * _1102.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _1132 = _1051.xyz;\n        float3 _1134 = _1132 - world_pos;\n        float3 to_light = _1134;\n        float _1137 = length(_1134);\n        float reach = _1137;\n        bool front = true;\n        if (_1071)\n        {\n            int param_8 = _1043 + 7;\n            reach = max(_1137 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _1043 + 4;\n            float4 _1161 = fa_light_texel(param_9);\n            int param_10 = _1043 + 5;\n            float4 _1166 = fa_light_texel(param_10);\n            int param_11 = _1043 + 6;\n            float4 _1171 = fa_light_texel(param_11);\n            float _1172 = _1171.w;\n            int param_12 = _1043 + 2;\n            float3 _1179 = normalize(fa_light_texel(param_12).xyz);\n            bool _1181 = _1172 > 1.5f;\n            bool _1189;\n            if (!_1181)\n            {\n                _1189 = dot(_1179, to_light) < 0.0f;\n            }\n            else\n            {\n                _1189 = _1181;\n            }\n            front = _1189;\n            float3 r = 0.0f.xxx;\n            float3 _1198 = _602_fa_camera_pos.xyz - world_pos;\n            bool _1202 = dot(n, n) > 0.5f;\n            bool _1210;\n            if (_1202)\n            {\n                _1210 = dot(_1198, _1198) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _1210 = _1202;\n            }\n            if (_1210)\n            {\n                r = reflect(-normalize(_1198), normalize(n));\n            }\n            float3 param_13 = _1132;\n            float3 param_14 = _1179;\n            float3 param_15 = _1161.xyz;\n            float3 param_16 = _1166.xyz;\n            float param_17 = _1161.w;\n            float param_18 = _1166.w;\n            float param_19 = _1172;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1246 = length(to_light);\n        dist = _1246;\n        l = to_light / max(_1246, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1260 = reach / max(_1051.w, 0.001000000047497451305389404296875f);\n        float _1266 = clamp(1.0f - (_1260 * _1260), 0.0f, 1.0f);\n        float _1268;\n        if (front)\n        {\n            _1268 = _1266 * _1266;\n        }\n        else\n        {\n            _1268 = 0.0f;\n        }\n        atten = _1268;\n        bool _1279 = _1059 < 2.5f;\n        if ((_1059 > 1.5f) && _1279)\n        {\n            int param_22 = _1043 + 2;\n            float4 _1287 = fa_light_texel(param_22);\n            float _1297 = _1287.w;\n            int param_23 = _1043 + 3;\n            float4 _1302 = fa_light_texel(param_23);\n            float _1303 = _1302.x;\n            float cos_inner = _1303;\n            if (_1303 > 1.5f)\n            {\n                cos_inner = lerp(_1297, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1297, cos_inner, dot(-l, normalize(_1287.xyz)));\n        }\n        if (_1047 && (_1059 < 1.5f))\n        {\n            int param_24 = _1043 + 6;\n            float4 _1327 = fa_light_texel(param_24);\n            if (_1327.z > 0.5f)\n            {\n                float3 _1335 = -to_light;\n                int param_25 = _1043 + 4;\n                int param_26 = _1043 + 5;\n                float3 _1349 = fa_light_texel(param_25).xyz;\n                float3 _1353 = fa_light_texel(param_26).xyz;\n                float3 _1362 = float3(dot(_1335, _1349), dot(_1335, _1353), dot(_1335, cross(_1349, _1353)));\n                float3 param_27 = _1362;\n                int _1366 = fa_cube_face(param_27);\n                int param_28 = _1366;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1393 = float2(dot(_1362, cross(param_29, param_30)), dot(_1362, param_30)) / max(dot(_1362, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1397 = _1366 / 3;\n                float2 param_31 = _1327.xy + (float2(float(_1366 - (_1397 * 3)), float(_1397)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1393.x), 0.5f - (0.5f * _1393.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1043 + 7;\n            float4 _1427 = fa_light_texel(param_33);\n            if (_1427.z > 0.5f)\n            {\n                int param_34 = _1043 + 2;\n                int param_35 = _1043 + 4;\n                int param_36 = _1043 + 5;\n                float2 param_37 = _1427.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1047 && _1279)\n            {\n                int param_42 = _1043 + 6;\n                float4 _1474 = fa_light_texel(param_42);\n                int param_43 = _1043 + 7;\n                float4 _1479 = fa_light_texel(param_43);\n                bool _1482 = _1474.z > 0.5f;\n                bool _1489;\n                if (!_1482)\n                {\n                    _1489 = _1479.z > 0.5f;\n                }\n                else\n                {\n                    _1489 = _1482;\n                }\n                if (_1489)\n                {\n                    int param_44 = _1043 + 2;\n                    float4 _1496 = fa_light_texel(param_44);\n                    float3 _1500 = normalize(_1496.xyz);\n                    int param_45 = _1043 + 4;\n                    float4 _1505 = fa_light_texel(param_45);\n                    int param_46 = _1043 + 5;\n                    float4 _1510 = fa_light_texel(param_46);\n                    if (_1482)\n                    {\n                        float3 _1518 = -to_light;\n                        float _1525 = _1496.w;\n                        float _1541 = 0.5f / max(dot(_1518, _1500) * (sqrt(max(1.0f - (_1525 * _1525), 0.0f)) / max(_1525, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1474.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1518, _1505.xyz) * _1541), 0.5f - (dot(_1518, _1510.xyz) * _1541));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1479.z > 0.5f)\n                    {\n                        float2 param_49 = _1479.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1500;\n                        float3 param_52 = _1505.xyz;\n                        float3 param_53 = _1510.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _9371 = _1056.xyz * atten;\n    if (_1047)\n    {\n        _9371 *= fa_light_tint;\n    }\n    int _1610;\n    if (_1073)\n    {\n        _1610 = 0;\n    }\n    else\n    {\n        _1610 = ((_1059 > 1.5f) && (_1059 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _9382 = { l, _9371, atten, 1.0f, dist, _1610 };\n    return _9382;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2336;\n    if (i == 0)\n    {\n        _2336 = _2346_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2352;\n        if (i == 1)\n        {\n            _2352 = _2346_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2360;\n            if (i == 2)\n            {\n                _2360 = _2346_fa_shadow_split.z;\n            }\n            else\n            {\n                _2360 = _2346_fa_shadow_split.w;\n            }\n            _2352 = _2360;\n        }\n        _2336 = _2352;\n    }\n    return _2336;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2393 = fa_shadow_depth(param, param_1);\n    float _2397;\n    if (conv.x < 0.5f)\n    {\n        _2397 = _2393;\n    }\n    else\n    {\n        _2397 = (conv.y * conv.z) / (conv.z - (_2393 * (conv.z - conv.y)));\n    }\n    return _2397;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel_turn(float2 d)\n{\n    return float2((d.x * (-0.737368881702423095703125f)) - (d.y * 0.675490319728851318359375f), (d.y * (-0.737368881702423095703125f)) + (d.x * 0.675490319728851318359375f));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2443 = fa_shadow_noise() * 6.283185482025146484375f;\n    float2 _2449 = float2(cos(_2443), sin(_2443));\n    float2 dir = _2449;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2458;\n        if (k < 0.0f)\n        {\n            _2458 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2458 = k;\n        }\n        float _2477 = clamp((_2458 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2496 = sqrt((float(i) + 0.5f) * 0.0625f) * _2477;\n            float2 param_3 = uv + (dir * (_2346_fa_shadow_bias.zw * _2496));\n            float4 param_4 = rect;\n            float3 param_5 = conv;\n            float _2510 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2510 < (zr - (_2496 * plane)))\n            {\n                sum += _2510;\n                cnt += 1.0f;\n            }\n            float2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2538 = sum / cnt;\n        float _2548;\n        if (k < 0.0f)\n        {\n            _2548 = (-k) / max(_2538, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2548 = k;\n        }\n        radius = clamp(((max(zr - _2538, 0.0f) * unit) * _2548) / texel_m, 1.5f, 16.0f);\n        dir = _2449;\n    }\n    float lit = 0.0f;\n    int _2574 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2574; i_1++)\n    {\n        float _2593 = sqrt((float(i_1) + 0.5f) / float(_2574)) * radius;\n        float2 param_7 = uv + (dir * (_2346_fa_shadow_bias.zw * _2593));\n        float4 param_8 = rect;\n        float3 param_9 = conv;\n        lit += float((zr - (_2593 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        float2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2574);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2639 = max(_2346_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2644 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2650 = sqrt(1.0f - (_2644 * _2644));\n    float _2658 = min(_2650 / max(_2644, 0.20000000298023223876953125f), 4.0f);\n    float _2663;\n    if (_2346_fa_shadow_bias.y > 0.0f)\n    {\n        _2663 = _2346_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2663 = 1.5f * _2346_fa_shadow_info[ci].x;\n    }\n    float4 _2688 = mul(float4(world + (n * (_2663 * _2650)), 1.0f), _2346_fa_shadow_mat[ci]);\n    float _2695 = _2688.x;\n    bool _2698 = _2695 < _2346_fa_shadow_rect[ci].x;\n    bool _2707;\n    if (!_2698)\n    {\n        _2707 = _2695 > _2346_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2707 = _2698;\n    }\n    bool _2716;\n    if (!_2707)\n    {\n        _2716 = _2688.y < _2346_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2716 = _2707;\n    }\n    bool _2725;\n    if (!_2716)\n    {\n        _2725 = _2688.y > _2346_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2725 = _2716;\n    }\n    bool _2732;\n    if (!_2725)\n    {\n        _2732 = _2688.z > 1.0f;\n    }\n    else\n    {\n        _2732 = _2725;\n    }\n    if (_2732)\n    {\n        return -1.0f;\n    }\n    float _2740;\n    if (_2346_fa_shadow_bias.x > 0.0f)\n    {\n        _2740 = _2346_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2740 = 1.5f * _2346_fa_shadow_info[ci].x;\n    }\n    float2 param = _2688.xy;\n    float4 param_1 = _2346_fa_shadow_rect[ci];\n    float param_2 = _2688.z - ((_2740 * (1.0f + (0.5f * _2658))) / _2639);\n    float param_3 = _2346_fa_shadow_info[ci].x;\n    float param_4 = _2639;\n    float param_5 = _2639 * 0.25f;\n    float param_6 = ((_2346_fa_shadow_info[ci].x * min(_2658, 3.0f)) * 0.5f) / _2639;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2346_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2346_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_602_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _3118 = int(_2346_fa_shadow_cfg.x + 0.5f);\n    if (_3118 < 1)\n    {\n        return 1.0f;\n    }\n    float _3133 = dot(world - _2346_fa_shadow_eye.xyz, _2346_fa_shadow_fwd.xyz);\n    int param = _3118 - 1;\n    if (_3133 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _3145 = _3118 > 1;\n    bool _3152;\n    if (_3145)\n    {\n        _3152 = _3133 > _2346_fa_shadow_split.x;\n    }\n    else\n    {\n        _3152 = _3145;\n    }\n    if (_3152)\n    {\n        ci = 1;\n    }\n    bool _3156 = _3118 > 2;\n    bool _3163;\n    if (_3156)\n    {\n        _3163 = _3133 > _2346_fa_shadow_split.y;\n    }\n    else\n    {\n        _3163 = _3156;\n    }\n    if (_3163)\n    {\n        ci = 2;\n    }\n    bool _3167 = _3118 > 3;\n    bool _3174;\n    if (_3167)\n    {\n        _3174 = _3133 > _2346_fa_shadow_split.z;\n    }\n    else\n    {\n        _3174 = _3167;\n    }\n    if (_3174)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    float s2 = -1.0f;\n    float t = 0.0f;\n    int _3185 = min(_3118, 4);\n    float _3226;\n    for (int c = ci; c < _3185; c++)\n    {\n        int param_1 = c;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _3205 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0f)\n        {\n            s2 = _3205;\n            break;\n        }\n        if (_3205 < 0.0f)\n        {\n            continue;\n        }\n        s = _3205;\n        ci = c;\n        if (_2346_fa_shadow_cfg.y > 0.0f)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3226 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3226 = _2346_fa_shadow_fwd.w;\n            }\n            int param_6 = ci;\n            float _3245 = _2346_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3226, 9.9999997473787516355514526367188e-05f);\n            int param_7 = ci;\n            t = clamp((_3133 - (fa_shadow_split_at(param_7) - _3245)) / _3245, 0.0f, 1.0f);\n        }\n        if (t <= 0.0f)\n        {\n            break;\n        }\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (t > 0.0f)\n    {\n        float _3277;\n        if ((ci + 1) < _3118)\n        {\n            _3277 = (s2 < 0.0f) ? s : s2;\n        }\n        else\n        {\n            _3277 = 1.0f;\n        }\n        s = lerp(s, _3277, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    bool _3382 = _602_fa_ct_b.y > 0.5f;\n    bool _3388;\n    if (_3382)\n    {\n        _3388 = _602_fa_pbr.z > 0.5f;\n    }\n    else\n    {\n        _3388 = _3382;\n    }\n    if (_3388)\n    {\n        float _3402 = dot(_602_fa_ct_fwd.xyz, fa_world_pos) + _602_fa_ct_fwd.w;\n        float _3405 = fwidth(_3402);\n        float4 _3415 = float4(fa_world_pos, 1.0f);\n        float _3421 = dot(_602_fa_ct_vpw, _3415);\n        if (_3421 > 9.9999997473787516355514526367188e-05f)\n        {\n            float2 _3440 = float2(dot(_602_fa_ct_vpx, _3415), dot(_602_fa_ct_vpy, _3415)) / _3421.xx;\n            float _3445 = (_3440.x * 0.5f) + 0.5f;\n            float _3449;\n            if (_602_fa_ct_a.y > 0.5f)\n            {\n                _3449 = (_3440.y * 0.5f) + 0.5f;\n            }\n            else\n            {\n                _3449 = 0.5f - (_3440.y * 0.5f);\n            }\n            bool _3465 = _3445 >= 0.0f;\n            bool _3471;\n            if (_3465)\n            {\n                _3471 = _3445 < 1.0f;\n            }\n            else\n            {\n                _3471 = _3465;\n            }\n            bool _3477;\n            if (_3471)\n            {\n                _3477 = _3449 >= 0.0f;\n            }\n            else\n            {\n                _3477 = _3471;\n            }\n            bool _3483;\n            if (_3477)\n            {\n                _3483 = _3449 < 1.0f;\n            }\n            else\n            {\n                _3483 = _3477;\n            }\n            if (_3483)\n            {\n                float4 _3509 = fa_screen_tex.Load(int3(clamp(int2(float2(_3445, _3449) * _602_fa_ct_a.zw), int2(0, 0), int2(_602_fa_ct_a.zw) - int2(1, 1)), 0));\n                bool _3512 = _3509.w > 0.5f;\n                bool _3528;\n                if (_3512)\n                {\n                    _3528 = abs(_3402 - _3509.x) <= (((0.00200000009499490261077880859375f * _3402) + 0.00999999977648258209228515625f) + min(1.5f * _3405, 0.100000001490116119384765625f * _3402));\n                }\n                else\n                {\n                    _3528 = _3512;\n                }\n                if (_3528)\n                {\n                    float _3534;\n                    if (_602_fa_ct_b.z > 0.5f)\n                    {\n                        float3 param = fa_world_pos;\n                        float3 param_1 = n;\n                        float3 param_2 = l;\n                        _3534 = min(_3509.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3534 = _3509.y;\n                    }\n                    return _3534;\n                }\n            }\n        }\n    }\n    float3 param_3 = fa_world_pos;\n    float3 param_4 = n;\n    float3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2798 = _602_fa_pbr.z < 0.5f;\n    bool _2805;\n    if (!_2798)\n    {\n        _2805 = _2346_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2805 = _2798;\n    }\n    if (_2805)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2346_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2818 = fa_light_texel(param);\n    float _2819 = _2818.x;\n    if (_2819 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2828 = int(_2819 + 0.5f);\n    int param_1 = _2828;\n    float4 _2832 = fa_light_texel(param_1);\n    int param_2 = _2828 + 1;\n    float4 _2837 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2840 = _2832.y;\n    if (_2840 > 0.0f)\n    {\n        float _2857 = 1.0f - smoothstep(0.75f * _2840, _2840, length(world - _2346_fa_shadow_eye.xyz));\n        fade = _2857;\n        if (_2857 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2832.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2881 = (_2828 + 2) + (face * 6);\n    int param_4 = _2881;\n    int param_5 = _2881 + 1;\n    int param_6 = _2881 + 3;\n    float4 _2895 = fa_light_texel(param_6);\n    int param_7 = _2881 + 4;\n    float4 _2900 = fa_light_texel(param_7);\n    int param_8 = _2881 + 5;\n    float4 _2905 = fa_light_texel(param_8);\n    float _2917 = _2905.x * max(dot(_2895, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2922 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2945 = clamp(dot(n, _2895.xyz), -1.0f, 1.0f);\n    float _2964 = min(sqrt(1.0f - (_2945 * _2945)) / max(abs(dot(n, world - lpos)) / max(dot(_2895, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2967 = _2837.y;\n    float _2969;\n    if (_2967 > 0.0f)\n    {\n        _2969 = _2967;\n    }\n    else\n    {\n        _2969 = 1.5f * _2917;\n    }\n    float4 _2989 = float4(world + (n * (_2969 * sqrt(1.0f - (_2922 * _2922)))), 1.0f);\n    float _2993 = dot(_2895, _2989);\n    float _2996 = _2905.y;\n    if (_2993 < _2996)\n    {\n        return 1.0f;\n    }\n    float2 _3011 = float2(dot(fa_light_texel(param_4), _2989), dot(fa_light_texel(param_5), _2989)) / _2993.xx;\n    float _3013 = _3011.x;\n    bool _3016 = _3013 < _2900.x;\n    bool _3025;\n    if (!_3016)\n    {\n        _3025 = _3013 > _2900.z;\n    }\n    else\n    {\n        _3025 = _3016;\n    }\n    bool _3034;\n    if (!_3025)\n    {\n        _3034 = _3011.y < _2900.y;\n    }\n    else\n    {\n        _3034 = _3025;\n    }\n    bool _3043;\n    if (!_3034)\n    {\n        _3043 = _3011.y > _2900.w;\n    }\n    else\n    {\n        _3043 = _3034;\n    }\n    if (_3043)\n    {\n        return 1.0f;\n    }\n    float _3049 = _2837.x;\n    float _3051;\n    if (_3049 > 0.0f)\n    {\n        _3051 = _3049;\n    }\n    else\n    {\n        _3051 = 1.5f * _2917;\n    }\n    float2 param_9 = _3011;\n    float4 param_10 = _2900;\n    float param_11 = _2993 - (_3051 * (1.0f + (0.5f * _2964)));\n    float param_12 = _2917;\n    float param_13 = 1.0f;\n    float param_14 = _2905.z * 0.25f;\n    float param_15 = (_2917 * min(_2964, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2996, _2905.z);\n    int param_17 = int(_2832.z + 0.5f);\n    float param_18 = _2832.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _5377 = _602_fa_ct_a.x < 0.5f;\n    bool _5384;\n    if (!_5377)\n    {\n        _5384 = _2346_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _5384 = _5377;\n    }\n    if (_5384)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2346_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _5397 = fa_light_texel(param);\n    float _5398 = _5397.y;\n    float len = _5398;\n    if (_5398 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _5410 = length(world - _602_fa_camera_pos.xyz);\n    float _5419 = 1.0f - smoothstep(0.5f * _602_fa_ct_b.x, _602_fa_ct_b.x, _5410);\n    if (_5419 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _5425 = len;\n    float _5428 = min(_5425, 0.89999997615814208984375f * dist);\n    len = _5428;\n    float _5433 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _5410);\n    float _5438 = _5433 + (0.5f * _5428);\n    float3 _5444 = world + (gn * _5433);\n    float _5446 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _5507;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5461 = (float(k) + _5446) * 0.083333335816860198974609375f;\n        float3 _5469 = _5444 + (l * (_5461 * len));\n        float4 _5475 = float4(_5469, 1.0f);\n        float _5480 = dot(_602_fa_ct_vpw, _5475);\n        if (_5480 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _5498 = float2(dot(_602_fa_ct_vpx, _5475), dot(_602_fa_ct_vpy, _5475)) / _5480.xx;\n        float _5502 = _5498.x * 0.5f;\n        float _5503 = _5502 + 0.5f;\n        if (_602_fa_ct_a.y > 0.5f)\n        {\n            _5507 = (_5498.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _5507 = 0.5f - (_5498.y * 0.5f);\n        }\n        bool _5523 = _5503 < 0.0f;\n        bool _5530;\n        if (!_5523)\n        {\n            _5530 = _5503 >= 1.0f;\n        }\n        else\n        {\n            _5530 = _5523;\n        }\n        bool _5537;\n        if (!_5530)\n        {\n            _5537 = _5507 < 0.0f;\n        }\n        else\n        {\n            _5537 = _5530;\n        }\n        bool _5544;\n        if (!_5537)\n        {\n            _5544 = _5507 >= 1.0f;\n        }\n        else\n        {\n            _5544 = _5537;\n        }\n        if (_5544)\n        {\n            break;\n        }\n        float4 _5568 = fa_screen_tex.Load(int3(clamp(int2(float2(_5503, _5507) * _602_fa_ct_a.zw), int2(0, 0), int2(_602_fa_ct_a.zw) - int2(1, 1)), 0));\n        if (_5568.w < 0.5f)\n        {\n            continue;\n        }\n        float _5586 = (dot(_602_fa_ct_fwd.xyz, _5469) + _602_fa_ct_fwd.w) - _5568.x;\n        if ((_5586 > _5433) && (_5586 < _5438))\n        {\n            occ = max(occ, (1.0f - (_5461 * _5461)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_5503, 0.5f - _5502), min(_5507, 1.0f - _5507))));\n        }\n    }\n    return 1.0f - (occ * _5419);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _6219 = fa_baked_keep(param);\n    if (_6219 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _9438 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _9438;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _6245 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _9440 = _6245.color;\n    float _9441 = _6245.attenuation;\n    float _9442 = _6245.shadow;\n    bool _6248 = _6245.type == 0;\n    if (_6248 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _6245.direction;\n        float _6259 = fa_shadow_factor(param_5, param_6);\n        _9442 = _6259;\n        _9440 *= _6259;\n    }\n    else\n    {\n        bool _6270 = _6245.type != 0;\n        bool _6276;\n        if (_6270)\n        {\n            _6276 = _9441 > 0.0f;\n        }\n        else\n        {\n            _6276 = _6270;\n        }\n        if (_6276)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _6245.direction;\n            float _6295 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _9442 = _6295;\n            _9440 *= _6295;\n        }\n    }\n    bool _6305 = _602_fa_ct_a.x > 0.5f;\n    bool _6311;\n    if (_6305)\n    {\n        _6311 = _9441 > 0.0f;\n    }\n    else\n    {\n        _6311 = _6305;\n    }\n    if (_6311)\n    {\n        float _6318;\n        if (_6248)\n        {\n            _6318 = 1000000000.0f;\n        }\n        else\n        {\n            _6318 = _6245._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _6245.direction;\n        float param_18 = _6318;\n        float _6336 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9442 *= _6336;\n        _9440 *= _6336;\n    }\n    float _6349 = _9441;\n    float _6350 = _6349 * _6219;\n    _9441 = _6350;\n    float3 _6354 = _9440;\n    float3 _6355 = _6354 * _6219;\n    _9440 = _6355;\n    LightSample _9457 = { _6245.direction, _6355, _6350, _9442, _6245._distance, _6245.type };\n    return _9457;\n}\n\nfloat3 fa_ltc_tangent(float3 n, float3 v)\n{\n    float3 _6389 = v - (n * dot(v, n));\n    float3 t = _6389;\n    float _6393 = dot(_6389, _6389);\n    float l2 = _6393;\n    if (_6393 < 1.0000000133514319600180897396058e-10f)\n    {\n        float3 _6403;\n        if (abs(n.z) < 0.999000012874603271484375f)\n        {\n            _6403 = cross(n, float3(0.0f, 0.0f, 1.0f));\n        }\n        else\n        {\n            _6403 = cross(n, float3(1.0f, 0.0f, 0.0f));\n        }\n        t = _6403;\n        l2 = dot(_6403, _6403);\n    }\n    return t * rsqrt(l2);\n}\n\nfloat3 fa_ltc_local(float3 t1, float3 n, float3 p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nfloat2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((float2(clamp((roughness - 0.0500000007450580596923828125f) * 1.0526316165924072265625f, 0.0f, 1.0f), sqrt(clamp(1.0f - ndv, 0.0f, 1.0f))) * 63.0f) + 0.5f.xx) * 0.015625f.xx;\n}\n\nfloat3 fa_oct_vertex(int j, float3 pc, float3 ex, float3 ey)\n{\n    float _6790;\n    if ((j == 0) || (j == 7))\n    {\n        _6790 = 0.92387950420379638671875f;\n    }\n    else\n    {\n        float _6800;\n        if ((j == 3) || (j == 4))\n        {\n            _6800 = -0.92387950420379638671875f;\n        }\n        else\n        {\n            _6800 = ((j == 1) || (j == 6)) ? 0.3826834261417388916015625f : (-0.3826834261417388916015625f);\n        }\n        _6790 = _6800;\n    }\n    float _6821;\n    if ((j == 1) || (j == 2))\n    {\n        _6821 = 0.92387950420379638671875f;\n    }\n    else\n    {\n        float _6830;\n        if ((j == 5) || (j == 6))\n        {\n            _6830 = -0.92387950420379638671875f;\n        }\n        else\n        {\n            _6830 = ((j == 0) || (j == 3)) ? 0.3826834261417388916015625f : (-0.3826834261417388916015625f);\n        }\n        _6821 = _6830;\n    }\n    return (pc + (ex * _6790)) + (ey * _6821);\n}\n\nfloat3 fa_ltc_edge_vector(float3 a, float3 b)\n{\n    float _6438 = dot(a, a);\n    float _6442 = dot(b, b);\n    if ((_6438 < 1.0000000195414813782625560981111e-24f) || (_6442 < 1.0000000195414813782625560981111e-24f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _6456 = a * rsqrt(_6438);\n    float3 _6461 = b * rsqrt(_6442);\n    float _6465 = dot(_6456, _6461);\n    float _6468 = abs(_6465);\n    float g = (((((((((((0.0416471660137176513671875f * _6468) - 0.1924748718738555908203125f) * _6468) + 0.4179156124591827392578125f) * _6468) - 0.616057217121124267578125f) * _6468) + 0.777722418308258056640625f) * _6468) - 0.999542415142059326171875f) * _6468) + 1.570791721343994140625f;\n    if (_6465 < 0.0f)\n    {\n        g = (3.1415927410125732421875f * rsqrt(max(1.0f - (_6465 * _6465), 1.0000000116860974230803549289703e-07f))) - g;\n    }\n    return cross(_6456, _6461) * g;\n}\n\nvoid fa_ltc_clip_edge(float3 a, float3 b, inout float3 sum, inout float3 leave, inout float3 enter, inout float2 seen)\n{\n    bool _6525 = a.z > 0.0f;\n    bool _6529 = b.z > 0.0f;\n    if (_6525 && _6529)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6525 != _6529)\n        {\n            float3 _6564 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6564.z = 0.0f;\n            if (_6525)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _6564;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6564;\n                seen.x = 1.0f;\n            }\n            else\n            {\n                float3 param_4 = _6564;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6564;\n                seen.y = 1.0f;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(float4 abcd, float3 p0, float3 p1, float3 p2, float3 p3)\n{\n    float3 _6613 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _6639 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _6665 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _6691 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = 0.0f.xxx;\n    float3 leave = 0.0f.xxx;\n    float3 enter = 0.0f.xxx;\n    float3 param = _6613;\n    float3 param_1 = _6639;\n    float3 param_2 = 0.0f.xxx;\n    float3 param_3 = 0.0f.xxx;\n    float3 param_4 = 0.0f.xxx;\n    float2 param_5 = 0.0f.xx;\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _6639;\n    float3 param_7 = _6665;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _6665;\n    float3 param_13 = _6691;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _6691;\n    float3 param_19 = _6613;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5f)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875f;\n}\n\nfloat2 fa_area_forms(float4 m, float shape, float3 pc, float3 ex, float3 ey)\n{\n    int _6859 = ((shape < 0.5f) || (shape > 1.5f)) ? 1 : 3;\n    float2 sum = 0.0f.xx;\n    int _6877;\n    for (int k = 0; k < (2 * _6859); k++)\n    {\n        bool _6874 = k >= _6859;\n        if (_6874)\n        {\n            _6877 = k - _6859;\n        }\n        else\n        {\n            _6877 = k;\n        }\n        float3 p0 = (pc - ex) - ey;\n        float3 p1 = (pc + ex) - ey;\n        float3 p2 = (pc + ex) + ey;\n        float3 p3 = (pc - ex) + ey;\n        if (_6859 == 3)\n        {\n            int param = 0;\n            float3 param_1 = pc;\n            float3 param_2 = ex;\n            float3 param_3 = ey;\n            p0 = fa_oct_vertex(param, param_1, param_2, param_3);\n            int _6923 = 2 * _6877;\n            int param_4 = _6923 + 1;\n            float3 param_5 = pc;\n            float3 param_6 = ex;\n            float3 param_7 = ey;\n            p1 = fa_oct_vertex(param_4, param_5, param_6, param_7);\n            int param_8 = _6923 + 2;\n            float3 param_9 = pc;\n            float3 param_10 = ex;\n            float3 param_11 = ey;\n            p2 = fa_oct_vertex(param_8, param_9, param_10, param_11);\n            int param_12 = _6923 + 3;\n            float3 param_13 = pc;\n            float3 param_14 = ex;\n            float3 param_15 = ey;\n            p3 = fa_oct_vertex(param_12, param_13, param_14, param_15);\n        }\n        bool4 _6960 = _6874.xxxx;\n        float4 param_16 = float4(_6960.x ? m.x : float4(1.0f, 0.0f, 0.0f, 1.0f).x, _6960.y ? m.y : float4(1.0f, 0.0f, 0.0f, 1.0f).y, _6960.z ? m.z : float4(1.0f, 0.0f, 0.0f, 1.0f).z, _6960.w ? m.w : float4(1.0f, 0.0f, 0.0f, 1.0f).w);\n        float3 param_17 = p0;\n        float3 param_18 = p1;\n        float3 param_19 = p2;\n        float3 param_20 = p3;\n        float _6971 = fa_ltc_quad(param_16, param_17, param_18, param_19, param_20);\n        if (_6874)\n        {\n            float2 _9683 = sum;\n            _9683.y = _9683.y + _6971;\n            sum = _9683;\n        }\n        else\n        {\n            float2 _9686 = sum;\n            _9686.x = _9686.x + _6971;\n            sum = _9686;\n        }\n    }\n    return abs(sum);\n}\n\nfloat3 fa_area_shade(int li, float3 world_pos, float3 n, float3 v, float3 diffuse_color, float3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _6995 = fa_light_base(param);\n    int param_1 = _6995;\n    int param_2 = _6995 + 1;\n    int param_3 = _6995 + 2;\n    int param_4 = _6995 + 4;\n    float4 _7017 = fa_light_texel(param_4);\n    int param_5 = _6995 + 5;\n    float4 _7022 = fa_light_texel(param_5);\n    int param_6 = _6995 + 6;\n    float4 _7027 = fa_light_texel(param_6);\n    float _7028 = _7027.w;\n    float3 _7033 = fa_light_texel(param_1).xyz - world_pos;\n    bool _7035 = _7028 < 1.5f;\n    bool _7042;\n    if (_7035)\n    {\n        _7042 = dot(normalize(fa_light_texel(param_3).xyz), _7033) >= 0.0f;\n    }\n    else\n    {\n        _7042 = _7035;\n    }\n    if (_7042)\n    {\n        return 0.0f.xxx;\n    }\n    bool _7051 = (_7028 > 0.5f) && _7035;\n    float _7055 = _7051 ? 1.0539000034332275390625f : 1.0f;\n    float3 _7058 = _7017.xyz;\n    float _7060 = _7017.w;\n    float3 _7066 = _7022.xyz;\n    float _7068 = _7022.w;\n    float3 up = _7066 * (_7068 * _7055);\n    float _7074;\n    if (_7051)\n    {\n        _7074 = (3.1415927410125732421875f * _7060) * _7060;\n    }\n    else\n    {\n        _7074 = (4.0f * _7060) * _7068;\n    }\n    if (_7028 > 1.5f)\n    {\n        float3 _7100 = cross(_7058, -_7033);\n        float3 perp = _7100;\n        float _7104 = dot(_7100, _7100);\n        float3 _7107;\n        if (_7104 > 1.0000000133514319600180897396058e-10f)\n        {\n            _7107 = perp * rsqrt(_7104);\n        }\n        else\n        {\n            _7107 = _7066;\n        }\n        perp = _7107;\n        up = _7107 * _7068;\n    }\n    float _7128 = max(_7074, 9.9999999747524270787835121154785e-07f);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _7138 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _7138;\n    float3 param_10 = n;\n    float3 param_11 = _7033;\n    float3 param_12 = _7138;\n    float3 param_13 = n;\n    float3 param_14 = _7058 * (_7060 * _7055);\n    float3 param_15 = _7138;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float param_18 = roughness;\n    float param_19 = ndv;\n    float2 _7169 = fa_ltc_uv(param_18, param_19) * 64.0f;\n    float2 param_20 = _7169;\n    float2 param_21 = _7169 + float2(64.0f, 0.0f);\n    float4 _7179 = fa_atlas_fetch(param_21);\n    float4 param_22 = fa_atlas_fetch(param_20);\n    float param_23 = _7028;\n    float3 param_24 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_25 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_26 = fa_ltc_local(param_15, param_16, param_17);\n    float2 _7191 = fa_area_forms(param_22, param_23, param_24, param_25, param_26);\n    return (((diffuse_color * _7191.x) + (((f0 * _7179.x) + ((f90.xxx - f0) * _7179.y)) * _7191.y)) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875f * dot(_7033, _7033)) + _7128) / _7128) * window);\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _5114 = 1.0f / alpha;\n    return ((2.0f + _5114) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _5114)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat fa_layers_coat(FaLayers L, float3 l, float3 h, float vdh)\n{\n    float _5149 = max(dot(L.nc, l), 0.0f);\n    float _5155 = max(dot(L.nc, h), 0.0f);\n    float _5164 = ((_5155 * _5155) * (L.coat_a2 - 1.0f)) + 1.0f;\n    return (((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _5164) * _5164)) * (0.5f / max(lerp((2.0f * _5149) * L.coat_ndv, _5149 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _5149)) * _5149;\n}\n\nfloat3 fa_area_layers(FaLayers L, float3 base, int li, float3 n, float3 v, float3 l, float ndv, float window)\n{\n    float _7228;\n    if (L.sheen_on)\n    {\n        _7228 = L.sheen_scale;\n    }\n    else\n    {\n        _7228 = 1.0f;\n    }\n    float3 result = base * (L.keep * _7228);\n    float3 _7241 = normalize(l + v);\n    int param = li;\n    float3 _7252 = fa_light_rgb(param) * window;\n    if (L.sheen_on)\n    {\n        float _7261 = max(dot(n, l), 0.0f);\n        float param_1 = L.sheen_alpha;\n        float param_2 = max(dot(n, _7241), 0.0f);\n        float param_3 = _7261;\n        float param_4 = ndv;\n        result += ((L.sheen * _7252) * (((((fa_d_charlie(param_1, param_2) * fa_v_ashikhmin(param_3, param_4)) * 3.1415927410125732421875f) * step(9.9999997473787516355514526367188e-05f, _7261)) * _7261) * L.keep));\n    }\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_5 = L;\n        float3 param_6 = l;\n        float3 param_7 = _7241;\n        float param_8 = max(dot(v, _7241), 0.0f);\n        result += (_7252 * fa_layers_coat(param_5, param_6, param_7, param_8));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _5017 = tdh / at;\n    float _5021 = bdh / ab;\n    float _5033 = ((_5017 * _5017) + (_5021 * _5021)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _5033) * _5033);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5213 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5292 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _5292) * _5292);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _5213);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _5213));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_17 = L;\n        float3 param_18 = l;\n        float3 param_19 = h;\n        float param_20 = vdh;\n        result += fa_layers_coat(param_17, param_18, param_19, param_20).xxx;\n    }\n    return result;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _4416 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _4419 = _4416.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_4419 * _4419, exp2((-9.27999973297119140625f) * ndv)) * _4419) + _4416.y)) + _4416.zw;\n}\n\nfloat3 fa_probe_level(float2 origin, float res, int lv, float2 e)\n{\n    float _3725;\n    if (lv == 0)\n    {\n        _3725 = 0.0f;\n    }\n    else\n    {\n        _3725 = res + 2.0f;\n    }\n    float _3735;\n    if (lv == 0)\n    {\n        _3735 = 0.0f;\n    }\n    else\n    {\n        _3735 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0f * float(lv - 1));\n    }\n    return fa_probe_atlas.SampleLevel(fa_env_smp, (((origin + float2(_3725, _3735)) + 1.0f.xx) + (((e * 0.5f) + 0.5f.xx) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0f).xyz;\n}\n\nfloat3 fa_probe_radiance(float2 origin, float res, float3 d, float rough)\n{\n    float _3781;\n    if (res > 64.5f)\n    {\n        _3781 = 5.0f;\n    }\n    else\n    {\n        _3781 = (res > 32.5f) ? 4.0f : 3.0f;\n    }\n    float _3796 = clamp(rough, 0.0f, 1.0f) * (_3781 - 1.0f);\n    int _3803 = int(min(floor(_3796), _3781 - 2.0f));\n    float _3808 = _3796 - float(_3803);\n    float3 param = d;\n    float2 _3812 = fa_oct_encode(param);\n    float2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3803;\n    float2 param_4 = _3812;\n    float3 _3822 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3808 < 0.00200000009499490261077880859375f)\n    {\n        return _3822;\n    }\n    float2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3803 + 1;\n    float2 param_8 = _3812;\n    return lerp(_3822, fa_probe_level(param_5, param_6, param_7, param_8), _3808.xxx);\n}\n\nfloat3 fa_probe_box_dir(float3 d, float4 posw, float4 bx, float4 by, float4 bz)\n{\n    if (posw.w < 0.5f)\n    {\n        return d;\n    }\n    float _3894 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3901 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3908 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3914 = dot(bx.xyz, d);\n    float _3918 = dot(by.xyz, d);\n    float _3922 = dot(bz.xyz, d);\n    float _3928;\n    if (_3914 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3928 = (1.0f - _3894) / _3914;\n    }\n    else\n    {\n        float _3942;\n        if (_3914 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3942 = ((-1.0f) - _3894) / _3914;\n        }\n        else\n        {\n            _3942 = 1000000015047466219876688855040.0f;\n        }\n        _3928 = _3942;\n    }\n    float tx = _3928;\n    float _3959;\n    if (_3918 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3959 = (1.0f - _3901) / _3918;\n    }\n    else\n    {\n        float _3972;\n        if (_3918 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3972 = ((-1.0f) - _3901) / _3918;\n        }\n        else\n        {\n            _3972 = 1000000015047466219876688855040.0f;\n        }\n        _3959 = _3972;\n    }\n    float ty = _3959;\n    float _3988;\n    if (_3922 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3988 = (1.0f - _3908) / _3922;\n    }\n    else\n    {\n        float _4001;\n        if (_3922 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _4001 = ((-1.0f) - _3908) / _3922;\n        }\n        else\n        {\n            _4001 = 1000000015047466219876688855040.0f;\n        }\n        _3988 = _4001;\n    }\n    float _4013 = tx;\n    float _4016 = (_4013 > 0.0f) ? _4013 : 1000000015047466219876688855040.0f;\n    tx = _4016;\n    float _4017 = ty;\n    float _4020 = (_4017 > 0.0f) ? _4017 : 1000000015047466219876688855040.0f;\n    ty = _4020;\n    float _4030 = min(_4016, min(_4020, (_3988 > 0.0f) ? _3988 : 1000000015047466219876688855040.0f));\n    if (_4030 > 100000001504746621987668885504.0f)\n    {\n        return d;\n    }\n    float3 _4046 = (fa_world_pos + (d * _4030)) - posw.xyz;\n    float3 _4051;\n    if (dot(_4046, _4046) > 1.0000000133514319600180897396058e-10f)\n    {\n        _4051 = normalize(_4046);\n    }\n    else\n    {\n        _4051 = d;\n    }\n    return _4051;\n}\n\nfloat3 fa_probe_environment(float4 tile, float4 posw, float4 bx, float4 by, float4 bz, inout float3 d, float rough)\n{\n    float3 param = d;\n    float4 param_1 = posw;\n    float4 param_2 = bx;\n    float4 param_3 = by;\n    float4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    float2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    float3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _4097 = (1.0f - _602_fa_rpa_tile.w) - _602_fa_rpb_tile.w;\n    float3 outc = 0.0f.xxx;\n    if (_4097 > 0.0005000000237487256526947021484375f)\n    {\n        float3 base;\n        if (_602_fa_env_sky.w > 0.5f)\n        {\n            float2 param = _602_fa_atlas.zw;\n            float param_1 = 128.0f;\n            float3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _4125 = rough * rough;\n            float _4156 = 0.60000002384185791015625f * _4125;\n            base = lerp(lerp(_602_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_602_fa_env_horizon.xyz, _602_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _4125)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _4156, 0.0500000007450580596923828125f + _4156, d.y).xxx), ((_602_fa_env_sky.xyz + _602_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_4125 * 0.60000002384185791015625f).xxx);\n        }\n        outc = base * _4097;\n    }\n    if (_602_fa_rpa_tile.w > 0.0f)\n    {\n        float4 param_4 = _602_fa_rpa_tile;\n        float4 param_5 = _602_fa_rpa_pos;\n        float4 param_6 = _602_fa_rpa_bx;\n        float4 param_7 = _602_fa_rpa_by;\n        float4 param_8 = _602_fa_rpa_bz;\n        float3 param_9 = d;\n        float param_10 = rough;\n        float3 _4215 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4215 * _602_fa_rpa_tile.w);\n    }\n    if (_602_fa_rpb_tile.w > 0.0f)\n    {\n        float4 param_11 = _602_fa_rpb_tile;\n        float4 param_12 = _602_fa_rpb_pos;\n        float4 param_13 = _602_fa_rpb_bx;\n        float4 param_14 = _602_fa_rpb_by;\n        float4 param_15 = _602_fa_rpb_bz;\n        float3 param_16 = d;\n        float param_17 = rough;\n        float3 _4247 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4247 * _602_fa_rpb_tile.w);\n    }\n    return outc;\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness, float occlusion)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _4894;\n        if (L.aniso >= 0.0f)\n        {\n            _4894 = L.b;\n        }\n        else\n        {\n            _4894 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_4894, v), _4894), (abs(L.aniso) * smoothstep(0.0f, 0.25f, roughness)).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4930 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _4930.x) + (L.f90.xxx * _4930.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _4988 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _4988.x) + _4988.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4458 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4458.x) + _4458.y.xxx);\n}\n\nfloat2 fa_xm_size(int k)\n{\n    return max(floor(_602_fa_ct_a.zw / float(1 << k).xx), 1.0f.xx);\n}\n\nfloat2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return 0.0f.xx;\n    }\n    float y = 0.0f;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return float2(_602_fa_ct_a.z, y);\n}\n\nfloat3 fa_xm_texel(float2 size, float2 origin, float2 p)\n{\n    return fa_screen_tex.Load(int3(int2(origin + clamp(p, 0.0f.xx, size - 1.0f.xx)), 0)).xyz;\n}\n\nfloat3 fa_xm_level(int k, float2 uv)\n{\n    int param = k;\n    float2 _5690 = fa_xm_size(param);\n    int param_1 = k;\n    float2 _5694 = fa_xm_origin(param_1);\n    float2 _5700 = (uv * _5690) - 0.5f.xx;\n    float2 _5703 = frac(_5700);\n    float2 _5706 = floor(_5700);\n    float2 param_2 = _5690;\n    float2 param_3 = _5694;\n    float2 param_4 = _5706;\n    float2 param_5 = _5690;\n    float2 param_6 = _5694;\n    float2 param_7 = _5706 + float2(1.0f, 0.0f);\n    float2 param_8 = _5690;\n    float2 param_9 = _5694;\n    float2 param_10 = _5706 + float2(0.0f, 1.0f);\n    float2 param_11 = _5690;\n    float2 param_12 = _5694;\n    float2 param_13 = _5706 + 1.0f.xx;\n    float3 _5748 = _5703.x.xxx;\n    return lerp(lerp(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _5748), lerp(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _5748), _5703.y.xxx);\n}\n\nfloat3 fa_xm_sample(float2 uv, float lod)\n{\n    float _5767 = max(_602_fa_tr_b.w - 1.0f, 0.0f);\n    float _5771 = clamp(lod, 0.0f, _5767);\n    int _5775 = int(floor(_5771));\n    int param = _5775;\n    float2 param_1 = uv;\n    float3 c = fa_xm_level(param, param_1);\n    float _5785 = float(_5775);\n    float _5786 = _5771 - _5785;\n    bool _5788 = _5786 > 0.001000000047497451305389404296875f;\n    bool _5795;\n    if (_5788)\n    {\n        _5795 = _5785 < _5767;\n    }\n    else\n    {\n        _5795 = _5788;\n    }\n    if (_5795)\n    {\n        int param_2 = _5775 + 1;\n        float2 param_3 = uv;\n        c = lerp(c, fa_xm_level(param_2, param_3), _5786.xxx);\n    }\n    return c;\n}\n\nfloat3 fa_transmitted(Surface s, float3 n, float3 v, float roughness, float3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _5821 = fa_env_brdf(param, param_1);\n    float3 _5845 = ((1.0f.xxx - clamp((f0 * _5821.x) + (f90.xxx * _5821.y), 0.0f.xxx, 1.0f.xxx)) * s.albedo) * (tr * keep);\n    float3 through = _5845;\n    float _5851 = max(s.thickness, 0.0f);\n    bool _5856 = _5851 > 0.0f;\n    if ((s.attenuation_distance > 0.0f) && _5856)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, 9.9999997473787516355514526367188e-05f.xxx, 1.0f.xxx))) / s.attenuation_distance.xxx)) * _5851);\n    }\n    bool _5881 = _602_fa_tr_a.w > 1.5f;\n    bool _5887;\n    if (_5881)\n    {\n        _5887 = _602_fa_tr_a.w < 2.5f;\n    }\n    else\n    {\n        _5887 = _5881;\n    }\n    bool _5894;\n    if (!_5887)\n    {\n        _5894 = _602_fa_tr_a.w < 0.5f;\n    }\n    else\n    {\n        _5894 = _5887;\n    }\n    if (_5894)\n    {\n        blend = clamp(dot(through, 0.3333333432674407958984375f.xxx), 0.0f, 0.980000019073486328125f);\n        return 0.0f.xxx;\n    }\n    float4 _5909 = float4(fa_world_pos, 1.0f);\n    float _5914 = dot(_602_fa_ct_vpw, _5909);\n    float2 uv0 = 0.5f.xx;\n    if (_5914 > 9.9999997473787516355514526367188e-05f)\n    {\n        float2 _5932 = float2(dot(_602_fa_ct_vpx, _5909), dot(_602_fa_ct_vpy, _5909)) / _5914.xx;\n        float _5940;\n        if (_602_fa_ct_a.y > 0.5f)\n        {\n            _5940 = (_5932.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _5940 = 0.5f - (_5932.y * 0.5f);\n        }\n        uv0 = float2((_5932.x * 0.5f) + 0.5f, _5940);\n    }\n    if (_602_fa_tr_a.w > 2.5f)\n    {\n        int param_2 = 0;\n        float2 _5961 = fa_xm_size(param_2);\n        float2 _5969 = floor(clamp(uv0, 0.0f.xx, 0.99989998340606689453125f.xx) * _5961);\n        if (fa_screen_tex.Load(int3(int2(_5969), 0)).w > 0.5f)\n        {\n            int _5989 = int(floor((clamp(roughness, 0.0f, 1.0f) * 2.0f) + 0.5f));\n            float3 acc = 0.0f.xxx;\n            float cnt = 0.0f;\n            for (int dy = -2; dy <= 2; dy++)\n            {\n                for (int dx = -2; dx <= 2; dx++)\n                {\n                    bool _6012 = abs(dx) > _5989;\n                    bool _6020;\n                    if (!_6012)\n                    {\n                        _6020 = abs(dy) > _5989;\n                    }\n                    else\n                    {\n                        _6020 = _6012;\n                    }\n                    if (_6020)\n                    {\n                        continue;\n                    }\n                    float4 _6041 = fa_screen_tex.Load(int3(int2(clamp(_5969 + float2(float(dx), float(dy)), 0.0f.xx, _5961 - 1.0f.xx)), 0));\n                    if (_6041.w > 0.5f)\n                    {\n                        acc += _6041.xyz;\n                        cnt += 1.0f;\n                    }\n                }\n            }\n            return _5845 * (acc / max(cnt, 1.0f).xxx);\n        }\n    }\n    float2 uv = uv0;\n    if (_5856)\n    {\n        float4 _6089 = float4(fa_world_pos + (refract(-v, n, 1.0f / max(s.ior, 1.0f)) * _5851), 1.0f);\n        float _6094 = dot(_602_fa_ct_vpw, _6089);\n        uv = 0.5f.xx;\n        if (_6094 > 9.9999997473787516355514526367188e-05f)\n        {\n            float2 _6111 = float2(dot(_602_fa_ct_vpx, _6089), dot(_602_fa_ct_vpy, _6089)) / _6094.xx;\n            float _6119;\n            if (_602_fa_ct_a.y > 0.5f)\n            {\n                _6119 = (_6111.y * 0.5f) + 0.5f;\n            }\n            else\n            {\n                _6119 = 0.5f - (_6111.y * 0.5f);\n            }\n            uv = float2((_6111.x * 0.5f) + 0.5f, _6119);\n        }\n    }\n    float2 param_3 = clamp(uv, 0.0f.xx, 1.0f.xx);\n    float param_4 = (clamp(roughness, 0.0f, 1.0f) * clamp((2.0f * s.ior) - 2.0f, 0.0f, 1.0f)) * max(_602_fa_tr_b.w - 1.0f, 0.0f);\n    return through * fa_xm_sample(param_3, param_4);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2346_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3305 = int(_2346_fa_shadow_cfg.x + 0.5f);\n    float _3315 = dot(world - _2346_fa_shadow_eye.xyz, _2346_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3320 = _3305 > 0;\n    bool _3329;\n    if (_3320)\n    {\n        int param = _3305 - 1;\n        _3329 = _3315 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3329 = _3320;\n    }\n    if (_3329)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3335 = _3305 > 1;\n        bool _3342;\n        if (_3335)\n        {\n            _3342 = _3315 > _2346_fa_shadow_split.x;\n        }\n        else\n        {\n            _3342 = _3335;\n        }\n        if (_3342)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3348 = _3305 > 2;\n        bool _3355;\n        if (_3348)\n        {\n            _3355 = _3315 > _2346_fa_shadow_split.y;\n        }\n        else\n        {\n            _3355 = _3348;\n        }\n        if (_3355)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3361 = _3305 > 3;\n        bool _3368;\n        if (_3361)\n        {\n            _3368 = _3315 > _2346_fa_shadow_split.z;\n        }\n        else\n        {\n            _3368 = _3361;\n        }\n        if (_3368)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _9099 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _9099 = -_9099;\n    }\n    float3 _8385 = normalize(_602_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _9112 = { fa_world_pos, _9099, fa_world_tangent, fa_uv, fa_vertex_color, _8385, gl_FrontFacing };\n    SurfaceInput param_1 = _9112;\n    Surface _8393 = fa_standard_surface(param_1);\n    float3 _9130 = _8393.albedo;\n    float _9131 = _8393.alpha;\n    float3 _9132 = _8393.normal;\n    float _9133 = _8393.metallic;\n    float _9134 = _8393.roughness;\n    float _9135 = _8393.occlusion;\n    float3 _9136 = _8393.emission;\n    float _9137 = _8393.clearcoat;\n    float _9138 = _8393.clearcoat_roughness;\n    float3 _9139 = _8393.sheen_color;\n    float _9140 = _8393.sheen_roughness;\n    float _9141 = _8393.anisotropy;\n    float _9142 = _8393.anisotropy_rotation;\n    float _9143 = _8393.specular;\n    float _9144 = _8393.ior;\n    float3 _9145 = _8393.specular_color;\n    float _9146 = _8393.transmission;\n    float _9147 = _8393.thickness;\n    float3 _9148 = _8393.attenuation_color;\n    float _9149 = _8393.attenuation_distance;\n    SurfaceInput _9120 = { fa_world_pos, _9099, fa_world_tangent, fa_uv, fa_vertex_color, _8385, gl_FrontFacing };\n    SurfaceInput param_2 = _9120;\n    Surface param_3 = _8393;\n    surface(param_2, param_3);\n    _9130 = param_3.albedo;\n    _9131 = param_3.alpha;\n    _9132 = param_3.normal;\n    _9133 = param_3.metallic;\n    _9134 = param_3.roughness;\n    _9135 = param_3.occlusion;\n    _9136 = param_3.emission;\n    _9137 = param_3.clearcoat;\n    _9138 = param_3.clearcoat_roughness;\n    _9139 = param_3.sheen_color;\n    _9140 = param_3.sheen_roughness;\n    _9141 = param_3.anisotropy;\n    _9142 = param_3.anisotropy_rotation;\n    _9143 = param_3.specular;\n    _9144 = param_3.ior;\n    _9145 = param_3.specular_color;\n    _9146 = param_3.transmission;\n    _9147 = param_3.thickness;\n    _9148 = param_3.attenuation_color;\n    _9149 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _9099;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _9130 = param_6;\n    _9132 = param_7;\n    if (_9131 < _8421_alphaCutoff)\n    {\n        discard;\n    }\n    fa_lod_dither();\n    float fa_tr_blend = 0.0f;\n    float3 result;\n    if (_602_fa_emissive.w > 0.5f)\n    {\n        result = _9130;\n    }\n    else\n    {\n        float3 _8445 = normalize(_9132);\n        float _8452 = clamp(_9133, 0.0f, 1.0f);\n        float _8456 = clamp(_9134, 0.0500000007450580596923828125f, 1.0f);\n        float _8460 = _8456 * _8456;\n        float _8464 = _8460 * _8460;\n        float _8469 = max(dot(_8445, _8385), 9.9999997473787516355514526367188e-05f);\n        float _8475 = 1.0f - _8452;\n        float _8476 = clamp(_9146, 0.0f, 1.0f) * _8475;\n        float3 _8485 = (_9130 * _8475) * (1.0f - _8476);\n        float3 _8492 = lerp(0.039999999105930328369140625f.xxx, _9130, _8452.xxx);\n        float3 f0 = _8492;\n        SurfaceInput _9128 = { fa_world_pos, _9099, fa_world_tangent, fa_uv, fa_vertex_color, _8385, gl_FrontFacing };\n        SurfaceInput param_8 = _9128;\n        Surface _9231 = { _9130, _9131, _9132, _9133, _9134, _9135, _9136, _9137, _9138, _9139, _9140, _9141, _9142, _9143, _9144, _9145, _9146, _9147, _9148, _9149 };\n        Surface param_9 = _9231;\n        float3 param_10 = _8445;\n        float3 param_11 = _8385;\n        float param_12 = _8452;\n        float param_13 = _8456;\n        float3 param_14 = _8492;\n        FaLayers _8508 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _8445;\n        float3 lit = (fa_indirect_diffuse(param_15) * _8485) * _9135;\n        if (_8508.on)\n        {\n            lit *= _8508.base_scale;\n        }\n        int _8530 = fa_cl_ndir + fa_cl_local;\n        float _8595;\n        for (int ln = 0; ln < _8530; ln++)\n        {\n            int param_16 = ln;\n            int _8543 = fa_cl_light(param_16);\n            int param_17 = _8543;\n            if (fa_baked_keep(param_17) <= 0.0f)\n            {\n                continue;\n            }\n            int param_18 = _8543;\n            float3 param_19 = fa_world_pos;\n            float3 param_20 = _9099;\n            LightSample _8559 = fa_light_shadowed(param_18, param_19, param_20);\n            float _8567 = max(dot(_8445, _8559.direction), 0.0f);\n            float _8573 = _8559.attenuation * _8559.shadow;\n            float3 _8578 = normalize(_8559.direction + _8385);\n            float _8583 = max(dot(_8445, _8578), 0.0f);\n            float _8588 = max(dot(_8385, _8578), 0.0f);\n            if (fa_light_is_area)\n            {\n                if (_8508.on)\n                {\n                    _8595 = _8508.f90;\n                }\n                else\n                {\n                    _8595 = 1.0f;\n                }\n                int param_21 = _8543;\n                float3 param_22 = fa_world_pos;\n                float3 param_23 = _8445;\n                float3 param_24 = _8385;\n                float3 param_25 = _8485;\n                float3 param_26 = f0;\n                float param_27 = _8595;\n                float param_28 = _8456;\n                float param_29 = _8469;\n                float param_30 = _8573;\n                float3 area = fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n                if (_8508.on)\n                {\n                    FaLayers param_31 = _8508;\n                    float3 param_32 = area;\n                    int param_33 = _8543;\n                    float3 param_34 = _8445;\n                    float3 param_35 = _8385;\n                    float3 param_36 = _8559.direction;\n                    float param_37 = _8469;\n                    float param_38 = _8573;\n                    area = fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38);\n                }\n                lit += area;\n            }\n            else\n            {\n                if (_8508.on)\n                {\n                    FaLayers param_39 = _8508;\n                    float3 param_40 = _8485;\n                    float3 param_41 = f0;\n                    float3 param_42 = _8445;\n                    float3 param_43 = _8385;\n                    float3 param_44 = _8559.direction;\n                    float3 param_45 = _8578;\n                    float param_46 = _8567;\n                    float param_47 = _8469;\n                    float param_48 = _8583;\n                    float param_49 = _8588;\n                    float param_50 = _8460;\n                    float param_51 = _8464;\n                    int param_52 = _8543;\n                    lit += (fa_layers_light(param_39, param_40, param_41, param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51) * ((fa_light_rgb(param_52) * fa_light_tint) * _8573));\n                }\n                else\n                {\n                    float _8697 = ((_8583 * _8583) * (_8464 - 1.0f)) + 1.0f;\n                    int param_53 = _8543;\n                    lit += (((_8485 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _8588, 5.0f))) * (((_8464 / ((3.1415927410125732421875f * _8697) * _8697)) * (0.5f / max(lerp((2.0f * _8567) * _8469, _8567 + _8469, _8460), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _8567))) * (fa_light_rgb(param_53) * fa_light_tint)) * (_8567 * _8573));\n                }\n            }\n        }\n        if (_8508.on)\n        {\n            FaLayers param_54 = _8508;\n            float3 param_55 = _8445;\n            float3 param_56 = _8385;\n            float3 param_57 = f0;\n            float param_58 = _8456;\n            float param_59 = _9135;\n            lit += fa_layers_ibl(param_54, param_55, param_56, param_57, param_58, param_59);\n        }\n        else\n        {\n            float3 param_60 = _8445;\n            float3 param_61 = _8385;\n            float3 param_62 = f0;\n            float param_63 = _8456;\n            lit += (fa_sky_reflection(param_60, param_61, param_62, param_63) * _9135);\n        }\n        if (_8476 > 0.0f)\n        {\n            float _8795;\n            if (_8508.on)\n            {\n                _8795 = _8508.f90;\n            }\n            else\n            {\n                _8795 = 1.0f;\n            }\n            float _8803;\n            if (_8508.on)\n            {\n                _8803 = _8508.base_scale;\n            }\n            else\n            {\n                _8803 = 1.0f;\n            }\n            Surface _9252 = { _9130, _9131, _9132, _9133, _9134, _9135, _9136, _9137, _9138, _9139, _9140, _9141, _9142, _9143, _9144, _9145, _9146, _9147, _9148, _9149 };\n            Surface param_64 = _9252;\n            float3 param_65 = _8445;\n            float3 param_66 = _8385;\n            float param_67 = _8456;\n            float3 param_68 = f0;\n            float param_69 = _8795;\n            float param_70 = _8803;\n            float param_71 = _8476;\n            float param_72 = fa_tr_blend;\n            float3 _8827 = fa_transmitted(param_64, param_65, param_66, param_67, param_68, param_69, param_70, param_71, param_72);\n            fa_tr_blend = param_72;\n            lit += _8827;\n        }\n        result = lit;\n    }\n    float3 _8834 = result;\n    float3 _8835 = _8834 + _9136;\n    result = _8835;\n    float3 param_73 = _8835;\n    float3 param_74 = fa_world_pos;\n    result = fa_shadow_debug(param_73, param_74);\n    bool _8844 = _602_fa_fog.w > 0.0f;\n    bool _8851;\n    if (!_8844)\n    {\n        _8851 = _602_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _8851 = _8844;\n    }\n    if (_8851)\n    {\n        float3 _8860 = fa_world_pos - _602_fa_camera_pos.xyz;\n        float _8866 = dot(_8860, _602_fa_fog_c.xyz);\n        bool _8870 = _602_fa_fog_c.w > 0.5f;\n        float _8871;\n        if (_8870)\n        {\n            _8871 = _8866;\n        }\n        else\n        {\n            _8871 = length(_8860);\n        }\n        float _8883 = _8871 - _602_fa_fog_b.x;\n        if (_8883 > 0.0f)\n        {\n            float _8892 = _602_fa_fog.w * _8883;\n            float tau = _8892 * _8892;\n            if (_602_fa_fog_b.y > 0.0f)\n            {\n                float _8908;\n                if (_8870)\n                {\n                    _8908 = fa_world_pos.y - (_602_fa_fog_c.y * _8866);\n                }\n                else\n                {\n                    _8908 = _602_fa_camera_pos.y;\n                }\n                float _8929 = lerp(_8908, fa_world_pos.y, clamp(_602_fa_fog_b.x / _8871, 0.0f, 1.0f));\n                float _8933 = fa_world_pos.y - _8929;\n                float _8938 = _8929 - _602_fa_fog_b.z;\n                float _8943 = fa_world_pos.y - _602_fa_fog_b.z;\n                bool _8946 = _8938 <= 0.0f;\n                bool _8947 = !_8946;\n                bool _8953;\n                if (_8947)\n                {\n                    _8953 = _602_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _8953 = _8946;\n                }\n                float _8954;\n                if (_8953)\n                {\n                    _8954 = _602_fa_fog_b.y;\n                }\n                else\n                {\n                    _8954 = _602_fa_fog_b.y * exp(-min(_602_fa_fog_b.w * _8938, 80.0f));\n                }\n                bool _8981;\n                if (_8947)\n                {\n                    _8981 = _602_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _8981 = _8946;\n                }\n                float _8982;\n                if (_8981)\n                {\n                    _8982 = _602_fa_fog_b.y * _8938;\n                }\n                else\n                {\n                    _8982 = (_602_fa_fog_b.y * (1.0f - exp(-min(_602_fa_fog_b.w * _8938, 80.0f)))) / _602_fa_fog_b.w;\n                }\n                bool _9007 = _8943 <= 0.0f;\n                bool _9014;\n                if (!_9007)\n                {\n                    _9014 = _602_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _9014 = _9007;\n                }\n                float _9015;\n                if (_9014)\n                {\n                    _9015 = _602_fa_fog_b.y * _8943;\n                }\n                else\n                {\n                    _9015 = (_602_fa_fog_b.y * (1.0f - exp(-min(_602_fa_fog_b.w * _8943, 80.0f)))) / _602_fa_fog_b.w;\n                }\n                float _9042;\n                if (abs(_8933) < 0.001000000047497451305389404296875f)\n                {\n                    _9042 = _8954;\n                }\n                else\n                {\n                    _9042 = (_9015 - _8982) / _8933;\n                }\n                tau += (_8883 * max(_9042, 0.0f));\n            }\n            result = lerp(result, _602_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    if (fa_tr_blend > 0.0f)\n    {\n        float _9078 = 1.0f - fa_tr_blend;\n        result /= _9078.xxx;\n        _9131 *= _9078;\n    }\n    fa_frag_color = float4(result, _9131);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_602",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2346",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_8421",
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
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 6
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
              "hlsl_register_t_n": 7
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
              "hlsl_register_t_n": 8
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
              "hlsl_register_t_n": 9
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
              "hlsl_register_t_n": 10
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
              "hlsl_register_t_n": 11
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
              "hlsl_register_t_n": 12
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
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 2
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
            "sampler_slot": 10
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10
          },
          {
            "slot": 11,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1
          },
          {
            "slot": 12,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _57_fa_view_proj : packoffset(c0);\n    row_major float4x4 _57_fa_light_vp : packoffset(c4);\n    float4 _57_fa_uv_scale : packoffset(c8);\n    float4 _57_fa_time : packoffset(c9);\n    float4 _57_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_vel_params : register(b2)\n{\n    row_major float4x4 _225_fa_vel_vp : packoffset(c0);\n    row_major float4x4 _225_fa_vel_prev_vp : packoffset(c4);\n    float4 _225_fa_vel_on : packoffset(c8);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float3 fa_vel_cur;\nstatic float3 fa_vel_prev;\nstatic float4 fa_prev_r0;\nstatic float4 fa_prev_r1;\nstatic float4 fa_prev_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_prev_r0 : TEXCOORD9;\n    float4 fa_prev_r1 : TEXCOORD10;\n    float4 fa_prev_r2 : TEXCOORD11;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float3 fa_vel_cur : TEXCOORD9;\n    float3 fa_vel_prev : TEXCOORD10;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4 fa_time_now()\n{\n    return _57_fa_time;\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _97 = cross(model[1].xyz, model[2].xyz);\n    float _101 = (dot(model[0].xyz, _97) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _457 = { mul(float4(position, 1.0f), model).xyz, (((_97 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _101, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _101), texcoord0 * _57_fa_uv_scale.xy, color, position };\n    return _457;\n}\n\nfloat4x4 fa_rows_to_mat4(float4 r0, float4 r1, float4 r2)\n{\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nfloat4x4 fa_prev_model()\n{\n    float4 param = fa_prev_r0;\n    float4 param_1 = fa_prev_r1;\n    float4 param_2 = fa_prev_r2;\n    return fa_rows_to_mat4(param, param_1, param_2);\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color, bool has_prev)\n{\n    bool _231;\n    if (has_prev)\n    {\n        _231 = _225_fa_vel_on.x > 0.5f;\n    }\n    else\n    {\n        _231 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _246 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _464 = _246.world_pos;\n    float4 _257 = float4(_464, 1.0f);\n    fa_world_pos = _464;\n    fa_world_normal = _246.world_normal;\n    fa_world_tangent = _246.world_tangent;\n    fa_uv = _246.uv;\n    fa_vertex_color = _246.color;\n    fa_pre_depth = -mul(_257, _57_fa_light_vp).z;\n    fa_pre_r0 = float3(_57_fa_light_vp[0].x, _57_fa_light_vp[1].x, _57_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_57_fa_light_vp[0].y, _57_fa_light_vp[1].y, _57_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_57_fa_light_vp[0].z, _57_fa_light_vp[1].z, _57_fa_light_vp[2].z);\n    gl_Position = mul(_257, _57_fa_view_proj);\n    fa_vel_cur = float3(0.0f, 0.0f, 1.0f);\n    fa_vel_prev = 0.0f.xxx;\n    if (_231)\n    {\n        float4 _330 = float4(position, 1.0f);\n        fa_vel_cur = float3(mul(_257, _225_fa_vel_vp).xyw);\n        fa_vel_prev = float3(mul(float4((_464 + mul(_330, fa_prev_model()).xyz) - mul(_330, model).xyz, 1.0f), _225_fa_vel_prev_vp).xyw);\n    }\n}\n\nvoid vert_main()\n{\n    fa_vtime = 0.0f.xxxx;\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    bool param_6 = true;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, param_6);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_prev_r0 = stage_input.fa_prev_r0;\n    fa_prev_r1 = stage_input.fa_prev_r1;\n    fa_prev_r2 = stage_input.fa_prev_r2;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    stage_output.fa_vel_cur = fa_vel_cur;\n    stage_output.fa_vel_prev = fa_vel_prev;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _129_fa_camera_pos : packoffset(c0);\n    float4 _129_fa_ambient : packoffset(c1);\n    float4 _129_fa_base_color : packoffset(c2);\n    float4 _129_fa_emissive : packoffset(c3);\n    float4 _129_fa_model_emissive : packoffset(c4);\n    float4 _129_fa_pbr : packoffset(c5);\n    float4 _129_fa_maps : packoffset(c6);\n    float4 _129_fa_fog : packoffset(c7);\n    float4 _129_fa_fog_b : packoffset(c8);\n    float4 _129_fa_fog_c : packoffset(c9);\n    float4 _129_fa_counts : packoffset(c10);\n    float4 _129_fa_env_sky : packoffset(c11);\n    float4 _129_fa_env_horizon : packoffset(c12);\n    float4 _129_fa_time : packoffset(c13);\n    float4 _129_fa_cl_vpx : packoffset(c14);\n    float4 _129_fa_cl_vpy : packoffset(c15);\n    float4 _129_fa_cl_vpw : packoffset(c16);\n    float4 _129_fa_cl_fwd : packoffset(c17);\n    float4 _129_fa_cl_grid : packoffset(c18);\n    float4 _129_fa_cl_info : packoffset(c19);\n    float4 _129_fa_layers_a : packoffset(c20);\n    float4 _129_fa_layers_b : packoffset(c21);\n    float4 _129_fa_layers_c : packoffset(c22);\n    float4 _129_fa_layers_d : packoffset(c23);\n    float4 _129_fa_ct_a : packoffset(c24);\n    float4 _129_fa_ct_b : packoffset(c25);\n    float4 _129_fa_ct_vpx : packoffset(c26);\n    float4 _129_fa_ct_vpy : packoffset(c27);\n    float4 _129_fa_ct_vpw : packoffset(c28);\n    float4 _129_fa_ct_fwd : packoffset(c29);\n    float4 _129_fa_tr_a : packoffset(c30);\n    float4 _129_fa_tr_b : packoffset(c31);\n    float4 _129_fa_probe_sh[9] : packoffset(c32);\n    float4 _129_fa_atlas : packoffset(c41);\n    float4 _129_fa_rpa_tile : packoffset(c42);\n    float4 _129_fa_rpa_pos : packoffset(c43);\n    float4 _129_fa_rpa_bx : packoffset(c44);\n    float4 _129_fa_rpa_by : packoffset(c45);\n    float4 _129_fa_rpa_bz : packoffset(c46);\n    float4 _129_fa_rpb_tile : packoffset(c47);\n    float4 _129_fa_rpb_pos : packoffset(c48);\n    float4 _129_fa_rpb_bx : packoffset(c49);\n    float4 _129_fa_rpb_by : packoffset(c50);\n    float4 _129_fa_rpb_bz : packoffset(c51);\n    float4 _129_fa_gi : packoffset(c52);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _616_alphaCutoff : packoffset(c0);\n    float _616_fa_pad0 : packoffset(c0.y);\n    float _616_fa_pad1 : packoffset(c0.z);\n    float _616_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> mask : register(t5);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\nstatic float3 fa_vel_cur;\nstatic float3 fa_vel_prev;\nstatic float2 fa_frag_velocity;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float3 fa_vel_cur : TEXCOORD9;\n    float3 fa_vel_prev : TEXCOORD10;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n    float2 fa_frag_velocity : SV_Target1;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _237 = fa_linear_to_srgb(param);\n        c = _237;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _246 = fa_srgb_to_linear(param_1);\n            c = _246;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _58;\n    if (i.front_facing)\n    {\n        _58 = i.world_normal;\n    }\n    else\n    {\n        _58 = -i.world_normal;\n    }\n    float3 _83 = normalize(i.world_tangent.xyz - (_58 * dot(_58, i.world_tangent.xyz)));\n    float3 _111 = normalize(((_83 * m.x) + ((cross(_58, _83) * i.world_tangent.w) * m.y)) + (_58 * m.z));\n    float3 _114;\n    if (i.front_facing)\n    {\n        _114 = _111;\n    }\n    else\n    {\n        _114 = -_111;\n    }\n    return _114;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _129_fa_env_horizon.w);\n    float param = _129_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _282 = fa_tex_fix(param_2, param_3);\n    float4 _901 = base_t;\n    _901.x = _282.x;\n    _901.y = _282.y;\n    _901.z = _282.z;\n    base_t = _901;\n    float4 _298 = (_901 * _129_fa_base_color) * i.vertex_color;\n    float3 _856 = i.world_normal;\n    if (_129_fa_maps.z > 0.5f)\n    {\n        float param_4 = _129_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _129_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _334 = fa_tex_fix(param_6, param_7);\n        float3 _337 = (_334 * 2.0f) - 1.0f.xxx;\n        float2 _342 = _337.xy * _129_fa_maps.x;\n        float3 _909 = _337;\n        _909.x = _342.x;\n        _909.y = _342.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _909;\n        _856 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _129_fa_env_horizon.w);\n    float param_10 = _129_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _373 = fa_tex_fix(param_12, param_13);\n    float4 _912 = mrt;\n    _912.x = _373.x;\n    _912.y = _373.y;\n    _912.z = _373.z;\n    mrt = _912;\n    float4 _405 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _129_fa_env_horizon.w);\n    float param_14 = _129_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _405.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _417 = fa_tex_fix(param_16, param_17);\n    float param_18 = _129_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _129_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _449 = fa_tex_fix(param_20, param_21);\n    float _861 = _129_fa_layers_a.x;\n    float _862 = _129_fa_layers_a.y;\n    float _865 = _129_fa_layers_a.z;\n    float _864 = _129_fa_layers_b.w;\n    float _867 = _129_fa_layers_c.x;\n    if (_129_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_129_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _861 *= _417.y;\n            _862 *= _417.z;\n            _864 *= _405.w;\n        }\n        if (_129_fa_layers_c.z > 1.5f)\n        {\n            _865 *= mrt.x;\n            _867 *= mrt.w;\n        }\n    }\n    Surface _894 = { _298.xyz, _298.w, _856, clamp(_129_fa_pbr.x * _373.z, 0.0f, 1.0f), clamp(_129_fa_pbr.y * _373.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_129_fa_maps.y * (_417.x - 1.0f)), _129_fa_emissive.xyz + (_129_fa_model_emissive.xyz * _449), _861, _862, _129_fa_layers_b.xyz, _864, _865, _129_fa_layers_a.w, _867, _129_fa_layers_c.y, _129_fa_layers_d.xyz, _129_fa_tr_a.x, _129_fa_tr_a.y, _129_fa_tr_b.xyz, _129_fa_tr_a.z };\n    return _894;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nvoid fa_lod_dither()\n{\n    if (_129_fa_gi.w != 0.0f)\n    {\n        float _151 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n        bool _154;\n        if (_129_fa_gi.w > 0.0f)\n        {\n            _154 = _151 >= _129_fa_gi.w;\n        }\n        else\n        {\n            _154 = _151 < (-_129_fa_gi.w);\n        }\n        if (_154)\n        {\n            discard;\n        }\n    }\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _751 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _751 = -_751;\n    }\n    float3 _600 = normalize(_129_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _764 = { fa_world_pos, _751, fa_world_tangent, fa_uv, fa_vertex_color, _600, gl_FrontFacing };\n    SurfaceInput param = _764;\n    Surface _605 = fa_standard_surface(param);\n    float3 _775 = _605.normal;\n    SurfaceInput _772 = { fa_world_pos, _751, fa_world_tangent, fa_uv, fa_vertex_color, _600, gl_FrontFacing };\n    SurfaceInput param_1 = _772;\n    Surface param_2 = _605;\n    surface(param_1, param_2);\n    _775 = param_2.normal;\n    if (param_2.alpha < _616_alphaCutoff)\n    {\n        discard;\n    }\n    fa_lod_dither();\n    float3 _627 = normalize(_775);\n    float3 _642 = normalize(float3(dot(fa_pre_r0, _627), dot(fa_pre_r1, _627), dot(fa_pre_r2, _627)));\n    float _654 = _642.z;\n    float2 e = _642.xy / ((abs(_642.x) + abs(_642.y)) + abs(_654)).xx;\n    if (_654 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n    float2 motion = 1024.0f.xx;\n    bool _698 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06f;\n    bool _705;\n    if (_698)\n    {\n        _705 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06f;\n    }\n    else\n    {\n        _705 = _698;\n    }\n    if (_705)\n    {\n        motion = clamp(((float2(fa_vel_prev.x, -fa_vel_prev.y) / fa_vel_prev.z.xx) * 0.5f) - ((float2(fa_vel_cur.x, -fa_vel_cur.y) / fa_vel_cur.z.xx) * 0.5f), (-4.0f).xx, 4.0f.xx);\n    }\n    fa_frag_velocity = motion;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    fa_vel_cur = stage_input.fa_vel_cur;\n    fa_vel_prev = stage_input.fa_vel_prev;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    stage_output.fa_frag_velocity = fa_frag_velocity;\n    return stage_output;\n}\n",
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
            "inst_name": "_129",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_616",
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
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 5
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 2
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    },
    "prepass_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _74_fa_view_proj : packoffset(c0);\n    row_major float4x4 _74_fa_light_vp : packoffset(c4);\n    float4 _74_fa_uv_scale : packoffset(c8);\n    float4 _74_fa_time : packoffset(c9);\n    float4 _74_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _213_fa_joint_rows[192] : packoffset(c0);\n};\n\ncbuffer fa_vel_params : register(b2)\n{\n    row_major float4x4 _470_fa_vel_vp : packoffset(c0);\n    row_major float4x4 _470_fa_vel_prev_vp : packoffset(c4);\n    float4 _470_fa_vel_on : packoffset(c8);\n};\n\nTexture2D<float4> fa_prev_pal_tex : register(t0);\nSamplerState fa_prev_pal_smp : register(s11);\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float3 fa_vel_cur;\nstatic float3 fa_vel_prev;\nstatic float4 fa_prev_r0;\nstatic float4 fa_prev_r1;\nstatic float4 fa_prev_r2;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n    float4 fa_prev_r0 : TEXCOORD11;\n    float4 fa_prev_r1 : TEXCOORD12;\n    float4 fa_prev_r2 : TEXCOORD13;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float3 fa_vel_cur : TEXCOORD9;\n    float3 fa_vel_prev : TEXCOORD10;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _204 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_213_fa_joint_rows[_204] * weights[i]);\n        r1 += (_213_fa_joint_rows[_204 + 1] * weights[i]);\n        r2 += (_213_fa_joint_rows[_204 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nfloat4 fa_time_now()\n{\n    return _74_fa_time;\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _113 = cross(model[1].xyz, model[2].xyz);\n    float _117 = (dot(model[0].xyz, _113) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _718 = { mul(float4(position, 1.0f), model).xyz, (((_113 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _117, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _117), texcoord0 * _74_fa_uv_scale.xy, color, position };\n    return _718;\n}\n\nfloat4x4 fa_rows_to_mat4(float4 r0, float4 r1, float4 r2)\n{\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nfloat4 fa_prev_pal_texel(int t)\n{\n    return fa_prev_pal_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4x4 fa_prev_skin_matrix(float4 joints, float4 weights, int base)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _332 = base + (int((joints[i] * 255.0f) + 0.5f) * 3);\n        int param = _332;\n        r0 += (fa_prev_pal_texel(param) * weights[i]);\n        int param_1 = _332 + 1;\n        r1 += (fa_prev_pal_texel(param_1) * weights[i]);\n        int param_2 = _332 + 2;\n        r2 += (fa_prev_pal_texel(param_2) * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nfloat4x4 fa_prev_model()\n{\n    float4 param = fa_prev_r0;\n    float4 param_1 = fa_prev_r1;\n    float4 param_2 = fa_prev_r2;\n    float4 param_3 = fa_joints;\n    float4 param_4 = fa_weights;\n    int param_5 = int(_470_fa_vel_on.w + 0.5f);\n    return mul(fa_prev_skin_matrix(param_3, param_4, param_5), fa_rows_to_mat4(param, param_1, param_2));\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color, bool has_prev)\n{\n    bool _475;\n    if (has_prev)\n    {\n        _475 = _470_fa_vel_on.x > 0.5f;\n    }\n    else\n    {\n        _475 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _490 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _725 = _490.world_pos;\n    float4 _501 = float4(_725, 1.0f);\n    fa_world_pos = _725;\n    fa_world_normal = _490.world_normal;\n    fa_world_tangent = _490.world_tangent;\n    fa_uv = _490.uv;\n    fa_vertex_color = _490.color;\n    fa_pre_depth = -mul(_501, _74_fa_light_vp).z;\n    fa_pre_r0 = float3(_74_fa_light_vp[0].x, _74_fa_light_vp[1].x, _74_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_74_fa_light_vp[0].y, _74_fa_light_vp[1].y, _74_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_74_fa_light_vp[0].z, _74_fa_light_vp[1].z, _74_fa_light_vp[2].z);\n    gl_Position = mul(_501, _74_fa_view_proj);\n    fa_vel_cur = float3(0.0f, 0.0f, 1.0f);\n    fa_vel_prev = 0.0f.xxx;\n    if (_475)\n    {\n        float4 _574 = float4(position, 1.0f);\n        fa_vel_cur = float3(mul(_501, _470_fa_vel_vp).xyw);\n        fa_vel_prev = float3(mul(float4((_725 + mul(_574, fa_prev_model()).xyz) - mul(_574, model).xyz, 1.0f), _470_fa_vel_prev_vp).xyw);\n    }\n}\n\nvoid vert_main()\n{\n    fa_vtime = 0.0f.xxxx;\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    bool param_8 = _470_fa_vel_on.z > 0.5f;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, param_8);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_prev_r0 = stage_input.fa_prev_r0;\n    fa_prev_r1 = stage_input.fa_prev_r1;\n    fa_prev_r2 = stage_input.fa_prev_r2;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    stage_output.fa_vel_cur = fa_vel_cur;\n    stage_output.fa_vel_prev = fa_vel_prev;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _129_fa_camera_pos : packoffset(c0);\n    float4 _129_fa_ambient : packoffset(c1);\n    float4 _129_fa_base_color : packoffset(c2);\n    float4 _129_fa_emissive : packoffset(c3);\n    float4 _129_fa_model_emissive : packoffset(c4);\n    float4 _129_fa_pbr : packoffset(c5);\n    float4 _129_fa_maps : packoffset(c6);\n    float4 _129_fa_fog : packoffset(c7);\n    float4 _129_fa_fog_b : packoffset(c8);\n    float4 _129_fa_fog_c : packoffset(c9);\n    float4 _129_fa_counts : packoffset(c10);\n    float4 _129_fa_env_sky : packoffset(c11);\n    float4 _129_fa_env_horizon : packoffset(c12);\n    float4 _129_fa_time : packoffset(c13);\n    float4 _129_fa_cl_vpx : packoffset(c14);\n    float4 _129_fa_cl_vpy : packoffset(c15);\n    float4 _129_fa_cl_vpw : packoffset(c16);\n    float4 _129_fa_cl_fwd : packoffset(c17);\n    float4 _129_fa_cl_grid : packoffset(c18);\n    float4 _129_fa_cl_info : packoffset(c19);\n    float4 _129_fa_layers_a : packoffset(c20);\n    float4 _129_fa_layers_b : packoffset(c21);\n    float4 _129_fa_layers_c : packoffset(c22);\n    float4 _129_fa_layers_d : packoffset(c23);\n    float4 _129_fa_ct_a : packoffset(c24);\n    float4 _129_fa_ct_b : packoffset(c25);\n    float4 _129_fa_ct_vpx : packoffset(c26);\n    float4 _129_fa_ct_vpy : packoffset(c27);\n    float4 _129_fa_ct_vpw : packoffset(c28);\n    float4 _129_fa_ct_fwd : packoffset(c29);\n    float4 _129_fa_tr_a : packoffset(c30);\n    float4 _129_fa_tr_b : packoffset(c31);\n    float4 _129_fa_probe_sh[9] : packoffset(c32);\n    float4 _129_fa_atlas : packoffset(c41);\n    float4 _129_fa_rpa_tile : packoffset(c42);\n    float4 _129_fa_rpa_pos : packoffset(c43);\n    float4 _129_fa_rpa_bx : packoffset(c44);\n    float4 _129_fa_rpa_by : packoffset(c45);\n    float4 _129_fa_rpa_bz : packoffset(c46);\n    float4 _129_fa_rpb_tile : packoffset(c47);\n    float4 _129_fa_rpb_pos : packoffset(c48);\n    float4 _129_fa_rpb_bx : packoffset(c49);\n    float4 _129_fa_rpb_by : packoffset(c50);\n    float4 _129_fa_rpb_bz : packoffset(c51);\n    float4 _129_fa_gi : packoffset(c52);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _616_alphaCutoff : packoffset(c0);\n    float _616_fa_pad0 : packoffset(c0.y);\n    float _616_fa_pad1 : packoffset(c0.z);\n    float _616_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> mask : register(t5);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\nstatic float3 fa_vel_cur;\nstatic float3 fa_vel_prev;\nstatic float2 fa_frag_velocity;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float3 fa_vel_cur : TEXCOORD9;\n    float3 fa_vel_prev : TEXCOORD10;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n    float2 fa_frag_velocity : SV_Target1;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _237 = fa_linear_to_srgb(param);\n        c = _237;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _246 = fa_srgb_to_linear(param_1);\n            c = _246;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _58;\n    if (i.front_facing)\n    {\n        _58 = i.world_normal;\n    }\n    else\n    {\n        _58 = -i.world_normal;\n    }\n    float3 _83 = normalize(i.world_tangent.xyz - (_58 * dot(_58, i.world_tangent.xyz)));\n    float3 _111 = normalize(((_83 * m.x) + ((cross(_58, _83) * i.world_tangent.w) * m.y)) + (_58 * m.z));\n    float3 _114;\n    if (i.front_facing)\n    {\n        _114 = _111;\n    }\n    else\n    {\n        _114 = -_111;\n    }\n    return _114;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _129_fa_env_horizon.w);\n    float param = _129_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _282 = fa_tex_fix(param_2, param_3);\n    float4 _901 = base_t;\n    _901.x = _282.x;\n    _901.y = _282.y;\n    _901.z = _282.z;\n    base_t = _901;\n    float4 _298 = (_901 * _129_fa_base_color) * i.vertex_color;\n    float3 _856 = i.world_normal;\n    if (_129_fa_maps.z > 0.5f)\n    {\n        float param_4 = _129_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _129_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _334 = fa_tex_fix(param_6, param_7);\n        float3 _337 = (_334 * 2.0f) - 1.0f.xxx;\n        float2 _342 = _337.xy * _129_fa_maps.x;\n        float3 _909 = _337;\n        _909.x = _342.x;\n        _909.y = _342.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _909;\n        _856 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _129_fa_env_horizon.w);\n    float param_10 = _129_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _373 = fa_tex_fix(param_12, param_13);\n    float4 _912 = mrt;\n    _912.x = _373.x;\n    _912.y = _373.y;\n    _912.z = _373.z;\n    mrt = _912;\n    float4 _405 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _129_fa_env_horizon.w);\n    float param_14 = _129_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _405.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _417 = fa_tex_fix(param_16, param_17);\n    float param_18 = _129_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _129_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _449 = fa_tex_fix(param_20, param_21);\n    float _861 = _129_fa_layers_a.x;\n    float _862 = _129_fa_layers_a.y;\n    float _865 = _129_fa_layers_a.z;\n    float _864 = _129_fa_layers_b.w;\n    float _867 = _129_fa_layers_c.x;\n    if (_129_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_129_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _861 *= _417.y;\n            _862 *= _417.z;\n            _864 *= _405.w;\n        }\n        if (_129_fa_layers_c.z > 1.5f)\n        {\n            _865 *= mrt.x;\n            _867 *= mrt.w;\n        }\n    }\n    Surface _894 = { _298.xyz, _298.w, _856, clamp(_129_fa_pbr.x * _373.z, 0.0f, 1.0f), clamp(_129_fa_pbr.y * _373.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_129_fa_maps.y * (_417.x - 1.0f)), _129_fa_emissive.xyz + (_129_fa_model_emissive.xyz * _449), _861, _862, _129_fa_layers_b.xyz, _864, _865, _129_fa_layers_a.w, _867, _129_fa_layers_c.y, _129_fa_layers_d.xyz, _129_fa_tr_a.x, _129_fa_tr_a.y, _129_fa_tr_b.xyz, _129_fa_tr_a.z };\n    return _894;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nvoid fa_lod_dither()\n{\n    if (_129_fa_gi.w != 0.0f)\n    {\n        float _151 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n        bool _154;\n        if (_129_fa_gi.w > 0.0f)\n        {\n            _154 = _151 >= _129_fa_gi.w;\n        }\n        else\n        {\n            _154 = _151 < (-_129_fa_gi.w);\n        }\n        if (_154)\n        {\n            discard;\n        }\n    }\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _751 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _751 = -_751;\n    }\n    float3 _600 = normalize(_129_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _764 = { fa_world_pos, _751, fa_world_tangent, fa_uv, fa_vertex_color, _600, gl_FrontFacing };\n    SurfaceInput param = _764;\n    Surface _605 = fa_standard_surface(param);\n    float3 _775 = _605.normal;\n    SurfaceInput _772 = { fa_world_pos, _751, fa_world_tangent, fa_uv, fa_vertex_color, _600, gl_FrontFacing };\n    SurfaceInput param_1 = _772;\n    Surface param_2 = _605;\n    surface(param_1, param_2);\n    _775 = param_2.normal;\n    if (param_2.alpha < _616_alphaCutoff)\n    {\n        discard;\n    }\n    fa_lod_dither();\n    float3 _627 = normalize(_775);\n    float3 _642 = normalize(float3(dot(fa_pre_r0, _627), dot(fa_pre_r1, _627), dot(fa_pre_r2, _627)));\n    float _654 = _642.z;\n    float2 e = _642.xy / ((abs(_642.x) + abs(_642.y)) + abs(_654)).xx;\n    if (_654 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n    float2 motion = 1024.0f.xx;\n    bool _698 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06f;\n    bool _705;\n    if (_698)\n    {\n        _705 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06f;\n    }\n    else\n    {\n        _705 = _698;\n    }\n    if (_705)\n    {\n        motion = clamp(((float2(fa_vel_prev.x, -fa_vel_prev.y) / fa_vel_prev.z.xx) * 0.5f) - ((float2(fa_vel_cur.x, -fa_vel_cur.y) / fa_vel_cur.z.xx) * 0.5f), (-4.0f).xx, 4.0f.xx);\n    }\n    fa_frag_velocity = motion;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    fa_vel_cur = stage_input.fa_vel_cur;\n    fa_vel_prev = stage_input.fa_vel_prev;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    stage_output.fa_frag_velocity = fa_frag_velocity;\n    return stage_output;\n}\n",
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
            "inst_name": "_129",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_616",
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
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 5
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
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 2
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
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    },
    "shadow": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _122_fa_view_proj : packoffset(c0);\n    row_major float4x4 _122_fa_light_vp : packoffset(c4);\n    float4 _122_fa_uv_scale : packoffset(c8);\n    float4 _122_fa_time : packoffset(c9);\n    float4 _122_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float3 fa_normal : TEXCOORD5;\n    float2 fa_texcoord0 : TEXCOORD6;\n    float4 fa_tangent : TEXCOORD7;\n    float4 fa_color : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _60 = cross(model[1].xyz, model[2].xyz);\n    float _66 = (dot(model[0].xyz, _60) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _256 = { mul(float4(position, 1.0f), model).xyz, (((_60 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _66, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _66), texcoord0 * _122_fa_uv_scale.xy, color, position };\n    return _256;\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    VertexData _190 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _239 = _190.world_pos;\n    fa_world_pos = _239;\n    fa_world_normal = _190.world_normal;\n    fa_world_tangent = _190.world_tangent;\n    fa_uv = _190.uv;\n    fa_vertex_color = _190.color;\n    gl_Position = mul(float4(_239, 1.0f), _122_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _226_fa_camera_pos : packoffset(c0);\n    float4 _226_fa_ambient : packoffset(c1);\n    float4 _226_fa_base_color : packoffset(c2);\n    float4 _226_fa_emissive : packoffset(c3);\n    float4 _226_fa_model_emissive : packoffset(c4);\n    float4 _226_fa_pbr : packoffset(c5);\n    float4 _226_fa_maps : packoffset(c6);\n    float4 _226_fa_fog : packoffset(c7);\n    float4 _226_fa_fog_b : packoffset(c8);\n    float4 _226_fa_fog_c : packoffset(c9);\n    float4 _226_fa_counts : packoffset(c10);\n    float4 _226_fa_env_sky : packoffset(c11);\n    float4 _226_fa_env_horizon : packoffset(c12);\n    float4 _226_fa_time : packoffset(c13);\n    float4 _226_fa_cl_vpx : packoffset(c14);\n    float4 _226_fa_cl_vpy : packoffset(c15);\n    float4 _226_fa_cl_vpw : packoffset(c16);\n    float4 _226_fa_cl_fwd : packoffset(c17);\n    float4 _226_fa_cl_grid : packoffset(c18);\n    float4 _226_fa_cl_info : packoffset(c19);\n    float4 _226_fa_layers_a : packoffset(c20);\n    float4 _226_fa_layers_b : packoffset(c21);\n    float4 _226_fa_layers_c : packoffset(c22);\n    float4 _226_fa_layers_d : packoffset(c23);\n    float4 _226_fa_ct_a : packoffset(c24);\n    float4 _226_fa_ct_b : packoffset(c25);\n    float4 _226_fa_ct_vpx : packoffset(c26);\n    float4 _226_fa_ct_vpy : packoffset(c27);\n    float4 _226_fa_ct_vpw : packoffset(c28);\n    float4 _226_fa_ct_fwd : packoffset(c29);\n    float4 _226_fa_tr_a : packoffset(c30);\n    float4 _226_fa_tr_b : packoffset(c31);\n    float4 _226_fa_probe_sh[9] : packoffset(c32);\n    float4 _226_fa_atlas : packoffset(c41);\n    float4 _226_fa_rpa_tile : packoffset(c42);\n    float4 _226_fa_rpa_pos : packoffset(c43);\n    float4 _226_fa_rpa_bx : packoffset(c44);\n    float4 _226_fa_rpa_by : packoffset(c45);\n    float4 _226_fa_rpa_bz : packoffset(c46);\n    float4 _226_fa_rpb_tile : packoffset(c47);\n    float4 _226_fa_rpb_pos : packoffset(c48);\n    float4 _226_fa_rpb_bx : packoffset(c49);\n    float4 _226_fa_rpb_by : packoffset(c50);\n    float4 _226_fa_rpb_bz : packoffset(c51);\n    float4 _226_fa_gi : packoffset(c52);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _577_alphaCutoff : packoffset(c0);\n    float _577_fa_pad0 : packoffset(c0.y);\n    float _577_fa_pad1 : packoffset(c0.z);\n    float _577_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> mask : register(t5);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _226_fa_env_horizon.w);\n    float param = _226_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _242 = fa_tex_fix(param_2, param_3);\n    float4 _744 = base_t;\n    _744.x = _242.x;\n    _744.y = _242.y;\n    _744.z = _242.z;\n    base_t = _744;\n    float4 _258 = (_744 * _226_fa_base_color) * i.vertex_color;\n    float3 _705 = i.world_normal;\n    if (_226_fa_maps.z > 0.5f)\n    {\n        float param_4 = _226_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _226_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _294 = fa_tex_fix(param_6, param_7);\n        float3 _297 = (_294 * 2.0f) - 1.0f.xxx;\n        float2 _302 = _297.xy * _226_fa_maps.x;\n        float3 _752 = _297;\n        _752.x = _302.x;\n        _752.y = _302.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _752;\n        _705 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _226_fa_env_horizon.w);\n    float param_10 = _226_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _333 = fa_tex_fix(param_12, param_13);\n    float4 _755 = mrt;\n    _755.x = _333.x;\n    _755.y = _333.y;\n    _755.z = _333.z;\n    mrt = _755;\n    float4 _365 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _226_fa_env_horizon.w);\n    float param_14 = _226_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _365.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _377 = fa_tex_fix(param_16, param_17);\n    float param_18 = _226_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _226_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _409 = fa_tex_fix(param_20, param_21);\n    float _710 = _226_fa_layers_a.x;\n    float _711 = _226_fa_layers_a.y;\n    float _714 = _226_fa_layers_a.z;\n    float _713 = _226_fa_layers_b.w;\n    float _716 = _226_fa_layers_c.x;\n    if (_226_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_226_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _710 *= _377.y;\n            _711 *= _377.z;\n            _713 *= _365.w;\n        }\n        if (_226_fa_layers_c.z > 1.5f)\n        {\n            _714 *= mrt.x;\n            _716 *= mrt.w;\n        }\n    }\n    Surface _743 = { _258.xyz, _258.w, _705, clamp(_226_fa_pbr.x * _333.z, 0.0f, 1.0f), clamp(_226_fa_pbr.y * _333.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_226_fa_maps.y * (_377.x - 1.0f)), _226_fa_emissive.xyz + (_226_fa_model_emissive.xyz * _409), _710, _711, _226_fa_layers_b.xyz, _713, _714, _226_fa_layers_a.w, _716, _226_fa_layers_c.y, _226_fa_layers_d.xyz, _226_fa_tr_a.x, _226_fa_tr_a.y, _226_fa_tr_b.xyz, _226_fa_tr_a.z };\n    return _743;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _600 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _600 = -_600;\n    }\n    float3 _561 = normalize(_226_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _613 = { fa_world_pos, _600, fa_world_tangent, fa_uv, fa_vertex_color, _561, gl_FrontFacing };\n    SurfaceInput param = _613;\n    SurfaceInput _621 = { fa_world_pos, _600, fa_world_tangent, fa_uv, fa_vertex_color, _561, gl_FrontFacing };\n    SurfaceInput param_1 = _621;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    if (param_2.alpha < _577_alphaCutoff)\n    {\n        discard;\n    }\n    fa_frag_color = float4(gl_FragCoord.z, 0.0f, 0.0f, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 1
          },
          {
            "slot": 2,
            "type": "vec4",
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
            "type": "vec3",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 5
          },
          {
            "slot": 6,
            "type": "vec2",
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
            "inst_name": "_122",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_226",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_577",
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
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 5
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 2
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _127_fa_view_proj : packoffset(c0);\n    row_major float4x4 _127_fa_light_vp : packoffset(c4);\n    float4 _127_fa_uv_scale : packoffset(c8);\n    float4 _127_fa_time : packoffset(c9);\n    float4 _127_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _174_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float4 fa_joints : TEXCOORD5;\n    float4 fa_weights : TEXCOORD6;\n    float3 fa_normal : TEXCOORD7;\n    float2 fa_texcoord0 : TEXCOORD8;\n    float4 fa_tangent : TEXCOORD9;\n    float4 fa_color : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _165 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_174_fa_joint_rows[_165] * weights[i]);\n        r1 += (_174_fa_joint_rows[_165 + 1] * weights[i]);\n        r2 += (_174_fa_joint_rows[_165 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _65 = cross(model[1].xyz, model[2].xyz);\n    float _71 = (dot(model[0].xyz, _65) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _377 = { mul(float4(position, 1.0f), model).xyz, (((_65 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _71, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _71), texcoord0 * _127_fa_uv_scale.xy, color, position };\n    return _377;\n}\n\nvoid vert_main()\n{\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    fa_inst_begin();\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    VertexData _311 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    float3 _360 = _311.world_pos;\n    fa_world_pos = _360;\n    fa_world_normal = _311.world_normal;\n    fa_world_tangent = _311.world_tangent;\n    fa_uv = _311.uv;\n    fa_vertex_color = _311.color;\n    gl_Position = mul(float4(_360, 1.0f), _127_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _226_fa_camera_pos : packoffset(c0);\n    float4 _226_fa_ambient : packoffset(c1);\n    float4 _226_fa_base_color : packoffset(c2);\n    float4 _226_fa_emissive : packoffset(c3);\n    float4 _226_fa_model_emissive : packoffset(c4);\n    float4 _226_fa_pbr : packoffset(c5);\n    float4 _226_fa_maps : packoffset(c6);\n    float4 _226_fa_fog : packoffset(c7);\n    float4 _226_fa_fog_b : packoffset(c8);\n    float4 _226_fa_fog_c : packoffset(c9);\n    float4 _226_fa_counts : packoffset(c10);\n    float4 _226_fa_env_sky : packoffset(c11);\n    float4 _226_fa_env_horizon : packoffset(c12);\n    float4 _226_fa_time : packoffset(c13);\n    float4 _226_fa_cl_vpx : packoffset(c14);\n    float4 _226_fa_cl_vpy : packoffset(c15);\n    float4 _226_fa_cl_vpw : packoffset(c16);\n    float4 _226_fa_cl_fwd : packoffset(c17);\n    float4 _226_fa_cl_grid : packoffset(c18);\n    float4 _226_fa_cl_info : packoffset(c19);\n    float4 _226_fa_layers_a : packoffset(c20);\n    float4 _226_fa_layers_b : packoffset(c21);\n    float4 _226_fa_layers_c : packoffset(c22);\n    float4 _226_fa_layers_d : packoffset(c23);\n    float4 _226_fa_ct_a : packoffset(c24);\n    float4 _226_fa_ct_b : packoffset(c25);\n    float4 _226_fa_ct_vpx : packoffset(c26);\n    float4 _226_fa_ct_vpy : packoffset(c27);\n    float4 _226_fa_ct_vpw : packoffset(c28);\n    float4 _226_fa_ct_fwd : packoffset(c29);\n    float4 _226_fa_tr_a : packoffset(c30);\n    float4 _226_fa_tr_b : packoffset(c31);\n    float4 _226_fa_probe_sh[9] : packoffset(c32);\n    float4 _226_fa_atlas : packoffset(c41);\n    float4 _226_fa_rpa_tile : packoffset(c42);\n    float4 _226_fa_rpa_pos : packoffset(c43);\n    float4 _226_fa_rpa_bx : packoffset(c44);\n    float4 _226_fa_rpa_by : packoffset(c45);\n    float4 _226_fa_rpa_bz : packoffset(c46);\n    float4 _226_fa_rpb_tile : packoffset(c47);\n    float4 _226_fa_rpb_pos : packoffset(c48);\n    float4 _226_fa_rpb_bx : packoffset(c49);\n    float4 _226_fa_rpb_by : packoffset(c50);\n    float4 _226_fa_rpb_bz : packoffset(c51);\n    float4 _226_fa_gi : packoffset(c52);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _577_alphaCutoff : packoffset(c0);\n    float _577_fa_pad0 : packoffset(c0.y);\n    float _577_fa_pad1 : packoffset(c0.z);\n    float _577_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> mask : register(t5);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _226_fa_env_horizon.w);\n    float param = _226_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _242 = fa_tex_fix(param_2, param_3);\n    float4 _744 = base_t;\n    _744.x = _242.x;\n    _744.y = _242.y;\n    _744.z = _242.z;\n    base_t = _744;\n    float4 _258 = (_744 * _226_fa_base_color) * i.vertex_color;\n    float3 _705 = i.world_normal;\n    if (_226_fa_maps.z > 0.5f)\n    {\n        float param_4 = _226_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _226_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _294 = fa_tex_fix(param_6, param_7);\n        float3 _297 = (_294 * 2.0f) - 1.0f.xxx;\n        float2 _302 = _297.xy * _226_fa_maps.x;\n        float3 _752 = _297;\n        _752.x = _302.x;\n        _752.y = _302.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _752;\n        _705 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _226_fa_env_horizon.w);\n    float param_10 = _226_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _333 = fa_tex_fix(param_12, param_13);\n    float4 _755 = mrt;\n    _755.x = _333.x;\n    _755.y = _333.y;\n    _755.z = _333.z;\n    mrt = _755;\n    float4 _365 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _226_fa_env_horizon.w);\n    float param_14 = _226_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _365.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _377 = fa_tex_fix(param_16, param_17);\n    float param_18 = _226_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _226_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _409 = fa_tex_fix(param_20, param_21);\n    float _710 = _226_fa_layers_a.x;\n    float _711 = _226_fa_layers_a.y;\n    float _714 = _226_fa_layers_a.z;\n    float _713 = _226_fa_layers_b.w;\n    float _716 = _226_fa_layers_c.x;\n    if (_226_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_226_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _710 *= _377.y;\n            _711 *= _377.z;\n            _713 *= _365.w;\n        }\n        if (_226_fa_layers_c.z > 1.5f)\n        {\n            _714 *= mrt.x;\n            _716 *= mrt.w;\n        }\n    }\n    Surface _743 = { _258.xyz, _258.w, _705, clamp(_226_fa_pbr.x * _333.z, 0.0f, 1.0f), clamp(_226_fa_pbr.y * _333.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_226_fa_maps.y * (_377.x - 1.0f)), _226_fa_emissive.xyz + (_226_fa_model_emissive.xyz * _409), _710, _711, _226_fa_layers_b.xyz, _713, _714, _226_fa_layers_a.w, _716, _226_fa_layers_c.y, _226_fa_layers_d.xyz, _226_fa_tr_a.x, _226_fa_tr_a.y, _226_fa_tr_b.xyz, _226_fa_tr_a.z };\n    return _743;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _600 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _600 = -_600;\n    }\n    float3 _561 = normalize(_226_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _613 = { fa_world_pos, _600, fa_world_tangent, fa_uv, fa_vertex_color, _561, gl_FrontFacing };\n    SurfaceInput param = _613;\n    SurfaceInput _621 = { fa_world_pos, _600, fa_world_tangent, fa_uv, fa_vertex_color, _561, gl_FrontFacing };\n    SurfaceInput param_1 = _621;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    if (param_2.alpha < _577_alphaCutoff)\n    {\n        discard;\n    }\n    fa_frag_color = float4(gl_FragCoord.z, 0.0f, 0.0f, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 1
          },
          {
            "slot": 2,
            "type": "vec4",
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
            "type": "vec3",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 7
          },
          {
            "slot": 8,
            "type": "vec2",
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
            "inst_name": "_127",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_174",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_226",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_577",
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
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 5
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 2
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    }
  }
}
