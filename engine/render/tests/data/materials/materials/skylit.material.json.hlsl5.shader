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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _1544[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _414_fa_camera_pos : packoffset(c0);\n    float4 _414_fa_ambient : packoffset(c1);\n    float4 _414_fa_base_color : packoffset(c2);\n    float4 _414_fa_emissive : packoffset(c3);\n    float4 _414_fa_model_emissive : packoffset(c4);\n    float4 _414_fa_pbr : packoffset(c5);\n    float4 _414_fa_maps : packoffset(c6);\n    float4 _414_fa_fog : packoffset(c7);\n    float4 _414_fa_fog_b : packoffset(c8);\n    float4 _414_fa_fog_c : packoffset(c9);\n    float4 _414_fa_counts : packoffset(c10);\n    float4 _414_fa_env_sky : packoffset(c11);\n    float4 _414_fa_env_horizon : packoffset(c12);\n    float4 _414_fa_time : packoffset(c13);\n    float4 _414_fa_cl_vpx : packoffset(c14);\n    float4 _414_fa_cl_vpy : packoffset(c15);\n    float4 _414_fa_cl_vpw : packoffset(c16);\n    float4 _414_fa_cl_fwd : packoffset(c17);\n    float4 _414_fa_cl_grid : packoffset(c18);\n    float4 _414_fa_cl_info : packoffset(c19);\n    float4 _414_fa_layers_a : packoffset(c20);\n    float4 _414_fa_layers_b : packoffset(c21);\n    float4 _414_fa_layers_c : packoffset(c22);\n    float4 _414_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _650_fa_shadow_mat[4] : packoffset(c0);\n    float4 _650_fa_shadow_rect[4] : packoffset(c16);\n    float4 _650_fa_shadow_info[4] : packoffset(c20);\n    float4 _650_fa_shadow_split : packoffset(c24);\n    float4 _650_fa_shadow_cfg : packoffset(c25);\n    float4 _650_fa_shadow_bias : packoffset(c26);\n    float4 _650_fa_shadow_eye : packoffset(c27);\n    float4 _650_fa_shadow_fwd : packoffset(c28);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _419 = _414_fa_cl_info.x < 0.0f;\n    bool _426;\n    if (!_419)\n    {\n        _426 = _414_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _426 = _419;\n    }\n    bool _434;\n    if (!_426)\n    {\n        _434 = _414_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _434 = _426;\n    }\n    bool _441;\n    if (!_434)\n    {\n        _441 = _414_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _441 = _434;\n    }\n    bool _448;\n    if (!_441)\n    {\n        _448 = _414_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _448 = _441;\n    }\n    if (_448)\n    {\n        return int2(0, 0);\n    }\n    float4 _458 = float4(world_pos, 1.0f);\n    float _465 = dot(_414_fa_cl_vpw, _458);\n    if (!(_465 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _487 = float2(dot(_414_fa_cl_vpx, _458), dot(_414_fa_cl_vpy, _458)) / _465.xx;\n    int _491 = int(_414_fa_cl_grid.x);\n    int _495 = int(_414_fa_cl_grid.y);\n    int param = (int(_414_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_414_fa_cl_fwd.xyz, world_pos) + _414_fa_cl_fwd.w, _414_fa_cl_grid.w) / _414_fa_cl_grid.w) * _414_fa_cl_grid.z)), 0, int(_414_fa_cl_info.y) - 1) * _495) + clamp(int(floor(((_487.y * 0.5f) + 0.5f) * _414_fa_cl_grid.y)), 0, _495 - 1)) * _491)) + clamp(int(floor(((_487.x * 0.5f) + 0.5f) * _414_fa_cl_grid.x)), 0, _491 - 1);\n    float4 _566 = fa_light_texel(param);\n    return int2(int(_566.x), int(_566.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_414_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2084 = fa_cluster_lookup(param);\n    fa_cl_slot = _2084.x;\n    fa_cl_local = _2084.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _2193 = fa_linear_to_srgb(param);\n        c = _2193;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _2201 = fa_srgb_to_linear(param_1);\n            c = _2201;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _195;\n    if (i.front_facing)\n    {\n        _195 = i.world_normal;\n    }\n    else\n    {\n        _195 = -i.world_normal;\n    }\n    float3 _219 = normalize(i.world_tangent.xyz - (_195 * dot(_195, i.world_tangent.xyz)));\n    float3 _247 = normalize(((_219 * m.x) + ((cross(_195, _219) * i.world_tangent.w) * m.y)) + (_195 * m.z));\n    float3 _250;\n    if (i.front_facing)\n    {\n        _250 = _247;\n    }\n    else\n    {\n        _250 = -_247;\n    }\n    return _250;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _414_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2232 = fa_tex_fix(param_2, param_3);\n    float4 _3207 = base_t;\n    _3207.x = _2232.x;\n    _3207.y = _2232.y;\n    _3207.z = _2232.z;\n    base_t = _3207;\n    float4 _2246 = (_3207 * _414_fa_base_color) * i.vertex_color;\n    float3 _3141 = i.world_normal;\n    if (_414_fa_maps.z > 0.5f)\n    {\n        float param_4 = _414_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2278 = fa_tex_fix(param_6, param_7);\n        float3 _2282 = (_2278 * 2.0f) - 1.0f.xxx;\n        float2 _2287 = _2282.xy * _414_fa_maps.x;\n        float3 _3215 = _2282;\n        _3215.x = _2287.x;\n        _3215.y = _2287.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3215;\n        _3141 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _414_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2316 = fa_tex_fix(param_12, param_13);\n    float4 _3218 = mrt;\n    _3218.x = _2316.x;\n    _3218.y = _2316.y;\n    _3218.z = _2316.z;\n    mrt = _3218;\n    float4 _2344 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _414_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _2344.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2356 = fa_tex_fix(param_16, param_17);\n    float param_18 = _414_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2386 = fa_tex_fix(param_20, param_21);\n    float _3146 = _414_fa_layers_a.x;\n    float _3147 = _414_fa_layers_a.y;\n    float _3150 = _414_fa_layers_a.z;\n    float _3149 = _414_fa_layers_b.w;\n    float _3152 = _414_fa_layers_c.x;\n    if (_414_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_414_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _3146 *= _2356.y;\n            _3147 *= _2356.z;\n            _3149 *= _2344.w;\n        }\n        if (_414_fa_layers_c.z > 1.5f)\n        {\n            _3150 *= mrt.x;\n            _3152 *= mrt.w;\n        }\n    }\n    Surface _3171 = { _2246.xyz, _2246.w, _3141, clamp(_414_fa_pbr.x * _2316.z, 0.0f, 1.0f), clamp(_414_fa_pbr.y * _2316.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_414_fa_maps.y * (_2356.x - 1.0f)), _414_fa_emissive.xyz + (_414_fa_model_emissive.xyz * _2386), _3146, _3147, _414_fa_layers_b.xyz, _3149, _3150, _414_fa_layers_a.w, _3152, _414_fa_layers_c.y, _414_fa_layers_d.xyz };\n    return _3171;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_414_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _414_fa_ambient.xyz;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1469 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _1477 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _1480 = int(_1469);\n    int _1483 = int(_1477);\n    float _1493 = _1477 - float(_1483);\n    int _1549 = (_1480 * 9) + _1483;\n    int _1569 = ((_1480 + 1) * 9) + _1483;\n    return lerp(lerp(_1544[_1549], _1544[_1549 + 1], _1493), lerp(_1544[_1569], _1544[_1569 + 1], _1493), _1469 - float(_1480));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _3013 = false;\n    float _3014 = 1.0f;\n    float _3015 = 1.0f;\n    float _3016 = 1.0f;\n    float _3017 = 0.0f;\n    float _3018 = 0.0f;\n    float _3019 = 0.0f;\n    float _3020 = 0.0f;\n    float _3022 = 1.0f;\n    bool _3023 = false;\n    float3 _3024 = 0.0f.xxx;\n    float _3025 = 1.0f;\n    float _3026 = 1.0f;\n    float _3027 = 1.0f;\n    float _3028 = 0.0f;\n    float _3029 = 0.0f;\n    float3 _3030 = float3(1.0f, 0.0f, 0.0f);\n    float3 _3031 = float3(0.0f, 0.0f, 1.0f);\n    float _3032 = 1.0f;\n    float _3033 = 1.0f;\n    float _1624 = clamp(s.specular, 0.0f, 1.0f);\n    float _1628 = clamp(s.ior, 1.0f, 3.0f);\n    bool _1633 = (_1624 != 1.0f) || (_1628 != 1.5f);\n    bool _1643;\n    if (!_1633)\n    {\n        _1643 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _1643 = _1633;\n    }\n    if (_1643)\n    {\n        float _1651 = (_1628 - 1.0f) / (_1628 + 1.0f);\n        f0 = lerp(min((_1651 * _1651).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _1624, s.albedo, metallic.xxx);\n        _3014 = lerp(_1624, 1.0f, metallic);\n        _3013 = true;\n    }\n    float _1679 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_1679 > 0.0f)\n    {\n        float _1687 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _3017 = _1679;\n        _3018 = _1687;\n        float _1694 = _1687 * _1687;\n        _3019 = _1694;\n        _3020 = _1694 * _1694;\n        float _1706 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _3022 = _1706;\n        _3015 = 1.0f - (_1679 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _1706, 0.0f, 1.0f), 5.0f))));\n        _3013 = true;\n    }\n    float3 _1726 = max(s.sheen_color, 0.0f.xxx);\n    float _1735 = max(_1726.x, max(_1726.y, _1726.z));\n    if (_1735 > 0.0f)\n    {\n        float _1743 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _3023 = true;\n        _3024 = _1726;\n        _3025 = _1743;\n        _3026 = _1743 * _1743;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _1743;\n        float _1760 = fa_sheen_albedo(param, param_1);\n        _3028 = _1760;\n        _3027 = 1.0f - min(_1735 * _1760, 1.0f);\n        _3013 = true;\n    }\n    _3016 = _3015 * _3027;\n    float _1779 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_1779 != 0.0f)\n    {\n        float3 _1794 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _1794;\n        if (dot(_1794, _1794) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _1808 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_1808.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _1808.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _1808.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _1812 = t;\n        float3 _1813 = normalize(_1812);\n        t = _1813;\n        float3 _1838 = normalize((_1813 * cos(s.anisotropy_rotation)) + ((cross(n, _1813) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _3030 = _1838;\n        _3031 = cross(n, _1838);\n        float _1848 = roughness * roughness;\n        float _1854 = lerp(_1848, 1.0f, _1779 * _1779);\n        bool _1856 = _1779 > 0.0f;\n        _3032 = _1856 ? _1854 : _1848;\n        _3033 = _1856 ? _1848 : _1854;\n        _3029 = _1779;\n        _3013 = true;\n    }\n    FaLayers _3055 = { _3013, _3014, _3015, _3016, _3017, _3018, _3019, _3020, i.world_normal, _3022, _3023, _3024, _3025, _3026, _3027, _3028, _3029, _3030, _3031, _3032, _3033 };\n    return _3055;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _1401 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _1404 = _1401.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_1404 * _1404, exp2((-9.27999973297119140625f) * ndv)) * _1404) + _1401.y)) + _1401.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_414_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _414_fa_env_horizon.w).xyz;\n    }\n    float _1306 = rough * rough;\n    float _1336 = 0.60000002384185791015625f * _1306;\n    return lerp(lerp(_414_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_414_fa_env_horizon.xyz, _414_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _1306)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _1336, 0.0500000007450580596923828125f + _1336, d.y).xxx), ((_414_fa_env_sky.xyz + _414_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_1306 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _1889;\n        if (L.aniso >= 0.0f)\n        {\n            _1889 = L.b;\n        }\n        else\n        {\n            _1889 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_1889, v), _1889), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1922 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _1922.x) + (L.f90.xxx * _1922.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _1977 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _1977.x) + _1977.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1443 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1443.x) + _1443.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _2006 = clamp(s.metallic, 0.0f, 1.0f);\n    float _2010 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _2017 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _2006.xxx);\n    float3 f0 = _2017;\n    float3 _2021 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _2021;\n    float3 param_3 = i.view_dir;\n    float param_4 = _2006;\n    float param_5 = _2010;\n    float3 param_6 = _2017;\n    FaLayers _2038 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_2038.on)\n    {\n        FaLayers param_7 = _2038;\n        float3 param_8 = _2021;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _2010;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _2021;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _2010;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_414_fa_cl_info.x) + int(_414_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _287 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _293 = fa_light_texel(param_1);\n    float _296 = _293.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _303 = _296 < 0.5f;\n    float3 l;\n    if (_303)\n    {\n        l = normalize(_287.xyz);\n    }\n    else\n    {\n        float3 _315 = _287.xyz - world_pos;\n        float _317 = length(_315);\n        dist = _317;\n        l = _315 / max(_317, 9.9999997473787516355514526367188e-05f).xxx;\n        float _332 = _317 / max(_287.w, 0.001000000047497451305389404296875f);\n        float _338 = clamp(1.0f - (_332 * _332), 0.0f, 1.0f);\n        atten = _338 * _338;\n        if (_296 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _352 = fa_light_texel(param_2);\n            float _362 = _352.w;\n            int param_3 = (li * 4) + 3;\n            float4 _369 = fa_light_texel(param_3);\n            float _370 = _369.x;\n            float cos_inner = _370;\n            if (_370 > 1.5f)\n            {\n                cos_inner = lerp(_362, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_362, cos_inner, dot(-l, normalize(_352.xyz)));\n        }\n    }\n    int _400;\n    if (_303)\n    {\n        _400 = 0;\n    }\n    else\n    {\n        _400 = (_296 > 1.5f) ? 2 : 1;\n    }\n    LightSample _3012 = { l, _293.xyz * atten, atten, 1.0f, dist, _400 };\n    return _3012;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _640;\n    if (i == 0)\n    {\n        _640 = _650_fa_shadow_split.x;\n    }\n    else\n    {\n        float _656;\n        if (i == 1)\n        {\n            _656 = _650_fa_shadow_split.y;\n        }\n        else\n        {\n            float _664;\n            if (i == 2)\n            {\n                _664 = _650_fa_shadow_split.z;\n            }\n            else\n            {\n                _664 = _650_fa_shadow_split.w;\n            }\n            _656 = _664;\n        }\n        _640 = _656;\n    }\n    return _640;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _628 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_628), sin(_628)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _702 = max(_650_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _707 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _713 = sqrt(1.0f - (_707 * _707));\n    float _721 = min(_713 / max(_707, 0.20000000298023223876953125f), 4.0f);\n    float _726;\n    if (_650_fa_shadow_bias.y > 0.0f)\n    {\n        _726 = _650_fa_shadow_bias.y;\n    }\n    else\n    {\n        _726 = 1.5f * _650_fa_shadow_info[ci].x;\n    }\n    float4 _751 = mul(float4(world + (n * (_726 * _713)), 1.0f), _650_fa_shadow_mat[ci]);\n    float _758 = _751.x;\n    bool _761 = _758 < _650_fa_shadow_rect[ci].x;\n    bool _770;\n    if (!_761)\n    {\n        _770 = _758 > _650_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _770 = _761;\n    }\n    bool _779;\n    if (!_770)\n    {\n        _779 = _751.y < _650_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _779 = _770;\n    }\n    bool _788;\n    if (!_779)\n    {\n        _788 = _751.y > _650_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _788 = _779;\n    }\n    bool _795;\n    if (!_788)\n    {\n        _795 = _751.z > 1.0f;\n    }\n    else\n    {\n        _795 = _788;\n    }\n    if (_795)\n    {\n        return -1.0f;\n    }\n    float _804;\n    if (_650_fa_shadow_bias.x > 0.0f)\n    {\n        _804 = _650_fa_shadow_bias.x;\n    }\n    else\n    {\n        _804 = 1.5f * _650_fa_shadow_info[ci].x;\n    }\n    float _823 = _751.z - ((_804 * (1.0f + (0.5f * _721))) / _702);\n    float _832 = ((_650_fa_shadow_info[ci].x * min(_721, 3.0f)) * 0.5f) / _702;\n    int _841 = int(_650_fa_shadow_cfg.z + 0.5f);\n    if (_841 == 1)\n    {\n        float2 param = _751.xy;\n        float4 param_1 = _650_fa_shadow_rect[ci];\n        float _852 = fa_shadow_depth(param, param_1);\n        return float(_823 <= _852);\n    }\n    float _859 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _862 = _841 == 2;\n    if (_862)\n    {\n        float _876 = clamp(((_650_fa_shadow_cfg.w * _702) * 0.25f) / _650_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _859;\n            float2 _895 = fa_shadow_vogel(param_2, param_3, param_4) * _876;\n            float2 param_5 = _751.xy + (_895 * _650_fa_shadow_bias.zw);\n            float4 param_6 = _650_fa_shadow_rect[ci];\n            float _906 = fa_shadow_depth(param_5, param_6);\n            if (_906 < (_823 - (length(_895) * _832)))\n            {\n                sum += _906;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_823 - (sum / cnt), 0.0f) * _702) * _650_fa_shadow_cfg.w) / _650_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _950 = _862 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _950; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _950;\n        float param_9 = _859;\n        float2 _969 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _751.xy + (_969 * _650_fa_shadow_bias.zw);\n        float4 param_11 = _650_fa_shadow_rect[ci];\n        float _980 = fa_shadow_depth(param_10, param_11);\n        lit += float((_823 - (length(_969) * _832)) <= _980);\n    }\n    return lit / float(_950);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_414_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1010 = int(_650_fa_shadow_cfg.x + 0.5f);\n    if (_1010 < 1)\n    {\n        return 1.0f;\n    }\n    float _1026 = dot(world - _650_fa_shadow_eye.xyz, _650_fa_shadow_fwd.xyz);\n    int param = _1010 - 1;\n    if (_1026 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1038 = _1010 > 1;\n    bool _1045;\n    if (_1038)\n    {\n        _1045 = _1026 > _650_fa_shadow_split.x;\n    }\n    else\n    {\n        _1045 = _1038;\n    }\n    if (_1045)\n    {\n        ci = 1;\n    }\n    bool _1049 = _1010 > 2;\n    bool _1056;\n    if (_1049)\n    {\n        _1056 = _1026 > _650_fa_shadow_split.y;\n    }\n    else\n    {\n        _1056 = _1049;\n    }\n    if (_1056)\n    {\n        ci = 2;\n    }\n    bool _1060 = _1010 > 3;\n    bool _1067;\n    if (_1060)\n    {\n        _1067 = _1026 > _650_fa_shadow_split.z;\n    }\n    else\n    {\n        _1067 = _1060;\n    }\n    if (_1067)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1010)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1093 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1093;\n        if (_1093 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_650_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1118;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1118 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1118 = _650_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1137 = _650_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1118, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1148 = clamp((_1026 - (fa_shadow_split_at(param_7) - _1137)) / _1137, 0.0f, 1.0f);\n        if (_1148 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1010)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1169 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1169;\n                if (_1169 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1148);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _2112 = fa_light_sample(param, param_1);\n    float3 _3126 = _2112.direction;\n    float3 _3121 = _2112.color;\n    float _3123 = _2112.shadow;\n    int _3131 = _2112.type;\n    if ((_3131 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _3126;\n        float _2126 = fa_shadow_factor(param_2, param_3);\n        _3123 = _2126;\n        _3121 *= _2126;\n    }\n    LightSample _3138 = { _3126, _3121, _2112.attenuation, _3123, _2112._distance, _3131 };\n    return _3138;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_650_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1193 = int(_650_fa_shadow_cfg.x + 0.5f);\n    float _1203 = dot(world - _650_fa_shadow_eye.xyz, _650_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1208 = _1193 > 0;\n    bool _1217;\n    if (_1208)\n    {\n        int param = _1193 - 1;\n        _1217 = _1203 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1217 = _1208;\n    }\n    if (_1217)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1224 = _1193 > 1;\n        bool _1231;\n        if (_1224)\n        {\n            _1231 = _1203 > _650_fa_shadow_split.x;\n        }\n        else\n        {\n            _1231 = _1224;\n        }\n        if (_1231)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1237 = _1193 > 2;\n        bool _1244;\n        if (_1237)\n        {\n            _1244 = _1203 > _650_fa_shadow_split.y;\n        }\n        else\n        {\n            _1244 = _1237;\n        }\n        if (_1244)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1250 = _1193 > 3;\n        bool _1257;\n        if (_1250)\n        {\n            _1257 = _1203 > _650_fa_shadow_split.z;\n        }\n        else\n        {\n            _1257 = _1250;\n        }\n        if (_1257)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _2843 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2843 = -_2843;\n    }\n    float3 _2507 = normalize(_414_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _2856 = { fa_world_pos, _2843, fa_world_tangent, fa_uv, fa_vertex_color, _2507, gl_FrontFacing };\n    SurfaceInput param_1 = _2856;\n    Surface _2515 = fa_standard_surface(param_1);\n    float3 _2882 = _2515.albedo;\n    float _2883 = _2515.alpha;\n    float3 _2884 = _2515.normal;\n    float _2885 = _2515.metallic;\n    float _2886 = _2515.roughness;\n    float _2887 = _2515.occlusion;\n    float3 _2888 = _2515.emission;\n    float _2889 = _2515.clearcoat;\n    float _2890 = _2515.clearcoat_roughness;\n    float3 _2891 = _2515.sheen_color;\n    float _2892 = _2515.sheen_roughness;\n    float _2893 = _2515.anisotropy;\n    float _2894 = _2515.anisotropy_rotation;\n    float _2895 = _2515.specular;\n    float _2896 = _2515.ior;\n    float3 _2897 = _2515.specular_color;\n    SurfaceInput _2864 = { fa_world_pos, _2843, fa_world_tangent, fa_uv, fa_vertex_color, _2507, gl_FrontFacing };\n    SurfaceInput param_2 = _2864;\n    Surface param_3 = _2515;\n    surface(param_2, param_3);\n    _2882 = param_3.albedo;\n    _2883 = param_3.alpha;\n    _2884 = param_3.normal;\n    _2885 = param_3.metallic;\n    _2886 = param_3.roughness;\n    _2887 = param_3.occlusion;\n    _2888 = param_3.emission;\n    _2889 = param_3.clearcoat;\n    _2890 = param_3.clearcoat_roughness;\n    _2891 = param_3.sheen_color;\n    _2892 = param_3.sheen_roughness;\n    _2893 = param_3.anisotropy;\n    _2894 = param_3.anisotropy_rotation;\n    _2895 = param_3.specular;\n    _2896 = param_3.ior;\n    _2897 = param_3.specular_color;\n    float3 result;\n    if (_414_fa_emissive.w > 0.5f)\n    {\n        result = _2882;\n    }\n    else\n    {\n        float3 _2536 = _2884;\n        float3 _2537 = normalize(_2536);\n        _2884 = _2537;\n        float3 param_4 = _2537;\n        SurfaceInput _2872 = { fa_world_pos, _2843, fa_world_tangent, fa_uv, fa_vertex_color, _2507, gl_FrontFacing };\n        SurfaceInput param_5 = _2872;\n        Surface _2963 = { _2882, _2883, _2884, _2885, _2886, _2887, _2888, _2889, _2890, _2891, _2892, _2893, _2894, _2895, _2896, _2897 };\n        Surface param_6 = _2963;\n        float3 param_7 = fa_ambient_light(param_4);\n        float3 lit = ambient(param_5, param_6, param_7);\n        int _2556 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2556; ln++)\n        {\n            int param_8 = ln;\n            int param_9 = fa_cl_light(param_8);\n            float3 param_10 = fa_world_pos;\n            float3 param_11 = _2843;\n            SurfaceInput _2880 = { fa_world_pos, _2843, fa_world_tangent, fa_uv, fa_vertex_color, _2507, gl_FrontFacing };\n            SurfaceInput param_12 = _2880;\n            Surface _2980 = { _2882, _2883, _2884, _2885, _2886, _2887, _2888, _2889, _2890, _2891, _2892, _2893, _2894, _2895, _2896, _2897 };\n            Surface param_13 = _2980;\n            LightSample param_14 = fa_light_shadowed(param_9, param_10, param_11);\n            lit += light(param_12, param_13, param_14);\n        }\n        result = lit;\n    }\n    float3 _2593 = result;\n    float3 _2594 = _2593 + _2888;\n    result = _2594;\n    float3 param_15 = _2594;\n    float3 param_16 = fa_world_pos;\n    result = fa_shadow_debug(param_15, param_16);\n    bool _2603 = _414_fa_fog.w > 0.0f;\n    bool _2610;\n    if (!_2603)\n    {\n        _2610 = _414_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2610 = _2603;\n    }\n    if (_2610)\n    {\n        float3 _2619 = fa_world_pos - _414_fa_camera_pos.xyz;\n        float _2625 = dot(_2619, _414_fa_fog_c.xyz);\n        bool _2629 = _414_fa_fog_c.w > 0.5f;\n        float _2630;\n        if (_2629)\n        {\n            _2630 = _2625;\n        }\n        else\n        {\n            _2630 = length(_2619);\n        }\n        float _2642 = _2630 - _414_fa_fog_b.x;\n        if (_2642 > 0.0f)\n        {\n            float _2651 = _414_fa_fog.w * _2642;\n            float tau = _2651 * _2651;\n            if (_414_fa_fog_b.y > 0.0f)\n            {\n                float _2667;\n                if (_2629)\n                {\n                    _2667 = fa_world_pos.y - (_414_fa_fog_c.y * _2625);\n                }\n                else\n                {\n                    _2667 = _414_fa_camera_pos.y;\n                }\n                float _2688 = lerp(_2667, fa_world_pos.y, clamp(_414_fa_fog_b.x / _2630, 0.0f, 1.0f));\n                float _2692 = fa_world_pos.y - _2688;\n                float _2697 = _2688 - _414_fa_fog_b.z;\n                float _2702 = fa_world_pos.y - _414_fa_fog_b.z;\n                bool _2705 = _2697 <= 0.0f;\n                bool _2706 = !_2705;\n                bool _2712;\n                if (_2706)\n                {\n                    _2712 = _414_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2712 = _2705;\n                }\n                float _2713;\n                if (_2712)\n                {\n                    _2713 = _414_fa_fog_b.y;\n                }\n                else\n                {\n                    _2713 = _414_fa_fog_b.y * exp(-min(_414_fa_fog_b.w * _2697, 80.0f));\n                }\n                bool _2740;\n                if (_2706)\n                {\n                    _2740 = _414_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2740 = _2705;\n                }\n                float _2741;\n                if (_2740)\n                {\n                    _2741 = _414_fa_fog_b.y * _2697;\n                }\n                else\n                {\n                    _2741 = (_414_fa_fog_b.y * (1.0f - exp(-min(_414_fa_fog_b.w * _2697, 80.0f)))) / _414_fa_fog_b.w;\n                }\n                bool _2766 = _2702 <= 0.0f;\n                bool _2773;\n                if (!_2766)\n                {\n                    _2773 = _414_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2773 = _2766;\n                }\n                float _2774;\n                if (_2773)\n                {\n                    _2774 = _414_fa_fog_b.y * _2702;\n                }\n                else\n                {\n                    _2774 = (_414_fa_fog_b.y * (1.0f - exp(-min(_414_fa_fog_b.w * _2702, 80.0f)))) / _414_fa_fog_b.w;\n                }\n                float _2801;\n                if (abs(_2692) < 0.001000000047497451305389404296875f)\n                {\n                    _2801 = _2713;\n                }\n                else\n                {\n                    _2801 = (_2774 - _2741) / _2692;\n                }\n                tau += (_2642 * max(_2801, 0.0f));\n            }\n            result = lerp(result, _414_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _2883);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_414",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_650",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _1544[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _414_fa_camera_pos : packoffset(c0);\n    float4 _414_fa_ambient : packoffset(c1);\n    float4 _414_fa_base_color : packoffset(c2);\n    float4 _414_fa_emissive : packoffset(c3);\n    float4 _414_fa_model_emissive : packoffset(c4);\n    float4 _414_fa_pbr : packoffset(c5);\n    float4 _414_fa_maps : packoffset(c6);\n    float4 _414_fa_fog : packoffset(c7);\n    float4 _414_fa_fog_b : packoffset(c8);\n    float4 _414_fa_fog_c : packoffset(c9);\n    float4 _414_fa_counts : packoffset(c10);\n    float4 _414_fa_env_sky : packoffset(c11);\n    float4 _414_fa_env_horizon : packoffset(c12);\n    float4 _414_fa_time : packoffset(c13);\n    float4 _414_fa_cl_vpx : packoffset(c14);\n    float4 _414_fa_cl_vpy : packoffset(c15);\n    float4 _414_fa_cl_vpw : packoffset(c16);\n    float4 _414_fa_cl_fwd : packoffset(c17);\n    float4 _414_fa_cl_grid : packoffset(c18);\n    float4 _414_fa_cl_info : packoffset(c19);\n    float4 _414_fa_layers_a : packoffset(c20);\n    float4 _414_fa_layers_b : packoffset(c21);\n    float4 _414_fa_layers_c : packoffset(c22);\n    float4 _414_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _650_fa_shadow_mat[4] : packoffset(c0);\n    float4 _650_fa_shadow_rect[4] : packoffset(c16);\n    float4 _650_fa_shadow_info[4] : packoffset(c20);\n    float4 _650_fa_shadow_split : packoffset(c24);\n    float4 _650_fa_shadow_cfg : packoffset(c25);\n    float4 _650_fa_shadow_bias : packoffset(c26);\n    float4 _650_fa_shadow_eye : packoffset(c27);\n    float4 _650_fa_shadow_fwd : packoffset(c28);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _419 = _414_fa_cl_info.x < 0.0f;\n    bool _426;\n    if (!_419)\n    {\n        _426 = _414_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _426 = _419;\n    }\n    bool _434;\n    if (!_426)\n    {\n        _434 = _414_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _434 = _426;\n    }\n    bool _441;\n    if (!_434)\n    {\n        _441 = _414_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _441 = _434;\n    }\n    bool _448;\n    if (!_441)\n    {\n        _448 = _414_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _448 = _441;\n    }\n    if (_448)\n    {\n        return int2(0, 0);\n    }\n    float4 _458 = float4(world_pos, 1.0f);\n    float _465 = dot(_414_fa_cl_vpw, _458);\n    if (!(_465 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _487 = float2(dot(_414_fa_cl_vpx, _458), dot(_414_fa_cl_vpy, _458)) / _465.xx;\n    int _491 = int(_414_fa_cl_grid.x);\n    int _495 = int(_414_fa_cl_grid.y);\n    int param = (int(_414_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_414_fa_cl_fwd.xyz, world_pos) + _414_fa_cl_fwd.w, _414_fa_cl_grid.w) / _414_fa_cl_grid.w) * _414_fa_cl_grid.z)), 0, int(_414_fa_cl_info.y) - 1) * _495) + clamp(int(floor(((_487.y * 0.5f) + 0.5f) * _414_fa_cl_grid.y)), 0, _495 - 1)) * _491)) + clamp(int(floor(((_487.x * 0.5f) + 0.5f) * _414_fa_cl_grid.x)), 0, _491 - 1);\n    float4 _566 = fa_light_texel(param);\n    return int2(int(_566.x), int(_566.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_414_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2084 = fa_cluster_lookup(param);\n    fa_cl_slot = _2084.x;\n    fa_cl_local = _2084.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _2193 = fa_linear_to_srgb(param);\n        c = _2193;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _2201 = fa_srgb_to_linear(param_1);\n            c = _2201;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _195;\n    if (i.front_facing)\n    {\n        _195 = i.world_normal;\n    }\n    else\n    {\n        _195 = -i.world_normal;\n    }\n    float3 _219 = normalize(i.world_tangent.xyz - (_195 * dot(_195, i.world_tangent.xyz)));\n    float3 _247 = normalize(((_219 * m.x) + ((cross(_195, _219) * i.world_tangent.w) * m.y)) + (_195 * m.z));\n    float3 _250;\n    if (i.front_facing)\n    {\n        _250 = _247;\n    }\n    else\n    {\n        _250 = -_247;\n    }\n    return _250;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _414_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2232 = fa_tex_fix(param_2, param_3);\n    float4 _3207 = base_t;\n    _3207.x = _2232.x;\n    _3207.y = _2232.y;\n    _3207.z = _2232.z;\n    base_t = _3207;\n    float4 _2246 = (_3207 * _414_fa_base_color) * i.vertex_color;\n    float3 _3141 = i.world_normal;\n    if (_414_fa_maps.z > 0.5f)\n    {\n        float param_4 = _414_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2278 = fa_tex_fix(param_6, param_7);\n        float3 _2282 = (_2278 * 2.0f) - 1.0f.xxx;\n        float2 _2287 = _2282.xy * _414_fa_maps.x;\n        float3 _3215 = _2282;\n        _3215.x = _2287.x;\n        _3215.y = _2287.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3215;\n        _3141 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _414_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2316 = fa_tex_fix(param_12, param_13);\n    float4 _3218 = mrt;\n    _3218.x = _2316.x;\n    _3218.y = _2316.y;\n    _3218.z = _2316.z;\n    mrt = _3218;\n    float4 _2344 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _414_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _2344.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2356 = fa_tex_fix(param_16, param_17);\n    float param_18 = _414_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2386 = fa_tex_fix(param_20, param_21);\n    float _3146 = _414_fa_layers_a.x;\n    float _3147 = _414_fa_layers_a.y;\n    float _3150 = _414_fa_layers_a.z;\n    float _3149 = _414_fa_layers_b.w;\n    float _3152 = _414_fa_layers_c.x;\n    if (_414_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_414_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _3146 *= _2356.y;\n            _3147 *= _2356.z;\n            _3149 *= _2344.w;\n        }\n        if (_414_fa_layers_c.z > 1.5f)\n        {\n            _3150 *= mrt.x;\n            _3152 *= mrt.w;\n        }\n    }\n    Surface _3171 = { _2246.xyz, _2246.w, _3141, clamp(_414_fa_pbr.x * _2316.z, 0.0f, 1.0f), clamp(_414_fa_pbr.y * _2316.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_414_fa_maps.y * (_2356.x - 1.0f)), _414_fa_emissive.xyz + (_414_fa_model_emissive.xyz * _2386), _3146, _3147, _414_fa_layers_b.xyz, _3149, _3150, _414_fa_layers_a.w, _3152, _414_fa_layers_c.y, _414_fa_layers_d.xyz };\n    return _3171;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_414_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _414_fa_ambient.xyz;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1469 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _1477 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _1480 = int(_1469);\n    int _1483 = int(_1477);\n    float _1493 = _1477 - float(_1483);\n    int _1549 = (_1480 * 9) + _1483;\n    int _1569 = ((_1480 + 1) * 9) + _1483;\n    return lerp(lerp(_1544[_1549], _1544[_1549 + 1], _1493), lerp(_1544[_1569], _1544[_1569 + 1], _1493), _1469 - float(_1480));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _3013 = false;\n    float _3014 = 1.0f;\n    float _3015 = 1.0f;\n    float _3016 = 1.0f;\n    float _3017 = 0.0f;\n    float _3018 = 0.0f;\n    float _3019 = 0.0f;\n    float _3020 = 0.0f;\n    float _3022 = 1.0f;\n    bool _3023 = false;\n    float3 _3024 = 0.0f.xxx;\n    float _3025 = 1.0f;\n    float _3026 = 1.0f;\n    float _3027 = 1.0f;\n    float _3028 = 0.0f;\n    float _3029 = 0.0f;\n    float3 _3030 = float3(1.0f, 0.0f, 0.0f);\n    float3 _3031 = float3(0.0f, 0.0f, 1.0f);\n    float _3032 = 1.0f;\n    float _3033 = 1.0f;\n    float _1624 = clamp(s.specular, 0.0f, 1.0f);\n    float _1628 = clamp(s.ior, 1.0f, 3.0f);\n    bool _1633 = (_1624 != 1.0f) || (_1628 != 1.5f);\n    bool _1643;\n    if (!_1633)\n    {\n        _1643 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _1643 = _1633;\n    }\n    if (_1643)\n    {\n        float _1651 = (_1628 - 1.0f) / (_1628 + 1.0f);\n        f0 = lerp(min((_1651 * _1651).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _1624, s.albedo, metallic.xxx);\n        _3014 = lerp(_1624, 1.0f, metallic);\n        _3013 = true;\n    }\n    float _1679 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_1679 > 0.0f)\n    {\n        float _1687 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _3017 = _1679;\n        _3018 = _1687;\n        float _1694 = _1687 * _1687;\n        _3019 = _1694;\n        _3020 = _1694 * _1694;\n        float _1706 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _3022 = _1706;\n        _3015 = 1.0f - (_1679 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _1706, 0.0f, 1.0f), 5.0f))));\n        _3013 = true;\n    }\n    float3 _1726 = max(s.sheen_color, 0.0f.xxx);\n    float _1735 = max(_1726.x, max(_1726.y, _1726.z));\n    if (_1735 > 0.0f)\n    {\n        float _1743 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _3023 = true;\n        _3024 = _1726;\n        _3025 = _1743;\n        _3026 = _1743 * _1743;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _1743;\n        float _1760 = fa_sheen_albedo(param, param_1);\n        _3028 = _1760;\n        _3027 = 1.0f - min(_1735 * _1760, 1.0f);\n        _3013 = true;\n    }\n    _3016 = _3015 * _3027;\n    float _1779 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_1779 != 0.0f)\n    {\n        float3 _1794 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _1794;\n        if (dot(_1794, _1794) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _1808 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_1808.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _1808.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _1808.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _1812 = t;\n        float3 _1813 = normalize(_1812);\n        t = _1813;\n        float3 _1838 = normalize((_1813 * cos(s.anisotropy_rotation)) + ((cross(n, _1813) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _3030 = _1838;\n        _3031 = cross(n, _1838);\n        float _1848 = roughness * roughness;\n        float _1854 = lerp(_1848, 1.0f, _1779 * _1779);\n        bool _1856 = _1779 > 0.0f;\n        _3032 = _1856 ? _1854 : _1848;\n        _3033 = _1856 ? _1848 : _1854;\n        _3029 = _1779;\n        _3013 = true;\n    }\n    FaLayers _3055 = { _3013, _3014, _3015, _3016, _3017, _3018, _3019, _3020, i.world_normal, _3022, _3023, _3024, _3025, _3026, _3027, _3028, _3029, _3030, _3031, _3032, _3033 };\n    return _3055;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _1401 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _1404 = _1401.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_1404 * _1404, exp2((-9.27999973297119140625f) * ndv)) * _1404) + _1401.y)) + _1401.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_414_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _414_fa_env_horizon.w).xyz;\n    }\n    float _1306 = rough * rough;\n    float _1336 = 0.60000002384185791015625f * _1306;\n    return lerp(lerp(_414_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_414_fa_env_horizon.xyz, _414_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _1306)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _1336, 0.0500000007450580596923828125f + _1336, d.y).xxx), ((_414_fa_env_sky.xyz + _414_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_1306 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _1889;\n        if (L.aniso >= 0.0f)\n        {\n            _1889 = L.b;\n        }\n        else\n        {\n            _1889 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_1889, v), _1889), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1922 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _1922.x) + (L.f90.xxx * _1922.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _1977 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _1977.x) + _1977.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1443 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1443.x) + _1443.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _2006 = clamp(s.metallic, 0.0f, 1.0f);\n    float _2010 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _2017 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _2006.xxx);\n    float3 f0 = _2017;\n    float3 _2021 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _2021;\n    float3 param_3 = i.view_dir;\n    float param_4 = _2006;\n    float param_5 = _2010;\n    float3 param_6 = _2017;\n    FaLayers _2038 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_2038.on)\n    {\n        FaLayers param_7 = _2038;\n        float3 param_8 = _2021;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _2010;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _2021;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _2010;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_414_fa_cl_info.x) + int(_414_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _287 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _293 = fa_light_texel(param_1);\n    float _296 = _293.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _303 = _296 < 0.5f;\n    float3 l;\n    if (_303)\n    {\n        l = normalize(_287.xyz);\n    }\n    else\n    {\n        float3 _315 = _287.xyz - world_pos;\n        float _317 = length(_315);\n        dist = _317;\n        l = _315 / max(_317, 9.9999997473787516355514526367188e-05f).xxx;\n        float _332 = _317 / max(_287.w, 0.001000000047497451305389404296875f);\n        float _338 = clamp(1.0f - (_332 * _332), 0.0f, 1.0f);\n        atten = _338 * _338;\n        if (_296 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _352 = fa_light_texel(param_2);\n            float _362 = _352.w;\n            int param_3 = (li * 4) + 3;\n            float4 _369 = fa_light_texel(param_3);\n            float _370 = _369.x;\n            float cos_inner = _370;\n            if (_370 > 1.5f)\n            {\n                cos_inner = lerp(_362, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_362, cos_inner, dot(-l, normalize(_352.xyz)));\n        }\n    }\n    int _400;\n    if (_303)\n    {\n        _400 = 0;\n    }\n    else\n    {\n        _400 = (_296 > 1.5f) ? 2 : 1;\n    }\n    LightSample _3012 = { l, _293.xyz * atten, atten, 1.0f, dist, _400 };\n    return _3012;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _640;\n    if (i == 0)\n    {\n        _640 = _650_fa_shadow_split.x;\n    }\n    else\n    {\n        float _656;\n        if (i == 1)\n        {\n            _656 = _650_fa_shadow_split.y;\n        }\n        else\n        {\n            float _664;\n            if (i == 2)\n            {\n                _664 = _650_fa_shadow_split.z;\n            }\n            else\n            {\n                _664 = _650_fa_shadow_split.w;\n            }\n            _656 = _664;\n        }\n        _640 = _656;\n    }\n    return _640;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _628 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_628), sin(_628)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _702 = max(_650_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _707 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _713 = sqrt(1.0f - (_707 * _707));\n    float _721 = min(_713 / max(_707, 0.20000000298023223876953125f), 4.0f);\n    float _726;\n    if (_650_fa_shadow_bias.y > 0.0f)\n    {\n        _726 = _650_fa_shadow_bias.y;\n    }\n    else\n    {\n        _726 = 1.5f * _650_fa_shadow_info[ci].x;\n    }\n    float4 _751 = mul(float4(world + (n * (_726 * _713)), 1.0f), _650_fa_shadow_mat[ci]);\n    float _758 = _751.x;\n    bool _761 = _758 < _650_fa_shadow_rect[ci].x;\n    bool _770;\n    if (!_761)\n    {\n        _770 = _758 > _650_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _770 = _761;\n    }\n    bool _779;\n    if (!_770)\n    {\n        _779 = _751.y < _650_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _779 = _770;\n    }\n    bool _788;\n    if (!_779)\n    {\n        _788 = _751.y > _650_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _788 = _779;\n    }\n    bool _795;\n    if (!_788)\n    {\n        _795 = _751.z > 1.0f;\n    }\n    else\n    {\n        _795 = _788;\n    }\n    if (_795)\n    {\n        return -1.0f;\n    }\n    float _804;\n    if (_650_fa_shadow_bias.x > 0.0f)\n    {\n        _804 = _650_fa_shadow_bias.x;\n    }\n    else\n    {\n        _804 = 1.5f * _650_fa_shadow_info[ci].x;\n    }\n    float _823 = _751.z - ((_804 * (1.0f + (0.5f * _721))) / _702);\n    float _832 = ((_650_fa_shadow_info[ci].x * min(_721, 3.0f)) * 0.5f) / _702;\n    int _841 = int(_650_fa_shadow_cfg.z + 0.5f);\n    if (_841 == 1)\n    {\n        float2 param = _751.xy;\n        float4 param_1 = _650_fa_shadow_rect[ci];\n        float _852 = fa_shadow_depth(param, param_1);\n        return float(_823 <= _852);\n    }\n    float _859 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _862 = _841 == 2;\n    if (_862)\n    {\n        float _876 = clamp(((_650_fa_shadow_cfg.w * _702) * 0.25f) / _650_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _859;\n            float2 _895 = fa_shadow_vogel(param_2, param_3, param_4) * _876;\n            float2 param_5 = _751.xy + (_895 * _650_fa_shadow_bias.zw);\n            float4 param_6 = _650_fa_shadow_rect[ci];\n            float _906 = fa_shadow_depth(param_5, param_6);\n            if (_906 < (_823 - (length(_895) * _832)))\n            {\n                sum += _906;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_823 - (sum / cnt), 0.0f) * _702) * _650_fa_shadow_cfg.w) / _650_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _950 = _862 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _950; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _950;\n        float param_9 = _859;\n        float2 _969 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _751.xy + (_969 * _650_fa_shadow_bias.zw);\n        float4 param_11 = _650_fa_shadow_rect[ci];\n        float _980 = fa_shadow_depth(param_10, param_11);\n        lit += float((_823 - (length(_969) * _832)) <= _980);\n    }\n    return lit / float(_950);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_414_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1010 = int(_650_fa_shadow_cfg.x + 0.5f);\n    if (_1010 < 1)\n    {\n        return 1.0f;\n    }\n    float _1026 = dot(world - _650_fa_shadow_eye.xyz, _650_fa_shadow_fwd.xyz);\n    int param = _1010 - 1;\n    if (_1026 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1038 = _1010 > 1;\n    bool _1045;\n    if (_1038)\n    {\n        _1045 = _1026 > _650_fa_shadow_split.x;\n    }\n    else\n    {\n        _1045 = _1038;\n    }\n    if (_1045)\n    {\n        ci = 1;\n    }\n    bool _1049 = _1010 > 2;\n    bool _1056;\n    if (_1049)\n    {\n        _1056 = _1026 > _650_fa_shadow_split.y;\n    }\n    else\n    {\n        _1056 = _1049;\n    }\n    if (_1056)\n    {\n        ci = 2;\n    }\n    bool _1060 = _1010 > 3;\n    bool _1067;\n    if (_1060)\n    {\n        _1067 = _1026 > _650_fa_shadow_split.z;\n    }\n    else\n    {\n        _1067 = _1060;\n    }\n    if (_1067)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1010)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1093 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1093;\n        if (_1093 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_650_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1118;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1118 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1118 = _650_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1137 = _650_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1118, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1148 = clamp((_1026 - (fa_shadow_split_at(param_7) - _1137)) / _1137, 0.0f, 1.0f);\n        if (_1148 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1010)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1169 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1169;\n                if (_1169 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1148);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _2112 = fa_light_sample(param, param_1);\n    float3 _3126 = _2112.direction;\n    float3 _3121 = _2112.color;\n    float _3123 = _2112.shadow;\n    int _3131 = _2112.type;\n    if ((_3131 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _3126;\n        float _2126 = fa_shadow_factor(param_2, param_3);\n        _3123 = _2126;\n        _3121 *= _2126;\n    }\n    LightSample _3138 = { _3126, _3121, _2112.attenuation, _3123, _2112._distance, _3131 };\n    return _3138;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_650_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1193 = int(_650_fa_shadow_cfg.x + 0.5f);\n    float _1203 = dot(world - _650_fa_shadow_eye.xyz, _650_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1208 = _1193 > 0;\n    bool _1217;\n    if (_1208)\n    {\n        int param = _1193 - 1;\n        _1217 = _1203 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1217 = _1208;\n    }\n    if (_1217)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1224 = _1193 > 1;\n        bool _1231;\n        if (_1224)\n        {\n            _1231 = _1203 > _650_fa_shadow_split.x;\n        }\n        else\n        {\n            _1231 = _1224;\n        }\n        if (_1231)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1237 = _1193 > 2;\n        bool _1244;\n        if (_1237)\n        {\n            _1244 = _1203 > _650_fa_shadow_split.y;\n        }\n        else\n        {\n            _1244 = _1237;\n        }\n        if (_1244)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1250 = _1193 > 3;\n        bool _1257;\n        if (_1250)\n        {\n            _1257 = _1203 > _650_fa_shadow_split.z;\n        }\n        else\n        {\n            _1257 = _1250;\n        }\n        if (_1257)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _2843 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2843 = -_2843;\n    }\n    float3 _2507 = normalize(_414_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _2856 = { fa_world_pos, _2843, fa_world_tangent, fa_uv, fa_vertex_color, _2507, gl_FrontFacing };\n    SurfaceInput param_1 = _2856;\n    Surface _2515 = fa_standard_surface(param_1);\n    float3 _2882 = _2515.albedo;\n    float _2883 = _2515.alpha;\n    float3 _2884 = _2515.normal;\n    float _2885 = _2515.metallic;\n    float _2886 = _2515.roughness;\n    float _2887 = _2515.occlusion;\n    float3 _2888 = _2515.emission;\n    float _2889 = _2515.clearcoat;\n    float _2890 = _2515.clearcoat_roughness;\n    float3 _2891 = _2515.sheen_color;\n    float _2892 = _2515.sheen_roughness;\n    float _2893 = _2515.anisotropy;\n    float _2894 = _2515.anisotropy_rotation;\n    float _2895 = _2515.specular;\n    float _2896 = _2515.ior;\n    float3 _2897 = _2515.specular_color;\n    SurfaceInput _2864 = { fa_world_pos, _2843, fa_world_tangent, fa_uv, fa_vertex_color, _2507, gl_FrontFacing };\n    SurfaceInput param_2 = _2864;\n    Surface param_3 = _2515;\n    surface(param_2, param_3);\n    _2882 = param_3.albedo;\n    _2883 = param_3.alpha;\n    _2884 = param_3.normal;\n    _2885 = param_3.metallic;\n    _2886 = param_3.roughness;\n    _2887 = param_3.occlusion;\n    _2888 = param_3.emission;\n    _2889 = param_3.clearcoat;\n    _2890 = param_3.clearcoat_roughness;\n    _2891 = param_3.sheen_color;\n    _2892 = param_3.sheen_roughness;\n    _2893 = param_3.anisotropy;\n    _2894 = param_3.anisotropy_rotation;\n    _2895 = param_3.specular;\n    _2896 = param_3.ior;\n    _2897 = param_3.specular_color;\n    float3 result;\n    if (_414_fa_emissive.w > 0.5f)\n    {\n        result = _2882;\n    }\n    else\n    {\n        float3 _2536 = _2884;\n        float3 _2537 = normalize(_2536);\n        _2884 = _2537;\n        float3 param_4 = _2537;\n        SurfaceInput _2872 = { fa_world_pos, _2843, fa_world_tangent, fa_uv, fa_vertex_color, _2507, gl_FrontFacing };\n        SurfaceInput param_5 = _2872;\n        Surface _2963 = { _2882, _2883, _2884, _2885, _2886, _2887, _2888, _2889, _2890, _2891, _2892, _2893, _2894, _2895, _2896, _2897 };\n        Surface param_6 = _2963;\n        float3 param_7 = fa_ambient_light(param_4);\n        float3 lit = ambient(param_5, param_6, param_7);\n        int _2556 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2556; ln++)\n        {\n            int param_8 = ln;\n            int param_9 = fa_cl_light(param_8);\n            float3 param_10 = fa_world_pos;\n            float3 param_11 = _2843;\n            SurfaceInput _2880 = { fa_world_pos, _2843, fa_world_tangent, fa_uv, fa_vertex_color, _2507, gl_FrontFacing };\n            SurfaceInput param_12 = _2880;\n            Surface _2980 = { _2882, _2883, _2884, _2885, _2886, _2887, _2888, _2889, _2890, _2891, _2892, _2893, _2894, _2895, _2896, _2897 };\n            Surface param_13 = _2980;\n            LightSample param_14 = fa_light_shadowed(param_9, param_10, param_11);\n            lit += light(param_12, param_13, param_14);\n        }\n        result = lit;\n    }\n    float3 _2593 = result;\n    float3 _2594 = _2593 + _2888;\n    result = _2594;\n    float3 param_15 = _2594;\n    float3 param_16 = fa_world_pos;\n    result = fa_shadow_debug(param_15, param_16);\n    bool _2603 = _414_fa_fog.w > 0.0f;\n    bool _2610;\n    if (!_2603)\n    {\n        _2610 = _414_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2610 = _2603;\n    }\n    if (_2610)\n    {\n        float3 _2619 = fa_world_pos - _414_fa_camera_pos.xyz;\n        float _2625 = dot(_2619, _414_fa_fog_c.xyz);\n        bool _2629 = _414_fa_fog_c.w > 0.5f;\n        float _2630;\n        if (_2629)\n        {\n            _2630 = _2625;\n        }\n        else\n        {\n            _2630 = length(_2619);\n        }\n        float _2642 = _2630 - _414_fa_fog_b.x;\n        if (_2642 > 0.0f)\n        {\n            float _2651 = _414_fa_fog.w * _2642;\n            float tau = _2651 * _2651;\n            if (_414_fa_fog_b.y > 0.0f)\n            {\n                float _2667;\n                if (_2629)\n                {\n                    _2667 = fa_world_pos.y - (_414_fa_fog_c.y * _2625);\n                }\n                else\n                {\n                    _2667 = _414_fa_camera_pos.y;\n                }\n                float _2688 = lerp(_2667, fa_world_pos.y, clamp(_414_fa_fog_b.x / _2630, 0.0f, 1.0f));\n                float _2692 = fa_world_pos.y - _2688;\n                float _2697 = _2688 - _414_fa_fog_b.z;\n                float _2702 = fa_world_pos.y - _414_fa_fog_b.z;\n                bool _2705 = _2697 <= 0.0f;\n                bool _2706 = !_2705;\n                bool _2712;\n                if (_2706)\n                {\n                    _2712 = _414_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2712 = _2705;\n                }\n                float _2713;\n                if (_2712)\n                {\n                    _2713 = _414_fa_fog_b.y;\n                }\n                else\n                {\n                    _2713 = _414_fa_fog_b.y * exp(-min(_414_fa_fog_b.w * _2697, 80.0f));\n                }\n                bool _2740;\n                if (_2706)\n                {\n                    _2740 = _414_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2740 = _2705;\n                }\n                float _2741;\n                if (_2740)\n                {\n                    _2741 = _414_fa_fog_b.y * _2697;\n                }\n                else\n                {\n                    _2741 = (_414_fa_fog_b.y * (1.0f - exp(-min(_414_fa_fog_b.w * _2697, 80.0f)))) / _414_fa_fog_b.w;\n                }\n                bool _2766 = _2702 <= 0.0f;\n                bool _2773;\n                if (!_2766)\n                {\n                    _2773 = _414_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2773 = _2766;\n                }\n                float _2774;\n                if (_2773)\n                {\n                    _2774 = _414_fa_fog_b.y * _2702;\n                }\n                else\n                {\n                    _2774 = (_414_fa_fog_b.y * (1.0f - exp(-min(_414_fa_fog_b.w * _2702, 80.0f)))) / _414_fa_fog_b.w;\n                }\n                float _2801;\n                if (abs(_2692) < 0.001000000047497451305389404296875f)\n                {\n                    _2801 = _2713;\n                }\n                else\n                {\n                    _2801 = (_2774 - _2741) / _2692;\n                }\n                tau += (_2642 * max(_2801, 0.0f));\n            }\n            result = lerp(result, _414_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _2883);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_414",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_650",
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
