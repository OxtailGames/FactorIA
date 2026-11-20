{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "fc5698cd941e0af057040ef4c307a7106b1e2971cc74f7501935817daedb7ce8",
  "slang": "hlsl5",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _263 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _263;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_270, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _3349[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\nstatic const LightSample _5302 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, 0 };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _365_fa_camera_pos : packoffset(c0);\n    float4 _365_fa_ambient : packoffset(c1);\n    float4 _365_fa_base_color : packoffset(c2);\n    float4 _365_fa_emissive : packoffset(c3);\n    float4 _365_fa_model_emissive : packoffset(c4);\n    float4 _365_fa_pbr : packoffset(c5);\n    float4 _365_fa_maps : packoffset(c6);\n    float4 _365_fa_fog : packoffset(c7);\n    float4 _365_fa_fog_b : packoffset(c8);\n    float4 _365_fa_fog_c : packoffset(c9);\n    float4 _365_fa_counts : packoffset(c10);\n    float4 _365_fa_env_sky : packoffset(c11);\n    float4 _365_fa_env_horizon : packoffset(c12);\n    float4 _365_fa_time : packoffset(c13);\n    float4 _365_fa_cl_vpx : packoffset(c14);\n    float4 _365_fa_cl_vpy : packoffset(c15);\n    float4 _365_fa_cl_vpw : packoffset(c16);\n    float4 _365_fa_cl_fwd : packoffset(c17);\n    float4 _365_fa_cl_grid : packoffset(c18);\n    float4 _365_fa_cl_info : packoffset(c19);\n    float4 _365_fa_layers_a : packoffset(c20);\n    float4 _365_fa_layers_b : packoffset(c21);\n    float4 _365_fa_layers_c : packoffset(c22);\n    float4 _365_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2073_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2073_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2073_fa_shadow_info[4] : packoffset(c20);\n    float4 _2073_fa_shadow_split : packoffset(c24);\n    float4 _2073_fa_shadow_cfg : packoffset(c25);\n    float4 _2073_fa_shadow_bias : packoffset(c26);\n    float4 _2073_fa_shadow_eye : packoffset(c27);\n    float4 _2073_fa_shadow_fwd : packoffset(c28);\n    float4 _2073_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _4142_dark : packoffset(c0);\n    float _4142_fa_pad0 : packoffset(c0.y);\n    float _4142_fa_pad1 : packoffset(c0.z);\n    float _4142_fa_pad2 : packoffset(c0.w);\n    float _4142_skyAmount : packoffset(c1);\n    float _4142_fa_pad3 : packoffset(c1.y);\n    float _4142_fa_pad4 : packoffset(c1.z);\n    float _4142_fa_pad5 : packoffset(c1.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t9);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1344 = _365_fa_cl_info.x < 0.0f;\n    bool _1351;\n    if (!_1344)\n    {\n        _1351 = _365_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1351 = _1344;\n    }\n    bool _1359;\n    if (!_1351)\n    {\n        _1359 = _365_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1359 = _1351;\n    }\n    bool _1366;\n    if (!_1359)\n    {\n        _1366 = _365_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1366 = _1359;\n    }\n    bool _1373;\n    if (!_1366)\n    {\n        _1373 = _365_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1373 = _1366;\n    }\n    if (_1373)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1383 = float4(world_pos, 1.0f);\n    float _1389 = dot(_365_fa_cl_vpw, _1383);\n    if (!(_1389 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1411 = float2(dot(_365_fa_cl_vpx, _1383), dot(_365_fa_cl_vpy, _1383)) / _1389.xx;\n    int _1415 = int(_365_fa_cl_grid.x);\n    int _1419 = int(_365_fa_cl_grid.y);\n    int param = (int(_365_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_365_fa_cl_fwd.xyz, world_pos) + _365_fa_cl_fwd.w, _365_fa_cl_grid.w) / _365_fa_cl_grid.w) * _365_fa_cl_grid.z)), 0, int(_365_fa_cl_info.y) - 1) * _1419) + clamp(int(floor(((_1411.y * 0.5f) + 0.5f) * _365_fa_cl_grid.y)), 0, _1419 - 1)) * _1415)) + clamp(int(floor(((_1411.x * 0.5f) + 0.5f) * _365_fa_cl_grid.x)), 0, _1415 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1495 = fa_cluster_texel(param);\n    return int2(int(_1495.x), int(_1495.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_365_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3891 = fa_cluster_lookup(param);\n    fa_cl_slot = _3891.x;\n    fa_cl_local = _3891.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _4203 = fa_linear_to_srgb(param);\n        c = _4203;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _4211 = fa_srgb_to_linear(param_1);\n            c = _4211;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _297;\n    if (i.front_facing)\n    {\n        _297 = i.world_normal;\n    }\n    else\n    {\n        _297 = -i.world_normal;\n    }\n    float3 _321 = normalize(i.world_tangent.xyz - (_297 * dot(_297, i.world_tangent.xyz)));\n    float3 _349 = normalize(((_321 * m.x) + ((cross(_297, _321) * i.world_tangent.w) * m.y)) + (_297 * m.z));\n    float3 _352;\n    if (i.front_facing)\n    {\n        _352 = _349;\n    }\n    else\n    {\n        _352 = -_349;\n    }\n    return _352;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _365_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _4242 = fa_tex_fix(param_2, param_3);\n    float4 _5265 = base_t;\n    _5265.x = _4242.x;\n    _5265.y = _4242.y;\n    _5265.z = _4242.z;\n    base_t = _5265;\n    float4 _4256 = (_5265 * _365_fa_base_color) * i.vertex_color;\n    float3 _5117 = i.world_normal;\n    if (_365_fa_maps.z > 0.5f)\n    {\n        float param_4 = _365_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4288 = fa_tex_fix(param_6, param_7);\n        float3 _4291 = (_4288 * 2.0f) - 1.0f.xxx;\n        float2 _4296 = _4291.xy * _365_fa_maps.x;\n        float3 _5273 = _4291;\n        _5273.x = _4296.x;\n        _5273.y = _4296.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5273;\n        _5117 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _365_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4324 = fa_tex_fix(param_12, param_13);\n    float4 _5276 = mrt;\n    _5276.x = _4324.x;\n    _5276.y = _4324.y;\n    _5276.z = _4324.z;\n    mrt = _5276;\n    float4 _4352 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _365_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _4352.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4363 = fa_tex_fix(param_16, param_17);\n    float param_18 = _365_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4393 = fa_tex_fix(param_20, param_21);\n    float _5122 = _365_fa_layers_a.x;\n    float _5123 = _365_fa_layers_a.y;\n    float _5126 = _365_fa_layers_a.z;\n    float _5125 = _365_fa_layers_b.w;\n    float _5128 = _365_fa_layers_c.x;\n    if (_365_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_365_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _5122 *= _4363.y;\n            _5123 *= _4363.z;\n            _5125 *= _4352.w;\n        }\n        if (_365_fa_layers_c.z > 1.5f)\n        {\n            _5126 *= mrt.x;\n            _5128 *= mrt.w;\n        }\n    }\n    Surface _5147 = { _4256.xyz, _4256.w, _5117, clamp(_365_fa_pbr.x * _4324.z, 0.0f, 1.0f), clamp(_365_fa_pbr.y * _4324.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_365_fa_maps.y * (_4363.x - 1.0f)), _365_fa_emissive.xyz + (_365_fa_model_emissive.xyz * _4393), _5122, _5123, _365_fa_layers_b.xyz, _5125, _5126, _365_fa_layers_a.w, _5128, _365_fa_layers_c.y, _365_fa_layers_d.xyz };\n    return _5147;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1575 = rect.zw - rect.xy;\n    float2 _1579 = _1575 * atlas;\n    float2 _1583 = ddx * _1579;\n    float2 _1587 = ddy * _1579;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1575), clamp(0.5f * log2(max(max(dot(_1583, _1583), dot(_1587, _1587)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1620 = _365_fa_counts.y < 0.5f;\n    bool _1627;\n    if (!_1620)\n    {\n        _1627 = _365_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1627 = _1620;\n    }\n    if (_1627)\n    {\n        return;\n    }\n    float3 _1633 = ddx(world_pos);\n    float3 _1636 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1640 = fa_cluster_texel(param);\n    int _1644 = int(_1640.w);\n    if (_1644 < 1)\n    {\n        return;\n    }\n    int _1654 = int(_365_fa_counts.y + 0.5f);\n    int param_1 = _1654;\n    float4 _1658 = fa_light_texel(param_1);\n    float2 _1661 = _1658.yz;\n    int _1665 = int(_1658.w);\n    int param_2 = _1654 + 1;\n    float4 _1670 = fa_light_texel(param_2);\n    float _1671 = _1670.x;\n    int _1677 = int(_365_fa_counts.w + 0.5f) - 1;\n    int _1681 = int(_1640.z);\n    float3 _1946;\n    for (int k = 0; k < _1644; k++)\n    {\n        int _1694 = _1681 + k;\n        int param_3 = _1665 + (_1694 >> 2);\n        int _1711 = (_1654 + 2) + (int(fa_light_texel(param_3)[_1694 & 3]) * 7);\n        int param_4 = _1711 + 6;\n        float4 _1716 = fa_light_texel(param_4);\n        if (((int(_1716.w + 0.5f) >> _1677) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1711;\n        float4 _1731 = fa_light_texel(param_5);\n        int param_6 = _1711 + 1;\n        float4 _1736 = fa_light_texel(param_6);\n        int param_7 = _1711 + 2;\n        float4 _1741 = fa_light_texel(param_7);\n        float3 _1744 = _1731.xyz;\n        float _1749 = dot(_1744, world_pos) + _1731.w;\n        float3 _1751 = _1736.xyz;\n        float _1756 = dot(_1751, world_pos) + _1736.w;\n        float3 _1758 = _1741.xyz;\n        float _1763 = dot(_1758, world_pos) + _1741.w;\n        bool _1768 = abs(_1749) > 0.5f;\n        bool _1776;\n        if (!_1768)\n        {\n            _1776 = abs(_1756) > 0.5f;\n        }\n        else\n        {\n            _1776 = _1768;\n        }\n        bool _1784;\n        if (!_1776)\n        {\n            _1784 = abs(_1763) > 0.5f;\n        }\n        else\n        {\n            _1784 = _1776;\n        }\n        if (_1784)\n        {\n            continue;\n        }\n        float _1799 = clamp(dot(geo_normal, normalize(_1758)) * _1716.z, 0.0f, 1.0f);\n        if (_1799 <= 0.0f)\n        {\n            continue;\n        }\n        float _1819 = (clamp((0.5f - abs(_1763)) * 10.0f, 0.0f, 1.0f) * _1799) * _1716.x;\n        float2 _1827 = float2(_1749 + 0.5f, 0.5f - _1756);\n        float2 _1837 = float2(dot(_1744, _1633), dot(_1751, _1633));\n        float2 _1847 = float2(dot(_1744, _1636), dot(_1751, _1636));\n        int param_8 = _1711 + 5;\n        float4 _1852 = fa_light_texel(param_8);\n        int param_9 = _1711 + 3;\n        float4 _1857 = fa_light_texel(param_9);\n        int param_10 = _1711 + 4;\n        float4 _1862 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1852.xyz;\n        bool _1872 = _1857.z > _1857.x;\n        if (_1872)\n        {\n            float4 param_11 = _1857;\n            float2 param_12 = _1827;\n            float2 param_13 = _1661;\n            float2 param_14 = _1837;\n            float2 param_15 = _1847;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1671 > 0.5f) && (_1671 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1898 = fa_dc_to_linear(param_16);\n                float4 _5197 = tx;\n                _5197.x = _1898.x;\n                _5197.y = _1898.y;\n                _5197.z = _1898.z;\n                tx = _5197;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1819 * tex_a) * _1852.w, 0.0f, 1.0f).xxx);\n        if (_1862.z > _1862.x)\n        {\n            float4 param_17 = _1862;\n            float2 param_18 = _1827;\n            float2 param_19 = _1661;\n            float2 param_20 = _1837;\n            float2 param_21 = _1847;\n            float4 _1942 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1671 > 1.5f)\n            {\n                float3 param_22 = _1942.xyz;\n                float3 _1952 = fa_dc_to_srgb(param_22);\n                _1946 = _1952;\n            }\n            else\n            {\n                _1946 = _1942.xyz;\n            }\n            float3 _1961 = (_1946 * 2.0f) - 1.0f.xxx;\n            float2 _1966 = _1961.xy * _1716.y;\n            float3 _1988 = (normalize(_1744) * _1966.x) + (normalize(_1751) * _1966.y);\n            float3 _1991 = normalize(normal);\n            normal = normalize(lerp(_1991, normalize((_1991 * max(_1961.z, 0.0500000007450580596923828125f)) + (_1988 - (_1991 * dot(_1991, _1988)))), clamp(_1819 * (_1872 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return _5302;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_365_fa_cl_info.x) + int(_365_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_365_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _427_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _427_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _593 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _606 = (c - (ru * hx)) - p;\n        float3 _612 = ru * (2.0f * hx);\n        float _618 = max(dot(_612, _612), 9.9999999392252902907785028219223e-09f);\n        float _622 = dot(_606, _612);\n        float t = clamp((-_622) / _618, 0.0f, 1.0f);\n        if (_593)\n        {\n            float _637 = dot(r, _612);\n            float _643 = _618 - (_637 * _637);\n            if (abs(_643) > (9.9999997473787516355514526367188e-06f * _618))\n            {\n                t = clamp(((dot(r, _606) * _637) - _622) / _643, 0.0f, 1.0f);\n            }\n        }\n        return (p + _606) + (_612 * t);\n    }\n    float3 q = p;\n    float _675 = dot(r, axis);\n    bool _683;\n    if (_593)\n    {\n        _683 = abs(_675) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _683 = _593;\n    }\n    if (_683)\n    {\n        float _693 = dot(c - p, axis) / _675;\n        if (_693 > 0.0f)\n        {\n            q = p + (r * _693);\n        }\n    }\n    float3 _706 = q - c;\n    float2 xy = float2(dot(_706, ru), dot(_706, uu));\n    if (shape > 0.5f)\n    {\n        float _721 = length(xy);\n        if (_721 > hx)\n        {\n            xy *= (hx / _721);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _514 = abs(d);\n    float _516 = _514.x;\n    float _518 = _514.y;\n    bool _519 = _516 >= _518;\n    bool _527;\n    if (_519)\n    {\n        _527 = _516 >= _514.z;\n    }\n    else\n    {\n        _527 = _519;\n    }\n    int _528;\n    if (_527)\n    {\n        _528 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _541;\n        if (_518 >= _514.z)\n        {\n            _541 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _541 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _528 = _541;\n    }\n    return _528;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _467 = dot(d, right);\n    float _471 = dot(d, up);\n    float _482;\n    if (((_467 * _467) + (_471 * _471)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _482 = atan2(_471, _467) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _482 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_482 - floor(_482)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _759 = fa_light_base(param);\n    bool _763 = _365_fa_ambient.w > 4.5f;\n    int param_1 = _759;\n    float4 _767 = fa_light_texel(param_1);\n    int param_2 = _759 + 1;\n    float4 _772 = fa_light_texel(param_2);\n    float _775 = _772.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _787 = _763 && (_775 > 2.5f);\n    fa_light_is_area = _787;\n    bool _789 = _775 < 0.5f;\n    float3 l;\n    if (_789)\n    {\n        l = normalize(_767.xyz);\n        if (_763)\n        {\n            int param_3 = _759 + 6;\n            float4 _803 = fa_light_texel(param_3);\n            if (_803.z > 0.5f)\n            {\n                int param_4 = _759 + 4;\n                float4 _813 = fa_light_texel(param_4);\n                int param_5 = _759 + 5;\n                float4 _818 = fa_light_texel(param_5);\n                float2 param_6 = _803.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _813.xyz) * _813.w, (-dot(world_pos, _818.xyz)) * _818.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _848 = _767.xyz;\n        float3 _850 = _848 - world_pos;\n        float3 to_light = _850;\n        float _853 = length(_850);\n        float reach = _853;\n        bool front = true;\n        if (_787)\n        {\n            int param_8 = _759 + 7;\n            reach = max(_853 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _759 + 4;\n            float4 _877 = fa_light_texel(param_9);\n            int param_10 = _759 + 5;\n            float4 _882 = fa_light_texel(param_10);\n            int param_11 = _759 + 6;\n            float4 _887 = fa_light_texel(param_11);\n            float _888 = _887.w;\n            int param_12 = _759 + 2;\n            float3 _895 = normalize(fa_light_texel(param_12).xyz);\n            bool _897 = _888 > 1.5f;\n            bool _905;\n            if (!_897)\n            {\n                _905 = dot(_895, to_light) < 0.0f;\n            }\n            else\n            {\n                _905 = _897;\n            }\n            front = _905;\n            float3 r = 0.0f.xxx;\n            float3 _914 = _365_fa_camera_pos.xyz - world_pos;\n            bool _918 = dot(n, n) > 0.5f;\n            bool _926;\n            if (_918)\n            {\n                _926 = dot(_914, _914) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _926 = _918;\n            }\n            if (_926)\n            {\n                r = reflect(-normalize(_914), normalize(n));\n            }\n            float3 param_13 = _848;\n            float3 param_14 = _895;\n            float3 param_15 = _877.xyz;\n            float3 param_16 = _882.xyz;\n            float param_17 = _877.w;\n            float param_18 = _882.w;\n            float param_19 = _888;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _962 = length(to_light);\n        dist = _962;\n        l = to_light / max(_962, 9.9999997473787516355514526367188e-05f).xxx;\n        float _976 = reach / max(_767.w, 0.001000000047497451305389404296875f);\n        float _982 = clamp(1.0f - (_976 * _976), 0.0f, 1.0f);\n        float _984;\n        if (front)\n        {\n            _984 = _982 * _982;\n        }\n        else\n        {\n            _984 = 0.0f;\n        }\n        atten = _984;\n        bool _995 = _775 < 2.5f;\n        if ((_775 > 1.5f) && _995)\n        {\n            int param_22 = _759 + 2;\n            float4 _1003 = fa_light_texel(param_22);\n            float _1013 = _1003.w;\n            int param_23 = _759 + 3;\n            float4 _1018 = fa_light_texel(param_23);\n            float _1019 = _1018.x;\n            float cos_inner = _1019;\n            if (_1019 > 1.5f)\n            {\n                cos_inner = lerp(_1013, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1013, cos_inner, dot(-l, normalize(_1003.xyz)));\n        }\n        if (_763 && (_775 < 1.5f))\n        {\n            int param_24 = _759 + 6;\n            float4 _1043 = fa_light_texel(param_24);\n            if (_1043.z > 0.5f)\n            {\n                float3 _1051 = -to_light;\n                int param_25 = _759 + 4;\n                int param_26 = _759 + 5;\n                float3 _1065 = fa_light_texel(param_25).xyz;\n                float3 _1069 = fa_light_texel(param_26).xyz;\n                float3 _1078 = float3(dot(_1051, _1065), dot(_1051, _1069), dot(_1051, cross(_1065, _1069)));\n                float3 param_27 = _1078;\n                int _1082 = fa_cube_face(param_27);\n                int param_28 = _1082;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1109 = float2(dot(_1078, cross(param_29, param_30)), dot(_1078, param_30)) / max(dot(_1078, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1113 = _1082 / 3;\n                float2 param_31 = _1043.xy + (float2(float(_1082 - (_1113 * 3)), float(_1113)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1109.x), 0.5f - (0.5f * _1109.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _759 + 7;\n            float4 _1143 = fa_light_texel(param_33);\n            if (_1143.z > 0.5f)\n            {\n                int param_34 = _759 + 2;\n                int param_35 = _759 + 4;\n                int param_36 = _759 + 5;\n                float2 param_37 = _1143.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_763 && _995)\n            {\n                int param_42 = _759 + 6;\n                float4 _1190 = fa_light_texel(param_42);\n                int param_43 = _759 + 7;\n                float4 _1195 = fa_light_texel(param_43);\n                bool _1198 = _1190.z > 0.5f;\n                bool _1205;\n                if (!_1198)\n                {\n                    _1205 = _1195.z > 0.5f;\n                }\n                else\n                {\n                    _1205 = _1198;\n                }\n                if (_1205)\n                {\n                    int param_44 = _759 + 2;\n                    float4 _1212 = fa_light_texel(param_44);\n                    float3 _1216 = normalize(_1212.xyz);\n                    int param_45 = _759 + 4;\n                    float4 _1221 = fa_light_texel(param_45);\n                    int param_46 = _759 + 5;\n                    float4 _1226 = fa_light_texel(param_46);\n                    if (_1198)\n                    {\n                        float3 _1234 = -to_light;\n                        float _1241 = _1212.w;\n                        float _1257 = 0.5f / max(dot(_1234, _1216) * (sqrt(max(1.0f - (_1241 * _1241), 0.0f)) / max(_1241, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1190.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1234, _1221.xyz) * _1257), 0.5f - (dot(_1234, _1226.xyz) * _1257));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1195.z > 0.5f)\n                    {\n                        float2 param_49 = _1195.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1216;\n                        float3 param_52 = _1221.xyz;\n                        float3 param_53 = _1226.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4942 = _772.xyz * atten;\n    if (_763)\n    {\n        _4942 *= fa_light_tint;\n    }\n    int _1326;\n    if (_789)\n    {\n        _1326 = 0;\n    }\n    else\n    {\n        _1326 = ((_775 > 1.5f) && (_775 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _4953 = { l, _4942, atten, 1.0f, dist, _1326 };\n    return _4953;\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _4034 = n < 0;\n    bool _4041;\n    if (!_4034)\n    {\n        _4041 = n >= fa_light_count();\n    }\n    else\n    {\n        _4041 = _4034;\n    }\n    if (_4041)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _4049 = fa_cl_light(param);\n    bool _4052 = fa_lm.z > 0.5f;\n    bool _4058;\n    if (_4052)\n    {\n        int param_1 = _4049;\n        _4058 = fa_light_baked(param_1);\n    }\n    else\n    {\n        _4058 = _4052;\n    }\n    if (_4058)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _4049;\n    float3 param_3 = i.world_pos;\n    float3 param_4 = i.world_normal;\n    LightSample _4071 = fa_light_sample_n(param_2, param_3, param_4);\n    return _4071;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2063;\n    if (i == 0)\n    {\n        _2063 = _2073_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2079;\n        if (i == 1)\n        {\n            _2079 = _2073_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2087;\n            if (i == 2)\n            {\n                _2087 = _2073_fa_shadow_split.z;\n            }\n            else\n            {\n                _2087 = _2073_fa_shadow_split.w;\n            }\n            _2079 = _2087;\n        }\n        _2063 = _2079;\n    }\n    return _2063;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2120 = fa_shadow_depth(param, param_1);\n    float _2124;\n    if (conv.x < 0.5f)\n    {\n        _2124 = _2120;\n    }\n    else\n    {\n        _2124 = (conv.y * conv.z) / (conv.z - (_2120 * (conv.z - conv.y)));\n    }\n    return _2124;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2051 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2051), sin(_2051)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2170 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2179;\n        if (k < 0.0f)\n        {\n            _2179 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2179 = k;\n        }\n        float _2199 = clamp((_2179 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2170;\n            float2 _2218 = fa_shadow_vogel(param_3, param_4, param_5) * _2199;\n            float2 param_6 = uv + (_2218 * _2073_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2230 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2230 < (zr - (length(_2218) * plane)))\n            {\n                sum += _2230;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2256 = sum / cnt;\n        float _2266;\n        if (k < 0.0f)\n        {\n            _2266 = (-k) / max(_2256, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2266 = k;\n        }\n        radius = clamp(((max(zr - _2256, 0.0f) * unit) * _2266) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2288 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2288; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2288;\n        float param_11 = _2170;\n        float2 _2307 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2307 * _2073_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2307) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2288);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2349 = max(_2073_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2354 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2360 = sqrt(1.0f - (_2354 * _2354));\n    float _2367 = min(_2360 / max(_2354, 0.20000000298023223876953125f), 4.0f);\n    float _2372;\n    if (_2073_fa_shadow_bias.y > 0.0f)\n    {\n        _2372 = _2073_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2372 = 1.5f * _2073_fa_shadow_info[ci].x;\n    }\n    float4 _2397 = mul(float4(world + (n * (_2372 * _2360)), 1.0f), _2073_fa_shadow_mat[ci]);\n    float _2404 = _2397.x;\n    bool _2407 = _2404 < _2073_fa_shadow_rect[ci].x;\n    bool _2416;\n    if (!_2407)\n    {\n        _2416 = _2404 > _2073_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2416 = _2407;\n    }\n    bool _2425;\n    if (!_2416)\n    {\n        _2425 = _2397.y < _2073_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2425 = _2416;\n    }\n    bool _2434;\n    if (!_2425)\n    {\n        _2434 = _2397.y > _2073_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2434 = _2425;\n    }\n    bool _2441;\n    if (!_2434)\n    {\n        _2441 = _2397.z > 1.0f;\n    }\n    else\n    {\n        _2441 = _2434;\n    }\n    if (_2441)\n    {\n        return -1.0f;\n    }\n    float _2449;\n    if (_2073_fa_shadow_bias.x > 0.0f)\n    {\n        _2449 = _2073_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2449 = 1.5f * _2073_fa_shadow_info[ci].x;\n    }\n    float2 param = _2397.xy;\n    float4 param_1 = _2073_fa_shadow_rect[ci];\n    float param_2 = _2397.z - ((_2449 * (1.0f + (0.5f * _2367))) / _2349);\n    float param_3 = _2073_fa_shadow_info[ci].x;\n    float param_4 = _2349;\n    float param_5 = _2349 * 0.25f;\n    float param_6 = ((_2073_fa_shadow_info[ci].x * min(_2367, 3.0f)) * 0.5f) / _2349;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2073_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2073_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_365_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2837 = int(_2073_fa_shadow_cfg.x + 0.5f);\n    if (_2837 < 1)\n    {\n        return 1.0f;\n    }\n    float _2852 = dot(world - _2073_fa_shadow_eye.xyz, _2073_fa_shadow_fwd.xyz);\n    int param = _2837 - 1;\n    if (_2852 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2864 = _2837 > 1;\n    bool _2871;\n    if (_2864)\n    {\n        _2871 = _2852 > _2073_fa_shadow_split.x;\n    }\n    else\n    {\n        _2871 = _2864;\n    }\n    if (_2871)\n    {\n        ci = 1;\n    }\n    bool _2875 = _2837 > 2;\n    bool _2882;\n    if (_2875)\n    {\n        _2882 = _2852 > _2073_fa_shadow_split.y;\n    }\n    else\n    {\n        _2882 = _2875;\n    }\n    if (_2882)\n    {\n        ci = 2;\n    }\n    bool _2886 = _2837 > 3;\n    bool _2893;\n    if (_2886)\n    {\n        _2893 = _2852 > _2073_fa_shadow_split.z;\n    }\n    else\n    {\n        _2893 = _2886;\n    }\n    if (_2893)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2837)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2919 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2919;\n        if (_2919 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2073_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2944;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2944 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2944 = _2073_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2963 = _2073_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2944, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2974 = clamp((_2852 - (fa_shadow_split_at(param_7) - _2963)) / _2963, 0.0f, 1.0f);\n        if (_2974 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2837)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2995 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2995;\n                if (_2995 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2974);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _2507 = _365_fa_pbr.z < 0.5f;\n    bool _2514;\n    if (!_2507)\n    {\n        _2514 = _2073_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2514 = _2507;\n    }\n    if (_2514)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2073_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2527 = fa_light_texel(param);\n    float _2528 = _2527.x;\n    if (_2528 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2537 = int(_2528 + 0.5f);\n    int param_1 = _2537;\n    float4 _2541 = fa_light_texel(param_1);\n    int param_2 = _2537 + 1;\n    float4 _2546 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2549 = _2541.y;\n    if (_2549 > 0.0f)\n    {\n        float _2566 = 1.0f - smoothstep(0.75f * _2549, _2549, length(world - _2073_fa_shadow_eye.xyz));\n        fade = _2566;\n        if (_2566 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2541.x > 1.5f)\n    {\n        int param_3 = li;\n        int param_4 = fa_light_base(param_3);\n        float3 param_5 = world - fa_light_texel(param_4).xyz;\n        face = fa_cube_face(param_5);\n    }\n    int _2595 = (_2537 + 2) + (face * 6);\n    int param_6 = _2595;\n    int param_7 = _2595 + 1;\n    int param_8 = _2595 + 3;\n    float4 _2609 = fa_light_texel(param_8);\n    int param_9 = _2595 + 4;\n    float4 _2614 = fa_light_texel(param_9);\n    int param_10 = _2595 + 5;\n    float4 _2619 = fa_light_texel(param_10);\n    float _2631 = _2619.x * max(dot(_2609, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2636 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2659 = clamp(dot(n, _2609.xyz), -1.0f, 1.0f);\n    int param_11 = li;\n    int param_12 = fa_light_base(param_11);\n    float _2683 = min(sqrt(1.0f - (_2659 * _2659)) / max(abs(dot(n, world - fa_light_texel(param_12).xyz)) / max(dot(_2609, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2686 = _2546.y;\n    float _2688;\n    if (_2686 > 0.0f)\n    {\n        _2688 = _2686;\n    }\n    else\n    {\n        _2688 = 1.5f * _2631;\n    }\n    float4 _2708 = float4(world + (n * (_2688 * sqrt(1.0f - (_2636 * _2636)))), 1.0f);\n    float _2712 = dot(_2609, _2708);\n    float _2715 = _2619.y;\n    if (_2712 < _2715)\n    {\n        return 1.0f;\n    }\n    float2 _2730 = float2(dot(fa_light_texel(param_6), _2708), dot(fa_light_texel(param_7), _2708)) / _2712.xx;\n    float _2732 = _2730.x;\n    bool _2735 = _2732 < _2614.x;\n    bool _2744;\n    if (!_2735)\n    {\n        _2744 = _2732 > _2614.z;\n    }\n    else\n    {\n        _2744 = _2735;\n    }\n    bool _2753;\n    if (!_2744)\n    {\n        _2753 = _2730.y < _2614.y;\n    }\n    else\n    {\n        _2753 = _2744;\n    }\n    bool _2762;\n    if (!_2753)\n    {\n        _2762 = _2730.y > _2614.w;\n    }\n    else\n    {\n        _2762 = _2753;\n    }\n    if (_2762)\n    {\n        return 1.0f;\n    }\n    float _2768 = _2546.x;\n    float _2770;\n    if (_2768 > 0.0f)\n    {\n        _2770 = _2768;\n    }\n    else\n    {\n        _2770 = 1.5f * _2631;\n    }\n    float2 param_13 = _2730;\n    float4 param_14 = _2614;\n    float param_15 = _2712 - (_2770 * (1.0f + (0.5f * _2683)));\n    float param_16 = _2631;\n    float param_17 = 1.0f;\n    float param_18 = _2619.z * 0.25f;\n    float param_19 = (_2631 * min(_2683, 3.0f)) * 0.5f;\n    float3 param_20 = float3(1.0f, _2715, _2619.z);\n    int param_21 = int(_2541.z + 0.5f);\n    float param_22 = _2541.w;\n    return lerp(1.0f, fa_shadow_filter(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _3918 = fa_lm.z > 0.5f;\n    bool _3924;\n    if (_3918)\n    {\n        int param = li;\n        _3924 = fa_light_baked(param);\n    }\n    else\n    {\n        _3924 = _3918;\n    }\n    if (_3924)\n    {\n        int param_1 = li;\n        LightSample _5086 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _5086;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3948 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _5088 = _3948.color;\n    float _5090 = _3948.shadow;\n    if ((_3948.type == 0) && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3948.direction;\n        float _3962 = fa_shadow_factor(param_5, param_6);\n        _5090 = _3962;\n        _5088 *= _3962;\n    }\n    else\n    {\n        bool _3973 = _3948.type != 0;\n        bool _3979;\n        if (_3973)\n        {\n            _3979 = _3948.attenuation > 0.0f;\n        }\n        else\n        {\n            _3979 = _3973;\n        }\n        if (_3979)\n        {\n            int param_7 = li;\n            float3 param_8 = world_pos;\n            float3 param_9 = gn;\n            float3 param_10 = _3948.direction;\n            float _3991 = fa_shadow_local(param_7, param_8, param_9, param_10);\n            _5090 = _3991;\n            _5088 *= _3991;\n        }\n    }\n    LightSample _5105 = { _3948.direction, _5088, _3948.attenuation, _5090, _3948._distance, _3948.type };\n    return _5105;\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _4008 = n < 0;\n    bool _4015;\n    if (!_4008)\n    {\n        _4015 = n >= fa_light_count();\n    }\n    else\n    {\n        _4015 = _4008;\n    }\n    if (_4015)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    LightSample _4030 = fa_light_shadowed(param_1, param_2, param_3);\n    return _4030;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3274 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3282 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3285 = int(_3274);\n    int _3288 = int(_3282);\n    float _3298 = _3282 - float(_3288);\n    int _3354 = (_3285 * 9) + _3288;\n    int _3374 = ((_3285 + 1) * 9) + _3288;\n    return lerp(lerp(_3349[_3354], _3349[_3354 + 1], _3298), lerp(_3349[_3374], _3349[_3374 + 1], _3298), _3274 - float(_3285));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _4954 = false;\n    float _4955 = 1.0f;\n    float _4956 = 1.0f;\n    float _4957 = 1.0f;\n    float _4958 = 0.0f;\n    float _4959 = 0.0f;\n    float _4960 = 0.0f;\n    float _4961 = 0.0f;\n    float _4963 = 1.0f;\n    bool _4964 = false;\n    float3 _4965 = 0.0f.xxx;\n    float _4966 = 1.0f;\n    float _4967 = 1.0f;\n    float _4968 = 1.0f;\n    float _4969 = 0.0f;\n    float _4970 = 0.0f;\n    float3 _4971 = float3(1.0f, 0.0f, 0.0f);\n    float3 _4972 = float3(0.0f, 0.0f, 1.0f);\n    float _4973 = 1.0f;\n    float _4974 = 1.0f;\n    float _3425 = clamp(s.specular, 0.0f, 1.0f);\n    float _3429 = clamp(s.ior, 1.0f, 3.0f);\n    bool _3434 = (_3425 != 1.0f) || (_3429 != 1.5f);\n    bool _3443;\n    if (!_3434)\n    {\n        _3443 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _3443 = _3434;\n    }\n    if (_3443)\n    {\n        float _3451 = (_3429 - 1.0f) / (_3429 + 1.0f);\n        f0 = lerp(min((_3451 * _3451).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _3425, s.albedo, metallic.xxx);\n        _4955 = lerp(_3425, 1.0f, metallic);\n        _4954 = true;\n    }\n    float _3478 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_3478 > 0.0f)\n    {\n        float _3486 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _4958 = _3478;\n        _4959 = _3486;\n        float _3493 = _3486 * _3486;\n        _4960 = _3493;\n        _4961 = _3493 * _3493;\n        float _3505 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _4963 = _3505;\n        _4956 = 1.0f - (_3478 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _3505, 0.0f, 1.0f), 5.0f))));\n        _4954 = true;\n    }\n    float3 _3525 = max(s.sheen_color, 0.0f.xxx);\n    float _3534 = max(_3525.x, max(_3525.y, _3525.z));\n    if (_3534 > 0.0f)\n    {\n        float _3542 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _4964 = true;\n        _4965 = _3525;\n        _4966 = _3542;\n        _4967 = _3542 * _3542;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _3542;\n        float _3559 = fa_sheen_albedo(param, param_1);\n        _4969 = _3559;\n        _4968 = 1.0f - min(_3534 * _3559, 1.0f);\n        _4954 = true;\n    }\n    _4957 = _4956 * _4968;\n    float _3578 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_3578 != 0.0f)\n    {\n        float3 _3593 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _3593;\n        if (dot(_3593, _3593) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _3605 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_3605.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _3605.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _3605.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _3609 = t;\n        float3 _3610 = normalize(_3609);\n        t = _3610;\n        float3 _3635 = normalize((_3610 * cos(s.anisotropy_rotation)) + ((cross(n, _3610) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _4971 = _3635;\n        _4972 = cross(n, _3635);\n        float _3645 = roughness * roughness;\n        float _3651 = lerp(_3645, 1.0f, _3578 * _3578);\n        bool _3653 = _3578 > 0.0f;\n        _4973 = _3653 ? _3651 : _3645;\n        _4974 = _3653 ? _3645 : _3651;\n        _4970 = _3578;\n        _4954 = true;\n    }\n    FaLayers _4996 = { _4954, _4955, _4956, _4957, _4958, _4959, _4960, _4961, i.world_normal, _4963, _4964, _4965, _4966, _4967, _4968, _4969, _4970, _4971, _4972, _4973, _4974 };\n    return _4996;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3206 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3209 = _3206.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3209 * _3209, exp2((-9.27999973297119140625f) * ndv)) * _3209) + _3206.y)) + _3206.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_365_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _365_fa_env_horizon.w).xyz;\n    }\n    float _3130 = rough * rough;\n    float _3160 = 0.60000002384185791015625f * _3130;\n    return lerp(lerp(_365_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_365_fa_env_horizon.xyz, _365_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3130)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3160, 0.0500000007450580596923828125f + _3160, d.y).xxx), ((_365_fa_env_sky.xyz + _365_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3130 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _3686;\n        if (L.aniso >= 0.0f)\n        {\n            _3686 = L.b;\n        }\n        else\n        {\n            _3686 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_3686, v), _3686), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3719 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _3719.x) + (L.f90.xxx * _3719.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3774 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _3774.x) + _3774.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3248 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3248.x) + _3248.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _3813 = clamp(s.metallic, 0.0f, 1.0f);\n    float _3817 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _3824 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _3813.xxx);\n    float3 f0 = _3824;\n    float3 _3828 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _3828;\n    float3 param_3 = i.view_dir;\n    float param_4 = _3813;\n    float param_5 = _3817;\n    float3 param_6 = _3824;\n    FaLayers _3845 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_3845.on)\n    {\n        FaLayers param_7 = _3845;\n        float3 param_8 = _3828;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _3817;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _3828;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _3817;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0f;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _4091 = fa_light_unshadowed(param, param_1);\n        float _4099 = dot(_4091.color, float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));\n        if (_4099 > bestPower)\n        {\n            bestPower = _4099;\n            best = n;\n        }\n    }\n    float3 lit = (_365_fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _4128 = fa_light(param_2, param_3);\n        float _4136;\n        if (dot(s.normal, _4128.direction) > 0.5f)\n        {\n            _4136 = 1.0f;\n        }\n        else\n        {\n            _4136 = _4142_dark;\n        }\n        lit += ((s.albedo * _4128.color) * _4136);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * _4142_skyAmount);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2073_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3019 = int(_2073_fa_shadow_cfg.x + 0.5f);\n    float _3029 = dot(world - _2073_fa_shadow_eye.xyz, _2073_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3034 = _3019 > 0;\n    bool _3043;\n    if (_3034)\n    {\n        int param = _3019 - 1;\n        _3043 = _3029 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3043 = _3034;\n    }\n    if (_3043)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3049 = _3019 > 1;\n        bool _3056;\n        if (_3049)\n        {\n            _3056 = _3029 > _2073_fa_shadow_split.x;\n        }\n        else\n        {\n            _3056 = _3049;\n        }\n        if (_3056)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3062 = _3019 > 2;\n        bool _3069;\n        if (_3062)\n        {\n            _3069 = _3029 > _2073_fa_shadow_split.y;\n        }\n        else\n        {\n            _3069 = _3062;\n        }\n        if (_3069)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3075 = _3019 > 3;\n        bool _3082;\n        if (_3075)\n        {\n            _3082 = _3029 > _2073_fa_shadow_split.z;\n        }\n        else\n        {\n            _3082 = _3075;\n        }\n        if (_3082)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _4828 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4828 = -_4828;\n    }\n    float3 _4514 = normalize(_365_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _4841 = { fa_world_pos, _4828, fa_world_tangent, fa_uv, fa_vertex_color, _4514, gl_FrontFacing };\n    SurfaceInput param_1 = _4841;\n    Surface _4522 = fa_standard_surface(param_1);\n    float3 _4859 = _4522.albedo;\n    float _4860 = _4522.alpha;\n    float3 _4861 = _4522.normal;\n    float _4862 = _4522.metallic;\n    float _4863 = _4522.roughness;\n    float _4864 = _4522.occlusion;\n    float3 _4865 = _4522.emission;\n    float _4866 = _4522.clearcoat;\n    float _4867 = _4522.clearcoat_roughness;\n    float3 _4868 = _4522.sheen_color;\n    float _4869 = _4522.sheen_roughness;\n    float _4870 = _4522.anisotropy;\n    float _4871 = _4522.anisotropy_rotation;\n    float _4872 = _4522.specular;\n    float _4873 = _4522.ior;\n    float3 _4874 = _4522.specular_color;\n    SurfaceInput _4849 = { fa_world_pos, _4828, fa_world_tangent, fa_uv, fa_vertex_color, _4514, gl_FrontFacing };\n    SurfaceInput param_2 = _4849;\n    Surface param_3 = _4522;\n    surface(param_2, param_3);\n    _4859 = param_3.albedo;\n    _4860 = param_3.alpha;\n    _4861 = param_3.normal;\n    _4862 = param_3.metallic;\n    _4863 = param_3.roughness;\n    _4864 = param_3.occlusion;\n    _4865 = param_3.emission;\n    _4866 = param_3.clearcoat;\n    _4867 = param_3.clearcoat_roughness;\n    _4868 = param_3.sheen_color;\n    _4869 = param_3.sheen_roughness;\n    _4870 = param_3.anisotropy;\n    _4871 = param_3.anisotropy_rotation;\n    _4872 = param_3.specular;\n    _4873 = param_3.ior;\n    _4874 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _4828;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4859 = param_6;\n    _4861 = param_7;\n    float3 result;\n    if (_365_fa_emissive.w > 0.5f)\n    {\n        result = _4859;\n    }\n    else\n    {\n        float3 _4560 = _4861;\n        float3 _4561 = normalize(_4560);\n        _4861 = _4561;\n        SurfaceInput _4857 = { fa_world_pos, _4828, fa_world_tangent, fa_uv, fa_vertex_color, _4514, gl_FrontFacing };\n        SurfaceInput param_8 = _4857;\n        Surface _4940 = { _4859, _4860, _4561, _4862, _4863, _4864, _4865, _4866, _4867, _4868, _4869, _4870, _4871, _4872, _4873, _4874 };\n        Surface param_9 = _4940;\n        float3 _4572 = lighting(param_8, param_9);\n        result = _4572;\n    }\n    float3 _4576 = result;\n    float3 _4577 = _4576 + _4865;\n    result = _4577;\n    float3 param_10 = _4577;\n    float3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _4586 = _365_fa_fog.w > 0.0f;\n    bool _4593;\n    if (!_4586)\n    {\n        _4593 = _365_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _4593 = _4586;\n    }\n    if (_4593)\n    {\n        float3 _4602 = fa_world_pos - _365_fa_camera_pos.xyz;\n        float _4608 = dot(_4602, _365_fa_fog_c.xyz);\n        bool _4612 = _365_fa_fog_c.w > 0.5f;\n        float _4613;\n        if (_4612)\n        {\n            _4613 = _4608;\n        }\n        else\n        {\n            _4613 = length(_4602);\n        }\n        float _4625 = _4613 - _365_fa_fog_b.x;\n        if (_4625 > 0.0f)\n        {\n            float _4634 = _365_fa_fog.w * _4625;\n            float tau = _4634 * _4634;\n            if (_365_fa_fog_b.y > 0.0f)\n            {\n                float _4650;\n                if (_4612)\n                {\n                    _4650 = fa_world_pos.y - (_365_fa_fog_c.y * _4608);\n                }\n                else\n                {\n                    _4650 = _365_fa_camera_pos.y;\n                }\n                float _4671 = lerp(_4650, fa_world_pos.y, clamp(_365_fa_fog_b.x / _4613, 0.0f, 1.0f));\n                float _4675 = fa_world_pos.y - _4671;\n                float _4680 = _4671 - _365_fa_fog_b.z;\n                float _4685 = fa_world_pos.y - _365_fa_fog_b.z;\n                bool _4688 = _4680 <= 0.0f;\n                bool _4689 = !_4688;\n                bool _4695;\n                if (_4689)\n                {\n                    _4695 = _365_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4695 = _4688;\n                }\n                float _4696;\n                if (_4695)\n                {\n                    _4696 = _365_fa_fog_b.y;\n                }\n                else\n                {\n                    _4696 = _365_fa_fog_b.y * exp(-min(_365_fa_fog_b.w * _4680, 80.0f));\n                }\n                bool _4723;\n                if (_4689)\n                {\n                    _4723 = _365_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4723 = _4688;\n                }\n                float _4724;\n                if (_4723)\n                {\n                    _4724 = _365_fa_fog_b.y * _4680;\n                }\n                else\n                {\n                    _4724 = (_365_fa_fog_b.y * (1.0f - exp(-min(_365_fa_fog_b.w * _4680, 80.0f)))) / _365_fa_fog_b.w;\n                }\n                bool _4749 = _4685 <= 0.0f;\n                bool _4756;\n                if (!_4749)\n                {\n                    _4756 = _365_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4756 = _4749;\n                }\n                float _4757;\n                if (_4756)\n                {\n                    _4757 = _365_fa_fog_b.y * _4685;\n                }\n                else\n                {\n                    _4757 = (_365_fa_fog_b.y * (1.0f - exp(-min(_365_fa_fog_b.w * _4685, 80.0f)))) / _365_fa_fog_b.w;\n                }\n                float _4784;\n                if (abs(_4675) < 0.001000000047497451305389404296875f)\n                {\n                    _4784 = _4696;\n                }\n                else\n                {\n                    _4784 = (_4757 - _4724) / _4675;\n                }\n                tau += (_4625 * max(_4784, 0.0f));\n            }\n            result = lerp(result, _365_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4860);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_2073",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_4142",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _3349[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\nstatic const LightSample _5302 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, 0 };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _365_fa_camera_pos : packoffset(c0);\n    float4 _365_fa_ambient : packoffset(c1);\n    float4 _365_fa_base_color : packoffset(c2);\n    float4 _365_fa_emissive : packoffset(c3);\n    float4 _365_fa_model_emissive : packoffset(c4);\n    float4 _365_fa_pbr : packoffset(c5);\n    float4 _365_fa_maps : packoffset(c6);\n    float4 _365_fa_fog : packoffset(c7);\n    float4 _365_fa_fog_b : packoffset(c8);\n    float4 _365_fa_fog_c : packoffset(c9);\n    float4 _365_fa_counts : packoffset(c10);\n    float4 _365_fa_env_sky : packoffset(c11);\n    float4 _365_fa_env_horizon : packoffset(c12);\n    float4 _365_fa_time : packoffset(c13);\n    float4 _365_fa_cl_vpx : packoffset(c14);\n    float4 _365_fa_cl_vpy : packoffset(c15);\n    float4 _365_fa_cl_vpw : packoffset(c16);\n    float4 _365_fa_cl_fwd : packoffset(c17);\n    float4 _365_fa_cl_grid : packoffset(c18);\n    float4 _365_fa_cl_info : packoffset(c19);\n    float4 _365_fa_layers_a : packoffset(c20);\n    float4 _365_fa_layers_b : packoffset(c21);\n    float4 _365_fa_layers_c : packoffset(c22);\n    float4 _365_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2073_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2073_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2073_fa_shadow_info[4] : packoffset(c20);\n    float4 _2073_fa_shadow_split : packoffset(c24);\n    float4 _2073_fa_shadow_cfg : packoffset(c25);\n    float4 _2073_fa_shadow_bias : packoffset(c26);\n    float4 _2073_fa_shadow_eye : packoffset(c27);\n    float4 _2073_fa_shadow_fwd : packoffset(c28);\n    float4 _2073_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _4142_dark : packoffset(c0);\n    float _4142_fa_pad0 : packoffset(c0.y);\n    float _4142_fa_pad1 : packoffset(c0.z);\n    float _4142_fa_pad2 : packoffset(c0.w);\n    float _4142_skyAmount : packoffset(c1);\n    float _4142_fa_pad3 : packoffset(c1.y);\n    float _4142_fa_pad4 : packoffset(c1.z);\n    float _4142_fa_pad5 : packoffset(c1.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t9);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1344 = _365_fa_cl_info.x < 0.0f;\n    bool _1351;\n    if (!_1344)\n    {\n        _1351 = _365_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1351 = _1344;\n    }\n    bool _1359;\n    if (!_1351)\n    {\n        _1359 = _365_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1359 = _1351;\n    }\n    bool _1366;\n    if (!_1359)\n    {\n        _1366 = _365_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1366 = _1359;\n    }\n    bool _1373;\n    if (!_1366)\n    {\n        _1373 = _365_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1373 = _1366;\n    }\n    if (_1373)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1383 = float4(world_pos, 1.0f);\n    float _1389 = dot(_365_fa_cl_vpw, _1383);\n    if (!(_1389 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1411 = float2(dot(_365_fa_cl_vpx, _1383), dot(_365_fa_cl_vpy, _1383)) / _1389.xx;\n    int _1415 = int(_365_fa_cl_grid.x);\n    int _1419 = int(_365_fa_cl_grid.y);\n    int param = (int(_365_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_365_fa_cl_fwd.xyz, world_pos) + _365_fa_cl_fwd.w, _365_fa_cl_grid.w) / _365_fa_cl_grid.w) * _365_fa_cl_grid.z)), 0, int(_365_fa_cl_info.y) - 1) * _1419) + clamp(int(floor(((_1411.y * 0.5f) + 0.5f) * _365_fa_cl_grid.y)), 0, _1419 - 1)) * _1415)) + clamp(int(floor(((_1411.x * 0.5f) + 0.5f) * _365_fa_cl_grid.x)), 0, _1415 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1495 = fa_cluster_texel(param);\n    return int2(int(_1495.x), int(_1495.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_365_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3891 = fa_cluster_lookup(param);\n    fa_cl_slot = _3891.x;\n    fa_cl_local = _3891.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _4203 = fa_linear_to_srgb(param);\n        c = _4203;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _4211 = fa_srgb_to_linear(param_1);\n            c = _4211;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _297;\n    if (i.front_facing)\n    {\n        _297 = i.world_normal;\n    }\n    else\n    {\n        _297 = -i.world_normal;\n    }\n    float3 _321 = normalize(i.world_tangent.xyz - (_297 * dot(_297, i.world_tangent.xyz)));\n    float3 _349 = normalize(((_321 * m.x) + ((cross(_297, _321) * i.world_tangent.w) * m.y)) + (_297 * m.z));\n    float3 _352;\n    if (i.front_facing)\n    {\n        _352 = _349;\n    }\n    else\n    {\n        _352 = -_349;\n    }\n    return _352;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _365_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _4242 = fa_tex_fix(param_2, param_3);\n    float4 _5265 = base_t;\n    _5265.x = _4242.x;\n    _5265.y = _4242.y;\n    _5265.z = _4242.z;\n    base_t = _5265;\n    float4 _4256 = (_5265 * _365_fa_base_color) * i.vertex_color;\n    float3 _5117 = i.world_normal;\n    if (_365_fa_maps.z > 0.5f)\n    {\n        float param_4 = _365_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4288 = fa_tex_fix(param_6, param_7);\n        float3 _4291 = (_4288 * 2.0f) - 1.0f.xxx;\n        float2 _4296 = _4291.xy * _365_fa_maps.x;\n        float3 _5273 = _4291;\n        _5273.x = _4296.x;\n        _5273.y = _4296.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5273;\n        _5117 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _365_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4324 = fa_tex_fix(param_12, param_13);\n    float4 _5276 = mrt;\n    _5276.x = _4324.x;\n    _5276.y = _4324.y;\n    _5276.z = _4324.z;\n    mrt = _5276;\n    float4 _4352 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _365_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _4352.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4363 = fa_tex_fix(param_16, param_17);\n    float param_18 = _365_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4393 = fa_tex_fix(param_20, param_21);\n    float _5122 = _365_fa_layers_a.x;\n    float _5123 = _365_fa_layers_a.y;\n    float _5126 = _365_fa_layers_a.z;\n    float _5125 = _365_fa_layers_b.w;\n    float _5128 = _365_fa_layers_c.x;\n    if (_365_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_365_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _5122 *= _4363.y;\n            _5123 *= _4363.z;\n            _5125 *= _4352.w;\n        }\n        if (_365_fa_layers_c.z > 1.5f)\n        {\n            _5126 *= mrt.x;\n            _5128 *= mrt.w;\n        }\n    }\n    Surface _5147 = { _4256.xyz, _4256.w, _5117, clamp(_365_fa_pbr.x * _4324.z, 0.0f, 1.0f), clamp(_365_fa_pbr.y * _4324.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_365_fa_maps.y * (_4363.x - 1.0f)), _365_fa_emissive.xyz + (_365_fa_model_emissive.xyz * _4393), _5122, _5123, _365_fa_layers_b.xyz, _5125, _5126, _365_fa_layers_a.w, _5128, _365_fa_layers_c.y, _365_fa_layers_d.xyz };\n    return _5147;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1575 = rect.zw - rect.xy;\n    float2 _1579 = _1575 * atlas;\n    float2 _1583 = ddx * _1579;\n    float2 _1587 = ddy * _1579;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1575), clamp(0.5f * log2(max(max(dot(_1583, _1583), dot(_1587, _1587)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1620 = _365_fa_counts.y < 0.5f;\n    bool _1627;\n    if (!_1620)\n    {\n        _1627 = _365_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1627 = _1620;\n    }\n    if (_1627)\n    {\n        return;\n    }\n    float3 _1633 = ddx(world_pos);\n    float3 _1636 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1640 = fa_cluster_texel(param);\n    int _1644 = int(_1640.w);\n    if (_1644 < 1)\n    {\n        return;\n    }\n    int _1654 = int(_365_fa_counts.y + 0.5f);\n    int param_1 = _1654;\n    float4 _1658 = fa_light_texel(param_1);\n    float2 _1661 = _1658.yz;\n    int _1665 = int(_1658.w);\n    int param_2 = _1654 + 1;\n    float4 _1670 = fa_light_texel(param_2);\n    float _1671 = _1670.x;\n    int _1677 = int(_365_fa_counts.w + 0.5f) - 1;\n    int _1681 = int(_1640.z);\n    float3 _1946;\n    for (int k = 0; k < _1644; k++)\n    {\n        int _1694 = _1681 + k;\n        int param_3 = _1665 + (_1694 >> 2);\n        int _1711 = (_1654 + 2) + (int(fa_light_texel(param_3)[_1694 & 3]) * 7);\n        int param_4 = _1711 + 6;\n        float4 _1716 = fa_light_texel(param_4);\n        if (((int(_1716.w + 0.5f) >> _1677) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1711;\n        float4 _1731 = fa_light_texel(param_5);\n        int param_6 = _1711 + 1;\n        float4 _1736 = fa_light_texel(param_6);\n        int param_7 = _1711 + 2;\n        float4 _1741 = fa_light_texel(param_7);\n        float3 _1744 = _1731.xyz;\n        float _1749 = dot(_1744, world_pos) + _1731.w;\n        float3 _1751 = _1736.xyz;\n        float _1756 = dot(_1751, world_pos) + _1736.w;\n        float3 _1758 = _1741.xyz;\n        float _1763 = dot(_1758, world_pos) + _1741.w;\n        bool _1768 = abs(_1749) > 0.5f;\n        bool _1776;\n        if (!_1768)\n        {\n            _1776 = abs(_1756) > 0.5f;\n        }\n        else\n        {\n            _1776 = _1768;\n        }\n        bool _1784;\n        if (!_1776)\n        {\n            _1784 = abs(_1763) > 0.5f;\n        }\n        else\n        {\n            _1784 = _1776;\n        }\n        if (_1784)\n        {\n            continue;\n        }\n        float _1799 = clamp(dot(geo_normal, normalize(_1758)) * _1716.z, 0.0f, 1.0f);\n        if (_1799 <= 0.0f)\n        {\n            continue;\n        }\n        float _1819 = (clamp((0.5f - abs(_1763)) * 10.0f, 0.0f, 1.0f) * _1799) * _1716.x;\n        float2 _1827 = float2(_1749 + 0.5f, 0.5f - _1756);\n        float2 _1837 = float2(dot(_1744, _1633), dot(_1751, _1633));\n        float2 _1847 = float2(dot(_1744, _1636), dot(_1751, _1636));\n        int param_8 = _1711 + 5;\n        float4 _1852 = fa_light_texel(param_8);\n        int param_9 = _1711 + 3;\n        float4 _1857 = fa_light_texel(param_9);\n        int param_10 = _1711 + 4;\n        float4 _1862 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1852.xyz;\n        bool _1872 = _1857.z > _1857.x;\n        if (_1872)\n        {\n            float4 param_11 = _1857;\n            float2 param_12 = _1827;\n            float2 param_13 = _1661;\n            float2 param_14 = _1837;\n            float2 param_15 = _1847;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1671 > 0.5f) && (_1671 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1898 = fa_dc_to_linear(param_16);\n                float4 _5197 = tx;\n                _5197.x = _1898.x;\n                _5197.y = _1898.y;\n                _5197.z = _1898.z;\n                tx = _5197;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1819 * tex_a) * _1852.w, 0.0f, 1.0f).xxx);\n        if (_1862.z > _1862.x)\n        {\n            float4 param_17 = _1862;\n            float2 param_18 = _1827;\n            float2 param_19 = _1661;\n            float2 param_20 = _1837;\n            float2 param_21 = _1847;\n            float4 _1942 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1671 > 1.5f)\n            {\n                float3 param_22 = _1942.xyz;\n                float3 _1952 = fa_dc_to_srgb(param_22);\n                _1946 = _1952;\n            }\n            else\n            {\n                _1946 = _1942.xyz;\n            }\n            float3 _1961 = (_1946 * 2.0f) - 1.0f.xxx;\n            float2 _1966 = _1961.xy * _1716.y;\n            float3 _1988 = (normalize(_1744) * _1966.x) + (normalize(_1751) * _1966.y);\n            float3 _1991 = normalize(normal);\n            normal = normalize(lerp(_1991, normalize((_1991 * max(_1961.z, 0.0500000007450580596923828125f)) + (_1988 - (_1991 * dot(_1991, _1988)))), clamp(_1819 * (_1872 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return _5302;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_365_fa_cl_info.x) + int(_365_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_365_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _427_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _427_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _593 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _606 = (c - (ru * hx)) - p;\n        float3 _612 = ru * (2.0f * hx);\n        float _618 = max(dot(_612, _612), 9.9999999392252902907785028219223e-09f);\n        float _622 = dot(_606, _612);\n        float t = clamp((-_622) / _618, 0.0f, 1.0f);\n        if (_593)\n        {\n            float _637 = dot(r, _612);\n            float _643 = _618 - (_637 * _637);\n            if (abs(_643) > (9.9999997473787516355514526367188e-06f * _618))\n            {\n                t = clamp(((dot(r, _606) * _637) - _622) / _643, 0.0f, 1.0f);\n            }\n        }\n        return (p + _606) + (_612 * t);\n    }\n    float3 q = p;\n    float _675 = dot(r, axis);\n    bool _683;\n    if (_593)\n    {\n        _683 = abs(_675) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _683 = _593;\n    }\n    if (_683)\n    {\n        float _693 = dot(c - p, axis) / _675;\n        if (_693 > 0.0f)\n        {\n            q = p + (r * _693);\n        }\n    }\n    float3 _706 = q - c;\n    float2 xy = float2(dot(_706, ru), dot(_706, uu));\n    if (shape > 0.5f)\n    {\n        float _721 = length(xy);\n        if (_721 > hx)\n        {\n            xy *= (hx / _721);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _514 = abs(d);\n    float _516 = _514.x;\n    float _518 = _514.y;\n    bool _519 = _516 >= _518;\n    bool _527;\n    if (_519)\n    {\n        _527 = _516 >= _514.z;\n    }\n    else\n    {\n        _527 = _519;\n    }\n    int _528;\n    if (_527)\n    {\n        _528 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _541;\n        if (_518 >= _514.z)\n        {\n            _541 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _541 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _528 = _541;\n    }\n    return _528;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _467 = dot(d, right);\n    float _471 = dot(d, up);\n    float _482;\n    if (((_467 * _467) + (_471 * _471)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _482 = atan2(_471, _467) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _482 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_482 - floor(_482)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _759 = fa_light_base(param);\n    bool _763 = _365_fa_ambient.w > 4.5f;\n    int param_1 = _759;\n    float4 _767 = fa_light_texel(param_1);\n    int param_2 = _759 + 1;\n    float4 _772 = fa_light_texel(param_2);\n    float _775 = _772.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _787 = _763 && (_775 > 2.5f);\n    fa_light_is_area = _787;\n    bool _789 = _775 < 0.5f;\n    float3 l;\n    if (_789)\n    {\n        l = normalize(_767.xyz);\n        if (_763)\n        {\n            int param_3 = _759 + 6;\n            float4 _803 = fa_light_texel(param_3);\n            if (_803.z > 0.5f)\n            {\n                int param_4 = _759 + 4;\n                float4 _813 = fa_light_texel(param_4);\n                int param_5 = _759 + 5;\n                float4 _818 = fa_light_texel(param_5);\n                float2 param_6 = _803.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _813.xyz) * _813.w, (-dot(world_pos, _818.xyz)) * _818.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _848 = _767.xyz;\n        float3 _850 = _848 - world_pos;\n        float3 to_light = _850;\n        float _853 = length(_850);\n        float reach = _853;\n        bool front = true;\n        if (_787)\n        {\n            int param_8 = _759 + 7;\n            reach = max(_853 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _759 + 4;\n            float4 _877 = fa_light_texel(param_9);\n            int param_10 = _759 + 5;\n            float4 _882 = fa_light_texel(param_10);\n            int param_11 = _759 + 6;\n            float4 _887 = fa_light_texel(param_11);\n            float _888 = _887.w;\n            int param_12 = _759 + 2;\n            float3 _895 = normalize(fa_light_texel(param_12).xyz);\n            bool _897 = _888 > 1.5f;\n            bool _905;\n            if (!_897)\n            {\n                _905 = dot(_895, to_light) < 0.0f;\n            }\n            else\n            {\n                _905 = _897;\n            }\n            front = _905;\n            float3 r = 0.0f.xxx;\n            float3 _914 = _365_fa_camera_pos.xyz - world_pos;\n            bool _918 = dot(n, n) > 0.5f;\n            bool _926;\n            if (_918)\n            {\n                _926 = dot(_914, _914) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _926 = _918;\n            }\n            if (_926)\n            {\n                r = reflect(-normalize(_914), normalize(n));\n            }\n            float3 param_13 = _848;\n            float3 param_14 = _895;\n            float3 param_15 = _877.xyz;\n            float3 param_16 = _882.xyz;\n            float param_17 = _877.w;\n            float param_18 = _882.w;\n            float param_19 = _888;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _962 = length(to_light);\n        dist = _962;\n        l = to_light / max(_962, 9.9999997473787516355514526367188e-05f).xxx;\n        float _976 = reach / max(_767.w, 0.001000000047497451305389404296875f);\n        float _982 = clamp(1.0f - (_976 * _976), 0.0f, 1.0f);\n        float _984;\n        if (front)\n        {\n            _984 = _982 * _982;\n        }\n        else\n        {\n            _984 = 0.0f;\n        }\n        atten = _984;\n        bool _995 = _775 < 2.5f;\n        if ((_775 > 1.5f) && _995)\n        {\n            int param_22 = _759 + 2;\n            float4 _1003 = fa_light_texel(param_22);\n            float _1013 = _1003.w;\n            int param_23 = _759 + 3;\n            float4 _1018 = fa_light_texel(param_23);\n            float _1019 = _1018.x;\n            float cos_inner = _1019;\n            if (_1019 > 1.5f)\n            {\n                cos_inner = lerp(_1013, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1013, cos_inner, dot(-l, normalize(_1003.xyz)));\n        }\n        if (_763 && (_775 < 1.5f))\n        {\n            int param_24 = _759 + 6;\n            float4 _1043 = fa_light_texel(param_24);\n            if (_1043.z > 0.5f)\n            {\n                float3 _1051 = -to_light;\n                int param_25 = _759 + 4;\n                int param_26 = _759 + 5;\n                float3 _1065 = fa_light_texel(param_25).xyz;\n                float3 _1069 = fa_light_texel(param_26).xyz;\n                float3 _1078 = float3(dot(_1051, _1065), dot(_1051, _1069), dot(_1051, cross(_1065, _1069)));\n                float3 param_27 = _1078;\n                int _1082 = fa_cube_face(param_27);\n                int param_28 = _1082;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1109 = float2(dot(_1078, cross(param_29, param_30)), dot(_1078, param_30)) / max(dot(_1078, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1113 = _1082 / 3;\n                float2 param_31 = _1043.xy + (float2(float(_1082 - (_1113 * 3)), float(_1113)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1109.x), 0.5f - (0.5f * _1109.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _759 + 7;\n            float4 _1143 = fa_light_texel(param_33);\n            if (_1143.z > 0.5f)\n            {\n                int param_34 = _759 + 2;\n                int param_35 = _759 + 4;\n                int param_36 = _759 + 5;\n                float2 param_37 = _1143.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_763 && _995)\n            {\n                int param_42 = _759 + 6;\n                float4 _1190 = fa_light_texel(param_42);\n                int param_43 = _759 + 7;\n                float4 _1195 = fa_light_texel(param_43);\n                bool _1198 = _1190.z > 0.5f;\n                bool _1205;\n                if (!_1198)\n                {\n                    _1205 = _1195.z > 0.5f;\n                }\n                else\n                {\n                    _1205 = _1198;\n                }\n                if (_1205)\n                {\n                    int param_44 = _759 + 2;\n                    float4 _1212 = fa_light_texel(param_44);\n                    float3 _1216 = normalize(_1212.xyz);\n                    int param_45 = _759 + 4;\n                    float4 _1221 = fa_light_texel(param_45);\n                    int param_46 = _759 + 5;\n                    float4 _1226 = fa_light_texel(param_46);\n                    if (_1198)\n                    {\n                        float3 _1234 = -to_light;\n                        float _1241 = _1212.w;\n                        float _1257 = 0.5f / max(dot(_1234, _1216) * (sqrt(max(1.0f - (_1241 * _1241), 0.0f)) / max(_1241, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1190.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1234, _1221.xyz) * _1257), 0.5f - (dot(_1234, _1226.xyz) * _1257));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1195.z > 0.5f)\n                    {\n                        float2 param_49 = _1195.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1216;\n                        float3 param_52 = _1221.xyz;\n                        float3 param_53 = _1226.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4942 = _772.xyz * atten;\n    if (_763)\n    {\n        _4942 *= fa_light_tint;\n    }\n    int _1326;\n    if (_789)\n    {\n        _1326 = 0;\n    }\n    else\n    {\n        _1326 = ((_775 > 1.5f) && (_775 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _4953 = { l, _4942, atten, 1.0f, dist, _1326 };\n    return _4953;\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _4034 = n < 0;\n    bool _4041;\n    if (!_4034)\n    {\n        _4041 = n >= fa_light_count();\n    }\n    else\n    {\n        _4041 = _4034;\n    }\n    if (_4041)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _4049 = fa_cl_light(param);\n    bool _4052 = fa_lm.z > 0.5f;\n    bool _4058;\n    if (_4052)\n    {\n        int param_1 = _4049;\n        _4058 = fa_light_baked(param_1);\n    }\n    else\n    {\n        _4058 = _4052;\n    }\n    if (_4058)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _4049;\n    float3 param_3 = i.world_pos;\n    float3 param_4 = i.world_normal;\n    LightSample _4071 = fa_light_sample_n(param_2, param_3, param_4);\n    return _4071;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2063;\n    if (i == 0)\n    {\n        _2063 = _2073_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2079;\n        if (i == 1)\n        {\n            _2079 = _2073_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2087;\n            if (i == 2)\n            {\n                _2087 = _2073_fa_shadow_split.z;\n            }\n            else\n            {\n                _2087 = _2073_fa_shadow_split.w;\n            }\n            _2079 = _2087;\n        }\n        _2063 = _2079;\n    }\n    return _2063;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2120 = fa_shadow_depth(param, param_1);\n    float _2124;\n    if (conv.x < 0.5f)\n    {\n        _2124 = _2120;\n    }\n    else\n    {\n        _2124 = (conv.y * conv.z) / (conv.z - (_2120 * (conv.z - conv.y)));\n    }\n    return _2124;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2051 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2051), sin(_2051)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2170 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2179;\n        if (k < 0.0f)\n        {\n            _2179 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2179 = k;\n        }\n        float _2199 = clamp((_2179 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2170;\n            float2 _2218 = fa_shadow_vogel(param_3, param_4, param_5) * _2199;\n            float2 param_6 = uv + (_2218 * _2073_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2230 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2230 < (zr - (length(_2218) * plane)))\n            {\n                sum += _2230;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2256 = sum / cnt;\n        float _2266;\n        if (k < 0.0f)\n        {\n            _2266 = (-k) / max(_2256, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2266 = k;\n        }\n        radius = clamp(((max(zr - _2256, 0.0f) * unit) * _2266) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2288 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2288; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2288;\n        float param_11 = _2170;\n        float2 _2307 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2307 * _2073_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2307) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2288);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2349 = max(_2073_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2354 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2360 = sqrt(1.0f - (_2354 * _2354));\n    float _2367 = min(_2360 / max(_2354, 0.20000000298023223876953125f), 4.0f);\n    float _2372;\n    if (_2073_fa_shadow_bias.y > 0.0f)\n    {\n        _2372 = _2073_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2372 = 1.5f * _2073_fa_shadow_info[ci].x;\n    }\n    float4 _2397 = mul(float4(world + (n * (_2372 * _2360)), 1.0f), _2073_fa_shadow_mat[ci]);\n    float _2404 = _2397.x;\n    bool _2407 = _2404 < _2073_fa_shadow_rect[ci].x;\n    bool _2416;\n    if (!_2407)\n    {\n        _2416 = _2404 > _2073_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2416 = _2407;\n    }\n    bool _2425;\n    if (!_2416)\n    {\n        _2425 = _2397.y < _2073_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2425 = _2416;\n    }\n    bool _2434;\n    if (!_2425)\n    {\n        _2434 = _2397.y > _2073_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2434 = _2425;\n    }\n    bool _2441;\n    if (!_2434)\n    {\n        _2441 = _2397.z > 1.0f;\n    }\n    else\n    {\n        _2441 = _2434;\n    }\n    if (_2441)\n    {\n        return -1.0f;\n    }\n    float _2449;\n    if (_2073_fa_shadow_bias.x > 0.0f)\n    {\n        _2449 = _2073_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2449 = 1.5f * _2073_fa_shadow_info[ci].x;\n    }\n    float2 param = _2397.xy;\n    float4 param_1 = _2073_fa_shadow_rect[ci];\n    float param_2 = _2397.z - ((_2449 * (1.0f + (0.5f * _2367))) / _2349);\n    float param_3 = _2073_fa_shadow_info[ci].x;\n    float param_4 = _2349;\n    float param_5 = _2349 * 0.25f;\n    float param_6 = ((_2073_fa_shadow_info[ci].x * min(_2367, 3.0f)) * 0.5f) / _2349;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2073_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2073_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_365_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2837 = int(_2073_fa_shadow_cfg.x + 0.5f);\n    if (_2837 < 1)\n    {\n        return 1.0f;\n    }\n    float _2852 = dot(world - _2073_fa_shadow_eye.xyz, _2073_fa_shadow_fwd.xyz);\n    int param = _2837 - 1;\n    if (_2852 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2864 = _2837 > 1;\n    bool _2871;\n    if (_2864)\n    {\n        _2871 = _2852 > _2073_fa_shadow_split.x;\n    }\n    else\n    {\n        _2871 = _2864;\n    }\n    if (_2871)\n    {\n        ci = 1;\n    }\n    bool _2875 = _2837 > 2;\n    bool _2882;\n    if (_2875)\n    {\n        _2882 = _2852 > _2073_fa_shadow_split.y;\n    }\n    else\n    {\n        _2882 = _2875;\n    }\n    if (_2882)\n    {\n        ci = 2;\n    }\n    bool _2886 = _2837 > 3;\n    bool _2893;\n    if (_2886)\n    {\n        _2893 = _2852 > _2073_fa_shadow_split.z;\n    }\n    else\n    {\n        _2893 = _2886;\n    }\n    if (_2893)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2837)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2919 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2919;\n        if (_2919 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2073_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2944;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2944 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2944 = _2073_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2963 = _2073_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2944, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2974 = clamp((_2852 - (fa_shadow_split_at(param_7) - _2963)) / _2963, 0.0f, 1.0f);\n        if (_2974 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2837)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2995 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2995;\n                if (_2995 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2974);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _2507 = _365_fa_pbr.z < 0.5f;\n    bool _2514;\n    if (!_2507)\n    {\n        _2514 = _2073_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2514 = _2507;\n    }\n    if (_2514)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2073_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2527 = fa_light_texel(param);\n    float _2528 = _2527.x;\n    if (_2528 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2537 = int(_2528 + 0.5f);\n    int param_1 = _2537;\n    float4 _2541 = fa_light_texel(param_1);\n    int param_2 = _2537 + 1;\n    float4 _2546 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2549 = _2541.y;\n    if (_2549 > 0.0f)\n    {\n        float _2566 = 1.0f - smoothstep(0.75f * _2549, _2549, length(world - _2073_fa_shadow_eye.xyz));\n        fade = _2566;\n        if (_2566 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2541.x > 1.5f)\n    {\n        int param_3 = li;\n        int param_4 = fa_light_base(param_3);\n        float3 param_5 = world - fa_light_texel(param_4).xyz;\n        face = fa_cube_face(param_5);\n    }\n    int _2595 = (_2537 + 2) + (face * 6);\n    int param_6 = _2595;\n    int param_7 = _2595 + 1;\n    int param_8 = _2595 + 3;\n    float4 _2609 = fa_light_texel(param_8);\n    int param_9 = _2595 + 4;\n    float4 _2614 = fa_light_texel(param_9);\n    int param_10 = _2595 + 5;\n    float4 _2619 = fa_light_texel(param_10);\n    float _2631 = _2619.x * max(dot(_2609, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2636 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2659 = clamp(dot(n, _2609.xyz), -1.0f, 1.0f);\n    int param_11 = li;\n    int param_12 = fa_light_base(param_11);\n    float _2683 = min(sqrt(1.0f - (_2659 * _2659)) / max(abs(dot(n, world - fa_light_texel(param_12).xyz)) / max(dot(_2609, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2686 = _2546.y;\n    float _2688;\n    if (_2686 > 0.0f)\n    {\n        _2688 = _2686;\n    }\n    else\n    {\n        _2688 = 1.5f * _2631;\n    }\n    float4 _2708 = float4(world + (n * (_2688 * sqrt(1.0f - (_2636 * _2636)))), 1.0f);\n    float _2712 = dot(_2609, _2708);\n    float _2715 = _2619.y;\n    if (_2712 < _2715)\n    {\n        return 1.0f;\n    }\n    float2 _2730 = float2(dot(fa_light_texel(param_6), _2708), dot(fa_light_texel(param_7), _2708)) / _2712.xx;\n    float _2732 = _2730.x;\n    bool _2735 = _2732 < _2614.x;\n    bool _2744;\n    if (!_2735)\n    {\n        _2744 = _2732 > _2614.z;\n    }\n    else\n    {\n        _2744 = _2735;\n    }\n    bool _2753;\n    if (!_2744)\n    {\n        _2753 = _2730.y < _2614.y;\n    }\n    else\n    {\n        _2753 = _2744;\n    }\n    bool _2762;\n    if (!_2753)\n    {\n        _2762 = _2730.y > _2614.w;\n    }\n    else\n    {\n        _2762 = _2753;\n    }\n    if (_2762)\n    {\n        return 1.0f;\n    }\n    float _2768 = _2546.x;\n    float _2770;\n    if (_2768 > 0.0f)\n    {\n        _2770 = _2768;\n    }\n    else\n    {\n        _2770 = 1.5f * _2631;\n    }\n    float2 param_13 = _2730;\n    float4 param_14 = _2614;\n    float param_15 = _2712 - (_2770 * (1.0f + (0.5f * _2683)));\n    float param_16 = _2631;\n    float param_17 = 1.0f;\n    float param_18 = _2619.z * 0.25f;\n    float param_19 = (_2631 * min(_2683, 3.0f)) * 0.5f;\n    float3 param_20 = float3(1.0f, _2715, _2619.z);\n    int param_21 = int(_2541.z + 0.5f);\n    float param_22 = _2541.w;\n    return lerp(1.0f, fa_shadow_filter(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _3918 = fa_lm.z > 0.5f;\n    bool _3924;\n    if (_3918)\n    {\n        int param = li;\n        _3924 = fa_light_baked(param);\n    }\n    else\n    {\n        _3924 = _3918;\n    }\n    if (_3924)\n    {\n        int param_1 = li;\n        LightSample _5086 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _5086;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3948 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _5088 = _3948.color;\n    float _5090 = _3948.shadow;\n    if ((_3948.type == 0) && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3948.direction;\n        float _3962 = fa_shadow_factor(param_5, param_6);\n        _5090 = _3962;\n        _5088 *= _3962;\n    }\n    else\n    {\n        bool _3973 = _3948.type != 0;\n        bool _3979;\n        if (_3973)\n        {\n            _3979 = _3948.attenuation > 0.0f;\n        }\n        else\n        {\n            _3979 = _3973;\n        }\n        if (_3979)\n        {\n            int param_7 = li;\n            float3 param_8 = world_pos;\n            float3 param_9 = gn;\n            float3 param_10 = _3948.direction;\n            float _3991 = fa_shadow_local(param_7, param_8, param_9, param_10);\n            _5090 = _3991;\n            _5088 *= _3991;\n        }\n    }\n    LightSample _5105 = { _3948.direction, _5088, _3948.attenuation, _5090, _3948._distance, _3948.type };\n    return _5105;\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _4008 = n < 0;\n    bool _4015;\n    if (!_4008)\n    {\n        _4015 = n >= fa_light_count();\n    }\n    else\n    {\n        _4015 = _4008;\n    }\n    if (_4015)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    LightSample _4030 = fa_light_shadowed(param_1, param_2, param_3);\n    return _4030;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3274 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3282 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3285 = int(_3274);\n    int _3288 = int(_3282);\n    float _3298 = _3282 - float(_3288);\n    int _3354 = (_3285 * 9) + _3288;\n    int _3374 = ((_3285 + 1) * 9) + _3288;\n    return lerp(lerp(_3349[_3354], _3349[_3354 + 1], _3298), lerp(_3349[_3374], _3349[_3374 + 1], _3298), _3274 - float(_3285));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _4954 = false;\n    float _4955 = 1.0f;\n    float _4956 = 1.0f;\n    float _4957 = 1.0f;\n    float _4958 = 0.0f;\n    float _4959 = 0.0f;\n    float _4960 = 0.0f;\n    float _4961 = 0.0f;\n    float _4963 = 1.0f;\n    bool _4964 = false;\n    float3 _4965 = 0.0f.xxx;\n    float _4966 = 1.0f;\n    float _4967 = 1.0f;\n    float _4968 = 1.0f;\n    float _4969 = 0.0f;\n    float _4970 = 0.0f;\n    float3 _4971 = float3(1.0f, 0.0f, 0.0f);\n    float3 _4972 = float3(0.0f, 0.0f, 1.0f);\n    float _4973 = 1.0f;\n    float _4974 = 1.0f;\n    float _3425 = clamp(s.specular, 0.0f, 1.0f);\n    float _3429 = clamp(s.ior, 1.0f, 3.0f);\n    bool _3434 = (_3425 != 1.0f) || (_3429 != 1.5f);\n    bool _3443;\n    if (!_3434)\n    {\n        _3443 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _3443 = _3434;\n    }\n    if (_3443)\n    {\n        float _3451 = (_3429 - 1.0f) / (_3429 + 1.0f);\n        f0 = lerp(min((_3451 * _3451).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _3425, s.albedo, metallic.xxx);\n        _4955 = lerp(_3425, 1.0f, metallic);\n        _4954 = true;\n    }\n    float _3478 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_3478 > 0.0f)\n    {\n        float _3486 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _4958 = _3478;\n        _4959 = _3486;\n        float _3493 = _3486 * _3486;\n        _4960 = _3493;\n        _4961 = _3493 * _3493;\n        float _3505 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _4963 = _3505;\n        _4956 = 1.0f - (_3478 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _3505, 0.0f, 1.0f), 5.0f))));\n        _4954 = true;\n    }\n    float3 _3525 = max(s.sheen_color, 0.0f.xxx);\n    float _3534 = max(_3525.x, max(_3525.y, _3525.z));\n    if (_3534 > 0.0f)\n    {\n        float _3542 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _4964 = true;\n        _4965 = _3525;\n        _4966 = _3542;\n        _4967 = _3542 * _3542;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _3542;\n        float _3559 = fa_sheen_albedo(param, param_1);\n        _4969 = _3559;\n        _4968 = 1.0f - min(_3534 * _3559, 1.0f);\n        _4954 = true;\n    }\n    _4957 = _4956 * _4968;\n    float _3578 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_3578 != 0.0f)\n    {\n        float3 _3593 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _3593;\n        if (dot(_3593, _3593) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _3605 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_3605.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _3605.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _3605.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _3609 = t;\n        float3 _3610 = normalize(_3609);\n        t = _3610;\n        float3 _3635 = normalize((_3610 * cos(s.anisotropy_rotation)) + ((cross(n, _3610) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _4971 = _3635;\n        _4972 = cross(n, _3635);\n        float _3645 = roughness * roughness;\n        float _3651 = lerp(_3645, 1.0f, _3578 * _3578);\n        bool _3653 = _3578 > 0.0f;\n        _4973 = _3653 ? _3651 : _3645;\n        _4974 = _3653 ? _3645 : _3651;\n        _4970 = _3578;\n        _4954 = true;\n    }\n    FaLayers _4996 = { _4954, _4955, _4956, _4957, _4958, _4959, _4960, _4961, i.world_normal, _4963, _4964, _4965, _4966, _4967, _4968, _4969, _4970, _4971, _4972, _4973, _4974 };\n    return _4996;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3206 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3209 = _3206.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3209 * _3209, exp2((-9.27999973297119140625f) * ndv)) * _3209) + _3206.y)) + _3206.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_365_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _365_fa_env_horizon.w).xyz;\n    }\n    float _3130 = rough * rough;\n    float _3160 = 0.60000002384185791015625f * _3130;\n    return lerp(lerp(_365_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_365_fa_env_horizon.xyz, _365_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3130)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3160, 0.0500000007450580596923828125f + _3160, d.y).xxx), ((_365_fa_env_sky.xyz + _365_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3130 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _3686;\n        if (L.aniso >= 0.0f)\n        {\n            _3686 = L.b;\n        }\n        else\n        {\n            _3686 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_3686, v), _3686), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3719 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _3719.x) + (L.f90.xxx * _3719.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3774 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _3774.x) + _3774.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3248 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3248.x) + _3248.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _3813 = clamp(s.metallic, 0.0f, 1.0f);\n    float _3817 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _3824 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _3813.xxx);\n    float3 f0 = _3824;\n    float3 _3828 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _3828;\n    float3 param_3 = i.view_dir;\n    float param_4 = _3813;\n    float param_5 = _3817;\n    float3 param_6 = _3824;\n    FaLayers _3845 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_3845.on)\n    {\n        FaLayers param_7 = _3845;\n        float3 param_8 = _3828;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _3817;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _3828;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _3817;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0f;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _4091 = fa_light_unshadowed(param, param_1);\n        float _4099 = dot(_4091.color, float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));\n        if (_4099 > bestPower)\n        {\n            bestPower = _4099;\n            best = n;\n        }\n    }\n    float3 lit = (_365_fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _4128 = fa_light(param_2, param_3);\n        float _4136;\n        if (dot(s.normal, _4128.direction) > 0.5f)\n        {\n            _4136 = 1.0f;\n        }\n        else\n        {\n            _4136 = _4142_dark;\n        }\n        lit += ((s.albedo * _4128.color) * _4136);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * _4142_skyAmount);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2073_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3019 = int(_2073_fa_shadow_cfg.x + 0.5f);\n    float _3029 = dot(world - _2073_fa_shadow_eye.xyz, _2073_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3034 = _3019 > 0;\n    bool _3043;\n    if (_3034)\n    {\n        int param = _3019 - 1;\n        _3043 = _3029 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3043 = _3034;\n    }\n    if (_3043)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3049 = _3019 > 1;\n        bool _3056;\n        if (_3049)\n        {\n            _3056 = _3029 > _2073_fa_shadow_split.x;\n        }\n        else\n        {\n            _3056 = _3049;\n        }\n        if (_3056)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3062 = _3019 > 2;\n        bool _3069;\n        if (_3062)\n        {\n            _3069 = _3029 > _2073_fa_shadow_split.y;\n        }\n        else\n        {\n            _3069 = _3062;\n        }\n        if (_3069)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3075 = _3019 > 3;\n        bool _3082;\n        if (_3075)\n        {\n            _3082 = _3029 > _2073_fa_shadow_split.z;\n        }\n        else\n        {\n            _3082 = _3075;\n        }\n        if (_3082)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _4828 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4828 = -_4828;\n    }\n    float3 _4514 = normalize(_365_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _4841 = { fa_world_pos, _4828, fa_world_tangent, fa_uv, fa_vertex_color, _4514, gl_FrontFacing };\n    SurfaceInput param_1 = _4841;\n    Surface _4522 = fa_standard_surface(param_1);\n    float3 _4859 = _4522.albedo;\n    float _4860 = _4522.alpha;\n    float3 _4861 = _4522.normal;\n    float _4862 = _4522.metallic;\n    float _4863 = _4522.roughness;\n    float _4864 = _4522.occlusion;\n    float3 _4865 = _4522.emission;\n    float _4866 = _4522.clearcoat;\n    float _4867 = _4522.clearcoat_roughness;\n    float3 _4868 = _4522.sheen_color;\n    float _4869 = _4522.sheen_roughness;\n    float _4870 = _4522.anisotropy;\n    float _4871 = _4522.anisotropy_rotation;\n    float _4872 = _4522.specular;\n    float _4873 = _4522.ior;\n    float3 _4874 = _4522.specular_color;\n    SurfaceInput _4849 = { fa_world_pos, _4828, fa_world_tangent, fa_uv, fa_vertex_color, _4514, gl_FrontFacing };\n    SurfaceInput param_2 = _4849;\n    Surface param_3 = _4522;\n    surface(param_2, param_3);\n    _4859 = param_3.albedo;\n    _4860 = param_3.alpha;\n    _4861 = param_3.normal;\n    _4862 = param_3.metallic;\n    _4863 = param_3.roughness;\n    _4864 = param_3.occlusion;\n    _4865 = param_3.emission;\n    _4866 = param_3.clearcoat;\n    _4867 = param_3.clearcoat_roughness;\n    _4868 = param_3.sheen_color;\n    _4869 = param_3.sheen_roughness;\n    _4870 = param_3.anisotropy;\n    _4871 = param_3.anisotropy_rotation;\n    _4872 = param_3.specular;\n    _4873 = param_3.ior;\n    _4874 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _4828;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4859 = param_6;\n    _4861 = param_7;\n    float3 result;\n    if (_365_fa_emissive.w > 0.5f)\n    {\n        result = _4859;\n    }\n    else\n    {\n        float3 _4560 = _4861;\n        float3 _4561 = normalize(_4560);\n        _4861 = _4561;\n        SurfaceInput _4857 = { fa_world_pos, _4828, fa_world_tangent, fa_uv, fa_vertex_color, _4514, gl_FrontFacing };\n        SurfaceInput param_8 = _4857;\n        Surface _4940 = { _4859, _4860, _4561, _4862, _4863, _4864, _4865, _4866, _4867, _4868, _4869, _4870, _4871, _4872, _4873, _4874 };\n        Surface param_9 = _4940;\n        float3 _4572 = lighting(param_8, param_9);\n        result = _4572;\n    }\n    float3 _4576 = result;\n    float3 _4577 = _4576 + _4865;\n    result = _4577;\n    float3 param_10 = _4577;\n    float3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _4586 = _365_fa_fog.w > 0.0f;\n    bool _4593;\n    if (!_4586)\n    {\n        _4593 = _365_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _4593 = _4586;\n    }\n    if (_4593)\n    {\n        float3 _4602 = fa_world_pos - _365_fa_camera_pos.xyz;\n        float _4608 = dot(_4602, _365_fa_fog_c.xyz);\n        bool _4612 = _365_fa_fog_c.w > 0.5f;\n        float _4613;\n        if (_4612)\n        {\n            _4613 = _4608;\n        }\n        else\n        {\n            _4613 = length(_4602);\n        }\n        float _4625 = _4613 - _365_fa_fog_b.x;\n        if (_4625 > 0.0f)\n        {\n            float _4634 = _365_fa_fog.w * _4625;\n            float tau = _4634 * _4634;\n            if (_365_fa_fog_b.y > 0.0f)\n            {\n                float _4650;\n                if (_4612)\n                {\n                    _4650 = fa_world_pos.y - (_365_fa_fog_c.y * _4608);\n                }\n                else\n                {\n                    _4650 = _365_fa_camera_pos.y;\n                }\n                float _4671 = lerp(_4650, fa_world_pos.y, clamp(_365_fa_fog_b.x / _4613, 0.0f, 1.0f));\n                float _4675 = fa_world_pos.y - _4671;\n                float _4680 = _4671 - _365_fa_fog_b.z;\n                float _4685 = fa_world_pos.y - _365_fa_fog_b.z;\n                bool _4688 = _4680 <= 0.0f;\n                bool _4689 = !_4688;\n                bool _4695;\n                if (_4689)\n                {\n                    _4695 = _365_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4695 = _4688;\n                }\n                float _4696;\n                if (_4695)\n                {\n                    _4696 = _365_fa_fog_b.y;\n                }\n                else\n                {\n                    _4696 = _365_fa_fog_b.y * exp(-min(_365_fa_fog_b.w * _4680, 80.0f));\n                }\n                bool _4723;\n                if (_4689)\n                {\n                    _4723 = _365_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4723 = _4688;\n                }\n                float _4724;\n                if (_4723)\n                {\n                    _4724 = _365_fa_fog_b.y * _4680;\n                }\n                else\n                {\n                    _4724 = (_365_fa_fog_b.y * (1.0f - exp(-min(_365_fa_fog_b.w * _4680, 80.0f)))) / _365_fa_fog_b.w;\n                }\n                bool _4749 = _4685 <= 0.0f;\n                bool _4756;\n                if (!_4749)\n                {\n                    _4756 = _365_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4756 = _4749;\n                }\n                float _4757;\n                if (_4756)\n                {\n                    _4757 = _365_fa_fog_b.y * _4685;\n                }\n                else\n                {\n                    _4757 = (_365_fa_fog_b.y * (1.0f - exp(-min(_365_fa_fog_b.w * _4685, 80.0f)))) / _365_fa_fog_b.w;\n                }\n                float _4784;\n                if (abs(_4675) < 0.001000000047497451305389404296875f)\n                {\n                    _4784 = _4696;\n                }\n                else\n                {\n                    _4784 = (_4757 - _4724) / _4675;\n                }\n                tau += (_4625 * max(_4784, 0.0f));\n            }\n            result = lerp(result, _365_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4860);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_2073",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_4142",
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
