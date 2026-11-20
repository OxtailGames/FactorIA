{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "b9137a7fd5249b4222bedebb6ca5e740fb7c4a348474dd42da5706fae9a2d4c0",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _258 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _258;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _265 = _160.world_pos;\n    fa_world_pos = _265;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_265, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _1589[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _459_fa_camera_pos : packoffset(c0);\n    float4 _459_fa_ambient : packoffset(c1);\n    float4 _459_fa_base_color : packoffset(c2);\n    float4 _459_fa_emissive : packoffset(c3);\n    float4 _459_fa_model_emissive : packoffset(c4);\n    float4 _459_fa_pbr : packoffset(c5);\n    float4 _459_fa_maps : packoffset(c6);\n    float4 _459_fa_fog : packoffset(c7);\n    float4 _459_fa_fog_b : packoffset(c8);\n    float4 _459_fa_fog_c : packoffset(c9);\n    float4 _459_fa_counts : packoffset(c10);\n    float4 _459_fa_env_sky : packoffset(c11);\n    float4 _459_fa_env_horizon : packoffset(c12);\n    float4 _459_fa_time : packoffset(c13);\n    float4 _459_fa_cl_vpx : packoffset(c14);\n    float4 _459_fa_cl_vpy : packoffset(c15);\n    float4 _459_fa_cl_vpw : packoffset(c16);\n    float4 _459_fa_cl_fwd : packoffset(c17);\n    float4 _459_fa_cl_grid : packoffset(c18);\n    float4 _459_fa_cl_info : packoffset(c19);\n    float4 _459_fa_layers_a : packoffset(c20);\n    float4 _459_fa_layers_b : packoffset(c21);\n    float4 _459_fa_layers_c : packoffset(c22);\n    float4 _459_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _695_fa_shadow_mat[4] : packoffset(c0);\n    float4 _695_fa_shadow_rect[4] : packoffset(c16);\n    float4 _695_fa_shadow_info[4] : packoffset(c20);\n    float4 _695_fa_shadow_split : packoffset(c24);\n    float4 _695_fa_shadow_cfg : packoffset(c25);\n    float4 _695_fa_shadow_bias : packoffset(c26);\n    float4 _695_fa_shadow_eye : packoffset(c27);\n    float4 _695_fa_shadow_fwd : packoffset(c28);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _464 = _459_fa_cl_info.x < 0.0f;\n    bool _471;\n    if (!_464)\n    {\n        _471 = _459_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _471 = _464;\n    }\n    bool _479;\n    if (!_471)\n    {\n        _479 = _459_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _479 = _471;\n    }\n    bool _486;\n    if (!_479)\n    {\n        _486 = _459_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _486 = _479;\n    }\n    bool _493;\n    if (!_486)\n    {\n        _493 = _459_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _493 = _486;\n    }\n    if (_493)\n    {\n        return int2(0, 0);\n    }\n    float4 _503 = float4(world_pos, 1.0f);\n    float _510 = dot(_459_fa_cl_vpw, _503);\n    if (!(_510 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _532 = float2(dot(_459_fa_cl_vpx, _503), dot(_459_fa_cl_vpy, _503)) / _510.xx;\n    int _536 = int(_459_fa_cl_grid.x);\n    int _540 = int(_459_fa_cl_grid.y);\n    int param = (int(_459_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_459_fa_cl_fwd.xyz, world_pos) + _459_fa_cl_fwd.w, _459_fa_cl_grid.w) / _459_fa_cl_grid.w) * _459_fa_cl_grid.z)), 0, int(_459_fa_cl_info.y) - 1) * _540) + clamp(int(floor(((_532.y * 0.5f) + 0.5f) * _459_fa_cl_grid.y)), 0, _540 - 1)) * _536)) + clamp(int(floor(((_532.x * 0.5f) + 0.5f) * _459_fa_cl_grid.x)), 0, _536 - 1);\n    float4 _611 = fa_light_texel(param);\n    return int2(int(_611.x), int(_611.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_459_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2408 = fa_cluster_lookup(param);\n    fa_cl_slot = _2408.x;\n    fa_cl_local = _2408.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _2508 = fa_linear_to_srgb(param);\n        c = _2508;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _2516 = fa_srgb_to_linear(param_1);\n            c = _2516;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _231;\n    if (i.front_facing)\n    {\n        _231 = i.world_normal;\n    }\n    else\n    {\n        _231 = -i.world_normal;\n    }\n    float3 _255 = normalize(i.world_tangent.xyz - (_231 * dot(_231, i.world_tangent.xyz)));\n    float3 _283 = normalize(((_255 * m.x) + ((cross(_231, _255) * i.world_tangent.w) * m.y)) + (_231 * m.z));\n    float3 _286;\n    if (i.front_facing)\n    {\n        _286 = _283;\n    }\n    else\n    {\n        _286 = -_283;\n    }\n    return _286;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _459_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2547 = fa_tex_fix(param_2, param_3);\n    float4 _3718 = base_t;\n    _3718.x = _2547.x;\n    _3718.y = _2547.y;\n    _3718.z = _2547.z;\n    base_t = _3718;\n    float4 _2561 = (_3718 * _459_fa_base_color) * i.vertex_color;\n    float3 _3652 = i.world_normal;\n    if (_459_fa_maps.z > 0.5f)\n    {\n        float param_4 = _459_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2593 = fa_tex_fix(param_6, param_7);\n        float3 _2596 = (_2593 * 2.0f) - 1.0f.xxx;\n        float2 _2601 = _2596.xy * _459_fa_maps.x;\n        float3 _3726 = _2596;\n        _3726.x = _2601.x;\n        _3726.y = _2601.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3726;\n        _3652 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _459_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2630 = fa_tex_fix(param_12, param_13);\n    float4 _3729 = mrt;\n    _3729.x = _2630.x;\n    _3729.y = _2630.y;\n    _3729.z = _2630.z;\n    mrt = _3729;\n    float4 _2658 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _459_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _2658.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2670 = fa_tex_fix(param_16, param_17);\n    float param_18 = _459_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2700 = fa_tex_fix(param_20, param_21);\n    float _3657 = _459_fa_layers_a.x;\n    float _3658 = _459_fa_layers_a.y;\n    float _3661 = _459_fa_layers_a.z;\n    float _3660 = _459_fa_layers_b.w;\n    float _3663 = _459_fa_layers_c.x;\n    if (_459_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_459_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _3657 *= _2670.y;\n            _3658 *= _2670.z;\n            _3660 *= _2658.w;\n        }\n        if (_459_fa_layers_c.z > 1.5f)\n        {\n            _3661 *= mrt.x;\n            _3663 *= mrt.w;\n        }\n    }\n    Surface _3682 = { _2561.xyz, _2561.w, _3652, clamp(_459_fa_pbr.x * _2630.z, 0.0f, 1.0f), clamp(_459_fa_pbr.y * _2630.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_459_fa_maps.y * (_2670.x - 1.0f)), _459_fa_emissive.xyz + (_459_fa_model_emissive.xyz * _2700), _3657, _3658, _459_fa_layers_b.xyz, _3660, _3661, _459_fa_layers_a.w, _3663, _459_fa_layers_c.y, _459_fa_layers_d.xyz };\n    return _3682;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1514 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _1522 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _1525 = int(_1514);\n    int _1528 = int(_1522);\n    float _1538 = _1522 - float(_1528);\n    int _1594 = (_1525 * 9) + _1528;\n    int _1614 = ((_1525 + 1) * 9) + _1528;\n    return lerp(lerp(_1589[_1594], _1589[_1594 + 1], _1538), lerp(_1589[_1614], _1589[_1614 + 1], _1538), _1514 - float(_1525));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _3588 = false;\n    float _3589 = 1.0f;\n    float _3590 = 1.0f;\n    float _3591 = 1.0f;\n    float _3592 = 0.0f;\n    float _3593 = 0.0f;\n    float _3594 = 0.0f;\n    float _3595 = 0.0f;\n    float _3597 = 1.0f;\n    bool _3598 = false;\n    float3 _3599 = 0.0f.xxx;\n    float _3600 = 1.0f;\n    float _3601 = 1.0f;\n    float _3602 = 1.0f;\n    float _3603 = 0.0f;\n    float _3604 = 0.0f;\n    float3 _3605 = float3(1.0f, 0.0f, 0.0f);\n    float3 _3606 = float3(0.0f, 0.0f, 1.0f);\n    float _3607 = 1.0f;\n    float _3608 = 1.0f;\n    float _1669 = clamp(s.specular, 0.0f, 1.0f);\n    float _1673 = clamp(s.ior, 1.0f, 3.0f);\n    bool _1678 = (_1669 != 1.0f) || (_1673 != 1.5f);\n    bool _1688;\n    if (!_1678)\n    {\n        _1688 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _1688 = _1678;\n    }\n    if (_1688)\n    {\n        float _1696 = (_1673 - 1.0f) / (_1673 + 1.0f);\n        f0 = lerp(min((_1696 * _1696).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _1669, s.albedo, metallic.xxx);\n        _3589 = lerp(_1669, 1.0f, metallic);\n        _3588 = true;\n    }\n    float _1724 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_1724 > 0.0f)\n    {\n        float _1732 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _3592 = _1724;\n        _3593 = _1732;\n        float _1739 = _1732 * _1732;\n        _3594 = _1739;\n        _3595 = _1739 * _1739;\n        float _1751 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _3597 = _1751;\n        _3590 = 1.0f - (_1724 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _1751, 0.0f, 1.0f), 5.0f))));\n        _3588 = true;\n    }\n    float3 _1771 = max(s.sheen_color, 0.0f.xxx);\n    float _1780 = max(_1771.x, max(_1771.y, _1771.z));\n    if (_1780 > 0.0f)\n    {\n        float _1788 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _3598 = true;\n        _3599 = _1771;\n        _3600 = _1788;\n        _3601 = _1788 * _1788;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _1788;\n        float _1805 = fa_sheen_albedo(param, param_1);\n        _3603 = _1805;\n        _3602 = 1.0f - min(_1780 * _1805, 1.0f);\n        _3588 = true;\n    }\n    _3591 = _3590 * _3602;\n    float _1824 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_1824 != 0.0f)\n    {\n        float3 _1839 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _1839;\n        if (dot(_1839, _1839) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _1853 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_1853.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _1853.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _1853.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _1857 = t;\n        float3 _1858 = normalize(_1857);\n        t = _1858;\n        float3 _1883 = normalize((_1858 * cos(s.anisotropy_rotation)) + ((cross(n, _1858) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _3605 = _1883;\n        _3606 = cross(n, _1883);\n        float _1893 = roughness * roughness;\n        float _1899 = lerp(_1893, 1.0f, _1824 * _1824);\n        bool _1901 = _1824 > 0.0f;\n        _3607 = _1901 ? _1899 : _1893;\n        _3608 = _1901 ? _1893 : _1899;\n        _3604 = _1824;\n        _3588 = true;\n    }\n    FaLayers _3630 = { _3588, _3589, _3590, _3591, _3592, _3593, _3594, _3595, i.world_normal, _3597, _3598, _3599, _3600, _3601, _3602, _3603, _3604, _3605, _3606, _3607, _3608 };\n    return _3630;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_459_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _459_fa_ambient.xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_459_fa_cl_info.x) + int(_459_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _331 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _337 = fa_light_texel(param_1);\n    float _340 = _337.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _347 = _340 < 0.5f;\n    float3 l;\n    if (_347)\n    {\n        l = normalize(_331.xyz);\n    }\n    else\n    {\n        float3 _359 = _331.xyz - world_pos;\n        float _361 = length(_359);\n        dist = _361;\n        l = _359 / max(_361, 9.9999997473787516355514526367188e-05f).xxx;\n        float _376 = _361 / max(_331.w, 0.001000000047497451305389404296875f);\n        float _382 = clamp(1.0f - (_376 * _376), 0.0f, 1.0f);\n        atten = _382 * _382;\n        if (_340 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _396 = fa_light_texel(param_2);\n            float _406 = _396.w;\n            int param_3 = (li * 4) + 3;\n            float4 _413 = fa_light_texel(param_3);\n            float _414 = _413.x;\n            float cos_inner = _414;\n            if (_414 > 1.5f)\n            {\n                cos_inner = lerp(_406, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_406, cos_inner, dot(-l, normalize(_396.xyz)));\n        }\n    }\n    int _445;\n    if (_347)\n    {\n        _445 = 0;\n    }\n    else\n    {\n        _445 = (_340 > 1.5f) ? 2 : 1;\n    }\n    LightSample _3587 = { l, _337.xyz * atten, atten, 1.0f, dist, _445 };\n    return _3587;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _685;\n    if (i == 0)\n    {\n        _685 = _695_fa_shadow_split.x;\n    }\n    else\n    {\n        float _701;\n        if (i == 1)\n        {\n            _701 = _695_fa_shadow_split.y;\n        }\n        else\n        {\n            float _709;\n            if (i == 2)\n            {\n                _709 = _695_fa_shadow_split.z;\n            }\n            else\n            {\n                _709 = _695_fa_shadow_split.w;\n            }\n            _701 = _709;\n        }\n        _685 = _701;\n    }\n    return _685;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _673 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_673), sin(_673)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _747 = max(_695_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _752 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _758 = sqrt(1.0f - (_752 * _752));\n    float _766 = min(_758 / max(_752, 0.20000000298023223876953125f), 4.0f);\n    float _771;\n    if (_695_fa_shadow_bias.y > 0.0f)\n    {\n        _771 = _695_fa_shadow_bias.y;\n    }\n    else\n    {\n        _771 = 1.5f * _695_fa_shadow_info[ci].x;\n    }\n    float4 _796 = mul(float4(world + (n * (_771 * _758)), 1.0f), _695_fa_shadow_mat[ci]);\n    float _803 = _796.x;\n    bool _806 = _803 < _695_fa_shadow_rect[ci].x;\n    bool _815;\n    if (!_806)\n    {\n        _815 = _803 > _695_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _815 = _806;\n    }\n    bool _824;\n    if (!_815)\n    {\n        _824 = _796.y < _695_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _824 = _815;\n    }\n    bool _833;\n    if (!_824)\n    {\n        _833 = _796.y > _695_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _833 = _824;\n    }\n    bool _840;\n    if (!_833)\n    {\n        _840 = _796.z > 1.0f;\n    }\n    else\n    {\n        _840 = _833;\n    }\n    if (_840)\n    {\n        return -1.0f;\n    }\n    float _849;\n    if (_695_fa_shadow_bias.x > 0.0f)\n    {\n        _849 = _695_fa_shadow_bias.x;\n    }\n    else\n    {\n        _849 = 1.5f * _695_fa_shadow_info[ci].x;\n    }\n    float _868 = _796.z - ((_849 * (1.0f + (0.5f * _766))) / _747);\n    float _877 = ((_695_fa_shadow_info[ci].x * min(_766, 3.0f)) * 0.5f) / _747;\n    int _886 = int(_695_fa_shadow_cfg.z + 0.5f);\n    if (_886 == 1)\n    {\n        float2 param = _796.xy;\n        float4 param_1 = _695_fa_shadow_rect[ci];\n        float _897 = fa_shadow_depth(param, param_1);\n        return float(_868 <= _897);\n    }\n    float _904 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _907 = _886 == 2;\n    if (_907)\n    {\n        float _921 = clamp(((_695_fa_shadow_cfg.w * _747) * 0.25f) / _695_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _904;\n            float2 _940 = fa_shadow_vogel(param_2, param_3, param_4) * _921;\n            float2 param_5 = _796.xy + (_940 * _695_fa_shadow_bias.zw);\n            float4 param_6 = _695_fa_shadow_rect[ci];\n            float _951 = fa_shadow_depth(param_5, param_6);\n            if (_951 < (_868 - (length(_940) * _877)))\n            {\n                sum += _951;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_868 - (sum / cnt), 0.0f) * _747) * _695_fa_shadow_cfg.w) / _695_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _995 = _907 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _995; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _995;\n        float param_9 = _904;\n        float2 _1014 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _796.xy + (_1014 * _695_fa_shadow_bias.zw);\n        float4 param_11 = _695_fa_shadow_rect[ci];\n        float _1025 = fa_shadow_depth(param_10, param_11);\n        lit += float((_868 - (length(_1014) * _877)) <= _1025);\n    }\n    return lit / float(_995);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_459_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1055 = int(_695_fa_shadow_cfg.x + 0.5f);\n    if (_1055 < 1)\n    {\n        return 1.0f;\n    }\n    float _1071 = dot(world - _695_fa_shadow_eye.xyz, _695_fa_shadow_fwd.xyz);\n    int param = _1055 - 1;\n    if (_1071 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1083 = _1055 > 1;\n    bool _1090;\n    if (_1083)\n    {\n        _1090 = _1071 > _695_fa_shadow_split.x;\n    }\n    else\n    {\n        _1090 = _1083;\n    }\n    if (_1090)\n    {\n        ci = 1;\n    }\n    bool _1094 = _1055 > 2;\n    bool _1101;\n    if (_1094)\n    {\n        _1101 = _1071 > _695_fa_shadow_split.y;\n    }\n    else\n    {\n        _1101 = _1094;\n    }\n    if (_1101)\n    {\n        ci = 2;\n    }\n    bool _1105 = _1055 > 3;\n    bool _1112;\n    if (_1105)\n    {\n        _1112 = _1071 > _695_fa_shadow_split.z;\n    }\n    else\n    {\n        _1112 = _1105;\n    }\n    if (_1112)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1055)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1138 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1138;\n        if (_1138 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_695_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1163;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1163 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1163 = _695_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1182 = _695_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1163, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1193 = clamp((_1071 - (fa_shadow_split_at(param_7) - _1182)) / _1182, 0.0f, 1.0f);\n        if (_1193 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1055)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1214 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1214;\n                if (_1214 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1193);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _2436 = fa_light_sample(param, param_1);\n    float3 _3637 = _2436.direction;\n    float3 _3632 = _2436.color;\n    float _3634 = _2436.shadow;\n    int _3642 = _2436.type;\n    if ((_3642 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _3637;\n        float _2450 = fa_shadow_factor(param_2, param_3);\n        _3634 = _2450;\n        _3632 *= _2450;\n    }\n    LightSample _3649 = { _3637, _3632, _2436.attenuation, _3634, _2436._distance, _3642 };\n    return _3649;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _2051 = tdh / at;\n    float _2055 = bdh / ab;\n    float _2067 = ((_2051 * _2051) + (_2055 * _2055)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _2067) * _2067);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _2148 = 1.0f / alpha;\n    return ((2.0f + _2148) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _2148)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _2181 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _2260 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _2260) * _2260);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _2181);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _2181));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        float _2333 = max(dot(L.nc, l), 0.0f);\n        float _2339 = max(dot(L.nc, h), 0.0f);\n        float _2348 = ((_2339 * _2339) * (L.coat_a2 - 1.0f)) + 1.0f;\n        result += ((((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _2348) * _2348)) * (0.5f / max(lerp((2.0f * _2333) * L.coat_ndv, _2333 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _2333)) * _2333).xxx;\n    }\n    return result;\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _1446 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _1449 = _1446.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_1449 * _1449, exp2((-9.27999973297119140625f) * ndv)) * _1449) + _1446.y)) + _1446.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_459_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _459_fa_env_horizon.w).xyz;\n    }\n    float _1351 = rough * rough;\n    float _1381 = 0.60000002384185791015625f * _1351;\n    return lerp(lerp(_459_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_459_fa_env_horizon.xyz, _459_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _1351)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _1381, 0.0500000007450580596923828125f + _1381, d.y).xxx), ((_459_fa_env_sky.xyz + _459_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_1351 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _1934;\n        if (L.aniso >= 0.0f)\n        {\n            _1934 = L.b;\n        }\n        else\n        {\n            _1934 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_1934, v), _1934), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1967 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _1967.x) + (L.f90.xxx * _1967.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2022 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _2022.x) + _2022.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1488 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1488.x) + _1488.y.xxx);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_695_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1238 = int(_695_fa_shadow_cfg.x + 0.5f);\n    float _1248 = dot(world - _695_fa_shadow_eye.xyz, _695_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1253 = _1238 > 0;\n    bool _1262;\n    if (_1253)\n    {\n        int param = _1238 - 1;\n        _1262 = _1248 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1262 = _1253;\n    }\n    if (_1262)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1269 = _1238 > 1;\n        bool _1276;\n        if (_1269)\n        {\n            _1276 = _1248 > _695_fa_shadow_split.x;\n        }\n        else\n        {\n            _1276 = _1269;\n        }\n        if (_1276)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1282 = _1238 > 2;\n        bool _1289;\n        if (_1282)\n        {\n            _1289 = _1248 > _695_fa_shadow_split.y;\n        }\n        else\n        {\n            _1289 = _1282;\n        }\n        if (_1289)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1295 = _1238 > 3;\n        bool _1302;\n        if (_1295)\n        {\n            _1302 = _1248 > _695_fa_shadow_split.z;\n        }\n        else\n        {\n            _1302 = _1295;\n        }\n        if (_1302)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _3367 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3367 = -_3367;\n    }\n    float3 _2821 = normalize(_459_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _3380 = { fa_world_pos, _3367, fa_world_tangent, fa_uv, fa_vertex_color, _2821, gl_FrontFacing };\n    SurfaceInput param_1 = _3380;\n    Surface _2829 = fa_standard_surface(param_1);\n    float3 _3398 = _2829.albedo;\n    float _3399 = _2829.alpha;\n    float3 _3400 = _2829.normal;\n    float _3401 = _2829.metallic;\n    float _3402 = _2829.roughness;\n    float _3403 = _2829.occlusion;\n    float3 _3404 = _2829.emission;\n    float _3405 = _2829.clearcoat;\n    float _3406 = _2829.clearcoat_roughness;\n    float3 _3407 = _2829.sheen_color;\n    float _3408 = _2829.sheen_roughness;\n    float _3409 = _2829.anisotropy;\n    float _3410 = _2829.anisotropy_rotation;\n    float _3411 = _2829.specular;\n    float _3412 = _2829.ior;\n    float3 _3413 = _2829.specular_color;\n    SurfaceInput _3388 = { fa_world_pos, _3367, fa_world_tangent, fa_uv, fa_vertex_color, _2821, gl_FrontFacing };\n    SurfaceInput param_2 = _3388;\n    Surface param_3 = _2829;\n    surface(param_2, param_3);\n    _3398 = param_3.albedo;\n    _3399 = param_3.alpha;\n    _3400 = param_3.normal;\n    _3401 = param_3.metallic;\n    _3402 = param_3.roughness;\n    _3403 = param_3.occlusion;\n    _3404 = param_3.emission;\n    _3405 = param_3.clearcoat;\n    _3406 = param_3.clearcoat_roughness;\n    _3407 = param_3.sheen_color;\n    _3408 = param_3.sheen_roughness;\n    _3409 = param_3.anisotropy;\n    _3410 = param_3.anisotropy_rotation;\n    _3411 = param_3.specular;\n    _3412 = param_3.ior;\n    _3413 = param_3.specular_color;\n    float3 result;\n    if (_459_fa_emissive.w > 0.5f)\n    {\n        result = _3398;\n    }\n    else\n    {\n        float3 _2851 = normalize(_3400);\n        float _2858 = clamp(_3401, 0.0f, 1.0f);\n        float _2862 = clamp(_3402, 0.0500000007450580596923828125f, 1.0f);\n        float _2866 = _2862 * _2862;\n        float _2870 = _2866 * _2866;\n        float _2875 = max(dot(_2851, _2821), 9.9999997473787516355514526367188e-05f);\n        float3 _2881 = _3398 * (1.0f - _2858);\n        float3 _2888 = lerp(0.039999999105930328369140625f.xxx, _3398, _2858.xxx);\n        float3 f0 = _2888;\n        SurfaceInput _3396 = { fa_world_pos, _3367, fa_world_tangent, fa_uv, fa_vertex_color, _2821, gl_FrontFacing };\n        SurfaceInput param_4 = _3396;\n        Surface _3479 = { _3398, _3399, _3400, _3401, _3402, _3403, _3404, _3405, _3406, _3407, _3408, _3409, _3410, _3411, _3412, _3413 };\n        Surface param_5 = _3479;\n        float3 param_6 = _2851;\n        float3 param_7 = _2821;\n        float param_8 = _2858;\n        float param_9 = _2862;\n        float3 param_10 = _2888;\n        FaLayers _2904 = fa_layers_setup(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        f0 = param_10;\n        float3 param_11 = _2851;\n        float3 lit = (fa_ambient_light(param_11) * _2881) * _3403;\n        if (_2904.on)\n        {\n            lit *= _2904.base_scale;\n        }\n        int _2926 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2926; ln++)\n        {\n            int param_12 = ln;\n            int _2939 = fa_cl_light(param_12);\n            int param_13 = _2939;\n            float3 param_14 = fa_world_pos;\n            float3 param_15 = _3367;\n            LightSample _2948 = fa_light_shadowed(param_13, param_14, param_15);\n            float3 _3572 = _2948.direction;\n            float _2956 = max(dot(_2851, _3572), 0.0f);\n            float _2962 = _2948.attenuation * _2948.shadow;\n            float3 _2967 = normalize(_3572 + _2821);\n            float _2972 = max(dot(_2851, _2967), 0.0f);\n            float _2977 = max(dot(_2821, _2967), 0.0f);\n            if (_2904.on)\n            {\n                FaLayers param_16 = _2904;\n                float3 param_17 = _2881;\n                float3 param_18 = f0;\n                float3 param_19 = _2851;\n                float3 param_20 = _2821;\n                float3 param_21 = _3572;\n                float3 param_22 = _2967;\n                float param_23 = _2956;\n                float param_24 = _2875;\n                float param_25 = _2972;\n                float param_26 = _2977;\n                float param_27 = _2866;\n                float param_28 = _2870;\n                int param_29 = _2939;\n                lit += (fa_layers_light(param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28) * (fa_light_rgb(param_29) * _2962));\n            }\n            else\n            {\n                float _3025 = ((_2972 * _2972) * (_2870 - 1.0f)) + 1.0f;\n                int param_30 = _2939;\n                lit += (((_2881 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _2977, 5.0f))) * (((_2870 / ((3.1415927410125732421875f * _3025) * _3025)) * (0.5f / max(lerp((2.0f * _2956) * _2875, _2956 + _2875, _2866), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _2956))) * fa_light_rgb(param_30)) * (_2956 * _2962));\n            }\n        }\n        if (_2904.on)\n        {\n            FaLayers param_31 = _2904;\n            float3 param_32 = _2851;\n            float3 param_33 = _2821;\n            float3 param_34 = f0;\n            float param_35 = _2862;\n            lit += (fa_layers_ibl(param_31, param_32, param_33, param_34, param_35) * _3403);\n        }\n        else\n        {\n            float3 param_36 = _2851;\n            float3 param_37 = _2821;\n            float3 param_38 = f0;\n            float param_39 = _2862;\n            lit += (fa_sky_reflection(param_36, param_37, param_38, param_39) * _3403);\n        }\n        result = lit;\n    }\n    float3 _3118 = result;\n    float3 _3119 = _3118 + _3404;\n    result = _3119;\n    float3 param_40 = _3119;\n    float3 param_41 = fa_world_pos;\n    result = fa_shadow_debug(param_40, param_41);\n    bool _3128 = _459_fa_fog.w > 0.0f;\n    bool _3135;\n    if (!_3128)\n    {\n        _3135 = _459_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _3135 = _3128;\n    }\n    if (_3135)\n    {\n        float3 _3144 = fa_world_pos - _459_fa_camera_pos.xyz;\n        float _3150 = dot(_3144, _459_fa_fog_c.xyz);\n        bool _3154 = _459_fa_fog_c.w > 0.5f;\n        float _3155;\n        if (_3154)\n        {\n            _3155 = _3150;\n        }\n        else\n        {\n            _3155 = length(_3144);\n        }\n        float _3167 = _3155 - _459_fa_fog_b.x;\n        if (_3167 > 0.0f)\n        {\n            float _3176 = _459_fa_fog.w * _3167;\n            float tau = _3176 * _3176;\n            if (_459_fa_fog_b.y > 0.0f)\n            {\n                float _3192;\n                if (_3154)\n                {\n                    _3192 = fa_world_pos.y - (_459_fa_fog_c.y * _3150);\n                }\n                else\n                {\n                    _3192 = _459_fa_camera_pos.y;\n                }\n                float _3213 = lerp(_3192, fa_world_pos.y, clamp(_459_fa_fog_b.x / _3155, 0.0f, 1.0f));\n                float _3217 = fa_world_pos.y - _3213;\n                float _3222 = _3213 - _459_fa_fog_b.z;\n                float _3227 = fa_world_pos.y - _459_fa_fog_b.z;\n                bool _3230 = _3222 <= 0.0f;\n                bool _3231 = !_3230;\n                bool _3237;\n                if (_3231)\n                {\n                    _3237 = _459_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3237 = _3230;\n                }\n                float _3238;\n                if (_3237)\n                {\n                    _3238 = _459_fa_fog_b.y;\n                }\n                else\n                {\n                    _3238 = _459_fa_fog_b.y * exp(-min(_459_fa_fog_b.w * _3222, 80.0f));\n                }\n                bool _3265;\n                if (_3231)\n                {\n                    _3265 = _459_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3265 = _3230;\n                }\n                float _3266;\n                if (_3265)\n                {\n                    _3266 = _459_fa_fog_b.y * _3222;\n                }\n                else\n                {\n                    _3266 = (_459_fa_fog_b.y * (1.0f - exp(-min(_459_fa_fog_b.w * _3222, 80.0f)))) / _459_fa_fog_b.w;\n                }\n                bool _3291 = _3227 <= 0.0f;\n                bool _3298;\n                if (!_3291)\n                {\n                    _3298 = _459_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3298 = _3291;\n                }\n                float _3299;\n                if (_3298)\n                {\n                    _3299 = _459_fa_fog_b.y * _3227;\n                }\n                else\n                {\n                    _3299 = (_459_fa_fog_b.y * (1.0f - exp(-min(_459_fa_fog_b.w * _3227, 80.0f)))) / _459_fa_fog_b.w;\n                }\n                float _3326;\n                if (abs(_3217) < 0.001000000047497451305389404296875f)\n                {\n                    _3326 = _3238;\n                }\n                else\n                {\n                    _3326 = (_3299 - _3266) / _3217;\n                }\n                tau += (_3167 * max(_3326, 0.0f));\n            }\n            result = lerp(result, _459_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _3399);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_131",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_459",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_695",
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
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
              "multisampled": false,
              "type": "cube",
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 8,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _379 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _379;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _386 = _273.world_pos;\n    fa_world_pos = _386;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_386, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _1589[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _459_fa_camera_pos : packoffset(c0);\n    float4 _459_fa_ambient : packoffset(c1);\n    float4 _459_fa_base_color : packoffset(c2);\n    float4 _459_fa_emissive : packoffset(c3);\n    float4 _459_fa_model_emissive : packoffset(c4);\n    float4 _459_fa_pbr : packoffset(c5);\n    float4 _459_fa_maps : packoffset(c6);\n    float4 _459_fa_fog : packoffset(c7);\n    float4 _459_fa_fog_b : packoffset(c8);\n    float4 _459_fa_fog_c : packoffset(c9);\n    float4 _459_fa_counts : packoffset(c10);\n    float4 _459_fa_env_sky : packoffset(c11);\n    float4 _459_fa_env_horizon : packoffset(c12);\n    float4 _459_fa_time : packoffset(c13);\n    float4 _459_fa_cl_vpx : packoffset(c14);\n    float4 _459_fa_cl_vpy : packoffset(c15);\n    float4 _459_fa_cl_vpw : packoffset(c16);\n    float4 _459_fa_cl_fwd : packoffset(c17);\n    float4 _459_fa_cl_grid : packoffset(c18);\n    float4 _459_fa_cl_info : packoffset(c19);\n    float4 _459_fa_layers_a : packoffset(c20);\n    float4 _459_fa_layers_b : packoffset(c21);\n    float4 _459_fa_layers_c : packoffset(c22);\n    float4 _459_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _695_fa_shadow_mat[4] : packoffset(c0);\n    float4 _695_fa_shadow_rect[4] : packoffset(c16);\n    float4 _695_fa_shadow_info[4] : packoffset(c20);\n    float4 _695_fa_shadow_split : packoffset(c24);\n    float4 _695_fa_shadow_cfg : packoffset(c25);\n    float4 _695_fa_shadow_bias : packoffset(c26);\n    float4 _695_fa_shadow_eye : packoffset(c27);\n    float4 _695_fa_shadow_fwd : packoffset(c28);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _464 = _459_fa_cl_info.x < 0.0f;\n    bool _471;\n    if (!_464)\n    {\n        _471 = _459_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _471 = _464;\n    }\n    bool _479;\n    if (!_471)\n    {\n        _479 = _459_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _479 = _471;\n    }\n    bool _486;\n    if (!_479)\n    {\n        _486 = _459_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _486 = _479;\n    }\n    bool _493;\n    if (!_486)\n    {\n        _493 = _459_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _493 = _486;\n    }\n    if (_493)\n    {\n        return int2(0, 0);\n    }\n    float4 _503 = float4(world_pos, 1.0f);\n    float _510 = dot(_459_fa_cl_vpw, _503);\n    if (!(_510 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _532 = float2(dot(_459_fa_cl_vpx, _503), dot(_459_fa_cl_vpy, _503)) / _510.xx;\n    int _536 = int(_459_fa_cl_grid.x);\n    int _540 = int(_459_fa_cl_grid.y);\n    int param = (int(_459_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_459_fa_cl_fwd.xyz, world_pos) + _459_fa_cl_fwd.w, _459_fa_cl_grid.w) / _459_fa_cl_grid.w) * _459_fa_cl_grid.z)), 0, int(_459_fa_cl_info.y) - 1) * _540) + clamp(int(floor(((_532.y * 0.5f) + 0.5f) * _459_fa_cl_grid.y)), 0, _540 - 1)) * _536)) + clamp(int(floor(((_532.x * 0.5f) + 0.5f) * _459_fa_cl_grid.x)), 0, _536 - 1);\n    float4 _611 = fa_light_texel(param);\n    return int2(int(_611.x), int(_611.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_459_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2408 = fa_cluster_lookup(param);\n    fa_cl_slot = _2408.x;\n    fa_cl_local = _2408.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _2508 = fa_linear_to_srgb(param);\n        c = _2508;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _2516 = fa_srgb_to_linear(param_1);\n            c = _2516;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _231;\n    if (i.front_facing)\n    {\n        _231 = i.world_normal;\n    }\n    else\n    {\n        _231 = -i.world_normal;\n    }\n    float3 _255 = normalize(i.world_tangent.xyz - (_231 * dot(_231, i.world_tangent.xyz)));\n    float3 _283 = normalize(((_255 * m.x) + ((cross(_231, _255) * i.world_tangent.w) * m.y)) + (_231 * m.z));\n    float3 _286;\n    if (i.front_facing)\n    {\n        _286 = _283;\n    }\n    else\n    {\n        _286 = -_283;\n    }\n    return _286;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _459_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2547 = fa_tex_fix(param_2, param_3);\n    float4 _3718 = base_t;\n    _3718.x = _2547.x;\n    _3718.y = _2547.y;\n    _3718.z = _2547.z;\n    base_t = _3718;\n    float4 _2561 = (_3718 * _459_fa_base_color) * i.vertex_color;\n    float3 _3652 = i.world_normal;\n    if (_459_fa_maps.z > 0.5f)\n    {\n        float param_4 = _459_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2593 = fa_tex_fix(param_6, param_7);\n        float3 _2596 = (_2593 * 2.0f) - 1.0f.xxx;\n        float2 _2601 = _2596.xy * _459_fa_maps.x;\n        float3 _3726 = _2596;\n        _3726.x = _2601.x;\n        _3726.y = _2601.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3726;\n        _3652 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _459_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2630 = fa_tex_fix(param_12, param_13);\n    float4 _3729 = mrt;\n    _3729.x = _2630.x;\n    _3729.y = _2630.y;\n    _3729.z = _2630.z;\n    mrt = _3729;\n    float4 _2658 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _459_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _2658.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2670 = fa_tex_fix(param_16, param_17);\n    float param_18 = _459_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2700 = fa_tex_fix(param_20, param_21);\n    float _3657 = _459_fa_layers_a.x;\n    float _3658 = _459_fa_layers_a.y;\n    float _3661 = _459_fa_layers_a.z;\n    float _3660 = _459_fa_layers_b.w;\n    float _3663 = _459_fa_layers_c.x;\n    if (_459_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_459_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _3657 *= _2670.y;\n            _3658 *= _2670.z;\n            _3660 *= _2658.w;\n        }\n        if (_459_fa_layers_c.z > 1.5f)\n        {\n            _3661 *= mrt.x;\n            _3663 *= mrt.w;\n        }\n    }\n    Surface _3682 = { _2561.xyz, _2561.w, _3652, clamp(_459_fa_pbr.x * _2630.z, 0.0f, 1.0f), clamp(_459_fa_pbr.y * _2630.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_459_fa_maps.y * (_2670.x - 1.0f)), _459_fa_emissive.xyz + (_459_fa_model_emissive.xyz * _2700), _3657, _3658, _459_fa_layers_b.xyz, _3660, _3661, _459_fa_layers_a.w, _3663, _459_fa_layers_c.y, _459_fa_layers_d.xyz };\n    return _3682;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1514 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _1522 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _1525 = int(_1514);\n    int _1528 = int(_1522);\n    float _1538 = _1522 - float(_1528);\n    int _1594 = (_1525 * 9) + _1528;\n    int _1614 = ((_1525 + 1) * 9) + _1528;\n    return lerp(lerp(_1589[_1594], _1589[_1594 + 1], _1538), lerp(_1589[_1614], _1589[_1614 + 1], _1538), _1514 - float(_1525));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _3588 = false;\n    float _3589 = 1.0f;\n    float _3590 = 1.0f;\n    float _3591 = 1.0f;\n    float _3592 = 0.0f;\n    float _3593 = 0.0f;\n    float _3594 = 0.0f;\n    float _3595 = 0.0f;\n    float _3597 = 1.0f;\n    bool _3598 = false;\n    float3 _3599 = 0.0f.xxx;\n    float _3600 = 1.0f;\n    float _3601 = 1.0f;\n    float _3602 = 1.0f;\n    float _3603 = 0.0f;\n    float _3604 = 0.0f;\n    float3 _3605 = float3(1.0f, 0.0f, 0.0f);\n    float3 _3606 = float3(0.0f, 0.0f, 1.0f);\n    float _3607 = 1.0f;\n    float _3608 = 1.0f;\n    float _1669 = clamp(s.specular, 0.0f, 1.0f);\n    float _1673 = clamp(s.ior, 1.0f, 3.0f);\n    bool _1678 = (_1669 != 1.0f) || (_1673 != 1.5f);\n    bool _1688;\n    if (!_1678)\n    {\n        _1688 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _1688 = _1678;\n    }\n    if (_1688)\n    {\n        float _1696 = (_1673 - 1.0f) / (_1673 + 1.0f);\n        f0 = lerp(min((_1696 * _1696).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _1669, s.albedo, metallic.xxx);\n        _3589 = lerp(_1669, 1.0f, metallic);\n        _3588 = true;\n    }\n    float _1724 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_1724 > 0.0f)\n    {\n        float _1732 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _3592 = _1724;\n        _3593 = _1732;\n        float _1739 = _1732 * _1732;\n        _3594 = _1739;\n        _3595 = _1739 * _1739;\n        float _1751 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _3597 = _1751;\n        _3590 = 1.0f - (_1724 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _1751, 0.0f, 1.0f), 5.0f))));\n        _3588 = true;\n    }\n    float3 _1771 = max(s.sheen_color, 0.0f.xxx);\n    float _1780 = max(_1771.x, max(_1771.y, _1771.z));\n    if (_1780 > 0.0f)\n    {\n        float _1788 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _3598 = true;\n        _3599 = _1771;\n        _3600 = _1788;\n        _3601 = _1788 * _1788;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _1788;\n        float _1805 = fa_sheen_albedo(param, param_1);\n        _3603 = _1805;\n        _3602 = 1.0f - min(_1780 * _1805, 1.0f);\n        _3588 = true;\n    }\n    _3591 = _3590 * _3602;\n    float _1824 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_1824 != 0.0f)\n    {\n        float3 _1839 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _1839;\n        if (dot(_1839, _1839) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _1853 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_1853.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _1853.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _1853.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _1857 = t;\n        float3 _1858 = normalize(_1857);\n        t = _1858;\n        float3 _1883 = normalize((_1858 * cos(s.anisotropy_rotation)) + ((cross(n, _1858) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _3605 = _1883;\n        _3606 = cross(n, _1883);\n        float _1893 = roughness * roughness;\n        float _1899 = lerp(_1893, 1.0f, _1824 * _1824);\n        bool _1901 = _1824 > 0.0f;\n        _3607 = _1901 ? _1899 : _1893;\n        _3608 = _1901 ? _1893 : _1899;\n        _3604 = _1824;\n        _3588 = true;\n    }\n    FaLayers _3630 = { _3588, _3589, _3590, _3591, _3592, _3593, _3594, _3595, i.world_normal, _3597, _3598, _3599, _3600, _3601, _3602, _3603, _3604, _3605, _3606, _3607, _3608 };\n    return _3630;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_459_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _459_fa_ambient.xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_459_fa_cl_info.x) + int(_459_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _331 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _337 = fa_light_texel(param_1);\n    float _340 = _337.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _347 = _340 < 0.5f;\n    float3 l;\n    if (_347)\n    {\n        l = normalize(_331.xyz);\n    }\n    else\n    {\n        float3 _359 = _331.xyz - world_pos;\n        float _361 = length(_359);\n        dist = _361;\n        l = _359 / max(_361, 9.9999997473787516355514526367188e-05f).xxx;\n        float _376 = _361 / max(_331.w, 0.001000000047497451305389404296875f);\n        float _382 = clamp(1.0f - (_376 * _376), 0.0f, 1.0f);\n        atten = _382 * _382;\n        if (_340 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _396 = fa_light_texel(param_2);\n            float _406 = _396.w;\n            int param_3 = (li * 4) + 3;\n            float4 _413 = fa_light_texel(param_3);\n            float _414 = _413.x;\n            float cos_inner = _414;\n            if (_414 > 1.5f)\n            {\n                cos_inner = lerp(_406, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_406, cos_inner, dot(-l, normalize(_396.xyz)));\n        }\n    }\n    int _445;\n    if (_347)\n    {\n        _445 = 0;\n    }\n    else\n    {\n        _445 = (_340 > 1.5f) ? 2 : 1;\n    }\n    LightSample _3587 = { l, _337.xyz * atten, atten, 1.0f, dist, _445 };\n    return _3587;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _685;\n    if (i == 0)\n    {\n        _685 = _695_fa_shadow_split.x;\n    }\n    else\n    {\n        float _701;\n        if (i == 1)\n        {\n            _701 = _695_fa_shadow_split.y;\n        }\n        else\n        {\n            float _709;\n            if (i == 2)\n            {\n                _709 = _695_fa_shadow_split.z;\n            }\n            else\n            {\n                _709 = _695_fa_shadow_split.w;\n            }\n            _701 = _709;\n        }\n        _685 = _701;\n    }\n    return _685;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _673 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_673), sin(_673)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _747 = max(_695_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _752 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _758 = sqrt(1.0f - (_752 * _752));\n    float _766 = min(_758 / max(_752, 0.20000000298023223876953125f), 4.0f);\n    float _771;\n    if (_695_fa_shadow_bias.y > 0.0f)\n    {\n        _771 = _695_fa_shadow_bias.y;\n    }\n    else\n    {\n        _771 = 1.5f * _695_fa_shadow_info[ci].x;\n    }\n    float4 _796 = mul(float4(world + (n * (_771 * _758)), 1.0f), _695_fa_shadow_mat[ci]);\n    float _803 = _796.x;\n    bool _806 = _803 < _695_fa_shadow_rect[ci].x;\n    bool _815;\n    if (!_806)\n    {\n        _815 = _803 > _695_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _815 = _806;\n    }\n    bool _824;\n    if (!_815)\n    {\n        _824 = _796.y < _695_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _824 = _815;\n    }\n    bool _833;\n    if (!_824)\n    {\n        _833 = _796.y > _695_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _833 = _824;\n    }\n    bool _840;\n    if (!_833)\n    {\n        _840 = _796.z > 1.0f;\n    }\n    else\n    {\n        _840 = _833;\n    }\n    if (_840)\n    {\n        return -1.0f;\n    }\n    float _849;\n    if (_695_fa_shadow_bias.x > 0.0f)\n    {\n        _849 = _695_fa_shadow_bias.x;\n    }\n    else\n    {\n        _849 = 1.5f * _695_fa_shadow_info[ci].x;\n    }\n    float _868 = _796.z - ((_849 * (1.0f + (0.5f * _766))) / _747);\n    float _877 = ((_695_fa_shadow_info[ci].x * min(_766, 3.0f)) * 0.5f) / _747;\n    int _886 = int(_695_fa_shadow_cfg.z + 0.5f);\n    if (_886 == 1)\n    {\n        float2 param = _796.xy;\n        float4 param_1 = _695_fa_shadow_rect[ci];\n        float _897 = fa_shadow_depth(param, param_1);\n        return float(_868 <= _897);\n    }\n    float _904 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _907 = _886 == 2;\n    if (_907)\n    {\n        float _921 = clamp(((_695_fa_shadow_cfg.w * _747) * 0.25f) / _695_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _904;\n            float2 _940 = fa_shadow_vogel(param_2, param_3, param_4) * _921;\n            float2 param_5 = _796.xy + (_940 * _695_fa_shadow_bias.zw);\n            float4 param_6 = _695_fa_shadow_rect[ci];\n            float _951 = fa_shadow_depth(param_5, param_6);\n            if (_951 < (_868 - (length(_940) * _877)))\n            {\n                sum += _951;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_868 - (sum / cnt), 0.0f) * _747) * _695_fa_shadow_cfg.w) / _695_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _995 = _907 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _995; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _995;\n        float param_9 = _904;\n        float2 _1014 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _796.xy + (_1014 * _695_fa_shadow_bias.zw);\n        float4 param_11 = _695_fa_shadow_rect[ci];\n        float _1025 = fa_shadow_depth(param_10, param_11);\n        lit += float((_868 - (length(_1014) * _877)) <= _1025);\n    }\n    return lit / float(_995);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_459_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1055 = int(_695_fa_shadow_cfg.x + 0.5f);\n    if (_1055 < 1)\n    {\n        return 1.0f;\n    }\n    float _1071 = dot(world - _695_fa_shadow_eye.xyz, _695_fa_shadow_fwd.xyz);\n    int param = _1055 - 1;\n    if (_1071 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1083 = _1055 > 1;\n    bool _1090;\n    if (_1083)\n    {\n        _1090 = _1071 > _695_fa_shadow_split.x;\n    }\n    else\n    {\n        _1090 = _1083;\n    }\n    if (_1090)\n    {\n        ci = 1;\n    }\n    bool _1094 = _1055 > 2;\n    bool _1101;\n    if (_1094)\n    {\n        _1101 = _1071 > _695_fa_shadow_split.y;\n    }\n    else\n    {\n        _1101 = _1094;\n    }\n    if (_1101)\n    {\n        ci = 2;\n    }\n    bool _1105 = _1055 > 3;\n    bool _1112;\n    if (_1105)\n    {\n        _1112 = _1071 > _695_fa_shadow_split.z;\n    }\n    else\n    {\n        _1112 = _1105;\n    }\n    if (_1112)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1055)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1138 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1138;\n        if (_1138 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_695_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1163;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1163 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1163 = _695_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1182 = _695_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1163, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1193 = clamp((_1071 - (fa_shadow_split_at(param_7) - _1182)) / _1182, 0.0f, 1.0f);\n        if (_1193 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1055)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1214 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1214;\n                if (_1214 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1193);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _2436 = fa_light_sample(param, param_1);\n    float3 _3637 = _2436.direction;\n    float3 _3632 = _2436.color;\n    float _3634 = _2436.shadow;\n    int _3642 = _2436.type;\n    if ((_3642 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _3637;\n        float _2450 = fa_shadow_factor(param_2, param_3);\n        _3634 = _2450;\n        _3632 *= _2450;\n    }\n    LightSample _3649 = { _3637, _3632, _2436.attenuation, _3634, _2436._distance, _3642 };\n    return _3649;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _2051 = tdh / at;\n    float _2055 = bdh / ab;\n    float _2067 = ((_2051 * _2051) + (_2055 * _2055)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _2067) * _2067);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _2148 = 1.0f / alpha;\n    return ((2.0f + _2148) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _2148)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _2181 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _2260 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _2260) * _2260);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _2181);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _2181));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        float _2333 = max(dot(L.nc, l), 0.0f);\n        float _2339 = max(dot(L.nc, h), 0.0f);\n        float _2348 = ((_2339 * _2339) * (L.coat_a2 - 1.0f)) + 1.0f;\n        result += ((((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _2348) * _2348)) * (0.5f / max(lerp((2.0f * _2333) * L.coat_ndv, _2333 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _2333)) * _2333).xxx;\n    }\n    return result;\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _1446 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _1449 = _1446.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_1449 * _1449, exp2((-9.27999973297119140625f) * ndv)) * _1449) + _1446.y)) + _1446.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_459_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _459_fa_env_horizon.w).xyz;\n    }\n    float _1351 = rough * rough;\n    float _1381 = 0.60000002384185791015625f * _1351;\n    return lerp(lerp(_459_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_459_fa_env_horizon.xyz, _459_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _1351)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _1381, 0.0500000007450580596923828125f + _1381, d.y).xxx), ((_459_fa_env_sky.xyz + _459_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_1351 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _1934;\n        if (L.aniso >= 0.0f)\n        {\n            _1934 = L.b;\n        }\n        else\n        {\n            _1934 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_1934, v), _1934), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1967 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _1967.x) + (L.f90.xxx * _1967.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2022 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _2022.x) + _2022.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1488 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1488.x) + _1488.y.xxx);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_695_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1238 = int(_695_fa_shadow_cfg.x + 0.5f);\n    float _1248 = dot(world - _695_fa_shadow_eye.xyz, _695_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1253 = _1238 > 0;\n    bool _1262;\n    if (_1253)\n    {\n        int param = _1238 - 1;\n        _1262 = _1248 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1262 = _1253;\n    }\n    if (_1262)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1269 = _1238 > 1;\n        bool _1276;\n        if (_1269)\n        {\n            _1276 = _1248 > _695_fa_shadow_split.x;\n        }\n        else\n        {\n            _1276 = _1269;\n        }\n        if (_1276)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1282 = _1238 > 2;\n        bool _1289;\n        if (_1282)\n        {\n            _1289 = _1248 > _695_fa_shadow_split.y;\n        }\n        else\n        {\n            _1289 = _1282;\n        }\n        if (_1289)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1295 = _1238 > 3;\n        bool _1302;\n        if (_1295)\n        {\n            _1302 = _1248 > _695_fa_shadow_split.z;\n        }\n        else\n        {\n            _1302 = _1295;\n        }\n        if (_1302)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _3367 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3367 = -_3367;\n    }\n    float3 _2821 = normalize(_459_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _3380 = { fa_world_pos, _3367, fa_world_tangent, fa_uv, fa_vertex_color, _2821, gl_FrontFacing };\n    SurfaceInput param_1 = _3380;\n    Surface _2829 = fa_standard_surface(param_1);\n    float3 _3398 = _2829.albedo;\n    float _3399 = _2829.alpha;\n    float3 _3400 = _2829.normal;\n    float _3401 = _2829.metallic;\n    float _3402 = _2829.roughness;\n    float _3403 = _2829.occlusion;\n    float3 _3404 = _2829.emission;\n    float _3405 = _2829.clearcoat;\n    float _3406 = _2829.clearcoat_roughness;\n    float3 _3407 = _2829.sheen_color;\n    float _3408 = _2829.sheen_roughness;\n    float _3409 = _2829.anisotropy;\n    float _3410 = _2829.anisotropy_rotation;\n    float _3411 = _2829.specular;\n    float _3412 = _2829.ior;\n    float3 _3413 = _2829.specular_color;\n    SurfaceInput _3388 = { fa_world_pos, _3367, fa_world_tangent, fa_uv, fa_vertex_color, _2821, gl_FrontFacing };\n    SurfaceInput param_2 = _3388;\n    Surface param_3 = _2829;\n    surface(param_2, param_3);\n    _3398 = param_3.albedo;\n    _3399 = param_3.alpha;\n    _3400 = param_3.normal;\n    _3401 = param_3.metallic;\n    _3402 = param_3.roughness;\n    _3403 = param_3.occlusion;\n    _3404 = param_3.emission;\n    _3405 = param_3.clearcoat;\n    _3406 = param_3.clearcoat_roughness;\n    _3407 = param_3.sheen_color;\n    _3408 = param_3.sheen_roughness;\n    _3409 = param_3.anisotropy;\n    _3410 = param_3.anisotropy_rotation;\n    _3411 = param_3.specular;\n    _3412 = param_3.ior;\n    _3413 = param_3.specular_color;\n    float3 result;\n    if (_459_fa_emissive.w > 0.5f)\n    {\n        result = _3398;\n    }\n    else\n    {\n        float3 _2851 = normalize(_3400);\n        float _2858 = clamp(_3401, 0.0f, 1.0f);\n        float _2862 = clamp(_3402, 0.0500000007450580596923828125f, 1.0f);\n        float _2866 = _2862 * _2862;\n        float _2870 = _2866 * _2866;\n        float _2875 = max(dot(_2851, _2821), 9.9999997473787516355514526367188e-05f);\n        float3 _2881 = _3398 * (1.0f - _2858);\n        float3 _2888 = lerp(0.039999999105930328369140625f.xxx, _3398, _2858.xxx);\n        float3 f0 = _2888;\n        SurfaceInput _3396 = { fa_world_pos, _3367, fa_world_tangent, fa_uv, fa_vertex_color, _2821, gl_FrontFacing };\n        SurfaceInput param_4 = _3396;\n        Surface _3479 = { _3398, _3399, _3400, _3401, _3402, _3403, _3404, _3405, _3406, _3407, _3408, _3409, _3410, _3411, _3412, _3413 };\n        Surface param_5 = _3479;\n        float3 param_6 = _2851;\n        float3 param_7 = _2821;\n        float param_8 = _2858;\n        float param_9 = _2862;\n        float3 param_10 = _2888;\n        FaLayers _2904 = fa_layers_setup(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        f0 = param_10;\n        float3 param_11 = _2851;\n        float3 lit = (fa_ambient_light(param_11) * _2881) * _3403;\n        if (_2904.on)\n        {\n            lit *= _2904.base_scale;\n        }\n        int _2926 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2926; ln++)\n        {\n            int param_12 = ln;\n            int _2939 = fa_cl_light(param_12);\n            int param_13 = _2939;\n            float3 param_14 = fa_world_pos;\n            float3 param_15 = _3367;\n            LightSample _2948 = fa_light_shadowed(param_13, param_14, param_15);\n            float3 _3572 = _2948.direction;\n            float _2956 = max(dot(_2851, _3572), 0.0f);\n            float _2962 = _2948.attenuation * _2948.shadow;\n            float3 _2967 = normalize(_3572 + _2821);\n            float _2972 = max(dot(_2851, _2967), 0.0f);\n            float _2977 = max(dot(_2821, _2967), 0.0f);\n            if (_2904.on)\n            {\n                FaLayers param_16 = _2904;\n                float3 param_17 = _2881;\n                float3 param_18 = f0;\n                float3 param_19 = _2851;\n                float3 param_20 = _2821;\n                float3 param_21 = _3572;\n                float3 param_22 = _2967;\n                float param_23 = _2956;\n                float param_24 = _2875;\n                float param_25 = _2972;\n                float param_26 = _2977;\n                float param_27 = _2866;\n                float param_28 = _2870;\n                int param_29 = _2939;\n                lit += (fa_layers_light(param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28) * (fa_light_rgb(param_29) * _2962));\n            }\n            else\n            {\n                float _3025 = ((_2972 * _2972) * (_2870 - 1.0f)) + 1.0f;\n                int param_30 = _2939;\n                lit += (((_2881 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _2977, 5.0f))) * (((_2870 / ((3.1415927410125732421875f * _3025) * _3025)) * (0.5f / max(lerp((2.0f * _2956) * _2875, _2956 + _2875, _2866), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _2956))) * fa_light_rgb(param_30)) * (_2956 * _2962));\n            }\n        }\n        if (_2904.on)\n        {\n            FaLayers param_31 = _2904;\n            float3 param_32 = _2851;\n            float3 param_33 = _2821;\n            float3 param_34 = f0;\n            float param_35 = _2862;\n            lit += (fa_layers_ibl(param_31, param_32, param_33, param_34, param_35) * _3403);\n        }\n        else\n        {\n            float3 param_36 = _2851;\n            float3 param_37 = _2821;\n            float3 param_38 = f0;\n            float param_39 = _2862;\n            lit += (fa_sky_reflection(param_36, param_37, param_38, param_39) * _3403);\n        }\n        result = lit;\n    }\n    float3 _3118 = result;\n    float3 _3119 = _3118 + _3404;\n    result = _3119;\n    float3 param_40 = _3119;\n    float3 param_41 = fa_world_pos;\n    result = fa_shadow_debug(param_40, param_41);\n    bool _3128 = _459_fa_fog.w > 0.0f;\n    bool _3135;\n    if (!_3128)\n    {\n        _3135 = _459_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _3135 = _3128;\n    }\n    if (_3135)\n    {\n        float3 _3144 = fa_world_pos - _459_fa_camera_pos.xyz;\n        float _3150 = dot(_3144, _459_fa_fog_c.xyz);\n        bool _3154 = _459_fa_fog_c.w > 0.5f;\n        float _3155;\n        if (_3154)\n        {\n            _3155 = _3150;\n        }\n        else\n        {\n            _3155 = length(_3144);\n        }\n        float _3167 = _3155 - _459_fa_fog_b.x;\n        if (_3167 > 0.0f)\n        {\n            float _3176 = _459_fa_fog.w * _3167;\n            float tau = _3176 * _3176;\n            if (_459_fa_fog_b.y > 0.0f)\n            {\n                float _3192;\n                if (_3154)\n                {\n                    _3192 = fa_world_pos.y - (_459_fa_fog_c.y * _3150);\n                }\n                else\n                {\n                    _3192 = _459_fa_camera_pos.y;\n                }\n                float _3213 = lerp(_3192, fa_world_pos.y, clamp(_459_fa_fog_b.x / _3155, 0.0f, 1.0f));\n                float _3217 = fa_world_pos.y - _3213;\n                float _3222 = _3213 - _459_fa_fog_b.z;\n                float _3227 = fa_world_pos.y - _459_fa_fog_b.z;\n                bool _3230 = _3222 <= 0.0f;\n                bool _3231 = !_3230;\n                bool _3237;\n                if (_3231)\n                {\n                    _3237 = _459_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3237 = _3230;\n                }\n                float _3238;\n                if (_3237)\n                {\n                    _3238 = _459_fa_fog_b.y;\n                }\n                else\n                {\n                    _3238 = _459_fa_fog_b.y * exp(-min(_459_fa_fog_b.w * _3222, 80.0f));\n                }\n                bool _3265;\n                if (_3231)\n                {\n                    _3265 = _459_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3265 = _3230;\n                }\n                float _3266;\n                if (_3265)\n                {\n                    _3266 = _459_fa_fog_b.y * _3222;\n                }\n                else\n                {\n                    _3266 = (_459_fa_fog_b.y * (1.0f - exp(-min(_459_fa_fog_b.w * _3222, 80.0f)))) / _459_fa_fog_b.w;\n                }\n                bool _3291 = _3227 <= 0.0f;\n                bool _3298;\n                if (!_3291)\n                {\n                    _3298 = _459_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3298 = _3291;\n                }\n                float _3299;\n                if (_3298)\n                {\n                    _3299 = _459_fa_fog_b.y * _3227;\n                }\n                else\n                {\n                    _3299 = (_459_fa_fog_b.y * (1.0f - exp(-min(_459_fa_fog_b.w * _3227, 80.0f)))) / _459_fa_fog_b.w;\n                }\n                float _3326;\n                if (abs(_3217) < 0.001000000047497451305389404296875f)\n                {\n                    _3326 = _3238;\n                }\n                else\n                {\n                    _3326 = (_3299 - _3266) / _3217;\n                }\n                tau += (_3167 * max(_3326, 0.0f));\n            }\n            result = lerp(result, _459_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _3399);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 160,
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
            "inst_name": "_459",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_695",
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
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
              "multisampled": false,
              "type": "cube",
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 8,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _292 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _292;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _299 = _160.world_pos;\n    float4 _171 = float4(_299, 1.0f);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -mul(_171, _131_fa_light_vp).z;\n    fa_pre_r0 = float3(_131_fa_light_vp[0].x, _131_fa_light_vp[1].x, _131_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131_fa_light_vp[0].y, _131_fa_light_vp[1].y, _131_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131_fa_light_vp[0].z, _131_fa_light_vp[1].z, _131_fa_light_vp[2].z);\n    gl_Position = mul(_171, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _733 = base_t;\n    _733.x = _225.x;\n    _733.y = _225.y;\n    _733.z = _225.z;\n    base_t = _733;\n    float4 _241 = (_733 * _213_fa_base_color) * i.vertex_color;\n    float3 _696 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _741 = _279;\n        _741.x = _284.x;\n        _741.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _741;\n        _696 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _744 = mrt;\n    _744.x = _313.x;\n    _744.y = _313.y;\n    _744.z = _313.z;\n    mrt = _744;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _701 = _213_fa_layers_a.x;\n    float _702 = _213_fa_layers_a.y;\n    float _705 = _213_fa_layers_a.z;\n    float _704 = _213_fa_layers_b.w;\n    float _707 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _701 *= _355.y;\n            _702 *= _355.z;\n            _704 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _705 *= mrt.x;\n            _707 *= mrt.w;\n        }\n    }\n    Surface _726 = { _241.xyz, _241.w, _696, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _701, _702, _213_fa_layers_b.xyz, _704, _705, _213_fa_layers_a.w, _707, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _726;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _607 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _607 = -_607;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _620 = { fa_world_pos, _607, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _620;\n    SurfaceInput _628 = { fa_world_pos, _607, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _628;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 160,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _413 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _413;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _420 = _273.world_pos;\n    float4 _284 = float4(_420, 1.0f);\n    fa_world_pos = _420;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -mul(_284, _136_fa_light_vp).z;\n    fa_pre_r0 = float3(_136_fa_light_vp[0].x, _136_fa_light_vp[1].x, _136_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136_fa_light_vp[0].y, _136_fa_light_vp[1].y, _136_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136_fa_light_vp[0].z, _136_fa_light_vp[1].z, _136_fa_light_vp[2].z);\n    gl_Position = mul(_284, _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _733 = base_t;\n    _733.x = _225.x;\n    _733.y = _225.y;\n    _733.z = _225.z;\n    base_t = _733;\n    float4 _241 = (_733 * _213_fa_base_color) * i.vertex_color;\n    float3 _696 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _741 = _279;\n        _741.x = _284.x;\n        _741.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _741;\n        _696 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _744 = mrt;\n    _744.x = _313.x;\n    _744.y = _313.y;\n    _744.z = _313.z;\n    mrt = _744;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _701 = _213_fa_layers_a.x;\n    float _702 = _213_fa_layers_a.y;\n    float _705 = _213_fa_layers_a.z;\n    float _704 = _213_fa_layers_b.w;\n    float _707 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _701 *= _355.y;\n            _702 *= _355.z;\n            _704 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _705 *= mrt.x;\n            _707 *= mrt.w;\n        }\n    }\n    Surface _726 = { _241.xyz, _241.w, _696, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _701, _702, _213_fa_layers_b.xyz, _704, _705, _213_fa_layers_a.w, _707, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _726;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _607 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _607 = -_607;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _620 = { fa_world_pos, _607, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _620;\n    SurfaceInput _628 = { fa_world_pos, _607, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _628;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 160,
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
