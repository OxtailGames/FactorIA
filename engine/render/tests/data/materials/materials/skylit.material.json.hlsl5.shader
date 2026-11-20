{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "27973f29289cdb06f6da050426786ada05329a25848bb279986221a7a56fee4b",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _260 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _260;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_267, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _3524[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _437_fa_camera_pos : packoffset(c0);\n    float4 _437_fa_ambient : packoffset(c1);\n    float4 _437_fa_base_color : packoffset(c2);\n    float4 _437_fa_emissive : packoffset(c3);\n    float4 _437_fa_model_emissive : packoffset(c4);\n    float4 _437_fa_pbr : packoffset(c5);\n    float4 _437_fa_maps : packoffset(c6);\n    float4 _437_fa_fog : packoffset(c7);\n    float4 _437_fa_fog_b : packoffset(c8);\n    float4 _437_fa_fog_c : packoffset(c9);\n    float4 _437_fa_counts : packoffset(c10);\n    float4 _437_fa_env_sky : packoffset(c11);\n    float4 _437_fa_env_horizon : packoffset(c12);\n    float4 _437_fa_time : packoffset(c13);\n    float4 _437_fa_cl_vpx : packoffset(c14);\n    float4 _437_fa_cl_vpy : packoffset(c15);\n    float4 _437_fa_cl_vpw : packoffset(c16);\n    float4 _437_fa_cl_fwd : packoffset(c17);\n    float4 _437_fa_cl_grid : packoffset(c18);\n    float4 _437_fa_cl_info : packoffset(c19);\n    float4 _437_fa_layers_a : packoffset(c20);\n    float4 _437_fa_layers_b : packoffset(c21);\n    float4 _437_fa_layers_c : packoffset(c22);\n    float4 _437_fa_layers_d : packoffset(c23);\n    float4 _437_fa_ct_a : packoffset(c24);\n    float4 _437_fa_ct_b : packoffset(c25);\n    float4 _437_fa_ct_vpx : packoffset(c26);\n    float4 _437_fa_ct_vpy : packoffset(c27);\n    float4 _437_fa_ct_vpw : packoffset(c28);\n    float4 _437_fa_ct_fwd : packoffset(c29);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2094_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2094_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2094_fa_shadow_info[4] : packoffset(c20);\n    float4 _2094_fa_shadow_split : packoffset(c24);\n    float4 _2094_fa_shadow_cfg : packoffset(c25);\n    float4 _2094_fa_shadow_bias : packoffset(c26);\n    float4 _2094_fa_shadow_eye : packoffset(c27);\n    float4 _2094_fa_shadow_fwd : packoffset(c28);\n    float4 _2094_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_screen_tex : register(t11);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1365 = _437_fa_cl_info.x < 0.0f;\n    bool _1372;\n    if (!_1365)\n    {\n        _1372 = _437_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1372 = _1365;\n    }\n    bool _1380;\n    if (!_1372)\n    {\n        _1380 = _437_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1380 = _1372;\n    }\n    bool _1387;\n    if (!_1380)\n    {\n        _1387 = _437_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1387 = _1380;\n    }\n    bool _1394;\n    if (!_1387)\n    {\n        _1394 = _437_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1394 = _1387;\n    }\n    if (_1394)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1404 = float4(world_pos, 1.0f);\n    float _1410 = dot(_437_fa_cl_vpw, _1404);\n    if (!(_1410 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1432 = float2(dot(_437_fa_cl_vpx, _1404), dot(_437_fa_cl_vpy, _1404)) / _1410.xx;\n    int _1436 = int(_437_fa_cl_grid.x);\n    int _1440 = int(_437_fa_cl_grid.y);\n    int param = (int(_437_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_437_fa_cl_fwd.xyz, world_pos) + _437_fa_cl_fwd.w, _437_fa_cl_grid.w) / _437_fa_cl_grid.w) * _437_fa_cl_grid.z)), 0, int(_437_fa_cl_info.y) - 1) * _1440) + clamp(int(floor(((_1432.y * 0.5f) + 0.5f) * _437_fa_cl_grid.y)), 0, _1440 - 1)) * _1436)) + clamp(int(floor(((_1432.x * 0.5f) + 0.5f) * _437_fa_cl_grid.x)), 0, _1436 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1516 = fa_cluster_texel(param);\n    return int2(int(_1516.x), int(_1516.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_437_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4305 = fa_cluster_lookup(param);\n    fa_cl_slot = _4305.x;\n    fa_cl_local = _4305.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _4512 = fa_linear_to_srgb(param);\n        c = _4512;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _4520 = fa_srgb_to_linear(param_1);\n            c = _4520;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _320;\n    if (i.front_facing)\n    {\n        _320 = i.world_normal;\n    }\n    else\n    {\n        _320 = -i.world_normal;\n    }\n    float3 _344 = normalize(i.world_tangent.xyz - (_320 * dot(_320, i.world_tangent.xyz)));\n    float3 _371 = normalize(((_344 * m.x) + ((cross(_320, _344) * i.world_tangent.w) * m.y)) + (_320 * m.z));\n    float3 _374;\n    if (i.front_facing)\n    {\n        _374 = _371;\n    }\n    else\n    {\n        _374 = -_371;\n    }\n    return _374;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _437_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _4551 = fa_tex_fix(param_2, param_3);\n    float4 _5679 = base_t;\n    _5679.x = _4551.x;\n    _5679.y = _4551.y;\n    _5679.z = _4551.z;\n    base_t = _5679;\n    float4 _4565 = (_5679 * _437_fa_base_color) * i.vertex_color;\n    float3 _5518 = i.world_normal;\n    if (_437_fa_maps.z > 0.5f)\n    {\n        float param_4 = _437_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4597 = fa_tex_fix(param_6, param_7);\n        float3 _4600 = (_4597 * 2.0f) - 1.0f.xxx;\n        float2 _4605 = _4600.xy * _437_fa_maps.x;\n        float3 _5687 = _4600;\n        _5687.x = _4605.x;\n        _5687.y = _4605.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5687;\n        _5518 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _437_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4633 = fa_tex_fix(param_12, param_13);\n    float4 _5690 = mrt;\n    _5690.x = _4633.x;\n    _5690.y = _4633.y;\n    _5690.z = _4633.z;\n    mrt = _5690;\n    float4 _4661 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _437_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _4661.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4672 = fa_tex_fix(param_16, param_17);\n    float param_18 = _437_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4702 = fa_tex_fix(param_20, param_21);\n    float _5523 = _437_fa_layers_a.x;\n    float _5524 = _437_fa_layers_a.y;\n    float _5527 = _437_fa_layers_a.z;\n    float _5526 = _437_fa_layers_b.w;\n    float _5529 = _437_fa_layers_c.x;\n    if (_437_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_437_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _5523 *= _4672.y;\n            _5524 *= _4672.z;\n            _5526 *= _4661.w;\n        }\n        if (_437_fa_layers_c.z > 1.5f)\n        {\n            _5527 *= mrt.x;\n            _5529 *= mrt.w;\n        }\n    }\n    Surface _5548 = { _4565.xyz, _4565.w, _5518, clamp(_437_fa_pbr.x * _4633.z, 0.0f, 1.0f), clamp(_437_fa_pbr.y * _4633.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_437_fa_maps.y * (_4672.x - 1.0f)), _437_fa_emissive.xyz + (_437_fa_model_emissive.xyz * _4702), _5523, _5524, _437_fa_layers_b.xyz, _5526, _5527, _437_fa_layers_a.w, _5529, _437_fa_layers_c.y, _437_fa_layers_d.xyz };\n    return _5548;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1596 = rect.zw - rect.xy;\n    float2 _1600 = _1596 * atlas;\n    float2 _1604 = ddx * _1600;\n    float2 _1608 = ddy * _1600;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1596), clamp(0.5f * log2(max(max(dot(_1604, _1604), dot(_1608, _1608)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1641 = _437_fa_counts.y < 0.5f;\n    bool _1648;\n    if (!_1641)\n    {\n        _1648 = _437_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1648 = _1641;\n    }\n    if (_1648)\n    {\n        return;\n    }\n    float3 _1654 = ddx(world_pos);\n    float3 _1657 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1661 = fa_cluster_texel(param);\n    int _1665 = int(_1661.w);\n    if (_1665 < 1)\n    {\n        return;\n    }\n    int _1675 = int(_437_fa_counts.y + 0.5f);\n    int param_1 = _1675;\n    float4 _1679 = fa_light_texel(param_1);\n    float2 _1682 = _1679.yz;\n    int _1686 = int(_1679.w);\n    int param_2 = _1675 + 1;\n    float4 _1691 = fa_light_texel(param_2);\n    float _1692 = _1691.x;\n    int _1698 = int(_437_fa_counts.w + 0.5f) - 1;\n    int _1702 = int(_1661.z);\n    float3 _1967;\n    for (int k = 0; k < _1665; k++)\n    {\n        int _1715 = _1702 + k;\n        int param_3 = _1686 + (_1715 >> 2);\n        int _1732 = (_1675 + 2) + (int(fa_light_texel(param_3)[_1715 & 3]) * 7);\n        int param_4 = _1732 + 6;\n        float4 _1737 = fa_light_texel(param_4);\n        if (((int(_1737.w + 0.5f) >> _1698) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1732;\n        float4 _1752 = fa_light_texel(param_5);\n        int param_6 = _1732 + 1;\n        float4 _1757 = fa_light_texel(param_6);\n        int param_7 = _1732 + 2;\n        float4 _1762 = fa_light_texel(param_7);\n        float3 _1765 = _1752.xyz;\n        float _1770 = dot(_1765, world_pos) + _1752.w;\n        float3 _1772 = _1757.xyz;\n        float _1777 = dot(_1772, world_pos) + _1757.w;\n        float3 _1779 = _1762.xyz;\n        float _1784 = dot(_1779, world_pos) + _1762.w;\n        bool _1789 = abs(_1770) > 0.5f;\n        bool _1797;\n        if (!_1789)\n        {\n            _1797 = abs(_1777) > 0.5f;\n        }\n        else\n        {\n            _1797 = _1789;\n        }\n        bool _1805;\n        if (!_1797)\n        {\n            _1805 = abs(_1784) > 0.5f;\n        }\n        else\n        {\n            _1805 = _1797;\n        }\n        if (_1805)\n        {\n            continue;\n        }\n        float _1820 = clamp(dot(geo_normal, normalize(_1779)) * _1737.z, 0.0f, 1.0f);\n        if (_1820 <= 0.0f)\n        {\n            continue;\n        }\n        float _1840 = (clamp((0.5f - abs(_1784)) * 10.0f, 0.0f, 1.0f) * _1820) * _1737.x;\n        float2 _1848 = float2(_1770 + 0.5f, 0.5f - _1777);\n        float2 _1858 = float2(dot(_1765, _1654), dot(_1772, _1654));\n        float2 _1868 = float2(dot(_1765, _1657), dot(_1772, _1657));\n        int param_8 = _1732 + 5;\n        float4 _1873 = fa_light_texel(param_8);\n        int param_9 = _1732 + 3;\n        float4 _1878 = fa_light_texel(param_9);\n        int param_10 = _1732 + 4;\n        float4 _1883 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1873.xyz;\n        bool _1893 = _1878.z > _1878.x;\n        if (_1893)\n        {\n            float4 param_11 = _1878;\n            float2 param_12 = _1848;\n            float2 param_13 = _1682;\n            float2 param_14 = _1858;\n            float2 param_15 = _1868;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1692 > 0.5f) && (_1692 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1919 = fa_dc_to_linear(param_16);\n                float4 _5598 = tx;\n                _5598.x = _1919.x;\n                _5598.y = _1919.y;\n                _5598.z = _1919.z;\n                tx = _5598;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1840 * tex_a) * _1873.w, 0.0f, 1.0f).xxx);\n        if (_1883.z > _1883.x)\n        {\n            float4 param_17 = _1883;\n            float2 param_18 = _1848;\n            float2 param_19 = _1682;\n            float2 param_20 = _1858;\n            float2 param_21 = _1868;\n            float4 _1963 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1692 > 1.5f)\n            {\n                float3 param_22 = _1963.xyz;\n                float3 _1973 = fa_dc_to_srgb(param_22);\n                _1967 = _1973;\n            }\n            else\n            {\n                _1967 = _1963.xyz;\n            }\n            float3 _1982 = (_1967 * 2.0f) - 1.0f.xxx;\n            float2 _1987 = _1982.xy * _1737.y;\n            float3 _2009 = (normalize(_1765) * _1987.x) + (normalize(_1772) * _1987.y);\n            float3 _2012 = normalize(normal);\n            normal = normalize(lerp(_2012, normalize((_2012 * max(_1982.z, 0.0500000007450580596923828125f)) + (_2009 - (_2012 * dot(_2012, _2009)))), clamp(_1840 * (_1893 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_sky_sh_coef(int k)\n{\n    float3 v = fa_env_tex.SampleLevel(fa_env_smp, float3(1.0f, 1.0f - (float((2 * (k >> 2)) + 1) * 0.25f), 1.0f - (float((2 * (k & 3)) + 1) * 0.25f)), 5.0f).xyz;\n    if (_437_fa_env_sky.w > 1.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3207 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3207;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_437_fa_env_sky.w > 0.5f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _437_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3450 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3457 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3460 = int(_3450);\n    int _3463 = int(_3457);\n    float _3473 = _3457 - float(_3463);\n    int _3528 = (_3460 * 9) + _3463;\n    int _3548 = ((_3460 + 1) * 9) + _3463;\n    return lerp(lerp(_3524[_3528], _3524[_3528 + 1], _3473), lerp(_3524[_3548], _3524[_3548 + 1], _3473), _3450 - float(_3460));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _5377 = false;\n    float _5378 = 1.0f;\n    float _5379 = 1.0f;\n    float _5380 = 1.0f;\n    float _5381 = 0.0f;\n    float _5382 = 0.0f;\n    float _5383 = 0.0f;\n    float _5384 = 0.0f;\n    float _5386 = 1.0f;\n    bool _5387 = false;\n    float3 _5388 = 0.0f.xxx;\n    float _5389 = 1.0f;\n    float _5390 = 1.0f;\n    float _5391 = 1.0f;\n    float _5392 = 0.0f;\n    float _5393 = 0.0f;\n    float3 _5394 = float3(1.0f, 0.0f, 0.0f);\n    float3 _5395 = float3(0.0f, 0.0f, 1.0f);\n    float _5396 = 1.0f;\n    float _5397 = 1.0f;\n    float _3599 = clamp(s.specular, 0.0f, 1.0f);\n    float _3603 = clamp(s.ior, 1.0f, 3.0f);\n    bool _3608 = (_3599 != 1.0f) || (_3603 != 1.5f);\n    bool _3617;\n    if (!_3608)\n    {\n        _3617 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _3617 = _3608;\n    }\n    if (_3617)\n    {\n        float _3625 = (_3603 - 1.0f) / (_3603 + 1.0f);\n        f0 = lerp(min((_3625 * _3625).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _3599, s.albedo, metallic.xxx);\n        _5378 = lerp(_3599, 1.0f, metallic);\n        _5377 = true;\n    }\n    float _3652 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_3652 > 0.0f)\n    {\n        float _3660 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _5381 = _3652;\n        _5382 = _3660;\n        float _3667 = _3660 * _3660;\n        _5383 = _3667;\n        _5384 = _3667 * _3667;\n        float _3679 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _5386 = _3679;\n        _5379 = 1.0f - (_3652 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _3679, 0.0f, 1.0f), 5.0f))));\n        _5377 = true;\n    }\n    float3 _3698 = max(s.sheen_color, 0.0f.xxx);\n    float _3707 = max(_3698.x, max(_3698.y, _3698.z));\n    if (_3707 > 0.0f)\n    {\n        float _3715 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _5387 = true;\n        _5388 = _3698;\n        _5389 = _3715;\n        _5390 = _3715 * _3715;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _3715;\n        float _3732 = fa_sheen_albedo(param, param_1);\n        _5392 = _3732;\n        _5391 = 1.0f - min(_3707 * _3732, 1.0f);\n        _5377 = true;\n    }\n    _5380 = _5379 * _5391;\n    float _3751 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_3751 != 0.0f)\n    {\n        float3 _3766 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _3766;\n        if (dot(_3766, _3766) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _3778 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_3778.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _3778.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _3778.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _3782 = t;\n        float3 _3783 = normalize(_3782);\n        t = _3783;\n        float3 _3808 = normalize((_3783 * cos(s.anisotropy_rotation)) + ((cross(n, _3783) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _5394 = _3808;\n        _5395 = cross(n, _3808);\n        float _3818 = roughness * roughness;\n        float _3824 = lerp(_3818, 1.0f, _3751 * _3751);\n        bool _3826 = _3751 > 0.0f;\n        _5396 = _3826 ? _3824 : _3818;\n        _5397 = _3826 ? _3818 : _3824;\n        _5393 = _3751;\n        _5377 = true;\n    }\n    FaLayers _5419 = { _5377, _5378, _5379, _5380, _5381, _5382, _5383, _5384, i.world_normal, _5386, _5387, _5388, _5389, _5390, _5391, _5392, _5393, _5394, _5395, _5396, _5397 };\n    return _5419;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3382 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3385 = _3382.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3385 * _3385, exp2((-9.27999973297119140625f) * ndv)) * _3385) + _3382.y)) + _3382.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_437_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _437_fa_env_horizon.w).xyz;\n    }\n    float _3236 = rough * rough;\n    float _3266 = 0.60000002384185791015625f * _3236;\n    return lerp(lerp(_437_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_437_fa_env_horizon.xyz, _437_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3236)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3266, 0.0500000007450580596923828125f + _3266, d.y).xxx), ((_437_fa_env_sky.xyz + _437_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3236 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _3859;\n        if (L.aniso >= 0.0f)\n        {\n            _3859 = L.b;\n        }\n        else\n        {\n            _3859 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_3859, v), _3859), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3892 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _3892.x) + (L.f90.xxx * _3892.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3947 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _3947.x) + _3947.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3424 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3424.x) + _3424.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _3976 = clamp(s.metallic, 0.0f, 1.0f);\n    float _3980 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _3987 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _3976.xxx);\n    float3 f0 = _3987;\n    float3 _3991 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _3991;\n    float3 param_3 = i.view_dir;\n    float param_4 = _3976;\n    float param_5 = _3980;\n    float3 param_6 = _3987;\n    FaLayers _4008 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4008.on)\n    {\n        FaLayers param_7 = _4008;\n        float3 param_8 = _3991;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _3980;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _3991;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _3980;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_437_fa_cl_info.x) + int(_437_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_437_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _496_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _496_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _615 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _628 = (c - (ru * hx)) - p;\n        float3 _634 = ru * (2.0f * hx);\n        float _640 = max(dot(_634, _634), 9.9999999392252902907785028219223e-09f);\n        float _644 = dot(_628, _634);\n        float t = clamp((-_644) / _640, 0.0f, 1.0f);\n        if (_615)\n        {\n            float _659 = dot(r, _634);\n            float _665 = _640 - (_659 * _659);\n            if (abs(_665) > (9.9999997473787516355514526367188e-06f * _640))\n            {\n                t = clamp(((dot(r, _628) * _659) - _644) / _665, 0.0f, 1.0f);\n            }\n        }\n        return (p + _628) + (_634 * t);\n    }\n    float3 q = p;\n    float _697 = dot(r, axis);\n    bool _705;\n    if (_615)\n    {\n        _705 = abs(_697) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _705 = _615;\n    }\n    if (_705)\n    {\n        float _715 = dot(c - p, axis) / _697;\n        if (_715 > 0.0f)\n        {\n            q = p + (r * _715);\n        }\n    }\n    float3 _728 = q - c;\n    float2 xy = float2(dot(_728, ru), dot(_728, uu));\n    if (shape > 0.5f)\n    {\n        float _743 = length(xy);\n        if (_743 > hx)\n        {\n            xy *= (hx / _743);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _386 = abs(d);\n    float _388 = _386.x;\n    float _390 = _386.y;\n    bool _391 = _388 >= _390;\n    bool _399;\n    if (_391)\n    {\n        _399 = _388 >= _386.z;\n    }\n    else\n    {\n        _399 = _391;\n    }\n    int _400;\n    if (_399)\n    {\n        _400 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _415;\n        if (_390 >= _386.z)\n        {\n            _415 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _415 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _400 = _415;\n    }\n    return _400;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _535 = dot(d, right);\n    float _539 = dot(d, up);\n    float _550;\n    if (((_535 * _535) + (_539 * _539)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _550 = atan2(_539, _535) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _550 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_550 - floor(_550)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _781 = fa_light_base(param);\n    bool _785 = _437_fa_ambient.w > 4.5f;\n    int param_1 = _781;\n    float4 _789 = fa_light_texel(param_1);\n    int param_2 = _781 + 1;\n    float4 _794 = fa_light_texel(param_2);\n    float _797 = _794.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _809 = _785 && (_797 > 2.5f);\n    fa_light_is_area = _809;\n    bool _811 = _797 < 0.5f;\n    float3 l;\n    if (_811)\n    {\n        l = normalize(_789.xyz);\n        if (_785)\n        {\n            int param_3 = _781 + 6;\n            float4 _825 = fa_light_texel(param_3);\n            if (_825.z > 0.5f)\n            {\n                int param_4 = _781 + 4;\n                float4 _835 = fa_light_texel(param_4);\n                int param_5 = _781 + 5;\n                float4 _840 = fa_light_texel(param_5);\n                float2 param_6 = _825.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _835.xyz) * _835.w, (-dot(world_pos, _840.xyz)) * _840.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _870 = _789.xyz;\n        float3 _872 = _870 - world_pos;\n        float3 to_light = _872;\n        float _875 = length(_872);\n        float reach = _875;\n        bool front = true;\n        if (_809)\n        {\n            int param_8 = _781 + 7;\n            reach = max(_875 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _781 + 4;\n            float4 _899 = fa_light_texel(param_9);\n            int param_10 = _781 + 5;\n            float4 _904 = fa_light_texel(param_10);\n            int param_11 = _781 + 6;\n            float4 _909 = fa_light_texel(param_11);\n            float _910 = _909.w;\n            int param_12 = _781 + 2;\n            float3 _917 = normalize(fa_light_texel(param_12).xyz);\n            bool _919 = _910 > 1.5f;\n            bool _927;\n            if (!_919)\n            {\n                _927 = dot(_917, to_light) < 0.0f;\n            }\n            else\n            {\n                _927 = _919;\n            }\n            front = _927;\n            float3 r = 0.0f.xxx;\n            float3 _936 = _437_fa_camera_pos.xyz - world_pos;\n            bool _940 = dot(n, n) > 0.5f;\n            bool _948;\n            if (_940)\n            {\n                _948 = dot(_936, _936) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _948 = _940;\n            }\n            if (_948)\n            {\n                r = reflect(-normalize(_936), normalize(n));\n            }\n            float3 param_13 = _870;\n            float3 param_14 = _917;\n            float3 param_15 = _899.xyz;\n            float3 param_16 = _904.xyz;\n            float param_17 = _899.w;\n            float param_18 = _904.w;\n            float param_19 = _910;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _984 = length(to_light);\n        dist = _984;\n        l = to_light / max(_984, 9.9999997473787516355514526367188e-05f).xxx;\n        float _998 = reach / max(_789.w, 0.001000000047497451305389404296875f);\n        float _1004 = clamp(1.0f - (_998 * _998), 0.0f, 1.0f);\n        float _1006;\n        if (front)\n        {\n            _1006 = _1004 * _1004;\n        }\n        else\n        {\n            _1006 = 0.0f;\n        }\n        atten = _1006;\n        bool _1017 = _797 < 2.5f;\n        if ((_797 > 1.5f) && _1017)\n        {\n            int param_22 = _781 + 2;\n            float4 _1025 = fa_light_texel(param_22);\n            float _1035 = _1025.w;\n            int param_23 = _781 + 3;\n            float4 _1040 = fa_light_texel(param_23);\n            float _1041 = _1040.x;\n            float cos_inner = _1041;\n            if (_1041 > 1.5f)\n            {\n                cos_inner = lerp(_1035, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1035, cos_inner, dot(-l, normalize(_1025.xyz)));\n        }\n        if (_785 && (_797 < 1.5f))\n        {\n            int param_24 = _781 + 6;\n            float4 _1065 = fa_light_texel(param_24);\n            if (_1065.z > 0.5f)\n            {\n                float3 _1073 = -to_light;\n                int param_25 = _781 + 4;\n                int param_26 = _781 + 5;\n                float3 _1087 = fa_light_texel(param_25).xyz;\n                float3 _1091 = fa_light_texel(param_26).xyz;\n                float3 _1100 = float3(dot(_1073, _1087), dot(_1073, _1091), dot(_1073, cross(_1087, _1091)));\n                float3 param_27 = _1100;\n                int _1104 = fa_cube_face(param_27);\n                int param_28 = _1104;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1131 = float2(dot(_1100, cross(param_29, param_30)), dot(_1100, param_30)) / max(dot(_1100, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1135 = _1104 / 3;\n                float2 param_31 = _1065.xy + (float2(float(_1104 - (_1135 * 3)), float(_1135)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1131.x), 0.5f - (0.5f * _1131.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _781 + 7;\n            float4 _1165 = fa_light_texel(param_33);\n            if (_1165.z > 0.5f)\n            {\n                int param_34 = _781 + 2;\n                int param_35 = _781 + 4;\n                int param_36 = _781 + 5;\n                float2 param_37 = _1165.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_785 && _1017)\n            {\n                int param_42 = _781 + 6;\n                float4 _1212 = fa_light_texel(param_42);\n                int param_43 = _781 + 7;\n                float4 _1217 = fa_light_texel(param_43);\n                bool _1220 = _1212.z > 0.5f;\n                bool _1227;\n                if (!_1220)\n                {\n                    _1227 = _1217.z > 0.5f;\n                }\n                else\n                {\n                    _1227 = _1220;\n                }\n                if (_1227)\n                {\n                    int param_44 = _781 + 2;\n                    float4 _1234 = fa_light_texel(param_44);\n                    float3 _1238 = normalize(_1234.xyz);\n                    int param_45 = _781 + 4;\n                    float4 _1243 = fa_light_texel(param_45);\n                    int param_46 = _781 + 5;\n                    float4 _1248 = fa_light_texel(param_46);\n                    if (_1220)\n                    {\n                        float3 _1256 = -to_light;\n                        float _1263 = _1234.w;\n                        float _1279 = 0.5f / max(dot(_1256, _1238) * (sqrt(max(1.0f - (_1263 * _1263), 0.0f)) / max(_1263, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1212.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1256, _1243.xyz) * _1279), 0.5f - (dot(_1256, _1248.xyz) * _1279));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1217.z > 0.5f)\n                    {\n                        float2 param_49 = _1217.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1238;\n                        float3 param_52 = _1243.xyz;\n                        float3 param_53 = _1248.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _5365 = _794.xyz * atten;\n    if (_785)\n    {\n        _5365 *= fa_light_tint;\n    }\n    int _1347;\n    if (_811)\n    {\n        _1347 = 0;\n    }\n    else\n    {\n        _1347 = ((_797 > 1.5f) && (_797 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _5376 = { l, _5365, atten, 1.0f, dist, _1347 };\n    return _5376;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2084;\n    if (i == 0)\n    {\n        _2084 = _2094_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2100;\n        if (i == 1)\n        {\n            _2100 = _2094_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2108;\n            if (i == 2)\n            {\n                _2108 = _2094_fa_shadow_split.z;\n            }\n            else\n            {\n                _2108 = _2094_fa_shadow_split.w;\n            }\n            _2100 = _2108;\n        }\n        _2084 = _2100;\n    }\n    return _2084;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2141 = fa_shadow_depth(param, param_1);\n    float _2145;\n    if (conv.x < 0.5f)\n    {\n        _2145 = _2141;\n    }\n    else\n    {\n        _2145 = (conv.y * conv.z) / (conv.z - (_2141 * (conv.z - conv.y)));\n    }\n    return _2145;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2072 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2072), sin(_2072)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2191 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2200;\n        if (k < 0.0f)\n        {\n            _2200 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2200 = k;\n        }\n        float _2220 = clamp((_2200 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2191;\n            float2 _2239 = fa_shadow_vogel(param_3, param_4, param_5) * _2220;\n            float2 param_6 = uv + (_2239 * _2094_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2251 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2251 < (zr - (length(_2239) * plane)))\n            {\n                sum += _2251;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2277 = sum / cnt;\n        float _2287;\n        if (k < 0.0f)\n        {\n            _2287 = (-k) / max(_2277, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2287 = k;\n        }\n        radius = clamp(((max(zr - _2277, 0.0f) * unit) * _2287) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2309 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2309; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2309;\n        float param_11 = _2191;\n        float2 _2328 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2328 * _2094_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2328) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2309);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2370 = max(_2094_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2375 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2381 = sqrt(1.0f - (_2375 * _2375));\n    float _2388 = min(_2381 / max(_2375, 0.20000000298023223876953125f), 4.0f);\n    float _2393;\n    if (_2094_fa_shadow_bias.y > 0.0f)\n    {\n        _2393 = _2094_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2393 = 1.5f * _2094_fa_shadow_info[ci].x;\n    }\n    float4 _2418 = mul(float4(world + (n * (_2393 * _2381)), 1.0f), _2094_fa_shadow_mat[ci]);\n    float _2425 = _2418.x;\n    bool _2428 = _2425 < _2094_fa_shadow_rect[ci].x;\n    bool _2437;\n    if (!_2428)\n    {\n        _2437 = _2425 > _2094_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2437 = _2428;\n    }\n    bool _2446;\n    if (!_2437)\n    {\n        _2446 = _2418.y < _2094_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2446 = _2437;\n    }\n    bool _2455;\n    if (!_2446)\n    {\n        _2455 = _2418.y > _2094_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2455 = _2446;\n    }\n    bool _2462;\n    if (!_2455)\n    {\n        _2462 = _2418.z > 1.0f;\n    }\n    else\n    {\n        _2462 = _2455;\n    }\n    if (_2462)\n    {\n        return -1.0f;\n    }\n    float _2470;\n    if (_2094_fa_shadow_bias.x > 0.0f)\n    {\n        _2470 = _2094_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2470 = 1.5f * _2094_fa_shadow_info[ci].x;\n    }\n    float2 param = _2418.xy;\n    float4 param_1 = _2094_fa_shadow_rect[ci];\n    float param_2 = _2418.z - ((_2470 * (1.0f + (0.5f * _2388))) / _2370);\n    float param_3 = _2094_fa_shadow_info[ci].x;\n    float param_4 = _2370;\n    float param_5 = _2370 * 0.25f;\n    float param_6 = ((_2094_fa_shadow_info[ci].x * min(_2388, 3.0f)) * 0.5f) / _2370;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2094_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2094_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_437_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2848 = int(_2094_fa_shadow_cfg.x + 0.5f);\n    if (_2848 < 1)\n    {\n        return 1.0f;\n    }\n    float _2863 = dot(world - _2094_fa_shadow_eye.xyz, _2094_fa_shadow_fwd.xyz);\n    int param = _2848 - 1;\n    if (_2863 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2875 = _2848 > 1;\n    bool _2882;\n    if (_2875)\n    {\n        _2882 = _2863 > _2094_fa_shadow_split.x;\n    }\n    else\n    {\n        _2882 = _2875;\n    }\n    if (_2882)\n    {\n        ci = 1;\n    }\n    bool _2886 = _2848 > 2;\n    bool _2893;\n    if (_2886)\n    {\n        _2893 = _2863 > _2094_fa_shadow_split.y;\n    }\n    else\n    {\n        _2893 = _2886;\n    }\n    if (_2893)\n    {\n        ci = 2;\n    }\n    bool _2897 = _2848 > 3;\n    bool _2904;\n    if (_2897)\n    {\n        _2904 = _2863 > _2094_fa_shadow_split.z;\n    }\n    else\n    {\n        _2904 = _2897;\n    }\n    if (_2904)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2848)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2930 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2930;\n        if (_2930 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2094_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2955;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2955 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2955 = _2094_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2974 = _2094_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2955, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2985 = clamp((_2863 - (fa_shadow_split_at(param_7) - _2974)) / _2974, 0.0f, 1.0f);\n        if (_2985 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2848)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _3006 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3006;\n                if (_3006 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2985);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2528 = _437_fa_pbr.z < 0.5f;\n    bool _2535;\n    if (!_2528)\n    {\n        _2535 = _2094_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2535 = _2528;\n    }\n    if (_2535)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2094_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2548 = fa_light_texel(param);\n    float _2549 = _2548.x;\n    if (_2549 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2558 = int(_2549 + 0.5f);\n    int param_1 = _2558;\n    float4 _2562 = fa_light_texel(param_1);\n    int param_2 = _2558 + 1;\n    float4 _2567 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2570 = _2562.y;\n    if (_2570 > 0.0f)\n    {\n        float _2587 = 1.0f - smoothstep(0.75f * _2570, _2570, length(world - _2094_fa_shadow_eye.xyz));\n        fade = _2587;\n        if (_2587 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2562.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2611 = (_2558 + 2) + (face * 6);\n    int param_4 = _2611;\n    int param_5 = _2611 + 1;\n    int param_6 = _2611 + 3;\n    float4 _2625 = fa_light_texel(param_6);\n    int param_7 = _2611 + 4;\n    float4 _2630 = fa_light_texel(param_7);\n    int param_8 = _2611 + 5;\n    float4 _2635 = fa_light_texel(param_8);\n    float _2647 = _2635.x * max(dot(_2625, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2652 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2675 = clamp(dot(n, _2625.xyz), -1.0f, 1.0f);\n    float _2694 = min(sqrt(1.0f - (_2675 * _2675)) / max(abs(dot(n, world - lpos)) / max(dot(_2625, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2697 = _2567.y;\n    float _2699;\n    if (_2697 > 0.0f)\n    {\n        _2699 = _2697;\n    }\n    else\n    {\n        _2699 = 1.5f * _2647;\n    }\n    float4 _2719 = float4(world + (n * (_2699 * sqrt(1.0f - (_2652 * _2652)))), 1.0f);\n    float _2723 = dot(_2625, _2719);\n    float _2726 = _2635.y;\n    if (_2723 < _2726)\n    {\n        return 1.0f;\n    }\n    float2 _2741 = float2(dot(fa_light_texel(param_4), _2719), dot(fa_light_texel(param_5), _2719)) / _2723.xx;\n    float _2743 = _2741.x;\n    bool _2746 = _2743 < _2630.x;\n    bool _2755;\n    if (!_2746)\n    {\n        _2755 = _2743 > _2630.z;\n    }\n    else\n    {\n        _2755 = _2746;\n    }\n    bool _2764;\n    if (!_2755)\n    {\n        _2764 = _2741.y < _2630.y;\n    }\n    else\n    {\n        _2764 = _2755;\n    }\n    bool _2773;\n    if (!_2764)\n    {\n        _2773 = _2741.y > _2630.w;\n    }\n    else\n    {\n        _2773 = _2764;\n    }\n    if (_2773)\n    {\n        return 1.0f;\n    }\n    float _2779 = _2567.x;\n    float _2781;\n    if (_2779 > 0.0f)\n    {\n        _2781 = _2779;\n    }\n    else\n    {\n        _2781 = 1.5f * _2647;\n    }\n    float2 param_9 = _2741;\n    float4 param_10 = _2630;\n    float param_11 = _2723 - (_2781 * (1.0f + (0.5f * _2694)));\n    float param_12 = _2647;\n    float param_13 = 1.0f;\n    float param_14 = _2635.z * 0.25f;\n    float param_15 = (_2647 * min(_2694, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2726, _2635.z);\n    int param_17 = int(_2562.z + 0.5f);\n    float param_18 = _2562.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _4047 = _437_fa_ct_a.x < 0.5f;\n    bool _4054;\n    if (!_4047)\n    {\n        _4054 = _2094_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _4054 = _4047;\n    }\n    if (_4054)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2094_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _4067 = fa_light_texel(param);\n    float _4068 = _4067.y;\n    float len = _4068;\n    if (_4068 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4080 = length(world - _437_fa_camera_pos.xyz);\n    float _4090 = 1.0f - smoothstep(0.5f * _437_fa_ct_b.x, _437_fa_ct_b.x, _4080);\n    if (_4090 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4096 = len;\n    float _4099 = min(_4096, 0.89999997615814208984375f * dist);\n    len = _4099;\n    float _4104 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _4080);\n    float _4109 = _4104 + (0.5f * _4099);\n    float3 _4115 = world + (gn * _4104);\n    float _4117 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _4181;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4132 = (float(k) + _4117) * 0.083333335816860198974609375f;\n        float3 _4140 = _4115 + (l * (_4132 * len));\n        float4 _4146 = float4(_4140, 1.0f);\n        float _4152 = dot(_437_fa_ct_vpw, _4146);\n        if (_4152 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _4172 = float2(dot(_437_fa_ct_vpx, _4146), dot(_437_fa_ct_vpy, _4146)) / _4152.xx;\n        float _4176 = _4172.x * 0.5f;\n        float _4177 = _4176 + 0.5f;\n        if (_437_fa_ct_a.y > 0.5f)\n        {\n            _4181 = (_4172.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _4181 = 0.5f - (_4172.y * 0.5f);\n        }\n        bool _4197 = _4177 < 0.0f;\n        bool _4204;\n        if (!_4197)\n        {\n            _4204 = _4177 >= 1.0f;\n        }\n        else\n        {\n            _4204 = _4197;\n        }\n        bool _4211;\n        if (!_4204)\n        {\n            _4211 = _4181 < 0.0f;\n        }\n        else\n        {\n            _4211 = _4204;\n        }\n        bool _4218;\n        if (!_4211)\n        {\n            _4218 = _4181 >= 1.0f;\n        }\n        else\n        {\n            _4218 = _4211;\n        }\n        if (_4218)\n        {\n            break;\n        }\n        float4 _4237 = fa_screen_tex.Load(int3(int2(float2(_4177, _4181) * _437_fa_ct_a.zw), 0));\n        if (_4237.w < 0.5f)\n        {\n            continue;\n        }\n        float _4256 = (dot(_437_fa_ct_fwd.xyz, _4140) + _437_fa_ct_fwd.w) - _4237.x;\n        if ((_4256 > _4104) && (_4256 < _4109))\n        {\n            occ = max(occ, (1.0f - (_4132 * _4132)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_4177, 0.5f - _4176), min(_4181, 1.0f - _4181))));\n        }\n    }\n    return 1.0f - (occ * _4090);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _4332 = fa_lm.z > 0.5f;\n    bool _4338;\n    if (_4332)\n    {\n        int param = li;\n        _4338 = fa_light_baked(param);\n    }\n    else\n    {\n        _4338 = _4332;\n    }\n    if (_4338)\n    {\n        int param_1 = li;\n        LightSample _5496 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _5496;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4362 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _5498 = _4362.color;\n    float _5500 = _4362.shadow;\n    bool _4365 = _4362.type == 0;\n    if (_4365 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4362.direction;\n        float _4376 = fa_shadow_factor(param_5, param_6);\n        _5500 = _4376;\n        _5498 *= _4376;\n    }\n    else\n    {\n        bool _4387 = _4362.type != 0;\n        bool _4393;\n        if (_4387)\n        {\n            _4393 = _4362.attenuation > 0.0f;\n        }\n        else\n        {\n            _4393 = _4387;\n        }\n        if (_4393)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _4362.direction;\n            float _4412 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _5500 = _4412;\n            _5498 *= _4412;\n        }\n    }\n    bool _4422 = _437_fa_ct_a.x > 0.5f;\n    bool _4428;\n    if (_4422)\n    {\n        _4428 = _4362.attenuation > 0.0f;\n    }\n    else\n    {\n        _4428 = _4422;\n    }\n    if (_4428)\n    {\n        float _4435;\n        if (_4365)\n        {\n            _4435 = 1000000000.0f;\n        }\n        else\n        {\n            _4435 = _4362._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _4362.direction;\n        float param_18 = _4435;\n        float _4453 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _5500 *= _4453;\n        _5498 *= _4453;\n    }\n    LightSample _5515 = { _4362.direction, _5498, _4362.attenuation, _5500, _4362._distance, _4362.type };\n    return _5515;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2094_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3030 = int(_2094_fa_shadow_cfg.x + 0.5f);\n    float _3040 = dot(world - _2094_fa_shadow_eye.xyz, _2094_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3045 = _3030 > 0;\n    bool _3054;\n    if (_3045)\n    {\n        int param = _3030 - 1;\n        _3054 = _3040 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3054 = _3045;\n    }\n    if (_3054)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3060 = _3030 > 1;\n        bool _3067;\n        if (_3060)\n        {\n            _3067 = _3040 > _2094_fa_shadow_split.x;\n        }\n        else\n        {\n            _3067 = _3060;\n        }\n        if (_3067)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3073 = _3030 > 2;\n        bool _3080;\n        if (_3073)\n        {\n            _3080 = _3040 > _2094_fa_shadow_split.y;\n        }\n        else\n        {\n            _3080 = _3073;\n        }\n        if (_3080)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3086 = _3030 > 3;\n        bool _3093;\n        if (_3086)\n        {\n            _3093 = _3040 > _2094_fa_shadow_split.z;\n        }\n        else\n        {\n            _3093 = _3086;\n        }\n        if (_3093)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _5207 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5207 = -_5207;\n    }\n    float3 _4842 = normalize(_437_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _5220 = { fa_world_pos, _5207, fa_world_tangent, fa_uv, fa_vertex_color, _4842, gl_FrontFacing };\n    SurfaceInput param_1 = _5220;\n    Surface _4850 = fa_standard_surface(param_1);\n    float3 _5246 = _4850.albedo;\n    float _5247 = _4850.alpha;\n    float3 _5248 = _4850.normal;\n    float _5249 = _4850.metallic;\n    float _5250 = _4850.roughness;\n    float _5251 = _4850.occlusion;\n    float3 _5252 = _4850.emission;\n    float _5253 = _4850.clearcoat;\n    float _5254 = _4850.clearcoat_roughness;\n    float3 _5255 = _4850.sheen_color;\n    float _5256 = _4850.sheen_roughness;\n    float _5257 = _4850.anisotropy;\n    float _5258 = _4850.anisotropy_rotation;\n    float _5259 = _4850.specular;\n    float _5260 = _4850.ior;\n    float3 _5261 = _4850.specular_color;\n    SurfaceInput _5228 = { fa_world_pos, _5207, fa_world_tangent, fa_uv, fa_vertex_color, _4842, gl_FrontFacing };\n    SurfaceInput param_2 = _5228;\n    Surface param_3 = _4850;\n    surface(param_2, param_3);\n    _5246 = param_3.albedo;\n    _5247 = param_3.alpha;\n    _5248 = param_3.normal;\n    _5249 = param_3.metallic;\n    _5250 = param_3.roughness;\n    _5251 = param_3.occlusion;\n    _5252 = param_3.emission;\n    _5253 = param_3.clearcoat;\n    _5254 = param_3.clearcoat_roughness;\n    _5255 = param_3.sheen_color;\n    _5256 = param_3.sheen_roughness;\n    _5257 = param_3.anisotropy;\n    _5258 = param_3.anisotropy_rotation;\n    _5259 = param_3.specular;\n    _5260 = param_3.ior;\n    _5261 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _5207;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5246 = param_6;\n    _5248 = param_7;\n    float3 result;\n    if (_437_fa_emissive.w > 0.5f)\n    {\n        result = _5246;\n    }\n    else\n    {\n        float3 _4888 = _5248;\n        float3 _4889 = normalize(_4888);\n        _5248 = _4889;\n        float3 param_8 = _4889;\n        SurfaceInput _5236 = { fa_world_pos, _5207, fa_world_tangent, fa_uv, fa_vertex_color, _4842, gl_FrontFacing };\n        SurfaceInput param_9 = _5236;\n        Surface _5327 = { _5246, _5247, _5248, _5249, _5250, _5251, _5252, _5253, _5254, _5255, _5256, _5257, _5258, _5259, _5260, _5261 };\n        Surface param_10 = _5327;\n        float3 param_11 = fa_indirect_diffuse(param_8);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _4908 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4908; ln++)\n        {\n            int param_12 = ln;\n            int _4921 = fa_cl_light(param_12);\n            bool _4924 = fa_lm.z > 0.5f;\n            bool _4930;\n            if (_4924)\n            {\n                int param_13 = _4921;\n                _4930 = fa_light_baked(param_13);\n            }\n            else\n            {\n                _4930 = _4924;\n            }\n            if (_4930)\n            {\n                continue;\n            }\n            int param_14 = _4921;\n            float3 param_15 = fa_world_pos;\n            float3 param_16 = _5207;\n            LightSample _4942 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput _5244 = { fa_world_pos, _5207, fa_world_tangent, fa_uv, fa_vertex_color, _4842, gl_FrontFacing };\n            SurfaceInput param_17 = _5244;\n            Surface _5344 = { _5246, _5247, _5248, _5249, _5250, _5251, _5252, _5253, _5254, _5255, _5256, _5257, _5258, _5259, _5260, _5261 };\n            Surface param_18 = _5344;\n            LightSample param_19 = _4942;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _4957 = result;\n    float3 _4958 = _4957 + _5252;\n    result = _4958;\n    float3 param_20 = _4958;\n    float3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _4967 = _437_fa_fog.w > 0.0f;\n    bool _4974;\n    if (!_4967)\n    {\n        _4974 = _437_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _4974 = _4967;\n    }\n    if (_4974)\n    {\n        float3 _4983 = fa_world_pos - _437_fa_camera_pos.xyz;\n        float _4989 = dot(_4983, _437_fa_fog_c.xyz);\n        bool _4993 = _437_fa_fog_c.w > 0.5f;\n        float _4994;\n        if (_4993)\n        {\n            _4994 = _4989;\n        }\n        else\n        {\n            _4994 = length(_4983);\n        }\n        float _5006 = _4994 - _437_fa_fog_b.x;\n        if (_5006 > 0.0f)\n        {\n            float _5015 = _437_fa_fog.w * _5006;\n            float tau = _5015 * _5015;\n            if (_437_fa_fog_b.y > 0.0f)\n            {\n                float _5031;\n                if (_4993)\n                {\n                    _5031 = fa_world_pos.y - (_437_fa_fog_c.y * _4989);\n                }\n                else\n                {\n                    _5031 = _437_fa_camera_pos.y;\n                }\n                float _5052 = lerp(_5031, fa_world_pos.y, clamp(_437_fa_fog_b.x / _4994, 0.0f, 1.0f));\n                float _5056 = fa_world_pos.y - _5052;\n                float _5061 = _5052 - _437_fa_fog_b.z;\n                float _5066 = fa_world_pos.y - _437_fa_fog_b.z;\n                bool _5069 = _5061 <= 0.0f;\n                bool _5070 = !_5069;\n                bool _5076;\n                if (_5070)\n                {\n                    _5076 = _437_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5076 = _5069;\n                }\n                float _5077;\n                if (_5076)\n                {\n                    _5077 = _437_fa_fog_b.y;\n                }\n                else\n                {\n                    _5077 = _437_fa_fog_b.y * exp(-min(_437_fa_fog_b.w * _5061, 80.0f));\n                }\n                bool _5104;\n                if (_5070)\n                {\n                    _5104 = _437_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5104 = _5069;\n                }\n                float _5105;\n                if (_5104)\n                {\n                    _5105 = _437_fa_fog_b.y * _5061;\n                }\n                else\n                {\n                    _5105 = (_437_fa_fog_b.y * (1.0f - exp(-min(_437_fa_fog_b.w * _5061, 80.0f)))) / _437_fa_fog_b.w;\n                }\n                bool _5130 = _5066 <= 0.0f;\n                bool _5137;\n                if (!_5130)\n                {\n                    _5137 = _437_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5137 = _5130;\n                }\n                float _5138;\n                if (_5137)\n                {\n                    _5138 = _437_fa_fog_b.y * _5066;\n                }\n                else\n                {\n                    _5138 = (_437_fa_fog_b.y * (1.0f - exp(-min(_437_fa_fog_b.w * _5066, 80.0f)))) / _437_fa_fog_b.w;\n                }\n                float _5165;\n                if (abs(_5056) < 0.001000000047497451305389404296875f)\n                {\n                    _5165 = _5077;\n                }\n                else\n                {\n                    _5165 = (_5138 - _5105) / _5056;\n                }\n                tau += (_5006 * max(_5165, 0.0f));\n            }\n            result = lerp(result, _437_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _5247);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_437",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2094",
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
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _3524[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _437_fa_camera_pos : packoffset(c0);\n    float4 _437_fa_ambient : packoffset(c1);\n    float4 _437_fa_base_color : packoffset(c2);\n    float4 _437_fa_emissive : packoffset(c3);\n    float4 _437_fa_model_emissive : packoffset(c4);\n    float4 _437_fa_pbr : packoffset(c5);\n    float4 _437_fa_maps : packoffset(c6);\n    float4 _437_fa_fog : packoffset(c7);\n    float4 _437_fa_fog_b : packoffset(c8);\n    float4 _437_fa_fog_c : packoffset(c9);\n    float4 _437_fa_counts : packoffset(c10);\n    float4 _437_fa_env_sky : packoffset(c11);\n    float4 _437_fa_env_horizon : packoffset(c12);\n    float4 _437_fa_time : packoffset(c13);\n    float4 _437_fa_cl_vpx : packoffset(c14);\n    float4 _437_fa_cl_vpy : packoffset(c15);\n    float4 _437_fa_cl_vpw : packoffset(c16);\n    float4 _437_fa_cl_fwd : packoffset(c17);\n    float4 _437_fa_cl_grid : packoffset(c18);\n    float4 _437_fa_cl_info : packoffset(c19);\n    float4 _437_fa_layers_a : packoffset(c20);\n    float4 _437_fa_layers_b : packoffset(c21);\n    float4 _437_fa_layers_c : packoffset(c22);\n    float4 _437_fa_layers_d : packoffset(c23);\n    float4 _437_fa_ct_a : packoffset(c24);\n    float4 _437_fa_ct_b : packoffset(c25);\n    float4 _437_fa_ct_vpx : packoffset(c26);\n    float4 _437_fa_ct_vpy : packoffset(c27);\n    float4 _437_fa_ct_vpw : packoffset(c28);\n    float4 _437_fa_ct_fwd : packoffset(c29);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2094_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2094_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2094_fa_shadow_info[4] : packoffset(c20);\n    float4 _2094_fa_shadow_split : packoffset(c24);\n    float4 _2094_fa_shadow_cfg : packoffset(c25);\n    float4 _2094_fa_shadow_bias : packoffset(c26);\n    float4 _2094_fa_shadow_eye : packoffset(c27);\n    float4 _2094_fa_shadow_fwd : packoffset(c28);\n    float4 _2094_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_screen_tex : register(t11);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1365 = _437_fa_cl_info.x < 0.0f;\n    bool _1372;\n    if (!_1365)\n    {\n        _1372 = _437_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1372 = _1365;\n    }\n    bool _1380;\n    if (!_1372)\n    {\n        _1380 = _437_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1380 = _1372;\n    }\n    bool _1387;\n    if (!_1380)\n    {\n        _1387 = _437_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1387 = _1380;\n    }\n    bool _1394;\n    if (!_1387)\n    {\n        _1394 = _437_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1394 = _1387;\n    }\n    if (_1394)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1404 = float4(world_pos, 1.0f);\n    float _1410 = dot(_437_fa_cl_vpw, _1404);\n    if (!(_1410 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1432 = float2(dot(_437_fa_cl_vpx, _1404), dot(_437_fa_cl_vpy, _1404)) / _1410.xx;\n    int _1436 = int(_437_fa_cl_grid.x);\n    int _1440 = int(_437_fa_cl_grid.y);\n    int param = (int(_437_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_437_fa_cl_fwd.xyz, world_pos) + _437_fa_cl_fwd.w, _437_fa_cl_grid.w) / _437_fa_cl_grid.w) * _437_fa_cl_grid.z)), 0, int(_437_fa_cl_info.y) - 1) * _1440) + clamp(int(floor(((_1432.y * 0.5f) + 0.5f) * _437_fa_cl_grid.y)), 0, _1440 - 1)) * _1436)) + clamp(int(floor(((_1432.x * 0.5f) + 0.5f) * _437_fa_cl_grid.x)), 0, _1436 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1516 = fa_cluster_texel(param);\n    return int2(int(_1516.x), int(_1516.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_437_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4305 = fa_cluster_lookup(param);\n    fa_cl_slot = _4305.x;\n    fa_cl_local = _4305.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _4512 = fa_linear_to_srgb(param);\n        c = _4512;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _4520 = fa_srgb_to_linear(param_1);\n            c = _4520;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _320;\n    if (i.front_facing)\n    {\n        _320 = i.world_normal;\n    }\n    else\n    {\n        _320 = -i.world_normal;\n    }\n    float3 _344 = normalize(i.world_tangent.xyz - (_320 * dot(_320, i.world_tangent.xyz)));\n    float3 _371 = normalize(((_344 * m.x) + ((cross(_320, _344) * i.world_tangent.w) * m.y)) + (_320 * m.z));\n    float3 _374;\n    if (i.front_facing)\n    {\n        _374 = _371;\n    }\n    else\n    {\n        _374 = -_371;\n    }\n    return _374;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _437_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _4551 = fa_tex_fix(param_2, param_3);\n    float4 _5679 = base_t;\n    _5679.x = _4551.x;\n    _5679.y = _4551.y;\n    _5679.z = _4551.z;\n    base_t = _5679;\n    float4 _4565 = (_5679 * _437_fa_base_color) * i.vertex_color;\n    float3 _5518 = i.world_normal;\n    if (_437_fa_maps.z > 0.5f)\n    {\n        float param_4 = _437_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4597 = fa_tex_fix(param_6, param_7);\n        float3 _4600 = (_4597 * 2.0f) - 1.0f.xxx;\n        float2 _4605 = _4600.xy * _437_fa_maps.x;\n        float3 _5687 = _4600;\n        _5687.x = _4605.x;\n        _5687.y = _4605.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5687;\n        _5518 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _437_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4633 = fa_tex_fix(param_12, param_13);\n    float4 _5690 = mrt;\n    _5690.x = _4633.x;\n    _5690.y = _4633.y;\n    _5690.z = _4633.z;\n    mrt = _5690;\n    float4 _4661 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _437_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _4661.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4672 = fa_tex_fix(param_16, param_17);\n    float param_18 = _437_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4702 = fa_tex_fix(param_20, param_21);\n    float _5523 = _437_fa_layers_a.x;\n    float _5524 = _437_fa_layers_a.y;\n    float _5527 = _437_fa_layers_a.z;\n    float _5526 = _437_fa_layers_b.w;\n    float _5529 = _437_fa_layers_c.x;\n    if (_437_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_437_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _5523 *= _4672.y;\n            _5524 *= _4672.z;\n            _5526 *= _4661.w;\n        }\n        if (_437_fa_layers_c.z > 1.5f)\n        {\n            _5527 *= mrt.x;\n            _5529 *= mrt.w;\n        }\n    }\n    Surface _5548 = { _4565.xyz, _4565.w, _5518, clamp(_437_fa_pbr.x * _4633.z, 0.0f, 1.0f), clamp(_437_fa_pbr.y * _4633.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_437_fa_maps.y * (_4672.x - 1.0f)), _437_fa_emissive.xyz + (_437_fa_model_emissive.xyz * _4702), _5523, _5524, _437_fa_layers_b.xyz, _5526, _5527, _437_fa_layers_a.w, _5529, _437_fa_layers_c.y, _437_fa_layers_d.xyz };\n    return _5548;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1596 = rect.zw - rect.xy;\n    float2 _1600 = _1596 * atlas;\n    float2 _1604 = ddx * _1600;\n    float2 _1608 = ddy * _1600;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1596), clamp(0.5f * log2(max(max(dot(_1604, _1604), dot(_1608, _1608)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1641 = _437_fa_counts.y < 0.5f;\n    bool _1648;\n    if (!_1641)\n    {\n        _1648 = _437_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1648 = _1641;\n    }\n    if (_1648)\n    {\n        return;\n    }\n    float3 _1654 = ddx(world_pos);\n    float3 _1657 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1661 = fa_cluster_texel(param);\n    int _1665 = int(_1661.w);\n    if (_1665 < 1)\n    {\n        return;\n    }\n    int _1675 = int(_437_fa_counts.y + 0.5f);\n    int param_1 = _1675;\n    float4 _1679 = fa_light_texel(param_1);\n    float2 _1682 = _1679.yz;\n    int _1686 = int(_1679.w);\n    int param_2 = _1675 + 1;\n    float4 _1691 = fa_light_texel(param_2);\n    float _1692 = _1691.x;\n    int _1698 = int(_437_fa_counts.w + 0.5f) - 1;\n    int _1702 = int(_1661.z);\n    float3 _1967;\n    for (int k = 0; k < _1665; k++)\n    {\n        int _1715 = _1702 + k;\n        int param_3 = _1686 + (_1715 >> 2);\n        int _1732 = (_1675 + 2) + (int(fa_light_texel(param_3)[_1715 & 3]) * 7);\n        int param_4 = _1732 + 6;\n        float4 _1737 = fa_light_texel(param_4);\n        if (((int(_1737.w + 0.5f) >> _1698) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1732;\n        float4 _1752 = fa_light_texel(param_5);\n        int param_6 = _1732 + 1;\n        float4 _1757 = fa_light_texel(param_6);\n        int param_7 = _1732 + 2;\n        float4 _1762 = fa_light_texel(param_7);\n        float3 _1765 = _1752.xyz;\n        float _1770 = dot(_1765, world_pos) + _1752.w;\n        float3 _1772 = _1757.xyz;\n        float _1777 = dot(_1772, world_pos) + _1757.w;\n        float3 _1779 = _1762.xyz;\n        float _1784 = dot(_1779, world_pos) + _1762.w;\n        bool _1789 = abs(_1770) > 0.5f;\n        bool _1797;\n        if (!_1789)\n        {\n            _1797 = abs(_1777) > 0.5f;\n        }\n        else\n        {\n            _1797 = _1789;\n        }\n        bool _1805;\n        if (!_1797)\n        {\n            _1805 = abs(_1784) > 0.5f;\n        }\n        else\n        {\n            _1805 = _1797;\n        }\n        if (_1805)\n        {\n            continue;\n        }\n        float _1820 = clamp(dot(geo_normal, normalize(_1779)) * _1737.z, 0.0f, 1.0f);\n        if (_1820 <= 0.0f)\n        {\n            continue;\n        }\n        float _1840 = (clamp((0.5f - abs(_1784)) * 10.0f, 0.0f, 1.0f) * _1820) * _1737.x;\n        float2 _1848 = float2(_1770 + 0.5f, 0.5f - _1777);\n        float2 _1858 = float2(dot(_1765, _1654), dot(_1772, _1654));\n        float2 _1868 = float2(dot(_1765, _1657), dot(_1772, _1657));\n        int param_8 = _1732 + 5;\n        float4 _1873 = fa_light_texel(param_8);\n        int param_9 = _1732 + 3;\n        float4 _1878 = fa_light_texel(param_9);\n        int param_10 = _1732 + 4;\n        float4 _1883 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1873.xyz;\n        bool _1893 = _1878.z > _1878.x;\n        if (_1893)\n        {\n            float4 param_11 = _1878;\n            float2 param_12 = _1848;\n            float2 param_13 = _1682;\n            float2 param_14 = _1858;\n            float2 param_15 = _1868;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1692 > 0.5f) && (_1692 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1919 = fa_dc_to_linear(param_16);\n                float4 _5598 = tx;\n                _5598.x = _1919.x;\n                _5598.y = _1919.y;\n                _5598.z = _1919.z;\n                tx = _5598;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1840 * tex_a) * _1873.w, 0.0f, 1.0f).xxx);\n        if (_1883.z > _1883.x)\n        {\n            float4 param_17 = _1883;\n            float2 param_18 = _1848;\n            float2 param_19 = _1682;\n            float2 param_20 = _1858;\n            float2 param_21 = _1868;\n            float4 _1963 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1692 > 1.5f)\n            {\n                float3 param_22 = _1963.xyz;\n                float3 _1973 = fa_dc_to_srgb(param_22);\n                _1967 = _1973;\n            }\n            else\n            {\n                _1967 = _1963.xyz;\n            }\n            float3 _1982 = (_1967 * 2.0f) - 1.0f.xxx;\n            float2 _1987 = _1982.xy * _1737.y;\n            float3 _2009 = (normalize(_1765) * _1987.x) + (normalize(_1772) * _1987.y);\n            float3 _2012 = normalize(normal);\n            normal = normalize(lerp(_2012, normalize((_2012 * max(_1982.z, 0.0500000007450580596923828125f)) + (_2009 - (_2012 * dot(_2012, _2009)))), clamp(_1840 * (_1893 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_sky_sh_coef(int k)\n{\n    float3 v = fa_env_tex.SampleLevel(fa_env_smp, float3(1.0f, 1.0f - (float((2 * (k >> 2)) + 1) * 0.25f), 1.0f - (float((2 * (k & 3)) + 1) * 0.25f)), 5.0f).xyz;\n    if (_437_fa_env_sky.w > 1.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3207 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3207;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_437_fa_env_sky.w > 0.5f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _437_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3450 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3457 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3460 = int(_3450);\n    int _3463 = int(_3457);\n    float _3473 = _3457 - float(_3463);\n    int _3528 = (_3460 * 9) + _3463;\n    int _3548 = ((_3460 + 1) * 9) + _3463;\n    return lerp(lerp(_3524[_3528], _3524[_3528 + 1], _3473), lerp(_3524[_3548], _3524[_3548 + 1], _3473), _3450 - float(_3460));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _5377 = false;\n    float _5378 = 1.0f;\n    float _5379 = 1.0f;\n    float _5380 = 1.0f;\n    float _5381 = 0.0f;\n    float _5382 = 0.0f;\n    float _5383 = 0.0f;\n    float _5384 = 0.0f;\n    float _5386 = 1.0f;\n    bool _5387 = false;\n    float3 _5388 = 0.0f.xxx;\n    float _5389 = 1.0f;\n    float _5390 = 1.0f;\n    float _5391 = 1.0f;\n    float _5392 = 0.0f;\n    float _5393 = 0.0f;\n    float3 _5394 = float3(1.0f, 0.0f, 0.0f);\n    float3 _5395 = float3(0.0f, 0.0f, 1.0f);\n    float _5396 = 1.0f;\n    float _5397 = 1.0f;\n    float _3599 = clamp(s.specular, 0.0f, 1.0f);\n    float _3603 = clamp(s.ior, 1.0f, 3.0f);\n    bool _3608 = (_3599 != 1.0f) || (_3603 != 1.5f);\n    bool _3617;\n    if (!_3608)\n    {\n        _3617 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _3617 = _3608;\n    }\n    if (_3617)\n    {\n        float _3625 = (_3603 - 1.0f) / (_3603 + 1.0f);\n        f0 = lerp(min((_3625 * _3625).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _3599, s.albedo, metallic.xxx);\n        _5378 = lerp(_3599, 1.0f, metallic);\n        _5377 = true;\n    }\n    float _3652 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_3652 > 0.0f)\n    {\n        float _3660 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _5381 = _3652;\n        _5382 = _3660;\n        float _3667 = _3660 * _3660;\n        _5383 = _3667;\n        _5384 = _3667 * _3667;\n        float _3679 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _5386 = _3679;\n        _5379 = 1.0f - (_3652 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _3679, 0.0f, 1.0f), 5.0f))));\n        _5377 = true;\n    }\n    float3 _3698 = max(s.sheen_color, 0.0f.xxx);\n    float _3707 = max(_3698.x, max(_3698.y, _3698.z));\n    if (_3707 > 0.0f)\n    {\n        float _3715 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _5387 = true;\n        _5388 = _3698;\n        _5389 = _3715;\n        _5390 = _3715 * _3715;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _3715;\n        float _3732 = fa_sheen_albedo(param, param_1);\n        _5392 = _3732;\n        _5391 = 1.0f - min(_3707 * _3732, 1.0f);\n        _5377 = true;\n    }\n    _5380 = _5379 * _5391;\n    float _3751 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_3751 != 0.0f)\n    {\n        float3 _3766 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _3766;\n        if (dot(_3766, _3766) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _3778 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_3778.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _3778.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _3778.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _3782 = t;\n        float3 _3783 = normalize(_3782);\n        t = _3783;\n        float3 _3808 = normalize((_3783 * cos(s.anisotropy_rotation)) + ((cross(n, _3783) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _5394 = _3808;\n        _5395 = cross(n, _3808);\n        float _3818 = roughness * roughness;\n        float _3824 = lerp(_3818, 1.0f, _3751 * _3751);\n        bool _3826 = _3751 > 0.0f;\n        _5396 = _3826 ? _3824 : _3818;\n        _5397 = _3826 ? _3818 : _3824;\n        _5393 = _3751;\n        _5377 = true;\n    }\n    FaLayers _5419 = { _5377, _5378, _5379, _5380, _5381, _5382, _5383, _5384, i.world_normal, _5386, _5387, _5388, _5389, _5390, _5391, _5392, _5393, _5394, _5395, _5396, _5397 };\n    return _5419;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3382 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3385 = _3382.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3385 * _3385, exp2((-9.27999973297119140625f) * ndv)) * _3385) + _3382.y)) + _3382.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_437_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _437_fa_env_horizon.w).xyz;\n    }\n    float _3236 = rough * rough;\n    float _3266 = 0.60000002384185791015625f * _3236;\n    return lerp(lerp(_437_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_437_fa_env_horizon.xyz, _437_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3236)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3266, 0.0500000007450580596923828125f + _3266, d.y).xxx), ((_437_fa_env_sky.xyz + _437_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3236 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _3859;\n        if (L.aniso >= 0.0f)\n        {\n            _3859 = L.b;\n        }\n        else\n        {\n            _3859 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_3859, v), _3859), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3892 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _3892.x) + (L.f90.xxx * _3892.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3947 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _3947.x) + _3947.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3424 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3424.x) + _3424.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _3976 = clamp(s.metallic, 0.0f, 1.0f);\n    float _3980 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _3987 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _3976.xxx);\n    float3 f0 = _3987;\n    float3 _3991 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _3991;\n    float3 param_3 = i.view_dir;\n    float param_4 = _3976;\n    float param_5 = _3980;\n    float3 param_6 = _3987;\n    FaLayers _4008 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4008.on)\n    {\n        FaLayers param_7 = _4008;\n        float3 param_8 = _3991;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _3980;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _3991;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _3980;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_437_fa_cl_info.x) + int(_437_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_437_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _496_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _496_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _615 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _628 = (c - (ru * hx)) - p;\n        float3 _634 = ru * (2.0f * hx);\n        float _640 = max(dot(_634, _634), 9.9999999392252902907785028219223e-09f);\n        float _644 = dot(_628, _634);\n        float t = clamp((-_644) / _640, 0.0f, 1.0f);\n        if (_615)\n        {\n            float _659 = dot(r, _634);\n            float _665 = _640 - (_659 * _659);\n            if (abs(_665) > (9.9999997473787516355514526367188e-06f * _640))\n            {\n                t = clamp(((dot(r, _628) * _659) - _644) / _665, 0.0f, 1.0f);\n            }\n        }\n        return (p + _628) + (_634 * t);\n    }\n    float3 q = p;\n    float _697 = dot(r, axis);\n    bool _705;\n    if (_615)\n    {\n        _705 = abs(_697) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _705 = _615;\n    }\n    if (_705)\n    {\n        float _715 = dot(c - p, axis) / _697;\n        if (_715 > 0.0f)\n        {\n            q = p + (r * _715);\n        }\n    }\n    float3 _728 = q - c;\n    float2 xy = float2(dot(_728, ru), dot(_728, uu));\n    if (shape > 0.5f)\n    {\n        float _743 = length(xy);\n        if (_743 > hx)\n        {\n            xy *= (hx / _743);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _386 = abs(d);\n    float _388 = _386.x;\n    float _390 = _386.y;\n    bool _391 = _388 >= _390;\n    bool _399;\n    if (_391)\n    {\n        _399 = _388 >= _386.z;\n    }\n    else\n    {\n        _399 = _391;\n    }\n    int _400;\n    if (_399)\n    {\n        _400 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _415;\n        if (_390 >= _386.z)\n        {\n            _415 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _415 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _400 = _415;\n    }\n    return _400;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _535 = dot(d, right);\n    float _539 = dot(d, up);\n    float _550;\n    if (((_535 * _535) + (_539 * _539)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _550 = atan2(_539, _535) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _550 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_550 - floor(_550)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _781 = fa_light_base(param);\n    bool _785 = _437_fa_ambient.w > 4.5f;\n    int param_1 = _781;\n    float4 _789 = fa_light_texel(param_1);\n    int param_2 = _781 + 1;\n    float4 _794 = fa_light_texel(param_2);\n    float _797 = _794.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _809 = _785 && (_797 > 2.5f);\n    fa_light_is_area = _809;\n    bool _811 = _797 < 0.5f;\n    float3 l;\n    if (_811)\n    {\n        l = normalize(_789.xyz);\n        if (_785)\n        {\n            int param_3 = _781 + 6;\n            float4 _825 = fa_light_texel(param_3);\n            if (_825.z > 0.5f)\n            {\n                int param_4 = _781 + 4;\n                float4 _835 = fa_light_texel(param_4);\n                int param_5 = _781 + 5;\n                float4 _840 = fa_light_texel(param_5);\n                float2 param_6 = _825.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _835.xyz) * _835.w, (-dot(world_pos, _840.xyz)) * _840.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _870 = _789.xyz;\n        float3 _872 = _870 - world_pos;\n        float3 to_light = _872;\n        float _875 = length(_872);\n        float reach = _875;\n        bool front = true;\n        if (_809)\n        {\n            int param_8 = _781 + 7;\n            reach = max(_875 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _781 + 4;\n            float4 _899 = fa_light_texel(param_9);\n            int param_10 = _781 + 5;\n            float4 _904 = fa_light_texel(param_10);\n            int param_11 = _781 + 6;\n            float4 _909 = fa_light_texel(param_11);\n            float _910 = _909.w;\n            int param_12 = _781 + 2;\n            float3 _917 = normalize(fa_light_texel(param_12).xyz);\n            bool _919 = _910 > 1.5f;\n            bool _927;\n            if (!_919)\n            {\n                _927 = dot(_917, to_light) < 0.0f;\n            }\n            else\n            {\n                _927 = _919;\n            }\n            front = _927;\n            float3 r = 0.0f.xxx;\n            float3 _936 = _437_fa_camera_pos.xyz - world_pos;\n            bool _940 = dot(n, n) > 0.5f;\n            bool _948;\n            if (_940)\n            {\n                _948 = dot(_936, _936) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _948 = _940;\n            }\n            if (_948)\n            {\n                r = reflect(-normalize(_936), normalize(n));\n            }\n            float3 param_13 = _870;\n            float3 param_14 = _917;\n            float3 param_15 = _899.xyz;\n            float3 param_16 = _904.xyz;\n            float param_17 = _899.w;\n            float param_18 = _904.w;\n            float param_19 = _910;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _984 = length(to_light);\n        dist = _984;\n        l = to_light / max(_984, 9.9999997473787516355514526367188e-05f).xxx;\n        float _998 = reach / max(_789.w, 0.001000000047497451305389404296875f);\n        float _1004 = clamp(1.0f - (_998 * _998), 0.0f, 1.0f);\n        float _1006;\n        if (front)\n        {\n            _1006 = _1004 * _1004;\n        }\n        else\n        {\n            _1006 = 0.0f;\n        }\n        atten = _1006;\n        bool _1017 = _797 < 2.5f;\n        if ((_797 > 1.5f) && _1017)\n        {\n            int param_22 = _781 + 2;\n            float4 _1025 = fa_light_texel(param_22);\n            float _1035 = _1025.w;\n            int param_23 = _781 + 3;\n            float4 _1040 = fa_light_texel(param_23);\n            float _1041 = _1040.x;\n            float cos_inner = _1041;\n            if (_1041 > 1.5f)\n            {\n                cos_inner = lerp(_1035, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1035, cos_inner, dot(-l, normalize(_1025.xyz)));\n        }\n        if (_785 && (_797 < 1.5f))\n        {\n            int param_24 = _781 + 6;\n            float4 _1065 = fa_light_texel(param_24);\n            if (_1065.z > 0.5f)\n            {\n                float3 _1073 = -to_light;\n                int param_25 = _781 + 4;\n                int param_26 = _781 + 5;\n                float3 _1087 = fa_light_texel(param_25).xyz;\n                float3 _1091 = fa_light_texel(param_26).xyz;\n                float3 _1100 = float3(dot(_1073, _1087), dot(_1073, _1091), dot(_1073, cross(_1087, _1091)));\n                float3 param_27 = _1100;\n                int _1104 = fa_cube_face(param_27);\n                int param_28 = _1104;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1131 = float2(dot(_1100, cross(param_29, param_30)), dot(_1100, param_30)) / max(dot(_1100, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1135 = _1104 / 3;\n                float2 param_31 = _1065.xy + (float2(float(_1104 - (_1135 * 3)), float(_1135)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1131.x), 0.5f - (0.5f * _1131.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _781 + 7;\n            float4 _1165 = fa_light_texel(param_33);\n            if (_1165.z > 0.5f)\n            {\n                int param_34 = _781 + 2;\n                int param_35 = _781 + 4;\n                int param_36 = _781 + 5;\n                float2 param_37 = _1165.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_785 && _1017)\n            {\n                int param_42 = _781 + 6;\n                float4 _1212 = fa_light_texel(param_42);\n                int param_43 = _781 + 7;\n                float4 _1217 = fa_light_texel(param_43);\n                bool _1220 = _1212.z > 0.5f;\n                bool _1227;\n                if (!_1220)\n                {\n                    _1227 = _1217.z > 0.5f;\n                }\n                else\n                {\n                    _1227 = _1220;\n                }\n                if (_1227)\n                {\n                    int param_44 = _781 + 2;\n                    float4 _1234 = fa_light_texel(param_44);\n                    float3 _1238 = normalize(_1234.xyz);\n                    int param_45 = _781 + 4;\n                    float4 _1243 = fa_light_texel(param_45);\n                    int param_46 = _781 + 5;\n                    float4 _1248 = fa_light_texel(param_46);\n                    if (_1220)\n                    {\n                        float3 _1256 = -to_light;\n                        float _1263 = _1234.w;\n                        float _1279 = 0.5f / max(dot(_1256, _1238) * (sqrt(max(1.0f - (_1263 * _1263), 0.0f)) / max(_1263, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1212.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1256, _1243.xyz) * _1279), 0.5f - (dot(_1256, _1248.xyz) * _1279));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1217.z > 0.5f)\n                    {\n                        float2 param_49 = _1217.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1238;\n                        float3 param_52 = _1243.xyz;\n                        float3 param_53 = _1248.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _5365 = _794.xyz * atten;\n    if (_785)\n    {\n        _5365 *= fa_light_tint;\n    }\n    int _1347;\n    if (_811)\n    {\n        _1347 = 0;\n    }\n    else\n    {\n        _1347 = ((_797 > 1.5f) && (_797 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _5376 = { l, _5365, atten, 1.0f, dist, _1347 };\n    return _5376;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2084;\n    if (i == 0)\n    {\n        _2084 = _2094_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2100;\n        if (i == 1)\n        {\n            _2100 = _2094_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2108;\n            if (i == 2)\n            {\n                _2108 = _2094_fa_shadow_split.z;\n            }\n            else\n            {\n                _2108 = _2094_fa_shadow_split.w;\n            }\n            _2100 = _2108;\n        }\n        _2084 = _2100;\n    }\n    return _2084;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2141 = fa_shadow_depth(param, param_1);\n    float _2145;\n    if (conv.x < 0.5f)\n    {\n        _2145 = _2141;\n    }\n    else\n    {\n        _2145 = (conv.y * conv.z) / (conv.z - (_2141 * (conv.z - conv.y)));\n    }\n    return _2145;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2072 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2072), sin(_2072)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2191 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2200;\n        if (k < 0.0f)\n        {\n            _2200 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2200 = k;\n        }\n        float _2220 = clamp((_2200 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2191;\n            float2 _2239 = fa_shadow_vogel(param_3, param_4, param_5) * _2220;\n            float2 param_6 = uv + (_2239 * _2094_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2251 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2251 < (zr - (length(_2239) * plane)))\n            {\n                sum += _2251;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2277 = sum / cnt;\n        float _2287;\n        if (k < 0.0f)\n        {\n            _2287 = (-k) / max(_2277, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2287 = k;\n        }\n        radius = clamp(((max(zr - _2277, 0.0f) * unit) * _2287) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2309 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2309; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2309;\n        float param_11 = _2191;\n        float2 _2328 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2328 * _2094_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2328) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2309);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2370 = max(_2094_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2375 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2381 = sqrt(1.0f - (_2375 * _2375));\n    float _2388 = min(_2381 / max(_2375, 0.20000000298023223876953125f), 4.0f);\n    float _2393;\n    if (_2094_fa_shadow_bias.y > 0.0f)\n    {\n        _2393 = _2094_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2393 = 1.5f * _2094_fa_shadow_info[ci].x;\n    }\n    float4 _2418 = mul(float4(world + (n * (_2393 * _2381)), 1.0f), _2094_fa_shadow_mat[ci]);\n    float _2425 = _2418.x;\n    bool _2428 = _2425 < _2094_fa_shadow_rect[ci].x;\n    bool _2437;\n    if (!_2428)\n    {\n        _2437 = _2425 > _2094_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2437 = _2428;\n    }\n    bool _2446;\n    if (!_2437)\n    {\n        _2446 = _2418.y < _2094_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2446 = _2437;\n    }\n    bool _2455;\n    if (!_2446)\n    {\n        _2455 = _2418.y > _2094_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2455 = _2446;\n    }\n    bool _2462;\n    if (!_2455)\n    {\n        _2462 = _2418.z > 1.0f;\n    }\n    else\n    {\n        _2462 = _2455;\n    }\n    if (_2462)\n    {\n        return -1.0f;\n    }\n    float _2470;\n    if (_2094_fa_shadow_bias.x > 0.0f)\n    {\n        _2470 = _2094_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2470 = 1.5f * _2094_fa_shadow_info[ci].x;\n    }\n    float2 param = _2418.xy;\n    float4 param_1 = _2094_fa_shadow_rect[ci];\n    float param_2 = _2418.z - ((_2470 * (1.0f + (0.5f * _2388))) / _2370);\n    float param_3 = _2094_fa_shadow_info[ci].x;\n    float param_4 = _2370;\n    float param_5 = _2370 * 0.25f;\n    float param_6 = ((_2094_fa_shadow_info[ci].x * min(_2388, 3.0f)) * 0.5f) / _2370;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2094_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2094_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_437_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2848 = int(_2094_fa_shadow_cfg.x + 0.5f);\n    if (_2848 < 1)\n    {\n        return 1.0f;\n    }\n    float _2863 = dot(world - _2094_fa_shadow_eye.xyz, _2094_fa_shadow_fwd.xyz);\n    int param = _2848 - 1;\n    if (_2863 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2875 = _2848 > 1;\n    bool _2882;\n    if (_2875)\n    {\n        _2882 = _2863 > _2094_fa_shadow_split.x;\n    }\n    else\n    {\n        _2882 = _2875;\n    }\n    if (_2882)\n    {\n        ci = 1;\n    }\n    bool _2886 = _2848 > 2;\n    bool _2893;\n    if (_2886)\n    {\n        _2893 = _2863 > _2094_fa_shadow_split.y;\n    }\n    else\n    {\n        _2893 = _2886;\n    }\n    if (_2893)\n    {\n        ci = 2;\n    }\n    bool _2897 = _2848 > 3;\n    bool _2904;\n    if (_2897)\n    {\n        _2904 = _2863 > _2094_fa_shadow_split.z;\n    }\n    else\n    {\n        _2904 = _2897;\n    }\n    if (_2904)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2848)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2930 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2930;\n        if (_2930 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2094_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2955;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2955 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2955 = _2094_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2974 = _2094_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2955, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2985 = clamp((_2863 - (fa_shadow_split_at(param_7) - _2974)) / _2974, 0.0f, 1.0f);\n        if (_2985 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2848)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _3006 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3006;\n                if (_3006 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2985);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2528 = _437_fa_pbr.z < 0.5f;\n    bool _2535;\n    if (!_2528)\n    {\n        _2535 = _2094_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2535 = _2528;\n    }\n    if (_2535)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2094_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2548 = fa_light_texel(param);\n    float _2549 = _2548.x;\n    if (_2549 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2558 = int(_2549 + 0.5f);\n    int param_1 = _2558;\n    float4 _2562 = fa_light_texel(param_1);\n    int param_2 = _2558 + 1;\n    float4 _2567 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2570 = _2562.y;\n    if (_2570 > 0.0f)\n    {\n        float _2587 = 1.0f - smoothstep(0.75f * _2570, _2570, length(world - _2094_fa_shadow_eye.xyz));\n        fade = _2587;\n        if (_2587 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2562.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2611 = (_2558 + 2) + (face * 6);\n    int param_4 = _2611;\n    int param_5 = _2611 + 1;\n    int param_6 = _2611 + 3;\n    float4 _2625 = fa_light_texel(param_6);\n    int param_7 = _2611 + 4;\n    float4 _2630 = fa_light_texel(param_7);\n    int param_8 = _2611 + 5;\n    float4 _2635 = fa_light_texel(param_8);\n    float _2647 = _2635.x * max(dot(_2625, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2652 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2675 = clamp(dot(n, _2625.xyz), -1.0f, 1.0f);\n    float _2694 = min(sqrt(1.0f - (_2675 * _2675)) / max(abs(dot(n, world - lpos)) / max(dot(_2625, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2697 = _2567.y;\n    float _2699;\n    if (_2697 > 0.0f)\n    {\n        _2699 = _2697;\n    }\n    else\n    {\n        _2699 = 1.5f * _2647;\n    }\n    float4 _2719 = float4(world + (n * (_2699 * sqrt(1.0f - (_2652 * _2652)))), 1.0f);\n    float _2723 = dot(_2625, _2719);\n    float _2726 = _2635.y;\n    if (_2723 < _2726)\n    {\n        return 1.0f;\n    }\n    float2 _2741 = float2(dot(fa_light_texel(param_4), _2719), dot(fa_light_texel(param_5), _2719)) / _2723.xx;\n    float _2743 = _2741.x;\n    bool _2746 = _2743 < _2630.x;\n    bool _2755;\n    if (!_2746)\n    {\n        _2755 = _2743 > _2630.z;\n    }\n    else\n    {\n        _2755 = _2746;\n    }\n    bool _2764;\n    if (!_2755)\n    {\n        _2764 = _2741.y < _2630.y;\n    }\n    else\n    {\n        _2764 = _2755;\n    }\n    bool _2773;\n    if (!_2764)\n    {\n        _2773 = _2741.y > _2630.w;\n    }\n    else\n    {\n        _2773 = _2764;\n    }\n    if (_2773)\n    {\n        return 1.0f;\n    }\n    float _2779 = _2567.x;\n    float _2781;\n    if (_2779 > 0.0f)\n    {\n        _2781 = _2779;\n    }\n    else\n    {\n        _2781 = 1.5f * _2647;\n    }\n    float2 param_9 = _2741;\n    float4 param_10 = _2630;\n    float param_11 = _2723 - (_2781 * (1.0f + (0.5f * _2694)));\n    float param_12 = _2647;\n    float param_13 = 1.0f;\n    float param_14 = _2635.z * 0.25f;\n    float param_15 = (_2647 * min(_2694, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2726, _2635.z);\n    int param_17 = int(_2562.z + 0.5f);\n    float param_18 = _2562.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _4047 = _437_fa_ct_a.x < 0.5f;\n    bool _4054;\n    if (!_4047)\n    {\n        _4054 = _2094_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _4054 = _4047;\n    }\n    if (_4054)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2094_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _4067 = fa_light_texel(param);\n    float _4068 = _4067.y;\n    float len = _4068;\n    if (_4068 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4080 = length(world - _437_fa_camera_pos.xyz);\n    float _4090 = 1.0f - smoothstep(0.5f * _437_fa_ct_b.x, _437_fa_ct_b.x, _4080);\n    if (_4090 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4096 = len;\n    float _4099 = min(_4096, 0.89999997615814208984375f * dist);\n    len = _4099;\n    float _4104 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _4080);\n    float _4109 = _4104 + (0.5f * _4099);\n    float3 _4115 = world + (gn * _4104);\n    float _4117 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _4181;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4132 = (float(k) + _4117) * 0.083333335816860198974609375f;\n        float3 _4140 = _4115 + (l * (_4132 * len));\n        float4 _4146 = float4(_4140, 1.0f);\n        float _4152 = dot(_437_fa_ct_vpw, _4146);\n        if (_4152 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _4172 = float2(dot(_437_fa_ct_vpx, _4146), dot(_437_fa_ct_vpy, _4146)) / _4152.xx;\n        float _4176 = _4172.x * 0.5f;\n        float _4177 = _4176 + 0.5f;\n        if (_437_fa_ct_a.y > 0.5f)\n        {\n            _4181 = (_4172.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _4181 = 0.5f - (_4172.y * 0.5f);\n        }\n        bool _4197 = _4177 < 0.0f;\n        bool _4204;\n        if (!_4197)\n        {\n            _4204 = _4177 >= 1.0f;\n        }\n        else\n        {\n            _4204 = _4197;\n        }\n        bool _4211;\n        if (!_4204)\n        {\n            _4211 = _4181 < 0.0f;\n        }\n        else\n        {\n            _4211 = _4204;\n        }\n        bool _4218;\n        if (!_4211)\n        {\n            _4218 = _4181 >= 1.0f;\n        }\n        else\n        {\n            _4218 = _4211;\n        }\n        if (_4218)\n        {\n            break;\n        }\n        float4 _4237 = fa_screen_tex.Load(int3(int2(float2(_4177, _4181) * _437_fa_ct_a.zw), 0));\n        if (_4237.w < 0.5f)\n        {\n            continue;\n        }\n        float _4256 = (dot(_437_fa_ct_fwd.xyz, _4140) + _437_fa_ct_fwd.w) - _4237.x;\n        if ((_4256 > _4104) && (_4256 < _4109))\n        {\n            occ = max(occ, (1.0f - (_4132 * _4132)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_4177, 0.5f - _4176), min(_4181, 1.0f - _4181))));\n        }\n    }\n    return 1.0f - (occ * _4090);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _4332 = fa_lm.z > 0.5f;\n    bool _4338;\n    if (_4332)\n    {\n        int param = li;\n        _4338 = fa_light_baked(param);\n    }\n    else\n    {\n        _4338 = _4332;\n    }\n    if (_4338)\n    {\n        int param_1 = li;\n        LightSample _5496 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _5496;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4362 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _5498 = _4362.color;\n    float _5500 = _4362.shadow;\n    bool _4365 = _4362.type == 0;\n    if (_4365 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4362.direction;\n        float _4376 = fa_shadow_factor(param_5, param_6);\n        _5500 = _4376;\n        _5498 *= _4376;\n    }\n    else\n    {\n        bool _4387 = _4362.type != 0;\n        bool _4393;\n        if (_4387)\n        {\n            _4393 = _4362.attenuation > 0.0f;\n        }\n        else\n        {\n            _4393 = _4387;\n        }\n        if (_4393)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _4362.direction;\n            float _4412 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _5500 = _4412;\n            _5498 *= _4412;\n        }\n    }\n    bool _4422 = _437_fa_ct_a.x > 0.5f;\n    bool _4428;\n    if (_4422)\n    {\n        _4428 = _4362.attenuation > 0.0f;\n    }\n    else\n    {\n        _4428 = _4422;\n    }\n    if (_4428)\n    {\n        float _4435;\n        if (_4365)\n        {\n            _4435 = 1000000000.0f;\n        }\n        else\n        {\n            _4435 = _4362._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _4362.direction;\n        float param_18 = _4435;\n        float _4453 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _5500 *= _4453;\n        _5498 *= _4453;\n    }\n    LightSample _5515 = { _4362.direction, _5498, _4362.attenuation, _5500, _4362._distance, _4362.type };\n    return _5515;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2094_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3030 = int(_2094_fa_shadow_cfg.x + 0.5f);\n    float _3040 = dot(world - _2094_fa_shadow_eye.xyz, _2094_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3045 = _3030 > 0;\n    bool _3054;\n    if (_3045)\n    {\n        int param = _3030 - 1;\n        _3054 = _3040 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3054 = _3045;\n    }\n    if (_3054)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3060 = _3030 > 1;\n        bool _3067;\n        if (_3060)\n        {\n            _3067 = _3040 > _2094_fa_shadow_split.x;\n        }\n        else\n        {\n            _3067 = _3060;\n        }\n        if (_3067)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3073 = _3030 > 2;\n        bool _3080;\n        if (_3073)\n        {\n            _3080 = _3040 > _2094_fa_shadow_split.y;\n        }\n        else\n        {\n            _3080 = _3073;\n        }\n        if (_3080)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3086 = _3030 > 3;\n        bool _3093;\n        if (_3086)\n        {\n            _3093 = _3040 > _2094_fa_shadow_split.z;\n        }\n        else\n        {\n            _3093 = _3086;\n        }\n        if (_3093)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _5207 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5207 = -_5207;\n    }\n    float3 _4842 = normalize(_437_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _5220 = { fa_world_pos, _5207, fa_world_tangent, fa_uv, fa_vertex_color, _4842, gl_FrontFacing };\n    SurfaceInput param_1 = _5220;\n    Surface _4850 = fa_standard_surface(param_1);\n    float3 _5246 = _4850.albedo;\n    float _5247 = _4850.alpha;\n    float3 _5248 = _4850.normal;\n    float _5249 = _4850.metallic;\n    float _5250 = _4850.roughness;\n    float _5251 = _4850.occlusion;\n    float3 _5252 = _4850.emission;\n    float _5253 = _4850.clearcoat;\n    float _5254 = _4850.clearcoat_roughness;\n    float3 _5255 = _4850.sheen_color;\n    float _5256 = _4850.sheen_roughness;\n    float _5257 = _4850.anisotropy;\n    float _5258 = _4850.anisotropy_rotation;\n    float _5259 = _4850.specular;\n    float _5260 = _4850.ior;\n    float3 _5261 = _4850.specular_color;\n    SurfaceInput _5228 = { fa_world_pos, _5207, fa_world_tangent, fa_uv, fa_vertex_color, _4842, gl_FrontFacing };\n    SurfaceInput param_2 = _5228;\n    Surface param_3 = _4850;\n    surface(param_2, param_3);\n    _5246 = param_3.albedo;\n    _5247 = param_3.alpha;\n    _5248 = param_3.normal;\n    _5249 = param_3.metallic;\n    _5250 = param_3.roughness;\n    _5251 = param_3.occlusion;\n    _5252 = param_3.emission;\n    _5253 = param_3.clearcoat;\n    _5254 = param_3.clearcoat_roughness;\n    _5255 = param_3.sheen_color;\n    _5256 = param_3.sheen_roughness;\n    _5257 = param_3.anisotropy;\n    _5258 = param_3.anisotropy_rotation;\n    _5259 = param_3.specular;\n    _5260 = param_3.ior;\n    _5261 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _5207;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5246 = param_6;\n    _5248 = param_7;\n    float3 result;\n    if (_437_fa_emissive.w > 0.5f)\n    {\n        result = _5246;\n    }\n    else\n    {\n        float3 _4888 = _5248;\n        float3 _4889 = normalize(_4888);\n        _5248 = _4889;\n        float3 param_8 = _4889;\n        SurfaceInput _5236 = { fa_world_pos, _5207, fa_world_tangent, fa_uv, fa_vertex_color, _4842, gl_FrontFacing };\n        SurfaceInput param_9 = _5236;\n        Surface _5327 = { _5246, _5247, _5248, _5249, _5250, _5251, _5252, _5253, _5254, _5255, _5256, _5257, _5258, _5259, _5260, _5261 };\n        Surface param_10 = _5327;\n        float3 param_11 = fa_indirect_diffuse(param_8);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _4908 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4908; ln++)\n        {\n            int param_12 = ln;\n            int _4921 = fa_cl_light(param_12);\n            bool _4924 = fa_lm.z > 0.5f;\n            bool _4930;\n            if (_4924)\n            {\n                int param_13 = _4921;\n                _4930 = fa_light_baked(param_13);\n            }\n            else\n            {\n                _4930 = _4924;\n            }\n            if (_4930)\n            {\n                continue;\n            }\n            int param_14 = _4921;\n            float3 param_15 = fa_world_pos;\n            float3 param_16 = _5207;\n            LightSample _4942 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput _5244 = { fa_world_pos, _5207, fa_world_tangent, fa_uv, fa_vertex_color, _4842, gl_FrontFacing };\n            SurfaceInput param_17 = _5244;\n            Surface _5344 = { _5246, _5247, _5248, _5249, _5250, _5251, _5252, _5253, _5254, _5255, _5256, _5257, _5258, _5259, _5260, _5261 };\n            Surface param_18 = _5344;\n            LightSample param_19 = _4942;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _4957 = result;\n    float3 _4958 = _4957 + _5252;\n    result = _4958;\n    float3 param_20 = _4958;\n    float3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _4967 = _437_fa_fog.w > 0.0f;\n    bool _4974;\n    if (!_4967)\n    {\n        _4974 = _437_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _4974 = _4967;\n    }\n    if (_4974)\n    {\n        float3 _4983 = fa_world_pos - _437_fa_camera_pos.xyz;\n        float _4989 = dot(_4983, _437_fa_fog_c.xyz);\n        bool _4993 = _437_fa_fog_c.w > 0.5f;\n        float _4994;\n        if (_4993)\n        {\n            _4994 = _4989;\n        }\n        else\n        {\n            _4994 = length(_4983);\n        }\n        float _5006 = _4994 - _437_fa_fog_b.x;\n        if (_5006 > 0.0f)\n        {\n            float _5015 = _437_fa_fog.w * _5006;\n            float tau = _5015 * _5015;\n            if (_437_fa_fog_b.y > 0.0f)\n            {\n                float _5031;\n                if (_4993)\n                {\n                    _5031 = fa_world_pos.y - (_437_fa_fog_c.y * _4989);\n                }\n                else\n                {\n                    _5031 = _437_fa_camera_pos.y;\n                }\n                float _5052 = lerp(_5031, fa_world_pos.y, clamp(_437_fa_fog_b.x / _4994, 0.0f, 1.0f));\n                float _5056 = fa_world_pos.y - _5052;\n                float _5061 = _5052 - _437_fa_fog_b.z;\n                float _5066 = fa_world_pos.y - _437_fa_fog_b.z;\n                bool _5069 = _5061 <= 0.0f;\n                bool _5070 = !_5069;\n                bool _5076;\n                if (_5070)\n                {\n                    _5076 = _437_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5076 = _5069;\n                }\n                float _5077;\n                if (_5076)\n                {\n                    _5077 = _437_fa_fog_b.y;\n                }\n                else\n                {\n                    _5077 = _437_fa_fog_b.y * exp(-min(_437_fa_fog_b.w * _5061, 80.0f));\n                }\n                bool _5104;\n                if (_5070)\n                {\n                    _5104 = _437_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5104 = _5069;\n                }\n                float _5105;\n                if (_5104)\n                {\n                    _5105 = _437_fa_fog_b.y * _5061;\n                }\n                else\n                {\n                    _5105 = (_437_fa_fog_b.y * (1.0f - exp(-min(_437_fa_fog_b.w * _5061, 80.0f)))) / _437_fa_fog_b.w;\n                }\n                bool _5130 = _5066 <= 0.0f;\n                bool _5137;\n                if (!_5130)\n                {\n                    _5137 = _437_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5137 = _5130;\n                }\n                float _5138;\n                if (_5137)\n                {\n                    _5138 = _437_fa_fog_b.y * _5066;\n                }\n                else\n                {\n                    _5138 = (_437_fa_fog_b.y * (1.0f - exp(-min(_437_fa_fog_b.w * _5066, 80.0f)))) / _437_fa_fog_b.w;\n                }\n                float _5165;\n                if (abs(_5056) < 0.001000000047497451305389404296875f)\n                {\n                    _5165 = _5077;\n                }\n                else\n                {\n                    _5165 = (_5138 - _5105) / _5056;\n                }\n                tau += (_5006 * max(_5165, 0.0f));\n            }\n            result = lerp(result, _437_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _5247);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_437",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2094",
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
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n    float4 _213_fa_ct_a : packoffset(c24);\n    float4 _213_fa_ct_b : packoffset(c25);\n    float4 _213_fa_ct_vpx : packoffset(c26);\n    float4 _213_fa_ct_vpy : packoffset(c27);\n    float4 _213_fa_ct_vpw : packoffset(c28);\n    float4 _213_fa_ct_fwd : packoffset(c29);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _785 = base_t;\n    _785.x = _225.x;\n    _785.y = _225.y;\n    _785.z = _225.z;\n    base_t = _785;\n    float4 _241 = (_785 * _213_fa_base_color) * i.vertex_color;\n    float3 _748 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _793 = _279;\n        _793.x = _284.x;\n        _793.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _793;\n        _748 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _796 = mrt;\n    _796.x = _313.x;\n    _796.y = _313.y;\n    _796.z = _313.z;\n    mrt = _796;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _753 = _213_fa_layers_a.x;\n    float _754 = _213_fa_layers_a.y;\n    float _757 = _213_fa_layers_a.z;\n    float _756 = _213_fa_layers_b.w;\n    float _759 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _753 *= _355.y;\n            _754 *= _355.z;\n            _756 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _757 *= mrt.x;\n            _759 *= mrt.w;\n        }\n    }\n    Surface _778 = { _241.xyz, _241.w, _748, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _753, _754, _213_fa_layers_b.xyz, _756, _757, _213_fa_layers_a.w, _759, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _778;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _659 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _659 = -_659;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _672 = { fa_world_pos, _659, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _672;\n    SurfaceInput _680 = { fa_world_pos, _659, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _680;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 480,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _413 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _413;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _420 = _273.world_pos;\n    float4 _284 = float4(_420, 1.0f);\n    fa_world_pos = _420;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -mul(_284, _136_fa_light_vp).z;\n    fa_pre_r0 = float3(_136_fa_light_vp[0].x, _136_fa_light_vp[1].x, _136_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136_fa_light_vp[0].y, _136_fa_light_vp[1].y, _136_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136_fa_light_vp[0].z, _136_fa_light_vp[1].z, _136_fa_light_vp[2].z);\n    gl_Position = mul(_284, _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n    float4 _213_fa_ct_a : packoffset(c24);\n    float4 _213_fa_ct_b : packoffset(c25);\n    float4 _213_fa_ct_vpx : packoffset(c26);\n    float4 _213_fa_ct_vpy : packoffset(c27);\n    float4 _213_fa_ct_vpw : packoffset(c28);\n    float4 _213_fa_ct_fwd : packoffset(c29);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _785 = base_t;\n    _785.x = _225.x;\n    _785.y = _225.y;\n    _785.z = _225.z;\n    base_t = _785;\n    float4 _241 = (_785 * _213_fa_base_color) * i.vertex_color;\n    float3 _748 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _793 = _279;\n        _793.x = _284.x;\n        _793.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _793;\n        _748 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _796 = mrt;\n    _796.x = _313.x;\n    _796.y = _313.y;\n    _796.z = _313.z;\n    mrt = _796;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _753 = _213_fa_layers_a.x;\n    float _754 = _213_fa_layers_a.y;\n    float _757 = _213_fa_layers_a.z;\n    float _756 = _213_fa_layers_b.w;\n    float _759 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _753 *= _355.y;\n            _754 *= _355.z;\n            _756 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _757 *= mrt.x;\n            _759 *= mrt.w;\n        }\n    }\n    Surface _778 = { _241.xyz, _241.w, _748, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _753, _754, _213_fa_layers_b.xyz, _756, _757, _213_fa_layers_a.w, _759, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _778;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _659 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _659 = -_659;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _672 = { fa_world_pos, _659, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _672;\n    SurfaceInput _680 = { fa_world_pos, _659, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _680;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 480,
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
