{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "ae26515a48b1a8d2e7a58b8583b7398bc5ad5b1e5314aaacf65f28e91c149fe7",
  "slang": "hlsl5",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _263 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _263;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_270, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _3885[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\nstatic const LightSample _6312 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, 0 };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _468_fa_camera_pos : packoffset(c0);\n    float4 _468_fa_ambient : packoffset(c1);\n    float4 _468_fa_base_color : packoffset(c2);\n    float4 _468_fa_emissive : packoffset(c3);\n    float4 _468_fa_model_emissive : packoffset(c4);\n    float4 _468_fa_pbr : packoffset(c5);\n    float4 _468_fa_maps : packoffset(c6);\n    float4 _468_fa_fog : packoffset(c7);\n    float4 _468_fa_fog_b : packoffset(c8);\n    float4 _468_fa_fog_c : packoffset(c9);\n    float4 _468_fa_counts : packoffset(c10);\n    float4 _468_fa_env_sky : packoffset(c11);\n    float4 _468_fa_env_horizon : packoffset(c12);\n    float4 _468_fa_time : packoffset(c13);\n    float4 _468_fa_cl_vpx : packoffset(c14);\n    float4 _468_fa_cl_vpy : packoffset(c15);\n    float4 _468_fa_cl_vpw : packoffset(c16);\n    float4 _468_fa_cl_fwd : packoffset(c17);\n    float4 _468_fa_cl_grid : packoffset(c18);\n    float4 _468_fa_cl_info : packoffset(c19);\n    float4 _468_fa_layers_a : packoffset(c20);\n    float4 _468_fa_layers_b : packoffset(c21);\n    float4 _468_fa_layers_c : packoffset(c22);\n    float4 _468_fa_layers_d : packoffset(c23);\n    float4 _468_fa_ct_a : packoffset(c24);\n    float4 _468_fa_ct_b : packoffset(c25);\n    float4 _468_fa_ct_vpx : packoffset(c26);\n    float4 _468_fa_ct_vpy : packoffset(c27);\n    float4 _468_fa_ct_vpw : packoffset(c28);\n    float4 _468_fa_ct_fwd : packoffset(c29);\n    float4 _468_fa_tr_a : packoffset(c30);\n    float4 _468_fa_tr_b : packoffset(c31);\n    float4 _468_fa_probe_sh[9] : packoffset(c32);\n    float4 _468_fa_atlas : packoffset(c41);\n    float4 _468_fa_rpa_tile : packoffset(c42);\n    float4 _468_fa_rpa_pos : packoffset(c43);\n    float4 _468_fa_rpa_bx : packoffset(c44);\n    float4 _468_fa_rpa_by : packoffset(c45);\n    float4 _468_fa_rpa_bz : packoffset(c46);\n    float4 _468_fa_rpb_tile : packoffset(c47);\n    float4 _468_fa_rpb_pos : packoffset(c48);\n    float4 _468_fa_rpb_bx : packoffset(c49);\n    float4 _468_fa_rpb_by : packoffset(c50);\n    float4 _468_fa_rpb_bz : packoffset(c51);\n    float4 _468_fa_gi : packoffset(c52);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2121_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2121_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2121_fa_shadow_info[4] : packoffset(c20);\n    float4 _2121_fa_shadow_split : packoffset(c24);\n    float4 _2121_fa_shadow_cfg : packoffset(c25);\n    float4 _2121_fa_shadow_bias : packoffset(c26);\n    float4 _2121_fa_shadow_eye : packoffset(c27);\n    float4 _2121_fa_shadow_fwd : packoffset(c28);\n    float4 _2121_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _5035_dark : packoffset(c0);\n    float _5035_fa_pad0 : packoffset(c0.y);\n    float _5035_fa_pad1 : packoffset(c0.z);\n    float _5035_fa_pad2 : packoffset(c0.w);\n    float _5035_skyAmount : packoffset(c1);\n    float _5035_fa_pad3 : packoffset(c1.y);\n    float _5035_fa_pad4 : packoffset(c1.z);\n    float _5035_fa_pad5 : packoffset(c1.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t9);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_probe_atlas : register(t6);\nTexture2D<float4> fa_screen_tex : register(t10);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1397 = _468_fa_cl_info.x < 0.0f;\n    bool _1404;\n    if (!_1397)\n    {\n        _1404 = _468_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1404 = _1397;\n    }\n    bool _1412;\n    if (!_1404)\n    {\n        _1412 = _468_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1412 = _1404;\n    }\n    bool _1419;\n    if (!_1412)\n    {\n        _1419 = _468_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1419 = _1412;\n    }\n    bool _1426;\n    if (!_1419)\n    {\n        _1426 = _468_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1426 = _1419;\n    }\n    if (_1426)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1436 = float4(world_pos, 1.0f);\n    float _1442 = dot(_468_fa_cl_vpw, _1436);\n    if (!(_1442 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1464 = float2(dot(_468_fa_cl_vpx, _1436), dot(_468_fa_cl_vpy, _1436)) / _1442.xx;\n    int _1468 = int(_468_fa_cl_grid.x);\n    int _1472 = int(_468_fa_cl_grid.y);\n    int param = (int(_468_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_468_fa_cl_fwd.xyz, world_pos) + _468_fa_cl_fwd.w, _468_fa_cl_grid.w) / _468_fa_cl_grid.w) * _468_fa_cl_grid.z)), 0, int(_468_fa_cl_info.y) - 1) * _1472) + clamp(int(floor(((_1464.y * 0.5f) + 0.5f) * _468_fa_cl_grid.y)), 0, _1472 - 1)) * _1468)) + clamp(int(floor(((_1464.x * 0.5f) + 0.5f) * _468_fa_cl_grid.x)), 0, _1468 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1548 = fa_cluster_texel(param);\n    return int2(int(_1548.x), int(_1548.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_468_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4719 = fa_cluster_lookup(param);\n    fa_cl_slot = _4719.x;\n    fa_cl_local = _4719.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _5096 = fa_linear_to_srgb(param);\n        c = _5096;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _5104 = fa_srgb_to_linear(param_1);\n            c = _5104;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _348;\n    if (i.front_facing)\n    {\n        _348 = i.world_normal;\n    }\n    else\n    {\n        _348 = -i.world_normal;\n    }\n    float3 _372 = normalize(i.world_tangent.xyz - (_348 * dot(_348, i.world_tangent.xyz)));\n    float3 _400 = normalize(((_372 * m.x) + ((cross(_348, _372) * i.world_tangent.w) * m.y)) + (_348 * m.z));\n    float3 _403;\n    if (i.front_facing)\n    {\n        _403 = _400;\n    }\n    else\n    {\n        _403 = -_400;\n    }\n    return _403;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _468_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _5135 = fa_tex_fix(param_2, param_3);\n    float4 _6274 = base_t;\n    _6274.x = _5135.x;\n    _6274.y = _5135.y;\n    _6274.z = _5135.z;\n    base_t = _6274;\n    float4 _5149 = (_6274 * _468_fa_base_color) * i.vertex_color;\n    float3 _6080 = i.world_normal;\n    if (_468_fa_maps.z > 0.5f)\n    {\n        float param_4 = _468_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _5181 = fa_tex_fix(param_6, param_7);\n        float3 _5184 = (_5181 * 2.0f) - 1.0f.xxx;\n        float2 _5189 = _5184.xy * _468_fa_maps.x;\n        float3 _6282 = _5184;\n        _6282.x = _5189.x;\n        _6282.y = _5189.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _6282;\n        _6080 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _468_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _5217 = fa_tex_fix(param_12, param_13);\n    float4 _6285 = mrt;\n    _6285.x = _5217.x;\n    _6285.y = _5217.y;\n    _6285.z = _5217.z;\n    mrt = _6285;\n    float4 _5245 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _468_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _5245.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _5256 = fa_tex_fix(param_16, param_17);\n    float param_18 = _468_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _5286 = fa_tex_fix(param_20, param_21);\n    float _6085 = _468_fa_layers_a.x;\n    float _6086 = _468_fa_layers_a.y;\n    float _6089 = _468_fa_layers_a.z;\n    float _6088 = _468_fa_layers_b.w;\n    float _6091 = _468_fa_layers_c.x;\n    if (_468_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_468_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _6085 *= _5256.y;\n            _6086 *= _5256.z;\n            _6088 *= _5245.w;\n        }\n        if (_468_fa_layers_c.z > 1.5f)\n        {\n            _6089 *= mrt.x;\n            _6091 *= mrt.w;\n        }\n    }\n    Surface _6118 = { _5149.xyz, _5149.w, _6080, clamp(_468_fa_pbr.x * _5217.z, 0.0f, 1.0f), clamp(_468_fa_pbr.y * _5217.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_468_fa_maps.y * (_5256.x - 1.0f)), _468_fa_emissive.xyz + (_468_fa_model_emissive.xyz * _5286), _6085, _6086, _468_fa_layers_b.xyz, _6088, _6089, _468_fa_layers_a.w, _6091, _468_fa_layers_c.y, _468_fa_layers_d.xyz, _468_fa_tr_a.x, _468_fa_tr_a.y, _468_fa_tr_b.xyz, _468_fa_tr_a.z };\n    return _6118;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1628 = rect.zw - rect.xy;\n    float2 _1632 = _1628 * atlas;\n    float2 _1636 = ddx * _1632;\n    float2 _1640 = ddy * _1632;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1628), clamp(0.5f * log2(max(max(dot(_1636, _1636), dot(_1640, _1640)), 9.9999999392252902907785028219223e-09f)), 0.0f, 3.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1673 = _468_fa_counts.y < 0.5f;\n    bool _1680;\n    if (!_1673)\n    {\n        _1680 = _468_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1680 = _1673;\n    }\n    if (_1680)\n    {\n        return;\n    }\n    float3 _1686 = ddx(world_pos);\n    float3 _1689 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1693 = fa_cluster_texel(param);\n    int _1697 = int(_1693.w);\n    if (_1697 < 1)\n    {\n        return;\n    }\n    int _1707 = int(_468_fa_counts.y + 0.5f);\n    int param_1 = _1707;\n    float4 _1711 = fa_light_texel(param_1);\n    float2 _1714 = _1711.yz;\n    int _1718 = int(_1711.w);\n    int param_2 = _1707 + 1;\n    float4 _1723 = fa_light_texel(param_2);\n    float _1724 = _1723.x;\n    int _1730 = int(_468_fa_counts.w + 0.5f) - 1;\n    int _1734 = int(_1693.z);\n    float3 _1999;\n    for (int k = 0; k < _1697; k++)\n    {\n        int _1747 = _1734 + k;\n        int param_3 = _1718 + (_1747 >> 2);\n        int _1764 = (_1707 + 2) + (int(fa_light_texel(param_3)[_1747 & 3]) * 7);\n        int param_4 = _1764 + 6;\n        float4 _1769 = fa_light_texel(param_4);\n        if (((int(_1769.w + 0.5f) >> _1730) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1764;\n        float4 _1784 = fa_light_texel(param_5);\n        int param_6 = _1764 + 1;\n        float4 _1789 = fa_light_texel(param_6);\n        int param_7 = _1764 + 2;\n        float4 _1794 = fa_light_texel(param_7);\n        float3 _1797 = _1784.xyz;\n        float _1802 = dot(_1797, world_pos) + _1784.w;\n        float3 _1804 = _1789.xyz;\n        float _1809 = dot(_1804, world_pos) + _1789.w;\n        float3 _1811 = _1794.xyz;\n        float _1816 = dot(_1811, world_pos) + _1794.w;\n        bool _1821 = abs(_1802) > 0.5f;\n        bool _1829;\n        if (!_1821)\n        {\n            _1829 = abs(_1809) > 0.5f;\n        }\n        else\n        {\n            _1829 = _1821;\n        }\n        bool _1837;\n        if (!_1829)\n        {\n            _1837 = abs(_1816) > 0.5f;\n        }\n        else\n        {\n            _1837 = _1829;\n        }\n        if (_1837)\n        {\n            continue;\n        }\n        float _1852 = clamp(dot(geo_normal, normalize(_1811)) * _1769.z, 0.0f, 1.0f);\n        if (_1852 <= 0.0f)\n        {\n            continue;\n        }\n        float _1872 = (clamp((0.5f - abs(_1816)) * 10.0f, 0.0f, 1.0f) * _1852) * _1769.x;\n        float2 _1880 = float2(_1802 + 0.5f, 0.5f - _1809);\n        float2 _1890 = float2(dot(_1797, _1686), dot(_1804, _1686));\n        float2 _1900 = float2(dot(_1797, _1689), dot(_1804, _1689));\n        int param_8 = _1764 + 5;\n        float4 _1905 = fa_light_texel(param_8);\n        int param_9 = _1764 + 3;\n        float4 _1910 = fa_light_texel(param_9);\n        int param_10 = _1764 + 4;\n        float4 _1915 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1905.xyz;\n        bool _1925 = _1910.z > _1910.x;\n        if (_1925)\n        {\n            float4 param_11 = _1910;\n            float2 param_12 = _1880;\n            float2 param_13 = _1714;\n            float2 param_14 = _1890;\n            float2 param_15 = _1900;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1724 > 0.5f) && (_1724 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1951 = fa_dc_to_linear(param_16);\n                float4 _6168 = tx;\n                _6168.x = _1951.x;\n                _6168.y = _1951.y;\n                _6168.z = _1951.z;\n                tx = _6168;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1872 * tex_a) * _1905.w, 0.0f, 1.0f).xxx);\n        if (_1915.z > _1915.x)\n        {\n            float4 param_17 = _1915;\n            float2 param_18 = _1880;\n            float2 param_19 = _1714;\n            float2 param_20 = _1890;\n            float2 param_21 = _1900;\n            float4 _1995 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1724 > 1.5f)\n            {\n                float3 param_22 = _1995.xyz;\n                float3 _2005 = fa_dc_to_srgb(param_22);\n                _1999 = _2005;\n            }\n            else\n            {\n                _1999 = _1995.xyz;\n            }\n            float3 _2014 = (_1999 * 2.0f) - 1.0f.xxx;\n            float2 _2019 = _2014.xy * _1769.y;\n            float3 _2041 = (normalize(_1797) * _2019.x) + (normalize(_1804) * _2019.y);\n            float3 _2044 = normalize(normal);\n            normal = normalize(lerp(_2044, normalize((_2044 * max(_2014.z, 0.0500000007450580596923828125f)) + (_2041 - (_2044 * dot(_2044, _2041)))), clamp(_1872 * (_1925 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return _6312;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_468_fa_cl_info.x) + int(_468_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_468_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4689;\n    if (fa_lm.z > 0.5f)\n    {\n        _4689 = 0.0f;\n    }\n    else\n    {\n        _4689 = 1.0f - clamp(_468_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _4700 = _4689 < 1.0f;\n    bool _4706;\n    if (_4700)\n    {\n        int param = li;\n        _4706 = fa_light_baked(param);\n    }\n    else\n    {\n        _4706 = _4700;\n    }\n    return _4706 ? _4689 : 1.0f;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _646 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _659 = (c - (ru * hx)) - p;\n        float3 _665 = ru * (2.0f * hx);\n        float _671 = max(dot(_665, _665), 9.9999999392252902907785028219223e-09f);\n        float _675 = dot(_659, _665);\n        float t = clamp((-_675) / _671, 0.0f, 1.0f);\n        if (_646)\n        {\n            float _690 = dot(r, _665);\n            float _696 = _671 - (_690 * _690);\n            if (abs(_696) > (9.9999997473787516355514526367188e-06f * _671))\n            {\n                t = clamp(((dot(r, _659) * _690) - _675) / _696, 0.0f, 1.0f);\n            }\n        }\n        return (p + _659) + (_665 * t);\n    }\n    float3 q = p;\n    float _728 = dot(r, axis);\n    bool _736;\n    if (_646)\n    {\n        _736 = abs(_728) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _736 = _646;\n    }\n    if (_736)\n    {\n        float _746 = dot(c - p, axis) / _728;\n        if (_746 > 0.0f)\n        {\n            q = p + (r * _746);\n        }\n    }\n    float3 _759 = q - c;\n    float2 xy = float2(dot(_759, ru), dot(_759, uu));\n    if (shape > 0.5f)\n    {\n        float _774 = length(xy);\n        if (_774 > hx)\n        {\n            xy *= (hx / _774);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _527_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _527_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _566 = dot(d, right);\n    float _570 = dot(d, up);\n    float _581;\n    if (((_566 * _566) + (_570 * _570)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _581 = atan2(_570, _566) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _581 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_581 - floor(_581)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _415 = abs(d);\n    float _417 = _415.x;\n    float _419 = _415.y;\n    bool _420 = _417 >= _419;\n    bool _428;\n    if (_420)\n    {\n        _428 = _417 >= _415.z;\n    }\n    else\n    {\n        _428 = _420;\n    }\n    int _429;\n    if (_428)\n    {\n        _429 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _444;\n        if (_419 >= _415.z)\n        {\n            _444 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _444 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _429 = _444;\n    }\n    return _429;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _812 = fa_light_base(param);\n    bool _816 = _468_fa_ambient.w > 4.5f;\n    int param_1 = _812;\n    float4 _820 = fa_light_texel(param_1);\n    int param_2 = _812 + 1;\n    float4 _825 = fa_light_texel(param_2);\n    float _828 = _825.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _840 = _816 && (_828 > 2.5f);\n    fa_light_is_area = _840;\n    bool _842 = _828 < 0.5f;\n    float3 l;\n    if (_842)\n    {\n        l = normalize(_820.xyz);\n        if (_816)\n        {\n            int param_3 = _812 + 6;\n            float4 _856 = fa_light_texel(param_3);\n            if (_856.z > 0.5f)\n            {\n                int param_4 = _812 + 4;\n                float4 _866 = fa_light_texel(param_4);\n                int param_5 = _812 + 5;\n                float4 _871 = fa_light_texel(param_5);\n                float2 param_6 = _856.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _866.xyz) * _866.w, (-dot(world_pos, _871.xyz)) * _871.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _901 = _820.xyz;\n        float3 _903 = _901 - world_pos;\n        float3 to_light = _903;\n        float _906 = length(_903);\n        float reach = _906;\n        bool front = true;\n        if (_840)\n        {\n            int param_8 = _812 + 7;\n            reach = max(_906 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _812 + 4;\n            float4 _930 = fa_light_texel(param_9);\n            int param_10 = _812 + 5;\n            float4 _935 = fa_light_texel(param_10);\n            int param_11 = _812 + 6;\n            float4 _940 = fa_light_texel(param_11);\n            float _941 = _940.w;\n            int param_12 = _812 + 2;\n            float3 _948 = normalize(fa_light_texel(param_12).xyz);\n            bool _950 = _941 > 1.5f;\n            bool _958;\n            if (!_950)\n            {\n                _958 = dot(_948, to_light) < 0.0f;\n            }\n            else\n            {\n                _958 = _950;\n            }\n            front = _958;\n            float3 r = 0.0f.xxx;\n            float3 _967 = _468_fa_camera_pos.xyz - world_pos;\n            bool _971 = dot(n, n) > 0.5f;\n            bool _979;\n            if (_971)\n            {\n                _979 = dot(_967, _967) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _979 = _971;\n            }\n            if (_979)\n            {\n                r = reflect(-normalize(_967), normalize(n));\n            }\n            float3 param_13 = _901;\n            float3 param_14 = _948;\n            float3 param_15 = _930.xyz;\n            float3 param_16 = _935.xyz;\n            float param_17 = _930.w;\n            float param_18 = _935.w;\n            float param_19 = _941;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1015 = length(to_light);\n        dist = _1015;\n        l = to_light / max(_1015, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1029 = reach / max(_820.w, 0.001000000047497451305389404296875f);\n        float _1035 = clamp(1.0f - (_1029 * _1029), 0.0f, 1.0f);\n        float _1037;\n        if (front)\n        {\n            _1037 = _1035 * _1035;\n        }\n        else\n        {\n            _1037 = 0.0f;\n        }\n        atten = _1037;\n        bool _1048 = _828 < 2.5f;\n        if ((_828 > 1.5f) && _1048)\n        {\n            int param_22 = _812 + 2;\n            float4 _1056 = fa_light_texel(param_22);\n            float _1066 = _1056.w;\n            int param_23 = _812 + 3;\n            float4 _1071 = fa_light_texel(param_23);\n            float _1072 = _1071.x;\n            float cos_inner = _1072;\n            if (_1072 > 1.5f)\n            {\n                cos_inner = lerp(_1066, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1066, cos_inner, dot(-l, normalize(_1056.xyz)));\n        }\n        if (_816 && (_828 < 1.5f))\n        {\n            int param_24 = _812 + 6;\n            float4 _1096 = fa_light_texel(param_24);\n            if (_1096.z > 0.5f)\n            {\n                float3 _1104 = -to_light;\n                int param_25 = _812 + 4;\n                int param_26 = _812 + 5;\n                float3 _1118 = fa_light_texel(param_25).xyz;\n                float3 _1122 = fa_light_texel(param_26).xyz;\n                float3 _1131 = float3(dot(_1104, _1118), dot(_1104, _1122), dot(_1104, cross(_1118, _1122)));\n                float3 param_27 = _1131;\n                int _1135 = fa_cube_face(param_27);\n                int param_28 = _1135;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1162 = float2(dot(_1131, cross(param_29, param_30)), dot(_1131, param_30)) / max(dot(_1131, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1166 = _1135 / 3;\n                float2 param_31 = _1096.xy + (float2(float(_1135 - (_1166 * 3)), float(_1166)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1162.x), 0.5f - (0.5f * _1162.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _812 + 7;\n            float4 _1196 = fa_light_texel(param_33);\n            if (_1196.z > 0.5f)\n            {\n                int param_34 = _812 + 2;\n                int param_35 = _812 + 4;\n                int param_36 = _812 + 5;\n                float2 param_37 = _1196.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_816 && _1048)\n            {\n                int param_42 = _812 + 6;\n                float4 _1243 = fa_light_texel(param_42);\n                int param_43 = _812 + 7;\n                float4 _1248 = fa_light_texel(param_43);\n                bool _1251 = _1243.z > 0.5f;\n                bool _1258;\n                if (!_1251)\n                {\n                    _1258 = _1248.z > 0.5f;\n                }\n                else\n                {\n                    _1258 = _1251;\n                }\n                if (_1258)\n                {\n                    int param_44 = _812 + 2;\n                    float4 _1265 = fa_light_texel(param_44);\n                    float3 _1269 = normalize(_1265.xyz);\n                    int param_45 = _812 + 4;\n                    float4 _1274 = fa_light_texel(param_45);\n                    int param_46 = _812 + 5;\n                    float4 _1279 = fa_light_texel(param_46);\n                    if (_1251)\n                    {\n                        float3 _1287 = -to_light;\n                        float _1294 = _1265.w;\n                        float _1310 = 0.5f / max(dot(_1287, _1269) * (sqrt(max(1.0f - (_1294 * _1294), 0.0f)) / max(_1294, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1243.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1287, _1274.xyz) * _1310), 0.5f - (dot(_1287, _1279.xyz) * _1310));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1248.z > 0.5f)\n                    {\n                        float2 param_49 = _1248.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1269;\n                        float3 param_52 = _1274.xyz;\n                        float3 param_53 = _1279.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _5886 = _825.xyz * atten;\n    if (_816)\n    {\n        _5886 *= fa_light_tint;\n    }\n    int _1379;\n    if (_842)\n    {\n        _1379 = 0;\n    }\n    else\n    {\n        _1379 = ((_828 > 1.5f) && (_828 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _5897 = { l, _5886, atten, 1.0f, dist, _1379 };\n    return _5897;\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _4918 = n < 0;\n    bool _4925;\n    if (!_4918)\n    {\n        _4925 = n >= fa_light_count();\n    }\n    else\n    {\n        _4925 = _4918;\n    }\n    if (_4925)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _4933 = fa_cl_light(param);\n    int param_1 = _4933;\n    float _4937 = fa_baked_keep(param_1);\n    if (_4937 <= 0.0f)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _4933;\n    float3 param_3 = i.world_pos;\n    float3 param_4 = i.world_normal;\n    LightSample _4953 = fa_light_sample_n(param_2, param_3, param_4);\n    LightSample _6068 = { _4953.direction, _4953.color * _4937, _4953.attenuation * _4937, _4953.shadow, _4953._distance, _4953.type };\n    return _6068;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2168 = fa_shadow_depth(param, param_1);\n    float _2172;\n    if (conv.x < 0.5f)\n    {\n        _2172 = _2168;\n    }\n    else\n    {\n        _2172 = (conv.y * conv.z) / (conv.z - (_2168 * (conv.z - conv.y)));\n    }\n    return _2172;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel_turn(float2 d)\n{\n    return float2((d.x * (-0.737368881702423095703125f)) - (d.y * 0.675490319728851318359375f), (d.y * (-0.737368881702423095703125f)) + (d.x * 0.675490319728851318359375f));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2218 = fa_shadow_noise() * 6.283185482025146484375f;\n    float2 _2224 = float2(cos(_2218), sin(_2218));\n    float2 dir = _2224;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2233;\n        if (k < 0.0f)\n        {\n            _2233 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2233 = k;\n        }\n        float _2252 = clamp((_2233 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2271 = sqrt((float(i) + 0.5f) * 0.0625f) * _2252;\n            float2 param_3 = uv + (dir * (_2121_fa_shadow_bias.zw * _2271));\n            float4 param_4 = rect;\n            float3 param_5 = conv;\n            float _2285 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2285 < (zr - (_2271 * plane)))\n            {\n                sum += _2285;\n                cnt += 1.0f;\n            }\n            float2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2313 = sum / cnt;\n        float _2323;\n        if (k < 0.0f)\n        {\n            _2323 = (-k) / max(_2313, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2323 = k;\n        }\n        radius = clamp(((max(zr - _2313, 0.0f) * unit) * _2323) / texel_m, 1.5f, 16.0f);\n        dir = _2224;\n    }\n    float lit = 0.0f;\n    int _2349 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2349; i_1++)\n    {\n        float _2368 = sqrt((float(i_1) + 0.5f) / float(_2349)) * radius;\n        float2 param_7 = uv + (dir * (_2121_fa_shadow_bias.zw * _2368));\n        float4 param_8 = rect;\n        float3 param_9 = conv;\n        lit += float((zr - (_2368 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        float2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2349);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2573 = _468_fa_pbr.z < 0.5f;\n    bool _2580;\n    if (!_2573)\n    {\n        _2580 = _2121_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2580 = _2573;\n    }\n    if (_2580)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2121_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2593 = fa_light_texel(param);\n    float _2594 = _2593.x;\n    if (_2594 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2603 = int(_2594 + 0.5f);\n    int param_1 = _2603;\n    float4 _2607 = fa_light_texel(param_1);\n    int param_2 = _2603 + 1;\n    float4 _2612 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2615 = _2607.y;\n    if (_2615 > 0.0f)\n    {\n        float _2632 = 1.0f - smoothstep(0.75f * _2615, _2615, length(world - _2121_fa_shadow_eye.xyz));\n        fade = _2632;\n        if (_2632 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2607.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2656 = (_2603 + 2) + (face * 6);\n    int param_4 = _2656;\n    int param_5 = _2656 + 1;\n    int param_6 = _2656 + 3;\n    float4 _2670 = fa_light_texel(param_6);\n    int param_7 = _2656 + 4;\n    float4 _2675 = fa_light_texel(param_7);\n    int param_8 = _2656 + 5;\n    float4 _2680 = fa_light_texel(param_8);\n    float _2692 = _2680.x * max(dot(_2670, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2697 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2720 = clamp(dot(n, _2670.xyz), -1.0f, 1.0f);\n    float _2739 = min(sqrt(1.0f - (_2720 * _2720)) / max(abs(dot(n, world - lpos)) / max(dot(_2670, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2742 = _2612.y;\n    float _2744;\n    if (_2742 > 0.0f)\n    {\n        _2744 = _2742;\n    }\n    else\n    {\n        _2744 = 1.5f * _2692;\n    }\n    float4 _2764 = float4(world + (n * (_2744 * sqrt(1.0f - (_2697 * _2697)))), 1.0f);\n    float _2768 = dot(_2670, _2764);\n    float _2771 = _2680.y;\n    if (_2768 < _2771)\n    {\n        return 1.0f;\n    }\n    float2 _2786 = float2(dot(fa_light_texel(param_4), _2764), dot(fa_light_texel(param_5), _2764)) / _2768.xx;\n    float _2788 = _2786.x;\n    bool _2791 = _2788 < _2675.x;\n    bool _2800;\n    if (!_2791)\n    {\n        _2800 = _2788 > _2675.z;\n    }\n    else\n    {\n        _2800 = _2791;\n    }\n    bool _2809;\n    if (!_2800)\n    {\n        _2809 = _2786.y < _2675.y;\n    }\n    else\n    {\n        _2809 = _2800;\n    }\n    bool _2818;\n    if (!_2809)\n    {\n        _2818 = _2786.y > _2675.w;\n    }\n    else\n    {\n        _2818 = _2809;\n    }\n    if (_2818)\n    {\n        return 1.0f;\n    }\n    float _2824 = _2612.x;\n    float _2826;\n    if (_2824 > 0.0f)\n    {\n        _2826 = _2824;\n    }\n    else\n    {\n        _2826 = 1.5f * _2692;\n    }\n    float2 param_9 = _2786;\n    float4 param_10 = _2675;\n    float param_11 = _2768 - (_2826 * (1.0f + (0.5f * _2739)));\n    float param_12 = _2692;\n    float param_13 = 1.0f;\n    float param_14 = _2680.z * 0.25f;\n    float param_15 = (_2692 * min(_2739, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2771, _2680.z);\n    int param_17 = int(_2607.z + 0.5f);\n    float param_18 = _2607.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2111;\n    if (i == 0)\n    {\n        _2111 = _2121_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2127;\n        if (i == 1)\n        {\n            _2127 = _2121_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2135;\n            if (i == 2)\n            {\n                _2135 = _2121_fa_shadow_split.z;\n            }\n            else\n            {\n                _2135 = _2121_fa_shadow_split.w;\n            }\n            _2127 = _2135;\n        }\n        _2111 = _2127;\n    }\n    return _2111;\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2414 = max(_2121_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2419 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2425 = sqrt(1.0f - (_2419 * _2419));\n    float _2433 = min(_2425 / max(_2419, 0.20000000298023223876953125f), 4.0f);\n    float _2438;\n    if (_2121_fa_shadow_bias.y > 0.0f)\n    {\n        _2438 = _2121_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2438 = 1.5f * _2121_fa_shadow_info[ci].x;\n    }\n    float4 _2463 = mul(float4(world + (n * (_2438 * _2425)), 1.0f), _2121_fa_shadow_mat[ci]);\n    float _2470 = _2463.x;\n    bool _2473 = _2470 < _2121_fa_shadow_rect[ci].x;\n    bool _2482;\n    if (!_2473)\n    {\n        _2482 = _2470 > _2121_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2482 = _2473;\n    }\n    bool _2491;\n    if (!_2482)\n    {\n        _2491 = _2463.y < _2121_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2491 = _2482;\n    }\n    bool _2500;\n    if (!_2491)\n    {\n        _2500 = _2463.y > _2121_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2500 = _2491;\n    }\n    bool _2507;\n    if (!_2500)\n    {\n        _2507 = _2463.z > 1.0f;\n    }\n    else\n    {\n        _2507 = _2500;\n    }\n    if (_2507)\n    {\n        return -1.0f;\n    }\n    float _2515;\n    if (_2121_fa_shadow_bias.x > 0.0f)\n    {\n        _2515 = _2121_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2515 = 1.5f * _2121_fa_shadow_info[ci].x;\n    }\n    float2 param = _2463.xy;\n    float4 param_1 = _2121_fa_shadow_rect[ci];\n    float param_2 = _2463.z - ((_2515 * (1.0f + (0.5f * _2433))) / _2414);\n    float param_3 = _2121_fa_shadow_info[ci].x;\n    float param_4 = _2414;\n    float param_5 = _2414 * 0.25f;\n    float param_6 = ((_2121_fa_shadow_info[ci].x * min(_2433, 3.0f)) * 0.5f) / _2414;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2121_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2121_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_468_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2893 = int(_2121_fa_shadow_cfg.x + 0.5f);\n    if (_2893 < 1)\n    {\n        return 1.0f;\n    }\n    float _2908 = dot(world - _2121_fa_shadow_eye.xyz, _2121_fa_shadow_fwd.xyz);\n    int param = _2893 - 1;\n    if (_2908 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2920 = _2893 > 1;\n    bool _2927;\n    if (_2920)\n    {\n        _2927 = _2908 > _2121_fa_shadow_split.x;\n    }\n    else\n    {\n        _2927 = _2920;\n    }\n    if (_2927)\n    {\n        ci = 1;\n    }\n    bool _2931 = _2893 > 2;\n    bool _2938;\n    if (_2931)\n    {\n        _2938 = _2908 > _2121_fa_shadow_split.y;\n    }\n    else\n    {\n        _2938 = _2931;\n    }\n    if (_2938)\n    {\n        ci = 2;\n    }\n    bool _2942 = _2893 > 3;\n    bool _2949;\n    if (_2942)\n    {\n        _2949 = _2908 > _2121_fa_shadow_split.z;\n    }\n    else\n    {\n        _2949 = _2942;\n    }\n    if (_2949)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2893)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2975 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2975;\n        if (_2975 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2121_fa_shadow_cfg.y > 0.0f)\n    {\n        float _3000;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3000 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3000 = _2121_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _3019 = _2121_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3000, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _3030 = clamp((_2908 - (fa_shadow_split_at(param_7) - _3019)) / _3019, 0.0f, 1.0f);\n        if (_3030 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2893)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _3051 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3051;\n                if (_3051 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _3030);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _4425 = _468_fa_ct_a.x < 0.5f;\n    bool _4432;\n    if (!_4425)\n    {\n        _4432 = _2121_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _4432 = _4425;\n    }\n    if (_4432)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2121_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _4445 = fa_light_texel(param);\n    float _4446 = _4445.y;\n    float len = _4446;\n    if (_4446 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4458 = length(world - _468_fa_camera_pos.xyz);\n    float _4468 = 1.0f - smoothstep(0.5f * _468_fa_ct_b.x, _468_fa_ct_b.x, _4458);\n    if (_4468 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4474 = len;\n    float _4477 = min(_4474, 0.89999997615814208984375f * dist);\n    len = _4477;\n    float _4482 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _4458);\n    float _4487 = _4482 + (0.5f * _4477);\n    float3 _4493 = world + (gn * _4482);\n    float _4495 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _4559;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4510 = (float(k) + _4495) * 0.083333335816860198974609375f;\n        float3 _4518 = _4493 + (l * (_4510 * len));\n        float4 _4524 = float4(_4518, 1.0f);\n        float _4530 = dot(_468_fa_ct_vpw, _4524);\n        if (_4530 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _4550 = float2(dot(_468_fa_ct_vpx, _4524), dot(_468_fa_ct_vpy, _4524)) / _4530.xx;\n        float _4554 = _4550.x * 0.5f;\n        float _4555 = _4554 + 0.5f;\n        if (_468_fa_ct_a.y > 0.5f)\n        {\n            _4559 = (_4550.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _4559 = 0.5f - (_4550.y * 0.5f);\n        }\n        bool _4575 = _4555 < 0.0f;\n        bool _4582;\n        if (!_4575)\n        {\n            _4582 = _4555 >= 1.0f;\n        }\n        else\n        {\n            _4582 = _4575;\n        }\n        bool _4589;\n        if (!_4582)\n        {\n            _4589 = _4559 < 0.0f;\n        }\n        else\n        {\n            _4589 = _4582;\n        }\n        bool _4596;\n        if (!_4589)\n        {\n            _4596 = _4559 >= 1.0f;\n        }\n        else\n        {\n            _4596 = _4589;\n        }\n        if (_4596)\n        {\n            break;\n        }\n        float4 _4623 = fa_screen_tex.Load(int3(clamp(int2(float2(_4555, _4559) * _468_fa_ct_a.zw), int2(0, 0), int2(_468_fa_ct_a.zw) - int2(1, 1)), 0));\n        if (_4623.w < 0.5f)\n        {\n            continue;\n        }\n        float _4642 = (dot(_468_fa_ct_fwd.xyz, _4518) + _468_fa_ct_fwd.w) - _4623.x;\n        if ((_4642 > _4482) && (_4642 < _4487))\n        {\n            occ = max(occ, (1.0f - (_4510 * _4510)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_4555, 0.5f - _4554), min(_4559, 1.0f - _4559))));\n        }\n    }\n    return 1.0f - (occ * _4468);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _4745 = fa_baked_keep(param);\n    if (_4745 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _6030 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _6030;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4771 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _6032 = _4771.color;\n    float _6033 = _4771.attenuation;\n    float _6034 = _4771.shadow;\n    bool _4774 = _4771.type == 0;\n    if (_4774 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4771.direction;\n        float _4785 = fa_shadow_factor(param_5, param_6);\n        _6034 = _4785;\n        _6032 *= _4785;\n    }\n    else\n    {\n        bool _4796 = _4771.type != 0;\n        bool _4802;\n        if (_4796)\n        {\n            _4802 = _6033 > 0.0f;\n        }\n        else\n        {\n            _4802 = _4796;\n        }\n        if (_4802)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _4771.direction;\n            float _4821 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _6034 = _4821;\n            _6032 *= _4821;\n        }\n    }\n    bool _4831 = _468_fa_ct_a.x > 0.5f;\n    bool _4837;\n    if (_4831)\n    {\n        _4837 = _6033 > 0.0f;\n    }\n    else\n    {\n        _4837 = _4831;\n    }\n    if (_4837)\n    {\n        float _4844;\n        if (_4774)\n        {\n            _4844 = 1000000000.0f;\n        }\n        else\n        {\n            _4844 = _4771._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _4771.direction;\n        float param_18 = _4844;\n        float _4862 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6034 *= _4862;\n        _6032 *= _4862;\n    }\n    float _4875 = _6033;\n    float _4876 = _4875 * _4745;\n    _6033 = _4876;\n    float3 _4880 = _6032;\n    float3 _4881 = _4880 * _4745;\n    _6032 = _4881;\n    LightSample _6049 = { _4771.direction, _4881, _4876, _6034, _4771._distance, _4771.type };\n    return _6049;\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _4892 = n < 0;\n    bool _4899;\n    if (!_4892)\n    {\n        _4899 = n >= fa_light_count();\n    }\n    else\n    {\n        _4899 = _4892;\n    }\n    if (_4899)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    LightSample _4914 = fa_light_shadowed(param_1, param_2, param_3);\n    return _4914;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3810 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3818 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3821 = int(_3810);\n    int _3824 = int(_3818);\n    float _3834 = _3818 - float(_3824);\n    int _3890 = (_3821 * 9) + _3824;\n    int _3910 = ((_3821 + 1) * 9) + _3824;\n    return lerp(lerp(_3885[_3890], _3885[_3890 + 1], _3834), lerp(_3885[_3910], _3885[_3910 + 1], _3834), _3810 - float(_3821));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _5898 = false;\n    float _5899 = 1.0f;\n    float _5900 = 1.0f;\n    float _5901 = 1.0f;\n    float _5902 = 0.0f;\n    float _5903 = 0.0f;\n    float _5904 = 0.0f;\n    float _5905 = 0.0f;\n    float _5907 = 1.0f;\n    bool _5908 = false;\n    float3 _5909 = 0.0f.xxx;\n    float _5910 = 1.0f;\n    float _5911 = 1.0f;\n    float _5912 = 1.0f;\n    float _5913 = 0.0f;\n    float _5914 = 0.0f;\n    float3 _5915 = float3(1.0f, 0.0f, 0.0f);\n    float3 _5916 = float3(0.0f, 0.0f, 1.0f);\n    float _5917 = 1.0f;\n    float _5918 = 1.0f;\n    float _3961 = clamp(s.specular, 0.0f, 1.0f);\n    float _3965 = clamp(s.ior, 1.0f, 3.0f);\n    bool _3970 = (_3961 != 1.0f) || (_3965 != 1.5f);\n    bool _3979;\n    if (!_3970)\n    {\n        _3979 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _3979 = _3970;\n    }\n    if (_3979)\n    {\n        float _3987 = (_3965 - 1.0f) / (_3965 + 1.0f);\n        f0 = lerp(min((_3987 * _3987).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _3961, s.albedo, metallic.xxx);\n        _5899 = lerp(_3961, 1.0f, metallic);\n        _5898 = true;\n    }\n    float _4014 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_4014 > 0.0f)\n    {\n        float _4022 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _5902 = _4014;\n        _5903 = _4022;\n        float _4029 = _4022 * _4022;\n        _5904 = _4029;\n        _5905 = _4029 * _4029;\n        float _4041 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _5907 = _4041;\n        _5900 = 1.0f - (_4014 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _4041, 0.0f, 1.0f), 5.0f))));\n        _5898 = true;\n    }\n    float3 _4060 = max(s.sheen_color, 0.0f.xxx);\n    float _4069 = max(_4060.x, max(_4060.y, _4060.z));\n    if (_4069 > 0.0f)\n    {\n        float _4077 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _5908 = true;\n        _5909 = _4060;\n        _5910 = _4077;\n        _5911 = _4077 * _4077;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _4077;\n        float _4094 = fa_sheen_albedo(param, param_1);\n        _5913 = _4094;\n        _5912 = 1.0f - min(_4069 * _4094, 1.0f);\n        _5898 = true;\n    }\n    _5901 = _5900 * _5912;\n    float _4113 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_4113 != 0.0f)\n    {\n        float3 _4128 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _4128;\n        if (dot(_4128, _4128) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _4140 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_4140.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _4140.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _4140.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _4144 = t;\n        float3 _4145 = normalize(_4144);\n        t = _4145;\n        float3 _4170 = normalize((_4145 * cos(s.anisotropy_rotation)) + ((cross(n, _4145) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _5915 = _4170;\n        _5916 = cross(n, _4170);\n        float _4180 = roughness * roughness;\n        float _4186 = lerp(_4180, 1.0f, _4113 * _4113);\n        bool _4188 = _4113 > 0.0f;\n        _5917 = _4188 ? _4186 : _4180;\n        _5918 = _4188 ? _4180 : _4186;\n        _5914 = _4113;\n        _5898 = true;\n    }\n    FaLayers _5940 = { _5898, _5899, _5900, _5901, _5902, _5903, _5904, _5905, i.world_normal, _5907, _5908, _5909, _5910, _5911, _5912, _5913, _5914, _5915, _5916, _5917, _5918 };\n    return _5940;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3742 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3745 = _3742.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3745 * _3745, exp2((-9.27999973297119140625f) * ndv)) * _3745) + _3742.y)) + _3742.zw;\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3177 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3180 = _3177.x;\n    float _3182 = _3177.z;\n    float2 e = float2(_3180, _3182);\n    if (_3177.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3182)) * ((_3180 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3180)) * ((_3182 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3216_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3216_dummy_parameter)));\n}\n\nfloat3 fa_probe_level(float2 origin, float res, int lv, float2 e)\n{\n    float _3229;\n    if (lv == 0)\n    {\n        _3229 = 0.0f;\n    }\n    else\n    {\n        _3229 = res + 2.0f;\n    }\n    float _3239;\n    if (lv == 0)\n    {\n        _3239 = 0.0f;\n    }\n    else\n    {\n        _3239 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0f * float(lv - 1));\n    }\n    return fa_probe_atlas.SampleLevel(fa_env_smp, (((origin + float2(_3229, _3239)) + 1.0f.xx) + (((e * 0.5f) + 0.5f.xx) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0f).xyz;\n}\n\nfloat3 fa_probe_radiance(float2 origin, float res, float3 d, float rough)\n{\n    float _3285;\n    if (res > 64.5f)\n    {\n        _3285 = 5.0f;\n    }\n    else\n    {\n        _3285 = (res > 32.5f) ? 4.0f : 3.0f;\n    }\n    float _3300 = clamp(rough, 0.0f, 1.0f) * (_3285 - 1.0f);\n    int _3307 = int(min(floor(_3300), _3285 - 2.0f));\n    float _3312 = _3300 - float(_3307);\n    float3 param = d;\n    float2 _3316 = fa_oct_encode(param);\n    float2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3307;\n    float2 param_4 = _3316;\n    float3 _3326 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3312 < 0.00200000009499490261077880859375f)\n    {\n        return _3326;\n    }\n    float2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3307 + 1;\n    float2 param_8 = _3316;\n    return lerp(_3326, fa_probe_level(param_5, param_6, param_7, param_8), _3312.xxx);\n}\n\nfloat3 fa_probe_box_dir(float3 d, float4 posw, float4 bx, float4 by, float4 bz)\n{\n    if (posw.w < 0.5f)\n    {\n        return d;\n    }\n    float _3364 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3371 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3378 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3384 = dot(bx.xyz, d);\n    float _3388 = dot(by.xyz, d);\n    float _3392 = dot(bz.xyz, d);\n    float _3398;\n    if (_3384 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3398 = (1.0f - _3364) / _3384;\n    }\n    else\n    {\n        float _3412;\n        if (_3384 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3412 = ((-1.0f) - _3364) / _3384;\n        }\n        else\n        {\n            _3412 = 1000000015047466219876688855040.0f;\n        }\n        _3398 = _3412;\n    }\n    float tx = _3398;\n    float _3429;\n    if (_3388 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3429 = (1.0f - _3371) / _3388;\n    }\n    else\n    {\n        float _3442;\n        if (_3388 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3442 = ((-1.0f) - _3371) / _3388;\n        }\n        else\n        {\n            _3442 = 1000000015047466219876688855040.0f;\n        }\n        _3429 = _3442;\n    }\n    float ty = _3429;\n    float _3458;\n    if (_3392 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3458 = (1.0f - _3378) / _3392;\n    }\n    else\n    {\n        float _3471;\n        if (_3392 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3471 = ((-1.0f) - _3378) / _3392;\n        }\n        else\n        {\n            _3471 = 1000000015047466219876688855040.0f;\n        }\n        _3458 = _3471;\n    }\n    float _3483 = tx;\n    float _3486 = (_3483 > 0.0f) ? _3483 : 1000000015047466219876688855040.0f;\n    tx = _3486;\n    float _3487 = ty;\n    float _3490 = (_3487 > 0.0f) ? _3487 : 1000000015047466219876688855040.0f;\n    ty = _3490;\n    float _3500 = min(_3486, min(_3490, (_3458 > 0.0f) ? _3458 : 1000000015047466219876688855040.0f));\n    if (_3500 > 100000001504746621987668885504.0f)\n    {\n        return d;\n    }\n    float3 _3516 = (fa_world_pos + (d * _3500)) - posw.xyz;\n    float3 _3521;\n    if (dot(_3516, _3516) > 1.0000000133514319600180897396058e-10f)\n    {\n        _3521 = normalize(_3516);\n    }\n    else\n    {\n        _3521 = d;\n    }\n    return _3521;\n}\n\nfloat3 fa_probe_environment(float4 tile, float4 posw, float4 bx, float4 by, float4 bz, inout float3 d, float rough)\n{\n    float3 param = d;\n    float4 param_1 = posw;\n    float4 param_2 = bx;\n    float4 param_3 = by;\n    float4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    float2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    float3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _3567 = (1.0f - _468_fa_rpa_tile.w) - _468_fa_rpb_tile.w;\n    float3 outc = 0.0f.xxx;\n    if (_3567 > 0.0005000000237487256526947021484375f)\n    {\n        float3 base;\n        if (_468_fa_env_sky.w > 0.5f)\n        {\n            float2 param = _468_fa_atlas.zw;\n            float param_1 = 128.0f;\n            float3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3597 = rough * rough;\n            float _3628 = 0.60000002384185791015625f * _3597;\n            base = lerp(lerp(_468_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_468_fa_env_horizon.xyz, _468_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3597)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3628, 0.0500000007450580596923828125f + _3628, d.y).xxx), ((_468_fa_env_sky.xyz + _468_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3597 * 0.60000002384185791015625f).xxx);\n        }\n        outc = base * _3567;\n    }\n    if (_468_fa_rpa_tile.w > 0.0f)\n    {\n        float4 param_4 = _468_fa_rpa_tile;\n        float4 param_5 = _468_fa_rpa_pos;\n        float4 param_6 = _468_fa_rpa_bx;\n        float4 param_7 = _468_fa_rpa_by;\n        float4 param_8 = _468_fa_rpa_bz;\n        float3 param_9 = d;\n        float param_10 = rough;\n        float3 _3687 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3687 * _468_fa_rpa_tile.w);\n    }\n    if (_468_fa_rpb_tile.w > 0.0f)\n    {\n        float4 param_11 = _468_fa_rpb_tile;\n        float4 param_12 = _468_fa_rpb_pos;\n        float4 param_13 = _468_fa_rpb_bx;\n        float4 param_14 = _468_fa_rpb_by;\n        float4 param_15 = _468_fa_rpb_bz;\n        float3 param_16 = d;\n        float param_17 = rough;\n        float3 _3719 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_3719 * _468_fa_rpb_tile.w);\n    }\n    return outc;\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness, float occlusion)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _4221;\n        if (L.aniso >= 0.0f)\n        {\n            _4221 = L.b;\n        }\n        else\n        {\n            _4221 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_4221, v), _4221), (abs(L.aniso) * smoothstep(0.0f, 0.25f, roughness)).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4257 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _4257.x) + (L.f90.xxx * _4257.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _4315 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _4315.x) + _4315.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3784 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3784.x) + _3784.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _4354 = clamp(s.metallic, 0.0f, 1.0f);\n    float _4358 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _4365 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _4354.xxx);\n    float3 f0 = _4365;\n    float3 _4369 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _4369;\n    float3 param_3 = i.view_dir;\n    float param_4 = _4354;\n    float param_5 = _4358;\n    float3 param_6 = _4365;\n    FaLayers _4386 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4386.on)\n    {\n        FaLayers param_7 = _4386;\n        float3 param_8 = _4369;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _4358;\n        float param_12 = s.occlusion;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    float3 param_13 = _4369;\n    float3 param_14 = i.view_dir;\n    float3 param_15 = f0;\n    float param_16 = _4358;\n    return fa_sky_reflection(param_13, param_14, param_15, param_16) * s.occlusion;\n}\n\nfloat3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0f;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _4984 = fa_light_unshadowed(param, param_1);\n        float _4992 = dot(_4984.color, float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));\n        if (_4992 > bestPower)\n        {\n            bestPower = _4992;\n            best = n;\n        }\n    }\n    float3 lit = (_468_fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _5021 = fa_light(param_2, param_3);\n        float _5029;\n        if (dot(s.normal, _5021.direction) > 0.5f)\n        {\n            _5029 = 1.0f;\n        }\n        else\n        {\n            _5029 = _5035_dark;\n        }\n        lit += ((s.albedo * _5021.color) * _5029);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * _5035_skyAmount);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2121_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3075 = int(_2121_fa_shadow_cfg.x + 0.5f);\n    float _3085 = dot(world - _2121_fa_shadow_eye.xyz, _2121_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3090 = _3075 > 0;\n    bool _3099;\n    if (_3090)\n    {\n        int param = _3075 - 1;\n        _3099 = _3085 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3099 = _3090;\n    }\n    if (_3099)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3105 = _3075 > 1;\n        bool _3112;\n        if (_3105)\n        {\n            _3112 = _3085 > _2121_fa_shadow_split.x;\n        }\n        else\n        {\n            _3112 = _3105;\n        }\n        if (_3112)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3118 = _3075 > 2;\n        bool _3125;\n        if (_3118)\n        {\n            _3125 = _3085 > _2121_fa_shadow_split.y;\n        }\n        else\n        {\n            _3125 = _3118;\n        }\n        if (_3125)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3131 = _3075 > 3;\n        bool _3138;\n        if (_3131)\n        {\n            _3138 = _3085 > _2121_fa_shadow_split.z;\n        }\n        else\n        {\n            _3138 = _3131;\n        }\n        if (_3138)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _5752 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5752 = -_5752;\n    }\n    float3 _5422 = normalize(_468_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _5765 = { fa_world_pos, _5752, fa_world_tangent, fa_uv, fa_vertex_color, _5422, gl_FrontFacing };\n    SurfaceInput param_1 = _5765;\n    Surface _5430 = fa_standard_surface(param_1);\n    float3 _5783 = _5430.albedo;\n    float _5784 = _5430.alpha;\n    float3 _5785 = _5430.normal;\n    float _5786 = _5430.metallic;\n    float _5787 = _5430.roughness;\n    float _5788 = _5430.occlusion;\n    float3 _5789 = _5430.emission;\n    float _5790 = _5430.clearcoat;\n    float _5791 = _5430.clearcoat_roughness;\n    float3 _5792 = _5430.sheen_color;\n    float _5793 = _5430.sheen_roughness;\n    float _5794 = _5430.anisotropy;\n    float _5795 = _5430.anisotropy_rotation;\n    float _5796 = _5430.specular;\n    float _5797 = _5430.ior;\n    float3 _5798 = _5430.specular_color;\n    float _5799 = _5430.transmission;\n    float _5800 = _5430.thickness;\n    float3 _5801 = _5430.attenuation_color;\n    float _5802 = _5430.attenuation_distance;\n    SurfaceInput _5773 = { fa_world_pos, _5752, fa_world_tangent, fa_uv, fa_vertex_color, _5422, gl_FrontFacing };\n    SurfaceInput param_2 = _5773;\n    Surface param_3 = _5430;\n    surface(param_2, param_3);\n    _5783 = param_3.albedo;\n    _5784 = param_3.alpha;\n    _5785 = param_3.normal;\n    _5786 = param_3.metallic;\n    _5787 = param_3.roughness;\n    _5788 = param_3.occlusion;\n    _5789 = param_3.emission;\n    _5790 = param_3.clearcoat;\n    _5791 = param_3.clearcoat_roughness;\n    _5792 = param_3.sheen_color;\n    _5793 = param_3.sheen_roughness;\n    _5794 = param_3.anisotropy;\n    _5795 = param_3.anisotropy_rotation;\n    _5796 = param_3.specular;\n    _5797 = param_3.ior;\n    _5798 = param_3.specular_color;\n    _5799 = param_3.transmission;\n    _5800 = param_3.thickness;\n    _5801 = param_3.attenuation_color;\n    _5802 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _5752;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5783 = param_6;\n    _5785 = param_7;\n    float3 result;\n    if (_468_fa_emissive.w > 0.5f)\n    {\n        result = _5783;\n    }\n    else\n    {\n        float3 _5469 = _5785;\n        float3 _5470 = normalize(_5469);\n        _5785 = _5470;\n        SurfaceInput _5781 = { fa_world_pos, _5752, fa_world_tangent, fa_uv, fa_vertex_color, _5422, gl_FrontFacing };\n        SurfaceInput param_8 = _5781;\n        Surface _5884 = { _5783, _5784, _5470, _5786, _5787, _5788, _5789, _5790, _5791, _5792, _5793, _5794, _5795, _5796, _5797, _5798, _5799, _5800, _5801, _5802 };\n        Surface param_9 = _5884;\n        float3 _5481 = lighting(param_8, param_9);\n        result = _5481;\n    }\n    float3 _5485 = result;\n    float3 _5486 = _5485 + _5789;\n    result = _5486;\n    float3 param_10 = _5486;\n    float3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _5495 = _468_fa_fog.w > 0.0f;\n    bool _5502;\n    if (!_5495)\n    {\n        _5502 = _468_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _5502 = _5495;\n    }\n    if (_5502)\n    {\n        float3 _5511 = fa_world_pos - _468_fa_camera_pos.xyz;\n        float _5517 = dot(_5511, _468_fa_fog_c.xyz);\n        bool _5521 = _468_fa_fog_c.w > 0.5f;\n        float _5522;\n        if (_5521)\n        {\n            _5522 = _5517;\n        }\n        else\n        {\n            _5522 = length(_5511);\n        }\n        float _5534 = _5522 - _468_fa_fog_b.x;\n        if (_5534 > 0.0f)\n        {\n            float _5543 = _468_fa_fog.w * _5534;\n            float tau = _5543 * _5543;\n            if (_468_fa_fog_b.y > 0.0f)\n            {\n                float _5559;\n                if (_5521)\n                {\n                    _5559 = fa_world_pos.y - (_468_fa_fog_c.y * _5517);\n                }\n                else\n                {\n                    _5559 = _468_fa_camera_pos.y;\n                }\n                float _5580 = lerp(_5559, fa_world_pos.y, clamp(_468_fa_fog_b.x / _5522, 0.0f, 1.0f));\n                float _5584 = fa_world_pos.y - _5580;\n                float _5589 = _5580 - _468_fa_fog_b.z;\n                float _5594 = fa_world_pos.y - _468_fa_fog_b.z;\n                bool _5597 = _5589 <= 0.0f;\n                bool _5598 = !_5597;\n                bool _5604;\n                if (_5598)\n                {\n                    _5604 = _468_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5604 = _5597;\n                }\n                float _5605;\n                if (_5604)\n                {\n                    _5605 = _468_fa_fog_b.y;\n                }\n                else\n                {\n                    _5605 = _468_fa_fog_b.y * exp(-min(_468_fa_fog_b.w * _5589, 80.0f));\n                }\n                bool _5632;\n                if (_5598)\n                {\n                    _5632 = _468_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5632 = _5597;\n                }\n                float _5633;\n                if (_5632)\n                {\n                    _5633 = _468_fa_fog_b.y * _5589;\n                }\n                else\n                {\n                    _5633 = (_468_fa_fog_b.y * (1.0f - exp(-min(_468_fa_fog_b.w * _5589, 80.0f)))) / _468_fa_fog_b.w;\n                }\n                bool _5658 = _5594 <= 0.0f;\n                bool _5665;\n                if (!_5658)\n                {\n                    _5665 = _468_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5665 = _5658;\n                }\n                float _5666;\n                if (_5665)\n                {\n                    _5666 = _468_fa_fog_b.y * _5594;\n                }\n                else\n                {\n                    _5666 = (_468_fa_fog_b.y * (1.0f - exp(-min(_468_fa_fog_b.w * _5594, 80.0f)))) / _468_fa_fog_b.w;\n                }\n                float _5693;\n                if (abs(_5584) < 0.001000000047497451305389404296875f)\n                {\n                    _5693 = _5605;\n                }\n                else\n                {\n                    _5693 = (_5666 - _5633) / _5584;\n                }\n                tau += (_5534 * max(_5693, 0.0f));\n            }\n            result = lerp(result, _468_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _5784);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_5035",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _3885[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\nstatic const LightSample _6312 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, 0 };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _468_fa_camera_pos : packoffset(c0);\n    float4 _468_fa_ambient : packoffset(c1);\n    float4 _468_fa_base_color : packoffset(c2);\n    float4 _468_fa_emissive : packoffset(c3);\n    float4 _468_fa_model_emissive : packoffset(c4);\n    float4 _468_fa_pbr : packoffset(c5);\n    float4 _468_fa_maps : packoffset(c6);\n    float4 _468_fa_fog : packoffset(c7);\n    float4 _468_fa_fog_b : packoffset(c8);\n    float4 _468_fa_fog_c : packoffset(c9);\n    float4 _468_fa_counts : packoffset(c10);\n    float4 _468_fa_env_sky : packoffset(c11);\n    float4 _468_fa_env_horizon : packoffset(c12);\n    float4 _468_fa_time : packoffset(c13);\n    float4 _468_fa_cl_vpx : packoffset(c14);\n    float4 _468_fa_cl_vpy : packoffset(c15);\n    float4 _468_fa_cl_vpw : packoffset(c16);\n    float4 _468_fa_cl_fwd : packoffset(c17);\n    float4 _468_fa_cl_grid : packoffset(c18);\n    float4 _468_fa_cl_info : packoffset(c19);\n    float4 _468_fa_layers_a : packoffset(c20);\n    float4 _468_fa_layers_b : packoffset(c21);\n    float4 _468_fa_layers_c : packoffset(c22);\n    float4 _468_fa_layers_d : packoffset(c23);\n    float4 _468_fa_ct_a : packoffset(c24);\n    float4 _468_fa_ct_b : packoffset(c25);\n    float4 _468_fa_ct_vpx : packoffset(c26);\n    float4 _468_fa_ct_vpy : packoffset(c27);\n    float4 _468_fa_ct_vpw : packoffset(c28);\n    float4 _468_fa_ct_fwd : packoffset(c29);\n    float4 _468_fa_tr_a : packoffset(c30);\n    float4 _468_fa_tr_b : packoffset(c31);\n    float4 _468_fa_probe_sh[9] : packoffset(c32);\n    float4 _468_fa_atlas : packoffset(c41);\n    float4 _468_fa_rpa_tile : packoffset(c42);\n    float4 _468_fa_rpa_pos : packoffset(c43);\n    float4 _468_fa_rpa_bx : packoffset(c44);\n    float4 _468_fa_rpa_by : packoffset(c45);\n    float4 _468_fa_rpa_bz : packoffset(c46);\n    float4 _468_fa_rpb_tile : packoffset(c47);\n    float4 _468_fa_rpb_pos : packoffset(c48);\n    float4 _468_fa_rpb_bx : packoffset(c49);\n    float4 _468_fa_rpb_by : packoffset(c50);\n    float4 _468_fa_rpb_bz : packoffset(c51);\n    float4 _468_fa_gi : packoffset(c52);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2121_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2121_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2121_fa_shadow_info[4] : packoffset(c20);\n    float4 _2121_fa_shadow_split : packoffset(c24);\n    float4 _2121_fa_shadow_cfg : packoffset(c25);\n    float4 _2121_fa_shadow_bias : packoffset(c26);\n    float4 _2121_fa_shadow_eye : packoffset(c27);\n    float4 _2121_fa_shadow_fwd : packoffset(c28);\n    float4 _2121_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _5035_dark : packoffset(c0);\n    float _5035_fa_pad0 : packoffset(c0.y);\n    float _5035_fa_pad1 : packoffset(c0.z);\n    float _5035_fa_pad2 : packoffset(c0.w);\n    float _5035_skyAmount : packoffset(c1);\n    float _5035_fa_pad3 : packoffset(c1.y);\n    float _5035_fa_pad4 : packoffset(c1.z);\n    float _5035_fa_pad5 : packoffset(c1.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t9);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_probe_atlas : register(t6);\nTexture2D<float4> fa_screen_tex : register(t10);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1397 = _468_fa_cl_info.x < 0.0f;\n    bool _1404;\n    if (!_1397)\n    {\n        _1404 = _468_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1404 = _1397;\n    }\n    bool _1412;\n    if (!_1404)\n    {\n        _1412 = _468_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1412 = _1404;\n    }\n    bool _1419;\n    if (!_1412)\n    {\n        _1419 = _468_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1419 = _1412;\n    }\n    bool _1426;\n    if (!_1419)\n    {\n        _1426 = _468_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1426 = _1419;\n    }\n    if (_1426)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1436 = float4(world_pos, 1.0f);\n    float _1442 = dot(_468_fa_cl_vpw, _1436);\n    if (!(_1442 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1464 = float2(dot(_468_fa_cl_vpx, _1436), dot(_468_fa_cl_vpy, _1436)) / _1442.xx;\n    int _1468 = int(_468_fa_cl_grid.x);\n    int _1472 = int(_468_fa_cl_grid.y);\n    int param = (int(_468_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_468_fa_cl_fwd.xyz, world_pos) + _468_fa_cl_fwd.w, _468_fa_cl_grid.w) / _468_fa_cl_grid.w) * _468_fa_cl_grid.z)), 0, int(_468_fa_cl_info.y) - 1) * _1472) + clamp(int(floor(((_1464.y * 0.5f) + 0.5f) * _468_fa_cl_grid.y)), 0, _1472 - 1)) * _1468)) + clamp(int(floor(((_1464.x * 0.5f) + 0.5f) * _468_fa_cl_grid.x)), 0, _1468 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1548 = fa_cluster_texel(param);\n    return int2(int(_1548.x), int(_1548.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_468_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4719 = fa_cluster_lookup(param);\n    fa_cl_slot = _4719.x;\n    fa_cl_local = _4719.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _5096 = fa_linear_to_srgb(param);\n        c = _5096;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _5104 = fa_srgb_to_linear(param_1);\n            c = _5104;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _348;\n    if (i.front_facing)\n    {\n        _348 = i.world_normal;\n    }\n    else\n    {\n        _348 = -i.world_normal;\n    }\n    float3 _372 = normalize(i.world_tangent.xyz - (_348 * dot(_348, i.world_tangent.xyz)));\n    float3 _400 = normalize(((_372 * m.x) + ((cross(_348, _372) * i.world_tangent.w) * m.y)) + (_348 * m.z));\n    float3 _403;\n    if (i.front_facing)\n    {\n        _403 = _400;\n    }\n    else\n    {\n        _403 = -_400;\n    }\n    return _403;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _468_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _5135 = fa_tex_fix(param_2, param_3);\n    float4 _6274 = base_t;\n    _6274.x = _5135.x;\n    _6274.y = _5135.y;\n    _6274.z = _5135.z;\n    base_t = _6274;\n    float4 _5149 = (_6274 * _468_fa_base_color) * i.vertex_color;\n    float3 _6080 = i.world_normal;\n    if (_468_fa_maps.z > 0.5f)\n    {\n        float param_4 = _468_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _5181 = fa_tex_fix(param_6, param_7);\n        float3 _5184 = (_5181 * 2.0f) - 1.0f.xxx;\n        float2 _5189 = _5184.xy * _468_fa_maps.x;\n        float3 _6282 = _5184;\n        _6282.x = _5189.x;\n        _6282.y = _5189.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _6282;\n        _6080 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _468_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _5217 = fa_tex_fix(param_12, param_13);\n    float4 _6285 = mrt;\n    _6285.x = _5217.x;\n    _6285.y = _5217.y;\n    _6285.z = _5217.z;\n    mrt = _6285;\n    float4 _5245 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _468_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _5245.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _5256 = fa_tex_fix(param_16, param_17);\n    float param_18 = _468_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _5286 = fa_tex_fix(param_20, param_21);\n    float _6085 = _468_fa_layers_a.x;\n    float _6086 = _468_fa_layers_a.y;\n    float _6089 = _468_fa_layers_a.z;\n    float _6088 = _468_fa_layers_b.w;\n    float _6091 = _468_fa_layers_c.x;\n    if (_468_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_468_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _6085 *= _5256.y;\n            _6086 *= _5256.z;\n            _6088 *= _5245.w;\n        }\n        if (_468_fa_layers_c.z > 1.5f)\n        {\n            _6089 *= mrt.x;\n            _6091 *= mrt.w;\n        }\n    }\n    Surface _6118 = { _5149.xyz, _5149.w, _6080, clamp(_468_fa_pbr.x * _5217.z, 0.0f, 1.0f), clamp(_468_fa_pbr.y * _5217.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_468_fa_maps.y * (_5256.x - 1.0f)), _468_fa_emissive.xyz + (_468_fa_model_emissive.xyz * _5286), _6085, _6086, _468_fa_layers_b.xyz, _6088, _6089, _468_fa_layers_a.w, _6091, _468_fa_layers_c.y, _468_fa_layers_d.xyz, _468_fa_tr_a.x, _468_fa_tr_a.y, _468_fa_tr_b.xyz, _468_fa_tr_a.z };\n    return _6118;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1628 = rect.zw - rect.xy;\n    float2 _1632 = _1628 * atlas;\n    float2 _1636 = ddx * _1632;\n    float2 _1640 = ddy * _1632;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1628), clamp(0.5f * log2(max(max(dot(_1636, _1636), dot(_1640, _1640)), 9.9999999392252902907785028219223e-09f)), 0.0f, 3.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1673 = _468_fa_counts.y < 0.5f;\n    bool _1680;\n    if (!_1673)\n    {\n        _1680 = _468_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1680 = _1673;\n    }\n    if (_1680)\n    {\n        return;\n    }\n    float3 _1686 = ddx(world_pos);\n    float3 _1689 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1693 = fa_cluster_texel(param);\n    int _1697 = int(_1693.w);\n    if (_1697 < 1)\n    {\n        return;\n    }\n    int _1707 = int(_468_fa_counts.y + 0.5f);\n    int param_1 = _1707;\n    float4 _1711 = fa_light_texel(param_1);\n    float2 _1714 = _1711.yz;\n    int _1718 = int(_1711.w);\n    int param_2 = _1707 + 1;\n    float4 _1723 = fa_light_texel(param_2);\n    float _1724 = _1723.x;\n    int _1730 = int(_468_fa_counts.w + 0.5f) - 1;\n    int _1734 = int(_1693.z);\n    float3 _1999;\n    for (int k = 0; k < _1697; k++)\n    {\n        int _1747 = _1734 + k;\n        int param_3 = _1718 + (_1747 >> 2);\n        int _1764 = (_1707 + 2) + (int(fa_light_texel(param_3)[_1747 & 3]) * 7);\n        int param_4 = _1764 + 6;\n        float4 _1769 = fa_light_texel(param_4);\n        if (((int(_1769.w + 0.5f) >> _1730) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1764;\n        float4 _1784 = fa_light_texel(param_5);\n        int param_6 = _1764 + 1;\n        float4 _1789 = fa_light_texel(param_6);\n        int param_7 = _1764 + 2;\n        float4 _1794 = fa_light_texel(param_7);\n        float3 _1797 = _1784.xyz;\n        float _1802 = dot(_1797, world_pos) + _1784.w;\n        float3 _1804 = _1789.xyz;\n        float _1809 = dot(_1804, world_pos) + _1789.w;\n        float3 _1811 = _1794.xyz;\n        float _1816 = dot(_1811, world_pos) + _1794.w;\n        bool _1821 = abs(_1802) > 0.5f;\n        bool _1829;\n        if (!_1821)\n        {\n            _1829 = abs(_1809) > 0.5f;\n        }\n        else\n        {\n            _1829 = _1821;\n        }\n        bool _1837;\n        if (!_1829)\n        {\n            _1837 = abs(_1816) > 0.5f;\n        }\n        else\n        {\n            _1837 = _1829;\n        }\n        if (_1837)\n        {\n            continue;\n        }\n        float _1852 = clamp(dot(geo_normal, normalize(_1811)) * _1769.z, 0.0f, 1.0f);\n        if (_1852 <= 0.0f)\n        {\n            continue;\n        }\n        float _1872 = (clamp((0.5f - abs(_1816)) * 10.0f, 0.0f, 1.0f) * _1852) * _1769.x;\n        float2 _1880 = float2(_1802 + 0.5f, 0.5f - _1809);\n        float2 _1890 = float2(dot(_1797, _1686), dot(_1804, _1686));\n        float2 _1900 = float2(dot(_1797, _1689), dot(_1804, _1689));\n        int param_8 = _1764 + 5;\n        float4 _1905 = fa_light_texel(param_8);\n        int param_9 = _1764 + 3;\n        float4 _1910 = fa_light_texel(param_9);\n        int param_10 = _1764 + 4;\n        float4 _1915 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1905.xyz;\n        bool _1925 = _1910.z > _1910.x;\n        if (_1925)\n        {\n            float4 param_11 = _1910;\n            float2 param_12 = _1880;\n            float2 param_13 = _1714;\n            float2 param_14 = _1890;\n            float2 param_15 = _1900;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1724 > 0.5f) && (_1724 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1951 = fa_dc_to_linear(param_16);\n                float4 _6168 = tx;\n                _6168.x = _1951.x;\n                _6168.y = _1951.y;\n                _6168.z = _1951.z;\n                tx = _6168;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1872 * tex_a) * _1905.w, 0.0f, 1.0f).xxx);\n        if (_1915.z > _1915.x)\n        {\n            float4 param_17 = _1915;\n            float2 param_18 = _1880;\n            float2 param_19 = _1714;\n            float2 param_20 = _1890;\n            float2 param_21 = _1900;\n            float4 _1995 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1724 > 1.5f)\n            {\n                float3 param_22 = _1995.xyz;\n                float3 _2005 = fa_dc_to_srgb(param_22);\n                _1999 = _2005;\n            }\n            else\n            {\n                _1999 = _1995.xyz;\n            }\n            float3 _2014 = (_1999 * 2.0f) - 1.0f.xxx;\n            float2 _2019 = _2014.xy * _1769.y;\n            float3 _2041 = (normalize(_1797) * _2019.x) + (normalize(_1804) * _2019.y);\n            float3 _2044 = normalize(normal);\n            normal = normalize(lerp(_2044, normalize((_2044 * max(_2014.z, 0.0500000007450580596923828125f)) + (_2041 - (_2044 * dot(_2044, _2041)))), clamp(_1872 * (_1925 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return _6312;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_468_fa_cl_info.x) + int(_468_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_468_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4689;\n    if (fa_lm.z > 0.5f)\n    {\n        _4689 = 0.0f;\n    }\n    else\n    {\n        _4689 = 1.0f - clamp(_468_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _4700 = _4689 < 1.0f;\n    bool _4706;\n    if (_4700)\n    {\n        int param = li;\n        _4706 = fa_light_baked(param);\n    }\n    else\n    {\n        _4706 = _4700;\n    }\n    return _4706 ? _4689 : 1.0f;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _646 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _659 = (c - (ru * hx)) - p;\n        float3 _665 = ru * (2.0f * hx);\n        float _671 = max(dot(_665, _665), 9.9999999392252902907785028219223e-09f);\n        float _675 = dot(_659, _665);\n        float t = clamp((-_675) / _671, 0.0f, 1.0f);\n        if (_646)\n        {\n            float _690 = dot(r, _665);\n            float _696 = _671 - (_690 * _690);\n            if (abs(_696) > (9.9999997473787516355514526367188e-06f * _671))\n            {\n                t = clamp(((dot(r, _659) * _690) - _675) / _696, 0.0f, 1.0f);\n            }\n        }\n        return (p + _659) + (_665 * t);\n    }\n    float3 q = p;\n    float _728 = dot(r, axis);\n    bool _736;\n    if (_646)\n    {\n        _736 = abs(_728) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _736 = _646;\n    }\n    if (_736)\n    {\n        float _746 = dot(c - p, axis) / _728;\n        if (_746 > 0.0f)\n        {\n            q = p + (r * _746);\n        }\n    }\n    float3 _759 = q - c;\n    float2 xy = float2(dot(_759, ru), dot(_759, uu));\n    if (shape > 0.5f)\n    {\n        float _774 = length(xy);\n        if (_774 > hx)\n        {\n            xy *= (hx / _774);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _527_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _527_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _566 = dot(d, right);\n    float _570 = dot(d, up);\n    float _581;\n    if (((_566 * _566) + (_570 * _570)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _581 = atan2(_570, _566) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _581 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_581 - floor(_581)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _415 = abs(d);\n    float _417 = _415.x;\n    float _419 = _415.y;\n    bool _420 = _417 >= _419;\n    bool _428;\n    if (_420)\n    {\n        _428 = _417 >= _415.z;\n    }\n    else\n    {\n        _428 = _420;\n    }\n    int _429;\n    if (_428)\n    {\n        _429 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _444;\n        if (_419 >= _415.z)\n        {\n            _444 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _444 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _429 = _444;\n    }\n    return _429;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _812 = fa_light_base(param);\n    bool _816 = _468_fa_ambient.w > 4.5f;\n    int param_1 = _812;\n    float4 _820 = fa_light_texel(param_1);\n    int param_2 = _812 + 1;\n    float4 _825 = fa_light_texel(param_2);\n    float _828 = _825.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _840 = _816 && (_828 > 2.5f);\n    fa_light_is_area = _840;\n    bool _842 = _828 < 0.5f;\n    float3 l;\n    if (_842)\n    {\n        l = normalize(_820.xyz);\n        if (_816)\n        {\n            int param_3 = _812 + 6;\n            float4 _856 = fa_light_texel(param_3);\n            if (_856.z > 0.5f)\n            {\n                int param_4 = _812 + 4;\n                float4 _866 = fa_light_texel(param_4);\n                int param_5 = _812 + 5;\n                float4 _871 = fa_light_texel(param_5);\n                float2 param_6 = _856.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _866.xyz) * _866.w, (-dot(world_pos, _871.xyz)) * _871.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _901 = _820.xyz;\n        float3 _903 = _901 - world_pos;\n        float3 to_light = _903;\n        float _906 = length(_903);\n        float reach = _906;\n        bool front = true;\n        if (_840)\n        {\n            int param_8 = _812 + 7;\n            reach = max(_906 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _812 + 4;\n            float4 _930 = fa_light_texel(param_9);\n            int param_10 = _812 + 5;\n            float4 _935 = fa_light_texel(param_10);\n            int param_11 = _812 + 6;\n            float4 _940 = fa_light_texel(param_11);\n            float _941 = _940.w;\n            int param_12 = _812 + 2;\n            float3 _948 = normalize(fa_light_texel(param_12).xyz);\n            bool _950 = _941 > 1.5f;\n            bool _958;\n            if (!_950)\n            {\n                _958 = dot(_948, to_light) < 0.0f;\n            }\n            else\n            {\n                _958 = _950;\n            }\n            front = _958;\n            float3 r = 0.0f.xxx;\n            float3 _967 = _468_fa_camera_pos.xyz - world_pos;\n            bool _971 = dot(n, n) > 0.5f;\n            bool _979;\n            if (_971)\n            {\n                _979 = dot(_967, _967) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _979 = _971;\n            }\n            if (_979)\n            {\n                r = reflect(-normalize(_967), normalize(n));\n            }\n            float3 param_13 = _901;\n            float3 param_14 = _948;\n            float3 param_15 = _930.xyz;\n            float3 param_16 = _935.xyz;\n            float param_17 = _930.w;\n            float param_18 = _935.w;\n            float param_19 = _941;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1015 = length(to_light);\n        dist = _1015;\n        l = to_light / max(_1015, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1029 = reach / max(_820.w, 0.001000000047497451305389404296875f);\n        float _1035 = clamp(1.0f - (_1029 * _1029), 0.0f, 1.0f);\n        float _1037;\n        if (front)\n        {\n            _1037 = _1035 * _1035;\n        }\n        else\n        {\n            _1037 = 0.0f;\n        }\n        atten = _1037;\n        bool _1048 = _828 < 2.5f;\n        if ((_828 > 1.5f) && _1048)\n        {\n            int param_22 = _812 + 2;\n            float4 _1056 = fa_light_texel(param_22);\n            float _1066 = _1056.w;\n            int param_23 = _812 + 3;\n            float4 _1071 = fa_light_texel(param_23);\n            float _1072 = _1071.x;\n            float cos_inner = _1072;\n            if (_1072 > 1.5f)\n            {\n                cos_inner = lerp(_1066, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1066, cos_inner, dot(-l, normalize(_1056.xyz)));\n        }\n        if (_816 && (_828 < 1.5f))\n        {\n            int param_24 = _812 + 6;\n            float4 _1096 = fa_light_texel(param_24);\n            if (_1096.z > 0.5f)\n            {\n                float3 _1104 = -to_light;\n                int param_25 = _812 + 4;\n                int param_26 = _812 + 5;\n                float3 _1118 = fa_light_texel(param_25).xyz;\n                float3 _1122 = fa_light_texel(param_26).xyz;\n                float3 _1131 = float3(dot(_1104, _1118), dot(_1104, _1122), dot(_1104, cross(_1118, _1122)));\n                float3 param_27 = _1131;\n                int _1135 = fa_cube_face(param_27);\n                int param_28 = _1135;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1162 = float2(dot(_1131, cross(param_29, param_30)), dot(_1131, param_30)) / max(dot(_1131, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1166 = _1135 / 3;\n                float2 param_31 = _1096.xy + (float2(float(_1135 - (_1166 * 3)), float(_1166)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1162.x), 0.5f - (0.5f * _1162.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _812 + 7;\n            float4 _1196 = fa_light_texel(param_33);\n            if (_1196.z > 0.5f)\n            {\n                int param_34 = _812 + 2;\n                int param_35 = _812 + 4;\n                int param_36 = _812 + 5;\n                float2 param_37 = _1196.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_816 && _1048)\n            {\n                int param_42 = _812 + 6;\n                float4 _1243 = fa_light_texel(param_42);\n                int param_43 = _812 + 7;\n                float4 _1248 = fa_light_texel(param_43);\n                bool _1251 = _1243.z > 0.5f;\n                bool _1258;\n                if (!_1251)\n                {\n                    _1258 = _1248.z > 0.5f;\n                }\n                else\n                {\n                    _1258 = _1251;\n                }\n                if (_1258)\n                {\n                    int param_44 = _812 + 2;\n                    float4 _1265 = fa_light_texel(param_44);\n                    float3 _1269 = normalize(_1265.xyz);\n                    int param_45 = _812 + 4;\n                    float4 _1274 = fa_light_texel(param_45);\n                    int param_46 = _812 + 5;\n                    float4 _1279 = fa_light_texel(param_46);\n                    if (_1251)\n                    {\n                        float3 _1287 = -to_light;\n                        float _1294 = _1265.w;\n                        float _1310 = 0.5f / max(dot(_1287, _1269) * (sqrt(max(1.0f - (_1294 * _1294), 0.0f)) / max(_1294, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1243.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1287, _1274.xyz) * _1310), 0.5f - (dot(_1287, _1279.xyz) * _1310));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1248.z > 0.5f)\n                    {\n                        float2 param_49 = _1248.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1269;\n                        float3 param_52 = _1274.xyz;\n                        float3 param_53 = _1279.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _5886 = _825.xyz * atten;\n    if (_816)\n    {\n        _5886 *= fa_light_tint;\n    }\n    int _1379;\n    if (_842)\n    {\n        _1379 = 0;\n    }\n    else\n    {\n        _1379 = ((_828 > 1.5f) && (_828 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _5897 = { l, _5886, atten, 1.0f, dist, _1379 };\n    return _5897;\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _4918 = n < 0;\n    bool _4925;\n    if (!_4918)\n    {\n        _4925 = n >= fa_light_count();\n    }\n    else\n    {\n        _4925 = _4918;\n    }\n    if (_4925)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _4933 = fa_cl_light(param);\n    int param_1 = _4933;\n    float _4937 = fa_baked_keep(param_1);\n    if (_4937 <= 0.0f)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _4933;\n    float3 param_3 = i.world_pos;\n    float3 param_4 = i.world_normal;\n    LightSample _4953 = fa_light_sample_n(param_2, param_3, param_4);\n    LightSample _6068 = { _4953.direction, _4953.color * _4937, _4953.attenuation * _4937, _4953.shadow, _4953._distance, _4953.type };\n    return _6068;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2168 = fa_shadow_depth(param, param_1);\n    float _2172;\n    if (conv.x < 0.5f)\n    {\n        _2172 = _2168;\n    }\n    else\n    {\n        _2172 = (conv.y * conv.z) / (conv.z - (_2168 * (conv.z - conv.y)));\n    }\n    return _2172;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel_turn(float2 d)\n{\n    return float2((d.x * (-0.737368881702423095703125f)) - (d.y * 0.675490319728851318359375f), (d.y * (-0.737368881702423095703125f)) + (d.x * 0.675490319728851318359375f));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2218 = fa_shadow_noise() * 6.283185482025146484375f;\n    float2 _2224 = float2(cos(_2218), sin(_2218));\n    float2 dir = _2224;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2233;\n        if (k < 0.0f)\n        {\n            _2233 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2233 = k;\n        }\n        float _2252 = clamp((_2233 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2271 = sqrt((float(i) + 0.5f) * 0.0625f) * _2252;\n            float2 param_3 = uv + (dir * (_2121_fa_shadow_bias.zw * _2271));\n            float4 param_4 = rect;\n            float3 param_5 = conv;\n            float _2285 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2285 < (zr - (_2271 * plane)))\n            {\n                sum += _2285;\n                cnt += 1.0f;\n            }\n            float2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2313 = sum / cnt;\n        float _2323;\n        if (k < 0.0f)\n        {\n            _2323 = (-k) / max(_2313, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2323 = k;\n        }\n        radius = clamp(((max(zr - _2313, 0.0f) * unit) * _2323) / texel_m, 1.5f, 16.0f);\n        dir = _2224;\n    }\n    float lit = 0.0f;\n    int _2349 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2349; i_1++)\n    {\n        float _2368 = sqrt((float(i_1) + 0.5f) / float(_2349)) * radius;\n        float2 param_7 = uv + (dir * (_2121_fa_shadow_bias.zw * _2368));\n        float4 param_8 = rect;\n        float3 param_9 = conv;\n        lit += float((zr - (_2368 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        float2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2349);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2573 = _468_fa_pbr.z < 0.5f;\n    bool _2580;\n    if (!_2573)\n    {\n        _2580 = _2121_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2580 = _2573;\n    }\n    if (_2580)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2121_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2593 = fa_light_texel(param);\n    float _2594 = _2593.x;\n    if (_2594 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2603 = int(_2594 + 0.5f);\n    int param_1 = _2603;\n    float4 _2607 = fa_light_texel(param_1);\n    int param_2 = _2603 + 1;\n    float4 _2612 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2615 = _2607.y;\n    if (_2615 > 0.0f)\n    {\n        float _2632 = 1.0f - smoothstep(0.75f * _2615, _2615, length(world - _2121_fa_shadow_eye.xyz));\n        fade = _2632;\n        if (_2632 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2607.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2656 = (_2603 + 2) + (face * 6);\n    int param_4 = _2656;\n    int param_5 = _2656 + 1;\n    int param_6 = _2656 + 3;\n    float4 _2670 = fa_light_texel(param_6);\n    int param_7 = _2656 + 4;\n    float4 _2675 = fa_light_texel(param_7);\n    int param_8 = _2656 + 5;\n    float4 _2680 = fa_light_texel(param_8);\n    float _2692 = _2680.x * max(dot(_2670, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2697 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2720 = clamp(dot(n, _2670.xyz), -1.0f, 1.0f);\n    float _2739 = min(sqrt(1.0f - (_2720 * _2720)) / max(abs(dot(n, world - lpos)) / max(dot(_2670, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2742 = _2612.y;\n    float _2744;\n    if (_2742 > 0.0f)\n    {\n        _2744 = _2742;\n    }\n    else\n    {\n        _2744 = 1.5f * _2692;\n    }\n    float4 _2764 = float4(world + (n * (_2744 * sqrt(1.0f - (_2697 * _2697)))), 1.0f);\n    float _2768 = dot(_2670, _2764);\n    float _2771 = _2680.y;\n    if (_2768 < _2771)\n    {\n        return 1.0f;\n    }\n    float2 _2786 = float2(dot(fa_light_texel(param_4), _2764), dot(fa_light_texel(param_5), _2764)) / _2768.xx;\n    float _2788 = _2786.x;\n    bool _2791 = _2788 < _2675.x;\n    bool _2800;\n    if (!_2791)\n    {\n        _2800 = _2788 > _2675.z;\n    }\n    else\n    {\n        _2800 = _2791;\n    }\n    bool _2809;\n    if (!_2800)\n    {\n        _2809 = _2786.y < _2675.y;\n    }\n    else\n    {\n        _2809 = _2800;\n    }\n    bool _2818;\n    if (!_2809)\n    {\n        _2818 = _2786.y > _2675.w;\n    }\n    else\n    {\n        _2818 = _2809;\n    }\n    if (_2818)\n    {\n        return 1.0f;\n    }\n    float _2824 = _2612.x;\n    float _2826;\n    if (_2824 > 0.0f)\n    {\n        _2826 = _2824;\n    }\n    else\n    {\n        _2826 = 1.5f * _2692;\n    }\n    float2 param_9 = _2786;\n    float4 param_10 = _2675;\n    float param_11 = _2768 - (_2826 * (1.0f + (0.5f * _2739)));\n    float param_12 = _2692;\n    float param_13 = 1.0f;\n    float param_14 = _2680.z * 0.25f;\n    float param_15 = (_2692 * min(_2739, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2771, _2680.z);\n    int param_17 = int(_2607.z + 0.5f);\n    float param_18 = _2607.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2111;\n    if (i == 0)\n    {\n        _2111 = _2121_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2127;\n        if (i == 1)\n        {\n            _2127 = _2121_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2135;\n            if (i == 2)\n            {\n                _2135 = _2121_fa_shadow_split.z;\n            }\n            else\n            {\n                _2135 = _2121_fa_shadow_split.w;\n            }\n            _2127 = _2135;\n        }\n        _2111 = _2127;\n    }\n    return _2111;\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2414 = max(_2121_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2419 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2425 = sqrt(1.0f - (_2419 * _2419));\n    float _2433 = min(_2425 / max(_2419, 0.20000000298023223876953125f), 4.0f);\n    float _2438;\n    if (_2121_fa_shadow_bias.y > 0.0f)\n    {\n        _2438 = _2121_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2438 = 1.5f * _2121_fa_shadow_info[ci].x;\n    }\n    float4 _2463 = mul(float4(world + (n * (_2438 * _2425)), 1.0f), _2121_fa_shadow_mat[ci]);\n    float _2470 = _2463.x;\n    bool _2473 = _2470 < _2121_fa_shadow_rect[ci].x;\n    bool _2482;\n    if (!_2473)\n    {\n        _2482 = _2470 > _2121_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2482 = _2473;\n    }\n    bool _2491;\n    if (!_2482)\n    {\n        _2491 = _2463.y < _2121_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2491 = _2482;\n    }\n    bool _2500;\n    if (!_2491)\n    {\n        _2500 = _2463.y > _2121_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2500 = _2491;\n    }\n    bool _2507;\n    if (!_2500)\n    {\n        _2507 = _2463.z > 1.0f;\n    }\n    else\n    {\n        _2507 = _2500;\n    }\n    if (_2507)\n    {\n        return -1.0f;\n    }\n    float _2515;\n    if (_2121_fa_shadow_bias.x > 0.0f)\n    {\n        _2515 = _2121_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2515 = 1.5f * _2121_fa_shadow_info[ci].x;\n    }\n    float2 param = _2463.xy;\n    float4 param_1 = _2121_fa_shadow_rect[ci];\n    float param_2 = _2463.z - ((_2515 * (1.0f + (0.5f * _2433))) / _2414);\n    float param_3 = _2121_fa_shadow_info[ci].x;\n    float param_4 = _2414;\n    float param_5 = _2414 * 0.25f;\n    float param_6 = ((_2121_fa_shadow_info[ci].x * min(_2433, 3.0f)) * 0.5f) / _2414;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2121_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2121_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_468_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2893 = int(_2121_fa_shadow_cfg.x + 0.5f);\n    if (_2893 < 1)\n    {\n        return 1.0f;\n    }\n    float _2908 = dot(world - _2121_fa_shadow_eye.xyz, _2121_fa_shadow_fwd.xyz);\n    int param = _2893 - 1;\n    if (_2908 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2920 = _2893 > 1;\n    bool _2927;\n    if (_2920)\n    {\n        _2927 = _2908 > _2121_fa_shadow_split.x;\n    }\n    else\n    {\n        _2927 = _2920;\n    }\n    if (_2927)\n    {\n        ci = 1;\n    }\n    bool _2931 = _2893 > 2;\n    bool _2938;\n    if (_2931)\n    {\n        _2938 = _2908 > _2121_fa_shadow_split.y;\n    }\n    else\n    {\n        _2938 = _2931;\n    }\n    if (_2938)\n    {\n        ci = 2;\n    }\n    bool _2942 = _2893 > 3;\n    bool _2949;\n    if (_2942)\n    {\n        _2949 = _2908 > _2121_fa_shadow_split.z;\n    }\n    else\n    {\n        _2949 = _2942;\n    }\n    if (_2949)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2893)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2975 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2975;\n        if (_2975 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2121_fa_shadow_cfg.y > 0.0f)\n    {\n        float _3000;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3000 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3000 = _2121_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _3019 = _2121_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3000, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _3030 = clamp((_2908 - (fa_shadow_split_at(param_7) - _3019)) / _3019, 0.0f, 1.0f);\n        if (_3030 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2893)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _3051 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3051;\n                if (_3051 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _3030);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _4425 = _468_fa_ct_a.x < 0.5f;\n    bool _4432;\n    if (!_4425)\n    {\n        _4432 = _2121_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _4432 = _4425;\n    }\n    if (_4432)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2121_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _4445 = fa_light_texel(param);\n    float _4446 = _4445.y;\n    float len = _4446;\n    if (_4446 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4458 = length(world - _468_fa_camera_pos.xyz);\n    float _4468 = 1.0f - smoothstep(0.5f * _468_fa_ct_b.x, _468_fa_ct_b.x, _4458);\n    if (_4468 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4474 = len;\n    float _4477 = min(_4474, 0.89999997615814208984375f * dist);\n    len = _4477;\n    float _4482 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _4458);\n    float _4487 = _4482 + (0.5f * _4477);\n    float3 _4493 = world + (gn * _4482);\n    float _4495 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _4559;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4510 = (float(k) + _4495) * 0.083333335816860198974609375f;\n        float3 _4518 = _4493 + (l * (_4510 * len));\n        float4 _4524 = float4(_4518, 1.0f);\n        float _4530 = dot(_468_fa_ct_vpw, _4524);\n        if (_4530 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _4550 = float2(dot(_468_fa_ct_vpx, _4524), dot(_468_fa_ct_vpy, _4524)) / _4530.xx;\n        float _4554 = _4550.x * 0.5f;\n        float _4555 = _4554 + 0.5f;\n        if (_468_fa_ct_a.y > 0.5f)\n        {\n            _4559 = (_4550.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _4559 = 0.5f - (_4550.y * 0.5f);\n        }\n        bool _4575 = _4555 < 0.0f;\n        bool _4582;\n        if (!_4575)\n        {\n            _4582 = _4555 >= 1.0f;\n        }\n        else\n        {\n            _4582 = _4575;\n        }\n        bool _4589;\n        if (!_4582)\n        {\n            _4589 = _4559 < 0.0f;\n        }\n        else\n        {\n            _4589 = _4582;\n        }\n        bool _4596;\n        if (!_4589)\n        {\n            _4596 = _4559 >= 1.0f;\n        }\n        else\n        {\n            _4596 = _4589;\n        }\n        if (_4596)\n        {\n            break;\n        }\n        float4 _4623 = fa_screen_tex.Load(int3(clamp(int2(float2(_4555, _4559) * _468_fa_ct_a.zw), int2(0, 0), int2(_468_fa_ct_a.zw) - int2(1, 1)), 0));\n        if (_4623.w < 0.5f)\n        {\n            continue;\n        }\n        float _4642 = (dot(_468_fa_ct_fwd.xyz, _4518) + _468_fa_ct_fwd.w) - _4623.x;\n        if ((_4642 > _4482) && (_4642 < _4487))\n        {\n            occ = max(occ, (1.0f - (_4510 * _4510)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_4555, 0.5f - _4554), min(_4559, 1.0f - _4559))));\n        }\n    }\n    return 1.0f - (occ * _4468);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _4745 = fa_baked_keep(param);\n    if (_4745 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _6030 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _6030;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4771 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _6032 = _4771.color;\n    float _6033 = _4771.attenuation;\n    float _6034 = _4771.shadow;\n    bool _4774 = _4771.type == 0;\n    if (_4774 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4771.direction;\n        float _4785 = fa_shadow_factor(param_5, param_6);\n        _6034 = _4785;\n        _6032 *= _4785;\n    }\n    else\n    {\n        bool _4796 = _4771.type != 0;\n        bool _4802;\n        if (_4796)\n        {\n            _4802 = _6033 > 0.0f;\n        }\n        else\n        {\n            _4802 = _4796;\n        }\n        if (_4802)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _4771.direction;\n            float _4821 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _6034 = _4821;\n            _6032 *= _4821;\n        }\n    }\n    bool _4831 = _468_fa_ct_a.x > 0.5f;\n    bool _4837;\n    if (_4831)\n    {\n        _4837 = _6033 > 0.0f;\n    }\n    else\n    {\n        _4837 = _4831;\n    }\n    if (_4837)\n    {\n        float _4844;\n        if (_4774)\n        {\n            _4844 = 1000000000.0f;\n        }\n        else\n        {\n            _4844 = _4771._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _4771.direction;\n        float param_18 = _4844;\n        float _4862 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6034 *= _4862;\n        _6032 *= _4862;\n    }\n    float _4875 = _6033;\n    float _4876 = _4875 * _4745;\n    _6033 = _4876;\n    float3 _4880 = _6032;\n    float3 _4881 = _4880 * _4745;\n    _6032 = _4881;\n    LightSample _6049 = { _4771.direction, _4881, _4876, _6034, _4771._distance, _4771.type };\n    return _6049;\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _4892 = n < 0;\n    bool _4899;\n    if (!_4892)\n    {\n        _4899 = n >= fa_light_count();\n    }\n    else\n    {\n        _4899 = _4892;\n    }\n    if (_4899)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    LightSample _4914 = fa_light_shadowed(param_1, param_2, param_3);\n    return _4914;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3810 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3818 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3821 = int(_3810);\n    int _3824 = int(_3818);\n    float _3834 = _3818 - float(_3824);\n    int _3890 = (_3821 * 9) + _3824;\n    int _3910 = ((_3821 + 1) * 9) + _3824;\n    return lerp(lerp(_3885[_3890], _3885[_3890 + 1], _3834), lerp(_3885[_3910], _3885[_3910 + 1], _3834), _3810 - float(_3821));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _5898 = false;\n    float _5899 = 1.0f;\n    float _5900 = 1.0f;\n    float _5901 = 1.0f;\n    float _5902 = 0.0f;\n    float _5903 = 0.0f;\n    float _5904 = 0.0f;\n    float _5905 = 0.0f;\n    float _5907 = 1.0f;\n    bool _5908 = false;\n    float3 _5909 = 0.0f.xxx;\n    float _5910 = 1.0f;\n    float _5911 = 1.0f;\n    float _5912 = 1.0f;\n    float _5913 = 0.0f;\n    float _5914 = 0.0f;\n    float3 _5915 = float3(1.0f, 0.0f, 0.0f);\n    float3 _5916 = float3(0.0f, 0.0f, 1.0f);\n    float _5917 = 1.0f;\n    float _5918 = 1.0f;\n    float _3961 = clamp(s.specular, 0.0f, 1.0f);\n    float _3965 = clamp(s.ior, 1.0f, 3.0f);\n    bool _3970 = (_3961 != 1.0f) || (_3965 != 1.5f);\n    bool _3979;\n    if (!_3970)\n    {\n        _3979 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _3979 = _3970;\n    }\n    if (_3979)\n    {\n        float _3987 = (_3965 - 1.0f) / (_3965 + 1.0f);\n        f0 = lerp(min((_3987 * _3987).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _3961, s.albedo, metallic.xxx);\n        _5899 = lerp(_3961, 1.0f, metallic);\n        _5898 = true;\n    }\n    float _4014 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_4014 > 0.0f)\n    {\n        float _4022 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _5902 = _4014;\n        _5903 = _4022;\n        float _4029 = _4022 * _4022;\n        _5904 = _4029;\n        _5905 = _4029 * _4029;\n        float _4041 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _5907 = _4041;\n        _5900 = 1.0f - (_4014 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _4041, 0.0f, 1.0f), 5.0f))));\n        _5898 = true;\n    }\n    float3 _4060 = max(s.sheen_color, 0.0f.xxx);\n    float _4069 = max(_4060.x, max(_4060.y, _4060.z));\n    if (_4069 > 0.0f)\n    {\n        float _4077 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _5908 = true;\n        _5909 = _4060;\n        _5910 = _4077;\n        _5911 = _4077 * _4077;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _4077;\n        float _4094 = fa_sheen_albedo(param, param_1);\n        _5913 = _4094;\n        _5912 = 1.0f - min(_4069 * _4094, 1.0f);\n        _5898 = true;\n    }\n    _5901 = _5900 * _5912;\n    float _4113 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_4113 != 0.0f)\n    {\n        float3 _4128 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _4128;\n        if (dot(_4128, _4128) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _4140 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_4140.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _4140.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _4140.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _4144 = t;\n        float3 _4145 = normalize(_4144);\n        t = _4145;\n        float3 _4170 = normalize((_4145 * cos(s.anisotropy_rotation)) + ((cross(n, _4145) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _5915 = _4170;\n        _5916 = cross(n, _4170);\n        float _4180 = roughness * roughness;\n        float _4186 = lerp(_4180, 1.0f, _4113 * _4113);\n        bool _4188 = _4113 > 0.0f;\n        _5917 = _4188 ? _4186 : _4180;\n        _5918 = _4188 ? _4180 : _4186;\n        _5914 = _4113;\n        _5898 = true;\n    }\n    FaLayers _5940 = { _5898, _5899, _5900, _5901, _5902, _5903, _5904, _5905, i.world_normal, _5907, _5908, _5909, _5910, _5911, _5912, _5913, _5914, _5915, _5916, _5917, _5918 };\n    return _5940;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3742 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3745 = _3742.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3745 * _3745, exp2((-9.27999973297119140625f) * ndv)) * _3745) + _3742.y)) + _3742.zw;\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3177 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3180 = _3177.x;\n    float _3182 = _3177.z;\n    float2 e = float2(_3180, _3182);\n    if (_3177.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3182)) * ((_3180 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3180)) * ((_3182 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3216_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3216_dummy_parameter)));\n}\n\nfloat3 fa_probe_level(float2 origin, float res, int lv, float2 e)\n{\n    float _3229;\n    if (lv == 0)\n    {\n        _3229 = 0.0f;\n    }\n    else\n    {\n        _3229 = res + 2.0f;\n    }\n    float _3239;\n    if (lv == 0)\n    {\n        _3239 = 0.0f;\n    }\n    else\n    {\n        _3239 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0f * float(lv - 1));\n    }\n    return fa_probe_atlas.SampleLevel(fa_env_smp, (((origin + float2(_3229, _3239)) + 1.0f.xx) + (((e * 0.5f) + 0.5f.xx) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0f).xyz;\n}\n\nfloat3 fa_probe_radiance(float2 origin, float res, float3 d, float rough)\n{\n    float _3285;\n    if (res > 64.5f)\n    {\n        _3285 = 5.0f;\n    }\n    else\n    {\n        _3285 = (res > 32.5f) ? 4.0f : 3.0f;\n    }\n    float _3300 = clamp(rough, 0.0f, 1.0f) * (_3285 - 1.0f);\n    int _3307 = int(min(floor(_3300), _3285 - 2.0f));\n    float _3312 = _3300 - float(_3307);\n    float3 param = d;\n    float2 _3316 = fa_oct_encode(param);\n    float2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3307;\n    float2 param_4 = _3316;\n    float3 _3326 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3312 < 0.00200000009499490261077880859375f)\n    {\n        return _3326;\n    }\n    float2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3307 + 1;\n    float2 param_8 = _3316;\n    return lerp(_3326, fa_probe_level(param_5, param_6, param_7, param_8), _3312.xxx);\n}\n\nfloat3 fa_probe_box_dir(float3 d, float4 posw, float4 bx, float4 by, float4 bz)\n{\n    if (posw.w < 0.5f)\n    {\n        return d;\n    }\n    float _3364 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3371 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3378 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3384 = dot(bx.xyz, d);\n    float _3388 = dot(by.xyz, d);\n    float _3392 = dot(bz.xyz, d);\n    float _3398;\n    if (_3384 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3398 = (1.0f - _3364) / _3384;\n    }\n    else\n    {\n        float _3412;\n        if (_3384 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3412 = ((-1.0f) - _3364) / _3384;\n        }\n        else\n        {\n            _3412 = 1000000015047466219876688855040.0f;\n        }\n        _3398 = _3412;\n    }\n    float tx = _3398;\n    float _3429;\n    if (_3388 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3429 = (1.0f - _3371) / _3388;\n    }\n    else\n    {\n        float _3442;\n        if (_3388 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3442 = ((-1.0f) - _3371) / _3388;\n        }\n        else\n        {\n            _3442 = 1000000015047466219876688855040.0f;\n        }\n        _3429 = _3442;\n    }\n    float ty = _3429;\n    float _3458;\n    if (_3392 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3458 = (1.0f - _3378) / _3392;\n    }\n    else\n    {\n        float _3471;\n        if (_3392 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3471 = ((-1.0f) - _3378) / _3392;\n        }\n        else\n        {\n            _3471 = 1000000015047466219876688855040.0f;\n        }\n        _3458 = _3471;\n    }\n    float _3483 = tx;\n    float _3486 = (_3483 > 0.0f) ? _3483 : 1000000015047466219876688855040.0f;\n    tx = _3486;\n    float _3487 = ty;\n    float _3490 = (_3487 > 0.0f) ? _3487 : 1000000015047466219876688855040.0f;\n    ty = _3490;\n    float _3500 = min(_3486, min(_3490, (_3458 > 0.0f) ? _3458 : 1000000015047466219876688855040.0f));\n    if (_3500 > 100000001504746621987668885504.0f)\n    {\n        return d;\n    }\n    float3 _3516 = (fa_world_pos + (d * _3500)) - posw.xyz;\n    float3 _3521;\n    if (dot(_3516, _3516) > 1.0000000133514319600180897396058e-10f)\n    {\n        _3521 = normalize(_3516);\n    }\n    else\n    {\n        _3521 = d;\n    }\n    return _3521;\n}\n\nfloat3 fa_probe_environment(float4 tile, float4 posw, float4 bx, float4 by, float4 bz, inout float3 d, float rough)\n{\n    float3 param = d;\n    float4 param_1 = posw;\n    float4 param_2 = bx;\n    float4 param_3 = by;\n    float4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    float2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    float3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _3567 = (1.0f - _468_fa_rpa_tile.w) - _468_fa_rpb_tile.w;\n    float3 outc = 0.0f.xxx;\n    if (_3567 > 0.0005000000237487256526947021484375f)\n    {\n        float3 base;\n        if (_468_fa_env_sky.w > 0.5f)\n        {\n            float2 param = _468_fa_atlas.zw;\n            float param_1 = 128.0f;\n            float3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3597 = rough * rough;\n            float _3628 = 0.60000002384185791015625f * _3597;\n            base = lerp(lerp(_468_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_468_fa_env_horizon.xyz, _468_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3597)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3628, 0.0500000007450580596923828125f + _3628, d.y).xxx), ((_468_fa_env_sky.xyz + _468_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3597 * 0.60000002384185791015625f).xxx);\n        }\n        outc = base * _3567;\n    }\n    if (_468_fa_rpa_tile.w > 0.0f)\n    {\n        float4 param_4 = _468_fa_rpa_tile;\n        float4 param_5 = _468_fa_rpa_pos;\n        float4 param_6 = _468_fa_rpa_bx;\n        float4 param_7 = _468_fa_rpa_by;\n        float4 param_8 = _468_fa_rpa_bz;\n        float3 param_9 = d;\n        float param_10 = rough;\n        float3 _3687 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3687 * _468_fa_rpa_tile.w);\n    }\n    if (_468_fa_rpb_tile.w > 0.0f)\n    {\n        float4 param_11 = _468_fa_rpb_tile;\n        float4 param_12 = _468_fa_rpb_pos;\n        float4 param_13 = _468_fa_rpb_bx;\n        float4 param_14 = _468_fa_rpb_by;\n        float4 param_15 = _468_fa_rpb_bz;\n        float3 param_16 = d;\n        float param_17 = rough;\n        float3 _3719 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_3719 * _468_fa_rpb_tile.w);\n    }\n    return outc;\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness, float occlusion)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _4221;\n        if (L.aniso >= 0.0f)\n        {\n            _4221 = L.b;\n        }\n        else\n        {\n            _4221 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_4221, v), _4221), (abs(L.aniso) * smoothstep(0.0f, 0.25f, roughness)).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4257 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _4257.x) + (L.f90.xxx * _4257.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _4315 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _4315.x) + _4315.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3784 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3784.x) + _3784.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _4354 = clamp(s.metallic, 0.0f, 1.0f);\n    float _4358 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _4365 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _4354.xxx);\n    float3 f0 = _4365;\n    float3 _4369 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _4369;\n    float3 param_3 = i.view_dir;\n    float param_4 = _4354;\n    float param_5 = _4358;\n    float3 param_6 = _4365;\n    FaLayers _4386 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4386.on)\n    {\n        FaLayers param_7 = _4386;\n        float3 param_8 = _4369;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _4358;\n        float param_12 = s.occlusion;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    float3 param_13 = _4369;\n    float3 param_14 = i.view_dir;\n    float3 param_15 = f0;\n    float param_16 = _4358;\n    return fa_sky_reflection(param_13, param_14, param_15, param_16) * s.occlusion;\n}\n\nfloat3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0f;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _4984 = fa_light_unshadowed(param, param_1);\n        float _4992 = dot(_4984.color, float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));\n        if (_4992 > bestPower)\n        {\n            bestPower = _4992;\n            best = n;\n        }\n    }\n    float3 lit = (_468_fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _5021 = fa_light(param_2, param_3);\n        float _5029;\n        if (dot(s.normal, _5021.direction) > 0.5f)\n        {\n            _5029 = 1.0f;\n        }\n        else\n        {\n            _5029 = _5035_dark;\n        }\n        lit += ((s.albedo * _5021.color) * _5029);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * _5035_skyAmount);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2121_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3075 = int(_2121_fa_shadow_cfg.x + 0.5f);\n    float _3085 = dot(world - _2121_fa_shadow_eye.xyz, _2121_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3090 = _3075 > 0;\n    bool _3099;\n    if (_3090)\n    {\n        int param = _3075 - 1;\n        _3099 = _3085 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3099 = _3090;\n    }\n    if (_3099)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3105 = _3075 > 1;\n        bool _3112;\n        if (_3105)\n        {\n            _3112 = _3085 > _2121_fa_shadow_split.x;\n        }\n        else\n        {\n            _3112 = _3105;\n        }\n        if (_3112)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3118 = _3075 > 2;\n        bool _3125;\n        if (_3118)\n        {\n            _3125 = _3085 > _2121_fa_shadow_split.y;\n        }\n        else\n        {\n            _3125 = _3118;\n        }\n        if (_3125)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3131 = _3075 > 3;\n        bool _3138;\n        if (_3131)\n        {\n            _3138 = _3085 > _2121_fa_shadow_split.z;\n        }\n        else\n        {\n            _3138 = _3131;\n        }\n        if (_3138)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _5752 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5752 = -_5752;\n    }\n    float3 _5422 = normalize(_468_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _5765 = { fa_world_pos, _5752, fa_world_tangent, fa_uv, fa_vertex_color, _5422, gl_FrontFacing };\n    SurfaceInput param_1 = _5765;\n    Surface _5430 = fa_standard_surface(param_1);\n    float3 _5783 = _5430.albedo;\n    float _5784 = _5430.alpha;\n    float3 _5785 = _5430.normal;\n    float _5786 = _5430.metallic;\n    float _5787 = _5430.roughness;\n    float _5788 = _5430.occlusion;\n    float3 _5789 = _5430.emission;\n    float _5790 = _5430.clearcoat;\n    float _5791 = _5430.clearcoat_roughness;\n    float3 _5792 = _5430.sheen_color;\n    float _5793 = _5430.sheen_roughness;\n    float _5794 = _5430.anisotropy;\n    float _5795 = _5430.anisotropy_rotation;\n    float _5796 = _5430.specular;\n    float _5797 = _5430.ior;\n    float3 _5798 = _5430.specular_color;\n    float _5799 = _5430.transmission;\n    float _5800 = _5430.thickness;\n    float3 _5801 = _5430.attenuation_color;\n    float _5802 = _5430.attenuation_distance;\n    SurfaceInput _5773 = { fa_world_pos, _5752, fa_world_tangent, fa_uv, fa_vertex_color, _5422, gl_FrontFacing };\n    SurfaceInput param_2 = _5773;\n    Surface param_3 = _5430;\n    surface(param_2, param_3);\n    _5783 = param_3.albedo;\n    _5784 = param_3.alpha;\n    _5785 = param_3.normal;\n    _5786 = param_3.metallic;\n    _5787 = param_3.roughness;\n    _5788 = param_3.occlusion;\n    _5789 = param_3.emission;\n    _5790 = param_3.clearcoat;\n    _5791 = param_3.clearcoat_roughness;\n    _5792 = param_3.sheen_color;\n    _5793 = param_3.sheen_roughness;\n    _5794 = param_3.anisotropy;\n    _5795 = param_3.anisotropy_rotation;\n    _5796 = param_3.specular;\n    _5797 = param_3.ior;\n    _5798 = param_3.specular_color;\n    _5799 = param_3.transmission;\n    _5800 = param_3.thickness;\n    _5801 = param_3.attenuation_color;\n    _5802 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _5752;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5783 = param_6;\n    _5785 = param_7;\n    float3 result;\n    if (_468_fa_emissive.w > 0.5f)\n    {\n        result = _5783;\n    }\n    else\n    {\n        float3 _5469 = _5785;\n        float3 _5470 = normalize(_5469);\n        _5785 = _5470;\n        SurfaceInput _5781 = { fa_world_pos, _5752, fa_world_tangent, fa_uv, fa_vertex_color, _5422, gl_FrontFacing };\n        SurfaceInput param_8 = _5781;\n        Surface _5884 = { _5783, _5784, _5470, _5786, _5787, _5788, _5789, _5790, _5791, _5792, _5793, _5794, _5795, _5796, _5797, _5798, _5799, _5800, _5801, _5802 };\n        Surface param_9 = _5884;\n        float3 _5481 = lighting(param_8, param_9);\n        result = _5481;\n    }\n    float3 _5485 = result;\n    float3 _5486 = _5485 + _5789;\n    result = _5486;\n    float3 param_10 = _5486;\n    float3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _5495 = _468_fa_fog.w > 0.0f;\n    bool _5502;\n    if (!_5495)\n    {\n        _5502 = _468_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _5502 = _5495;\n    }\n    if (_5502)\n    {\n        float3 _5511 = fa_world_pos - _468_fa_camera_pos.xyz;\n        float _5517 = dot(_5511, _468_fa_fog_c.xyz);\n        bool _5521 = _468_fa_fog_c.w > 0.5f;\n        float _5522;\n        if (_5521)\n        {\n            _5522 = _5517;\n        }\n        else\n        {\n            _5522 = length(_5511);\n        }\n        float _5534 = _5522 - _468_fa_fog_b.x;\n        if (_5534 > 0.0f)\n        {\n            float _5543 = _468_fa_fog.w * _5534;\n            float tau = _5543 * _5543;\n            if (_468_fa_fog_b.y > 0.0f)\n            {\n                float _5559;\n                if (_5521)\n                {\n                    _5559 = fa_world_pos.y - (_468_fa_fog_c.y * _5517);\n                }\n                else\n                {\n                    _5559 = _468_fa_camera_pos.y;\n                }\n                float _5580 = lerp(_5559, fa_world_pos.y, clamp(_468_fa_fog_b.x / _5522, 0.0f, 1.0f));\n                float _5584 = fa_world_pos.y - _5580;\n                float _5589 = _5580 - _468_fa_fog_b.z;\n                float _5594 = fa_world_pos.y - _468_fa_fog_b.z;\n                bool _5597 = _5589 <= 0.0f;\n                bool _5598 = !_5597;\n                bool _5604;\n                if (_5598)\n                {\n                    _5604 = _468_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5604 = _5597;\n                }\n                float _5605;\n                if (_5604)\n                {\n                    _5605 = _468_fa_fog_b.y;\n                }\n                else\n                {\n                    _5605 = _468_fa_fog_b.y * exp(-min(_468_fa_fog_b.w * _5589, 80.0f));\n                }\n                bool _5632;\n                if (_5598)\n                {\n                    _5632 = _468_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5632 = _5597;\n                }\n                float _5633;\n                if (_5632)\n                {\n                    _5633 = _468_fa_fog_b.y * _5589;\n                }\n                else\n                {\n                    _5633 = (_468_fa_fog_b.y * (1.0f - exp(-min(_468_fa_fog_b.w * _5589, 80.0f)))) / _468_fa_fog_b.w;\n                }\n                bool _5658 = _5594 <= 0.0f;\n                bool _5665;\n                if (!_5658)\n                {\n                    _5665 = _468_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5665 = _5658;\n                }\n                float _5666;\n                if (_5665)\n                {\n                    _5666 = _468_fa_fog_b.y * _5594;\n                }\n                else\n                {\n                    _5666 = (_468_fa_fog_b.y * (1.0f - exp(-min(_468_fa_fog_b.w * _5594, 80.0f)))) / _468_fa_fog_b.w;\n                }\n                float _5693;\n                if (abs(_5584) < 0.001000000047497451305389404296875f)\n                {\n                    _5693 = _5605;\n                }\n                else\n                {\n                    _5693 = (_5666 - _5633) / _5584;\n                }\n                tau += (_5534 * max(_5693, 0.0f));\n            }\n            result = lerp(result, _468_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _5784);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_5035",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _215_fa_camera_pos : packoffset(c0);\n    float4 _215_fa_ambient : packoffset(c1);\n    float4 _215_fa_base_color : packoffset(c2);\n    float4 _215_fa_emissive : packoffset(c3);\n    float4 _215_fa_model_emissive : packoffset(c4);\n    float4 _215_fa_pbr : packoffset(c5);\n    float4 _215_fa_maps : packoffset(c6);\n    float4 _215_fa_fog : packoffset(c7);\n    float4 _215_fa_fog_b : packoffset(c8);\n    float4 _215_fa_fog_c : packoffset(c9);\n    float4 _215_fa_counts : packoffset(c10);\n    float4 _215_fa_env_sky : packoffset(c11);\n    float4 _215_fa_env_horizon : packoffset(c12);\n    float4 _215_fa_time : packoffset(c13);\n    float4 _215_fa_cl_vpx : packoffset(c14);\n    float4 _215_fa_cl_vpy : packoffset(c15);\n    float4 _215_fa_cl_vpw : packoffset(c16);\n    float4 _215_fa_cl_fwd : packoffset(c17);\n    float4 _215_fa_cl_grid : packoffset(c18);\n    float4 _215_fa_cl_info : packoffset(c19);\n    float4 _215_fa_layers_a : packoffset(c20);\n    float4 _215_fa_layers_b : packoffset(c21);\n    float4 _215_fa_layers_c : packoffset(c22);\n    float4 _215_fa_layers_d : packoffset(c23);\n    float4 _215_fa_ct_a : packoffset(c24);\n    float4 _215_fa_ct_b : packoffset(c25);\n    float4 _215_fa_ct_vpx : packoffset(c26);\n    float4 _215_fa_ct_vpy : packoffset(c27);\n    float4 _215_fa_ct_vpw : packoffset(c28);\n    float4 _215_fa_ct_fwd : packoffset(c29);\n    float4 _215_fa_tr_a : packoffset(c30);\n    float4 _215_fa_tr_b : packoffset(c31);\n    float4 _215_fa_probe_sh[9] : packoffset(c32);\n    float4 _215_fa_atlas : packoffset(c41);\n    float4 _215_fa_rpa_tile : packoffset(c42);\n    float4 _215_fa_rpa_pos : packoffset(c43);\n    float4 _215_fa_rpa_bx : packoffset(c44);\n    float4 _215_fa_rpa_by : packoffset(c45);\n    float4 _215_fa_rpa_bz : packoffset(c46);\n    float4 _215_fa_rpb_tile : packoffset(c47);\n    float4 _215_fa_rpb_pos : packoffset(c48);\n    float4 _215_fa_rpb_bx : packoffset(c49);\n    float4 _215_fa_rpb_by : packoffset(c50);\n    float4 _215_fa_rpb_bz : packoffset(c51);\n    float4 _215_fa_gi : packoffset(c52);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _215_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _227 = fa_tex_fix(param_2, param_3);\n    float4 _831 = base_t;\n    _831.x = _227.x;\n    _831.y = _227.y;\n    _831.z = _227.z;\n    base_t = _831;\n    float4 _243 = (_831 * _215_fa_base_color) * i.vertex_color;\n    float3 _786 = i.world_normal;\n    if (_215_fa_maps.z > 0.5f)\n    {\n        float param_4 = _215_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _277 = fa_tex_fix(param_6, param_7);\n        float3 _281 = (_277 * 2.0f) - 1.0f.xxx;\n        float2 _286 = _281.xy * _215_fa_maps.x;\n        float3 _839 = _281;\n        _839.x = _286.x;\n        _839.y = _286.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _839;\n        _786 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _215_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _315 = fa_tex_fix(param_12, param_13);\n    float4 _842 = mrt;\n    _842.x = _315.x;\n    _842.y = _315.y;\n    _842.z = _315.z;\n    mrt = _842;\n    float4 _345 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _215_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = _215_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _387 = fa_tex_fix(param_20, param_21);\n    float _791 = _215_fa_layers_a.x;\n    float _792 = _215_fa_layers_a.y;\n    float _795 = _215_fa_layers_a.z;\n    float _794 = _215_fa_layers_b.w;\n    float _797 = _215_fa_layers_c.x;\n    if (_215_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_215_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _791 *= _357.y;\n            _792 *= _357.z;\n            _794 *= _345.w;\n        }\n        if (_215_fa_layers_c.z > 1.5f)\n        {\n            _795 *= mrt.x;\n            _797 *= mrt.w;\n        }\n    }\n    Surface _824 = { _243.xyz, _243.w, _786, clamp(_215_fa_pbr.x * _315.z, 0.0f, 1.0f), clamp(_215_fa_pbr.y * _315.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_215_fa_maps.y * (_357.x - 1.0f)), _215_fa_emissive.xyz + (_215_fa_model_emissive.xyz * _387), _791, _792, _215_fa_layers_b.xyz, _794, _795, _215_fa_layers_a.w, _797, _215_fa_layers_c.y, _215_fa_layers_d.xyz, _215_fa_tr_a.x, _215_fa_tr_a.y, _215_fa_tr_b.xyz, _215_fa_tr_a.z };\n    return _824;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _681 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _681 = -_681;\n    }\n    float3 _540 = normalize(_215_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _694 = { fa_world_pos, _681, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing };\n    SurfaceInput param = _694;\n    SurfaceInput _702 = { fa_world_pos, _681, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing };\n    SurfaceInput param_1 = _702;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _555 = normalize(param_2.normal);\n    float3 _570 = normalize(float3(dot(fa_pre_r0, _555), dot(fa_pre_r1, _555), dot(fa_pre_r2, _555)));\n    float _582 = _570.z;\n    float2 e = _570.xy / ((abs(_570.x) + abs(_570.y)) + abs(_582)).xx;\n    if (_582 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _416 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _416;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _423 = _273.world_pos;\n    float4 _284 = float4(_423, 1.0f);\n    fa_world_pos = _423;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -mul(_284, _136_fa_light_vp).z;\n    fa_pre_r0 = float3(_136_fa_light_vp[0].x, _136_fa_light_vp[1].x, _136_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136_fa_light_vp[0].y, _136_fa_light_vp[1].y, _136_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136_fa_light_vp[0].z, _136_fa_light_vp[1].z, _136_fa_light_vp[2].z);\n    gl_Position = mul(_284, _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _215_fa_camera_pos : packoffset(c0);\n    float4 _215_fa_ambient : packoffset(c1);\n    float4 _215_fa_base_color : packoffset(c2);\n    float4 _215_fa_emissive : packoffset(c3);\n    float4 _215_fa_model_emissive : packoffset(c4);\n    float4 _215_fa_pbr : packoffset(c5);\n    float4 _215_fa_maps : packoffset(c6);\n    float4 _215_fa_fog : packoffset(c7);\n    float4 _215_fa_fog_b : packoffset(c8);\n    float4 _215_fa_fog_c : packoffset(c9);\n    float4 _215_fa_counts : packoffset(c10);\n    float4 _215_fa_env_sky : packoffset(c11);\n    float4 _215_fa_env_horizon : packoffset(c12);\n    float4 _215_fa_time : packoffset(c13);\n    float4 _215_fa_cl_vpx : packoffset(c14);\n    float4 _215_fa_cl_vpy : packoffset(c15);\n    float4 _215_fa_cl_vpw : packoffset(c16);\n    float4 _215_fa_cl_fwd : packoffset(c17);\n    float4 _215_fa_cl_grid : packoffset(c18);\n    float4 _215_fa_cl_info : packoffset(c19);\n    float4 _215_fa_layers_a : packoffset(c20);\n    float4 _215_fa_layers_b : packoffset(c21);\n    float4 _215_fa_layers_c : packoffset(c22);\n    float4 _215_fa_layers_d : packoffset(c23);\n    float4 _215_fa_ct_a : packoffset(c24);\n    float4 _215_fa_ct_b : packoffset(c25);\n    float4 _215_fa_ct_vpx : packoffset(c26);\n    float4 _215_fa_ct_vpy : packoffset(c27);\n    float4 _215_fa_ct_vpw : packoffset(c28);\n    float4 _215_fa_ct_fwd : packoffset(c29);\n    float4 _215_fa_tr_a : packoffset(c30);\n    float4 _215_fa_tr_b : packoffset(c31);\n    float4 _215_fa_probe_sh[9] : packoffset(c32);\n    float4 _215_fa_atlas : packoffset(c41);\n    float4 _215_fa_rpa_tile : packoffset(c42);\n    float4 _215_fa_rpa_pos : packoffset(c43);\n    float4 _215_fa_rpa_bx : packoffset(c44);\n    float4 _215_fa_rpa_by : packoffset(c45);\n    float4 _215_fa_rpa_bz : packoffset(c46);\n    float4 _215_fa_rpb_tile : packoffset(c47);\n    float4 _215_fa_rpb_pos : packoffset(c48);\n    float4 _215_fa_rpb_bx : packoffset(c49);\n    float4 _215_fa_rpb_by : packoffset(c50);\n    float4 _215_fa_rpb_bz : packoffset(c51);\n    float4 _215_fa_gi : packoffset(c52);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _215_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _227 = fa_tex_fix(param_2, param_3);\n    float4 _831 = base_t;\n    _831.x = _227.x;\n    _831.y = _227.y;\n    _831.z = _227.z;\n    base_t = _831;\n    float4 _243 = (_831 * _215_fa_base_color) * i.vertex_color;\n    float3 _786 = i.world_normal;\n    if (_215_fa_maps.z > 0.5f)\n    {\n        float param_4 = _215_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _277 = fa_tex_fix(param_6, param_7);\n        float3 _281 = (_277 * 2.0f) - 1.0f.xxx;\n        float2 _286 = _281.xy * _215_fa_maps.x;\n        float3 _839 = _281;\n        _839.x = _286.x;\n        _839.y = _286.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _839;\n        _786 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _215_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _315 = fa_tex_fix(param_12, param_13);\n    float4 _842 = mrt;\n    _842.x = _315.x;\n    _842.y = _315.y;\n    _842.z = _315.z;\n    mrt = _842;\n    float4 _345 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _215_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = _215_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _387 = fa_tex_fix(param_20, param_21);\n    float _791 = _215_fa_layers_a.x;\n    float _792 = _215_fa_layers_a.y;\n    float _795 = _215_fa_layers_a.z;\n    float _794 = _215_fa_layers_b.w;\n    float _797 = _215_fa_layers_c.x;\n    if (_215_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_215_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _791 *= _357.y;\n            _792 *= _357.z;\n            _794 *= _345.w;\n        }\n        if (_215_fa_layers_c.z > 1.5f)\n        {\n            _795 *= mrt.x;\n            _797 *= mrt.w;\n        }\n    }\n    Surface _824 = { _243.xyz, _243.w, _786, clamp(_215_fa_pbr.x * _315.z, 0.0f, 1.0f), clamp(_215_fa_pbr.y * _315.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_215_fa_maps.y * (_357.x - 1.0f)), _215_fa_emissive.xyz + (_215_fa_model_emissive.xyz * _387), _791, _792, _215_fa_layers_b.xyz, _794, _795, _215_fa_layers_a.w, _797, _215_fa_layers_c.y, _215_fa_layers_d.xyz, _215_fa_tr_a.x, _215_fa_tr_a.y, _215_fa_tr_b.xyz, _215_fa_tr_a.z };\n    return _824;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _681 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _681 = -_681;\n    }\n    float3 _540 = normalize(_215_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _694 = { fa_world_pos, _681, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing };\n    SurfaceInput param = _694;\n    SurfaceInput _702 = { fa_world_pos, _681, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing };\n    SurfaceInput param_1 = _702;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _555 = normalize(param_2.normal);\n    float3 _570 = normalize(float3(dot(fa_pre_r0, _555), dot(fa_pre_r1, _555), dot(fa_pre_r2, _555)));\n    float _582 = _570.z;\n    float2 e = _570.xy / ((abs(_570.x) + abs(_570.y)) + abs(_582)).xx;\n    if (_582 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
