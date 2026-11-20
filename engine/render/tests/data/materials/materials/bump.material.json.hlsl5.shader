{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "27973f29289cdb06f6da050426786ada05329a25848bb279986221a7a56fee4b",
  "slang": "hlsl5",
  "params": [
    "lift"
  ],
  "textures": [
    "height"
  ],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_material_vs : register(b4)\n{\n    float _63_lift : packoffset(c0);\n    float _63_fa_pad0 : packoffset(c0.y);\n    float _63_fa_pad1 : packoffset(c0.z);\n    float _63_fa_pad2 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _160_fa_view_proj : packoffset(c0);\n    row_major float4x4 _160_fa_light_vp : packoffset(c4);\n    float4 _160_fa_uv_scale : packoffset(c8);\n    float4 _160_fa_time : packoffset(c9);\n    float4 _160_fa_lm_so : packoffset(c10);\n};\n\nTexture2D<float4> fa_vs_height : register(t0);\nSamplerState fa_vs_height_smp : register(s6);\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _103 = cross(model[1].xyz, model[2].xyz);\n    float _108 = (dot(model[0].xyz, _103) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _293 = { mul(float4(position, 1.0f), model).xyz, (((_103 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _108, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _108), texcoord0 * _160_fa_uv_scale.xy, color, position };\n    return _293;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += (fa_vs_height.SampleLevel(fa_vs_height_smp, v.uv, 0.0f).x * _63_lift);\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _160_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _3653[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _556_fa_camera_pos : packoffset(c0);\n    float4 _556_fa_ambient : packoffset(c1);\n    float4 _556_fa_base_color : packoffset(c2);\n    float4 _556_fa_emissive : packoffset(c3);\n    float4 _556_fa_model_emissive : packoffset(c4);\n    float4 _556_fa_pbr : packoffset(c5);\n    float4 _556_fa_maps : packoffset(c6);\n    float4 _556_fa_fog : packoffset(c7);\n    float4 _556_fa_fog_b : packoffset(c8);\n    float4 _556_fa_fog_c : packoffset(c9);\n    float4 _556_fa_counts : packoffset(c10);\n    float4 _556_fa_env_sky : packoffset(c11);\n    float4 _556_fa_env_horizon : packoffset(c12);\n    float4 _556_fa_time : packoffset(c13);\n    float4 _556_fa_cl_vpx : packoffset(c14);\n    float4 _556_fa_cl_vpy : packoffset(c15);\n    float4 _556_fa_cl_vpw : packoffset(c16);\n    float4 _556_fa_cl_fwd : packoffset(c17);\n    float4 _556_fa_cl_grid : packoffset(c18);\n    float4 _556_fa_cl_info : packoffset(c19);\n    float4 _556_fa_layers_a : packoffset(c20);\n    float4 _556_fa_layers_b : packoffset(c21);\n    float4 _556_fa_layers_c : packoffset(c22);\n    float4 _556_fa_layers_d : packoffset(c23);\n    float4 _556_fa_ct_a : packoffset(c24);\n    float4 _556_fa_ct_b : packoffset(c25);\n    float4 _556_fa_ct_vpx : packoffset(c26);\n    float4 _556_fa_ct_vpy : packoffset(c27);\n    float4 _556_fa_ct_vpw : packoffset(c28);\n    float4 _556_fa_ct_fwd : packoffset(c29);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2223_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2223_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2223_fa_shadow_info[4] : packoffset(c20);\n    float4 _2223_fa_shadow_split : packoffset(c24);\n    float4 _2223_fa_shadow_cfg : packoffset(c25);\n    float4 _2223_fa_shadow_bias : packoffset(c26);\n    float4 _2223_fa_shadow_eye : packoffset(c27);\n    float4 _2223_fa_shadow_fwd : packoffset(c28);\n    float4 _2223_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t11);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t7);\nTexture2D<float4> fa_screen_tex : register(t12);\nTexture2D<float4> height : register(t6);\nSamplerState height_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t10);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1494 = _556_fa_cl_info.x < 0.0f;\n    bool _1501;\n    if (!_1494)\n    {\n        _1501 = _556_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1501 = _1494;\n    }\n    bool _1509;\n    if (!_1501)\n    {\n        _1509 = _556_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1509 = _1501;\n    }\n    bool _1516;\n    if (!_1509)\n    {\n        _1516 = _556_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1516 = _1509;\n    }\n    bool _1523;\n    if (!_1516)\n    {\n        _1523 = _556_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1523 = _1516;\n    }\n    if (_1523)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1533 = float4(world_pos, 1.0f);\n    float _1539 = dot(_556_fa_cl_vpw, _1533);\n    if (!(_1539 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1561 = float2(dot(_556_fa_cl_vpx, _1533), dot(_556_fa_cl_vpy, _1533)) / _1539.xx;\n    int _1565 = int(_556_fa_cl_grid.x);\n    int _1569 = int(_556_fa_cl_grid.y);\n    int param = (int(_556_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_556_fa_cl_fwd.xyz, world_pos) + _556_fa_cl_fwd.w, _556_fa_cl_grid.w) / _556_fa_cl_grid.w) * _556_fa_cl_grid.z)), 0, int(_556_fa_cl_info.y) - 1) * _1569) + clamp(int(floor(((_1561.y * 0.5f) + 0.5f) * _556_fa_cl_grid.y)), 0, _1569 - 1)) * _1565)) + clamp(int(floor(((_1561.x * 0.5f) + 0.5f) * _556_fa_cl_grid.x)), 0, _1565 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1645 = fa_cluster_texel(param);\n    return int2(int(_1645.x), int(_1645.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_556_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4723 = fa_cluster_lookup(param);\n    fa_cl_slot = _4723.x;\n    fa_cl_local = _4723.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _5866 = fa_linear_to_srgb(param);\n        c = _5866;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _5874 = fa_srgb_to_linear(param_1);\n            c = _5874;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _439;\n    if (i.front_facing)\n    {\n        _439 = i.world_normal;\n    }\n    else\n    {\n        _439 = -i.world_normal;\n    }\n    float3 _463 = normalize(i.world_tangent.xyz - (_439 * dot(_439, i.world_tangent.xyz)));\n    float3 _490 = normalize(((_463 * m.x) + ((cross(_439, _463) * i.world_tangent.w) * m.y)) + (_439 * m.z));\n    float3 _493;\n    if (i.front_facing)\n    {\n        _493 = _490;\n    }\n    else\n    {\n        _493 = -_490;\n    }\n    return _493;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _556_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _5905 = fa_tex_fix(param_2, param_3);\n    float4 _7336 = base_t;\n    _7336.x = _5905.x;\n    _7336.y = _5905.y;\n    _7336.z = _5905.z;\n    base_t = _7336;\n    float4 _5919 = (_7336 * _556_fa_base_color) * i.vertex_color;\n    float3 _7161 = i.world_normal;\n    if (_556_fa_maps.z > 0.5f)\n    {\n        float param_4 = _556_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _5951 = fa_tex_fix(param_6, param_7);\n        float3 _5954 = (_5951 * 2.0f) - 1.0f.xxx;\n        float2 _5959 = _5954.xy * _556_fa_maps.x;\n        float3 _7344 = _5954;\n        _7344.x = _5959.x;\n        _7344.y = _5959.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _7344;\n        _7161 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _556_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _5987 = fa_tex_fix(param_12, param_13);\n    float4 _7347 = mrt;\n    _7347.x = _5987.x;\n    _7347.y = _5987.y;\n    _7347.z = _5987.z;\n    mrt = _7347;\n    float4 _6015 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _556_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _6015.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _6026 = fa_tex_fix(param_16, param_17);\n    float param_18 = _556_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _6056 = fa_tex_fix(param_20, param_21);\n    float _7166 = _556_fa_layers_a.x;\n    float _7167 = _556_fa_layers_a.y;\n    float _7170 = _556_fa_layers_a.z;\n    float _7169 = _556_fa_layers_b.w;\n    float _7172 = _556_fa_layers_c.x;\n    if (_556_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_556_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _7166 *= _6026.y;\n            _7167 *= _6026.z;\n            _7169 *= _6015.w;\n        }\n        if (_556_fa_layers_c.z > 1.5f)\n        {\n            _7170 *= mrt.x;\n            _7172 *= mrt.w;\n        }\n    }\n    Surface _7191 = { _5919.xyz, _5919.w, _7161, clamp(_556_fa_pbr.x * _5987.z, 0.0f, 1.0f), clamp(_556_fa_pbr.y * _5987.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_556_fa_maps.y * (_6026.x - 1.0f)), _556_fa_emissive.xyz + (_556_fa_model_emissive.xyz * _6056), _7166, _7167, _556_fa_layers_b.xyz, _7169, _7170, _556_fa_layers_a.w, _7172, _556_fa_layers_c.y, _556_fa_layers_d.xyz };\n    return _7191;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.albedo *= lerp(0.5f, 1.0f, height.Sample(height_smp, i.uv).x);\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1725 = rect.zw - rect.xy;\n    float2 _1729 = _1725 * atlas;\n    float2 _1733 = ddx * _1729;\n    float2 _1737 = ddy * _1729;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1725), clamp(0.5f * log2(max(max(dot(_1733, _1733), dot(_1737, _1737)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1770 = _556_fa_counts.y < 0.5f;\n    bool _1777;\n    if (!_1770)\n    {\n        _1777 = _556_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1777 = _1770;\n    }\n    if (_1777)\n    {\n        return;\n    }\n    float3 _1783 = ddx(world_pos);\n    float3 _1786 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1790 = fa_cluster_texel(param);\n    int _1794 = int(_1790.w);\n    if (_1794 < 1)\n    {\n        return;\n    }\n    int _1804 = int(_556_fa_counts.y + 0.5f);\n    int param_1 = _1804;\n    float4 _1808 = fa_light_texel(param_1);\n    float2 _1811 = _1808.yz;\n    int _1815 = int(_1808.w);\n    int param_2 = _1804 + 1;\n    float4 _1820 = fa_light_texel(param_2);\n    float _1821 = _1820.x;\n    int _1827 = int(_556_fa_counts.w + 0.5f) - 1;\n    int _1831 = int(_1790.z);\n    float3 _2096;\n    for (int k = 0; k < _1794; k++)\n    {\n        int _1844 = _1831 + k;\n        int param_3 = _1815 + (_1844 >> 2);\n        int _1861 = (_1804 + 2) + (int(fa_light_texel(param_3)[_1844 & 3]) * 7);\n        int param_4 = _1861 + 6;\n        float4 _1866 = fa_light_texel(param_4);\n        if (((int(_1866.w + 0.5f) >> _1827) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1861;\n        float4 _1881 = fa_light_texel(param_5);\n        int param_6 = _1861 + 1;\n        float4 _1886 = fa_light_texel(param_6);\n        int param_7 = _1861 + 2;\n        float4 _1891 = fa_light_texel(param_7);\n        float3 _1894 = _1881.xyz;\n        float _1899 = dot(_1894, world_pos) + _1881.w;\n        float3 _1901 = _1886.xyz;\n        float _1906 = dot(_1901, world_pos) + _1886.w;\n        float3 _1908 = _1891.xyz;\n        float _1913 = dot(_1908, world_pos) + _1891.w;\n        bool _1918 = abs(_1899) > 0.5f;\n        bool _1926;\n        if (!_1918)\n        {\n            _1926 = abs(_1906) > 0.5f;\n        }\n        else\n        {\n            _1926 = _1918;\n        }\n        bool _1934;\n        if (!_1926)\n        {\n            _1934 = abs(_1913) > 0.5f;\n        }\n        else\n        {\n            _1934 = _1926;\n        }\n        if (_1934)\n        {\n            continue;\n        }\n        float _1949 = clamp(dot(geo_normal, normalize(_1908)) * _1866.z, 0.0f, 1.0f);\n        if (_1949 <= 0.0f)\n        {\n            continue;\n        }\n        float _1969 = (clamp((0.5f - abs(_1913)) * 10.0f, 0.0f, 1.0f) * _1949) * _1866.x;\n        float2 _1977 = float2(_1899 + 0.5f, 0.5f - _1906);\n        float2 _1987 = float2(dot(_1894, _1783), dot(_1901, _1783));\n        float2 _1997 = float2(dot(_1894, _1786), dot(_1901, _1786));\n        int param_8 = _1861 + 5;\n        float4 _2002 = fa_light_texel(param_8);\n        int param_9 = _1861 + 3;\n        float4 _2007 = fa_light_texel(param_9);\n        int param_10 = _1861 + 4;\n        float4 _2012 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _2002.xyz;\n        bool _2022 = _2007.z > _2007.x;\n        if (_2022)\n        {\n            float4 param_11 = _2007;\n            float2 param_12 = _1977;\n            float2 param_13 = _1811;\n            float2 param_14 = _1987;\n            float2 param_15 = _1997;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1821 > 0.5f) && (_1821 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _2048 = fa_dc_to_linear(param_16);\n                float4 _7241 = tx;\n                _7241.x = _2048.x;\n                _7241.y = _2048.y;\n                _7241.z = _2048.z;\n                tx = _7241;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1969 * tex_a) * _2002.w, 0.0f, 1.0f).xxx);\n        if (_2012.z > _2012.x)\n        {\n            float4 param_17 = _2012;\n            float2 param_18 = _1977;\n            float2 param_19 = _1811;\n            float2 param_20 = _1987;\n            float2 param_21 = _1997;\n            float4 _2092 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1821 > 1.5f)\n            {\n                float3 param_22 = _2092.xyz;\n                float3 _2102 = fa_dc_to_srgb(param_22);\n                _2096 = _2102;\n            }\n            else\n            {\n                _2096 = _2092.xyz;\n            }\n            float3 _2111 = (_2096 * 2.0f) - 1.0f.xxx;\n            float2 _2116 = _2111.xy * _1866.y;\n            float3 _2138 = (normalize(_1894) * _2116.x) + (normalize(_1901) * _2116.y);\n            float3 _2141 = normalize(normal);\n            normal = normalize(lerp(_2141, normalize((_2141 * max(_2111.z, 0.0500000007450580596923828125f)) + (_2138 - (_2141 * dot(_2141, _2138)))), clamp(_1969 * (_2022 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3579 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3586 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3589 = int(_3579);\n    int _3592 = int(_3586);\n    float _3602 = _3586 - float(_3592);\n    int _3657 = (_3589 * 9) + _3592;\n    int _3677 = ((_3589 + 1) * 9) + _3592;\n    return lerp(lerp(_3653[_3657], _3653[_3657 + 1], _3602), lerp(_3653[_3677], _3653[_3677 + 1], _3602), _3579 - float(_3589));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _7084 = false;\n    float _7085 = 1.0f;\n    float _7086 = 1.0f;\n    float _7087 = 1.0f;\n    float _7088 = 0.0f;\n    float _7089 = 0.0f;\n    float _7090 = 0.0f;\n    float _7091 = 0.0f;\n    float _7093 = 1.0f;\n    bool _7094 = false;\n    float3 _7095 = 0.0f.xxx;\n    float _7096 = 1.0f;\n    float _7097 = 1.0f;\n    float _7098 = 1.0f;\n    float _7099 = 0.0f;\n    float _7100 = 0.0f;\n    float3 _7101 = float3(1.0f, 0.0f, 0.0f);\n    float3 _7102 = float3(0.0f, 0.0f, 1.0f);\n    float _7103 = 1.0f;\n    float _7104 = 1.0f;\n    float _3728 = clamp(s.specular, 0.0f, 1.0f);\n    float _3732 = clamp(s.ior, 1.0f, 3.0f);\n    bool _3737 = (_3728 != 1.0f) || (_3732 != 1.5f);\n    bool _3746;\n    if (!_3737)\n    {\n        _3746 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _3746 = _3737;\n    }\n    if (_3746)\n    {\n        float _3754 = (_3732 - 1.0f) / (_3732 + 1.0f);\n        f0 = lerp(min((_3754 * _3754).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _3728, s.albedo, metallic.xxx);\n        _7085 = lerp(_3728, 1.0f, metallic);\n        _7084 = true;\n    }\n    float _3781 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_3781 > 0.0f)\n    {\n        float _3789 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _7088 = _3781;\n        _7089 = _3789;\n        float _3796 = _3789 * _3789;\n        _7090 = _3796;\n        _7091 = _3796 * _3796;\n        float _3808 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _7093 = _3808;\n        _7086 = 1.0f - (_3781 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _3808, 0.0f, 1.0f), 5.0f))));\n        _7084 = true;\n    }\n    float3 _3827 = max(s.sheen_color, 0.0f.xxx);\n    float _3836 = max(_3827.x, max(_3827.y, _3827.z));\n    if (_3836 > 0.0f)\n    {\n        float _3844 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _7094 = true;\n        _7095 = _3827;\n        _7096 = _3844;\n        _7097 = _3844 * _3844;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _3844;\n        float _3861 = fa_sheen_albedo(param, param_1);\n        _7099 = _3861;\n        _7098 = 1.0f - min(_3836 * _3861, 1.0f);\n        _7084 = true;\n    }\n    _7087 = _7086 * _7098;\n    float _3880 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_3880 != 0.0f)\n    {\n        float3 _3895 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _3895;\n        if (dot(_3895, _3895) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _3907 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_3907.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _3907.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _3907.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _3911 = t;\n        float3 _3912 = normalize(_3911);\n        t = _3912;\n        float3 _3937 = normalize((_3912 * cos(s.anisotropy_rotation)) + ((cross(n, _3912) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _7101 = _3937;\n        _7102 = cross(n, _3937);\n        float _3947 = roughness * roughness;\n        float _3953 = lerp(_3947, 1.0f, _3880 * _3880);\n        bool _3955 = _3880 > 0.0f;\n        _7103 = _3955 ? _3953 : _3947;\n        _7104 = _3955 ? _3947 : _3953;\n        _7100 = _3880;\n        _7084 = true;\n    }\n    FaLayers _7126 = { _7084, _7085, _7086, _7087, _7088, _7089, _7090, _7091, i.world_normal, _7093, _7094, _7095, _7096, _7097, _7098, _7099, _7100, _7101, _7102, _7103, _7104 };\n    return _7126;\n}\n\nfloat3 fa_sky_sh_coef(int k)\n{\n    float3 v = fa_env_tex.SampleLevel(fa_env_smp, float3(1.0f, 1.0f - (float((2 * (k >> 2)) + 1) * 0.25f), 1.0f - (float((2 * (k & 3)) + 1) * 0.25f)), 5.0f).xyz;\n    if (_556_fa_env_sky.w > 1.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3336 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3336;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_556_fa_env_sky.w > 0.5f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _556_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_556_fa_cl_info.x) + int(_556_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_556_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _624_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _624_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _743 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _756 = (c - (ru * hx)) - p;\n        float3 _762 = ru * (2.0f * hx);\n        float _768 = max(dot(_762, _762), 9.9999999392252902907785028219223e-09f);\n        float _772 = dot(_756, _762);\n        float t = clamp((-_772) / _768, 0.0f, 1.0f);\n        if (_743)\n        {\n            float _787 = dot(r, _762);\n            float _793 = _768 - (_787 * _787);\n            if (abs(_793) > (9.9999997473787516355514526367188e-06f * _768))\n            {\n                t = clamp(((dot(r, _756) * _787) - _772) / _793, 0.0f, 1.0f);\n            }\n        }\n        return (p + _756) + (_762 * t);\n    }\n    float3 q = p;\n    float _825 = dot(r, axis);\n    bool _833;\n    if (_743)\n    {\n        _833 = abs(_825) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _833 = _743;\n    }\n    if (_833)\n    {\n        float _843 = dot(c - p, axis) / _825;\n        if (_843 > 0.0f)\n        {\n            q = p + (r * _843);\n        }\n    }\n    float3 _856 = q - c;\n    float2 xy = float2(dot(_856, ru), dot(_856, uu));\n    if (shape > 0.5f)\n    {\n        float _871 = length(xy);\n        if (_871 > hx)\n        {\n            xy *= (hx / _871);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _505 = abs(d);\n    float _507 = _505.x;\n    float _509 = _505.y;\n    bool _510 = _507 >= _509;\n    bool _518;\n    if (_510)\n    {\n        _518 = _507 >= _505.z;\n    }\n    else\n    {\n        _518 = _510;\n    }\n    int _519;\n    if (_518)\n    {\n        _519 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _534;\n        if (_509 >= _505.z)\n        {\n            _534 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _534 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _519 = _534;\n    }\n    return _519;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _663 = dot(d, right);\n    float _667 = dot(d, up);\n    float _678;\n    if (((_663 * _663) + (_667 * _667)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _678 = atan2(_667, _663) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _678 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_678 - floor(_678)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _909 = fa_light_base(param);\n    bool _913 = _556_fa_ambient.w > 4.5f;\n    int param_1 = _909;\n    float4 _917 = fa_light_texel(param_1);\n    int param_2 = _909 + 1;\n    float4 _922 = fa_light_texel(param_2);\n    float _925 = _922.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _937 = _913 && (_925 > 2.5f);\n    fa_light_is_area = _937;\n    bool _939 = _925 < 0.5f;\n    float3 l;\n    if (_939)\n    {\n        l = normalize(_917.xyz);\n        if (_913)\n        {\n            int param_3 = _909 + 6;\n            float4 _953 = fa_light_texel(param_3);\n            if (_953.z > 0.5f)\n            {\n                int param_4 = _909 + 4;\n                float4 _963 = fa_light_texel(param_4);\n                int param_5 = _909 + 5;\n                float4 _968 = fa_light_texel(param_5);\n                float2 param_6 = _953.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _963.xyz) * _963.w, (-dot(world_pos, _968.xyz)) * _968.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _998 = _917.xyz;\n        float3 _1000 = _998 - world_pos;\n        float3 to_light = _1000;\n        float _1003 = length(_1000);\n        float reach = _1003;\n        bool front = true;\n        if (_937)\n        {\n            int param_8 = _909 + 7;\n            reach = max(_1003 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _909 + 4;\n            float4 _1027 = fa_light_texel(param_9);\n            int param_10 = _909 + 5;\n            float4 _1032 = fa_light_texel(param_10);\n            int param_11 = _909 + 6;\n            float4 _1037 = fa_light_texel(param_11);\n            float _1038 = _1037.w;\n            int param_12 = _909 + 2;\n            float3 _1045 = normalize(fa_light_texel(param_12).xyz);\n            bool _1047 = _1038 > 1.5f;\n            bool _1055;\n            if (!_1047)\n            {\n                _1055 = dot(_1045, to_light) < 0.0f;\n            }\n            else\n            {\n                _1055 = _1047;\n            }\n            front = _1055;\n            float3 r = 0.0f.xxx;\n            float3 _1064 = _556_fa_camera_pos.xyz - world_pos;\n            bool _1068 = dot(n, n) > 0.5f;\n            bool _1076;\n            if (_1068)\n            {\n                _1076 = dot(_1064, _1064) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _1076 = _1068;\n            }\n            if (_1076)\n            {\n                r = reflect(-normalize(_1064), normalize(n));\n            }\n            float3 param_13 = _998;\n            float3 param_14 = _1045;\n            float3 param_15 = _1027.xyz;\n            float3 param_16 = _1032.xyz;\n            float param_17 = _1027.w;\n            float param_18 = _1032.w;\n            float param_19 = _1038;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1112 = length(to_light);\n        dist = _1112;\n        l = to_light / max(_1112, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1126 = reach / max(_917.w, 0.001000000047497451305389404296875f);\n        float _1132 = clamp(1.0f - (_1126 * _1126), 0.0f, 1.0f);\n        float _1134;\n        if (front)\n        {\n            _1134 = _1132 * _1132;\n        }\n        else\n        {\n            _1134 = 0.0f;\n        }\n        atten = _1134;\n        bool _1145 = _925 < 2.5f;\n        if ((_925 > 1.5f) && _1145)\n        {\n            int param_22 = _909 + 2;\n            float4 _1153 = fa_light_texel(param_22);\n            float _1163 = _1153.w;\n            int param_23 = _909 + 3;\n            float4 _1168 = fa_light_texel(param_23);\n            float _1169 = _1168.x;\n            float cos_inner = _1169;\n            if (_1169 > 1.5f)\n            {\n                cos_inner = lerp(_1163, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1163, cos_inner, dot(-l, normalize(_1153.xyz)));\n        }\n        if (_913 && (_925 < 1.5f))\n        {\n            int param_24 = _909 + 6;\n            float4 _1193 = fa_light_texel(param_24);\n            if (_1193.z > 0.5f)\n            {\n                float3 _1201 = -to_light;\n                int param_25 = _909 + 4;\n                int param_26 = _909 + 5;\n                float3 _1215 = fa_light_texel(param_25).xyz;\n                float3 _1219 = fa_light_texel(param_26).xyz;\n                float3 _1228 = float3(dot(_1201, _1215), dot(_1201, _1219), dot(_1201, cross(_1215, _1219)));\n                float3 param_27 = _1228;\n                int _1232 = fa_cube_face(param_27);\n                int param_28 = _1232;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1259 = float2(dot(_1228, cross(param_29, param_30)), dot(_1228, param_30)) / max(dot(_1228, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1263 = _1232 / 3;\n                float2 param_31 = _1193.xy + (float2(float(_1232 - (_1263 * 3)), float(_1263)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1259.x), 0.5f - (0.5f * _1259.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _909 + 7;\n            float4 _1293 = fa_light_texel(param_33);\n            if (_1293.z > 0.5f)\n            {\n                int param_34 = _909 + 2;\n                int param_35 = _909 + 4;\n                int param_36 = _909 + 5;\n                float2 param_37 = _1293.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_913 && _1145)\n            {\n                int param_42 = _909 + 6;\n                float4 _1340 = fa_light_texel(param_42);\n                int param_43 = _909 + 7;\n                float4 _1345 = fa_light_texel(param_43);\n                bool _1348 = _1340.z > 0.5f;\n                bool _1355;\n                if (!_1348)\n                {\n                    _1355 = _1345.z > 0.5f;\n                }\n                else\n                {\n                    _1355 = _1348;\n                }\n                if (_1355)\n                {\n                    int param_44 = _909 + 2;\n                    float4 _1362 = fa_light_texel(param_44);\n                    float3 _1366 = normalize(_1362.xyz);\n                    int param_45 = _909 + 4;\n                    float4 _1371 = fa_light_texel(param_45);\n                    int param_46 = _909 + 5;\n                    float4 _1376 = fa_light_texel(param_46);\n                    if (_1348)\n                    {\n                        float3 _1384 = -to_light;\n                        float _1391 = _1362.w;\n                        float _1407 = 0.5f / max(dot(_1384, _1366) * (sqrt(max(1.0f - (_1391 * _1391), 0.0f)) / max(_1391, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1340.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1384, _1371.xyz) * _1407), 0.5f - (dot(_1384, _1376.xyz) * _1407));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1345.z > 0.5f)\n                    {\n                        float2 param_49 = _1345.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1366;\n                        float3 param_52 = _1371.xyz;\n                        float3 param_53 = _1376.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _7072 = _922.xyz * atten;\n    if (_913)\n    {\n        _7072 *= fa_light_tint;\n    }\n    int _1476;\n    if (_939)\n    {\n        _1476 = 0;\n    }\n    else\n    {\n        _1476 = ((_925 > 1.5f) && (_925 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _7083 = { l, _7072, atten, 1.0f, dist, _1476 };\n    return _7083;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2213;\n    if (i == 0)\n    {\n        _2213 = _2223_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2229;\n        if (i == 1)\n        {\n            _2229 = _2223_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2237;\n            if (i == 2)\n            {\n                _2237 = _2223_fa_shadow_split.z;\n            }\n            else\n            {\n                _2237 = _2223_fa_shadow_split.w;\n            }\n            _2229 = _2237;\n        }\n        _2213 = _2229;\n    }\n    return _2213;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2270 = fa_shadow_depth(param, param_1);\n    float _2274;\n    if (conv.x < 0.5f)\n    {\n        _2274 = _2270;\n    }\n    else\n    {\n        _2274 = (conv.y * conv.z) / (conv.z - (_2270 * (conv.z - conv.y)));\n    }\n    return _2274;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2201 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2201), sin(_2201)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2320 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2329;\n        if (k < 0.0f)\n        {\n            _2329 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2329 = k;\n        }\n        float _2349 = clamp((_2329 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2320;\n            float2 _2368 = fa_shadow_vogel(param_3, param_4, param_5) * _2349;\n            float2 param_6 = uv + (_2368 * _2223_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2380 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2380 < (zr - (length(_2368) * plane)))\n            {\n                sum += _2380;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2406 = sum / cnt;\n        float _2416;\n        if (k < 0.0f)\n        {\n            _2416 = (-k) / max(_2406, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2416 = k;\n        }\n        radius = clamp(((max(zr - _2406, 0.0f) * unit) * _2416) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2438 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2438; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2438;\n        float param_11 = _2320;\n        float2 _2457 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2457 * _2223_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2457) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2438);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2499 = max(_2223_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2504 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2510 = sqrt(1.0f - (_2504 * _2504));\n    float _2517 = min(_2510 / max(_2504, 0.20000000298023223876953125f), 4.0f);\n    float _2522;\n    if (_2223_fa_shadow_bias.y > 0.0f)\n    {\n        _2522 = _2223_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2522 = 1.5f * _2223_fa_shadow_info[ci].x;\n    }\n    float4 _2547 = mul(float4(world + (n * (_2522 * _2510)), 1.0f), _2223_fa_shadow_mat[ci]);\n    float _2554 = _2547.x;\n    bool _2557 = _2554 < _2223_fa_shadow_rect[ci].x;\n    bool _2566;\n    if (!_2557)\n    {\n        _2566 = _2554 > _2223_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2566 = _2557;\n    }\n    bool _2575;\n    if (!_2566)\n    {\n        _2575 = _2547.y < _2223_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2575 = _2566;\n    }\n    bool _2584;\n    if (!_2575)\n    {\n        _2584 = _2547.y > _2223_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2584 = _2575;\n    }\n    bool _2591;\n    if (!_2584)\n    {\n        _2591 = _2547.z > 1.0f;\n    }\n    else\n    {\n        _2591 = _2584;\n    }\n    if (_2591)\n    {\n        return -1.0f;\n    }\n    float _2599;\n    if (_2223_fa_shadow_bias.x > 0.0f)\n    {\n        _2599 = _2223_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2599 = 1.5f * _2223_fa_shadow_info[ci].x;\n    }\n    float2 param = _2547.xy;\n    float4 param_1 = _2223_fa_shadow_rect[ci];\n    float param_2 = _2547.z - ((_2599 * (1.0f + (0.5f * _2517))) / _2499);\n    float param_3 = _2223_fa_shadow_info[ci].x;\n    float param_4 = _2499;\n    float param_5 = _2499 * 0.25f;\n    float param_6 = ((_2223_fa_shadow_info[ci].x * min(_2517, 3.0f)) * 0.5f) / _2499;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2223_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2223_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_556_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2977 = int(_2223_fa_shadow_cfg.x + 0.5f);\n    if (_2977 < 1)\n    {\n        return 1.0f;\n    }\n    float _2992 = dot(world - _2223_fa_shadow_eye.xyz, _2223_fa_shadow_fwd.xyz);\n    int param = _2977 - 1;\n    if (_2992 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _3004 = _2977 > 1;\n    bool _3011;\n    if (_3004)\n    {\n        _3011 = _2992 > _2223_fa_shadow_split.x;\n    }\n    else\n    {\n        _3011 = _3004;\n    }\n    if (_3011)\n    {\n        ci = 1;\n    }\n    bool _3015 = _2977 > 2;\n    bool _3022;\n    if (_3015)\n    {\n        _3022 = _2992 > _2223_fa_shadow_split.y;\n    }\n    else\n    {\n        _3022 = _3015;\n    }\n    if (_3022)\n    {\n        ci = 2;\n    }\n    bool _3026 = _2977 > 3;\n    bool _3033;\n    if (_3026)\n    {\n        _3033 = _2992 > _2223_fa_shadow_split.z;\n    }\n    else\n    {\n        _3033 = _3026;\n    }\n    if (_3033)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2977)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _3059 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3059;\n        if (_3059 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2223_fa_shadow_cfg.y > 0.0f)\n    {\n        float _3084;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3084 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3084 = _2223_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _3103 = _2223_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3084, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _3114 = clamp((_2992 - (fa_shadow_split_at(param_7) - _3103)) / _3103, 0.0f, 1.0f);\n        if (_3114 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2977)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _3135 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3135;\n                if (_3135 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _3114);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2657 = _556_fa_pbr.z < 0.5f;\n    bool _2664;\n    if (!_2657)\n    {\n        _2664 = _2223_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2664 = _2657;\n    }\n    if (_2664)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2223_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2677 = fa_light_texel(param);\n    float _2678 = _2677.x;\n    if (_2678 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2687 = int(_2678 + 0.5f);\n    int param_1 = _2687;\n    float4 _2691 = fa_light_texel(param_1);\n    int param_2 = _2687 + 1;\n    float4 _2696 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2699 = _2691.y;\n    if (_2699 > 0.0f)\n    {\n        float _2716 = 1.0f - smoothstep(0.75f * _2699, _2699, length(world - _2223_fa_shadow_eye.xyz));\n        fade = _2716;\n        if (_2716 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2691.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2740 = (_2687 + 2) + (face * 6);\n    int param_4 = _2740;\n    int param_5 = _2740 + 1;\n    int param_6 = _2740 + 3;\n    float4 _2754 = fa_light_texel(param_6);\n    int param_7 = _2740 + 4;\n    float4 _2759 = fa_light_texel(param_7);\n    int param_8 = _2740 + 5;\n    float4 _2764 = fa_light_texel(param_8);\n    float _2776 = _2764.x * max(dot(_2754, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2781 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2804 = clamp(dot(n, _2754.xyz), -1.0f, 1.0f);\n    float _2823 = min(sqrt(1.0f - (_2804 * _2804)) / max(abs(dot(n, world - lpos)) / max(dot(_2754, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2826 = _2696.y;\n    float _2828;\n    if (_2826 > 0.0f)\n    {\n        _2828 = _2826;\n    }\n    else\n    {\n        _2828 = 1.5f * _2776;\n    }\n    float4 _2848 = float4(world + (n * (_2828 * sqrt(1.0f - (_2781 * _2781)))), 1.0f);\n    float _2852 = dot(_2754, _2848);\n    float _2855 = _2764.y;\n    if (_2852 < _2855)\n    {\n        return 1.0f;\n    }\n    float2 _2870 = float2(dot(fa_light_texel(param_4), _2848), dot(fa_light_texel(param_5), _2848)) / _2852.xx;\n    float _2872 = _2870.x;\n    bool _2875 = _2872 < _2759.x;\n    bool _2884;\n    if (!_2875)\n    {\n        _2884 = _2872 > _2759.z;\n    }\n    else\n    {\n        _2884 = _2875;\n    }\n    bool _2893;\n    if (!_2884)\n    {\n        _2893 = _2870.y < _2759.y;\n    }\n    else\n    {\n        _2893 = _2884;\n    }\n    bool _2902;\n    if (!_2893)\n    {\n        _2902 = _2870.y > _2759.w;\n    }\n    else\n    {\n        _2902 = _2893;\n    }\n    if (_2902)\n    {\n        return 1.0f;\n    }\n    float _2908 = _2696.x;\n    float _2910;\n    if (_2908 > 0.0f)\n    {\n        _2910 = _2908;\n    }\n    else\n    {\n        _2910 = 1.5f * _2776;\n    }\n    float2 param_9 = _2870;\n    float4 param_10 = _2759;\n    float param_11 = _2852 - (_2910 * (1.0f + (0.5f * _2823)));\n    float param_12 = _2776;\n    float param_13 = 1.0f;\n    float param_14 = _2764.z * 0.25f;\n    float param_15 = (_2776 * min(_2823, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2855, _2764.z);\n    int param_17 = int(_2691.z + 0.5f);\n    float param_18 = _2691.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _4465 = _556_fa_ct_a.x < 0.5f;\n    bool _4472;\n    if (!_4465)\n    {\n        _4472 = _2223_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _4472 = _4465;\n    }\n    if (_4472)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2223_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _4485 = fa_light_texel(param);\n    float _4486 = _4485.y;\n    float len = _4486;\n    if (_4486 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4498 = length(world - _556_fa_camera_pos.xyz);\n    float _4508 = 1.0f - smoothstep(0.5f * _556_fa_ct_b.x, _556_fa_ct_b.x, _4498);\n    if (_4508 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4514 = len;\n    float _4517 = min(_4514, 0.89999997615814208984375f * dist);\n    len = _4517;\n    float _4522 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _4498);\n    float _4527 = _4522 + (0.5f * _4517);\n    float3 _4533 = world + (gn * _4522);\n    float _4535 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _4599;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4550 = (float(k) + _4535) * 0.083333335816860198974609375f;\n        float3 _4558 = _4533 + (l * (_4550 * len));\n        float4 _4564 = float4(_4558, 1.0f);\n        float _4570 = dot(_556_fa_ct_vpw, _4564);\n        if (_4570 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _4590 = float2(dot(_556_fa_ct_vpx, _4564), dot(_556_fa_ct_vpy, _4564)) / _4570.xx;\n        float _4594 = _4590.x * 0.5f;\n        float _4595 = _4594 + 0.5f;\n        if (_556_fa_ct_a.y > 0.5f)\n        {\n            _4599 = (_4590.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _4599 = 0.5f - (_4590.y * 0.5f);\n        }\n        bool _4615 = _4595 < 0.0f;\n        bool _4622;\n        if (!_4615)\n        {\n            _4622 = _4595 >= 1.0f;\n        }\n        else\n        {\n            _4622 = _4615;\n        }\n        bool _4629;\n        if (!_4622)\n        {\n            _4629 = _4599 < 0.0f;\n        }\n        else\n        {\n            _4629 = _4622;\n        }\n        bool _4636;\n        if (!_4629)\n        {\n            _4636 = _4599 >= 1.0f;\n        }\n        else\n        {\n            _4636 = _4629;\n        }\n        if (_4636)\n        {\n            break;\n        }\n        float4 _4655 = fa_screen_tex.Load(int3(int2(float2(_4595, _4599) * _556_fa_ct_a.zw), 0));\n        if (_4655.w < 0.5f)\n        {\n            continue;\n        }\n        float _4674 = (dot(_556_fa_ct_fwd.xyz, _4558) + _556_fa_ct_fwd.w) - _4655.x;\n        if ((_4674 > _4522) && (_4674 < _4527))\n        {\n            occ = max(occ, (1.0f - (_4550 * _4550)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_4595, 0.5f - _4594), min(_4599, 1.0f - _4599))));\n        }\n    }\n    return 1.0f - (occ * _4508);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _4750 = fa_lm.z > 0.5f;\n    bool _4756;\n    if (_4750)\n    {\n        int param = li;\n        _4756 = fa_light_baked(param);\n    }\n    else\n    {\n        _4756 = _4750;\n    }\n    if (_4756)\n    {\n        int param_1 = li;\n        LightSample _7139 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _7139;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4780 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _7141 = _4780.color;\n    float _7143 = _4780.shadow;\n    bool _4783 = _4780.type == 0;\n    if (_4783 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4780.direction;\n        float _4794 = fa_shadow_factor(param_5, param_6);\n        _7143 = _4794;\n        _7141 *= _4794;\n    }\n    else\n    {\n        bool _4805 = _4780.type != 0;\n        bool _4811;\n        if (_4805)\n        {\n            _4811 = _4780.attenuation > 0.0f;\n        }\n        else\n        {\n            _4811 = _4805;\n        }\n        if (_4811)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _4780.direction;\n            float _4830 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _7143 = _4830;\n            _7141 *= _4830;\n        }\n    }\n    bool _4840 = _556_fa_ct_a.x > 0.5f;\n    bool _4846;\n    if (_4840)\n    {\n        _4846 = _4780.attenuation > 0.0f;\n    }\n    else\n    {\n        _4846 = _4840;\n    }\n    if (_4846)\n    {\n        float _4853;\n        if (_4783)\n        {\n            _4853 = 1000000000.0f;\n        }\n        else\n        {\n            _4853 = _4780._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _4780.direction;\n        float param_18 = _4853;\n        float _4871 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _7143 *= _4871;\n        _7141 *= _4871;\n    }\n    LightSample _7158 = { _4780.direction, _7141, _4780.attenuation, _7143, _4780._distance, _4780.type };\n    return _7158;\n}\n\nfloat3 fa_ltc_tangent(float3 n, float3 v)\n{\n    float3 _4914 = v - (n * dot(v, n));\n    float3 t = _4914;\n    float _4918 = dot(_4914, _4914);\n    float l2 = _4918;\n    if (_4918 < 1.0000000133514319600180897396058e-10f)\n    {\n        float3 _4928;\n        if (abs(n.z) < 0.999000012874603271484375f)\n        {\n            _4928 = cross(n, float3(0.0f, 0.0f, 1.0f));\n        }\n        else\n        {\n            _4928 = cross(n, float3(1.0f, 0.0f, 0.0f));\n        }\n        t = _4928;\n        l2 = dot(_4928, _4928);\n    }\n    return t * rsqrt(l2);\n}\n\nfloat3 fa_ltc_local(float3 t1, float3 n, float3 p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nfloat3 fa_ltc_edge_vector(float3 a, float3 b)\n{\n    float _4963 = dot(a, a);\n    float _4967 = dot(b, b);\n    if ((_4963 < 1.0000000195414813782625560981111e-24f) || (_4967 < 1.0000000195414813782625560981111e-24f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _4981 = a * rsqrt(_4963);\n    float3 _4986 = b * rsqrt(_4967);\n    float _4990 = dot(_4981, _4986);\n    float _4993 = abs(_4990);\n    float g = (((((((((((0.0416471660137176513671875f * _4993) - 0.1924748718738555908203125f) * _4993) + 0.4179156124591827392578125f) * _4993) - 0.616057217121124267578125f) * _4993) + 0.777722418308258056640625f) * _4993) - 0.999542415142059326171875f) * _4993) + 1.570791721343994140625f;\n    if (_4990 < 0.0f)\n    {\n        g = (3.1415927410125732421875f * rsqrt(max(1.0f - (_4990 * _4990), 1.0000000116860974230803549289703e-07f))) - g;\n    }\n    return cross(_4981, _4986) * g;\n}\n\nvoid fa_ltc_clip_edge(float3 a, float3 b, inout float3 sum, inout float3 leave, inout float3 enter, inout float2 seen)\n{\n    bool _5050 = a.z > 0.0f;\n    bool _5054 = b.z > 0.0f;\n    if (_5050 && _5054)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_5050 != _5054)\n        {\n            float3 _5089 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _5089.z = 0.0f;\n            if (_5050)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _5089;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _5089;\n                seen.x = 1.0f;\n            }\n            else\n            {\n                float3 param_4 = _5089;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _5089;\n                seen.y = 1.0f;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(float4 abcd, float3 p0, float3 p1, float3 p2, float3 p3)\n{\n    float3 _5138 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _5164 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _5190 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _5216 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = 0.0f.xxx;\n    float3 leave = 0.0f.xxx;\n    float3 enter = 0.0f.xxx;\n    float3 param = _5138;\n    float3 param_1 = _5164;\n    float3 param_2 = 0.0f.xxx;\n    float3 param_3 = 0.0f.xxx;\n    float3 param_4 = 0.0f.xxx;\n    float2 param_5 = 0.0f.xx;\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _5164;\n    float3 param_7 = _5190;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _5190;\n    float3 param_13 = _5216;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _5216;\n    float3 param_19 = _5138;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5f)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875f;\n}\n\nfloat fa_ltc_rect(float4 abcd, float3 center, float3 ex, float3 ey)\n{\n    float4 param = abcd;\n    float3 param_1 = (center - ex) - ey;\n    float3 param_2 = (center + ex) - ey;\n    float3 param_3 = (center + ex) + ey;\n    float3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(float4 m, float shape, float3 pc, float3 ex, float3 ey)\n{\n    if ((shape < 0.5f) || (shape > 1.5f))\n    {\n        float4 param = m;\n        float3 param_1 = pc;\n        float3 param_2 = ex;\n        float3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    float3 _5366 = (pc + (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _5390 = (pc - (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _5406 = (pc - (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float4 param_4 = m;\n    float3 param_5 = _5366;\n    float3 param_6 = (pc + (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_7 = (pc - (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_8 = _5390;\n    float4 param_9 = m;\n    float3 param_10 = _5366;\n    float3 param_11 = _5390;\n    float3 param_12 = (pc - (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    float3 param_13 = _5406;\n    float4 param_14 = m;\n    float3 param_15 = _5366;\n    float3 param_16 = _5406;\n    float3 param_17 = (pc + (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float3 param_18 = (pc + (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nfloat2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((float2(clamp((roughness - 0.0500000007450580596923828125f) * 1.0526316165924072265625f, 0.0f, 1.0f), sqrt(clamp(1.0f - ndv, 0.0f, 1.0f))) * 63.0f) + 0.5f.xx) * 0.015625f.xx;\n}\n\nfloat3 fa_area_shade(int li, float3 world_pos, float3 n, float3 v, float3 diffuse_color, float3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _5464 = fa_light_base(param);\n    int param_1 = _5464;\n    int param_2 = _5464 + 1;\n    int param_3 = _5464 + 2;\n    int param_4 = _5464 + 4;\n    float4 _5486 = fa_light_texel(param_4);\n    int param_5 = _5464 + 5;\n    float4 _5491 = fa_light_texel(param_5);\n    int param_6 = _5464 + 6;\n    float4 _5496 = fa_light_texel(param_6);\n    float _5497 = _5496.w;\n    float3 _5502 = fa_light_texel(param_1).xyz - world_pos;\n    bool _5504 = _5497 < 1.5f;\n    bool _5511;\n    if (_5504)\n    {\n        _5511 = dot(normalize(fa_light_texel(param_3).xyz), _5502) >= 0.0f;\n    }\n    else\n    {\n        _5511 = _5504;\n    }\n    if (_5511)\n    {\n        return 0.0f.xxx;\n    }\n    bool _5520 = (_5497 > 0.5f) && _5504;\n    float _5524 = _5520 ? 1.0539000034332275390625f : 1.0f;\n    float3 _5527 = _5486.xyz;\n    float _5529 = _5486.w;\n    float3 _5535 = _5491.xyz;\n    float _5537 = _5491.w;\n    float3 up = _5535 * (_5537 * _5524);\n    float _5543;\n    if (_5520)\n    {\n        _5543 = (3.1415927410125732421875f * _5529) * _5529;\n    }\n    else\n    {\n        _5543 = (4.0f * _5529) * _5537;\n    }\n    if (_5497 > 1.5f)\n    {\n        float3 _5569 = cross(_5527, -_5502);\n        float3 perp = _5569;\n        float _5573 = dot(_5569, _5569);\n        float3 _5576;\n        if (_5573 > 1.0000000133514319600180897396058e-10f)\n        {\n            _5576 = perp * rsqrt(_5573);\n        }\n        else\n        {\n            _5576 = _5535;\n        }\n        perp = _5576;\n        up = _5576 * _5537;\n    }\n    float _5597 = max(_5543, 9.9999999747524270787835121154785e-07f);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _5607 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _5607;\n    float3 param_10 = n;\n    float3 param_11 = _5502;\n    float3 _5615 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_12 = _5607;\n    float3 param_13 = n;\n    float3 param_14 = _5527 * (_5529 * _5524);\n    float3 _5623 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_15 = _5607;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float3 _5631 = fa_ltc_local(param_15, param_16, param_17);\n    float4 param_18 = float4(1.0f, 0.0f, 0.0f, 1.0f);\n    float param_19 = _5497;\n    float3 param_20 = _5615;\n    float3 param_21 = _5623;\n    float3 param_22 = _5631;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    float2 _5650 = fa_ltc_uv(param_23, param_24) * 64.0f;\n    float2 param_25 = _5650;\n    float2 param_26 = _5650 + float2(64.0f, 0.0f);\n    float4 _5660 = fa_atlas_fetch(param_26);\n    float4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _5497;\n    float3 param_29 = _5615;\n    float3 param_30 = _5623;\n    float3 param_31 = _5631;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _5660.x) + ((f90.xxx - f0) * _5660.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875f * dot(_5502, _5502)) + _5597) / _5597) * window);\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4202 = 1.0f / alpha;\n    return ((2.0f + _4202) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _4202)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat fa_layers_coat(FaLayers L, float3 l, float3 h, float vdh)\n{\n    float _4237 = max(dot(L.nc, l), 0.0f);\n    float _4243 = max(dot(L.nc, h), 0.0f);\n    float _4252 = ((_4243 * _4243) * (L.coat_a2 - 1.0f)) + 1.0f;\n    return (((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _4252) * _4252)) * (0.5f / max(lerp((2.0f * _4237) * L.coat_ndv, _4237 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _4237)) * _4237;\n}\n\nfloat3 fa_area_layers(FaLayers L, int li, float3 world_pos, float3 n, float3 v, float3 l, float3 diffuse_color, float3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    float3 param_2 = n;\n    float3 param_3 = v;\n    float3 param_4 = diffuse_color;\n    float3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _5728;\n    if (L.sheen_on)\n    {\n        _5728 = L.sheen_scale;\n    }\n    else\n    {\n        _5728 = 1.0f;\n    }\n    float3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _5728);\n    float3 _5741 = normalize(l + v);\n    int param_10 = li;\n    float3 _5752 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _5761 = max(dot(n, l), 0.0f);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _5741), 0.0f);\n        float param_13 = _5761;\n        float param_14 = ndv;\n        result += ((L.sheen * _5752) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875f) * step(9.9999997473787516355514526367188e-05f, _5761)) * _5761) * L.keep));\n    }\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_15 = L;\n        float3 param_16 = l;\n        float3 param_17 = _5741;\n        float param_18 = max(dot(v, _5741), 0.0f);\n        result += (_5752 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4105 = tdh / at;\n    float _4109 = bdh / ab;\n    float _4121 = ((_4105 * _4105) + (_4109 * _4109)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _4121) * _4121);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4301 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4380 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _4380) * _4380);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _4301);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _4301));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_17 = L;\n        float3 param_18 = l;\n        float3 param_19 = h;\n        float param_20 = vdh;\n        result += fa_layers_coat(param_17, param_18, param_19, param_20).xxx;\n    }\n    return result;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3511 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3514 = _3511.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3514 * _3514, exp2((-9.27999973297119140625f) * ndv)) * _3514) + _3511.y)) + _3511.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_556_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _556_fa_env_horizon.w).xyz;\n    }\n    float _3365 = rough * rough;\n    float _3395 = 0.60000002384185791015625f * _3365;\n    return lerp(lerp(_556_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_556_fa_env_horizon.xyz, _556_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3365)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3395, 0.0500000007450580596923828125f + _3395, d.y).xxx), ((_556_fa_env_sky.xyz + _556_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3365 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _3988;\n        if (L.aniso >= 0.0f)\n        {\n            _3988 = L.b;\n        }\n        else\n        {\n            _3988 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_3988, v), _3988), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4021 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _4021.x) + (L.f90.xxx * _4021.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _4076 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _4076.x) + _4076.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3553 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3553.x) + _3553.y.xxx);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2223_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3159 = int(_2223_fa_shadow_cfg.x + 0.5f);\n    float _3169 = dot(world - _2223_fa_shadow_eye.xyz, _2223_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3174 = _3159 > 0;\n    bool _3183;\n    if (_3174)\n    {\n        int param = _3159 - 1;\n        _3183 = _3169 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3183 = _3174;\n    }\n    if (_3183)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3189 = _3159 > 1;\n        bool _3196;\n        if (_3189)\n        {\n            _3196 = _3169 > _2223_fa_shadow_split.x;\n        }\n        else\n        {\n            _3196 = _3189;\n        }\n        if (_3196)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3202 = _3159 > 2;\n        bool _3209;\n        if (_3202)\n        {\n            _3209 = _3169 > _2223_fa_shadow_split.y;\n        }\n        else\n        {\n            _3209 = _3202;\n        }\n        if (_3209)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3215 = _3159 > 3;\n        bool _3222;\n        if (_3215)\n        {\n            _3222 = _3169 > _2223_fa_shadow_split.z;\n        }\n        else\n        {\n            _3222 = _3215;\n        }\n        if (_3222)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _6841 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6841 = -_6841;\n    }\n    float3 _6196 = normalize(_556_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _6854 = { fa_world_pos, _6841, fa_world_tangent, fa_uv, fa_vertex_color, _6196, gl_FrontFacing };\n    SurfaceInput param_1 = _6854;\n    Surface _6204 = fa_standard_surface(param_1);\n    float3 _6872 = _6204.albedo;\n    float _6873 = _6204.alpha;\n    float3 _6874 = _6204.normal;\n    float _6875 = _6204.metallic;\n    float _6876 = _6204.roughness;\n    float _6877 = _6204.occlusion;\n    float3 _6878 = _6204.emission;\n    float _6879 = _6204.clearcoat;\n    float _6880 = _6204.clearcoat_roughness;\n    float3 _6881 = _6204.sheen_color;\n    float _6882 = _6204.sheen_roughness;\n    float _6883 = _6204.anisotropy;\n    float _6884 = _6204.anisotropy_rotation;\n    float _6885 = _6204.specular;\n    float _6886 = _6204.ior;\n    float3 _6887 = _6204.specular_color;\n    SurfaceInput _6862 = { fa_world_pos, _6841, fa_world_tangent, fa_uv, fa_vertex_color, _6196, gl_FrontFacing };\n    SurfaceInput param_2 = _6862;\n    Surface param_3 = _6204;\n    surface(param_2, param_3);\n    _6872 = param_3.albedo;\n    _6873 = param_3.alpha;\n    _6874 = param_3.normal;\n    _6875 = param_3.metallic;\n    _6876 = param_3.roughness;\n    _6877 = param_3.occlusion;\n    _6878 = param_3.emission;\n    _6879 = param_3.clearcoat;\n    _6880 = param_3.clearcoat_roughness;\n    _6881 = param_3.sheen_color;\n    _6882 = param_3.sheen_roughness;\n    _6883 = param_3.anisotropy;\n    _6884 = param_3.anisotropy_rotation;\n    _6885 = param_3.specular;\n    _6886 = param_3.ior;\n    _6887 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _6841;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6872 = param_6;\n    _6874 = param_7;\n    float3 result;\n    if (_556_fa_emissive.w > 0.5f)\n    {\n        result = _6872;\n    }\n    else\n    {\n        float3 _6243 = normalize(_6874);\n        float _6250 = clamp(_6875, 0.0f, 1.0f);\n        float _6254 = clamp(_6876, 0.0500000007450580596923828125f, 1.0f);\n        float _6258 = _6254 * _6254;\n        float _6262 = _6258 * _6258;\n        float _6267 = max(dot(_6243, _6196), 9.9999997473787516355514526367188e-05f);\n        float3 _6273 = _6872 * (1.0f - _6250);\n        float3 _6280 = lerp(0.039999999105930328369140625f.xxx, _6872, _6250.xxx);\n        float3 f0 = _6280;\n        SurfaceInput _6870 = { fa_world_pos, _6841, fa_world_tangent, fa_uv, fa_vertex_color, _6196, gl_FrontFacing };\n        SurfaceInput param_8 = _6870;\n        Surface _6953 = { _6872, _6873, _6874, _6875, _6876, _6877, _6878, _6879, _6880, _6881, _6882, _6883, _6884, _6885, _6886, _6887 };\n        Surface param_9 = _6953;\n        float3 param_10 = _6243;\n        float3 param_11 = _6196;\n        float param_12 = _6250;\n        float param_13 = _6254;\n        float3 param_14 = _6280;\n        FaLayers _6296 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _6243;\n        float3 lit = (fa_indirect_diffuse(param_15) * _6273) * _6877;\n        if (_6296.on)\n        {\n            lit *= _6296.base_scale;\n        }\n        int _6318 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6318; ln++)\n        {\n            int param_16 = ln;\n            int _6331 = fa_cl_light(param_16);\n            bool _6334 = fa_lm.z > 0.5f;\n            bool _6340;\n            if (_6334)\n            {\n                int param_17 = _6331;\n                _6340 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _6340 = _6334;\n            }\n            if (_6340)\n            {\n                continue;\n            }\n            int param_18 = _6331;\n            float3 param_19 = fa_world_pos;\n            float3 param_20 = _6841;\n            LightSample _6352 = fa_light_shadowed(param_18, param_19, param_20);\n            float _6360 = max(dot(_6243, _6352.direction), 0.0f);\n            float _6366 = _6352.attenuation * _6352.shadow;\n            float3 _6371 = normalize(_6352.direction + _6196);\n            float _6376 = max(dot(_6243, _6371), 0.0f);\n            float _6381 = max(dot(_6196, _6371), 0.0f);\n            bool _6388;\n            if (fa_light_is_area)\n            {\n                _6388 = !_6296.on;\n            }\n            else\n            {\n                _6388 = fa_light_is_area;\n            }\n            if (_6388)\n            {\n                int param_21 = _6331;\n                float3 param_22 = fa_world_pos;\n                float3 param_23 = _6243;\n                float3 param_24 = _6196;\n                float3 param_25 = _6273;\n                float3 param_26 = f0;\n                float param_27 = 1.0f;\n                float param_28 = _6254;\n                float param_29 = _6267;\n                float param_30 = _6366;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _6296;\n                    int param_32 = _6331;\n                    float3 param_33 = fa_world_pos;\n                    float3 param_34 = _6243;\n                    float3 param_35 = _6196;\n                    float3 param_36 = _6352.direction;\n                    float3 param_37 = _6273;\n                    float3 param_38 = f0;\n                    float param_39 = _6254;\n                    float param_40 = _6267;\n                    float param_41 = _6366;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_6296.on)\n                    {\n                        FaLayers param_42 = _6296;\n                        float3 param_43 = _6273;\n                        float3 param_44 = f0;\n                        float3 param_45 = _6243;\n                        float3 param_46 = _6196;\n                        float3 param_47 = _6352.direction;\n                        float3 param_48 = _6371;\n                        float param_49 = _6360;\n                        float param_50 = _6267;\n                        float param_51 = _6376;\n                        float param_52 = _6381;\n                        float param_53 = _6258;\n                        float param_54 = _6262;\n                        int param_55 = _6331;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _6366));\n                    }\n                    else\n                    {\n                        float _6494 = ((_6376 * _6376) * (_6262 - 1.0f)) + 1.0f;\n                        int param_56 = _6331;\n                        lit += (((_6273 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _6381, 5.0f))) * (((_6262 / ((3.1415927410125732421875f * _6494) * _6494)) * (0.5f / max(lerp((2.0f * _6360) * _6267, _6360 + _6267, _6258), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _6360))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_6360 * _6366));\n                    }\n                }\n            }\n        }\n        if (_6296.on)\n        {\n            FaLayers param_57 = _6296;\n            float3 param_58 = _6243;\n            float3 param_59 = _6196;\n            float3 param_60 = f0;\n            float param_61 = _6254;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _6877);\n        }\n        else\n        {\n            float3 param_62 = _6243;\n            float3 param_63 = _6196;\n            float3 param_64 = f0;\n            float param_65 = _6254;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _6877);\n        }\n        result = lit;\n    }\n    float3 _6589 = result;\n    float3 _6590 = _6589 + _6878;\n    result = _6590;\n    float3 param_66 = _6590;\n    float3 param_67 = fa_world_pos;\n    result = fa_shadow_debug(param_66, param_67);\n    bool _6599 = _556_fa_fog.w > 0.0f;\n    bool _6606;\n    if (!_6599)\n    {\n        _6606 = _556_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _6606 = _6599;\n    }\n    if (_6606)\n    {\n        float3 _6615 = fa_world_pos - _556_fa_camera_pos.xyz;\n        float _6621 = dot(_6615, _556_fa_fog_c.xyz);\n        bool _6625 = _556_fa_fog_c.w > 0.5f;\n        float _6626;\n        if (_6625)\n        {\n            _6626 = _6621;\n        }\n        else\n        {\n            _6626 = length(_6615);\n        }\n        float _6638 = _6626 - _556_fa_fog_b.x;\n        if (_6638 > 0.0f)\n        {\n            float _6647 = _556_fa_fog.w * _6638;\n            float tau = _6647 * _6647;\n            if (_556_fa_fog_b.y > 0.0f)\n            {\n                float _6663;\n                if (_6625)\n                {\n                    _6663 = fa_world_pos.y - (_556_fa_fog_c.y * _6621);\n                }\n                else\n                {\n                    _6663 = _556_fa_camera_pos.y;\n                }\n                float _6684 = lerp(_6663, fa_world_pos.y, clamp(_556_fa_fog_b.x / _6626, 0.0f, 1.0f));\n                float _6688 = fa_world_pos.y - _6684;\n                float _6693 = _6684 - _556_fa_fog_b.z;\n                float _6698 = fa_world_pos.y - _556_fa_fog_b.z;\n                bool _6701 = _6693 <= 0.0f;\n                bool _6702 = !_6701;\n                bool _6708;\n                if (_6702)\n                {\n                    _6708 = _556_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6708 = _6701;\n                }\n                float _6709;\n                if (_6708)\n                {\n                    _6709 = _556_fa_fog_b.y;\n                }\n                else\n                {\n                    _6709 = _556_fa_fog_b.y * exp(-min(_556_fa_fog_b.w * _6693, 80.0f));\n                }\n                bool _6736;\n                if (_6702)\n                {\n                    _6736 = _556_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6736 = _6701;\n                }\n                float _6737;\n                if (_6736)\n                {\n                    _6737 = _556_fa_fog_b.y * _6693;\n                }\n                else\n                {\n                    _6737 = (_556_fa_fog_b.y * (1.0f - exp(-min(_556_fa_fog_b.w * _6693, 80.0f)))) / _556_fa_fog_b.w;\n                }\n                bool _6762 = _6698 <= 0.0f;\n                bool _6769;\n                if (!_6762)\n                {\n                    _6769 = _556_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6769 = _6762;\n                }\n                float _6770;\n                if (_6769)\n                {\n                    _6770 = _556_fa_fog_b.y * _6698;\n                }\n                else\n                {\n                    _6770 = (_556_fa_fog_b.y * (1.0f - exp(-min(_556_fa_fog_b.w * _6698, 80.0f)))) / _556_fa_fog_b.w;\n                }\n                float _6797;\n                if (abs(_6688) < 0.001000000047497451305389404296875f)\n                {\n                    _6797 = _6709;\n                }\n                else\n                {\n                    _6797 = (_6770 - _6737) / _6688;\n                }\n                tau += (_6638 * max(_6797, 0.0f));\n            }\n            result = lerp(result, _556_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _6873);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_63",
            "hlsl_register_b_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_160",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_556",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2223",
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
              "slot": 6,
              "stage": "fragment",
              "name": "height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 6
            }
          },
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 0
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
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 6
          },
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
            "name": "height_smp",
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
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_light_tex_fa_shadow_smp",
            "view_name": "fa_light_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 24,
            "sampler_slot": 1
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "height_height_smp",
            "view_name": "height",
            "sampler_name": "height_smp",
            "view_slot": 6,
            "sampler_slot": 2
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
            "sampler_slot": 10
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          },
          {
            "slot": 11,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10
          },
          {
            "slot": 12,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 13,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_material_vs : register(b4)\n{\n    float _68_lift : packoffset(c0);\n    float _68_fa_pad0 : packoffset(c0.y);\n    float _68_fa_pad1 : packoffset(c0.z);\n    float _68_fa_pad2 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _165_fa_view_proj : packoffset(c0);\n    row_major float4x4 _165_fa_light_vp : packoffset(c4);\n    float4 _165_fa_uv_scale : packoffset(c8);\n    float4 _165_fa_time : packoffset(c9);\n    float4 _165_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _212_fa_joint_rows[192] : packoffset(c0);\n};\n\nTexture2D<float4> fa_vs_height : register(t0);\nSamplerState fa_vs_height_smp : register(s6);\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _203 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_212_fa_joint_rows[_203] * weights[i]);\n        r1 += (_212_fa_joint_rows[_203 + 1] * weights[i]);\n        r2 += (_212_fa_joint_rows[_203 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _108 = cross(model[1].xyz, model[2].xyz);\n    float _113 = (dot(model[0].xyz, _108) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _414 = { mul(float4(position, 1.0f), model).xyz, (((_108 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _113, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _113), texcoord0 * _165_fa_uv_scale.xy, color, position };\n    return _414;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += (fa_vs_height.SampleLevel(fa_vs_height_smp, v.uv, 0.0f).x * _68_lift);\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _165_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _3653[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _556_fa_camera_pos : packoffset(c0);\n    float4 _556_fa_ambient : packoffset(c1);\n    float4 _556_fa_base_color : packoffset(c2);\n    float4 _556_fa_emissive : packoffset(c3);\n    float4 _556_fa_model_emissive : packoffset(c4);\n    float4 _556_fa_pbr : packoffset(c5);\n    float4 _556_fa_maps : packoffset(c6);\n    float4 _556_fa_fog : packoffset(c7);\n    float4 _556_fa_fog_b : packoffset(c8);\n    float4 _556_fa_fog_c : packoffset(c9);\n    float4 _556_fa_counts : packoffset(c10);\n    float4 _556_fa_env_sky : packoffset(c11);\n    float4 _556_fa_env_horizon : packoffset(c12);\n    float4 _556_fa_time : packoffset(c13);\n    float4 _556_fa_cl_vpx : packoffset(c14);\n    float4 _556_fa_cl_vpy : packoffset(c15);\n    float4 _556_fa_cl_vpw : packoffset(c16);\n    float4 _556_fa_cl_fwd : packoffset(c17);\n    float4 _556_fa_cl_grid : packoffset(c18);\n    float4 _556_fa_cl_info : packoffset(c19);\n    float4 _556_fa_layers_a : packoffset(c20);\n    float4 _556_fa_layers_b : packoffset(c21);\n    float4 _556_fa_layers_c : packoffset(c22);\n    float4 _556_fa_layers_d : packoffset(c23);\n    float4 _556_fa_ct_a : packoffset(c24);\n    float4 _556_fa_ct_b : packoffset(c25);\n    float4 _556_fa_ct_vpx : packoffset(c26);\n    float4 _556_fa_ct_vpy : packoffset(c27);\n    float4 _556_fa_ct_vpw : packoffset(c28);\n    float4 _556_fa_ct_fwd : packoffset(c29);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2223_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2223_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2223_fa_shadow_info[4] : packoffset(c20);\n    float4 _2223_fa_shadow_split : packoffset(c24);\n    float4 _2223_fa_shadow_cfg : packoffset(c25);\n    float4 _2223_fa_shadow_bias : packoffset(c26);\n    float4 _2223_fa_shadow_eye : packoffset(c27);\n    float4 _2223_fa_shadow_fwd : packoffset(c28);\n    float4 _2223_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t11);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t7);\nTexture2D<float4> fa_screen_tex : register(t12);\nTexture2D<float4> height : register(t6);\nSamplerState height_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t10);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1494 = _556_fa_cl_info.x < 0.0f;\n    bool _1501;\n    if (!_1494)\n    {\n        _1501 = _556_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1501 = _1494;\n    }\n    bool _1509;\n    if (!_1501)\n    {\n        _1509 = _556_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1509 = _1501;\n    }\n    bool _1516;\n    if (!_1509)\n    {\n        _1516 = _556_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1516 = _1509;\n    }\n    bool _1523;\n    if (!_1516)\n    {\n        _1523 = _556_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1523 = _1516;\n    }\n    if (_1523)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1533 = float4(world_pos, 1.0f);\n    float _1539 = dot(_556_fa_cl_vpw, _1533);\n    if (!(_1539 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1561 = float2(dot(_556_fa_cl_vpx, _1533), dot(_556_fa_cl_vpy, _1533)) / _1539.xx;\n    int _1565 = int(_556_fa_cl_grid.x);\n    int _1569 = int(_556_fa_cl_grid.y);\n    int param = (int(_556_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_556_fa_cl_fwd.xyz, world_pos) + _556_fa_cl_fwd.w, _556_fa_cl_grid.w) / _556_fa_cl_grid.w) * _556_fa_cl_grid.z)), 0, int(_556_fa_cl_info.y) - 1) * _1569) + clamp(int(floor(((_1561.y * 0.5f) + 0.5f) * _556_fa_cl_grid.y)), 0, _1569 - 1)) * _1565)) + clamp(int(floor(((_1561.x * 0.5f) + 0.5f) * _556_fa_cl_grid.x)), 0, _1565 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1645 = fa_cluster_texel(param);\n    return int2(int(_1645.x), int(_1645.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_556_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4723 = fa_cluster_lookup(param);\n    fa_cl_slot = _4723.x;\n    fa_cl_local = _4723.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _5866 = fa_linear_to_srgb(param);\n        c = _5866;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _5874 = fa_srgb_to_linear(param_1);\n            c = _5874;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _439;\n    if (i.front_facing)\n    {\n        _439 = i.world_normal;\n    }\n    else\n    {\n        _439 = -i.world_normal;\n    }\n    float3 _463 = normalize(i.world_tangent.xyz - (_439 * dot(_439, i.world_tangent.xyz)));\n    float3 _490 = normalize(((_463 * m.x) + ((cross(_439, _463) * i.world_tangent.w) * m.y)) + (_439 * m.z));\n    float3 _493;\n    if (i.front_facing)\n    {\n        _493 = _490;\n    }\n    else\n    {\n        _493 = -_490;\n    }\n    return _493;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _556_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _5905 = fa_tex_fix(param_2, param_3);\n    float4 _7336 = base_t;\n    _7336.x = _5905.x;\n    _7336.y = _5905.y;\n    _7336.z = _5905.z;\n    base_t = _7336;\n    float4 _5919 = (_7336 * _556_fa_base_color) * i.vertex_color;\n    float3 _7161 = i.world_normal;\n    if (_556_fa_maps.z > 0.5f)\n    {\n        float param_4 = _556_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _5951 = fa_tex_fix(param_6, param_7);\n        float3 _5954 = (_5951 * 2.0f) - 1.0f.xxx;\n        float2 _5959 = _5954.xy * _556_fa_maps.x;\n        float3 _7344 = _5954;\n        _7344.x = _5959.x;\n        _7344.y = _5959.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _7344;\n        _7161 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _556_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _5987 = fa_tex_fix(param_12, param_13);\n    float4 _7347 = mrt;\n    _7347.x = _5987.x;\n    _7347.y = _5987.y;\n    _7347.z = _5987.z;\n    mrt = _7347;\n    float4 _6015 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _556_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _6015.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _6026 = fa_tex_fix(param_16, param_17);\n    float param_18 = _556_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _6056 = fa_tex_fix(param_20, param_21);\n    float _7166 = _556_fa_layers_a.x;\n    float _7167 = _556_fa_layers_a.y;\n    float _7170 = _556_fa_layers_a.z;\n    float _7169 = _556_fa_layers_b.w;\n    float _7172 = _556_fa_layers_c.x;\n    if (_556_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_556_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _7166 *= _6026.y;\n            _7167 *= _6026.z;\n            _7169 *= _6015.w;\n        }\n        if (_556_fa_layers_c.z > 1.5f)\n        {\n            _7170 *= mrt.x;\n            _7172 *= mrt.w;\n        }\n    }\n    Surface _7191 = { _5919.xyz, _5919.w, _7161, clamp(_556_fa_pbr.x * _5987.z, 0.0f, 1.0f), clamp(_556_fa_pbr.y * _5987.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_556_fa_maps.y * (_6026.x - 1.0f)), _556_fa_emissive.xyz + (_556_fa_model_emissive.xyz * _6056), _7166, _7167, _556_fa_layers_b.xyz, _7169, _7170, _556_fa_layers_a.w, _7172, _556_fa_layers_c.y, _556_fa_layers_d.xyz };\n    return _7191;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.albedo *= lerp(0.5f, 1.0f, height.Sample(height_smp, i.uv).x);\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1725 = rect.zw - rect.xy;\n    float2 _1729 = _1725 * atlas;\n    float2 _1733 = ddx * _1729;\n    float2 _1737 = ddy * _1729;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1725), clamp(0.5f * log2(max(max(dot(_1733, _1733), dot(_1737, _1737)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1770 = _556_fa_counts.y < 0.5f;\n    bool _1777;\n    if (!_1770)\n    {\n        _1777 = _556_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1777 = _1770;\n    }\n    if (_1777)\n    {\n        return;\n    }\n    float3 _1783 = ddx(world_pos);\n    float3 _1786 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1790 = fa_cluster_texel(param);\n    int _1794 = int(_1790.w);\n    if (_1794 < 1)\n    {\n        return;\n    }\n    int _1804 = int(_556_fa_counts.y + 0.5f);\n    int param_1 = _1804;\n    float4 _1808 = fa_light_texel(param_1);\n    float2 _1811 = _1808.yz;\n    int _1815 = int(_1808.w);\n    int param_2 = _1804 + 1;\n    float4 _1820 = fa_light_texel(param_2);\n    float _1821 = _1820.x;\n    int _1827 = int(_556_fa_counts.w + 0.5f) - 1;\n    int _1831 = int(_1790.z);\n    float3 _2096;\n    for (int k = 0; k < _1794; k++)\n    {\n        int _1844 = _1831 + k;\n        int param_3 = _1815 + (_1844 >> 2);\n        int _1861 = (_1804 + 2) + (int(fa_light_texel(param_3)[_1844 & 3]) * 7);\n        int param_4 = _1861 + 6;\n        float4 _1866 = fa_light_texel(param_4);\n        if (((int(_1866.w + 0.5f) >> _1827) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1861;\n        float4 _1881 = fa_light_texel(param_5);\n        int param_6 = _1861 + 1;\n        float4 _1886 = fa_light_texel(param_6);\n        int param_7 = _1861 + 2;\n        float4 _1891 = fa_light_texel(param_7);\n        float3 _1894 = _1881.xyz;\n        float _1899 = dot(_1894, world_pos) + _1881.w;\n        float3 _1901 = _1886.xyz;\n        float _1906 = dot(_1901, world_pos) + _1886.w;\n        float3 _1908 = _1891.xyz;\n        float _1913 = dot(_1908, world_pos) + _1891.w;\n        bool _1918 = abs(_1899) > 0.5f;\n        bool _1926;\n        if (!_1918)\n        {\n            _1926 = abs(_1906) > 0.5f;\n        }\n        else\n        {\n            _1926 = _1918;\n        }\n        bool _1934;\n        if (!_1926)\n        {\n            _1934 = abs(_1913) > 0.5f;\n        }\n        else\n        {\n            _1934 = _1926;\n        }\n        if (_1934)\n        {\n            continue;\n        }\n        float _1949 = clamp(dot(geo_normal, normalize(_1908)) * _1866.z, 0.0f, 1.0f);\n        if (_1949 <= 0.0f)\n        {\n            continue;\n        }\n        float _1969 = (clamp((0.5f - abs(_1913)) * 10.0f, 0.0f, 1.0f) * _1949) * _1866.x;\n        float2 _1977 = float2(_1899 + 0.5f, 0.5f - _1906);\n        float2 _1987 = float2(dot(_1894, _1783), dot(_1901, _1783));\n        float2 _1997 = float2(dot(_1894, _1786), dot(_1901, _1786));\n        int param_8 = _1861 + 5;\n        float4 _2002 = fa_light_texel(param_8);\n        int param_9 = _1861 + 3;\n        float4 _2007 = fa_light_texel(param_9);\n        int param_10 = _1861 + 4;\n        float4 _2012 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _2002.xyz;\n        bool _2022 = _2007.z > _2007.x;\n        if (_2022)\n        {\n            float4 param_11 = _2007;\n            float2 param_12 = _1977;\n            float2 param_13 = _1811;\n            float2 param_14 = _1987;\n            float2 param_15 = _1997;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1821 > 0.5f) && (_1821 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _2048 = fa_dc_to_linear(param_16);\n                float4 _7241 = tx;\n                _7241.x = _2048.x;\n                _7241.y = _2048.y;\n                _7241.z = _2048.z;\n                tx = _7241;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1969 * tex_a) * _2002.w, 0.0f, 1.0f).xxx);\n        if (_2012.z > _2012.x)\n        {\n            float4 param_17 = _2012;\n            float2 param_18 = _1977;\n            float2 param_19 = _1811;\n            float2 param_20 = _1987;\n            float2 param_21 = _1997;\n            float4 _2092 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1821 > 1.5f)\n            {\n                float3 param_22 = _2092.xyz;\n                float3 _2102 = fa_dc_to_srgb(param_22);\n                _2096 = _2102;\n            }\n            else\n            {\n                _2096 = _2092.xyz;\n            }\n            float3 _2111 = (_2096 * 2.0f) - 1.0f.xxx;\n            float2 _2116 = _2111.xy * _1866.y;\n            float3 _2138 = (normalize(_1894) * _2116.x) + (normalize(_1901) * _2116.y);\n            float3 _2141 = normalize(normal);\n            normal = normalize(lerp(_2141, normalize((_2141 * max(_2111.z, 0.0500000007450580596923828125f)) + (_2138 - (_2141 * dot(_2141, _2138)))), clamp(_1969 * (_2022 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3579 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3586 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3589 = int(_3579);\n    int _3592 = int(_3586);\n    float _3602 = _3586 - float(_3592);\n    int _3657 = (_3589 * 9) + _3592;\n    int _3677 = ((_3589 + 1) * 9) + _3592;\n    return lerp(lerp(_3653[_3657], _3653[_3657 + 1], _3602), lerp(_3653[_3677], _3653[_3677 + 1], _3602), _3579 - float(_3589));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _7084 = false;\n    float _7085 = 1.0f;\n    float _7086 = 1.0f;\n    float _7087 = 1.0f;\n    float _7088 = 0.0f;\n    float _7089 = 0.0f;\n    float _7090 = 0.0f;\n    float _7091 = 0.0f;\n    float _7093 = 1.0f;\n    bool _7094 = false;\n    float3 _7095 = 0.0f.xxx;\n    float _7096 = 1.0f;\n    float _7097 = 1.0f;\n    float _7098 = 1.0f;\n    float _7099 = 0.0f;\n    float _7100 = 0.0f;\n    float3 _7101 = float3(1.0f, 0.0f, 0.0f);\n    float3 _7102 = float3(0.0f, 0.0f, 1.0f);\n    float _7103 = 1.0f;\n    float _7104 = 1.0f;\n    float _3728 = clamp(s.specular, 0.0f, 1.0f);\n    float _3732 = clamp(s.ior, 1.0f, 3.0f);\n    bool _3737 = (_3728 != 1.0f) || (_3732 != 1.5f);\n    bool _3746;\n    if (!_3737)\n    {\n        _3746 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _3746 = _3737;\n    }\n    if (_3746)\n    {\n        float _3754 = (_3732 - 1.0f) / (_3732 + 1.0f);\n        f0 = lerp(min((_3754 * _3754).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _3728, s.albedo, metallic.xxx);\n        _7085 = lerp(_3728, 1.0f, metallic);\n        _7084 = true;\n    }\n    float _3781 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_3781 > 0.0f)\n    {\n        float _3789 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _7088 = _3781;\n        _7089 = _3789;\n        float _3796 = _3789 * _3789;\n        _7090 = _3796;\n        _7091 = _3796 * _3796;\n        float _3808 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _7093 = _3808;\n        _7086 = 1.0f - (_3781 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _3808, 0.0f, 1.0f), 5.0f))));\n        _7084 = true;\n    }\n    float3 _3827 = max(s.sheen_color, 0.0f.xxx);\n    float _3836 = max(_3827.x, max(_3827.y, _3827.z));\n    if (_3836 > 0.0f)\n    {\n        float _3844 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _7094 = true;\n        _7095 = _3827;\n        _7096 = _3844;\n        _7097 = _3844 * _3844;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _3844;\n        float _3861 = fa_sheen_albedo(param, param_1);\n        _7099 = _3861;\n        _7098 = 1.0f - min(_3836 * _3861, 1.0f);\n        _7084 = true;\n    }\n    _7087 = _7086 * _7098;\n    float _3880 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_3880 != 0.0f)\n    {\n        float3 _3895 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _3895;\n        if (dot(_3895, _3895) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _3907 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_3907.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _3907.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _3907.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _3911 = t;\n        float3 _3912 = normalize(_3911);\n        t = _3912;\n        float3 _3937 = normalize((_3912 * cos(s.anisotropy_rotation)) + ((cross(n, _3912) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _7101 = _3937;\n        _7102 = cross(n, _3937);\n        float _3947 = roughness * roughness;\n        float _3953 = lerp(_3947, 1.0f, _3880 * _3880);\n        bool _3955 = _3880 > 0.0f;\n        _7103 = _3955 ? _3953 : _3947;\n        _7104 = _3955 ? _3947 : _3953;\n        _7100 = _3880;\n        _7084 = true;\n    }\n    FaLayers _7126 = { _7084, _7085, _7086, _7087, _7088, _7089, _7090, _7091, i.world_normal, _7093, _7094, _7095, _7096, _7097, _7098, _7099, _7100, _7101, _7102, _7103, _7104 };\n    return _7126;\n}\n\nfloat3 fa_sky_sh_coef(int k)\n{\n    float3 v = fa_env_tex.SampleLevel(fa_env_smp, float3(1.0f, 1.0f - (float((2 * (k >> 2)) + 1) * 0.25f), 1.0f - (float((2 * (k & 3)) + 1) * 0.25f)), 5.0f).xyz;\n    if (_556_fa_env_sky.w > 1.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3336 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3336;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_556_fa_env_sky.w > 0.5f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _556_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_556_fa_cl_info.x) + int(_556_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_556_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _624_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _624_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _743 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _756 = (c - (ru * hx)) - p;\n        float3 _762 = ru * (2.0f * hx);\n        float _768 = max(dot(_762, _762), 9.9999999392252902907785028219223e-09f);\n        float _772 = dot(_756, _762);\n        float t = clamp((-_772) / _768, 0.0f, 1.0f);\n        if (_743)\n        {\n            float _787 = dot(r, _762);\n            float _793 = _768 - (_787 * _787);\n            if (abs(_793) > (9.9999997473787516355514526367188e-06f * _768))\n            {\n                t = clamp(((dot(r, _756) * _787) - _772) / _793, 0.0f, 1.0f);\n            }\n        }\n        return (p + _756) + (_762 * t);\n    }\n    float3 q = p;\n    float _825 = dot(r, axis);\n    bool _833;\n    if (_743)\n    {\n        _833 = abs(_825) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _833 = _743;\n    }\n    if (_833)\n    {\n        float _843 = dot(c - p, axis) / _825;\n        if (_843 > 0.0f)\n        {\n            q = p + (r * _843);\n        }\n    }\n    float3 _856 = q - c;\n    float2 xy = float2(dot(_856, ru), dot(_856, uu));\n    if (shape > 0.5f)\n    {\n        float _871 = length(xy);\n        if (_871 > hx)\n        {\n            xy *= (hx / _871);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _505 = abs(d);\n    float _507 = _505.x;\n    float _509 = _505.y;\n    bool _510 = _507 >= _509;\n    bool _518;\n    if (_510)\n    {\n        _518 = _507 >= _505.z;\n    }\n    else\n    {\n        _518 = _510;\n    }\n    int _519;\n    if (_518)\n    {\n        _519 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _534;\n        if (_509 >= _505.z)\n        {\n            _534 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _534 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _519 = _534;\n    }\n    return _519;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _663 = dot(d, right);\n    float _667 = dot(d, up);\n    float _678;\n    if (((_663 * _663) + (_667 * _667)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _678 = atan2(_667, _663) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _678 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_678 - floor(_678)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _909 = fa_light_base(param);\n    bool _913 = _556_fa_ambient.w > 4.5f;\n    int param_1 = _909;\n    float4 _917 = fa_light_texel(param_1);\n    int param_2 = _909 + 1;\n    float4 _922 = fa_light_texel(param_2);\n    float _925 = _922.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _937 = _913 && (_925 > 2.5f);\n    fa_light_is_area = _937;\n    bool _939 = _925 < 0.5f;\n    float3 l;\n    if (_939)\n    {\n        l = normalize(_917.xyz);\n        if (_913)\n        {\n            int param_3 = _909 + 6;\n            float4 _953 = fa_light_texel(param_3);\n            if (_953.z > 0.5f)\n            {\n                int param_4 = _909 + 4;\n                float4 _963 = fa_light_texel(param_4);\n                int param_5 = _909 + 5;\n                float4 _968 = fa_light_texel(param_5);\n                float2 param_6 = _953.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _963.xyz) * _963.w, (-dot(world_pos, _968.xyz)) * _968.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _998 = _917.xyz;\n        float3 _1000 = _998 - world_pos;\n        float3 to_light = _1000;\n        float _1003 = length(_1000);\n        float reach = _1003;\n        bool front = true;\n        if (_937)\n        {\n            int param_8 = _909 + 7;\n            reach = max(_1003 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _909 + 4;\n            float4 _1027 = fa_light_texel(param_9);\n            int param_10 = _909 + 5;\n            float4 _1032 = fa_light_texel(param_10);\n            int param_11 = _909 + 6;\n            float4 _1037 = fa_light_texel(param_11);\n            float _1038 = _1037.w;\n            int param_12 = _909 + 2;\n            float3 _1045 = normalize(fa_light_texel(param_12).xyz);\n            bool _1047 = _1038 > 1.5f;\n            bool _1055;\n            if (!_1047)\n            {\n                _1055 = dot(_1045, to_light) < 0.0f;\n            }\n            else\n            {\n                _1055 = _1047;\n            }\n            front = _1055;\n            float3 r = 0.0f.xxx;\n            float3 _1064 = _556_fa_camera_pos.xyz - world_pos;\n            bool _1068 = dot(n, n) > 0.5f;\n            bool _1076;\n            if (_1068)\n            {\n                _1076 = dot(_1064, _1064) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _1076 = _1068;\n            }\n            if (_1076)\n            {\n                r = reflect(-normalize(_1064), normalize(n));\n            }\n            float3 param_13 = _998;\n            float3 param_14 = _1045;\n            float3 param_15 = _1027.xyz;\n            float3 param_16 = _1032.xyz;\n            float param_17 = _1027.w;\n            float param_18 = _1032.w;\n            float param_19 = _1038;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1112 = length(to_light);\n        dist = _1112;\n        l = to_light / max(_1112, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1126 = reach / max(_917.w, 0.001000000047497451305389404296875f);\n        float _1132 = clamp(1.0f - (_1126 * _1126), 0.0f, 1.0f);\n        float _1134;\n        if (front)\n        {\n            _1134 = _1132 * _1132;\n        }\n        else\n        {\n            _1134 = 0.0f;\n        }\n        atten = _1134;\n        bool _1145 = _925 < 2.5f;\n        if ((_925 > 1.5f) && _1145)\n        {\n            int param_22 = _909 + 2;\n            float4 _1153 = fa_light_texel(param_22);\n            float _1163 = _1153.w;\n            int param_23 = _909 + 3;\n            float4 _1168 = fa_light_texel(param_23);\n            float _1169 = _1168.x;\n            float cos_inner = _1169;\n            if (_1169 > 1.5f)\n            {\n                cos_inner = lerp(_1163, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1163, cos_inner, dot(-l, normalize(_1153.xyz)));\n        }\n        if (_913 && (_925 < 1.5f))\n        {\n            int param_24 = _909 + 6;\n            float4 _1193 = fa_light_texel(param_24);\n            if (_1193.z > 0.5f)\n            {\n                float3 _1201 = -to_light;\n                int param_25 = _909 + 4;\n                int param_26 = _909 + 5;\n                float3 _1215 = fa_light_texel(param_25).xyz;\n                float3 _1219 = fa_light_texel(param_26).xyz;\n                float3 _1228 = float3(dot(_1201, _1215), dot(_1201, _1219), dot(_1201, cross(_1215, _1219)));\n                float3 param_27 = _1228;\n                int _1232 = fa_cube_face(param_27);\n                int param_28 = _1232;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1259 = float2(dot(_1228, cross(param_29, param_30)), dot(_1228, param_30)) / max(dot(_1228, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1263 = _1232 / 3;\n                float2 param_31 = _1193.xy + (float2(float(_1232 - (_1263 * 3)), float(_1263)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1259.x), 0.5f - (0.5f * _1259.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _909 + 7;\n            float4 _1293 = fa_light_texel(param_33);\n            if (_1293.z > 0.5f)\n            {\n                int param_34 = _909 + 2;\n                int param_35 = _909 + 4;\n                int param_36 = _909 + 5;\n                float2 param_37 = _1293.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_913 && _1145)\n            {\n                int param_42 = _909 + 6;\n                float4 _1340 = fa_light_texel(param_42);\n                int param_43 = _909 + 7;\n                float4 _1345 = fa_light_texel(param_43);\n                bool _1348 = _1340.z > 0.5f;\n                bool _1355;\n                if (!_1348)\n                {\n                    _1355 = _1345.z > 0.5f;\n                }\n                else\n                {\n                    _1355 = _1348;\n                }\n                if (_1355)\n                {\n                    int param_44 = _909 + 2;\n                    float4 _1362 = fa_light_texel(param_44);\n                    float3 _1366 = normalize(_1362.xyz);\n                    int param_45 = _909 + 4;\n                    float4 _1371 = fa_light_texel(param_45);\n                    int param_46 = _909 + 5;\n                    float4 _1376 = fa_light_texel(param_46);\n                    if (_1348)\n                    {\n                        float3 _1384 = -to_light;\n                        float _1391 = _1362.w;\n                        float _1407 = 0.5f / max(dot(_1384, _1366) * (sqrt(max(1.0f - (_1391 * _1391), 0.0f)) / max(_1391, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1340.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1384, _1371.xyz) * _1407), 0.5f - (dot(_1384, _1376.xyz) * _1407));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1345.z > 0.5f)\n                    {\n                        float2 param_49 = _1345.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1366;\n                        float3 param_52 = _1371.xyz;\n                        float3 param_53 = _1376.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _7072 = _922.xyz * atten;\n    if (_913)\n    {\n        _7072 *= fa_light_tint;\n    }\n    int _1476;\n    if (_939)\n    {\n        _1476 = 0;\n    }\n    else\n    {\n        _1476 = ((_925 > 1.5f) && (_925 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _7083 = { l, _7072, atten, 1.0f, dist, _1476 };\n    return _7083;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2213;\n    if (i == 0)\n    {\n        _2213 = _2223_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2229;\n        if (i == 1)\n        {\n            _2229 = _2223_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2237;\n            if (i == 2)\n            {\n                _2237 = _2223_fa_shadow_split.z;\n            }\n            else\n            {\n                _2237 = _2223_fa_shadow_split.w;\n            }\n            _2229 = _2237;\n        }\n        _2213 = _2229;\n    }\n    return _2213;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2270 = fa_shadow_depth(param, param_1);\n    float _2274;\n    if (conv.x < 0.5f)\n    {\n        _2274 = _2270;\n    }\n    else\n    {\n        _2274 = (conv.y * conv.z) / (conv.z - (_2270 * (conv.z - conv.y)));\n    }\n    return _2274;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2201 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2201), sin(_2201)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2320 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2329;\n        if (k < 0.0f)\n        {\n            _2329 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2329 = k;\n        }\n        float _2349 = clamp((_2329 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2320;\n            float2 _2368 = fa_shadow_vogel(param_3, param_4, param_5) * _2349;\n            float2 param_6 = uv + (_2368 * _2223_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2380 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2380 < (zr - (length(_2368) * plane)))\n            {\n                sum += _2380;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2406 = sum / cnt;\n        float _2416;\n        if (k < 0.0f)\n        {\n            _2416 = (-k) / max(_2406, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2416 = k;\n        }\n        radius = clamp(((max(zr - _2406, 0.0f) * unit) * _2416) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2438 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2438; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2438;\n        float param_11 = _2320;\n        float2 _2457 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2457 * _2223_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2457) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2438);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2499 = max(_2223_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2504 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2510 = sqrt(1.0f - (_2504 * _2504));\n    float _2517 = min(_2510 / max(_2504, 0.20000000298023223876953125f), 4.0f);\n    float _2522;\n    if (_2223_fa_shadow_bias.y > 0.0f)\n    {\n        _2522 = _2223_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2522 = 1.5f * _2223_fa_shadow_info[ci].x;\n    }\n    float4 _2547 = mul(float4(world + (n * (_2522 * _2510)), 1.0f), _2223_fa_shadow_mat[ci]);\n    float _2554 = _2547.x;\n    bool _2557 = _2554 < _2223_fa_shadow_rect[ci].x;\n    bool _2566;\n    if (!_2557)\n    {\n        _2566 = _2554 > _2223_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2566 = _2557;\n    }\n    bool _2575;\n    if (!_2566)\n    {\n        _2575 = _2547.y < _2223_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2575 = _2566;\n    }\n    bool _2584;\n    if (!_2575)\n    {\n        _2584 = _2547.y > _2223_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2584 = _2575;\n    }\n    bool _2591;\n    if (!_2584)\n    {\n        _2591 = _2547.z > 1.0f;\n    }\n    else\n    {\n        _2591 = _2584;\n    }\n    if (_2591)\n    {\n        return -1.0f;\n    }\n    float _2599;\n    if (_2223_fa_shadow_bias.x > 0.0f)\n    {\n        _2599 = _2223_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2599 = 1.5f * _2223_fa_shadow_info[ci].x;\n    }\n    float2 param = _2547.xy;\n    float4 param_1 = _2223_fa_shadow_rect[ci];\n    float param_2 = _2547.z - ((_2599 * (1.0f + (0.5f * _2517))) / _2499);\n    float param_3 = _2223_fa_shadow_info[ci].x;\n    float param_4 = _2499;\n    float param_5 = _2499 * 0.25f;\n    float param_6 = ((_2223_fa_shadow_info[ci].x * min(_2517, 3.0f)) * 0.5f) / _2499;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2223_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2223_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_556_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2977 = int(_2223_fa_shadow_cfg.x + 0.5f);\n    if (_2977 < 1)\n    {\n        return 1.0f;\n    }\n    float _2992 = dot(world - _2223_fa_shadow_eye.xyz, _2223_fa_shadow_fwd.xyz);\n    int param = _2977 - 1;\n    if (_2992 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _3004 = _2977 > 1;\n    bool _3011;\n    if (_3004)\n    {\n        _3011 = _2992 > _2223_fa_shadow_split.x;\n    }\n    else\n    {\n        _3011 = _3004;\n    }\n    if (_3011)\n    {\n        ci = 1;\n    }\n    bool _3015 = _2977 > 2;\n    bool _3022;\n    if (_3015)\n    {\n        _3022 = _2992 > _2223_fa_shadow_split.y;\n    }\n    else\n    {\n        _3022 = _3015;\n    }\n    if (_3022)\n    {\n        ci = 2;\n    }\n    bool _3026 = _2977 > 3;\n    bool _3033;\n    if (_3026)\n    {\n        _3033 = _2992 > _2223_fa_shadow_split.z;\n    }\n    else\n    {\n        _3033 = _3026;\n    }\n    if (_3033)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2977)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _3059 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3059;\n        if (_3059 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2223_fa_shadow_cfg.y > 0.0f)\n    {\n        float _3084;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3084 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3084 = _2223_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _3103 = _2223_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3084, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _3114 = clamp((_2992 - (fa_shadow_split_at(param_7) - _3103)) / _3103, 0.0f, 1.0f);\n        if (_3114 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2977)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _3135 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3135;\n                if (_3135 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _3114);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2657 = _556_fa_pbr.z < 0.5f;\n    bool _2664;\n    if (!_2657)\n    {\n        _2664 = _2223_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2664 = _2657;\n    }\n    if (_2664)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2223_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2677 = fa_light_texel(param);\n    float _2678 = _2677.x;\n    if (_2678 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2687 = int(_2678 + 0.5f);\n    int param_1 = _2687;\n    float4 _2691 = fa_light_texel(param_1);\n    int param_2 = _2687 + 1;\n    float4 _2696 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2699 = _2691.y;\n    if (_2699 > 0.0f)\n    {\n        float _2716 = 1.0f - smoothstep(0.75f * _2699, _2699, length(world - _2223_fa_shadow_eye.xyz));\n        fade = _2716;\n        if (_2716 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2691.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2740 = (_2687 + 2) + (face * 6);\n    int param_4 = _2740;\n    int param_5 = _2740 + 1;\n    int param_6 = _2740 + 3;\n    float4 _2754 = fa_light_texel(param_6);\n    int param_7 = _2740 + 4;\n    float4 _2759 = fa_light_texel(param_7);\n    int param_8 = _2740 + 5;\n    float4 _2764 = fa_light_texel(param_8);\n    float _2776 = _2764.x * max(dot(_2754, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2781 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2804 = clamp(dot(n, _2754.xyz), -1.0f, 1.0f);\n    float _2823 = min(sqrt(1.0f - (_2804 * _2804)) / max(abs(dot(n, world - lpos)) / max(dot(_2754, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2826 = _2696.y;\n    float _2828;\n    if (_2826 > 0.0f)\n    {\n        _2828 = _2826;\n    }\n    else\n    {\n        _2828 = 1.5f * _2776;\n    }\n    float4 _2848 = float4(world + (n * (_2828 * sqrt(1.0f - (_2781 * _2781)))), 1.0f);\n    float _2852 = dot(_2754, _2848);\n    float _2855 = _2764.y;\n    if (_2852 < _2855)\n    {\n        return 1.0f;\n    }\n    float2 _2870 = float2(dot(fa_light_texel(param_4), _2848), dot(fa_light_texel(param_5), _2848)) / _2852.xx;\n    float _2872 = _2870.x;\n    bool _2875 = _2872 < _2759.x;\n    bool _2884;\n    if (!_2875)\n    {\n        _2884 = _2872 > _2759.z;\n    }\n    else\n    {\n        _2884 = _2875;\n    }\n    bool _2893;\n    if (!_2884)\n    {\n        _2893 = _2870.y < _2759.y;\n    }\n    else\n    {\n        _2893 = _2884;\n    }\n    bool _2902;\n    if (!_2893)\n    {\n        _2902 = _2870.y > _2759.w;\n    }\n    else\n    {\n        _2902 = _2893;\n    }\n    if (_2902)\n    {\n        return 1.0f;\n    }\n    float _2908 = _2696.x;\n    float _2910;\n    if (_2908 > 0.0f)\n    {\n        _2910 = _2908;\n    }\n    else\n    {\n        _2910 = 1.5f * _2776;\n    }\n    float2 param_9 = _2870;\n    float4 param_10 = _2759;\n    float param_11 = _2852 - (_2910 * (1.0f + (0.5f * _2823)));\n    float param_12 = _2776;\n    float param_13 = 1.0f;\n    float param_14 = _2764.z * 0.25f;\n    float param_15 = (_2776 * min(_2823, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2855, _2764.z);\n    int param_17 = int(_2691.z + 0.5f);\n    float param_18 = _2691.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _4465 = _556_fa_ct_a.x < 0.5f;\n    bool _4472;\n    if (!_4465)\n    {\n        _4472 = _2223_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _4472 = _4465;\n    }\n    if (_4472)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2223_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _4485 = fa_light_texel(param);\n    float _4486 = _4485.y;\n    float len = _4486;\n    if (_4486 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4498 = length(world - _556_fa_camera_pos.xyz);\n    float _4508 = 1.0f - smoothstep(0.5f * _556_fa_ct_b.x, _556_fa_ct_b.x, _4498);\n    if (_4508 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4514 = len;\n    float _4517 = min(_4514, 0.89999997615814208984375f * dist);\n    len = _4517;\n    float _4522 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _4498);\n    float _4527 = _4522 + (0.5f * _4517);\n    float3 _4533 = world + (gn * _4522);\n    float _4535 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _4599;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4550 = (float(k) + _4535) * 0.083333335816860198974609375f;\n        float3 _4558 = _4533 + (l * (_4550 * len));\n        float4 _4564 = float4(_4558, 1.0f);\n        float _4570 = dot(_556_fa_ct_vpw, _4564);\n        if (_4570 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _4590 = float2(dot(_556_fa_ct_vpx, _4564), dot(_556_fa_ct_vpy, _4564)) / _4570.xx;\n        float _4594 = _4590.x * 0.5f;\n        float _4595 = _4594 + 0.5f;\n        if (_556_fa_ct_a.y > 0.5f)\n        {\n            _4599 = (_4590.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _4599 = 0.5f - (_4590.y * 0.5f);\n        }\n        bool _4615 = _4595 < 0.0f;\n        bool _4622;\n        if (!_4615)\n        {\n            _4622 = _4595 >= 1.0f;\n        }\n        else\n        {\n            _4622 = _4615;\n        }\n        bool _4629;\n        if (!_4622)\n        {\n            _4629 = _4599 < 0.0f;\n        }\n        else\n        {\n            _4629 = _4622;\n        }\n        bool _4636;\n        if (!_4629)\n        {\n            _4636 = _4599 >= 1.0f;\n        }\n        else\n        {\n            _4636 = _4629;\n        }\n        if (_4636)\n        {\n            break;\n        }\n        float4 _4655 = fa_screen_tex.Load(int3(int2(float2(_4595, _4599) * _556_fa_ct_a.zw), 0));\n        if (_4655.w < 0.5f)\n        {\n            continue;\n        }\n        float _4674 = (dot(_556_fa_ct_fwd.xyz, _4558) + _556_fa_ct_fwd.w) - _4655.x;\n        if ((_4674 > _4522) && (_4674 < _4527))\n        {\n            occ = max(occ, (1.0f - (_4550 * _4550)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_4595, 0.5f - _4594), min(_4599, 1.0f - _4599))));\n        }\n    }\n    return 1.0f - (occ * _4508);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _4750 = fa_lm.z > 0.5f;\n    bool _4756;\n    if (_4750)\n    {\n        int param = li;\n        _4756 = fa_light_baked(param);\n    }\n    else\n    {\n        _4756 = _4750;\n    }\n    if (_4756)\n    {\n        int param_1 = li;\n        LightSample _7139 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _7139;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4780 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _7141 = _4780.color;\n    float _7143 = _4780.shadow;\n    bool _4783 = _4780.type == 0;\n    if (_4783 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4780.direction;\n        float _4794 = fa_shadow_factor(param_5, param_6);\n        _7143 = _4794;\n        _7141 *= _4794;\n    }\n    else\n    {\n        bool _4805 = _4780.type != 0;\n        bool _4811;\n        if (_4805)\n        {\n            _4811 = _4780.attenuation > 0.0f;\n        }\n        else\n        {\n            _4811 = _4805;\n        }\n        if (_4811)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _4780.direction;\n            float _4830 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _7143 = _4830;\n            _7141 *= _4830;\n        }\n    }\n    bool _4840 = _556_fa_ct_a.x > 0.5f;\n    bool _4846;\n    if (_4840)\n    {\n        _4846 = _4780.attenuation > 0.0f;\n    }\n    else\n    {\n        _4846 = _4840;\n    }\n    if (_4846)\n    {\n        float _4853;\n        if (_4783)\n        {\n            _4853 = 1000000000.0f;\n        }\n        else\n        {\n            _4853 = _4780._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _4780.direction;\n        float param_18 = _4853;\n        float _4871 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _7143 *= _4871;\n        _7141 *= _4871;\n    }\n    LightSample _7158 = { _4780.direction, _7141, _4780.attenuation, _7143, _4780._distance, _4780.type };\n    return _7158;\n}\n\nfloat3 fa_ltc_tangent(float3 n, float3 v)\n{\n    float3 _4914 = v - (n * dot(v, n));\n    float3 t = _4914;\n    float _4918 = dot(_4914, _4914);\n    float l2 = _4918;\n    if (_4918 < 1.0000000133514319600180897396058e-10f)\n    {\n        float3 _4928;\n        if (abs(n.z) < 0.999000012874603271484375f)\n        {\n            _4928 = cross(n, float3(0.0f, 0.0f, 1.0f));\n        }\n        else\n        {\n            _4928 = cross(n, float3(1.0f, 0.0f, 0.0f));\n        }\n        t = _4928;\n        l2 = dot(_4928, _4928);\n    }\n    return t * rsqrt(l2);\n}\n\nfloat3 fa_ltc_local(float3 t1, float3 n, float3 p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nfloat3 fa_ltc_edge_vector(float3 a, float3 b)\n{\n    float _4963 = dot(a, a);\n    float _4967 = dot(b, b);\n    if ((_4963 < 1.0000000195414813782625560981111e-24f) || (_4967 < 1.0000000195414813782625560981111e-24f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _4981 = a * rsqrt(_4963);\n    float3 _4986 = b * rsqrt(_4967);\n    float _4990 = dot(_4981, _4986);\n    float _4993 = abs(_4990);\n    float g = (((((((((((0.0416471660137176513671875f * _4993) - 0.1924748718738555908203125f) * _4993) + 0.4179156124591827392578125f) * _4993) - 0.616057217121124267578125f) * _4993) + 0.777722418308258056640625f) * _4993) - 0.999542415142059326171875f) * _4993) + 1.570791721343994140625f;\n    if (_4990 < 0.0f)\n    {\n        g = (3.1415927410125732421875f * rsqrt(max(1.0f - (_4990 * _4990), 1.0000000116860974230803549289703e-07f))) - g;\n    }\n    return cross(_4981, _4986) * g;\n}\n\nvoid fa_ltc_clip_edge(float3 a, float3 b, inout float3 sum, inout float3 leave, inout float3 enter, inout float2 seen)\n{\n    bool _5050 = a.z > 0.0f;\n    bool _5054 = b.z > 0.0f;\n    if (_5050 && _5054)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_5050 != _5054)\n        {\n            float3 _5089 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _5089.z = 0.0f;\n            if (_5050)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _5089;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _5089;\n                seen.x = 1.0f;\n            }\n            else\n            {\n                float3 param_4 = _5089;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _5089;\n                seen.y = 1.0f;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(float4 abcd, float3 p0, float3 p1, float3 p2, float3 p3)\n{\n    float3 _5138 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _5164 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _5190 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _5216 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = 0.0f.xxx;\n    float3 leave = 0.0f.xxx;\n    float3 enter = 0.0f.xxx;\n    float3 param = _5138;\n    float3 param_1 = _5164;\n    float3 param_2 = 0.0f.xxx;\n    float3 param_3 = 0.0f.xxx;\n    float3 param_4 = 0.0f.xxx;\n    float2 param_5 = 0.0f.xx;\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _5164;\n    float3 param_7 = _5190;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _5190;\n    float3 param_13 = _5216;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _5216;\n    float3 param_19 = _5138;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5f)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875f;\n}\n\nfloat fa_ltc_rect(float4 abcd, float3 center, float3 ex, float3 ey)\n{\n    float4 param = abcd;\n    float3 param_1 = (center - ex) - ey;\n    float3 param_2 = (center + ex) - ey;\n    float3 param_3 = (center + ex) + ey;\n    float3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(float4 m, float shape, float3 pc, float3 ex, float3 ey)\n{\n    if ((shape < 0.5f) || (shape > 1.5f))\n    {\n        float4 param = m;\n        float3 param_1 = pc;\n        float3 param_2 = ex;\n        float3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    float3 _5366 = (pc + (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _5390 = (pc - (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _5406 = (pc - (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float4 param_4 = m;\n    float3 param_5 = _5366;\n    float3 param_6 = (pc + (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_7 = (pc - (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_8 = _5390;\n    float4 param_9 = m;\n    float3 param_10 = _5366;\n    float3 param_11 = _5390;\n    float3 param_12 = (pc - (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    float3 param_13 = _5406;\n    float4 param_14 = m;\n    float3 param_15 = _5366;\n    float3 param_16 = _5406;\n    float3 param_17 = (pc + (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float3 param_18 = (pc + (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nfloat2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((float2(clamp((roughness - 0.0500000007450580596923828125f) * 1.0526316165924072265625f, 0.0f, 1.0f), sqrt(clamp(1.0f - ndv, 0.0f, 1.0f))) * 63.0f) + 0.5f.xx) * 0.015625f.xx;\n}\n\nfloat3 fa_area_shade(int li, float3 world_pos, float3 n, float3 v, float3 diffuse_color, float3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _5464 = fa_light_base(param);\n    int param_1 = _5464;\n    int param_2 = _5464 + 1;\n    int param_3 = _5464 + 2;\n    int param_4 = _5464 + 4;\n    float4 _5486 = fa_light_texel(param_4);\n    int param_5 = _5464 + 5;\n    float4 _5491 = fa_light_texel(param_5);\n    int param_6 = _5464 + 6;\n    float4 _5496 = fa_light_texel(param_6);\n    float _5497 = _5496.w;\n    float3 _5502 = fa_light_texel(param_1).xyz - world_pos;\n    bool _5504 = _5497 < 1.5f;\n    bool _5511;\n    if (_5504)\n    {\n        _5511 = dot(normalize(fa_light_texel(param_3).xyz), _5502) >= 0.0f;\n    }\n    else\n    {\n        _5511 = _5504;\n    }\n    if (_5511)\n    {\n        return 0.0f.xxx;\n    }\n    bool _5520 = (_5497 > 0.5f) && _5504;\n    float _5524 = _5520 ? 1.0539000034332275390625f : 1.0f;\n    float3 _5527 = _5486.xyz;\n    float _5529 = _5486.w;\n    float3 _5535 = _5491.xyz;\n    float _5537 = _5491.w;\n    float3 up = _5535 * (_5537 * _5524);\n    float _5543;\n    if (_5520)\n    {\n        _5543 = (3.1415927410125732421875f * _5529) * _5529;\n    }\n    else\n    {\n        _5543 = (4.0f * _5529) * _5537;\n    }\n    if (_5497 > 1.5f)\n    {\n        float3 _5569 = cross(_5527, -_5502);\n        float3 perp = _5569;\n        float _5573 = dot(_5569, _5569);\n        float3 _5576;\n        if (_5573 > 1.0000000133514319600180897396058e-10f)\n        {\n            _5576 = perp * rsqrt(_5573);\n        }\n        else\n        {\n            _5576 = _5535;\n        }\n        perp = _5576;\n        up = _5576 * _5537;\n    }\n    float _5597 = max(_5543, 9.9999999747524270787835121154785e-07f);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _5607 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _5607;\n    float3 param_10 = n;\n    float3 param_11 = _5502;\n    float3 _5615 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_12 = _5607;\n    float3 param_13 = n;\n    float3 param_14 = _5527 * (_5529 * _5524);\n    float3 _5623 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_15 = _5607;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float3 _5631 = fa_ltc_local(param_15, param_16, param_17);\n    float4 param_18 = float4(1.0f, 0.0f, 0.0f, 1.0f);\n    float param_19 = _5497;\n    float3 param_20 = _5615;\n    float3 param_21 = _5623;\n    float3 param_22 = _5631;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    float2 _5650 = fa_ltc_uv(param_23, param_24) * 64.0f;\n    float2 param_25 = _5650;\n    float2 param_26 = _5650 + float2(64.0f, 0.0f);\n    float4 _5660 = fa_atlas_fetch(param_26);\n    float4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _5497;\n    float3 param_29 = _5615;\n    float3 param_30 = _5623;\n    float3 param_31 = _5631;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _5660.x) + ((f90.xxx - f0) * _5660.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875f * dot(_5502, _5502)) + _5597) / _5597) * window);\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4202 = 1.0f / alpha;\n    return ((2.0f + _4202) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _4202)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat fa_layers_coat(FaLayers L, float3 l, float3 h, float vdh)\n{\n    float _4237 = max(dot(L.nc, l), 0.0f);\n    float _4243 = max(dot(L.nc, h), 0.0f);\n    float _4252 = ((_4243 * _4243) * (L.coat_a2 - 1.0f)) + 1.0f;\n    return (((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _4252) * _4252)) * (0.5f / max(lerp((2.0f * _4237) * L.coat_ndv, _4237 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _4237)) * _4237;\n}\n\nfloat3 fa_area_layers(FaLayers L, int li, float3 world_pos, float3 n, float3 v, float3 l, float3 diffuse_color, float3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    float3 param_2 = n;\n    float3 param_3 = v;\n    float3 param_4 = diffuse_color;\n    float3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _5728;\n    if (L.sheen_on)\n    {\n        _5728 = L.sheen_scale;\n    }\n    else\n    {\n        _5728 = 1.0f;\n    }\n    float3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _5728);\n    float3 _5741 = normalize(l + v);\n    int param_10 = li;\n    float3 _5752 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _5761 = max(dot(n, l), 0.0f);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _5741), 0.0f);\n        float param_13 = _5761;\n        float param_14 = ndv;\n        result += ((L.sheen * _5752) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875f) * step(9.9999997473787516355514526367188e-05f, _5761)) * _5761) * L.keep));\n    }\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_15 = L;\n        float3 param_16 = l;\n        float3 param_17 = _5741;\n        float param_18 = max(dot(v, _5741), 0.0f);\n        result += (_5752 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4105 = tdh / at;\n    float _4109 = bdh / ab;\n    float _4121 = ((_4105 * _4105) + (_4109 * _4109)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _4121) * _4121);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4301 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4380 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _4380) * _4380);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _4301);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _4301));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_17 = L;\n        float3 param_18 = l;\n        float3 param_19 = h;\n        float param_20 = vdh;\n        result += fa_layers_coat(param_17, param_18, param_19, param_20).xxx;\n    }\n    return result;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3511 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3514 = _3511.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3514 * _3514, exp2((-9.27999973297119140625f) * ndv)) * _3514) + _3511.y)) + _3511.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_556_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _556_fa_env_horizon.w).xyz;\n    }\n    float _3365 = rough * rough;\n    float _3395 = 0.60000002384185791015625f * _3365;\n    return lerp(lerp(_556_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_556_fa_env_horizon.xyz, _556_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3365)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3395, 0.0500000007450580596923828125f + _3395, d.y).xxx), ((_556_fa_env_sky.xyz + _556_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3365 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _3988;\n        if (L.aniso >= 0.0f)\n        {\n            _3988 = L.b;\n        }\n        else\n        {\n            _3988 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_3988, v), _3988), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4021 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _4021.x) + (L.f90.xxx * _4021.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _4076 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _4076.x) + _4076.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3553 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3553.x) + _3553.y.xxx);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2223_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3159 = int(_2223_fa_shadow_cfg.x + 0.5f);\n    float _3169 = dot(world - _2223_fa_shadow_eye.xyz, _2223_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3174 = _3159 > 0;\n    bool _3183;\n    if (_3174)\n    {\n        int param = _3159 - 1;\n        _3183 = _3169 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3183 = _3174;\n    }\n    if (_3183)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3189 = _3159 > 1;\n        bool _3196;\n        if (_3189)\n        {\n            _3196 = _3169 > _2223_fa_shadow_split.x;\n        }\n        else\n        {\n            _3196 = _3189;\n        }\n        if (_3196)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3202 = _3159 > 2;\n        bool _3209;\n        if (_3202)\n        {\n            _3209 = _3169 > _2223_fa_shadow_split.y;\n        }\n        else\n        {\n            _3209 = _3202;\n        }\n        if (_3209)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3215 = _3159 > 3;\n        bool _3222;\n        if (_3215)\n        {\n            _3222 = _3169 > _2223_fa_shadow_split.z;\n        }\n        else\n        {\n            _3222 = _3215;\n        }\n        if (_3222)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _6841 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6841 = -_6841;\n    }\n    float3 _6196 = normalize(_556_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _6854 = { fa_world_pos, _6841, fa_world_tangent, fa_uv, fa_vertex_color, _6196, gl_FrontFacing };\n    SurfaceInput param_1 = _6854;\n    Surface _6204 = fa_standard_surface(param_1);\n    float3 _6872 = _6204.albedo;\n    float _6873 = _6204.alpha;\n    float3 _6874 = _6204.normal;\n    float _6875 = _6204.metallic;\n    float _6876 = _6204.roughness;\n    float _6877 = _6204.occlusion;\n    float3 _6878 = _6204.emission;\n    float _6879 = _6204.clearcoat;\n    float _6880 = _6204.clearcoat_roughness;\n    float3 _6881 = _6204.sheen_color;\n    float _6882 = _6204.sheen_roughness;\n    float _6883 = _6204.anisotropy;\n    float _6884 = _6204.anisotropy_rotation;\n    float _6885 = _6204.specular;\n    float _6886 = _6204.ior;\n    float3 _6887 = _6204.specular_color;\n    SurfaceInput _6862 = { fa_world_pos, _6841, fa_world_tangent, fa_uv, fa_vertex_color, _6196, gl_FrontFacing };\n    SurfaceInput param_2 = _6862;\n    Surface param_3 = _6204;\n    surface(param_2, param_3);\n    _6872 = param_3.albedo;\n    _6873 = param_3.alpha;\n    _6874 = param_3.normal;\n    _6875 = param_3.metallic;\n    _6876 = param_3.roughness;\n    _6877 = param_3.occlusion;\n    _6878 = param_3.emission;\n    _6879 = param_3.clearcoat;\n    _6880 = param_3.clearcoat_roughness;\n    _6881 = param_3.sheen_color;\n    _6882 = param_3.sheen_roughness;\n    _6883 = param_3.anisotropy;\n    _6884 = param_3.anisotropy_rotation;\n    _6885 = param_3.specular;\n    _6886 = param_3.ior;\n    _6887 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _6841;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6872 = param_6;\n    _6874 = param_7;\n    float3 result;\n    if (_556_fa_emissive.w > 0.5f)\n    {\n        result = _6872;\n    }\n    else\n    {\n        float3 _6243 = normalize(_6874);\n        float _6250 = clamp(_6875, 0.0f, 1.0f);\n        float _6254 = clamp(_6876, 0.0500000007450580596923828125f, 1.0f);\n        float _6258 = _6254 * _6254;\n        float _6262 = _6258 * _6258;\n        float _6267 = max(dot(_6243, _6196), 9.9999997473787516355514526367188e-05f);\n        float3 _6273 = _6872 * (1.0f - _6250);\n        float3 _6280 = lerp(0.039999999105930328369140625f.xxx, _6872, _6250.xxx);\n        float3 f0 = _6280;\n        SurfaceInput _6870 = { fa_world_pos, _6841, fa_world_tangent, fa_uv, fa_vertex_color, _6196, gl_FrontFacing };\n        SurfaceInput param_8 = _6870;\n        Surface _6953 = { _6872, _6873, _6874, _6875, _6876, _6877, _6878, _6879, _6880, _6881, _6882, _6883, _6884, _6885, _6886, _6887 };\n        Surface param_9 = _6953;\n        float3 param_10 = _6243;\n        float3 param_11 = _6196;\n        float param_12 = _6250;\n        float param_13 = _6254;\n        float3 param_14 = _6280;\n        FaLayers _6296 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _6243;\n        float3 lit = (fa_indirect_diffuse(param_15) * _6273) * _6877;\n        if (_6296.on)\n        {\n            lit *= _6296.base_scale;\n        }\n        int _6318 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6318; ln++)\n        {\n            int param_16 = ln;\n            int _6331 = fa_cl_light(param_16);\n            bool _6334 = fa_lm.z > 0.5f;\n            bool _6340;\n            if (_6334)\n            {\n                int param_17 = _6331;\n                _6340 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _6340 = _6334;\n            }\n            if (_6340)\n            {\n                continue;\n            }\n            int param_18 = _6331;\n            float3 param_19 = fa_world_pos;\n            float3 param_20 = _6841;\n            LightSample _6352 = fa_light_shadowed(param_18, param_19, param_20);\n            float _6360 = max(dot(_6243, _6352.direction), 0.0f);\n            float _6366 = _6352.attenuation * _6352.shadow;\n            float3 _6371 = normalize(_6352.direction + _6196);\n            float _6376 = max(dot(_6243, _6371), 0.0f);\n            float _6381 = max(dot(_6196, _6371), 0.0f);\n            bool _6388;\n            if (fa_light_is_area)\n            {\n                _6388 = !_6296.on;\n            }\n            else\n            {\n                _6388 = fa_light_is_area;\n            }\n            if (_6388)\n            {\n                int param_21 = _6331;\n                float3 param_22 = fa_world_pos;\n                float3 param_23 = _6243;\n                float3 param_24 = _6196;\n                float3 param_25 = _6273;\n                float3 param_26 = f0;\n                float param_27 = 1.0f;\n                float param_28 = _6254;\n                float param_29 = _6267;\n                float param_30 = _6366;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _6296;\n                    int param_32 = _6331;\n                    float3 param_33 = fa_world_pos;\n                    float3 param_34 = _6243;\n                    float3 param_35 = _6196;\n                    float3 param_36 = _6352.direction;\n                    float3 param_37 = _6273;\n                    float3 param_38 = f0;\n                    float param_39 = _6254;\n                    float param_40 = _6267;\n                    float param_41 = _6366;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_6296.on)\n                    {\n                        FaLayers param_42 = _6296;\n                        float3 param_43 = _6273;\n                        float3 param_44 = f0;\n                        float3 param_45 = _6243;\n                        float3 param_46 = _6196;\n                        float3 param_47 = _6352.direction;\n                        float3 param_48 = _6371;\n                        float param_49 = _6360;\n                        float param_50 = _6267;\n                        float param_51 = _6376;\n                        float param_52 = _6381;\n                        float param_53 = _6258;\n                        float param_54 = _6262;\n                        int param_55 = _6331;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _6366));\n                    }\n                    else\n                    {\n                        float _6494 = ((_6376 * _6376) * (_6262 - 1.0f)) + 1.0f;\n                        int param_56 = _6331;\n                        lit += (((_6273 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _6381, 5.0f))) * (((_6262 / ((3.1415927410125732421875f * _6494) * _6494)) * (0.5f / max(lerp((2.0f * _6360) * _6267, _6360 + _6267, _6258), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _6360))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_6360 * _6366));\n                    }\n                }\n            }\n        }\n        if (_6296.on)\n        {\n            FaLayers param_57 = _6296;\n            float3 param_58 = _6243;\n            float3 param_59 = _6196;\n            float3 param_60 = f0;\n            float param_61 = _6254;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _6877);\n        }\n        else\n        {\n            float3 param_62 = _6243;\n            float3 param_63 = _6196;\n            float3 param_64 = f0;\n            float param_65 = _6254;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _6877);\n        }\n        result = lit;\n    }\n    float3 _6589 = result;\n    float3 _6590 = _6589 + _6878;\n    result = _6590;\n    float3 param_66 = _6590;\n    float3 param_67 = fa_world_pos;\n    result = fa_shadow_debug(param_66, param_67);\n    bool _6599 = _556_fa_fog.w > 0.0f;\n    bool _6606;\n    if (!_6599)\n    {\n        _6606 = _556_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _6606 = _6599;\n    }\n    if (_6606)\n    {\n        float3 _6615 = fa_world_pos - _556_fa_camera_pos.xyz;\n        float _6621 = dot(_6615, _556_fa_fog_c.xyz);\n        bool _6625 = _556_fa_fog_c.w > 0.5f;\n        float _6626;\n        if (_6625)\n        {\n            _6626 = _6621;\n        }\n        else\n        {\n            _6626 = length(_6615);\n        }\n        float _6638 = _6626 - _556_fa_fog_b.x;\n        if (_6638 > 0.0f)\n        {\n            float _6647 = _556_fa_fog.w * _6638;\n            float tau = _6647 * _6647;\n            if (_556_fa_fog_b.y > 0.0f)\n            {\n                float _6663;\n                if (_6625)\n                {\n                    _6663 = fa_world_pos.y - (_556_fa_fog_c.y * _6621);\n                }\n                else\n                {\n                    _6663 = _556_fa_camera_pos.y;\n                }\n                float _6684 = lerp(_6663, fa_world_pos.y, clamp(_556_fa_fog_b.x / _6626, 0.0f, 1.0f));\n                float _6688 = fa_world_pos.y - _6684;\n                float _6693 = _6684 - _556_fa_fog_b.z;\n                float _6698 = fa_world_pos.y - _556_fa_fog_b.z;\n                bool _6701 = _6693 <= 0.0f;\n                bool _6702 = !_6701;\n                bool _6708;\n                if (_6702)\n                {\n                    _6708 = _556_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6708 = _6701;\n                }\n                float _6709;\n                if (_6708)\n                {\n                    _6709 = _556_fa_fog_b.y;\n                }\n                else\n                {\n                    _6709 = _556_fa_fog_b.y * exp(-min(_556_fa_fog_b.w * _6693, 80.0f));\n                }\n                bool _6736;\n                if (_6702)\n                {\n                    _6736 = _556_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6736 = _6701;\n                }\n                float _6737;\n                if (_6736)\n                {\n                    _6737 = _556_fa_fog_b.y * _6693;\n                }\n                else\n                {\n                    _6737 = (_556_fa_fog_b.y * (1.0f - exp(-min(_556_fa_fog_b.w * _6693, 80.0f)))) / _556_fa_fog_b.w;\n                }\n                bool _6762 = _6698 <= 0.0f;\n                bool _6769;\n                if (!_6762)\n                {\n                    _6769 = _556_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6769 = _6762;\n                }\n                float _6770;\n                if (_6769)\n                {\n                    _6770 = _556_fa_fog_b.y * _6698;\n                }\n                else\n                {\n                    _6770 = (_556_fa_fog_b.y * (1.0f - exp(-min(_556_fa_fog_b.w * _6698, 80.0f)))) / _556_fa_fog_b.w;\n                }\n                float _6797;\n                if (abs(_6688) < 0.001000000047497451305389404296875f)\n                {\n                    _6797 = _6709;\n                }\n                else\n                {\n                    _6797 = (_6770 - _6737) / _6688;\n                }\n                tau += (_6638 * max(_6797, 0.0f));\n            }\n            result = lerp(result, _556_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _6873);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_68",
            "hlsl_register_b_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_165",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_212",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_556",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2223",
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
              "slot": 6,
              "stage": "fragment",
              "name": "height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 6
            }
          },
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 0
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
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 6
          },
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
            "name": "height_smp",
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
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_light_tex_fa_shadow_smp",
            "view_name": "fa_light_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 24,
            "sampler_slot": 1
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "height_height_smp",
            "view_name": "height",
            "sampler_name": "height_smp",
            "view_slot": 6,
            "sampler_slot": 2
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
            "sampler_slot": 10
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          },
          {
            "slot": 11,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10
          },
          {
            "slot": 12,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 13,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_material_vs : register(b4)\n{\n    float _63_lift : packoffset(c0);\n    float _63_fa_pad0 : packoffset(c0.y);\n    float _63_fa_pad1 : packoffset(c0.z);\n    float _63_fa_pad2 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _160_fa_view_proj : packoffset(c0);\n    row_major float4x4 _160_fa_light_vp : packoffset(c4);\n    float4 _160_fa_uv_scale : packoffset(c8);\n    float4 _160_fa_time : packoffset(c9);\n    float4 _160_fa_lm_so : packoffset(c10);\n};\n\nTexture2D<float4> fa_vs_height : register(t0);\nSamplerState fa_vs_height_smp : register(s6);\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _103 = cross(model[1].xyz, model[2].xyz);\n    float _108 = (dot(model[0].xyz, _103) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _325 = { mul(float4(position, 1.0f), model).xyz, (((_103 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _108, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _108), texcoord0 * _160_fa_uv_scale.xy, color, position };\n    return _325;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += (fa_vs_height.SampleLevel(fa_vs_height_smp, v.uv, 0.0f).x * _63_lift);\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _204 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -mul(_204, _160_fa_light_vp).z;\n    fa_pre_r0 = float3(_160_fa_light_vp[0].x, _160_fa_light_vp[1].x, _160_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_160_fa_light_vp[0].y, _160_fa_light_vp[1].y, _160_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_160_fa_light_vp[0].z, _160_fa_light_vp[1].z, _160_fa_light_vp[2].z);\n    gl_Position = mul(_204, _160_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _229_fa_camera_pos : packoffset(c0);\n    float4 _229_fa_ambient : packoffset(c1);\n    float4 _229_fa_base_color : packoffset(c2);\n    float4 _229_fa_emissive : packoffset(c3);\n    float4 _229_fa_model_emissive : packoffset(c4);\n    float4 _229_fa_pbr : packoffset(c5);\n    float4 _229_fa_maps : packoffset(c6);\n    float4 _229_fa_fog : packoffset(c7);\n    float4 _229_fa_fog_b : packoffset(c8);\n    float4 _229_fa_fog_c : packoffset(c9);\n    float4 _229_fa_counts : packoffset(c10);\n    float4 _229_fa_env_sky : packoffset(c11);\n    float4 _229_fa_env_horizon : packoffset(c12);\n    float4 _229_fa_time : packoffset(c13);\n    float4 _229_fa_cl_vpx : packoffset(c14);\n    float4 _229_fa_cl_vpy : packoffset(c15);\n    float4 _229_fa_cl_vpw : packoffset(c16);\n    float4 _229_fa_cl_fwd : packoffset(c17);\n    float4 _229_fa_cl_grid : packoffset(c18);\n    float4 _229_fa_cl_info : packoffset(c19);\n    float4 _229_fa_layers_a : packoffset(c20);\n    float4 _229_fa_layers_b : packoffset(c21);\n    float4 _229_fa_layers_c : packoffset(c22);\n    float4 _229_fa_layers_d : packoffset(c23);\n    float4 _229_fa_ct_a : packoffset(c24);\n    float4 _229_fa_ct_b : packoffset(c25);\n    float4 _229_fa_ct_vpx : packoffset(c26);\n    float4 _229_fa_ct_vpy : packoffset(c27);\n    float4 _229_fa_ct_vpw : packoffset(c28);\n    float4 _229_fa_ct_fwd : packoffset(c29);\n};\n\nTexture2D<float4> height : register(t5);\nSamplerState height_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _196 = fa_linear_to_srgb(param);\n        c = _196;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _204 = fa_srgb_to_linear(param_1);\n            c = _204;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _229_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _240 = fa_tex_fix(param_2, param_3);\n    float4 _752 = base_t;\n    _752.x = _240.x;\n    _752.y = _240.y;\n    _752.z = _240.z;\n    base_t = _752;\n    float4 _256 = (_752 * _229_fa_base_color) * i.vertex_color;\n    float3 _715 = i.world_normal;\n    if (_229_fa_maps.z > 0.5f)\n    {\n        float param_4 = _229_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _289 = fa_tex_fix(param_6, param_7);\n        float3 _293 = (_289 * 2.0f) - 1.0f.xxx;\n        float2 _298 = _293.xy * _229_fa_maps.x;\n        float3 _760 = _293;\n        _760.x = _298.x;\n        _760.y = _298.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _760;\n        _715 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _229_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _327 = fa_tex_fix(param_12, param_13);\n    float4 _763 = mrt;\n    _763.x = _327.x;\n    _763.y = _327.y;\n    _763.z = _327.z;\n    mrt = _763;\n    float4 _357 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _229_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _357.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _369 = fa_tex_fix(param_16, param_17);\n    float param_18 = _229_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _399 = fa_tex_fix(param_20, param_21);\n    float _720 = _229_fa_layers_a.x;\n    float _721 = _229_fa_layers_a.y;\n    float _724 = _229_fa_layers_a.z;\n    float _723 = _229_fa_layers_b.w;\n    float _726 = _229_fa_layers_c.x;\n    if (_229_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_229_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _720 *= _369.y;\n            _721 *= _369.z;\n            _723 *= _357.w;\n        }\n        if (_229_fa_layers_c.z > 1.5f)\n        {\n            _724 *= mrt.x;\n            _726 *= mrt.w;\n        }\n    }\n    Surface _745 = { _256.xyz, _256.w, _715, clamp(_229_fa_pbr.x * _327.z, 0.0f, 1.0f), clamp(_229_fa_pbr.y * _327.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_229_fa_maps.y * (_369.x - 1.0f)), _229_fa_emissive.xyz + (_229_fa_model_emissive.xyz * _399), _720, _721, _229_fa_layers_b.xyz, _723, _724, _229_fa_layers_a.w, _726, _229_fa_layers_c.y, _229_fa_layers_d.xyz };\n    return _745;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.albedo *= lerp(0.5f, 1.0f, height.Sample(height_smp, i.uv).x);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _626 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _626 = -_626;\n    }\n    float3 _533 = normalize(_229_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _639 = { fa_world_pos, _626, fa_world_tangent, fa_uv, fa_vertex_color, _533, gl_FrontFacing };\n    SurfaceInput param = _639;\n    SurfaceInput _647 = { fa_world_pos, _626, fa_world_tangent, fa_uv, fa_vertex_color, _533, gl_FrontFacing };\n    SurfaceInput param_1 = _647;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _548 = normalize(param_2.normal);\n    float3 _563 = normalize(float3(dot(fa_pre_r0, _548), dot(fa_pre_r1, _548), dot(fa_pre_r2, _548)));\n    float _575 = _563.z;\n    float2 e = _563.xy / ((abs(_563.x) + abs(_563.y)) + abs(_575)).xx;\n    if (_575 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_63",
            "hlsl_register_b_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_160",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_229",
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
          },
          {
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 5
            }
          },
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 6
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "height_smp",
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
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6
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
            "name": "height_height_smp",
            "view_name": "height",
            "sampler_name": "height_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    },
    "prepass_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_material_vs : register(b4)\n{\n    float _68_lift : packoffset(c0);\n    float _68_fa_pad0 : packoffset(c0.y);\n    float _68_fa_pad1 : packoffset(c0.z);\n    float _68_fa_pad2 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _165_fa_view_proj : packoffset(c0);\n    row_major float4x4 _165_fa_light_vp : packoffset(c4);\n    float4 _165_fa_uv_scale : packoffset(c8);\n    float4 _165_fa_time : packoffset(c9);\n    float4 _165_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _212_fa_joint_rows[192] : packoffset(c0);\n};\n\nTexture2D<float4> fa_vs_height : register(t0);\nSamplerState fa_vs_height_smp : register(s6);\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _203 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_212_fa_joint_rows[_203] * weights[i]);\n        r1 += (_212_fa_joint_rows[_203 + 1] * weights[i]);\n        r2 += (_212_fa_joint_rows[_203 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _108 = cross(model[1].xyz, model[2].xyz);\n    float _113 = (dot(model[0].xyz, _108) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _446 = { mul(float4(position, 1.0f), model).xyz, (((_108 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _113, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _113), texcoord0 * _165_fa_uv_scale.xy, color, position };\n    return _446;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += (fa_vs_height.SampleLevel(fa_vs_height_smp, v.uv, 0.0f).x * _68_lift);\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _317 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -mul(_317, _165_fa_light_vp).z;\n    fa_pre_r0 = float3(_165_fa_light_vp[0].x, _165_fa_light_vp[1].x, _165_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_165_fa_light_vp[0].y, _165_fa_light_vp[1].y, _165_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_165_fa_light_vp[0].z, _165_fa_light_vp[1].z, _165_fa_light_vp[2].z);\n    gl_Position = mul(_317, _165_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _229_fa_camera_pos : packoffset(c0);\n    float4 _229_fa_ambient : packoffset(c1);\n    float4 _229_fa_base_color : packoffset(c2);\n    float4 _229_fa_emissive : packoffset(c3);\n    float4 _229_fa_model_emissive : packoffset(c4);\n    float4 _229_fa_pbr : packoffset(c5);\n    float4 _229_fa_maps : packoffset(c6);\n    float4 _229_fa_fog : packoffset(c7);\n    float4 _229_fa_fog_b : packoffset(c8);\n    float4 _229_fa_fog_c : packoffset(c9);\n    float4 _229_fa_counts : packoffset(c10);\n    float4 _229_fa_env_sky : packoffset(c11);\n    float4 _229_fa_env_horizon : packoffset(c12);\n    float4 _229_fa_time : packoffset(c13);\n    float4 _229_fa_cl_vpx : packoffset(c14);\n    float4 _229_fa_cl_vpy : packoffset(c15);\n    float4 _229_fa_cl_vpw : packoffset(c16);\n    float4 _229_fa_cl_fwd : packoffset(c17);\n    float4 _229_fa_cl_grid : packoffset(c18);\n    float4 _229_fa_cl_info : packoffset(c19);\n    float4 _229_fa_layers_a : packoffset(c20);\n    float4 _229_fa_layers_b : packoffset(c21);\n    float4 _229_fa_layers_c : packoffset(c22);\n    float4 _229_fa_layers_d : packoffset(c23);\n    float4 _229_fa_ct_a : packoffset(c24);\n    float4 _229_fa_ct_b : packoffset(c25);\n    float4 _229_fa_ct_vpx : packoffset(c26);\n    float4 _229_fa_ct_vpy : packoffset(c27);\n    float4 _229_fa_ct_vpw : packoffset(c28);\n    float4 _229_fa_ct_fwd : packoffset(c29);\n};\n\nTexture2D<float4> height : register(t5);\nSamplerState height_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _196 = fa_linear_to_srgb(param);\n        c = _196;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _204 = fa_srgb_to_linear(param_1);\n            c = _204;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _229_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _240 = fa_tex_fix(param_2, param_3);\n    float4 _752 = base_t;\n    _752.x = _240.x;\n    _752.y = _240.y;\n    _752.z = _240.z;\n    base_t = _752;\n    float4 _256 = (_752 * _229_fa_base_color) * i.vertex_color;\n    float3 _715 = i.world_normal;\n    if (_229_fa_maps.z > 0.5f)\n    {\n        float param_4 = _229_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _289 = fa_tex_fix(param_6, param_7);\n        float3 _293 = (_289 * 2.0f) - 1.0f.xxx;\n        float2 _298 = _293.xy * _229_fa_maps.x;\n        float3 _760 = _293;\n        _760.x = _298.x;\n        _760.y = _298.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _760;\n        _715 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _229_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _327 = fa_tex_fix(param_12, param_13);\n    float4 _763 = mrt;\n    _763.x = _327.x;\n    _763.y = _327.y;\n    _763.z = _327.z;\n    mrt = _763;\n    float4 _357 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _229_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _357.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _369 = fa_tex_fix(param_16, param_17);\n    float param_18 = _229_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _399 = fa_tex_fix(param_20, param_21);\n    float _720 = _229_fa_layers_a.x;\n    float _721 = _229_fa_layers_a.y;\n    float _724 = _229_fa_layers_a.z;\n    float _723 = _229_fa_layers_b.w;\n    float _726 = _229_fa_layers_c.x;\n    if (_229_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_229_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _720 *= _369.y;\n            _721 *= _369.z;\n            _723 *= _357.w;\n        }\n        if (_229_fa_layers_c.z > 1.5f)\n        {\n            _724 *= mrt.x;\n            _726 *= mrt.w;\n        }\n    }\n    Surface _745 = { _256.xyz, _256.w, _715, clamp(_229_fa_pbr.x * _327.z, 0.0f, 1.0f), clamp(_229_fa_pbr.y * _327.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_229_fa_maps.y * (_369.x - 1.0f)), _229_fa_emissive.xyz + (_229_fa_model_emissive.xyz * _399), _720, _721, _229_fa_layers_b.xyz, _723, _724, _229_fa_layers_a.w, _726, _229_fa_layers_c.y, _229_fa_layers_d.xyz };\n    return _745;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.albedo *= lerp(0.5f, 1.0f, height.Sample(height_smp, i.uv).x);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _626 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _626 = -_626;\n    }\n    float3 _533 = normalize(_229_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _639 = { fa_world_pos, _626, fa_world_tangent, fa_uv, fa_vertex_color, _533, gl_FrontFacing };\n    SurfaceInput param = _639;\n    SurfaceInput _647 = { fa_world_pos, _626, fa_world_tangent, fa_uv, fa_vertex_color, _533, gl_FrontFacing };\n    SurfaceInput param_1 = _647;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _548 = normalize(param_2.normal);\n    float3 _563 = normalize(float3(dot(fa_pre_r0, _548), dot(fa_pre_r1, _548), dot(fa_pre_r2, _548)));\n    float _575 = _563.z;\n    float2 e = _563.xy / ((abs(_563.x) + abs(_563.y)) + abs(_575)).xx;\n    if (_575 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_68",
            "hlsl_register_b_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_165",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_212",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_229",
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
          },
          {
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 5
            }
          },
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 6
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "height_smp",
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
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6
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
            "name": "height_height_smp",
            "view_name": "height",
            "sampler_name": "height_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    },
    "shadow": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_material_vs : register(b4)\n{\n    float _54_lift : packoffset(c0);\n    float _54_fa_pad0 : packoffset(c0.y);\n    float _54_fa_pad1 : packoffset(c0.z);\n    float _54_fa_pad2 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _151_fa_view_proj : packoffset(c0);\n    row_major float4x4 _151_fa_light_vp : packoffset(c4);\n    float4 _151_fa_uv_scale : packoffset(c8);\n    float4 _151_fa_time : packoffset(c9);\n    float4 _151_fa_lm_so : packoffset(c10);\n};\n\nTexture2D<float4> fa_vs_height : register(t0);\nSamplerState fa_vs_height_smp : register(s6);\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float3 fa_normal : TEXCOORD5;\n    float2 fa_texcoord0 : TEXCOORD6;\n    float4 fa_tangent : TEXCOORD7;\n    float4 fa_color : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _99 = (dot(model[0].xyz, _94) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _277 = { mul(float4(position, 1.0f), model).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _99, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _99), texcoord0 * _151_fa_uv_scale.xy, color, position };\n    return _277;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += (fa_vs_height.SampleLevel(fa_vs_height_smp, v.uv, 0.0f).x * _54_lift);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _151_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    return stage_output;\n}\n",
      "fs": "static float4 gl_FragCoord;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nvoid frag_main()\n{\n    fa_frag_color = float4(gl_FragCoord.z, 0.0f, 0.0f, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_54",
            "hlsl_register_b_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_151",
            "hlsl_register_b_n": 0
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 6
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "vertex",
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_material_vs : register(b4)\n{\n    float _59_lift : packoffset(c0);\n    float _59_fa_pad0 : packoffset(c0.y);\n    float _59_fa_pad1 : packoffset(c0.z);\n    float _59_fa_pad2 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _156_fa_view_proj : packoffset(c0);\n    row_major float4x4 _156_fa_light_vp : packoffset(c4);\n    float4 _156_fa_uv_scale : packoffset(c8);\n    float4 _156_fa_time : packoffset(c9);\n    float4 _156_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _203_fa_joint_rows[192] : packoffset(c0);\n};\n\nTexture2D<float4> fa_vs_height : register(t0);\nSamplerState fa_vs_height_smp : register(s6);\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float4 fa_joints : TEXCOORD5;\n    float4 fa_weights : TEXCOORD6;\n    float3 fa_normal : TEXCOORD7;\n    float2 fa_texcoord0 : TEXCOORD8;\n    float4 fa_tangent : TEXCOORD9;\n    float4 fa_color : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 gl_Position : SV_Position;\n};\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _194 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_203_fa_joint_rows[_194] * weights[i]);\n        r1 += (_203_fa_joint_rows[_194 + 1] * weights[i]);\n        r2 += (_203_fa_joint_rows[_194 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _104 = (dot(model[0].xyz, _99) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _398 = { mul(float4(position, 1.0f), model).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _104, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _104), texcoord0 * _156_fa_uv_scale.xy, color, position };\n    return _398;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += (fa_vs_height.SampleLevel(fa_vs_height_smp, v.uv, 0.0f).x * _59_lift);\n}\n\nvoid vert_main()\n{\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    fa_inst_begin();\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    vertex(param_8);\n    gl_Position = mul(float4(param_8.world_pos, 1.0f), _156_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    return stage_output;\n}\n",
      "fs": "static float4 gl_FragCoord;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nvoid frag_main()\n{\n    fa_frag_color = float4(gl_FragCoord.z, 0.0f, 0.0f, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_59",
            "hlsl_register_b_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_156",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_203",
            "hlsl_register_b_n": 3
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 6
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "vertex",
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6
          }
        ]
      }
    }
  }
}
