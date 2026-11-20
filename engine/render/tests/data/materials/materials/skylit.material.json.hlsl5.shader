{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "5f457c7d0bc8edbcdea422ba00c093c613745eefd8db6d8c8f93fc5e235db1e8",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _260 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _260;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_267, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _3516[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _429_fa_camera_pos : packoffset(c0);\n    float4 _429_fa_ambient : packoffset(c1);\n    float4 _429_fa_base_color : packoffset(c2);\n    float4 _429_fa_emissive : packoffset(c3);\n    float4 _429_fa_model_emissive : packoffset(c4);\n    float4 _429_fa_pbr : packoffset(c5);\n    float4 _429_fa_maps : packoffset(c6);\n    float4 _429_fa_fog : packoffset(c7);\n    float4 _429_fa_fog_b : packoffset(c8);\n    float4 _429_fa_fog_c : packoffset(c9);\n    float4 _429_fa_counts : packoffset(c10);\n    float4 _429_fa_env_sky : packoffset(c11);\n    float4 _429_fa_env_horizon : packoffset(c12);\n    float4 _429_fa_time : packoffset(c13);\n    float4 _429_fa_cl_vpx : packoffset(c14);\n    float4 _429_fa_cl_vpy : packoffset(c15);\n    float4 _429_fa_cl_vpw : packoffset(c16);\n    float4 _429_fa_cl_fwd : packoffset(c17);\n    float4 _429_fa_cl_grid : packoffset(c18);\n    float4 _429_fa_cl_info : packoffset(c19);\n    float4 _429_fa_layers_a : packoffset(c20);\n    float4 _429_fa_layers_b : packoffset(c21);\n    float4 _429_fa_layers_c : packoffset(c22);\n    float4 _429_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2086_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2086_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2086_fa_shadow_info[4] : packoffset(c20);\n    float4 _2086_fa_shadow_split : packoffset(c24);\n    float4 _2086_fa_shadow_cfg : packoffset(c25);\n    float4 _2086_fa_shadow_bias : packoffset(c26);\n    float4 _2086_fa_shadow_eye : packoffset(c27);\n    float4 _2086_fa_shadow_fwd : packoffset(c28);\n    float4 _2086_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1357 = _429_fa_cl_info.x < 0.0f;\n    bool _1364;\n    if (!_1357)\n    {\n        _1364 = _429_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1364 = _1357;\n    }\n    bool _1372;\n    if (!_1364)\n    {\n        _1372 = _429_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1372 = _1364;\n    }\n    bool _1379;\n    if (!_1372)\n    {\n        _1379 = _429_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1379 = _1372;\n    }\n    bool _1386;\n    if (!_1379)\n    {\n        _1386 = _429_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1386 = _1379;\n    }\n    if (_1386)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1396 = float4(world_pos, 1.0f);\n    float _1402 = dot(_429_fa_cl_vpw, _1396);\n    if (!(_1402 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1424 = float2(dot(_429_fa_cl_vpx, _1396), dot(_429_fa_cl_vpy, _1396)) / _1402.xx;\n    int _1428 = int(_429_fa_cl_grid.x);\n    int _1432 = int(_429_fa_cl_grid.y);\n    int param = (int(_429_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_429_fa_cl_fwd.xyz, world_pos) + _429_fa_cl_fwd.w, _429_fa_cl_grid.w) / _429_fa_cl_grid.w) * _429_fa_cl_grid.z)), 0, int(_429_fa_cl_info.y) - 1) * _1432) + clamp(int(floor(((_1424.y * 0.5f) + 0.5f) * _429_fa_cl_grid.y)), 0, _1432 - 1)) * _1428)) + clamp(int(floor(((_1424.x * 0.5f) + 0.5f) * _429_fa_cl_grid.x)), 0, _1428 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1508 = fa_cluster_texel(param);\n    return int2(int(_1508.x), int(_1508.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_429_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4046 = fa_cluster_lookup(param);\n    fa_cl_slot = _4046.x;\n    fa_cl_local = _4046.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _4209 = fa_linear_to_srgb(param);\n        c = _4209;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _4217 = fa_srgb_to_linear(param_1);\n            c = _4217;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _312;\n    if (i.front_facing)\n    {\n        _312 = i.world_normal;\n    }\n    else\n    {\n        _312 = -i.world_normal;\n    }\n    float3 _336 = normalize(i.world_tangent.xyz - (_312 * dot(_312, i.world_tangent.xyz)));\n    float3 _363 = normalize(((_336 * m.x) + ((cross(_312, _336) * i.world_tangent.w) * m.y)) + (_312 * m.z));\n    float3 _366;\n    if (i.front_facing)\n    {\n        _366 = _363;\n    }\n    else\n    {\n        _366 = -_363;\n    }\n    return _366;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _429_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _4248 = fa_tex_fix(param_2, param_3);\n    float4 _5363 = base_t;\n    _5363.x = _4248.x;\n    _5363.y = _4248.y;\n    _5363.z = _4248.z;\n    base_t = _5363;\n    float4 _4262 = (_5363 * _429_fa_base_color) * i.vertex_color;\n    float3 _5215 = i.world_normal;\n    if (_429_fa_maps.z > 0.5f)\n    {\n        float param_4 = _429_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4294 = fa_tex_fix(param_6, param_7);\n        float3 _4297 = (_4294 * 2.0f) - 1.0f.xxx;\n        float2 _4302 = _4297.xy * _429_fa_maps.x;\n        float3 _5371 = _4297;\n        _5371.x = _4302.x;\n        _5371.y = _4302.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5371;\n        _5215 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _429_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4330 = fa_tex_fix(param_12, param_13);\n    float4 _5374 = mrt;\n    _5374.x = _4330.x;\n    _5374.y = _4330.y;\n    _5374.z = _4330.z;\n    mrt = _5374;\n    float4 _4358 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _429_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _4358.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4369 = fa_tex_fix(param_16, param_17);\n    float param_18 = _429_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4399 = fa_tex_fix(param_20, param_21);\n    float _5220 = _429_fa_layers_a.x;\n    float _5221 = _429_fa_layers_a.y;\n    float _5224 = _429_fa_layers_a.z;\n    float _5223 = _429_fa_layers_b.w;\n    float _5226 = _429_fa_layers_c.x;\n    if (_429_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_429_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _5220 *= _4369.y;\n            _5221 *= _4369.z;\n            _5223 *= _4358.w;\n        }\n        if (_429_fa_layers_c.z > 1.5f)\n        {\n            _5224 *= mrt.x;\n            _5226 *= mrt.w;\n        }\n    }\n    Surface _5245 = { _4262.xyz, _4262.w, _5215, clamp(_429_fa_pbr.x * _4330.z, 0.0f, 1.0f), clamp(_429_fa_pbr.y * _4330.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_429_fa_maps.y * (_4369.x - 1.0f)), _429_fa_emissive.xyz + (_429_fa_model_emissive.xyz * _4399), _5220, _5221, _429_fa_layers_b.xyz, _5223, _5224, _429_fa_layers_a.w, _5226, _429_fa_layers_c.y, _429_fa_layers_d.xyz };\n    return _5245;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1588 = rect.zw - rect.xy;\n    float2 _1592 = _1588 * atlas;\n    float2 _1596 = ddx * _1592;\n    float2 _1600 = ddy * _1592;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1588), clamp(0.5f * log2(max(max(dot(_1596, _1596), dot(_1600, _1600)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1633 = _429_fa_counts.y < 0.5f;\n    bool _1640;\n    if (!_1633)\n    {\n        _1640 = _429_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1640 = _1633;\n    }\n    if (_1640)\n    {\n        return;\n    }\n    float3 _1646 = ddx(world_pos);\n    float3 _1649 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1653 = fa_cluster_texel(param);\n    int _1657 = int(_1653.w);\n    if (_1657 < 1)\n    {\n        return;\n    }\n    int _1667 = int(_429_fa_counts.y + 0.5f);\n    int param_1 = _1667;\n    float4 _1671 = fa_light_texel(param_1);\n    float2 _1674 = _1671.yz;\n    int _1678 = int(_1671.w);\n    int param_2 = _1667 + 1;\n    float4 _1683 = fa_light_texel(param_2);\n    float _1684 = _1683.x;\n    int _1690 = int(_429_fa_counts.w + 0.5f) - 1;\n    int _1694 = int(_1653.z);\n    float3 _1959;\n    for (int k = 0; k < _1657; k++)\n    {\n        int _1707 = _1694 + k;\n        int param_3 = _1678 + (_1707 >> 2);\n        int _1724 = (_1667 + 2) + (int(fa_light_texel(param_3)[_1707 & 3]) * 7);\n        int param_4 = _1724 + 6;\n        float4 _1729 = fa_light_texel(param_4);\n        if (((int(_1729.w + 0.5f) >> _1690) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1724;\n        float4 _1744 = fa_light_texel(param_5);\n        int param_6 = _1724 + 1;\n        float4 _1749 = fa_light_texel(param_6);\n        int param_7 = _1724 + 2;\n        float4 _1754 = fa_light_texel(param_7);\n        float3 _1757 = _1744.xyz;\n        float _1762 = dot(_1757, world_pos) + _1744.w;\n        float3 _1764 = _1749.xyz;\n        float _1769 = dot(_1764, world_pos) + _1749.w;\n        float3 _1771 = _1754.xyz;\n        float _1776 = dot(_1771, world_pos) + _1754.w;\n        bool _1781 = abs(_1762) > 0.5f;\n        bool _1789;\n        if (!_1781)\n        {\n            _1789 = abs(_1769) > 0.5f;\n        }\n        else\n        {\n            _1789 = _1781;\n        }\n        bool _1797;\n        if (!_1789)\n        {\n            _1797 = abs(_1776) > 0.5f;\n        }\n        else\n        {\n            _1797 = _1789;\n        }\n        if (_1797)\n        {\n            continue;\n        }\n        float _1812 = clamp(dot(geo_normal, normalize(_1771)) * _1729.z, 0.0f, 1.0f);\n        if (_1812 <= 0.0f)\n        {\n            continue;\n        }\n        float _1832 = (clamp((0.5f - abs(_1776)) * 10.0f, 0.0f, 1.0f) * _1812) * _1729.x;\n        float2 _1840 = float2(_1762 + 0.5f, 0.5f - _1769);\n        float2 _1850 = float2(dot(_1757, _1646), dot(_1764, _1646));\n        float2 _1860 = float2(dot(_1757, _1649), dot(_1764, _1649));\n        int param_8 = _1724 + 5;\n        float4 _1865 = fa_light_texel(param_8);\n        int param_9 = _1724 + 3;\n        float4 _1870 = fa_light_texel(param_9);\n        int param_10 = _1724 + 4;\n        float4 _1875 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1865.xyz;\n        bool _1885 = _1870.z > _1870.x;\n        if (_1885)\n        {\n            float4 param_11 = _1870;\n            float2 param_12 = _1840;\n            float2 param_13 = _1674;\n            float2 param_14 = _1850;\n            float2 param_15 = _1860;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1684 > 0.5f) && (_1684 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1911 = fa_dc_to_linear(param_16);\n                float4 _5295 = tx;\n                _5295.x = _1911.x;\n                _5295.y = _1911.y;\n                _5295.z = _1911.z;\n                tx = _5295;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1832 * tex_a) * _1865.w, 0.0f, 1.0f).xxx);\n        if (_1875.z > _1875.x)\n        {\n            float4 param_17 = _1875;\n            float2 param_18 = _1840;\n            float2 param_19 = _1674;\n            float2 param_20 = _1850;\n            float2 param_21 = _1860;\n            float4 _1955 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1684 > 1.5f)\n            {\n                float3 param_22 = _1955.xyz;\n                float3 _1965 = fa_dc_to_srgb(param_22);\n                _1959 = _1965;\n            }\n            else\n            {\n                _1959 = _1955.xyz;\n            }\n            float3 _1974 = (_1959 * 2.0f) - 1.0f.xxx;\n            float2 _1979 = _1974.xy * _1729.y;\n            float3 _2001 = (normalize(_1757) * _1979.x) + (normalize(_1764) * _1979.y);\n            float3 _2004 = normalize(normal);\n            normal = normalize(lerp(_2004, normalize((_2004 * max(_1974.z, 0.0500000007450580596923828125f)) + (_2001 - (_2004 * dot(_2004, _2001)))), clamp(_1832 * (_1885 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_sky_sh_coef(int k)\n{\n    float3 v = fa_env_tex.SampleLevel(fa_env_smp, float3(1.0f, 1.0f - (float((2 * (k >> 2)) + 1) * 0.25f), 1.0f - (float((2 * (k & 3)) + 1) * 0.25f)), 5.0f).xyz;\n    if (_429_fa_env_sky.w > 1.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3199 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3199;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_429_fa_env_sky.w > 0.5f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _429_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3442 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3449 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3452 = int(_3442);\n    int _3455 = int(_3449);\n    float _3465 = _3449 - float(_3455);\n    int _3520 = (_3452 * 9) + _3455;\n    int _3540 = ((_3452 + 1) * 9) + _3455;\n    return lerp(lerp(_3516[_3520], _3516[_3520 + 1], _3465), lerp(_3516[_3540], _3516[_3540 + 1], _3465), _3442 - float(_3452));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _5074 = false;\n    float _5075 = 1.0f;\n    float _5076 = 1.0f;\n    float _5077 = 1.0f;\n    float _5078 = 0.0f;\n    float _5079 = 0.0f;\n    float _5080 = 0.0f;\n    float _5081 = 0.0f;\n    float _5083 = 1.0f;\n    bool _5084 = false;\n    float3 _5085 = 0.0f.xxx;\n    float _5086 = 1.0f;\n    float _5087 = 1.0f;\n    float _5088 = 1.0f;\n    float _5089 = 0.0f;\n    float _5090 = 0.0f;\n    float3 _5091 = float3(1.0f, 0.0f, 0.0f);\n    float3 _5092 = float3(0.0f, 0.0f, 1.0f);\n    float _5093 = 1.0f;\n    float _5094 = 1.0f;\n    float _3591 = clamp(s.specular, 0.0f, 1.0f);\n    float _3595 = clamp(s.ior, 1.0f, 3.0f);\n    bool _3600 = (_3591 != 1.0f) || (_3595 != 1.5f);\n    bool _3609;\n    if (!_3600)\n    {\n        _3609 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _3609 = _3600;\n    }\n    if (_3609)\n    {\n        float _3617 = (_3595 - 1.0f) / (_3595 + 1.0f);\n        f0 = lerp(min((_3617 * _3617).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _3591, s.albedo, metallic.xxx);\n        _5075 = lerp(_3591, 1.0f, metallic);\n        _5074 = true;\n    }\n    float _3644 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_3644 > 0.0f)\n    {\n        float _3652 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _5078 = _3644;\n        _5079 = _3652;\n        float _3659 = _3652 * _3652;\n        _5080 = _3659;\n        _5081 = _3659 * _3659;\n        float _3671 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _5083 = _3671;\n        _5076 = 1.0f - (_3644 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _3671, 0.0f, 1.0f), 5.0f))));\n        _5074 = true;\n    }\n    float3 _3690 = max(s.sheen_color, 0.0f.xxx);\n    float _3699 = max(_3690.x, max(_3690.y, _3690.z));\n    if (_3699 > 0.0f)\n    {\n        float _3707 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _5084 = true;\n        _5085 = _3690;\n        _5086 = _3707;\n        _5087 = _3707 * _3707;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _3707;\n        float _3724 = fa_sheen_albedo(param, param_1);\n        _5089 = _3724;\n        _5088 = 1.0f - min(_3699 * _3724, 1.0f);\n        _5074 = true;\n    }\n    _5077 = _5076 * _5088;\n    float _3743 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_3743 != 0.0f)\n    {\n        float3 _3758 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _3758;\n        if (dot(_3758, _3758) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _3770 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_3770.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _3770.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _3770.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _3774 = t;\n        float3 _3775 = normalize(_3774);\n        t = _3775;\n        float3 _3800 = normalize((_3775 * cos(s.anisotropy_rotation)) + ((cross(n, _3775) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _5091 = _3800;\n        _5092 = cross(n, _3800);\n        float _3810 = roughness * roughness;\n        float _3816 = lerp(_3810, 1.0f, _3743 * _3743);\n        bool _3818 = _3743 > 0.0f;\n        _5093 = _3818 ? _3816 : _3810;\n        _5094 = _3818 ? _3810 : _3816;\n        _5090 = _3743;\n        _5074 = true;\n    }\n    FaLayers _5116 = { _5074, _5075, _5076, _5077, _5078, _5079, _5080, _5081, i.world_normal, _5083, _5084, _5085, _5086, _5087, _5088, _5089, _5090, _5091, _5092, _5093, _5094 };\n    return _5116;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3374 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3377 = _3374.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3377 * _3377, exp2((-9.27999973297119140625f) * ndv)) * _3377) + _3374.y)) + _3374.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_429_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _429_fa_env_horizon.w).xyz;\n    }\n    float _3228 = rough * rough;\n    float _3258 = 0.60000002384185791015625f * _3228;\n    return lerp(lerp(_429_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_429_fa_env_horizon.xyz, _429_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3228)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3258, 0.0500000007450580596923828125f + _3258, d.y).xxx), ((_429_fa_env_sky.xyz + _429_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3228 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _3851;\n        if (L.aniso >= 0.0f)\n        {\n            _3851 = L.b;\n        }\n        else\n        {\n            _3851 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_3851, v), _3851), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3884 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _3884.x) + (L.f90.xxx * _3884.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3939 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _3939.x) + _3939.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3416 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3416.x) + _3416.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _3968 = clamp(s.metallic, 0.0f, 1.0f);\n    float _3972 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _3979 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _3968.xxx);\n    float3 f0 = _3979;\n    float3 _3983 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _3983;\n    float3 param_3 = i.view_dir;\n    float param_4 = _3968;\n    float param_5 = _3972;\n    float3 param_6 = _3979;\n    FaLayers _4000 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4000.on)\n    {\n        FaLayers param_7 = _4000;\n        float3 param_8 = _3983;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _3972;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _3983;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _3972;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_429_fa_cl_info.x) + int(_429_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_429_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _488_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _488_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _607 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _620 = (c - (ru * hx)) - p;\n        float3 _626 = ru * (2.0f * hx);\n        float _632 = max(dot(_626, _626), 9.9999999392252902907785028219223e-09f);\n        float _636 = dot(_620, _626);\n        float t = clamp((-_636) / _632, 0.0f, 1.0f);\n        if (_607)\n        {\n            float _651 = dot(r, _626);\n            float _657 = _632 - (_651 * _651);\n            if (abs(_657) > (9.9999997473787516355514526367188e-06f * _632))\n            {\n                t = clamp(((dot(r, _620) * _651) - _636) / _657, 0.0f, 1.0f);\n            }\n        }\n        return (p + _620) + (_626 * t);\n    }\n    float3 q = p;\n    float _689 = dot(r, axis);\n    bool _697;\n    if (_607)\n    {\n        _697 = abs(_689) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _697 = _607;\n    }\n    if (_697)\n    {\n        float _707 = dot(c - p, axis) / _689;\n        if (_707 > 0.0f)\n        {\n            q = p + (r * _707);\n        }\n    }\n    float3 _720 = q - c;\n    float2 xy = float2(dot(_720, ru), dot(_720, uu));\n    if (shape > 0.5f)\n    {\n        float _735 = length(xy);\n        if (_735 > hx)\n        {\n            xy *= (hx / _735);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _378 = abs(d);\n    float _380 = _378.x;\n    float _382 = _378.y;\n    bool _383 = _380 >= _382;\n    bool _391;\n    if (_383)\n    {\n        _391 = _380 >= _378.z;\n    }\n    else\n    {\n        _391 = _383;\n    }\n    int _392;\n    if (_391)\n    {\n        _392 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _407;\n        if (_382 >= _378.z)\n        {\n            _407 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _407 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _392 = _407;\n    }\n    return _392;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _527 = dot(d, right);\n    float _531 = dot(d, up);\n    float _542;\n    if (((_527 * _527) + (_531 * _531)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _542 = atan2(_531, _527) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _542 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_542 - floor(_542)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _773 = fa_light_base(param);\n    bool _777 = _429_fa_ambient.w > 4.5f;\n    int param_1 = _773;\n    float4 _781 = fa_light_texel(param_1);\n    int param_2 = _773 + 1;\n    float4 _786 = fa_light_texel(param_2);\n    float _789 = _786.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _801 = _777 && (_789 > 2.5f);\n    fa_light_is_area = _801;\n    bool _803 = _789 < 0.5f;\n    float3 l;\n    if (_803)\n    {\n        l = normalize(_781.xyz);\n        if (_777)\n        {\n            int param_3 = _773 + 6;\n            float4 _817 = fa_light_texel(param_3);\n            if (_817.z > 0.5f)\n            {\n                int param_4 = _773 + 4;\n                float4 _827 = fa_light_texel(param_4);\n                int param_5 = _773 + 5;\n                float4 _832 = fa_light_texel(param_5);\n                float2 param_6 = _817.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _827.xyz) * _827.w, (-dot(world_pos, _832.xyz)) * _832.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _862 = _781.xyz;\n        float3 _864 = _862 - world_pos;\n        float3 to_light = _864;\n        float _867 = length(_864);\n        float reach = _867;\n        bool front = true;\n        if (_801)\n        {\n            int param_8 = _773 + 7;\n            reach = max(_867 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _773 + 4;\n            float4 _891 = fa_light_texel(param_9);\n            int param_10 = _773 + 5;\n            float4 _896 = fa_light_texel(param_10);\n            int param_11 = _773 + 6;\n            float4 _901 = fa_light_texel(param_11);\n            float _902 = _901.w;\n            int param_12 = _773 + 2;\n            float3 _909 = normalize(fa_light_texel(param_12).xyz);\n            bool _911 = _902 > 1.5f;\n            bool _919;\n            if (!_911)\n            {\n                _919 = dot(_909, to_light) < 0.0f;\n            }\n            else\n            {\n                _919 = _911;\n            }\n            front = _919;\n            float3 r = 0.0f.xxx;\n            float3 _928 = _429_fa_camera_pos.xyz - world_pos;\n            bool _932 = dot(n, n) > 0.5f;\n            bool _940;\n            if (_932)\n            {\n                _940 = dot(_928, _928) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _940 = _932;\n            }\n            if (_940)\n            {\n                r = reflect(-normalize(_928), normalize(n));\n            }\n            float3 param_13 = _862;\n            float3 param_14 = _909;\n            float3 param_15 = _891.xyz;\n            float3 param_16 = _896.xyz;\n            float param_17 = _891.w;\n            float param_18 = _896.w;\n            float param_19 = _902;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _976 = length(to_light);\n        dist = _976;\n        l = to_light / max(_976, 9.9999997473787516355514526367188e-05f).xxx;\n        float _990 = reach / max(_781.w, 0.001000000047497451305389404296875f);\n        float _996 = clamp(1.0f - (_990 * _990), 0.0f, 1.0f);\n        float _998;\n        if (front)\n        {\n            _998 = _996 * _996;\n        }\n        else\n        {\n            _998 = 0.0f;\n        }\n        atten = _998;\n        bool _1009 = _789 < 2.5f;\n        if ((_789 > 1.5f) && _1009)\n        {\n            int param_22 = _773 + 2;\n            float4 _1017 = fa_light_texel(param_22);\n            float _1027 = _1017.w;\n            int param_23 = _773 + 3;\n            float4 _1032 = fa_light_texel(param_23);\n            float _1033 = _1032.x;\n            float cos_inner = _1033;\n            if (_1033 > 1.5f)\n            {\n                cos_inner = lerp(_1027, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1027, cos_inner, dot(-l, normalize(_1017.xyz)));\n        }\n        if (_777 && (_789 < 1.5f))\n        {\n            int param_24 = _773 + 6;\n            float4 _1057 = fa_light_texel(param_24);\n            if (_1057.z > 0.5f)\n            {\n                float3 _1065 = -to_light;\n                int param_25 = _773 + 4;\n                int param_26 = _773 + 5;\n                float3 _1079 = fa_light_texel(param_25).xyz;\n                float3 _1083 = fa_light_texel(param_26).xyz;\n                float3 _1092 = float3(dot(_1065, _1079), dot(_1065, _1083), dot(_1065, cross(_1079, _1083)));\n                float3 param_27 = _1092;\n                int _1096 = fa_cube_face(param_27);\n                int param_28 = _1096;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1123 = float2(dot(_1092, cross(param_29, param_30)), dot(_1092, param_30)) / max(dot(_1092, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1127 = _1096 / 3;\n                float2 param_31 = _1057.xy + (float2(float(_1096 - (_1127 * 3)), float(_1127)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1123.x), 0.5f - (0.5f * _1123.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _773 + 7;\n            float4 _1157 = fa_light_texel(param_33);\n            if (_1157.z > 0.5f)\n            {\n                int param_34 = _773 + 2;\n                int param_35 = _773 + 4;\n                int param_36 = _773 + 5;\n                float2 param_37 = _1157.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_777 && _1009)\n            {\n                int param_42 = _773 + 6;\n                float4 _1204 = fa_light_texel(param_42);\n                int param_43 = _773 + 7;\n                float4 _1209 = fa_light_texel(param_43);\n                bool _1212 = _1204.z > 0.5f;\n                bool _1219;\n                if (!_1212)\n                {\n                    _1219 = _1209.z > 0.5f;\n                }\n                else\n                {\n                    _1219 = _1212;\n                }\n                if (_1219)\n                {\n                    int param_44 = _773 + 2;\n                    float4 _1226 = fa_light_texel(param_44);\n                    float3 _1230 = normalize(_1226.xyz);\n                    int param_45 = _773 + 4;\n                    float4 _1235 = fa_light_texel(param_45);\n                    int param_46 = _773 + 5;\n                    float4 _1240 = fa_light_texel(param_46);\n                    if (_1212)\n                    {\n                        float3 _1248 = -to_light;\n                        float _1255 = _1226.w;\n                        float _1271 = 0.5f / max(dot(_1248, _1230) * (sqrt(max(1.0f - (_1255 * _1255), 0.0f)) / max(_1255, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1204.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1248, _1235.xyz) * _1271), 0.5f - (dot(_1248, _1240.xyz) * _1271));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1209.z > 0.5f)\n                    {\n                        float2 param_49 = _1209.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1230;\n                        float3 param_52 = _1235.xyz;\n                        float3 param_53 = _1240.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _5062 = _786.xyz * atten;\n    if (_777)\n    {\n        _5062 *= fa_light_tint;\n    }\n    int _1339;\n    if (_803)\n    {\n        _1339 = 0;\n    }\n    else\n    {\n        _1339 = ((_789 > 1.5f) && (_789 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _5073 = { l, _5062, atten, 1.0f, dist, _1339 };\n    return _5073;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2076;\n    if (i == 0)\n    {\n        _2076 = _2086_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2092;\n        if (i == 1)\n        {\n            _2092 = _2086_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2100;\n            if (i == 2)\n            {\n                _2100 = _2086_fa_shadow_split.z;\n            }\n            else\n            {\n                _2100 = _2086_fa_shadow_split.w;\n            }\n            _2092 = _2100;\n        }\n        _2076 = _2092;\n    }\n    return _2076;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2133 = fa_shadow_depth(param, param_1);\n    float _2137;\n    if (conv.x < 0.5f)\n    {\n        _2137 = _2133;\n    }\n    else\n    {\n        _2137 = (conv.y * conv.z) / (conv.z - (_2133 * (conv.z - conv.y)));\n    }\n    return _2137;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2064 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2064), sin(_2064)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2183 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2192;\n        if (k < 0.0f)\n        {\n            _2192 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2192 = k;\n        }\n        float _2212 = clamp((_2192 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2183;\n            float2 _2231 = fa_shadow_vogel(param_3, param_4, param_5) * _2212;\n            float2 param_6 = uv + (_2231 * _2086_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2243 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2243 < (zr - (length(_2231) * plane)))\n            {\n                sum += _2243;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2269 = sum / cnt;\n        float _2279;\n        if (k < 0.0f)\n        {\n            _2279 = (-k) / max(_2269, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2279 = k;\n        }\n        radius = clamp(((max(zr - _2269, 0.0f) * unit) * _2279) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2301 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2301; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2301;\n        float param_11 = _2183;\n        float2 _2320 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2320 * _2086_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2320) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2301);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2362 = max(_2086_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2367 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2373 = sqrt(1.0f - (_2367 * _2367));\n    float _2380 = min(_2373 / max(_2367, 0.20000000298023223876953125f), 4.0f);\n    float _2385;\n    if (_2086_fa_shadow_bias.y > 0.0f)\n    {\n        _2385 = _2086_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2385 = 1.5f * _2086_fa_shadow_info[ci].x;\n    }\n    float4 _2410 = mul(float4(world + (n * (_2385 * _2373)), 1.0f), _2086_fa_shadow_mat[ci]);\n    float _2417 = _2410.x;\n    bool _2420 = _2417 < _2086_fa_shadow_rect[ci].x;\n    bool _2429;\n    if (!_2420)\n    {\n        _2429 = _2417 > _2086_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2429 = _2420;\n    }\n    bool _2438;\n    if (!_2429)\n    {\n        _2438 = _2410.y < _2086_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2438 = _2429;\n    }\n    bool _2447;\n    if (!_2438)\n    {\n        _2447 = _2410.y > _2086_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2447 = _2438;\n    }\n    bool _2454;\n    if (!_2447)\n    {\n        _2454 = _2410.z > 1.0f;\n    }\n    else\n    {\n        _2454 = _2447;\n    }\n    if (_2454)\n    {\n        return -1.0f;\n    }\n    float _2462;\n    if (_2086_fa_shadow_bias.x > 0.0f)\n    {\n        _2462 = _2086_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2462 = 1.5f * _2086_fa_shadow_info[ci].x;\n    }\n    float2 param = _2410.xy;\n    float4 param_1 = _2086_fa_shadow_rect[ci];\n    float param_2 = _2410.z - ((_2462 * (1.0f + (0.5f * _2380))) / _2362);\n    float param_3 = _2086_fa_shadow_info[ci].x;\n    float param_4 = _2362;\n    float param_5 = _2362 * 0.25f;\n    float param_6 = ((_2086_fa_shadow_info[ci].x * min(_2380, 3.0f)) * 0.5f) / _2362;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2086_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2086_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_429_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2840 = int(_2086_fa_shadow_cfg.x + 0.5f);\n    if (_2840 < 1)\n    {\n        return 1.0f;\n    }\n    float _2855 = dot(world - _2086_fa_shadow_eye.xyz, _2086_fa_shadow_fwd.xyz);\n    int param = _2840 - 1;\n    if (_2855 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2867 = _2840 > 1;\n    bool _2874;\n    if (_2867)\n    {\n        _2874 = _2855 > _2086_fa_shadow_split.x;\n    }\n    else\n    {\n        _2874 = _2867;\n    }\n    if (_2874)\n    {\n        ci = 1;\n    }\n    bool _2878 = _2840 > 2;\n    bool _2885;\n    if (_2878)\n    {\n        _2885 = _2855 > _2086_fa_shadow_split.y;\n    }\n    else\n    {\n        _2885 = _2878;\n    }\n    if (_2885)\n    {\n        ci = 2;\n    }\n    bool _2889 = _2840 > 3;\n    bool _2896;\n    if (_2889)\n    {\n        _2896 = _2855 > _2086_fa_shadow_split.z;\n    }\n    else\n    {\n        _2896 = _2889;\n    }\n    if (_2896)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2840)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2922 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2922;\n        if (_2922 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2086_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2947;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2947 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2947 = _2086_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2966 = _2086_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2947, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2977 = clamp((_2855 - (fa_shadow_split_at(param_7) - _2966)) / _2966, 0.0f, 1.0f);\n        if (_2977 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2840)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2998 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2998;\n                if (_2998 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2977);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2520 = _429_fa_pbr.z < 0.5f;\n    bool _2527;\n    if (!_2520)\n    {\n        _2527 = _2086_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2527 = _2520;\n    }\n    if (_2527)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2086_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2540 = fa_light_texel(param);\n    float _2541 = _2540.x;\n    if (_2541 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2550 = int(_2541 + 0.5f);\n    int param_1 = _2550;\n    float4 _2554 = fa_light_texel(param_1);\n    int param_2 = _2550 + 1;\n    float4 _2559 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2562 = _2554.y;\n    if (_2562 > 0.0f)\n    {\n        float _2579 = 1.0f - smoothstep(0.75f * _2562, _2562, length(world - _2086_fa_shadow_eye.xyz));\n        fade = _2579;\n        if (_2579 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2554.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2603 = (_2550 + 2) + (face * 6);\n    int param_4 = _2603;\n    int param_5 = _2603 + 1;\n    int param_6 = _2603 + 3;\n    float4 _2617 = fa_light_texel(param_6);\n    int param_7 = _2603 + 4;\n    float4 _2622 = fa_light_texel(param_7);\n    int param_8 = _2603 + 5;\n    float4 _2627 = fa_light_texel(param_8);\n    float _2639 = _2627.x * max(dot(_2617, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2644 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2667 = clamp(dot(n, _2617.xyz), -1.0f, 1.0f);\n    float _2686 = min(sqrt(1.0f - (_2667 * _2667)) / max(abs(dot(n, world - lpos)) / max(dot(_2617, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2689 = _2559.y;\n    float _2691;\n    if (_2689 > 0.0f)\n    {\n        _2691 = _2689;\n    }\n    else\n    {\n        _2691 = 1.5f * _2639;\n    }\n    float4 _2711 = float4(world + (n * (_2691 * sqrt(1.0f - (_2644 * _2644)))), 1.0f);\n    float _2715 = dot(_2617, _2711);\n    float _2718 = _2627.y;\n    if (_2715 < _2718)\n    {\n        return 1.0f;\n    }\n    float2 _2733 = float2(dot(fa_light_texel(param_4), _2711), dot(fa_light_texel(param_5), _2711)) / _2715.xx;\n    float _2735 = _2733.x;\n    bool _2738 = _2735 < _2622.x;\n    bool _2747;\n    if (!_2738)\n    {\n        _2747 = _2735 > _2622.z;\n    }\n    else\n    {\n        _2747 = _2738;\n    }\n    bool _2756;\n    if (!_2747)\n    {\n        _2756 = _2733.y < _2622.y;\n    }\n    else\n    {\n        _2756 = _2747;\n    }\n    bool _2765;\n    if (!_2756)\n    {\n        _2765 = _2733.y > _2622.w;\n    }\n    else\n    {\n        _2765 = _2756;\n    }\n    if (_2765)\n    {\n        return 1.0f;\n    }\n    float _2771 = _2559.x;\n    float _2773;\n    if (_2771 > 0.0f)\n    {\n        _2773 = _2771;\n    }\n    else\n    {\n        _2773 = 1.5f * _2639;\n    }\n    float2 param_9 = _2733;\n    float4 param_10 = _2622;\n    float param_11 = _2715 - (_2773 * (1.0f + (0.5f * _2686)));\n    float param_12 = _2639;\n    float param_13 = 1.0f;\n    float param_14 = _2627.z * 0.25f;\n    float param_15 = (_2639 * min(_2686, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2718, _2627.z);\n    int param_17 = int(_2554.z + 0.5f);\n    float param_18 = _2554.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _4073 = fa_lm.z > 0.5f;\n    bool _4079;\n    if (_4073)\n    {\n        int param = li;\n        _4079 = fa_light_baked(param);\n    }\n    else\n    {\n        _4079 = _4073;\n    }\n    if (_4079)\n    {\n        int param_1 = li;\n        LightSample _5193 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _5193;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4103 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _5195 = _4103.color;\n    float _5197 = _4103.shadow;\n    if ((_4103.type == 0) && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4103.direction;\n        float _4117 = fa_shadow_factor(param_5, param_6);\n        _5197 = _4117;\n        _5195 *= _4117;\n    }\n    else\n    {\n        bool _4128 = _4103.type != 0;\n        bool _4134;\n        if (_4128)\n        {\n            _4134 = _4103.attenuation > 0.0f;\n        }\n        else\n        {\n            _4134 = _4128;\n        }\n        if (_4134)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _4103.direction;\n            float _4153 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _5197 = _4153;\n            _5195 *= _4153;\n        }\n    }\n    LightSample _5212 = { _4103.direction, _5195, _4103.attenuation, _5197, _4103._distance, _4103.type };\n    return _5212;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2086_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3022 = int(_2086_fa_shadow_cfg.x + 0.5f);\n    float _3032 = dot(world - _2086_fa_shadow_eye.xyz, _2086_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3037 = _3022 > 0;\n    bool _3046;\n    if (_3037)\n    {\n        int param = _3022 - 1;\n        _3046 = _3032 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3046 = _3037;\n    }\n    if (_3046)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3052 = _3022 > 1;\n        bool _3059;\n        if (_3052)\n        {\n            _3059 = _3032 > _2086_fa_shadow_split.x;\n        }\n        else\n        {\n            _3059 = _3052;\n        }\n        if (_3059)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3065 = _3022 > 2;\n        bool _3072;\n        if (_3065)\n        {\n            _3072 = _3032 > _2086_fa_shadow_split.y;\n        }\n        else\n        {\n            _3072 = _3065;\n        }\n        if (_3072)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3078 = _3022 > 3;\n        bool _3085;\n        if (_3078)\n        {\n            _3085 = _3032 > _2086_fa_shadow_split.z;\n        }\n        else\n        {\n            _3085 = _3078;\n        }\n        if (_3085)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _4904 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4904 = -_4904;\n    }\n    float3 _4539 = normalize(_429_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _4917 = { fa_world_pos, _4904, fa_world_tangent, fa_uv, fa_vertex_color, _4539, gl_FrontFacing };\n    SurfaceInput param_1 = _4917;\n    Surface _4547 = fa_standard_surface(param_1);\n    float3 _4943 = _4547.albedo;\n    float _4944 = _4547.alpha;\n    float3 _4945 = _4547.normal;\n    float _4946 = _4547.metallic;\n    float _4947 = _4547.roughness;\n    float _4948 = _4547.occlusion;\n    float3 _4949 = _4547.emission;\n    float _4950 = _4547.clearcoat;\n    float _4951 = _4547.clearcoat_roughness;\n    float3 _4952 = _4547.sheen_color;\n    float _4953 = _4547.sheen_roughness;\n    float _4954 = _4547.anisotropy;\n    float _4955 = _4547.anisotropy_rotation;\n    float _4956 = _4547.specular;\n    float _4957 = _4547.ior;\n    float3 _4958 = _4547.specular_color;\n    SurfaceInput _4925 = { fa_world_pos, _4904, fa_world_tangent, fa_uv, fa_vertex_color, _4539, gl_FrontFacing };\n    SurfaceInput param_2 = _4925;\n    Surface param_3 = _4547;\n    surface(param_2, param_3);\n    _4943 = param_3.albedo;\n    _4944 = param_3.alpha;\n    _4945 = param_3.normal;\n    _4946 = param_3.metallic;\n    _4947 = param_3.roughness;\n    _4948 = param_3.occlusion;\n    _4949 = param_3.emission;\n    _4950 = param_3.clearcoat;\n    _4951 = param_3.clearcoat_roughness;\n    _4952 = param_3.sheen_color;\n    _4953 = param_3.sheen_roughness;\n    _4954 = param_3.anisotropy;\n    _4955 = param_3.anisotropy_rotation;\n    _4956 = param_3.specular;\n    _4957 = param_3.ior;\n    _4958 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _4904;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4943 = param_6;\n    _4945 = param_7;\n    float3 result;\n    if (_429_fa_emissive.w > 0.5f)\n    {\n        result = _4943;\n    }\n    else\n    {\n        float3 _4585 = _4945;\n        float3 _4586 = normalize(_4585);\n        _4945 = _4586;\n        float3 param_8 = _4586;\n        SurfaceInput _4933 = { fa_world_pos, _4904, fa_world_tangent, fa_uv, fa_vertex_color, _4539, gl_FrontFacing };\n        SurfaceInput param_9 = _4933;\n        Surface _5024 = { _4943, _4944, _4945, _4946, _4947, _4948, _4949, _4950, _4951, _4952, _4953, _4954, _4955, _4956, _4957, _4958 };\n        Surface param_10 = _5024;\n        float3 param_11 = fa_indirect_diffuse(param_8);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _4605 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4605; ln++)\n        {\n            int param_12 = ln;\n            int _4618 = fa_cl_light(param_12);\n            bool _4621 = fa_lm.z > 0.5f;\n            bool _4627;\n            if (_4621)\n            {\n                int param_13 = _4618;\n                _4627 = fa_light_baked(param_13);\n            }\n            else\n            {\n                _4627 = _4621;\n            }\n            if (_4627)\n            {\n                continue;\n            }\n            int param_14 = _4618;\n            float3 param_15 = fa_world_pos;\n            float3 param_16 = _4904;\n            LightSample _4639 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput _4941 = { fa_world_pos, _4904, fa_world_tangent, fa_uv, fa_vertex_color, _4539, gl_FrontFacing };\n            SurfaceInput param_17 = _4941;\n            Surface _5041 = { _4943, _4944, _4945, _4946, _4947, _4948, _4949, _4950, _4951, _4952, _4953, _4954, _4955, _4956, _4957, _4958 };\n            Surface param_18 = _5041;\n            LightSample param_19 = _4639;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _4654 = result;\n    float3 _4655 = _4654 + _4949;\n    result = _4655;\n    float3 param_20 = _4655;\n    float3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _4664 = _429_fa_fog.w > 0.0f;\n    bool _4671;\n    if (!_4664)\n    {\n        _4671 = _429_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _4671 = _4664;\n    }\n    if (_4671)\n    {\n        float3 _4680 = fa_world_pos - _429_fa_camera_pos.xyz;\n        float _4686 = dot(_4680, _429_fa_fog_c.xyz);\n        bool _4690 = _429_fa_fog_c.w > 0.5f;\n        float _4691;\n        if (_4690)\n        {\n            _4691 = _4686;\n        }\n        else\n        {\n            _4691 = length(_4680);\n        }\n        float _4703 = _4691 - _429_fa_fog_b.x;\n        if (_4703 > 0.0f)\n        {\n            float _4712 = _429_fa_fog.w * _4703;\n            float tau = _4712 * _4712;\n            if (_429_fa_fog_b.y > 0.0f)\n            {\n                float _4728;\n                if (_4690)\n                {\n                    _4728 = fa_world_pos.y - (_429_fa_fog_c.y * _4686);\n                }\n                else\n                {\n                    _4728 = _429_fa_camera_pos.y;\n                }\n                float _4749 = lerp(_4728, fa_world_pos.y, clamp(_429_fa_fog_b.x / _4691, 0.0f, 1.0f));\n                float _4753 = fa_world_pos.y - _4749;\n                float _4758 = _4749 - _429_fa_fog_b.z;\n                float _4763 = fa_world_pos.y - _429_fa_fog_b.z;\n                bool _4766 = _4758 <= 0.0f;\n                bool _4767 = !_4766;\n                bool _4773;\n                if (_4767)\n                {\n                    _4773 = _429_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4773 = _4766;\n                }\n                float _4774;\n                if (_4773)\n                {\n                    _4774 = _429_fa_fog_b.y;\n                }\n                else\n                {\n                    _4774 = _429_fa_fog_b.y * exp(-min(_429_fa_fog_b.w * _4758, 80.0f));\n                }\n                bool _4801;\n                if (_4767)\n                {\n                    _4801 = _429_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4801 = _4766;\n                }\n                float _4802;\n                if (_4801)\n                {\n                    _4802 = _429_fa_fog_b.y * _4758;\n                }\n                else\n                {\n                    _4802 = (_429_fa_fog_b.y * (1.0f - exp(-min(_429_fa_fog_b.w * _4758, 80.0f)))) / _429_fa_fog_b.w;\n                }\n                bool _4827 = _4763 <= 0.0f;\n                bool _4834;\n                if (!_4827)\n                {\n                    _4834 = _429_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4834 = _4827;\n                }\n                float _4835;\n                if (_4834)\n                {\n                    _4835 = _429_fa_fog_b.y * _4763;\n                }\n                else\n                {\n                    _4835 = (_429_fa_fog_b.y * (1.0f - exp(-min(_429_fa_fog_b.w * _4763, 80.0f)))) / _429_fa_fog_b.w;\n                }\n                float _4862;\n                if (abs(_4753) < 0.001000000047497451305389404296875f)\n                {\n                    _4862 = _4774;\n                }\n                else\n                {\n                    _4862 = (_4835 - _4802) / _4753;\n                }\n                tau += (_4703 * max(_4862, 0.0f));\n            }\n            result = lerp(result, _429_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4944);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_429",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2086",
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
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _381 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _381;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _388 = _273.world_pos;\n    fa_world_pos = _388;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_388, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _3516[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _429_fa_camera_pos : packoffset(c0);\n    float4 _429_fa_ambient : packoffset(c1);\n    float4 _429_fa_base_color : packoffset(c2);\n    float4 _429_fa_emissive : packoffset(c3);\n    float4 _429_fa_model_emissive : packoffset(c4);\n    float4 _429_fa_pbr : packoffset(c5);\n    float4 _429_fa_maps : packoffset(c6);\n    float4 _429_fa_fog : packoffset(c7);\n    float4 _429_fa_fog_b : packoffset(c8);\n    float4 _429_fa_fog_c : packoffset(c9);\n    float4 _429_fa_counts : packoffset(c10);\n    float4 _429_fa_env_sky : packoffset(c11);\n    float4 _429_fa_env_horizon : packoffset(c12);\n    float4 _429_fa_time : packoffset(c13);\n    float4 _429_fa_cl_vpx : packoffset(c14);\n    float4 _429_fa_cl_vpy : packoffset(c15);\n    float4 _429_fa_cl_vpw : packoffset(c16);\n    float4 _429_fa_cl_fwd : packoffset(c17);\n    float4 _429_fa_cl_grid : packoffset(c18);\n    float4 _429_fa_cl_info : packoffset(c19);\n    float4 _429_fa_layers_a : packoffset(c20);\n    float4 _429_fa_layers_b : packoffset(c21);\n    float4 _429_fa_layers_c : packoffset(c22);\n    float4 _429_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2086_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2086_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2086_fa_shadow_info[4] : packoffset(c20);\n    float4 _2086_fa_shadow_split : packoffset(c24);\n    float4 _2086_fa_shadow_cfg : packoffset(c25);\n    float4 _2086_fa_shadow_bias : packoffset(c26);\n    float4 _2086_fa_shadow_eye : packoffset(c27);\n    float4 _2086_fa_shadow_fwd : packoffset(c28);\n    float4 _2086_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1357 = _429_fa_cl_info.x < 0.0f;\n    bool _1364;\n    if (!_1357)\n    {\n        _1364 = _429_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1364 = _1357;\n    }\n    bool _1372;\n    if (!_1364)\n    {\n        _1372 = _429_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1372 = _1364;\n    }\n    bool _1379;\n    if (!_1372)\n    {\n        _1379 = _429_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1379 = _1372;\n    }\n    bool _1386;\n    if (!_1379)\n    {\n        _1386 = _429_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1386 = _1379;\n    }\n    if (_1386)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1396 = float4(world_pos, 1.0f);\n    float _1402 = dot(_429_fa_cl_vpw, _1396);\n    if (!(_1402 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1424 = float2(dot(_429_fa_cl_vpx, _1396), dot(_429_fa_cl_vpy, _1396)) / _1402.xx;\n    int _1428 = int(_429_fa_cl_grid.x);\n    int _1432 = int(_429_fa_cl_grid.y);\n    int param = (int(_429_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_429_fa_cl_fwd.xyz, world_pos) + _429_fa_cl_fwd.w, _429_fa_cl_grid.w) / _429_fa_cl_grid.w) * _429_fa_cl_grid.z)), 0, int(_429_fa_cl_info.y) - 1) * _1432) + clamp(int(floor(((_1424.y * 0.5f) + 0.5f) * _429_fa_cl_grid.y)), 0, _1432 - 1)) * _1428)) + clamp(int(floor(((_1424.x * 0.5f) + 0.5f) * _429_fa_cl_grid.x)), 0, _1428 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1508 = fa_cluster_texel(param);\n    return int2(int(_1508.x), int(_1508.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_429_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4046 = fa_cluster_lookup(param);\n    fa_cl_slot = _4046.x;\n    fa_cl_local = _4046.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _4209 = fa_linear_to_srgb(param);\n        c = _4209;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _4217 = fa_srgb_to_linear(param_1);\n            c = _4217;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _312;\n    if (i.front_facing)\n    {\n        _312 = i.world_normal;\n    }\n    else\n    {\n        _312 = -i.world_normal;\n    }\n    float3 _336 = normalize(i.world_tangent.xyz - (_312 * dot(_312, i.world_tangent.xyz)));\n    float3 _363 = normalize(((_336 * m.x) + ((cross(_312, _336) * i.world_tangent.w) * m.y)) + (_312 * m.z));\n    float3 _366;\n    if (i.front_facing)\n    {\n        _366 = _363;\n    }\n    else\n    {\n        _366 = -_363;\n    }\n    return _366;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _429_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _4248 = fa_tex_fix(param_2, param_3);\n    float4 _5363 = base_t;\n    _5363.x = _4248.x;\n    _5363.y = _4248.y;\n    _5363.z = _4248.z;\n    base_t = _5363;\n    float4 _4262 = (_5363 * _429_fa_base_color) * i.vertex_color;\n    float3 _5215 = i.world_normal;\n    if (_429_fa_maps.z > 0.5f)\n    {\n        float param_4 = _429_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4294 = fa_tex_fix(param_6, param_7);\n        float3 _4297 = (_4294 * 2.0f) - 1.0f.xxx;\n        float2 _4302 = _4297.xy * _429_fa_maps.x;\n        float3 _5371 = _4297;\n        _5371.x = _4302.x;\n        _5371.y = _4302.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5371;\n        _5215 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _429_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4330 = fa_tex_fix(param_12, param_13);\n    float4 _5374 = mrt;\n    _5374.x = _4330.x;\n    _5374.y = _4330.y;\n    _5374.z = _4330.z;\n    mrt = _5374;\n    float4 _4358 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _429_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _4358.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4369 = fa_tex_fix(param_16, param_17);\n    float param_18 = _429_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4399 = fa_tex_fix(param_20, param_21);\n    float _5220 = _429_fa_layers_a.x;\n    float _5221 = _429_fa_layers_a.y;\n    float _5224 = _429_fa_layers_a.z;\n    float _5223 = _429_fa_layers_b.w;\n    float _5226 = _429_fa_layers_c.x;\n    if (_429_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_429_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _5220 *= _4369.y;\n            _5221 *= _4369.z;\n            _5223 *= _4358.w;\n        }\n        if (_429_fa_layers_c.z > 1.5f)\n        {\n            _5224 *= mrt.x;\n            _5226 *= mrt.w;\n        }\n    }\n    Surface _5245 = { _4262.xyz, _4262.w, _5215, clamp(_429_fa_pbr.x * _4330.z, 0.0f, 1.0f), clamp(_429_fa_pbr.y * _4330.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_429_fa_maps.y * (_4369.x - 1.0f)), _429_fa_emissive.xyz + (_429_fa_model_emissive.xyz * _4399), _5220, _5221, _429_fa_layers_b.xyz, _5223, _5224, _429_fa_layers_a.w, _5226, _429_fa_layers_c.y, _429_fa_layers_d.xyz };\n    return _5245;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1588 = rect.zw - rect.xy;\n    float2 _1592 = _1588 * atlas;\n    float2 _1596 = ddx * _1592;\n    float2 _1600 = ddy * _1592;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1588), clamp(0.5f * log2(max(max(dot(_1596, _1596), dot(_1600, _1600)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1633 = _429_fa_counts.y < 0.5f;\n    bool _1640;\n    if (!_1633)\n    {\n        _1640 = _429_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1640 = _1633;\n    }\n    if (_1640)\n    {\n        return;\n    }\n    float3 _1646 = ddx(world_pos);\n    float3 _1649 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1653 = fa_cluster_texel(param);\n    int _1657 = int(_1653.w);\n    if (_1657 < 1)\n    {\n        return;\n    }\n    int _1667 = int(_429_fa_counts.y + 0.5f);\n    int param_1 = _1667;\n    float4 _1671 = fa_light_texel(param_1);\n    float2 _1674 = _1671.yz;\n    int _1678 = int(_1671.w);\n    int param_2 = _1667 + 1;\n    float4 _1683 = fa_light_texel(param_2);\n    float _1684 = _1683.x;\n    int _1690 = int(_429_fa_counts.w + 0.5f) - 1;\n    int _1694 = int(_1653.z);\n    float3 _1959;\n    for (int k = 0; k < _1657; k++)\n    {\n        int _1707 = _1694 + k;\n        int param_3 = _1678 + (_1707 >> 2);\n        int _1724 = (_1667 + 2) + (int(fa_light_texel(param_3)[_1707 & 3]) * 7);\n        int param_4 = _1724 + 6;\n        float4 _1729 = fa_light_texel(param_4);\n        if (((int(_1729.w + 0.5f) >> _1690) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1724;\n        float4 _1744 = fa_light_texel(param_5);\n        int param_6 = _1724 + 1;\n        float4 _1749 = fa_light_texel(param_6);\n        int param_7 = _1724 + 2;\n        float4 _1754 = fa_light_texel(param_7);\n        float3 _1757 = _1744.xyz;\n        float _1762 = dot(_1757, world_pos) + _1744.w;\n        float3 _1764 = _1749.xyz;\n        float _1769 = dot(_1764, world_pos) + _1749.w;\n        float3 _1771 = _1754.xyz;\n        float _1776 = dot(_1771, world_pos) + _1754.w;\n        bool _1781 = abs(_1762) > 0.5f;\n        bool _1789;\n        if (!_1781)\n        {\n            _1789 = abs(_1769) > 0.5f;\n        }\n        else\n        {\n            _1789 = _1781;\n        }\n        bool _1797;\n        if (!_1789)\n        {\n            _1797 = abs(_1776) > 0.5f;\n        }\n        else\n        {\n            _1797 = _1789;\n        }\n        if (_1797)\n        {\n            continue;\n        }\n        float _1812 = clamp(dot(geo_normal, normalize(_1771)) * _1729.z, 0.0f, 1.0f);\n        if (_1812 <= 0.0f)\n        {\n            continue;\n        }\n        float _1832 = (clamp((0.5f - abs(_1776)) * 10.0f, 0.0f, 1.0f) * _1812) * _1729.x;\n        float2 _1840 = float2(_1762 + 0.5f, 0.5f - _1769);\n        float2 _1850 = float2(dot(_1757, _1646), dot(_1764, _1646));\n        float2 _1860 = float2(dot(_1757, _1649), dot(_1764, _1649));\n        int param_8 = _1724 + 5;\n        float4 _1865 = fa_light_texel(param_8);\n        int param_9 = _1724 + 3;\n        float4 _1870 = fa_light_texel(param_9);\n        int param_10 = _1724 + 4;\n        float4 _1875 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1865.xyz;\n        bool _1885 = _1870.z > _1870.x;\n        if (_1885)\n        {\n            float4 param_11 = _1870;\n            float2 param_12 = _1840;\n            float2 param_13 = _1674;\n            float2 param_14 = _1850;\n            float2 param_15 = _1860;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1684 > 0.5f) && (_1684 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1911 = fa_dc_to_linear(param_16);\n                float4 _5295 = tx;\n                _5295.x = _1911.x;\n                _5295.y = _1911.y;\n                _5295.z = _1911.z;\n                tx = _5295;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1832 * tex_a) * _1865.w, 0.0f, 1.0f).xxx);\n        if (_1875.z > _1875.x)\n        {\n            float4 param_17 = _1875;\n            float2 param_18 = _1840;\n            float2 param_19 = _1674;\n            float2 param_20 = _1850;\n            float2 param_21 = _1860;\n            float4 _1955 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1684 > 1.5f)\n            {\n                float3 param_22 = _1955.xyz;\n                float3 _1965 = fa_dc_to_srgb(param_22);\n                _1959 = _1965;\n            }\n            else\n            {\n                _1959 = _1955.xyz;\n            }\n            float3 _1974 = (_1959 * 2.0f) - 1.0f.xxx;\n            float2 _1979 = _1974.xy * _1729.y;\n            float3 _2001 = (normalize(_1757) * _1979.x) + (normalize(_1764) * _1979.y);\n            float3 _2004 = normalize(normal);\n            normal = normalize(lerp(_2004, normalize((_2004 * max(_1974.z, 0.0500000007450580596923828125f)) + (_2001 - (_2004 * dot(_2004, _2001)))), clamp(_1832 * (_1885 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_sky_sh_coef(int k)\n{\n    float3 v = fa_env_tex.SampleLevel(fa_env_smp, float3(1.0f, 1.0f - (float((2 * (k >> 2)) + 1) * 0.25f), 1.0f - (float((2 * (k & 3)) + 1) * 0.25f)), 5.0f).xyz;\n    if (_429_fa_env_sky.w > 1.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3199 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3199;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_429_fa_env_sky.w > 0.5f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _429_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3442 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3449 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3452 = int(_3442);\n    int _3455 = int(_3449);\n    float _3465 = _3449 - float(_3455);\n    int _3520 = (_3452 * 9) + _3455;\n    int _3540 = ((_3452 + 1) * 9) + _3455;\n    return lerp(lerp(_3516[_3520], _3516[_3520 + 1], _3465), lerp(_3516[_3540], _3516[_3540 + 1], _3465), _3442 - float(_3452));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _5074 = false;\n    float _5075 = 1.0f;\n    float _5076 = 1.0f;\n    float _5077 = 1.0f;\n    float _5078 = 0.0f;\n    float _5079 = 0.0f;\n    float _5080 = 0.0f;\n    float _5081 = 0.0f;\n    float _5083 = 1.0f;\n    bool _5084 = false;\n    float3 _5085 = 0.0f.xxx;\n    float _5086 = 1.0f;\n    float _5087 = 1.0f;\n    float _5088 = 1.0f;\n    float _5089 = 0.0f;\n    float _5090 = 0.0f;\n    float3 _5091 = float3(1.0f, 0.0f, 0.0f);\n    float3 _5092 = float3(0.0f, 0.0f, 1.0f);\n    float _5093 = 1.0f;\n    float _5094 = 1.0f;\n    float _3591 = clamp(s.specular, 0.0f, 1.0f);\n    float _3595 = clamp(s.ior, 1.0f, 3.0f);\n    bool _3600 = (_3591 != 1.0f) || (_3595 != 1.5f);\n    bool _3609;\n    if (!_3600)\n    {\n        _3609 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _3609 = _3600;\n    }\n    if (_3609)\n    {\n        float _3617 = (_3595 - 1.0f) / (_3595 + 1.0f);\n        f0 = lerp(min((_3617 * _3617).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _3591, s.albedo, metallic.xxx);\n        _5075 = lerp(_3591, 1.0f, metallic);\n        _5074 = true;\n    }\n    float _3644 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_3644 > 0.0f)\n    {\n        float _3652 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _5078 = _3644;\n        _5079 = _3652;\n        float _3659 = _3652 * _3652;\n        _5080 = _3659;\n        _5081 = _3659 * _3659;\n        float _3671 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _5083 = _3671;\n        _5076 = 1.0f - (_3644 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _3671, 0.0f, 1.0f), 5.0f))));\n        _5074 = true;\n    }\n    float3 _3690 = max(s.sheen_color, 0.0f.xxx);\n    float _3699 = max(_3690.x, max(_3690.y, _3690.z));\n    if (_3699 > 0.0f)\n    {\n        float _3707 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _5084 = true;\n        _5085 = _3690;\n        _5086 = _3707;\n        _5087 = _3707 * _3707;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _3707;\n        float _3724 = fa_sheen_albedo(param, param_1);\n        _5089 = _3724;\n        _5088 = 1.0f - min(_3699 * _3724, 1.0f);\n        _5074 = true;\n    }\n    _5077 = _5076 * _5088;\n    float _3743 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_3743 != 0.0f)\n    {\n        float3 _3758 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _3758;\n        if (dot(_3758, _3758) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _3770 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_3770.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _3770.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _3770.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _3774 = t;\n        float3 _3775 = normalize(_3774);\n        t = _3775;\n        float3 _3800 = normalize((_3775 * cos(s.anisotropy_rotation)) + ((cross(n, _3775) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _5091 = _3800;\n        _5092 = cross(n, _3800);\n        float _3810 = roughness * roughness;\n        float _3816 = lerp(_3810, 1.0f, _3743 * _3743);\n        bool _3818 = _3743 > 0.0f;\n        _5093 = _3818 ? _3816 : _3810;\n        _5094 = _3818 ? _3810 : _3816;\n        _5090 = _3743;\n        _5074 = true;\n    }\n    FaLayers _5116 = { _5074, _5075, _5076, _5077, _5078, _5079, _5080, _5081, i.world_normal, _5083, _5084, _5085, _5086, _5087, _5088, _5089, _5090, _5091, _5092, _5093, _5094 };\n    return _5116;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3374 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3377 = _3374.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3377 * _3377, exp2((-9.27999973297119140625f) * ndv)) * _3377) + _3374.y)) + _3374.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_429_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _429_fa_env_horizon.w).xyz;\n    }\n    float _3228 = rough * rough;\n    float _3258 = 0.60000002384185791015625f * _3228;\n    return lerp(lerp(_429_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_429_fa_env_horizon.xyz, _429_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3228)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3258, 0.0500000007450580596923828125f + _3258, d.y).xxx), ((_429_fa_env_sky.xyz + _429_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3228 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _3851;\n        if (L.aniso >= 0.0f)\n        {\n            _3851 = L.b;\n        }\n        else\n        {\n            _3851 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_3851, v), _3851), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3884 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _3884.x) + (L.f90.xxx * _3884.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3939 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _3939.x) + _3939.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3416 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3416.x) + _3416.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _3968 = clamp(s.metallic, 0.0f, 1.0f);\n    float _3972 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _3979 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _3968.xxx);\n    float3 f0 = _3979;\n    float3 _3983 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _3983;\n    float3 param_3 = i.view_dir;\n    float param_4 = _3968;\n    float param_5 = _3972;\n    float3 param_6 = _3979;\n    FaLayers _4000 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4000.on)\n    {\n        FaLayers param_7 = _4000;\n        float3 param_8 = _3983;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _3972;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _3983;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _3972;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_429_fa_cl_info.x) + int(_429_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_429_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _488_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _488_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _607 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _620 = (c - (ru * hx)) - p;\n        float3 _626 = ru * (2.0f * hx);\n        float _632 = max(dot(_626, _626), 9.9999999392252902907785028219223e-09f);\n        float _636 = dot(_620, _626);\n        float t = clamp((-_636) / _632, 0.0f, 1.0f);\n        if (_607)\n        {\n            float _651 = dot(r, _626);\n            float _657 = _632 - (_651 * _651);\n            if (abs(_657) > (9.9999997473787516355514526367188e-06f * _632))\n            {\n                t = clamp(((dot(r, _620) * _651) - _636) / _657, 0.0f, 1.0f);\n            }\n        }\n        return (p + _620) + (_626 * t);\n    }\n    float3 q = p;\n    float _689 = dot(r, axis);\n    bool _697;\n    if (_607)\n    {\n        _697 = abs(_689) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _697 = _607;\n    }\n    if (_697)\n    {\n        float _707 = dot(c - p, axis) / _689;\n        if (_707 > 0.0f)\n        {\n            q = p + (r * _707);\n        }\n    }\n    float3 _720 = q - c;\n    float2 xy = float2(dot(_720, ru), dot(_720, uu));\n    if (shape > 0.5f)\n    {\n        float _735 = length(xy);\n        if (_735 > hx)\n        {\n            xy *= (hx / _735);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _378 = abs(d);\n    float _380 = _378.x;\n    float _382 = _378.y;\n    bool _383 = _380 >= _382;\n    bool _391;\n    if (_383)\n    {\n        _391 = _380 >= _378.z;\n    }\n    else\n    {\n        _391 = _383;\n    }\n    int _392;\n    if (_391)\n    {\n        _392 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _407;\n        if (_382 >= _378.z)\n        {\n            _407 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _407 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _392 = _407;\n    }\n    return _392;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _527 = dot(d, right);\n    float _531 = dot(d, up);\n    float _542;\n    if (((_527 * _527) + (_531 * _531)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _542 = atan2(_531, _527) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _542 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_542 - floor(_542)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _773 = fa_light_base(param);\n    bool _777 = _429_fa_ambient.w > 4.5f;\n    int param_1 = _773;\n    float4 _781 = fa_light_texel(param_1);\n    int param_2 = _773 + 1;\n    float4 _786 = fa_light_texel(param_2);\n    float _789 = _786.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _801 = _777 && (_789 > 2.5f);\n    fa_light_is_area = _801;\n    bool _803 = _789 < 0.5f;\n    float3 l;\n    if (_803)\n    {\n        l = normalize(_781.xyz);\n        if (_777)\n        {\n            int param_3 = _773 + 6;\n            float4 _817 = fa_light_texel(param_3);\n            if (_817.z > 0.5f)\n            {\n                int param_4 = _773 + 4;\n                float4 _827 = fa_light_texel(param_4);\n                int param_5 = _773 + 5;\n                float4 _832 = fa_light_texel(param_5);\n                float2 param_6 = _817.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _827.xyz) * _827.w, (-dot(world_pos, _832.xyz)) * _832.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _862 = _781.xyz;\n        float3 _864 = _862 - world_pos;\n        float3 to_light = _864;\n        float _867 = length(_864);\n        float reach = _867;\n        bool front = true;\n        if (_801)\n        {\n            int param_8 = _773 + 7;\n            reach = max(_867 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _773 + 4;\n            float4 _891 = fa_light_texel(param_9);\n            int param_10 = _773 + 5;\n            float4 _896 = fa_light_texel(param_10);\n            int param_11 = _773 + 6;\n            float4 _901 = fa_light_texel(param_11);\n            float _902 = _901.w;\n            int param_12 = _773 + 2;\n            float3 _909 = normalize(fa_light_texel(param_12).xyz);\n            bool _911 = _902 > 1.5f;\n            bool _919;\n            if (!_911)\n            {\n                _919 = dot(_909, to_light) < 0.0f;\n            }\n            else\n            {\n                _919 = _911;\n            }\n            front = _919;\n            float3 r = 0.0f.xxx;\n            float3 _928 = _429_fa_camera_pos.xyz - world_pos;\n            bool _932 = dot(n, n) > 0.5f;\n            bool _940;\n            if (_932)\n            {\n                _940 = dot(_928, _928) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _940 = _932;\n            }\n            if (_940)\n            {\n                r = reflect(-normalize(_928), normalize(n));\n            }\n            float3 param_13 = _862;\n            float3 param_14 = _909;\n            float3 param_15 = _891.xyz;\n            float3 param_16 = _896.xyz;\n            float param_17 = _891.w;\n            float param_18 = _896.w;\n            float param_19 = _902;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _976 = length(to_light);\n        dist = _976;\n        l = to_light / max(_976, 9.9999997473787516355514526367188e-05f).xxx;\n        float _990 = reach / max(_781.w, 0.001000000047497451305389404296875f);\n        float _996 = clamp(1.0f - (_990 * _990), 0.0f, 1.0f);\n        float _998;\n        if (front)\n        {\n            _998 = _996 * _996;\n        }\n        else\n        {\n            _998 = 0.0f;\n        }\n        atten = _998;\n        bool _1009 = _789 < 2.5f;\n        if ((_789 > 1.5f) && _1009)\n        {\n            int param_22 = _773 + 2;\n            float4 _1017 = fa_light_texel(param_22);\n            float _1027 = _1017.w;\n            int param_23 = _773 + 3;\n            float4 _1032 = fa_light_texel(param_23);\n            float _1033 = _1032.x;\n            float cos_inner = _1033;\n            if (_1033 > 1.5f)\n            {\n                cos_inner = lerp(_1027, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1027, cos_inner, dot(-l, normalize(_1017.xyz)));\n        }\n        if (_777 && (_789 < 1.5f))\n        {\n            int param_24 = _773 + 6;\n            float4 _1057 = fa_light_texel(param_24);\n            if (_1057.z > 0.5f)\n            {\n                float3 _1065 = -to_light;\n                int param_25 = _773 + 4;\n                int param_26 = _773 + 5;\n                float3 _1079 = fa_light_texel(param_25).xyz;\n                float3 _1083 = fa_light_texel(param_26).xyz;\n                float3 _1092 = float3(dot(_1065, _1079), dot(_1065, _1083), dot(_1065, cross(_1079, _1083)));\n                float3 param_27 = _1092;\n                int _1096 = fa_cube_face(param_27);\n                int param_28 = _1096;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1123 = float2(dot(_1092, cross(param_29, param_30)), dot(_1092, param_30)) / max(dot(_1092, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1127 = _1096 / 3;\n                float2 param_31 = _1057.xy + (float2(float(_1096 - (_1127 * 3)), float(_1127)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1123.x), 0.5f - (0.5f * _1123.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _773 + 7;\n            float4 _1157 = fa_light_texel(param_33);\n            if (_1157.z > 0.5f)\n            {\n                int param_34 = _773 + 2;\n                int param_35 = _773 + 4;\n                int param_36 = _773 + 5;\n                float2 param_37 = _1157.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_777 && _1009)\n            {\n                int param_42 = _773 + 6;\n                float4 _1204 = fa_light_texel(param_42);\n                int param_43 = _773 + 7;\n                float4 _1209 = fa_light_texel(param_43);\n                bool _1212 = _1204.z > 0.5f;\n                bool _1219;\n                if (!_1212)\n                {\n                    _1219 = _1209.z > 0.5f;\n                }\n                else\n                {\n                    _1219 = _1212;\n                }\n                if (_1219)\n                {\n                    int param_44 = _773 + 2;\n                    float4 _1226 = fa_light_texel(param_44);\n                    float3 _1230 = normalize(_1226.xyz);\n                    int param_45 = _773 + 4;\n                    float4 _1235 = fa_light_texel(param_45);\n                    int param_46 = _773 + 5;\n                    float4 _1240 = fa_light_texel(param_46);\n                    if (_1212)\n                    {\n                        float3 _1248 = -to_light;\n                        float _1255 = _1226.w;\n                        float _1271 = 0.5f / max(dot(_1248, _1230) * (sqrt(max(1.0f - (_1255 * _1255), 0.0f)) / max(_1255, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1204.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1248, _1235.xyz) * _1271), 0.5f - (dot(_1248, _1240.xyz) * _1271));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1209.z > 0.5f)\n                    {\n                        float2 param_49 = _1209.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1230;\n                        float3 param_52 = _1235.xyz;\n                        float3 param_53 = _1240.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _5062 = _786.xyz * atten;\n    if (_777)\n    {\n        _5062 *= fa_light_tint;\n    }\n    int _1339;\n    if (_803)\n    {\n        _1339 = 0;\n    }\n    else\n    {\n        _1339 = ((_789 > 1.5f) && (_789 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _5073 = { l, _5062, atten, 1.0f, dist, _1339 };\n    return _5073;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2076;\n    if (i == 0)\n    {\n        _2076 = _2086_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2092;\n        if (i == 1)\n        {\n            _2092 = _2086_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2100;\n            if (i == 2)\n            {\n                _2100 = _2086_fa_shadow_split.z;\n            }\n            else\n            {\n                _2100 = _2086_fa_shadow_split.w;\n            }\n            _2092 = _2100;\n        }\n        _2076 = _2092;\n    }\n    return _2076;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2133 = fa_shadow_depth(param, param_1);\n    float _2137;\n    if (conv.x < 0.5f)\n    {\n        _2137 = _2133;\n    }\n    else\n    {\n        _2137 = (conv.y * conv.z) / (conv.z - (_2133 * (conv.z - conv.y)));\n    }\n    return _2137;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2064 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2064), sin(_2064)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2183 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2192;\n        if (k < 0.0f)\n        {\n            _2192 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2192 = k;\n        }\n        float _2212 = clamp((_2192 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2183;\n            float2 _2231 = fa_shadow_vogel(param_3, param_4, param_5) * _2212;\n            float2 param_6 = uv + (_2231 * _2086_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2243 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2243 < (zr - (length(_2231) * plane)))\n            {\n                sum += _2243;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2269 = sum / cnt;\n        float _2279;\n        if (k < 0.0f)\n        {\n            _2279 = (-k) / max(_2269, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2279 = k;\n        }\n        radius = clamp(((max(zr - _2269, 0.0f) * unit) * _2279) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2301 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2301; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2301;\n        float param_11 = _2183;\n        float2 _2320 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2320 * _2086_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2320) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2301);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2362 = max(_2086_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2367 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2373 = sqrt(1.0f - (_2367 * _2367));\n    float _2380 = min(_2373 / max(_2367, 0.20000000298023223876953125f), 4.0f);\n    float _2385;\n    if (_2086_fa_shadow_bias.y > 0.0f)\n    {\n        _2385 = _2086_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2385 = 1.5f * _2086_fa_shadow_info[ci].x;\n    }\n    float4 _2410 = mul(float4(world + (n * (_2385 * _2373)), 1.0f), _2086_fa_shadow_mat[ci]);\n    float _2417 = _2410.x;\n    bool _2420 = _2417 < _2086_fa_shadow_rect[ci].x;\n    bool _2429;\n    if (!_2420)\n    {\n        _2429 = _2417 > _2086_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2429 = _2420;\n    }\n    bool _2438;\n    if (!_2429)\n    {\n        _2438 = _2410.y < _2086_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2438 = _2429;\n    }\n    bool _2447;\n    if (!_2438)\n    {\n        _2447 = _2410.y > _2086_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2447 = _2438;\n    }\n    bool _2454;\n    if (!_2447)\n    {\n        _2454 = _2410.z > 1.0f;\n    }\n    else\n    {\n        _2454 = _2447;\n    }\n    if (_2454)\n    {\n        return -1.0f;\n    }\n    float _2462;\n    if (_2086_fa_shadow_bias.x > 0.0f)\n    {\n        _2462 = _2086_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2462 = 1.5f * _2086_fa_shadow_info[ci].x;\n    }\n    float2 param = _2410.xy;\n    float4 param_1 = _2086_fa_shadow_rect[ci];\n    float param_2 = _2410.z - ((_2462 * (1.0f + (0.5f * _2380))) / _2362);\n    float param_3 = _2086_fa_shadow_info[ci].x;\n    float param_4 = _2362;\n    float param_5 = _2362 * 0.25f;\n    float param_6 = ((_2086_fa_shadow_info[ci].x * min(_2380, 3.0f)) * 0.5f) / _2362;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2086_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2086_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_429_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2840 = int(_2086_fa_shadow_cfg.x + 0.5f);\n    if (_2840 < 1)\n    {\n        return 1.0f;\n    }\n    float _2855 = dot(world - _2086_fa_shadow_eye.xyz, _2086_fa_shadow_fwd.xyz);\n    int param = _2840 - 1;\n    if (_2855 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2867 = _2840 > 1;\n    bool _2874;\n    if (_2867)\n    {\n        _2874 = _2855 > _2086_fa_shadow_split.x;\n    }\n    else\n    {\n        _2874 = _2867;\n    }\n    if (_2874)\n    {\n        ci = 1;\n    }\n    bool _2878 = _2840 > 2;\n    bool _2885;\n    if (_2878)\n    {\n        _2885 = _2855 > _2086_fa_shadow_split.y;\n    }\n    else\n    {\n        _2885 = _2878;\n    }\n    if (_2885)\n    {\n        ci = 2;\n    }\n    bool _2889 = _2840 > 3;\n    bool _2896;\n    if (_2889)\n    {\n        _2896 = _2855 > _2086_fa_shadow_split.z;\n    }\n    else\n    {\n        _2896 = _2889;\n    }\n    if (_2896)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2840)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2922 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2922;\n        if (_2922 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2086_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2947;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2947 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2947 = _2086_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2966 = _2086_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2947, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2977 = clamp((_2855 - (fa_shadow_split_at(param_7) - _2966)) / _2966, 0.0f, 1.0f);\n        if (_2977 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2840)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2998 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2998;\n                if (_2998 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2977);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2520 = _429_fa_pbr.z < 0.5f;\n    bool _2527;\n    if (!_2520)\n    {\n        _2527 = _2086_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2527 = _2520;\n    }\n    if (_2527)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2086_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2540 = fa_light_texel(param);\n    float _2541 = _2540.x;\n    if (_2541 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2550 = int(_2541 + 0.5f);\n    int param_1 = _2550;\n    float4 _2554 = fa_light_texel(param_1);\n    int param_2 = _2550 + 1;\n    float4 _2559 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2562 = _2554.y;\n    if (_2562 > 0.0f)\n    {\n        float _2579 = 1.0f - smoothstep(0.75f * _2562, _2562, length(world - _2086_fa_shadow_eye.xyz));\n        fade = _2579;\n        if (_2579 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2554.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2603 = (_2550 + 2) + (face * 6);\n    int param_4 = _2603;\n    int param_5 = _2603 + 1;\n    int param_6 = _2603 + 3;\n    float4 _2617 = fa_light_texel(param_6);\n    int param_7 = _2603 + 4;\n    float4 _2622 = fa_light_texel(param_7);\n    int param_8 = _2603 + 5;\n    float4 _2627 = fa_light_texel(param_8);\n    float _2639 = _2627.x * max(dot(_2617, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2644 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2667 = clamp(dot(n, _2617.xyz), -1.0f, 1.0f);\n    float _2686 = min(sqrt(1.0f - (_2667 * _2667)) / max(abs(dot(n, world - lpos)) / max(dot(_2617, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2689 = _2559.y;\n    float _2691;\n    if (_2689 > 0.0f)\n    {\n        _2691 = _2689;\n    }\n    else\n    {\n        _2691 = 1.5f * _2639;\n    }\n    float4 _2711 = float4(world + (n * (_2691 * sqrt(1.0f - (_2644 * _2644)))), 1.0f);\n    float _2715 = dot(_2617, _2711);\n    float _2718 = _2627.y;\n    if (_2715 < _2718)\n    {\n        return 1.0f;\n    }\n    float2 _2733 = float2(dot(fa_light_texel(param_4), _2711), dot(fa_light_texel(param_5), _2711)) / _2715.xx;\n    float _2735 = _2733.x;\n    bool _2738 = _2735 < _2622.x;\n    bool _2747;\n    if (!_2738)\n    {\n        _2747 = _2735 > _2622.z;\n    }\n    else\n    {\n        _2747 = _2738;\n    }\n    bool _2756;\n    if (!_2747)\n    {\n        _2756 = _2733.y < _2622.y;\n    }\n    else\n    {\n        _2756 = _2747;\n    }\n    bool _2765;\n    if (!_2756)\n    {\n        _2765 = _2733.y > _2622.w;\n    }\n    else\n    {\n        _2765 = _2756;\n    }\n    if (_2765)\n    {\n        return 1.0f;\n    }\n    float _2771 = _2559.x;\n    float _2773;\n    if (_2771 > 0.0f)\n    {\n        _2773 = _2771;\n    }\n    else\n    {\n        _2773 = 1.5f * _2639;\n    }\n    float2 param_9 = _2733;\n    float4 param_10 = _2622;\n    float param_11 = _2715 - (_2773 * (1.0f + (0.5f * _2686)));\n    float param_12 = _2639;\n    float param_13 = 1.0f;\n    float param_14 = _2627.z * 0.25f;\n    float param_15 = (_2639 * min(_2686, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2718, _2627.z);\n    int param_17 = int(_2554.z + 0.5f);\n    float param_18 = _2554.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _4073 = fa_lm.z > 0.5f;\n    bool _4079;\n    if (_4073)\n    {\n        int param = li;\n        _4079 = fa_light_baked(param);\n    }\n    else\n    {\n        _4079 = _4073;\n    }\n    if (_4079)\n    {\n        int param_1 = li;\n        LightSample _5193 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _5193;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4103 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _5195 = _4103.color;\n    float _5197 = _4103.shadow;\n    if ((_4103.type == 0) && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4103.direction;\n        float _4117 = fa_shadow_factor(param_5, param_6);\n        _5197 = _4117;\n        _5195 *= _4117;\n    }\n    else\n    {\n        bool _4128 = _4103.type != 0;\n        bool _4134;\n        if (_4128)\n        {\n            _4134 = _4103.attenuation > 0.0f;\n        }\n        else\n        {\n            _4134 = _4128;\n        }\n        if (_4134)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _4103.direction;\n            float _4153 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _5197 = _4153;\n            _5195 *= _4153;\n        }\n    }\n    LightSample _5212 = { _4103.direction, _5195, _4103.attenuation, _5197, _4103._distance, _4103.type };\n    return _5212;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2086_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3022 = int(_2086_fa_shadow_cfg.x + 0.5f);\n    float _3032 = dot(world - _2086_fa_shadow_eye.xyz, _2086_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3037 = _3022 > 0;\n    bool _3046;\n    if (_3037)\n    {\n        int param = _3022 - 1;\n        _3046 = _3032 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3046 = _3037;\n    }\n    if (_3046)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3052 = _3022 > 1;\n        bool _3059;\n        if (_3052)\n        {\n            _3059 = _3032 > _2086_fa_shadow_split.x;\n        }\n        else\n        {\n            _3059 = _3052;\n        }\n        if (_3059)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3065 = _3022 > 2;\n        bool _3072;\n        if (_3065)\n        {\n            _3072 = _3032 > _2086_fa_shadow_split.y;\n        }\n        else\n        {\n            _3072 = _3065;\n        }\n        if (_3072)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3078 = _3022 > 3;\n        bool _3085;\n        if (_3078)\n        {\n            _3085 = _3032 > _2086_fa_shadow_split.z;\n        }\n        else\n        {\n            _3085 = _3078;\n        }\n        if (_3085)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _4904 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4904 = -_4904;\n    }\n    float3 _4539 = normalize(_429_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _4917 = { fa_world_pos, _4904, fa_world_tangent, fa_uv, fa_vertex_color, _4539, gl_FrontFacing };\n    SurfaceInput param_1 = _4917;\n    Surface _4547 = fa_standard_surface(param_1);\n    float3 _4943 = _4547.albedo;\n    float _4944 = _4547.alpha;\n    float3 _4945 = _4547.normal;\n    float _4946 = _4547.metallic;\n    float _4947 = _4547.roughness;\n    float _4948 = _4547.occlusion;\n    float3 _4949 = _4547.emission;\n    float _4950 = _4547.clearcoat;\n    float _4951 = _4547.clearcoat_roughness;\n    float3 _4952 = _4547.sheen_color;\n    float _4953 = _4547.sheen_roughness;\n    float _4954 = _4547.anisotropy;\n    float _4955 = _4547.anisotropy_rotation;\n    float _4956 = _4547.specular;\n    float _4957 = _4547.ior;\n    float3 _4958 = _4547.specular_color;\n    SurfaceInput _4925 = { fa_world_pos, _4904, fa_world_tangent, fa_uv, fa_vertex_color, _4539, gl_FrontFacing };\n    SurfaceInput param_2 = _4925;\n    Surface param_3 = _4547;\n    surface(param_2, param_3);\n    _4943 = param_3.albedo;\n    _4944 = param_3.alpha;\n    _4945 = param_3.normal;\n    _4946 = param_3.metallic;\n    _4947 = param_3.roughness;\n    _4948 = param_3.occlusion;\n    _4949 = param_3.emission;\n    _4950 = param_3.clearcoat;\n    _4951 = param_3.clearcoat_roughness;\n    _4952 = param_3.sheen_color;\n    _4953 = param_3.sheen_roughness;\n    _4954 = param_3.anisotropy;\n    _4955 = param_3.anisotropy_rotation;\n    _4956 = param_3.specular;\n    _4957 = param_3.ior;\n    _4958 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _4904;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4943 = param_6;\n    _4945 = param_7;\n    float3 result;\n    if (_429_fa_emissive.w > 0.5f)\n    {\n        result = _4943;\n    }\n    else\n    {\n        float3 _4585 = _4945;\n        float3 _4586 = normalize(_4585);\n        _4945 = _4586;\n        float3 param_8 = _4586;\n        SurfaceInput _4933 = { fa_world_pos, _4904, fa_world_tangent, fa_uv, fa_vertex_color, _4539, gl_FrontFacing };\n        SurfaceInput param_9 = _4933;\n        Surface _5024 = { _4943, _4944, _4945, _4946, _4947, _4948, _4949, _4950, _4951, _4952, _4953, _4954, _4955, _4956, _4957, _4958 };\n        Surface param_10 = _5024;\n        float3 param_11 = fa_indirect_diffuse(param_8);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _4605 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4605; ln++)\n        {\n            int param_12 = ln;\n            int _4618 = fa_cl_light(param_12);\n            bool _4621 = fa_lm.z > 0.5f;\n            bool _4627;\n            if (_4621)\n            {\n                int param_13 = _4618;\n                _4627 = fa_light_baked(param_13);\n            }\n            else\n            {\n                _4627 = _4621;\n            }\n            if (_4627)\n            {\n                continue;\n            }\n            int param_14 = _4618;\n            float3 param_15 = fa_world_pos;\n            float3 param_16 = _4904;\n            LightSample _4639 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput _4941 = { fa_world_pos, _4904, fa_world_tangent, fa_uv, fa_vertex_color, _4539, gl_FrontFacing };\n            SurfaceInput param_17 = _4941;\n            Surface _5041 = { _4943, _4944, _4945, _4946, _4947, _4948, _4949, _4950, _4951, _4952, _4953, _4954, _4955, _4956, _4957, _4958 };\n            Surface param_18 = _5041;\n            LightSample param_19 = _4639;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _4654 = result;\n    float3 _4655 = _4654 + _4949;\n    result = _4655;\n    float3 param_20 = _4655;\n    float3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _4664 = _429_fa_fog.w > 0.0f;\n    bool _4671;\n    if (!_4664)\n    {\n        _4671 = _429_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _4671 = _4664;\n    }\n    if (_4671)\n    {\n        float3 _4680 = fa_world_pos - _429_fa_camera_pos.xyz;\n        float _4686 = dot(_4680, _429_fa_fog_c.xyz);\n        bool _4690 = _429_fa_fog_c.w > 0.5f;\n        float _4691;\n        if (_4690)\n        {\n            _4691 = _4686;\n        }\n        else\n        {\n            _4691 = length(_4680);\n        }\n        float _4703 = _4691 - _429_fa_fog_b.x;\n        if (_4703 > 0.0f)\n        {\n            float _4712 = _429_fa_fog.w * _4703;\n            float tau = _4712 * _4712;\n            if (_429_fa_fog_b.y > 0.0f)\n            {\n                float _4728;\n                if (_4690)\n                {\n                    _4728 = fa_world_pos.y - (_429_fa_fog_c.y * _4686);\n                }\n                else\n                {\n                    _4728 = _429_fa_camera_pos.y;\n                }\n                float _4749 = lerp(_4728, fa_world_pos.y, clamp(_429_fa_fog_b.x / _4691, 0.0f, 1.0f));\n                float _4753 = fa_world_pos.y - _4749;\n                float _4758 = _4749 - _429_fa_fog_b.z;\n                float _4763 = fa_world_pos.y - _429_fa_fog_b.z;\n                bool _4766 = _4758 <= 0.0f;\n                bool _4767 = !_4766;\n                bool _4773;\n                if (_4767)\n                {\n                    _4773 = _429_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4773 = _4766;\n                }\n                float _4774;\n                if (_4773)\n                {\n                    _4774 = _429_fa_fog_b.y;\n                }\n                else\n                {\n                    _4774 = _429_fa_fog_b.y * exp(-min(_429_fa_fog_b.w * _4758, 80.0f));\n                }\n                bool _4801;\n                if (_4767)\n                {\n                    _4801 = _429_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4801 = _4766;\n                }\n                float _4802;\n                if (_4801)\n                {\n                    _4802 = _429_fa_fog_b.y * _4758;\n                }\n                else\n                {\n                    _4802 = (_429_fa_fog_b.y * (1.0f - exp(-min(_429_fa_fog_b.w * _4758, 80.0f)))) / _429_fa_fog_b.w;\n                }\n                bool _4827 = _4763 <= 0.0f;\n                bool _4834;\n                if (!_4827)\n                {\n                    _4834 = _429_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4834 = _4827;\n                }\n                float _4835;\n                if (_4834)\n                {\n                    _4835 = _429_fa_fog_b.y * _4763;\n                }\n                else\n                {\n                    _4835 = (_429_fa_fog_b.y * (1.0f - exp(-min(_429_fa_fog_b.w * _4763, 80.0f)))) / _429_fa_fog_b.w;\n                }\n                float _4862;\n                if (abs(_4753) < 0.001000000047497451305389404296875f)\n                {\n                    _4862 = _4774;\n                }\n                else\n                {\n                    _4862 = (_4835 - _4802) / _4753;\n                }\n                tau += (_4703 * max(_4862, 0.0f));\n            }\n            result = lerp(result, _429_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4944);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_429",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2086",
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
          }
        ]
      }
    },
    "prepass": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _292 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _292;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _299 = _160.world_pos;\n    float4 _171 = float4(_299, 1.0f);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -mul(_171, _131_fa_light_vp).z;\n    fa_pre_r0 = float3(_131_fa_light_vp[0].x, _131_fa_light_vp[1].x, _131_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131_fa_light_vp[0].y, _131_fa_light_vp[1].y, _131_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131_fa_light_vp[0].z, _131_fa_light_vp[1].z, _131_fa_light_vp[2].z);\n    gl_Position = mul(_171, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _784 = base_t;\n    _784.x = _225.x;\n    _784.y = _225.y;\n    _784.z = _225.z;\n    base_t = _784;\n    float4 _241 = (_784 * _213_fa_base_color) * i.vertex_color;\n    float3 _747 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _792 = _279;\n        _792.x = _284.x;\n        _792.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _792;\n        _747 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _795 = mrt;\n    _795.x = _313.x;\n    _795.y = _313.y;\n    _795.z = _313.z;\n    mrt = _795;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _752 = _213_fa_layers_a.x;\n    float _753 = _213_fa_layers_a.y;\n    float _756 = _213_fa_layers_a.z;\n    float _755 = _213_fa_layers_b.w;\n    float _758 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _752 *= _355.y;\n            _753 *= _355.z;\n            _755 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _756 *= mrt.x;\n            _758 *= mrt.w;\n        }\n    }\n    Surface _777 = { _241.xyz, _241.w, _747, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _752, _753, _213_fa_layers_b.xyz, _755, _756, _213_fa_layers_a.w, _758, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _777;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _658 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _658 = -_658;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _671 = { fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _671;\n    SurfaceInput _679 = { fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _679;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _413 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _413;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _420 = _273.world_pos;\n    float4 _284 = float4(_420, 1.0f);\n    fa_world_pos = _420;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -mul(_284, _136_fa_light_vp).z;\n    fa_pre_r0 = float3(_136_fa_light_vp[0].x, _136_fa_light_vp[1].x, _136_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136_fa_light_vp[0].y, _136_fa_light_vp[1].y, _136_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136_fa_light_vp[0].z, _136_fa_light_vp[1].z, _136_fa_light_vp[2].z);\n    gl_Position = mul(_284, _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _784 = base_t;\n    _784.x = _225.x;\n    _784.y = _225.y;\n    _784.z = _225.z;\n    base_t = _784;\n    float4 _241 = (_784 * _213_fa_base_color) * i.vertex_color;\n    float3 _747 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _792 = _279;\n        _792.x = _284.x;\n        _792.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _792;\n        _747 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _795 = mrt;\n    _795.x = _313.x;\n    _795.y = _313.y;\n    _795.z = _313.z;\n    mrt = _795;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _752 = _213_fa_layers_a.x;\n    float _753 = _213_fa_layers_a.y;\n    float _756 = _213_fa_layers_a.z;\n    float _755 = _213_fa_layers_b.w;\n    float _758 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _752 *= _355.y;\n            _753 *= _355.z;\n            _755 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _756 *= mrt.x;\n            _758 *= mrt.w;\n        }\n    }\n    Surface _777 = { _241.xyz, _241.w, _747, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _752, _753, _213_fa_layers_b.xyz, _755, _756, _213_fa_layers_a.w, _758, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _777;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _658 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _658 = -_658;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _671 = { fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _671;\n    SurfaceInput _679 = { fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _679;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
