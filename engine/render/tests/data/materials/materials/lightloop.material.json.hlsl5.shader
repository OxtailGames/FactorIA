{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "63c8ed9ef72f0fba56beb38b3018a9ae9876604a67ae71ca005757f89f9b9e64",
  "slang": "hlsl5",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _263 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _263;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_270, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _3339[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\nstatic const LightSample _5292 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, 0 };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _365_fa_camera_pos : packoffset(c0);\n    float4 _365_fa_ambient : packoffset(c1);\n    float4 _365_fa_base_color : packoffset(c2);\n    float4 _365_fa_emissive : packoffset(c3);\n    float4 _365_fa_model_emissive : packoffset(c4);\n    float4 _365_fa_pbr : packoffset(c5);\n    float4 _365_fa_maps : packoffset(c6);\n    float4 _365_fa_fog : packoffset(c7);\n    float4 _365_fa_fog_b : packoffset(c8);\n    float4 _365_fa_fog_c : packoffset(c9);\n    float4 _365_fa_counts : packoffset(c10);\n    float4 _365_fa_env_sky : packoffset(c11);\n    float4 _365_fa_env_horizon : packoffset(c12);\n    float4 _365_fa_time : packoffset(c13);\n    float4 _365_fa_cl_vpx : packoffset(c14);\n    float4 _365_fa_cl_vpy : packoffset(c15);\n    float4 _365_fa_cl_vpw : packoffset(c16);\n    float4 _365_fa_cl_fwd : packoffset(c17);\n    float4 _365_fa_cl_grid : packoffset(c18);\n    float4 _365_fa_cl_info : packoffset(c19);\n    float4 _365_fa_layers_a : packoffset(c20);\n    float4 _365_fa_layers_b : packoffset(c21);\n    float4 _365_fa_layers_c : packoffset(c22);\n    float4 _365_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2063_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2063_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2063_fa_shadow_info[4] : packoffset(c20);\n    float4 _2063_fa_shadow_split : packoffset(c24);\n    float4 _2063_fa_shadow_cfg : packoffset(c25);\n    float4 _2063_fa_shadow_bias : packoffset(c26);\n    float4 _2063_fa_shadow_eye : packoffset(c27);\n    float4 _2063_fa_shadow_fwd : packoffset(c28);\n    float4 _2063_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _4132_dark : packoffset(c0);\n    float _4132_fa_pad0 : packoffset(c0.y);\n    float _4132_fa_pad1 : packoffset(c0.z);\n    float _4132_fa_pad2 : packoffset(c0.w);\n    float _4132_skyAmount : packoffset(c1);\n    float _4132_fa_pad3 : packoffset(c1.y);\n    float _4132_fa_pad4 : packoffset(c1.z);\n    float _4132_fa_pad5 : packoffset(c1.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t9);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1334 = _365_fa_cl_info.x < 0.0f;\n    bool _1341;\n    if (!_1334)\n    {\n        _1341 = _365_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1341 = _1334;\n    }\n    bool _1349;\n    if (!_1341)\n    {\n        _1349 = _365_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1349 = _1341;\n    }\n    bool _1356;\n    if (!_1349)\n    {\n        _1356 = _365_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1356 = _1349;\n    }\n    bool _1363;\n    if (!_1356)\n    {\n        _1363 = _365_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1363 = _1356;\n    }\n    if (_1363)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1373 = float4(world_pos, 1.0f);\n    float _1379 = dot(_365_fa_cl_vpw, _1373);\n    if (!(_1379 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1401 = float2(dot(_365_fa_cl_vpx, _1373), dot(_365_fa_cl_vpy, _1373)) / _1379.xx;\n    int _1405 = int(_365_fa_cl_grid.x);\n    int _1409 = int(_365_fa_cl_grid.y);\n    int param = (int(_365_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_365_fa_cl_fwd.xyz, world_pos) + _365_fa_cl_fwd.w, _365_fa_cl_grid.w) / _365_fa_cl_grid.w) * _365_fa_cl_grid.z)), 0, int(_365_fa_cl_info.y) - 1) * _1409) + clamp(int(floor(((_1401.y * 0.5f) + 0.5f) * _365_fa_cl_grid.y)), 0, _1409 - 1)) * _1405)) + clamp(int(floor(((_1401.x * 0.5f) + 0.5f) * _365_fa_cl_grid.x)), 0, _1405 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1485 = fa_cluster_texel(param);\n    return int2(int(_1485.x), int(_1485.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_365_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3881 = fa_cluster_lookup(param);\n    fa_cl_slot = _3881.x;\n    fa_cl_local = _3881.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _4193 = fa_linear_to_srgb(param);\n        c = _4193;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _4201 = fa_srgb_to_linear(param_1);\n            c = _4201;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _297;\n    if (i.front_facing)\n    {\n        _297 = i.world_normal;\n    }\n    else\n    {\n        _297 = -i.world_normal;\n    }\n    float3 _321 = normalize(i.world_tangent.xyz - (_297 * dot(_297, i.world_tangent.xyz)));\n    float3 _349 = normalize(((_321 * m.x) + ((cross(_297, _321) * i.world_tangent.w) * m.y)) + (_297 * m.z));\n    float3 _352;\n    if (i.front_facing)\n    {\n        _352 = _349;\n    }\n    else\n    {\n        _352 = -_349;\n    }\n    return _352;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _365_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _4232 = fa_tex_fix(param_2, param_3);\n    float4 _5255 = base_t;\n    _5255.x = _4232.x;\n    _5255.y = _4232.y;\n    _5255.z = _4232.z;\n    base_t = _5255;\n    float4 _4246 = (_5255 * _365_fa_base_color) * i.vertex_color;\n    float3 _5107 = i.world_normal;\n    if (_365_fa_maps.z > 0.5f)\n    {\n        float param_4 = _365_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4278 = fa_tex_fix(param_6, param_7);\n        float3 _4281 = (_4278 * 2.0f) - 1.0f.xxx;\n        float2 _4286 = _4281.xy * _365_fa_maps.x;\n        float3 _5263 = _4281;\n        _5263.x = _4286.x;\n        _5263.y = _4286.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5263;\n        _5107 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _365_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4314 = fa_tex_fix(param_12, param_13);\n    float4 _5266 = mrt;\n    _5266.x = _4314.x;\n    _5266.y = _4314.y;\n    _5266.z = _4314.z;\n    mrt = _5266;\n    float4 _4342 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _365_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _4342.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4353 = fa_tex_fix(param_16, param_17);\n    float param_18 = _365_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4383 = fa_tex_fix(param_20, param_21);\n    float _5112 = _365_fa_layers_a.x;\n    float _5113 = _365_fa_layers_a.y;\n    float _5116 = _365_fa_layers_a.z;\n    float _5115 = _365_fa_layers_b.w;\n    float _5118 = _365_fa_layers_c.x;\n    if (_365_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_365_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _5112 *= _4353.y;\n            _5113 *= _4353.z;\n            _5115 *= _4342.w;\n        }\n        if (_365_fa_layers_c.z > 1.5f)\n        {\n            _5116 *= mrt.x;\n            _5118 *= mrt.w;\n        }\n    }\n    Surface _5137 = { _4246.xyz, _4246.w, _5107, clamp(_365_fa_pbr.x * _4314.z, 0.0f, 1.0f), clamp(_365_fa_pbr.y * _4314.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_365_fa_maps.y * (_4353.x - 1.0f)), _365_fa_emissive.xyz + (_365_fa_model_emissive.xyz * _4383), _5112, _5113, _365_fa_layers_b.xyz, _5115, _5116, _365_fa_layers_a.w, _5118, _365_fa_layers_c.y, _365_fa_layers_d.xyz };\n    return _5137;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1565 = rect.zw - rect.xy;\n    float2 _1569 = _1565 * atlas;\n    float2 _1573 = ddx * _1569;\n    float2 _1577 = ddy * _1569;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1565), clamp(0.5f * log2(max(max(dot(_1573, _1573), dot(_1577, _1577)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1610 = _365_fa_counts.y < 0.5f;\n    bool _1617;\n    if (!_1610)\n    {\n        _1617 = _365_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1617 = _1610;\n    }\n    if (_1617)\n    {\n        return;\n    }\n    float3 _1623 = ddx(world_pos);\n    float3 _1626 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1630 = fa_cluster_texel(param);\n    int _1634 = int(_1630.w);\n    if (_1634 < 1)\n    {\n        return;\n    }\n    int _1644 = int(_365_fa_counts.y + 0.5f);\n    int param_1 = _1644;\n    float4 _1648 = fa_light_texel(param_1);\n    float2 _1651 = _1648.yz;\n    int _1655 = int(_1648.w);\n    int param_2 = _1644 + 1;\n    float4 _1660 = fa_light_texel(param_2);\n    float _1661 = _1660.x;\n    int _1667 = int(_365_fa_counts.w + 0.5f) - 1;\n    int _1671 = int(_1630.z);\n    float3 _1936;\n    for (int k = 0; k < _1634; k++)\n    {\n        int _1684 = _1671 + k;\n        int param_3 = _1655 + (_1684 >> 2);\n        int _1701 = (_1644 + 2) + (int(fa_light_texel(param_3)[_1684 & 3]) * 7);\n        int param_4 = _1701 + 6;\n        float4 _1706 = fa_light_texel(param_4);\n        if (((int(_1706.w + 0.5f) >> _1667) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1701;\n        float4 _1721 = fa_light_texel(param_5);\n        int param_6 = _1701 + 1;\n        float4 _1726 = fa_light_texel(param_6);\n        int param_7 = _1701 + 2;\n        float4 _1731 = fa_light_texel(param_7);\n        float3 _1734 = _1721.xyz;\n        float _1739 = dot(_1734, world_pos) + _1721.w;\n        float3 _1741 = _1726.xyz;\n        float _1746 = dot(_1741, world_pos) + _1726.w;\n        float3 _1748 = _1731.xyz;\n        float _1753 = dot(_1748, world_pos) + _1731.w;\n        bool _1758 = abs(_1739) > 0.5f;\n        bool _1766;\n        if (!_1758)\n        {\n            _1766 = abs(_1746) > 0.5f;\n        }\n        else\n        {\n            _1766 = _1758;\n        }\n        bool _1774;\n        if (!_1766)\n        {\n            _1774 = abs(_1753) > 0.5f;\n        }\n        else\n        {\n            _1774 = _1766;\n        }\n        if (_1774)\n        {\n            continue;\n        }\n        float _1789 = clamp(dot(geo_normal, normalize(_1748)) * _1706.z, 0.0f, 1.0f);\n        if (_1789 <= 0.0f)\n        {\n            continue;\n        }\n        float _1809 = (clamp((0.5f - abs(_1753)) * 10.0f, 0.0f, 1.0f) * _1789) * _1706.x;\n        float2 _1817 = float2(_1739 + 0.5f, 0.5f - _1746);\n        float2 _1827 = float2(dot(_1734, _1623), dot(_1741, _1623));\n        float2 _1837 = float2(dot(_1734, _1626), dot(_1741, _1626));\n        int param_8 = _1701 + 5;\n        float4 _1842 = fa_light_texel(param_8);\n        int param_9 = _1701 + 3;\n        float4 _1847 = fa_light_texel(param_9);\n        int param_10 = _1701 + 4;\n        float4 _1852 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1842.xyz;\n        bool _1862 = _1847.z > _1847.x;\n        if (_1862)\n        {\n            float4 param_11 = _1847;\n            float2 param_12 = _1817;\n            float2 param_13 = _1651;\n            float2 param_14 = _1827;\n            float2 param_15 = _1837;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1661 > 0.5f) && (_1661 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1888 = fa_dc_to_linear(param_16);\n                float4 _5187 = tx;\n                _5187.x = _1888.x;\n                _5187.y = _1888.y;\n                _5187.z = _1888.z;\n                tx = _5187;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1809 * tex_a) * _1842.w, 0.0f, 1.0f).xxx);\n        if (_1852.z > _1852.x)\n        {\n            float4 param_17 = _1852;\n            float2 param_18 = _1817;\n            float2 param_19 = _1651;\n            float2 param_20 = _1827;\n            float2 param_21 = _1837;\n            float4 _1932 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1661 > 1.5f)\n            {\n                float3 param_22 = _1932.xyz;\n                float3 _1942 = fa_dc_to_srgb(param_22);\n                _1936 = _1942;\n            }\n            else\n            {\n                _1936 = _1932.xyz;\n            }\n            float3 _1951 = (_1936 * 2.0f) - 1.0f.xxx;\n            float2 _1956 = _1951.xy * _1706.y;\n            float3 _1978 = (normalize(_1734) * _1956.x) + (normalize(_1741) * _1956.y);\n            float3 _1981 = normalize(normal);\n            normal = normalize(lerp(_1981, normalize((_1981 * max(_1951.z, 0.0500000007450580596923828125f)) + (_1978 - (_1981 * dot(_1981, _1978)))), clamp(_1809 * (_1862 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return _5292;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_365_fa_cl_info.x) + int(_365_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_365_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _427_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _427_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _593 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _606 = (c - (ru * hx)) - p;\n        float3 _612 = ru * (2.0f * hx);\n        float _618 = max(dot(_612, _612), 9.9999999392252902907785028219223e-09f);\n        float _622 = dot(_606, _612);\n        float t = clamp((-_622) / _618, 0.0f, 1.0f);\n        if (_593)\n        {\n            float _637 = dot(r, _612);\n            float _643 = _618 - (_637 * _637);\n            if (abs(_643) > (9.9999997473787516355514526367188e-06f * _618))\n            {\n                t = clamp(((dot(r, _606) * _637) - _622) / _643, 0.0f, 1.0f);\n            }\n        }\n        return (p + _606) + (_612 * t);\n    }\n    float3 q = p;\n    float _675 = dot(r, axis);\n    bool _683;\n    if (_593)\n    {\n        _683 = abs(_675) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _683 = _593;\n    }\n    if (_683)\n    {\n        float _693 = dot(c - p, axis) / _675;\n        if (_693 > 0.0f)\n        {\n            q = p + (r * _693);\n        }\n    }\n    float3 _706 = q - c;\n    float2 xy = float2(dot(_706, ru), dot(_706, uu));\n    if (shape > 0.5f)\n    {\n        float _721 = length(xy);\n        if (_721 > hx)\n        {\n            xy *= (hx / _721);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _514 = abs(d);\n    float _516 = _514.x;\n    float _518 = _514.y;\n    bool _519 = _516 >= _518;\n    bool _527;\n    if (_519)\n    {\n        _527 = _516 >= _514.z;\n    }\n    else\n    {\n        _527 = _519;\n    }\n    int _528;\n    if (_527)\n    {\n        _528 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _541;\n        if (_518 >= _514.z)\n        {\n            _541 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _541 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _528 = _541;\n    }\n    return _528;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _467 = dot(d, right);\n    float _471 = dot(d, up);\n    float _482;\n    if (((_467 * _467) + (_471 * _471)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _482 = atan2(_471, _467) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _482 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_482 - floor(_482)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _759 = fa_light_base(param);\n    bool _763 = _365_fa_ambient.w > 4.5f;\n    int param_1 = _759;\n    float4 _767 = fa_light_texel(param_1);\n    int param_2 = _759 + 1;\n    float4 _772 = fa_light_texel(param_2);\n    float _775 = _772.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _787 = _763 && (_775 > 2.5f);\n    fa_light_is_area = _787;\n    bool _789 = _775 < 0.5f;\n    float3 l;\n    if (_789)\n    {\n        l = normalize(_767.xyz);\n        if (_763)\n        {\n            int param_3 = _759 + 6;\n            float4 _803 = fa_light_texel(param_3);\n            if (_803.z > 0.5f)\n            {\n                int param_4 = _759 + 4;\n                float4 _813 = fa_light_texel(param_4);\n                int param_5 = _759 + 5;\n                float4 _818 = fa_light_texel(param_5);\n                float2 param_6 = _803.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _813.xyz) * _813.w, (-dot(world_pos, _818.xyz)) * _818.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _848 = _767.xyz;\n        float3 _850 = _848 - world_pos;\n        float3 to_light = _850;\n        float _853 = length(_850);\n        float reach = _853;\n        bool front = true;\n        if (_787)\n        {\n            int param_8 = _759 + 7;\n            reach = max(_853 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _759 + 4;\n            float4 _877 = fa_light_texel(param_9);\n            int param_10 = _759 + 5;\n            float4 _882 = fa_light_texel(param_10);\n            int param_11 = _759 + 6;\n            float4 _887 = fa_light_texel(param_11);\n            float _888 = _887.w;\n            int param_12 = _759 + 2;\n            float3 _895 = normalize(fa_light_texel(param_12).xyz);\n            bool _897 = _888 > 1.5f;\n            bool _905;\n            if (!_897)\n            {\n                _905 = dot(_895, to_light) < 0.0f;\n            }\n            else\n            {\n                _905 = _897;\n            }\n            front = _905;\n            float3 r = 0.0f.xxx;\n            if (dot(n, n) > 0.5f)\n            {\n                r = reflect(-normalize(_365_fa_camera_pos.xyz - world_pos), normalize(n));\n            }\n            float3 param_13 = _848;\n            float3 param_14 = _895;\n            float3 param_15 = _877.xyz;\n            float3 param_16 = _882.xyz;\n            float param_17 = _877.w;\n            float param_18 = _882.w;\n            float param_19 = _888;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _952 = length(to_light);\n        dist = _952;\n        l = to_light / max(_952, 9.9999997473787516355514526367188e-05f).xxx;\n        float _966 = reach / max(_767.w, 0.001000000047497451305389404296875f);\n        float _972 = clamp(1.0f - (_966 * _966), 0.0f, 1.0f);\n        float _974;\n        if (front)\n        {\n            _974 = _972 * _972;\n        }\n        else\n        {\n            _974 = 0.0f;\n        }\n        atten = _974;\n        bool _985 = _775 < 2.5f;\n        if ((_775 > 1.5f) && _985)\n        {\n            int param_22 = _759 + 2;\n            float4 _993 = fa_light_texel(param_22);\n            float _1003 = _993.w;\n            int param_23 = _759 + 3;\n            float4 _1008 = fa_light_texel(param_23);\n            float _1009 = _1008.x;\n            float cos_inner = _1009;\n            if (_1009 > 1.5f)\n            {\n                cos_inner = lerp(_1003, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1003, cos_inner, dot(-l, normalize(_993.xyz)));\n        }\n        if (_763 && (_775 < 1.5f))\n        {\n            int param_24 = _759 + 6;\n            float4 _1033 = fa_light_texel(param_24);\n            if (_1033.z > 0.5f)\n            {\n                float3 _1041 = -to_light;\n                int param_25 = _759 + 4;\n                int param_26 = _759 + 5;\n                float3 _1055 = fa_light_texel(param_25).xyz;\n                float3 _1059 = fa_light_texel(param_26).xyz;\n                float3 _1068 = float3(dot(_1041, _1055), dot(_1041, _1059), dot(_1041, cross(_1055, _1059)));\n                float3 param_27 = _1068;\n                int _1072 = fa_cube_face(param_27);\n                int param_28 = _1072;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1099 = float2(dot(_1068, cross(param_29, param_30)), dot(_1068, param_30)) / max(dot(_1068, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1103 = _1072 / 3;\n                float2 param_31 = _1033.xy + (float2(float(_1072 - (_1103 * 3)), float(_1103)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1099.x), 0.5f - (0.5f * _1099.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _759 + 7;\n            float4 _1133 = fa_light_texel(param_33);\n            if (_1133.z > 0.5f)\n            {\n                int param_34 = _759 + 2;\n                int param_35 = _759 + 4;\n                int param_36 = _759 + 5;\n                float2 param_37 = _1133.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_763 && _985)\n            {\n                int param_42 = _759 + 6;\n                float4 _1180 = fa_light_texel(param_42);\n                int param_43 = _759 + 7;\n                float4 _1185 = fa_light_texel(param_43);\n                bool _1188 = _1180.z > 0.5f;\n                bool _1195;\n                if (!_1188)\n                {\n                    _1195 = _1185.z > 0.5f;\n                }\n                else\n                {\n                    _1195 = _1188;\n                }\n                if (_1195)\n                {\n                    int param_44 = _759 + 2;\n                    float4 _1202 = fa_light_texel(param_44);\n                    float3 _1206 = normalize(_1202.xyz);\n                    int param_45 = _759 + 4;\n                    float4 _1211 = fa_light_texel(param_45);\n                    int param_46 = _759 + 5;\n                    float4 _1216 = fa_light_texel(param_46);\n                    if (_1188)\n                    {\n                        float3 _1224 = -to_light;\n                        float _1231 = _1202.w;\n                        float _1247 = 0.5f / max(dot(_1224, _1206) * (sqrt(max(1.0f - (_1231 * _1231), 0.0f)) / max(_1231, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1180.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1224, _1211.xyz) * _1247), 0.5f - (dot(_1224, _1216.xyz) * _1247));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1185.z > 0.5f)\n                    {\n                        float2 param_49 = _1185.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1206;\n                        float3 param_52 = _1211.xyz;\n                        float3 param_53 = _1216.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4932 = _772.xyz * atten;\n    if (_763)\n    {\n        _4932 *= fa_light_tint;\n    }\n    int _1316;\n    if (_789)\n    {\n        _1316 = 0;\n    }\n    else\n    {\n        _1316 = ((_775 > 1.5f) && (_775 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _4943 = { l, _4932, atten, 1.0f, dist, _1316 };\n    return _4943;\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _4024 = n < 0;\n    bool _4031;\n    if (!_4024)\n    {\n        _4031 = n >= fa_light_count();\n    }\n    else\n    {\n        _4031 = _4024;\n    }\n    if (_4031)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _4039 = fa_cl_light(param);\n    bool _4042 = fa_lm.z > 0.5f;\n    bool _4048;\n    if (_4042)\n    {\n        int param_1 = _4039;\n        _4048 = fa_light_baked(param_1);\n    }\n    else\n    {\n        _4048 = _4042;\n    }\n    if (_4048)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _4039;\n    float3 param_3 = i.world_pos;\n    float3 param_4 = i.world_normal;\n    LightSample _4061 = fa_light_sample_n(param_2, param_3, param_4);\n    return _4061;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2053;\n    if (i == 0)\n    {\n        _2053 = _2063_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2069;\n        if (i == 1)\n        {\n            _2069 = _2063_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2077;\n            if (i == 2)\n            {\n                _2077 = _2063_fa_shadow_split.z;\n            }\n            else\n            {\n                _2077 = _2063_fa_shadow_split.w;\n            }\n            _2069 = _2077;\n        }\n        _2053 = _2069;\n    }\n    return _2053;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2110 = fa_shadow_depth(param, param_1);\n    float _2114;\n    if (conv.x < 0.5f)\n    {\n        _2114 = _2110;\n    }\n    else\n    {\n        _2114 = (conv.y * conv.z) / (conv.z - (_2110 * (conv.z - conv.y)));\n    }\n    return _2114;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2041 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2041), sin(_2041)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2160 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2169;\n        if (k < 0.0f)\n        {\n            _2169 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2169 = k;\n        }\n        float _2189 = clamp((_2169 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2160;\n            float2 _2208 = fa_shadow_vogel(param_3, param_4, param_5) * _2189;\n            float2 param_6 = uv + (_2208 * _2063_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2220 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2220 < (zr - (length(_2208) * plane)))\n            {\n                sum += _2220;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2246 = sum / cnt;\n        float _2256;\n        if (k < 0.0f)\n        {\n            _2256 = (-k) / max(_2246, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2256 = k;\n        }\n        radius = clamp(((max(zr - _2246, 0.0f) * unit) * _2256) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2278 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2278; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2278;\n        float param_11 = _2160;\n        float2 _2297 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2297 * _2063_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2297) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2278);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2339 = max(_2063_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2344 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2350 = sqrt(1.0f - (_2344 * _2344));\n    float _2357 = min(_2350 / max(_2344, 0.20000000298023223876953125f), 4.0f);\n    float _2362;\n    if (_2063_fa_shadow_bias.y > 0.0f)\n    {\n        _2362 = _2063_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2362 = 1.5f * _2063_fa_shadow_info[ci].x;\n    }\n    float4 _2387 = mul(float4(world + (n * (_2362 * _2350)), 1.0f), _2063_fa_shadow_mat[ci]);\n    float _2394 = _2387.x;\n    bool _2397 = _2394 < _2063_fa_shadow_rect[ci].x;\n    bool _2406;\n    if (!_2397)\n    {\n        _2406 = _2394 > _2063_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2406 = _2397;\n    }\n    bool _2415;\n    if (!_2406)\n    {\n        _2415 = _2387.y < _2063_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2415 = _2406;\n    }\n    bool _2424;\n    if (!_2415)\n    {\n        _2424 = _2387.y > _2063_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2424 = _2415;\n    }\n    bool _2431;\n    if (!_2424)\n    {\n        _2431 = _2387.z > 1.0f;\n    }\n    else\n    {\n        _2431 = _2424;\n    }\n    if (_2431)\n    {\n        return -1.0f;\n    }\n    float _2439;\n    if (_2063_fa_shadow_bias.x > 0.0f)\n    {\n        _2439 = _2063_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2439 = 1.5f * _2063_fa_shadow_info[ci].x;\n    }\n    float2 param = _2387.xy;\n    float4 param_1 = _2063_fa_shadow_rect[ci];\n    float param_2 = _2387.z - ((_2439 * (1.0f + (0.5f * _2357))) / _2339);\n    float param_3 = _2063_fa_shadow_info[ci].x;\n    float param_4 = _2339;\n    float param_5 = _2339 * 0.25f;\n    float param_6 = ((_2063_fa_shadow_info[ci].x * min(_2357, 3.0f)) * 0.5f) / _2339;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2063_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2063_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_365_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2827 = int(_2063_fa_shadow_cfg.x + 0.5f);\n    if (_2827 < 1)\n    {\n        return 1.0f;\n    }\n    float _2842 = dot(world - _2063_fa_shadow_eye.xyz, _2063_fa_shadow_fwd.xyz);\n    int param = _2827 - 1;\n    if (_2842 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2854 = _2827 > 1;\n    bool _2861;\n    if (_2854)\n    {\n        _2861 = _2842 > _2063_fa_shadow_split.x;\n    }\n    else\n    {\n        _2861 = _2854;\n    }\n    if (_2861)\n    {\n        ci = 1;\n    }\n    bool _2865 = _2827 > 2;\n    bool _2872;\n    if (_2865)\n    {\n        _2872 = _2842 > _2063_fa_shadow_split.y;\n    }\n    else\n    {\n        _2872 = _2865;\n    }\n    if (_2872)\n    {\n        ci = 2;\n    }\n    bool _2876 = _2827 > 3;\n    bool _2883;\n    if (_2876)\n    {\n        _2883 = _2842 > _2063_fa_shadow_split.z;\n    }\n    else\n    {\n        _2883 = _2876;\n    }\n    if (_2883)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2827)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2909 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2909;\n        if (_2909 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2063_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2934;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2934 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2934 = _2063_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2953 = _2063_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2934, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2964 = clamp((_2842 - (fa_shadow_split_at(param_7) - _2953)) / _2953, 0.0f, 1.0f);\n        if (_2964 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2827)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2985 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2985;\n                if (_2985 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2964);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _2497 = _365_fa_pbr.z < 0.5f;\n    bool _2504;\n    if (!_2497)\n    {\n        _2504 = _2063_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2504 = _2497;\n    }\n    if (_2504)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2063_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2517 = fa_light_texel(param);\n    float _2518 = _2517.x;\n    if (_2518 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2527 = int(_2518 + 0.5f);\n    int param_1 = _2527;\n    float4 _2531 = fa_light_texel(param_1);\n    int param_2 = _2527 + 1;\n    float4 _2536 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2539 = _2531.y;\n    if (_2539 > 0.0f)\n    {\n        float _2556 = 1.0f - smoothstep(0.75f * _2539, _2539, length(world - _2063_fa_shadow_eye.xyz));\n        fade = _2556;\n        if (_2556 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2531.x > 1.5f)\n    {\n        int param_3 = li;\n        int param_4 = fa_light_base(param_3);\n        float3 param_5 = world - fa_light_texel(param_4).xyz;\n        face = fa_cube_face(param_5);\n    }\n    int _2585 = (_2527 + 2) + (face * 6);\n    int param_6 = _2585;\n    int param_7 = _2585 + 1;\n    int param_8 = _2585 + 3;\n    float4 _2599 = fa_light_texel(param_8);\n    int param_9 = _2585 + 4;\n    float4 _2604 = fa_light_texel(param_9);\n    int param_10 = _2585 + 5;\n    float4 _2609 = fa_light_texel(param_10);\n    float _2621 = _2609.x * max(dot(_2599, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2626 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2649 = clamp(dot(n, _2599.xyz), -1.0f, 1.0f);\n    int param_11 = li;\n    int param_12 = fa_light_base(param_11);\n    float _2673 = min(sqrt(1.0f - (_2649 * _2649)) / max(abs(dot(n, world - fa_light_texel(param_12).xyz)) / max(dot(_2599, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2676 = _2536.y;\n    float _2678;\n    if (_2676 > 0.0f)\n    {\n        _2678 = _2676;\n    }\n    else\n    {\n        _2678 = 1.5f * _2621;\n    }\n    float4 _2698 = float4(world + (n * (_2678 * sqrt(1.0f - (_2626 * _2626)))), 1.0f);\n    float _2702 = dot(_2599, _2698);\n    float _2705 = _2609.y;\n    if (_2702 < _2705)\n    {\n        return 1.0f;\n    }\n    float2 _2720 = float2(dot(fa_light_texel(param_6), _2698), dot(fa_light_texel(param_7), _2698)) / _2702.xx;\n    float _2722 = _2720.x;\n    bool _2725 = _2722 < _2604.x;\n    bool _2734;\n    if (!_2725)\n    {\n        _2734 = _2722 > _2604.z;\n    }\n    else\n    {\n        _2734 = _2725;\n    }\n    bool _2743;\n    if (!_2734)\n    {\n        _2743 = _2720.y < _2604.y;\n    }\n    else\n    {\n        _2743 = _2734;\n    }\n    bool _2752;\n    if (!_2743)\n    {\n        _2752 = _2720.y > _2604.w;\n    }\n    else\n    {\n        _2752 = _2743;\n    }\n    if (_2752)\n    {\n        return 1.0f;\n    }\n    float _2758 = _2536.x;\n    float _2760;\n    if (_2758 > 0.0f)\n    {\n        _2760 = _2758;\n    }\n    else\n    {\n        _2760 = 1.5f * _2621;\n    }\n    float2 param_13 = _2720;\n    float4 param_14 = _2604;\n    float param_15 = _2702 - (_2760 * (1.0f + (0.5f * _2673)));\n    float param_16 = _2621;\n    float param_17 = 1.0f;\n    float param_18 = _2609.z * 0.25f;\n    float param_19 = (_2621 * min(_2673, 3.0f)) * 0.5f;\n    float3 param_20 = float3(1.0f, _2705, _2609.z);\n    int param_21 = int(_2531.z + 0.5f);\n    float param_22 = _2531.w;\n    return lerp(1.0f, fa_shadow_filter(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _3908 = fa_lm.z > 0.5f;\n    bool _3914;\n    if (_3908)\n    {\n        int param = li;\n        _3914 = fa_light_baked(param);\n    }\n    else\n    {\n        _3914 = _3908;\n    }\n    if (_3914)\n    {\n        int param_1 = li;\n        LightSample _5076 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _5076;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3938 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _5078 = _3938.color;\n    float _5080 = _3938.shadow;\n    if ((_3938.type == 0) && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3938.direction;\n        float _3952 = fa_shadow_factor(param_5, param_6);\n        _5080 = _3952;\n        _5078 *= _3952;\n    }\n    else\n    {\n        bool _3963 = _3938.type != 0;\n        bool _3969;\n        if (_3963)\n        {\n            _3969 = _3938.attenuation > 0.0f;\n        }\n        else\n        {\n            _3969 = _3963;\n        }\n        if (_3969)\n        {\n            int param_7 = li;\n            float3 param_8 = world_pos;\n            float3 param_9 = gn;\n            float3 param_10 = _3938.direction;\n            float _3981 = fa_shadow_local(param_7, param_8, param_9, param_10);\n            _5080 = _3981;\n            _5078 *= _3981;\n        }\n    }\n    LightSample _5095 = { _3938.direction, _5078, _3938.attenuation, _5080, _3938._distance, _3938.type };\n    return _5095;\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _3998 = n < 0;\n    bool _4005;\n    if (!_3998)\n    {\n        _4005 = n >= fa_light_count();\n    }\n    else\n    {\n        _4005 = _3998;\n    }\n    if (_4005)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    LightSample _4020 = fa_light_shadowed(param_1, param_2, param_3);\n    return _4020;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3264 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3272 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3275 = int(_3264);\n    int _3278 = int(_3272);\n    float _3288 = _3272 - float(_3278);\n    int _3344 = (_3275 * 9) + _3278;\n    int _3364 = ((_3275 + 1) * 9) + _3278;\n    return lerp(lerp(_3339[_3344], _3339[_3344 + 1], _3288), lerp(_3339[_3364], _3339[_3364 + 1], _3288), _3264 - float(_3275));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _4944 = false;\n    float _4945 = 1.0f;\n    float _4946 = 1.0f;\n    float _4947 = 1.0f;\n    float _4948 = 0.0f;\n    float _4949 = 0.0f;\n    float _4950 = 0.0f;\n    float _4951 = 0.0f;\n    float _4953 = 1.0f;\n    bool _4954 = false;\n    float3 _4955 = 0.0f.xxx;\n    float _4956 = 1.0f;\n    float _4957 = 1.0f;\n    float _4958 = 1.0f;\n    float _4959 = 0.0f;\n    float _4960 = 0.0f;\n    float3 _4961 = float3(1.0f, 0.0f, 0.0f);\n    float3 _4962 = float3(0.0f, 0.0f, 1.0f);\n    float _4963 = 1.0f;\n    float _4964 = 1.0f;\n    float _3415 = clamp(s.specular, 0.0f, 1.0f);\n    float _3419 = clamp(s.ior, 1.0f, 3.0f);\n    bool _3424 = (_3415 != 1.0f) || (_3419 != 1.5f);\n    bool _3433;\n    if (!_3424)\n    {\n        _3433 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _3433 = _3424;\n    }\n    if (_3433)\n    {\n        float _3441 = (_3419 - 1.0f) / (_3419 + 1.0f);\n        f0 = lerp(min((_3441 * _3441).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _3415, s.albedo, metallic.xxx);\n        _4945 = lerp(_3415, 1.0f, metallic);\n        _4944 = true;\n    }\n    float _3468 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_3468 > 0.0f)\n    {\n        float _3476 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _4948 = _3468;\n        _4949 = _3476;\n        float _3483 = _3476 * _3476;\n        _4950 = _3483;\n        _4951 = _3483 * _3483;\n        float _3495 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _4953 = _3495;\n        _4946 = 1.0f - (_3468 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _3495, 0.0f, 1.0f), 5.0f))));\n        _4944 = true;\n    }\n    float3 _3515 = max(s.sheen_color, 0.0f.xxx);\n    float _3524 = max(_3515.x, max(_3515.y, _3515.z));\n    if (_3524 > 0.0f)\n    {\n        float _3532 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _4954 = true;\n        _4955 = _3515;\n        _4956 = _3532;\n        _4957 = _3532 * _3532;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _3532;\n        float _3549 = fa_sheen_albedo(param, param_1);\n        _4959 = _3549;\n        _4958 = 1.0f - min(_3524 * _3549, 1.0f);\n        _4944 = true;\n    }\n    _4947 = _4946 * _4958;\n    float _3568 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_3568 != 0.0f)\n    {\n        float3 _3583 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _3583;\n        if (dot(_3583, _3583) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _3595 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_3595.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _3595.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _3595.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _3599 = t;\n        float3 _3600 = normalize(_3599);\n        t = _3600;\n        float3 _3625 = normalize((_3600 * cos(s.anisotropy_rotation)) + ((cross(n, _3600) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _4961 = _3625;\n        _4962 = cross(n, _3625);\n        float _3635 = roughness * roughness;\n        float _3641 = lerp(_3635, 1.0f, _3568 * _3568);\n        bool _3643 = _3568 > 0.0f;\n        _4963 = _3643 ? _3641 : _3635;\n        _4964 = _3643 ? _3635 : _3641;\n        _4960 = _3568;\n        _4944 = true;\n    }\n    FaLayers _4986 = { _4944, _4945, _4946, _4947, _4948, _4949, _4950, _4951, i.world_normal, _4953, _4954, _4955, _4956, _4957, _4958, _4959, _4960, _4961, _4962, _4963, _4964 };\n    return _4986;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3196 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3199 = _3196.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3199 * _3199, exp2((-9.27999973297119140625f) * ndv)) * _3199) + _3196.y)) + _3196.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_365_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _365_fa_env_horizon.w).xyz;\n    }\n    float _3120 = rough * rough;\n    float _3150 = 0.60000002384185791015625f * _3120;\n    return lerp(lerp(_365_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_365_fa_env_horizon.xyz, _365_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3120)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3150, 0.0500000007450580596923828125f + _3150, d.y).xxx), ((_365_fa_env_sky.xyz + _365_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3120 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _3676;\n        if (L.aniso >= 0.0f)\n        {\n            _3676 = L.b;\n        }\n        else\n        {\n            _3676 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_3676, v), _3676), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3709 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _3709.x) + (L.f90.xxx * _3709.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3764 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _3764.x) + _3764.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3238 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3238.x) + _3238.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _3803 = clamp(s.metallic, 0.0f, 1.0f);\n    float _3807 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _3814 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _3803.xxx);\n    float3 f0 = _3814;\n    float3 _3818 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _3818;\n    float3 param_3 = i.view_dir;\n    float param_4 = _3803;\n    float param_5 = _3807;\n    float3 param_6 = _3814;\n    FaLayers _3835 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_3835.on)\n    {\n        FaLayers param_7 = _3835;\n        float3 param_8 = _3818;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _3807;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _3818;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _3807;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0f;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _4081 = fa_light_unshadowed(param, param_1);\n        float _4089 = dot(_4081.color, float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));\n        if (_4089 > bestPower)\n        {\n            bestPower = _4089;\n            best = n;\n        }\n    }\n    float3 lit = (_365_fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _4118 = fa_light(param_2, param_3);\n        float _4126;\n        if (dot(s.normal, _4118.direction) > 0.5f)\n        {\n            _4126 = 1.0f;\n        }\n        else\n        {\n            _4126 = _4132_dark;\n        }\n        lit += ((s.albedo * _4118.color) * _4126);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * _4132_skyAmount);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2063_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3009 = int(_2063_fa_shadow_cfg.x + 0.5f);\n    float _3019 = dot(world - _2063_fa_shadow_eye.xyz, _2063_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3024 = _3009 > 0;\n    bool _3033;\n    if (_3024)\n    {\n        int param = _3009 - 1;\n        _3033 = _3019 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3033 = _3024;\n    }\n    if (_3033)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3039 = _3009 > 1;\n        bool _3046;\n        if (_3039)\n        {\n            _3046 = _3019 > _2063_fa_shadow_split.x;\n        }\n        else\n        {\n            _3046 = _3039;\n        }\n        if (_3046)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3052 = _3009 > 2;\n        bool _3059;\n        if (_3052)\n        {\n            _3059 = _3019 > _2063_fa_shadow_split.y;\n        }\n        else\n        {\n            _3059 = _3052;\n        }\n        if (_3059)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3065 = _3009 > 3;\n        bool _3072;\n        if (_3065)\n        {\n            _3072 = _3019 > _2063_fa_shadow_split.z;\n        }\n        else\n        {\n            _3072 = _3065;\n        }\n        if (_3072)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _4818 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4818 = -_4818;\n    }\n    float3 _4504 = normalize(_365_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _4831 = { fa_world_pos, _4818, fa_world_tangent, fa_uv, fa_vertex_color, _4504, gl_FrontFacing };\n    SurfaceInput param_1 = _4831;\n    Surface _4512 = fa_standard_surface(param_1);\n    float3 _4849 = _4512.albedo;\n    float _4850 = _4512.alpha;\n    float3 _4851 = _4512.normal;\n    float _4852 = _4512.metallic;\n    float _4853 = _4512.roughness;\n    float _4854 = _4512.occlusion;\n    float3 _4855 = _4512.emission;\n    float _4856 = _4512.clearcoat;\n    float _4857 = _4512.clearcoat_roughness;\n    float3 _4858 = _4512.sheen_color;\n    float _4859 = _4512.sheen_roughness;\n    float _4860 = _4512.anisotropy;\n    float _4861 = _4512.anisotropy_rotation;\n    float _4862 = _4512.specular;\n    float _4863 = _4512.ior;\n    float3 _4864 = _4512.specular_color;\n    SurfaceInput _4839 = { fa_world_pos, _4818, fa_world_tangent, fa_uv, fa_vertex_color, _4504, gl_FrontFacing };\n    SurfaceInput param_2 = _4839;\n    Surface param_3 = _4512;\n    surface(param_2, param_3);\n    _4849 = param_3.albedo;\n    _4850 = param_3.alpha;\n    _4851 = param_3.normal;\n    _4852 = param_3.metallic;\n    _4853 = param_3.roughness;\n    _4854 = param_3.occlusion;\n    _4855 = param_3.emission;\n    _4856 = param_3.clearcoat;\n    _4857 = param_3.clearcoat_roughness;\n    _4858 = param_3.sheen_color;\n    _4859 = param_3.sheen_roughness;\n    _4860 = param_3.anisotropy;\n    _4861 = param_3.anisotropy_rotation;\n    _4862 = param_3.specular;\n    _4863 = param_3.ior;\n    _4864 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _4818;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4849 = param_6;\n    _4851 = param_7;\n    float3 result;\n    if (_365_fa_emissive.w > 0.5f)\n    {\n        result = _4849;\n    }\n    else\n    {\n        float3 _4550 = _4851;\n        float3 _4551 = normalize(_4550);\n        _4851 = _4551;\n        SurfaceInput _4847 = { fa_world_pos, _4818, fa_world_tangent, fa_uv, fa_vertex_color, _4504, gl_FrontFacing };\n        SurfaceInput param_8 = _4847;\n        Surface _4930 = { _4849, _4850, _4551, _4852, _4853, _4854, _4855, _4856, _4857, _4858, _4859, _4860, _4861, _4862, _4863, _4864 };\n        Surface param_9 = _4930;\n        float3 _4562 = lighting(param_8, param_9);\n        result = _4562;\n    }\n    float3 _4566 = result;\n    float3 _4567 = _4566 + _4855;\n    result = _4567;\n    float3 param_10 = _4567;\n    float3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _4576 = _365_fa_fog.w > 0.0f;\n    bool _4583;\n    if (!_4576)\n    {\n        _4583 = _365_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _4583 = _4576;\n    }\n    if (_4583)\n    {\n        float3 _4592 = fa_world_pos - _365_fa_camera_pos.xyz;\n        float _4598 = dot(_4592, _365_fa_fog_c.xyz);\n        bool _4602 = _365_fa_fog_c.w > 0.5f;\n        float _4603;\n        if (_4602)\n        {\n            _4603 = _4598;\n        }\n        else\n        {\n            _4603 = length(_4592);\n        }\n        float _4615 = _4603 - _365_fa_fog_b.x;\n        if (_4615 > 0.0f)\n        {\n            float _4624 = _365_fa_fog.w * _4615;\n            float tau = _4624 * _4624;\n            if (_365_fa_fog_b.y > 0.0f)\n            {\n                float _4640;\n                if (_4602)\n                {\n                    _4640 = fa_world_pos.y - (_365_fa_fog_c.y * _4598);\n                }\n                else\n                {\n                    _4640 = _365_fa_camera_pos.y;\n                }\n                float _4661 = lerp(_4640, fa_world_pos.y, clamp(_365_fa_fog_b.x / _4603, 0.0f, 1.0f));\n                float _4665 = fa_world_pos.y - _4661;\n                float _4670 = _4661 - _365_fa_fog_b.z;\n                float _4675 = fa_world_pos.y - _365_fa_fog_b.z;\n                bool _4678 = _4670 <= 0.0f;\n                bool _4679 = !_4678;\n                bool _4685;\n                if (_4679)\n                {\n                    _4685 = _365_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4685 = _4678;\n                }\n                float _4686;\n                if (_4685)\n                {\n                    _4686 = _365_fa_fog_b.y;\n                }\n                else\n                {\n                    _4686 = _365_fa_fog_b.y * exp(-min(_365_fa_fog_b.w * _4670, 80.0f));\n                }\n                bool _4713;\n                if (_4679)\n                {\n                    _4713 = _365_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4713 = _4678;\n                }\n                float _4714;\n                if (_4713)\n                {\n                    _4714 = _365_fa_fog_b.y * _4670;\n                }\n                else\n                {\n                    _4714 = (_365_fa_fog_b.y * (1.0f - exp(-min(_365_fa_fog_b.w * _4670, 80.0f)))) / _365_fa_fog_b.w;\n                }\n                bool _4739 = _4675 <= 0.0f;\n                bool _4746;\n                if (!_4739)\n                {\n                    _4746 = _365_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4746 = _4739;\n                }\n                float _4747;\n                if (_4746)\n                {\n                    _4747 = _365_fa_fog_b.y * _4675;\n                }\n                else\n                {\n                    _4747 = (_365_fa_fog_b.y * (1.0f - exp(-min(_365_fa_fog_b.w * _4675, 80.0f)))) / _365_fa_fog_b.w;\n                }\n                float _4774;\n                if (abs(_4665) < 0.001000000047497451305389404296875f)\n                {\n                    _4774 = _4686;\n                }\n                else\n                {\n                    _4774 = (_4747 - _4714) / _4665;\n                }\n                tau += (_4615 * max(_4774, 0.0f));\n            }\n            result = lerp(result, _365_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4850);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_365",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2063",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_4132",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _3339[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\nstatic const LightSample _5292 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, 0 };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _365_fa_camera_pos : packoffset(c0);\n    float4 _365_fa_ambient : packoffset(c1);\n    float4 _365_fa_base_color : packoffset(c2);\n    float4 _365_fa_emissive : packoffset(c3);\n    float4 _365_fa_model_emissive : packoffset(c4);\n    float4 _365_fa_pbr : packoffset(c5);\n    float4 _365_fa_maps : packoffset(c6);\n    float4 _365_fa_fog : packoffset(c7);\n    float4 _365_fa_fog_b : packoffset(c8);\n    float4 _365_fa_fog_c : packoffset(c9);\n    float4 _365_fa_counts : packoffset(c10);\n    float4 _365_fa_env_sky : packoffset(c11);\n    float4 _365_fa_env_horizon : packoffset(c12);\n    float4 _365_fa_time : packoffset(c13);\n    float4 _365_fa_cl_vpx : packoffset(c14);\n    float4 _365_fa_cl_vpy : packoffset(c15);\n    float4 _365_fa_cl_vpw : packoffset(c16);\n    float4 _365_fa_cl_fwd : packoffset(c17);\n    float4 _365_fa_cl_grid : packoffset(c18);\n    float4 _365_fa_cl_info : packoffset(c19);\n    float4 _365_fa_layers_a : packoffset(c20);\n    float4 _365_fa_layers_b : packoffset(c21);\n    float4 _365_fa_layers_c : packoffset(c22);\n    float4 _365_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2063_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2063_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2063_fa_shadow_info[4] : packoffset(c20);\n    float4 _2063_fa_shadow_split : packoffset(c24);\n    float4 _2063_fa_shadow_cfg : packoffset(c25);\n    float4 _2063_fa_shadow_bias : packoffset(c26);\n    float4 _2063_fa_shadow_eye : packoffset(c27);\n    float4 _2063_fa_shadow_fwd : packoffset(c28);\n    float4 _2063_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _4132_dark : packoffset(c0);\n    float _4132_fa_pad0 : packoffset(c0.y);\n    float _4132_fa_pad1 : packoffset(c0.z);\n    float _4132_fa_pad2 : packoffset(c0.w);\n    float _4132_skyAmount : packoffset(c1);\n    float _4132_fa_pad3 : packoffset(c1.y);\n    float _4132_fa_pad4 : packoffset(c1.z);\n    float _4132_fa_pad5 : packoffset(c1.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t9);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1334 = _365_fa_cl_info.x < 0.0f;\n    bool _1341;\n    if (!_1334)\n    {\n        _1341 = _365_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1341 = _1334;\n    }\n    bool _1349;\n    if (!_1341)\n    {\n        _1349 = _365_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1349 = _1341;\n    }\n    bool _1356;\n    if (!_1349)\n    {\n        _1356 = _365_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1356 = _1349;\n    }\n    bool _1363;\n    if (!_1356)\n    {\n        _1363 = _365_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1363 = _1356;\n    }\n    if (_1363)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1373 = float4(world_pos, 1.0f);\n    float _1379 = dot(_365_fa_cl_vpw, _1373);\n    if (!(_1379 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1401 = float2(dot(_365_fa_cl_vpx, _1373), dot(_365_fa_cl_vpy, _1373)) / _1379.xx;\n    int _1405 = int(_365_fa_cl_grid.x);\n    int _1409 = int(_365_fa_cl_grid.y);\n    int param = (int(_365_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_365_fa_cl_fwd.xyz, world_pos) + _365_fa_cl_fwd.w, _365_fa_cl_grid.w) / _365_fa_cl_grid.w) * _365_fa_cl_grid.z)), 0, int(_365_fa_cl_info.y) - 1) * _1409) + clamp(int(floor(((_1401.y * 0.5f) + 0.5f) * _365_fa_cl_grid.y)), 0, _1409 - 1)) * _1405)) + clamp(int(floor(((_1401.x * 0.5f) + 0.5f) * _365_fa_cl_grid.x)), 0, _1405 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1485 = fa_cluster_texel(param);\n    return int2(int(_1485.x), int(_1485.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_365_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3881 = fa_cluster_lookup(param);\n    fa_cl_slot = _3881.x;\n    fa_cl_local = _3881.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _4193 = fa_linear_to_srgb(param);\n        c = _4193;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _4201 = fa_srgb_to_linear(param_1);\n            c = _4201;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _297;\n    if (i.front_facing)\n    {\n        _297 = i.world_normal;\n    }\n    else\n    {\n        _297 = -i.world_normal;\n    }\n    float3 _321 = normalize(i.world_tangent.xyz - (_297 * dot(_297, i.world_tangent.xyz)));\n    float3 _349 = normalize(((_321 * m.x) + ((cross(_297, _321) * i.world_tangent.w) * m.y)) + (_297 * m.z));\n    float3 _352;\n    if (i.front_facing)\n    {\n        _352 = _349;\n    }\n    else\n    {\n        _352 = -_349;\n    }\n    return _352;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _365_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _4232 = fa_tex_fix(param_2, param_3);\n    float4 _5255 = base_t;\n    _5255.x = _4232.x;\n    _5255.y = _4232.y;\n    _5255.z = _4232.z;\n    base_t = _5255;\n    float4 _4246 = (_5255 * _365_fa_base_color) * i.vertex_color;\n    float3 _5107 = i.world_normal;\n    if (_365_fa_maps.z > 0.5f)\n    {\n        float param_4 = _365_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4278 = fa_tex_fix(param_6, param_7);\n        float3 _4281 = (_4278 * 2.0f) - 1.0f.xxx;\n        float2 _4286 = _4281.xy * _365_fa_maps.x;\n        float3 _5263 = _4281;\n        _5263.x = _4286.x;\n        _5263.y = _4286.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5263;\n        _5107 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _365_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4314 = fa_tex_fix(param_12, param_13);\n    float4 _5266 = mrt;\n    _5266.x = _4314.x;\n    _5266.y = _4314.y;\n    _5266.z = _4314.z;\n    mrt = _5266;\n    float4 _4342 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _365_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _4342.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4353 = fa_tex_fix(param_16, param_17);\n    float param_18 = _365_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4383 = fa_tex_fix(param_20, param_21);\n    float _5112 = _365_fa_layers_a.x;\n    float _5113 = _365_fa_layers_a.y;\n    float _5116 = _365_fa_layers_a.z;\n    float _5115 = _365_fa_layers_b.w;\n    float _5118 = _365_fa_layers_c.x;\n    if (_365_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_365_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _5112 *= _4353.y;\n            _5113 *= _4353.z;\n            _5115 *= _4342.w;\n        }\n        if (_365_fa_layers_c.z > 1.5f)\n        {\n            _5116 *= mrt.x;\n            _5118 *= mrt.w;\n        }\n    }\n    Surface _5137 = { _4246.xyz, _4246.w, _5107, clamp(_365_fa_pbr.x * _4314.z, 0.0f, 1.0f), clamp(_365_fa_pbr.y * _4314.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_365_fa_maps.y * (_4353.x - 1.0f)), _365_fa_emissive.xyz + (_365_fa_model_emissive.xyz * _4383), _5112, _5113, _365_fa_layers_b.xyz, _5115, _5116, _365_fa_layers_a.w, _5118, _365_fa_layers_c.y, _365_fa_layers_d.xyz };\n    return _5137;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1565 = rect.zw - rect.xy;\n    float2 _1569 = _1565 * atlas;\n    float2 _1573 = ddx * _1569;\n    float2 _1577 = ddy * _1569;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1565), clamp(0.5f * log2(max(max(dot(_1573, _1573), dot(_1577, _1577)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1610 = _365_fa_counts.y < 0.5f;\n    bool _1617;\n    if (!_1610)\n    {\n        _1617 = _365_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1617 = _1610;\n    }\n    if (_1617)\n    {\n        return;\n    }\n    float3 _1623 = ddx(world_pos);\n    float3 _1626 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1630 = fa_cluster_texel(param);\n    int _1634 = int(_1630.w);\n    if (_1634 < 1)\n    {\n        return;\n    }\n    int _1644 = int(_365_fa_counts.y + 0.5f);\n    int param_1 = _1644;\n    float4 _1648 = fa_light_texel(param_1);\n    float2 _1651 = _1648.yz;\n    int _1655 = int(_1648.w);\n    int param_2 = _1644 + 1;\n    float4 _1660 = fa_light_texel(param_2);\n    float _1661 = _1660.x;\n    int _1667 = int(_365_fa_counts.w + 0.5f) - 1;\n    int _1671 = int(_1630.z);\n    float3 _1936;\n    for (int k = 0; k < _1634; k++)\n    {\n        int _1684 = _1671 + k;\n        int param_3 = _1655 + (_1684 >> 2);\n        int _1701 = (_1644 + 2) + (int(fa_light_texel(param_3)[_1684 & 3]) * 7);\n        int param_4 = _1701 + 6;\n        float4 _1706 = fa_light_texel(param_4);\n        if (((int(_1706.w + 0.5f) >> _1667) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1701;\n        float4 _1721 = fa_light_texel(param_5);\n        int param_6 = _1701 + 1;\n        float4 _1726 = fa_light_texel(param_6);\n        int param_7 = _1701 + 2;\n        float4 _1731 = fa_light_texel(param_7);\n        float3 _1734 = _1721.xyz;\n        float _1739 = dot(_1734, world_pos) + _1721.w;\n        float3 _1741 = _1726.xyz;\n        float _1746 = dot(_1741, world_pos) + _1726.w;\n        float3 _1748 = _1731.xyz;\n        float _1753 = dot(_1748, world_pos) + _1731.w;\n        bool _1758 = abs(_1739) > 0.5f;\n        bool _1766;\n        if (!_1758)\n        {\n            _1766 = abs(_1746) > 0.5f;\n        }\n        else\n        {\n            _1766 = _1758;\n        }\n        bool _1774;\n        if (!_1766)\n        {\n            _1774 = abs(_1753) > 0.5f;\n        }\n        else\n        {\n            _1774 = _1766;\n        }\n        if (_1774)\n        {\n            continue;\n        }\n        float _1789 = clamp(dot(geo_normal, normalize(_1748)) * _1706.z, 0.0f, 1.0f);\n        if (_1789 <= 0.0f)\n        {\n            continue;\n        }\n        float _1809 = (clamp((0.5f - abs(_1753)) * 10.0f, 0.0f, 1.0f) * _1789) * _1706.x;\n        float2 _1817 = float2(_1739 + 0.5f, 0.5f - _1746);\n        float2 _1827 = float2(dot(_1734, _1623), dot(_1741, _1623));\n        float2 _1837 = float2(dot(_1734, _1626), dot(_1741, _1626));\n        int param_8 = _1701 + 5;\n        float4 _1842 = fa_light_texel(param_8);\n        int param_9 = _1701 + 3;\n        float4 _1847 = fa_light_texel(param_9);\n        int param_10 = _1701 + 4;\n        float4 _1852 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1842.xyz;\n        bool _1862 = _1847.z > _1847.x;\n        if (_1862)\n        {\n            float4 param_11 = _1847;\n            float2 param_12 = _1817;\n            float2 param_13 = _1651;\n            float2 param_14 = _1827;\n            float2 param_15 = _1837;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1661 > 0.5f) && (_1661 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1888 = fa_dc_to_linear(param_16);\n                float4 _5187 = tx;\n                _5187.x = _1888.x;\n                _5187.y = _1888.y;\n                _5187.z = _1888.z;\n                tx = _5187;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1809 * tex_a) * _1842.w, 0.0f, 1.0f).xxx);\n        if (_1852.z > _1852.x)\n        {\n            float4 param_17 = _1852;\n            float2 param_18 = _1817;\n            float2 param_19 = _1651;\n            float2 param_20 = _1827;\n            float2 param_21 = _1837;\n            float4 _1932 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1661 > 1.5f)\n            {\n                float3 param_22 = _1932.xyz;\n                float3 _1942 = fa_dc_to_srgb(param_22);\n                _1936 = _1942;\n            }\n            else\n            {\n                _1936 = _1932.xyz;\n            }\n            float3 _1951 = (_1936 * 2.0f) - 1.0f.xxx;\n            float2 _1956 = _1951.xy * _1706.y;\n            float3 _1978 = (normalize(_1734) * _1956.x) + (normalize(_1741) * _1956.y);\n            float3 _1981 = normalize(normal);\n            normal = normalize(lerp(_1981, normalize((_1981 * max(_1951.z, 0.0500000007450580596923828125f)) + (_1978 - (_1981 * dot(_1981, _1978)))), clamp(_1809 * (_1862 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return _5292;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_365_fa_cl_info.x) + int(_365_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_365_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _427_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _427_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _593 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _606 = (c - (ru * hx)) - p;\n        float3 _612 = ru * (2.0f * hx);\n        float _618 = max(dot(_612, _612), 9.9999999392252902907785028219223e-09f);\n        float _622 = dot(_606, _612);\n        float t = clamp((-_622) / _618, 0.0f, 1.0f);\n        if (_593)\n        {\n            float _637 = dot(r, _612);\n            float _643 = _618 - (_637 * _637);\n            if (abs(_643) > (9.9999997473787516355514526367188e-06f * _618))\n            {\n                t = clamp(((dot(r, _606) * _637) - _622) / _643, 0.0f, 1.0f);\n            }\n        }\n        return (p + _606) + (_612 * t);\n    }\n    float3 q = p;\n    float _675 = dot(r, axis);\n    bool _683;\n    if (_593)\n    {\n        _683 = abs(_675) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _683 = _593;\n    }\n    if (_683)\n    {\n        float _693 = dot(c - p, axis) / _675;\n        if (_693 > 0.0f)\n        {\n            q = p + (r * _693);\n        }\n    }\n    float3 _706 = q - c;\n    float2 xy = float2(dot(_706, ru), dot(_706, uu));\n    if (shape > 0.5f)\n    {\n        float _721 = length(xy);\n        if (_721 > hx)\n        {\n            xy *= (hx / _721);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _514 = abs(d);\n    float _516 = _514.x;\n    float _518 = _514.y;\n    bool _519 = _516 >= _518;\n    bool _527;\n    if (_519)\n    {\n        _527 = _516 >= _514.z;\n    }\n    else\n    {\n        _527 = _519;\n    }\n    int _528;\n    if (_527)\n    {\n        _528 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _541;\n        if (_518 >= _514.z)\n        {\n            _541 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _541 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _528 = _541;\n    }\n    return _528;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _467 = dot(d, right);\n    float _471 = dot(d, up);\n    float _482;\n    if (((_467 * _467) + (_471 * _471)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _482 = atan2(_471, _467) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _482 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_482 - floor(_482)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _759 = fa_light_base(param);\n    bool _763 = _365_fa_ambient.w > 4.5f;\n    int param_1 = _759;\n    float4 _767 = fa_light_texel(param_1);\n    int param_2 = _759 + 1;\n    float4 _772 = fa_light_texel(param_2);\n    float _775 = _772.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _787 = _763 && (_775 > 2.5f);\n    fa_light_is_area = _787;\n    bool _789 = _775 < 0.5f;\n    float3 l;\n    if (_789)\n    {\n        l = normalize(_767.xyz);\n        if (_763)\n        {\n            int param_3 = _759 + 6;\n            float4 _803 = fa_light_texel(param_3);\n            if (_803.z > 0.5f)\n            {\n                int param_4 = _759 + 4;\n                float4 _813 = fa_light_texel(param_4);\n                int param_5 = _759 + 5;\n                float4 _818 = fa_light_texel(param_5);\n                float2 param_6 = _803.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _813.xyz) * _813.w, (-dot(world_pos, _818.xyz)) * _818.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _848 = _767.xyz;\n        float3 _850 = _848 - world_pos;\n        float3 to_light = _850;\n        float _853 = length(_850);\n        float reach = _853;\n        bool front = true;\n        if (_787)\n        {\n            int param_8 = _759 + 7;\n            reach = max(_853 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _759 + 4;\n            float4 _877 = fa_light_texel(param_9);\n            int param_10 = _759 + 5;\n            float4 _882 = fa_light_texel(param_10);\n            int param_11 = _759 + 6;\n            float4 _887 = fa_light_texel(param_11);\n            float _888 = _887.w;\n            int param_12 = _759 + 2;\n            float3 _895 = normalize(fa_light_texel(param_12).xyz);\n            bool _897 = _888 > 1.5f;\n            bool _905;\n            if (!_897)\n            {\n                _905 = dot(_895, to_light) < 0.0f;\n            }\n            else\n            {\n                _905 = _897;\n            }\n            front = _905;\n            float3 r = 0.0f.xxx;\n            if (dot(n, n) > 0.5f)\n            {\n                r = reflect(-normalize(_365_fa_camera_pos.xyz - world_pos), normalize(n));\n            }\n            float3 param_13 = _848;\n            float3 param_14 = _895;\n            float3 param_15 = _877.xyz;\n            float3 param_16 = _882.xyz;\n            float param_17 = _877.w;\n            float param_18 = _882.w;\n            float param_19 = _888;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _952 = length(to_light);\n        dist = _952;\n        l = to_light / max(_952, 9.9999997473787516355514526367188e-05f).xxx;\n        float _966 = reach / max(_767.w, 0.001000000047497451305389404296875f);\n        float _972 = clamp(1.0f - (_966 * _966), 0.0f, 1.0f);\n        float _974;\n        if (front)\n        {\n            _974 = _972 * _972;\n        }\n        else\n        {\n            _974 = 0.0f;\n        }\n        atten = _974;\n        bool _985 = _775 < 2.5f;\n        if ((_775 > 1.5f) && _985)\n        {\n            int param_22 = _759 + 2;\n            float4 _993 = fa_light_texel(param_22);\n            float _1003 = _993.w;\n            int param_23 = _759 + 3;\n            float4 _1008 = fa_light_texel(param_23);\n            float _1009 = _1008.x;\n            float cos_inner = _1009;\n            if (_1009 > 1.5f)\n            {\n                cos_inner = lerp(_1003, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1003, cos_inner, dot(-l, normalize(_993.xyz)));\n        }\n        if (_763 && (_775 < 1.5f))\n        {\n            int param_24 = _759 + 6;\n            float4 _1033 = fa_light_texel(param_24);\n            if (_1033.z > 0.5f)\n            {\n                float3 _1041 = -to_light;\n                int param_25 = _759 + 4;\n                int param_26 = _759 + 5;\n                float3 _1055 = fa_light_texel(param_25).xyz;\n                float3 _1059 = fa_light_texel(param_26).xyz;\n                float3 _1068 = float3(dot(_1041, _1055), dot(_1041, _1059), dot(_1041, cross(_1055, _1059)));\n                float3 param_27 = _1068;\n                int _1072 = fa_cube_face(param_27);\n                int param_28 = _1072;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1099 = float2(dot(_1068, cross(param_29, param_30)), dot(_1068, param_30)) / max(dot(_1068, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1103 = _1072 / 3;\n                float2 param_31 = _1033.xy + (float2(float(_1072 - (_1103 * 3)), float(_1103)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1099.x), 0.5f - (0.5f * _1099.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _759 + 7;\n            float4 _1133 = fa_light_texel(param_33);\n            if (_1133.z > 0.5f)\n            {\n                int param_34 = _759 + 2;\n                int param_35 = _759 + 4;\n                int param_36 = _759 + 5;\n                float2 param_37 = _1133.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_763 && _985)\n            {\n                int param_42 = _759 + 6;\n                float4 _1180 = fa_light_texel(param_42);\n                int param_43 = _759 + 7;\n                float4 _1185 = fa_light_texel(param_43);\n                bool _1188 = _1180.z > 0.5f;\n                bool _1195;\n                if (!_1188)\n                {\n                    _1195 = _1185.z > 0.5f;\n                }\n                else\n                {\n                    _1195 = _1188;\n                }\n                if (_1195)\n                {\n                    int param_44 = _759 + 2;\n                    float4 _1202 = fa_light_texel(param_44);\n                    float3 _1206 = normalize(_1202.xyz);\n                    int param_45 = _759 + 4;\n                    float4 _1211 = fa_light_texel(param_45);\n                    int param_46 = _759 + 5;\n                    float4 _1216 = fa_light_texel(param_46);\n                    if (_1188)\n                    {\n                        float3 _1224 = -to_light;\n                        float _1231 = _1202.w;\n                        float _1247 = 0.5f / max(dot(_1224, _1206) * (sqrt(max(1.0f - (_1231 * _1231), 0.0f)) / max(_1231, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1180.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1224, _1211.xyz) * _1247), 0.5f - (dot(_1224, _1216.xyz) * _1247));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1185.z > 0.5f)\n                    {\n                        float2 param_49 = _1185.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1206;\n                        float3 param_52 = _1211.xyz;\n                        float3 param_53 = _1216.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4932 = _772.xyz * atten;\n    if (_763)\n    {\n        _4932 *= fa_light_tint;\n    }\n    int _1316;\n    if (_789)\n    {\n        _1316 = 0;\n    }\n    else\n    {\n        _1316 = ((_775 > 1.5f) && (_775 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _4943 = { l, _4932, atten, 1.0f, dist, _1316 };\n    return _4943;\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _4024 = n < 0;\n    bool _4031;\n    if (!_4024)\n    {\n        _4031 = n >= fa_light_count();\n    }\n    else\n    {\n        _4031 = _4024;\n    }\n    if (_4031)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _4039 = fa_cl_light(param);\n    bool _4042 = fa_lm.z > 0.5f;\n    bool _4048;\n    if (_4042)\n    {\n        int param_1 = _4039;\n        _4048 = fa_light_baked(param_1);\n    }\n    else\n    {\n        _4048 = _4042;\n    }\n    if (_4048)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _4039;\n    float3 param_3 = i.world_pos;\n    float3 param_4 = i.world_normal;\n    LightSample _4061 = fa_light_sample_n(param_2, param_3, param_4);\n    return _4061;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2053;\n    if (i == 0)\n    {\n        _2053 = _2063_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2069;\n        if (i == 1)\n        {\n            _2069 = _2063_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2077;\n            if (i == 2)\n            {\n                _2077 = _2063_fa_shadow_split.z;\n            }\n            else\n            {\n                _2077 = _2063_fa_shadow_split.w;\n            }\n            _2069 = _2077;\n        }\n        _2053 = _2069;\n    }\n    return _2053;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2110 = fa_shadow_depth(param, param_1);\n    float _2114;\n    if (conv.x < 0.5f)\n    {\n        _2114 = _2110;\n    }\n    else\n    {\n        _2114 = (conv.y * conv.z) / (conv.z - (_2110 * (conv.z - conv.y)));\n    }\n    return _2114;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2041 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2041), sin(_2041)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2160 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2169;\n        if (k < 0.0f)\n        {\n            _2169 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2169 = k;\n        }\n        float _2189 = clamp((_2169 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2160;\n            float2 _2208 = fa_shadow_vogel(param_3, param_4, param_5) * _2189;\n            float2 param_6 = uv + (_2208 * _2063_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2220 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2220 < (zr - (length(_2208) * plane)))\n            {\n                sum += _2220;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2246 = sum / cnt;\n        float _2256;\n        if (k < 0.0f)\n        {\n            _2256 = (-k) / max(_2246, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2256 = k;\n        }\n        radius = clamp(((max(zr - _2246, 0.0f) * unit) * _2256) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2278 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2278; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2278;\n        float param_11 = _2160;\n        float2 _2297 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2297 * _2063_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2297) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2278);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2339 = max(_2063_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2344 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2350 = sqrt(1.0f - (_2344 * _2344));\n    float _2357 = min(_2350 / max(_2344, 0.20000000298023223876953125f), 4.0f);\n    float _2362;\n    if (_2063_fa_shadow_bias.y > 0.0f)\n    {\n        _2362 = _2063_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2362 = 1.5f * _2063_fa_shadow_info[ci].x;\n    }\n    float4 _2387 = mul(float4(world + (n * (_2362 * _2350)), 1.0f), _2063_fa_shadow_mat[ci]);\n    float _2394 = _2387.x;\n    bool _2397 = _2394 < _2063_fa_shadow_rect[ci].x;\n    bool _2406;\n    if (!_2397)\n    {\n        _2406 = _2394 > _2063_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2406 = _2397;\n    }\n    bool _2415;\n    if (!_2406)\n    {\n        _2415 = _2387.y < _2063_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2415 = _2406;\n    }\n    bool _2424;\n    if (!_2415)\n    {\n        _2424 = _2387.y > _2063_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2424 = _2415;\n    }\n    bool _2431;\n    if (!_2424)\n    {\n        _2431 = _2387.z > 1.0f;\n    }\n    else\n    {\n        _2431 = _2424;\n    }\n    if (_2431)\n    {\n        return -1.0f;\n    }\n    float _2439;\n    if (_2063_fa_shadow_bias.x > 0.0f)\n    {\n        _2439 = _2063_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2439 = 1.5f * _2063_fa_shadow_info[ci].x;\n    }\n    float2 param = _2387.xy;\n    float4 param_1 = _2063_fa_shadow_rect[ci];\n    float param_2 = _2387.z - ((_2439 * (1.0f + (0.5f * _2357))) / _2339);\n    float param_3 = _2063_fa_shadow_info[ci].x;\n    float param_4 = _2339;\n    float param_5 = _2339 * 0.25f;\n    float param_6 = ((_2063_fa_shadow_info[ci].x * min(_2357, 3.0f)) * 0.5f) / _2339;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2063_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2063_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_365_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2827 = int(_2063_fa_shadow_cfg.x + 0.5f);\n    if (_2827 < 1)\n    {\n        return 1.0f;\n    }\n    float _2842 = dot(world - _2063_fa_shadow_eye.xyz, _2063_fa_shadow_fwd.xyz);\n    int param = _2827 - 1;\n    if (_2842 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2854 = _2827 > 1;\n    bool _2861;\n    if (_2854)\n    {\n        _2861 = _2842 > _2063_fa_shadow_split.x;\n    }\n    else\n    {\n        _2861 = _2854;\n    }\n    if (_2861)\n    {\n        ci = 1;\n    }\n    bool _2865 = _2827 > 2;\n    bool _2872;\n    if (_2865)\n    {\n        _2872 = _2842 > _2063_fa_shadow_split.y;\n    }\n    else\n    {\n        _2872 = _2865;\n    }\n    if (_2872)\n    {\n        ci = 2;\n    }\n    bool _2876 = _2827 > 3;\n    bool _2883;\n    if (_2876)\n    {\n        _2883 = _2842 > _2063_fa_shadow_split.z;\n    }\n    else\n    {\n        _2883 = _2876;\n    }\n    if (_2883)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2827)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2909 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2909;\n        if (_2909 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2063_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2934;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2934 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2934 = _2063_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2953 = _2063_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2934, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2964 = clamp((_2842 - (fa_shadow_split_at(param_7) - _2953)) / _2953, 0.0f, 1.0f);\n        if (_2964 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2827)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2985 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2985;\n                if (_2985 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2964);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _2497 = _365_fa_pbr.z < 0.5f;\n    bool _2504;\n    if (!_2497)\n    {\n        _2504 = _2063_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2504 = _2497;\n    }\n    if (_2504)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2063_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2517 = fa_light_texel(param);\n    float _2518 = _2517.x;\n    if (_2518 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2527 = int(_2518 + 0.5f);\n    int param_1 = _2527;\n    float4 _2531 = fa_light_texel(param_1);\n    int param_2 = _2527 + 1;\n    float4 _2536 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2539 = _2531.y;\n    if (_2539 > 0.0f)\n    {\n        float _2556 = 1.0f - smoothstep(0.75f * _2539, _2539, length(world - _2063_fa_shadow_eye.xyz));\n        fade = _2556;\n        if (_2556 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2531.x > 1.5f)\n    {\n        int param_3 = li;\n        int param_4 = fa_light_base(param_3);\n        float3 param_5 = world - fa_light_texel(param_4).xyz;\n        face = fa_cube_face(param_5);\n    }\n    int _2585 = (_2527 + 2) + (face * 6);\n    int param_6 = _2585;\n    int param_7 = _2585 + 1;\n    int param_8 = _2585 + 3;\n    float4 _2599 = fa_light_texel(param_8);\n    int param_9 = _2585 + 4;\n    float4 _2604 = fa_light_texel(param_9);\n    int param_10 = _2585 + 5;\n    float4 _2609 = fa_light_texel(param_10);\n    float _2621 = _2609.x * max(dot(_2599, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2626 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2649 = clamp(dot(n, _2599.xyz), -1.0f, 1.0f);\n    int param_11 = li;\n    int param_12 = fa_light_base(param_11);\n    float _2673 = min(sqrt(1.0f - (_2649 * _2649)) / max(abs(dot(n, world - fa_light_texel(param_12).xyz)) / max(dot(_2599, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2676 = _2536.y;\n    float _2678;\n    if (_2676 > 0.0f)\n    {\n        _2678 = _2676;\n    }\n    else\n    {\n        _2678 = 1.5f * _2621;\n    }\n    float4 _2698 = float4(world + (n * (_2678 * sqrt(1.0f - (_2626 * _2626)))), 1.0f);\n    float _2702 = dot(_2599, _2698);\n    float _2705 = _2609.y;\n    if (_2702 < _2705)\n    {\n        return 1.0f;\n    }\n    float2 _2720 = float2(dot(fa_light_texel(param_6), _2698), dot(fa_light_texel(param_7), _2698)) / _2702.xx;\n    float _2722 = _2720.x;\n    bool _2725 = _2722 < _2604.x;\n    bool _2734;\n    if (!_2725)\n    {\n        _2734 = _2722 > _2604.z;\n    }\n    else\n    {\n        _2734 = _2725;\n    }\n    bool _2743;\n    if (!_2734)\n    {\n        _2743 = _2720.y < _2604.y;\n    }\n    else\n    {\n        _2743 = _2734;\n    }\n    bool _2752;\n    if (!_2743)\n    {\n        _2752 = _2720.y > _2604.w;\n    }\n    else\n    {\n        _2752 = _2743;\n    }\n    if (_2752)\n    {\n        return 1.0f;\n    }\n    float _2758 = _2536.x;\n    float _2760;\n    if (_2758 > 0.0f)\n    {\n        _2760 = _2758;\n    }\n    else\n    {\n        _2760 = 1.5f * _2621;\n    }\n    float2 param_13 = _2720;\n    float4 param_14 = _2604;\n    float param_15 = _2702 - (_2760 * (1.0f + (0.5f * _2673)));\n    float param_16 = _2621;\n    float param_17 = 1.0f;\n    float param_18 = _2609.z * 0.25f;\n    float param_19 = (_2621 * min(_2673, 3.0f)) * 0.5f;\n    float3 param_20 = float3(1.0f, _2705, _2609.z);\n    int param_21 = int(_2531.z + 0.5f);\n    float param_22 = _2531.w;\n    return lerp(1.0f, fa_shadow_filter(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _3908 = fa_lm.z > 0.5f;\n    bool _3914;\n    if (_3908)\n    {\n        int param = li;\n        _3914 = fa_light_baked(param);\n    }\n    else\n    {\n        _3914 = _3908;\n    }\n    if (_3914)\n    {\n        int param_1 = li;\n        LightSample _5076 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _5076;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3938 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _5078 = _3938.color;\n    float _5080 = _3938.shadow;\n    if ((_3938.type == 0) && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3938.direction;\n        float _3952 = fa_shadow_factor(param_5, param_6);\n        _5080 = _3952;\n        _5078 *= _3952;\n    }\n    else\n    {\n        bool _3963 = _3938.type != 0;\n        bool _3969;\n        if (_3963)\n        {\n            _3969 = _3938.attenuation > 0.0f;\n        }\n        else\n        {\n            _3969 = _3963;\n        }\n        if (_3969)\n        {\n            int param_7 = li;\n            float3 param_8 = world_pos;\n            float3 param_9 = gn;\n            float3 param_10 = _3938.direction;\n            float _3981 = fa_shadow_local(param_7, param_8, param_9, param_10);\n            _5080 = _3981;\n            _5078 *= _3981;\n        }\n    }\n    LightSample _5095 = { _3938.direction, _5078, _3938.attenuation, _5080, _3938._distance, _3938.type };\n    return _5095;\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _3998 = n < 0;\n    bool _4005;\n    if (!_3998)\n    {\n        _4005 = n >= fa_light_count();\n    }\n    else\n    {\n        _4005 = _3998;\n    }\n    if (_4005)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    LightSample _4020 = fa_light_shadowed(param_1, param_2, param_3);\n    return _4020;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3264 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3272 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3275 = int(_3264);\n    int _3278 = int(_3272);\n    float _3288 = _3272 - float(_3278);\n    int _3344 = (_3275 * 9) + _3278;\n    int _3364 = ((_3275 + 1) * 9) + _3278;\n    return lerp(lerp(_3339[_3344], _3339[_3344 + 1], _3288), lerp(_3339[_3364], _3339[_3364 + 1], _3288), _3264 - float(_3275));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _4944 = false;\n    float _4945 = 1.0f;\n    float _4946 = 1.0f;\n    float _4947 = 1.0f;\n    float _4948 = 0.0f;\n    float _4949 = 0.0f;\n    float _4950 = 0.0f;\n    float _4951 = 0.0f;\n    float _4953 = 1.0f;\n    bool _4954 = false;\n    float3 _4955 = 0.0f.xxx;\n    float _4956 = 1.0f;\n    float _4957 = 1.0f;\n    float _4958 = 1.0f;\n    float _4959 = 0.0f;\n    float _4960 = 0.0f;\n    float3 _4961 = float3(1.0f, 0.0f, 0.0f);\n    float3 _4962 = float3(0.0f, 0.0f, 1.0f);\n    float _4963 = 1.0f;\n    float _4964 = 1.0f;\n    float _3415 = clamp(s.specular, 0.0f, 1.0f);\n    float _3419 = clamp(s.ior, 1.0f, 3.0f);\n    bool _3424 = (_3415 != 1.0f) || (_3419 != 1.5f);\n    bool _3433;\n    if (!_3424)\n    {\n        _3433 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _3433 = _3424;\n    }\n    if (_3433)\n    {\n        float _3441 = (_3419 - 1.0f) / (_3419 + 1.0f);\n        f0 = lerp(min((_3441 * _3441).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _3415, s.albedo, metallic.xxx);\n        _4945 = lerp(_3415, 1.0f, metallic);\n        _4944 = true;\n    }\n    float _3468 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_3468 > 0.0f)\n    {\n        float _3476 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _4948 = _3468;\n        _4949 = _3476;\n        float _3483 = _3476 * _3476;\n        _4950 = _3483;\n        _4951 = _3483 * _3483;\n        float _3495 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _4953 = _3495;\n        _4946 = 1.0f - (_3468 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _3495, 0.0f, 1.0f), 5.0f))));\n        _4944 = true;\n    }\n    float3 _3515 = max(s.sheen_color, 0.0f.xxx);\n    float _3524 = max(_3515.x, max(_3515.y, _3515.z));\n    if (_3524 > 0.0f)\n    {\n        float _3532 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _4954 = true;\n        _4955 = _3515;\n        _4956 = _3532;\n        _4957 = _3532 * _3532;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _3532;\n        float _3549 = fa_sheen_albedo(param, param_1);\n        _4959 = _3549;\n        _4958 = 1.0f - min(_3524 * _3549, 1.0f);\n        _4944 = true;\n    }\n    _4947 = _4946 * _4958;\n    float _3568 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_3568 != 0.0f)\n    {\n        float3 _3583 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _3583;\n        if (dot(_3583, _3583) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _3595 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_3595.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _3595.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _3595.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _3599 = t;\n        float3 _3600 = normalize(_3599);\n        t = _3600;\n        float3 _3625 = normalize((_3600 * cos(s.anisotropy_rotation)) + ((cross(n, _3600) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _4961 = _3625;\n        _4962 = cross(n, _3625);\n        float _3635 = roughness * roughness;\n        float _3641 = lerp(_3635, 1.0f, _3568 * _3568);\n        bool _3643 = _3568 > 0.0f;\n        _4963 = _3643 ? _3641 : _3635;\n        _4964 = _3643 ? _3635 : _3641;\n        _4960 = _3568;\n        _4944 = true;\n    }\n    FaLayers _4986 = { _4944, _4945, _4946, _4947, _4948, _4949, _4950, _4951, i.world_normal, _4953, _4954, _4955, _4956, _4957, _4958, _4959, _4960, _4961, _4962, _4963, _4964 };\n    return _4986;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3196 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3199 = _3196.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3199 * _3199, exp2((-9.27999973297119140625f) * ndv)) * _3199) + _3196.y)) + _3196.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_365_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _365_fa_env_horizon.w).xyz;\n    }\n    float _3120 = rough * rough;\n    float _3150 = 0.60000002384185791015625f * _3120;\n    return lerp(lerp(_365_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_365_fa_env_horizon.xyz, _365_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3120)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3150, 0.0500000007450580596923828125f + _3150, d.y).xxx), ((_365_fa_env_sky.xyz + _365_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3120 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _3676;\n        if (L.aniso >= 0.0f)\n        {\n            _3676 = L.b;\n        }\n        else\n        {\n            _3676 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_3676, v), _3676), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3709 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _3709.x) + (L.f90.xxx * _3709.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3764 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _3764.x) + _3764.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3238 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3238.x) + _3238.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _3803 = clamp(s.metallic, 0.0f, 1.0f);\n    float _3807 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _3814 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _3803.xxx);\n    float3 f0 = _3814;\n    float3 _3818 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _3818;\n    float3 param_3 = i.view_dir;\n    float param_4 = _3803;\n    float param_5 = _3807;\n    float3 param_6 = _3814;\n    FaLayers _3835 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_3835.on)\n    {\n        FaLayers param_7 = _3835;\n        float3 param_8 = _3818;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _3807;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _3818;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _3807;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0f;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _4081 = fa_light_unshadowed(param, param_1);\n        float _4089 = dot(_4081.color, float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));\n        if (_4089 > bestPower)\n        {\n            bestPower = _4089;\n            best = n;\n        }\n    }\n    float3 lit = (_365_fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _4118 = fa_light(param_2, param_3);\n        float _4126;\n        if (dot(s.normal, _4118.direction) > 0.5f)\n        {\n            _4126 = 1.0f;\n        }\n        else\n        {\n            _4126 = _4132_dark;\n        }\n        lit += ((s.albedo * _4118.color) * _4126);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * _4132_skyAmount);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2063_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3009 = int(_2063_fa_shadow_cfg.x + 0.5f);\n    float _3019 = dot(world - _2063_fa_shadow_eye.xyz, _2063_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3024 = _3009 > 0;\n    bool _3033;\n    if (_3024)\n    {\n        int param = _3009 - 1;\n        _3033 = _3019 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3033 = _3024;\n    }\n    if (_3033)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3039 = _3009 > 1;\n        bool _3046;\n        if (_3039)\n        {\n            _3046 = _3019 > _2063_fa_shadow_split.x;\n        }\n        else\n        {\n            _3046 = _3039;\n        }\n        if (_3046)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3052 = _3009 > 2;\n        bool _3059;\n        if (_3052)\n        {\n            _3059 = _3019 > _2063_fa_shadow_split.y;\n        }\n        else\n        {\n            _3059 = _3052;\n        }\n        if (_3059)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3065 = _3009 > 3;\n        bool _3072;\n        if (_3065)\n        {\n            _3072 = _3019 > _2063_fa_shadow_split.z;\n        }\n        else\n        {\n            _3072 = _3065;\n        }\n        if (_3072)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _4818 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4818 = -_4818;\n    }\n    float3 _4504 = normalize(_365_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _4831 = { fa_world_pos, _4818, fa_world_tangent, fa_uv, fa_vertex_color, _4504, gl_FrontFacing };\n    SurfaceInput param_1 = _4831;\n    Surface _4512 = fa_standard_surface(param_1);\n    float3 _4849 = _4512.albedo;\n    float _4850 = _4512.alpha;\n    float3 _4851 = _4512.normal;\n    float _4852 = _4512.metallic;\n    float _4853 = _4512.roughness;\n    float _4854 = _4512.occlusion;\n    float3 _4855 = _4512.emission;\n    float _4856 = _4512.clearcoat;\n    float _4857 = _4512.clearcoat_roughness;\n    float3 _4858 = _4512.sheen_color;\n    float _4859 = _4512.sheen_roughness;\n    float _4860 = _4512.anisotropy;\n    float _4861 = _4512.anisotropy_rotation;\n    float _4862 = _4512.specular;\n    float _4863 = _4512.ior;\n    float3 _4864 = _4512.specular_color;\n    SurfaceInput _4839 = { fa_world_pos, _4818, fa_world_tangent, fa_uv, fa_vertex_color, _4504, gl_FrontFacing };\n    SurfaceInput param_2 = _4839;\n    Surface param_3 = _4512;\n    surface(param_2, param_3);\n    _4849 = param_3.albedo;\n    _4850 = param_3.alpha;\n    _4851 = param_3.normal;\n    _4852 = param_3.metallic;\n    _4853 = param_3.roughness;\n    _4854 = param_3.occlusion;\n    _4855 = param_3.emission;\n    _4856 = param_3.clearcoat;\n    _4857 = param_3.clearcoat_roughness;\n    _4858 = param_3.sheen_color;\n    _4859 = param_3.sheen_roughness;\n    _4860 = param_3.anisotropy;\n    _4861 = param_3.anisotropy_rotation;\n    _4862 = param_3.specular;\n    _4863 = param_3.ior;\n    _4864 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _4818;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4849 = param_6;\n    _4851 = param_7;\n    float3 result;\n    if (_365_fa_emissive.w > 0.5f)\n    {\n        result = _4849;\n    }\n    else\n    {\n        float3 _4550 = _4851;\n        float3 _4551 = normalize(_4550);\n        _4851 = _4551;\n        SurfaceInput _4847 = { fa_world_pos, _4818, fa_world_tangent, fa_uv, fa_vertex_color, _4504, gl_FrontFacing };\n        SurfaceInput param_8 = _4847;\n        Surface _4930 = { _4849, _4850, _4551, _4852, _4853, _4854, _4855, _4856, _4857, _4858, _4859, _4860, _4861, _4862, _4863, _4864 };\n        Surface param_9 = _4930;\n        float3 _4562 = lighting(param_8, param_9);\n        result = _4562;\n    }\n    float3 _4566 = result;\n    float3 _4567 = _4566 + _4855;\n    result = _4567;\n    float3 param_10 = _4567;\n    float3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _4576 = _365_fa_fog.w > 0.0f;\n    bool _4583;\n    if (!_4576)\n    {\n        _4583 = _365_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _4583 = _4576;\n    }\n    if (_4583)\n    {\n        float3 _4592 = fa_world_pos - _365_fa_camera_pos.xyz;\n        float _4598 = dot(_4592, _365_fa_fog_c.xyz);\n        bool _4602 = _365_fa_fog_c.w > 0.5f;\n        float _4603;\n        if (_4602)\n        {\n            _4603 = _4598;\n        }\n        else\n        {\n            _4603 = length(_4592);\n        }\n        float _4615 = _4603 - _365_fa_fog_b.x;\n        if (_4615 > 0.0f)\n        {\n            float _4624 = _365_fa_fog.w * _4615;\n            float tau = _4624 * _4624;\n            if (_365_fa_fog_b.y > 0.0f)\n            {\n                float _4640;\n                if (_4602)\n                {\n                    _4640 = fa_world_pos.y - (_365_fa_fog_c.y * _4598);\n                }\n                else\n                {\n                    _4640 = _365_fa_camera_pos.y;\n                }\n                float _4661 = lerp(_4640, fa_world_pos.y, clamp(_365_fa_fog_b.x / _4603, 0.0f, 1.0f));\n                float _4665 = fa_world_pos.y - _4661;\n                float _4670 = _4661 - _365_fa_fog_b.z;\n                float _4675 = fa_world_pos.y - _365_fa_fog_b.z;\n                bool _4678 = _4670 <= 0.0f;\n                bool _4679 = !_4678;\n                bool _4685;\n                if (_4679)\n                {\n                    _4685 = _365_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4685 = _4678;\n                }\n                float _4686;\n                if (_4685)\n                {\n                    _4686 = _365_fa_fog_b.y;\n                }\n                else\n                {\n                    _4686 = _365_fa_fog_b.y * exp(-min(_365_fa_fog_b.w * _4670, 80.0f));\n                }\n                bool _4713;\n                if (_4679)\n                {\n                    _4713 = _365_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4713 = _4678;\n                }\n                float _4714;\n                if (_4713)\n                {\n                    _4714 = _365_fa_fog_b.y * _4670;\n                }\n                else\n                {\n                    _4714 = (_365_fa_fog_b.y * (1.0f - exp(-min(_365_fa_fog_b.w * _4670, 80.0f)))) / _365_fa_fog_b.w;\n                }\n                bool _4739 = _4675 <= 0.0f;\n                bool _4746;\n                if (!_4739)\n                {\n                    _4746 = _365_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4746 = _4739;\n                }\n                float _4747;\n                if (_4746)\n                {\n                    _4747 = _365_fa_fog_b.y * _4675;\n                }\n                else\n                {\n                    _4747 = (_365_fa_fog_b.y * (1.0f - exp(-min(_365_fa_fog_b.w * _4675, 80.0f)))) / _365_fa_fog_b.w;\n                }\n                float _4774;\n                if (abs(_4665) < 0.001000000047497451305389404296875f)\n                {\n                    _4774 = _4686;\n                }\n                else\n                {\n                    _4774 = (_4747 - _4714) / _4665;\n                }\n                tau += (_4615 * max(_4774, 0.0f));\n            }\n            result = lerp(result, _365_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4850);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_365",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2063",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_4132",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _788 = base_t;\n    _788.x = _225.x;\n    _788.y = _225.y;\n    _788.z = _225.z;\n    base_t = _788;\n    float4 _241 = (_788 * _213_fa_base_color) * i.vertex_color;\n    float3 _751 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _796 = _279;\n        _796.x = _284.x;\n        _796.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _796;\n        _751 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _799 = mrt;\n    _799.x = _313.x;\n    _799.y = _313.y;\n    _799.z = _313.z;\n    mrt = _799;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _756 = _213_fa_layers_a.x;\n    float _757 = _213_fa_layers_a.y;\n    float _760 = _213_fa_layers_a.z;\n    float _759 = _213_fa_layers_b.w;\n    float _762 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _756 *= _355.y;\n            _757 *= _355.z;\n            _759 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _760 *= mrt.x;\n            _762 *= mrt.w;\n        }\n    }\n    Surface _781 = { _241.xyz, _241.w, _751, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _756, _757, _213_fa_layers_b.xyz, _759, _760, _213_fa_layers_a.w, _762, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _781;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _662 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _662 = -_662;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _675 = { fa_world_pos, _662, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _675;\n    SurfaceInput _683 = { fa_world_pos, _662, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _683;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_213",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _788 = base_t;\n    _788.x = _225.x;\n    _788.y = _225.y;\n    _788.z = _225.z;\n    base_t = _788;\n    float4 _241 = (_788 * _213_fa_base_color) * i.vertex_color;\n    float3 _751 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _796 = _279;\n        _796.x = _284.x;\n        _796.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _796;\n        _751 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _799 = mrt;\n    _799.x = _313.x;\n    _799.y = _313.y;\n    _799.z = _313.z;\n    mrt = _799;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _756 = _213_fa_layers_a.x;\n    float _757 = _213_fa_layers_a.y;\n    float _760 = _213_fa_layers_a.z;\n    float _759 = _213_fa_layers_b.w;\n    float _762 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _756 *= _355.y;\n            _757 *= _355.z;\n            _759 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _760 *= mrt.x;\n            _762 *= mrt.w;\n        }\n    }\n    Surface _781 = { _241.xyz, _241.w, _751, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _756, _757, _213_fa_layers_b.xyz, _759, _760, _213_fa_layers_a.w, _762, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _781;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _662 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _662 = -_662;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _675 = { fa_world_pos, _662, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _675;\n    SurfaceInput _683 = { fa_world_pos, _662, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _683;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_213",
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
