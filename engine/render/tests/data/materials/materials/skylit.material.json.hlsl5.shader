{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "7cd31c28ac6572768802838498bbbd3180b96e0a1bb1bab7ad49d1d6af9d528c",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _258 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _258;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _265 = _160.world_pos;\n    fa_world_pos = _265;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_265, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _1952[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _439_fa_camera_pos : packoffset(c0);\n    float4 _439_fa_ambient : packoffset(c1);\n    float4 _439_fa_base_color : packoffset(c2);\n    float4 _439_fa_emissive : packoffset(c3);\n    float4 _439_fa_model_emissive : packoffset(c4);\n    float4 _439_fa_pbr : packoffset(c5);\n    float4 _439_fa_maps : packoffset(c6);\n    float4 _439_fa_fog : packoffset(c7);\n    float4 _439_fa_fog_b : packoffset(c8);\n    float4 _439_fa_fog_c : packoffset(c9);\n    float4 _439_fa_counts : packoffset(c10);\n    float4 _439_fa_env_sky : packoffset(c11);\n    float4 _439_fa_env_horizon : packoffset(c12);\n    float4 _439_fa_time : packoffset(c13);\n    float4 _439_fa_cl_vpx : packoffset(c14);\n    float4 _439_fa_cl_vpy : packoffset(c15);\n    float4 _439_fa_cl_vpw : packoffset(c16);\n    float4 _439_fa_cl_fwd : packoffset(c17);\n    float4 _439_fa_cl_grid : packoffset(c18);\n    float4 _439_fa_cl_info : packoffset(c19);\n    float4 _439_fa_layers_a : packoffset(c20);\n    float4 _439_fa_layers_b : packoffset(c21);\n    float4 _439_fa_layers_c : packoffset(c22);\n    float4 _439_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _675_fa_shadow_mat[4] : packoffset(c0);\n    float4 _675_fa_shadow_rect[4] : packoffset(c16);\n    float4 _675_fa_shadow_info[4] : packoffset(c20);\n    float4 _675_fa_shadow_split : packoffset(c24);\n    float4 _675_fa_shadow_cfg : packoffset(c25);\n    float4 _675_fa_shadow_bias : packoffset(c26);\n    float4 _675_fa_shadow_eye : packoffset(c27);\n    float4 _675_fa_shadow_fwd : packoffset(c28);\n    float4 _675_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _444 = _439_fa_cl_info.x < 0.0f;\n    bool _451;\n    if (!_444)\n    {\n        _451 = _439_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _451 = _444;\n    }\n    bool _459;\n    if (!_451)\n    {\n        _459 = _439_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _459 = _451;\n    }\n    bool _466;\n    if (!_459)\n    {\n        _466 = _439_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _466 = _459;\n    }\n    bool _473;\n    if (!_466)\n    {\n        _473 = _439_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _473 = _466;\n    }\n    if (_473)\n    {\n        return int2(0, 0);\n    }\n    float4 _483 = float4(world_pos, 1.0f);\n    float _490 = dot(_439_fa_cl_vpw, _483);\n    if (!(_490 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _512 = float2(dot(_439_fa_cl_vpx, _483), dot(_439_fa_cl_vpy, _483)) / _490.xx;\n    int _516 = int(_439_fa_cl_grid.x);\n    int _520 = int(_439_fa_cl_grid.y);\n    int param = (int(_439_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_439_fa_cl_fwd.xyz, world_pos) + _439_fa_cl_fwd.w, _439_fa_cl_grid.w) / _439_fa_cl_grid.w) * _439_fa_cl_grid.z)), 0, int(_439_fa_cl_info.y) - 1) * _520) + clamp(int(floor(((_512.y * 0.5f) + 0.5f) * _439_fa_cl_grid.y)), 0, _520 - 1)) * _516)) + clamp(int(floor(((_512.x * 0.5f) + 0.5f) * _439_fa_cl_grid.x)), 0, _516 - 1);\n    float4 _591 = fa_light_texel(param);\n    return int2(int(_591.x), int(_591.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_439_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2490 = fa_cluster_lookup(param);\n    fa_cl_slot = _2490.x;\n    fa_cl_local = _2490.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _2628 = fa_linear_to_srgb(param);\n        c = _2628;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _2636 = fa_srgb_to_linear(param_1);\n            c = _2636;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _220;\n    if (i.front_facing)\n    {\n        _220 = i.world_normal;\n    }\n    else\n    {\n        _220 = -i.world_normal;\n    }\n    float3 _244 = normalize(i.world_tangent.xyz - (_220 * dot(_220, i.world_tangent.xyz)));\n    float3 _272 = normalize(((_244 * m.x) + ((cross(_220, _244) * i.world_tangent.w) * m.y)) + (_220 * m.z));\n    float3 _275;\n    if (i.front_facing)\n    {\n        _275 = _272;\n    }\n    else\n    {\n        _275 = -_272;\n    }\n    return _275;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _439_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2667 = fa_tex_fix(param_2, param_3);\n    float4 _3674 = base_t;\n    _3674.x = _2667.x;\n    _3674.y = _2667.y;\n    _3674.z = _2667.z;\n    base_t = _3674;\n    float4 _2681 = (_3674 * _439_fa_base_color) * i.vertex_color;\n    float3 _3576 = i.world_normal;\n    if (_439_fa_maps.z > 0.5f)\n    {\n        float param_4 = _439_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2713 = fa_tex_fix(param_6, param_7);\n        float3 _2717 = (_2713 * 2.0f) - 1.0f.xxx;\n        float2 _2722 = _2717.xy * _439_fa_maps.x;\n        float3 _3682 = _2717;\n        _3682.x = _2722.x;\n        _3682.y = _2722.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3682;\n        _3576 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _439_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2751 = fa_tex_fix(param_12, param_13);\n    float4 _3685 = mrt;\n    _3685.x = _2751.x;\n    _3685.y = _2751.y;\n    _3685.z = _2751.z;\n    mrt = _3685;\n    float4 _2779 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _439_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _2779.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2791 = fa_tex_fix(param_16, param_17);\n    float param_18 = _439_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2821 = fa_tex_fix(param_20, param_21);\n    float _3581 = _439_fa_layers_a.x;\n    float _3582 = _439_fa_layers_a.y;\n    float _3585 = _439_fa_layers_a.z;\n    float _3584 = _439_fa_layers_b.w;\n    float _3587 = _439_fa_layers_c.x;\n    if (_439_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_439_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _3581 *= _2791.y;\n            _3582 *= _2791.z;\n            _3584 *= _2779.w;\n        }\n        if (_439_fa_layers_c.z > 1.5f)\n        {\n            _3585 *= mrt.x;\n            _3587 *= mrt.w;\n        }\n    }\n    Surface _3606 = { _2681.xyz, _2681.w, _3576, clamp(_439_fa_pbr.x * _2751.z, 0.0f, 1.0f), clamp(_439_fa_pbr.y * _2751.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_439_fa_maps.y * (_2791.x - 1.0f)), _439_fa_emissive.xyz + (_439_fa_model_emissive.xyz * _2821), _3581, _3582, _439_fa_layers_b.xyz, _3584, _3585, _439_fa_layers_a.w, _3587, _439_fa_layers_c.y, _439_fa_layers_d.xyz };\n    return _3606;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_439_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _439_fa_ambient.xyz;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1877 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _1885 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _1888 = int(_1877);\n    int _1891 = int(_1885);\n    float _1901 = _1885 - float(_1891);\n    int _1957 = (_1888 * 9) + _1891;\n    int _1977 = ((_1888 + 1) * 9) + _1891;\n    return lerp(lerp(_1952[_1957], _1952[_1957 + 1], _1901), lerp(_1952[_1977], _1952[_1977 + 1], _1901), _1877 - float(_1888));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _3448 = false;\n    float _3449 = 1.0f;\n    float _3450 = 1.0f;\n    float _3451 = 1.0f;\n    float _3452 = 0.0f;\n    float _3453 = 0.0f;\n    float _3454 = 0.0f;\n    float _3455 = 0.0f;\n    float _3457 = 1.0f;\n    bool _3458 = false;\n    float3 _3459 = 0.0f.xxx;\n    float _3460 = 1.0f;\n    float _3461 = 1.0f;\n    float _3462 = 1.0f;\n    float _3463 = 0.0f;\n    float _3464 = 0.0f;\n    float3 _3465 = float3(1.0f, 0.0f, 0.0f);\n    float3 _3466 = float3(0.0f, 0.0f, 1.0f);\n    float _3467 = 1.0f;\n    float _3468 = 1.0f;\n    float _2030 = clamp(s.specular, 0.0f, 1.0f);\n    float _2034 = clamp(s.ior, 1.0f, 3.0f);\n    bool _2039 = (_2030 != 1.0f) || (_2034 != 1.5f);\n    bool _2049;\n    if (!_2039)\n    {\n        _2049 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _2049 = _2039;\n    }\n    if (_2049)\n    {\n        float _2057 = (_2034 - 1.0f) / (_2034 + 1.0f);\n        f0 = lerp(min((_2057 * _2057).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _2030, s.albedo, metallic.xxx);\n        _3449 = lerp(_2030, 1.0f, metallic);\n        _3448 = true;\n    }\n    float _2085 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_2085 > 0.0f)\n    {\n        float _2093 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _3452 = _2085;\n        _3453 = _2093;\n        float _2100 = _2093 * _2093;\n        _3454 = _2100;\n        _3455 = _2100 * _2100;\n        float _2112 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _3457 = _2112;\n        _3450 = 1.0f - (_2085 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _2112, 0.0f, 1.0f), 5.0f))));\n        _3448 = true;\n    }\n    float3 _2132 = max(s.sheen_color, 0.0f.xxx);\n    float _2141 = max(_2132.x, max(_2132.y, _2132.z));\n    if (_2141 > 0.0f)\n    {\n        float _2149 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _3458 = true;\n        _3459 = _2132;\n        _3460 = _2149;\n        _3461 = _2149 * _2149;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _2149;\n        float _2166 = fa_sheen_albedo(param, param_1);\n        _3463 = _2166;\n        _3462 = 1.0f - min(_2141 * _2166, 1.0f);\n        _3448 = true;\n    }\n    _3451 = _3450 * _3462;\n    float _2185 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_2185 != 0.0f)\n    {\n        float3 _2200 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2200;\n        if (dot(_2200, _2200) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _2214 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_2214.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _2214.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _2214.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _2218 = t;\n        float3 _2219 = normalize(_2218);\n        t = _2219;\n        float3 _2244 = normalize((_2219 * cos(s.anisotropy_rotation)) + ((cross(n, _2219) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _3465 = _2244;\n        _3466 = cross(n, _2244);\n        float _2254 = roughness * roughness;\n        float _2260 = lerp(_2254, 1.0f, _2185 * _2185);\n        bool _2262 = _2185 > 0.0f;\n        _3467 = _2262 ? _2260 : _2254;\n        _3468 = _2262 ? _2254 : _2260;\n        _3464 = _2185;\n        _3448 = true;\n    }\n    FaLayers _3490 = { _3448, _3449, _3450, _3451, _3452, _3453, _3454, _3455, i.world_normal, _3457, _3458, _3459, _3460, _3461, _3462, _3463, _3464, _3465, _3466, _3467, _3468 };\n    return _3490;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _1809 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _1812 = _1809.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_1812 * _1812, exp2((-9.27999973297119140625f) * ndv)) * _1812) + _1809.y)) + _1809.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_439_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _439_fa_env_horizon.w).xyz;\n    }\n    float _1714 = rough * rough;\n    float _1744 = 0.60000002384185791015625f * _1714;\n    return lerp(lerp(_439_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_439_fa_env_horizon.xyz, _439_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _1714)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _1744, 0.0500000007450580596923828125f + _1744, d.y).xxx), ((_439_fa_env_sky.xyz + _439_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_1714 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _2295;\n        if (L.aniso >= 0.0f)\n        {\n            _2295 = L.b;\n        }\n        else\n        {\n            _2295 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_2295, v), _2295), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _2328 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _2328.x) + (L.f90.xxx * _2328.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2383 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _2383.x) + _2383.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1851 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1851.x) + _1851.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _2412 = clamp(s.metallic, 0.0f, 1.0f);\n    float _2416 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _2423 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _2412.xxx);\n    float3 f0 = _2423;\n    float3 _2427 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _2427;\n    float3 param_3 = i.view_dir;\n    float param_4 = _2412;\n    float param_5 = _2416;\n    float3 param_6 = _2423;\n    FaLayers _2444 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_2444.on)\n    {\n        FaLayers param_7 = _2444;\n        float3 param_8 = _2427;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _2416;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _2427;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _2416;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_439_fa_cl_info.x) + int(_439_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _312 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _318 = fa_light_texel(param_1);\n    float _321 = _318.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _328 = _321 < 0.5f;\n    float3 l;\n    if (_328)\n    {\n        l = normalize(_312.xyz);\n    }\n    else\n    {\n        float3 _340 = _312.xyz - world_pos;\n        float _342 = length(_340);\n        dist = _342;\n        l = _340 / max(_342, 9.9999997473787516355514526367188e-05f).xxx;\n        float _357 = _342 / max(_312.w, 0.001000000047497451305389404296875f);\n        float _363 = clamp(1.0f - (_357 * _357), 0.0f, 1.0f);\n        atten = _363 * _363;\n        if (_321 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _377 = fa_light_texel(param_2);\n            float _387 = _377.w;\n            int param_3 = (li * 4) + 3;\n            float4 _394 = fa_light_texel(param_3);\n            float _395 = _394.x;\n            float cos_inner = _395;\n            if (_395 > 1.5f)\n            {\n                cos_inner = lerp(_387, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_387, cos_inner, dot(-l, normalize(_377.xyz)));\n        }\n    }\n    int _425;\n    if (_328)\n    {\n        _425 = 0;\n    }\n    else\n    {\n        _425 = (_321 > 1.5f) ? 2 : 1;\n    }\n    LightSample _3447 = { l, _318.xyz * atten, atten, 1.0f, dist, _425 };\n    return _3447;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _665;\n    if (i == 0)\n    {\n        _665 = _675_fa_shadow_split.x;\n    }\n    else\n    {\n        float _681;\n        if (i == 1)\n        {\n            _681 = _675_fa_shadow_split.y;\n        }\n        else\n        {\n            float _689;\n            if (i == 2)\n            {\n                _689 = _675_fa_shadow_split.z;\n            }\n            else\n            {\n                _689 = _675_fa_shadow_split.w;\n            }\n            _681 = _689;\n        }\n        _665 = _681;\n    }\n    return _665;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _722 = fa_shadow_depth(param, param_1);\n    float _726;\n    if (conv.x < 0.5f)\n    {\n        _726 = _722;\n    }\n    else\n    {\n        _726 = (conv.y * conv.z) / (conv.z - (_722 * (conv.z - conv.y)));\n    }\n    return _726;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _653 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_653), sin(_653)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _772 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _786 = clamp((k * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _772;\n            float2 _805 = fa_shadow_vogel(param_3, param_4, param_5) * _786;\n            float2 param_6 = uv + (_805 * _675_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _817 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_817 < (zr - (length(_805) * plane)))\n            {\n                sum += _817;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0f) * unit) * k) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _861 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _861; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _861;\n        float param_11 = _772;\n        float2 _880 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_880 * _675_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_880) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_861);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _922 = max(_675_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _927 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _933 = sqrt(1.0f - (_927 * _927));\n    float _941 = min(_933 / max(_927, 0.20000000298023223876953125f), 4.0f);\n    float _946;\n    if (_675_fa_shadow_bias.y > 0.0f)\n    {\n        _946 = _675_fa_shadow_bias.y;\n    }\n    else\n    {\n        _946 = 1.5f * _675_fa_shadow_info[ci].x;\n    }\n    float4 _971 = mul(float4(world + (n * (_946 * _933)), 1.0f), _675_fa_shadow_mat[ci]);\n    float _978 = _971.x;\n    bool _981 = _978 < _675_fa_shadow_rect[ci].x;\n    bool _990;\n    if (!_981)\n    {\n        _990 = _978 > _675_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _990 = _981;\n    }\n    bool _999;\n    if (!_990)\n    {\n        _999 = _971.y < _675_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _999 = _990;\n    }\n    bool _1008;\n    if (!_999)\n    {\n        _1008 = _971.y > _675_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1008 = _999;\n    }\n    bool _1015;\n    if (!_1008)\n    {\n        _1015 = _971.z > 1.0f;\n    }\n    else\n    {\n        _1015 = _1008;\n    }\n    if (_1015)\n    {\n        return -1.0f;\n    }\n    float _1024;\n    if (_675_fa_shadow_bias.x > 0.0f)\n    {\n        _1024 = _675_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1024 = 1.5f * _675_fa_shadow_info[ci].x;\n    }\n    float2 param = _971.xy;\n    float4 param_1 = _675_fa_shadow_rect[ci];\n    float param_2 = _971.z - ((_1024 * (1.0f + (0.5f * _941))) / _922);\n    float param_3 = _675_fa_shadow_info[ci].x;\n    float param_4 = _922;\n    float param_5 = _922 * 0.25f;\n    float param_6 = ((_675_fa_shadow_info[ci].x * min(_941, 3.0f)) * 0.5f) / _922;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_675_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _675_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_439_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1418 = int(_675_fa_shadow_cfg.x + 0.5f);\n    if (_1418 < 1)\n    {\n        return 1.0f;\n    }\n    float _1434 = dot(world - _675_fa_shadow_eye.xyz, _675_fa_shadow_fwd.xyz);\n    int param = _1418 - 1;\n    if (_1434 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1446 = _1418 > 1;\n    bool _1453;\n    if (_1446)\n    {\n        _1453 = _1434 > _675_fa_shadow_split.x;\n    }\n    else\n    {\n        _1453 = _1446;\n    }\n    if (_1453)\n    {\n        ci = 1;\n    }\n    bool _1457 = _1418 > 2;\n    bool _1464;\n    if (_1457)\n    {\n        _1464 = _1434 > _675_fa_shadow_split.y;\n    }\n    else\n    {\n        _1464 = _1457;\n    }\n    if (_1464)\n    {\n        ci = 2;\n    }\n    bool _1468 = _1418 > 3;\n    bool _1475;\n    if (_1468)\n    {\n        _1475 = _1434 > _675_fa_shadow_split.z;\n    }\n    else\n    {\n        _1475 = _1468;\n    }\n    if (_1475)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1418)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1501 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1501;\n        if (_1501 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_675_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1526;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1526 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1526 = _675_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1545 = _675_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1526, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1556 = clamp((_1434 - (fa_shadow_split_at(param_7) - _1545)) / _1545, 0.0f, 1.0f);\n        if (_1556 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1418)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1577 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1577;\n                if (_1577 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1556);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _1083 = _439_fa_pbr.z < 0.5f;\n    bool _1091;\n    if (!_1083)\n    {\n        _1091 = _675_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _1091 = _1083;\n    }\n    if (_1091)\n    {\n        return 1.0f;\n    }\n    int param = (int(_675_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _1104 = fa_light_texel(param);\n    float _1105 = _1104.x;\n    if (_1105 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _1114 = int(_1105 + 0.5f);\n    int param_1 = _1114;\n    float4 _1118 = fa_light_texel(param_1);\n    int param_2 = _1114 + 1;\n    float4 _1123 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _1126 = _1118.y;\n    if (_1126 > 0.0f)\n    {\n        float _1143 = 1.0f - smoothstep(0.75f * _1126, _1126, length(world - _675_fa_shadow_eye.xyz));\n        fade = _1143;\n        if (_1143 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_1118.x > 1.5f)\n    {\n        int param_3 = li * 4;\n        float3 _1162 = world - fa_light_texel(param_3).xyz;\n        float3 _1165 = abs(_1162);\n        float _1167 = _1165.x;\n        float _1169 = _1165.y;\n        bool _1170 = _1167 >= _1169;\n        bool _1178;\n        if (_1170)\n        {\n            _1178 = _1167 >= _1165.z;\n        }\n        else\n        {\n            _1178 = _1170;\n        }\n        int _1179;\n        if (_1178)\n        {\n            _1179 = (_1162.x > 0.0f) ? 0 : 1;\n        }\n        else\n        {\n            int _1192;\n            if (_1169 >= _1165.z)\n            {\n                _1192 = (_1162.y > 0.0f) ? 2 : 3;\n            }\n            else\n            {\n                _1192 = (_1162.z > 0.0f) ? 4 : 5;\n            }\n            _1179 = _1192;\n        }\n        face = _1179;\n    }\n    int _1211 = (_1114 + 2) + (face * 6);\n    int param_4 = _1211;\n    int param_5 = _1211 + 1;\n    int param_6 = _1211 + 3;\n    float4 _1225 = fa_light_texel(param_6);\n    int param_7 = _1211 + 4;\n    float4 _1230 = fa_light_texel(param_7);\n    int param_8 = _1211 + 5;\n    float4 _1235 = fa_light_texel(param_8);\n    float _1247 = _1235.x * max(dot(_1225, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _1252 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1258 = sqrt(1.0f - (_1252 * _1252));\n    float _1264 = min(_1258 / max(_1252, 0.20000000298023223876953125f), 4.0f);\n    float _1267 = _1123.y;\n    float _1269;\n    if (_1267 > 0.0f)\n    {\n        _1269 = _1267;\n    }\n    else\n    {\n        _1269 = 1.5f * _1247;\n    }\n    float4 _1289 = float4(world + (n * (_1269 * _1258)), 1.0f);\n    float _1293 = dot(_1225, _1289);\n    float _1296 = _1235.y;\n    if (_1293 < _1296)\n    {\n        return 1.0f;\n    }\n    float2 _1311 = float2(dot(fa_light_texel(param_4), _1289), dot(fa_light_texel(param_5), _1289)) / _1293.xx;\n    float _1313 = _1311.x;\n    bool _1316 = _1313 < _1230.x;\n    bool _1325;\n    if (!_1316)\n    {\n        _1325 = _1313 > _1230.z;\n    }\n    else\n    {\n        _1325 = _1316;\n    }\n    bool _1334;\n    if (!_1325)\n    {\n        _1334 = _1311.y < _1230.y;\n    }\n    else\n    {\n        _1334 = _1325;\n    }\n    bool _1343;\n    if (!_1334)\n    {\n        _1343 = _1311.y > _1230.w;\n    }\n    else\n    {\n        _1343 = _1334;\n    }\n    if (_1343)\n    {\n        return 1.0f;\n    }\n    float _1349 = _1123.x;\n    float _1351;\n    if (_1349 > 0.0f)\n    {\n        _1351 = _1349;\n    }\n    else\n    {\n        _1351 = 1.5f * _1247;\n    }\n    float2 param_9 = _1311;\n    float4 param_10 = _1230;\n    float param_11 = _1293 - (_1351 * (1.0f + (0.5f * _1264)));\n    float param_12 = _1247;\n    float param_13 = 1.0f;\n    float param_14 = _1235.z * 0.25f;\n    float param_15 = (_1247 * min(_1264, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _1296, _1235.z);\n    int param_17 = int(_1118.z + 0.5f);\n    float param_18 = _1118.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _2518 = fa_light_sample(param, param_1);\n    float3 _3561 = _2518.direction;\n    float3 _3556 = _2518.color;\n    float _3563 = _2518.attenuation;\n    float _3558 = _2518.shadow;\n    int _3566 = _2518.type;\n    if ((_3566 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _3561;\n        float _2532 = fa_shadow_factor(param_2, param_3);\n        _3558 = _2532;\n        _3556 *= _2532;\n    }\n    else\n    {\n        bool _2543 = _3566 != 0;\n        bool _2549;\n        if (_2543)\n        {\n            _2549 = _3563 > 0.0f;\n        }\n        else\n        {\n            _2549 = _2543;\n        }\n        if (_2549)\n        {\n            int param_4 = li;\n            float3 param_5 = world_pos;\n            float3 param_6 = gn;\n            float3 param_7 = _3561;\n            float _2561 = fa_shadow_local(param_4, param_5, param_6, param_7);\n            _3558 = _2561;\n            _3556 *= _2561;\n        }\n    }\n    LightSample _3573 = { _3561, _3556, _3563, _3558, _2518._distance, _3566 };\n    return _3573;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_675_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1601 = int(_675_fa_shadow_cfg.x + 0.5f);\n    float _1611 = dot(world - _675_fa_shadow_eye.xyz, _675_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1616 = _1601 > 0;\n    bool _1625;\n    if (_1616)\n    {\n        int param = _1601 - 1;\n        _1625 = _1611 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1625 = _1616;\n    }\n    if (_1625)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1632 = _1601 > 1;\n        bool _1639;\n        if (_1632)\n        {\n            _1639 = _1611 > _675_fa_shadow_split.x;\n        }\n        else\n        {\n            _1639 = _1632;\n        }\n        if (_1639)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1645 = _1601 > 2;\n        bool _1652;\n        if (_1645)\n        {\n            _1652 = _1611 > _675_fa_shadow_split.y;\n        }\n        else\n        {\n            _1652 = _1645;\n        }\n        if (_1652)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1658 = _1601 > 3;\n        bool _1665;\n        if (_1658)\n        {\n            _1665 = _1611 > _675_fa_shadow_split.z;\n        }\n        else\n        {\n            _1665 = _1658;\n        }\n        if (_1665)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _3278 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3278 = -_3278;\n    }\n    float3 _2942 = normalize(_439_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _3291 = { fa_world_pos, _3278, fa_world_tangent, fa_uv, fa_vertex_color, _2942, gl_FrontFacing };\n    SurfaceInput param_1 = _3291;\n    Surface _2950 = fa_standard_surface(param_1);\n    float3 _3317 = _2950.albedo;\n    float _3318 = _2950.alpha;\n    float3 _3319 = _2950.normal;\n    float _3320 = _2950.metallic;\n    float _3321 = _2950.roughness;\n    float _3322 = _2950.occlusion;\n    float3 _3323 = _2950.emission;\n    float _3324 = _2950.clearcoat;\n    float _3325 = _2950.clearcoat_roughness;\n    float3 _3326 = _2950.sheen_color;\n    float _3327 = _2950.sheen_roughness;\n    float _3328 = _2950.anisotropy;\n    float _3329 = _2950.anisotropy_rotation;\n    float _3330 = _2950.specular;\n    float _3331 = _2950.ior;\n    float3 _3332 = _2950.specular_color;\n    SurfaceInput _3299 = { fa_world_pos, _3278, fa_world_tangent, fa_uv, fa_vertex_color, _2942, gl_FrontFacing };\n    SurfaceInput param_2 = _3299;\n    Surface param_3 = _2950;\n    surface(param_2, param_3);\n    _3317 = param_3.albedo;\n    _3318 = param_3.alpha;\n    _3319 = param_3.normal;\n    _3320 = param_3.metallic;\n    _3321 = param_3.roughness;\n    _3322 = param_3.occlusion;\n    _3323 = param_3.emission;\n    _3324 = param_3.clearcoat;\n    _3325 = param_3.clearcoat_roughness;\n    _3326 = param_3.sheen_color;\n    _3327 = param_3.sheen_roughness;\n    _3328 = param_3.anisotropy;\n    _3329 = param_3.anisotropy_rotation;\n    _3330 = param_3.specular;\n    _3331 = param_3.ior;\n    _3332 = param_3.specular_color;\n    float3 result;\n    if (_439_fa_emissive.w > 0.5f)\n    {\n        result = _3317;\n    }\n    else\n    {\n        float3 _2971 = _3319;\n        float3 _2972 = normalize(_2971);\n        _3319 = _2972;\n        float3 param_4 = _2972;\n        SurfaceInput _3307 = { fa_world_pos, _3278, fa_world_tangent, fa_uv, fa_vertex_color, _2942, gl_FrontFacing };\n        SurfaceInput param_5 = _3307;\n        Surface _3398 = { _3317, _3318, _3319, _3320, _3321, _3322, _3323, _3324, _3325, _3326, _3327, _3328, _3329, _3330, _3331, _3332 };\n        Surface param_6 = _3398;\n        float3 param_7 = fa_ambient_light(param_4);\n        float3 lit = ambient(param_5, param_6, param_7);\n        int _2991 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2991; ln++)\n        {\n            int param_8 = ln;\n            int param_9 = fa_cl_light(param_8);\n            float3 param_10 = fa_world_pos;\n            float3 param_11 = _3278;\n            SurfaceInput _3315 = { fa_world_pos, _3278, fa_world_tangent, fa_uv, fa_vertex_color, _2942, gl_FrontFacing };\n            SurfaceInput param_12 = _3315;\n            Surface _3415 = { _3317, _3318, _3319, _3320, _3321, _3322, _3323, _3324, _3325, _3326, _3327, _3328, _3329, _3330, _3331, _3332 };\n            Surface param_13 = _3415;\n            LightSample param_14 = fa_light_shadowed(param_9, param_10, param_11);\n            lit += light(param_12, param_13, param_14);\n        }\n        result = lit;\n    }\n    float3 _3028 = result;\n    float3 _3029 = _3028 + _3323;\n    result = _3029;\n    float3 param_15 = _3029;\n    float3 param_16 = fa_world_pos;\n    result = fa_shadow_debug(param_15, param_16);\n    bool _3038 = _439_fa_fog.w > 0.0f;\n    bool _3045;\n    if (!_3038)\n    {\n        _3045 = _439_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _3045 = _3038;\n    }\n    if (_3045)\n    {\n        float3 _3054 = fa_world_pos - _439_fa_camera_pos.xyz;\n        float _3060 = dot(_3054, _439_fa_fog_c.xyz);\n        bool _3064 = _439_fa_fog_c.w > 0.5f;\n        float _3065;\n        if (_3064)\n        {\n            _3065 = _3060;\n        }\n        else\n        {\n            _3065 = length(_3054);\n        }\n        float _3077 = _3065 - _439_fa_fog_b.x;\n        if (_3077 > 0.0f)\n        {\n            float _3086 = _439_fa_fog.w * _3077;\n            float tau = _3086 * _3086;\n            if (_439_fa_fog_b.y > 0.0f)\n            {\n                float _3102;\n                if (_3064)\n                {\n                    _3102 = fa_world_pos.y - (_439_fa_fog_c.y * _3060);\n                }\n                else\n                {\n                    _3102 = _439_fa_camera_pos.y;\n                }\n                float _3123 = lerp(_3102, fa_world_pos.y, clamp(_439_fa_fog_b.x / _3065, 0.0f, 1.0f));\n                float _3127 = fa_world_pos.y - _3123;\n                float _3132 = _3123 - _439_fa_fog_b.z;\n                float _3137 = fa_world_pos.y - _439_fa_fog_b.z;\n                bool _3140 = _3132 <= 0.0f;\n                bool _3141 = !_3140;\n                bool _3147;\n                if (_3141)\n                {\n                    _3147 = _439_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3147 = _3140;\n                }\n                float _3148;\n                if (_3147)\n                {\n                    _3148 = _439_fa_fog_b.y;\n                }\n                else\n                {\n                    _3148 = _439_fa_fog_b.y * exp(-min(_439_fa_fog_b.w * _3132, 80.0f));\n                }\n                bool _3175;\n                if (_3141)\n                {\n                    _3175 = _439_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3175 = _3140;\n                }\n                float _3176;\n                if (_3175)\n                {\n                    _3176 = _439_fa_fog_b.y * _3132;\n                }\n                else\n                {\n                    _3176 = (_439_fa_fog_b.y * (1.0f - exp(-min(_439_fa_fog_b.w * _3132, 80.0f)))) / _439_fa_fog_b.w;\n                }\n                bool _3201 = _3137 <= 0.0f;\n                bool _3208;\n                if (!_3201)\n                {\n                    _3208 = _439_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3208 = _3201;\n                }\n                float _3209;\n                if (_3208)\n                {\n                    _3209 = _439_fa_fog_b.y * _3137;\n                }\n                else\n                {\n                    _3209 = (_439_fa_fog_b.y * (1.0f - exp(-min(_439_fa_fog_b.w * _3137, 80.0f)))) / _439_fa_fog_b.w;\n                }\n                float _3236;\n                if (abs(_3127) < 0.001000000047497451305389404296875f)\n                {\n                    _3236 = _3148;\n                }\n                else\n                {\n                    _3236 = (_3209 - _3176) / _3127;\n                }\n                tau += (_3077 * max(_3236, 0.0f));\n            }\n            result = lerp(result, _439_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _3318);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_439",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_675",
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
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
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
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _379 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _379;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _386 = _273.world_pos;\n    fa_world_pos = _386;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_386, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _1952[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _439_fa_camera_pos : packoffset(c0);\n    float4 _439_fa_ambient : packoffset(c1);\n    float4 _439_fa_base_color : packoffset(c2);\n    float4 _439_fa_emissive : packoffset(c3);\n    float4 _439_fa_model_emissive : packoffset(c4);\n    float4 _439_fa_pbr : packoffset(c5);\n    float4 _439_fa_maps : packoffset(c6);\n    float4 _439_fa_fog : packoffset(c7);\n    float4 _439_fa_fog_b : packoffset(c8);\n    float4 _439_fa_fog_c : packoffset(c9);\n    float4 _439_fa_counts : packoffset(c10);\n    float4 _439_fa_env_sky : packoffset(c11);\n    float4 _439_fa_env_horizon : packoffset(c12);\n    float4 _439_fa_time : packoffset(c13);\n    float4 _439_fa_cl_vpx : packoffset(c14);\n    float4 _439_fa_cl_vpy : packoffset(c15);\n    float4 _439_fa_cl_vpw : packoffset(c16);\n    float4 _439_fa_cl_fwd : packoffset(c17);\n    float4 _439_fa_cl_grid : packoffset(c18);\n    float4 _439_fa_cl_info : packoffset(c19);\n    float4 _439_fa_layers_a : packoffset(c20);\n    float4 _439_fa_layers_b : packoffset(c21);\n    float4 _439_fa_layers_c : packoffset(c22);\n    float4 _439_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _675_fa_shadow_mat[4] : packoffset(c0);\n    float4 _675_fa_shadow_rect[4] : packoffset(c16);\n    float4 _675_fa_shadow_info[4] : packoffset(c20);\n    float4 _675_fa_shadow_split : packoffset(c24);\n    float4 _675_fa_shadow_cfg : packoffset(c25);\n    float4 _675_fa_shadow_bias : packoffset(c26);\n    float4 _675_fa_shadow_eye : packoffset(c27);\n    float4 _675_fa_shadow_fwd : packoffset(c28);\n    float4 _675_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _444 = _439_fa_cl_info.x < 0.0f;\n    bool _451;\n    if (!_444)\n    {\n        _451 = _439_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _451 = _444;\n    }\n    bool _459;\n    if (!_451)\n    {\n        _459 = _439_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _459 = _451;\n    }\n    bool _466;\n    if (!_459)\n    {\n        _466 = _439_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _466 = _459;\n    }\n    bool _473;\n    if (!_466)\n    {\n        _473 = _439_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _473 = _466;\n    }\n    if (_473)\n    {\n        return int2(0, 0);\n    }\n    float4 _483 = float4(world_pos, 1.0f);\n    float _490 = dot(_439_fa_cl_vpw, _483);\n    if (!(_490 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _512 = float2(dot(_439_fa_cl_vpx, _483), dot(_439_fa_cl_vpy, _483)) / _490.xx;\n    int _516 = int(_439_fa_cl_grid.x);\n    int _520 = int(_439_fa_cl_grid.y);\n    int param = (int(_439_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_439_fa_cl_fwd.xyz, world_pos) + _439_fa_cl_fwd.w, _439_fa_cl_grid.w) / _439_fa_cl_grid.w) * _439_fa_cl_grid.z)), 0, int(_439_fa_cl_info.y) - 1) * _520) + clamp(int(floor(((_512.y * 0.5f) + 0.5f) * _439_fa_cl_grid.y)), 0, _520 - 1)) * _516)) + clamp(int(floor(((_512.x * 0.5f) + 0.5f) * _439_fa_cl_grid.x)), 0, _516 - 1);\n    float4 _591 = fa_light_texel(param);\n    return int2(int(_591.x), int(_591.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_439_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2490 = fa_cluster_lookup(param);\n    fa_cl_slot = _2490.x;\n    fa_cl_local = _2490.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _2628 = fa_linear_to_srgb(param);\n        c = _2628;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _2636 = fa_srgb_to_linear(param_1);\n            c = _2636;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _220;\n    if (i.front_facing)\n    {\n        _220 = i.world_normal;\n    }\n    else\n    {\n        _220 = -i.world_normal;\n    }\n    float3 _244 = normalize(i.world_tangent.xyz - (_220 * dot(_220, i.world_tangent.xyz)));\n    float3 _272 = normalize(((_244 * m.x) + ((cross(_220, _244) * i.world_tangent.w) * m.y)) + (_220 * m.z));\n    float3 _275;\n    if (i.front_facing)\n    {\n        _275 = _272;\n    }\n    else\n    {\n        _275 = -_272;\n    }\n    return _275;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _439_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2667 = fa_tex_fix(param_2, param_3);\n    float4 _3674 = base_t;\n    _3674.x = _2667.x;\n    _3674.y = _2667.y;\n    _3674.z = _2667.z;\n    base_t = _3674;\n    float4 _2681 = (_3674 * _439_fa_base_color) * i.vertex_color;\n    float3 _3576 = i.world_normal;\n    if (_439_fa_maps.z > 0.5f)\n    {\n        float param_4 = _439_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2713 = fa_tex_fix(param_6, param_7);\n        float3 _2717 = (_2713 * 2.0f) - 1.0f.xxx;\n        float2 _2722 = _2717.xy * _439_fa_maps.x;\n        float3 _3682 = _2717;\n        _3682.x = _2722.x;\n        _3682.y = _2722.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3682;\n        _3576 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _439_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2751 = fa_tex_fix(param_12, param_13);\n    float4 _3685 = mrt;\n    _3685.x = _2751.x;\n    _3685.y = _2751.y;\n    _3685.z = _2751.z;\n    mrt = _3685;\n    float4 _2779 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _439_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _2779.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2791 = fa_tex_fix(param_16, param_17);\n    float param_18 = _439_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2821 = fa_tex_fix(param_20, param_21);\n    float _3581 = _439_fa_layers_a.x;\n    float _3582 = _439_fa_layers_a.y;\n    float _3585 = _439_fa_layers_a.z;\n    float _3584 = _439_fa_layers_b.w;\n    float _3587 = _439_fa_layers_c.x;\n    if (_439_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_439_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _3581 *= _2791.y;\n            _3582 *= _2791.z;\n            _3584 *= _2779.w;\n        }\n        if (_439_fa_layers_c.z > 1.5f)\n        {\n            _3585 *= mrt.x;\n            _3587 *= mrt.w;\n        }\n    }\n    Surface _3606 = { _2681.xyz, _2681.w, _3576, clamp(_439_fa_pbr.x * _2751.z, 0.0f, 1.0f), clamp(_439_fa_pbr.y * _2751.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_439_fa_maps.y * (_2791.x - 1.0f)), _439_fa_emissive.xyz + (_439_fa_model_emissive.xyz * _2821), _3581, _3582, _439_fa_layers_b.xyz, _3584, _3585, _439_fa_layers_a.w, _3587, _439_fa_layers_c.y, _439_fa_layers_d.xyz };\n    return _3606;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_439_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _439_fa_ambient.xyz;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1877 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _1885 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _1888 = int(_1877);\n    int _1891 = int(_1885);\n    float _1901 = _1885 - float(_1891);\n    int _1957 = (_1888 * 9) + _1891;\n    int _1977 = ((_1888 + 1) * 9) + _1891;\n    return lerp(lerp(_1952[_1957], _1952[_1957 + 1], _1901), lerp(_1952[_1977], _1952[_1977 + 1], _1901), _1877 - float(_1888));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _3448 = false;\n    float _3449 = 1.0f;\n    float _3450 = 1.0f;\n    float _3451 = 1.0f;\n    float _3452 = 0.0f;\n    float _3453 = 0.0f;\n    float _3454 = 0.0f;\n    float _3455 = 0.0f;\n    float _3457 = 1.0f;\n    bool _3458 = false;\n    float3 _3459 = 0.0f.xxx;\n    float _3460 = 1.0f;\n    float _3461 = 1.0f;\n    float _3462 = 1.0f;\n    float _3463 = 0.0f;\n    float _3464 = 0.0f;\n    float3 _3465 = float3(1.0f, 0.0f, 0.0f);\n    float3 _3466 = float3(0.0f, 0.0f, 1.0f);\n    float _3467 = 1.0f;\n    float _3468 = 1.0f;\n    float _2030 = clamp(s.specular, 0.0f, 1.0f);\n    float _2034 = clamp(s.ior, 1.0f, 3.0f);\n    bool _2039 = (_2030 != 1.0f) || (_2034 != 1.5f);\n    bool _2049;\n    if (!_2039)\n    {\n        _2049 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _2049 = _2039;\n    }\n    if (_2049)\n    {\n        float _2057 = (_2034 - 1.0f) / (_2034 + 1.0f);\n        f0 = lerp(min((_2057 * _2057).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _2030, s.albedo, metallic.xxx);\n        _3449 = lerp(_2030, 1.0f, metallic);\n        _3448 = true;\n    }\n    float _2085 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_2085 > 0.0f)\n    {\n        float _2093 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _3452 = _2085;\n        _3453 = _2093;\n        float _2100 = _2093 * _2093;\n        _3454 = _2100;\n        _3455 = _2100 * _2100;\n        float _2112 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _3457 = _2112;\n        _3450 = 1.0f - (_2085 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _2112, 0.0f, 1.0f), 5.0f))));\n        _3448 = true;\n    }\n    float3 _2132 = max(s.sheen_color, 0.0f.xxx);\n    float _2141 = max(_2132.x, max(_2132.y, _2132.z));\n    if (_2141 > 0.0f)\n    {\n        float _2149 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _3458 = true;\n        _3459 = _2132;\n        _3460 = _2149;\n        _3461 = _2149 * _2149;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _2149;\n        float _2166 = fa_sheen_albedo(param, param_1);\n        _3463 = _2166;\n        _3462 = 1.0f - min(_2141 * _2166, 1.0f);\n        _3448 = true;\n    }\n    _3451 = _3450 * _3462;\n    float _2185 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_2185 != 0.0f)\n    {\n        float3 _2200 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2200;\n        if (dot(_2200, _2200) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _2214 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_2214.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _2214.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _2214.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _2218 = t;\n        float3 _2219 = normalize(_2218);\n        t = _2219;\n        float3 _2244 = normalize((_2219 * cos(s.anisotropy_rotation)) + ((cross(n, _2219) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _3465 = _2244;\n        _3466 = cross(n, _2244);\n        float _2254 = roughness * roughness;\n        float _2260 = lerp(_2254, 1.0f, _2185 * _2185);\n        bool _2262 = _2185 > 0.0f;\n        _3467 = _2262 ? _2260 : _2254;\n        _3468 = _2262 ? _2254 : _2260;\n        _3464 = _2185;\n        _3448 = true;\n    }\n    FaLayers _3490 = { _3448, _3449, _3450, _3451, _3452, _3453, _3454, _3455, i.world_normal, _3457, _3458, _3459, _3460, _3461, _3462, _3463, _3464, _3465, _3466, _3467, _3468 };\n    return _3490;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _1809 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _1812 = _1809.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_1812 * _1812, exp2((-9.27999973297119140625f) * ndv)) * _1812) + _1809.y)) + _1809.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_439_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _439_fa_env_horizon.w).xyz;\n    }\n    float _1714 = rough * rough;\n    float _1744 = 0.60000002384185791015625f * _1714;\n    return lerp(lerp(_439_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_439_fa_env_horizon.xyz, _439_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _1714)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _1744, 0.0500000007450580596923828125f + _1744, d.y).xxx), ((_439_fa_env_sky.xyz + _439_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_1714 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _2295;\n        if (L.aniso >= 0.0f)\n        {\n            _2295 = L.b;\n        }\n        else\n        {\n            _2295 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_2295, v), _2295), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _2328 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _2328.x) + (L.f90.xxx * _2328.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2383 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _2383.x) + _2383.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1851 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1851.x) + _1851.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _2412 = clamp(s.metallic, 0.0f, 1.0f);\n    float _2416 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _2423 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _2412.xxx);\n    float3 f0 = _2423;\n    float3 _2427 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _2427;\n    float3 param_3 = i.view_dir;\n    float param_4 = _2412;\n    float param_5 = _2416;\n    float3 param_6 = _2423;\n    FaLayers _2444 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_2444.on)\n    {\n        FaLayers param_7 = _2444;\n        float3 param_8 = _2427;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _2416;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _2427;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _2416;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_439_fa_cl_info.x) + int(_439_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _312 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _318 = fa_light_texel(param_1);\n    float _321 = _318.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _328 = _321 < 0.5f;\n    float3 l;\n    if (_328)\n    {\n        l = normalize(_312.xyz);\n    }\n    else\n    {\n        float3 _340 = _312.xyz - world_pos;\n        float _342 = length(_340);\n        dist = _342;\n        l = _340 / max(_342, 9.9999997473787516355514526367188e-05f).xxx;\n        float _357 = _342 / max(_312.w, 0.001000000047497451305389404296875f);\n        float _363 = clamp(1.0f - (_357 * _357), 0.0f, 1.0f);\n        atten = _363 * _363;\n        if (_321 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _377 = fa_light_texel(param_2);\n            float _387 = _377.w;\n            int param_3 = (li * 4) + 3;\n            float4 _394 = fa_light_texel(param_3);\n            float _395 = _394.x;\n            float cos_inner = _395;\n            if (_395 > 1.5f)\n            {\n                cos_inner = lerp(_387, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_387, cos_inner, dot(-l, normalize(_377.xyz)));\n        }\n    }\n    int _425;\n    if (_328)\n    {\n        _425 = 0;\n    }\n    else\n    {\n        _425 = (_321 > 1.5f) ? 2 : 1;\n    }\n    LightSample _3447 = { l, _318.xyz * atten, atten, 1.0f, dist, _425 };\n    return _3447;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _665;\n    if (i == 0)\n    {\n        _665 = _675_fa_shadow_split.x;\n    }\n    else\n    {\n        float _681;\n        if (i == 1)\n        {\n            _681 = _675_fa_shadow_split.y;\n        }\n        else\n        {\n            float _689;\n            if (i == 2)\n            {\n                _689 = _675_fa_shadow_split.z;\n            }\n            else\n            {\n                _689 = _675_fa_shadow_split.w;\n            }\n            _681 = _689;\n        }\n        _665 = _681;\n    }\n    return _665;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _722 = fa_shadow_depth(param, param_1);\n    float _726;\n    if (conv.x < 0.5f)\n    {\n        _726 = _722;\n    }\n    else\n    {\n        _726 = (conv.y * conv.z) / (conv.z - (_722 * (conv.z - conv.y)));\n    }\n    return _726;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _653 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_653), sin(_653)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _772 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _786 = clamp((k * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _772;\n            float2 _805 = fa_shadow_vogel(param_3, param_4, param_5) * _786;\n            float2 param_6 = uv + (_805 * _675_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _817 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_817 < (zr - (length(_805) * plane)))\n            {\n                sum += _817;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0f) * unit) * k) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _861 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _861; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _861;\n        float param_11 = _772;\n        float2 _880 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_880 * _675_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_880) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_861);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _922 = max(_675_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _927 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _933 = sqrt(1.0f - (_927 * _927));\n    float _941 = min(_933 / max(_927, 0.20000000298023223876953125f), 4.0f);\n    float _946;\n    if (_675_fa_shadow_bias.y > 0.0f)\n    {\n        _946 = _675_fa_shadow_bias.y;\n    }\n    else\n    {\n        _946 = 1.5f * _675_fa_shadow_info[ci].x;\n    }\n    float4 _971 = mul(float4(world + (n * (_946 * _933)), 1.0f), _675_fa_shadow_mat[ci]);\n    float _978 = _971.x;\n    bool _981 = _978 < _675_fa_shadow_rect[ci].x;\n    bool _990;\n    if (!_981)\n    {\n        _990 = _978 > _675_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _990 = _981;\n    }\n    bool _999;\n    if (!_990)\n    {\n        _999 = _971.y < _675_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _999 = _990;\n    }\n    bool _1008;\n    if (!_999)\n    {\n        _1008 = _971.y > _675_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1008 = _999;\n    }\n    bool _1015;\n    if (!_1008)\n    {\n        _1015 = _971.z > 1.0f;\n    }\n    else\n    {\n        _1015 = _1008;\n    }\n    if (_1015)\n    {\n        return -1.0f;\n    }\n    float _1024;\n    if (_675_fa_shadow_bias.x > 0.0f)\n    {\n        _1024 = _675_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1024 = 1.5f * _675_fa_shadow_info[ci].x;\n    }\n    float2 param = _971.xy;\n    float4 param_1 = _675_fa_shadow_rect[ci];\n    float param_2 = _971.z - ((_1024 * (1.0f + (0.5f * _941))) / _922);\n    float param_3 = _675_fa_shadow_info[ci].x;\n    float param_4 = _922;\n    float param_5 = _922 * 0.25f;\n    float param_6 = ((_675_fa_shadow_info[ci].x * min(_941, 3.0f)) * 0.5f) / _922;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_675_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _675_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_439_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1418 = int(_675_fa_shadow_cfg.x + 0.5f);\n    if (_1418 < 1)\n    {\n        return 1.0f;\n    }\n    float _1434 = dot(world - _675_fa_shadow_eye.xyz, _675_fa_shadow_fwd.xyz);\n    int param = _1418 - 1;\n    if (_1434 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1446 = _1418 > 1;\n    bool _1453;\n    if (_1446)\n    {\n        _1453 = _1434 > _675_fa_shadow_split.x;\n    }\n    else\n    {\n        _1453 = _1446;\n    }\n    if (_1453)\n    {\n        ci = 1;\n    }\n    bool _1457 = _1418 > 2;\n    bool _1464;\n    if (_1457)\n    {\n        _1464 = _1434 > _675_fa_shadow_split.y;\n    }\n    else\n    {\n        _1464 = _1457;\n    }\n    if (_1464)\n    {\n        ci = 2;\n    }\n    bool _1468 = _1418 > 3;\n    bool _1475;\n    if (_1468)\n    {\n        _1475 = _1434 > _675_fa_shadow_split.z;\n    }\n    else\n    {\n        _1475 = _1468;\n    }\n    if (_1475)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1418)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1501 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1501;\n        if (_1501 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_675_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1526;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1526 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1526 = _675_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1545 = _675_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1526, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1556 = clamp((_1434 - (fa_shadow_split_at(param_7) - _1545)) / _1545, 0.0f, 1.0f);\n        if (_1556 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1418)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1577 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1577;\n                if (_1577 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1556);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _1083 = _439_fa_pbr.z < 0.5f;\n    bool _1091;\n    if (!_1083)\n    {\n        _1091 = _675_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _1091 = _1083;\n    }\n    if (_1091)\n    {\n        return 1.0f;\n    }\n    int param = (int(_675_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _1104 = fa_light_texel(param);\n    float _1105 = _1104.x;\n    if (_1105 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _1114 = int(_1105 + 0.5f);\n    int param_1 = _1114;\n    float4 _1118 = fa_light_texel(param_1);\n    int param_2 = _1114 + 1;\n    float4 _1123 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _1126 = _1118.y;\n    if (_1126 > 0.0f)\n    {\n        float _1143 = 1.0f - smoothstep(0.75f * _1126, _1126, length(world - _675_fa_shadow_eye.xyz));\n        fade = _1143;\n        if (_1143 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_1118.x > 1.5f)\n    {\n        int param_3 = li * 4;\n        float3 _1162 = world - fa_light_texel(param_3).xyz;\n        float3 _1165 = abs(_1162);\n        float _1167 = _1165.x;\n        float _1169 = _1165.y;\n        bool _1170 = _1167 >= _1169;\n        bool _1178;\n        if (_1170)\n        {\n            _1178 = _1167 >= _1165.z;\n        }\n        else\n        {\n            _1178 = _1170;\n        }\n        int _1179;\n        if (_1178)\n        {\n            _1179 = (_1162.x > 0.0f) ? 0 : 1;\n        }\n        else\n        {\n            int _1192;\n            if (_1169 >= _1165.z)\n            {\n                _1192 = (_1162.y > 0.0f) ? 2 : 3;\n            }\n            else\n            {\n                _1192 = (_1162.z > 0.0f) ? 4 : 5;\n            }\n            _1179 = _1192;\n        }\n        face = _1179;\n    }\n    int _1211 = (_1114 + 2) + (face * 6);\n    int param_4 = _1211;\n    int param_5 = _1211 + 1;\n    int param_6 = _1211 + 3;\n    float4 _1225 = fa_light_texel(param_6);\n    int param_7 = _1211 + 4;\n    float4 _1230 = fa_light_texel(param_7);\n    int param_8 = _1211 + 5;\n    float4 _1235 = fa_light_texel(param_8);\n    float _1247 = _1235.x * max(dot(_1225, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _1252 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1258 = sqrt(1.0f - (_1252 * _1252));\n    float _1264 = min(_1258 / max(_1252, 0.20000000298023223876953125f), 4.0f);\n    float _1267 = _1123.y;\n    float _1269;\n    if (_1267 > 0.0f)\n    {\n        _1269 = _1267;\n    }\n    else\n    {\n        _1269 = 1.5f * _1247;\n    }\n    float4 _1289 = float4(world + (n * (_1269 * _1258)), 1.0f);\n    float _1293 = dot(_1225, _1289);\n    float _1296 = _1235.y;\n    if (_1293 < _1296)\n    {\n        return 1.0f;\n    }\n    float2 _1311 = float2(dot(fa_light_texel(param_4), _1289), dot(fa_light_texel(param_5), _1289)) / _1293.xx;\n    float _1313 = _1311.x;\n    bool _1316 = _1313 < _1230.x;\n    bool _1325;\n    if (!_1316)\n    {\n        _1325 = _1313 > _1230.z;\n    }\n    else\n    {\n        _1325 = _1316;\n    }\n    bool _1334;\n    if (!_1325)\n    {\n        _1334 = _1311.y < _1230.y;\n    }\n    else\n    {\n        _1334 = _1325;\n    }\n    bool _1343;\n    if (!_1334)\n    {\n        _1343 = _1311.y > _1230.w;\n    }\n    else\n    {\n        _1343 = _1334;\n    }\n    if (_1343)\n    {\n        return 1.0f;\n    }\n    float _1349 = _1123.x;\n    float _1351;\n    if (_1349 > 0.0f)\n    {\n        _1351 = _1349;\n    }\n    else\n    {\n        _1351 = 1.5f * _1247;\n    }\n    float2 param_9 = _1311;\n    float4 param_10 = _1230;\n    float param_11 = _1293 - (_1351 * (1.0f + (0.5f * _1264)));\n    float param_12 = _1247;\n    float param_13 = 1.0f;\n    float param_14 = _1235.z * 0.25f;\n    float param_15 = (_1247 * min(_1264, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _1296, _1235.z);\n    int param_17 = int(_1118.z + 0.5f);\n    float param_18 = _1118.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _2518 = fa_light_sample(param, param_1);\n    float3 _3561 = _2518.direction;\n    float3 _3556 = _2518.color;\n    float _3563 = _2518.attenuation;\n    float _3558 = _2518.shadow;\n    int _3566 = _2518.type;\n    if ((_3566 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _3561;\n        float _2532 = fa_shadow_factor(param_2, param_3);\n        _3558 = _2532;\n        _3556 *= _2532;\n    }\n    else\n    {\n        bool _2543 = _3566 != 0;\n        bool _2549;\n        if (_2543)\n        {\n            _2549 = _3563 > 0.0f;\n        }\n        else\n        {\n            _2549 = _2543;\n        }\n        if (_2549)\n        {\n            int param_4 = li;\n            float3 param_5 = world_pos;\n            float3 param_6 = gn;\n            float3 param_7 = _3561;\n            float _2561 = fa_shadow_local(param_4, param_5, param_6, param_7);\n            _3558 = _2561;\n            _3556 *= _2561;\n        }\n    }\n    LightSample _3573 = { _3561, _3556, _3563, _3558, _2518._distance, _3566 };\n    return _3573;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_675_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1601 = int(_675_fa_shadow_cfg.x + 0.5f);\n    float _1611 = dot(world - _675_fa_shadow_eye.xyz, _675_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1616 = _1601 > 0;\n    bool _1625;\n    if (_1616)\n    {\n        int param = _1601 - 1;\n        _1625 = _1611 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1625 = _1616;\n    }\n    if (_1625)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1632 = _1601 > 1;\n        bool _1639;\n        if (_1632)\n        {\n            _1639 = _1611 > _675_fa_shadow_split.x;\n        }\n        else\n        {\n            _1639 = _1632;\n        }\n        if (_1639)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1645 = _1601 > 2;\n        bool _1652;\n        if (_1645)\n        {\n            _1652 = _1611 > _675_fa_shadow_split.y;\n        }\n        else\n        {\n            _1652 = _1645;\n        }\n        if (_1652)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1658 = _1601 > 3;\n        bool _1665;\n        if (_1658)\n        {\n            _1665 = _1611 > _675_fa_shadow_split.z;\n        }\n        else\n        {\n            _1665 = _1658;\n        }\n        if (_1665)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _3278 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3278 = -_3278;\n    }\n    float3 _2942 = normalize(_439_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _3291 = { fa_world_pos, _3278, fa_world_tangent, fa_uv, fa_vertex_color, _2942, gl_FrontFacing };\n    SurfaceInput param_1 = _3291;\n    Surface _2950 = fa_standard_surface(param_1);\n    float3 _3317 = _2950.albedo;\n    float _3318 = _2950.alpha;\n    float3 _3319 = _2950.normal;\n    float _3320 = _2950.metallic;\n    float _3321 = _2950.roughness;\n    float _3322 = _2950.occlusion;\n    float3 _3323 = _2950.emission;\n    float _3324 = _2950.clearcoat;\n    float _3325 = _2950.clearcoat_roughness;\n    float3 _3326 = _2950.sheen_color;\n    float _3327 = _2950.sheen_roughness;\n    float _3328 = _2950.anisotropy;\n    float _3329 = _2950.anisotropy_rotation;\n    float _3330 = _2950.specular;\n    float _3331 = _2950.ior;\n    float3 _3332 = _2950.specular_color;\n    SurfaceInput _3299 = { fa_world_pos, _3278, fa_world_tangent, fa_uv, fa_vertex_color, _2942, gl_FrontFacing };\n    SurfaceInput param_2 = _3299;\n    Surface param_3 = _2950;\n    surface(param_2, param_3);\n    _3317 = param_3.albedo;\n    _3318 = param_3.alpha;\n    _3319 = param_3.normal;\n    _3320 = param_3.metallic;\n    _3321 = param_3.roughness;\n    _3322 = param_3.occlusion;\n    _3323 = param_3.emission;\n    _3324 = param_3.clearcoat;\n    _3325 = param_3.clearcoat_roughness;\n    _3326 = param_3.sheen_color;\n    _3327 = param_3.sheen_roughness;\n    _3328 = param_3.anisotropy;\n    _3329 = param_3.anisotropy_rotation;\n    _3330 = param_3.specular;\n    _3331 = param_3.ior;\n    _3332 = param_3.specular_color;\n    float3 result;\n    if (_439_fa_emissive.w > 0.5f)\n    {\n        result = _3317;\n    }\n    else\n    {\n        float3 _2971 = _3319;\n        float3 _2972 = normalize(_2971);\n        _3319 = _2972;\n        float3 param_4 = _2972;\n        SurfaceInput _3307 = { fa_world_pos, _3278, fa_world_tangent, fa_uv, fa_vertex_color, _2942, gl_FrontFacing };\n        SurfaceInput param_5 = _3307;\n        Surface _3398 = { _3317, _3318, _3319, _3320, _3321, _3322, _3323, _3324, _3325, _3326, _3327, _3328, _3329, _3330, _3331, _3332 };\n        Surface param_6 = _3398;\n        float3 param_7 = fa_ambient_light(param_4);\n        float3 lit = ambient(param_5, param_6, param_7);\n        int _2991 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2991; ln++)\n        {\n            int param_8 = ln;\n            int param_9 = fa_cl_light(param_8);\n            float3 param_10 = fa_world_pos;\n            float3 param_11 = _3278;\n            SurfaceInput _3315 = { fa_world_pos, _3278, fa_world_tangent, fa_uv, fa_vertex_color, _2942, gl_FrontFacing };\n            SurfaceInput param_12 = _3315;\n            Surface _3415 = { _3317, _3318, _3319, _3320, _3321, _3322, _3323, _3324, _3325, _3326, _3327, _3328, _3329, _3330, _3331, _3332 };\n            Surface param_13 = _3415;\n            LightSample param_14 = fa_light_shadowed(param_9, param_10, param_11);\n            lit += light(param_12, param_13, param_14);\n        }\n        result = lit;\n    }\n    float3 _3028 = result;\n    float3 _3029 = _3028 + _3323;\n    result = _3029;\n    float3 param_15 = _3029;\n    float3 param_16 = fa_world_pos;\n    result = fa_shadow_debug(param_15, param_16);\n    bool _3038 = _439_fa_fog.w > 0.0f;\n    bool _3045;\n    if (!_3038)\n    {\n        _3045 = _439_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _3045 = _3038;\n    }\n    if (_3045)\n    {\n        float3 _3054 = fa_world_pos - _439_fa_camera_pos.xyz;\n        float _3060 = dot(_3054, _439_fa_fog_c.xyz);\n        bool _3064 = _439_fa_fog_c.w > 0.5f;\n        float _3065;\n        if (_3064)\n        {\n            _3065 = _3060;\n        }\n        else\n        {\n            _3065 = length(_3054);\n        }\n        float _3077 = _3065 - _439_fa_fog_b.x;\n        if (_3077 > 0.0f)\n        {\n            float _3086 = _439_fa_fog.w * _3077;\n            float tau = _3086 * _3086;\n            if (_439_fa_fog_b.y > 0.0f)\n            {\n                float _3102;\n                if (_3064)\n                {\n                    _3102 = fa_world_pos.y - (_439_fa_fog_c.y * _3060);\n                }\n                else\n                {\n                    _3102 = _439_fa_camera_pos.y;\n                }\n                float _3123 = lerp(_3102, fa_world_pos.y, clamp(_439_fa_fog_b.x / _3065, 0.0f, 1.0f));\n                float _3127 = fa_world_pos.y - _3123;\n                float _3132 = _3123 - _439_fa_fog_b.z;\n                float _3137 = fa_world_pos.y - _439_fa_fog_b.z;\n                bool _3140 = _3132 <= 0.0f;\n                bool _3141 = !_3140;\n                bool _3147;\n                if (_3141)\n                {\n                    _3147 = _439_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3147 = _3140;\n                }\n                float _3148;\n                if (_3147)\n                {\n                    _3148 = _439_fa_fog_b.y;\n                }\n                else\n                {\n                    _3148 = _439_fa_fog_b.y * exp(-min(_439_fa_fog_b.w * _3132, 80.0f));\n                }\n                bool _3175;\n                if (_3141)\n                {\n                    _3175 = _439_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3175 = _3140;\n                }\n                float _3176;\n                if (_3175)\n                {\n                    _3176 = _439_fa_fog_b.y * _3132;\n                }\n                else\n                {\n                    _3176 = (_439_fa_fog_b.y * (1.0f - exp(-min(_439_fa_fog_b.w * _3132, 80.0f)))) / _439_fa_fog_b.w;\n                }\n                bool _3201 = _3137 <= 0.0f;\n                bool _3208;\n                if (!_3201)\n                {\n                    _3208 = _439_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3208 = _3201;\n                }\n                float _3209;\n                if (_3208)\n                {\n                    _3209 = _439_fa_fog_b.y * _3137;\n                }\n                else\n                {\n                    _3209 = (_439_fa_fog_b.y * (1.0f - exp(-min(_439_fa_fog_b.w * _3137, 80.0f)))) / _439_fa_fog_b.w;\n                }\n                float _3236;\n                if (abs(_3127) < 0.001000000047497451305389404296875f)\n                {\n                    _3236 = _3148;\n                }\n                else\n                {\n                    _3236 = (_3209 - _3176) / _3127;\n                }\n                tau += (_3077 * max(_3236, 0.0f));\n            }\n            result = lerp(result, _439_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _3318);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_439",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_675",
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
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
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
          }
        ]
      }
    },
    "prepass": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _292 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _292;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _299 = _160.world_pos;\n    float4 _171 = float4(_299, 1.0f);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -mul(_171, _131_fa_light_vp).z;\n    fa_pre_r0 = float3(_131_fa_light_vp[0].x, _131_fa_light_vp[1].x, _131_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131_fa_light_vp[0].y, _131_fa_light_vp[1].y, _131_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131_fa_light_vp[0].z, _131_fa_light_vp[1].z, _131_fa_light_vp[2].z);\n    gl_Position = mul(_171, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _783 = base_t;\n    _783.x = _225.x;\n    _783.y = _225.y;\n    _783.z = _225.z;\n    base_t = _783;\n    float4 _241 = (_783 * _213_fa_base_color) * i.vertex_color;\n    float3 _746 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _791 = _279;\n        _791.x = _284.x;\n        _791.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _791;\n        _746 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _794 = mrt;\n    _794.x = _313.x;\n    _794.y = _313.y;\n    _794.z = _313.z;\n    mrt = _794;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _751 = _213_fa_layers_a.x;\n    float _752 = _213_fa_layers_a.y;\n    float _755 = _213_fa_layers_a.z;\n    float _754 = _213_fa_layers_b.w;\n    float _757 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _751 *= _355.y;\n            _752 *= _355.z;\n            _754 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _755 *= mrt.x;\n            _757 *= mrt.w;\n        }\n    }\n    Surface _776 = { _241.xyz, _241.w, _746, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _751, _752, _213_fa_layers_b.xyz, _754, _755, _213_fa_layers_a.w, _757, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _776;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _657 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _657 = -_657;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _670 = { fa_world_pos, _657, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _670;\n    SurfaceInput _678 = { fa_world_pos, _657, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _678;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _783 = base_t;\n    _783.x = _225.x;\n    _783.y = _225.y;\n    _783.z = _225.z;\n    base_t = _783;\n    float4 _241 = (_783 * _213_fa_base_color) * i.vertex_color;\n    float3 _746 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _791 = _279;\n        _791.x = _284.x;\n        _791.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _791;\n        _746 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _794 = mrt;\n    _794.x = _313.x;\n    _794.y = _313.y;\n    _794.z = _313.z;\n    mrt = _794;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _751 = _213_fa_layers_a.x;\n    float _752 = _213_fa_layers_a.y;\n    float _755 = _213_fa_layers_a.z;\n    float _754 = _213_fa_layers_b.w;\n    float _757 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _751 *= _355.y;\n            _752 *= _355.z;\n            _754 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _755 *= mrt.x;\n            _757 *= mrt.w;\n        }\n    }\n    Surface _776 = { _241.xyz, _241.w, _746, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _751, _752, _213_fa_layers_b.xyz, _754, _755, _213_fa_layers_a.w, _757, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _776;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _657 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _657 = -_657;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _670 = { fa_world_pos, _657, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _670;\n    SurfaceInput _678 = { fa_world_pos, _657, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _678;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
