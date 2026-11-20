{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "194db57da3c2e45b061059a5d5aaa1ec99bea4d520978217d5e137fe8b76e503",
  "slang": "hlsl5",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _263 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _263;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_270, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _1554[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\nstatic const LightSample _3387 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, 0 };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _442_fa_camera_pos : packoffset(c0);\n    float4 _442_fa_ambient : packoffset(c1);\n    float4 _442_fa_base_color : packoffset(c2);\n    float4 _442_fa_emissive : packoffset(c3);\n    float4 _442_fa_model_emissive : packoffset(c4);\n    float4 _442_fa_pbr : packoffset(c5);\n    float4 _442_fa_maps : packoffset(c6);\n    float4 _442_fa_fog : packoffset(c7);\n    float4 _442_fa_fog_b : packoffset(c8);\n    float4 _442_fa_fog_c : packoffset(c9);\n    float4 _442_fa_counts : packoffset(c10);\n    float4 _442_fa_env_sky : packoffset(c11);\n    float4 _442_fa_env_horizon : packoffset(c12);\n    float4 _442_fa_time : packoffset(c13);\n    float4 _442_fa_cl_vpx : packoffset(c14);\n    float4 _442_fa_cl_vpy : packoffset(c15);\n    float4 _442_fa_cl_vpw : packoffset(c16);\n    float4 _442_fa_cl_fwd : packoffset(c17);\n    float4 _442_fa_cl_grid : packoffset(c18);\n    float4 _442_fa_cl_info : packoffset(c19);\n    float4 _442_fa_layers_a : packoffset(c20);\n    float4 _442_fa_layers_b : packoffset(c21);\n    float4 _442_fa_layers_c : packoffset(c22);\n    float4 _442_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _678_fa_shadow_mat[4] : packoffset(c0);\n    float4 _678_fa_shadow_rect[4] : packoffset(c16);\n    float4 _678_fa_shadow_info[4] : packoffset(c20);\n    float4 _678_fa_shadow_split : packoffset(c24);\n    float4 _678_fa_shadow_cfg : packoffset(c25);\n    float4 _678_fa_shadow_bias : packoffset(c26);\n    float4 _678_fa_shadow_eye : packoffset(c27);\n    float4 _678_fa_shadow_fwd : packoffset(c28);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _2321_dark : packoffset(c0);\n    float _2321_fa_pad0 : packoffset(c0.y);\n    float _2321_fa_pad1 : packoffset(c0.z);\n    float _2321_fa_pad2 : packoffset(c0.w);\n    float _2321_skyAmount : packoffset(c1);\n    float _2321_fa_pad3 : packoffset(c1.y);\n    float _2321_fa_pad4 : packoffset(c1.z);\n    float _2321_fa_pad5 : packoffset(c1.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _447 = _442_fa_cl_info.x < 0.0f;\n    bool _454;\n    if (!_447)\n    {\n        _454 = _442_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _454 = _447;\n    }\n    bool _462;\n    if (!_454)\n    {\n        _462 = _442_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _462 = _454;\n    }\n    bool _469;\n    if (!_462)\n    {\n        _469 = _442_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _469 = _462;\n    }\n    bool _476;\n    if (!_469)\n    {\n        _476 = _442_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _476 = _469;\n    }\n    if (_476)\n    {\n        return int2(0, 0);\n    }\n    float4 _486 = float4(world_pos, 1.0f);\n    float _493 = dot(_442_fa_cl_vpw, _486);\n    if (!(_493 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _515 = float2(dot(_442_fa_cl_vpx, _486), dot(_442_fa_cl_vpy, _486)) / _493.xx;\n    int _519 = int(_442_fa_cl_grid.x);\n    int _523 = int(_442_fa_cl_grid.y);\n    int param = (int(_442_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_442_fa_cl_fwd.xyz, world_pos) + _442_fa_cl_fwd.w, _442_fa_cl_grid.w) / _442_fa_cl_grid.w) * _442_fa_cl_grid.z)), 0, int(_442_fa_cl_info.y) - 1) * _523) + clamp(int(floor(((_515.y * 0.5f) + 0.5f) * _442_fa_cl_grid.y)), 0, _523 - 1)) * _519)) + clamp(int(floor(((_515.x * 0.5f) + 0.5f) * _442_fa_cl_grid.x)), 0, _519 - 1);\n    float4 _594 = fa_light_texel(param);\n    return int2(int(_594.x), int(_594.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_442_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2104 = fa_cluster_lookup(param);\n    fa_cl_slot = _2104.x;\n    fa_cl_local = _2104.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _2393 = fa_linear_to_srgb(param);\n        c = _2393;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _2401 = fa_srgb_to_linear(param_1);\n            c = _2401;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _205;\n    if (i.front_facing)\n    {\n        _205 = i.world_normal;\n    }\n    else\n    {\n        _205 = -i.world_normal;\n    }\n    float3 _229 = normalize(i.world_tangent.xyz - (_205 * dot(_205, i.world_tangent.xyz)));\n    float3 _257 = normalize(((_229 * m.x) + ((cross(_205, _229) * i.world_tangent.w) * m.y)) + (_205 * m.z));\n    float3 _260;\n    if (i.front_facing)\n    {\n        _260 = _257;\n    }\n    else\n    {\n        _260 = -_257;\n    }\n    return _260;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _442_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2432 = fa_tex_fix(param_2, param_3);\n    float4 _3359 = base_t;\n    _3359.x = _2432.x;\n    _3359.y = _2432.y;\n    _3359.z = _2432.z;\n    base_t = _3359;\n    float4 _2446 = (_3359 * _442_fa_base_color) * i.vertex_color;\n    float3 _3293 = i.world_normal;\n    if (_442_fa_maps.z > 0.5f)\n    {\n        float param_4 = _442_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2478 = fa_tex_fix(param_6, param_7);\n        float3 _2482 = (_2478 * 2.0f) - 1.0f.xxx;\n        float2 _2487 = _2482.xy * _442_fa_maps.x;\n        float3 _3367 = _2482;\n        _3367.x = _2487.x;\n        _3367.y = _2487.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3367;\n        _3293 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _442_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2516 = fa_tex_fix(param_12, param_13);\n    float4 _3370 = mrt;\n    _3370.x = _2516.x;\n    _3370.y = _2516.y;\n    _3370.z = _2516.z;\n    mrt = _3370;\n    float4 _2544 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _442_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _2544.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2556 = fa_tex_fix(param_16, param_17);\n    float param_18 = _442_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2586 = fa_tex_fix(param_20, param_21);\n    float _3298 = _442_fa_layers_a.x;\n    float _3299 = _442_fa_layers_a.y;\n    float _3302 = _442_fa_layers_a.z;\n    float _3301 = _442_fa_layers_b.w;\n    float _3304 = _442_fa_layers_c.x;\n    if (_442_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_442_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _3298 *= _2556.y;\n            _3299 *= _2556.z;\n            _3301 *= _2544.w;\n        }\n        if (_442_fa_layers_c.z > 1.5f)\n        {\n            _3302 *= mrt.x;\n            _3304 *= mrt.w;\n        }\n    }\n    Surface _3323 = { _2446.xyz, _2446.w, _3293, clamp(_442_fa_pbr.x * _2516.z, 0.0f, 1.0f), clamp(_442_fa_pbr.y * _2516.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_442_fa_maps.y * (_2556.x - 1.0f)), _442_fa_emissive.xyz + (_442_fa_model_emissive.xyz * _2586), _3298, _3299, _442_fa_layers_b.xyz, _3301, _3302, _442_fa_layers_a.w, _3304, _442_fa_layers_c.y, _442_fa_layers_d.xyz };\n    return _3323;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return _3387;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_442_fa_cl_info.x) + int(_442_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5f;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _316 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _322 = fa_light_texel(param_1);\n    float _325 = _322.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _331 = _325 < 0.5f;\n    float3 l;\n    if (_331)\n    {\n        l = normalize(_316.xyz);\n    }\n    else\n    {\n        float3 _343 = _316.xyz - world_pos;\n        float _345 = length(_343);\n        dist = _345;\n        l = _343 / max(_345, 9.9999997473787516355514526367188e-05f).xxx;\n        float _360 = _345 / max(_316.w, 0.001000000047497451305389404296875f);\n        float _366 = clamp(1.0f - (_360 * _360), 0.0f, 1.0f);\n        atten = _366 * _366;\n        if (_325 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _380 = fa_light_texel(param_2);\n            float _390 = _380.w;\n            int param_3 = (li * 4) + 3;\n            float4 _396 = fa_light_texel(param_3);\n            float _397 = _396.x;\n            float cos_inner = _397;\n            if (_397 > 1.5f)\n            {\n                cos_inner = lerp(_390, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_390, cos_inner, dot(-l, normalize(_380.xyz)));\n        }\n    }\n    int _428;\n    if (_331)\n    {\n        _428 = 0;\n    }\n    else\n    {\n        _428 = (_325 > 1.5f) ? 2 : 1;\n    }\n    LightSample _3129 = { l, _322.xyz * atten, atten, 1.0f, dist, _428 };\n    return _3129;\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _2216 = n < 0;\n    bool _2223;\n    if (!_2216)\n    {\n        _2223 = n >= fa_light_count();\n    }\n    else\n    {\n        _2223 = _2216;\n    }\n    if (_2223)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _2231 = fa_cl_light(param);\n    bool _2234 = fa_lm.z > 0.5f;\n    bool _2240;\n    if (_2234)\n    {\n        int param_1 = _2231;\n        _2240 = fa_light_baked(param_1);\n    }\n    else\n    {\n        _2240 = _2234;\n    }\n    if (_2240)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _2231;\n    float3 param_3 = i.world_pos;\n    return fa_light_sample(param_2, param_3);\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _668;\n    if (i == 0)\n    {\n        _668 = _678_fa_shadow_split.x;\n    }\n    else\n    {\n        float _684;\n        if (i == 1)\n        {\n            _684 = _678_fa_shadow_split.y;\n        }\n        else\n        {\n            float _692;\n            if (i == 2)\n            {\n                _692 = _678_fa_shadow_split.z;\n            }\n            else\n            {\n                _692 = _678_fa_shadow_split.w;\n            }\n            _684 = _692;\n        }\n        _668 = _684;\n    }\n    return _668;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _656 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_656), sin(_656)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _730 = max(_678_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _735 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _741 = sqrt(1.0f - (_735 * _735));\n    float _749 = min(_741 / max(_735, 0.20000000298023223876953125f), 4.0f);\n    float _754;\n    if (_678_fa_shadow_bias.y > 0.0f)\n    {\n        _754 = _678_fa_shadow_bias.y;\n    }\n    else\n    {\n        _754 = 1.5f * _678_fa_shadow_info[ci].x;\n    }\n    float4 _779 = mul(float4(world + (n * (_754 * _741)), 1.0f), _678_fa_shadow_mat[ci]);\n    float _786 = _779.x;\n    bool _789 = _786 < _678_fa_shadow_rect[ci].x;\n    bool _798;\n    if (!_789)\n    {\n        _798 = _786 > _678_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _798 = _789;\n    }\n    bool _807;\n    if (!_798)\n    {\n        _807 = _779.y < _678_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _807 = _798;\n    }\n    bool _816;\n    if (!_807)\n    {\n        _816 = _779.y > _678_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _816 = _807;\n    }\n    bool _823;\n    if (!_816)\n    {\n        _823 = _779.z > 1.0f;\n    }\n    else\n    {\n        _823 = _816;\n    }\n    if (_823)\n    {\n        return -1.0f;\n    }\n    float _832;\n    if (_678_fa_shadow_bias.x > 0.0f)\n    {\n        _832 = _678_fa_shadow_bias.x;\n    }\n    else\n    {\n        _832 = 1.5f * _678_fa_shadow_info[ci].x;\n    }\n    float _851 = _779.z - ((_832 * (1.0f + (0.5f * _749))) / _730);\n    float _860 = ((_678_fa_shadow_info[ci].x * min(_749, 3.0f)) * 0.5f) / _730;\n    int _869 = int(_678_fa_shadow_cfg.z + 0.5f);\n    if (_869 == 1)\n    {\n        float2 param = _779.xy;\n        float4 param_1 = _678_fa_shadow_rect[ci];\n        float _880 = fa_shadow_depth(param, param_1);\n        return float(_851 <= _880);\n    }\n    float _887 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _890 = _869 == 2;\n    if (_890)\n    {\n        float _904 = clamp(((_678_fa_shadow_cfg.w * _730) * 0.25f) / _678_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _887;\n            float2 _923 = fa_shadow_vogel(param_2, param_3, param_4) * _904;\n            float2 param_5 = _779.xy + (_923 * _678_fa_shadow_bias.zw);\n            float4 param_6 = _678_fa_shadow_rect[ci];\n            float _934 = fa_shadow_depth(param_5, param_6);\n            if (_934 < (_851 - (length(_923) * _860)))\n            {\n                sum += _934;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_851 - (sum / cnt), 0.0f) * _730) * _678_fa_shadow_cfg.w) / _678_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _978 = _890 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _978; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _978;\n        float param_9 = _887;\n        float2 _997 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _779.xy + (_997 * _678_fa_shadow_bias.zw);\n        float4 param_11 = _678_fa_shadow_rect[ci];\n        float _1008 = fa_shadow_depth(param_10, param_11);\n        lit += float((_851 - (length(_997) * _860)) <= _1008);\n    }\n    return lit / float(_978);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_442_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1038 = int(_678_fa_shadow_cfg.x + 0.5f);\n    if (_1038 < 1)\n    {\n        return 1.0f;\n    }\n    float _1054 = dot(world - _678_fa_shadow_eye.xyz, _678_fa_shadow_fwd.xyz);\n    int param = _1038 - 1;\n    if (_1054 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1066 = _1038 > 1;\n    bool _1073;\n    if (_1066)\n    {\n        _1073 = _1054 > _678_fa_shadow_split.x;\n    }\n    else\n    {\n        _1073 = _1066;\n    }\n    if (_1073)\n    {\n        ci = 1;\n    }\n    bool _1077 = _1038 > 2;\n    bool _1084;\n    if (_1077)\n    {\n        _1084 = _1054 > _678_fa_shadow_split.y;\n    }\n    else\n    {\n        _1084 = _1077;\n    }\n    if (_1084)\n    {\n        ci = 2;\n    }\n    bool _1088 = _1038 > 3;\n    bool _1095;\n    if (_1088)\n    {\n        _1095 = _1054 > _678_fa_shadow_split.z;\n    }\n    else\n    {\n        _1095 = _1088;\n    }\n    if (_1095)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1038)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1121 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1121;\n        if (_1121 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_678_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1146;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1146 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1146 = _678_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1165 = _678_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1146, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1176 = clamp((_1054 - (fa_shadow_split_at(param_7) - _1165)) / _1165, 0.0f, 1.0f);\n        if (_1176 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1038)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1197 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1197;\n                if (_1197 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1176);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _2131 = fa_lm.z > 0.5f;\n    bool _2137;\n    if (_2131)\n    {\n        int param = li;\n        _2137 = fa_light_baked(param);\n    }\n    else\n    {\n        _2137 = _2131;\n    }\n    if (_2137)\n    {\n        int param_1 = li;\n        LightSample _3262 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _3262;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _2159 = fa_light_sample(param_2, param_3);\n    float3 _3269 = _2159.direction;\n    float3 _3264 = _2159.color;\n    float _3266 = _2159.shadow;\n    int _3274 = _2159.type;\n    if ((_3274 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _3269;\n        float _2173 = fa_shadow_factor(param_4, param_5);\n        _3266 = _2173;\n        _3264 *= _2173;\n    }\n    LightSample _3281 = { _3269, _3264, _2159.attenuation, _3266, _2159._distance, _3274 };\n    return _3281;\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _2190 = n < 0;\n    bool _2197;\n    if (!_2190)\n    {\n        _2197 = n >= fa_light_count();\n    }\n    else\n    {\n        _2197 = _2190;\n    }\n    if (_2197)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    return fa_light_shadowed(param_1, param_2, param_3);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1479 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _1487 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _1490 = int(_1479);\n    int _1493 = int(_1487);\n    float _1503 = _1487 - float(_1493);\n    int _1559 = (_1490 * 9) + _1493;\n    int _1579 = ((_1490 + 1) * 9) + _1493;\n    return lerp(lerp(_1554[_1559], _1554[_1559 + 1], _1503), lerp(_1554[_1579], _1554[_1579 + 1], _1503), _1479 - float(_1490));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _3130 = false;\n    float _3131 = 1.0f;\n    float _3132 = 1.0f;\n    float _3133 = 1.0f;\n    float _3134 = 0.0f;\n    float _3135 = 0.0f;\n    float _3136 = 0.0f;\n    float _3137 = 0.0f;\n    float _3139 = 1.0f;\n    bool _3140 = false;\n    float3 _3141 = 0.0f.xxx;\n    float _3142 = 1.0f;\n    float _3143 = 1.0f;\n    float _3144 = 1.0f;\n    float _3145 = 0.0f;\n    float _3146 = 0.0f;\n    float3 _3147 = float3(1.0f, 0.0f, 0.0f);\n    float3 _3148 = float3(0.0f, 0.0f, 1.0f);\n    float _3149 = 1.0f;\n    float _3150 = 1.0f;\n    float _1634 = clamp(s.specular, 0.0f, 1.0f);\n    float _1638 = clamp(s.ior, 1.0f, 3.0f);\n    bool _1643 = (_1634 != 1.0f) || (_1638 != 1.5f);\n    bool _1653;\n    if (!_1643)\n    {\n        _1653 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _1653 = _1643;\n    }\n    if (_1653)\n    {\n        float _1661 = (_1638 - 1.0f) / (_1638 + 1.0f);\n        f0 = lerp(min((_1661 * _1661).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _1634, s.albedo, metallic.xxx);\n        _3131 = lerp(_1634, 1.0f, metallic);\n        _3130 = true;\n    }\n    float _1689 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_1689 > 0.0f)\n    {\n        float _1697 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _3134 = _1689;\n        _3135 = _1697;\n        float _1704 = _1697 * _1697;\n        _3136 = _1704;\n        _3137 = _1704 * _1704;\n        float _1716 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _3139 = _1716;\n        _3132 = 1.0f - (_1689 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _1716, 0.0f, 1.0f), 5.0f))));\n        _3130 = true;\n    }\n    float3 _1736 = max(s.sheen_color, 0.0f.xxx);\n    float _1745 = max(_1736.x, max(_1736.y, _1736.z));\n    if (_1745 > 0.0f)\n    {\n        float _1753 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _3140 = true;\n        _3141 = _1736;\n        _3142 = _1753;\n        _3143 = _1753 * _1753;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _1753;\n        float _1770 = fa_sheen_albedo(param, param_1);\n        _3145 = _1770;\n        _3144 = 1.0f - min(_1745 * _1770, 1.0f);\n        _3130 = true;\n    }\n    _3133 = _3132 * _3144;\n    float _1789 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_1789 != 0.0f)\n    {\n        float3 _1804 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _1804;\n        if (dot(_1804, _1804) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _1818 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_1818.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _1818.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _1818.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _1822 = t;\n        float3 _1823 = normalize(_1822);\n        t = _1823;\n        float3 _1848 = normalize((_1823 * cos(s.anisotropy_rotation)) + ((cross(n, _1823) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _3147 = _1848;\n        _3148 = cross(n, _1848);\n        float _1858 = roughness * roughness;\n        float _1864 = lerp(_1858, 1.0f, _1789 * _1789);\n        bool _1866 = _1789 > 0.0f;\n        _3149 = _1866 ? _1864 : _1858;\n        _3150 = _1866 ? _1858 : _1864;\n        _3146 = _1789;\n        _3130 = true;\n    }\n    FaLayers _3172 = { _3130, _3131, _3132, _3133, _3134, _3135, _3136, _3137, i.world_normal, _3139, _3140, _3141, _3142, _3143, _3144, _3145, _3146, _3147, _3148, _3149, _3150 };\n    return _3172;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _1411 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _1414 = _1411.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_1414 * _1414, exp2((-9.27999973297119140625f) * ndv)) * _1414) + _1411.y)) + _1411.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_442_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _442_fa_env_horizon.w).xyz;\n    }\n    float _1334 = rough * rough;\n    float _1364 = 0.60000002384185791015625f * _1334;\n    return lerp(lerp(_442_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_442_fa_env_horizon.xyz, _442_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _1334)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _1364, 0.0500000007450580596923828125f + _1364, d.y).xxx), ((_442_fa_env_sky.xyz + _442_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_1334 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _1899;\n        if (L.aniso >= 0.0f)\n        {\n            _1899 = L.b;\n        }\n        else\n        {\n            _1899 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_1899, v), _1899), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1932 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _1932.x) + (L.f90.xxx * _1932.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _1987 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _1987.x) + _1987.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1453 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1453.x) + _1453.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _2026 = clamp(s.metallic, 0.0f, 1.0f);\n    float _2030 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _2037 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _2026.xxx);\n    float3 f0 = _2037;\n    float3 _2041 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _2041;\n    float3 param_3 = i.view_dir;\n    float param_4 = _2026;\n    float param_5 = _2030;\n    float3 param_6 = _2037;\n    FaLayers _2058 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_2058.on)\n    {\n        FaLayers param_7 = _2058;\n        float3 param_8 = _2041;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _2030;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _2041;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _2030;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0f;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _2278 = dot(fa_light_unshadowed(param, param_1).color, float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));\n        if (_2278 > bestPower)\n        {\n            bestPower = _2278;\n            best = n;\n        }\n    }\n    float3 lit = (_442_fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _2307 = fa_light(param_2, param_3);\n        float _2315;\n        if (dot(s.normal, _2307.direction) > 0.5f)\n        {\n            _2315 = 1.0f;\n        }\n        else\n        {\n            _2315 = _2321_dark;\n        }\n        lit += ((s.albedo * _2307.color) * _2315);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * _2321_skyAmount);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_678_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1221 = int(_678_fa_shadow_cfg.x + 0.5f);\n    float _1231 = dot(world - _678_fa_shadow_eye.xyz, _678_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1236 = _1221 > 0;\n    bool _1245;\n    if (_1236)\n    {\n        int param = _1221 - 1;\n        _1245 = _1231 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1245 = _1236;\n    }\n    if (_1245)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1252 = _1221 > 1;\n        bool _1259;\n        if (_1252)\n        {\n            _1259 = _1231 > _678_fa_shadow_split.x;\n        }\n        else\n        {\n            _1259 = _1252;\n        }\n        if (_1259)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1265 = _1221 > 2;\n        bool _1272;\n        if (_1265)\n        {\n            _1272 = _1231 > _678_fa_shadow_split.y;\n        }\n        else\n        {\n            _1272 = _1265;\n        }\n        if (_1272)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1278 = _1221 > 3;\n        bool _1285;\n        if (_1278)\n        {\n            _1285 = _1231 > _678_fa_shadow_split.z;\n        }\n        else\n        {\n            _1285 = _1278;\n        }\n        if (_1285)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _3004 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3004 = -_3004;\n    }\n    float3 _2707 = normalize(_442_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _3017 = { fa_world_pos, _3004, fa_world_tangent, fa_uv, fa_vertex_color, _2707, gl_FrontFacing };\n    SurfaceInput param_1 = _3017;\n    Surface _2715 = fa_standard_surface(param_1);\n    float3 _3035 = _2715.albedo;\n    float _3036 = _2715.alpha;\n    float3 _3037 = _2715.normal;\n    float _3038 = _2715.metallic;\n    float _3039 = _2715.roughness;\n    float _3040 = _2715.occlusion;\n    float3 _3041 = _2715.emission;\n    float _3042 = _2715.clearcoat;\n    float _3043 = _2715.clearcoat_roughness;\n    float3 _3044 = _2715.sheen_color;\n    float _3045 = _2715.sheen_roughness;\n    float _3046 = _2715.anisotropy;\n    float _3047 = _2715.anisotropy_rotation;\n    float _3048 = _2715.specular;\n    float _3049 = _2715.ior;\n    float3 _3050 = _2715.specular_color;\n    SurfaceInput _3025 = { fa_world_pos, _3004, fa_world_tangent, fa_uv, fa_vertex_color, _2707, gl_FrontFacing };\n    SurfaceInput param_2 = _3025;\n    Surface param_3 = _2715;\n    surface(param_2, param_3);\n    _3035 = param_3.albedo;\n    _3036 = param_3.alpha;\n    _3037 = param_3.normal;\n    _3038 = param_3.metallic;\n    _3039 = param_3.roughness;\n    _3040 = param_3.occlusion;\n    _3041 = param_3.emission;\n    _3042 = param_3.clearcoat;\n    _3043 = param_3.clearcoat_roughness;\n    _3044 = param_3.sheen_color;\n    _3045 = param_3.sheen_roughness;\n    _3046 = param_3.anisotropy;\n    _3047 = param_3.anisotropy_rotation;\n    _3048 = param_3.specular;\n    _3049 = param_3.ior;\n    _3050 = param_3.specular_color;\n    float3 result;\n    if (_442_fa_emissive.w > 0.5f)\n    {\n        result = _3035;\n    }\n    else\n    {\n        float3 _2736 = _3037;\n        float3 _2737 = normalize(_2736);\n        _3037 = _2737;\n        SurfaceInput _3033 = { fa_world_pos, _3004, fa_world_tangent, fa_uv, fa_vertex_color, _2707, gl_FrontFacing };\n        SurfaceInput param_4 = _3033;\n        Surface _3116 = { _3035, _3036, _2737, _3038, _3039, _3040, _3041, _3042, _3043, _3044, _3045, _3046, _3047, _3048, _3049, _3050 };\n        Surface param_5 = _3116;\n        result = lighting(param_4, param_5);\n    }\n    float3 _2752 = result;\n    float3 _2753 = _2752 + _3041;\n    result = _2753;\n    float3 param_6 = _2753;\n    float3 param_7 = fa_world_pos;\n    result = fa_shadow_debug(param_6, param_7);\n    bool _2762 = _442_fa_fog.w > 0.0f;\n    bool _2769;\n    if (!_2762)\n    {\n        _2769 = _442_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2769 = _2762;\n    }\n    if (_2769)\n    {\n        float3 _2778 = fa_world_pos - _442_fa_camera_pos.xyz;\n        float _2784 = dot(_2778, _442_fa_fog_c.xyz);\n        bool _2788 = _442_fa_fog_c.w > 0.5f;\n        float _2789;\n        if (_2788)\n        {\n            _2789 = _2784;\n        }\n        else\n        {\n            _2789 = length(_2778);\n        }\n        float _2801 = _2789 - _442_fa_fog_b.x;\n        if (_2801 > 0.0f)\n        {\n            float _2810 = _442_fa_fog.w * _2801;\n            float tau = _2810 * _2810;\n            if (_442_fa_fog_b.y > 0.0f)\n            {\n                float _2826;\n                if (_2788)\n                {\n                    _2826 = fa_world_pos.y - (_442_fa_fog_c.y * _2784);\n                }\n                else\n                {\n                    _2826 = _442_fa_camera_pos.y;\n                }\n                float _2847 = lerp(_2826, fa_world_pos.y, clamp(_442_fa_fog_b.x / _2789, 0.0f, 1.0f));\n                float _2851 = fa_world_pos.y - _2847;\n                float _2856 = _2847 - _442_fa_fog_b.z;\n                float _2861 = fa_world_pos.y - _442_fa_fog_b.z;\n                bool _2864 = _2856 <= 0.0f;\n                bool _2865 = !_2864;\n                bool _2871;\n                if (_2865)\n                {\n                    _2871 = _442_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2871 = _2864;\n                }\n                float _2872;\n                if (_2871)\n                {\n                    _2872 = _442_fa_fog_b.y;\n                }\n                else\n                {\n                    _2872 = _442_fa_fog_b.y * exp(-min(_442_fa_fog_b.w * _2856, 80.0f));\n                }\n                bool _2899;\n                if (_2865)\n                {\n                    _2899 = _442_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2899 = _2864;\n                }\n                float _2900;\n                if (_2899)\n                {\n                    _2900 = _442_fa_fog_b.y * _2856;\n                }\n                else\n                {\n                    _2900 = (_442_fa_fog_b.y * (1.0f - exp(-min(_442_fa_fog_b.w * _2856, 80.0f)))) / _442_fa_fog_b.w;\n                }\n                bool _2925 = _2861 <= 0.0f;\n                bool _2932;\n                if (!_2925)\n                {\n                    _2932 = _442_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2932 = _2925;\n                }\n                float _2933;\n                if (_2932)\n                {\n                    _2933 = _442_fa_fog_b.y * _2861;\n                }\n                else\n                {\n                    _2933 = (_442_fa_fog_b.y * (1.0f - exp(-min(_442_fa_fog_b.w * _2861, 80.0f)))) / _442_fa_fog_b.w;\n                }\n                float _2960;\n                if (abs(_2851) < 0.001000000047497451305389404296875f)\n                {\n                    _2960 = _2872;\n                }\n                else\n                {\n                    _2960 = (_2933 - _2900) / _2851;\n                }\n                tau += (_2801 * max(_2960, 0.0f));\n            }\n            result = lerp(result, _442_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _3036);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_442",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_678",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_2321",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _384 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _384;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _391 = _273.world_pos;\n    fa_world_pos = _391;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_391, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _1554[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\nstatic const LightSample _3387 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, 0 };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _442_fa_camera_pos : packoffset(c0);\n    float4 _442_fa_ambient : packoffset(c1);\n    float4 _442_fa_base_color : packoffset(c2);\n    float4 _442_fa_emissive : packoffset(c3);\n    float4 _442_fa_model_emissive : packoffset(c4);\n    float4 _442_fa_pbr : packoffset(c5);\n    float4 _442_fa_maps : packoffset(c6);\n    float4 _442_fa_fog : packoffset(c7);\n    float4 _442_fa_fog_b : packoffset(c8);\n    float4 _442_fa_fog_c : packoffset(c9);\n    float4 _442_fa_counts : packoffset(c10);\n    float4 _442_fa_env_sky : packoffset(c11);\n    float4 _442_fa_env_horizon : packoffset(c12);\n    float4 _442_fa_time : packoffset(c13);\n    float4 _442_fa_cl_vpx : packoffset(c14);\n    float4 _442_fa_cl_vpy : packoffset(c15);\n    float4 _442_fa_cl_vpw : packoffset(c16);\n    float4 _442_fa_cl_fwd : packoffset(c17);\n    float4 _442_fa_cl_grid : packoffset(c18);\n    float4 _442_fa_cl_info : packoffset(c19);\n    float4 _442_fa_layers_a : packoffset(c20);\n    float4 _442_fa_layers_b : packoffset(c21);\n    float4 _442_fa_layers_c : packoffset(c22);\n    float4 _442_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _678_fa_shadow_mat[4] : packoffset(c0);\n    float4 _678_fa_shadow_rect[4] : packoffset(c16);\n    float4 _678_fa_shadow_info[4] : packoffset(c20);\n    float4 _678_fa_shadow_split : packoffset(c24);\n    float4 _678_fa_shadow_cfg : packoffset(c25);\n    float4 _678_fa_shadow_bias : packoffset(c26);\n    float4 _678_fa_shadow_eye : packoffset(c27);\n    float4 _678_fa_shadow_fwd : packoffset(c28);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _2321_dark : packoffset(c0);\n    float _2321_fa_pad0 : packoffset(c0.y);\n    float _2321_fa_pad1 : packoffset(c0.z);\n    float _2321_fa_pad2 : packoffset(c0.w);\n    float _2321_skyAmount : packoffset(c1);\n    float _2321_fa_pad3 : packoffset(c1.y);\n    float _2321_fa_pad4 : packoffset(c1.z);\n    float _2321_fa_pad5 : packoffset(c1.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _447 = _442_fa_cl_info.x < 0.0f;\n    bool _454;\n    if (!_447)\n    {\n        _454 = _442_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _454 = _447;\n    }\n    bool _462;\n    if (!_454)\n    {\n        _462 = _442_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _462 = _454;\n    }\n    bool _469;\n    if (!_462)\n    {\n        _469 = _442_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _469 = _462;\n    }\n    bool _476;\n    if (!_469)\n    {\n        _476 = _442_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _476 = _469;\n    }\n    if (_476)\n    {\n        return int2(0, 0);\n    }\n    float4 _486 = float4(world_pos, 1.0f);\n    float _493 = dot(_442_fa_cl_vpw, _486);\n    if (!(_493 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _515 = float2(dot(_442_fa_cl_vpx, _486), dot(_442_fa_cl_vpy, _486)) / _493.xx;\n    int _519 = int(_442_fa_cl_grid.x);\n    int _523 = int(_442_fa_cl_grid.y);\n    int param = (int(_442_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_442_fa_cl_fwd.xyz, world_pos) + _442_fa_cl_fwd.w, _442_fa_cl_grid.w) / _442_fa_cl_grid.w) * _442_fa_cl_grid.z)), 0, int(_442_fa_cl_info.y) - 1) * _523) + clamp(int(floor(((_515.y * 0.5f) + 0.5f) * _442_fa_cl_grid.y)), 0, _523 - 1)) * _519)) + clamp(int(floor(((_515.x * 0.5f) + 0.5f) * _442_fa_cl_grid.x)), 0, _519 - 1);\n    float4 _594 = fa_light_texel(param);\n    return int2(int(_594.x), int(_594.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_442_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2104 = fa_cluster_lookup(param);\n    fa_cl_slot = _2104.x;\n    fa_cl_local = _2104.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _2393 = fa_linear_to_srgb(param);\n        c = _2393;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _2401 = fa_srgb_to_linear(param_1);\n            c = _2401;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _205;\n    if (i.front_facing)\n    {\n        _205 = i.world_normal;\n    }\n    else\n    {\n        _205 = -i.world_normal;\n    }\n    float3 _229 = normalize(i.world_tangent.xyz - (_205 * dot(_205, i.world_tangent.xyz)));\n    float3 _257 = normalize(((_229 * m.x) + ((cross(_205, _229) * i.world_tangent.w) * m.y)) + (_205 * m.z));\n    float3 _260;\n    if (i.front_facing)\n    {\n        _260 = _257;\n    }\n    else\n    {\n        _260 = -_257;\n    }\n    return _260;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _442_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2432 = fa_tex_fix(param_2, param_3);\n    float4 _3359 = base_t;\n    _3359.x = _2432.x;\n    _3359.y = _2432.y;\n    _3359.z = _2432.z;\n    base_t = _3359;\n    float4 _2446 = (_3359 * _442_fa_base_color) * i.vertex_color;\n    float3 _3293 = i.world_normal;\n    if (_442_fa_maps.z > 0.5f)\n    {\n        float param_4 = _442_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2478 = fa_tex_fix(param_6, param_7);\n        float3 _2482 = (_2478 * 2.0f) - 1.0f.xxx;\n        float2 _2487 = _2482.xy * _442_fa_maps.x;\n        float3 _3367 = _2482;\n        _3367.x = _2487.x;\n        _3367.y = _2487.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3367;\n        _3293 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _442_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2516 = fa_tex_fix(param_12, param_13);\n    float4 _3370 = mrt;\n    _3370.x = _2516.x;\n    _3370.y = _2516.y;\n    _3370.z = _2516.z;\n    mrt = _3370;\n    float4 _2544 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _442_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _2544.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2556 = fa_tex_fix(param_16, param_17);\n    float param_18 = _442_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2586 = fa_tex_fix(param_20, param_21);\n    float _3298 = _442_fa_layers_a.x;\n    float _3299 = _442_fa_layers_a.y;\n    float _3302 = _442_fa_layers_a.z;\n    float _3301 = _442_fa_layers_b.w;\n    float _3304 = _442_fa_layers_c.x;\n    if (_442_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_442_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _3298 *= _2556.y;\n            _3299 *= _2556.z;\n            _3301 *= _2544.w;\n        }\n        if (_442_fa_layers_c.z > 1.5f)\n        {\n            _3302 *= mrt.x;\n            _3304 *= mrt.w;\n        }\n    }\n    Surface _3323 = { _2446.xyz, _2446.w, _3293, clamp(_442_fa_pbr.x * _2516.z, 0.0f, 1.0f), clamp(_442_fa_pbr.y * _2516.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_442_fa_maps.y * (_2556.x - 1.0f)), _442_fa_emissive.xyz + (_442_fa_model_emissive.xyz * _2586), _3298, _3299, _442_fa_layers_b.xyz, _3301, _3302, _442_fa_layers_a.w, _3304, _442_fa_layers_c.y, _442_fa_layers_d.xyz };\n    return _3323;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return _3387;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_442_fa_cl_info.x) + int(_442_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5f;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _316 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _322 = fa_light_texel(param_1);\n    float _325 = _322.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _331 = _325 < 0.5f;\n    float3 l;\n    if (_331)\n    {\n        l = normalize(_316.xyz);\n    }\n    else\n    {\n        float3 _343 = _316.xyz - world_pos;\n        float _345 = length(_343);\n        dist = _345;\n        l = _343 / max(_345, 9.9999997473787516355514526367188e-05f).xxx;\n        float _360 = _345 / max(_316.w, 0.001000000047497451305389404296875f);\n        float _366 = clamp(1.0f - (_360 * _360), 0.0f, 1.0f);\n        atten = _366 * _366;\n        if (_325 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _380 = fa_light_texel(param_2);\n            float _390 = _380.w;\n            int param_3 = (li * 4) + 3;\n            float4 _396 = fa_light_texel(param_3);\n            float _397 = _396.x;\n            float cos_inner = _397;\n            if (_397 > 1.5f)\n            {\n                cos_inner = lerp(_390, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_390, cos_inner, dot(-l, normalize(_380.xyz)));\n        }\n    }\n    int _428;\n    if (_331)\n    {\n        _428 = 0;\n    }\n    else\n    {\n        _428 = (_325 > 1.5f) ? 2 : 1;\n    }\n    LightSample _3129 = { l, _322.xyz * atten, atten, 1.0f, dist, _428 };\n    return _3129;\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _2216 = n < 0;\n    bool _2223;\n    if (!_2216)\n    {\n        _2223 = n >= fa_light_count();\n    }\n    else\n    {\n        _2223 = _2216;\n    }\n    if (_2223)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _2231 = fa_cl_light(param);\n    bool _2234 = fa_lm.z > 0.5f;\n    bool _2240;\n    if (_2234)\n    {\n        int param_1 = _2231;\n        _2240 = fa_light_baked(param_1);\n    }\n    else\n    {\n        _2240 = _2234;\n    }\n    if (_2240)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _2231;\n    float3 param_3 = i.world_pos;\n    return fa_light_sample(param_2, param_3);\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _668;\n    if (i == 0)\n    {\n        _668 = _678_fa_shadow_split.x;\n    }\n    else\n    {\n        float _684;\n        if (i == 1)\n        {\n            _684 = _678_fa_shadow_split.y;\n        }\n        else\n        {\n            float _692;\n            if (i == 2)\n            {\n                _692 = _678_fa_shadow_split.z;\n            }\n            else\n            {\n                _692 = _678_fa_shadow_split.w;\n            }\n            _684 = _692;\n        }\n        _668 = _684;\n    }\n    return _668;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _656 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_656), sin(_656)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _730 = max(_678_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _735 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _741 = sqrt(1.0f - (_735 * _735));\n    float _749 = min(_741 / max(_735, 0.20000000298023223876953125f), 4.0f);\n    float _754;\n    if (_678_fa_shadow_bias.y > 0.0f)\n    {\n        _754 = _678_fa_shadow_bias.y;\n    }\n    else\n    {\n        _754 = 1.5f * _678_fa_shadow_info[ci].x;\n    }\n    float4 _779 = mul(float4(world + (n * (_754 * _741)), 1.0f), _678_fa_shadow_mat[ci]);\n    float _786 = _779.x;\n    bool _789 = _786 < _678_fa_shadow_rect[ci].x;\n    bool _798;\n    if (!_789)\n    {\n        _798 = _786 > _678_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _798 = _789;\n    }\n    bool _807;\n    if (!_798)\n    {\n        _807 = _779.y < _678_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _807 = _798;\n    }\n    bool _816;\n    if (!_807)\n    {\n        _816 = _779.y > _678_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _816 = _807;\n    }\n    bool _823;\n    if (!_816)\n    {\n        _823 = _779.z > 1.0f;\n    }\n    else\n    {\n        _823 = _816;\n    }\n    if (_823)\n    {\n        return -1.0f;\n    }\n    float _832;\n    if (_678_fa_shadow_bias.x > 0.0f)\n    {\n        _832 = _678_fa_shadow_bias.x;\n    }\n    else\n    {\n        _832 = 1.5f * _678_fa_shadow_info[ci].x;\n    }\n    float _851 = _779.z - ((_832 * (1.0f + (0.5f * _749))) / _730);\n    float _860 = ((_678_fa_shadow_info[ci].x * min(_749, 3.0f)) * 0.5f) / _730;\n    int _869 = int(_678_fa_shadow_cfg.z + 0.5f);\n    if (_869 == 1)\n    {\n        float2 param = _779.xy;\n        float4 param_1 = _678_fa_shadow_rect[ci];\n        float _880 = fa_shadow_depth(param, param_1);\n        return float(_851 <= _880);\n    }\n    float _887 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _890 = _869 == 2;\n    if (_890)\n    {\n        float _904 = clamp(((_678_fa_shadow_cfg.w * _730) * 0.25f) / _678_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _887;\n            float2 _923 = fa_shadow_vogel(param_2, param_3, param_4) * _904;\n            float2 param_5 = _779.xy + (_923 * _678_fa_shadow_bias.zw);\n            float4 param_6 = _678_fa_shadow_rect[ci];\n            float _934 = fa_shadow_depth(param_5, param_6);\n            if (_934 < (_851 - (length(_923) * _860)))\n            {\n                sum += _934;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_851 - (sum / cnt), 0.0f) * _730) * _678_fa_shadow_cfg.w) / _678_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _978 = _890 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _978; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _978;\n        float param_9 = _887;\n        float2 _997 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _779.xy + (_997 * _678_fa_shadow_bias.zw);\n        float4 param_11 = _678_fa_shadow_rect[ci];\n        float _1008 = fa_shadow_depth(param_10, param_11);\n        lit += float((_851 - (length(_997) * _860)) <= _1008);\n    }\n    return lit / float(_978);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_442_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1038 = int(_678_fa_shadow_cfg.x + 0.5f);\n    if (_1038 < 1)\n    {\n        return 1.0f;\n    }\n    float _1054 = dot(world - _678_fa_shadow_eye.xyz, _678_fa_shadow_fwd.xyz);\n    int param = _1038 - 1;\n    if (_1054 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1066 = _1038 > 1;\n    bool _1073;\n    if (_1066)\n    {\n        _1073 = _1054 > _678_fa_shadow_split.x;\n    }\n    else\n    {\n        _1073 = _1066;\n    }\n    if (_1073)\n    {\n        ci = 1;\n    }\n    bool _1077 = _1038 > 2;\n    bool _1084;\n    if (_1077)\n    {\n        _1084 = _1054 > _678_fa_shadow_split.y;\n    }\n    else\n    {\n        _1084 = _1077;\n    }\n    if (_1084)\n    {\n        ci = 2;\n    }\n    bool _1088 = _1038 > 3;\n    bool _1095;\n    if (_1088)\n    {\n        _1095 = _1054 > _678_fa_shadow_split.z;\n    }\n    else\n    {\n        _1095 = _1088;\n    }\n    if (_1095)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1038)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1121 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1121;\n        if (_1121 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_678_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1146;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1146 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1146 = _678_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1165 = _678_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1146, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1176 = clamp((_1054 - (fa_shadow_split_at(param_7) - _1165)) / _1165, 0.0f, 1.0f);\n        if (_1176 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1038)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1197 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1197;\n                if (_1197 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1176);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _2131 = fa_lm.z > 0.5f;\n    bool _2137;\n    if (_2131)\n    {\n        int param = li;\n        _2137 = fa_light_baked(param);\n    }\n    else\n    {\n        _2137 = _2131;\n    }\n    if (_2137)\n    {\n        int param_1 = li;\n        LightSample _3262 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _3262;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _2159 = fa_light_sample(param_2, param_3);\n    float3 _3269 = _2159.direction;\n    float3 _3264 = _2159.color;\n    float _3266 = _2159.shadow;\n    int _3274 = _2159.type;\n    if ((_3274 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _3269;\n        float _2173 = fa_shadow_factor(param_4, param_5);\n        _3266 = _2173;\n        _3264 *= _2173;\n    }\n    LightSample _3281 = { _3269, _3264, _2159.attenuation, _3266, _2159._distance, _3274 };\n    return _3281;\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _2190 = n < 0;\n    bool _2197;\n    if (!_2190)\n    {\n        _2197 = n >= fa_light_count();\n    }\n    else\n    {\n        _2197 = _2190;\n    }\n    if (_2197)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    return fa_light_shadowed(param_1, param_2, param_3);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1479 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _1487 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _1490 = int(_1479);\n    int _1493 = int(_1487);\n    float _1503 = _1487 - float(_1493);\n    int _1559 = (_1490 * 9) + _1493;\n    int _1579 = ((_1490 + 1) * 9) + _1493;\n    return lerp(lerp(_1554[_1559], _1554[_1559 + 1], _1503), lerp(_1554[_1579], _1554[_1579 + 1], _1503), _1479 - float(_1490));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _3130 = false;\n    float _3131 = 1.0f;\n    float _3132 = 1.0f;\n    float _3133 = 1.0f;\n    float _3134 = 0.0f;\n    float _3135 = 0.0f;\n    float _3136 = 0.0f;\n    float _3137 = 0.0f;\n    float _3139 = 1.0f;\n    bool _3140 = false;\n    float3 _3141 = 0.0f.xxx;\n    float _3142 = 1.0f;\n    float _3143 = 1.0f;\n    float _3144 = 1.0f;\n    float _3145 = 0.0f;\n    float _3146 = 0.0f;\n    float3 _3147 = float3(1.0f, 0.0f, 0.0f);\n    float3 _3148 = float3(0.0f, 0.0f, 1.0f);\n    float _3149 = 1.0f;\n    float _3150 = 1.0f;\n    float _1634 = clamp(s.specular, 0.0f, 1.0f);\n    float _1638 = clamp(s.ior, 1.0f, 3.0f);\n    bool _1643 = (_1634 != 1.0f) || (_1638 != 1.5f);\n    bool _1653;\n    if (!_1643)\n    {\n        _1653 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _1653 = _1643;\n    }\n    if (_1653)\n    {\n        float _1661 = (_1638 - 1.0f) / (_1638 + 1.0f);\n        f0 = lerp(min((_1661 * _1661).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _1634, s.albedo, metallic.xxx);\n        _3131 = lerp(_1634, 1.0f, metallic);\n        _3130 = true;\n    }\n    float _1689 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_1689 > 0.0f)\n    {\n        float _1697 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _3134 = _1689;\n        _3135 = _1697;\n        float _1704 = _1697 * _1697;\n        _3136 = _1704;\n        _3137 = _1704 * _1704;\n        float _1716 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _3139 = _1716;\n        _3132 = 1.0f - (_1689 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _1716, 0.0f, 1.0f), 5.0f))));\n        _3130 = true;\n    }\n    float3 _1736 = max(s.sheen_color, 0.0f.xxx);\n    float _1745 = max(_1736.x, max(_1736.y, _1736.z));\n    if (_1745 > 0.0f)\n    {\n        float _1753 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _3140 = true;\n        _3141 = _1736;\n        _3142 = _1753;\n        _3143 = _1753 * _1753;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _1753;\n        float _1770 = fa_sheen_albedo(param, param_1);\n        _3145 = _1770;\n        _3144 = 1.0f - min(_1745 * _1770, 1.0f);\n        _3130 = true;\n    }\n    _3133 = _3132 * _3144;\n    float _1789 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_1789 != 0.0f)\n    {\n        float3 _1804 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _1804;\n        if (dot(_1804, _1804) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _1818 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_1818.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _1818.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _1818.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _1822 = t;\n        float3 _1823 = normalize(_1822);\n        t = _1823;\n        float3 _1848 = normalize((_1823 * cos(s.anisotropy_rotation)) + ((cross(n, _1823) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _3147 = _1848;\n        _3148 = cross(n, _1848);\n        float _1858 = roughness * roughness;\n        float _1864 = lerp(_1858, 1.0f, _1789 * _1789);\n        bool _1866 = _1789 > 0.0f;\n        _3149 = _1866 ? _1864 : _1858;\n        _3150 = _1866 ? _1858 : _1864;\n        _3146 = _1789;\n        _3130 = true;\n    }\n    FaLayers _3172 = { _3130, _3131, _3132, _3133, _3134, _3135, _3136, _3137, i.world_normal, _3139, _3140, _3141, _3142, _3143, _3144, _3145, _3146, _3147, _3148, _3149, _3150 };\n    return _3172;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _1411 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _1414 = _1411.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_1414 * _1414, exp2((-9.27999973297119140625f) * ndv)) * _1414) + _1411.y)) + _1411.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_442_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _442_fa_env_horizon.w).xyz;\n    }\n    float _1334 = rough * rough;\n    float _1364 = 0.60000002384185791015625f * _1334;\n    return lerp(lerp(_442_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_442_fa_env_horizon.xyz, _442_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _1334)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _1364, 0.0500000007450580596923828125f + _1364, d.y).xxx), ((_442_fa_env_sky.xyz + _442_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_1334 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _1899;\n        if (L.aniso >= 0.0f)\n        {\n            _1899 = L.b;\n        }\n        else\n        {\n            _1899 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_1899, v), _1899), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1932 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _1932.x) + (L.f90.xxx * _1932.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _1987 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _1987.x) + _1987.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1453 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1453.x) + _1453.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _2026 = clamp(s.metallic, 0.0f, 1.0f);\n    float _2030 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _2037 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _2026.xxx);\n    float3 f0 = _2037;\n    float3 _2041 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _2041;\n    float3 param_3 = i.view_dir;\n    float param_4 = _2026;\n    float param_5 = _2030;\n    float3 param_6 = _2037;\n    FaLayers _2058 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_2058.on)\n    {\n        FaLayers param_7 = _2058;\n        float3 param_8 = _2041;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _2030;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _2041;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _2030;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0f;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _2278 = dot(fa_light_unshadowed(param, param_1).color, float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));\n        if (_2278 > bestPower)\n        {\n            bestPower = _2278;\n            best = n;\n        }\n    }\n    float3 lit = (_442_fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _2307 = fa_light(param_2, param_3);\n        float _2315;\n        if (dot(s.normal, _2307.direction) > 0.5f)\n        {\n            _2315 = 1.0f;\n        }\n        else\n        {\n            _2315 = _2321_dark;\n        }\n        lit += ((s.albedo * _2307.color) * _2315);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * _2321_skyAmount);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_678_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1221 = int(_678_fa_shadow_cfg.x + 0.5f);\n    float _1231 = dot(world - _678_fa_shadow_eye.xyz, _678_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1236 = _1221 > 0;\n    bool _1245;\n    if (_1236)\n    {\n        int param = _1221 - 1;\n        _1245 = _1231 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1245 = _1236;\n    }\n    if (_1245)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1252 = _1221 > 1;\n        bool _1259;\n        if (_1252)\n        {\n            _1259 = _1231 > _678_fa_shadow_split.x;\n        }\n        else\n        {\n            _1259 = _1252;\n        }\n        if (_1259)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1265 = _1221 > 2;\n        bool _1272;\n        if (_1265)\n        {\n            _1272 = _1231 > _678_fa_shadow_split.y;\n        }\n        else\n        {\n            _1272 = _1265;\n        }\n        if (_1272)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1278 = _1221 > 3;\n        bool _1285;\n        if (_1278)\n        {\n            _1285 = _1231 > _678_fa_shadow_split.z;\n        }\n        else\n        {\n            _1285 = _1278;\n        }\n        if (_1285)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _3004 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3004 = -_3004;\n    }\n    float3 _2707 = normalize(_442_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _3017 = { fa_world_pos, _3004, fa_world_tangent, fa_uv, fa_vertex_color, _2707, gl_FrontFacing };\n    SurfaceInput param_1 = _3017;\n    Surface _2715 = fa_standard_surface(param_1);\n    float3 _3035 = _2715.albedo;\n    float _3036 = _2715.alpha;\n    float3 _3037 = _2715.normal;\n    float _3038 = _2715.metallic;\n    float _3039 = _2715.roughness;\n    float _3040 = _2715.occlusion;\n    float3 _3041 = _2715.emission;\n    float _3042 = _2715.clearcoat;\n    float _3043 = _2715.clearcoat_roughness;\n    float3 _3044 = _2715.sheen_color;\n    float _3045 = _2715.sheen_roughness;\n    float _3046 = _2715.anisotropy;\n    float _3047 = _2715.anisotropy_rotation;\n    float _3048 = _2715.specular;\n    float _3049 = _2715.ior;\n    float3 _3050 = _2715.specular_color;\n    SurfaceInput _3025 = { fa_world_pos, _3004, fa_world_tangent, fa_uv, fa_vertex_color, _2707, gl_FrontFacing };\n    SurfaceInput param_2 = _3025;\n    Surface param_3 = _2715;\n    surface(param_2, param_3);\n    _3035 = param_3.albedo;\n    _3036 = param_3.alpha;\n    _3037 = param_3.normal;\n    _3038 = param_3.metallic;\n    _3039 = param_3.roughness;\n    _3040 = param_3.occlusion;\n    _3041 = param_3.emission;\n    _3042 = param_3.clearcoat;\n    _3043 = param_3.clearcoat_roughness;\n    _3044 = param_3.sheen_color;\n    _3045 = param_3.sheen_roughness;\n    _3046 = param_3.anisotropy;\n    _3047 = param_3.anisotropy_rotation;\n    _3048 = param_3.specular;\n    _3049 = param_3.ior;\n    _3050 = param_3.specular_color;\n    float3 result;\n    if (_442_fa_emissive.w > 0.5f)\n    {\n        result = _3035;\n    }\n    else\n    {\n        float3 _2736 = _3037;\n        float3 _2737 = normalize(_2736);\n        _3037 = _2737;\n        SurfaceInput _3033 = { fa_world_pos, _3004, fa_world_tangent, fa_uv, fa_vertex_color, _2707, gl_FrontFacing };\n        SurfaceInput param_4 = _3033;\n        Surface _3116 = { _3035, _3036, _2737, _3038, _3039, _3040, _3041, _3042, _3043, _3044, _3045, _3046, _3047, _3048, _3049, _3050 };\n        Surface param_5 = _3116;\n        result = lighting(param_4, param_5);\n    }\n    float3 _2752 = result;\n    float3 _2753 = _2752 + _3041;\n    result = _2753;\n    float3 param_6 = _2753;\n    float3 param_7 = fa_world_pos;\n    result = fa_shadow_debug(param_6, param_7);\n    bool _2762 = _442_fa_fog.w > 0.0f;\n    bool _2769;\n    if (!_2762)\n    {\n        _2769 = _442_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2769 = _2762;\n    }\n    if (_2769)\n    {\n        float3 _2778 = fa_world_pos - _442_fa_camera_pos.xyz;\n        float _2784 = dot(_2778, _442_fa_fog_c.xyz);\n        bool _2788 = _442_fa_fog_c.w > 0.5f;\n        float _2789;\n        if (_2788)\n        {\n            _2789 = _2784;\n        }\n        else\n        {\n            _2789 = length(_2778);\n        }\n        float _2801 = _2789 - _442_fa_fog_b.x;\n        if (_2801 > 0.0f)\n        {\n            float _2810 = _442_fa_fog.w * _2801;\n            float tau = _2810 * _2810;\n            if (_442_fa_fog_b.y > 0.0f)\n            {\n                float _2826;\n                if (_2788)\n                {\n                    _2826 = fa_world_pos.y - (_442_fa_fog_c.y * _2784);\n                }\n                else\n                {\n                    _2826 = _442_fa_camera_pos.y;\n                }\n                float _2847 = lerp(_2826, fa_world_pos.y, clamp(_442_fa_fog_b.x / _2789, 0.0f, 1.0f));\n                float _2851 = fa_world_pos.y - _2847;\n                float _2856 = _2847 - _442_fa_fog_b.z;\n                float _2861 = fa_world_pos.y - _442_fa_fog_b.z;\n                bool _2864 = _2856 <= 0.0f;\n                bool _2865 = !_2864;\n                bool _2871;\n                if (_2865)\n                {\n                    _2871 = _442_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2871 = _2864;\n                }\n                float _2872;\n                if (_2871)\n                {\n                    _2872 = _442_fa_fog_b.y;\n                }\n                else\n                {\n                    _2872 = _442_fa_fog_b.y * exp(-min(_442_fa_fog_b.w * _2856, 80.0f));\n                }\n                bool _2899;\n                if (_2865)\n                {\n                    _2899 = _442_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2899 = _2864;\n                }\n                float _2900;\n                if (_2899)\n                {\n                    _2900 = _442_fa_fog_b.y * _2856;\n                }\n                else\n                {\n                    _2900 = (_442_fa_fog_b.y * (1.0f - exp(-min(_442_fa_fog_b.w * _2856, 80.0f)))) / _442_fa_fog_b.w;\n                }\n                bool _2925 = _2861 <= 0.0f;\n                bool _2932;\n                if (!_2925)\n                {\n                    _2932 = _442_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2932 = _2925;\n                }\n                float _2933;\n                if (_2932)\n                {\n                    _2933 = _442_fa_fog_b.y * _2861;\n                }\n                else\n                {\n                    _2933 = (_442_fa_fog_b.y * (1.0f - exp(-min(_442_fa_fog_b.w * _2861, 80.0f)))) / _442_fa_fog_b.w;\n                }\n                float _2960;\n                if (abs(_2851) < 0.001000000047497451305389404296875f)\n                {\n                    _2960 = _2872;\n                }\n                else\n                {\n                    _2960 = (_2933 - _2900) / _2851;\n                }\n                tau += (_2801 * max(_2960, 0.0f));\n            }\n            result = lerp(result, _442_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _3036);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_442",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_678",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_2321",
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
