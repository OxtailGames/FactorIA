{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "b9137a7fd5249b4222bedebb6ca5e740fb7c4a348474dd42da5706fae9a2d4c0",
  "slang": "hlsl5",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _261 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _261;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _268 = _160.world_pos;\n    fa_world_pos = _268;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_268, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _1530[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\nstatic const LightSample _3307 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, 0 };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _418_fa_camera_pos : packoffset(c0);\n    float4 _418_fa_ambient : packoffset(c1);\n    float4 _418_fa_base_color : packoffset(c2);\n    float4 _418_fa_emissive : packoffset(c3);\n    float4 _418_fa_model_emissive : packoffset(c4);\n    float4 _418_fa_pbr : packoffset(c5);\n    float4 _418_fa_maps : packoffset(c6);\n    float4 _418_fa_fog : packoffset(c7);\n    float4 _418_fa_fog_b : packoffset(c8);\n    float4 _418_fa_fog_c : packoffset(c9);\n    float4 _418_fa_counts : packoffset(c10);\n    float4 _418_fa_env_sky : packoffset(c11);\n    float4 _418_fa_env_horizon : packoffset(c12);\n    float4 _418_fa_time : packoffset(c13);\n    float4 _418_fa_cl_vpx : packoffset(c14);\n    float4 _418_fa_cl_vpy : packoffset(c15);\n    float4 _418_fa_cl_vpw : packoffset(c16);\n    float4 _418_fa_cl_fwd : packoffset(c17);\n    float4 _418_fa_cl_grid : packoffset(c18);\n    float4 _418_fa_cl_info : packoffset(c19);\n    float4 _418_fa_layers_a : packoffset(c20);\n    float4 _418_fa_layers_b : packoffset(c21);\n    float4 _418_fa_layers_c : packoffset(c22);\n    float4 _418_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _654_fa_shadow_mat[4] : packoffset(c0);\n    float4 _654_fa_shadow_rect[4] : packoffset(c16);\n    float4 _654_fa_shadow_info[4] : packoffset(c20);\n    float4 _654_fa_shadow_split : packoffset(c24);\n    float4 _654_fa_shadow_cfg : packoffset(c25);\n    float4 _654_fa_shadow_bias : packoffset(c26);\n    float4 _654_fa_shadow_eye : packoffset(c27);\n    float4 _654_fa_shadow_fwd : packoffset(c28);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _2255_dark : packoffset(c0);\n    float _2255_fa_pad0 : packoffset(c0.y);\n    float _2255_fa_pad1 : packoffset(c0.z);\n    float _2255_fa_pad2 : packoffset(c0.w);\n    float _2255_skyAmount : packoffset(c1);\n    float _2255_fa_pad3 : packoffset(c1.y);\n    float _2255_fa_pad4 : packoffset(c1.z);\n    float _2255_fa_pad5 : packoffset(c1.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _423 = _418_fa_cl_info.x < 0.0f;\n    bool _430;\n    if (!_423)\n    {\n        _430 = _418_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _430 = _423;\n    }\n    bool _438;\n    if (!_430)\n    {\n        _438 = _418_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _438 = _430;\n    }\n    bool _445;\n    if (!_438)\n    {\n        _445 = _418_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _445 = _438;\n    }\n    bool _452;\n    if (!_445)\n    {\n        _452 = _418_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _452 = _445;\n    }\n    if (_452)\n    {\n        return int2(0, 0);\n    }\n    float4 _462 = float4(world_pos, 1.0f);\n    float _469 = dot(_418_fa_cl_vpw, _462);\n    if (!(_469 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _491 = float2(dot(_418_fa_cl_vpx, _462), dot(_418_fa_cl_vpy, _462)) / _469.xx;\n    int _495 = int(_418_fa_cl_grid.x);\n    int _499 = int(_418_fa_cl_grid.y);\n    int param = (int(_418_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_418_fa_cl_fwd.xyz, world_pos) + _418_fa_cl_fwd.w, _418_fa_cl_grid.w) / _418_fa_cl_grid.w) * _418_fa_cl_grid.z)), 0, int(_418_fa_cl_info.y) - 1) * _499) + clamp(int(floor(((_491.y * 0.5f) + 0.5f) * _418_fa_cl_grid.y)), 0, _499 - 1)) * _495)) + clamp(int(floor(((_491.x * 0.5f) + 0.5f) * _418_fa_cl_grid.x)), 0, _495 - 1);\n    float4 _570 = fa_light_texel(param);\n    return int2(int(_570.x), int(_570.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_418_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2080 = fa_cluster_lookup(param);\n    fa_cl_slot = _2080.x;\n    fa_cl_local = _2080.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _2327 = fa_linear_to_srgb(param);\n        c = _2327;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _2335 = fa_srgb_to_linear(param_1);\n            c = _2335;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _198;\n    if (i.front_facing)\n    {\n        _198 = i.world_normal;\n    }\n    else\n    {\n        _198 = -i.world_normal;\n    }\n    float3 _222 = normalize(i.world_tangent.xyz - (_198 * dot(_198, i.world_tangent.xyz)));\n    float3 _250 = normalize(((_222 * m.x) + ((cross(_198, _222) * i.world_tangent.w) * m.y)) + (_198 * m.z));\n    float3 _253;\n    if (i.front_facing)\n    {\n        _253 = _250;\n    }\n    else\n    {\n        _253 = -_250;\n    }\n    return _253;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _418_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2366 = fa_tex_fix(param_2, param_3);\n    float4 _3279 = base_t;\n    _3279.x = _2366.x;\n    _3279.y = _2366.y;\n    _3279.z = _2366.z;\n    base_t = _3279;\n    float4 _2380 = (_3279 * _418_fa_base_color) * i.vertex_color;\n    float3 _3213 = i.world_normal;\n    if (_418_fa_maps.z > 0.5f)\n    {\n        float param_4 = _418_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2412 = fa_tex_fix(param_6, param_7);\n        float3 _2416 = (_2412 * 2.0f) - 1.0f.xxx;\n        float2 _2421 = _2416.xy * _418_fa_maps.x;\n        float3 _3287 = _2416;\n        _3287.x = _2421.x;\n        _3287.y = _2421.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3287;\n        _3213 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _418_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2450 = fa_tex_fix(param_12, param_13);\n    float4 _3290 = mrt;\n    _3290.x = _2450.x;\n    _3290.y = _2450.y;\n    _3290.z = _2450.z;\n    mrt = _3290;\n    float4 _2478 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _418_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _2478.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2490 = fa_tex_fix(param_16, param_17);\n    float param_18 = _418_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2520 = fa_tex_fix(param_20, param_21);\n    float _3218 = _418_fa_layers_a.x;\n    float _3219 = _418_fa_layers_a.y;\n    float _3222 = _418_fa_layers_a.z;\n    float _3221 = _418_fa_layers_b.w;\n    float _3224 = _418_fa_layers_c.x;\n    if (_418_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_418_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _3218 *= _2490.y;\n            _3219 *= _2490.z;\n            _3221 *= _2478.w;\n        }\n        if (_418_fa_layers_c.z > 1.5f)\n        {\n            _3222 *= mrt.x;\n            _3224 *= mrt.w;\n        }\n    }\n    Surface _3243 = { _2380.xyz, _2380.w, _3213, clamp(_418_fa_pbr.x * _2450.z, 0.0f, 1.0f), clamp(_418_fa_pbr.y * _2450.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_418_fa_maps.y * (_2490.x - 1.0f)), _418_fa_emissive.xyz + (_418_fa_model_emissive.xyz * _2520), _3218, _3219, _418_fa_layers_b.xyz, _3221, _3222, _418_fa_layers_a.w, _3224, _418_fa_layers_c.y, _418_fa_layers_d.xyz };\n    return _3243;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return _3307;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_418_fa_cl_info.x) + int(_418_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _290 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _296 = fa_light_texel(param_1);\n    float _299 = _296.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _306 = _299 < 0.5f;\n    float3 l;\n    if (_306)\n    {\n        l = normalize(_290.xyz);\n    }\n    else\n    {\n        float3 _318 = _290.xyz - world_pos;\n        float _320 = length(_318);\n        dist = _320;\n        l = _318 / max(_320, 9.9999997473787516355514526367188e-05f).xxx;\n        float _335 = _320 / max(_290.w, 0.001000000047497451305389404296875f);\n        float _341 = clamp(1.0f - (_335 * _335), 0.0f, 1.0f);\n        atten = _341 * _341;\n        if (_299 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _355 = fa_light_texel(param_2);\n            float _365 = _355.w;\n            int param_3 = (li * 4) + 3;\n            float4 _372 = fa_light_texel(param_3);\n            float _373 = _372.x;\n            float cos_inner = _373;\n            if (_373 > 1.5f)\n            {\n                cos_inner = lerp(_365, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_365, cos_inner, dot(-l, normalize(_355.xyz)));\n        }\n    }\n    int _404;\n    if (_306)\n    {\n        _404 = 0;\n    }\n    else\n    {\n        _404 = (_299 > 1.5f) ? 2 : 1;\n    }\n    LightSample _3062 = { l, _296.xyz * atten, atten, 1.0f, dist, _404 };\n    return _3062;\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _2165 = n < 0;\n    bool _2172;\n    if (!_2165)\n    {\n        _2172 = n >= fa_light_count();\n    }\n    else\n    {\n        _2172 = _2165;\n    }\n    if (_2172)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    return fa_light_sample(param_1, param_2);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _644;\n    if (i == 0)\n    {\n        _644 = _654_fa_shadow_split.x;\n    }\n    else\n    {\n        float _660;\n        if (i == 1)\n        {\n            _660 = _654_fa_shadow_split.y;\n        }\n        else\n        {\n            float _668;\n            if (i == 2)\n            {\n                _668 = _654_fa_shadow_split.z;\n            }\n            else\n            {\n                _668 = _654_fa_shadow_split.w;\n            }\n            _660 = _668;\n        }\n        _644 = _660;\n    }\n    return _644;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _632 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_632), sin(_632)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _706 = max(_654_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _711 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _717 = sqrt(1.0f - (_711 * _711));\n    float _725 = min(_717 / max(_711, 0.20000000298023223876953125f), 4.0f);\n    float _730;\n    if (_654_fa_shadow_bias.y > 0.0f)\n    {\n        _730 = _654_fa_shadow_bias.y;\n    }\n    else\n    {\n        _730 = 1.5f * _654_fa_shadow_info[ci].x;\n    }\n    float4 _755 = mul(float4(world + (n * (_730 * _717)), 1.0f), _654_fa_shadow_mat[ci]);\n    float _762 = _755.x;\n    bool _765 = _762 < _654_fa_shadow_rect[ci].x;\n    bool _774;\n    if (!_765)\n    {\n        _774 = _762 > _654_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _774 = _765;\n    }\n    bool _783;\n    if (!_774)\n    {\n        _783 = _755.y < _654_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _783 = _774;\n    }\n    bool _792;\n    if (!_783)\n    {\n        _792 = _755.y > _654_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _792 = _783;\n    }\n    bool _799;\n    if (!_792)\n    {\n        _799 = _755.z > 1.0f;\n    }\n    else\n    {\n        _799 = _792;\n    }\n    if (_799)\n    {\n        return -1.0f;\n    }\n    float _808;\n    if (_654_fa_shadow_bias.x > 0.0f)\n    {\n        _808 = _654_fa_shadow_bias.x;\n    }\n    else\n    {\n        _808 = 1.5f * _654_fa_shadow_info[ci].x;\n    }\n    float _827 = _755.z - ((_808 * (1.0f + (0.5f * _725))) / _706);\n    float _836 = ((_654_fa_shadow_info[ci].x * min(_725, 3.0f)) * 0.5f) / _706;\n    int _845 = int(_654_fa_shadow_cfg.z + 0.5f);\n    if (_845 == 1)\n    {\n        float2 param = _755.xy;\n        float4 param_1 = _654_fa_shadow_rect[ci];\n        float _856 = fa_shadow_depth(param, param_1);\n        return float(_827 <= _856);\n    }\n    float _863 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _866 = _845 == 2;\n    if (_866)\n    {\n        float _880 = clamp(((_654_fa_shadow_cfg.w * _706) * 0.25f) / _654_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _863;\n            float2 _899 = fa_shadow_vogel(param_2, param_3, param_4) * _880;\n            float2 param_5 = _755.xy + (_899 * _654_fa_shadow_bias.zw);\n            float4 param_6 = _654_fa_shadow_rect[ci];\n            float _910 = fa_shadow_depth(param_5, param_6);\n            if (_910 < (_827 - (length(_899) * _836)))\n            {\n                sum += _910;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_827 - (sum / cnt), 0.0f) * _706) * _654_fa_shadow_cfg.w) / _654_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _954 = _866 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _954; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _954;\n        float param_9 = _863;\n        float2 _973 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _755.xy + (_973 * _654_fa_shadow_bias.zw);\n        float4 param_11 = _654_fa_shadow_rect[ci];\n        float _984 = fa_shadow_depth(param_10, param_11);\n        lit += float((_827 - (length(_973) * _836)) <= _984);\n    }\n    return lit / float(_954);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_418_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1014 = int(_654_fa_shadow_cfg.x + 0.5f);\n    if (_1014 < 1)\n    {\n        return 1.0f;\n    }\n    float _1030 = dot(world - _654_fa_shadow_eye.xyz, _654_fa_shadow_fwd.xyz);\n    int param = _1014 - 1;\n    if (_1030 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1042 = _1014 > 1;\n    bool _1049;\n    if (_1042)\n    {\n        _1049 = _1030 > _654_fa_shadow_split.x;\n    }\n    else\n    {\n        _1049 = _1042;\n    }\n    if (_1049)\n    {\n        ci = 1;\n    }\n    bool _1053 = _1014 > 2;\n    bool _1060;\n    if (_1053)\n    {\n        _1060 = _1030 > _654_fa_shadow_split.y;\n    }\n    else\n    {\n        _1060 = _1053;\n    }\n    if (_1060)\n    {\n        ci = 2;\n    }\n    bool _1064 = _1014 > 3;\n    bool _1071;\n    if (_1064)\n    {\n        _1071 = _1030 > _654_fa_shadow_split.z;\n    }\n    else\n    {\n        _1071 = _1064;\n    }\n    if (_1071)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1014)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1097 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1097;\n        if (_1097 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_654_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1122;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1122 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1122 = _654_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1141 = _654_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1122, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1152 = clamp((_1030 - (fa_shadow_split_at(param_7) - _1141)) / _1141, 0.0f, 1.0f);\n        if (_1152 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1014)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1173 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1173;\n                if (_1173 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1152);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _2108 = fa_light_sample(param, param_1);\n    float3 _3189 = _2108.direction;\n    float3 _3184 = _2108.color;\n    float _3186 = _2108.shadow;\n    int _3194 = _2108.type;\n    if ((_3194 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _3189;\n        float _2122 = fa_shadow_factor(param_2, param_3);\n        _3186 = _2122;\n        _3184 *= _2122;\n    }\n    LightSample _3201 = { _3189, _3184, _2108.attenuation, _3186, _2108._distance, _3194 };\n    return _3201;\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _2139 = n < 0;\n    bool _2146;\n    if (!_2139)\n    {\n        _2146 = n >= fa_light_count();\n    }\n    else\n    {\n        _2146 = _2139;\n    }\n    if (_2146)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    return fa_light_shadowed(param_1, param_2, param_3);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1455 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _1463 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _1466 = int(_1455);\n    int _1469 = int(_1463);\n    float _1479 = _1463 - float(_1469);\n    int _1535 = (_1466 * 9) + _1469;\n    int _1555 = ((_1466 + 1) * 9) + _1469;\n    return lerp(lerp(_1530[_1535], _1530[_1535 + 1], _1479), lerp(_1530[_1555], _1530[_1555 + 1], _1479), _1455 - float(_1466));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _3063 = false;\n    float _3064 = 1.0f;\n    float _3065 = 1.0f;\n    float _3066 = 1.0f;\n    float _3067 = 0.0f;\n    float _3068 = 0.0f;\n    float _3069 = 0.0f;\n    float _3070 = 0.0f;\n    float _3072 = 1.0f;\n    bool _3073 = false;\n    float3 _3074 = 0.0f.xxx;\n    float _3075 = 1.0f;\n    float _3076 = 1.0f;\n    float _3077 = 1.0f;\n    float _3078 = 0.0f;\n    float _3079 = 0.0f;\n    float3 _3080 = float3(1.0f, 0.0f, 0.0f);\n    float3 _3081 = float3(0.0f, 0.0f, 1.0f);\n    float _3082 = 1.0f;\n    float _3083 = 1.0f;\n    float _1610 = clamp(s.specular, 0.0f, 1.0f);\n    float _1614 = clamp(s.ior, 1.0f, 3.0f);\n    bool _1619 = (_1610 != 1.0f) || (_1614 != 1.5f);\n    bool _1629;\n    if (!_1619)\n    {\n        _1629 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _1629 = _1619;\n    }\n    if (_1629)\n    {\n        float _1637 = (_1614 - 1.0f) / (_1614 + 1.0f);\n        f0 = lerp(min((_1637 * _1637).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _1610, s.albedo, metallic.xxx);\n        _3064 = lerp(_1610, 1.0f, metallic);\n        _3063 = true;\n    }\n    float _1665 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_1665 > 0.0f)\n    {\n        float _1673 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _3067 = _1665;\n        _3068 = _1673;\n        float _1680 = _1673 * _1673;\n        _3069 = _1680;\n        _3070 = _1680 * _1680;\n        float _1692 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _3072 = _1692;\n        _3065 = 1.0f - (_1665 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _1692, 0.0f, 1.0f), 5.0f))));\n        _3063 = true;\n    }\n    float3 _1712 = max(s.sheen_color, 0.0f.xxx);\n    float _1721 = max(_1712.x, max(_1712.y, _1712.z));\n    if (_1721 > 0.0f)\n    {\n        float _1729 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _3073 = true;\n        _3074 = _1712;\n        _3075 = _1729;\n        _3076 = _1729 * _1729;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _1729;\n        float _1746 = fa_sheen_albedo(param, param_1);\n        _3078 = _1746;\n        _3077 = 1.0f - min(_1721 * _1746, 1.0f);\n        _3063 = true;\n    }\n    _3066 = _3065 * _3077;\n    float _1765 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_1765 != 0.0f)\n    {\n        float3 _1780 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _1780;\n        if (dot(_1780, _1780) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _1794 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_1794.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _1794.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _1794.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _1798 = t;\n        float3 _1799 = normalize(_1798);\n        t = _1799;\n        float3 _1824 = normalize((_1799 * cos(s.anisotropy_rotation)) + ((cross(n, _1799) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _3080 = _1824;\n        _3081 = cross(n, _1824);\n        float _1834 = roughness * roughness;\n        float _1840 = lerp(_1834, 1.0f, _1765 * _1765);\n        bool _1842 = _1765 > 0.0f;\n        _3082 = _1842 ? _1840 : _1834;\n        _3083 = _1842 ? _1834 : _1840;\n        _3079 = _1765;\n        _3063 = true;\n    }\n    FaLayers _3105 = { _3063, _3064, _3065, _3066, _3067, _3068, _3069, _3070, i.world_normal, _3072, _3073, _3074, _3075, _3076, _3077, _3078, _3079, _3080, _3081, _3082, _3083 };\n    return _3105;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _1387 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _1390 = _1387.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_1390 * _1390, exp2((-9.27999973297119140625f) * ndv)) * _1390) + _1387.y)) + _1387.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_418_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _418_fa_env_horizon.w).xyz;\n    }\n    float _1310 = rough * rough;\n    float _1340 = 0.60000002384185791015625f * _1310;\n    return lerp(lerp(_418_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_418_fa_env_horizon.xyz, _418_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _1310)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _1340, 0.0500000007450580596923828125f + _1340, d.y).xxx), ((_418_fa_env_sky.xyz + _418_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_1310 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _1875;\n        if (L.aniso >= 0.0f)\n        {\n            _1875 = L.b;\n        }\n        else\n        {\n            _1875 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_1875, v), _1875), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1908 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _1908.x) + (L.f90.xxx * _1908.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _1963 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _1963.x) + _1963.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1429 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1429.x) + _1429.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _2002 = clamp(s.metallic, 0.0f, 1.0f);\n    float _2006 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _2013 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _2002.xxx);\n    float3 f0 = _2013;\n    float3 _2017 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _2017;\n    float3 param_3 = i.view_dir;\n    float param_4 = _2002;\n    float param_5 = _2006;\n    float3 param_6 = _2013;\n    FaLayers _2034 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_2034.on)\n    {\n        FaLayers param_7 = _2034;\n        float3 param_8 = _2017;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _2006;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _2017;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _2006;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0f;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _2212 = dot(fa_light_unshadowed(param, param_1).color, float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));\n        if (_2212 > bestPower)\n        {\n            bestPower = _2212;\n            best = n;\n        }\n    }\n    float3 lit = (_418_fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _2241 = fa_light(param_2, param_3);\n        float _2249;\n        if (dot(s.normal, _2241.direction) > 0.5f)\n        {\n            _2249 = 1.0f;\n        }\n        else\n        {\n            _2249 = _2255_dark;\n        }\n        lit += ((s.albedo * _2241.color) * _2249);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * _2255_skyAmount);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_654_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1197 = int(_654_fa_shadow_cfg.x + 0.5f);\n    float _1207 = dot(world - _654_fa_shadow_eye.xyz, _654_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1212 = _1197 > 0;\n    bool _1221;\n    if (_1212)\n    {\n        int param = _1197 - 1;\n        _1221 = _1207 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1221 = _1212;\n    }\n    if (_1221)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1228 = _1197 > 1;\n        bool _1235;\n        if (_1228)\n        {\n            _1235 = _1207 > _654_fa_shadow_split.x;\n        }\n        else\n        {\n            _1235 = _1228;\n        }\n        if (_1235)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1241 = _1197 > 2;\n        bool _1248;\n        if (_1241)\n        {\n            _1248 = _1207 > _654_fa_shadow_split.y;\n        }\n        else\n        {\n            _1248 = _1241;\n        }\n        if (_1248)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1254 = _1197 > 3;\n        bool _1261;\n        if (_1254)\n        {\n            _1261 = _1207 > _654_fa_shadow_split.z;\n        }\n        else\n        {\n            _1261 = _1254;\n        }\n        if (_1261)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _2937 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2937 = -_2937;\n    }\n    float3 _2641 = normalize(_418_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _2950 = { fa_world_pos, _2937, fa_world_tangent, fa_uv, fa_vertex_color, _2641, gl_FrontFacing };\n    SurfaceInput param_1 = _2950;\n    Surface _2649 = fa_standard_surface(param_1);\n    float3 _2968 = _2649.albedo;\n    float _2969 = _2649.alpha;\n    float3 _2970 = _2649.normal;\n    float _2971 = _2649.metallic;\n    float _2972 = _2649.roughness;\n    float _2973 = _2649.occlusion;\n    float3 _2974 = _2649.emission;\n    float _2975 = _2649.clearcoat;\n    float _2976 = _2649.clearcoat_roughness;\n    float3 _2977 = _2649.sheen_color;\n    float _2978 = _2649.sheen_roughness;\n    float _2979 = _2649.anisotropy;\n    float _2980 = _2649.anisotropy_rotation;\n    float _2981 = _2649.specular;\n    float _2982 = _2649.ior;\n    float3 _2983 = _2649.specular_color;\n    SurfaceInput _2958 = { fa_world_pos, _2937, fa_world_tangent, fa_uv, fa_vertex_color, _2641, gl_FrontFacing };\n    SurfaceInput param_2 = _2958;\n    Surface param_3 = _2649;\n    surface(param_2, param_3);\n    _2968 = param_3.albedo;\n    _2969 = param_3.alpha;\n    _2970 = param_3.normal;\n    _2971 = param_3.metallic;\n    _2972 = param_3.roughness;\n    _2973 = param_3.occlusion;\n    _2974 = param_3.emission;\n    _2975 = param_3.clearcoat;\n    _2976 = param_3.clearcoat_roughness;\n    _2977 = param_3.sheen_color;\n    _2978 = param_3.sheen_roughness;\n    _2979 = param_3.anisotropy;\n    _2980 = param_3.anisotropy_rotation;\n    _2981 = param_3.specular;\n    _2982 = param_3.ior;\n    _2983 = param_3.specular_color;\n    float3 result;\n    if (_418_fa_emissive.w > 0.5f)\n    {\n        result = _2968;\n    }\n    else\n    {\n        float3 _2670 = _2970;\n        float3 _2671 = normalize(_2670);\n        _2970 = _2671;\n        SurfaceInput _2966 = { fa_world_pos, _2937, fa_world_tangent, fa_uv, fa_vertex_color, _2641, gl_FrontFacing };\n        SurfaceInput param_4 = _2966;\n        Surface _3049 = { _2968, _2969, _2671, _2971, _2972, _2973, _2974, _2975, _2976, _2977, _2978, _2979, _2980, _2981, _2982, _2983 };\n        Surface param_5 = _3049;\n        result = lighting(param_4, param_5);\n    }\n    float3 _2686 = result;\n    float3 _2687 = _2686 + _2974;\n    result = _2687;\n    float3 param_6 = _2687;\n    float3 param_7 = fa_world_pos;\n    result = fa_shadow_debug(param_6, param_7);\n    bool _2696 = _418_fa_fog.w > 0.0f;\n    bool _2703;\n    if (!_2696)\n    {\n        _2703 = _418_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2703 = _2696;\n    }\n    if (_2703)\n    {\n        float3 _2712 = fa_world_pos - _418_fa_camera_pos.xyz;\n        float _2718 = dot(_2712, _418_fa_fog_c.xyz);\n        bool _2722 = _418_fa_fog_c.w > 0.5f;\n        float _2723;\n        if (_2722)\n        {\n            _2723 = _2718;\n        }\n        else\n        {\n            _2723 = length(_2712);\n        }\n        float _2735 = _2723 - _418_fa_fog_b.x;\n        if (_2735 > 0.0f)\n        {\n            float _2744 = _418_fa_fog.w * _2735;\n            float tau = _2744 * _2744;\n            if (_418_fa_fog_b.y > 0.0f)\n            {\n                float _2760;\n                if (_2722)\n                {\n                    _2760 = fa_world_pos.y - (_418_fa_fog_c.y * _2718);\n                }\n                else\n                {\n                    _2760 = _418_fa_camera_pos.y;\n                }\n                float _2781 = lerp(_2760, fa_world_pos.y, clamp(_418_fa_fog_b.x / _2723, 0.0f, 1.0f));\n                float _2785 = fa_world_pos.y - _2781;\n                float _2790 = _2781 - _418_fa_fog_b.z;\n                float _2795 = fa_world_pos.y - _418_fa_fog_b.z;\n                bool _2798 = _2790 <= 0.0f;\n                bool _2799 = !_2798;\n                bool _2805;\n                if (_2799)\n                {\n                    _2805 = _418_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2805 = _2798;\n                }\n                float _2806;\n                if (_2805)\n                {\n                    _2806 = _418_fa_fog_b.y;\n                }\n                else\n                {\n                    _2806 = _418_fa_fog_b.y * exp(-min(_418_fa_fog_b.w * _2790, 80.0f));\n                }\n                bool _2833;\n                if (_2799)\n                {\n                    _2833 = _418_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2833 = _2798;\n                }\n                float _2834;\n                if (_2833)\n                {\n                    _2834 = _418_fa_fog_b.y * _2790;\n                }\n                else\n                {\n                    _2834 = (_418_fa_fog_b.y * (1.0f - exp(-min(_418_fa_fog_b.w * _2790, 80.0f)))) / _418_fa_fog_b.w;\n                }\n                bool _2859 = _2795 <= 0.0f;\n                bool _2866;\n                if (!_2859)\n                {\n                    _2866 = _418_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2866 = _2859;\n                }\n                float _2867;\n                if (_2866)\n                {\n                    _2867 = _418_fa_fog_b.y * _2795;\n                }\n                else\n                {\n                    _2867 = (_418_fa_fog_b.y * (1.0f - exp(-min(_418_fa_fog_b.w * _2795, 80.0f)))) / _418_fa_fog_b.w;\n                }\n                float _2894;\n                if (abs(_2785) < 0.001000000047497451305389404296875f)\n                {\n                    _2894 = _2806;\n                }\n                else\n                {\n                    _2894 = (_2867 - _2834) / _2785;\n                }\n                tau += (_2735 * max(_2894, 0.0f));\n            }\n            result = lerp(result, _418_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _2969);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_418",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_654",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_2255",
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 7,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _382 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _382;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _389 = _273.world_pos;\n    fa_world_pos = _389;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_389, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _1530[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\nstatic const LightSample _3307 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, 0 };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _418_fa_camera_pos : packoffset(c0);\n    float4 _418_fa_ambient : packoffset(c1);\n    float4 _418_fa_base_color : packoffset(c2);\n    float4 _418_fa_emissive : packoffset(c3);\n    float4 _418_fa_model_emissive : packoffset(c4);\n    float4 _418_fa_pbr : packoffset(c5);\n    float4 _418_fa_maps : packoffset(c6);\n    float4 _418_fa_fog : packoffset(c7);\n    float4 _418_fa_fog_b : packoffset(c8);\n    float4 _418_fa_fog_c : packoffset(c9);\n    float4 _418_fa_counts : packoffset(c10);\n    float4 _418_fa_env_sky : packoffset(c11);\n    float4 _418_fa_env_horizon : packoffset(c12);\n    float4 _418_fa_time : packoffset(c13);\n    float4 _418_fa_cl_vpx : packoffset(c14);\n    float4 _418_fa_cl_vpy : packoffset(c15);\n    float4 _418_fa_cl_vpw : packoffset(c16);\n    float4 _418_fa_cl_fwd : packoffset(c17);\n    float4 _418_fa_cl_grid : packoffset(c18);\n    float4 _418_fa_cl_info : packoffset(c19);\n    float4 _418_fa_layers_a : packoffset(c20);\n    float4 _418_fa_layers_b : packoffset(c21);\n    float4 _418_fa_layers_c : packoffset(c22);\n    float4 _418_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _654_fa_shadow_mat[4] : packoffset(c0);\n    float4 _654_fa_shadow_rect[4] : packoffset(c16);\n    float4 _654_fa_shadow_info[4] : packoffset(c20);\n    float4 _654_fa_shadow_split : packoffset(c24);\n    float4 _654_fa_shadow_cfg : packoffset(c25);\n    float4 _654_fa_shadow_bias : packoffset(c26);\n    float4 _654_fa_shadow_eye : packoffset(c27);\n    float4 _654_fa_shadow_fwd : packoffset(c28);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _2255_dark : packoffset(c0);\n    float _2255_fa_pad0 : packoffset(c0.y);\n    float _2255_fa_pad1 : packoffset(c0.z);\n    float _2255_fa_pad2 : packoffset(c0.w);\n    float _2255_skyAmount : packoffset(c1);\n    float _2255_fa_pad3 : packoffset(c1.y);\n    float _2255_fa_pad4 : packoffset(c1.z);\n    float _2255_fa_pad5 : packoffset(c1.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _423 = _418_fa_cl_info.x < 0.0f;\n    bool _430;\n    if (!_423)\n    {\n        _430 = _418_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _430 = _423;\n    }\n    bool _438;\n    if (!_430)\n    {\n        _438 = _418_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _438 = _430;\n    }\n    bool _445;\n    if (!_438)\n    {\n        _445 = _418_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _445 = _438;\n    }\n    bool _452;\n    if (!_445)\n    {\n        _452 = _418_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _452 = _445;\n    }\n    if (_452)\n    {\n        return int2(0, 0);\n    }\n    float4 _462 = float4(world_pos, 1.0f);\n    float _469 = dot(_418_fa_cl_vpw, _462);\n    if (!(_469 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _491 = float2(dot(_418_fa_cl_vpx, _462), dot(_418_fa_cl_vpy, _462)) / _469.xx;\n    int _495 = int(_418_fa_cl_grid.x);\n    int _499 = int(_418_fa_cl_grid.y);\n    int param = (int(_418_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_418_fa_cl_fwd.xyz, world_pos) + _418_fa_cl_fwd.w, _418_fa_cl_grid.w) / _418_fa_cl_grid.w) * _418_fa_cl_grid.z)), 0, int(_418_fa_cl_info.y) - 1) * _499) + clamp(int(floor(((_491.y * 0.5f) + 0.5f) * _418_fa_cl_grid.y)), 0, _499 - 1)) * _495)) + clamp(int(floor(((_491.x * 0.5f) + 0.5f) * _418_fa_cl_grid.x)), 0, _495 - 1);\n    float4 _570 = fa_light_texel(param);\n    return int2(int(_570.x), int(_570.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_418_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2080 = fa_cluster_lookup(param);\n    fa_cl_slot = _2080.x;\n    fa_cl_local = _2080.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _2327 = fa_linear_to_srgb(param);\n        c = _2327;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _2335 = fa_srgb_to_linear(param_1);\n            c = _2335;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _198;\n    if (i.front_facing)\n    {\n        _198 = i.world_normal;\n    }\n    else\n    {\n        _198 = -i.world_normal;\n    }\n    float3 _222 = normalize(i.world_tangent.xyz - (_198 * dot(_198, i.world_tangent.xyz)));\n    float3 _250 = normalize(((_222 * m.x) + ((cross(_198, _222) * i.world_tangent.w) * m.y)) + (_198 * m.z));\n    float3 _253;\n    if (i.front_facing)\n    {\n        _253 = _250;\n    }\n    else\n    {\n        _253 = -_250;\n    }\n    return _253;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _418_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2366 = fa_tex_fix(param_2, param_3);\n    float4 _3279 = base_t;\n    _3279.x = _2366.x;\n    _3279.y = _2366.y;\n    _3279.z = _2366.z;\n    base_t = _3279;\n    float4 _2380 = (_3279 * _418_fa_base_color) * i.vertex_color;\n    float3 _3213 = i.world_normal;\n    if (_418_fa_maps.z > 0.5f)\n    {\n        float param_4 = _418_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2412 = fa_tex_fix(param_6, param_7);\n        float3 _2416 = (_2412 * 2.0f) - 1.0f.xxx;\n        float2 _2421 = _2416.xy * _418_fa_maps.x;\n        float3 _3287 = _2416;\n        _3287.x = _2421.x;\n        _3287.y = _2421.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3287;\n        _3213 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _418_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2450 = fa_tex_fix(param_12, param_13);\n    float4 _3290 = mrt;\n    _3290.x = _2450.x;\n    _3290.y = _2450.y;\n    _3290.z = _2450.z;\n    mrt = _3290;\n    float4 _2478 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _418_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _2478.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2490 = fa_tex_fix(param_16, param_17);\n    float param_18 = _418_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2520 = fa_tex_fix(param_20, param_21);\n    float _3218 = _418_fa_layers_a.x;\n    float _3219 = _418_fa_layers_a.y;\n    float _3222 = _418_fa_layers_a.z;\n    float _3221 = _418_fa_layers_b.w;\n    float _3224 = _418_fa_layers_c.x;\n    if (_418_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_418_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _3218 *= _2490.y;\n            _3219 *= _2490.z;\n            _3221 *= _2478.w;\n        }\n        if (_418_fa_layers_c.z > 1.5f)\n        {\n            _3222 *= mrt.x;\n            _3224 *= mrt.w;\n        }\n    }\n    Surface _3243 = { _2380.xyz, _2380.w, _3213, clamp(_418_fa_pbr.x * _2450.z, 0.0f, 1.0f), clamp(_418_fa_pbr.y * _2450.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_418_fa_maps.y * (_2490.x - 1.0f)), _418_fa_emissive.xyz + (_418_fa_model_emissive.xyz * _2520), _3218, _3219, _418_fa_layers_b.xyz, _3221, _3222, _418_fa_layers_a.w, _3224, _418_fa_layers_c.y, _418_fa_layers_d.xyz };\n    return _3243;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return _3307;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_418_fa_cl_info.x) + int(_418_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _290 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _296 = fa_light_texel(param_1);\n    float _299 = _296.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _306 = _299 < 0.5f;\n    float3 l;\n    if (_306)\n    {\n        l = normalize(_290.xyz);\n    }\n    else\n    {\n        float3 _318 = _290.xyz - world_pos;\n        float _320 = length(_318);\n        dist = _320;\n        l = _318 / max(_320, 9.9999997473787516355514526367188e-05f).xxx;\n        float _335 = _320 / max(_290.w, 0.001000000047497451305389404296875f);\n        float _341 = clamp(1.0f - (_335 * _335), 0.0f, 1.0f);\n        atten = _341 * _341;\n        if (_299 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _355 = fa_light_texel(param_2);\n            float _365 = _355.w;\n            int param_3 = (li * 4) + 3;\n            float4 _372 = fa_light_texel(param_3);\n            float _373 = _372.x;\n            float cos_inner = _373;\n            if (_373 > 1.5f)\n            {\n                cos_inner = lerp(_365, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_365, cos_inner, dot(-l, normalize(_355.xyz)));\n        }\n    }\n    int _404;\n    if (_306)\n    {\n        _404 = 0;\n    }\n    else\n    {\n        _404 = (_299 > 1.5f) ? 2 : 1;\n    }\n    LightSample _3062 = { l, _296.xyz * atten, atten, 1.0f, dist, _404 };\n    return _3062;\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _2165 = n < 0;\n    bool _2172;\n    if (!_2165)\n    {\n        _2172 = n >= fa_light_count();\n    }\n    else\n    {\n        _2172 = _2165;\n    }\n    if (_2172)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    return fa_light_sample(param_1, param_2);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _644;\n    if (i == 0)\n    {\n        _644 = _654_fa_shadow_split.x;\n    }\n    else\n    {\n        float _660;\n        if (i == 1)\n        {\n            _660 = _654_fa_shadow_split.y;\n        }\n        else\n        {\n            float _668;\n            if (i == 2)\n            {\n                _668 = _654_fa_shadow_split.z;\n            }\n            else\n            {\n                _668 = _654_fa_shadow_split.w;\n            }\n            _660 = _668;\n        }\n        _644 = _660;\n    }\n    return _644;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _632 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_632), sin(_632)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _706 = max(_654_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _711 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _717 = sqrt(1.0f - (_711 * _711));\n    float _725 = min(_717 / max(_711, 0.20000000298023223876953125f), 4.0f);\n    float _730;\n    if (_654_fa_shadow_bias.y > 0.0f)\n    {\n        _730 = _654_fa_shadow_bias.y;\n    }\n    else\n    {\n        _730 = 1.5f * _654_fa_shadow_info[ci].x;\n    }\n    float4 _755 = mul(float4(world + (n * (_730 * _717)), 1.0f), _654_fa_shadow_mat[ci]);\n    float _762 = _755.x;\n    bool _765 = _762 < _654_fa_shadow_rect[ci].x;\n    bool _774;\n    if (!_765)\n    {\n        _774 = _762 > _654_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _774 = _765;\n    }\n    bool _783;\n    if (!_774)\n    {\n        _783 = _755.y < _654_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _783 = _774;\n    }\n    bool _792;\n    if (!_783)\n    {\n        _792 = _755.y > _654_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _792 = _783;\n    }\n    bool _799;\n    if (!_792)\n    {\n        _799 = _755.z > 1.0f;\n    }\n    else\n    {\n        _799 = _792;\n    }\n    if (_799)\n    {\n        return -1.0f;\n    }\n    float _808;\n    if (_654_fa_shadow_bias.x > 0.0f)\n    {\n        _808 = _654_fa_shadow_bias.x;\n    }\n    else\n    {\n        _808 = 1.5f * _654_fa_shadow_info[ci].x;\n    }\n    float _827 = _755.z - ((_808 * (1.0f + (0.5f * _725))) / _706);\n    float _836 = ((_654_fa_shadow_info[ci].x * min(_725, 3.0f)) * 0.5f) / _706;\n    int _845 = int(_654_fa_shadow_cfg.z + 0.5f);\n    if (_845 == 1)\n    {\n        float2 param = _755.xy;\n        float4 param_1 = _654_fa_shadow_rect[ci];\n        float _856 = fa_shadow_depth(param, param_1);\n        return float(_827 <= _856);\n    }\n    float _863 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _866 = _845 == 2;\n    if (_866)\n    {\n        float _880 = clamp(((_654_fa_shadow_cfg.w * _706) * 0.25f) / _654_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _863;\n            float2 _899 = fa_shadow_vogel(param_2, param_3, param_4) * _880;\n            float2 param_5 = _755.xy + (_899 * _654_fa_shadow_bias.zw);\n            float4 param_6 = _654_fa_shadow_rect[ci];\n            float _910 = fa_shadow_depth(param_5, param_6);\n            if (_910 < (_827 - (length(_899) * _836)))\n            {\n                sum += _910;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_827 - (sum / cnt), 0.0f) * _706) * _654_fa_shadow_cfg.w) / _654_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _954 = _866 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _954; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _954;\n        float param_9 = _863;\n        float2 _973 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _755.xy + (_973 * _654_fa_shadow_bias.zw);\n        float4 param_11 = _654_fa_shadow_rect[ci];\n        float _984 = fa_shadow_depth(param_10, param_11);\n        lit += float((_827 - (length(_973) * _836)) <= _984);\n    }\n    return lit / float(_954);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_418_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1014 = int(_654_fa_shadow_cfg.x + 0.5f);\n    if (_1014 < 1)\n    {\n        return 1.0f;\n    }\n    float _1030 = dot(world - _654_fa_shadow_eye.xyz, _654_fa_shadow_fwd.xyz);\n    int param = _1014 - 1;\n    if (_1030 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1042 = _1014 > 1;\n    bool _1049;\n    if (_1042)\n    {\n        _1049 = _1030 > _654_fa_shadow_split.x;\n    }\n    else\n    {\n        _1049 = _1042;\n    }\n    if (_1049)\n    {\n        ci = 1;\n    }\n    bool _1053 = _1014 > 2;\n    bool _1060;\n    if (_1053)\n    {\n        _1060 = _1030 > _654_fa_shadow_split.y;\n    }\n    else\n    {\n        _1060 = _1053;\n    }\n    if (_1060)\n    {\n        ci = 2;\n    }\n    bool _1064 = _1014 > 3;\n    bool _1071;\n    if (_1064)\n    {\n        _1071 = _1030 > _654_fa_shadow_split.z;\n    }\n    else\n    {\n        _1071 = _1064;\n    }\n    if (_1071)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1014)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1097 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1097;\n        if (_1097 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_654_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1122;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1122 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1122 = _654_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1141 = _654_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1122, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1152 = clamp((_1030 - (fa_shadow_split_at(param_7) - _1141)) / _1141, 0.0f, 1.0f);\n        if (_1152 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1014)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1173 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1173;\n                if (_1173 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1152);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _2108 = fa_light_sample(param, param_1);\n    float3 _3189 = _2108.direction;\n    float3 _3184 = _2108.color;\n    float _3186 = _2108.shadow;\n    int _3194 = _2108.type;\n    if ((_3194 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _3189;\n        float _2122 = fa_shadow_factor(param_2, param_3);\n        _3186 = _2122;\n        _3184 *= _2122;\n    }\n    LightSample _3201 = { _3189, _3184, _2108.attenuation, _3186, _2108._distance, _3194 };\n    return _3201;\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _2139 = n < 0;\n    bool _2146;\n    if (!_2139)\n    {\n        _2146 = n >= fa_light_count();\n    }\n    else\n    {\n        _2146 = _2139;\n    }\n    if (_2146)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    return fa_light_shadowed(param_1, param_2, param_3);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1455 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _1463 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _1466 = int(_1455);\n    int _1469 = int(_1463);\n    float _1479 = _1463 - float(_1469);\n    int _1535 = (_1466 * 9) + _1469;\n    int _1555 = ((_1466 + 1) * 9) + _1469;\n    return lerp(lerp(_1530[_1535], _1530[_1535 + 1], _1479), lerp(_1530[_1555], _1530[_1555 + 1], _1479), _1455 - float(_1466));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _3063 = false;\n    float _3064 = 1.0f;\n    float _3065 = 1.0f;\n    float _3066 = 1.0f;\n    float _3067 = 0.0f;\n    float _3068 = 0.0f;\n    float _3069 = 0.0f;\n    float _3070 = 0.0f;\n    float _3072 = 1.0f;\n    bool _3073 = false;\n    float3 _3074 = 0.0f.xxx;\n    float _3075 = 1.0f;\n    float _3076 = 1.0f;\n    float _3077 = 1.0f;\n    float _3078 = 0.0f;\n    float _3079 = 0.0f;\n    float3 _3080 = float3(1.0f, 0.0f, 0.0f);\n    float3 _3081 = float3(0.0f, 0.0f, 1.0f);\n    float _3082 = 1.0f;\n    float _3083 = 1.0f;\n    float _1610 = clamp(s.specular, 0.0f, 1.0f);\n    float _1614 = clamp(s.ior, 1.0f, 3.0f);\n    bool _1619 = (_1610 != 1.0f) || (_1614 != 1.5f);\n    bool _1629;\n    if (!_1619)\n    {\n        _1629 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _1629 = _1619;\n    }\n    if (_1629)\n    {\n        float _1637 = (_1614 - 1.0f) / (_1614 + 1.0f);\n        f0 = lerp(min((_1637 * _1637).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _1610, s.albedo, metallic.xxx);\n        _3064 = lerp(_1610, 1.0f, metallic);\n        _3063 = true;\n    }\n    float _1665 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_1665 > 0.0f)\n    {\n        float _1673 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _3067 = _1665;\n        _3068 = _1673;\n        float _1680 = _1673 * _1673;\n        _3069 = _1680;\n        _3070 = _1680 * _1680;\n        float _1692 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _3072 = _1692;\n        _3065 = 1.0f - (_1665 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _1692, 0.0f, 1.0f), 5.0f))));\n        _3063 = true;\n    }\n    float3 _1712 = max(s.sheen_color, 0.0f.xxx);\n    float _1721 = max(_1712.x, max(_1712.y, _1712.z));\n    if (_1721 > 0.0f)\n    {\n        float _1729 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _3073 = true;\n        _3074 = _1712;\n        _3075 = _1729;\n        _3076 = _1729 * _1729;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _1729;\n        float _1746 = fa_sheen_albedo(param, param_1);\n        _3078 = _1746;\n        _3077 = 1.0f - min(_1721 * _1746, 1.0f);\n        _3063 = true;\n    }\n    _3066 = _3065 * _3077;\n    float _1765 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_1765 != 0.0f)\n    {\n        float3 _1780 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _1780;\n        if (dot(_1780, _1780) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _1794 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_1794.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _1794.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _1794.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _1798 = t;\n        float3 _1799 = normalize(_1798);\n        t = _1799;\n        float3 _1824 = normalize((_1799 * cos(s.anisotropy_rotation)) + ((cross(n, _1799) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _3080 = _1824;\n        _3081 = cross(n, _1824);\n        float _1834 = roughness * roughness;\n        float _1840 = lerp(_1834, 1.0f, _1765 * _1765);\n        bool _1842 = _1765 > 0.0f;\n        _3082 = _1842 ? _1840 : _1834;\n        _3083 = _1842 ? _1834 : _1840;\n        _3079 = _1765;\n        _3063 = true;\n    }\n    FaLayers _3105 = { _3063, _3064, _3065, _3066, _3067, _3068, _3069, _3070, i.world_normal, _3072, _3073, _3074, _3075, _3076, _3077, _3078, _3079, _3080, _3081, _3082, _3083 };\n    return _3105;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _1387 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _1390 = _1387.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_1390 * _1390, exp2((-9.27999973297119140625f) * ndv)) * _1390) + _1387.y)) + _1387.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_418_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _418_fa_env_horizon.w).xyz;\n    }\n    float _1310 = rough * rough;\n    float _1340 = 0.60000002384185791015625f * _1310;\n    return lerp(lerp(_418_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_418_fa_env_horizon.xyz, _418_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _1310)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _1340, 0.0500000007450580596923828125f + _1340, d.y).xxx), ((_418_fa_env_sky.xyz + _418_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_1310 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _1875;\n        if (L.aniso >= 0.0f)\n        {\n            _1875 = L.b;\n        }\n        else\n        {\n            _1875 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_1875, v), _1875), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1908 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _1908.x) + (L.f90.xxx * _1908.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _1963 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _1963.x) + _1963.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1429 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1429.x) + _1429.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _2002 = clamp(s.metallic, 0.0f, 1.0f);\n    float _2006 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _2013 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _2002.xxx);\n    float3 f0 = _2013;\n    float3 _2017 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _2017;\n    float3 param_3 = i.view_dir;\n    float param_4 = _2002;\n    float param_5 = _2006;\n    float3 param_6 = _2013;\n    FaLayers _2034 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_2034.on)\n    {\n        FaLayers param_7 = _2034;\n        float3 param_8 = _2017;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _2006;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _2017;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _2006;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0f;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _2212 = dot(fa_light_unshadowed(param, param_1).color, float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));\n        if (_2212 > bestPower)\n        {\n            bestPower = _2212;\n            best = n;\n        }\n    }\n    float3 lit = (_418_fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _2241 = fa_light(param_2, param_3);\n        float _2249;\n        if (dot(s.normal, _2241.direction) > 0.5f)\n        {\n            _2249 = 1.0f;\n        }\n        else\n        {\n            _2249 = _2255_dark;\n        }\n        lit += ((s.albedo * _2241.color) * _2249);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * _2255_skyAmount);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_654_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1197 = int(_654_fa_shadow_cfg.x + 0.5f);\n    float _1207 = dot(world - _654_fa_shadow_eye.xyz, _654_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1212 = _1197 > 0;\n    bool _1221;\n    if (_1212)\n    {\n        int param = _1197 - 1;\n        _1221 = _1207 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1221 = _1212;\n    }\n    if (_1221)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1228 = _1197 > 1;\n        bool _1235;\n        if (_1228)\n        {\n            _1235 = _1207 > _654_fa_shadow_split.x;\n        }\n        else\n        {\n            _1235 = _1228;\n        }\n        if (_1235)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1241 = _1197 > 2;\n        bool _1248;\n        if (_1241)\n        {\n            _1248 = _1207 > _654_fa_shadow_split.y;\n        }\n        else\n        {\n            _1248 = _1241;\n        }\n        if (_1248)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1254 = _1197 > 3;\n        bool _1261;\n        if (_1254)\n        {\n            _1261 = _1207 > _654_fa_shadow_split.z;\n        }\n        else\n        {\n            _1261 = _1254;\n        }\n        if (_1261)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _2937 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2937 = -_2937;\n    }\n    float3 _2641 = normalize(_418_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _2950 = { fa_world_pos, _2937, fa_world_tangent, fa_uv, fa_vertex_color, _2641, gl_FrontFacing };\n    SurfaceInput param_1 = _2950;\n    Surface _2649 = fa_standard_surface(param_1);\n    float3 _2968 = _2649.albedo;\n    float _2969 = _2649.alpha;\n    float3 _2970 = _2649.normal;\n    float _2971 = _2649.metallic;\n    float _2972 = _2649.roughness;\n    float _2973 = _2649.occlusion;\n    float3 _2974 = _2649.emission;\n    float _2975 = _2649.clearcoat;\n    float _2976 = _2649.clearcoat_roughness;\n    float3 _2977 = _2649.sheen_color;\n    float _2978 = _2649.sheen_roughness;\n    float _2979 = _2649.anisotropy;\n    float _2980 = _2649.anisotropy_rotation;\n    float _2981 = _2649.specular;\n    float _2982 = _2649.ior;\n    float3 _2983 = _2649.specular_color;\n    SurfaceInput _2958 = { fa_world_pos, _2937, fa_world_tangent, fa_uv, fa_vertex_color, _2641, gl_FrontFacing };\n    SurfaceInput param_2 = _2958;\n    Surface param_3 = _2649;\n    surface(param_2, param_3);\n    _2968 = param_3.albedo;\n    _2969 = param_3.alpha;\n    _2970 = param_3.normal;\n    _2971 = param_3.metallic;\n    _2972 = param_3.roughness;\n    _2973 = param_3.occlusion;\n    _2974 = param_3.emission;\n    _2975 = param_3.clearcoat;\n    _2976 = param_3.clearcoat_roughness;\n    _2977 = param_3.sheen_color;\n    _2978 = param_3.sheen_roughness;\n    _2979 = param_3.anisotropy;\n    _2980 = param_3.anisotropy_rotation;\n    _2981 = param_3.specular;\n    _2982 = param_3.ior;\n    _2983 = param_3.specular_color;\n    float3 result;\n    if (_418_fa_emissive.w > 0.5f)\n    {\n        result = _2968;\n    }\n    else\n    {\n        float3 _2670 = _2970;\n        float3 _2671 = normalize(_2670);\n        _2970 = _2671;\n        SurfaceInput _2966 = { fa_world_pos, _2937, fa_world_tangent, fa_uv, fa_vertex_color, _2641, gl_FrontFacing };\n        SurfaceInput param_4 = _2966;\n        Surface _3049 = { _2968, _2969, _2671, _2971, _2972, _2973, _2974, _2975, _2976, _2977, _2978, _2979, _2980, _2981, _2982, _2983 };\n        Surface param_5 = _3049;\n        result = lighting(param_4, param_5);\n    }\n    float3 _2686 = result;\n    float3 _2687 = _2686 + _2974;\n    result = _2687;\n    float3 param_6 = _2687;\n    float3 param_7 = fa_world_pos;\n    result = fa_shadow_debug(param_6, param_7);\n    bool _2696 = _418_fa_fog.w > 0.0f;\n    bool _2703;\n    if (!_2696)\n    {\n        _2703 = _418_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2703 = _2696;\n    }\n    if (_2703)\n    {\n        float3 _2712 = fa_world_pos - _418_fa_camera_pos.xyz;\n        float _2718 = dot(_2712, _418_fa_fog_c.xyz);\n        bool _2722 = _418_fa_fog_c.w > 0.5f;\n        float _2723;\n        if (_2722)\n        {\n            _2723 = _2718;\n        }\n        else\n        {\n            _2723 = length(_2712);\n        }\n        float _2735 = _2723 - _418_fa_fog_b.x;\n        if (_2735 > 0.0f)\n        {\n            float _2744 = _418_fa_fog.w * _2735;\n            float tau = _2744 * _2744;\n            if (_418_fa_fog_b.y > 0.0f)\n            {\n                float _2760;\n                if (_2722)\n                {\n                    _2760 = fa_world_pos.y - (_418_fa_fog_c.y * _2718);\n                }\n                else\n                {\n                    _2760 = _418_fa_camera_pos.y;\n                }\n                float _2781 = lerp(_2760, fa_world_pos.y, clamp(_418_fa_fog_b.x / _2723, 0.0f, 1.0f));\n                float _2785 = fa_world_pos.y - _2781;\n                float _2790 = _2781 - _418_fa_fog_b.z;\n                float _2795 = fa_world_pos.y - _418_fa_fog_b.z;\n                bool _2798 = _2790 <= 0.0f;\n                bool _2799 = !_2798;\n                bool _2805;\n                if (_2799)\n                {\n                    _2805 = _418_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2805 = _2798;\n                }\n                float _2806;\n                if (_2805)\n                {\n                    _2806 = _418_fa_fog_b.y;\n                }\n                else\n                {\n                    _2806 = _418_fa_fog_b.y * exp(-min(_418_fa_fog_b.w * _2790, 80.0f));\n                }\n                bool _2833;\n                if (_2799)\n                {\n                    _2833 = _418_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2833 = _2798;\n                }\n                float _2834;\n                if (_2833)\n                {\n                    _2834 = _418_fa_fog_b.y * _2790;\n                }\n                else\n                {\n                    _2834 = (_418_fa_fog_b.y * (1.0f - exp(-min(_418_fa_fog_b.w * _2790, 80.0f)))) / _418_fa_fog_b.w;\n                }\n                bool _2859 = _2795 <= 0.0f;\n                bool _2866;\n                if (!_2859)\n                {\n                    _2866 = _418_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2866 = _2859;\n                }\n                float _2867;\n                if (_2866)\n                {\n                    _2867 = _418_fa_fog_b.y * _2795;\n                }\n                else\n                {\n                    _2867 = (_418_fa_fog_b.y * (1.0f - exp(-min(_418_fa_fog_b.w * _2795, 80.0f)))) / _418_fa_fog_b.w;\n                }\n                float _2894;\n                if (abs(_2785) < 0.001000000047497451305389404296875f)\n                {\n                    _2894 = _2806;\n                }\n                else\n                {\n                    _2894 = (_2867 - _2834) / _2785;\n                }\n                tau += (_2735 * max(_2894, 0.0f));\n            }\n            result = lerp(result, _418_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _2969);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_418",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_654",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_2255",
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 7,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _295 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _295;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _302 = _160.world_pos;\n    float4 _171 = float4(_302, 1.0f);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -mul(_171, _131_fa_light_vp).z;\n    fa_pre_r0 = float3(_131_fa_light_vp[0].x, _131_fa_light_vp[1].x, _131_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131_fa_light_vp[0].y, _131_fa_light_vp[1].y, _131_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131_fa_light_vp[0].z, _131_fa_light_vp[1].z, _131_fa_light_vp[2].z);\n    gl_Position = mul(_171, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _416 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _416;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _423 = _273.world_pos;\n    float4 _284 = float4(_423, 1.0f);\n    fa_world_pos = _423;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -mul(_284, _136_fa_light_vp).z;\n    fa_pre_r0 = float3(_136_fa_light_vp[0].x, _136_fa_light_vp[1].x, _136_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136_fa_light_vp[0].y, _136_fa_light_vp[1].y, _136_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136_fa_light_vp[0].z, _136_fa_light_vp[1].z, _136_fa_light_vp[2].z);\n    gl_Position = mul(_284, _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
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
