{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "5c278b25d8ce4341984c8bf2a53e1ca7890b6a924713889b53c089df056597d0",
  "slang": "hlsl5",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _263 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _263;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_270, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _2520[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\nstatic const LightSample _4459 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, 0 };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _492_fa_camera_pos : packoffset(c0);\n    float4 _492_fa_ambient : packoffset(c1);\n    float4 _492_fa_base_color : packoffset(c2);\n    float4 _492_fa_emissive : packoffset(c3);\n    float4 _492_fa_model_emissive : packoffset(c4);\n    float4 _492_fa_pbr : packoffset(c5);\n    float4 _492_fa_maps : packoffset(c6);\n    float4 _492_fa_fog : packoffset(c7);\n    float4 _492_fa_fog_b : packoffset(c8);\n    float4 _492_fa_fog_c : packoffset(c9);\n    float4 _492_fa_counts : packoffset(c10);\n    float4 _492_fa_env_sky : packoffset(c11);\n    float4 _492_fa_env_horizon : packoffset(c12);\n    float4 _492_fa_time : packoffset(c13);\n    float4 _492_fa_cl_vpx : packoffset(c14);\n    float4 _492_fa_cl_vpy : packoffset(c15);\n    float4 _492_fa_cl_vpw : packoffset(c16);\n    float4 _492_fa_cl_fwd : packoffset(c17);\n    float4 _492_fa_cl_grid : packoffset(c18);\n    float4 _492_fa_cl_info : packoffset(c19);\n    float4 _492_fa_layers_a : packoffset(c20);\n    float4 _492_fa_layers_b : packoffset(c21);\n    float4 _492_fa_layers_c : packoffset(c22);\n    float4 _492_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _1232_fa_shadow_mat[4] : packoffset(c0);\n    float4 _1232_fa_shadow_rect[4] : packoffset(c16);\n    float4 _1232_fa_shadow_info[4] : packoffset(c20);\n    float4 _1232_fa_shadow_split : packoffset(c24);\n    float4 _1232_fa_shadow_cfg : packoffset(c25);\n    float4 _1232_fa_shadow_bias : packoffset(c26);\n    float4 _1232_fa_shadow_eye : packoffset(c27);\n    float4 _1232_fa_shadow_fwd : packoffset(c28);\n    float4 _1232_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _3313_dark : packoffset(c0);\n    float _3313_fa_pad0 : packoffset(c0.y);\n    float _3313_fa_pad1 : packoffset(c0.z);\n    float _3313_fa_pad2 : packoffset(c0.w);\n    float _3313_skyAmount : packoffset(c1);\n    float _3313_fa_pad3 : packoffset(c1.y);\n    float _3313_fa_pad4 : packoffset(c1.z);\n    float _3313_fa_pad5 : packoffset(c1.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_decal_tex : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _497 = _492_fa_cl_info.x < 0.0f;\n    bool _504;\n    if (!_497)\n    {\n        _504 = _492_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _504 = _497;\n    }\n    bool _512;\n    if (!_504)\n    {\n        _512 = _492_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _512 = _504;\n    }\n    bool _519;\n    if (!_512)\n    {\n        _519 = _492_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _519 = _512;\n    }\n    bool _526;\n    if (!_519)\n    {\n        _526 = _492_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _526 = _519;\n    }\n    if (_526)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _536 = float4(world_pos, 1.0f);\n    float _543 = dot(_492_fa_cl_vpw, _536);\n    if (!(_543 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _565 = float2(dot(_492_fa_cl_vpx, _536), dot(_492_fa_cl_vpy, _536)) / _543.xx;\n    int _569 = int(_492_fa_cl_grid.x);\n    int _573 = int(_492_fa_cl_grid.y);\n    int param = (int(_492_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_492_fa_cl_fwd.xyz, world_pos) + _492_fa_cl_fwd.w, _492_fa_cl_grid.w) / _492_fa_cl_grid.w) * _492_fa_cl_grid.z)), 0, int(_492_fa_cl_info.y) - 1) * _573) + clamp(int(floor(((_565.y * 0.5f) + 0.5f) * _492_fa_cl_grid.y)), 0, _573 - 1)) * _569)) + clamp(int(floor(((_565.x * 0.5f) + 0.5f) * _492_fa_cl_grid.x)), 0, _569 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _649 = fa_cluster_texel(param);\n    return int2(int(_649.x), int(_649.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_492_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3067 = fa_cluster_lookup(param);\n    fa_cl_slot = _3067.x;\n    fa_cl_local = _3067.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _3374 = fa_linear_to_srgb(param);\n        c = _3374;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _3382 = fa_srgb_to_linear(param_1);\n            c = _3382;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _255;\n    if (i.front_facing)\n    {\n        _255 = i.world_normal;\n    }\n    else\n    {\n        _255 = -i.world_normal;\n    }\n    float3 _279 = normalize(i.world_tangent.xyz - (_255 * dot(_255, i.world_tangent.xyz)));\n    float3 _307 = normalize(((_279 * m.x) + ((cross(_255, _279) * i.world_tangent.w) * m.y)) + (_255 * m.z));\n    float3 _310;\n    if (i.front_facing)\n    {\n        _310 = _307;\n    }\n    else\n    {\n        _310 = -_307;\n    }\n    return _310;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _492_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3413 = fa_tex_fix(param_2, param_3);\n    float4 _4422 = base_t;\n    _4422.x = _3413.x;\n    _4422.y = _3413.y;\n    _4422.z = _3413.z;\n    base_t = _4422;\n    float4 _3427 = (_4422 * _492_fa_base_color) * i.vertex_color;\n    float3 _4289 = i.world_normal;\n    if (_492_fa_maps.z > 0.5f)\n    {\n        float param_4 = _492_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3459 = fa_tex_fix(param_6, param_7);\n        float3 _3462 = (_3459 * 2.0f) - 1.0f.xxx;\n        float2 _3467 = _3462.xy * _492_fa_maps.x;\n        float3 _4430 = _3462;\n        _4430.x = _3467.x;\n        _4430.y = _3467.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4430;\n        _4289 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _492_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3496 = fa_tex_fix(param_12, param_13);\n    float4 _4433 = mrt;\n    _4433.x = _3496.x;\n    _4433.y = _3496.y;\n    _4433.z = _3496.z;\n    mrt = _4433;\n    float4 _3524 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _492_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _3524.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3536 = fa_tex_fix(param_16, param_17);\n    float param_18 = _492_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3566 = fa_tex_fix(param_20, param_21);\n    float _4294 = _492_fa_layers_a.x;\n    float _4295 = _492_fa_layers_a.y;\n    float _4298 = _492_fa_layers_a.z;\n    float _4297 = _492_fa_layers_b.w;\n    float _4300 = _492_fa_layers_c.x;\n    if (_492_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_492_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _4294 *= _3536.y;\n            _4295 *= _3536.z;\n            _4297 *= _3524.w;\n        }\n        if (_492_fa_layers_c.z > 1.5f)\n        {\n            _4298 *= mrt.x;\n            _4300 *= mrt.w;\n        }\n    }\n    Surface _4319 = { _3427.xyz, _3427.w, _4289, clamp(_492_fa_pbr.x * _3496.z, 0.0f, 1.0f), clamp(_492_fa_pbr.y * _3496.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_492_fa_maps.y * (_3536.x - 1.0f)), _492_fa_emissive.xyz + (_492_fa_model_emissive.xyz * _3566), _4294, _4295, _492_fa_layers_b.xyz, _4297, _4298, _492_fa_layers_a.w, _4300, _492_fa_layers_c.y, _492_fa_layers_d.xyz };\n    return _4319;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _730 = rect.zw - rect.xy;\n    float2 _734 = _730 * atlas;\n    float2 _738 = ddx * _734;\n    float2 _742 = ddy * _734;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _730), clamp(0.5f * log2(max(max(dot(_738, _738), dot(_742, _742)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _777 = _492_fa_counts.y < 0.5f;\n    bool _784;\n    if (!_777)\n    {\n        _784 = _492_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _784 = _777;\n    }\n    if (_784)\n    {\n        return;\n    }\n    float3 _790 = ddx(world_pos);\n    float3 _793 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _797 = fa_cluster_texel(param);\n    int _801 = int(_797.w);\n    if (_801 < 1)\n    {\n        return;\n    }\n    int _811 = int(_492_fa_counts.y + 0.5f);\n    int param_1 = _811;\n    float4 _815 = fa_light_texel(param_1);\n    float2 _818 = _815.yz;\n    int _822 = int(_815.w);\n    int param_2 = _811 + 1;\n    float4 _827 = fa_light_texel(param_2);\n    float _828 = _827.x;\n    int _834 = int(_492_fa_counts.w + 0.5f) - 1;\n    int _838 = int(_797.z);\n    float3 _1104;\n    for (int k = 0; k < _801; k++)\n    {\n        int _851 = _838 + k;\n        int param_3 = _822 + (_851 >> 2);\n        int _869 = (_811 + 2) + (int(fa_light_texel(param_3)[_851 & 3]) * 7);\n        int param_4 = _869 + 6;\n        float4 _874 = fa_light_texel(param_4);\n        if (((int(_874.w + 0.5f) >> _834) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _869;\n        float4 _889 = fa_light_texel(param_5);\n        int param_6 = _869 + 1;\n        float4 _894 = fa_light_texel(param_6);\n        int param_7 = _869 + 2;\n        float4 _899 = fa_light_texel(param_7);\n        float3 _902 = _889.xyz;\n        float _907 = dot(_902, world_pos) + _889.w;\n        float3 _909 = _894.xyz;\n        float _914 = dot(_909, world_pos) + _894.w;\n        float3 _916 = _899.xyz;\n        float _921 = dot(_916, world_pos) + _899.w;\n        bool _926 = abs(_907) > 0.5f;\n        bool _934;\n        if (!_926)\n        {\n            _934 = abs(_914) > 0.5f;\n        }\n        else\n        {\n            _934 = _926;\n        }\n        bool _942;\n        if (!_934)\n        {\n            _942 = abs(_921) > 0.5f;\n        }\n        else\n        {\n            _942 = _934;\n        }\n        if (_942)\n        {\n            continue;\n        }\n        float _957 = clamp(dot(geo_normal, normalize(_916)) * _874.z, 0.0f, 1.0f);\n        if (_957 <= 0.0f)\n        {\n            continue;\n        }\n        float _977 = (clamp((0.5f - abs(_921)) * 10.0f, 0.0f, 1.0f) * _957) * _874.x;\n        float2 _985 = float2(_907 + 0.5f, 0.5f - _914);\n        float2 _995 = float2(dot(_902, _790), dot(_909, _790));\n        float2 _1005 = float2(dot(_902, _793), dot(_909, _793));\n        int param_8 = _869 + 5;\n        float4 _1010 = fa_light_texel(param_8);\n        int param_9 = _869 + 3;\n        float4 _1015 = fa_light_texel(param_9);\n        int param_10 = _869 + 4;\n        float4 _1020 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1010.xyz;\n        bool _1030 = _1015.z > _1015.x;\n        if (_1030)\n        {\n            float4 param_11 = _1015;\n            float2 param_12 = _985;\n            float2 param_13 = _818;\n            float2 param_14 = _995;\n            float2 param_15 = _1005;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_828 > 0.5f) && (_828 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1056 = fa_dc_to_linear(param_16);\n                float4 _4345 = tx;\n                _4345.x = _1056.x;\n                _4345.y = _1056.y;\n                _4345.z = _1056.z;\n                tx = _4345;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_977 * tex_a) * _1010.w, 0.0f, 1.0f).xxx);\n        if (_1020.z > _1020.x)\n        {\n            float4 param_17 = _1020;\n            float2 param_18 = _985;\n            float2 param_19 = _818;\n            float2 param_20 = _995;\n            float2 param_21 = _1005;\n            float4 _1100 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_828 > 1.5f)\n            {\n                float3 param_22 = _1100.xyz;\n                float3 _1110 = fa_dc_to_srgb(param_22);\n                _1104 = _1110;\n            }\n            else\n            {\n                _1104 = _1100.xyz;\n            }\n            float3 _1120 = (_1104 * 2.0f) - 1.0f.xxx;\n            float2 _1125 = _1120.xy * _874.y;\n            float3 _1147 = (normalize(_902) * _1125.x) + (normalize(_909) * _1125.y);\n            float3 _1150 = normalize(normal);\n            normal = normalize(lerp(_1150, normalize((_1150 * max(_1120.z, 0.0500000007450580596923828125f)) + (_1147 - (_1150 * dot(_1150, _1147)))), clamp(_977 * (_1030 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return _4459;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_492_fa_cl_info.x) + int(_492_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5f;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _366 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _372 = fa_light_texel(param_1);\n    float _375 = _372.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _381 = _375 < 0.5f;\n    float3 l;\n    if (_381)\n    {\n        l = normalize(_366.xyz);\n    }\n    else\n    {\n        float3 _393 = _366.xyz - world_pos;\n        float _395 = length(_393);\n        dist = _395;\n        l = _393 / max(_395, 9.9999997473787516355514526367188e-05f).xxx;\n        float _410 = _395 / max(_366.w, 0.001000000047497451305389404296875f);\n        float _416 = clamp(1.0f - (_410 * _410), 0.0f, 1.0f);\n        atten = _416 * _416;\n        if (_375 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _430 = fa_light_texel(param_2);\n            float _440 = _430.w;\n            int param_3 = (li * 4) + 3;\n            float4 _446 = fa_light_texel(param_3);\n            float _447 = _446.x;\n            float cos_inner = _447;\n            if (_447 > 1.5f)\n            {\n                cos_inner = lerp(_440, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_440, cos_inner, dot(-l, normalize(_430.xyz)));\n        }\n    }\n    int _478;\n    if (_381)\n    {\n        _478 = 0;\n    }\n    else\n    {\n        _478 = (_375 > 1.5f) ? 2 : 1;\n    }\n    LightSample _4125 = { l, _372.xyz * atten, atten, 1.0f, dist, _478 };\n    return _4125;\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _3208 = n < 0;\n    bool _3215;\n    if (!_3208)\n    {\n        _3215 = n >= fa_light_count();\n    }\n    else\n    {\n        _3215 = _3208;\n    }\n    if (_3215)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _3223 = fa_cl_light(param);\n    bool _3226 = fa_lm.z > 0.5f;\n    bool _3232;\n    if (_3226)\n    {\n        int param_1 = _3223;\n        _3232 = fa_light_baked(param_1);\n    }\n    else\n    {\n        _3232 = _3226;\n    }\n    if (_3232)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _3223;\n    float3 param_3 = i.world_pos;\n    return fa_light_sample(param_2, param_3);\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1222;\n    if (i == 0)\n    {\n        _1222 = _1232_fa_shadow_split.x;\n    }\n    else\n    {\n        float _1238;\n        if (i == 1)\n        {\n            _1238 = _1232_fa_shadow_split.y;\n        }\n        else\n        {\n            float _1246;\n            if (i == 2)\n            {\n                _1246 = _1232_fa_shadow_split.z;\n            }\n            else\n            {\n                _1246 = _1232_fa_shadow_split.w;\n            }\n            _1238 = _1246;\n        }\n        _1222 = _1238;\n    }\n    return _1222;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1279 = fa_shadow_depth(param, param_1);\n    float _1283;\n    if (conv.x < 0.5f)\n    {\n        _1283 = _1279;\n    }\n    else\n    {\n        _1283 = (conv.y * conv.z) / (conv.z - (_1279 * (conv.z - conv.y)));\n    }\n    return _1283;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1210 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_1210), sin(_1210)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1329 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _1343 = clamp((k * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1329;\n            float2 _1362 = fa_shadow_vogel(param_3, param_4, param_5) * _1343;\n            float2 param_6 = uv + (_1362 * _1232_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1374 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1374 < (zr - (length(_1362) * plane)))\n            {\n                sum += _1374;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0f) * unit) * k) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _1418 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1418; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1418;\n        float param_11 = _1329;\n        float2 _1437 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1437 * _1232_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1437) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1418);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _1479 = max(_1232_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _1484 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1490 = sqrt(1.0f - (_1484 * _1484));\n    float _1497 = min(_1490 / max(_1484, 0.20000000298023223876953125f), 4.0f);\n    float _1502;\n    if (_1232_fa_shadow_bias.y > 0.0f)\n    {\n        _1502 = _1232_fa_shadow_bias.y;\n    }\n    else\n    {\n        _1502 = 1.5f * _1232_fa_shadow_info[ci].x;\n    }\n    float4 _1527 = mul(float4(world + (n * (_1502 * _1490)), 1.0f), _1232_fa_shadow_mat[ci]);\n    float _1534 = _1527.x;\n    bool _1537 = _1534 < _1232_fa_shadow_rect[ci].x;\n    bool _1546;\n    if (!_1537)\n    {\n        _1546 = _1534 > _1232_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1546 = _1537;\n    }\n    bool _1555;\n    if (!_1546)\n    {\n        _1555 = _1527.y < _1232_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1555 = _1546;\n    }\n    bool _1564;\n    if (!_1555)\n    {\n        _1564 = _1527.y > _1232_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1564 = _1555;\n    }\n    bool _1571;\n    if (!_1564)\n    {\n        _1571 = _1527.z > 1.0f;\n    }\n    else\n    {\n        _1571 = _1564;\n    }\n    if (_1571)\n    {\n        return -1.0f;\n    }\n    float _1580;\n    if (_1232_fa_shadow_bias.x > 0.0f)\n    {\n        _1580 = _1232_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1580 = 1.5f * _1232_fa_shadow_info[ci].x;\n    }\n    float2 param = _1527.xy;\n    float4 param_1 = _1232_fa_shadow_rect[ci];\n    float param_2 = _1527.z - ((_1580 * (1.0f + (0.5f * _1497))) / _1479);\n    float param_3 = _1232_fa_shadow_info[ci].x;\n    float param_4 = _1479;\n    float param_5 = _1479 * 0.25f;\n    float param_6 = ((_1232_fa_shadow_info[ci].x * min(_1497, 3.0f)) * 0.5f) / _1479;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_1232_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _1232_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_492_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2007 = int(_1232_fa_shadow_cfg.x + 0.5f);\n    if (_2007 < 1)\n    {\n        return 1.0f;\n    }\n    float _2022 = dot(world - _1232_fa_shadow_eye.xyz, _1232_fa_shadow_fwd.xyz);\n    int param = _2007 - 1;\n    if (_2022 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2034 = _2007 > 1;\n    bool _2041;\n    if (_2034)\n    {\n        _2041 = _2022 > _1232_fa_shadow_split.x;\n    }\n    else\n    {\n        _2041 = _2034;\n    }\n    if (_2041)\n    {\n        ci = 1;\n    }\n    bool _2045 = _2007 > 2;\n    bool _2052;\n    if (_2045)\n    {\n        _2052 = _2022 > _1232_fa_shadow_split.y;\n    }\n    else\n    {\n        _2052 = _2045;\n    }\n    if (_2052)\n    {\n        ci = 2;\n    }\n    bool _2056 = _2007 > 3;\n    bool _2063;\n    if (_2056)\n    {\n        _2063 = _2022 > _1232_fa_shadow_split.z;\n    }\n    else\n    {\n        _2063 = _2056;\n    }\n    if (_2063)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2007)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2089 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2089;\n        if (_2089 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_1232_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2114;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2114 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2114 = _1232_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2133 = _1232_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2114, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2144 = clamp((_2022 - (fa_shadow_split_at(param_7) - _2133)) / _2133, 0.0f, 1.0f);\n        if (_2144 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2007)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2165 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2165;\n                if (_2165 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2144);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _1638 = _492_fa_pbr.z < 0.5f;\n    bool _1646;\n    if (!_1638)\n    {\n        _1646 = _1232_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _1646 = _1638;\n    }\n    if (_1646)\n    {\n        return 1.0f;\n    }\n    int param = (int(_1232_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _1659 = fa_light_texel(param);\n    float _1660 = _1659.x;\n    if (_1660 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _1669 = int(_1660 + 0.5f);\n    int param_1 = _1669;\n    float4 _1673 = fa_light_texel(param_1);\n    int param_2 = _1669 + 1;\n    float4 _1678 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _1681 = _1673.y;\n    if (_1681 > 0.0f)\n    {\n        float _1698 = 1.0f - smoothstep(0.75f * _1681, _1681, length(world - _1232_fa_shadow_eye.xyz));\n        fade = _1698;\n        if (_1698 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_1673.x > 1.5f)\n    {\n        int param_3 = li * 4;\n        float3 _1717 = world - fa_light_texel(param_3).xyz;\n        float3 _1720 = abs(_1717);\n        float _1722 = _1720.x;\n        float _1724 = _1720.y;\n        bool _1725 = _1722 >= _1724;\n        bool _1733;\n        if (_1725)\n        {\n            _1733 = _1722 >= _1720.z;\n        }\n        else\n        {\n            _1733 = _1725;\n        }\n        int _1734;\n        if (_1733)\n        {\n            _1734 = (_1717.x > 0.0f) ? 0 : 1;\n        }\n        else\n        {\n            int _1747;\n            if (_1724 >= _1720.z)\n            {\n                _1747 = (_1717.y > 0.0f) ? 2 : 3;\n            }\n            else\n            {\n                _1747 = (_1717.z > 0.0f) ? 4 : 5;\n            }\n            _1734 = _1747;\n        }\n        face = _1734;\n    }\n    int _1766 = (_1669 + 2) + (face * 6);\n    int param_4 = _1766;\n    int param_5 = _1766 + 1;\n    int param_6 = _1766 + 3;\n    float4 _1780 = fa_light_texel(param_6);\n    int param_7 = _1766 + 4;\n    float4 _1785 = fa_light_texel(param_7);\n    int param_8 = _1766 + 5;\n    float4 _1790 = fa_light_texel(param_8);\n    float _1802 = _1790.x * max(dot(_1780, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _1807 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1830 = clamp(dot(n, _1780.xyz), -1.0f, 1.0f);\n    int param_9 = li * 4;\n    float _1853 = min(sqrt(1.0f - (_1830 * _1830)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1780, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _1856 = _1678.y;\n    float _1858;\n    if (_1856 > 0.0f)\n    {\n        _1858 = _1856;\n    }\n    else\n    {\n        _1858 = 1.5f * _1802;\n    }\n    float4 _1878 = float4(world + (n * (_1858 * sqrt(1.0f - (_1807 * _1807)))), 1.0f);\n    float _1882 = dot(_1780, _1878);\n    float _1885 = _1790.y;\n    if (_1882 < _1885)\n    {\n        return 1.0f;\n    }\n    float2 _1900 = float2(dot(fa_light_texel(param_4), _1878), dot(fa_light_texel(param_5), _1878)) / _1882.xx;\n    float _1902 = _1900.x;\n    bool _1905 = _1902 < _1785.x;\n    bool _1914;\n    if (!_1905)\n    {\n        _1914 = _1902 > _1785.z;\n    }\n    else\n    {\n        _1914 = _1905;\n    }\n    bool _1923;\n    if (!_1914)\n    {\n        _1923 = _1900.y < _1785.y;\n    }\n    else\n    {\n        _1923 = _1914;\n    }\n    bool _1932;\n    if (!_1923)\n    {\n        _1932 = _1900.y > _1785.w;\n    }\n    else\n    {\n        _1932 = _1923;\n    }\n    if (_1932)\n    {\n        return 1.0f;\n    }\n    float _1938 = _1678.x;\n    float _1940;\n    if (_1938 > 0.0f)\n    {\n        _1940 = _1938;\n    }\n    else\n    {\n        _1940 = 1.5f * _1802;\n    }\n    float2 param_10 = _1900;\n    float4 param_11 = _1785;\n    float param_12 = _1882 - (_1940 * (1.0f + (0.5f * _1853)));\n    float param_13 = _1802;\n    float param_14 = 1.0f;\n    float param_15 = _1790.z * 0.25f;\n    float param_16 = (_1802 * min(_1853, 3.0f)) * 0.5f;\n    float3 param_17 = float3(1.0f, _1885, _1790.z);\n    int param_18 = int(_1673.z + 0.5f);\n    float param_19 = _1673.w;\n    return lerp(1.0f, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _3094 = fa_lm.z > 0.5f;\n    bool _3100;\n    if (_3094)\n    {\n        int param = li;\n        _3100 = fa_light_baked(param);\n    }\n    else\n    {\n        _3100 = _3094;\n    }\n    if (_3100)\n    {\n        int param_1 = li;\n        LightSample _4258 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _4258;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _3122 = fa_light_sample(param_2, param_3);\n    float3 _4265 = _3122.direction;\n    float3 _4260 = _3122.color;\n    float _4267 = _3122.attenuation;\n    float _4262 = _3122.shadow;\n    int _4270 = _3122.type;\n    if ((_4270 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _4265;\n        float _3136 = fa_shadow_factor(param_4, param_5);\n        _4262 = _3136;\n        _4260 *= _3136;\n    }\n    else\n    {\n        bool _3147 = _4270 != 0;\n        bool _3153;\n        if (_3147)\n        {\n            _3153 = _4267 > 0.0f;\n        }\n        else\n        {\n            _3153 = _3147;\n        }\n        if (_3153)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _4265;\n            float _3165 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _4262 = _3165;\n            _4260 *= _3165;\n        }\n    }\n    LightSample _4277 = { _4265, _4260, _4267, _4262, _3122._distance, _4270 };\n    return _4277;\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _3182 = n < 0;\n    bool _3189;\n    if (!_3182)\n    {\n        _3189 = n >= fa_light_count();\n    }\n    else\n    {\n        _3189 = _3182;\n    }\n    if (_3189)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    return fa_light_shadowed(param_1, param_2, param_3);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _2445 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _2453 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _2456 = int(_2445);\n    int _2459 = int(_2453);\n    float _2469 = _2453 - float(_2459);\n    int _2525 = (_2456 * 9) + _2459;\n    int _2545 = ((_2456 + 1) * 9) + _2459;\n    return lerp(lerp(_2520[_2525], _2520[_2525 + 1], _2469), lerp(_2520[_2545], _2520[_2545 + 1], _2469), _2445 - float(_2456));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _4126 = false;\n    float _4127 = 1.0f;\n    float _4128 = 1.0f;\n    float _4129 = 1.0f;\n    float _4130 = 0.0f;\n    float _4131 = 0.0f;\n    float _4132 = 0.0f;\n    float _4133 = 0.0f;\n    float _4135 = 1.0f;\n    bool _4136 = false;\n    float3 _4137 = 0.0f.xxx;\n    float _4138 = 1.0f;\n    float _4139 = 1.0f;\n    float _4140 = 1.0f;\n    float _4141 = 0.0f;\n    float _4142 = 0.0f;\n    float3 _4143 = float3(1.0f, 0.0f, 0.0f);\n    float3 _4144 = float3(0.0f, 0.0f, 1.0f);\n    float _4145 = 1.0f;\n    float _4146 = 1.0f;\n    float _2598 = clamp(s.specular, 0.0f, 1.0f);\n    float _2602 = clamp(s.ior, 1.0f, 3.0f);\n    bool _2607 = (_2598 != 1.0f) || (_2602 != 1.5f);\n    bool _2617;\n    if (!_2607)\n    {\n        _2617 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _2617 = _2607;\n    }\n    if (_2617)\n    {\n        float _2625 = (_2602 - 1.0f) / (_2602 + 1.0f);\n        f0 = lerp(min((_2625 * _2625).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _2598, s.albedo, metallic.xxx);\n        _4127 = lerp(_2598, 1.0f, metallic);\n        _4126 = true;\n    }\n    float _2653 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_2653 > 0.0f)\n    {\n        float _2661 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _4130 = _2653;\n        _4131 = _2661;\n        float _2668 = _2661 * _2661;\n        _4132 = _2668;\n        _4133 = _2668 * _2668;\n        float _2680 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _4135 = _2680;\n        _4128 = 1.0f - (_2653 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _2680, 0.0f, 1.0f), 5.0f))));\n        _4126 = true;\n    }\n    float3 _2700 = max(s.sheen_color, 0.0f.xxx);\n    float _2709 = max(_2700.x, max(_2700.y, _2700.z));\n    if (_2709 > 0.0f)\n    {\n        float _2717 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _4136 = true;\n        _4137 = _2700;\n        _4138 = _2717;\n        _4139 = _2717 * _2717;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _2717;\n        float _2734 = fa_sheen_albedo(param, param_1);\n        _4141 = _2734;\n        _4140 = 1.0f - min(_2709 * _2734, 1.0f);\n        _4126 = true;\n    }\n    _4129 = _4128 * _4140;\n    float _2753 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_2753 != 0.0f)\n    {\n        float3 _2768 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2768;\n        if (dot(_2768, _2768) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _2781 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_2781.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _2781.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _2781.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _2785 = t;\n        float3 _2786 = normalize(_2785);\n        t = _2786;\n        float3 _2811 = normalize((_2786 * cos(s.anisotropy_rotation)) + ((cross(n, _2786) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _4143 = _2811;\n        _4144 = cross(n, _2811);\n        float _2821 = roughness * roughness;\n        float _2827 = lerp(_2821, 1.0f, _2753 * _2753);\n        bool _2829 = _2753 > 0.0f;\n        _4145 = _2829 ? _2827 : _2821;\n        _4146 = _2829 ? _2821 : _2827;\n        _4142 = _2753;\n        _4126 = true;\n    }\n    FaLayers _4168 = { _4126, _4127, _4128, _4129, _4130, _4131, _4132, _4133, i.world_normal, _4135, _4136, _4137, _4138, _4139, _4140, _4141, _4142, _4143, _4144, _4145, _4146 };\n    return _4168;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _2377 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _2380 = _2377.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_2380 * _2380, exp2((-9.27999973297119140625f) * ndv)) * _2380) + _2377.y)) + _2377.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_492_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _492_fa_env_horizon.w).xyz;\n    }\n    float _2301 = rough * rough;\n    float _2331 = 0.60000002384185791015625f * _2301;\n    return lerp(lerp(_492_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_492_fa_env_horizon.xyz, _492_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _2301)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _2331, 0.0500000007450580596923828125f + _2331, d.y).xxx), ((_492_fa_env_sky.xyz + _492_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_2301 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _2862;\n        if (L.aniso >= 0.0f)\n        {\n            _2862 = L.b;\n        }\n        else\n        {\n            _2862 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_2862, v), _2862), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _2895 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _2895.x) + (L.f90.xxx * _2895.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2950 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _2950.x) + _2950.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _2419 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _2419.x) + _2419.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _2989 = clamp(s.metallic, 0.0f, 1.0f);\n    float _2993 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _3000 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _2989.xxx);\n    float3 f0 = _3000;\n    float3 _3004 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _3004;\n    float3 param_3 = i.view_dir;\n    float param_4 = _2989;\n    float param_5 = _2993;\n    float3 param_6 = _3000;\n    FaLayers _3021 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_3021.on)\n    {\n        FaLayers param_7 = _3021;\n        float3 param_8 = _3004;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _2993;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _3004;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _2993;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0f;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _3270 = dot(fa_light_unshadowed(param, param_1).color, float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));\n        if (_3270 > bestPower)\n        {\n            bestPower = _3270;\n            best = n;\n        }\n    }\n    float3 lit = (_492_fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _3299 = fa_light(param_2, param_3);\n        float _3307;\n        if (dot(s.normal, _3299.direction) > 0.5f)\n        {\n            _3307 = 1.0f;\n        }\n        else\n        {\n            _3307 = _3313_dark;\n        }\n        lit += ((s.albedo * _3299.color) * _3307);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * _3313_skyAmount);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_1232_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _2189 = int(_1232_fa_shadow_cfg.x + 0.5f);\n    float _2199 = dot(world - _1232_fa_shadow_eye.xyz, _1232_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _2204 = _2189 > 0;\n    bool _2213;\n    if (_2204)\n    {\n        int param = _2189 - 1;\n        _2213 = _2199 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2213 = _2204;\n    }\n    if (_2213)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _2220 = _2189 > 1;\n        bool _2227;\n        if (_2220)\n        {\n            _2227 = _2199 > _1232_fa_shadow_split.x;\n        }\n        else\n        {\n            _2227 = _2220;\n        }\n        if (_2227)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _2233 = _2189 > 2;\n        bool _2240;\n        if (_2233)\n        {\n            _2240 = _2199 > _1232_fa_shadow_split.y;\n        }\n        else\n        {\n            _2240 = _2233;\n        }\n        if (_2240)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _2246 = _2189 > 3;\n        bool _2253;\n        if (_2246)\n        {\n            _2253 = _2199 > _1232_fa_shadow_split.z;\n        }\n        else\n        {\n            _2253 = _2246;\n        }\n        if (_2253)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _4000 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4000 = -_4000;\n    }\n    float3 _3687 = normalize(_492_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _4013 = { fa_world_pos, _4000, fa_world_tangent, fa_uv, fa_vertex_color, _3687, gl_FrontFacing };\n    SurfaceInput param_1 = _4013;\n    Surface _3695 = fa_standard_surface(param_1);\n    float3 _4031 = _3695.albedo;\n    float _4032 = _3695.alpha;\n    float3 _4033 = _3695.normal;\n    float _4034 = _3695.metallic;\n    float _4035 = _3695.roughness;\n    float _4036 = _3695.occlusion;\n    float3 _4037 = _3695.emission;\n    float _4038 = _3695.clearcoat;\n    float _4039 = _3695.clearcoat_roughness;\n    float3 _4040 = _3695.sheen_color;\n    float _4041 = _3695.sheen_roughness;\n    float _4042 = _3695.anisotropy;\n    float _4043 = _3695.anisotropy_rotation;\n    float _4044 = _3695.specular;\n    float _4045 = _3695.ior;\n    float3 _4046 = _3695.specular_color;\n    SurfaceInput _4021 = { fa_world_pos, _4000, fa_world_tangent, fa_uv, fa_vertex_color, _3687, gl_FrontFacing };\n    SurfaceInput param_2 = _4021;\n    Surface param_3 = _3695;\n    surface(param_2, param_3);\n    _4031 = param_3.albedo;\n    _4032 = param_3.alpha;\n    _4033 = param_3.normal;\n    _4034 = param_3.metallic;\n    _4035 = param_3.roughness;\n    _4036 = param_3.occlusion;\n    _4037 = param_3.emission;\n    _4038 = param_3.clearcoat;\n    _4039 = param_3.clearcoat_roughness;\n    _4040 = param_3.sheen_color;\n    _4041 = param_3.sheen_roughness;\n    _4042 = param_3.anisotropy;\n    _4043 = param_3.anisotropy_rotation;\n    _4044 = param_3.specular;\n    _4045 = param_3.ior;\n    _4046 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _4000;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4031 = param_6;\n    _4033 = param_7;\n    float3 result;\n    if (_492_fa_emissive.w > 0.5f)\n    {\n        result = _4031;\n    }\n    else\n    {\n        float3 _3733 = _4033;\n        float3 _3734 = normalize(_3733);\n        _4033 = _3734;\n        SurfaceInput _4029 = { fa_world_pos, _4000, fa_world_tangent, fa_uv, fa_vertex_color, _3687, gl_FrontFacing };\n        SurfaceInput param_8 = _4029;\n        Surface _4112 = { _4031, _4032, _3734, _4034, _4035, _4036, _4037, _4038, _4039, _4040, _4041, _4042, _4043, _4044, _4045, _4046 };\n        Surface param_9 = _4112;\n        result = lighting(param_8, param_9);\n    }\n    float3 _3749 = result;\n    float3 _3750 = _3749 + _4037;\n    result = _3750;\n    float3 param_10 = _3750;\n    float3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _3759 = _492_fa_fog.w > 0.0f;\n    bool _3766;\n    if (!_3759)\n    {\n        _3766 = _492_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _3766 = _3759;\n    }\n    if (_3766)\n    {\n        float3 _3775 = fa_world_pos - _492_fa_camera_pos.xyz;\n        float _3781 = dot(_3775, _492_fa_fog_c.xyz);\n        bool _3785 = _492_fa_fog_c.w > 0.5f;\n        float _3786;\n        if (_3785)\n        {\n            _3786 = _3781;\n        }\n        else\n        {\n            _3786 = length(_3775);\n        }\n        float _3798 = _3786 - _492_fa_fog_b.x;\n        if (_3798 > 0.0f)\n        {\n            float _3807 = _492_fa_fog.w * _3798;\n            float tau = _3807 * _3807;\n            if (_492_fa_fog_b.y > 0.0f)\n            {\n                float _3823;\n                if (_3785)\n                {\n                    _3823 = fa_world_pos.y - (_492_fa_fog_c.y * _3781);\n                }\n                else\n                {\n                    _3823 = _492_fa_camera_pos.y;\n                }\n                float _3844 = lerp(_3823, fa_world_pos.y, clamp(_492_fa_fog_b.x / _3786, 0.0f, 1.0f));\n                float _3848 = fa_world_pos.y - _3844;\n                float _3853 = _3844 - _492_fa_fog_b.z;\n                float _3858 = fa_world_pos.y - _492_fa_fog_b.z;\n                bool _3861 = _3853 <= 0.0f;\n                bool _3862 = !_3861;\n                bool _3868;\n                if (_3862)\n                {\n                    _3868 = _492_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3868 = _3861;\n                }\n                float _3869;\n                if (_3868)\n                {\n                    _3869 = _492_fa_fog_b.y;\n                }\n                else\n                {\n                    _3869 = _492_fa_fog_b.y * exp(-min(_492_fa_fog_b.w * _3853, 80.0f));\n                }\n                bool _3896;\n                if (_3862)\n                {\n                    _3896 = _492_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3896 = _3861;\n                }\n                float _3897;\n                if (_3896)\n                {\n                    _3897 = _492_fa_fog_b.y * _3853;\n                }\n                else\n                {\n                    _3897 = (_492_fa_fog_b.y * (1.0f - exp(-min(_492_fa_fog_b.w * _3853, 80.0f)))) / _492_fa_fog_b.w;\n                }\n                bool _3922 = _3858 <= 0.0f;\n                bool _3929;\n                if (!_3922)\n                {\n                    _3929 = _492_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3929 = _3922;\n                }\n                float _3930;\n                if (_3929)\n                {\n                    _3930 = _492_fa_fog_b.y * _3858;\n                }\n                else\n                {\n                    _3930 = (_492_fa_fog_b.y * (1.0f - exp(-min(_492_fa_fog_b.w * _3858, 80.0f)))) / _492_fa_fog_b.w;\n                }\n                float _3957;\n                if (abs(_3848) < 0.001000000047497451305389404296875f)\n                {\n                    _3957 = _3869;\n                }\n                else\n                {\n                    _3957 = (_3930 - _3897) / _3848;\n                }\n                tau += (_3798 * max(_3957, 0.0f));\n            }\n            result = lerp(result, _492_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4032);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_492",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1232",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_3313",
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
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
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
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _384 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _384;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _391 = _273.world_pos;\n    fa_world_pos = _391;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_391, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _2520[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\nstatic const LightSample _4459 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, 0 };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _492_fa_camera_pos : packoffset(c0);\n    float4 _492_fa_ambient : packoffset(c1);\n    float4 _492_fa_base_color : packoffset(c2);\n    float4 _492_fa_emissive : packoffset(c3);\n    float4 _492_fa_model_emissive : packoffset(c4);\n    float4 _492_fa_pbr : packoffset(c5);\n    float4 _492_fa_maps : packoffset(c6);\n    float4 _492_fa_fog : packoffset(c7);\n    float4 _492_fa_fog_b : packoffset(c8);\n    float4 _492_fa_fog_c : packoffset(c9);\n    float4 _492_fa_counts : packoffset(c10);\n    float4 _492_fa_env_sky : packoffset(c11);\n    float4 _492_fa_env_horizon : packoffset(c12);\n    float4 _492_fa_time : packoffset(c13);\n    float4 _492_fa_cl_vpx : packoffset(c14);\n    float4 _492_fa_cl_vpy : packoffset(c15);\n    float4 _492_fa_cl_vpw : packoffset(c16);\n    float4 _492_fa_cl_fwd : packoffset(c17);\n    float4 _492_fa_cl_grid : packoffset(c18);\n    float4 _492_fa_cl_info : packoffset(c19);\n    float4 _492_fa_layers_a : packoffset(c20);\n    float4 _492_fa_layers_b : packoffset(c21);\n    float4 _492_fa_layers_c : packoffset(c22);\n    float4 _492_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _1232_fa_shadow_mat[4] : packoffset(c0);\n    float4 _1232_fa_shadow_rect[4] : packoffset(c16);\n    float4 _1232_fa_shadow_info[4] : packoffset(c20);\n    float4 _1232_fa_shadow_split : packoffset(c24);\n    float4 _1232_fa_shadow_cfg : packoffset(c25);\n    float4 _1232_fa_shadow_bias : packoffset(c26);\n    float4 _1232_fa_shadow_eye : packoffset(c27);\n    float4 _1232_fa_shadow_fwd : packoffset(c28);\n    float4 _1232_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _3313_dark : packoffset(c0);\n    float _3313_fa_pad0 : packoffset(c0.y);\n    float _3313_fa_pad1 : packoffset(c0.z);\n    float _3313_fa_pad2 : packoffset(c0.w);\n    float _3313_skyAmount : packoffset(c1);\n    float _3313_fa_pad3 : packoffset(c1.y);\n    float _3313_fa_pad4 : packoffset(c1.z);\n    float _3313_fa_pad5 : packoffset(c1.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_decal_tex : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _497 = _492_fa_cl_info.x < 0.0f;\n    bool _504;\n    if (!_497)\n    {\n        _504 = _492_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _504 = _497;\n    }\n    bool _512;\n    if (!_504)\n    {\n        _512 = _492_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _512 = _504;\n    }\n    bool _519;\n    if (!_512)\n    {\n        _519 = _492_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _519 = _512;\n    }\n    bool _526;\n    if (!_519)\n    {\n        _526 = _492_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _526 = _519;\n    }\n    if (_526)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _536 = float4(world_pos, 1.0f);\n    float _543 = dot(_492_fa_cl_vpw, _536);\n    if (!(_543 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _565 = float2(dot(_492_fa_cl_vpx, _536), dot(_492_fa_cl_vpy, _536)) / _543.xx;\n    int _569 = int(_492_fa_cl_grid.x);\n    int _573 = int(_492_fa_cl_grid.y);\n    int param = (int(_492_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_492_fa_cl_fwd.xyz, world_pos) + _492_fa_cl_fwd.w, _492_fa_cl_grid.w) / _492_fa_cl_grid.w) * _492_fa_cl_grid.z)), 0, int(_492_fa_cl_info.y) - 1) * _573) + clamp(int(floor(((_565.y * 0.5f) + 0.5f) * _492_fa_cl_grid.y)), 0, _573 - 1)) * _569)) + clamp(int(floor(((_565.x * 0.5f) + 0.5f) * _492_fa_cl_grid.x)), 0, _569 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _649 = fa_cluster_texel(param);\n    return int2(int(_649.x), int(_649.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_492_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3067 = fa_cluster_lookup(param);\n    fa_cl_slot = _3067.x;\n    fa_cl_local = _3067.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _3374 = fa_linear_to_srgb(param);\n        c = _3374;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _3382 = fa_srgb_to_linear(param_1);\n            c = _3382;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _255;\n    if (i.front_facing)\n    {\n        _255 = i.world_normal;\n    }\n    else\n    {\n        _255 = -i.world_normal;\n    }\n    float3 _279 = normalize(i.world_tangent.xyz - (_255 * dot(_255, i.world_tangent.xyz)));\n    float3 _307 = normalize(((_279 * m.x) + ((cross(_255, _279) * i.world_tangent.w) * m.y)) + (_255 * m.z));\n    float3 _310;\n    if (i.front_facing)\n    {\n        _310 = _307;\n    }\n    else\n    {\n        _310 = -_307;\n    }\n    return _310;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _492_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3413 = fa_tex_fix(param_2, param_3);\n    float4 _4422 = base_t;\n    _4422.x = _3413.x;\n    _4422.y = _3413.y;\n    _4422.z = _3413.z;\n    base_t = _4422;\n    float4 _3427 = (_4422 * _492_fa_base_color) * i.vertex_color;\n    float3 _4289 = i.world_normal;\n    if (_492_fa_maps.z > 0.5f)\n    {\n        float param_4 = _492_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3459 = fa_tex_fix(param_6, param_7);\n        float3 _3462 = (_3459 * 2.0f) - 1.0f.xxx;\n        float2 _3467 = _3462.xy * _492_fa_maps.x;\n        float3 _4430 = _3462;\n        _4430.x = _3467.x;\n        _4430.y = _3467.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4430;\n        _4289 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _492_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3496 = fa_tex_fix(param_12, param_13);\n    float4 _4433 = mrt;\n    _4433.x = _3496.x;\n    _4433.y = _3496.y;\n    _4433.z = _3496.z;\n    mrt = _4433;\n    float4 _3524 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _492_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _3524.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3536 = fa_tex_fix(param_16, param_17);\n    float param_18 = _492_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3566 = fa_tex_fix(param_20, param_21);\n    float _4294 = _492_fa_layers_a.x;\n    float _4295 = _492_fa_layers_a.y;\n    float _4298 = _492_fa_layers_a.z;\n    float _4297 = _492_fa_layers_b.w;\n    float _4300 = _492_fa_layers_c.x;\n    if (_492_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_492_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _4294 *= _3536.y;\n            _4295 *= _3536.z;\n            _4297 *= _3524.w;\n        }\n        if (_492_fa_layers_c.z > 1.5f)\n        {\n            _4298 *= mrt.x;\n            _4300 *= mrt.w;\n        }\n    }\n    Surface _4319 = { _3427.xyz, _3427.w, _4289, clamp(_492_fa_pbr.x * _3496.z, 0.0f, 1.0f), clamp(_492_fa_pbr.y * _3496.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_492_fa_maps.y * (_3536.x - 1.0f)), _492_fa_emissive.xyz + (_492_fa_model_emissive.xyz * _3566), _4294, _4295, _492_fa_layers_b.xyz, _4297, _4298, _492_fa_layers_a.w, _4300, _492_fa_layers_c.y, _492_fa_layers_d.xyz };\n    return _4319;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _730 = rect.zw - rect.xy;\n    float2 _734 = _730 * atlas;\n    float2 _738 = ddx * _734;\n    float2 _742 = ddy * _734;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _730), clamp(0.5f * log2(max(max(dot(_738, _738), dot(_742, _742)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _777 = _492_fa_counts.y < 0.5f;\n    bool _784;\n    if (!_777)\n    {\n        _784 = _492_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _784 = _777;\n    }\n    if (_784)\n    {\n        return;\n    }\n    float3 _790 = ddx(world_pos);\n    float3 _793 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _797 = fa_cluster_texel(param);\n    int _801 = int(_797.w);\n    if (_801 < 1)\n    {\n        return;\n    }\n    int _811 = int(_492_fa_counts.y + 0.5f);\n    int param_1 = _811;\n    float4 _815 = fa_light_texel(param_1);\n    float2 _818 = _815.yz;\n    int _822 = int(_815.w);\n    int param_2 = _811 + 1;\n    float4 _827 = fa_light_texel(param_2);\n    float _828 = _827.x;\n    int _834 = int(_492_fa_counts.w + 0.5f) - 1;\n    int _838 = int(_797.z);\n    float3 _1104;\n    for (int k = 0; k < _801; k++)\n    {\n        int _851 = _838 + k;\n        int param_3 = _822 + (_851 >> 2);\n        int _869 = (_811 + 2) + (int(fa_light_texel(param_3)[_851 & 3]) * 7);\n        int param_4 = _869 + 6;\n        float4 _874 = fa_light_texel(param_4);\n        if (((int(_874.w + 0.5f) >> _834) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _869;\n        float4 _889 = fa_light_texel(param_5);\n        int param_6 = _869 + 1;\n        float4 _894 = fa_light_texel(param_6);\n        int param_7 = _869 + 2;\n        float4 _899 = fa_light_texel(param_7);\n        float3 _902 = _889.xyz;\n        float _907 = dot(_902, world_pos) + _889.w;\n        float3 _909 = _894.xyz;\n        float _914 = dot(_909, world_pos) + _894.w;\n        float3 _916 = _899.xyz;\n        float _921 = dot(_916, world_pos) + _899.w;\n        bool _926 = abs(_907) > 0.5f;\n        bool _934;\n        if (!_926)\n        {\n            _934 = abs(_914) > 0.5f;\n        }\n        else\n        {\n            _934 = _926;\n        }\n        bool _942;\n        if (!_934)\n        {\n            _942 = abs(_921) > 0.5f;\n        }\n        else\n        {\n            _942 = _934;\n        }\n        if (_942)\n        {\n            continue;\n        }\n        float _957 = clamp(dot(geo_normal, normalize(_916)) * _874.z, 0.0f, 1.0f);\n        if (_957 <= 0.0f)\n        {\n            continue;\n        }\n        float _977 = (clamp((0.5f - abs(_921)) * 10.0f, 0.0f, 1.0f) * _957) * _874.x;\n        float2 _985 = float2(_907 + 0.5f, 0.5f - _914);\n        float2 _995 = float2(dot(_902, _790), dot(_909, _790));\n        float2 _1005 = float2(dot(_902, _793), dot(_909, _793));\n        int param_8 = _869 + 5;\n        float4 _1010 = fa_light_texel(param_8);\n        int param_9 = _869 + 3;\n        float4 _1015 = fa_light_texel(param_9);\n        int param_10 = _869 + 4;\n        float4 _1020 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1010.xyz;\n        bool _1030 = _1015.z > _1015.x;\n        if (_1030)\n        {\n            float4 param_11 = _1015;\n            float2 param_12 = _985;\n            float2 param_13 = _818;\n            float2 param_14 = _995;\n            float2 param_15 = _1005;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_828 > 0.5f) && (_828 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1056 = fa_dc_to_linear(param_16);\n                float4 _4345 = tx;\n                _4345.x = _1056.x;\n                _4345.y = _1056.y;\n                _4345.z = _1056.z;\n                tx = _4345;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_977 * tex_a) * _1010.w, 0.0f, 1.0f).xxx);\n        if (_1020.z > _1020.x)\n        {\n            float4 param_17 = _1020;\n            float2 param_18 = _985;\n            float2 param_19 = _818;\n            float2 param_20 = _995;\n            float2 param_21 = _1005;\n            float4 _1100 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_828 > 1.5f)\n            {\n                float3 param_22 = _1100.xyz;\n                float3 _1110 = fa_dc_to_srgb(param_22);\n                _1104 = _1110;\n            }\n            else\n            {\n                _1104 = _1100.xyz;\n            }\n            float3 _1120 = (_1104 * 2.0f) - 1.0f.xxx;\n            float2 _1125 = _1120.xy * _874.y;\n            float3 _1147 = (normalize(_902) * _1125.x) + (normalize(_909) * _1125.y);\n            float3 _1150 = normalize(normal);\n            normal = normalize(lerp(_1150, normalize((_1150 * max(_1120.z, 0.0500000007450580596923828125f)) + (_1147 - (_1150 * dot(_1150, _1147)))), clamp(_977 * (_1030 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return _4459;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_492_fa_cl_info.x) + int(_492_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5f;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _366 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _372 = fa_light_texel(param_1);\n    float _375 = _372.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _381 = _375 < 0.5f;\n    float3 l;\n    if (_381)\n    {\n        l = normalize(_366.xyz);\n    }\n    else\n    {\n        float3 _393 = _366.xyz - world_pos;\n        float _395 = length(_393);\n        dist = _395;\n        l = _393 / max(_395, 9.9999997473787516355514526367188e-05f).xxx;\n        float _410 = _395 / max(_366.w, 0.001000000047497451305389404296875f);\n        float _416 = clamp(1.0f - (_410 * _410), 0.0f, 1.0f);\n        atten = _416 * _416;\n        if (_375 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _430 = fa_light_texel(param_2);\n            float _440 = _430.w;\n            int param_3 = (li * 4) + 3;\n            float4 _446 = fa_light_texel(param_3);\n            float _447 = _446.x;\n            float cos_inner = _447;\n            if (_447 > 1.5f)\n            {\n                cos_inner = lerp(_440, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_440, cos_inner, dot(-l, normalize(_430.xyz)));\n        }\n    }\n    int _478;\n    if (_381)\n    {\n        _478 = 0;\n    }\n    else\n    {\n        _478 = (_375 > 1.5f) ? 2 : 1;\n    }\n    LightSample _4125 = { l, _372.xyz * atten, atten, 1.0f, dist, _478 };\n    return _4125;\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _3208 = n < 0;\n    bool _3215;\n    if (!_3208)\n    {\n        _3215 = n >= fa_light_count();\n    }\n    else\n    {\n        _3215 = _3208;\n    }\n    if (_3215)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _3223 = fa_cl_light(param);\n    bool _3226 = fa_lm.z > 0.5f;\n    bool _3232;\n    if (_3226)\n    {\n        int param_1 = _3223;\n        _3232 = fa_light_baked(param_1);\n    }\n    else\n    {\n        _3232 = _3226;\n    }\n    if (_3232)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _3223;\n    float3 param_3 = i.world_pos;\n    return fa_light_sample(param_2, param_3);\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1222;\n    if (i == 0)\n    {\n        _1222 = _1232_fa_shadow_split.x;\n    }\n    else\n    {\n        float _1238;\n        if (i == 1)\n        {\n            _1238 = _1232_fa_shadow_split.y;\n        }\n        else\n        {\n            float _1246;\n            if (i == 2)\n            {\n                _1246 = _1232_fa_shadow_split.z;\n            }\n            else\n            {\n                _1246 = _1232_fa_shadow_split.w;\n            }\n            _1238 = _1246;\n        }\n        _1222 = _1238;\n    }\n    return _1222;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1279 = fa_shadow_depth(param, param_1);\n    float _1283;\n    if (conv.x < 0.5f)\n    {\n        _1283 = _1279;\n    }\n    else\n    {\n        _1283 = (conv.y * conv.z) / (conv.z - (_1279 * (conv.z - conv.y)));\n    }\n    return _1283;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1210 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_1210), sin(_1210)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1329 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _1343 = clamp((k * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1329;\n            float2 _1362 = fa_shadow_vogel(param_3, param_4, param_5) * _1343;\n            float2 param_6 = uv + (_1362 * _1232_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1374 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1374 < (zr - (length(_1362) * plane)))\n            {\n                sum += _1374;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0f) * unit) * k) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _1418 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1418; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1418;\n        float param_11 = _1329;\n        float2 _1437 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1437 * _1232_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1437) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1418);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _1479 = max(_1232_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _1484 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1490 = sqrt(1.0f - (_1484 * _1484));\n    float _1497 = min(_1490 / max(_1484, 0.20000000298023223876953125f), 4.0f);\n    float _1502;\n    if (_1232_fa_shadow_bias.y > 0.0f)\n    {\n        _1502 = _1232_fa_shadow_bias.y;\n    }\n    else\n    {\n        _1502 = 1.5f * _1232_fa_shadow_info[ci].x;\n    }\n    float4 _1527 = mul(float4(world + (n * (_1502 * _1490)), 1.0f), _1232_fa_shadow_mat[ci]);\n    float _1534 = _1527.x;\n    bool _1537 = _1534 < _1232_fa_shadow_rect[ci].x;\n    bool _1546;\n    if (!_1537)\n    {\n        _1546 = _1534 > _1232_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1546 = _1537;\n    }\n    bool _1555;\n    if (!_1546)\n    {\n        _1555 = _1527.y < _1232_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1555 = _1546;\n    }\n    bool _1564;\n    if (!_1555)\n    {\n        _1564 = _1527.y > _1232_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1564 = _1555;\n    }\n    bool _1571;\n    if (!_1564)\n    {\n        _1571 = _1527.z > 1.0f;\n    }\n    else\n    {\n        _1571 = _1564;\n    }\n    if (_1571)\n    {\n        return -1.0f;\n    }\n    float _1580;\n    if (_1232_fa_shadow_bias.x > 0.0f)\n    {\n        _1580 = _1232_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1580 = 1.5f * _1232_fa_shadow_info[ci].x;\n    }\n    float2 param = _1527.xy;\n    float4 param_1 = _1232_fa_shadow_rect[ci];\n    float param_2 = _1527.z - ((_1580 * (1.0f + (0.5f * _1497))) / _1479);\n    float param_3 = _1232_fa_shadow_info[ci].x;\n    float param_4 = _1479;\n    float param_5 = _1479 * 0.25f;\n    float param_6 = ((_1232_fa_shadow_info[ci].x * min(_1497, 3.0f)) * 0.5f) / _1479;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_1232_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _1232_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_492_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2007 = int(_1232_fa_shadow_cfg.x + 0.5f);\n    if (_2007 < 1)\n    {\n        return 1.0f;\n    }\n    float _2022 = dot(world - _1232_fa_shadow_eye.xyz, _1232_fa_shadow_fwd.xyz);\n    int param = _2007 - 1;\n    if (_2022 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2034 = _2007 > 1;\n    bool _2041;\n    if (_2034)\n    {\n        _2041 = _2022 > _1232_fa_shadow_split.x;\n    }\n    else\n    {\n        _2041 = _2034;\n    }\n    if (_2041)\n    {\n        ci = 1;\n    }\n    bool _2045 = _2007 > 2;\n    bool _2052;\n    if (_2045)\n    {\n        _2052 = _2022 > _1232_fa_shadow_split.y;\n    }\n    else\n    {\n        _2052 = _2045;\n    }\n    if (_2052)\n    {\n        ci = 2;\n    }\n    bool _2056 = _2007 > 3;\n    bool _2063;\n    if (_2056)\n    {\n        _2063 = _2022 > _1232_fa_shadow_split.z;\n    }\n    else\n    {\n        _2063 = _2056;\n    }\n    if (_2063)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2007)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2089 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2089;\n        if (_2089 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_1232_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2114;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2114 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2114 = _1232_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2133 = _1232_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2114, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2144 = clamp((_2022 - (fa_shadow_split_at(param_7) - _2133)) / _2133, 0.0f, 1.0f);\n        if (_2144 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2007)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2165 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2165;\n                if (_2165 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2144);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _1638 = _492_fa_pbr.z < 0.5f;\n    bool _1646;\n    if (!_1638)\n    {\n        _1646 = _1232_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _1646 = _1638;\n    }\n    if (_1646)\n    {\n        return 1.0f;\n    }\n    int param = (int(_1232_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _1659 = fa_light_texel(param);\n    float _1660 = _1659.x;\n    if (_1660 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _1669 = int(_1660 + 0.5f);\n    int param_1 = _1669;\n    float4 _1673 = fa_light_texel(param_1);\n    int param_2 = _1669 + 1;\n    float4 _1678 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _1681 = _1673.y;\n    if (_1681 > 0.0f)\n    {\n        float _1698 = 1.0f - smoothstep(0.75f * _1681, _1681, length(world - _1232_fa_shadow_eye.xyz));\n        fade = _1698;\n        if (_1698 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_1673.x > 1.5f)\n    {\n        int param_3 = li * 4;\n        float3 _1717 = world - fa_light_texel(param_3).xyz;\n        float3 _1720 = abs(_1717);\n        float _1722 = _1720.x;\n        float _1724 = _1720.y;\n        bool _1725 = _1722 >= _1724;\n        bool _1733;\n        if (_1725)\n        {\n            _1733 = _1722 >= _1720.z;\n        }\n        else\n        {\n            _1733 = _1725;\n        }\n        int _1734;\n        if (_1733)\n        {\n            _1734 = (_1717.x > 0.0f) ? 0 : 1;\n        }\n        else\n        {\n            int _1747;\n            if (_1724 >= _1720.z)\n            {\n                _1747 = (_1717.y > 0.0f) ? 2 : 3;\n            }\n            else\n            {\n                _1747 = (_1717.z > 0.0f) ? 4 : 5;\n            }\n            _1734 = _1747;\n        }\n        face = _1734;\n    }\n    int _1766 = (_1669 + 2) + (face * 6);\n    int param_4 = _1766;\n    int param_5 = _1766 + 1;\n    int param_6 = _1766 + 3;\n    float4 _1780 = fa_light_texel(param_6);\n    int param_7 = _1766 + 4;\n    float4 _1785 = fa_light_texel(param_7);\n    int param_8 = _1766 + 5;\n    float4 _1790 = fa_light_texel(param_8);\n    float _1802 = _1790.x * max(dot(_1780, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _1807 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1830 = clamp(dot(n, _1780.xyz), -1.0f, 1.0f);\n    int param_9 = li * 4;\n    float _1853 = min(sqrt(1.0f - (_1830 * _1830)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1780, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _1856 = _1678.y;\n    float _1858;\n    if (_1856 > 0.0f)\n    {\n        _1858 = _1856;\n    }\n    else\n    {\n        _1858 = 1.5f * _1802;\n    }\n    float4 _1878 = float4(world + (n * (_1858 * sqrt(1.0f - (_1807 * _1807)))), 1.0f);\n    float _1882 = dot(_1780, _1878);\n    float _1885 = _1790.y;\n    if (_1882 < _1885)\n    {\n        return 1.0f;\n    }\n    float2 _1900 = float2(dot(fa_light_texel(param_4), _1878), dot(fa_light_texel(param_5), _1878)) / _1882.xx;\n    float _1902 = _1900.x;\n    bool _1905 = _1902 < _1785.x;\n    bool _1914;\n    if (!_1905)\n    {\n        _1914 = _1902 > _1785.z;\n    }\n    else\n    {\n        _1914 = _1905;\n    }\n    bool _1923;\n    if (!_1914)\n    {\n        _1923 = _1900.y < _1785.y;\n    }\n    else\n    {\n        _1923 = _1914;\n    }\n    bool _1932;\n    if (!_1923)\n    {\n        _1932 = _1900.y > _1785.w;\n    }\n    else\n    {\n        _1932 = _1923;\n    }\n    if (_1932)\n    {\n        return 1.0f;\n    }\n    float _1938 = _1678.x;\n    float _1940;\n    if (_1938 > 0.0f)\n    {\n        _1940 = _1938;\n    }\n    else\n    {\n        _1940 = 1.5f * _1802;\n    }\n    float2 param_10 = _1900;\n    float4 param_11 = _1785;\n    float param_12 = _1882 - (_1940 * (1.0f + (0.5f * _1853)));\n    float param_13 = _1802;\n    float param_14 = 1.0f;\n    float param_15 = _1790.z * 0.25f;\n    float param_16 = (_1802 * min(_1853, 3.0f)) * 0.5f;\n    float3 param_17 = float3(1.0f, _1885, _1790.z);\n    int param_18 = int(_1673.z + 0.5f);\n    float param_19 = _1673.w;\n    return lerp(1.0f, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _3094 = fa_lm.z > 0.5f;\n    bool _3100;\n    if (_3094)\n    {\n        int param = li;\n        _3100 = fa_light_baked(param);\n    }\n    else\n    {\n        _3100 = _3094;\n    }\n    if (_3100)\n    {\n        int param_1 = li;\n        LightSample _4258 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _4258;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _3122 = fa_light_sample(param_2, param_3);\n    float3 _4265 = _3122.direction;\n    float3 _4260 = _3122.color;\n    float _4267 = _3122.attenuation;\n    float _4262 = _3122.shadow;\n    int _4270 = _3122.type;\n    if ((_4270 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _4265;\n        float _3136 = fa_shadow_factor(param_4, param_5);\n        _4262 = _3136;\n        _4260 *= _3136;\n    }\n    else\n    {\n        bool _3147 = _4270 != 0;\n        bool _3153;\n        if (_3147)\n        {\n            _3153 = _4267 > 0.0f;\n        }\n        else\n        {\n            _3153 = _3147;\n        }\n        if (_3153)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _4265;\n            float _3165 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _4262 = _3165;\n            _4260 *= _3165;\n        }\n    }\n    LightSample _4277 = { _4265, _4260, _4267, _4262, _3122._distance, _4270 };\n    return _4277;\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _3182 = n < 0;\n    bool _3189;\n    if (!_3182)\n    {\n        _3189 = n >= fa_light_count();\n    }\n    else\n    {\n        _3189 = _3182;\n    }\n    if (_3189)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    return fa_light_shadowed(param_1, param_2, param_3);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _2445 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _2453 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _2456 = int(_2445);\n    int _2459 = int(_2453);\n    float _2469 = _2453 - float(_2459);\n    int _2525 = (_2456 * 9) + _2459;\n    int _2545 = ((_2456 + 1) * 9) + _2459;\n    return lerp(lerp(_2520[_2525], _2520[_2525 + 1], _2469), lerp(_2520[_2545], _2520[_2545 + 1], _2469), _2445 - float(_2456));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _4126 = false;\n    float _4127 = 1.0f;\n    float _4128 = 1.0f;\n    float _4129 = 1.0f;\n    float _4130 = 0.0f;\n    float _4131 = 0.0f;\n    float _4132 = 0.0f;\n    float _4133 = 0.0f;\n    float _4135 = 1.0f;\n    bool _4136 = false;\n    float3 _4137 = 0.0f.xxx;\n    float _4138 = 1.0f;\n    float _4139 = 1.0f;\n    float _4140 = 1.0f;\n    float _4141 = 0.0f;\n    float _4142 = 0.0f;\n    float3 _4143 = float3(1.0f, 0.0f, 0.0f);\n    float3 _4144 = float3(0.0f, 0.0f, 1.0f);\n    float _4145 = 1.0f;\n    float _4146 = 1.0f;\n    float _2598 = clamp(s.specular, 0.0f, 1.0f);\n    float _2602 = clamp(s.ior, 1.0f, 3.0f);\n    bool _2607 = (_2598 != 1.0f) || (_2602 != 1.5f);\n    bool _2617;\n    if (!_2607)\n    {\n        _2617 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _2617 = _2607;\n    }\n    if (_2617)\n    {\n        float _2625 = (_2602 - 1.0f) / (_2602 + 1.0f);\n        f0 = lerp(min((_2625 * _2625).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _2598, s.albedo, metallic.xxx);\n        _4127 = lerp(_2598, 1.0f, metallic);\n        _4126 = true;\n    }\n    float _2653 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_2653 > 0.0f)\n    {\n        float _2661 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _4130 = _2653;\n        _4131 = _2661;\n        float _2668 = _2661 * _2661;\n        _4132 = _2668;\n        _4133 = _2668 * _2668;\n        float _2680 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _4135 = _2680;\n        _4128 = 1.0f - (_2653 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _2680, 0.0f, 1.0f), 5.0f))));\n        _4126 = true;\n    }\n    float3 _2700 = max(s.sheen_color, 0.0f.xxx);\n    float _2709 = max(_2700.x, max(_2700.y, _2700.z));\n    if (_2709 > 0.0f)\n    {\n        float _2717 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _4136 = true;\n        _4137 = _2700;\n        _4138 = _2717;\n        _4139 = _2717 * _2717;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _2717;\n        float _2734 = fa_sheen_albedo(param, param_1);\n        _4141 = _2734;\n        _4140 = 1.0f - min(_2709 * _2734, 1.0f);\n        _4126 = true;\n    }\n    _4129 = _4128 * _4140;\n    float _2753 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_2753 != 0.0f)\n    {\n        float3 _2768 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2768;\n        if (dot(_2768, _2768) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _2781 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_2781.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _2781.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _2781.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _2785 = t;\n        float3 _2786 = normalize(_2785);\n        t = _2786;\n        float3 _2811 = normalize((_2786 * cos(s.anisotropy_rotation)) + ((cross(n, _2786) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _4143 = _2811;\n        _4144 = cross(n, _2811);\n        float _2821 = roughness * roughness;\n        float _2827 = lerp(_2821, 1.0f, _2753 * _2753);\n        bool _2829 = _2753 > 0.0f;\n        _4145 = _2829 ? _2827 : _2821;\n        _4146 = _2829 ? _2821 : _2827;\n        _4142 = _2753;\n        _4126 = true;\n    }\n    FaLayers _4168 = { _4126, _4127, _4128, _4129, _4130, _4131, _4132, _4133, i.world_normal, _4135, _4136, _4137, _4138, _4139, _4140, _4141, _4142, _4143, _4144, _4145, _4146 };\n    return _4168;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _2377 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _2380 = _2377.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_2380 * _2380, exp2((-9.27999973297119140625f) * ndv)) * _2380) + _2377.y)) + _2377.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_492_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _492_fa_env_horizon.w).xyz;\n    }\n    float _2301 = rough * rough;\n    float _2331 = 0.60000002384185791015625f * _2301;\n    return lerp(lerp(_492_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_492_fa_env_horizon.xyz, _492_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _2301)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _2331, 0.0500000007450580596923828125f + _2331, d.y).xxx), ((_492_fa_env_sky.xyz + _492_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_2301 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _2862;\n        if (L.aniso >= 0.0f)\n        {\n            _2862 = L.b;\n        }\n        else\n        {\n            _2862 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_2862, v), _2862), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _2895 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _2895.x) + (L.f90.xxx * _2895.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2950 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _2950.x) + _2950.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _2419 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _2419.x) + _2419.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _2989 = clamp(s.metallic, 0.0f, 1.0f);\n    float _2993 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _3000 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _2989.xxx);\n    float3 f0 = _3000;\n    float3 _3004 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _3004;\n    float3 param_3 = i.view_dir;\n    float param_4 = _2989;\n    float param_5 = _2993;\n    float3 param_6 = _3000;\n    FaLayers _3021 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_3021.on)\n    {\n        FaLayers param_7 = _3021;\n        float3 param_8 = _3004;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _2993;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _3004;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _2993;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0f;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _3270 = dot(fa_light_unshadowed(param, param_1).color, float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));\n        if (_3270 > bestPower)\n        {\n            bestPower = _3270;\n            best = n;\n        }\n    }\n    float3 lit = (_492_fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _3299 = fa_light(param_2, param_3);\n        float _3307;\n        if (dot(s.normal, _3299.direction) > 0.5f)\n        {\n            _3307 = 1.0f;\n        }\n        else\n        {\n            _3307 = _3313_dark;\n        }\n        lit += ((s.albedo * _3299.color) * _3307);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * _3313_skyAmount);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_1232_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _2189 = int(_1232_fa_shadow_cfg.x + 0.5f);\n    float _2199 = dot(world - _1232_fa_shadow_eye.xyz, _1232_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _2204 = _2189 > 0;\n    bool _2213;\n    if (_2204)\n    {\n        int param = _2189 - 1;\n        _2213 = _2199 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2213 = _2204;\n    }\n    if (_2213)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _2220 = _2189 > 1;\n        bool _2227;\n        if (_2220)\n        {\n            _2227 = _2199 > _1232_fa_shadow_split.x;\n        }\n        else\n        {\n            _2227 = _2220;\n        }\n        if (_2227)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _2233 = _2189 > 2;\n        bool _2240;\n        if (_2233)\n        {\n            _2240 = _2199 > _1232_fa_shadow_split.y;\n        }\n        else\n        {\n            _2240 = _2233;\n        }\n        if (_2240)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _2246 = _2189 > 3;\n        bool _2253;\n        if (_2246)\n        {\n            _2253 = _2199 > _1232_fa_shadow_split.z;\n        }\n        else\n        {\n            _2253 = _2246;\n        }\n        if (_2253)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _4000 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4000 = -_4000;\n    }\n    float3 _3687 = normalize(_492_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _4013 = { fa_world_pos, _4000, fa_world_tangent, fa_uv, fa_vertex_color, _3687, gl_FrontFacing };\n    SurfaceInput param_1 = _4013;\n    Surface _3695 = fa_standard_surface(param_1);\n    float3 _4031 = _3695.albedo;\n    float _4032 = _3695.alpha;\n    float3 _4033 = _3695.normal;\n    float _4034 = _3695.metallic;\n    float _4035 = _3695.roughness;\n    float _4036 = _3695.occlusion;\n    float3 _4037 = _3695.emission;\n    float _4038 = _3695.clearcoat;\n    float _4039 = _3695.clearcoat_roughness;\n    float3 _4040 = _3695.sheen_color;\n    float _4041 = _3695.sheen_roughness;\n    float _4042 = _3695.anisotropy;\n    float _4043 = _3695.anisotropy_rotation;\n    float _4044 = _3695.specular;\n    float _4045 = _3695.ior;\n    float3 _4046 = _3695.specular_color;\n    SurfaceInput _4021 = { fa_world_pos, _4000, fa_world_tangent, fa_uv, fa_vertex_color, _3687, gl_FrontFacing };\n    SurfaceInput param_2 = _4021;\n    Surface param_3 = _3695;\n    surface(param_2, param_3);\n    _4031 = param_3.albedo;\n    _4032 = param_3.alpha;\n    _4033 = param_3.normal;\n    _4034 = param_3.metallic;\n    _4035 = param_3.roughness;\n    _4036 = param_3.occlusion;\n    _4037 = param_3.emission;\n    _4038 = param_3.clearcoat;\n    _4039 = param_3.clearcoat_roughness;\n    _4040 = param_3.sheen_color;\n    _4041 = param_3.sheen_roughness;\n    _4042 = param_3.anisotropy;\n    _4043 = param_3.anisotropy_rotation;\n    _4044 = param_3.specular;\n    _4045 = param_3.ior;\n    _4046 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _4000;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4031 = param_6;\n    _4033 = param_7;\n    float3 result;\n    if (_492_fa_emissive.w > 0.5f)\n    {\n        result = _4031;\n    }\n    else\n    {\n        float3 _3733 = _4033;\n        float3 _3734 = normalize(_3733);\n        _4033 = _3734;\n        SurfaceInput _4029 = { fa_world_pos, _4000, fa_world_tangent, fa_uv, fa_vertex_color, _3687, gl_FrontFacing };\n        SurfaceInput param_8 = _4029;\n        Surface _4112 = { _4031, _4032, _3734, _4034, _4035, _4036, _4037, _4038, _4039, _4040, _4041, _4042, _4043, _4044, _4045, _4046 };\n        Surface param_9 = _4112;\n        result = lighting(param_8, param_9);\n    }\n    float3 _3749 = result;\n    float3 _3750 = _3749 + _4037;\n    result = _3750;\n    float3 param_10 = _3750;\n    float3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _3759 = _492_fa_fog.w > 0.0f;\n    bool _3766;\n    if (!_3759)\n    {\n        _3766 = _492_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _3766 = _3759;\n    }\n    if (_3766)\n    {\n        float3 _3775 = fa_world_pos - _492_fa_camera_pos.xyz;\n        float _3781 = dot(_3775, _492_fa_fog_c.xyz);\n        bool _3785 = _492_fa_fog_c.w > 0.5f;\n        float _3786;\n        if (_3785)\n        {\n            _3786 = _3781;\n        }\n        else\n        {\n            _3786 = length(_3775);\n        }\n        float _3798 = _3786 - _492_fa_fog_b.x;\n        if (_3798 > 0.0f)\n        {\n            float _3807 = _492_fa_fog.w * _3798;\n            float tau = _3807 * _3807;\n            if (_492_fa_fog_b.y > 0.0f)\n            {\n                float _3823;\n                if (_3785)\n                {\n                    _3823 = fa_world_pos.y - (_492_fa_fog_c.y * _3781);\n                }\n                else\n                {\n                    _3823 = _492_fa_camera_pos.y;\n                }\n                float _3844 = lerp(_3823, fa_world_pos.y, clamp(_492_fa_fog_b.x / _3786, 0.0f, 1.0f));\n                float _3848 = fa_world_pos.y - _3844;\n                float _3853 = _3844 - _492_fa_fog_b.z;\n                float _3858 = fa_world_pos.y - _492_fa_fog_b.z;\n                bool _3861 = _3853 <= 0.0f;\n                bool _3862 = !_3861;\n                bool _3868;\n                if (_3862)\n                {\n                    _3868 = _492_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3868 = _3861;\n                }\n                float _3869;\n                if (_3868)\n                {\n                    _3869 = _492_fa_fog_b.y;\n                }\n                else\n                {\n                    _3869 = _492_fa_fog_b.y * exp(-min(_492_fa_fog_b.w * _3853, 80.0f));\n                }\n                bool _3896;\n                if (_3862)\n                {\n                    _3896 = _492_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3896 = _3861;\n                }\n                float _3897;\n                if (_3896)\n                {\n                    _3897 = _492_fa_fog_b.y * _3853;\n                }\n                else\n                {\n                    _3897 = (_492_fa_fog_b.y * (1.0f - exp(-min(_492_fa_fog_b.w * _3853, 80.0f)))) / _492_fa_fog_b.w;\n                }\n                bool _3922 = _3858 <= 0.0f;\n                bool _3929;\n                if (!_3922)\n                {\n                    _3929 = _492_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3929 = _3922;\n                }\n                float _3930;\n                if (_3929)\n                {\n                    _3930 = _492_fa_fog_b.y * _3858;\n                }\n                else\n                {\n                    _3930 = (_492_fa_fog_b.y * (1.0f - exp(-min(_492_fa_fog_b.w * _3858, 80.0f)))) / _492_fa_fog_b.w;\n                }\n                float _3957;\n                if (abs(_3848) < 0.001000000047497451305389404296875f)\n                {\n                    _3957 = _3869;\n                }\n                else\n                {\n                    _3957 = (_3930 - _3897) / _3848;\n                }\n                tau += (_3798 * max(_3957, 0.0f));\n            }\n            result = lerp(result, _492_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4032);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_492",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1232",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_3313",
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
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
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
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _295 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _295;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _302 = _160.world_pos;\n    float4 _171 = float4(_302, 1.0f);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -mul(_171, _131_fa_light_vp).z;\n    fa_pre_r0 = float3(_131_fa_light_vp[0].x, _131_fa_light_vp[1].x, _131_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131_fa_light_vp[0].y, _131_fa_light_vp[1].y, _131_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131_fa_light_vp[0].z, _131_fa_light_vp[1].z, _131_fa_light_vp[2].z);\n    gl_Position = mul(_171, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _786 = base_t;\n    _786.x = _225.x;\n    _786.y = _225.y;\n    _786.z = _225.z;\n    base_t = _786;\n    float4 _241 = (_786 * _213_fa_base_color) * i.vertex_color;\n    float3 _749 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _794 = _279;\n        _794.x = _284.x;\n        _794.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _794;\n        _749 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _797 = mrt;\n    _797.x = _313.x;\n    _797.y = _313.y;\n    _797.z = _313.z;\n    mrt = _797;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _754 = _213_fa_layers_a.x;\n    float _755 = _213_fa_layers_a.y;\n    float _758 = _213_fa_layers_a.z;\n    float _757 = _213_fa_layers_b.w;\n    float _760 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _754 *= _355.y;\n            _755 *= _355.z;\n            _757 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _758 *= mrt.x;\n            _760 *= mrt.w;\n        }\n    }\n    Surface _779 = { _241.xyz, _241.w, _749, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _754, _755, _213_fa_layers_b.xyz, _757, _758, _213_fa_layers_a.w, _760, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _779;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _660 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _660 = -_660;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _673 = { fa_world_pos, _660, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _673;\n    SurfaceInput _681 = { fa_world_pos, _660, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _681;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _786 = base_t;\n    _786.x = _225.x;\n    _786.y = _225.y;\n    _786.z = _225.z;\n    base_t = _786;\n    float4 _241 = (_786 * _213_fa_base_color) * i.vertex_color;\n    float3 _749 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _794 = _279;\n        _794.x = _284.x;\n        _794.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _794;\n        _749 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _797 = mrt;\n    _797.x = _313.x;\n    _797.y = _313.y;\n    _797.z = _313.z;\n    mrt = _797;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _754 = _213_fa_layers_a.x;\n    float _755 = _213_fa_layers_a.y;\n    float _758 = _213_fa_layers_a.z;\n    float _757 = _213_fa_layers_b.w;\n    float _760 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _754 *= _355.y;\n            _755 *= _355.z;\n            _757 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _758 *= mrt.x;\n            _760 *= mrt.w;\n        }\n    }\n    Surface _779 = { _241.xyz, _241.w, _749, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _754, _755, _213_fa_layers_b.xyz, _757, _758, _213_fa_layers_a.w, _760, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _779;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _660 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _660 = -_660;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _673 = { fa_world_pos, _660, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _673;\n    SurfaceInput _681 = { fa_world_pos, _660, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _681;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
