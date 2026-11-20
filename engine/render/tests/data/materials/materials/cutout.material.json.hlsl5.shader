{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "63c8ed9ef72f0fba56beb38b3018a9ae9876604a67ae71ca005757f89f9b9e64",
  "slang": "hlsl5",
  "params": [
    "alphaCutoff"
  ],
  "textures": [
    "mask"
  ],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _269 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _269;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _276 = _160.world_pos;\n    fa_world_pos = _276;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_276, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _3486[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _485_fa_camera_pos : packoffset(c0);\n    float4 _485_fa_ambient : packoffset(c1);\n    float4 _485_fa_base_color : packoffset(c2);\n    float4 _485_fa_emissive : packoffset(c3);\n    float4 _485_fa_model_emissive : packoffset(c4);\n    float4 _485_fa_pbr : packoffset(c5);\n    float4 _485_fa_maps : packoffset(c6);\n    float4 _485_fa_fog : packoffset(c7);\n    float4 _485_fa_fog_b : packoffset(c8);\n    float4 _485_fa_fog_c : packoffset(c9);\n    float4 _485_fa_counts : packoffset(c10);\n    float4 _485_fa_env_sky : packoffset(c11);\n    float4 _485_fa_env_horizon : packoffset(c12);\n    float4 _485_fa_time : packoffset(c13);\n    float4 _485_fa_cl_vpx : packoffset(c14);\n    float4 _485_fa_cl_vpy : packoffset(c15);\n    float4 _485_fa_cl_vpw : packoffset(c16);\n    float4 _485_fa_cl_fwd : packoffset(c17);\n    float4 _485_fa_cl_grid : packoffset(c18);\n    float4 _485_fa_cl_info : packoffset(c19);\n    float4 _485_fa_layers_a : packoffset(c20);\n    float4 _485_fa_layers_b : packoffset(c21);\n    float4 _485_fa_layers_c : packoffset(c22);\n    float4 _485_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2192_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2192_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2192_fa_shadow_info[4] : packoffset(c20);\n    float4 _2192_fa_shadow_split : packoffset(c24);\n    float4 _2192_fa_shadow_cfg : packoffset(c25);\n    float4 _2192_fa_shadow_bias : packoffset(c26);\n    float4 _2192_fa_shadow_eye : packoffset(c27);\n    float4 _2192_fa_shadow_fwd : packoffset(c28);\n    float4 _2192_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _5762_alphaCutoff : packoffset(c0);\n    float _5762_fa_pad0 : packoffset(c0.y);\n    float _5762_fa_pad1 : packoffset(c0.z);\n    float _5762_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t9);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t10);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t12);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t7);\nTextureCube<float4> fa_irr_tex : register(t8);\nTexture2D<float4> mask : register(t6);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t11);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1463 = _485_fa_cl_info.x < 0.0f;\n    bool _1470;\n    if (!_1463)\n    {\n        _1470 = _485_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1470 = _1463;\n    }\n    bool _1478;\n    if (!_1470)\n    {\n        _1478 = _485_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1478 = _1470;\n    }\n    bool _1485;\n    if (!_1478)\n    {\n        _1485 = _485_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1485 = _1478;\n    }\n    bool _1492;\n    if (!_1485)\n    {\n        _1492 = _485_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1492 = _1485;\n    }\n    if (_1492)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1502 = float4(world_pos, 1.0f);\n    float _1508 = dot(_485_fa_cl_vpw, _1502);\n    if (!(_1508 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1530 = float2(dot(_485_fa_cl_vpx, _1502), dot(_485_fa_cl_vpy, _1502)) / _1508.xx;\n    int _1534 = int(_485_fa_cl_grid.x);\n    int _1538 = int(_485_fa_cl_grid.y);\n    int param = (int(_485_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_485_fa_cl_fwd.xyz, world_pos) + _485_fa_cl_fwd.w, _485_fa_cl_grid.w) / _485_fa_cl_grid.w) * _485_fa_cl_grid.z)), 0, int(_485_fa_cl_info.y) - 1) * _1538) + clamp(int(floor(((_1530.y * 0.5f) + 0.5f) * _485_fa_cl_grid.y)), 0, _1538 - 1)) * _1534)) + clamp(int(floor(((_1530.x * 0.5f) + 0.5f) * _485_fa_cl_grid.x)), 0, _1534 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1614 = fa_cluster_texel(param);\n    return int2(int(_1614.x), int(_1614.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_485_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4307 = fa_cluster_lookup(param);\n    fa_cl_slot = _4307.x;\n    fa_cl_local = _4307.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _5396 = fa_linear_to_srgb(param);\n        c = _5396;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _5404 = fa_srgb_to_linear(param_1);\n            c = _5404;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _417;\n    if (i.front_facing)\n    {\n        _417 = i.world_normal;\n    }\n    else\n    {\n        _417 = -i.world_normal;\n    }\n    float3 _441 = normalize(i.world_tangent.xyz - (_417 * dot(_417, i.world_tangent.xyz)));\n    float3 _469 = normalize(((_441 * m.x) + ((cross(_417, _441) * i.world_tangent.w) * m.y)) + (_417 * m.z));\n    float3 _472;\n    if (i.front_facing)\n    {\n        _472 = _469;\n    }\n    else\n    {\n        _472 = -_469;\n    }\n    return _472;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _485_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _5435 = fa_tex_fix(param_2, param_3);\n    float4 _6861 = base_t;\n    _6861.x = _5435.x;\n    _6861.y = _5435.y;\n    _6861.z = _5435.z;\n    base_t = _6861;\n    float4 _5449 = (_6861 * _485_fa_base_color) * i.vertex_color;\n    float3 _6699 = i.world_normal;\n    if (_485_fa_maps.z > 0.5f)\n    {\n        float param_4 = _485_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _5481 = fa_tex_fix(param_6, param_7);\n        float3 _5484 = (_5481 * 2.0f) - 1.0f.xxx;\n        float2 _5489 = _5484.xy * _485_fa_maps.x;\n        float3 _6869 = _5484;\n        _6869.x = _5489.x;\n        _6869.y = _5489.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _6869;\n        _6699 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _485_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _5517 = fa_tex_fix(param_12, param_13);\n    float4 _6872 = mrt;\n    _6872.x = _5517.x;\n    _6872.y = _5517.y;\n    _6872.z = _5517.z;\n    mrt = _6872;\n    float4 _5545 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _485_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _5545.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _5556 = fa_tex_fix(param_16, param_17);\n    float param_18 = _485_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _5586 = fa_tex_fix(param_20, param_21);\n    float _6704 = _485_fa_layers_a.x;\n    float _6705 = _485_fa_layers_a.y;\n    float _6708 = _485_fa_layers_a.z;\n    float _6707 = _485_fa_layers_b.w;\n    float _6710 = _485_fa_layers_c.x;\n    if (_485_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_485_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _6704 *= _5556.y;\n            _6705 *= _5556.z;\n            _6707 *= _5545.w;\n        }\n        if (_485_fa_layers_c.z > 1.5f)\n        {\n            _6708 *= mrt.x;\n            _6710 *= mrt.w;\n        }\n    }\n    Surface _6729 = { _5449.xyz, _5449.w, _6699, clamp(_485_fa_pbr.x * _5517.z, 0.0f, 1.0f), clamp(_485_fa_pbr.y * _5517.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_485_fa_maps.y * (_5556.x - 1.0f)), _485_fa_emissive.xyz + (_485_fa_model_emissive.xyz * _5586), _6704, _6705, _485_fa_layers_b.xyz, _6707, _6708, _485_fa_layers_a.w, _6710, _485_fa_layers_c.y, _485_fa_layers_d.xyz };\n    return _6729;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1694 = rect.zw - rect.xy;\n    float2 _1698 = _1694 * atlas;\n    float2 _1702 = ddx * _1698;\n    float2 _1706 = ddy * _1698;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1694), clamp(0.5f * log2(max(max(dot(_1702, _1702), dot(_1706, _1706)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1739 = _485_fa_counts.y < 0.5f;\n    bool _1746;\n    if (!_1739)\n    {\n        _1746 = _485_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1746 = _1739;\n    }\n    if (_1746)\n    {\n        return;\n    }\n    float3 _1752 = ddx(world_pos);\n    float3 _1755 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1759 = fa_cluster_texel(param);\n    int _1763 = int(_1759.w);\n    if (_1763 < 1)\n    {\n        return;\n    }\n    int _1773 = int(_485_fa_counts.y + 0.5f);\n    int param_1 = _1773;\n    float4 _1777 = fa_light_texel(param_1);\n    float2 _1780 = _1777.yz;\n    int _1784 = int(_1777.w);\n    int param_2 = _1773 + 1;\n    float4 _1789 = fa_light_texel(param_2);\n    float _1790 = _1789.x;\n    int _1796 = int(_485_fa_counts.w + 0.5f) - 1;\n    int _1800 = int(_1759.z);\n    float3 _2065;\n    for (int k = 0; k < _1763; k++)\n    {\n        int _1813 = _1800 + k;\n        int param_3 = _1784 + (_1813 >> 2);\n        int _1830 = (_1773 + 2) + (int(fa_light_texel(param_3)[_1813 & 3]) * 7);\n        int param_4 = _1830 + 6;\n        float4 _1835 = fa_light_texel(param_4);\n        if (((int(_1835.w + 0.5f) >> _1796) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1830;\n        float4 _1850 = fa_light_texel(param_5);\n        int param_6 = _1830 + 1;\n        float4 _1855 = fa_light_texel(param_6);\n        int param_7 = _1830 + 2;\n        float4 _1860 = fa_light_texel(param_7);\n        float3 _1863 = _1850.xyz;\n        float _1868 = dot(_1863, world_pos) + _1850.w;\n        float3 _1870 = _1855.xyz;\n        float _1875 = dot(_1870, world_pos) + _1855.w;\n        float3 _1877 = _1860.xyz;\n        float _1882 = dot(_1877, world_pos) + _1860.w;\n        bool _1887 = abs(_1868) > 0.5f;\n        bool _1895;\n        if (!_1887)\n        {\n            _1895 = abs(_1875) > 0.5f;\n        }\n        else\n        {\n            _1895 = _1887;\n        }\n        bool _1903;\n        if (!_1895)\n        {\n            _1903 = abs(_1882) > 0.5f;\n        }\n        else\n        {\n            _1903 = _1895;\n        }\n        if (_1903)\n        {\n            continue;\n        }\n        float _1918 = clamp(dot(geo_normal, normalize(_1877)) * _1835.z, 0.0f, 1.0f);\n        if (_1918 <= 0.0f)\n        {\n            continue;\n        }\n        float _1938 = (clamp((0.5f - abs(_1882)) * 10.0f, 0.0f, 1.0f) * _1918) * _1835.x;\n        float2 _1946 = float2(_1868 + 0.5f, 0.5f - _1875);\n        float2 _1956 = float2(dot(_1863, _1752), dot(_1870, _1752));\n        float2 _1966 = float2(dot(_1863, _1755), dot(_1870, _1755));\n        int param_8 = _1830 + 5;\n        float4 _1971 = fa_light_texel(param_8);\n        int param_9 = _1830 + 3;\n        float4 _1976 = fa_light_texel(param_9);\n        int param_10 = _1830 + 4;\n        float4 _1981 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1971.xyz;\n        bool _1991 = _1976.z > _1976.x;\n        if (_1991)\n        {\n            float4 param_11 = _1976;\n            float2 param_12 = _1946;\n            float2 param_13 = _1780;\n            float2 param_14 = _1956;\n            float2 param_15 = _1966;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1790 > 0.5f) && (_1790 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _2017 = fa_dc_to_linear(param_16);\n                float4 _6779 = tx;\n                _6779.x = _2017.x;\n                _6779.y = _2017.y;\n                _6779.z = _2017.z;\n                tx = _6779;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1938 * tex_a) * _1971.w, 0.0f, 1.0f).xxx);\n        if (_1981.z > _1981.x)\n        {\n            float4 param_17 = _1981;\n            float2 param_18 = _1946;\n            float2 param_19 = _1780;\n            float2 param_20 = _1956;\n            float2 param_21 = _1966;\n            float4 _2061 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1790 > 1.5f)\n            {\n                float3 param_22 = _2061.xyz;\n                float3 _2071 = fa_dc_to_srgb(param_22);\n                _2065 = _2071;\n            }\n            else\n            {\n                _2065 = _2061.xyz;\n            }\n            float3 _2080 = (_2065 * 2.0f) - 1.0f.xxx;\n            float2 _2085 = _2080.xy * _1835.y;\n            float3 _2107 = (normalize(_1863) * _2085.x) + (normalize(_1870) * _2085.y);\n            float3 _2110 = normalize(normal);\n            normal = normalize(lerp(_2110, normalize((_2110 * max(_2080.z, 0.0500000007450580596923828125f)) + (_2107 - (_2110 * dot(_2110, _2107)))), clamp(_1938 * (_1991 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3411 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3419 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3422 = int(_3411);\n    int _3425 = int(_3419);\n    float _3435 = _3419 - float(_3425);\n    int _3491 = (_3422 * 9) + _3425;\n    int _3511 = ((_3422 + 1) * 9) + _3425;\n    return lerp(lerp(_3486[_3491], _3486[_3491 + 1], _3435), lerp(_3486[_3511], _3486[_3511 + 1], _3435), _3411 - float(_3422));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _6622 = false;\n    float _6623 = 1.0f;\n    float _6624 = 1.0f;\n    float _6625 = 1.0f;\n    float _6626 = 0.0f;\n    float _6627 = 0.0f;\n    float _6628 = 0.0f;\n    float _6629 = 0.0f;\n    float _6631 = 1.0f;\n    bool _6632 = false;\n    float3 _6633 = 0.0f.xxx;\n    float _6634 = 1.0f;\n    float _6635 = 1.0f;\n    float _6636 = 1.0f;\n    float _6637 = 0.0f;\n    float _6638 = 0.0f;\n    float3 _6639 = float3(1.0f, 0.0f, 0.0f);\n    float3 _6640 = float3(0.0f, 0.0f, 1.0f);\n    float _6641 = 1.0f;\n    float _6642 = 1.0f;\n    float _3562 = clamp(s.specular, 0.0f, 1.0f);\n    float _3566 = clamp(s.ior, 1.0f, 3.0f);\n    bool _3571 = (_3562 != 1.0f) || (_3566 != 1.5f);\n    bool _3580;\n    if (!_3571)\n    {\n        _3580 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _3580 = _3571;\n    }\n    if (_3580)\n    {\n        float _3588 = (_3566 - 1.0f) / (_3566 + 1.0f);\n        f0 = lerp(min((_3588 * _3588).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _3562, s.albedo, metallic.xxx);\n        _6623 = lerp(_3562, 1.0f, metallic);\n        _6622 = true;\n    }\n    float _3615 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_3615 > 0.0f)\n    {\n        float _3623 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _6626 = _3615;\n        _6627 = _3623;\n        float _3630 = _3623 * _3623;\n        _6628 = _3630;\n        _6629 = _3630 * _3630;\n        float _3642 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _6631 = _3642;\n        _6624 = 1.0f - (_3615 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _3642, 0.0f, 1.0f), 5.0f))));\n        _6622 = true;\n    }\n    float3 _3662 = max(s.sheen_color, 0.0f.xxx);\n    float _3671 = max(_3662.x, max(_3662.y, _3662.z));\n    if (_3671 > 0.0f)\n    {\n        float _3679 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _6632 = true;\n        _6633 = _3662;\n        _6634 = _3679;\n        _6635 = _3679 * _3679;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _3679;\n        float _3696 = fa_sheen_albedo(param, param_1);\n        _6637 = _3696;\n        _6636 = 1.0f - min(_3671 * _3696, 1.0f);\n        _6622 = true;\n    }\n    _6625 = _6624 * _6636;\n    float _3715 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_3715 != 0.0f)\n    {\n        float3 _3730 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _3730;\n        if (dot(_3730, _3730) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _3742 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_3742.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _3742.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _3742.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _3746 = t;\n        float3 _3747 = normalize(_3746);\n        t = _3747;\n        float3 _3772 = normalize((_3747 * cos(s.anisotropy_rotation)) + ((cross(n, _3747) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _6639 = _3772;\n        _6640 = cross(n, _3772);\n        float _3782 = roughness * roughness;\n        float _3788 = lerp(_3782, 1.0f, _3715 * _3715);\n        bool _3790 = _3715 > 0.0f;\n        _6641 = _3790 ? _3788 : _3782;\n        _6642 = _3790 ? _3782 : _3788;\n        _6638 = _3715;\n        _6622 = true;\n    }\n    FaLayers _6664 = { _6622, _6623, _6624, _6625, _6626, _6627, _6628, _6629, i.world_normal, _6631, _6632, _6633, _6634, _6635, _6636, _6637, _6638, _6639, _6640, _6641, _6642 };\n    return _6664;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_485_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _485_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_485_fa_cl_info.x) + int(_485_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_485_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _556_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _556_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _722 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _735 = (c - (ru * hx)) - p;\n        float3 _741 = ru * (2.0f * hx);\n        float _747 = max(dot(_741, _741), 9.9999999392252902907785028219223e-09f);\n        float _751 = dot(_735, _741);\n        float t = clamp((-_751) / _747, 0.0f, 1.0f);\n        if (_722)\n        {\n            float _766 = dot(r, _741);\n            float _772 = _747 - (_766 * _766);\n            if (abs(_772) > (9.9999997473787516355514526367188e-06f * _747))\n            {\n                t = clamp(((dot(r, _735) * _766) - _751) / _772, 0.0f, 1.0f);\n            }\n        }\n        return (p + _735) + (_741 * t);\n    }\n    float3 q = p;\n    float _804 = dot(r, axis);\n    bool _812;\n    if (_722)\n    {\n        _812 = abs(_804) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _812 = _722;\n    }\n    if (_812)\n    {\n        float _822 = dot(c - p, axis) / _804;\n        if (_822 > 0.0f)\n        {\n            q = p + (r * _822);\n        }\n    }\n    float3 _835 = q - c;\n    float2 xy = float2(dot(_835, ru), dot(_835, uu));\n    if (shape > 0.5f)\n    {\n        float _850 = length(xy);\n        if (_850 > hx)\n        {\n            xy *= (hx / _850);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _643 = abs(d);\n    float _645 = _643.x;\n    float _647 = _643.y;\n    bool _648 = _645 >= _647;\n    bool _656;\n    if (_648)\n    {\n        _656 = _645 >= _643.z;\n    }\n    else\n    {\n        _656 = _648;\n    }\n    int _657;\n    if (_656)\n    {\n        _657 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _670;\n        if (_647 >= _643.z)\n        {\n            _670 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _670 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _657 = _670;\n    }\n    return _657;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _596 = dot(d, right);\n    float _600 = dot(d, up);\n    float _611;\n    if (((_596 * _596) + (_600 * _600)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _611 = atan2(_600, _596) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _611 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_611 - floor(_611)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _888 = fa_light_base(param);\n    bool _892 = _485_fa_ambient.w > 4.5f;\n    int param_1 = _888;\n    float4 _896 = fa_light_texel(param_1);\n    int param_2 = _888 + 1;\n    float4 _901 = fa_light_texel(param_2);\n    float _904 = _901.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _916 = _892 && (_904 > 2.5f);\n    fa_light_is_area = _916;\n    bool _918 = _904 < 0.5f;\n    float3 l;\n    if (_918)\n    {\n        l = normalize(_896.xyz);\n        if (_892)\n        {\n            int param_3 = _888 + 6;\n            float4 _932 = fa_light_texel(param_3);\n            if (_932.z > 0.5f)\n            {\n                int param_4 = _888 + 4;\n                float4 _942 = fa_light_texel(param_4);\n                int param_5 = _888 + 5;\n                float4 _947 = fa_light_texel(param_5);\n                float2 param_6 = _932.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _942.xyz) * _942.w, (-dot(world_pos, _947.xyz)) * _947.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _977 = _896.xyz;\n        float3 _979 = _977 - world_pos;\n        float3 to_light = _979;\n        float _982 = length(_979);\n        float reach = _982;\n        bool front = true;\n        if (_916)\n        {\n            int param_8 = _888 + 7;\n            reach = max(_982 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _888 + 4;\n            float4 _1006 = fa_light_texel(param_9);\n            int param_10 = _888 + 5;\n            float4 _1011 = fa_light_texel(param_10);\n            int param_11 = _888 + 6;\n            float4 _1016 = fa_light_texel(param_11);\n            float _1017 = _1016.w;\n            int param_12 = _888 + 2;\n            float3 _1024 = normalize(fa_light_texel(param_12).xyz);\n            bool _1026 = _1017 > 1.5f;\n            bool _1034;\n            if (!_1026)\n            {\n                _1034 = dot(_1024, to_light) < 0.0f;\n            }\n            else\n            {\n                _1034 = _1026;\n            }\n            front = _1034;\n            float3 r = 0.0f.xxx;\n            if (dot(n, n) > 0.5f)\n            {\n                r = reflect(-normalize(_485_fa_camera_pos.xyz - world_pos), normalize(n));\n            }\n            float3 param_13 = _977;\n            float3 param_14 = _1024;\n            float3 param_15 = _1006.xyz;\n            float3 param_16 = _1011.xyz;\n            float param_17 = _1006.w;\n            float param_18 = _1011.w;\n            float param_19 = _1017;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1081 = length(to_light);\n        dist = _1081;\n        l = to_light / max(_1081, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1095 = reach / max(_896.w, 0.001000000047497451305389404296875f);\n        float _1101 = clamp(1.0f - (_1095 * _1095), 0.0f, 1.0f);\n        float _1103;\n        if (front)\n        {\n            _1103 = _1101 * _1101;\n        }\n        else\n        {\n            _1103 = 0.0f;\n        }\n        atten = _1103;\n        bool _1114 = _904 < 2.5f;\n        if ((_904 > 1.5f) && _1114)\n        {\n            int param_22 = _888 + 2;\n            float4 _1122 = fa_light_texel(param_22);\n            float _1132 = _1122.w;\n            int param_23 = _888 + 3;\n            float4 _1137 = fa_light_texel(param_23);\n            float _1138 = _1137.x;\n            float cos_inner = _1138;\n            if (_1138 > 1.5f)\n            {\n                cos_inner = lerp(_1132, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1132, cos_inner, dot(-l, normalize(_1122.xyz)));\n        }\n        if (_892 && (_904 < 1.5f))\n        {\n            int param_24 = _888 + 6;\n            float4 _1162 = fa_light_texel(param_24);\n            if (_1162.z > 0.5f)\n            {\n                float3 _1170 = -to_light;\n                int param_25 = _888 + 4;\n                int param_26 = _888 + 5;\n                float3 _1184 = fa_light_texel(param_25).xyz;\n                float3 _1188 = fa_light_texel(param_26).xyz;\n                float3 _1197 = float3(dot(_1170, _1184), dot(_1170, _1188), dot(_1170, cross(_1184, _1188)));\n                float3 param_27 = _1197;\n                int _1201 = fa_cube_face(param_27);\n                int param_28 = _1201;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1228 = float2(dot(_1197, cross(param_29, param_30)), dot(_1197, param_30)) / max(dot(_1197, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1232 = _1201 / 3;\n                float2 param_31 = _1162.xy + (float2(float(_1201 - (_1232 * 3)), float(_1232)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1228.x), 0.5f - (0.5f * _1228.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _888 + 7;\n            float4 _1262 = fa_light_texel(param_33);\n            if (_1262.z > 0.5f)\n            {\n                int param_34 = _888 + 2;\n                int param_35 = _888 + 4;\n                int param_36 = _888 + 5;\n                float2 param_37 = _1262.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_892 && _1114)\n            {\n                int param_42 = _888 + 6;\n                float4 _1309 = fa_light_texel(param_42);\n                int param_43 = _888 + 7;\n                float4 _1314 = fa_light_texel(param_43);\n                bool _1317 = _1309.z > 0.5f;\n                bool _1324;\n                if (!_1317)\n                {\n                    _1324 = _1314.z > 0.5f;\n                }\n                else\n                {\n                    _1324 = _1317;\n                }\n                if (_1324)\n                {\n                    int param_44 = _888 + 2;\n                    float4 _1331 = fa_light_texel(param_44);\n                    float3 _1335 = normalize(_1331.xyz);\n                    int param_45 = _888 + 4;\n                    float4 _1340 = fa_light_texel(param_45);\n                    int param_46 = _888 + 5;\n                    float4 _1345 = fa_light_texel(param_46);\n                    if (_1317)\n                    {\n                        float3 _1353 = -to_light;\n                        float _1360 = _1331.w;\n                        float _1376 = 0.5f / max(dot(_1353, _1335) * (sqrt(max(1.0f - (_1360 * _1360), 0.0f)) / max(_1360, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1309.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1353, _1340.xyz) * _1376), 0.5f - (dot(_1353, _1345.xyz) * _1376));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1314.z > 0.5f)\n                    {\n                        float2 param_49 = _1314.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1335;\n                        float3 param_52 = _1340.xyz;\n                        float3 param_53 = _1345.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _6610 = _901.xyz * atten;\n    if (_892)\n    {\n        _6610 *= fa_light_tint;\n    }\n    int _1445;\n    if (_918)\n    {\n        _1445 = 0;\n    }\n    else\n    {\n        _1445 = ((_904 > 1.5f) && (_904 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _6621 = { l, _6610, atten, 1.0f, dist, _1445 };\n    return _6621;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2182;\n    if (i == 0)\n    {\n        _2182 = _2192_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2198;\n        if (i == 1)\n        {\n            _2198 = _2192_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2206;\n            if (i == 2)\n            {\n                _2206 = _2192_fa_shadow_split.z;\n            }\n            else\n            {\n                _2206 = _2192_fa_shadow_split.w;\n            }\n            _2198 = _2206;\n        }\n        _2182 = _2198;\n    }\n    return _2182;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2239 = fa_shadow_depth(param, param_1);\n    float _2243;\n    if (conv.x < 0.5f)\n    {\n        _2243 = _2239;\n    }\n    else\n    {\n        _2243 = (conv.y * conv.z) / (conv.z - (_2239 * (conv.z - conv.y)));\n    }\n    return _2243;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2170 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2170), sin(_2170)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2289 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2298;\n        if (k < 0.0f)\n        {\n            _2298 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2298 = k;\n        }\n        float _2318 = clamp((_2298 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2289;\n            float2 _2337 = fa_shadow_vogel(param_3, param_4, param_5) * _2318;\n            float2 param_6 = uv + (_2337 * _2192_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2349 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2349 < (zr - (length(_2337) * plane)))\n            {\n                sum += _2349;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2375 = sum / cnt;\n        float _2385;\n        if (k < 0.0f)\n        {\n            _2385 = (-k) / max(_2375, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2385 = k;\n        }\n        radius = clamp(((max(zr - _2375, 0.0f) * unit) * _2385) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2407 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2407; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2407;\n        float param_11 = _2289;\n        float2 _2426 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2426 * _2192_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2426) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2407);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2468 = max(_2192_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2473 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2479 = sqrt(1.0f - (_2473 * _2473));\n    float _2486 = min(_2479 / max(_2473, 0.20000000298023223876953125f), 4.0f);\n    float _2491;\n    if (_2192_fa_shadow_bias.y > 0.0f)\n    {\n        _2491 = _2192_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2491 = 1.5f * _2192_fa_shadow_info[ci].x;\n    }\n    float4 _2516 = mul(float4(world + (n * (_2491 * _2479)), 1.0f), _2192_fa_shadow_mat[ci]);\n    float _2523 = _2516.x;\n    bool _2526 = _2523 < _2192_fa_shadow_rect[ci].x;\n    bool _2535;\n    if (!_2526)\n    {\n        _2535 = _2523 > _2192_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2535 = _2526;\n    }\n    bool _2544;\n    if (!_2535)\n    {\n        _2544 = _2516.y < _2192_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2544 = _2535;\n    }\n    bool _2553;\n    if (!_2544)\n    {\n        _2553 = _2516.y > _2192_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2553 = _2544;\n    }\n    bool _2560;\n    if (!_2553)\n    {\n        _2560 = _2516.z > 1.0f;\n    }\n    else\n    {\n        _2560 = _2553;\n    }\n    if (_2560)\n    {\n        return -1.0f;\n    }\n    float _2568;\n    if (_2192_fa_shadow_bias.x > 0.0f)\n    {\n        _2568 = _2192_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2568 = 1.5f * _2192_fa_shadow_info[ci].x;\n    }\n    float2 param = _2516.xy;\n    float4 param_1 = _2192_fa_shadow_rect[ci];\n    float param_2 = _2516.z - ((_2568 * (1.0f + (0.5f * _2486))) / _2468);\n    float param_3 = _2192_fa_shadow_info[ci].x;\n    float param_4 = _2468;\n    float param_5 = _2468 * 0.25f;\n    float param_6 = ((_2192_fa_shadow_info[ci].x * min(_2486, 3.0f)) * 0.5f) / _2468;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2192_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2192_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_485_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2956 = int(_2192_fa_shadow_cfg.x + 0.5f);\n    if (_2956 < 1)\n    {\n        return 1.0f;\n    }\n    float _2971 = dot(world - _2192_fa_shadow_eye.xyz, _2192_fa_shadow_fwd.xyz);\n    int param = _2956 - 1;\n    if (_2971 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2983 = _2956 > 1;\n    bool _2990;\n    if (_2983)\n    {\n        _2990 = _2971 > _2192_fa_shadow_split.x;\n    }\n    else\n    {\n        _2990 = _2983;\n    }\n    if (_2990)\n    {\n        ci = 1;\n    }\n    bool _2994 = _2956 > 2;\n    bool _3001;\n    if (_2994)\n    {\n        _3001 = _2971 > _2192_fa_shadow_split.y;\n    }\n    else\n    {\n        _3001 = _2994;\n    }\n    if (_3001)\n    {\n        ci = 2;\n    }\n    bool _3005 = _2956 > 3;\n    bool _3012;\n    if (_3005)\n    {\n        _3012 = _2971 > _2192_fa_shadow_split.z;\n    }\n    else\n    {\n        _3012 = _3005;\n    }\n    if (_3012)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2956)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _3038 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3038;\n        if (_3038 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2192_fa_shadow_cfg.y > 0.0f)\n    {\n        float _3063;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3063 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3063 = _2192_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _3082 = _2192_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3063, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _3093 = clamp((_2971 - (fa_shadow_split_at(param_7) - _3082)) / _3082, 0.0f, 1.0f);\n        if (_3093 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2956)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _3114 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3114;\n                if (_3114 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _3093);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _2626 = _485_fa_pbr.z < 0.5f;\n    bool _2633;\n    if (!_2626)\n    {\n        _2633 = _2192_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2633 = _2626;\n    }\n    if (_2633)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2192_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2646 = fa_light_texel(param);\n    float _2647 = _2646.x;\n    if (_2647 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2656 = int(_2647 + 0.5f);\n    int param_1 = _2656;\n    float4 _2660 = fa_light_texel(param_1);\n    int param_2 = _2656 + 1;\n    float4 _2665 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2668 = _2660.y;\n    if (_2668 > 0.0f)\n    {\n        float _2685 = 1.0f - smoothstep(0.75f * _2668, _2668, length(world - _2192_fa_shadow_eye.xyz));\n        fade = _2685;\n        if (_2685 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2660.x > 1.5f)\n    {\n        int param_3 = li;\n        int param_4 = fa_light_base(param_3);\n        float3 param_5 = world - fa_light_texel(param_4).xyz;\n        face = fa_cube_face(param_5);\n    }\n    int _2714 = (_2656 + 2) + (face * 6);\n    int param_6 = _2714;\n    int param_7 = _2714 + 1;\n    int param_8 = _2714 + 3;\n    float4 _2728 = fa_light_texel(param_8);\n    int param_9 = _2714 + 4;\n    float4 _2733 = fa_light_texel(param_9);\n    int param_10 = _2714 + 5;\n    float4 _2738 = fa_light_texel(param_10);\n    float _2750 = _2738.x * max(dot(_2728, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2755 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2778 = clamp(dot(n, _2728.xyz), -1.0f, 1.0f);\n    int param_11 = li;\n    int param_12 = fa_light_base(param_11);\n    float _2802 = min(sqrt(1.0f - (_2778 * _2778)) / max(abs(dot(n, world - fa_light_texel(param_12).xyz)) / max(dot(_2728, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2805 = _2665.y;\n    float _2807;\n    if (_2805 > 0.0f)\n    {\n        _2807 = _2805;\n    }\n    else\n    {\n        _2807 = 1.5f * _2750;\n    }\n    float4 _2827 = float4(world + (n * (_2807 * sqrt(1.0f - (_2755 * _2755)))), 1.0f);\n    float _2831 = dot(_2728, _2827);\n    float _2834 = _2738.y;\n    if (_2831 < _2834)\n    {\n        return 1.0f;\n    }\n    float2 _2849 = float2(dot(fa_light_texel(param_6), _2827), dot(fa_light_texel(param_7), _2827)) / _2831.xx;\n    float _2851 = _2849.x;\n    bool _2854 = _2851 < _2733.x;\n    bool _2863;\n    if (!_2854)\n    {\n        _2863 = _2851 > _2733.z;\n    }\n    else\n    {\n        _2863 = _2854;\n    }\n    bool _2872;\n    if (!_2863)\n    {\n        _2872 = _2849.y < _2733.y;\n    }\n    else\n    {\n        _2872 = _2863;\n    }\n    bool _2881;\n    if (!_2872)\n    {\n        _2881 = _2849.y > _2733.w;\n    }\n    else\n    {\n        _2881 = _2872;\n    }\n    if (_2881)\n    {\n        return 1.0f;\n    }\n    float _2887 = _2665.x;\n    float _2889;\n    if (_2887 > 0.0f)\n    {\n        _2889 = _2887;\n    }\n    else\n    {\n        _2889 = 1.5f * _2750;\n    }\n    float2 param_13 = _2849;\n    float4 param_14 = _2733;\n    float param_15 = _2831 - (_2889 * (1.0f + (0.5f * _2802)));\n    float param_16 = _2750;\n    float param_17 = 1.0f;\n    float param_18 = _2738.z * 0.25f;\n    float param_19 = (_2750 * min(_2802, 3.0f)) * 0.5f;\n    float3 param_20 = float3(1.0f, _2834, _2738.z);\n    int param_21 = int(_2660.z + 0.5f);\n    float param_22 = _2660.w;\n    return lerp(1.0f, fa_shadow_filter(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _4334 = fa_lm.z > 0.5f;\n    bool _4340;\n    if (_4334)\n    {\n        int param = li;\n        _4340 = fa_light_baked(param);\n    }\n    else\n    {\n        _4340 = _4334;\n    }\n    if (_4340)\n    {\n        int param_1 = li;\n        LightSample _6677 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _6677;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4364 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _6679 = _4364.color;\n    float _6681 = _4364.shadow;\n    if ((_4364.type == 0) && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4364.direction;\n        float _4378 = fa_shadow_factor(param_5, param_6);\n        _6681 = _4378;\n        _6679 *= _4378;\n    }\n    else\n    {\n        bool _4389 = _4364.type != 0;\n        bool _4395;\n        if (_4389)\n        {\n            _4395 = _4364.attenuation > 0.0f;\n        }\n        else\n        {\n            _4395 = _4389;\n        }\n        if (_4395)\n        {\n            int param_7 = li;\n            float3 param_8 = world_pos;\n            float3 param_9 = gn;\n            float3 param_10 = _4364.direction;\n            float _4407 = fa_shadow_local(param_7, param_8, param_9, param_10);\n            _6681 = _4407;\n            _6679 *= _4407;\n        }\n    }\n    LightSample _6696 = { _4364.direction, _6679, _4364.attenuation, _6681, _4364._distance, _4364.type };\n    return _6696;\n}\n\nfloat3 fa_ltc_tangent(float3 n, float3 v)\n{\n    float3 _4447 = v - (n * dot(v, n));\n    float3 t = _4447;\n    float _4451 = dot(_4447, _4447);\n    float l2 = _4451;\n    if (_4451 < 1.0000000133514319600180897396058e-10f)\n    {\n        float3 _4461;\n        if (abs(n.z) < 0.999000012874603271484375f)\n        {\n            _4461 = cross(n, float3(0.0f, 0.0f, 1.0f));\n        }\n        else\n        {\n            _4461 = cross(n, float3(1.0f, 0.0f, 0.0f));\n        }\n        t = _4461;\n        l2 = dot(_4461, _4461);\n    }\n    return t * rsqrt(l2);\n}\n\nfloat3 fa_ltc_local(float3 t1, float3 n, float3 p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nfloat3 fa_ltc_edge_vector(float3 a, float3 b)\n{\n    float _4496 = dot(a, a);\n    float _4500 = dot(b, b);\n    if ((_4496 < 1.0000000195414813782625560981111e-24f) || (_4500 < 1.0000000195414813782625560981111e-24f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _4514 = a * rsqrt(_4496);\n    float3 _4519 = b * rsqrt(_4500);\n    float _4523 = dot(_4514, _4519);\n    float _4526 = abs(_4523);\n    float g = (((((((((((0.0416471660137176513671875f * _4526) - 0.1924748718738555908203125f) * _4526) + 0.4179156124591827392578125f) * _4526) - 0.616057217121124267578125f) * _4526) + 0.777722418308258056640625f) * _4526) - 0.999542415142059326171875f) * _4526) + 1.570791721343994140625f;\n    if (_4523 < 0.0f)\n    {\n        g = (3.1415927410125732421875f * rsqrt(max(1.0f - (_4523 * _4523), 1.0000000116860974230803549289703e-07f))) - g;\n    }\n    return cross(_4514, _4519) * g;\n}\n\nvoid fa_ltc_clip_edge(float3 a, float3 b, inout float3 sum, inout float3 leave, inout float3 enter, inout float2 seen)\n{\n    bool _4583 = a.z > 0.0f;\n    bool _4587 = b.z > 0.0f;\n    if (_4583 && _4587)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_4583 != _4587)\n        {\n            float3 _4622 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _4622.z = 0.0f;\n            if (_4583)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _4622;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _4622;\n                seen.x = 1.0f;\n            }\n            else\n            {\n                float3 param_4 = _4622;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _4622;\n                seen.y = 1.0f;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(float4 abcd, float3 p0, float3 p1, float3 p2, float3 p3)\n{\n    float3 _4671 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _4697 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _4723 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _4749 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = 0.0f.xxx;\n    float3 leave = 0.0f.xxx;\n    float3 enter = 0.0f.xxx;\n    float3 param = _4671;\n    float3 param_1 = _4697;\n    float3 param_2 = 0.0f.xxx;\n    float3 param_3 = 0.0f.xxx;\n    float3 param_4 = 0.0f.xxx;\n    float2 param_5 = 0.0f.xx;\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _4697;\n    float3 param_7 = _4723;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _4723;\n    float3 param_13 = _4749;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _4749;\n    float3 param_19 = _4671;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5f)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875f;\n}\n\nfloat fa_ltc_rect(float4 abcd, float3 center, float3 ex, float3 ey)\n{\n    float4 param = abcd;\n    float3 param_1 = (center - ex) - ey;\n    float3 param_2 = (center + ex) - ey;\n    float3 param_3 = (center + ex) + ey;\n    float3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(float4 m, float shape, float3 pc, float3 ex, float3 ey)\n{\n    if ((shape < 0.5f) || (shape > 1.5f))\n    {\n        float4 param = m;\n        float3 param_1 = pc;\n        float3 param_2 = ex;\n        float3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    float3 _4899 = (pc + (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _4923 = (pc - (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _4939 = (pc - (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float4 param_4 = m;\n    float3 param_5 = _4899;\n    float3 param_6 = (pc + (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_7 = (pc - (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_8 = _4923;\n    float4 param_9 = m;\n    float3 param_10 = _4899;\n    float3 param_11 = _4923;\n    float3 param_12 = (pc - (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    float3 param_13 = _4939;\n    float4 param_14 = m;\n    float3 param_15 = _4899;\n    float3 param_16 = _4939;\n    float3 param_17 = (pc + (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float3 param_18 = (pc + (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nfloat2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((float2(clamp((roughness - 0.0500000007450580596923828125f) * 1.0526316165924072265625f, 0.0f, 1.0f), sqrt(clamp(1.0f - ndv, 0.0f, 1.0f))) * 63.0f) + 0.5f.xx) * 0.015625f.xx;\n}\n\nfloat3 fa_area_shade(int li, float3 world_pos, float3 n, float3 v, float3 diffuse_color, float3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _4997 = fa_light_base(param);\n    int param_1 = _4997;\n    int param_2 = _4997 + 1;\n    int param_3 = _4997 + 2;\n    int param_4 = _4997 + 4;\n    float4 _5019 = fa_light_texel(param_4);\n    int param_5 = _4997 + 5;\n    float4 _5024 = fa_light_texel(param_5);\n    int param_6 = _4997 + 6;\n    float4 _5029 = fa_light_texel(param_6);\n    float _5030 = _5029.w;\n    float3 _5035 = fa_light_texel(param_1).xyz - world_pos;\n    bool _5037 = _5030 < 1.5f;\n    bool _5044;\n    if (_5037)\n    {\n        _5044 = dot(normalize(fa_light_texel(param_3).xyz), _5035) >= 0.0f;\n    }\n    else\n    {\n        _5044 = _5037;\n    }\n    if (_5044)\n    {\n        return 0.0f.xxx;\n    }\n    bool _5053 = (_5030 > 0.5f) && _5037;\n    float _5057 = _5053 ? 1.0539000034332275390625f : 1.0f;\n    float3 _5060 = _5019.xyz;\n    float _5062 = _5019.w;\n    float3 _5068 = _5024.xyz;\n    float _5070 = _5024.w;\n    float3 up = _5068 * (_5070 * _5057);\n    float _5076;\n    if (_5053)\n    {\n        _5076 = (3.1415927410125732421875f * _5062) * _5062;\n    }\n    else\n    {\n        _5076 = (4.0f * _5062) * _5070;\n    }\n    if (_5030 > 1.5f)\n    {\n        float3 _5102 = cross(_5060, -_5035);\n        float3 perp = _5102;\n        float _5106 = dot(_5102, _5102);\n        float3 _5109;\n        if (_5106 > 1.0000000133514319600180897396058e-10f)\n        {\n            _5109 = perp * rsqrt(_5106);\n        }\n        else\n        {\n            _5109 = _5068;\n        }\n        perp = _5109;\n        up = _5109 * _5070;\n    }\n    float _5130 = max(_5076, 9.9999999747524270787835121154785e-07f);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _5140 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _5140;\n    float3 param_10 = n;\n    float3 param_11 = _5035;\n    float3 _5148 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_12 = _5140;\n    float3 param_13 = n;\n    float3 param_14 = _5060 * (_5062 * _5057);\n    float3 _5156 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_15 = _5140;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float3 _5164 = fa_ltc_local(param_15, param_16, param_17);\n    float4 param_18 = float4(1.0f, 0.0f, 0.0f, 1.0f);\n    float param_19 = _5030;\n    float3 param_20 = _5148;\n    float3 param_21 = _5156;\n    float3 param_22 = _5164;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    float2 _5183 = fa_ltc_uv(param_23, param_24) * 64.0f;\n    float2 param_25 = _5183;\n    float2 param_26 = _5183 + float2(64.0f, 0.0f);\n    float4 _5193 = fa_atlas_fetch(param_26);\n    float4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _5030;\n    float3 param_29 = _5148;\n    float3 param_30 = _5156;\n    float3 param_31 = _5164;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _5193.x) + ((f90.xxx - f0) * _5193.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875f * dot(_5035, _5035)) + _5130) / _5130) * window);\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4037 = 1.0f / alpha;\n    return ((2.0f + _4037) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _4037)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat fa_layers_coat(FaLayers L, float3 l, float3 h, float vdh)\n{\n    float _4072 = max(dot(L.nc, l), 0.0f);\n    float _4078 = max(dot(L.nc, h), 0.0f);\n    float _4087 = ((_4078 * _4078) * (L.coat_a2 - 1.0f)) + 1.0f;\n    return (((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _4087) * _4087)) * (0.5f / max(lerp((2.0f * _4072) * L.coat_ndv, _4072 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _4072)) * _4072;\n}\n\nfloat3 fa_area_layers(FaLayers L, int li, float3 world_pos, float3 n, float3 v, float3 l, float3 diffuse_color, float3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    float3 param_2 = n;\n    float3 param_3 = v;\n    float3 param_4 = diffuse_color;\n    float3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _5261;\n    if (L.sheen_on)\n    {\n        _5261 = L.sheen_scale;\n    }\n    else\n    {\n        _5261 = 1.0f;\n    }\n    float3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _5261);\n    float3 _5274 = normalize(l + v);\n    int param_10 = li;\n    float3 _5285 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _5294 = max(dot(n, l), 0.0f);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _5274), 0.0f);\n        float param_13 = _5294;\n        float param_14 = ndv;\n        result += ((L.sheen * _5285) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875f) * step(9.9999997473787516355514526367188e-05f, _5294)) * _5294) * L.keep));\n    }\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_15 = L;\n        float3 param_16 = l;\n        float3 param_17 = _5274;\n        float param_18 = max(dot(v, _5274), 0.0f);\n        result += (_5285 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _3940 = tdh / at;\n    float _3944 = bdh / ab;\n    float _3956 = ((_3940 * _3940) + (_3944 * _3944)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _3956) * _3956);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4136 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4215 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _4215) * _4215);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _4136);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _4136));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_17 = L;\n        float3 param_18 = l;\n        float3 param_19 = h;\n        float param_20 = vdh;\n        result += fa_layers_coat(param_17, param_18, param_19, param_20).xxx;\n    }\n    return result;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3343 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3346 = _3343.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3346 * _3346, exp2((-9.27999973297119140625f) * ndv)) * _3346) + _3343.y)) + _3343.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_485_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _485_fa_env_horizon.w).xyz;\n    }\n    float _3249 = rough * rough;\n    float _3279 = 0.60000002384185791015625f * _3249;\n    return lerp(lerp(_485_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_485_fa_env_horizon.xyz, _485_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3249)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3279, 0.0500000007450580596923828125f + _3279, d.y).xxx), ((_485_fa_env_sky.xyz + _485_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3249 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _3823;\n        if (L.aniso >= 0.0f)\n        {\n            _3823 = L.b;\n        }\n        else\n        {\n            _3823 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_3823, v), _3823), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3856 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _3856.x) + (L.f90.xxx * _3856.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3911 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _3911.x) + _3911.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3385 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3385.x) + _3385.y.xxx);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2192_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3138 = int(_2192_fa_shadow_cfg.x + 0.5f);\n    float _3148 = dot(world - _2192_fa_shadow_eye.xyz, _2192_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3153 = _3138 > 0;\n    bool _3162;\n    if (_3153)\n    {\n        int param = _3138 - 1;\n        _3162 = _3148 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3162 = _3153;\n    }\n    if (_3162)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3168 = _3138 > 1;\n        bool _3175;\n        if (_3168)\n        {\n            _3175 = _3148 > _2192_fa_shadow_split.x;\n        }\n        else\n        {\n            _3175 = _3168;\n        }\n        if (_3175)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3181 = _3138 > 2;\n        bool _3188;\n        if (_3181)\n        {\n            _3188 = _3148 > _2192_fa_shadow_split.y;\n        }\n        else\n        {\n            _3188 = _3181;\n        }\n        if (_3188)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3194 = _3138 > 3;\n        bool _3201;\n        if (_3194)\n        {\n            _3201 = _3148 > _2192_fa_shadow_split.z;\n        }\n        else\n        {\n            _3201 = _3194;\n        }\n        if (_3201)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _6379 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6379 = -_6379;\n    }\n    float3 _5726 = normalize(_485_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _6392 = { fa_world_pos, _6379, fa_world_tangent, fa_uv, fa_vertex_color, _5726, gl_FrontFacing };\n    SurfaceInput param_1 = _6392;\n    Surface _5734 = fa_standard_surface(param_1);\n    float3 _6410 = _5734.albedo;\n    float _6411 = _5734.alpha;\n    float3 _6412 = _5734.normal;\n    float _6413 = _5734.metallic;\n    float _6414 = _5734.roughness;\n    float _6415 = _5734.occlusion;\n    float3 _6416 = _5734.emission;\n    float _6417 = _5734.clearcoat;\n    float _6418 = _5734.clearcoat_roughness;\n    float3 _6419 = _5734.sheen_color;\n    float _6420 = _5734.sheen_roughness;\n    float _6421 = _5734.anisotropy;\n    float _6422 = _5734.anisotropy_rotation;\n    float _6423 = _5734.specular;\n    float _6424 = _5734.ior;\n    float3 _6425 = _5734.specular_color;\n    SurfaceInput _6400 = { fa_world_pos, _6379, fa_world_tangent, fa_uv, fa_vertex_color, _5726, gl_FrontFacing };\n    SurfaceInput param_2 = _6400;\n    Surface param_3 = _5734;\n    surface(param_2, param_3);\n    _6410 = param_3.albedo;\n    _6411 = param_3.alpha;\n    _6412 = param_3.normal;\n    _6413 = param_3.metallic;\n    _6414 = param_3.roughness;\n    _6415 = param_3.occlusion;\n    _6416 = param_3.emission;\n    _6417 = param_3.clearcoat;\n    _6418 = param_3.clearcoat_roughness;\n    _6419 = param_3.sheen_color;\n    _6420 = param_3.sheen_roughness;\n    _6421 = param_3.anisotropy;\n    _6422 = param_3.anisotropy_rotation;\n    _6423 = param_3.specular;\n    _6424 = param_3.ior;\n    _6425 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _6379;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6410 = param_6;\n    _6412 = param_7;\n    if (_6411 < _5762_alphaCutoff)\n    {\n        discard;\n    }\n    float3 result;\n    if (_485_fa_emissive.w > 0.5f)\n    {\n        result = _6410;\n    }\n    else\n    {\n        float3 _5784 = normalize(_6412);\n        float _5791 = clamp(_6413, 0.0f, 1.0f);\n        float _5795 = clamp(_6414, 0.0500000007450580596923828125f, 1.0f);\n        float _5799 = _5795 * _5795;\n        float _5803 = _5799 * _5799;\n        float _5808 = max(dot(_5784, _5726), 9.9999997473787516355514526367188e-05f);\n        float3 _5814 = _6410 * (1.0f - _5791);\n        float3 _5821 = lerp(0.039999999105930328369140625f.xxx, _6410, _5791.xxx);\n        float3 f0 = _5821;\n        SurfaceInput _6408 = { fa_world_pos, _6379, fa_world_tangent, fa_uv, fa_vertex_color, _5726, gl_FrontFacing };\n        SurfaceInput param_8 = _6408;\n        Surface _6491 = { _6410, _6411, _6412, _6413, _6414, _6415, _6416, _6417, _6418, _6419, _6420, _6421, _6422, _6423, _6424, _6425 };\n        Surface param_9 = _6491;\n        float3 param_10 = _5784;\n        float3 param_11 = _5726;\n        float param_12 = _5791;\n        float param_13 = _5795;\n        float3 param_14 = _5821;\n        FaLayers _5837 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _5784;\n        float3 lit = (fa_indirect_diffuse(param_15) * _5814) * _6415;\n        if (_5837.on)\n        {\n            lit *= _5837.base_scale;\n        }\n        int _5859 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5859; ln++)\n        {\n            int param_16 = ln;\n            int _5872 = fa_cl_light(param_16);\n            bool _5875 = fa_lm.z > 0.5f;\n            bool _5881;\n            if (_5875)\n            {\n                int param_17 = _5872;\n                _5881 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _5881 = _5875;\n            }\n            if (_5881)\n            {\n                continue;\n            }\n            int param_18 = _5872;\n            float3 param_19 = fa_world_pos;\n            float3 param_20 = _6379;\n            LightSample _5893 = fa_light_shadowed(param_18, param_19, param_20);\n            float _5901 = max(dot(_5784, _5893.direction), 0.0f);\n            float _5907 = _5893.attenuation * _5893.shadow;\n            float3 _5912 = normalize(_5893.direction + _5726);\n            float _5917 = max(dot(_5784, _5912), 0.0f);\n            float _5922 = max(dot(_5726, _5912), 0.0f);\n            bool _5929;\n            if (fa_light_is_area)\n            {\n                _5929 = !_5837.on;\n            }\n            else\n            {\n                _5929 = fa_light_is_area;\n            }\n            if (_5929)\n            {\n                int param_21 = _5872;\n                float3 param_22 = fa_world_pos;\n                float3 param_23 = _5784;\n                float3 param_24 = _5726;\n                float3 param_25 = _5814;\n                float3 param_26 = f0;\n                float param_27 = 1.0f;\n                float param_28 = _5795;\n                float param_29 = _5808;\n                float param_30 = _5907;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _5837;\n                    int param_32 = _5872;\n                    float3 param_33 = fa_world_pos;\n                    float3 param_34 = _5784;\n                    float3 param_35 = _5726;\n                    float3 param_36 = _5893.direction;\n                    float3 param_37 = _5814;\n                    float3 param_38 = f0;\n                    float param_39 = _5795;\n                    float param_40 = _5808;\n                    float param_41 = _5907;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_5837.on)\n                    {\n                        FaLayers param_42 = _5837;\n                        float3 param_43 = _5814;\n                        float3 param_44 = f0;\n                        float3 param_45 = _5784;\n                        float3 param_46 = _5726;\n                        float3 param_47 = _5893.direction;\n                        float3 param_48 = _5912;\n                        float param_49 = _5901;\n                        float param_50 = _5808;\n                        float param_51 = _5917;\n                        float param_52 = _5922;\n                        float param_53 = _5799;\n                        float param_54 = _5803;\n                        int param_55 = _5872;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _5907));\n                    }\n                    else\n                    {\n                        float _6035 = ((_5917 * _5917) * (_5803 - 1.0f)) + 1.0f;\n                        int param_56 = _5872;\n                        lit += (((_5814 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _5922, 5.0f))) * (((_5803 / ((3.1415927410125732421875f * _6035) * _6035)) * (0.5f / max(lerp((2.0f * _5901) * _5808, _5901 + _5808, _5799), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _5901))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_5901 * _5907));\n                    }\n                }\n            }\n        }\n        if (_5837.on)\n        {\n            FaLayers param_57 = _5837;\n            float3 param_58 = _5784;\n            float3 param_59 = _5726;\n            float3 param_60 = f0;\n            float param_61 = _5795;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _6415);\n        }\n        else\n        {\n            float3 param_62 = _5784;\n            float3 param_63 = _5726;\n            float3 param_64 = f0;\n            float param_65 = _5795;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _6415);\n        }\n        result = lit;\n    }\n    float3 _6130 = result;\n    float3 _6131 = _6130 + _6416;\n    result = _6131;\n    float3 param_66 = _6131;\n    float3 param_67 = fa_world_pos;\n    result = fa_shadow_debug(param_66, param_67);\n    bool _6140 = _485_fa_fog.w > 0.0f;\n    bool _6147;\n    if (!_6140)\n    {\n        _6147 = _485_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _6147 = _6140;\n    }\n    if (_6147)\n    {\n        float3 _6156 = fa_world_pos - _485_fa_camera_pos.xyz;\n        float _6162 = dot(_6156, _485_fa_fog_c.xyz);\n        bool _6166 = _485_fa_fog_c.w > 0.5f;\n        float _6167;\n        if (_6166)\n        {\n            _6167 = _6162;\n        }\n        else\n        {\n            _6167 = length(_6156);\n        }\n        float _6179 = _6167 - _485_fa_fog_b.x;\n        if (_6179 > 0.0f)\n        {\n            float _6188 = _485_fa_fog.w * _6179;\n            float tau = _6188 * _6188;\n            if (_485_fa_fog_b.y > 0.0f)\n            {\n                float _6204;\n                if (_6166)\n                {\n                    _6204 = fa_world_pos.y - (_485_fa_fog_c.y * _6162);\n                }\n                else\n                {\n                    _6204 = _485_fa_camera_pos.y;\n                }\n                float _6225 = lerp(_6204, fa_world_pos.y, clamp(_485_fa_fog_b.x / _6167, 0.0f, 1.0f));\n                float _6229 = fa_world_pos.y - _6225;\n                float _6234 = _6225 - _485_fa_fog_b.z;\n                float _6239 = fa_world_pos.y - _485_fa_fog_b.z;\n                bool _6242 = _6234 <= 0.0f;\n                bool _6243 = !_6242;\n                bool _6249;\n                if (_6243)\n                {\n                    _6249 = _485_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6249 = _6242;\n                }\n                float _6250;\n                if (_6249)\n                {\n                    _6250 = _485_fa_fog_b.y;\n                }\n                else\n                {\n                    _6250 = _485_fa_fog_b.y * exp(-min(_485_fa_fog_b.w * _6234, 80.0f));\n                }\n                bool _6277;\n                if (_6243)\n                {\n                    _6277 = _485_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6277 = _6242;\n                }\n                float _6278;\n                if (_6277)\n                {\n                    _6278 = _485_fa_fog_b.y * _6234;\n                }\n                else\n                {\n                    _6278 = (_485_fa_fog_b.y * (1.0f - exp(-min(_485_fa_fog_b.w * _6234, 80.0f)))) / _485_fa_fog_b.w;\n                }\n                bool _6303 = _6239 <= 0.0f;\n                bool _6310;\n                if (!_6303)\n                {\n                    _6310 = _485_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6310 = _6303;\n                }\n                float _6311;\n                if (_6310)\n                {\n                    _6311 = _485_fa_fog_b.y * _6239;\n                }\n                else\n                {\n                    _6311 = (_485_fa_fog_b.y * (1.0f - exp(-min(_485_fa_fog_b.w * _6239, 80.0f)))) / _485_fa_fog_b.w;\n                }\n                float _6338;\n                if (abs(_6229) < 0.001000000047497451305389404296875f)\n                {\n                    _6338 = _6250;\n                }\n                else\n                {\n                    _6338 = (_6311 - _6278) / _6229;\n                }\n                tau += (_6179 * max(_6338, 0.0f));\n            }\n            result = lerp(result, _485_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _6411);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_485",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2192",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_5762",
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
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 6
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
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float",
              "hlsl_register_t_n": 8
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
              "hlsl_register_t_n": 9
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
              "hlsl_register_t_n": 10
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
              "hlsl_register_t_n": 11
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
              "hlsl_register_t_n": 12
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
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
            "sampler_slot": 10
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10
          },
          {
            "slot": 11,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 12,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _390 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _390;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _397 = _273.world_pos;\n    fa_world_pos = _397;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_397, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _3486[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _485_fa_camera_pos : packoffset(c0);\n    float4 _485_fa_ambient : packoffset(c1);\n    float4 _485_fa_base_color : packoffset(c2);\n    float4 _485_fa_emissive : packoffset(c3);\n    float4 _485_fa_model_emissive : packoffset(c4);\n    float4 _485_fa_pbr : packoffset(c5);\n    float4 _485_fa_maps : packoffset(c6);\n    float4 _485_fa_fog : packoffset(c7);\n    float4 _485_fa_fog_b : packoffset(c8);\n    float4 _485_fa_fog_c : packoffset(c9);\n    float4 _485_fa_counts : packoffset(c10);\n    float4 _485_fa_env_sky : packoffset(c11);\n    float4 _485_fa_env_horizon : packoffset(c12);\n    float4 _485_fa_time : packoffset(c13);\n    float4 _485_fa_cl_vpx : packoffset(c14);\n    float4 _485_fa_cl_vpy : packoffset(c15);\n    float4 _485_fa_cl_vpw : packoffset(c16);\n    float4 _485_fa_cl_fwd : packoffset(c17);\n    float4 _485_fa_cl_grid : packoffset(c18);\n    float4 _485_fa_cl_info : packoffset(c19);\n    float4 _485_fa_layers_a : packoffset(c20);\n    float4 _485_fa_layers_b : packoffset(c21);\n    float4 _485_fa_layers_c : packoffset(c22);\n    float4 _485_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2192_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2192_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2192_fa_shadow_info[4] : packoffset(c20);\n    float4 _2192_fa_shadow_split : packoffset(c24);\n    float4 _2192_fa_shadow_cfg : packoffset(c25);\n    float4 _2192_fa_shadow_bias : packoffset(c26);\n    float4 _2192_fa_shadow_eye : packoffset(c27);\n    float4 _2192_fa_shadow_fwd : packoffset(c28);\n    float4 _2192_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _5762_alphaCutoff : packoffset(c0);\n    float _5762_fa_pad0 : packoffset(c0.y);\n    float _5762_fa_pad1 : packoffset(c0.z);\n    float _5762_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t9);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t10);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t12);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t7);\nTextureCube<float4> fa_irr_tex : register(t8);\nTexture2D<float4> mask : register(t6);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t11);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1463 = _485_fa_cl_info.x < 0.0f;\n    bool _1470;\n    if (!_1463)\n    {\n        _1470 = _485_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1470 = _1463;\n    }\n    bool _1478;\n    if (!_1470)\n    {\n        _1478 = _485_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1478 = _1470;\n    }\n    bool _1485;\n    if (!_1478)\n    {\n        _1485 = _485_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1485 = _1478;\n    }\n    bool _1492;\n    if (!_1485)\n    {\n        _1492 = _485_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1492 = _1485;\n    }\n    if (_1492)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1502 = float4(world_pos, 1.0f);\n    float _1508 = dot(_485_fa_cl_vpw, _1502);\n    if (!(_1508 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1530 = float2(dot(_485_fa_cl_vpx, _1502), dot(_485_fa_cl_vpy, _1502)) / _1508.xx;\n    int _1534 = int(_485_fa_cl_grid.x);\n    int _1538 = int(_485_fa_cl_grid.y);\n    int param = (int(_485_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_485_fa_cl_fwd.xyz, world_pos) + _485_fa_cl_fwd.w, _485_fa_cl_grid.w) / _485_fa_cl_grid.w) * _485_fa_cl_grid.z)), 0, int(_485_fa_cl_info.y) - 1) * _1538) + clamp(int(floor(((_1530.y * 0.5f) + 0.5f) * _485_fa_cl_grid.y)), 0, _1538 - 1)) * _1534)) + clamp(int(floor(((_1530.x * 0.5f) + 0.5f) * _485_fa_cl_grid.x)), 0, _1534 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1614 = fa_cluster_texel(param);\n    return int2(int(_1614.x), int(_1614.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_485_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4307 = fa_cluster_lookup(param);\n    fa_cl_slot = _4307.x;\n    fa_cl_local = _4307.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _5396 = fa_linear_to_srgb(param);\n        c = _5396;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _5404 = fa_srgb_to_linear(param_1);\n            c = _5404;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _417;\n    if (i.front_facing)\n    {\n        _417 = i.world_normal;\n    }\n    else\n    {\n        _417 = -i.world_normal;\n    }\n    float3 _441 = normalize(i.world_tangent.xyz - (_417 * dot(_417, i.world_tangent.xyz)));\n    float3 _469 = normalize(((_441 * m.x) + ((cross(_417, _441) * i.world_tangent.w) * m.y)) + (_417 * m.z));\n    float3 _472;\n    if (i.front_facing)\n    {\n        _472 = _469;\n    }\n    else\n    {\n        _472 = -_469;\n    }\n    return _472;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _485_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _5435 = fa_tex_fix(param_2, param_3);\n    float4 _6861 = base_t;\n    _6861.x = _5435.x;\n    _6861.y = _5435.y;\n    _6861.z = _5435.z;\n    base_t = _6861;\n    float4 _5449 = (_6861 * _485_fa_base_color) * i.vertex_color;\n    float3 _6699 = i.world_normal;\n    if (_485_fa_maps.z > 0.5f)\n    {\n        float param_4 = _485_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _5481 = fa_tex_fix(param_6, param_7);\n        float3 _5484 = (_5481 * 2.0f) - 1.0f.xxx;\n        float2 _5489 = _5484.xy * _485_fa_maps.x;\n        float3 _6869 = _5484;\n        _6869.x = _5489.x;\n        _6869.y = _5489.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _6869;\n        _6699 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _485_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _5517 = fa_tex_fix(param_12, param_13);\n    float4 _6872 = mrt;\n    _6872.x = _5517.x;\n    _6872.y = _5517.y;\n    _6872.z = _5517.z;\n    mrt = _6872;\n    float4 _5545 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _485_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _5545.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _5556 = fa_tex_fix(param_16, param_17);\n    float param_18 = _485_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _5586 = fa_tex_fix(param_20, param_21);\n    float _6704 = _485_fa_layers_a.x;\n    float _6705 = _485_fa_layers_a.y;\n    float _6708 = _485_fa_layers_a.z;\n    float _6707 = _485_fa_layers_b.w;\n    float _6710 = _485_fa_layers_c.x;\n    if (_485_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_485_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _6704 *= _5556.y;\n            _6705 *= _5556.z;\n            _6707 *= _5545.w;\n        }\n        if (_485_fa_layers_c.z > 1.5f)\n        {\n            _6708 *= mrt.x;\n            _6710 *= mrt.w;\n        }\n    }\n    Surface _6729 = { _5449.xyz, _5449.w, _6699, clamp(_485_fa_pbr.x * _5517.z, 0.0f, 1.0f), clamp(_485_fa_pbr.y * _5517.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_485_fa_maps.y * (_5556.x - 1.0f)), _485_fa_emissive.xyz + (_485_fa_model_emissive.xyz * _5586), _6704, _6705, _485_fa_layers_b.xyz, _6707, _6708, _485_fa_layers_a.w, _6710, _485_fa_layers_c.y, _485_fa_layers_d.xyz };\n    return _6729;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1694 = rect.zw - rect.xy;\n    float2 _1698 = _1694 * atlas;\n    float2 _1702 = ddx * _1698;\n    float2 _1706 = ddy * _1698;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1694), clamp(0.5f * log2(max(max(dot(_1702, _1702), dot(_1706, _1706)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1739 = _485_fa_counts.y < 0.5f;\n    bool _1746;\n    if (!_1739)\n    {\n        _1746 = _485_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1746 = _1739;\n    }\n    if (_1746)\n    {\n        return;\n    }\n    float3 _1752 = ddx(world_pos);\n    float3 _1755 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1759 = fa_cluster_texel(param);\n    int _1763 = int(_1759.w);\n    if (_1763 < 1)\n    {\n        return;\n    }\n    int _1773 = int(_485_fa_counts.y + 0.5f);\n    int param_1 = _1773;\n    float4 _1777 = fa_light_texel(param_1);\n    float2 _1780 = _1777.yz;\n    int _1784 = int(_1777.w);\n    int param_2 = _1773 + 1;\n    float4 _1789 = fa_light_texel(param_2);\n    float _1790 = _1789.x;\n    int _1796 = int(_485_fa_counts.w + 0.5f) - 1;\n    int _1800 = int(_1759.z);\n    float3 _2065;\n    for (int k = 0; k < _1763; k++)\n    {\n        int _1813 = _1800 + k;\n        int param_3 = _1784 + (_1813 >> 2);\n        int _1830 = (_1773 + 2) + (int(fa_light_texel(param_3)[_1813 & 3]) * 7);\n        int param_4 = _1830 + 6;\n        float4 _1835 = fa_light_texel(param_4);\n        if (((int(_1835.w + 0.5f) >> _1796) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1830;\n        float4 _1850 = fa_light_texel(param_5);\n        int param_6 = _1830 + 1;\n        float4 _1855 = fa_light_texel(param_6);\n        int param_7 = _1830 + 2;\n        float4 _1860 = fa_light_texel(param_7);\n        float3 _1863 = _1850.xyz;\n        float _1868 = dot(_1863, world_pos) + _1850.w;\n        float3 _1870 = _1855.xyz;\n        float _1875 = dot(_1870, world_pos) + _1855.w;\n        float3 _1877 = _1860.xyz;\n        float _1882 = dot(_1877, world_pos) + _1860.w;\n        bool _1887 = abs(_1868) > 0.5f;\n        bool _1895;\n        if (!_1887)\n        {\n            _1895 = abs(_1875) > 0.5f;\n        }\n        else\n        {\n            _1895 = _1887;\n        }\n        bool _1903;\n        if (!_1895)\n        {\n            _1903 = abs(_1882) > 0.5f;\n        }\n        else\n        {\n            _1903 = _1895;\n        }\n        if (_1903)\n        {\n            continue;\n        }\n        float _1918 = clamp(dot(geo_normal, normalize(_1877)) * _1835.z, 0.0f, 1.0f);\n        if (_1918 <= 0.0f)\n        {\n            continue;\n        }\n        float _1938 = (clamp((0.5f - abs(_1882)) * 10.0f, 0.0f, 1.0f) * _1918) * _1835.x;\n        float2 _1946 = float2(_1868 + 0.5f, 0.5f - _1875);\n        float2 _1956 = float2(dot(_1863, _1752), dot(_1870, _1752));\n        float2 _1966 = float2(dot(_1863, _1755), dot(_1870, _1755));\n        int param_8 = _1830 + 5;\n        float4 _1971 = fa_light_texel(param_8);\n        int param_9 = _1830 + 3;\n        float4 _1976 = fa_light_texel(param_9);\n        int param_10 = _1830 + 4;\n        float4 _1981 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1971.xyz;\n        bool _1991 = _1976.z > _1976.x;\n        if (_1991)\n        {\n            float4 param_11 = _1976;\n            float2 param_12 = _1946;\n            float2 param_13 = _1780;\n            float2 param_14 = _1956;\n            float2 param_15 = _1966;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1790 > 0.5f) && (_1790 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _2017 = fa_dc_to_linear(param_16);\n                float4 _6779 = tx;\n                _6779.x = _2017.x;\n                _6779.y = _2017.y;\n                _6779.z = _2017.z;\n                tx = _6779;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1938 * tex_a) * _1971.w, 0.0f, 1.0f).xxx);\n        if (_1981.z > _1981.x)\n        {\n            float4 param_17 = _1981;\n            float2 param_18 = _1946;\n            float2 param_19 = _1780;\n            float2 param_20 = _1956;\n            float2 param_21 = _1966;\n            float4 _2061 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1790 > 1.5f)\n            {\n                float3 param_22 = _2061.xyz;\n                float3 _2071 = fa_dc_to_srgb(param_22);\n                _2065 = _2071;\n            }\n            else\n            {\n                _2065 = _2061.xyz;\n            }\n            float3 _2080 = (_2065 * 2.0f) - 1.0f.xxx;\n            float2 _2085 = _2080.xy * _1835.y;\n            float3 _2107 = (normalize(_1863) * _2085.x) + (normalize(_1870) * _2085.y);\n            float3 _2110 = normalize(normal);\n            normal = normalize(lerp(_2110, normalize((_2110 * max(_2080.z, 0.0500000007450580596923828125f)) + (_2107 - (_2110 * dot(_2110, _2107)))), clamp(_1938 * (_1991 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3411 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3419 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3422 = int(_3411);\n    int _3425 = int(_3419);\n    float _3435 = _3419 - float(_3425);\n    int _3491 = (_3422 * 9) + _3425;\n    int _3511 = ((_3422 + 1) * 9) + _3425;\n    return lerp(lerp(_3486[_3491], _3486[_3491 + 1], _3435), lerp(_3486[_3511], _3486[_3511 + 1], _3435), _3411 - float(_3422));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _6622 = false;\n    float _6623 = 1.0f;\n    float _6624 = 1.0f;\n    float _6625 = 1.0f;\n    float _6626 = 0.0f;\n    float _6627 = 0.0f;\n    float _6628 = 0.0f;\n    float _6629 = 0.0f;\n    float _6631 = 1.0f;\n    bool _6632 = false;\n    float3 _6633 = 0.0f.xxx;\n    float _6634 = 1.0f;\n    float _6635 = 1.0f;\n    float _6636 = 1.0f;\n    float _6637 = 0.0f;\n    float _6638 = 0.0f;\n    float3 _6639 = float3(1.0f, 0.0f, 0.0f);\n    float3 _6640 = float3(0.0f, 0.0f, 1.0f);\n    float _6641 = 1.0f;\n    float _6642 = 1.0f;\n    float _3562 = clamp(s.specular, 0.0f, 1.0f);\n    float _3566 = clamp(s.ior, 1.0f, 3.0f);\n    bool _3571 = (_3562 != 1.0f) || (_3566 != 1.5f);\n    bool _3580;\n    if (!_3571)\n    {\n        _3580 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _3580 = _3571;\n    }\n    if (_3580)\n    {\n        float _3588 = (_3566 - 1.0f) / (_3566 + 1.0f);\n        f0 = lerp(min((_3588 * _3588).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _3562, s.albedo, metallic.xxx);\n        _6623 = lerp(_3562, 1.0f, metallic);\n        _6622 = true;\n    }\n    float _3615 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_3615 > 0.0f)\n    {\n        float _3623 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _6626 = _3615;\n        _6627 = _3623;\n        float _3630 = _3623 * _3623;\n        _6628 = _3630;\n        _6629 = _3630 * _3630;\n        float _3642 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _6631 = _3642;\n        _6624 = 1.0f - (_3615 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _3642, 0.0f, 1.0f), 5.0f))));\n        _6622 = true;\n    }\n    float3 _3662 = max(s.sheen_color, 0.0f.xxx);\n    float _3671 = max(_3662.x, max(_3662.y, _3662.z));\n    if (_3671 > 0.0f)\n    {\n        float _3679 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _6632 = true;\n        _6633 = _3662;\n        _6634 = _3679;\n        _6635 = _3679 * _3679;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _3679;\n        float _3696 = fa_sheen_albedo(param, param_1);\n        _6637 = _3696;\n        _6636 = 1.0f - min(_3671 * _3696, 1.0f);\n        _6622 = true;\n    }\n    _6625 = _6624 * _6636;\n    float _3715 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_3715 != 0.0f)\n    {\n        float3 _3730 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _3730;\n        if (dot(_3730, _3730) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _3742 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_3742.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _3742.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _3742.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _3746 = t;\n        float3 _3747 = normalize(_3746);\n        t = _3747;\n        float3 _3772 = normalize((_3747 * cos(s.anisotropy_rotation)) + ((cross(n, _3747) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _6639 = _3772;\n        _6640 = cross(n, _3772);\n        float _3782 = roughness * roughness;\n        float _3788 = lerp(_3782, 1.0f, _3715 * _3715);\n        bool _3790 = _3715 > 0.0f;\n        _6641 = _3790 ? _3788 : _3782;\n        _6642 = _3790 ? _3782 : _3788;\n        _6638 = _3715;\n        _6622 = true;\n    }\n    FaLayers _6664 = { _6622, _6623, _6624, _6625, _6626, _6627, _6628, _6629, i.world_normal, _6631, _6632, _6633, _6634, _6635, _6636, _6637, _6638, _6639, _6640, _6641, _6642 };\n    return _6664;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_485_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _485_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_485_fa_cl_info.x) + int(_485_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_485_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _556_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _556_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _722 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _735 = (c - (ru * hx)) - p;\n        float3 _741 = ru * (2.0f * hx);\n        float _747 = max(dot(_741, _741), 9.9999999392252902907785028219223e-09f);\n        float _751 = dot(_735, _741);\n        float t = clamp((-_751) / _747, 0.0f, 1.0f);\n        if (_722)\n        {\n            float _766 = dot(r, _741);\n            float _772 = _747 - (_766 * _766);\n            if (abs(_772) > (9.9999997473787516355514526367188e-06f * _747))\n            {\n                t = clamp(((dot(r, _735) * _766) - _751) / _772, 0.0f, 1.0f);\n            }\n        }\n        return (p + _735) + (_741 * t);\n    }\n    float3 q = p;\n    float _804 = dot(r, axis);\n    bool _812;\n    if (_722)\n    {\n        _812 = abs(_804) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _812 = _722;\n    }\n    if (_812)\n    {\n        float _822 = dot(c - p, axis) / _804;\n        if (_822 > 0.0f)\n        {\n            q = p + (r * _822);\n        }\n    }\n    float3 _835 = q - c;\n    float2 xy = float2(dot(_835, ru), dot(_835, uu));\n    if (shape > 0.5f)\n    {\n        float _850 = length(xy);\n        if (_850 > hx)\n        {\n            xy *= (hx / _850);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _643 = abs(d);\n    float _645 = _643.x;\n    float _647 = _643.y;\n    bool _648 = _645 >= _647;\n    bool _656;\n    if (_648)\n    {\n        _656 = _645 >= _643.z;\n    }\n    else\n    {\n        _656 = _648;\n    }\n    int _657;\n    if (_656)\n    {\n        _657 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _670;\n        if (_647 >= _643.z)\n        {\n            _670 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _670 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _657 = _670;\n    }\n    return _657;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _596 = dot(d, right);\n    float _600 = dot(d, up);\n    float _611;\n    if (((_596 * _596) + (_600 * _600)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _611 = atan2(_600, _596) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _611 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_611 - floor(_611)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _888 = fa_light_base(param);\n    bool _892 = _485_fa_ambient.w > 4.5f;\n    int param_1 = _888;\n    float4 _896 = fa_light_texel(param_1);\n    int param_2 = _888 + 1;\n    float4 _901 = fa_light_texel(param_2);\n    float _904 = _901.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _916 = _892 && (_904 > 2.5f);\n    fa_light_is_area = _916;\n    bool _918 = _904 < 0.5f;\n    float3 l;\n    if (_918)\n    {\n        l = normalize(_896.xyz);\n        if (_892)\n        {\n            int param_3 = _888 + 6;\n            float4 _932 = fa_light_texel(param_3);\n            if (_932.z > 0.5f)\n            {\n                int param_4 = _888 + 4;\n                float4 _942 = fa_light_texel(param_4);\n                int param_5 = _888 + 5;\n                float4 _947 = fa_light_texel(param_5);\n                float2 param_6 = _932.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _942.xyz) * _942.w, (-dot(world_pos, _947.xyz)) * _947.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _977 = _896.xyz;\n        float3 _979 = _977 - world_pos;\n        float3 to_light = _979;\n        float _982 = length(_979);\n        float reach = _982;\n        bool front = true;\n        if (_916)\n        {\n            int param_8 = _888 + 7;\n            reach = max(_982 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _888 + 4;\n            float4 _1006 = fa_light_texel(param_9);\n            int param_10 = _888 + 5;\n            float4 _1011 = fa_light_texel(param_10);\n            int param_11 = _888 + 6;\n            float4 _1016 = fa_light_texel(param_11);\n            float _1017 = _1016.w;\n            int param_12 = _888 + 2;\n            float3 _1024 = normalize(fa_light_texel(param_12).xyz);\n            bool _1026 = _1017 > 1.5f;\n            bool _1034;\n            if (!_1026)\n            {\n                _1034 = dot(_1024, to_light) < 0.0f;\n            }\n            else\n            {\n                _1034 = _1026;\n            }\n            front = _1034;\n            float3 r = 0.0f.xxx;\n            if (dot(n, n) > 0.5f)\n            {\n                r = reflect(-normalize(_485_fa_camera_pos.xyz - world_pos), normalize(n));\n            }\n            float3 param_13 = _977;\n            float3 param_14 = _1024;\n            float3 param_15 = _1006.xyz;\n            float3 param_16 = _1011.xyz;\n            float param_17 = _1006.w;\n            float param_18 = _1011.w;\n            float param_19 = _1017;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1081 = length(to_light);\n        dist = _1081;\n        l = to_light / max(_1081, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1095 = reach / max(_896.w, 0.001000000047497451305389404296875f);\n        float _1101 = clamp(1.0f - (_1095 * _1095), 0.0f, 1.0f);\n        float _1103;\n        if (front)\n        {\n            _1103 = _1101 * _1101;\n        }\n        else\n        {\n            _1103 = 0.0f;\n        }\n        atten = _1103;\n        bool _1114 = _904 < 2.5f;\n        if ((_904 > 1.5f) && _1114)\n        {\n            int param_22 = _888 + 2;\n            float4 _1122 = fa_light_texel(param_22);\n            float _1132 = _1122.w;\n            int param_23 = _888 + 3;\n            float4 _1137 = fa_light_texel(param_23);\n            float _1138 = _1137.x;\n            float cos_inner = _1138;\n            if (_1138 > 1.5f)\n            {\n                cos_inner = lerp(_1132, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1132, cos_inner, dot(-l, normalize(_1122.xyz)));\n        }\n        if (_892 && (_904 < 1.5f))\n        {\n            int param_24 = _888 + 6;\n            float4 _1162 = fa_light_texel(param_24);\n            if (_1162.z > 0.5f)\n            {\n                float3 _1170 = -to_light;\n                int param_25 = _888 + 4;\n                int param_26 = _888 + 5;\n                float3 _1184 = fa_light_texel(param_25).xyz;\n                float3 _1188 = fa_light_texel(param_26).xyz;\n                float3 _1197 = float3(dot(_1170, _1184), dot(_1170, _1188), dot(_1170, cross(_1184, _1188)));\n                float3 param_27 = _1197;\n                int _1201 = fa_cube_face(param_27);\n                int param_28 = _1201;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1228 = float2(dot(_1197, cross(param_29, param_30)), dot(_1197, param_30)) / max(dot(_1197, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1232 = _1201 / 3;\n                float2 param_31 = _1162.xy + (float2(float(_1201 - (_1232 * 3)), float(_1232)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1228.x), 0.5f - (0.5f * _1228.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _888 + 7;\n            float4 _1262 = fa_light_texel(param_33);\n            if (_1262.z > 0.5f)\n            {\n                int param_34 = _888 + 2;\n                int param_35 = _888 + 4;\n                int param_36 = _888 + 5;\n                float2 param_37 = _1262.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_892 && _1114)\n            {\n                int param_42 = _888 + 6;\n                float4 _1309 = fa_light_texel(param_42);\n                int param_43 = _888 + 7;\n                float4 _1314 = fa_light_texel(param_43);\n                bool _1317 = _1309.z > 0.5f;\n                bool _1324;\n                if (!_1317)\n                {\n                    _1324 = _1314.z > 0.5f;\n                }\n                else\n                {\n                    _1324 = _1317;\n                }\n                if (_1324)\n                {\n                    int param_44 = _888 + 2;\n                    float4 _1331 = fa_light_texel(param_44);\n                    float3 _1335 = normalize(_1331.xyz);\n                    int param_45 = _888 + 4;\n                    float4 _1340 = fa_light_texel(param_45);\n                    int param_46 = _888 + 5;\n                    float4 _1345 = fa_light_texel(param_46);\n                    if (_1317)\n                    {\n                        float3 _1353 = -to_light;\n                        float _1360 = _1331.w;\n                        float _1376 = 0.5f / max(dot(_1353, _1335) * (sqrt(max(1.0f - (_1360 * _1360), 0.0f)) / max(_1360, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1309.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1353, _1340.xyz) * _1376), 0.5f - (dot(_1353, _1345.xyz) * _1376));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1314.z > 0.5f)\n                    {\n                        float2 param_49 = _1314.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1335;\n                        float3 param_52 = _1340.xyz;\n                        float3 param_53 = _1345.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _6610 = _901.xyz * atten;\n    if (_892)\n    {\n        _6610 *= fa_light_tint;\n    }\n    int _1445;\n    if (_918)\n    {\n        _1445 = 0;\n    }\n    else\n    {\n        _1445 = ((_904 > 1.5f) && (_904 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _6621 = { l, _6610, atten, 1.0f, dist, _1445 };\n    return _6621;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2182;\n    if (i == 0)\n    {\n        _2182 = _2192_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2198;\n        if (i == 1)\n        {\n            _2198 = _2192_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2206;\n            if (i == 2)\n            {\n                _2206 = _2192_fa_shadow_split.z;\n            }\n            else\n            {\n                _2206 = _2192_fa_shadow_split.w;\n            }\n            _2198 = _2206;\n        }\n        _2182 = _2198;\n    }\n    return _2182;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2239 = fa_shadow_depth(param, param_1);\n    float _2243;\n    if (conv.x < 0.5f)\n    {\n        _2243 = _2239;\n    }\n    else\n    {\n        _2243 = (conv.y * conv.z) / (conv.z - (_2239 * (conv.z - conv.y)));\n    }\n    return _2243;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2170 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2170), sin(_2170)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2289 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2298;\n        if (k < 0.0f)\n        {\n            _2298 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2298 = k;\n        }\n        float _2318 = clamp((_2298 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2289;\n            float2 _2337 = fa_shadow_vogel(param_3, param_4, param_5) * _2318;\n            float2 param_6 = uv + (_2337 * _2192_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2349 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2349 < (zr - (length(_2337) * plane)))\n            {\n                sum += _2349;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2375 = sum / cnt;\n        float _2385;\n        if (k < 0.0f)\n        {\n            _2385 = (-k) / max(_2375, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2385 = k;\n        }\n        radius = clamp(((max(zr - _2375, 0.0f) * unit) * _2385) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2407 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2407; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2407;\n        float param_11 = _2289;\n        float2 _2426 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2426 * _2192_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2426) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2407);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2468 = max(_2192_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2473 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2479 = sqrt(1.0f - (_2473 * _2473));\n    float _2486 = min(_2479 / max(_2473, 0.20000000298023223876953125f), 4.0f);\n    float _2491;\n    if (_2192_fa_shadow_bias.y > 0.0f)\n    {\n        _2491 = _2192_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2491 = 1.5f * _2192_fa_shadow_info[ci].x;\n    }\n    float4 _2516 = mul(float4(world + (n * (_2491 * _2479)), 1.0f), _2192_fa_shadow_mat[ci]);\n    float _2523 = _2516.x;\n    bool _2526 = _2523 < _2192_fa_shadow_rect[ci].x;\n    bool _2535;\n    if (!_2526)\n    {\n        _2535 = _2523 > _2192_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2535 = _2526;\n    }\n    bool _2544;\n    if (!_2535)\n    {\n        _2544 = _2516.y < _2192_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2544 = _2535;\n    }\n    bool _2553;\n    if (!_2544)\n    {\n        _2553 = _2516.y > _2192_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2553 = _2544;\n    }\n    bool _2560;\n    if (!_2553)\n    {\n        _2560 = _2516.z > 1.0f;\n    }\n    else\n    {\n        _2560 = _2553;\n    }\n    if (_2560)\n    {\n        return -1.0f;\n    }\n    float _2568;\n    if (_2192_fa_shadow_bias.x > 0.0f)\n    {\n        _2568 = _2192_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2568 = 1.5f * _2192_fa_shadow_info[ci].x;\n    }\n    float2 param = _2516.xy;\n    float4 param_1 = _2192_fa_shadow_rect[ci];\n    float param_2 = _2516.z - ((_2568 * (1.0f + (0.5f * _2486))) / _2468);\n    float param_3 = _2192_fa_shadow_info[ci].x;\n    float param_4 = _2468;\n    float param_5 = _2468 * 0.25f;\n    float param_6 = ((_2192_fa_shadow_info[ci].x * min(_2486, 3.0f)) * 0.5f) / _2468;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2192_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2192_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_485_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2956 = int(_2192_fa_shadow_cfg.x + 0.5f);\n    if (_2956 < 1)\n    {\n        return 1.0f;\n    }\n    float _2971 = dot(world - _2192_fa_shadow_eye.xyz, _2192_fa_shadow_fwd.xyz);\n    int param = _2956 - 1;\n    if (_2971 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2983 = _2956 > 1;\n    bool _2990;\n    if (_2983)\n    {\n        _2990 = _2971 > _2192_fa_shadow_split.x;\n    }\n    else\n    {\n        _2990 = _2983;\n    }\n    if (_2990)\n    {\n        ci = 1;\n    }\n    bool _2994 = _2956 > 2;\n    bool _3001;\n    if (_2994)\n    {\n        _3001 = _2971 > _2192_fa_shadow_split.y;\n    }\n    else\n    {\n        _3001 = _2994;\n    }\n    if (_3001)\n    {\n        ci = 2;\n    }\n    bool _3005 = _2956 > 3;\n    bool _3012;\n    if (_3005)\n    {\n        _3012 = _2971 > _2192_fa_shadow_split.z;\n    }\n    else\n    {\n        _3012 = _3005;\n    }\n    if (_3012)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2956)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _3038 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3038;\n        if (_3038 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2192_fa_shadow_cfg.y > 0.0f)\n    {\n        float _3063;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3063 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3063 = _2192_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _3082 = _2192_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3063, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _3093 = clamp((_2971 - (fa_shadow_split_at(param_7) - _3082)) / _3082, 0.0f, 1.0f);\n        if (_3093 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2956)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _3114 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3114;\n                if (_3114 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _3093);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _2626 = _485_fa_pbr.z < 0.5f;\n    bool _2633;\n    if (!_2626)\n    {\n        _2633 = _2192_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2633 = _2626;\n    }\n    if (_2633)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2192_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2646 = fa_light_texel(param);\n    float _2647 = _2646.x;\n    if (_2647 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2656 = int(_2647 + 0.5f);\n    int param_1 = _2656;\n    float4 _2660 = fa_light_texel(param_1);\n    int param_2 = _2656 + 1;\n    float4 _2665 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2668 = _2660.y;\n    if (_2668 > 0.0f)\n    {\n        float _2685 = 1.0f - smoothstep(0.75f * _2668, _2668, length(world - _2192_fa_shadow_eye.xyz));\n        fade = _2685;\n        if (_2685 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2660.x > 1.5f)\n    {\n        int param_3 = li;\n        int param_4 = fa_light_base(param_3);\n        float3 param_5 = world - fa_light_texel(param_4).xyz;\n        face = fa_cube_face(param_5);\n    }\n    int _2714 = (_2656 + 2) + (face * 6);\n    int param_6 = _2714;\n    int param_7 = _2714 + 1;\n    int param_8 = _2714 + 3;\n    float4 _2728 = fa_light_texel(param_8);\n    int param_9 = _2714 + 4;\n    float4 _2733 = fa_light_texel(param_9);\n    int param_10 = _2714 + 5;\n    float4 _2738 = fa_light_texel(param_10);\n    float _2750 = _2738.x * max(dot(_2728, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2755 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2778 = clamp(dot(n, _2728.xyz), -1.0f, 1.0f);\n    int param_11 = li;\n    int param_12 = fa_light_base(param_11);\n    float _2802 = min(sqrt(1.0f - (_2778 * _2778)) / max(abs(dot(n, world - fa_light_texel(param_12).xyz)) / max(dot(_2728, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2805 = _2665.y;\n    float _2807;\n    if (_2805 > 0.0f)\n    {\n        _2807 = _2805;\n    }\n    else\n    {\n        _2807 = 1.5f * _2750;\n    }\n    float4 _2827 = float4(world + (n * (_2807 * sqrt(1.0f - (_2755 * _2755)))), 1.0f);\n    float _2831 = dot(_2728, _2827);\n    float _2834 = _2738.y;\n    if (_2831 < _2834)\n    {\n        return 1.0f;\n    }\n    float2 _2849 = float2(dot(fa_light_texel(param_6), _2827), dot(fa_light_texel(param_7), _2827)) / _2831.xx;\n    float _2851 = _2849.x;\n    bool _2854 = _2851 < _2733.x;\n    bool _2863;\n    if (!_2854)\n    {\n        _2863 = _2851 > _2733.z;\n    }\n    else\n    {\n        _2863 = _2854;\n    }\n    bool _2872;\n    if (!_2863)\n    {\n        _2872 = _2849.y < _2733.y;\n    }\n    else\n    {\n        _2872 = _2863;\n    }\n    bool _2881;\n    if (!_2872)\n    {\n        _2881 = _2849.y > _2733.w;\n    }\n    else\n    {\n        _2881 = _2872;\n    }\n    if (_2881)\n    {\n        return 1.0f;\n    }\n    float _2887 = _2665.x;\n    float _2889;\n    if (_2887 > 0.0f)\n    {\n        _2889 = _2887;\n    }\n    else\n    {\n        _2889 = 1.5f * _2750;\n    }\n    float2 param_13 = _2849;\n    float4 param_14 = _2733;\n    float param_15 = _2831 - (_2889 * (1.0f + (0.5f * _2802)));\n    float param_16 = _2750;\n    float param_17 = 1.0f;\n    float param_18 = _2738.z * 0.25f;\n    float param_19 = (_2750 * min(_2802, 3.0f)) * 0.5f;\n    float3 param_20 = float3(1.0f, _2834, _2738.z);\n    int param_21 = int(_2660.z + 0.5f);\n    float param_22 = _2660.w;\n    return lerp(1.0f, fa_shadow_filter(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _4334 = fa_lm.z > 0.5f;\n    bool _4340;\n    if (_4334)\n    {\n        int param = li;\n        _4340 = fa_light_baked(param);\n    }\n    else\n    {\n        _4340 = _4334;\n    }\n    if (_4340)\n    {\n        int param_1 = li;\n        LightSample _6677 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _6677;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4364 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _6679 = _4364.color;\n    float _6681 = _4364.shadow;\n    if ((_4364.type == 0) && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4364.direction;\n        float _4378 = fa_shadow_factor(param_5, param_6);\n        _6681 = _4378;\n        _6679 *= _4378;\n    }\n    else\n    {\n        bool _4389 = _4364.type != 0;\n        bool _4395;\n        if (_4389)\n        {\n            _4395 = _4364.attenuation > 0.0f;\n        }\n        else\n        {\n            _4395 = _4389;\n        }\n        if (_4395)\n        {\n            int param_7 = li;\n            float3 param_8 = world_pos;\n            float3 param_9 = gn;\n            float3 param_10 = _4364.direction;\n            float _4407 = fa_shadow_local(param_7, param_8, param_9, param_10);\n            _6681 = _4407;\n            _6679 *= _4407;\n        }\n    }\n    LightSample _6696 = { _4364.direction, _6679, _4364.attenuation, _6681, _4364._distance, _4364.type };\n    return _6696;\n}\n\nfloat3 fa_ltc_tangent(float3 n, float3 v)\n{\n    float3 _4447 = v - (n * dot(v, n));\n    float3 t = _4447;\n    float _4451 = dot(_4447, _4447);\n    float l2 = _4451;\n    if (_4451 < 1.0000000133514319600180897396058e-10f)\n    {\n        float3 _4461;\n        if (abs(n.z) < 0.999000012874603271484375f)\n        {\n            _4461 = cross(n, float3(0.0f, 0.0f, 1.0f));\n        }\n        else\n        {\n            _4461 = cross(n, float3(1.0f, 0.0f, 0.0f));\n        }\n        t = _4461;\n        l2 = dot(_4461, _4461);\n    }\n    return t * rsqrt(l2);\n}\n\nfloat3 fa_ltc_local(float3 t1, float3 n, float3 p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nfloat3 fa_ltc_edge_vector(float3 a, float3 b)\n{\n    float _4496 = dot(a, a);\n    float _4500 = dot(b, b);\n    if ((_4496 < 1.0000000195414813782625560981111e-24f) || (_4500 < 1.0000000195414813782625560981111e-24f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _4514 = a * rsqrt(_4496);\n    float3 _4519 = b * rsqrt(_4500);\n    float _4523 = dot(_4514, _4519);\n    float _4526 = abs(_4523);\n    float g = (((((((((((0.0416471660137176513671875f * _4526) - 0.1924748718738555908203125f) * _4526) + 0.4179156124591827392578125f) * _4526) - 0.616057217121124267578125f) * _4526) + 0.777722418308258056640625f) * _4526) - 0.999542415142059326171875f) * _4526) + 1.570791721343994140625f;\n    if (_4523 < 0.0f)\n    {\n        g = (3.1415927410125732421875f * rsqrt(max(1.0f - (_4523 * _4523), 1.0000000116860974230803549289703e-07f))) - g;\n    }\n    return cross(_4514, _4519) * g;\n}\n\nvoid fa_ltc_clip_edge(float3 a, float3 b, inout float3 sum, inout float3 leave, inout float3 enter, inout float2 seen)\n{\n    bool _4583 = a.z > 0.0f;\n    bool _4587 = b.z > 0.0f;\n    if (_4583 && _4587)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_4583 != _4587)\n        {\n            float3 _4622 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _4622.z = 0.0f;\n            if (_4583)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _4622;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _4622;\n                seen.x = 1.0f;\n            }\n            else\n            {\n                float3 param_4 = _4622;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _4622;\n                seen.y = 1.0f;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(float4 abcd, float3 p0, float3 p1, float3 p2, float3 p3)\n{\n    float3 _4671 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _4697 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _4723 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _4749 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = 0.0f.xxx;\n    float3 leave = 0.0f.xxx;\n    float3 enter = 0.0f.xxx;\n    float3 param = _4671;\n    float3 param_1 = _4697;\n    float3 param_2 = 0.0f.xxx;\n    float3 param_3 = 0.0f.xxx;\n    float3 param_4 = 0.0f.xxx;\n    float2 param_5 = 0.0f.xx;\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _4697;\n    float3 param_7 = _4723;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _4723;\n    float3 param_13 = _4749;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _4749;\n    float3 param_19 = _4671;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5f)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875f;\n}\n\nfloat fa_ltc_rect(float4 abcd, float3 center, float3 ex, float3 ey)\n{\n    float4 param = abcd;\n    float3 param_1 = (center - ex) - ey;\n    float3 param_2 = (center + ex) - ey;\n    float3 param_3 = (center + ex) + ey;\n    float3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(float4 m, float shape, float3 pc, float3 ex, float3 ey)\n{\n    if ((shape < 0.5f) || (shape > 1.5f))\n    {\n        float4 param = m;\n        float3 param_1 = pc;\n        float3 param_2 = ex;\n        float3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    float3 _4899 = (pc + (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _4923 = (pc - (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _4939 = (pc - (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float4 param_4 = m;\n    float3 param_5 = _4899;\n    float3 param_6 = (pc + (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_7 = (pc - (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_8 = _4923;\n    float4 param_9 = m;\n    float3 param_10 = _4899;\n    float3 param_11 = _4923;\n    float3 param_12 = (pc - (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    float3 param_13 = _4939;\n    float4 param_14 = m;\n    float3 param_15 = _4899;\n    float3 param_16 = _4939;\n    float3 param_17 = (pc + (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float3 param_18 = (pc + (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nfloat2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((float2(clamp((roughness - 0.0500000007450580596923828125f) * 1.0526316165924072265625f, 0.0f, 1.0f), sqrt(clamp(1.0f - ndv, 0.0f, 1.0f))) * 63.0f) + 0.5f.xx) * 0.015625f.xx;\n}\n\nfloat3 fa_area_shade(int li, float3 world_pos, float3 n, float3 v, float3 diffuse_color, float3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _4997 = fa_light_base(param);\n    int param_1 = _4997;\n    int param_2 = _4997 + 1;\n    int param_3 = _4997 + 2;\n    int param_4 = _4997 + 4;\n    float4 _5019 = fa_light_texel(param_4);\n    int param_5 = _4997 + 5;\n    float4 _5024 = fa_light_texel(param_5);\n    int param_6 = _4997 + 6;\n    float4 _5029 = fa_light_texel(param_6);\n    float _5030 = _5029.w;\n    float3 _5035 = fa_light_texel(param_1).xyz - world_pos;\n    bool _5037 = _5030 < 1.5f;\n    bool _5044;\n    if (_5037)\n    {\n        _5044 = dot(normalize(fa_light_texel(param_3).xyz), _5035) >= 0.0f;\n    }\n    else\n    {\n        _5044 = _5037;\n    }\n    if (_5044)\n    {\n        return 0.0f.xxx;\n    }\n    bool _5053 = (_5030 > 0.5f) && _5037;\n    float _5057 = _5053 ? 1.0539000034332275390625f : 1.0f;\n    float3 _5060 = _5019.xyz;\n    float _5062 = _5019.w;\n    float3 _5068 = _5024.xyz;\n    float _5070 = _5024.w;\n    float3 up = _5068 * (_5070 * _5057);\n    float _5076;\n    if (_5053)\n    {\n        _5076 = (3.1415927410125732421875f * _5062) * _5062;\n    }\n    else\n    {\n        _5076 = (4.0f * _5062) * _5070;\n    }\n    if (_5030 > 1.5f)\n    {\n        float3 _5102 = cross(_5060, -_5035);\n        float3 perp = _5102;\n        float _5106 = dot(_5102, _5102);\n        float3 _5109;\n        if (_5106 > 1.0000000133514319600180897396058e-10f)\n        {\n            _5109 = perp * rsqrt(_5106);\n        }\n        else\n        {\n            _5109 = _5068;\n        }\n        perp = _5109;\n        up = _5109 * _5070;\n    }\n    float _5130 = max(_5076, 9.9999999747524270787835121154785e-07f);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _5140 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _5140;\n    float3 param_10 = n;\n    float3 param_11 = _5035;\n    float3 _5148 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_12 = _5140;\n    float3 param_13 = n;\n    float3 param_14 = _5060 * (_5062 * _5057);\n    float3 _5156 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_15 = _5140;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float3 _5164 = fa_ltc_local(param_15, param_16, param_17);\n    float4 param_18 = float4(1.0f, 0.0f, 0.0f, 1.0f);\n    float param_19 = _5030;\n    float3 param_20 = _5148;\n    float3 param_21 = _5156;\n    float3 param_22 = _5164;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    float2 _5183 = fa_ltc_uv(param_23, param_24) * 64.0f;\n    float2 param_25 = _5183;\n    float2 param_26 = _5183 + float2(64.0f, 0.0f);\n    float4 _5193 = fa_atlas_fetch(param_26);\n    float4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _5030;\n    float3 param_29 = _5148;\n    float3 param_30 = _5156;\n    float3 param_31 = _5164;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _5193.x) + ((f90.xxx - f0) * _5193.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875f * dot(_5035, _5035)) + _5130) / _5130) * window);\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4037 = 1.0f / alpha;\n    return ((2.0f + _4037) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _4037)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat fa_layers_coat(FaLayers L, float3 l, float3 h, float vdh)\n{\n    float _4072 = max(dot(L.nc, l), 0.0f);\n    float _4078 = max(dot(L.nc, h), 0.0f);\n    float _4087 = ((_4078 * _4078) * (L.coat_a2 - 1.0f)) + 1.0f;\n    return (((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _4087) * _4087)) * (0.5f / max(lerp((2.0f * _4072) * L.coat_ndv, _4072 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _4072)) * _4072;\n}\n\nfloat3 fa_area_layers(FaLayers L, int li, float3 world_pos, float3 n, float3 v, float3 l, float3 diffuse_color, float3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    float3 param_2 = n;\n    float3 param_3 = v;\n    float3 param_4 = diffuse_color;\n    float3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _5261;\n    if (L.sheen_on)\n    {\n        _5261 = L.sheen_scale;\n    }\n    else\n    {\n        _5261 = 1.0f;\n    }\n    float3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _5261);\n    float3 _5274 = normalize(l + v);\n    int param_10 = li;\n    float3 _5285 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _5294 = max(dot(n, l), 0.0f);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _5274), 0.0f);\n        float param_13 = _5294;\n        float param_14 = ndv;\n        result += ((L.sheen * _5285) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875f) * step(9.9999997473787516355514526367188e-05f, _5294)) * _5294) * L.keep));\n    }\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_15 = L;\n        float3 param_16 = l;\n        float3 param_17 = _5274;\n        float param_18 = max(dot(v, _5274), 0.0f);\n        result += (_5285 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _3940 = tdh / at;\n    float _3944 = bdh / ab;\n    float _3956 = ((_3940 * _3940) + (_3944 * _3944)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _3956) * _3956);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4136 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4215 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _4215) * _4215);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _4136);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _4136));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_17 = L;\n        float3 param_18 = l;\n        float3 param_19 = h;\n        float param_20 = vdh;\n        result += fa_layers_coat(param_17, param_18, param_19, param_20).xxx;\n    }\n    return result;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3343 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3346 = _3343.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3346 * _3346, exp2((-9.27999973297119140625f) * ndv)) * _3346) + _3343.y)) + _3343.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_485_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _485_fa_env_horizon.w).xyz;\n    }\n    float _3249 = rough * rough;\n    float _3279 = 0.60000002384185791015625f * _3249;\n    return lerp(lerp(_485_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_485_fa_env_horizon.xyz, _485_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3249)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3279, 0.0500000007450580596923828125f + _3279, d.y).xxx), ((_485_fa_env_sky.xyz + _485_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3249 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _3823;\n        if (L.aniso >= 0.0f)\n        {\n            _3823 = L.b;\n        }\n        else\n        {\n            _3823 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_3823, v), _3823), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3856 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _3856.x) + (L.f90.xxx * _3856.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3911 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _3911.x) + _3911.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3385 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3385.x) + _3385.y.xxx);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2192_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3138 = int(_2192_fa_shadow_cfg.x + 0.5f);\n    float _3148 = dot(world - _2192_fa_shadow_eye.xyz, _2192_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3153 = _3138 > 0;\n    bool _3162;\n    if (_3153)\n    {\n        int param = _3138 - 1;\n        _3162 = _3148 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3162 = _3153;\n    }\n    if (_3162)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3168 = _3138 > 1;\n        bool _3175;\n        if (_3168)\n        {\n            _3175 = _3148 > _2192_fa_shadow_split.x;\n        }\n        else\n        {\n            _3175 = _3168;\n        }\n        if (_3175)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3181 = _3138 > 2;\n        bool _3188;\n        if (_3181)\n        {\n            _3188 = _3148 > _2192_fa_shadow_split.y;\n        }\n        else\n        {\n            _3188 = _3181;\n        }\n        if (_3188)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3194 = _3138 > 3;\n        bool _3201;\n        if (_3194)\n        {\n            _3201 = _3148 > _2192_fa_shadow_split.z;\n        }\n        else\n        {\n            _3201 = _3194;\n        }\n        if (_3201)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _6379 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6379 = -_6379;\n    }\n    float3 _5726 = normalize(_485_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _6392 = { fa_world_pos, _6379, fa_world_tangent, fa_uv, fa_vertex_color, _5726, gl_FrontFacing };\n    SurfaceInput param_1 = _6392;\n    Surface _5734 = fa_standard_surface(param_1);\n    float3 _6410 = _5734.albedo;\n    float _6411 = _5734.alpha;\n    float3 _6412 = _5734.normal;\n    float _6413 = _5734.metallic;\n    float _6414 = _5734.roughness;\n    float _6415 = _5734.occlusion;\n    float3 _6416 = _5734.emission;\n    float _6417 = _5734.clearcoat;\n    float _6418 = _5734.clearcoat_roughness;\n    float3 _6419 = _5734.sheen_color;\n    float _6420 = _5734.sheen_roughness;\n    float _6421 = _5734.anisotropy;\n    float _6422 = _5734.anisotropy_rotation;\n    float _6423 = _5734.specular;\n    float _6424 = _5734.ior;\n    float3 _6425 = _5734.specular_color;\n    SurfaceInput _6400 = { fa_world_pos, _6379, fa_world_tangent, fa_uv, fa_vertex_color, _5726, gl_FrontFacing };\n    SurfaceInput param_2 = _6400;\n    Surface param_3 = _5734;\n    surface(param_2, param_3);\n    _6410 = param_3.albedo;\n    _6411 = param_3.alpha;\n    _6412 = param_3.normal;\n    _6413 = param_3.metallic;\n    _6414 = param_3.roughness;\n    _6415 = param_3.occlusion;\n    _6416 = param_3.emission;\n    _6417 = param_3.clearcoat;\n    _6418 = param_3.clearcoat_roughness;\n    _6419 = param_3.sheen_color;\n    _6420 = param_3.sheen_roughness;\n    _6421 = param_3.anisotropy;\n    _6422 = param_3.anisotropy_rotation;\n    _6423 = param_3.specular;\n    _6424 = param_3.ior;\n    _6425 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _6379;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6410 = param_6;\n    _6412 = param_7;\n    if (_6411 < _5762_alphaCutoff)\n    {\n        discard;\n    }\n    float3 result;\n    if (_485_fa_emissive.w > 0.5f)\n    {\n        result = _6410;\n    }\n    else\n    {\n        float3 _5784 = normalize(_6412);\n        float _5791 = clamp(_6413, 0.0f, 1.0f);\n        float _5795 = clamp(_6414, 0.0500000007450580596923828125f, 1.0f);\n        float _5799 = _5795 * _5795;\n        float _5803 = _5799 * _5799;\n        float _5808 = max(dot(_5784, _5726), 9.9999997473787516355514526367188e-05f);\n        float3 _5814 = _6410 * (1.0f - _5791);\n        float3 _5821 = lerp(0.039999999105930328369140625f.xxx, _6410, _5791.xxx);\n        float3 f0 = _5821;\n        SurfaceInput _6408 = { fa_world_pos, _6379, fa_world_tangent, fa_uv, fa_vertex_color, _5726, gl_FrontFacing };\n        SurfaceInput param_8 = _6408;\n        Surface _6491 = { _6410, _6411, _6412, _6413, _6414, _6415, _6416, _6417, _6418, _6419, _6420, _6421, _6422, _6423, _6424, _6425 };\n        Surface param_9 = _6491;\n        float3 param_10 = _5784;\n        float3 param_11 = _5726;\n        float param_12 = _5791;\n        float param_13 = _5795;\n        float3 param_14 = _5821;\n        FaLayers _5837 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _5784;\n        float3 lit = (fa_indirect_diffuse(param_15) * _5814) * _6415;\n        if (_5837.on)\n        {\n            lit *= _5837.base_scale;\n        }\n        int _5859 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5859; ln++)\n        {\n            int param_16 = ln;\n            int _5872 = fa_cl_light(param_16);\n            bool _5875 = fa_lm.z > 0.5f;\n            bool _5881;\n            if (_5875)\n            {\n                int param_17 = _5872;\n                _5881 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _5881 = _5875;\n            }\n            if (_5881)\n            {\n                continue;\n            }\n            int param_18 = _5872;\n            float3 param_19 = fa_world_pos;\n            float3 param_20 = _6379;\n            LightSample _5893 = fa_light_shadowed(param_18, param_19, param_20);\n            float _5901 = max(dot(_5784, _5893.direction), 0.0f);\n            float _5907 = _5893.attenuation * _5893.shadow;\n            float3 _5912 = normalize(_5893.direction + _5726);\n            float _5917 = max(dot(_5784, _5912), 0.0f);\n            float _5922 = max(dot(_5726, _5912), 0.0f);\n            bool _5929;\n            if (fa_light_is_area)\n            {\n                _5929 = !_5837.on;\n            }\n            else\n            {\n                _5929 = fa_light_is_area;\n            }\n            if (_5929)\n            {\n                int param_21 = _5872;\n                float3 param_22 = fa_world_pos;\n                float3 param_23 = _5784;\n                float3 param_24 = _5726;\n                float3 param_25 = _5814;\n                float3 param_26 = f0;\n                float param_27 = 1.0f;\n                float param_28 = _5795;\n                float param_29 = _5808;\n                float param_30 = _5907;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _5837;\n                    int param_32 = _5872;\n                    float3 param_33 = fa_world_pos;\n                    float3 param_34 = _5784;\n                    float3 param_35 = _5726;\n                    float3 param_36 = _5893.direction;\n                    float3 param_37 = _5814;\n                    float3 param_38 = f0;\n                    float param_39 = _5795;\n                    float param_40 = _5808;\n                    float param_41 = _5907;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_5837.on)\n                    {\n                        FaLayers param_42 = _5837;\n                        float3 param_43 = _5814;\n                        float3 param_44 = f0;\n                        float3 param_45 = _5784;\n                        float3 param_46 = _5726;\n                        float3 param_47 = _5893.direction;\n                        float3 param_48 = _5912;\n                        float param_49 = _5901;\n                        float param_50 = _5808;\n                        float param_51 = _5917;\n                        float param_52 = _5922;\n                        float param_53 = _5799;\n                        float param_54 = _5803;\n                        int param_55 = _5872;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _5907));\n                    }\n                    else\n                    {\n                        float _6035 = ((_5917 * _5917) * (_5803 - 1.0f)) + 1.0f;\n                        int param_56 = _5872;\n                        lit += (((_5814 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _5922, 5.0f))) * (((_5803 / ((3.1415927410125732421875f * _6035) * _6035)) * (0.5f / max(lerp((2.0f * _5901) * _5808, _5901 + _5808, _5799), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _5901))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_5901 * _5907));\n                    }\n                }\n            }\n        }\n        if (_5837.on)\n        {\n            FaLayers param_57 = _5837;\n            float3 param_58 = _5784;\n            float3 param_59 = _5726;\n            float3 param_60 = f0;\n            float param_61 = _5795;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _6415);\n        }\n        else\n        {\n            float3 param_62 = _5784;\n            float3 param_63 = _5726;\n            float3 param_64 = f0;\n            float param_65 = _5795;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _6415);\n        }\n        result = lit;\n    }\n    float3 _6130 = result;\n    float3 _6131 = _6130 + _6416;\n    result = _6131;\n    float3 param_66 = _6131;\n    float3 param_67 = fa_world_pos;\n    result = fa_shadow_debug(param_66, param_67);\n    bool _6140 = _485_fa_fog.w > 0.0f;\n    bool _6147;\n    if (!_6140)\n    {\n        _6147 = _485_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _6147 = _6140;\n    }\n    if (_6147)\n    {\n        float3 _6156 = fa_world_pos - _485_fa_camera_pos.xyz;\n        float _6162 = dot(_6156, _485_fa_fog_c.xyz);\n        bool _6166 = _485_fa_fog_c.w > 0.5f;\n        float _6167;\n        if (_6166)\n        {\n            _6167 = _6162;\n        }\n        else\n        {\n            _6167 = length(_6156);\n        }\n        float _6179 = _6167 - _485_fa_fog_b.x;\n        if (_6179 > 0.0f)\n        {\n            float _6188 = _485_fa_fog.w * _6179;\n            float tau = _6188 * _6188;\n            if (_485_fa_fog_b.y > 0.0f)\n            {\n                float _6204;\n                if (_6166)\n                {\n                    _6204 = fa_world_pos.y - (_485_fa_fog_c.y * _6162);\n                }\n                else\n                {\n                    _6204 = _485_fa_camera_pos.y;\n                }\n                float _6225 = lerp(_6204, fa_world_pos.y, clamp(_485_fa_fog_b.x / _6167, 0.0f, 1.0f));\n                float _6229 = fa_world_pos.y - _6225;\n                float _6234 = _6225 - _485_fa_fog_b.z;\n                float _6239 = fa_world_pos.y - _485_fa_fog_b.z;\n                bool _6242 = _6234 <= 0.0f;\n                bool _6243 = !_6242;\n                bool _6249;\n                if (_6243)\n                {\n                    _6249 = _485_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6249 = _6242;\n                }\n                float _6250;\n                if (_6249)\n                {\n                    _6250 = _485_fa_fog_b.y;\n                }\n                else\n                {\n                    _6250 = _485_fa_fog_b.y * exp(-min(_485_fa_fog_b.w * _6234, 80.0f));\n                }\n                bool _6277;\n                if (_6243)\n                {\n                    _6277 = _485_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6277 = _6242;\n                }\n                float _6278;\n                if (_6277)\n                {\n                    _6278 = _485_fa_fog_b.y * _6234;\n                }\n                else\n                {\n                    _6278 = (_485_fa_fog_b.y * (1.0f - exp(-min(_485_fa_fog_b.w * _6234, 80.0f)))) / _485_fa_fog_b.w;\n                }\n                bool _6303 = _6239 <= 0.0f;\n                bool _6310;\n                if (!_6303)\n                {\n                    _6310 = _485_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6310 = _6303;\n                }\n                float _6311;\n                if (_6310)\n                {\n                    _6311 = _485_fa_fog_b.y * _6239;\n                }\n                else\n                {\n                    _6311 = (_485_fa_fog_b.y * (1.0f - exp(-min(_485_fa_fog_b.w * _6239, 80.0f)))) / _485_fa_fog_b.w;\n                }\n                float _6338;\n                if (abs(_6229) < 0.001000000047497451305389404296875f)\n                {\n                    _6338 = _6250;\n                }\n                else\n                {\n                    _6338 = (_6311 - _6278) / _6229;\n                }\n                tau += (_6179 * max(_6338, 0.0f));\n            }\n            result = lerp(result, _485_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _6411);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_485",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2192",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_5762",
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
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 6
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
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float",
              "hlsl_register_t_n": 8
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
              "hlsl_register_t_n": 9
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
              "hlsl_register_t_n": 10
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
              "hlsl_register_t_n": 11
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
              "hlsl_register_t_n": 12
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
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
            "sampler_slot": 10
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10
          },
          {
            "slot": 11,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 12,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _301 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _301;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _308 = _160.world_pos;\n    float4 _171 = float4(_308, 1.0f);\n    fa_world_pos = _308;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -mul(_171, _131_fa_light_vp).z;\n    fa_pre_r0 = float3(_131_fa_light_vp[0].x, _131_fa_light_vp[1].x, _131_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131_fa_light_vp[0].y, _131_fa_light_vp[1].y, _131_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131_fa_light_vp[0].z, _131_fa_light_vp[1].z, _131_fa_light_vp[2].z);\n    gl_Position = mul(_171, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _225_fa_camera_pos : packoffset(c0);\n    float4 _225_fa_ambient : packoffset(c1);\n    float4 _225_fa_base_color : packoffset(c2);\n    float4 _225_fa_emissive : packoffset(c3);\n    float4 _225_fa_model_emissive : packoffset(c4);\n    float4 _225_fa_pbr : packoffset(c5);\n    float4 _225_fa_maps : packoffset(c6);\n    float4 _225_fa_fog : packoffset(c7);\n    float4 _225_fa_fog_b : packoffset(c8);\n    float4 _225_fa_fog_c : packoffset(c9);\n    float4 _225_fa_counts : packoffset(c10);\n    float4 _225_fa_env_sky : packoffset(c11);\n    float4 _225_fa_env_horizon : packoffset(c12);\n    float4 _225_fa_time : packoffset(c13);\n    float4 _225_fa_cl_vpx : packoffset(c14);\n    float4 _225_fa_cl_vpy : packoffset(c15);\n    float4 _225_fa_cl_vpw : packoffset(c16);\n    float4 _225_fa_cl_fwd : packoffset(c17);\n    float4 _225_fa_cl_grid : packoffset(c18);\n    float4 _225_fa_cl_info : packoffset(c19);\n    float4 _225_fa_layers_a : packoffset(c20);\n    float4 _225_fa_layers_b : packoffset(c21);\n    float4 _225_fa_layers_c : packoffset(c22);\n    float4 _225_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _546_alphaCutoff : packoffset(c0);\n    float _546_fa_pad0 : packoffset(c0.y);\n    float _546_fa_pad1 : packoffset(c0.z);\n    float _546_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> mask : register(t5);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _225_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _237 = fa_tex_fix(param_2, param_3);\n    float4 _757 = base_t;\n    _757.x = _237.x;\n    _757.y = _237.y;\n    _757.z = _237.z;\n    base_t = _757;\n    float4 _253 = (_757 * _225_fa_base_color) * i.vertex_color;\n    float3 _720 = i.world_normal;\n    if (_225_fa_maps.z > 0.5f)\n    {\n        float param_4 = _225_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _287 = fa_tex_fix(param_6, param_7);\n        float3 _290 = (_287 * 2.0f) - 1.0f.xxx;\n        float2 _295 = _290.xy * _225_fa_maps.x;\n        float3 _765 = _290;\n        _765.x = _295.x;\n        _765.y = _295.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _765;\n        _720 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _225_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _324 = fa_tex_fix(param_12, param_13);\n    float4 _768 = mrt;\n    _768.x = _324.x;\n    _768.y = _324.y;\n    _768.z = _324.z;\n    mrt = _768;\n    float4 _354 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _225_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = _225_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _396 = fa_tex_fix(param_20, param_21);\n    float _725 = _225_fa_layers_a.x;\n    float _726 = _225_fa_layers_a.y;\n    float _729 = _225_fa_layers_a.z;\n    float _728 = _225_fa_layers_b.w;\n    float _731 = _225_fa_layers_c.x;\n    if (_225_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_225_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _725 *= _366.y;\n            _726 *= _366.z;\n            _728 *= _354.w;\n        }\n        if (_225_fa_layers_c.z > 1.5f)\n        {\n            _729 *= mrt.x;\n            _731 *= mrt.w;\n        }\n    }\n    Surface _750 = { _253.xyz, _253.w, _720, clamp(_225_fa_pbr.x * _324.z, 0.0f, 1.0f), clamp(_225_fa_pbr.y * _324.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_225_fa_maps.y * (_366.x - 1.0f)), _225_fa_emissive.xyz + (_225_fa_model_emissive.xyz * _396), _725, _726, _225_fa_layers_b.xyz, _728, _729, _225_fa_layers_a.w, _731, _225_fa_layers_c.y, _225_fa_layers_d.xyz };\n    return _750;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _631 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _631 = -_631;\n    }\n    float3 _530 = normalize(_225_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _644 = { fa_world_pos, _631, fa_world_tangent, fa_uv, fa_vertex_color, _530, gl_FrontFacing };\n    SurfaceInput param = _644;\n    Surface _535 = fa_standard_surface(param);\n    float3 _655 = _535.normal;\n    SurfaceInput _652 = { fa_world_pos, _631, fa_world_tangent, fa_uv, fa_vertex_color, _530, gl_FrontFacing };\n    SurfaceInput param_1 = _652;\n    Surface param_2 = _535;\n    surface(param_1, param_2);\n    _655 = param_2.normal;\n    if (param_2.alpha < _546_alphaCutoff)\n    {\n        discard;\n    }\n    float3 _556 = normalize(_655);\n    float3 _571 = normalize(float3(dot(fa_pre_r0, _556), dot(fa_pre_r1, _556), dot(fa_pre_r2, _556)));\n    float _583 = _571.z;\n    float2 e = _571.xy / ((abs(_571.x) + abs(_571.y)) + abs(_583)).xx;\n    if (_583 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_225",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_546",
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
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 5
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    },
    "prepass_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _422 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _422;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _429 = _273.world_pos;\n    float4 _284 = float4(_429, 1.0f);\n    fa_world_pos = _429;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -mul(_284, _136_fa_light_vp).z;\n    fa_pre_r0 = float3(_136_fa_light_vp[0].x, _136_fa_light_vp[1].x, _136_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136_fa_light_vp[0].y, _136_fa_light_vp[1].y, _136_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136_fa_light_vp[0].z, _136_fa_light_vp[1].z, _136_fa_light_vp[2].z);\n    gl_Position = mul(_284, _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _225_fa_camera_pos : packoffset(c0);\n    float4 _225_fa_ambient : packoffset(c1);\n    float4 _225_fa_base_color : packoffset(c2);\n    float4 _225_fa_emissive : packoffset(c3);\n    float4 _225_fa_model_emissive : packoffset(c4);\n    float4 _225_fa_pbr : packoffset(c5);\n    float4 _225_fa_maps : packoffset(c6);\n    float4 _225_fa_fog : packoffset(c7);\n    float4 _225_fa_fog_b : packoffset(c8);\n    float4 _225_fa_fog_c : packoffset(c9);\n    float4 _225_fa_counts : packoffset(c10);\n    float4 _225_fa_env_sky : packoffset(c11);\n    float4 _225_fa_env_horizon : packoffset(c12);\n    float4 _225_fa_time : packoffset(c13);\n    float4 _225_fa_cl_vpx : packoffset(c14);\n    float4 _225_fa_cl_vpy : packoffset(c15);\n    float4 _225_fa_cl_vpw : packoffset(c16);\n    float4 _225_fa_cl_fwd : packoffset(c17);\n    float4 _225_fa_cl_grid : packoffset(c18);\n    float4 _225_fa_cl_info : packoffset(c19);\n    float4 _225_fa_layers_a : packoffset(c20);\n    float4 _225_fa_layers_b : packoffset(c21);\n    float4 _225_fa_layers_c : packoffset(c22);\n    float4 _225_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _546_alphaCutoff : packoffset(c0);\n    float _546_fa_pad0 : packoffset(c0.y);\n    float _546_fa_pad1 : packoffset(c0.z);\n    float _546_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> mask : register(t5);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _225_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _237 = fa_tex_fix(param_2, param_3);\n    float4 _757 = base_t;\n    _757.x = _237.x;\n    _757.y = _237.y;\n    _757.z = _237.z;\n    base_t = _757;\n    float4 _253 = (_757 * _225_fa_base_color) * i.vertex_color;\n    float3 _720 = i.world_normal;\n    if (_225_fa_maps.z > 0.5f)\n    {\n        float param_4 = _225_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _287 = fa_tex_fix(param_6, param_7);\n        float3 _290 = (_287 * 2.0f) - 1.0f.xxx;\n        float2 _295 = _290.xy * _225_fa_maps.x;\n        float3 _765 = _290;\n        _765.x = _295.x;\n        _765.y = _295.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _765;\n        _720 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _225_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _324 = fa_tex_fix(param_12, param_13);\n    float4 _768 = mrt;\n    _768.x = _324.x;\n    _768.y = _324.y;\n    _768.z = _324.z;\n    mrt = _768;\n    float4 _354 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _225_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = _225_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _396 = fa_tex_fix(param_20, param_21);\n    float _725 = _225_fa_layers_a.x;\n    float _726 = _225_fa_layers_a.y;\n    float _729 = _225_fa_layers_a.z;\n    float _728 = _225_fa_layers_b.w;\n    float _731 = _225_fa_layers_c.x;\n    if (_225_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_225_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _725 *= _366.y;\n            _726 *= _366.z;\n            _728 *= _354.w;\n        }\n        if (_225_fa_layers_c.z > 1.5f)\n        {\n            _729 *= mrt.x;\n            _731 *= mrt.w;\n        }\n    }\n    Surface _750 = { _253.xyz, _253.w, _720, clamp(_225_fa_pbr.x * _324.z, 0.0f, 1.0f), clamp(_225_fa_pbr.y * _324.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_225_fa_maps.y * (_366.x - 1.0f)), _225_fa_emissive.xyz + (_225_fa_model_emissive.xyz * _396), _725, _726, _225_fa_layers_b.xyz, _728, _729, _225_fa_layers_a.w, _731, _225_fa_layers_c.y, _225_fa_layers_d.xyz };\n    return _750;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _631 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _631 = -_631;\n    }\n    float3 _530 = normalize(_225_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _644 = { fa_world_pos, _631, fa_world_tangent, fa_uv, fa_vertex_color, _530, gl_FrontFacing };\n    SurfaceInput param = _644;\n    Surface _535 = fa_standard_surface(param);\n    float3 _655 = _535.normal;\n    SurfaceInput _652 = { fa_world_pos, _631, fa_world_tangent, fa_uv, fa_vertex_color, _530, gl_FrontFacing };\n    SurfaceInput param_1 = _652;\n    Surface param_2 = _535;\n    surface(param_1, param_2);\n    _655 = param_2.normal;\n    if (param_2.alpha < _546_alphaCutoff)\n    {\n        discard;\n    }\n    float3 _556 = normalize(_655);\n    float3 _571 = normalize(float3(dot(fa_pre_r0, _556), dot(fa_pre_r1, _556), dot(fa_pre_r2, _556)));\n    float _583 = _571.z;\n    float2 e = _571.xy / ((abs(_571.x) + abs(_571.y)) + abs(_583)).xx;\n    if (_583 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_225",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_546",
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
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 5
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    },
    "shadow": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _122_fa_view_proj : packoffset(c0);\n    row_major float4x4 _122_fa_light_vp : packoffset(c4);\n    float4 _122_fa_uv_scale : packoffset(c8);\n    float4 _122_fa_time : packoffset(c9);\n    float4 _122_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float3 fa_normal : TEXCOORD5;\n    float2 fa_texcoord0 : TEXCOORD6;\n    float4 fa_tangent : TEXCOORD7;\n    float4 fa_color : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _60 = cross(model[1].xyz, model[2].xyz);\n    float _66 = (dot(model[0].xyz, _60) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _256 = { mul(float4(position, 1.0f), model).xyz, (((_60 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _66, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _66), texcoord0 * _122_fa_uv_scale.xy, color, position };\n    return _256;\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    VertexData _190 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _239 = _190.world_pos;\n    fa_world_pos = _239;\n    fa_world_normal = _190.world_normal;\n    fa_world_tangent = _190.world_tangent;\n    fa_uv = _190.uv;\n    fa_vertex_color = _190.color;\n    gl_Position = mul(float4(_239, 1.0f), _122_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _225_fa_camera_pos : packoffset(c0);\n    float4 _225_fa_ambient : packoffset(c1);\n    float4 _225_fa_base_color : packoffset(c2);\n    float4 _225_fa_emissive : packoffset(c3);\n    float4 _225_fa_model_emissive : packoffset(c4);\n    float4 _225_fa_pbr : packoffset(c5);\n    float4 _225_fa_maps : packoffset(c6);\n    float4 _225_fa_fog : packoffset(c7);\n    float4 _225_fa_fog_b : packoffset(c8);\n    float4 _225_fa_fog_c : packoffset(c9);\n    float4 _225_fa_counts : packoffset(c10);\n    float4 _225_fa_env_sky : packoffset(c11);\n    float4 _225_fa_env_horizon : packoffset(c12);\n    float4 _225_fa_time : packoffset(c13);\n    float4 _225_fa_cl_vpx : packoffset(c14);\n    float4 _225_fa_cl_vpy : packoffset(c15);\n    float4 _225_fa_cl_vpw : packoffset(c16);\n    float4 _225_fa_cl_fwd : packoffset(c17);\n    float4 _225_fa_cl_grid : packoffset(c18);\n    float4 _225_fa_cl_info : packoffset(c19);\n    float4 _225_fa_layers_a : packoffset(c20);\n    float4 _225_fa_layers_b : packoffset(c21);\n    float4 _225_fa_layers_c : packoffset(c22);\n    float4 _225_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _546_alphaCutoff : packoffset(c0);\n    float _546_fa_pad0 : packoffset(c0.y);\n    float _546_fa_pad1 : packoffset(c0.z);\n    float _546_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> mask : register(t5);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _225_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _237 = fa_tex_fix(param_2, param_3);\n    float4 _691 = base_t;\n    _691.x = _237.x;\n    _691.y = _237.y;\n    _691.z = _237.z;\n    base_t = _691;\n    float4 _253 = (_691 * _225_fa_base_color) * i.vertex_color;\n    float3 _660 = i.world_normal;\n    if (_225_fa_maps.z > 0.5f)\n    {\n        float param_4 = _225_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _287 = fa_tex_fix(param_6, param_7);\n        float3 _290 = (_287 * 2.0f) - 1.0f.xxx;\n        float2 _295 = _290.xy * _225_fa_maps.x;\n        float3 _699 = _290;\n        _699.x = _295.x;\n        _699.y = _295.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _699;\n        _660 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _225_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _324 = fa_tex_fix(param_12, param_13);\n    float4 _702 = mrt;\n    _702.x = _324.x;\n    _702.y = _324.y;\n    _702.z = _324.z;\n    mrt = _702;\n    float4 _354 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _225_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = _225_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _396 = fa_tex_fix(param_20, param_21);\n    float _665 = _225_fa_layers_a.x;\n    float _666 = _225_fa_layers_a.y;\n    float _669 = _225_fa_layers_a.z;\n    float _668 = _225_fa_layers_b.w;\n    float _671 = _225_fa_layers_c.x;\n    if (_225_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_225_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _665 *= _366.y;\n            _666 *= _366.z;\n            _668 *= _354.w;\n        }\n        if (_225_fa_layers_c.z > 1.5f)\n        {\n            _669 *= mrt.x;\n            _671 *= mrt.w;\n        }\n    }\n    Surface _690 = { _253.xyz, _253.w, _660, clamp(_225_fa_pbr.x * _324.z, 0.0f, 1.0f), clamp(_225_fa_pbr.y * _324.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_225_fa_maps.y * (_366.x - 1.0f)), _225_fa_emissive.xyz + (_225_fa_model_emissive.xyz * _396), _665, _666, _225_fa_layers_b.xyz, _668, _669, _225_fa_layers_a.w, _671, _225_fa_layers_c.y, _225_fa_layers_d.xyz };\n    return _690;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _571 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _571 = -_571;\n    }\n    float3 _530 = normalize(_225_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _584 = { fa_world_pos, _571, fa_world_tangent, fa_uv, fa_vertex_color, _530, gl_FrontFacing };\n    SurfaceInput param = _584;\n    SurfaceInput _592 = { fa_world_pos, _571, fa_world_tangent, fa_uv, fa_vertex_color, _530, gl_FrontFacing };\n    SurfaceInput param_1 = _592;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    if (param_2.alpha < _546_alphaCutoff)\n    {\n        discard;\n    }\n    fa_frag_color = float4(gl_FragCoord.z, 0.0f, 0.0f, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_122",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_225",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_546",
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
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 5
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _127_fa_view_proj : packoffset(c0);\n    row_major float4x4 _127_fa_light_vp : packoffset(c4);\n    float4 _127_fa_uv_scale : packoffset(c8);\n    float4 _127_fa_time : packoffset(c9);\n    float4 _127_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _174_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float4 fa_joints : TEXCOORD5;\n    float4 fa_weights : TEXCOORD6;\n    float3 fa_normal : TEXCOORD7;\n    float2 fa_texcoord0 : TEXCOORD8;\n    float4 fa_tangent : TEXCOORD9;\n    float4 fa_color : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _165 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_174_fa_joint_rows[_165] * weights[i]);\n        r1 += (_174_fa_joint_rows[_165 + 1] * weights[i]);\n        r2 += (_174_fa_joint_rows[_165 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _65 = cross(model[1].xyz, model[2].xyz);\n    float _71 = (dot(model[0].xyz, _65) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _377 = { mul(float4(position, 1.0f), model).xyz, (((_65 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _71, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _71), texcoord0 * _127_fa_uv_scale.xy, color, position };\n    return _377;\n}\n\nvoid vert_main()\n{\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    fa_inst_begin();\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    VertexData _311 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    float3 _360 = _311.world_pos;\n    fa_world_pos = _360;\n    fa_world_normal = _311.world_normal;\n    fa_world_tangent = _311.world_tangent;\n    fa_uv = _311.uv;\n    fa_vertex_color = _311.color;\n    gl_Position = mul(float4(_360, 1.0f), _127_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _225_fa_camera_pos : packoffset(c0);\n    float4 _225_fa_ambient : packoffset(c1);\n    float4 _225_fa_base_color : packoffset(c2);\n    float4 _225_fa_emissive : packoffset(c3);\n    float4 _225_fa_model_emissive : packoffset(c4);\n    float4 _225_fa_pbr : packoffset(c5);\n    float4 _225_fa_maps : packoffset(c6);\n    float4 _225_fa_fog : packoffset(c7);\n    float4 _225_fa_fog_b : packoffset(c8);\n    float4 _225_fa_fog_c : packoffset(c9);\n    float4 _225_fa_counts : packoffset(c10);\n    float4 _225_fa_env_sky : packoffset(c11);\n    float4 _225_fa_env_horizon : packoffset(c12);\n    float4 _225_fa_time : packoffset(c13);\n    float4 _225_fa_cl_vpx : packoffset(c14);\n    float4 _225_fa_cl_vpy : packoffset(c15);\n    float4 _225_fa_cl_vpw : packoffset(c16);\n    float4 _225_fa_cl_fwd : packoffset(c17);\n    float4 _225_fa_cl_grid : packoffset(c18);\n    float4 _225_fa_cl_info : packoffset(c19);\n    float4 _225_fa_layers_a : packoffset(c20);\n    float4 _225_fa_layers_b : packoffset(c21);\n    float4 _225_fa_layers_c : packoffset(c22);\n    float4 _225_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _546_alphaCutoff : packoffset(c0);\n    float _546_fa_pad0 : packoffset(c0.y);\n    float _546_fa_pad1 : packoffset(c0.z);\n    float _546_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> mask : register(t5);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _225_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _237 = fa_tex_fix(param_2, param_3);\n    float4 _691 = base_t;\n    _691.x = _237.x;\n    _691.y = _237.y;\n    _691.z = _237.z;\n    base_t = _691;\n    float4 _253 = (_691 * _225_fa_base_color) * i.vertex_color;\n    float3 _660 = i.world_normal;\n    if (_225_fa_maps.z > 0.5f)\n    {\n        float param_4 = _225_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _287 = fa_tex_fix(param_6, param_7);\n        float3 _290 = (_287 * 2.0f) - 1.0f.xxx;\n        float2 _295 = _290.xy * _225_fa_maps.x;\n        float3 _699 = _290;\n        _699.x = _295.x;\n        _699.y = _295.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _699;\n        _660 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _225_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _324 = fa_tex_fix(param_12, param_13);\n    float4 _702 = mrt;\n    _702.x = _324.x;\n    _702.y = _324.y;\n    _702.z = _324.z;\n    mrt = _702;\n    float4 _354 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _225_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = _225_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _396 = fa_tex_fix(param_20, param_21);\n    float _665 = _225_fa_layers_a.x;\n    float _666 = _225_fa_layers_a.y;\n    float _669 = _225_fa_layers_a.z;\n    float _668 = _225_fa_layers_b.w;\n    float _671 = _225_fa_layers_c.x;\n    if (_225_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_225_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _665 *= _366.y;\n            _666 *= _366.z;\n            _668 *= _354.w;\n        }\n        if (_225_fa_layers_c.z > 1.5f)\n        {\n            _669 *= mrt.x;\n            _671 *= mrt.w;\n        }\n    }\n    Surface _690 = { _253.xyz, _253.w, _660, clamp(_225_fa_pbr.x * _324.z, 0.0f, 1.0f), clamp(_225_fa_pbr.y * _324.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_225_fa_maps.y * (_366.x - 1.0f)), _225_fa_emissive.xyz + (_225_fa_model_emissive.xyz * _396), _665, _666, _225_fa_layers_b.xyz, _668, _669, _225_fa_layers_a.w, _671, _225_fa_layers_c.y, _225_fa_layers_d.xyz };\n    return _690;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _571 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _571 = -_571;\n    }\n    float3 _530 = normalize(_225_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _584 = { fa_world_pos, _571, fa_world_tangent, fa_uv, fa_vertex_color, _530, gl_FrontFacing };\n    SurfaceInput param = _584;\n    SurfaceInput _592 = { fa_world_pos, _571, fa_world_tangent, fa_uv, fa_vertex_color, _530, gl_FrontFacing };\n    SurfaceInput param_1 = _592;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    if (param_2.alpha < _546_alphaCutoff)\n    {\n        discard;\n    }\n    fa_frag_color = float4(gl_FragCoord.z, 0.0f, 0.0f, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_127",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_174",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_225",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_546",
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
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 5
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    }
  }
}
