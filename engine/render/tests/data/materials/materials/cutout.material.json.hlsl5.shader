{
  "format": "factoria.shader/1",
  "engine": "0.38.0",
  "template": "e0c1f830a27b422ba9d050f4a118de89d0d8c6a78e3cc09d7dad74ea546b40a2",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _4853[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _609_fa_camera_pos : packoffset(c0);\n    float4 _609_fa_ambient : packoffset(c1);\n    float4 _609_fa_base_color : packoffset(c2);\n    float4 _609_fa_emissive : packoffset(c3);\n    float4 _609_fa_model_emissive : packoffset(c4);\n    float4 _609_fa_pbr : packoffset(c5);\n    float4 _609_fa_maps : packoffset(c6);\n    float4 _609_fa_fog : packoffset(c7);\n    float4 _609_fa_fog_b : packoffset(c8);\n    float4 _609_fa_fog_c : packoffset(c9);\n    float4 _609_fa_counts : packoffset(c10);\n    float4 _609_fa_env_sky : packoffset(c11);\n    float4 _609_fa_env_horizon : packoffset(c12);\n    float4 _609_fa_time : packoffset(c13);\n    float4 _609_fa_cl_vpx : packoffset(c14);\n    float4 _609_fa_cl_vpy : packoffset(c15);\n    float4 _609_fa_cl_vpw : packoffset(c16);\n    float4 _609_fa_cl_fwd : packoffset(c17);\n    float4 _609_fa_cl_grid : packoffset(c18);\n    float4 _609_fa_cl_info : packoffset(c19);\n    float4 _609_fa_layers_a : packoffset(c20);\n    float4 _609_fa_layers_b : packoffset(c21);\n    float4 _609_fa_layers_c : packoffset(c22);\n    float4 _609_fa_layers_d : packoffset(c23);\n    float4 _609_fa_ct_a : packoffset(c24);\n    float4 _609_fa_ct_b : packoffset(c25);\n    float4 _609_fa_ct_vpx : packoffset(c26);\n    float4 _609_fa_ct_vpy : packoffset(c27);\n    float4 _609_fa_ct_vpw : packoffset(c28);\n    float4 _609_fa_ct_fwd : packoffset(c29);\n    float4 _609_fa_tr_a : packoffset(c30);\n    float4 _609_fa_tr_b : packoffset(c31);\n    float4 _609_fa_probe_sh[9] : packoffset(c32);\n    float4 _609_fa_atlas : packoffset(c41);\n    float4 _609_fa_rpa_tile : packoffset(c42);\n    float4 _609_fa_rpa_pos : packoffset(c43);\n    float4 _609_fa_rpa_bx : packoffset(c44);\n    float4 _609_fa_rpa_by : packoffset(c45);\n    float4 _609_fa_rpa_bz : packoffset(c46);\n    float4 _609_fa_rpb_tile : packoffset(c47);\n    float4 _609_fa_rpb_pos : packoffset(c48);\n    float4 _609_fa_rpb_bx : packoffset(c49);\n    float4 _609_fa_rpb_by : packoffset(c50);\n    float4 _609_fa_rpb_bz : packoffset(c51);\n    float4 _609_fa_gi : packoffset(c52);\n    float4 _609_fa_gi_px : packoffset(c53);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2353_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2353_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2353_fa_shadow_info[4] : packoffset(c20);\n    float4 _2353_fa_shadow_split : packoffset(c24);\n    float4 _2353_fa_shadow_cfg : packoffset(c25);\n    float4 _2353_fa_shadow_bias : packoffset(c26);\n    float4 _2353_fa_shadow_eye : packoffset(c27);\n    float4 _2353_fa_shadow_fwd : packoffset(c28);\n    float4 _2353_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _8790_alphaCutoff : packoffset(c0);\n    float _8790_fa_pad0 : packoffset(c0.y);\n    float _8790_fa_pad1 : packoffset(c0.z);\n    float _8790_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t11);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_screen_tex : register(t12);\nTexture2D<float4> fa_probe_atlas : register(t7);\nTexture2D<float4> mask : register(t6);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t10);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1635 = _609_fa_cl_info.x < 0.0f;\n    bool _1642;\n    if (!_1635)\n    {\n        _1642 = _609_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1642 = _1635;\n    }\n    bool _1650;\n    if (!_1642)\n    {\n        _1650 = _609_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1650 = _1642;\n    }\n    bool _1657;\n    if (!_1650)\n    {\n        _1657 = _609_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1657 = _1650;\n    }\n    bool _1664;\n    if (!_1657)\n    {\n        _1664 = _609_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1664 = _1657;\n    }\n    if (_1664)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1674 = float4(world_pos, 1.0f);\n    float _1680 = dot(_609_fa_cl_vpw, _1674);\n    if (!(_1680 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1702 = float2(dot(_609_fa_cl_vpx, _1674), dot(_609_fa_cl_vpy, _1674)) / _1680.xx;\n    int _1706 = int(_609_fa_cl_grid.x);\n    int _1710 = int(_609_fa_cl_grid.y);\n    int param = (int(_609_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_609_fa_cl_fwd.xyz, world_pos) + _609_fa_cl_fwd.w, _609_fa_cl_grid.w) / _609_fa_cl_grid.w) * _609_fa_cl_grid.z)), 0, int(_609_fa_cl_info.y) - 1) * _1710) + clamp(int(floor(((_1702.y * 0.5f) + 0.5f) * _609_fa_cl_grid.y)), 0, _1710 - 1)) * _1706)) + clamp(int(floor(((_1702.x * 0.5f) + 0.5f) * _609_fa_cl_grid.x)), 0, _1706 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1786 = fa_cluster_texel(param);\n    return int2(int(_1786.x), int(_1786.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_609_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _6487 = fa_cluster_lookup(param);\n    fa_cl_slot = _6487.x;\n    fa_cl_local = _6487.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _7657 = fa_linear_to_srgb(param);\n        c = _7657;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _7665 = fa_srgb_to_linear(param_1);\n            c = _7665;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _541;\n    if (i.front_facing)\n    {\n        _541 = i.world_normal;\n    }\n    else\n    {\n        _541 = -i.world_normal;\n    }\n    float3 _565 = normalize(i.world_tangent.xyz - (_541 * dot(_541, i.world_tangent.xyz)));\n    float3 _592 = normalize(((_565 * m.x) + ((cross(_541, _565) * i.world_tangent.w) * m.y)) + (_541 * m.z));\n    float3 _595;\n    if (i.front_facing)\n    {\n        _595 = _592;\n    }\n    else\n    {\n        _595 = -_592;\n    }\n    return _595;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _609_fa_env_horizon.w);\n    float param = _609_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _7697 = fa_tex_fix(param_2, param_3);\n    float4 _10079 = base_t;\n    _10079.x = _7697.x;\n    _10079.y = _7697.y;\n    _10079.z = _7697.z;\n    base_t = _10079;\n    float4 _7711 = (_10079 * _609_fa_base_color) * i.vertex_color;\n    float3 _9829 = i.world_normal;\n    if (_609_fa_maps.z > 0.5f)\n    {\n        float param_4 = _609_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _609_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _7745 = fa_tex_fix(param_6, param_7);\n        float3 _7748 = (_7745 * 2.0f) - 1.0f.xxx;\n        float2 _7753 = _7748.xy * _609_fa_maps.x;\n        float3 _10087 = _7748;\n        _10087.x = _7753.x;\n        _10087.y = _7753.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _10087;\n        _9829 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _609_fa_env_horizon.w);\n    float param_10 = _609_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _7783 = fa_tex_fix(param_12, param_13);\n    float4 _10090 = mrt;\n    _10090.x = _7783.x;\n    _10090.y = _7783.y;\n    _10090.z = _7783.z;\n    mrt = _10090;\n    float4 _7813 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _609_fa_env_horizon.w);\n    float param_14 = _609_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _7813.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _7824 = fa_tex_fix(param_16, param_17);\n    float param_18 = _609_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _609_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _7856 = fa_tex_fix(param_20, param_21);\n    float _9834 = _609_fa_layers_a.x;\n    float _9835 = _609_fa_layers_a.y;\n    float _9838 = _609_fa_layers_a.z;\n    float _9837 = _609_fa_layers_b.w;\n    float _9840 = _609_fa_layers_c.x;\n    if (_609_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_609_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _9834 *= _7824.y;\n            _9835 *= _7824.z;\n            _9837 *= _7813.w;\n        }\n        if (_609_fa_layers_c.z > 1.5f)\n        {\n            _9838 *= mrt.x;\n            _9840 *= mrt.w;\n        }\n    }\n    Surface _9867 = { _7711.xyz, _7711.w, _9829, clamp(_609_fa_pbr.x * _7783.z, 0.0f, 1.0f), clamp(_609_fa_pbr.y * _7783.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_609_fa_maps.y * (_7824.x - 1.0f)), _609_fa_emissive.xyz + (_609_fa_model_emissive.xyz * _7856), _9834, _9835, _609_fa_layers_b.xyz, _9837, _9838, _609_fa_layers_a.w, _9840, _609_fa_layers_c.y, _609_fa_layers_d.xyz, _609_fa_tr_a.x, _609_fa_tr_a.y, _609_fa_tr_b.xyz, _609_fa_tr_a.z };\n    return _9867;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1866 = rect.zw - rect.xy;\n    float2 _1870 = _1866 * atlas;\n    float2 _1874 = ddx * _1870;\n    float2 _1878 = ddy * _1870;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1866), clamp(0.5f * log2(max(max(dot(_1874, _1874), dot(_1878, _1878)), 9.9999999392252902907785028219223e-09f)), 0.0f, 3.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1911 = _609_fa_counts.y < 0.5f;\n    bool _1918;\n    if (!_1911)\n    {\n        _1918 = _609_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1918 = _1911;\n    }\n    if (_1918)\n    {\n        return;\n    }\n    float3 _1924 = ddx(world_pos);\n    float3 _1927 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1931 = fa_cluster_texel(param);\n    int _1935 = int(_1931.w);\n    if (_1935 < 1)\n    {\n        return;\n    }\n    int _1945 = int(_609_fa_counts.y + 0.5f);\n    int param_1 = _1945;\n    float4 _1949 = fa_light_texel(param_1);\n    float2 _1952 = _1949.yz;\n    int _1956 = int(_1949.w);\n    int param_2 = _1945 + 1;\n    float4 _1961 = fa_light_texel(param_2);\n    float _1962 = _1961.x;\n    int _1968 = int(_609_fa_counts.w + 0.5f) - 1;\n    int _1972 = int(_1931.z);\n    float3 _2237;\n    for (int k = 0; k < _1935; k++)\n    {\n        int _1985 = _1972 + k;\n        int param_3 = _1956 + (_1985 >> 2);\n        int _2002 = (_1945 + 2) + (int(fa_light_texel(param_3)[_1985 & 3]) * 7);\n        int param_4 = _2002 + 6;\n        float4 _2007 = fa_light_texel(param_4);\n        if (((int(_2007.w + 0.5f) >> _1968) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _2002;\n        float4 _2022 = fa_light_texel(param_5);\n        int param_6 = _2002 + 1;\n        float4 _2027 = fa_light_texel(param_6);\n        int param_7 = _2002 + 2;\n        float4 _2032 = fa_light_texel(param_7);\n        float3 _2035 = _2022.xyz;\n        float _2040 = dot(_2035, world_pos) + _2022.w;\n        float3 _2042 = _2027.xyz;\n        float _2047 = dot(_2042, world_pos) + _2027.w;\n        float3 _2049 = _2032.xyz;\n        float _2054 = dot(_2049, world_pos) + _2032.w;\n        bool _2059 = abs(_2040) > 0.5f;\n        bool _2067;\n        if (!_2059)\n        {\n            _2067 = abs(_2047) > 0.5f;\n        }\n        else\n        {\n            _2067 = _2059;\n        }\n        bool _2075;\n        if (!_2067)\n        {\n            _2075 = abs(_2054) > 0.5f;\n        }\n        else\n        {\n            _2075 = _2067;\n        }\n        if (_2075)\n        {\n            continue;\n        }\n        float _2090 = clamp(dot(geo_normal, normalize(_2049)) * _2007.z, 0.0f, 1.0f);\n        if (_2090 <= 0.0f)\n        {\n            continue;\n        }\n        float _2110 = (clamp((0.5f - abs(_2054)) * 10.0f, 0.0f, 1.0f) * _2090) * _2007.x;\n        float2 _2118 = float2(_2040 + 0.5f, 0.5f - _2047);\n        float2 _2128 = float2(dot(_2035, _1924), dot(_2042, _1924));\n        float2 _2138 = float2(dot(_2035, _1927), dot(_2042, _1927));\n        int param_8 = _2002 + 5;\n        float4 _2143 = fa_light_texel(param_8);\n        int param_9 = _2002 + 3;\n        float4 _2148 = fa_light_texel(param_9);\n        int param_10 = _2002 + 4;\n        float4 _2153 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _2143.xyz;\n        bool _2163 = _2148.z > _2148.x;\n        if (_2163)\n        {\n            float4 param_11 = _2148;\n            float2 param_12 = _2118;\n            float2 param_13 = _1952;\n            float2 param_14 = _2128;\n            float2 param_15 = _2138;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1962 > 0.5f) && (_1962 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _2189 = fa_dc_to_linear(param_16);\n                float4 _9917 = tx;\n                _9917.x = _2189.x;\n                _9917.y = _2189.y;\n                _9917.z = _2189.z;\n                tx = _9917;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_2110 * tex_a) * _2143.w, 0.0f, 1.0f).xxx);\n        if (_2153.z > _2153.x)\n        {\n            float4 param_17 = _2153;\n            float2 param_18 = _2118;\n            float2 param_19 = _1952;\n            float2 param_20 = _2128;\n            float2 param_21 = _2138;\n            float4 _2233 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1962 > 1.5f)\n            {\n                float3 param_22 = _2233.xyz;\n                float3 _2243 = fa_dc_to_srgb(param_22);\n                _2237 = _2243;\n            }\n            else\n            {\n                _2237 = _2233.xyz;\n            }\n            float3 _2252 = (_2237 * 2.0f) - 1.0f.xxx;\n            float2 _2257 = _2252.xy * _2007.y;\n            float3 _2279 = (normalize(_2035) * _2257.x) + (normalize(_2042) * _2257.y);\n            float3 _2282 = normalize(normal);\n            normal = normalize(lerp(_2282, normalize((_2282 * max(_2252.z, 0.0500000007450580596923828125f)) + (_2279 - (_2282 * dot(_2282, _2279)))), clamp(_2110 * (_2163 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nvoid fa_lod_dither()\n{\n    if (_609_fa_gi.w != 0.0f)\n    {\n        float _631 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n        bool _634;\n        if (_609_fa_gi.w > 0.0f)\n        {\n            _634 = _631 >= _609_fa_gi.w;\n        }\n        else\n        {\n            _634 = _631 < (-_609_fa_gi.w);\n        }\n        if (_634)\n        {\n            discard;\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4778 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _4786 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _4789 = int(_4778);\n    int _4792 = int(_4786);\n    float _4802 = _4786 - float(_4792);\n    int _4857 = (_4789 * 9) + _4792;\n    int _4877 = ((_4789 + 1) * 9) + _4792;\n    return lerp(lerp(_4853[_4857], _4853[_4857 + 1], _4802), lerp(_4853[_4877], _4853[_4877 + 1], _4802), _4778 - float(_4789));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _9752 = false;\n    float _9753 = 1.0f;\n    float _9754 = 1.0f;\n    float _9755 = 1.0f;\n    float _9756 = 0.0f;\n    float _9757 = 0.0f;\n    float _9758 = 0.0f;\n    float _9759 = 0.0f;\n    float _9761 = 1.0f;\n    bool _9762 = false;\n    float3 _9763 = 0.0f.xxx;\n    float _9764 = 1.0f;\n    float _9765 = 1.0f;\n    float _9766 = 1.0f;\n    float _9767 = 0.0f;\n    float _9768 = 0.0f;\n    float3 _9769 = float3(1.0f, 0.0f, 0.0f);\n    float3 _9770 = float3(0.0f, 0.0f, 1.0f);\n    float _9771 = 1.0f;\n    float _9772 = 1.0f;\n    float _4928 = clamp(s.specular, 0.0f, 1.0f);\n    float _4932 = clamp(s.ior, 1.0f, 3.0f);\n    bool _4937 = (_4928 != 1.0f) || (_4932 != 1.5f);\n    bool _4946;\n    if (!_4937)\n    {\n        _4946 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _4946 = _4937;\n    }\n    if (_4946)\n    {\n        float _4954 = (_4932 - 1.0f) / (_4932 + 1.0f);\n        f0 = lerp(min((_4954 * _4954).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _4928, s.albedo, metallic.xxx);\n        _9753 = lerp(_4928, 1.0f, metallic);\n        _9752 = true;\n    }\n    float _4981 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_4981 > 0.0f)\n    {\n        float _4989 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _9756 = _4981;\n        _9757 = _4989;\n        float _4996 = _4989 * _4989;\n        _9758 = _4996;\n        _9759 = _4996 * _4996;\n        float _5008 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _9761 = _5008;\n        _9754 = 1.0f - (_4981 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _5008, 0.0f, 1.0f), 5.0f))));\n        _9752 = true;\n    }\n    float3 _5027 = max(s.sheen_color, 0.0f.xxx);\n    float _5036 = max(_5027.x, max(_5027.y, _5027.z));\n    if (_5036 > 0.0f)\n    {\n        float _5044 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _9762 = true;\n        _9763 = _5027;\n        _9764 = _5044;\n        _9765 = _5044 * _5044;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _5044;\n        float _5061 = fa_sheen_albedo(param, param_1);\n        _9767 = _5061;\n        _9766 = 1.0f - min(_5036 * _5061, 1.0f);\n        _9752 = true;\n    }\n    _9755 = _9754 * _9766;\n    float _5080 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_5080 != 0.0f)\n    {\n        float3 _5095 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _5095;\n        if (dot(_5095, _5095) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _5107 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_5107.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _5107.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _5107.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _5111 = t;\n        float3 _5112 = normalize(_5111);\n        t = _5112;\n        float3 _5137 = normalize((_5112 * cos(s.anisotropy_rotation)) + ((cross(n, _5112) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _9769 = _5137;\n        _9770 = cross(n, _5137);\n        float _5147 = roughness * roughness;\n        float _5153 = lerp(_5147, 1.0f, _5080 * _5080);\n        bool _5155 = _5080 > 0.0f;\n        _9771 = _5155 ? _5153 : _5147;\n        _9772 = _5155 ? _5147 : _5153;\n        _9768 = _5080;\n        _9752 = true;\n    }\n    FaLayers _9794 = { _9752, _9753, _9754, _9755, _9756, _9757, _9758, _9759, i.world_normal, _9761, _9762, _9763, _9764, _9765, _9766, _9767, _9768, _9769, _9770, _9771, _9772 };\n    return _9794;\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _4007_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _4007_dummy_parameter)));\n}\n\nfloat3 fa_probe_sh_coef(float2 origin, float res, int k)\n{\n    float3 v = fa_probe_atlas.SampleLevel(fa_env_smp, (origin + float2(float(k) + 0.5f, res + 2.5f)) / fa_atlas_size(), 0.0f).xyz;\n    if (_609_fa_atlas.y > 0.5f)\n    {\n        v = ((v * 255.0f) - 128.0f.xxx) * 0.03149606287479400634765625f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3948 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3948;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    float _4559 = (1.0f - _609_fa_rpa_tile.w) - _609_fa_rpb_tile.w;\n    float3 amb = 0.0f.xxx;\n    bool _4564 = _609_fa_env_sky.w > 0.5f;\n    float3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = 0.0f.xxx;\n    }\n    if (_4559 > 0.0005000000237487256526947021484375f)\n    {\n        if (_4564)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _609_fa_atlas.zw;\n                float param_1 = 128.0f;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4559;\n            }\n        }\n        else\n        {\n            amb = _609_fa_ambient.xyz * _4559;\n        }\n    }\n    bool _4615 = _609_fa_rpa_tile.w > 0.0f;\n    if (_4615)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _609_fa_rpa_tile.xy;\n            float param_4 = _609_fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * _609_fa_rpa_tile.w);\n        }\n    }\n    bool _4646 = _609_fa_rpb_tile.w > 0.0f;\n    if (_4646)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _609_fa_rpb_tile.xy;\n            float param_7 = _609_fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * _609_fa_rpb_tile.w);\n        }\n    }\n    if ((_4564 || _4615) || _4646)\n    {\n        float3 param_9[9] = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nfloat4 fa_gi_fetch(float2 texel)\n{\n    return fa_probe_atlas.SampleLevel(fa_env_smp, texel / fa_atlas_size(), 0.0f);\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3968 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3971 = _3968.x;\n    float _3973 = _3968.z;\n    float2 e = float2(_3971, _3973);\n    if (_3968.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3973)) * ((_3971 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3971)) * ((_3973 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat3 fa_gi_grid(int rec, float3 n, float3 v, out float cover)\n{\n    cover = 0.0f;\n    int param = rec;\n    float4 _7966 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    float4 _7971 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    float4 _7976 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    float4 _7981 = fa_light_texel(param_3);\n    bool _7984 = _7981.z < 0.5f;\n    bool _7992;\n    if (!_7984)\n    {\n        _7992 = fa_atlas_size().y < 1155.0f;\n    }\n    else\n    {\n        _7992 = _7984;\n    }\n    if (_7992)\n    {\n        return 0.0f.xxx;\n    }\n    float _7999 = max(_7966.w, 9.9999997473787516355514526367188e-05f);\n    float3 _8002 = _7971.xyz;\n    float3 _8006 = _7966.xyz;\n    float3 _8010 = (fa_world_pos - _8006) / _7999.xxx;\n    float3 _8019 = min(_8010 + 0.5f.xxx, (_8002 - 0.5f.xxx) - _8010);\n    float _8028 = min(_8019.x, min(_8019.y, _8019.z));\n    if (!(_8028 > 0.0f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _8043 = _8002 - 1.0f.xxx;\n    float3 _8044 = clamp(_8010, 0.0f.xxx, _8043);\n    float3 _8052 = min(floor(_8044), max(_8002 - 2.0f.xxx, 0.0f.xxx));\n    float3 _8056 = _8044 - _8052;\n    float3 _8067 = fa_world_pos + (((n * 0.800000011920928955078125f) + (v * 0.20000000298023223876953125f)) * (0.20000000298023223876953125f * _7999));\n    int _8072 = int(_7976.y + 0.5f);\n    float _8077 = 0.3257350027561187744140625f * n.y;\n    float _8081 = 0.3257350027561187744140625f * n.z;\n    float _8085 = 0.3257350027561187744140625f * n.x;\n    float _8092 = (0.2731371223926544189453125f * n.x) * n.y;\n    float _8099 = (0.2731371223926544189453125f * n.y) * n.z;\n    float _8108 = 0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f);\n    float _8115 = (0.2731371223926544189453125f * n.x) * n.z;\n    float _8128 = 0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y));\n    float3 acc = 0.0f.xxx;\n    float wsum = 0.0f;\n    int _8135 = 8 + int(_7981.w);\n    float _8162;\n    float _8175;\n    float _8189;\n    for (int k = 0; k < _8135; k++)\n    {\n        float _8148 = float(k & 1);\n        float _8152 = float((k >> 1) & 1);\n        float _8156 = float((k >> 2) & 1);\n        if (_8148 > 0.5f)\n        {\n            _8162 = _8056.x;\n        }\n        else\n        {\n            _8162 = 1.0f - _8056.x;\n        }\n        if (_8152 > 0.5f)\n        {\n            _8175 = _8056.y;\n        }\n        else\n        {\n            _8175 = 1.0f - _8056.y;\n        }\n        if (_8156 > 0.5f)\n        {\n            _8189 = _8056.z;\n        }\n        else\n        {\n            _8189 = 1.0f - _8056.z;\n        }\n        float _8199 = (_8162 * _8175) * _8189;\n        if (!(_8199 > 0.0f))\n        {\n            continue;\n        }\n        float3 _8212 = min(_8052 + float3(_8148, _8152, _8156), _8043);\n        int _8232 = int(((_7976.x + _8212.x) + (_7971.x * (_8212.y + (_7971.y * _8212.z)))) + 0.5f);\n        float2 _8247 = float2(float(_8232 % _8072) * 10.0f, 1024.0f + (float(_8232 / _8072) * 11.0f));\n        float2 param_4 = _8247 + float2(9.5f, 10.5f);\n        float4 _8255 = fa_gi_fetch(param_4);\n        bool _8258 = _8255.y < 0.5f;\n        bool _8267;\n        if (!_8258)\n        {\n            _8267 = _8255.x > _7981.y;\n        }\n        else\n        {\n            _8267 = _8258;\n        }\n        if (_8267)\n        {\n            continue;\n        }\n        float3 _8279 = _8067 - (_8006 + (_8212 * _7999));\n        float _8282 = length(_8279);\n        float3 _8288 = _8279 / max(_8282, 9.9999997473787516355514526367188e-05f).xxx;\n        float _8298 = max(9.9999997473787516355514526367188e-05f, (dot(-_8288, n) + 1.0f) * 0.5f);\n        float w = _8199 * (_8298 * _8298);\n        float3 param_5 = _8288;\n        float2 param_6 = (_8247 + 1.0f.xx) + (((fa_oct_encode(param_5) * 0.5f) + 0.5f.xx) * 8.0f);\n        float4 _8317 = fa_gi_fetch(param_6);\n        float _8324 = _8282 / max(_7976.z, 9.9999997473787516355514526367188e-05f);\n        float _8327 = _8317.x;\n        if (_8324 > _8327)\n        {\n            float _8340 = max(_8317.y - (_8327 * _8327), 0.0f);\n            float _8345 = _8324 - _8327;\n            float _8354 = _8340 / max(_8340 + (_8345 * _8345), 9.9999999600419720025001879548654e-13f);\n            w *= ((_8354 * _8354) * _8354);\n        }\n        if (!(w > 0.0f))\n        {\n            continue;\n        }\n        float2 param_7 = _8247 + float2(0.5f, 10.5f);\n        float2 param_8 = _8247 + float2(1.5f, 10.5f);\n        float2 param_9 = _8247 + float2(2.5f, 10.5f);\n        float2 param_10 = _8247 + float2(3.5f, 10.5f);\n        float2 param_11 = _8247 + float2(4.5f, 10.5f);\n        float2 param_12 = _8247 + float2(5.5f, 10.5f);\n        float2 param_13 = _8247 + float2(6.5f, 10.5f);\n        float2 param_14 = _8247 + float2(7.5f, 10.5f);\n        float2 param_15 = _8247 + float2(8.5f, 10.5f);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375f) + (fa_gi_fetch(param_8).xyz * _8077)) + (fa_gi_fetch(param_9).xyz * _8081)) + (fa_gi_fetch(param_10).xyz * _8085)) + (fa_gi_fetch(param_11).xyz * _8092)) + (fa_gi_fetch(param_12).xyz * _8099)) + (fa_gi_fetch(param_13).xyz * _8108)) + (fa_gi_fetch(param_14).xyz * _8115)) + (fa_gi_fetch(param_15).xyz * _8128)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06f))\n    {\n        return 0.0f.xxx;\n    }\n    cover = smoothstep(0.0f, 1.0f, clamp(_8028 * 2.0f, 0.0f, 1.0f)) * smoothstep(0.0f, 0.0199999995529651641845703125f, wsum);\n    float _8478;\n    if (_609_fa_gi.z > 0.5f)\n    {\n        _8478 = _7981.x;\n    }\n    else\n    {\n        _8478 = 1.0f;\n    }\n    return max(acc / wsum.xxx, 0.0f.xxx) * (_7976.w * _8478);\n}\n\nfloat3 fa_gi_light(float3 n, inout float left)\n{\n    left = 1.0f;\n    float3 acc = 0.0f.xxx;\n    float3 _8502 = normalize(_609_fa_camera_pos.xyz - fa_world_pos);\n    int _8507 = int(_609_fa_gi.x + 0.5f);\n    int _8512 = int(_609_fa_gi.y + 0.5f);\n    float param_3;\n    for (int k = 0; (k < _8512) && (k < 8); k++)\n    {\n        int param = _8507 + (4 * k);\n        float3 param_1 = n;\n        float3 param_2 = _8502;\n        float3 _8537 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _8542 = param_3 * left;\n        acc += (_8537 * _8542);\n        left -= _8542;\n        if (left < 0.001000000047497451305389404296875f)\n        {\n            left = 0.0f;\n            break;\n        }\n    }\n    return acc;\n}\n\nfloat3 fa_realtime_or_ambient(float3 n)\n{\n    float3 gi = 0.0f.xxx;\n    float left = 1.0f;\n    if (_609_fa_gi.y > 0.5f)\n    {\n        float3 param = n;\n        float param_1;\n        float3 _8571 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _8571;\n    }\n    if (left <= 0.0f)\n    {\n        return gi;\n    }\n    float3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_609_fa_gi_px.x > 0.5f)\n    {\n        float4 _8613 = float4(fa_world_pos, 1.0f);\n        float2 _8632 = float2(dot(_609_fa_ct_vpx, _8613), dot(_609_fa_ct_vpy, _8613)) / max(dot(_609_fa_ct_vpw, _8613), 9.9999997473787516355514526367188e-05f).xx;\n        float _8641;\n        if (_609_fa_ct_a.y > 0.5f)\n        {\n            _8641 = (_8632.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _8641 = 0.5f - (_8632.y * 0.5f);\n        }\n        return fa_lightmap.Load(int3(clamp(int2(float2((_8632.x * 0.5f) + 0.5f, _8641) * _609_fa_ct_a.zw), int2(0, 0), int2(_609_fa_ct_a.zw) - int2(1, 1)), 0)).xyz;\n    }\n    if (_609_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _609_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_609_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_609_fa_cl_info.x) + int(_609_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_609_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _6457;\n    if (fa_lm.z > 0.5f)\n    {\n        _6457 = 0.0f;\n    }\n    else\n    {\n        _6457 = 1.0f - clamp(_609_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _6468 = _6457 < 1.0f;\n    bool _6474;\n    if (_6468)\n    {\n        int param = li;\n        _6474 = fa_light_baked(param);\n    }\n    else\n    {\n        _6474 = _6468;\n    }\n    return _6474 ? _6457 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _765_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _765_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _884 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _897 = (c - (ru * hx)) - p;\n        float3 _903 = ru * (2.0f * hx);\n        float _909 = max(dot(_903, _903), 9.9999999392252902907785028219223e-09f);\n        float _913 = dot(_897, _903);\n        float t = clamp((-_913) / _909, 0.0f, 1.0f);\n        if (_884)\n        {\n            float _928 = dot(r, _903);\n            float _934 = _909 - (_928 * _928);\n            if (abs(_934) > (9.9999997473787516355514526367188e-06f * _909))\n            {\n                t = clamp(((dot(r, _897) * _928) - _913) / _934, 0.0f, 1.0f);\n            }\n        }\n        return (p + _897) + (_903 * t);\n    }\n    float3 q = p;\n    float _966 = dot(r, axis);\n    bool _974;\n    if (_884)\n    {\n        _974 = abs(_966) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _974 = _884;\n    }\n    if (_974)\n    {\n        float _984 = dot(c - p, axis) / _966;\n        if (_984 > 0.0f)\n        {\n            q = p + (r * _984);\n        }\n    }\n    float3 _997 = q - c;\n    float2 xy = float2(dot(_997, ru), dot(_997, uu));\n    if (shape > 0.5f)\n    {\n        float _1012 = length(xy);\n        if (_1012 > hx)\n        {\n            xy *= (hx / _1012);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _651 = abs(d);\n    float _653 = _651.x;\n    float _655 = _651.y;\n    bool _656 = _653 >= _655;\n    bool _664;\n    if (_656)\n    {\n        _664 = _653 >= _651.z;\n    }\n    else\n    {\n        _664 = _656;\n    }\n    int _665;\n    if (_664)\n    {\n        _665 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _679;\n        if (_655 >= _651.z)\n        {\n            _679 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _679 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _665 = _679;\n    }\n    return _665;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _804 = dot(d, right);\n    float _808 = dot(d, up);\n    float _819;\n    if (((_804 * _804) + (_808 * _808)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _819 = atan2(_808, _804) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _819 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_819 - floor(_819)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _1050 = fa_light_base(param);\n    bool _1054 = _609_fa_ambient.w > 4.5f;\n    int param_1 = _1050;\n    float4 _1058 = fa_light_texel(param_1);\n    int param_2 = _1050 + 1;\n    float4 _1063 = fa_light_texel(param_2);\n    float _1066 = _1063.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _1078 = _1054 && (_1066 > 2.5f);\n    fa_light_is_area = _1078;\n    bool _1080 = _1066 < 0.5f;\n    float3 l;\n    if (_1080)\n    {\n        l = normalize(_1058.xyz);\n        if (_1054)\n        {\n            int param_3 = _1050 + 6;\n            float4 _1094 = fa_light_texel(param_3);\n            if (_1094.z > 0.5f)\n            {\n                int param_4 = _1050 + 4;\n                float4 _1104 = fa_light_texel(param_4);\n                int param_5 = _1050 + 5;\n                float4 _1109 = fa_light_texel(param_5);\n                float2 param_6 = _1094.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _1104.xyz) * _1104.w, (-dot(world_pos, _1109.xyz)) * _1109.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _1139 = _1058.xyz;\n        float3 _1141 = _1139 - world_pos;\n        float3 to_light = _1141;\n        float _1144 = length(_1141);\n        float reach = _1144;\n        bool front = true;\n        if (_1078)\n        {\n            int param_8 = _1050 + 7;\n            reach = max(_1144 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _1050 + 4;\n            float4 _1168 = fa_light_texel(param_9);\n            int param_10 = _1050 + 5;\n            float4 _1173 = fa_light_texel(param_10);\n            int param_11 = _1050 + 6;\n            float4 _1178 = fa_light_texel(param_11);\n            float _1179 = _1178.w;\n            int param_12 = _1050 + 2;\n            float3 _1186 = normalize(fa_light_texel(param_12).xyz);\n            bool _1188 = _1179 > 1.5f;\n            bool _1196;\n            if (!_1188)\n            {\n                _1196 = dot(_1186, to_light) < 0.0f;\n            }\n            else\n            {\n                _1196 = _1188;\n            }\n            front = _1196;\n            float3 r = 0.0f.xxx;\n            float3 _1205 = _609_fa_camera_pos.xyz - world_pos;\n            bool _1209 = dot(n, n) > 0.5f;\n            bool _1217;\n            if (_1209)\n            {\n                _1217 = dot(_1205, _1205) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _1217 = _1209;\n            }\n            if (_1217)\n            {\n                r = reflect(-normalize(_1205), normalize(n));\n            }\n            float3 param_13 = _1139;\n            float3 param_14 = _1186;\n            float3 param_15 = _1168.xyz;\n            float3 param_16 = _1173.xyz;\n            float param_17 = _1168.w;\n            float param_18 = _1173.w;\n            float param_19 = _1179;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1253 = length(to_light);\n        dist = _1253;\n        l = to_light / max(_1253, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1267 = reach / max(_1058.w, 0.001000000047497451305389404296875f);\n        float _1273 = clamp(1.0f - (_1267 * _1267), 0.0f, 1.0f);\n        float _1275;\n        if (front)\n        {\n            _1275 = _1273 * _1273;\n        }\n        else\n        {\n            _1275 = 0.0f;\n        }\n        atten = _1275;\n        bool _1286 = _1066 < 2.5f;\n        if ((_1066 > 1.5f) && _1286)\n        {\n            int param_22 = _1050 + 2;\n            float4 _1294 = fa_light_texel(param_22);\n            float _1304 = _1294.w;\n            int param_23 = _1050 + 3;\n            float4 _1309 = fa_light_texel(param_23);\n            float _1310 = _1309.x;\n            float cos_inner = _1310;\n            if (_1310 > 1.5f)\n            {\n                cos_inner = lerp(_1304, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1304, cos_inner, dot(-l, normalize(_1294.xyz)));\n        }\n        if (_1054 && (_1066 < 1.5f))\n        {\n            int param_24 = _1050 + 6;\n            float4 _1334 = fa_light_texel(param_24);\n            if (_1334.z > 0.5f)\n            {\n                float3 _1342 = -to_light;\n                int param_25 = _1050 + 4;\n                int param_26 = _1050 + 5;\n                float3 _1356 = fa_light_texel(param_25).xyz;\n                float3 _1360 = fa_light_texel(param_26).xyz;\n                float3 _1369 = float3(dot(_1342, _1356), dot(_1342, _1360), dot(_1342, cross(_1356, _1360)));\n                float3 param_27 = _1369;\n                int _1373 = fa_cube_face(param_27);\n                int param_28 = _1373;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1400 = float2(dot(_1369, cross(param_29, param_30)), dot(_1369, param_30)) / max(dot(_1369, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1404 = _1373 / 3;\n                float2 param_31 = _1334.xy + (float2(float(_1373 - (_1404 * 3)), float(_1404)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1400.x), 0.5f - (0.5f * _1400.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1050 + 7;\n            float4 _1434 = fa_light_texel(param_33);\n            if (_1434.z > 0.5f)\n            {\n                int param_34 = _1050 + 2;\n                int param_35 = _1050 + 4;\n                int param_36 = _1050 + 5;\n                float2 param_37 = _1434.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1054 && _1286)\n            {\n                int param_42 = _1050 + 6;\n                float4 _1481 = fa_light_texel(param_42);\n                int param_43 = _1050 + 7;\n                float4 _1486 = fa_light_texel(param_43);\n                bool _1489 = _1481.z > 0.5f;\n                bool _1496;\n                if (!_1489)\n                {\n                    _1496 = _1486.z > 0.5f;\n                }\n                else\n                {\n                    _1496 = _1489;\n                }\n                if (_1496)\n                {\n                    int param_44 = _1050 + 2;\n                    float4 _1503 = fa_light_texel(param_44);\n                    float3 _1507 = normalize(_1503.xyz);\n                    int param_45 = _1050 + 4;\n                    float4 _1512 = fa_light_texel(param_45);\n                    int param_46 = _1050 + 5;\n                    float4 _1517 = fa_light_texel(param_46);\n                    if (_1489)\n                    {\n                        float3 _1525 = -to_light;\n                        float _1532 = _1503.w;\n                        float _1548 = 0.5f / max(dot(_1525, _1507) * (sqrt(max(1.0f - (_1532 * _1532), 0.0f)) / max(_1532, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1481.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1525, _1512.xyz) * _1548), 0.5f - (dot(_1525, _1517.xyz) * _1548));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1486.z > 0.5f)\n                    {\n                        float2 param_49 = _1486.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1507;\n                        float3 param_52 = _1512.xyz;\n                        float3 param_53 = _1517.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _9740 = _1063.xyz * atten;\n    if (_1054)\n    {\n        _9740 *= fa_light_tint;\n    }\n    int _1617;\n    if (_1080)\n    {\n        _1617 = 0;\n    }\n    else\n    {\n        _1617 = ((_1066 > 1.5f) && (_1066 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _9751 = { l, _9740, atten, 1.0f, dist, _1617 };\n    return _9751;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2343;\n    if (i == 0)\n    {\n        _2343 = _2353_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2359;\n        if (i == 1)\n        {\n            _2359 = _2353_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2367;\n            if (i == 2)\n            {\n                _2367 = _2353_fa_shadow_split.z;\n            }\n            else\n            {\n                _2367 = _2353_fa_shadow_split.w;\n            }\n            _2359 = _2367;\n        }\n        _2343 = _2359;\n    }\n    return _2343;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2400 = fa_shadow_depth(param, param_1);\n    float _2404;\n    if (conv.x < 0.5f)\n    {\n        _2404 = _2400;\n    }\n    else\n    {\n        _2404 = (conv.y * conv.z) / (conv.z - (_2400 * (conv.z - conv.y)));\n    }\n    return _2404;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel_turn(float2 d)\n{\n    return float2((d.x * (-0.737368881702423095703125f)) - (d.y * 0.675490319728851318359375f), (d.y * (-0.737368881702423095703125f)) + (d.x * 0.675490319728851318359375f));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2450 = fa_shadow_noise() * 6.283185482025146484375f;\n    float2 _2456 = float2(cos(_2450), sin(_2450));\n    float2 dir = _2456;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2465;\n        if (k < 0.0f)\n        {\n            _2465 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2465 = k;\n        }\n        float _2484 = clamp((_2465 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2503 = sqrt((float(i) + 0.5f) * 0.0625f) * _2484;\n            float2 param_3 = uv + (dir * (_2353_fa_shadow_bias.zw * _2503));\n            float4 param_4 = rect;\n            float3 param_5 = conv;\n            float _2517 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2517 < (zr - (_2503 * plane)))\n            {\n                sum += _2517;\n                cnt += 1.0f;\n            }\n            float2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2545 = sum / cnt;\n        float _2555;\n        if (k < 0.0f)\n        {\n            _2555 = (-k) / max(_2545, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2555 = k;\n        }\n        radius = clamp(((max(zr - _2545, 0.0f) * unit) * _2555) / texel_m, 1.5f, 16.0f);\n        dir = _2456;\n    }\n    float lit = 0.0f;\n    int _2581 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2581; i_1++)\n    {\n        float _2600 = sqrt((float(i_1) + 0.5f) / float(_2581)) * radius;\n        float2 param_7 = uv + (dir * (_2353_fa_shadow_bias.zw * _2600));\n        float4 param_8 = rect;\n        float3 param_9 = conv;\n        lit += float((zr - (_2600 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        float2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2581);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2646 = max(_2353_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2651 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2657 = sqrt(1.0f - (_2651 * _2651));\n    float _2665 = min(_2657 / max(_2651, 0.20000000298023223876953125f), 4.0f);\n    float _2670;\n    if (_2353_fa_shadow_bias.y > 0.0f)\n    {\n        _2670 = _2353_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2670 = 1.5f * _2353_fa_shadow_info[ci].x;\n    }\n    float4 _2695 = mul(float4(world + (n * (_2670 * _2657)), 1.0f), _2353_fa_shadow_mat[ci]);\n    float _2702 = _2695.x;\n    bool _2705 = _2702 < _2353_fa_shadow_rect[ci].x;\n    bool _2714;\n    if (!_2705)\n    {\n        _2714 = _2702 > _2353_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2714 = _2705;\n    }\n    bool _2723;\n    if (!_2714)\n    {\n        _2723 = _2695.y < _2353_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2723 = _2714;\n    }\n    bool _2732;\n    if (!_2723)\n    {\n        _2732 = _2695.y > _2353_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2732 = _2723;\n    }\n    bool _2739;\n    if (!_2732)\n    {\n        _2739 = _2695.z > 1.0f;\n    }\n    else\n    {\n        _2739 = _2732;\n    }\n    if (_2739)\n    {\n        return -1.0f;\n    }\n    float _2747;\n    if (_2353_fa_shadow_bias.x > 0.0f)\n    {\n        _2747 = _2353_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2747 = 1.5f * _2353_fa_shadow_info[ci].x;\n    }\n    float2 param = _2695.xy;\n    float4 param_1 = _2353_fa_shadow_rect[ci];\n    float param_2 = _2695.z - ((_2747 * (1.0f + (0.5f * _2665))) / _2646);\n    float param_3 = _2353_fa_shadow_info[ci].x;\n    float param_4 = _2646;\n    float param_5 = _2646 * 0.25f;\n    float param_6 = ((_2353_fa_shadow_info[ci].x * min(_2665, 3.0f)) * 0.5f) / _2646;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2353_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2353_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_609_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _3125 = int(_2353_fa_shadow_cfg.x + 0.5f);\n    if (_3125 < 1)\n    {\n        return 1.0f;\n    }\n    float _3140 = dot(world - _2353_fa_shadow_eye.xyz, _2353_fa_shadow_fwd.xyz);\n    int param = _3125 - 1;\n    if (_3140 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _3152 = _3125 > 1;\n    bool _3159;\n    if (_3152)\n    {\n        _3159 = _3140 > _2353_fa_shadow_split.x;\n    }\n    else\n    {\n        _3159 = _3152;\n    }\n    if (_3159)\n    {\n        ci = 1;\n    }\n    bool _3163 = _3125 > 2;\n    bool _3170;\n    if (_3163)\n    {\n        _3170 = _3140 > _2353_fa_shadow_split.y;\n    }\n    else\n    {\n        _3170 = _3163;\n    }\n    if (_3170)\n    {\n        ci = 2;\n    }\n    bool _3174 = _3125 > 3;\n    bool _3181;\n    if (_3174)\n    {\n        _3181 = _3140 > _2353_fa_shadow_split.z;\n    }\n    else\n    {\n        _3181 = _3174;\n    }\n    if (_3181)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    float s2 = -1.0f;\n    float t = 0.0f;\n    int _3192 = min(_3125, 4);\n    float _3233;\n    for (int c = ci; c < _3192; c++)\n    {\n        int param_1 = c;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _3212 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0f)\n        {\n            s2 = _3212;\n            break;\n        }\n        if (_3212 < 0.0f)\n        {\n            continue;\n        }\n        s = _3212;\n        ci = c;\n        if (_2353_fa_shadow_cfg.y > 0.0f)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3233 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3233 = _2353_fa_shadow_fwd.w;\n            }\n            int param_6 = ci;\n            float _3252 = _2353_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3233, 9.9999997473787516355514526367188e-05f);\n            int param_7 = ci;\n            t = clamp((_3140 - (fa_shadow_split_at(param_7) - _3252)) / _3252, 0.0f, 1.0f);\n        }\n        if (t <= 0.0f)\n        {\n            break;\n        }\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (t > 0.0f)\n    {\n        float _3284;\n        if ((ci + 1) < _3125)\n        {\n            _3284 = (s2 < 0.0f) ? s : s2;\n        }\n        else\n        {\n            _3284 = 1.0f;\n        }\n        s = lerp(s, _3284, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    bool _3389 = _609_fa_ct_b.y > 0.5f;\n    bool _3395;\n    if (_3389)\n    {\n        _3395 = _609_fa_pbr.z > 0.5f;\n    }\n    else\n    {\n        _3395 = _3389;\n    }\n    if (_3395)\n    {\n        float _3409 = dot(_609_fa_ct_fwd.xyz, fa_world_pos) + _609_fa_ct_fwd.w;\n        float _3412 = fwidth(_3409);\n        float4 _3422 = float4(fa_world_pos, 1.0f);\n        float _3428 = dot(_609_fa_ct_vpw, _3422);\n        if (_3428 > 9.9999997473787516355514526367188e-05f)\n        {\n            float2 _3447 = float2(dot(_609_fa_ct_vpx, _3422), dot(_609_fa_ct_vpy, _3422)) / _3428.xx;\n            float _3452 = (_3447.x * 0.5f) + 0.5f;\n            float _3456;\n            if (_609_fa_ct_a.y > 0.5f)\n            {\n                _3456 = (_3447.y * 0.5f) + 0.5f;\n            }\n            else\n            {\n                _3456 = 0.5f - (_3447.y * 0.5f);\n            }\n            bool _3472 = _3452 >= 0.0f;\n            bool _3478;\n            if (_3472)\n            {\n                _3478 = _3452 < 1.0f;\n            }\n            else\n            {\n                _3478 = _3472;\n            }\n            bool _3484;\n            if (_3478)\n            {\n                _3484 = _3456 >= 0.0f;\n            }\n            else\n            {\n                _3484 = _3478;\n            }\n            bool _3490;\n            if (_3484)\n            {\n                _3490 = _3456 < 1.0f;\n            }\n            else\n            {\n                _3490 = _3484;\n            }\n            if (_3490)\n            {\n                float4 _3516 = fa_screen_tex.Load(int3(clamp(int2(float2(_3452, _3456) * _609_fa_ct_a.zw), int2(0, 0), int2(_609_fa_ct_a.zw) - int2(1, 1)), 0));\n                bool _3519 = _3516.w > 0.5f;\n                bool _3535;\n                if (_3519)\n                {\n                    _3535 = abs(_3409 - _3516.x) <= (((0.00200000009499490261077880859375f * _3409) + 0.00999999977648258209228515625f) + min(1.5f * _3412, 0.100000001490116119384765625f * _3409));\n                }\n                else\n                {\n                    _3535 = _3519;\n                }\n                if (_3535)\n                {\n                    float _3541;\n                    if (_609_fa_ct_b.z > 0.5f)\n                    {\n                        float3 param = fa_world_pos;\n                        float3 param_1 = n;\n                        float3 param_2 = l;\n                        _3541 = min(_3516.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3541 = _3516.y;\n                    }\n                    return _3541;\n                }\n            }\n        }\n    }\n    float3 param_3 = fa_world_pos;\n    float3 param_4 = n;\n    float3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2805 = _609_fa_pbr.z < 0.5f;\n    bool _2812;\n    if (!_2805)\n    {\n        _2812 = _2353_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2812 = _2805;\n    }\n    if (_2812)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2353_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2825 = fa_light_texel(param);\n    float _2826 = _2825.x;\n    if (_2826 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2835 = int(_2826 + 0.5f);\n    int param_1 = _2835;\n    float4 _2839 = fa_light_texel(param_1);\n    int param_2 = _2835 + 1;\n    float4 _2844 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2847 = _2839.y;\n    if (_2847 > 0.0f)\n    {\n        float _2864 = 1.0f - smoothstep(0.75f * _2847, _2847, length(world - _2353_fa_shadow_eye.xyz));\n        fade = _2864;\n        if (_2864 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2839.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2888 = (_2835 + 2) + (face * 6);\n    int param_4 = _2888;\n    int param_5 = _2888 + 1;\n    int param_6 = _2888 + 3;\n    float4 _2902 = fa_light_texel(param_6);\n    int param_7 = _2888 + 4;\n    float4 _2907 = fa_light_texel(param_7);\n    int param_8 = _2888 + 5;\n    float4 _2912 = fa_light_texel(param_8);\n    float _2924 = _2912.x * max(dot(_2902, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2929 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2952 = clamp(dot(n, _2902.xyz), -1.0f, 1.0f);\n    float _2971 = min(sqrt(1.0f - (_2952 * _2952)) / max(abs(dot(n, world - lpos)) / max(dot(_2902, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2974 = _2844.y;\n    float _2976;\n    if (_2974 > 0.0f)\n    {\n        _2976 = _2974;\n    }\n    else\n    {\n        _2976 = 1.5f * _2924;\n    }\n    float4 _2996 = float4(world + (n * (_2976 * sqrt(1.0f - (_2929 * _2929)))), 1.0f);\n    float _3000 = dot(_2902, _2996);\n    float _3003 = _2912.y;\n    if (_3000 < _3003)\n    {\n        return 1.0f;\n    }\n    float2 _3018 = float2(dot(fa_light_texel(param_4), _2996), dot(fa_light_texel(param_5), _2996)) / _3000.xx;\n    float _3020 = _3018.x;\n    bool _3023 = _3020 < _2907.x;\n    bool _3032;\n    if (!_3023)\n    {\n        _3032 = _3020 > _2907.z;\n    }\n    else\n    {\n        _3032 = _3023;\n    }\n    bool _3041;\n    if (!_3032)\n    {\n        _3041 = _3018.y < _2907.y;\n    }\n    else\n    {\n        _3041 = _3032;\n    }\n    bool _3050;\n    if (!_3041)\n    {\n        _3050 = _3018.y > _2907.w;\n    }\n    else\n    {\n        _3050 = _3041;\n    }\n    if (_3050)\n    {\n        return 1.0f;\n    }\n    float _3056 = _2844.x;\n    float _3058;\n    if (_3056 > 0.0f)\n    {\n        _3058 = _3056;\n    }\n    else\n    {\n        _3058 = 1.5f * _2924;\n    }\n    float2 param_9 = _3018;\n    float4 param_10 = _2907;\n    float param_11 = _3000 - (_3058 * (1.0f + (0.5f * _2971)));\n    float param_12 = _2924;\n    float param_13 = 1.0f;\n    float param_14 = _2912.z * 0.25f;\n    float param_15 = (_2924 * min(_2971, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _3003, _2912.z);\n    int param_17 = int(_2839.z + 0.5f);\n    float param_18 = _2839.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _3570 = _609_fa_ct_b.w > 0.5f;\n    bool _3576;\n    if (_3570)\n    {\n        _3576 = _609_fa_pbr.z > 0.5f;\n    }\n    else\n    {\n        _3576 = _3570;\n    }\n    bool _3582;\n    if (_3576)\n    {\n        _3582 = _2353_fa_shadow_lcfg.x > 0.5f;\n    }\n    else\n    {\n        _3582 = _3576;\n    }\n    if (_3582)\n    {\n        int param = (int(_2353_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n        float4 _3594 = fa_light_texel(param);\n        float _3595 = _3594.z;\n        if (_3595 > 0.5f)\n        {\n            float _3608 = dot(_609_fa_ct_fwd.xyz, world) + _609_fa_ct_fwd.w;\n            float _3611 = fwidth(_3608);\n            float _3615 = min(1.5f * _3611, 0.100000001490116119384765625f * _3608);\n            float4 _3621 = float4(world, 1.0f);\n            float _3626 = dot(_609_fa_ct_vpw, _3621);\n            if (_3626 > 9.9999997473787516355514526367188e-05f)\n            {\n                float2 _3643 = float2(dot(_609_fa_ct_vpx, _3621), dot(_609_fa_ct_vpy, _3621)) / _3626.xx;\n                float _3648 = (_3643.x * 0.5f) + 0.5f;\n                float _3652;\n                if (_609_fa_ct_a.y > 0.5f)\n                {\n                    _3652 = (_3643.y * 0.5f) + 0.5f;\n                }\n                else\n                {\n                    _3652 = 0.5f - (_3643.y * 0.5f);\n                }\n                bool _3668 = _3648 >= 0.0f;\n                bool _3674;\n                if (_3668)\n                {\n                    _3674 = _3648 < 1.0f;\n                }\n                else\n                {\n                    _3674 = _3668;\n                }\n                bool _3680;\n                if (_3674)\n                {\n                    _3680 = _3652 >= 0.0f;\n                }\n                else\n                {\n                    _3680 = _3674;\n                }\n                bool _3686;\n                if (_3680)\n                {\n                    _3686 = _3652 < 1.0f;\n                }\n                else\n                {\n                    _3686 = _3680;\n                }\n                if (_3686)\n                {\n                    int2 _3703 = int2(_609_fa_ct_a.zw) - int2(1, 1);\n                    int2 _3704 = clamp(int2(float2(_3648, _3652) * _609_fa_ct_a.zw), int2(0, 0), _3703);\n                    int2 _3716;\n                    int2 _3722;\n                    int2 _3729;\n                    float _3780;\n                    float _3801;\n                    for (int k = 0; k < 5; k++)\n                    {\n                        if (k == 0)\n                        {\n                            _3716 = int2(0, 0);\n                        }\n                        else\n                        {\n                            if (k == 1)\n                            {\n                                _3722 = int2(1, 0);\n                            }\n                            else\n                            {\n                                if (k == 2)\n                                {\n                                    _3729 = int2(-1, 0);\n                                }\n                                else\n                                {\n                                    bool2 _3740 = (k == 3).xx;\n                                    _3729 = int2(_3740.x ? int2(0, 1).x : int2(0, -1).x, _3740.y ? int2(0, 1).y : int2(0, -1).y);\n                                }\n                                _3722 = _3729;\n                            }\n                            _3716 = _3722;\n                        }\n                        float4 _3757 = fa_screen_tex.Load(int3(clamp(_3704 + _3716, int2(0, 0), _3703), 0));\n                        bool _3760 = _3757.w > 0.5f;\n                        bool _3774;\n                        if (_3760)\n                        {\n                            _3774 = abs(_3608 - _3757.x) <= (((0.00200000009499490261077880859375f * _3608) + 0.00999999977648258209228515625f) + _3615);\n                        }\n                        else\n                        {\n                            _3774 = _3760;\n                        }\n                        if (_3774)\n                        {\n                            if (_3595 < 1.5f)\n                            {\n                                _3780 = 1.0f;\n                            }\n                            else\n                            {\n                                _3780 = (_3595 < 2.5f) ? 256.0f : 65536.0f;\n                            }\n                            float _3797 = mod(floor(_3757.z / _3780), 256.0f) * 0.0039215688593685626983642578125f;\n                            if (_609_fa_ct_b.z > 0.5f)\n                            {\n                                int param_1 = li;\n                                float3 param_2 = lpos;\n                                float3 param_3 = world;\n                                float3 param_4 = n;\n                                float3 param_5 = l;\n                                _3801 = min(_3797, fa_shadow_local(param_1, param_2, param_3, param_4, param_5));\n                            }\n                            else\n                            {\n                                _3801 = _3797;\n                            }\n                            return _3801;\n                        }\n                    }\n                }\n            }\n            float _3826;\n            if (_609_fa_ct_b.z > 0.5f)\n            {\n                int param_6 = li;\n                float3 param_7 = lpos;\n                float3 param_8 = world;\n                float3 param_9 = n;\n                float3 param_10 = l;\n                _3826 = fa_shadow_local(param_6, param_7, param_8, param_9, param_10);\n            }\n            else\n            {\n                _3826 = 1.0f;\n            }\n            return _3826;\n        }\n    }\n    int param_11 = li;\n    float3 param_12 = lpos;\n    float3 param_13 = world;\n    float3 param_14 = n;\n    float3 param_15 = l;\n    return fa_shadow_local(param_11, param_12, param_13, param_14, param_15);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _5671 = _609_fa_ct_a.x < 0.5f;\n    bool _5678;\n    if (!_5671)\n    {\n        _5678 = _2353_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _5678 = _5671;\n    }\n    if (_5678)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2353_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _5691 = fa_light_texel(param);\n    float _5692 = _5691.y;\n    float len = _5692;\n    if (_5692 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _5704 = length(world - _609_fa_camera_pos.xyz);\n    float _5713 = 1.0f - smoothstep(0.5f * _609_fa_ct_b.x, _609_fa_ct_b.x, _5704);\n    if (_5713 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _5719 = len;\n    float _5722 = min(_5719, 0.89999997615814208984375f * dist);\n    len = _5722;\n    float _5727 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _5704);\n    float _5732 = _5727 + (0.5f * _5722);\n    float3 _5738 = world + (gn * _5727);\n    float _5740 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _5801;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5755 = (float(k) + _5740) * 0.083333335816860198974609375f;\n        float3 _5763 = _5738 + (l * (_5755 * len));\n        float4 _5769 = float4(_5763, 1.0f);\n        float _5774 = dot(_609_fa_ct_vpw, _5769);\n        if (_5774 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _5792 = float2(dot(_609_fa_ct_vpx, _5769), dot(_609_fa_ct_vpy, _5769)) / _5774.xx;\n        float _5796 = _5792.x * 0.5f;\n        float _5797 = _5796 + 0.5f;\n        if (_609_fa_ct_a.y > 0.5f)\n        {\n            _5801 = (_5792.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _5801 = 0.5f - (_5792.y * 0.5f);\n        }\n        bool _5817 = _5797 < 0.0f;\n        bool _5824;\n        if (!_5817)\n        {\n            _5824 = _5797 >= 1.0f;\n        }\n        else\n        {\n            _5824 = _5817;\n        }\n        bool _5831;\n        if (!_5824)\n        {\n            _5831 = _5801 < 0.0f;\n        }\n        else\n        {\n            _5831 = _5824;\n        }\n        bool _5838;\n        if (!_5831)\n        {\n            _5838 = _5801 >= 1.0f;\n        }\n        else\n        {\n            _5838 = _5831;\n        }\n        if (_5838)\n        {\n            break;\n        }\n        float4 _5862 = fa_screen_tex.Load(int3(clamp(int2(float2(_5797, _5801) * _609_fa_ct_a.zw), int2(0, 0), int2(_609_fa_ct_a.zw) - int2(1, 1)), 0));\n        if (_5862.w < 0.5f)\n        {\n            continue;\n        }\n        float _5880 = (dot(_609_fa_ct_fwd.xyz, _5763) + _609_fa_ct_fwd.w) - _5862.x;\n        if ((_5880 > _5727) && (_5880 < _5732))\n        {\n            occ = max(occ, (1.0f - (_5755 * _5755)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_5797, 0.5f - _5796), min(_5801, 1.0f - _5801))));\n        }\n    }\n    return 1.0f - (occ * _5713);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _6513 = fa_baked_keep(param);\n    if (_6513 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _9807 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _9807;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _6539 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _9809 = _6539.color;\n    float _9810 = _6539.attenuation;\n    float _9811 = _6539.shadow;\n    bool _6542 = _6539.type == 0;\n    if (_6542 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _6539.direction;\n        float _6553 = fa_shadow_factor(param_5, param_6);\n        _9811 = _6553;\n        _9809 *= _6553;\n    }\n    else\n    {\n        bool _6564 = _6539.type != 0;\n        bool _6570;\n        if (_6564)\n        {\n            _6570 = _9810 > 0.0f;\n        }\n        else\n        {\n            _6570 = _6564;\n        }\n        if (_6570)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _6539.direction;\n            float _6589 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _9811 = _6589;\n            _9809 *= _6589;\n        }\n    }\n    bool _6599 = _609_fa_ct_a.x > 0.5f;\n    bool _6605;\n    if (_6599)\n    {\n        _6605 = _9810 > 0.0f;\n    }\n    else\n    {\n        _6605 = _6599;\n    }\n    if (_6605)\n    {\n        float _6612;\n        if (_6542)\n        {\n            _6612 = 1000000000.0f;\n        }\n        else\n        {\n            _6612 = _6539._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _6539.direction;\n        float param_18 = _6612;\n        float _6630 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9811 *= _6630;\n        _9809 *= _6630;\n    }\n    float _6643 = _9810;\n    float _6644 = _6643 * _6513;\n    _9810 = _6644;\n    float3 _6648 = _9809;\n    float3 _6649 = _6648 * _6513;\n    _9809 = _6649;\n    LightSample _9826 = { _6539.direction, _6649, _6644, _9811, _6539._distance, _6539.type };\n    return _9826;\n}\n\nfloat3 fa_ltc_tangent(float3 n, float3 v)\n{\n    float3 _6683 = v - (n * dot(v, n));\n    float3 t = _6683;\n    float _6687 = dot(_6683, _6683);\n    float l2 = _6687;\n    if (_6687 < 1.0000000133514319600180897396058e-10f)\n    {\n        float3 _6697;\n        if (abs(n.z) < 0.999000012874603271484375f)\n        {\n            _6697 = cross(n, float3(0.0f, 0.0f, 1.0f));\n        }\n        else\n        {\n            _6697 = cross(n, float3(1.0f, 0.0f, 0.0f));\n        }\n        t = _6697;\n        l2 = dot(_6697, _6697);\n    }\n    return t * rsqrt(l2);\n}\n\nfloat3 fa_ltc_local(float3 t1, float3 n, float3 p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nfloat2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((float2(clamp((roughness - 0.0500000007450580596923828125f) * 1.0526316165924072265625f, 0.0f, 1.0f), sqrt(clamp(1.0f - ndv, 0.0f, 1.0f))) * 63.0f) + 0.5f.xx) * 0.015625f.xx;\n}\n\nfloat3 fa_oct_vertex(int j, float3 pc, float3 ex, float3 ey)\n{\n    float _7084;\n    if ((j == 0) || (j == 7))\n    {\n        _7084 = 0.92387950420379638671875f;\n    }\n    else\n    {\n        float _7094;\n        if ((j == 3) || (j == 4))\n        {\n            _7094 = -0.92387950420379638671875f;\n        }\n        else\n        {\n            _7094 = ((j == 1) || (j == 6)) ? 0.3826834261417388916015625f : (-0.3826834261417388916015625f);\n        }\n        _7084 = _7094;\n    }\n    float _7115;\n    if ((j == 1) || (j == 2))\n    {\n        _7115 = 0.92387950420379638671875f;\n    }\n    else\n    {\n        float _7124;\n        if ((j == 5) || (j == 6))\n        {\n            _7124 = -0.92387950420379638671875f;\n        }\n        else\n        {\n            _7124 = ((j == 0) || (j == 3)) ? 0.3826834261417388916015625f : (-0.3826834261417388916015625f);\n        }\n        _7115 = _7124;\n    }\n    return (pc + (ex * _7084)) + (ey * _7115);\n}\n\nfloat3 fa_ltc_edge_vector(float3 a, float3 b)\n{\n    float _6732 = dot(a, a);\n    float _6736 = dot(b, b);\n    if ((_6732 < 1.0000000195414813782625560981111e-24f) || (_6736 < 1.0000000195414813782625560981111e-24f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _6750 = a * rsqrt(_6732);\n    float3 _6755 = b * rsqrt(_6736);\n    float _6759 = dot(_6750, _6755);\n    float _6762 = abs(_6759);\n    float g = (((((((((((0.0416471660137176513671875f * _6762) - 0.1924748718738555908203125f) * _6762) + 0.4179156124591827392578125f) * _6762) - 0.616057217121124267578125f) * _6762) + 0.777722418308258056640625f) * _6762) - 0.999542415142059326171875f) * _6762) + 1.570791721343994140625f;\n    if (_6759 < 0.0f)\n    {\n        g = (3.1415927410125732421875f * rsqrt(max(1.0f - (_6759 * _6759), 1.0000000116860974230803549289703e-07f))) - g;\n    }\n    return cross(_6750, _6755) * g;\n}\n\nvoid fa_ltc_clip_edge(float3 a, float3 b, inout float3 sum, inout float3 leave, inout float3 enter, inout float2 seen)\n{\n    bool _6819 = a.z > 0.0f;\n    bool _6823 = b.z > 0.0f;\n    if (_6819 && _6823)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6819 != _6823)\n        {\n            float3 _6858 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6858.z = 0.0f;\n            if (_6819)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _6858;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6858;\n                seen.x = 1.0f;\n            }\n            else\n            {\n                float3 param_4 = _6858;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6858;\n                seen.y = 1.0f;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(float4 abcd, float3 p0, float3 p1, float3 p2, float3 p3)\n{\n    float3 _6907 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _6933 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _6959 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _6985 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = 0.0f.xxx;\n    float3 leave = 0.0f.xxx;\n    float3 enter = 0.0f.xxx;\n    float3 param = _6907;\n    float3 param_1 = _6933;\n    float3 param_2 = 0.0f.xxx;\n    float3 param_3 = 0.0f.xxx;\n    float3 param_4 = 0.0f.xxx;\n    float2 param_5 = 0.0f.xx;\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _6933;\n    float3 param_7 = _6959;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _6959;\n    float3 param_13 = _6985;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _6985;\n    float3 param_19 = _6907;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5f)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875f;\n}\n\nfloat2 fa_area_forms(float4 m, float shape, float3 pc, float3 ex, float3 ey)\n{\n    int _7153 = ((shape < 0.5f) || (shape > 1.5f)) ? 1 : 3;\n    float2 sum = 0.0f.xx;\n    int _7171;\n    for (int k = 0; k < (2 * _7153); k++)\n    {\n        bool _7168 = k >= _7153;\n        if (_7168)\n        {\n            _7171 = k - _7153;\n        }\n        else\n        {\n            _7171 = k;\n        }\n        float3 p0 = (pc - ex) - ey;\n        float3 p1 = (pc + ex) - ey;\n        float3 p2 = (pc + ex) + ey;\n        float3 p3 = (pc - ex) + ey;\n        if (_7153 == 3)\n        {\n            int param = 0;\n            float3 param_1 = pc;\n            float3 param_2 = ex;\n            float3 param_3 = ey;\n            p0 = fa_oct_vertex(param, param_1, param_2, param_3);\n            int _7217 = 2 * _7171;\n            int param_4 = _7217 + 1;\n            float3 param_5 = pc;\n            float3 param_6 = ex;\n            float3 param_7 = ey;\n            p1 = fa_oct_vertex(param_4, param_5, param_6, param_7);\n            int param_8 = _7217 + 2;\n            float3 param_9 = pc;\n            float3 param_10 = ex;\n            float3 param_11 = ey;\n            p2 = fa_oct_vertex(param_8, param_9, param_10, param_11);\n            int param_12 = _7217 + 3;\n            float3 param_13 = pc;\n            float3 param_14 = ex;\n            float3 param_15 = ey;\n            p3 = fa_oct_vertex(param_12, param_13, param_14, param_15);\n        }\n        bool4 _7254 = _7168.xxxx;\n        float4 param_16 = float4(_7254.x ? m.x : float4(1.0f, 0.0f, 0.0f, 1.0f).x, _7254.y ? m.y : float4(1.0f, 0.0f, 0.0f, 1.0f).y, _7254.z ? m.z : float4(1.0f, 0.0f, 0.0f, 1.0f).z, _7254.w ? m.w : float4(1.0f, 0.0f, 0.0f, 1.0f).w);\n        float3 param_17 = p0;\n        float3 param_18 = p1;\n        float3 param_19 = p2;\n        float3 param_20 = p3;\n        float _7265 = fa_ltc_quad(param_16, param_17, param_18, param_19, param_20);\n        if (_7168)\n        {\n            float2 _10062 = sum;\n            _10062.y = _10062.y + _7265;\n            sum = _10062;\n        }\n        else\n        {\n            float2 _10065 = sum;\n            _10065.x = _10065.x + _7265;\n            sum = _10065;\n        }\n    }\n    return abs(sum);\n}\n\nfloat3 fa_area_shade(int li, float3 world_pos, float3 n, float3 v, float3 diffuse_color, float3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _7289 = fa_light_base(param);\n    int param_1 = _7289;\n    int param_2 = _7289 + 1;\n    int param_3 = _7289 + 2;\n    int param_4 = _7289 + 4;\n    float4 _7311 = fa_light_texel(param_4);\n    int param_5 = _7289 + 5;\n    float4 _7316 = fa_light_texel(param_5);\n    int param_6 = _7289 + 6;\n    float4 _7321 = fa_light_texel(param_6);\n    float _7322 = _7321.w;\n    float3 _7327 = fa_light_texel(param_1).xyz - world_pos;\n    bool _7329 = _7322 < 1.5f;\n    bool _7336;\n    if (_7329)\n    {\n        _7336 = dot(normalize(fa_light_texel(param_3).xyz), _7327) >= 0.0f;\n    }\n    else\n    {\n        _7336 = _7329;\n    }\n    if (_7336)\n    {\n        return 0.0f.xxx;\n    }\n    bool _7345 = (_7322 > 0.5f) && _7329;\n    float _7349 = _7345 ? 1.0539000034332275390625f : 1.0f;\n    float3 _7352 = _7311.xyz;\n    float _7354 = _7311.w;\n    float3 _7360 = _7316.xyz;\n    float _7362 = _7316.w;\n    float3 up = _7360 * (_7362 * _7349);\n    float _7368;\n    if (_7345)\n    {\n        _7368 = (3.1415927410125732421875f * _7354) * _7354;\n    }\n    else\n    {\n        _7368 = (4.0f * _7354) * _7362;\n    }\n    if (_7322 > 1.5f)\n    {\n        float3 _7394 = cross(_7352, -_7327);\n        float3 perp = _7394;\n        float _7398 = dot(_7394, _7394);\n        float3 _7401;\n        if (_7398 > 1.0000000133514319600180897396058e-10f)\n        {\n            _7401 = perp * rsqrt(_7398);\n        }\n        else\n        {\n            _7401 = _7360;\n        }\n        perp = _7401;\n        up = _7401 * _7362;\n    }\n    float _7422 = max(_7368, 9.9999999747524270787835121154785e-07f);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _7432 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _7432;\n    float3 param_10 = n;\n    float3 param_11 = _7327;\n    float3 param_12 = _7432;\n    float3 param_13 = n;\n    float3 param_14 = _7352 * (_7354 * _7349);\n    float3 param_15 = _7432;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float param_18 = roughness;\n    float param_19 = ndv;\n    float2 _7463 = fa_ltc_uv(param_18, param_19) * 64.0f;\n    float2 param_20 = _7463;\n    float2 param_21 = _7463 + float2(64.0f, 0.0f);\n    float4 _7473 = fa_atlas_fetch(param_21);\n    float4 param_22 = fa_atlas_fetch(param_20);\n    float param_23 = _7322;\n    float3 param_24 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_25 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_26 = fa_ltc_local(param_15, param_16, param_17);\n    float2 _7485 = fa_area_forms(param_22, param_23, param_24, param_25, param_26);\n    return (((diffuse_color * _7485.x) + (((f0 * _7473.x) + ((f90.xxx - f0) * _7473.y)) * _7485.y)) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875f * dot(_7327, _7327)) + _7422) / _7422) * window);\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _5408 = 1.0f / alpha;\n    return ((2.0f + _5408) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _5408)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat fa_layers_coat(FaLayers L, float3 l, float3 h, float vdh)\n{\n    float _5443 = max(dot(L.nc, l), 0.0f);\n    float _5449 = max(dot(L.nc, h), 0.0f);\n    float _5458 = ((_5449 * _5449) * (L.coat_a2 - 1.0f)) + 1.0f;\n    return (((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _5458) * _5458)) * (0.5f / max(lerp((2.0f * _5443) * L.coat_ndv, _5443 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _5443)) * _5443;\n}\n\nfloat3 fa_area_layers(FaLayers L, float3 base, int li, float3 n, float3 v, float3 l, float ndv, float window)\n{\n    float _7522;\n    if (L.sheen_on)\n    {\n        _7522 = L.sheen_scale;\n    }\n    else\n    {\n        _7522 = 1.0f;\n    }\n    float3 result = base * (L.keep * _7522);\n    float3 _7535 = normalize(l + v);\n    int param = li;\n    float3 _7546 = fa_light_rgb(param) * window;\n    if (L.sheen_on)\n    {\n        float _7555 = max(dot(n, l), 0.0f);\n        float param_1 = L.sheen_alpha;\n        float param_2 = max(dot(n, _7535), 0.0f);\n        float param_3 = _7555;\n        float param_4 = ndv;\n        result += ((L.sheen * _7546) * (((((fa_d_charlie(param_1, param_2) * fa_v_ashikhmin(param_3, param_4)) * 3.1415927410125732421875f) * step(9.9999997473787516355514526367188e-05f, _7555)) * _7555) * L.keep));\n    }\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_5 = L;\n        float3 param_6 = l;\n        float3 param_7 = _7535;\n        float param_8 = max(dot(v, _7535), 0.0f);\n        result += (_7546 * fa_layers_coat(param_5, param_6, param_7, param_8));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _5311 = tdh / at;\n    float _5315 = bdh / ab;\n    float _5327 = ((_5311 * _5311) + (_5315 * _5315)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _5327) * _5327);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5507 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5586 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _5586) * _5586);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _5507);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _5507));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_17 = L;\n        float3 param_18 = l;\n        float3 param_19 = h;\n        float param_20 = vdh;\n        result += fa_layers_coat(param_17, param_18, param_19, param_20).xxx;\n    }\n    return result;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _4710 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _4713 = _4710.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_4713 * _4713, exp2((-9.27999973297119140625f) * ndv)) * _4713) + _4710.y)) + _4710.zw;\n}\n\nfloat3 fa_probe_level(float2 origin, float res, int lv, float2 e)\n{\n    float _4020;\n    if (lv == 0)\n    {\n        _4020 = 0.0f;\n    }\n    else\n    {\n        _4020 = res + 2.0f;\n    }\n    float _4030;\n    if (lv == 0)\n    {\n        _4030 = 0.0f;\n    }\n    else\n    {\n        _4030 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0f * float(lv - 1));\n    }\n    return fa_probe_atlas.SampleLevel(fa_env_smp, (((origin + float2(_4020, _4030)) + 1.0f.xx) + (((e * 0.5f) + 0.5f.xx) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0f).xyz;\n}\n\nfloat3 fa_probe_radiance(float2 origin, float res, float3 d, float rough)\n{\n    float _4076;\n    if (res > 64.5f)\n    {\n        _4076 = 5.0f;\n    }\n    else\n    {\n        _4076 = (res > 32.5f) ? 4.0f : 3.0f;\n    }\n    float _4091 = clamp(rough, 0.0f, 1.0f) * (_4076 - 1.0f);\n    int _4098 = int(min(floor(_4091), _4076 - 2.0f));\n    float _4103 = _4091 - float(_4098);\n    float3 param = d;\n    float2 _4107 = fa_oct_encode(param);\n    float2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _4098;\n    float2 param_4 = _4107;\n    float3 _4117 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_4103 < 0.00200000009499490261077880859375f)\n    {\n        return _4117;\n    }\n    float2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _4098 + 1;\n    float2 param_8 = _4107;\n    return lerp(_4117, fa_probe_level(param_5, param_6, param_7, param_8), _4103.xxx);\n}\n\nfloat3 fa_probe_box_dir(float3 d, float4 posw, float4 bx, float4 by, float4 bz)\n{\n    if (posw.w < 0.5f)\n    {\n        return d;\n    }\n    float _4188 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _4195 = dot(by.xyz, fa_world_pos) + by.w;\n    float _4202 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _4208 = dot(bx.xyz, d);\n    float _4212 = dot(by.xyz, d);\n    float _4216 = dot(bz.xyz, d);\n    float _4222;\n    if (_4208 > 9.9999999747524270787835121154785e-07f)\n    {\n        _4222 = (1.0f - _4188) / _4208;\n    }\n    else\n    {\n        float _4236;\n        if (_4208 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _4236 = ((-1.0f) - _4188) / _4208;\n        }\n        else\n        {\n            _4236 = 1000000015047466219876688855040.0f;\n        }\n        _4222 = _4236;\n    }\n    float tx = _4222;\n    float _4253;\n    if (_4212 > 9.9999999747524270787835121154785e-07f)\n    {\n        _4253 = (1.0f - _4195) / _4212;\n    }\n    else\n    {\n        float _4266;\n        if (_4212 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _4266 = ((-1.0f) - _4195) / _4212;\n        }\n        else\n        {\n            _4266 = 1000000015047466219876688855040.0f;\n        }\n        _4253 = _4266;\n    }\n    float ty = _4253;\n    float _4282;\n    if (_4216 > 9.9999999747524270787835121154785e-07f)\n    {\n        _4282 = (1.0f - _4202) / _4216;\n    }\n    else\n    {\n        float _4295;\n        if (_4216 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _4295 = ((-1.0f) - _4202) / _4216;\n        }\n        else\n        {\n            _4295 = 1000000015047466219876688855040.0f;\n        }\n        _4282 = _4295;\n    }\n    float _4307 = tx;\n    float _4310 = (_4307 > 0.0f) ? _4307 : 1000000015047466219876688855040.0f;\n    tx = _4310;\n    float _4311 = ty;\n    float _4314 = (_4311 > 0.0f) ? _4311 : 1000000015047466219876688855040.0f;\n    ty = _4314;\n    float _4324 = min(_4310, min(_4314, (_4282 > 0.0f) ? _4282 : 1000000015047466219876688855040.0f));\n    if (_4324 > 100000001504746621987668885504.0f)\n    {\n        return d;\n    }\n    float3 _4340 = (fa_world_pos + (d * _4324)) - posw.xyz;\n    float3 _4345;\n    if (dot(_4340, _4340) > 1.0000000133514319600180897396058e-10f)\n    {\n        _4345 = normalize(_4340);\n    }\n    else\n    {\n        _4345 = d;\n    }\n    return _4345;\n}\n\nfloat3 fa_probe_environment(float4 tile, float4 posw, float4 bx, float4 by, float4 bz, inout float3 d, float rough)\n{\n    float3 param = d;\n    float4 param_1 = posw;\n    float4 param_2 = bx;\n    float4 param_3 = by;\n    float4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    float2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    float3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _4391 = (1.0f - _609_fa_rpa_tile.w) - _609_fa_rpb_tile.w;\n    float3 outc = 0.0f.xxx;\n    if (_4391 > 0.0005000000237487256526947021484375f)\n    {\n        float3 base;\n        if (_609_fa_env_sky.w > 0.5f)\n        {\n            float2 param = _609_fa_atlas.zw;\n            float param_1 = 128.0f;\n            float3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _4419 = rough * rough;\n            float _4450 = 0.60000002384185791015625f * _4419;\n            base = lerp(lerp(_609_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_609_fa_env_horizon.xyz, _609_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _4419)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _4450, 0.0500000007450580596923828125f + _4450, d.y).xxx), ((_609_fa_env_sky.xyz + _609_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_4419 * 0.60000002384185791015625f).xxx);\n        }\n        outc = base * _4391;\n    }\n    if (_609_fa_rpa_tile.w > 0.0f)\n    {\n        float4 param_4 = _609_fa_rpa_tile;\n        float4 param_5 = _609_fa_rpa_pos;\n        float4 param_6 = _609_fa_rpa_bx;\n        float4 param_7 = _609_fa_rpa_by;\n        float4 param_8 = _609_fa_rpa_bz;\n        float3 param_9 = d;\n        float param_10 = rough;\n        float3 _4509 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4509 * _609_fa_rpa_tile.w);\n    }\n    if (_609_fa_rpb_tile.w > 0.0f)\n    {\n        float4 param_11 = _609_fa_rpb_tile;\n        float4 param_12 = _609_fa_rpb_pos;\n        float4 param_13 = _609_fa_rpb_bx;\n        float4 param_14 = _609_fa_rpb_by;\n        float4 param_15 = _609_fa_rpb_bz;\n        float3 param_16 = d;\n        float param_17 = rough;\n        float3 _4541 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4541 * _609_fa_rpb_tile.w);\n    }\n    return outc;\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness, float occlusion)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _5188;\n        if (L.aniso >= 0.0f)\n        {\n            _5188 = L.b;\n        }\n        else\n        {\n            _5188 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_5188, v), _5188), (abs(L.aniso) * smoothstep(0.0f, 0.25f, roughness)).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _5224 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _5224.x) + (L.f90.xxx * _5224.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _5282 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _5282.x) + _5282.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4752 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4752.x) + _4752.y.xxx);\n}\n\nfloat2 fa_xm_size(int k)\n{\n    return max(floor(_609_fa_ct_a.zw / float(1 << k).xx), 1.0f.xx);\n}\n\nfloat2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return 0.0f.xx;\n    }\n    float y = 0.0f;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return float2(_609_fa_ct_a.z, y);\n}\n\nfloat3 fa_xm_texel(float2 size, float2 origin, float2 p)\n{\n    return fa_screen_tex.Load(int3(int2(origin + clamp(p, 0.0f.xx, size - 1.0f.xx)), 0)).xyz;\n}\n\nfloat3 fa_xm_level(int k, float2 uv)\n{\n    int param = k;\n    float2 _5984 = fa_xm_size(param);\n    int param_1 = k;\n    float2 _5988 = fa_xm_origin(param_1);\n    float2 _5994 = (uv * _5984) - 0.5f.xx;\n    float2 _5997 = frac(_5994);\n    float2 _6000 = floor(_5994);\n    float2 param_2 = _5984;\n    float2 param_3 = _5988;\n    float2 param_4 = _6000;\n    float2 param_5 = _5984;\n    float2 param_6 = _5988;\n    float2 param_7 = _6000 + float2(1.0f, 0.0f);\n    float2 param_8 = _5984;\n    float2 param_9 = _5988;\n    float2 param_10 = _6000 + float2(0.0f, 1.0f);\n    float2 param_11 = _5984;\n    float2 param_12 = _5988;\n    float2 param_13 = _6000 + 1.0f.xx;\n    float3 _6042 = _5997.x.xxx;\n    return lerp(lerp(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _6042), lerp(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _6042), _5997.y.xxx);\n}\n\nfloat3 fa_xm_sample(float2 uv, float lod)\n{\n    float _6061 = max(_609_fa_tr_b.w - 1.0f, 0.0f);\n    float _6065 = clamp(lod, 0.0f, _6061);\n    int _6069 = int(floor(_6065));\n    int param = _6069;\n    float2 param_1 = uv;\n    float3 c = fa_xm_level(param, param_1);\n    float _6079 = float(_6069);\n    float _6080 = _6065 - _6079;\n    bool _6082 = _6080 > 0.001000000047497451305389404296875f;\n    bool _6089;\n    if (_6082)\n    {\n        _6089 = _6079 < _6061;\n    }\n    else\n    {\n        _6089 = _6082;\n    }\n    if (_6089)\n    {\n        int param_2 = _6069 + 1;\n        float2 param_3 = uv;\n        c = lerp(c, fa_xm_level(param_2, param_3), _6080.xxx);\n    }\n    return c;\n}\n\nfloat3 fa_transmitted(Surface s, float3 n, float3 v, float roughness, float3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _6115 = fa_env_brdf(param, param_1);\n    float3 _6139 = ((1.0f.xxx - clamp((f0 * _6115.x) + (f90.xxx * _6115.y), 0.0f.xxx, 1.0f.xxx)) * s.albedo) * (tr * keep);\n    float3 through = _6139;\n    float _6145 = max(s.thickness, 0.0f);\n    bool _6150 = _6145 > 0.0f;\n    if ((s.attenuation_distance > 0.0f) && _6150)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, 9.9999997473787516355514526367188e-05f.xxx, 1.0f.xxx))) / s.attenuation_distance.xxx)) * _6145);\n    }\n    bool _6175 = _609_fa_tr_a.w > 1.5f;\n    bool _6181;\n    if (_6175)\n    {\n        _6181 = _609_fa_tr_a.w < 2.5f;\n    }\n    else\n    {\n        _6181 = _6175;\n    }\n    bool _6188;\n    if (!_6181)\n    {\n        _6188 = _609_fa_tr_a.w < 0.5f;\n    }\n    else\n    {\n        _6188 = _6181;\n    }\n    if (_6188)\n    {\n        blend = clamp(dot(through, 0.3333333432674407958984375f.xxx), 0.0f, 0.980000019073486328125f);\n        return 0.0f.xxx;\n    }\n    float4 _6203 = float4(fa_world_pos, 1.0f);\n    float _6208 = dot(_609_fa_ct_vpw, _6203);\n    float2 uv0 = 0.5f.xx;\n    if (_6208 > 9.9999997473787516355514526367188e-05f)\n    {\n        float2 _6226 = float2(dot(_609_fa_ct_vpx, _6203), dot(_609_fa_ct_vpy, _6203)) / _6208.xx;\n        float _6234;\n        if (_609_fa_ct_a.y > 0.5f)\n        {\n            _6234 = (_6226.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _6234 = 0.5f - (_6226.y * 0.5f);\n        }\n        uv0 = float2((_6226.x * 0.5f) + 0.5f, _6234);\n    }\n    if (_609_fa_tr_a.w > 2.5f)\n    {\n        int param_2 = 0;\n        float2 _6255 = fa_xm_size(param_2);\n        float2 _6263 = floor(clamp(uv0, 0.0f.xx, 0.99989998340606689453125f.xx) * _6255);\n        if (fa_screen_tex.Load(int3(int2(_6263), 0)).w > 0.5f)\n        {\n            int _6283 = int(floor((clamp(roughness, 0.0f, 1.0f) * 2.0f) + 0.5f));\n            float3 acc = 0.0f.xxx;\n            float cnt = 0.0f;\n            for (int dy = -2; dy <= 2; dy++)\n            {\n                for (int dx = -2; dx <= 2; dx++)\n                {\n                    bool _6306 = abs(dx) > _6283;\n                    bool _6314;\n                    if (!_6306)\n                    {\n                        _6314 = abs(dy) > _6283;\n                    }\n                    else\n                    {\n                        _6314 = _6306;\n                    }\n                    if (_6314)\n                    {\n                        continue;\n                    }\n                    float4 _6335 = fa_screen_tex.Load(int3(int2(clamp(_6263 + float2(float(dx), float(dy)), 0.0f.xx, _6255 - 1.0f.xx)), 0));\n                    if (_6335.w > 0.5f)\n                    {\n                        acc += _6335.xyz;\n                        cnt += 1.0f;\n                    }\n                }\n            }\n            return _6139 * (acc / max(cnt, 1.0f).xxx);\n        }\n    }\n    float2 uv = uv0;\n    if (_6150)\n    {\n        float4 _6383 = float4(fa_world_pos + (refract(-v, n, 1.0f / max(s.ior, 1.0f)) * _6145), 1.0f);\n        float _6388 = dot(_609_fa_ct_vpw, _6383);\n        uv = 0.5f.xx;\n        if (_6388 > 9.9999997473787516355514526367188e-05f)\n        {\n            float2 _6405 = float2(dot(_609_fa_ct_vpx, _6383), dot(_609_fa_ct_vpy, _6383)) / _6388.xx;\n            float _6413;\n            if (_609_fa_ct_a.y > 0.5f)\n            {\n                _6413 = (_6405.y * 0.5f) + 0.5f;\n            }\n            else\n            {\n                _6413 = 0.5f - (_6405.y * 0.5f);\n            }\n            uv = float2((_6405.x * 0.5f) + 0.5f, _6413);\n        }\n    }\n    float2 param_3 = clamp(uv, 0.0f.xx, 1.0f.xx);\n    float param_4 = (clamp(roughness, 0.0f, 1.0f) * clamp((2.0f * s.ior) - 2.0f, 0.0f, 1.0f)) * max(_609_fa_tr_b.w - 1.0f, 0.0f);\n    return through * fa_xm_sample(param_3, param_4);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2353_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3312 = int(_2353_fa_shadow_cfg.x + 0.5f);\n    float _3322 = dot(world - _2353_fa_shadow_eye.xyz, _2353_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3327 = _3312 > 0;\n    bool _3336;\n    if (_3327)\n    {\n        int param = _3312 - 1;\n        _3336 = _3322 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3336 = _3327;\n    }\n    if (_3336)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3342 = _3312 > 1;\n        bool _3349;\n        if (_3342)\n        {\n            _3349 = _3322 > _2353_fa_shadow_split.x;\n        }\n        else\n        {\n            _3349 = _3342;\n        }\n        if (_3349)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3355 = _3312 > 2;\n        bool _3362;\n        if (_3355)\n        {\n            _3362 = _3322 > _2353_fa_shadow_split.y;\n        }\n        else\n        {\n            _3362 = _3355;\n        }\n        if (_3362)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3368 = _3312 > 3;\n        bool _3375;\n        if (_3368)\n        {\n            _3375 = _3322 > _2353_fa_shadow_split.z;\n        }\n        else\n        {\n            _3375 = _3368;\n        }\n        if (_3375)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _9468 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _9468 = -_9468;\n    }\n    float3 _8754 = normalize(_609_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _9481 = { fa_world_pos, _9468, fa_world_tangent, fa_uv, fa_vertex_color, _8754, gl_FrontFacing };\n    SurfaceInput param_1 = _9481;\n    Surface _8762 = fa_standard_surface(param_1);\n    float3 _9499 = _8762.albedo;\n    float _9500 = _8762.alpha;\n    float3 _9501 = _8762.normal;\n    float _9502 = _8762.metallic;\n    float _9503 = _8762.roughness;\n    float _9504 = _8762.occlusion;\n    float3 _9505 = _8762.emission;\n    float _9506 = _8762.clearcoat;\n    float _9507 = _8762.clearcoat_roughness;\n    float3 _9508 = _8762.sheen_color;\n    float _9509 = _8762.sheen_roughness;\n    float _9510 = _8762.anisotropy;\n    float _9511 = _8762.anisotropy_rotation;\n    float _9512 = _8762.specular;\n    float _9513 = _8762.ior;\n    float3 _9514 = _8762.specular_color;\n    float _9515 = _8762.transmission;\n    float _9516 = _8762.thickness;\n    float3 _9517 = _8762.attenuation_color;\n    float _9518 = _8762.attenuation_distance;\n    SurfaceInput _9489 = { fa_world_pos, _9468, fa_world_tangent, fa_uv, fa_vertex_color, _8754, gl_FrontFacing };\n    SurfaceInput param_2 = _9489;\n    Surface param_3 = _8762;\n    surface(param_2, param_3);\n    _9499 = param_3.albedo;\n    _9500 = param_3.alpha;\n    _9501 = param_3.normal;\n    _9502 = param_3.metallic;\n    _9503 = param_3.roughness;\n    _9504 = param_3.occlusion;\n    _9505 = param_3.emission;\n    _9506 = param_3.clearcoat;\n    _9507 = param_3.clearcoat_roughness;\n    _9508 = param_3.sheen_color;\n    _9509 = param_3.sheen_roughness;\n    _9510 = param_3.anisotropy;\n    _9511 = param_3.anisotropy_rotation;\n    _9512 = param_3.specular;\n    _9513 = param_3.ior;\n    _9514 = param_3.specular_color;\n    _9515 = param_3.transmission;\n    _9516 = param_3.thickness;\n    _9517 = param_3.attenuation_color;\n    _9518 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _9468;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _9499 = param_6;\n    _9501 = param_7;\n    if (_9500 < _8790_alphaCutoff)\n    {\n        discard;\n    }\n    fa_lod_dither();\n    float fa_tr_blend = 0.0f;\n    float3 result;\n    if (_609_fa_emissive.w > 0.5f)\n    {\n        result = _9499;\n    }\n    else\n    {\n        float3 _8814 = normalize(_9501);\n        float _8821 = clamp(_9502, 0.0f, 1.0f);\n        float _8825 = clamp(_9503, 0.0500000007450580596923828125f, 1.0f);\n        float _8829 = _8825 * _8825;\n        float _8833 = _8829 * _8829;\n        float _8838 = max(dot(_8814, _8754), 9.9999997473787516355514526367188e-05f);\n        float _8844 = 1.0f - _8821;\n        float _8845 = clamp(_9515, 0.0f, 1.0f) * _8844;\n        float3 _8854 = (_9499 * _8844) * (1.0f - _8845);\n        float3 _8861 = lerp(0.039999999105930328369140625f.xxx, _9499, _8821.xxx);\n        float3 f0 = _8861;\n        SurfaceInput _9497 = { fa_world_pos, _9468, fa_world_tangent, fa_uv, fa_vertex_color, _8754, gl_FrontFacing };\n        SurfaceInput param_8 = _9497;\n        Surface _9600 = { _9499, _9500, _9501, _9502, _9503, _9504, _9505, _9506, _9507, _9508, _9509, _9510, _9511, _9512, _9513, _9514, _9515, _9516, _9517, _9518 };\n        Surface param_9 = _9600;\n        float3 param_10 = _8814;\n        float3 param_11 = _8754;\n        float param_12 = _8821;\n        float param_13 = _8825;\n        float3 param_14 = _8861;\n        FaLayers _8877 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _8814;\n        float3 lit = (fa_indirect_diffuse(param_15) * _8854) * _9504;\n        if (_8877.on)\n        {\n            lit *= _8877.base_scale;\n        }\n        int _8899 = fa_cl_ndir + fa_cl_local;\n        float _8964;\n        for (int ln = 0; ln < _8899; ln++)\n        {\n            int param_16 = ln;\n            int _8912 = fa_cl_light(param_16);\n            int param_17 = _8912;\n            if (fa_baked_keep(param_17) <= 0.0f)\n            {\n                continue;\n            }\n            int param_18 = _8912;\n            float3 param_19 = fa_world_pos;\n            float3 param_20 = _9468;\n            LightSample _8928 = fa_light_shadowed(param_18, param_19, param_20);\n            float _8936 = max(dot(_8814, _8928.direction), 0.0f);\n            float _8942 = _8928.attenuation * _8928.shadow;\n            float3 _8947 = normalize(_8928.direction + _8754);\n            float _8952 = max(dot(_8814, _8947), 0.0f);\n            float _8957 = max(dot(_8754, _8947), 0.0f);\n            if (fa_light_is_area)\n            {\n                if (_8877.on)\n                {\n                    _8964 = _8877.f90;\n                }\n                else\n                {\n                    _8964 = 1.0f;\n                }\n                int param_21 = _8912;\n                float3 param_22 = fa_world_pos;\n                float3 param_23 = _8814;\n                float3 param_24 = _8754;\n                float3 param_25 = _8854;\n                float3 param_26 = f0;\n                float param_27 = _8964;\n                float param_28 = _8825;\n                float param_29 = _8838;\n                float param_30 = _8942;\n                float3 area = fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n                if (_8877.on)\n                {\n                    FaLayers param_31 = _8877;\n                    float3 param_32 = area;\n                    int param_33 = _8912;\n                    float3 param_34 = _8814;\n                    float3 param_35 = _8754;\n                    float3 param_36 = _8928.direction;\n                    float param_37 = _8838;\n                    float param_38 = _8942;\n                    area = fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38);\n                }\n                lit += area;\n            }\n            else\n            {\n                if (_8877.on)\n                {\n                    FaLayers param_39 = _8877;\n                    float3 param_40 = _8854;\n                    float3 param_41 = f0;\n                    float3 param_42 = _8814;\n                    float3 param_43 = _8754;\n                    float3 param_44 = _8928.direction;\n                    float3 param_45 = _8947;\n                    float param_46 = _8936;\n                    float param_47 = _8838;\n                    float param_48 = _8952;\n                    float param_49 = _8957;\n                    float param_50 = _8829;\n                    float param_51 = _8833;\n                    int param_52 = _8912;\n                    lit += (fa_layers_light(param_39, param_40, param_41, param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51) * ((fa_light_rgb(param_52) * fa_light_tint) * _8942));\n                }\n                else\n                {\n                    float _9066 = ((_8952 * _8952) * (_8833 - 1.0f)) + 1.0f;\n                    int param_53 = _8912;\n                    lit += (((_8854 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _8957, 5.0f))) * (((_8833 / ((3.1415927410125732421875f * _9066) * _9066)) * (0.5f / max(lerp((2.0f * _8936) * _8838, _8936 + _8838, _8829), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _8936))) * (fa_light_rgb(param_53) * fa_light_tint)) * (_8936 * _8942));\n                }\n            }\n        }\n        if (_8877.on)\n        {\n            FaLayers param_54 = _8877;\n            float3 param_55 = _8814;\n            float3 param_56 = _8754;\n            float3 param_57 = f0;\n            float param_58 = _8825;\n            float param_59 = _9504;\n            lit += fa_layers_ibl(param_54, param_55, param_56, param_57, param_58, param_59);\n        }\n        else\n        {\n            float3 param_60 = _8814;\n            float3 param_61 = _8754;\n            float3 param_62 = f0;\n            float param_63 = _8825;\n            lit += (fa_sky_reflection(param_60, param_61, param_62, param_63) * _9504);\n        }\n        if (_8845 > 0.0f)\n        {\n            float _9164;\n            if (_8877.on)\n            {\n                _9164 = _8877.f90;\n            }\n            else\n            {\n                _9164 = 1.0f;\n            }\n            float _9172;\n            if (_8877.on)\n            {\n                _9172 = _8877.base_scale;\n            }\n            else\n            {\n                _9172 = 1.0f;\n            }\n            Surface _9621 = { _9499, _9500, _9501, _9502, _9503, _9504, _9505, _9506, _9507, _9508, _9509, _9510, _9511, _9512, _9513, _9514, _9515, _9516, _9517, _9518 };\n            Surface param_64 = _9621;\n            float3 param_65 = _8814;\n            float3 param_66 = _8754;\n            float param_67 = _8825;\n            float3 param_68 = f0;\n            float param_69 = _9164;\n            float param_70 = _9172;\n            float param_71 = _8845;\n            float param_72 = fa_tr_blend;\n            float3 _9196 = fa_transmitted(param_64, param_65, param_66, param_67, param_68, param_69, param_70, param_71, param_72);\n            fa_tr_blend = param_72;\n            lit += _9196;\n        }\n        result = lit;\n    }\n    float3 _9203 = result;\n    float3 _9204 = _9203 + _9505;\n    result = _9204;\n    float3 param_73 = _9204;\n    float3 param_74 = fa_world_pos;\n    result = fa_shadow_debug(param_73, param_74);\n    bool _9213 = _609_fa_fog.w > 0.0f;\n    bool _9220;\n    if (!_9213)\n    {\n        _9220 = _609_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _9220 = _9213;\n    }\n    if (_9220)\n    {\n        float3 _9229 = fa_world_pos - _609_fa_camera_pos.xyz;\n        float _9235 = dot(_9229, _609_fa_fog_c.xyz);\n        bool _9239 = _609_fa_fog_c.w > 0.5f;\n        float _9240;\n        if (_9239)\n        {\n            _9240 = _9235;\n        }\n        else\n        {\n            _9240 = length(_9229);\n        }\n        float _9252 = _9240 - _609_fa_fog_b.x;\n        if (_9252 > 0.0f)\n        {\n            float _9261 = _609_fa_fog.w * _9252;\n            float tau = _9261 * _9261;\n            if (_609_fa_fog_b.y > 0.0f)\n            {\n                float _9277;\n                if (_9239)\n                {\n                    _9277 = fa_world_pos.y - (_609_fa_fog_c.y * _9235);\n                }\n                else\n                {\n                    _9277 = _609_fa_camera_pos.y;\n                }\n                float _9298 = lerp(_9277, fa_world_pos.y, clamp(_609_fa_fog_b.x / _9240, 0.0f, 1.0f));\n                float _9302 = fa_world_pos.y - _9298;\n                float _9307 = _9298 - _609_fa_fog_b.z;\n                float _9312 = fa_world_pos.y - _609_fa_fog_b.z;\n                bool _9315 = _9307 <= 0.0f;\n                bool _9316 = !_9315;\n                bool _9322;\n                if (_9316)\n                {\n                    _9322 = _609_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _9322 = _9315;\n                }\n                float _9323;\n                if (_9322)\n                {\n                    _9323 = _609_fa_fog_b.y;\n                }\n                else\n                {\n                    _9323 = _609_fa_fog_b.y * exp(-min(_609_fa_fog_b.w * _9307, 80.0f));\n                }\n                bool _9350;\n                if (_9316)\n                {\n                    _9350 = _609_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _9350 = _9315;\n                }\n                float _9351;\n                if (_9350)\n                {\n                    _9351 = _609_fa_fog_b.y * _9307;\n                }\n                else\n                {\n                    _9351 = (_609_fa_fog_b.y * (1.0f - exp(-min(_609_fa_fog_b.w * _9307, 80.0f)))) / _609_fa_fog_b.w;\n                }\n                bool _9376 = _9312 <= 0.0f;\n                bool _9383;\n                if (!_9376)\n                {\n                    _9383 = _609_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _9383 = _9376;\n                }\n                float _9384;\n                if (_9383)\n                {\n                    _9384 = _609_fa_fog_b.y * _9312;\n                }\n                else\n                {\n                    _9384 = (_609_fa_fog_b.y * (1.0f - exp(-min(_609_fa_fog_b.w * _9312, 80.0f)))) / _609_fa_fog_b.w;\n                }\n                float _9411;\n                if (abs(_9302) < 0.001000000047497451305389404296875f)\n                {\n                    _9411 = _9323;\n                }\n                else\n                {\n                    _9411 = (_9384 - _9351) / _9302;\n                }\n                tau += (_9252 * max(_9411, 0.0f));\n            }\n            result = lerp(result, _609_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    if (fa_tr_blend > 0.0f)\n    {\n        float _9447 = 1.0f - fa_tr_blend;\n        result /= _9447.xxx;\n        _9500 *= _9447;\n    }\n    fa_frag_color = float4(result, _9500);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_609",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2353",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_8790",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _4853[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _609_fa_camera_pos : packoffset(c0);\n    float4 _609_fa_ambient : packoffset(c1);\n    float4 _609_fa_base_color : packoffset(c2);\n    float4 _609_fa_emissive : packoffset(c3);\n    float4 _609_fa_model_emissive : packoffset(c4);\n    float4 _609_fa_pbr : packoffset(c5);\n    float4 _609_fa_maps : packoffset(c6);\n    float4 _609_fa_fog : packoffset(c7);\n    float4 _609_fa_fog_b : packoffset(c8);\n    float4 _609_fa_fog_c : packoffset(c9);\n    float4 _609_fa_counts : packoffset(c10);\n    float4 _609_fa_env_sky : packoffset(c11);\n    float4 _609_fa_env_horizon : packoffset(c12);\n    float4 _609_fa_time : packoffset(c13);\n    float4 _609_fa_cl_vpx : packoffset(c14);\n    float4 _609_fa_cl_vpy : packoffset(c15);\n    float4 _609_fa_cl_vpw : packoffset(c16);\n    float4 _609_fa_cl_fwd : packoffset(c17);\n    float4 _609_fa_cl_grid : packoffset(c18);\n    float4 _609_fa_cl_info : packoffset(c19);\n    float4 _609_fa_layers_a : packoffset(c20);\n    float4 _609_fa_layers_b : packoffset(c21);\n    float4 _609_fa_layers_c : packoffset(c22);\n    float4 _609_fa_layers_d : packoffset(c23);\n    float4 _609_fa_ct_a : packoffset(c24);\n    float4 _609_fa_ct_b : packoffset(c25);\n    float4 _609_fa_ct_vpx : packoffset(c26);\n    float4 _609_fa_ct_vpy : packoffset(c27);\n    float4 _609_fa_ct_vpw : packoffset(c28);\n    float4 _609_fa_ct_fwd : packoffset(c29);\n    float4 _609_fa_tr_a : packoffset(c30);\n    float4 _609_fa_tr_b : packoffset(c31);\n    float4 _609_fa_probe_sh[9] : packoffset(c32);\n    float4 _609_fa_atlas : packoffset(c41);\n    float4 _609_fa_rpa_tile : packoffset(c42);\n    float4 _609_fa_rpa_pos : packoffset(c43);\n    float4 _609_fa_rpa_bx : packoffset(c44);\n    float4 _609_fa_rpa_by : packoffset(c45);\n    float4 _609_fa_rpa_bz : packoffset(c46);\n    float4 _609_fa_rpb_tile : packoffset(c47);\n    float4 _609_fa_rpb_pos : packoffset(c48);\n    float4 _609_fa_rpb_bx : packoffset(c49);\n    float4 _609_fa_rpb_by : packoffset(c50);\n    float4 _609_fa_rpb_bz : packoffset(c51);\n    float4 _609_fa_gi : packoffset(c52);\n    float4 _609_fa_gi_px : packoffset(c53);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2353_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2353_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2353_fa_shadow_info[4] : packoffset(c20);\n    float4 _2353_fa_shadow_split : packoffset(c24);\n    float4 _2353_fa_shadow_cfg : packoffset(c25);\n    float4 _2353_fa_shadow_bias : packoffset(c26);\n    float4 _2353_fa_shadow_eye : packoffset(c27);\n    float4 _2353_fa_shadow_fwd : packoffset(c28);\n    float4 _2353_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _8790_alphaCutoff : packoffset(c0);\n    float _8790_fa_pad0 : packoffset(c0.y);\n    float _8790_fa_pad1 : packoffset(c0.z);\n    float _8790_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t11);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_screen_tex : register(t12);\nTexture2D<float4> fa_probe_atlas : register(t7);\nTexture2D<float4> mask : register(t6);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t10);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1635 = _609_fa_cl_info.x < 0.0f;\n    bool _1642;\n    if (!_1635)\n    {\n        _1642 = _609_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1642 = _1635;\n    }\n    bool _1650;\n    if (!_1642)\n    {\n        _1650 = _609_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1650 = _1642;\n    }\n    bool _1657;\n    if (!_1650)\n    {\n        _1657 = _609_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1657 = _1650;\n    }\n    bool _1664;\n    if (!_1657)\n    {\n        _1664 = _609_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1664 = _1657;\n    }\n    if (_1664)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1674 = float4(world_pos, 1.0f);\n    float _1680 = dot(_609_fa_cl_vpw, _1674);\n    if (!(_1680 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1702 = float2(dot(_609_fa_cl_vpx, _1674), dot(_609_fa_cl_vpy, _1674)) / _1680.xx;\n    int _1706 = int(_609_fa_cl_grid.x);\n    int _1710 = int(_609_fa_cl_grid.y);\n    int param = (int(_609_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_609_fa_cl_fwd.xyz, world_pos) + _609_fa_cl_fwd.w, _609_fa_cl_grid.w) / _609_fa_cl_grid.w) * _609_fa_cl_grid.z)), 0, int(_609_fa_cl_info.y) - 1) * _1710) + clamp(int(floor(((_1702.y * 0.5f) + 0.5f) * _609_fa_cl_grid.y)), 0, _1710 - 1)) * _1706)) + clamp(int(floor(((_1702.x * 0.5f) + 0.5f) * _609_fa_cl_grid.x)), 0, _1706 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1786 = fa_cluster_texel(param);\n    return int2(int(_1786.x), int(_1786.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_609_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _6487 = fa_cluster_lookup(param);\n    fa_cl_slot = _6487.x;\n    fa_cl_local = _6487.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _7657 = fa_linear_to_srgb(param);\n        c = _7657;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _7665 = fa_srgb_to_linear(param_1);\n            c = _7665;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _541;\n    if (i.front_facing)\n    {\n        _541 = i.world_normal;\n    }\n    else\n    {\n        _541 = -i.world_normal;\n    }\n    float3 _565 = normalize(i.world_tangent.xyz - (_541 * dot(_541, i.world_tangent.xyz)));\n    float3 _592 = normalize(((_565 * m.x) + ((cross(_541, _565) * i.world_tangent.w) * m.y)) + (_541 * m.z));\n    float3 _595;\n    if (i.front_facing)\n    {\n        _595 = _592;\n    }\n    else\n    {\n        _595 = -_592;\n    }\n    return _595;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _609_fa_env_horizon.w);\n    float param = _609_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _7697 = fa_tex_fix(param_2, param_3);\n    float4 _10079 = base_t;\n    _10079.x = _7697.x;\n    _10079.y = _7697.y;\n    _10079.z = _7697.z;\n    base_t = _10079;\n    float4 _7711 = (_10079 * _609_fa_base_color) * i.vertex_color;\n    float3 _9829 = i.world_normal;\n    if (_609_fa_maps.z > 0.5f)\n    {\n        float param_4 = _609_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _609_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _7745 = fa_tex_fix(param_6, param_7);\n        float3 _7748 = (_7745 * 2.0f) - 1.0f.xxx;\n        float2 _7753 = _7748.xy * _609_fa_maps.x;\n        float3 _10087 = _7748;\n        _10087.x = _7753.x;\n        _10087.y = _7753.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _10087;\n        _9829 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _609_fa_env_horizon.w);\n    float param_10 = _609_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _7783 = fa_tex_fix(param_12, param_13);\n    float4 _10090 = mrt;\n    _10090.x = _7783.x;\n    _10090.y = _7783.y;\n    _10090.z = _7783.z;\n    mrt = _10090;\n    float4 _7813 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _609_fa_env_horizon.w);\n    float param_14 = _609_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _7813.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _7824 = fa_tex_fix(param_16, param_17);\n    float param_18 = _609_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _609_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _7856 = fa_tex_fix(param_20, param_21);\n    float _9834 = _609_fa_layers_a.x;\n    float _9835 = _609_fa_layers_a.y;\n    float _9838 = _609_fa_layers_a.z;\n    float _9837 = _609_fa_layers_b.w;\n    float _9840 = _609_fa_layers_c.x;\n    if (_609_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_609_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _9834 *= _7824.y;\n            _9835 *= _7824.z;\n            _9837 *= _7813.w;\n        }\n        if (_609_fa_layers_c.z > 1.5f)\n        {\n            _9838 *= mrt.x;\n            _9840 *= mrt.w;\n        }\n    }\n    Surface _9867 = { _7711.xyz, _7711.w, _9829, clamp(_609_fa_pbr.x * _7783.z, 0.0f, 1.0f), clamp(_609_fa_pbr.y * _7783.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_609_fa_maps.y * (_7824.x - 1.0f)), _609_fa_emissive.xyz + (_609_fa_model_emissive.xyz * _7856), _9834, _9835, _609_fa_layers_b.xyz, _9837, _9838, _609_fa_layers_a.w, _9840, _609_fa_layers_c.y, _609_fa_layers_d.xyz, _609_fa_tr_a.x, _609_fa_tr_a.y, _609_fa_tr_b.xyz, _609_fa_tr_a.z };\n    return _9867;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1866 = rect.zw - rect.xy;\n    float2 _1870 = _1866 * atlas;\n    float2 _1874 = ddx * _1870;\n    float2 _1878 = ddy * _1870;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1866), clamp(0.5f * log2(max(max(dot(_1874, _1874), dot(_1878, _1878)), 9.9999999392252902907785028219223e-09f)), 0.0f, 3.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1911 = _609_fa_counts.y < 0.5f;\n    bool _1918;\n    if (!_1911)\n    {\n        _1918 = _609_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1918 = _1911;\n    }\n    if (_1918)\n    {\n        return;\n    }\n    float3 _1924 = ddx(world_pos);\n    float3 _1927 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1931 = fa_cluster_texel(param);\n    int _1935 = int(_1931.w);\n    if (_1935 < 1)\n    {\n        return;\n    }\n    int _1945 = int(_609_fa_counts.y + 0.5f);\n    int param_1 = _1945;\n    float4 _1949 = fa_light_texel(param_1);\n    float2 _1952 = _1949.yz;\n    int _1956 = int(_1949.w);\n    int param_2 = _1945 + 1;\n    float4 _1961 = fa_light_texel(param_2);\n    float _1962 = _1961.x;\n    int _1968 = int(_609_fa_counts.w + 0.5f) - 1;\n    int _1972 = int(_1931.z);\n    float3 _2237;\n    for (int k = 0; k < _1935; k++)\n    {\n        int _1985 = _1972 + k;\n        int param_3 = _1956 + (_1985 >> 2);\n        int _2002 = (_1945 + 2) + (int(fa_light_texel(param_3)[_1985 & 3]) * 7);\n        int param_4 = _2002 + 6;\n        float4 _2007 = fa_light_texel(param_4);\n        if (((int(_2007.w + 0.5f) >> _1968) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _2002;\n        float4 _2022 = fa_light_texel(param_5);\n        int param_6 = _2002 + 1;\n        float4 _2027 = fa_light_texel(param_6);\n        int param_7 = _2002 + 2;\n        float4 _2032 = fa_light_texel(param_7);\n        float3 _2035 = _2022.xyz;\n        float _2040 = dot(_2035, world_pos) + _2022.w;\n        float3 _2042 = _2027.xyz;\n        float _2047 = dot(_2042, world_pos) + _2027.w;\n        float3 _2049 = _2032.xyz;\n        float _2054 = dot(_2049, world_pos) + _2032.w;\n        bool _2059 = abs(_2040) > 0.5f;\n        bool _2067;\n        if (!_2059)\n        {\n            _2067 = abs(_2047) > 0.5f;\n        }\n        else\n        {\n            _2067 = _2059;\n        }\n        bool _2075;\n        if (!_2067)\n        {\n            _2075 = abs(_2054) > 0.5f;\n        }\n        else\n        {\n            _2075 = _2067;\n        }\n        if (_2075)\n        {\n            continue;\n        }\n        float _2090 = clamp(dot(geo_normal, normalize(_2049)) * _2007.z, 0.0f, 1.0f);\n        if (_2090 <= 0.0f)\n        {\n            continue;\n        }\n        float _2110 = (clamp((0.5f - abs(_2054)) * 10.0f, 0.0f, 1.0f) * _2090) * _2007.x;\n        float2 _2118 = float2(_2040 + 0.5f, 0.5f - _2047);\n        float2 _2128 = float2(dot(_2035, _1924), dot(_2042, _1924));\n        float2 _2138 = float2(dot(_2035, _1927), dot(_2042, _1927));\n        int param_8 = _2002 + 5;\n        float4 _2143 = fa_light_texel(param_8);\n        int param_9 = _2002 + 3;\n        float4 _2148 = fa_light_texel(param_9);\n        int param_10 = _2002 + 4;\n        float4 _2153 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _2143.xyz;\n        bool _2163 = _2148.z > _2148.x;\n        if (_2163)\n        {\n            float4 param_11 = _2148;\n            float2 param_12 = _2118;\n            float2 param_13 = _1952;\n            float2 param_14 = _2128;\n            float2 param_15 = _2138;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1962 > 0.5f) && (_1962 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _2189 = fa_dc_to_linear(param_16);\n                float4 _9917 = tx;\n                _9917.x = _2189.x;\n                _9917.y = _2189.y;\n                _9917.z = _2189.z;\n                tx = _9917;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_2110 * tex_a) * _2143.w, 0.0f, 1.0f).xxx);\n        if (_2153.z > _2153.x)\n        {\n            float4 param_17 = _2153;\n            float2 param_18 = _2118;\n            float2 param_19 = _1952;\n            float2 param_20 = _2128;\n            float2 param_21 = _2138;\n            float4 _2233 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1962 > 1.5f)\n            {\n                float3 param_22 = _2233.xyz;\n                float3 _2243 = fa_dc_to_srgb(param_22);\n                _2237 = _2243;\n            }\n            else\n            {\n                _2237 = _2233.xyz;\n            }\n            float3 _2252 = (_2237 * 2.0f) - 1.0f.xxx;\n            float2 _2257 = _2252.xy * _2007.y;\n            float3 _2279 = (normalize(_2035) * _2257.x) + (normalize(_2042) * _2257.y);\n            float3 _2282 = normalize(normal);\n            normal = normalize(lerp(_2282, normalize((_2282 * max(_2252.z, 0.0500000007450580596923828125f)) + (_2279 - (_2282 * dot(_2282, _2279)))), clamp(_2110 * (_2163 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nvoid fa_lod_dither()\n{\n    if (_609_fa_gi.w != 0.0f)\n    {\n        float _631 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n        bool _634;\n        if (_609_fa_gi.w > 0.0f)\n        {\n            _634 = _631 >= _609_fa_gi.w;\n        }\n        else\n        {\n            _634 = _631 < (-_609_fa_gi.w);\n        }\n        if (_634)\n        {\n            discard;\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4778 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _4786 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _4789 = int(_4778);\n    int _4792 = int(_4786);\n    float _4802 = _4786 - float(_4792);\n    int _4857 = (_4789 * 9) + _4792;\n    int _4877 = ((_4789 + 1) * 9) + _4792;\n    return lerp(lerp(_4853[_4857], _4853[_4857 + 1], _4802), lerp(_4853[_4877], _4853[_4877 + 1], _4802), _4778 - float(_4789));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _9752 = false;\n    float _9753 = 1.0f;\n    float _9754 = 1.0f;\n    float _9755 = 1.0f;\n    float _9756 = 0.0f;\n    float _9757 = 0.0f;\n    float _9758 = 0.0f;\n    float _9759 = 0.0f;\n    float _9761 = 1.0f;\n    bool _9762 = false;\n    float3 _9763 = 0.0f.xxx;\n    float _9764 = 1.0f;\n    float _9765 = 1.0f;\n    float _9766 = 1.0f;\n    float _9767 = 0.0f;\n    float _9768 = 0.0f;\n    float3 _9769 = float3(1.0f, 0.0f, 0.0f);\n    float3 _9770 = float3(0.0f, 0.0f, 1.0f);\n    float _9771 = 1.0f;\n    float _9772 = 1.0f;\n    float _4928 = clamp(s.specular, 0.0f, 1.0f);\n    float _4932 = clamp(s.ior, 1.0f, 3.0f);\n    bool _4937 = (_4928 != 1.0f) || (_4932 != 1.5f);\n    bool _4946;\n    if (!_4937)\n    {\n        _4946 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _4946 = _4937;\n    }\n    if (_4946)\n    {\n        float _4954 = (_4932 - 1.0f) / (_4932 + 1.0f);\n        f0 = lerp(min((_4954 * _4954).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _4928, s.albedo, metallic.xxx);\n        _9753 = lerp(_4928, 1.0f, metallic);\n        _9752 = true;\n    }\n    float _4981 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_4981 > 0.0f)\n    {\n        float _4989 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _9756 = _4981;\n        _9757 = _4989;\n        float _4996 = _4989 * _4989;\n        _9758 = _4996;\n        _9759 = _4996 * _4996;\n        float _5008 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _9761 = _5008;\n        _9754 = 1.0f - (_4981 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _5008, 0.0f, 1.0f), 5.0f))));\n        _9752 = true;\n    }\n    float3 _5027 = max(s.sheen_color, 0.0f.xxx);\n    float _5036 = max(_5027.x, max(_5027.y, _5027.z));\n    if (_5036 > 0.0f)\n    {\n        float _5044 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _9762 = true;\n        _9763 = _5027;\n        _9764 = _5044;\n        _9765 = _5044 * _5044;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _5044;\n        float _5061 = fa_sheen_albedo(param, param_1);\n        _9767 = _5061;\n        _9766 = 1.0f - min(_5036 * _5061, 1.0f);\n        _9752 = true;\n    }\n    _9755 = _9754 * _9766;\n    float _5080 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_5080 != 0.0f)\n    {\n        float3 _5095 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _5095;\n        if (dot(_5095, _5095) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _5107 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_5107.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _5107.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _5107.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _5111 = t;\n        float3 _5112 = normalize(_5111);\n        t = _5112;\n        float3 _5137 = normalize((_5112 * cos(s.anisotropy_rotation)) + ((cross(n, _5112) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _9769 = _5137;\n        _9770 = cross(n, _5137);\n        float _5147 = roughness * roughness;\n        float _5153 = lerp(_5147, 1.0f, _5080 * _5080);\n        bool _5155 = _5080 > 0.0f;\n        _9771 = _5155 ? _5153 : _5147;\n        _9772 = _5155 ? _5147 : _5153;\n        _9768 = _5080;\n        _9752 = true;\n    }\n    FaLayers _9794 = { _9752, _9753, _9754, _9755, _9756, _9757, _9758, _9759, i.world_normal, _9761, _9762, _9763, _9764, _9765, _9766, _9767, _9768, _9769, _9770, _9771, _9772 };\n    return _9794;\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _4007_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _4007_dummy_parameter)));\n}\n\nfloat3 fa_probe_sh_coef(float2 origin, float res, int k)\n{\n    float3 v = fa_probe_atlas.SampleLevel(fa_env_smp, (origin + float2(float(k) + 0.5f, res + 2.5f)) / fa_atlas_size(), 0.0f).xyz;\n    if (_609_fa_atlas.y > 0.5f)\n    {\n        v = ((v * 255.0f) - 128.0f.xxx) * 0.03149606287479400634765625f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3948 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3948;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    float _4559 = (1.0f - _609_fa_rpa_tile.w) - _609_fa_rpb_tile.w;\n    float3 amb = 0.0f.xxx;\n    bool _4564 = _609_fa_env_sky.w > 0.5f;\n    float3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = 0.0f.xxx;\n    }\n    if (_4559 > 0.0005000000237487256526947021484375f)\n    {\n        if (_4564)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _609_fa_atlas.zw;\n                float param_1 = 128.0f;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4559;\n            }\n        }\n        else\n        {\n            amb = _609_fa_ambient.xyz * _4559;\n        }\n    }\n    bool _4615 = _609_fa_rpa_tile.w > 0.0f;\n    if (_4615)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _609_fa_rpa_tile.xy;\n            float param_4 = _609_fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * _609_fa_rpa_tile.w);\n        }\n    }\n    bool _4646 = _609_fa_rpb_tile.w > 0.0f;\n    if (_4646)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _609_fa_rpb_tile.xy;\n            float param_7 = _609_fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * _609_fa_rpb_tile.w);\n        }\n    }\n    if ((_4564 || _4615) || _4646)\n    {\n        float3 param_9[9] = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nfloat4 fa_gi_fetch(float2 texel)\n{\n    return fa_probe_atlas.SampleLevel(fa_env_smp, texel / fa_atlas_size(), 0.0f);\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3968 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3971 = _3968.x;\n    float _3973 = _3968.z;\n    float2 e = float2(_3971, _3973);\n    if (_3968.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3973)) * ((_3971 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3971)) * ((_3973 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat3 fa_gi_grid(int rec, float3 n, float3 v, out float cover)\n{\n    cover = 0.0f;\n    int param = rec;\n    float4 _7966 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    float4 _7971 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    float4 _7976 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    float4 _7981 = fa_light_texel(param_3);\n    bool _7984 = _7981.z < 0.5f;\n    bool _7992;\n    if (!_7984)\n    {\n        _7992 = fa_atlas_size().y < 1155.0f;\n    }\n    else\n    {\n        _7992 = _7984;\n    }\n    if (_7992)\n    {\n        return 0.0f.xxx;\n    }\n    float _7999 = max(_7966.w, 9.9999997473787516355514526367188e-05f);\n    float3 _8002 = _7971.xyz;\n    float3 _8006 = _7966.xyz;\n    float3 _8010 = (fa_world_pos - _8006) / _7999.xxx;\n    float3 _8019 = min(_8010 + 0.5f.xxx, (_8002 - 0.5f.xxx) - _8010);\n    float _8028 = min(_8019.x, min(_8019.y, _8019.z));\n    if (!(_8028 > 0.0f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _8043 = _8002 - 1.0f.xxx;\n    float3 _8044 = clamp(_8010, 0.0f.xxx, _8043);\n    float3 _8052 = min(floor(_8044), max(_8002 - 2.0f.xxx, 0.0f.xxx));\n    float3 _8056 = _8044 - _8052;\n    float3 _8067 = fa_world_pos + (((n * 0.800000011920928955078125f) + (v * 0.20000000298023223876953125f)) * (0.20000000298023223876953125f * _7999));\n    int _8072 = int(_7976.y + 0.5f);\n    float _8077 = 0.3257350027561187744140625f * n.y;\n    float _8081 = 0.3257350027561187744140625f * n.z;\n    float _8085 = 0.3257350027561187744140625f * n.x;\n    float _8092 = (0.2731371223926544189453125f * n.x) * n.y;\n    float _8099 = (0.2731371223926544189453125f * n.y) * n.z;\n    float _8108 = 0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f);\n    float _8115 = (0.2731371223926544189453125f * n.x) * n.z;\n    float _8128 = 0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y));\n    float3 acc = 0.0f.xxx;\n    float wsum = 0.0f;\n    int _8135 = 8 + int(_7981.w);\n    float _8162;\n    float _8175;\n    float _8189;\n    for (int k = 0; k < _8135; k++)\n    {\n        float _8148 = float(k & 1);\n        float _8152 = float((k >> 1) & 1);\n        float _8156 = float((k >> 2) & 1);\n        if (_8148 > 0.5f)\n        {\n            _8162 = _8056.x;\n        }\n        else\n        {\n            _8162 = 1.0f - _8056.x;\n        }\n        if (_8152 > 0.5f)\n        {\n            _8175 = _8056.y;\n        }\n        else\n        {\n            _8175 = 1.0f - _8056.y;\n        }\n        if (_8156 > 0.5f)\n        {\n            _8189 = _8056.z;\n        }\n        else\n        {\n            _8189 = 1.0f - _8056.z;\n        }\n        float _8199 = (_8162 * _8175) * _8189;\n        if (!(_8199 > 0.0f))\n        {\n            continue;\n        }\n        float3 _8212 = min(_8052 + float3(_8148, _8152, _8156), _8043);\n        int _8232 = int(((_7976.x + _8212.x) + (_7971.x * (_8212.y + (_7971.y * _8212.z)))) + 0.5f);\n        float2 _8247 = float2(float(_8232 % _8072) * 10.0f, 1024.0f + (float(_8232 / _8072) * 11.0f));\n        float2 param_4 = _8247 + float2(9.5f, 10.5f);\n        float4 _8255 = fa_gi_fetch(param_4);\n        bool _8258 = _8255.y < 0.5f;\n        bool _8267;\n        if (!_8258)\n        {\n            _8267 = _8255.x > _7981.y;\n        }\n        else\n        {\n            _8267 = _8258;\n        }\n        if (_8267)\n        {\n            continue;\n        }\n        float3 _8279 = _8067 - (_8006 + (_8212 * _7999));\n        float _8282 = length(_8279);\n        float3 _8288 = _8279 / max(_8282, 9.9999997473787516355514526367188e-05f).xxx;\n        float _8298 = max(9.9999997473787516355514526367188e-05f, (dot(-_8288, n) + 1.0f) * 0.5f);\n        float w = _8199 * (_8298 * _8298);\n        float3 param_5 = _8288;\n        float2 param_6 = (_8247 + 1.0f.xx) + (((fa_oct_encode(param_5) * 0.5f) + 0.5f.xx) * 8.0f);\n        float4 _8317 = fa_gi_fetch(param_6);\n        float _8324 = _8282 / max(_7976.z, 9.9999997473787516355514526367188e-05f);\n        float _8327 = _8317.x;\n        if (_8324 > _8327)\n        {\n            float _8340 = max(_8317.y - (_8327 * _8327), 0.0f);\n            float _8345 = _8324 - _8327;\n            float _8354 = _8340 / max(_8340 + (_8345 * _8345), 9.9999999600419720025001879548654e-13f);\n            w *= ((_8354 * _8354) * _8354);\n        }\n        if (!(w > 0.0f))\n        {\n            continue;\n        }\n        float2 param_7 = _8247 + float2(0.5f, 10.5f);\n        float2 param_8 = _8247 + float2(1.5f, 10.5f);\n        float2 param_9 = _8247 + float2(2.5f, 10.5f);\n        float2 param_10 = _8247 + float2(3.5f, 10.5f);\n        float2 param_11 = _8247 + float2(4.5f, 10.5f);\n        float2 param_12 = _8247 + float2(5.5f, 10.5f);\n        float2 param_13 = _8247 + float2(6.5f, 10.5f);\n        float2 param_14 = _8247 + float2(7.5f, 10.5f);\n        float2 param_15 = _8247 + float2(8.5f, 10.5f);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375f) + (fa_gi_fetch(param_8).xyz * _8077)) + (fa_gi_fetch(param_9).xyz * _8081)) + (fa_gi_fetch(param_10).xyz * _8085)) + (fa_gi_fetch(param_11).xyz * _8092)) + (fa_gi_fetch(param_12).xyz * _8099)) + (fa_gi_fetch(param_13).xyz * _8108)) + (fa_gi_fetch(param_14).xyz * _8115)) + (fa_gi_fetch(param_15).xyz * _8128)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06f))\n    {\n        return 0.0f.xxx;\n    }\n    cover = smoothstep(0.0f, 1.0f, clamp(_8028 * 2.0f, 0.0f, 1.0f)) * smoothstep(0.0f, 0.0199999995529651641845703125f, wsum);\n    float _8478;\n    if (_609_fa_gi.z > 0.5f)\n    {\n        _8478 = _7981.x;\n    }\n    else\n    {\n        _8478 = 1.0f;\n    }\n    return max(acc / wsum.xxx, 0.0f.xxx) * (_7976.w * _8478);\n}\n\nfloat3 fa_gi_light(float3 n, inout float left)\n{\n    left = 1.0f;\n    float3 acc = 0.0f.xxx;\n    float3 _8502 = normalize(_609_fa_camera_pos.xyz - fa_world_pos);\n    int _8507 = int(_609_fa_gi.x + 0.5f);\n    int _8512 = int(_609_fa_gi.y + 0.5f);\n    float param_3;\n    for (int k = 0; (k < _8512) && (k < 8); k++)\n    {\n        int param = _8507 + (4 * k);\n        float3 param_1 = n;\n        float3 param_2 = _8502;\n        float3 _8537 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _8542 = param_3 * left;\n        acc += (_8537 * _8542);\n        left -= _8542;\n        if (left < 0.001000000047497451305389404296875f)\n        {\n            left = 0.0f;\n            break;\n        }\n    }\n    return acc;\n}\n\nfloat3 fa_realtime_or_ambient(float3 n)\n{\n    float3 gi = 0.0f.xxx;\n    float left = 1.0f;\n    if (_609_fa_gi.y > 0.5f)\n    {\n        float3 param = n;\n        float param_1;\n        float3 _8571 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _8571;\n    }\n    if (left <= 0.0f)\n    {\n        return gi;\n    }\n    float3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_609_fa_gi_px.x > 0.5f)\n    {\n        float4 _8613 = float4(fa_world_pos, 1.0f);\n        float2 _8632 = float2(dot(_609_fa_ct_vpx, _8613), dot(_609_fa_ct_vpy, _8613)) / max(dot(_609_fa_ct_vpw, _8613), 9.9999997473787516355514526367188e-05f).xx;\n        float _8641;\n        if (_609_fa_ct_a.y > 0.5f)\n        {\n            _8641 = (_8632.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _8641 = 0.5f - (_8632.y * 0.5f);\n        }\n        return fa_lightmap.Load(int3(clamp(int2(float2((_8632.x * 0.5f) + 0.5f, _8641) * _609_fa_ct_a.zw), int2(0, 0), int2(_609_fa_ct_a.zw) - int2(1, 1)), 0)).xyz;\n    }\n    if (_609_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _609_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_609_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_609_fa_cl_info.x) + int(_609_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_609_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _6457;\n    if (fa_lm.z > 0.5f)\n    {\n        _6457 = 0.0f;\n    }\n    else\n    {\n        _6457 = 1.0f - clamp(_609_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _6468 = _6457 < 1.0f;\n    bool _6474;\n    if (_6468)\n    {\n        int param = li;\n        _6474 = fa_light_baked(param);\n    }\n    else\n    {\n        _6474 = _6468;\n    }\n    return _6474 ? _6457 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _765_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _765_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _884 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _897 = (c - (ru * hx)) - p;\n        float3 _903 = ru * (2.0f * hx);\n        float _909 = max(dot(_903, _903), 9.9999999392252902907785028219223e-09f);\n        float _913 = dot(_897, _903);\n        float t = clamp((-_913) / _909, 0.0f, 1.0f);\n        if (_884)\n        {\n            float _928 = dot(r, _903);\n            float _934 = _909 - (_928 * _928);\n            if (abs(_934) > (9.9999997473787516355514526367188e-06f * _909))\n            {\n                t = clamp(((dot(r, _897) * _928) - _913) / _934, 0.0f, 1.0f);\n            }\n        }\n        return (p + _897) + (_903 * t);\n    }\n    float3 q = p;\n    float _966 = dot(r, axis);\n    bool _974;\n    if (_884)\n    {\n        _974 = abs(_966) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _974 = _884;\n    }\n    if (_974)\n    {\n        float _984 = dot(c - p, axis) / _966;\n        if (_984 > 0.0f)\n        {\n            q = p + (r * _984);\n        }\n    }\n    float3 _997 = q - c;\n    float2 xy = float2(dot(_997, ru), dot(_997, uu));\n    if (shape > 0.5f)\n    {\n        float _1012 = length(xy);\n        if (_1012 > hx)\n        {\n            xy *= (hx / _1012);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _651 = abs(d);\n    float _653 = _651.x;\n    float _655 = _651.y;\n    bool _656 = _653 >= _655;\n    bool _664;\n    if (_656)\n    {\n        _664 = _653 >= _651.z;\n    }\n    else\n    {\n        _664 = _656;\n    }\n    int _665;\n    if (_664)\n    {\n        _665 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _679;\n        if (_655 >= _651.z)\n        {\n            _679 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _679 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _665 = _679;\n    }\n    return _665;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _804 = dot(d, right);\n    float _808 = dot(d, up);\n    float _819;\n    if (((_804 * _804) + (_808 * _808)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _819 = atan2(_808, _804) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _819 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_819 - floor(_819)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _1050 = fa_light_base(param);\n    bool _1054 = _609_fa_ambient.w > 4.5f;\n    int param_1 = _1050;\n    float4 _1058 = fa_light_texel(param_1);\n    int param_2 = _1050 + 1;\n    float4 _1063 = fa_light_texel(param_2);\n    float _1066 = _1063.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _1078 = _1054 && (_1066 > 2.5f);\n    fa_light_is_area = _1078;\n    bool _1080 = _1066 < 0.5f;\n    float3 l;\n    if (_1080)\n    {\n        l = normalize(_1058.xyz);\n        if (_1054)\n        {\n            int param_3 = _1050 + 6;\n            float4 _1094 = fa_light_texel(param_3);\n            if (_1094.z > 0.5f)\n            {\n                int param_4 = _1050 + 4;\n                float4 _1104 = fa_light_texel(param_4);\n                int param_5 = _1050 + 5;\n                float4 _1109 = fa_light_texel(param_5);\n                float2 param_6 = _1094.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _1104.xyz) * _1104.w, (-dot(world_pos, _1109.xyz)) * _1109.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _1139 = _1058.xyz;\n        float3 _1141 = _1139 - world_pos;\n        float3 to_light = _1141;\n        float _1144 = length(_1141);\n        float reach = _1144;\n        bool front = true;\n        if (_1078)\n        {\n            int param_8 = _1050 + 7;\n            reach = max(_1144 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _1050 + 4;\n            float4 _1168 = fa_light_texel(param_9);\n            int param_10 = _1050 + 5;\n            float4 _1173 = fa_light_texel(param_10);\n            int param_11 = _1050 + 6;\n            float4 _1178 = fa_light_texel(param_11);\n            float _1179 = _1178.w;\n            int param_12 = _1050 + 2;\n            float3 _1186 = normalize(fa_light_texel(param_12).xyz);\n            bool _1188 = _1179 > 1.5f;\n            bool _1196;\n            if (!_1188)\n            {\n                _1196 = dot(_1186, to_light) < 0.0f;\n            }\n            else\n            {\n                _1196 = _1188;\n            }\n            front = _1196;\n            float3 r = 0.0f.xxx;\n            float3 _1205 = _609_fa_camera_pos.xyz - world_pos;\n            bool _1209 = dot(n, n) > 0.5f;\n            bool _1217;\n            if (_1209)\n            {\n                _1217 = dot(_1205, _1205) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _1217 = _1209;\n            }\n            if (_1217)\n            {\n                r = reflect(-normalize(_1205), normalize(n));\n            }\n            float3 param_13 = _1139;\n            float3 param_14 = _1186;\n            float3 param_15 = _1168.xyz;\n            float3 param_16 = _1173.xyz;\n            float param_17 = _1168.w;\n            float param_18 = _1173.w;\n            float param_19 = _1179;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1253 = length(to_light);\n        dist = _1253;\n        l = to_light / max(_1253, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1267 = reach / max(_1058.w, 0.001000000047497451305389404296875f);\n        float _1273 = clamp(1.0f - (_1267 * _1267), 0.0f, 1.0f);\n        float _1275;\n        if (front)\n        {\n            _1275 = _1273 * _1273;\n        }\n        else\n        {\n            _1275 = 0.0f;\n        }\n        atten = _1275;\n        bool _1286 = _1066 < 2.5f;\n        if ((_1066 > 1.5f) && _1286)\n        {\n            int param_22 = _1050 + 2;\n            float4 _1294 = fa_light_texel(param_22);\n            float _1304 = _1294.w;\n            int param_23 = _1050 + 3;\n            float4 _1309 = fa_light_texel(param_23);\n            float _1310 = _1309.x;\n            float cos_inner = _1310;\n            if (_1310 > 1.5f)\n            {\n                cos_inner = lerp(_1304, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1304, cos_inner, dot(-l, normalize(_1294.xyz)));\n        }\n        if (_1054 && (_1066 < 1.5f))\n        {\n            int param_24 = _1050 + 6;\n            float4 _1334 = fa_light_texel(param_24);\n            if (_1334.z > 0.5f)\n            {\n                float3 _1342 = -to_light;\n                int param_25 = _1050 + 4;\n                int param_26 = _1050 + 5;\n                float3 _1356 = fa_light_texel(param_25).xyz;\n                float3 _1360 = fa_light_texel(param_26).xyz;\n                float3 _1369 = float3(dot(_1342, _1356), dot(_1342, _1360), dot(_1342, cross(_1356, _1360)));\n                float3 param_27 = _1369;\n                int _1373 = fa_cube_face(param_27);\n                int param_28 = _1373;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1400 = float2(dot(_1369, cross(param_29, param_30)), dot(_1369, param_30)) / max(dot(_1369, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1404 = _1373 / 3;\n                float2 param_31 = _1334.xy + (float2(float(_1373 - (_1404 * 3)), float(_1404)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1400.x), 0.5f - (0.5f * _1400.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1050 + 7;\n            float4 _1434 = fa_light_texel(param_33);\n            if (_1434.z > 0.5f)\n            {\n                int param_34 = _1050 + 2;\n                int param_35 = _1050 + 4;\n                int param_36 = _1050 + 5;\n                float2 param_37 = _1434.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1054 && _1286)\n            {\n                int param_42 = _1050 + 6;\n                float4 _1481 = fa_light_texel(param_42);\n                int param_43 = _1050 + 7;\n                float4 _1486 = fa_light_texel(param_43);\n                bool _1489 = _1481.z > 0.5f;\n                bool _1496;\n                if (!_1489)\n                {\n                    _1496 = _1486.z > 0.5f;\n                }\n                else\n                {\n                    _1496 = _1489;\n                }\n                if (_1496)\n                {\n                    int param_44 = _1050 + 2;\n                    float4 _1503 = fa_light_texel(param_44);\n                    float3 _1507 = normalize(_1503.xyz);\n                    int param_45 = _1050 + 4;\n                    float4 _1512 = fa_light_texel(param_45);\n                    int param_46 = _1050 + 5;\n                    float4 _1517 = fa_light_texel(param_46);\n                    if (_1489)\n                    {\n                        float3 _1525 = -to_light;\n                        float _1532 = _1503.w;\n                        float _1548 = 0.5f / max(dot(_1525, _1507) * (sqrt(max(1.0f - (_1532 * _1532), 0.0f)) / max(_1532, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1481.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1525, _1512.xyz) * _1548), 0.5f - (dot(_1525, _1517.xyz) * _1548));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1486.z > 0.5f)\n                    {\n                        float2 param_49 = _1486.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1507;\n                        float3 param_52 = _1512.xyz;\n                        float3 param_53 = _1517.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _9740 = _1063.xyz * atten;\n    if (_1054)\n    {\n        _9740 *= fa_light_tint;\n    }\n    int _1617;\n    if (_1080)\n    {\n        _1617 = 0;\n    }\n    else\n    {\n        _1617 = ((_1066 > 1.5f) && (_1066 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _9751 = { l, _9740, atten, 1.0f, dist, _1617 };\n    return _9751;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2343;\n    if (i == 0)\n    {\n        _2343 = _2353_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2359;\n        if (i == 1)\n        {\n            _2359 = _2353_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2367;\n            if (i == 2)\n            {\n                _2367 = _2353_fa_shadow_split.z;\n            }\n            else\n            {\n                _2367 = _2353_fa_shadow_split.w;\n            }\n            _2359 = _2367;\n        }\n        _2343 = _2359;\n    }\n    return _2343;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2400 = fa_shadow_depth(param, param_1);\n    float _2404;\n    if (conv.x < 0.5f)\n    {\n        _2404 = _2400;\n    }\n    else\n    {\n        _2404 = (conv.y * conv.z) / (conv.z - (_2400 * (conv.z - conv.y)));\n    }\n    return _2404;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel_turn(float2 d)\n{\n    return float2((d.x * (-0.737368881702423095703125f)) - (d.y * 0.675490319728851318359375f), (d.y * (-0.737368881702423095703125f)) + (d.x * 0.675490319728851318359375f));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2450 = fa_shadow_noise() * 6.283185482025146484375f;\n    float2 _2456 = float2(cos(_2450), sin(_2450));\n    float2 dir = _2456;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2465;\n        if (k < 0.0f)\n        {\n            _2465 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2465 = k;\n        }\n        float _2484 = clamp((_2465 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2503 = sqrt((float(i) + 0.5f) * 0.0625f) * _2484;\n            float2 param_3 = uv + (dir * (_2353_fa_shadow_bias.zw * _2503));\n            float4 param_4 = rect;\n            float3 param_5 = conv;\n            float _2517 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2517 < (zr - (_2503 * plane)))\n            {\n                sum += _2517;\n                cnt += 1.0f;\n            }\n            float2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2545 = sum / cnt;\n        float _2555;\n        if (k < 0.0f)\n        {\n            _2555 = (-k) / max(_2545, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2555 = k;\n        }\n        radius = clamp(((max(zr - _2545, 0.0f) * unit) * _2555) / texel_m, 1.5f, 16.0f);\n        dir = _2456;\n    }\n    float lit = 0.0f;\n    int _2581 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2581; i_1++)\n    {\n        float _2600 = sqrt((float(i_1) + 0.5f) / float(_2581)) * radius;\n        float2 param_7 = uv + (dir * (_2353_fa_shadow_bias.zw * _2600));\n        float4 param_8 = rect;\n        float3 param_9 = conv;\n        lit += float((zr - (_2600 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        float2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2581);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2646 = max(_2353_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2651 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2657 = sqrt(1.0f - (_2651 * _2651));\n    float _2665 = min(_2657 / max(_2651, 0.20000000298023223876953125f), 4.0f);\n    float _2670;\n    if (_2353_fa_shadow_bias.y > 0.0f)\n    {\n        _2670 = _2353_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2670 = 1.5f * _2353_fa_shadow_info[ci].x;\n    }\n    float4 _2695 = mul(float4(world + (n * (_2670 * _2657)), 1.0f), _2353_fa_shadow_mat[ci]);\n    float _2702 = _2695.x;\n    bool _2705 = _2702 < _2353_fa_shadow_rect[ci].x;\n    bool _2714;\n    if (!_2705)\n    {\n        _2714 = _2702 > _2353_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2714 = _2705;\n    }\n    bool _2723;\n    if (!_2714)\n    {\n        _2723 = _2695.y < _2353_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2723 = _2714;\n    }\n    bool _2732;\n    if (!_2723)\n    {\n        _2732 = _2695.y > _2353_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2732 = _2723;\n    }\n    bool _2739;\n    if (!_2732)\n    {\n        _2739 = _2695.z > 1.0f;\n    }\n    else\n    {\n        _2739 = _2732;\n    }\n    if (_2739)\n    {\n        return -1.0f;\n    }\n    float _2747;\n    if (_2353_fa_shadow_bias.x > 0.0f)\n    {\n        _2747 = _2353_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2747 = 1.5f * _2353_fa_shadow_info[ci].x;\n    }\n    float2 param = _2695.xy;\n    float4 param_1 = _2353_fa_shadow_rect[ci];\n    float param_2 = _2695.z - ((_2747 * (1.0f + (0.5f * _2665))) / _2646);\n    float param_3 = _2353_fa_shadow_info[ci].x;\n    float param_4 = _2646;\n    float param_5 = _2646 * 0.25f;\n    float param_6 = ((_2353_fa_shadow_info[ci].x * min(_2665, 3.0f)) * 0.5f) / _2646;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2353_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2353_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_609_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _3125 = int(_2353_fa_shadow_cfg.x + 0.5f);\n    if (_3125 < 1)\n    {\n        return 1.0f;\n    }\n    float _3140 = dot(world - _2353_fa_shadow_eye.xyz, _2353_fa_shadow_fwd.xyz);\n    int param = _3125 - 1;\n    if (_3140 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _3152 = _3125 > 1;\n    bool _3159;\n    if (_3152)\n    {\n        _3159 = _3140 > _2353_fa_shadow_split.x;\n    }\n    else\n    {\n        _3159 = _3152;\n    }\n    if (_3159)\n    {\n        ci = 1;\n    }\n    bool _3163 = _3125 > 2;\n    bool _3170;\n    if (_3163)\n    {\n        _3170 = _3140 > _2353_fa_shadow_split.y;\n    }\n    else\n    {\n        _3170 = _3163;\n    }\n    if (_3170)\n    {\n        ci = 2;\n    }\n    bool _3174 = _3125 > 3;\n    bool _3181;\n    if (_3174)\n    {\n        _3181 = _3140 > _2353_fa_shadow_split.z;\n    }\n    else\n    {\n        _3181 = _3174;\n    }\n    if (_3181)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    float s2 = -1.0f;\n    float t = 0.0f;\n    int _3192 = min(_3125, 4);\n    float _3233;\n    for (int c = ci; c < _3192; c++)\n    {\n        int param_1 = c;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _3212 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0f)\n        {\n            s2 = _3212;\n            break;\n        }\n        if (_3212 < 0.0f)\n        {\n            continue;\n        }\n        s = _3212;\n        ci = c;\n        if (_2353_fa_shadow_cfg.y > 0.0f)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3233 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3233 = _2353_fa_shadow_fwd.w;\n            }\n            int param_6 = ci;\n            float _3252 = _2353_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3233, 9.9999997473787516355514526367188e-05f);\n            int param_7 = ci;\n            t = clamp((_3140 - (fa_shadow_split_at(param_7) - _3252)) / _3252, 0.0f, 1.0f);\n        }\n        if (t <= 0.0f)\n        {\n            break;\n        }\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (t > 0.0f)\n    {\n        float _3284;\n        if ((ci + 1) < _3125)\n        {\n            _3284 = (s2 < 0.0f) ? s : s2;\n        }\n        else\n        {\n            _3284 = 1.0f;\n        }\n        s = lerp(s, _3284, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    bool _3389 = _609_fa_ct_b.y > 0.5f;\n    bool _3395;\n    if (_3389)\n    {\n        _3395 = _609_fa_pbr.z > 0.5f;\n    }\n    else\n    {\n        _3395 = _3389;\n    }\n    if (_3395)\n    {\n        float _3409 = dot(_609_fa_ct_fwd.xyz, fa_world_pos) + _609_fa_ct_fwd.w;\n        float _3412 = fwidth(_3409);\n        float4 _3422 = float4(fa_world_pos, 1.0f);\n        float _3428 = dot(_609_fa_ct_vpw, _3422);\n        if (_3428 > 9.9999997473787516355514526367188e-05f)\n        {\n            float2 _3447 = float2(dot(_609_fa_ct_vpx, _3422), dot(_609_fa_ct_vpy, _3422)) / _3428.xx;\n            float _3452 = (_3447.x * 0.5f) + 0.5f;\n            float _3456;\n            if (_609_fa_ct_a.y > 0.5f)\n            {\n                _3456 = (_3447.y * 0.5f) + 0.5f;\n            }\n            else\n            {\n                _3456 = 0.5f - (_3447.y * 0.5f);\n            }\n            bool _3472 = _3452 >= 0.0f;\n            bool _3478;\n            if (_3472)\n            {\n                _3478 = _3452 < 1.0f;\n            }\n            else\n            {\n                _3478 = _3472;\n            }\n            bool _3484;\n            if (_3478)\n            {\n                _3484 = _3456 >= 0.0f;\n            }\n            else\n            {\n                _3484 = _3478;\n            }\n            bool _3490;\n            if (_3484)\n            {\n                _3490 = _3456 < 1.0f;\n            }\n            else\n            {\n                _3490 = _3484;\n            }\n            if (_3490)\n            {\n                float4 _3516 = fa_screen_tex.Load(int3(clamp(int2(float2(_3452, _3456) * _609_fa_ct_a.zw), int2(0, 0), int2(_609_fa_ct_a.zw) - int2(1, 1)), 0));\n                bool _3519 = _3516.w > 0.5f;\n                bool _3535;\n                if (_3519)\n                {\n                    _3535 = abs(_3409 - _3516.x) <= (((0.00200000009499490261077880859375f * _3409) + 0.00999999977648258209228515625f) + min(1.5f * _3412, 0.100000001490116119384765625f * _3409));\n                }\n                else\n                {\n                    _3535 = _3519;\n                }\n                if (_3535)\n                {\n                    float _3541;\n                    if (_609_fa_ct_b.z > 0.5f)\n                    {\n                        float3 param = fa_world_pos;\n                        float3 param_1 = n;\n                        float3 param_2 = l;\n                        _3541 = min(_3516.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3541 = _3516.y;\n                    }\n                    return _3541;\n                }\n            }\n        }\n    }\n    float3 param_3 = fa_world_pos;\n    float3 param_4 = n;\n    float3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2805 = _609_fa_pbr.z < 0.5f;\n    bool _2812;\n    if (!_2805)\n    {\n        _2812 = _2353_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2812 = _2805;\n    }\n    if (_2812)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2353_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2825 = fa_light_texel(param);\n    float _2826 = _2825.x;\n    if (_2826 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2835 = int(_2826 + 0.5f);\n    int param_1 = _2835;\n    float4 _2839 = fa_light_texel(param_1);\n    int param_2 = _2835 + 1;\n    float4 _2844 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2847 = _2839.y;\n    if (_2847 > 0.0f)\n    {\n        float _2864 = 1.0f - smoothstep(0.75f * _2847, _2847, length(world - _2353_fa_shadow_eye.xyz));\n        fade = _2864;\n        if (_2864 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2839.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2888 = (_2835 + 2) + (face * 6);\n    int param_4 = _2888;\n    int param_5 = _2888 + 1;\n    int param_6 = _2888 + 3;\n    float4 _2902 = fa_light_texel(param_6);\n    int param_7 = _2888 + 4;\n    float4 _2907 = fa_light_texel(param_7);\n    int param_8 = _2888 + 5;\n    float4 _2912 = fa_light_texel(param_8);\n    float _2924 = _2912.x * max(dot(_2902, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2929 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2952 = clamp(dot(n, _2902.xyz), -1.0f, 1.0f);\n    float _2971 = min(sqrt(1.0f - (_2952 * _2952)) / max(abs(dot(n, world - lpos)) / max(dot(_2902, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2974 = _2844.y;\n    float _2976;\n    if (_2974 > 0.0f)\n    {\n        _2976 = _2974;\n    }\n    else\n    {\n        _2976 = 1.5f * _2924;\n    }\n    float4 _2996 = float4(world + (n * (_2976 * sqrt(1.0f - (_2929 * _2929)))), 1.0f);\n    float _3000 = dot(_2902, _2996);\n    float _3003 = _2912.y;\n    if (_3000 < _3003)\n    {\n        return 1.0f;\n    }\n    float2 _3018 = float2(dot(fa_light_texel(param_4), _2996), dot(fa_light_texel(param_5), _2996)) / _3000.xx;\n    float _3020 = _3018.x;\n    bool _3023 = _3020 < _2907.x;\n    bool _3032;\n    if (!_3023)\n    {\n        _3032 = _3020 > _2907.z;\n    }\n    else\n    {\n        _3032 = _3023;\n    }\n    bool _3041;\n    if (!_3032)\n    {\n        _3041 = _3018.y < _2907.y;\n    }\n    else\n    {\n        _3041 = _3032;\n    }\n    bool _3050;\n    if (!_3041)\n    {\n        _3050 = _3018.y > _2907.w;\n    }\n    else\n    {\n        _3050 = _3041;\n    }\n    if (_3050)\n    {\n        return 1.0f;\n    }\n    float _3056 = _2844.x;\n    float _3058;\n    if (_3056 > 0.0f)\n    {\n        _3058 = _3056;\n    }\n    else\n    {\n        _3058 = 1.5f * _2924;\n    }\n    float2 param_9 = _3018;\n    float4 param_10 = _2907;\n    float param_11 = _3000 - (_3058 * (1.0f + (0.5f * _2971)));\n    float param_12 = _2924;\n    float param_13 = 1.0f;\n    float param_14 = _2912.z * 0.25f;\n    float param_15 = (_2924 * min(_2971, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _3003, _2912.z);\n    int param_17 = int(_2839.z + 0.5f);\n    float param_18 = _2839.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _3570 = _609_fa_ct_b.w > 0.5f;\n    bool _3576;\n    if (_3570)\n    {\n        _3576 = _609_fa_pbr.z > 0.5f;\n    }\n    else\n    {\n        _3576 = _3570;\n    }\n    bool _3582;\n    if (_3576)\n    {\n        _3582 = _2353_fa_shadow_lcfg.x > 0.5f;\n    }\n    else\n    {\n        _3582 = _3576;\n    }\n    if (_3582)\n    {\n        int param = (int(_2353_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n        float4 _3594 = fa_light_texel(param);\n        float _3595 = _3594.z;\n        if (_3595 > 0.5f)\n        {\n            float _3608 = dot(_609_fa_ct_fwd.xyz, world) + _609_fa_ct_fwd.w;\n            float _3611 = fwidth(_3608);\n            float _3615 = min(1.5f * _3611, 0.100000001490116119384765625f * _3608);\n            float4 _3621 = float4(world, 1.0f);\n            float _3626 = dot(_609_fa_ct_vpw, _3621);\n            if (_3626 > 9.9999997473787516355514526367188e-05f)\n            {\n                float2 _3643 = float2(dot(_609_fa_ct_vpx, _3621), dot(_609_fa_ct_vpy, _3621)) / _3626.xx;\n                float _3648 = (_3643.x * 0.5f) + 0.5f;\n                float _3652;\n                if (_609_fa_ct_a.y > 0.5f)\n                {\n                    _3652 = (_3643.y * 0.5f) + 0.5f;\n                }\n                else\n                {\n                    _3652 = 0.5f - (_3643.y * 0.5f);\n                }\n                bool _3668 = _3648 >= 0.0f;\n                bool _3674;\n                if (_3668)\n                {\n                    _3674 = _3648 < 1.0f;\n                }\n                else\n                {\n                    _3674 = _3668;\n                }\n                bool _3680;\n                if (_3674)\n                {\n                    _3680 = _3652 >= 0.0f;\n                }\n                else\n                {\n                    _3680 = _3674;\n                }\n                bool _3686;\n                if (_3680)\n                {\n                    _3686 = _3652 < 1.0f;\n                }\n                else\n                {\n                    _3686 = _3680;\n                }\n                if (_3686)\n                {\n                    int2 _3703 = int2(_609_fa_ct_a.zw) - int2(1, 1);\n                    int2 _3704 = clamp(int2(float2(_3648, _3652) * _609_fa_ct_a.zw), int2(0, 0), _3703);\n                    int2 _3716;\n                    int2 _3722;\n                    int2 _3729;\n                    float _3780;\n                    float _3801;\n                    for (int k = 0; k < 5; k++)\n                    {\n                        if (k == 0)\n                        {\n                            _3716 = int2(0, 0);\n                        }\n                        else\n                        {\n                            if (k == 1)\n                            {\n                                _3722 = int2(1, 0);\n                            }\n                            else\n                            {\n                                if (k == 2)\n                                {\n                                    _3729 = int2(-1, 0);\n                                }\n                                else\n                                {\n                                    bool2 _3740 = (k == 3).xx;\n                                    _3729 = int2(_3740.x ? int2(0, 1).x : int2(0, -1).x, _3740.y ? int2(0, 1).y : int2(0, -1).y);\n                                }\n                                _3722 = _3729;\n                            }\n                            _3716 = _3722;\n                        }\n                        float4 _3757 = fa_screen_tex.Load(int3(clamp(_3704 + _3716, int2(0, 0), _3703), 0));\n                        bool _3760 = _3757.w > 0.5f;\n                        bool _3774;\n                        if (_3760)\n                        {\n                            _3774 = abs(_3608 - _3757.x) <= (((0.00200000009499490261077880859375f * _3608) + 0.00999999977648258209228515625f) + _3615);\n                        }\n                        else\n                        {\n                            _3774 = _3760;\n                        }\n                        if (_3774)\n                        {\n                            if (_3595 < 1.5f)\n                            {\n                                _3780 = 1.0f;\n                            }\n                            else\n                            {\n                                _3780 = (_3595 < 2.5f) ? 256.0f : 65536.0f;\n                            }\n                            float _3797 = mod(floor(_3757.z / _3780), 256.0f) * 0.0039215688593685626983642578125f;\n                            if (_609_fa_ct_b.z > 0.5f)\n                            {\n                                int param_1 = li;\n                                float3 param_2 = lpos;\n                                float3 param_3 = world;\n                                float3 param_4 = n;\n                                float3 param_5 = l;\n                                _3801 = min(_3797, fa_shadow_local(param_1, param_2, param_3, param_4, param_5));\n                            }\n                            else\n                            {\n                                _3801 = _3797;\n                            }\n                            return _3801;\n                        }\n                    }\n                }\n            }\n            float _3826;\n            if (_609_fa_ct_b.z > 0.5f)\n            {\n                int param_6 = li;\n                float3 param_7 = lpos;\n                float3 param_8 = world;\n                float3 param_9 = n;\n                float3 param_10 = l;\n                _3826 = fa_shadow_local(param_6, param_7, param_8, param_9, param_10);\n            }\n            else\n            {\n                _3826 = 1.0f;\n            }\n            return _3826;\n        }\n    }\n    int param_11 = li;\n    float3 param_12 = lpos;\n    float3 param_13 = world;\n    float3 param_14 = n;\n    float3 param_15 = l;\n    return fa_shadow_local(param_11, param_12, param_13, param_14, param_15);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _5671 = _609_fa_ct_a.x < 0.5f;\n    bool _5678;\n    if (!_5671)\n    {\n        _5678 = _2353_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _5678 = _5671;\n    }\n    if (_5678)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2353_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _5691 = fa_light_texel(param);\n    float _5692 = _5691.y;\n    float len = _5692;\n    if (_5692 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _5704 = length(world - _609_fa_camera_pos.xyz);\n    float _5713 = 1.0f - smoothstep(0.5f * _609_fa_ct_b.x, _609_fa_ct_b.x, _5704);\n    if (_5713 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _5719 = len;\n    float _5722 = min(_5719, 0.89999997615814208984375f * dist);\n    len = _5722;\n    float _5727 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _5704);\n    float _5732 = _5727 + (0.5f * _5722);\n    float3 _5738 = world + (gn * _5727);\n    float _5740 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _5801;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5755 = (float(k) + _5740) * 0.083333335816860198974609375f;\n        float3 _5763 = _5738 + (l * (_5755 * len));\n        float4 _5769 = float4(_5763, 1.0f);\n        float _5774 = dot(_609_fa_ct_vpw, _5769);\n        if (_5774 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _5792 = float2(dot(_609_fa_ct_vpx, _5769), dot(_609_fa_ct_vpy, _5769)) / _5774.xx;\n        float _5796 = _5792.x * 0.5f;\n        float _5797 = _5796 + 0.5f;\n        if (_609_fa_ct_a.y > 0.5f)\n        {\n            _5801 = (_5792.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _5801 = 0.5f - (_5792.y * 0.5f);\n        }\n        bool _5817 = _5797 < 0.0f;\n        bool _5824;\n        if (!_5817)\n        {\n            _5824 = _5797 >= 1.0f;\n        }\n        else\n        {\n            _5824 = _5817;\n        }\n        bool _5831;\n        if (!_5824)\n        {\n            _5831 = _5801 < 0.0f;\n        }\n        else\n        {\n            _5831 = _5824;\n        }\n        bool _5838;\n        if (!_5831)\n        {\n            _5838 = _5801 >= 1.0f;\n        }\n        else\n        {\n            _5838 = _5831;\n        }\n        if (_5838)\n        {\n            break;\n        }\n        float4 _5862 = fa_screen_tex.Load(int3(clamp(int2(float2(_5797, _5801) * _609_fa_ct_a.zw), int2(0, 0), int2(_609_fa_ct_a.zw) - int2(1, 1)), 0));\n        if (_5862.w < 0.5f)\n        {\n            continue;\n        }\n        float _5880 = (dot(_609_fa_ct_fwd.xyz, _5763) + _609_fa_ct_fwd.w) - _5862.x;\n        if ((_5880 > _5727) && (_5880 < _5732))\n        {\n            occ = max(occ, (1.0f - (_5755 * _5755)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_5797, 0.5f - _5796), min(_5801, 1.0f - _5801))));\n        }\n    }\n    return 1.0f - (occ * _5713);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _6513 = fa_baked_keep(param);\n    if (_6513 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _9807 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _9807;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _6539 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _9809 = _6539.color;\n    float _9810 = _6539.attenuation;\n    float _9811 = _6539.shadow;\n    bool _6542 = _6539.type == 0;\n    if (_6542 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _6539.direction;\n        float _6553 = fa_shadow_factor(param_5, param_6);\n        _9811 = _6553;\n        _9809 *= _6553;\n    }\n    else\n    {\n        bool _6564 = _6539.type != 0;\n        bool _6570;\n        if (_6564)\n        {\n            _6570 = _9810 > 0.0f;\n        }\n        else\n        {\n            _6570 = _6564;\n        }\n        if (_6570)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _6539.direction;\n            float _6589 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _9811 = _6589;\n            _9809 *= _6589;\n        }\n    }\n    bool _6599 = _609_fa_ct_a.x > 0.5f;\n    bool _6605;\n    if (_6599)\n    {\n        _6605 = _9810 > 0.0f;\n    }\n    else\n    {\n        _6605 = _6599;\n    }\n    if (_6605)\n    {\n        float _6612;\n        if (_6542)\n        {\n            _6612 = 1000000000.0f;\n        }\n        else\n        {\n            _6612 = _6539._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _6539.direction;\n        float param_18 = _6612;\n        float _6630 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9811 *= _6630;\n        _9809 *= _6630;\n    }\n    float _6643 = _9810;\n    float _6644 = _6643 * _6513;\n    _9810 = _6644;\n    float3 _6648 = _9809;\n    float3 _6649 = _6648 * _6513;\n    _9809 = _6649;\n    LightSample _9826 = { _6539.direction, _6649, _6644, _9811, _6539._distance, _6539.type };\n    return _9826;\n}\n\nfloat3 fa_ltc_tangent(float3 n, float3 v)\n{\n    float3 _6683 = v - (n * dot(v, n));\n    float3 t = _6683;\n    float _6687 = dot(_6683, _6683);\n    float l2 = _6687;\n    if (_6687 < 1.0000000133514319600180897396058e-10f)\n    {\n        float3 _6697;\n        if (abs(n.z) < 0.999000012874603271484375f)\n        {\n            _6697 = cross(n, float3(0.0f, 0.0f, 1.0f));\n        }\n        else\n        {\n            _6697 = cross(n, float3(1.0f, 0.0f, 0.0f));\n        }\n        t = _6697;\n        l2 = dot(_6697, _6697);\n    }\n    return t * rsqrt(l2);\n}\n\nfloat3 fa_ltc_local(float3 t1, float3 n, float3 p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nfloat2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((float2(clamp((roughness - 0.0500000007450580596923828125f) * 1.0526316165924072265625f, 0.0f, 1.0f), sqrt(clamp(1.0f - ndv, 0.0f, 1.0f))) * 63.0f) + 0.5f.xx) * 0.015625f.xx;\n}\n\nfloat3 fa_oct_vertex(int j, float3 pc, float3 ex, float3 ey)\n{\n    float _7084;\n    if ((j == 0) || (j == 7))\n    {\n        _7084 = 0.92387950420379638671875f;\n    }\n    else\n    {\n        float _7094;\n        if ((j == 3) || (j == 4))\n        {\n            _7094 = -0.92387950420379638671875f;\n        }\n        else\n        {\n            _7094 = ((j == 1) || (j == 6)) ? 0.3826834261417388916015625f : (-0.3826834261417388916015625f);\n        }\n        _7084 = _7094;\n    }\n    float _7115;\n    if ((j == 1) || (j == 2))\n    {\n        _7115 = 0.92387950420379638671875f;\n    }\n    else\n    {\n        float _7124;\n        if ((j == 5) || (j == 6))\n        {\n            _7124 = -0.92387950420379638671875f;\n        }\n        else\n        {\n            _7124 = ((j == 0) || (j == 3)) ? 0.3826834261417388916015625f : (-0.3826834261417388916015625f);\n        }\n        _7115 = _7124;\n    }\n    return (pc + (ex * _7084)) + (ey * _7115);\n}\n\nfloat3 fa_ltc_edge_vector(float3 a, float3 b)\n{\n    float _6732 = dot(a, a);\n    float _6736 = dot(b, b);\n    if ((_6732 < 1.0000000195414813782625560981111e-24f) || (_6736 < 1.0000000195414813782625560981111e-24f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _6750 = a * rsqrt(_6732);\n    float3 _6755 = b * rsqrt(_6736);\n    float _6759 = dot(_6750, _6755);\n    float _6762 = abs(_6759);\n    float g = (((((((((((0.0416471660137176513671875f * _6762) - 0.1924748718738555908203125f) * _6762) + 0.4179156124591827392578125f) * _6762) - 0.616057217121124267578125f) * _6762) + 0.777722418308258056640625f) * _6762) - 0.999542415142059326171875f) * _6762) + 1.570791721343994140625f;\n    if (_6759 < 0.0f)\n    {\n        g = (3.1415927410125732421875f * rsqrt(max(1.0f - (_6759 * _6759), 1.0000000116860974230803549289703e-07f))) - g;\n    }\n    return cross(_6750, _6755) * g;\n}\n\nvoid fa_ltc_clip_edge(float3 a, float3 b, inout float3 sum, inout float3 leave, inout float3 enter, inout float2 seen)\n{\n    bool _6819 = a.z > 0.0f;\n    bool _6823 = b.z > 0.0f;\n    if (_6819 && _6823)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6819 != _6823)\n        {\n            float3 _6858 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6858.z = 0.0f;\n            if (_6819)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _6858;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6858;\n                seen.x = 1.0f;\n            }\n            else\n            {\n                float3 param_4 = _6858;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6858;\n                seen.y = 1.0f;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(float4 abcd, float3 p0, float3 p1, float3 p2, float3 p3)\n{\n    float3 _6907 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _6933 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _6959 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _6985 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = 0.0f.xxx;\n    float3 leave = 0.0f.xxx;\n    float3 enter = 0.0f.xxx;\n    float3 param = _6907;\n    float3 param_1 = _6933;\n    float3 param_2 = 0.0f.xxx;\n    float3 param_3 = 0.0f.xxx;\n    float3 param_4 = 0.0f.xxx;\n    float2 param_5 = 0.0f.xx;\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _6933;\n    float3 param_7 = _6959;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _6959;\n    float3 param_13 = _6985;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _6985;\n    float3 param_19 = _6907;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5f)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875f;\n}\n\nfloat2 fa_area_forms(float4 m, float shape, float3 pc, float3 ex, float3 ey)\n{\n    int _7153 = ((shape < 0.5f) || (shape > 1.5f)) ? 1 : 3;\n    float2 sum = 0.0f.xx;\n    int _7171;\n    for (int k = 0; k < (2 * _7153); k++)\n    {\n        bool _7168 = k >= _7153;\n        if (_7168)\n        {\n            _7171 = k - _7153;\n        }\n        else\n        {\n            _7171 = k;\n        }\n        float3 p0 = (pc - ex) - ey;\n        float3 p1 = (pc + ex) - ey;\n        float3 p2 = (pc + ex) + ey;\n        float3 p3 = (pc - ex) + ey;\n        if (_7153 == 3)\n        {\n            int param = 0;\n            float3 param_1 = pc;\n            float3 param_2 = ex;\n            float3 param_3 = ey;\n            p0 = fa_oct_vertex(param, param_1, param_2, param_3);\n            int _7217 = 2 * _7171;\n            int param_4 = _7217 + 1;\n            float3 param_5 = pc;\n            float3 param_6 = ex;\n            float3 param_7 = ey;\n            p1 = fa_oct_vertex(param_4, param_5, param_6, param_7);\n            int param_8 = _7217 + 2;\n            float3 param_9 = pc;\n            float3 param_10 = ex;\n            float3 param_11 = ey;\n            p2 = fa_oct_vertex(param_8, param_9, param_10, param_11);\n            int param_12 = _7217 + 3;\n            float3 param_13 = pc;\n            float3 param_14 = ex;\n            float3 param_15 = ey;\n            p3 = fa_oct_vertex(param_12, param_13, param_14, param_15);\n        }\n        bool4 _7254 = _7168.xxxx;\n        float4 param_16 = float4(_7254.x ? m.x : float4(1.0f, 0.0f, 0.0f, 1.0f).x, _7254.y ? m.y : float4(1.0f, 0.0f, 0.0f, 1.0f).y, _7254.z ? m.z : float4(1.0f, 0.0f, 0.0f, 1.0f).z, _7254.w ? m.w : float4(1.0f, 0.0f, 0.0f, 1.0f).w);\n        float3 param_17 = p0;\n        float3 param_18 = p1;\n        float3 param_19 = p2;\n        float3 param_20 = p3;\n        float _7265 = fa_ltc_quad(param_16, param_17, param_18, param_19, param_20);\n        if (_7168)\n        {\n            float2 _10062 = sum;\n            _10062.y = _10062.y + _7265;\n            sum = _10062;\n        }\n        else\n        {\n            float2 _10065 = sum;\n            _10065.x = _10065.x + _7265;\n            sum = _10065;\n        }\n    }\n    return abs(sum);\n}\n\nfloat3 fa_area_shade(int li, float3 world_pos, float3 n, float3 v, float3 diffuse_color, float3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _7289 = fa_light_base(param);\n    int param_1 = _7289;\n    int param_2 = _7289 + 1;\n    int param_3 = _7289 + 2;\n    int param_4 = _7289 + 4;\n    float4 _7311 = fa_light_texel(param_4);\n    int param_5 = _7289 + 5;\n    float4 _7316 = fa_light_texel(param_5);\n    int param_6 = _7289 + 6;\n    float4 _7321 = fa_light_texel(param_6);\n    float _7322 = _7321.w;\n    float3 _7327 = fa_light_texel(param_1).xyz - world_pos;\n    bool _7329 = _7322 < 1.5f;\n    bool _7336;\n    if (_7329)\n    {\n        _7336 = dot(normalize(fa_light_texel(param_3).xyz), _7327) >= 0.0f;\n    }\n    else\n    {\n        _7336 = _7329;\n    }\n    if (_7336)\n    {\n        return 0.0f.xxx;\n    }\n    bool _7345 = (_7322 > 0.5f) && _7329;\n    float _7349 = _7345 ? 1.0539000034332275390625f : 1.0f;\n    float3 _7352 = _7311.xyz;\n    float _7354 = _7311.w;\n    float3 _7360 = _7316.xyz;\n    float _7362 = _7316.w;\n    float3 up = _7360 * (_7362 * _7349);\n    float _7368;\n    if (_7345)\n    {\n        _7368 = (3.1415927410125732421875f * _7354) * _7354;\n    }\n    else\n    {\n        _7368 = (4.0f * _7354) * _7362;\n    }\n    if (_7322 > 1.5f)\n    {\n        float3 _7394 = cross(_7352, -_7327);\n        float3 perp = _7394;\n        float _7398 = dot(_7394, _7394);\n        float3 _7401;\n        if (_7398 > 1.0000000133514319600180897396058e-10f)\n        {\n            _7401 = perp * rsqrt(_7398);\n        }\n        else\n        {\n            _7401 = _7360;\n        }\n        perp = _7401;\n        up = _7401 * _7362;\n    }\n    float _7422 = max(_7368, 9.9999999747524270787835121154785e-07f);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _7432 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _7432;\n    float3 param_10 = n;\n    float3 param_11 = _7327;\n    float3 param_12 = _7432;\n    float3 param_13 = n;\n    float3 param_14 = _7352 * (_7354 * _7349);\n    float3 param_15 = _7432;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float param_18 = roughness;\n    float param_19 = ndv;\n    float2 _7463 = fa_ltc_uv(param_18, param_19) * 64.0f;\n    float2 param_20 = _7463;\n    float2 param_21 = _7463 + float2(64.0f, 0.0f);\n    float4 _7473 = fa_atlas_fetch(param_21);\n    float4 param_22 = fa_atlas_fetch(param_20);\n    float param_23 = _7322;\n    float3 param_24 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_25 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_26 = fa_ltc_local(param_15, param_16, param_17);\n    float2 _7485 = fa_area_forms(param_22, param_23, param_24, param_25, param_26);\n    return (((diffuse_color * _7485.x) + (((f0 * _7473.x) + ((f90.xxx - f0) * _7473.y)) * _7485.y)) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875f * dot(_7327, _7327)) + _7422) / _7422) * window);\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _5408 = 1.0f / alpha;\n    return ((2.0f + _5408) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _5408)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat fa_layers_coat(FaLayers L, float3 l, float3 h, float vdh)\n{\n    float _5443 = max(dot(L.nc, l), 0.0f);\n    float _5449 = max(dot(L.nc, h), 0.0f);\n    float _5458 = ((_5449 * _5449) * (L.coat_a2 - 1.0f)) + 1.0f;\n    return (((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _5458) * _5458)) * (0.5f / max(lerp((2.0f * _5443) * L.coat_ndv, _5443 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _5443)) * _5443;\n}\n\nfloat3 fa_area_layers(FaLayers L, float3 base, int li, float3 n, float3 v, float3 l, float ndv, float window)\n{\n    float _7522;\n    if (L.sheen_on)\n    {\n        _7522 = L.sheen_scale;\n    }\n    else\n    {\n        _7522 = 1.0f;\n    }\n    float3 result = base * (L.keep * _7522);\n    float3 _7535 = normalize(l + v);\n    int param = li;\n    float3 _7546 = fa_light_rgb(param) * window;\n    if (L.sheen_on)\n    {\n        float _7555 = max(dot(n, l), 0.0f);\n        float param_1 = L.sheen_alpha;\n        float param_2 = max(dot(n, _7535), 0.0f);\n        float param_3 = _7555;\n        float param_4 = ndv;\n        result += ((L.sheen * _7546) * (((((fa_d_charlie(param_1, param_2) * fa_v_ashikhmin(param_3, param_4)) * 3.1415927410125732421875f) * step(9.9999997473787516355514526367188e-05f, _7555)) * _7555) * L.keep));\n    }\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_5 = L;\n        float3 param_6 = l;\n        float3 param_7 = _7535;\n        float param_8 = max(dot(v, _7535), 0.0f);\n        result += (_7546 * fa_layers_coat(param_5, param_6, param_7, param_8));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _5311 = tdh / at;\n    float _5315 = bdh / ab;\n    float _5327 = ((_5311 * _5311) + (_5315 * _5315)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _5327) * _5327);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5507 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5586 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _5586) * _5586);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _5507);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _5507));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_17 = L;\n        float3 param_18 = l;\n        float3 param_19 = h;\n        float param_20 = vdh;\n        result += fa_layers_coat(param_17, param_18, param_19, param_20).xxx;\n    }\n    return result;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _4710 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _4713 = _4710.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_4713 * _4713, exp2((-9.27999973297119140625f) * ndv)) * _4713) + _4710.y)) + _4710.zw;\n}\n\nfloat3 fa_probe_level(float2 origin, float res, int lv, float2 e)\n{\n    float _4020;\n    if (lv == 0)\n    {\n        _4020 = 0.0f;\n    }\n    else\n    {\n        _4020 = res + 2.0f;\n    }\n    float _4030;\n    if (lv == 0)\n    {\n        _4030 = 0.0f;\n    }\n    else\n    {\n        _4030 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0f * float(lv - 1));\n    }\n    return fa_probe_atlas.SampleLevel(fa_env_smp, (((origin + float2(_4020, _4030)) + 1.0f.xx) + (((e * 0.5f) + 0.5f.xx) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0f).xyz;\n}\n\nfloat3 fa_probe_radiance(float2 origin, float res, float3 d, float rough)\n{\n    float _4076;\n    if (res > 64.5f)\n    {\n        _4076 = 5.0f;\n    }\n    else\n    {\n        _4076 = (res > 32.5f) ? 4.0f : 3.0f;\n    }\n    float _4091 = clamp(rough, 0.0f, 1.0f) * (_4076 - 1.0f);\n    int _4098 = int(min(floor(_4091), _4076 - 2.0f));\n    float _4103 = _4091 - float(_4098);\n    float3 param = d;\n    float2 _4107 = fa_oct_encode(param);\n    float2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _4098;\n    float2 param_4 = _4107;\n    float3 _4117 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_4103 < 0.00200000009499490261077880859375f)\n    {\n        return _4117;\n    }\n    float2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _4098 + 1;\n    float2 param_8 = _4107;\n    return lerp(_4117, fa_probe_level(param_5, param_6, param_7, param_8), _4103.xxx);\n}\n\nfloat3 fa_probe_box_dir(float3 d, float4 posw, float4 bx, float4 by, float4 bz)\n{\n    if (posw.w < 0.5f)\n    {\n        return d;\n    }\n    float _4188 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _4195 = dot(by.xyz, fa_world_pos) + by.w;\n    float _4202 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _4208 = dot(bx.xyz, d);\n    float _4212 = dot(by.xyz, d);\n    float _4216 = dot(bz.xyz, d);\n    float _4222;\n    if (_4208 > 9.9999999747524270787835121154785e-07f)\n    {\n        _4222 = (1.0f - _4188) / _4208;\n    }\n    else\n    {\n        float _4236;\n        if (_4208 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _4236 = ((-1.0f) - _4188) / _4208;\n        }\n        else\n        {\n            _4236 = 1000000015047466219876688855040.0f;\n        }\n        _4222 = _4236;\n    }\n    float tx = _4222;\n    float _4253;\n    if (_4212 > 9.9999999747524270787835121154785e-07f)\n    {\n        _4253 = (1.0f - _4195) / _4212;\n    }\n    else\n    {\n        float _4266;\n        if (_4212 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _4266 = ((-1.0f) - _4195) / _4212;\n        }\n        else\n        {\n            _4266 = 1000000015047466219876688855040.0f;\n        }\n        _4253 = _4266;\n    }\n    float ty = _4253;\n    float _4282;\n    if (_4216 > 9.9999999747524270787835121154785e-07f)\n    {\n        _4282 = (1.0f - _4202) / _4216;\n    }\n    else\n    {\n        float _4295;\n        if (_4216 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _4295 = ((-1.0f) - _4202) / _4216;\n        }\n        else\n        {\n            _4295 = 1000000015047466219876688855040.0f;\n        }\n        _4282 = _4295;\n    }\n    float _4307 = tx;\n    float _4310 = (_4307 > 0.0f) ? _4307 : 1000000015047466219876688855040.0f;\n    tx = _4310;\n    float _4311 = ty;\n    float _4314 = (_4311 > 0.0f) ? _4311 : 1000000015047466219876688855040.0f;\n    ty = _4314;\n    float _4324 = min(_4310, min(_4314, (_4282 > 0.0f) ? _4282 : 1000000015047466219876688855040.0f));\n    if (_4324 > 100000001504746621987668885504.0f)\n    {\n        return d;\n    }\n    float3 _4340 = (fa_world_pos + (d * _4324)) - posw.xyz;\n    float3 _4345;\n    if (dot(_4340, _4340) > 1.0000000133514319600180897396058e-10f)\n    {\n        _4345 = normalize(_4340);\n    }\n    else\n    {\n        _4345 = d;\n    }\n    return _4345;\n}\n\nfloat3 fa_probe_environment(float4 tile, float4 posw, float4 bx, float4 by, float4 bz, inout float3 d, float rough)\n{\n    float3 param = d;\n    float4 param_1 = posw;\n    float4 param_2 = bx;\n    float4 param_3 = by;\n    float4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    float2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    float3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _4391 = (1.0f - _609_fa_rpa_tile.w) - _609_fa_rpb_tile.w;\n    float3 outc = 0.0f.xxx;\n    if (_4391 > 0.0005000000237487256526947021484375f)\n    {\n        float3 base;\n        if (_609_fa_env_sky.w > 0.5f)\n        {\n            float2 param = _609_fa_atlas.zw;\n            float param_1 = 128.0f;\n            float3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _4419 = rough * rough;\n            float _4450 = 0.60000002384185791015625f * _4419;\n            base = lerp(lerp(_609_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_609_fa_env_horizon.xyz, _609_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _4419)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _4450, 0.0500000007450580596923828125f + _4450, d.y).xxx), ((_609_fa_env_sky.xyz + _609_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_4419 * 0.60000002384185791015625f).xxx);\n        }\n        outc = base * _4391;\n    }\n    if (_609_fa_rpa_tile.w > 0.0f)\n    {\n        float4 param_4 = _609_fa_rpa_tile;\n        float4 param_5 = _609_fa_rpa_pos;\n        float4 param_6 = _609_fa_rpa_bx;\n        float4 param_7 = _609_fa_rpa_by;\n        float4 param_8 = _609_fa_rpa_bz;\n        float3 param_9 = d;\n        float param_10 = rough;\n        float3 _4509 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4509 * _609_fa_rpa_tile.w);\n    }\n    if (_609_fa_rpb_tile.w > 0.0f)\n    {\n        float4 param_11 = _609_fa_rpb_tile;\n        float4 param_12 = _609_fa_rpb_pos;\n        float4 param_13 = _609_fa_rpb_bx;\n        float4 param_14 = _609_fa_rpb_by;\n        float4 param_15 = _609_fa_rpb_bz;\n        float3 param_16 = d;\n        float param_17 = rough;\n        float3 _4541 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4541 * _609_fa_rpb_tile.w);\n    }\n    return outc;\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness, float occlusion)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _5188;\n        if (L.aniso >= 0.0f)\n        {\n            _5188 = L.b;\n        }\n        else\n        {\n            _5188 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_5188, v), _5188), (abs(L.aniso) * smoothstep(0.0f, 0.25f, roughness)).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _5224 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _5224.x) + (L.f90.xxx * _5224.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _5282 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _5282.x) + _5282.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4752 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4752.x) + _4752.y.xxx);\n}\n\nfloat2 fa_xm_size(int k)\n{\n    return max(floor(_609_fa_ct_a.zw / float(1 << k).xx), 1.0f.xx);\n}\n\nfloat2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return 0.0f.xx;\n    }\n    float y = 0.0f;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return float2(_609_fa_ct_a.z, y);\n}\n\nfloat3 fa_xm_texel(float2 size, float2 origin, float2 p)\n{\n    return fa_screen_tex.Load(int3(int2(origin + clamp(p, 0.0f.xx, size - 1.0f.xx)), 0)).xyz;\n}\n\nfloat3 fa_xm_level(int k, float2 uv)\n{\n    int param = k;\n    float2 _5984 = fa_xm_size(param);\n    int param_1 = k;\n    float2 _5988 = fa_xm_origin(param_1);\n    float2 _5994 = (uv * _5984) - 0.5f.xx;\n    float2 _5997 = frac(_5994);\n    float2 _6000 = floor(_5994);\n    float2 param_2 = _5984;\n    float2 param_3 = _5988;\n    float2 param_4 = _6000;\n    float2 param_5 = _5984;\n    float2 param_6 = _5988;\n    float2 param_7 = _6000 + float2(1.0f, 0.0f);\n    float2 param_8 = _5984;\n    float2 param_9 = _5988;\n    float2 param_10 = _6000 + float2(0.0f, 1.0f);\n    float2 param_11 = _5984;\n    float2 param_12 = _5988;\n    float2 param_13 = _6000 + 1.0f.xx;\n    float3 _6042 = _5997.x.xxx;\n    return lerp(lerp(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _6042), lerp(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _6042), _5997.y.xxx);\n}\n\nfloat3 fa_xm_sample(float2 uv, float lod)\n{\n    float _6061 = max(_609_fa_tr_b.w - 1.0f, 0.0f);\n    float _6065 = clamp(lod, 0.0f, _6061);\n    int _6069 = int(floor(_6065));\n    int param = _6069;\n    float2 param_1 = uv;\n    float3 c = fa_xm_level(param, param_1);\n    float _6079 = float(_6069);\n    float _6080 = _6065 - _6079;\n    bool _6082 = _6080 > 0.001000000047497451305389404296875f;\n    bool _6089;\n    if (_6082)\n    {\n        _6089 = _6079 < _6061;\n    }\n    else\n    {\n        _6089 = _6082;\n    }\n    if (_6089)\n    {\n        int param_2 = _6069 + 1;\n        float2 param_3 = uv;\n        c = lerp(c, fa_xm_level(param_2, param_3), _6080.xxx);\n    }\n    return c;\n}\n\nfloat3 fa_transmitted(Surface s, float3 n, float3 v, float roughness, float3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _6115 = fa_env_brdf(param, param_1);\n    float3 _6139 = ((1.0f.xxx - clamp((f0 * _6115.x) + (f90.xxx * _6115.y), 0.0f.xxx, 1.0f.xxx)) * s.albedo) * (tr * keep);\n    float3 through = _6139;\n    float _6145 = max(s.thickness, 0.0f);\n    bool _6150 = _6145 > 0.0f;\n    if ((s.attenuation_distance > 0.0f) && _6150)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, 9.9999997473787516355514526367188e-05f.xxx, 1.0f.xxx))) / s.attenuation_distance.xxx)) * _6145);\n    }\n    bool _6175 = _609_fa_tr_a.w > 1.5f;\n    bool _6181;\n    if (_6175)\n    {\n        _6181 = _609_fa_tr_a.w < 2.5f;\n    }\n    else\n    {\n        _6181 = _6175;\n    }\n    bool _6188;\n    if (!_6181)\n    {\n        _6188 = _609_fa_tr_a.w < 0.5f;\n    }\n    else\n    {\n        _6188 = _6181;\n    }\n    if (_6188)\n    {\n        blend = clamp(dot(through, 0.3333333432674407958984375f.xxx), 0.0f, 0.980000019073486328125f);\n        return 0.0f.xxx;\n    }\n    float4 _6203 = float4(fa_world_pos, 1.0f);\n    float _6208 = dot(_609_fa_ct_vpw, _6203);\n    float2 uv0 = 0.5f.xx;\n    if (_6208 > 9.9999997473787516355514526367188e-05f)\n    {\n        float2 _6226 = float2(dot(_609_fa_ct_vpx, _6203), dot(_609_fa_ct_vpy, _6203)) / _6208.xx;\n        float _6234;\n        if (_609_fa_ct_a.y > 0.5f)\n        {\n            _6234 = (_6226.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _6234 = 0.5f - (_6226.y * 0.5f);\n        }\n        uv0 = float2((_6226.x * 0.5f) + 0.5f, _6234);\n    }\n    if (_609_fa_tr_a.w > 2.5f)\n    {\n        int param_2 = 0;\n        float2 _6255 = fa_xm_size(param_2);\n        float2 _6263 = floor(clamp(uv0, 0.0f.xx, 0.99989998340606689453125f.xx) * _6255);\n        if (fa_screen_tex.Load(int3(int2(_6263), 0)).w > 0.5f)\n        {\n            int _6283 = int(floor((clamp(roughness, 0.0f, 1.0f) * 2.0f) + 0.5f));\n            float3 acc = 0.0f.xxx;\n            float cnt = 0.0f;\n            for (int dy = -2; dy <= 2; dy++)\n            {\n                for (int dx = -2; dx <= 2; dx++)\n                {\n                    bool _6306 = abs(dx) > _6283;\n                    bool _6314;\n                    if (!_6306)\n                    {\n                        _6314 = abs(dy) > _6283;\n                    }\n                    else\n                    {\n                        _6314 = _6306;\n                    }\n                    if (_6314)\n                    {\n                        continue;\n                    }\n                    float4 _6335 = fa_screen_tex.Load(int3(int2(clamp(_6263 + float2(float(dx), float(dy)), 0.0f.xx, _6255 - 1.0f.xx)), 0));\n                    if (_6335.w > 0.5f)\n                    {\n                        acc += _6335.xyz;\n                        cnt += 1.0f;\n                    }\n                }\n            }\n            return _6139 * (acc / max(cnt, 1.0f).xxx);\n        }\n    }\n    float2 uv = uv0;\n    if (_6150)\n    {\n        float4 _6383 = float4(fa_world_pos + (refract(-v, n, 1.0f / max(s.ior, 1.0f)) * _6145), 1.0f);\n        float _6388 = dot(_609_fa_ct_vpw, _6383);\n        uv = 0.5f.xx;\n        if (_6388 > 9.9999997473787516355514526367188e-05f)\n        {\n            float2 _6405 = float2(dot(_609_fa_ct_vpx, _6383), dot(_609_fa_ct_vpy, _6383)) / _6388.xx;\n            float _6413;\n            if (_609_fa_ct_a.y > 0.5f)\n            {\n                _6413 = (_6405.y * 0.5f) + 0.5f;\n            }\n            else\n            {\n                _6413 = 0.5f - (_6405.y * 0.5f);\n            }\n            uv = float2((_6405.x * 0.5f) + 0.5f, _6413);\n        }\n    }\n    float2 param_3 = clamp(uv, 0.0f.xx, 1.0f.xx);\n    float param_4 = (clamp(roughness, 0.0f, 1.0f) * clamp((2.0f * s.ior) - 2.0f, 0.0f, 1.0f)) * max(_609_fa_tr_b.w - 1.0f, 0.0f);\n    return through * fa_xm_sample(param_3, param_4);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2353_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3312 = int(_2353_fa_shadow_cfg.x + 0.5f);\n    float _3322 = dot(world - _2353_fa_shadow_eye.xyz, _2353_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3327 = _3312 > 0;\n    bool _3336;\n    if (_3327)\n    {\n        int param = _3312 - 1;\n        _3336 = _3322 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3336 = _3327;\n    }\n    if (_3336)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3342 = _3312 > 1;\n        bool _3349;\n        if (_3342)\n        {\n            _3349 = _3322 > _2353_fa_shadow_split.x;\n        }\n        else\n        {\n            _3349 = _3342;\n        }\n        if (_3349)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3355 = _3312 > 2;\n        bool _3362;\n        if (_3355)\n        {\n            _3362 = _3322 > _2353_fa_shadow_split.y;\n        }\n        else\n        {\n            _3362 = _3355;\n        }\n        if (_3362)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3368 = _3312 > 3;\n        bool _3375;\n        if (_3368)\n        {\n            _3375 = _3322 > _2353_fa_shadow_split.z;\n        }\n        else\n        {\n            _3375 = _3368;\n        }\n        if (_3375)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _9468 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _9468 = -_9468;\n    }\n    float3 _8754 = normalize(_609_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _9481 = { fa_world_pos, _9468, fa_world_tangent, fa_uv, fa_vertex_color, _8754, gl_FrontFacing };\n    SurfaceInput param_1 = _9481;\n    Surface _8762 = fa_standard_surface(param_1);\n    float3 _9499 = _8762.albedo;\n    float _9500 = _8762.alpha;\n    float3 _9501 = _8762.normal;\n    float _9502 = _8762.metallic;\n    float _9503 = _8762.roughness;\n    float _9504 = _8762.occlusion;\n    float3 _9505 = _8762.emission;\n    float _9506 = _8762.clearcoat;\n    float _9507 = _8762.clearcoat_roughness;\n    float3 _9508 = _8762.sheen_color;\n    float _9509 = _8762.sheen_roughness;\n    float _9510 = _8762.anisotropy;\n    float _9511 = _8762.anisotropy_rotation;\n    float _9512 = _8762.specular;\n    float _9513 = _8762.ior;\n    float3 _9514 = _8762.specular_color;\n    float _9515 = _8762.transmission;\n    float _9516 = _8762.thickness;\n    float3 _9517 = _8762.attenuation_color;\n    float _9518 = _8762.attenuation_distance;\n    SurfaceInput _9489 = { fa_world_pos, _9468, fa_world_tangent, fa_uv, fa_vertex_color, _8754, gl_FrontFacing };\n    SurfaceInput param_2 = _9489;\n    Surface param_3 = _8762;\n    surface(param_2, param_3);\n    _9499 = param_3.albedo;\n    _9500 = param_3.alpha;\n    _9501 = param_3.normal;\n    _9502 = param_3.metallic;\n    _9503 = param_3.roughness;\n    _9504 = param_3.occlusion;\n    _9505 = param_3.emission;\n    _9506 = param_3.clearcoat;\n    _9507 = param_3.clearcoat_roughness;\n    _9508 = param_3.sheen_color;\n    _9509 = param_3.sheen_roughness;\n    _9510 = param_3.anisotropy;\n    _9511 = param_3.anisotropy_rotation;\n    _9512 = param_3.specular;\n    _9513 = param_3.ior;\n    _9514 = param_3.specular_color;\n    _9515 = param_3.transmission;\n    _9516 = param_3.thickness;\n    _9517 = param_3.attenuation_color;\n    _9518 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _9468;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _9499 = param_6;\n    _9501 = param_7;\n    if (_9500 < _8790_alphaCutoff)\n    {\n        discard;\n    }\n    fa_lod_dither();\n    float fa_tr_blend = 0.0f;\n    float3 result;\n    if (_609_fa_emissive.w > 0.5f)\n    {\n        result = _9499;\n    }\n    else\n    {\n        float3 _8814 = normalize(_9501);\n        float _8821 = clamp(_9502, 0.0f, 1.0f);\n        float _8825 = clamp(_9503, 0.0500000007450580596923828125f, 1.0f);\n        float _8829 = _8825 * _8825;\n        float _8833 = _8829 * _8829;\n        float _8838 = max(dot(_8814, _8754), 9.9999997473787516355514526367188e-05f);\n        float _8844 = 1.0f - _8821;\n        float _8845 = clamp(_9515, 0.0f, 1.0f) * _8844;\n        float3 _8854 = (_9499 * _8844) * (1.0f - _8845);\n        float3 _8861 = lerp(0.039999999105930328369140625f.xxx, _9499, _8821.xxx);\n        float3 f0 = _8861;\n        SurfaceInput _9497 = { fa_world_pos, _9468, fa_world_tangent, fa_uv, fa_vertex_color, _8754, gl_FrontFacing };\n        SurfaceInput param_8 = _9497;\n        Surface _9600 = { _9499, _9500, _9501, _9502, _9503, _9504, _9505, _9506, _9507, _9508, _9509, _9510, _9511, _9512, _9513, _9514, _9515, _9516, _9517, _9518 };\n        Surface param_9 = _9600;\n        float3 param_10 = _8814;\n        float3 param_11 = _8754;\n        float param_12 = _8821;\n        float param_13 = _8825;\n        float3 param_14 = _8861;\n        FaLayers _8877 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _8814;\n        float3 lit = (fa_indirect_diffuse(param_15) * _8854) * _9504;\n        if (_8877.on)\n        {\n            lit *= _8877.base_scale;\n        }\n        int _8899 = fa_cl_ndir + fa_cl_local;\n        float _8964;\n        for (int ln = 0; ln < _8899; ln++)\n        {\n            int param_16 = ln;\n            int _8912 = fa_cl_light(param_16);\n            int param_17 = _8912;\n            if (fa_baked_keep(param_17) <= 0.0f)\n            {\n                continue;\n            }\n            int param_18 = _8912;\n            float3 param_19 = fa_world_pos;\n            float3 param_20 = _9468;\n            LightSample _8928 = fa_light_shadowed(param_18, param_19, param_20);\n            float _8936 = max(dot(_8814, _8928.direction), 0.0f);\n            float _8942 = _8928.attenuation * _8928.shadow;\n            float3 _8947 = normalize(_8928.direction + _8754);\n            float _8952 = max(dot(_8814, _8947), 0.0f);\n            float _8957 = max(dot(_8754, _8947), 0.0f);\n            if (fa_light_is_area)\n            {\n                if (_8877.on)\n                {\n                    _8964 = _8877.f90;\n                }\n                else\n                {\n                    _8964 = 1.0f;\n                }\n                int param_21 = _8912;\n                float3 param_22 = fa_world_pos;\n                float3 param_23 = _8814;\n                float3 param_24 = _8754;\n                float3 param_25 = _8854;\n                float3 param_26 = f0;\n                float param_27 = _8964;\n                float param_28 = _8825;\n                float param_29 = _8838;\n                float param_30 = _8942;\n                float3 area = fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n                if (_8877.on)\n                {\n                    FaLayers param_31 = _8877;\n                    float3 param_32 = area;\n                    int param_33 = _8912;\n                    float3 param_34 = _8814;\n                    float3 param_35 = _8754;\n                    float3 param_36 = _8928.direction;\n                    float param_37 = _8838;\n                    float param_38 = _8942;\n                    area = fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38);\n                }\n                lit += area;\n            }\n            else\n            {\n                if (_8877.on)\n                {\n                    FaLayers param_39 = _8877;\n                    float3 param_40 = _8854;\n                    float3 param_41 = f0;\n                    float3 param_42 = _8814;\n                    float3 param_43 = _8754;\n                    float3 param_44 = _8928.direction;\n                    float3 param_45 = _8947;\n                    float param_46 = _8936;\n                    float param_47 = _8838;\n                    float param_48 = _8952;\n                    float param_49 = _8957;\n                    float param_50 = _8829;\n                    float param_51 = _8833;\n                    int param_52 = _8912;\n                    lit += (fa_layers_light(param_39, param_40, param_41, param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51) * ((fa_light_rgb(param_52) * fa_light_tint) * _8942));\n                }\n                else\n                {\n                    float _9066 = ((_8952 * _8952) * (_8833 - 1.0f)) + 1.0f;\n                    int param_53 = _8912;\n                    lit += (((_8854 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _8957, 5.0f))) * (((_8833 / ((3.1415927410125732421875f * _9066) * _9066)) * (0.5f / max(lerp((2.0f * _8936) * _8838, _8936 + _8838, _8829), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _8936))) * (fa_light_rgb(param_53) * fa_light_tint)) * (_8936 * _8942));\n                }\n            }\n        }\n        if (_8877.on)\n        {\n            FaLayers param_54 = _8877;\n            float3 param_55 = _8814;\n            float3 param_56 = _8754;\n            float3 param_57 = f0;\n            float param_58 = _8825;\n            float param_59 = _9504;\n            lit += fa_layers_ibl(param_54, param_55, param_56, param_57, param_58, param_59);\n        }\n        else\n        {\n            float3 param_60 = _8814;\n            float3 param_61 = _8754;\n            float3 param_62 = f0;\n            float param_63 = _8825;\n            lit += (fa_sky_reflection(param_60, param_61, param_62, param_63) * _9504);\n        }\n        if (_8845 > 0.0f)\n        {\n            float _9164;\n            if (_8877.on)\n            {\n                _9164 = _8877.f90;\n            }\n            else\n            {\n                _9164 = 1.0f;\n            }\n            float _9172;\n            if (_8877.on)\n            {\n                _9172 = _8877.base_scale;\n            }\n            else\n            {\n                _9172 = 1.0f;\n            }\n            Surface _9621 = { _9499, _9500, _9501, _9502, _9503, _9504, _9505, _9506, _9507, _9508, _9509, _9510, _9511, _9512, _9513, _9514, _9515, _9516, _9517, _9518 };\n            Surface param_64 = _9621;\n            float3 param_65 = _8814;\n            float3 param_66 = _8754;\n            float param_67 = _8825;\n            float3 param_68 = f0;\n            float param_69 = _9164;\n            float param_70 = _9172;\n            float param_71 = _8845;\n            float param_72 = fa_tr_blend;\n            float3 _9196 = fa_transmitted(param_64, param_65, param_66, param_67, param_68, param_69, param_70, param_71, param_72);\n            fa_tr_blend = param_72;\n            lit += _9196;\n        }\n        result = lit;\n    }\n    float3 _9203 = result;\n    float3 _9204 = _9203 + _9505;\n    result = _9204;\n    float3 param_73 = _9204;\n    float3 param_74 = fa_world_pos;\n    result = fa_shadow_debug(param_73, param_74);\n    bool _9213 = _609_fa_fog.w > 0.0f;\n    bool _9220;\n    if (!_9213)\n    {\n        _9220 = _609_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _9220 = _9213;\n    }\n    if (_9220)\n    {\n        float3 _9229 = fa_world_pos - _609_fa_camera_pos.xyz;\n        float _9235 = dot(_9229, _609_fa_fog_c.xyz);\n        bool _9239 = _609_fa_fog_c.w > 0.5f;\n        float _9240;\n        if (_9239)\n        {\n            _9240 = _9235;\n        }\n        else\n        {\n            _9240 = length(_9229);\n        }\n        float _9252 = _9240 - _609_fa_fog_b.x;\n        if (_9252 > 0.0f)\n        {\n            float _9261 = _609_fa_fog.w * _9252;\n            float tau = _9261 * _9261;\n            if (_609_fa_fog_b.y > 0.0f)\n            {\n                float _9277;\n                if (_9239)\n                {\n                    _9277 = fa_world_pos.y - (_609_fa_fog_c.y * _9235);\n                }\n                else\n                {\n                    _9277 = _609_fa_camera_pos.y;\n                }\n                float _9298 = lerp(_9277, fa_world_pos.y, clamp(_609_fa_fog_b.x / _9240, 0.0f, 1.0f));\n                float _9302 = fa_world_pos.y - _9298;\n                float _9307 = _9298 - _609_fa_fog_b.z;\n                float _9312 = fa_world_pos.y - _609_fa_fog_b.z;\n                bool _9315 = _9307 <= 0.0f;\n                bool _9316 = !_9315;\n                bool _9322;\n                if (_9316)\n                {\n                    _9322 = _609_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _9322 = _9315;\n                }\n                float _9323;\n                if (_9322)\n                {\n                    _9323 = _609_fa_fog_b.y;\n                }\n                else\n                {\n                    _9323 = _609_fa_fog_b.y * exp(-min(_609_fa_fog_b.w * _9307, 80.0f));\n                }\n                bool _9350;\n                if (_9316)\n                {\n                    _9350 = _609_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _9350 = _9315;\n                }\n                float _9351;\n                if (_9350)\n                {\n                    _9351 = _609_fa_fog_b.y * _9307;\n                }\n                else\n                {\n                    _9351 = (_609_fa_fog_b.y * (1.0f - exp(-min(_609_fa_fog_b.w * _9307, 80.0f)))) / _609_fa_fog_b.w;\n                }\n                bool _9376 = _9312 <= 0.0f;\n                bool _9383;\n                if (!_9376)\n                {\n                    _9383 = _609_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _9383 = _9376;\n                }\n                float _9384;\n                if (_9383)\n                {\n                    _9384 = _609_fa_fog_b.y * _9312;\n                }\n                else\n                {\n                    _9384 = (_609_fa_fog_b.y * (1.0f - exp(-min(_609_fa_fog_b.w * _9312, 80.0f)))) / _609_fa_fog_b.w;\n                }\n                float _9411;\n                if (abs(_9302) < 0.001000000047497451305389404296875f)\n                {\n                    _9411 = _9323;\n                }\n                else\n                {\n                    _9411 = (_9384 - _9351) / _9302;\n                }\n                tau += (_9252 * max(_9411, 0.0f));\n            }\n            result = lerp(result, _609_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    if (fa_tr_blend > 0.0f)\n    {\n        float _9447 = 1.0f - fa_tr_blend;\n        result /= _9447.xxx;\n        _9500 *= _9447;\n    }\n    fa_frag_color = float4(result, _9500);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_609",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2353",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_8790",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _129_fa_camera_pos : packoffset(c0);\n    float4 _129_fa_ambient : packoffset(c1);\n    float4 _129_fa_base_color : packoffset(c2);\n    float4 _129_fa_emissive : packoffset(c3);\n    float4 _129_fa_model_emissive : packoffset(c4);\n    float4 _129_fa_pbr : packoffset(c5);\n    float4 _129_fa_maps : packoffset(c6);\n    float4 _129_fa_fog : packoffset(c7);\n    float4 _129_fa_fog_b : packoffset(c8);\n    float4 _129_fa_fog_c : packoffset(c9);\n    float4 _129_fa_counts : packoffset(c10);\n    float4 _129_fa_env_sky : packoffset(c11);\n    float4 _129_fa_env_horizon : packoffset(c12);\n    float4 _129_fa_time : packoffset(c13);\n    float4 _129_fa_cl_vpx : packoffset(c14);\n    float4 _129_fa_cl_vpy : packoffset(c15);\n    float4 _129_fa_cl_vpw : packoffset(c16);\n    float4 _129_fa_cl_fwd : packoffset(c17);\n    float4 _129_fa_cl_grid : packoffset(c18);\n    float4 _129_fa_cl_info : packoffset(c19);\n    float4 _129_fa_layers_a : packoffset(c20);\n    float4 _129_fa_layers_b : packoffset(c21);\n    float4 _129_fa_layers_c : packoffset(c22);\n    float4 _129_fa_layers_d : packoffset(c23);\n    float4 _129_fa_ct_a : packoffset(c24);\n    float4 _129_fa_ct_b : packoffset(c25);\n    float4 _129_fa_ct_vpx : packoffset(c26);\n    float4 _129_fa_ct_vpy : packoffset(c27);\n    float4 _129_fa_ct_vpw : packoffset(c28);\n    float4 _129_fa_ct_fwd : packoffset(c29);\n    float4 _129_fa_tr_a : packoffset(c30);\n    float4 _129_fa_tr_b : packoffset(c31);\n    float4 _129_fa_probe_sh[9] : packoffset(c32);\n    float4 _129_fa_atlas : packoffset(c41);\n    float4 _129_fa_rpa_tile : packoffset(c42);\n    float4 _129_fa_rpa_pos : packoffset(c43);\n    float4 _129_fa_rpa_bx : packoffset(c44);\n    float4 _129_fa_rpa_by : packoffset(c45);\n    float4 _129_fa_rpa_bz : packoffset(c46);\n    float4 _129_fa_rpb_tile : packoffset(c47);\n    float4 _129_fa_rpb_pos : packoffset(c48);\n    float4 _129_fa_rpb_bx : packoffset(c49);\n    float4 _129_fa_rpb_by : packoffset(c50);\n    float4 _129_fa_rpb_bz : packoffset(c51);\n    float4 _129_fa_gi : packoffset(c52);\n    float4 _129_fa_gi_px : packoffset(c53);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _616_alphaCutoff : packoffset(c0);\n    float _616_fa_pad0 : packoffset(c0.y);\n    float _616_fa_pad1 : packoffset(c0.z);\n    float _616_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> mask : register(t5);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\nstatic float3 fa_vel_cur;\nstatic float3 fa_vel_prev;\nstatic float2 fa_frag_velocity;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float3 fa_vel_cur : TEXCOORD9;\n    float3 fa_vel_prev : TEXCOORD10;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n    float2 fa_frag_velocity : SV_Target1;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _237 = fa_linear_to_srgb(param);\n        c = _237;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _246 = fa_srgb_to_linear(param_1);\n            c = _246;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _58;\n    if (i.front_facing)\n    {\n        _58 = i.world_normal;\n    }\n    else\n    {\n        _58 = -i.world_normal;\n    }\n    float3 _83 = normalize(i.world_tangent.xyz - (_58 * dot(_58, i.world_tangent.xyz)));\n    float3 _111 = normalize(((_83 * m.x) + ((cross(_58, _83) * i.world_tangent.w) * m.y)) + (_58 * m.z));\n    float3 _114;\n    if (i.front_facing)\n    {\n        _114 = _111;\n    }\n    else\n    {\n        _114 = -_111;\n    }\n    return _114;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _129_fa_env_horizon.w);\n    float param = _129_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _282 = fa_tex_fix(param_2, param_3);\n    float4 _901 = base_t;\n    _901.x = _282.x;\n    _901.y = _282.y;\n    _901.z = _282.z;\n    base_t = _901;\n    float4 _298 = (_901 * _129_fa_base_color) * i.vertex_color;\n    float3 _856 = i.world_normal;\n    if (_129_fa_maps.z > 0.5f)\n    {\n        float param_4 = _129_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _129_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _334 = fa_tex_fix(param_6, param_7);\n        float3 _337 = (_334 * 2.0f) - 1.0f.xxx;\n        float2 _342 = _337.xy * _129_fa_maps.x;\n        float3 _909 = _337;\n        _909.x = _342.x;\n        _909.y = _342.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _909;\n        _856 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _129_fa_env_horizon.w);\n    float param_10 = _129_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _373 = fa_tex_fix(param_12, param_13);\n    float4 _912 = mrt;\n    _912.x = _373.x;\n    _912.y = _373.y;\n    _912.z = _373.z;\n    mrt = _912;\n    float4 _405 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _129_fa_env_horizon.w);\n    float param_14 = _129_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _405.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _417 = fa_tex_fix(param_16, param_17);\n    float param_18 = _129_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _129_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _449 = fa_tex_fix(param_20, param_21);\n    float _861 = _129_fa_layers_a.x;\n    float _862 = _129_fa_layers_a.y;\n    float _865 = _129_fa_layers_a.z;\n    float _864 = _129_fa_layers_b.w;\n    float _867 = _129_fa_layers_c.x;\n    if (_129_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_129_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _861 *= _417.y;\n            _862 *= _417.z;\n            _864 *= _405.w;\n        }\n        if (_129_fa_layers_c.z > 1.5f)\n        {\n            _865 *= mrt.x;\n            _867 *= mrt.w;\n        }\n    }\n    Surface _894 = { _298.xyz, _298.w, _856, clamp(_129_fa_pbr.x * _373.z, 0.0f, 1.0f), clamp(_129_fa_pbr.y * _373.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_129_fa_maps.y * (_417.x - 1.0f)), _129_fa_emissive.xyz + (_129_fa_model_emissive.xyz * _449), _861, _862, _129_fa_layers_b.xyz, _864, _865, _129_fa_layers_a.w, _867, _129_fa_layers_c.y, _129_fa_layers_d.xyz, _129_fa_tr_a.x, _129_fa_tr_a.y, _129_fa_tr_b.xyz, _129_fa_tr_a.z };\n    return _894;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nvoid fa_lod_dither()\n{\n    if (_129_fa_gi.w != 0.0f)\n    {\n        float _151 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n        bool _154;\n        if (_129_fa_gi.w > 0.0f)\n        {\n            _154 = _151 >= _129_fa_gi.w;\n        }\n        else\n        {\n            _154 = _151 < (-_129_fa_gi.w);\n        }\n        if (_154)\n        {\n            discard;\n        }\n    }\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _751 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _751 = -_751;\n    }\n    float3 _600 = normalize(_129_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _764 = { fa_world_pos, _751, fa_world_tangent, fa_uv, fa_vertex_color, _600, gl_FrontFacing };\n    SurfaceInput param = _764;\n    Surface _605 = fa_standard_surface(param);\n    float3 _775 = _605.normal;\n    SurfaceInput _772 = { fa_world_pos, _751, fa_world_tangent, fa_uv, fa_vertex_color, _600, gl_FrontFacing };\n    SurfaceInput param_1 = _772;\n    Surface param_2 = _605;\n    surface(param_1, param_2);\n    _775 = param_2.normal;\n    if (param_2.alpha < _616_alphaCutoff)\n    {\n        discard;\n    }\n    fa_lod_dither();\n    float3 _627 = normalize(_775);\n    float3 _642 = normalize(float3(dot(fa_pre_r0, _627), dot(fa_pre_r1, _627), dot(fa_pre_r2, _627)));\n    float _654 = _642.z;\n    float2 e = _642.xy / ((abs(_642.x) + abs(_642.y)) + abs(_654)).xx;\n    if (_654 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n    float2 motion = 1024.0f.xx;\n    bool _698 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06f;\n    bool _705;\n    if (_698)\n    {\n        _705 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06f;\n    }\n    else\n    {\n        _705 = _698;\n    }\n    if (_705)\n    {\n        motion = clamp(((float2(fa_vel_prev.x, -fa_vel_prev.y) / fa_vel_prev.z.xx) * 0.5f) - ((float2(fa_vel_cur.x, -fa_vel_cur.y) / fa_vel_cur.z.xx) * 0.5f), (-4.0f).xx, 4.0f.xx);\n    }\n    fa_frag_velocity = motion;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    fa_vel_cur = stage_input.fa_vel_cur;\n    fa_vel_prev = stage_input.fa_vel_prev;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    stage_output.fa_frag_velocity = fa_frag_velocity;\n    return stage_output;\n}\n",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _129_fa_camera_pos : packoffset(c0);\n    float4 _129_fa_ambient : packoffset(c1);\n    float4 _129_fa_base_color : packoffset(c2);\n    float4 _129_fa_emissive : packoffset(c3);\n    float4 _129_fa_model_emissive : packoffset(c4);\n    float4 _129_fa_pbr : packoffset(c5);\n    float4 _129_fa_maps : packoffset(c6);\n    float4 _129_fa_fog : packoffset(c7);\n    float4 _129_fa_fog_b : packoffset(c8);\n    float4 _129_fa_fog_c : packoffset(c9);\n    float4 _129_fa_counts : packoffset(c10);\n    float4 _129_fa_env_sky : packoffset(c11);\n    float4 _129_fa_env_horizon : packoffset(c12);\n    float4 _129_fa_time : packoffset(c13);\n    float4 _129_fa_cl_vpx : packoffset(c14);\n    float4 _129_fa_cl_vpy : packoffset(c15);\n    float4 _129_fa_cl_vpw : packoffset(c16);\n    float4 _129_fa_cl_fwd : packoffset(c17);\n    float4 _129_fa_cl_grid : packoffset(c18);\n    float4 _129_fa_cl_info : packoffset(c19);\n    float4 _129_fa_layers_a : packoffset(c20);\n    float4 _129_fa_layers_b : packoffset(c21);\n    float4 _129_fa_layers_c : packoffset(c22);\n    float4 _129_fa_layers_d : packoffset(c23);\n    float4 _129_fa_ct_a : packoffset(c24);\n    float4 _129_fa_ct_b : packoffset(c25);\n    float4 _129_fa_ct_vpx : packoffset(c26);\n    float4 _129_fa_ct_vpy : packoffset(c27);\n    float4 _129_fa_ct_vpw : packoffset(c28);\n    float4 _129_fa_ct_fwd : packoffset(c29);\n    float4 _129_fa_tr_a : packoffset(c30);\n    float4 _129_fa_tr_b : packoffset(c31);\n    float4 _129_fa_probe_sh[9] : packoffset(c32);\n    float4 _129_fa_atlas : packoffset(c41);\n    float4 _129_fa_rpa_tile : packoffset(c42);\n    float4 _129_fa_rpa_pos : packoffset(c43);\n    float4 _129_fa_rpa_bx : packoffset(c44);\n    float4 _129_fa_rpa_by : packoffset(c45);\n    float4 _129_fa_rpa_bz : packoffset(c46);\n    float4 _129_fa_rpb_tile : packoffset(c47);\n    float4 _129_fa_rpb_pos : packoffset(c48);\n    float4 _129_fa_rpb_bx : packoffset(c49);\n    float4 _129_fa_rpb_by : packoffset(c50);\n    float4 _129_fa_rpb_bz : packoffset(c51);\n    float4 _129_fa_gi : packoffset(c52);\n    float4 _129_fa_gi_px : packoffset(c53);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _616_alphaCutoff : packoffset(c0);\n    float _616_fa_pad0 : packoffset(c0.y);\n    float _616_fa_pad1 : packoffset(c0.z);\n    float _616_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> mask : register(t5);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\nstatic float3 fa_vel_cur;\nstatic float3 fa_vel_prev;\nstatic float2 fa_frag_velocity;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float3 fa_vel_cur : TEXCOORD9;\n    float3 fa_vel_prev : TEXCOORD10;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n    float2 fa_frag_velocity : SV_Target1;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _237 = fa_linear_to_srgb(param);\n        c = _237;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _246 = fa_srgb_to_linear(param_1);\n            c = _246;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _58;\n    if (i.front_facing)\n    {\n        _58 = i.world_normal;\n    }\n    else\n    {\n        _58 = -i.world_normal;\n    }\n    float3 _83 = normalize(i.world_tangent.xyz - (_58 * dot(_58, i.world_tangent.xyz)));\n    float3 _111 = normalize(((_83 * m.x) + ((cross(_58, _83) * i.world_tangent.w) * m.y)) + (_58 * m.z));\n    float3 _114;\n    if (i.front_facing)\n    {\n        _114 = _111;\n    }\n    else\n    {\n        _114 = -_111;\n    }\n    return _114;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _129_fa_env_horizon.w);\n    float param = _129_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _282 = fa_tex_fix(param_2, param_3);\n    float4 _901 = base_t;\n    _901.x = _282.x;\n    _901.y = _282.y;\n    _901.z = _282.z;\n    base_t = _901;\n    float4 _298 = (_901 * _129_fa_base_color) * i.vertex_color;\n    float3 _856 = i.world_normal;\n    if (_129_fa_maps.z > 0.5f)\n    {\n        float param_4 = _129_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _129_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _334 = fa_tex_fix(param_6, param_7);\n        float3 _337 = (_334 * 2.0f) - 1.0f.xxx;\n        float2 _342 = _337.xy * _129_fa_maps.x;\n        float3 _909 = _337;\n        _909.x = _342.x;\n        _909.y = _342.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _909;\n        _856 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _129_fa_env_horizon.w);\n    float param_10 = _129_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _373 = fa_tex_fix(param_12, param_13);\n    float4 _912 = mrt;\n    _912.x = _373.x;\n    _912.y = _373.y;\n    _912.z = _373.z;\n    mrt = _912;\n    float4 _405 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _129_fa_env_horizon.w);\n    float param_14 = _129_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _405.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _417 = fa_tex_fix(param_16, param_17);\n    float param_18 = _129_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _129_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _449 = fa_tex_fix(param_20, param_21);\n    float _861 = _129_fa_layers_a.x;\n    float _862 = _129_fa_layers_a.y;\n    float _865 = _129_fa_layers_a.z;\n    float _864 = _129_fa_layers_b.w;\n    float _867 = _129_fa_layers_c.x;\n    if (_129_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_129_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _861 *= _417.y;\n            _862 *= _417.z;\n            _864 *= _405.w;\n        }\n        if (_129_fa_layers_c.z > 1.5f)\n        {\n            _865 *= mrt.x;\n            _867 *= mrt.w;\n        }\n    }\n    Surface _894 = { _298.xyz, _298.w, _856, clamp(_129_fa_pbr.x * _373.z, 0.0f, 1.0f), clamp(_129_fa_pbr.y * _373.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_129_fa_maps.y * (_417.x - 1.0f)), _129_fa_emissive.xyz + (_129_fa_model_emissive.xyz * _449), _861, _862, _129_fa_layers_b.xyz, _864, _865, _129_fa_layers_a.w, _867, _129_fa_layers_c.y, _129_fa_layers_d.xyz, _129_fa_tr_a.x, _129_fa_tr_a.y, _129_fa_tr_b.xyz, _129_fa_tr_a.z };\n    return _894;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nvoid fa_lod_dither()\n{\n    if (_129_fa_gi.w != 0.0f)\n    {\n        float _151 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n        bool _154;\n        if (_129_fa_gi.w > 0.0f)\n        {\n            _154 = _151 >= _129_fa_gi.w;\n        }\n        else\n        {\n            _154 = _151 < (-_129_fa_gi.w);\n        }\n        if (_154)\n        {\n            discard;\n        }\n    }\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _751 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _751 = -_751;\n    }\n    float3 _600 = normalize(_129_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _764 = { fa_world_pos, _751, fa_world_tangent, fa_uv, fa_vertex_color, _600, gl_FrontFacing };\n    SurfaceInput param = _764;\n    Surface _605 = fa_standard_surface(param);\n    float3 _775 = _605.normal;\n    SurfaceInput _772 = { fa_world_pos, _751, fa_world_tangent, fa_uv, fa_vertex_color, _600, gl_FrontFacing };\n    SurfaceInput param_1 = _772;\n    Surface param_2 = _605;\n    surface(param_1, param_2);\n    _775 = param_2.normal;\n    if (param_2.alpha < _616_alphaCutoff)\n    {\n        discard;\n    }\n    fa_lod_dither();\n    float3 _627 = normalize(_775);\n    float3 _642 = normalize(float3(dot(fa_pre_r0, _627), dot(fa_pre_r1, _627), dot(fa_pre_r2, _627)));\n    float _654 = _642.z;\n    float2 e = _642.xy / ((abs(_642.x) + abs(_642.y)) + abs(_654)).xx;\n    if (_654 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n    float2 motion = 1024.0f.xx;\n    bool _698 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06f;\n    bool _705;\n    if (_698)\n    {\n        _705 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06f;\n    }\n    else\n    {\n        _705 = _698;\n    }\n    if (_705)\n    {\n        motion = clamp(((float2(fa_vel_prev.x, -fa_vel_prev.y) / fa_vel_prev.z.xx) * 0.5f) - ((float2(fa_vel_cur.x, -fa_vel_cur.y) / fa_vel_cur.z.xx) * 0.5f), (-4.0f).xx, 4.0f.xx);\n    }\n    fa_frag_velocity = motion;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    fa_vel_cur = stage_input.fa_vel_cur;\n    fa_vel_prev = stage_input.fa_vel_prev;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    stage_output.fa_frag_velocity = fa_frag_velocity;\n    return stage_output;\n}\n",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _226_fa_camera_pos : packoffset(c0);\n    float4 _226_fa_ambient : packoffset(c1);\n    float4 _226_fa_base_color : packoffset(c2);\n    float4 _226_fa_emissive : packoffset(c3);\n    float4 _226_fa_model_emissive : packoffset(c4);\n    float4 _226_fa_pbr : packoffset(c5);\n    float4 _226_fa_maps : packoffset(c6);\n    float4 _226_fa_fog : packoffset(c7);\n    float4 _226_fa_fog_b : packoffset(c8);\n    float4 _226_fa_fog_c : packoffset(c9);\n    float4 _226_fa_counts : packoffset(c10);\n    float4 _226_fa_env_sky : packoffset(c11);\n    float4 _226_fa_env_horizon : packoffset(c12);\n    float4 _226_fa_time : packoffset(c13);\n    float4 _226_fa_cl_vpx : packoffset(c14);\n    float4 _226_fa_cl_vpy : packoffset(c15);\n    float4 _226_fa_cl_vpw : packoffset(c16);\n    float4 _226_fa_cl_fwd : packoffset(c17);\n    float4 _226_fa_cl_grid : packoffset(c18);\n    float4 _226_fa_cl_info : packoffset(c19);\n    float4 _226_fa_layers_a : packoffset(c20);\n    float4 _226_fa_layers_b : packoffset(c21);\n    float4 _226_fa_layers_c : packoffset(c22);\n    float4 _226_fa_layers_d : packoffset(c23);\n    float4 _226_fa_ct_a : packoffset(c24);\n    float4 _226_fa_ct_b : packoffset(c25);\n    float4 _226_fa_ct_vpx : packoffset(c26);\n    float4 _226_fa_ct_vpy : packoffset(c27);\n    float4 _226_fa_ct_vpw : packoffset(c28);\n    float4 _226_fa_ct_fwd : packoffset(c29);\n    float4 _226_fa_tr_a : packoffset(c30);\n    float4 _226_fa_tr_b : packoffset(c31);\n    float4 _226_fa_probe_sh[9] : packoffset(c32);\n    float4 _226_fa_atlas : packoffset(c41);\n    float4 _226_fa_rpa_tile : packoffset(c42);\n    float4 _226_fa_rpa_pos : packoffset(c43);\n    float4 _226_fa_rpa_bx : packoffset(c44);\n    float4 _226_fa_rpa_by : packoffset(c45);\n    float4 _226_fa_rpa_bz : packoffset(c46);\n    float4 _226_fa_rpb_tile : packoffset(c47);\n    float4 _226_fa_rpb_pos : packoffset(c48);\n    float4 _226_fa_rpb_bx : packoffset(c49);\n    float4 _226_fa_rpb_by : packoffset(c50);\n    float4 _226_fa_rpb_bz : packoffset(c51);\n    float4 _226_fa_gi : packoffset(c52);\n    float4 _226_fa_gi_px : packoffset(c53);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _577_alphaCutoff : packoffset(c0);\n    float _577_fa_pad0 : packoffset(c0.y);\n    float _577_fa_pad1 : packoffset(c0.z);\n    float _577_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> mask : register(t5);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _226_fa_env_horizon.w);\n    float param = _226_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _242 = fa_tex_fix(param_2, param_3);\n    float4 _744 = base_t;\n    _744.x = _242.x;\n    _744.y = _242.y;\n    _744.z = _242.z;\n    base_t = _744;\n    float4 _258 = (_744 * _226_fa_base_color) * i.vertex_color;\n    float3 _705 = i.world_normal;\n    if (_226_fa_maps.z > 0.5f)\n    {\n        float param_4 = _226_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _226_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _294 = fa_tex_fix(param_6, param_7);\n        float3 _297 = (_294 * 2.0f) - 1.0f.xxx;\n        float2 _302 = _297.xy * _226_fa_maps.x;\n        float3 _752 = _297;\n        _752.x = _302.x;\n        _752.y = _302.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _752;\n        _705 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _226_fa_env_horizon.w);\n    float param_10 = _226_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _333 = fa_tex_fix(param_12, param_13);\n    float4 _755 = mrt;\n    _755.x = _333.x;\n    _755.y = _333.y;\n    _755.z = _333.z;\n    mrt = _755;\n    float4 _365 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _226_fa_env_horizon.w);\n    float param_14 = _226_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _365.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _377 = fa_tex_fix(param_16, param_17);\n    float param_18 = _226_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _226_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _409 = fa_tex_fix(param_20, param_21);\n    float _710 = _226_fa_layers_a.x;\n    float _711 = _226_fa_layers_a.y;\n    float _714 = _226_fa_layers_a.z;\n    float _713 = _226_fa_layers_b.w;\n    float _716 = _226_fa_layers_c.x;\n    if (_226_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_226_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _710 *= _377.y;\n            _711 *= _377.z;\n            _713 *= _365.w;\n        }\n        if (_226_fa_layers_c.z > 1.5f)\n        {\n            _714 *= mrt.x;\n            _716 *= mrt.w;\n        }\n    }\n    Surface _743 = { _258.xyz, _258.w, _705, clamp(_226_fa_pbr.x * _333.z, 0.0f, 1.0f), clamp(_226_fa_pbr.y * _333.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_226_fa_maps.y * (_377.x - 1.0f)), _226_fa_emissive.xyz + (_226_fa_model_emissive.xyz * _409), _710, _711, _226_fa_layers_b.xyz, _713, _714, _226_fa_layers_a.w, _716, _226_fa_layers_c.y, _226_fa_layers_d.xyz, _226_fa_tr_a.x, _226_fa_tr_a.y, _226_fa_tr_b.xyz, _226_fa_tr_a.z };\n    return _743;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _600 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _600 = -_600;\n    }\n    float3 _561 = normalize(_226_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _613 = { fa_world_pos, _600, fa_world_tangent, fa_uv, fa_vertex_color, _561, gl_FrontFacing };\n    SurfaceInput param = _613;\n    SurfaceInput _621 = { fa_world_pos, _600, fa_world_tangent, fa_uv, fa_vertex_color, _561, gl_FrontFacing };\n    SurfaceInput param_1 = _621;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    if (param_2.alpha < _577_alphaCutoff)\n    {\n        discard;\n    }\n    fa_frag_color = float4(gl_FragCoord.z, 0.0f, 0.0f, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 864,
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _226_fa_camera_pos : packoffset(c0);\n    float4 _226_fa_ambient : packoffset(c1);\n    float4 _226_fa_base_color : packoffset(c2);\n    float4 _226_fa_emissive : packoffset(c3);\n    float4 _226_fa_model_emissive : packoffset(c4);\n    float4 _226_fa_pbr : packoffset(c5);\n    float4 _226_fa_maps : packoffset(c6);\n    float4 _226_fa_fog : packoffset(c7);\n    float4 _226_fa_fog_b : packoffset(c8);\n    float4 _226_fa_fog_c : packoffset(c9);\n    float4 _226_fa_counts : packoffset(c10);\n    float4 _226_fa_env_sky : packoffset(c11);\n    float4 _226_fa_env_horizon : packoffset(c12);\n    float4 _226_fa_time : packoffset(c13);\n    float4 _226_fa_cl_vpx : packoffset(c14);\n    float4 _226_fa_cl_vpy : packoffset(c15);\n    float4 _226_fa_cl_vpw : packoffset(c16);\n    float4 _226_fa_cl_fwd : packoffset(c17);\n    float4 _226_fa_cl_grid : packoffset(c18);\n    float4 _226_fa_cl_info : packoffset(c19);\n    float4 _226_fa_layers_a : packoffset(c20);\n    float4 _226_fa_layers_b : packoffset(c21);\n    float4 _226_fa_layers_c : packoffset(c22);\n    float4 _226_fa_layers_d : packoffset(c23);\n    float4 _226_fa_ct_a : packoffset(c24);\n    float4 _226_fa_ct_b : packoffset(c25);\n    float4 _226_fa_ct_vpx : packoffset(c26);\n    float4 _226_fa_ct_vpy : packoffset(c27);\n    float4 _226_fa_ct_vpw : packoffset(c28);\n    float4 _226_fa_ct_fwd : packoffset(c29);\n    float4 _226_fa_tr_a : packoffset(c30);\n    float4 _226_fa_tr_b : packoffset(c31);\n    float4 _226_fa_probe_sh[9] : packoffset(c32);\n    float4 _226_fa_atlas : packoffset(c41);\n    float4 _226_fa_rpa_tile : packoffset(c42);\n    float4 _226_fa_rpa_pos : packoffset(c43);\n    float4 _226_fa_rpa_bx : packoffset(c44);\n    float4 _226_fa_rpa_by : packoffset(c45);\n    float4 _226_fa_rpa_bz : packoffset(c46);\n    float4 _226_fa_rpb_tile : packoffset(c47);\n    float4 _226_fa_rpb_pos : packoffset(c48);\n    float4 _226_fa_rpb_bx : packoffset(c49);\n    float4 _226_fa_rpb_by : packoffset(c50);\n    float4 _226_fa_rpb_bz : packoffset(c51);\n    float4 _226_fa_gi : packoffset(c52);\n    float4 _226_fa_gi_px : packoffset(c53);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _577_alphaCutoff : packoffset(c0);\n    float _577_fa_pad0 : packoffset(c0.y);\n    float _577_fa_pad1 : packoffset(c0.z);\n    float _577_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> mask : register(t5);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _226_fa_env_horizon.w);\n    float param = _226_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _242 = fa_tex_fix(param_2, param_3);\n    float4 _744 = base_t;\n    _744.x = _242.x;\n    _744.y = _242.y;\n    _744.z = _242.z;\n    base_t = _744;\n    float4 _258 = (_744 * _226_fa_base_color) * i.vertex_color;\n    float3 _705 = i.world_normal;\n    if (_226_fa_maps.z > 0.5f)\n    {\n        float param_4 = _226_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _226_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _294 = fa_tex_fix(param_6, param_7);\n        float3 _297 = (_294 * 2.0f) - 1.0f.xxx;\n        float2 _302 = _297.xy * _226_fa_maps.x;\n        float3 _752 = _297;\n        _752.x = _302.x;\n        _752.y = _302.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _752;\n        _705 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _226_fa_env_horizon.w);\n    float param_10 = _226_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _333 = fa_tex_fix(param_12, param_13);\n    float4 _755 = mrt;\n    _755.x = _333.x;\n    _755.y = _333.y;\n    _755.z = _333.z;\n    mrt = _755;\n    float4 _365 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _226_fa_env_horizon.w);\n    float param_14 = _226_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _365.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _377 = fa_tex_fix(param_16, param_17);\n    float param_18 = _226_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _226_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _409 = fa_tex_fix(param_20, param_21);\n    float _710 = _226_fa_layers_a.x;\n    float _711 = _226_fa_layers_a.y;\n    float _714 = _226_fa_layers_a.z;\n    float _713 = _226_fa_layers_b.w;\n    float _716 = _226_fa_layers_c.x;\n    if (_226_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_226_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _710 *= _377.y;\n            _711 *= _377.z;\n            _713 *= _365.w;\n        }\n        if (_226_fa_layers_c.z > 1.5f)\n        {\n            _714 *= mrt.x;\n            _716 *= mrt.w;\n        }\n    }\n    Surface _743 = { _258.xyz, _258.w, _705, clamp(_226_fa_pbr.x * _333.z, 0.0f, 1.0f), clamp(_226_fa_pbr.y * _333.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_226_fa_maps.y * (_377.x - 1.0f)), _226_fa_emissive.xyz + (_226_fa_model_emissive.xyz * _409), _710, _711, _226_fa_layers_b.xyz, _713, _714, _226_fa_layers_a.w, _716, _226_fa_layers_c.y, _226_fa_layers_d.xyz, _226_fa_tr_a.x, _226_fa_tr_a.y, _226_fa_tr_b.xyz, _226_fa_tr_a.z };\n    return _743;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _600 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _600 = -_600;\n    }\n    float3 _561 = normalize(_226_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _613 = { fa_world_pos, _600, fa_world_tangent, fa_uv, fa_vertex_color, _561, gl_FrontFacing };\n    SurfaceInput param = _613;\n    SurfaceInput _621 = { fa_world_pos, _600, fa_world_tangent, fa_uv, fa_vertex_color, _561, gl_FrontFacing };\n    SurfaceInput param_1 = _621;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    if (param_2.alpha < _577_alphaCutoff)\n    {\n        discard;\n    }\n    fa_frag_color = float4(gl_FragCoord.z, 0.0f, 0.0f, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 864,
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
