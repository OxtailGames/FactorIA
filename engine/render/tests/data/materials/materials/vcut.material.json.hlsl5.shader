{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "fc5698cd941e0af057040ef4c307a7106b1e2971cc74f7501935817daedb7ce8",
  "slang": "hlsl5",
  "params": [
    "alphaCutoff"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _263 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _263;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_270, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _3496[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _485_fa_camera_pos : packoffset(c0);\n    float4 _485_fa_ambient : packoffset(c1);\n    float4 _485_fa_base_color : packoffset(c2);\n    float4 _485_fa_emissive : packoffset(c3);\n    float4 _485_fa_model_emissive : packoffset(c4);\n    float4 _485_fa_pbr : packoffset(c5);\n    float4 _485_fa_maps : packoffset(c6);\n    float4 _485_fa_fog : packoffset(c7);\n    float4 _485_fa_fog_b : packoffset(c8);\n    float4 _485_fa_fog_c : packoffset(c9);\n    float4 _485_fa_counts : packoffset(c10);\n    float4 _485_fa_env_sky : packoffset(c11);\n    float4 _485_fa_env_horizon : packoffset(c12);\n    float4 _485_fa_time : packoffset(c13);\n    float4 _485_fa_cl_vpx : packoffset(c14);\n    float4 _485_fa_cl_vpy : packoffset(c15);\n    float4 _485_fa_cl_vpw : packoffset(c16);\n    float4 _485_fa_cl_fwd : packoffset(c17);\n    float4 _485_fa_cl_grid : packoffset(c18);\n    float4 _485_fa_cl_info : packoffset(c19);\n    float4 _485_fa_layers_a : packoffset(c20);\n    float4 _485_fa_layers_b : packoffset(c21);\n    float4 _485_fa_layers_c : packoffset(c22);\n    float4 _485_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2202_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2202_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2202_fa_shadow_info[4] : packoffset(c20);\n    float4 _2202_fa_shadow_split : packoffset(c24);\n    float4 _2202_fa_shadow_cfg : packoffset(c25);\n    float4 _2202_fa_shadow_bias : packoffset(c26);\n    float4 _2202_fa_shadow_eye : packoffset(c27);\n    float4 _2202_fa_shadow_fwd : packoffset(c28);\n    float4 _2202_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _5761_alphaCutoff : packoffset(c0);\n    float _5761_fa_pad0 : packoffset(c0.y);\n    float _5761_fa_pad1 : packoffset(c0.z);\n    float _5761_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t11);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t10);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1473 = _485_fa_cl_info.x < 0.0f;\n    bool _1480;\n    if (!_1473)\n    {\n        _1480 = _485_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1480 = _1473;\n    }\n    bool _1488;\n    if (!_1480)\n    {\n        _1488 = _485_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1488 = _1480;\n    }\n    bool _1495;\n    if (!_1488)\n    {\n        _1495 = _485_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1495 = _1488;\n    }\n    bool _1502;\n    if (!_1495)\n    {\n        _1502 = _485_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1502 = _1495;\n    }\n    if (_1502)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1512 = float4(world_pos, 1.0f);\n    float _1518 = dot(_485_fa_cl_vpw, _1512);\n    if (!(_1518 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1540 = float2(dot(_485_fa_cl_vpx, _1512), dot(_485_fa_cl_vpy, _1512)) / _1518.xx;\n    int _1544 = int(_485_fa_cl_grid.x);\n    int _1548 = int(_485_fa_cl_grid.y);\n    int param = (int(_485_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_485_fa_cl_fwd.xyz, world_pos) + _485_fa_cl_fwd.w, _485_fa_cl_grid.w) / _485_fa_cl_grid.w) * _485_fa_cl_grid.z)), 0, int(_485_fa_cl_info.y) - 1) * _1548) + clamp(int(floor(((_1540.y * 0.5f) + 0.5f) * _485_fa_cl_grid.y)), 0, _1548 - 1)) * _1544)) + clamp(int(floor(((_1540.x * 0.5f) + 0.5f) * _485_fa_cl_grid.x)), 0, _1544 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1624 = fa_cluster_texel(param);\n    return int2(int(_1624.x), int(_1624.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_485_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4317 = fa_cluster_lookup(param);\n    fa_cl_slot = _4317.x;\n    fa_cl_local = _4317.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _5395 = fa_linear_to_srgb(param);\n        c = _5395;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _5403 = fa_srgb_to_linear(param_1);\n            c = _5403;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _417;\n    if (i.front_facing)\n    {\n        _417 = i.world_normal;\n    }\n    else\n    {\n        _417 = -i.world_normal;\n    }\n    float3 _441 = normalize(i.world_tangent.xyz - (_417 * dot(_417, i.world_tangent.xyz)));\n    float3 _469 = normalize(((_441 * m.x) + ((cross(_417, _441) * i.world_tangent.w) * m.y)) + (_417 * m.z));\n    float3 _472;\n    if (i.front_facing)\n    {\n        _472 = _469;\n    }\n    else\n    {\n        _472 = -_469;\n    }\n    return _472;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _485_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _5434 = fa_tex_fix(param_2, param_3);\n    float4 _6860 = base_t;\n    _6860.x = _5434.x;\n    _6860.y = _5434.y;\n    _6860.z = _5434.z;\n    base_t = _6860;\n    float4 _5448 = (_6860 * _485_fa_base_color) * i.vertex_color;\n    float3 _6698 = i.world_normal;\n    if (_485_fa_maps.z > 0.5f)\n    {\n        float param_4 = _485_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _5480 = fa_tex_fix(param_6, param_7);\n        float3 _5483 = (_5480 * 2.0f) - 1.0f.xxx;\n        float2 _5488 = _5483.xy * _485_fa_maps.x;\n        float3 _6868 = _5483;\n        _6868.x = _5488.x;\n        _6868.y = _5488.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _6868;\n        _6698 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _485_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _5516 = fa_tex_fix(param_12, param_13);\n    float4 _6871 = mrt;\n    _6871.x = _5516.x;\n    _6871.y = _5516.y;\n    _6871.z = _5516.z;\n    mrt = _6871;\n    float4 _5544 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _485_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _5544.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _5555 = fa_tex_fix(param_16, param_17);\n    float param_18 = _485_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _5585 = fa_tex_fix(param_20, param_21);\n    float _6703 = _485_fa_layers_a.x;\n    float _6704 = _485_fa_layers_a.y;\n    float _6707 = _485_fa_layers_a.z;\n    float _6706 = _485_fa_layers_b.w;\n    float _6709 = _485_fa_layers_c.x;\n    if (_485_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_485_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _6703 *= _5555.y;\n            _6704 *= _5555.z;\n            _6706 *= _5544.w;\n        }\n        if (_485_fa_layers_c.z > 1.5f)\n        {\n            _6707 *= mrt.x;\n            _6709 *= mrt.w;\n        }\n    }\n    Surface _6728 = { _5448.xyz, _5448.w, _6698, clamp(_485_fa_pbr.x * _5516.z, 0.0f, 1.0f), clamp(_485_fa_pbr.y * _5516.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_485_fa_maps.y * (_5555.x - 1.0f)), _485_fa_emissive.xyz + (_485_fa_model_emissive.xyz * _5585), _6703, _6704, _485_fa_layers_b.xyz, _6706, _6707, _485_fa_layers_a.w, _6709, _485_fa_layers_c.y, _485_fa_layers_d.xyz };\n    return _6728;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1704 = rect.zw - rect.xy;\n    float2 _1708 = _1704 * atlas;\n    float2 _1712 = ddx * _1708;\n    float2 _1716 = ddy * _1708;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1704), clamp(0.5f * log2(max(max(dot(_1712, _1712), dot(_1716, _1716)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1749 = _485_fa_counts.y < 0.5f;\n    bool _1756;\n    if (!_1749)\n    {\n        _1756 = _485_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1756 = _1749;\n    }\n    if (_1756)\n    {\n        return;\n    }\n    float3 _1762 = ddx(world_pos);\n    float3 _1765 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1769 = fa_cluster_texel(param);\n    int _1773 = int(_1769.w);\n    if (_1773 < 1)\n    {\n        return;\n    }\n    int _1783 = int(_485_fa_counts.y + 0.5f);\n    int param_1 = _1783;\n    float4 _1787 = fa_light_texel(param_1);\n    float2 _1790 = _1787.yz;\n    int _1794 = int(_1787.w);\n    int param_2 = _1783 + 1;\n    float4 _1799 = fa_light_texel(param_2);\n    float _1800 = _1799.x;\n    int _1806 = int(_485_fa_counts.w + 0.5f) - 1;\n    int _1810 = int(_1769.z);\n    float3 _2075;\n    for (int k = 0; k < _1773; k++)\n    {\n        int _1823 = _1810 + k;\n        int param_3 = _1794 + (_1823 >> 2);\n        int _1840 = (_1783 + 2) + (int(fa_light_texel(param_3)[_1823 & 3]) * 7);\n        int param_4 = _1840 + 6;\n        float4 _1845 = fa_light_texel(param_4);\n        if (((int(_1845.w + 0.5f) >> _1806) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1840;\n        float4 _1860 = fa_light_texel(param_5);\n        int param_6 = _1840 + 1;\n        float4 _1865 = fa_light_texel(param_6);\n        int param_7 = _1840 + 2;\n        float4 _1870 = fa_light_texel(param_7);\n        float3 _1873 = _1860.xyz;\n        float _1878 = dot(_1873, world_pos) + _1860.w;\n        float3 _1880 = _1865.xyz;\n        float _1885 = dot(_1880, world_pos) + _1865.w;\n        float3 _1887 = _1870.xyz;\n        float _1892 = dot(_1887, world_pos) + _1870.w;\n        bool _1897 = abs(_1878) > 0.5f;\n        bool _1905;\n        if (!_1897)\n        {\n            _1905 = abs(_1885) > 0.5f;\n        }\n        else\n        {\n            _1905 = _1897;\n        }\n        bool _1913;\n        if (!_1905)\n        {\n            _1913 = abs(_1892) > 0.5f;\n        }\n        else\n        {\n            _1913 = _1905;\n        }\n        if (_1913)\n        {\n            continue;\n        }\n        float _1928 = clamp(dot(geo_normal, normalize(_1887)) * _1845.z, 0.0f, 1.0f);\n        if (_1928 <= 0.0f)\n        {\n            continue;\n        }\n        float _1948 = (clamp((0.5f - abs(_1892)) * 10.0f, 0.0f, 1.0f) * _1928) * _1845.x;\n        float2 _1956 = float2(_1878 + 0.5f, 0.5f - _1885);\n        float2 _1966 = float2(dot(_1873, _1762), dot(_1880, _1762));\n        float2 _1976 = float2(dot(_1873, _1765), dot(_1880, _1765));\n        int param_8 = _1840 + 5;\n        float4 _1981 = fa_light_texel(param_8);\n        int param_9 = _1840 + 3;\n        float4 _1986 = fa_light_texel(param_9);\n        int param_10 = _1840 + 4;\n        float4 _1991 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1981.xyz;\n        bool _2001 = _1986.z > _1986.x;\n        if (_2001)\n        {\n            float4 param_11 = _1986;\n            float2 param_12 = _1956;\n            float2 param_13 = _1790;\n            float2 param_14 = _1966;\n            float2 param_15 = _1976;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1800 > 0.5f) && (_1800 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _2027 = fa_dc_to_linear(param_16);\n                float4 _6778 = tx;\n                _6778.x = _2027.x;\n                _6778.y = _2027.y;\n                _6778.z = _2027.z;\n                tx = _6778;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1948 * tex_a) * _1981.w, 0.0f, 1.0f).xxx);\n        if (_1991.z > _1991.x)\n        {\n            float4 param_17 = _1991;\n            float2 param_18 = _1956;\n            float2 param_19 = _1790;\n            float2 param_20 = _1966;\n            float2 param_21 = _1976;\n            float4 _2071 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1800 > 1.5f)\n            {\n                float3 param_22 = _2071.xyz;\n                float3 _2081 = fa_dc_to_srgb(param_22);\n                _2075 = _2081;\n            }\n            else\n            {\n                _2075 = _2071.xyz;\n            }\n            float3 _2090 = (_2075 * 2.0f) - 1.0f.xxx;\n            float2 _2095 = _2090.xy * _1845.y;\n            float3 _2117 = (normalize(_1873) * _2095.x) + (normalize(_1880) * _2095.y);\n            float3 _2120 = normalize(normal);\n            normal = normalize(lerp(_2120, normalize((_2120 * max(_2090.z, 0.0500000007450580596923828125f)) + (_2117 - (_2120 * dot(_2120, _2117)))), clamp(_1948 * (_2001 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3421 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3429 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3432 = int(_3421);\n    int _3435 = int(_3429);\n    float _3445 = _3429 - float(_3435);\n    int _3501 = (_3432 * 9) + _3435;\n    int _3521 = ((_3432 + 1) * 9) + _3435;\n    return lerp(lerp(_3496[_3501], _3496[_3501 + 1], _3445), lerp(_3496[_3521], _3496[_3521 + 1], _3445), _3421 - float(_3432));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _6621 = false;\n    float _6622 = 1.0f;\n    float _6623 = 1.0f;\n    float _6624 = 1.0f;\n    float _6625 = 0.0f;\n    float _6626 = 0.0f;\n    float _6627 = 0.0f;\n    float _6628 = 0.0f;\n    float _6630 = 1.0f;\n    bool _6631 = false;\n    float3 _6632 = 0.0f.xxx;\n    float _6633 = 1.0f;\n    float _6634 = 1.0f;\n    float _6635 = 1.0f;\n    float _6636 = 0.0f;\n    float _6637 = 0.0f;\n    float3 _6638 = float3(1.0f, 0.0f, 0.0f);\n    float3 _6639 = float3(0.0f, 0.0f, 1.0f);\n    float _6640 = 1.0f;\n    float _6641 = 1.0f;\n    float _3572 = clamp(s.specular, 0.0f, 1.0f);\n    float _3576 = clamp(s.ior, 1.0f, 3.0f);\n    bool _3581 = (_3572 != 1.0f) || (_3576 != 1.5f);\n    bool _3590;\n    if (!_3581)\n    {\n        _3590 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _3590 = _3581;\n    }\n    if (_3590)\n    {\n        float _3598 = (_3576 - 1.0f) / (_3576 + 1.0f);\n        f0 = lerp(min((_3598 * _3598).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _3572, s.albedo, metallic.xxx);\n        _6622 = lerp(_3572, 1.0f, metallic);\n        _6621 = true;\n    }\n    float _3625 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_3625 > 0.0f)\n    {\n        float _3633 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _6625 = _3625;\n        _6626 = _3633;\n        float _3640 = _3633 * _3633;\n        _6627 = _3640;\n        _6628 = _3640 * _3640;\n        float _3652 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _6630 = _3652;\n        _6623 = 1.0f - (_3625 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _3652, 0.0f, 1.0f), 5.0f))));\n        _6621 = true;\n    }\n    float3 _3672 = max(s.sheen_color, 0.0f.xxx);\n    float _3681 = max(_3672.x, max(_3672.y, _3672.z));\n    if (_3681 > 0.0f)\n    {\n        float _3689 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _6631 = true;\n        _6632 = _3672;\n        _6633 = _3689;\n        _6634 = _3689 * _3689;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _3689;\n        float _3706 = fa_sheen_albedo(param, param_1);\n        _6636 = _3706;\n        _6635 = 1.0f - min(_3681 * _3706, 1.0f);\n        _6621 = true;\n    }\n    _6624 = _6623 * _6635;\n    float _3725 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_3725 != 0.0f)\n    {\n        float3 _3740 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _3740;\n        if (dot(_3740, _3740) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _3752 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_3752.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _3752.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _3752.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _3756 = t;\n        float3 _3757 = normalize(_3756);\n        t = _3757;\n        float3 _3782 = normalize((_3757 * cos(s.anisotropy_rotation)) + ((cross(n, _3757) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _6638 = _3782;\n        _6639 = cross(n, _3782);\n        float _3792 = roughness * roughness;\n        float _3798 = lerp(_3792, 1.0f, _3725 * _3725);\n        bool _3800 = _3725 > 0.0f;\n        _6640 = _3800 ? _3798 : _3792;\n        _6641 = _3800 ? _3792 : _3798;\n        _6637 = _3725;\n        _6621 = true;\n    }\n    FaLayers _6663 = { _6621, _6622, _6623, _6624, _6625, _6626, _6627, _6628, i.world_normal, _6630, _6631, _6632, _6633, _6634, _6635, _6636, _6637, _6638, _6639, _6640, _6641 };\n    return _6663;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_485_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _485_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_485_fa_cl_info.x) + int(_485_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_485_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _556_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _556_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _722 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _735 = (c - (ru * hx)) - p;\n        float3 _741 = ru * (2.0f * hx);\n        float _747 = max(dot(_741, _741), 9.9999999392252902907785028219223e-09f);\n        float _751 = dot(_735, _741);\n        float t = clamp((-_751) / _747, 0.0f, 1.0f);\n        if (_722)\n        {\n            float _766 = dot(r, _741);\n            float _772 = _747 - (_766 * _766);\n            if (abs(_772) > (9.9999997473787516355514526367188e-06f * _747))\n            {\n                t = clamp(((dot(r, _735) * _766) - _751) / _772, 0.0f, 1.0f);\n            }\n        }\n        return (p + _735) + (_741 * t);\n    }\n    float3 q = p;\n    float _804 = dot(r, axis);\n    bool _812;\n    if (_722)\n    {\n        _812 = abs(_804) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _812 = _722;\n    }\n    if (_812)\n    {\n        float _822 = dot(c - p, axis) / _804;\n        if (_822 > 0.0f)\n        {\n            q = p + (r * _822);\n        }\n    }\n    float3 _835 = q - c;\n    float2 xy = float2(dot(_835, ru), dot(_835, uu));\n    if (shape > 0.5f)\n    {\n        float _850 = length(xy);\n        if (_850 > hx)\n        {\n            xy *= (hx / _850);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _643 = abs(d);\n    float _645 = _643.x;\n    float _647 = _643.y;\n    bool _648 = _645 >= _647;\n    bool _656;\n    if (_648)\n    {\n        _656 = _645 >= _643.z;\n    }\n    else\n    {\n        _656 = _648;\n    }\n    int _657;\n    if (_656)\n    {\n        _657 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _670;\n        if (_647 >= _643.z)\n        {\n            _670 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _670 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _657 = _670;\n    }\n    return _657;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _596 = dot(d, right);\n    float _600 = dot(d, up);\n    float _611;\n    if (((_596 * _596) + (_600 * _600)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _611 = atan2(_600, _596) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _611 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_611 - floor(_611)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _888 = fa_light_base(param);\n    bool _892 = _485_fa_ambient.w > 4.5f;\n    int param_1 = _888;\n    float4 _896 = fa_light_texel(param_1);\n    int param_2 = _888 + 1;\n    float4 _901 = fa_light_texel(param_2);\n    float _904 = _901.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _916 = _892 && (_904 > 2.5f);\n    fa_light_is_area = _916;\n    bool _918 = _904 < 0.5f;\n    float3 l;\n    if (_918)\n    {\n        l = normalize(_896.xyz);\n        if (_892)\n        {\n            int param_3 = _888 + 6;\n            float4 _932 = fa_light_texel(param_3);\n            if (_932.z > 0.5f)\n            {\n                int param_4 = _888 + 4;\n                float4 _942 = fa_light_texel(param_4);\n                int param_5 = _888 + 5;\n                float4 _947 = fa_light_texel(param_5);\n                float2 param_6 = _932.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _942.xyz) * _942.w, (-dot(world_pos, _947.xyz)) * _947.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _977 = _896.xyz;\n        float3 _979 = _977 - world_pos;\n        float3 to_light = _979;\n        float _982 = length(_979);\n        float reach = _982;\n        bool front = true;\n        if (_916)\n        {\n            int param_8 = _888 + 7;\n            reach = max(_982 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _888 + 4;\n            float4 _1006 = fa_light_texel(param_9);\n            int param_10 = _888 + 5;\n            float4 _1011 = fa_light_texel(param_10);\n            int param_11 = _888 + 6;\n            float4 _1016 = fa_light_texel(param_11);\n            float _1017 = _1016.w;\n            int param_12 = _888 + 2;\n            float3 _1024 = normalize(fa_light_texel(param_12).xyz);\n            bool _1026 = _1017 > 1.5f;\n            bool _1034;\n            if (!_1026)\n            {\n                _1034 = dot(_1024, to_light) < 0.0f;\n            }\n            else\n            {\n                _1034 = _1026;\n            }\n            front = _1034;\n            float3 r = 0.0f.xxx;\n            float3 _1043 = _485_fa_camera_pos.xyz - world_pos;\n            bool _1047 = dot(n, n) > 0.5f;\n            bool _1055;\n            if (_1047)\n            {\n                _1055 = dot(_1043, _1043) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _1055 = _1047;\n            }\n            if (_1055)\n            {\n                r = reflect(-normalize(_1043), normalize(n));\n            }\n            float3 param_13 = _977;\n            float3 param_14 = _1024;\n            float3 param_15 = _1006.xyz;\n            float3 param_16 = _1011.xyz;\n            float param_17 = _1006.w;\n            float param_18 = _1011.w;\n            float param_19 = _1017;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1091 = length(to_light);\n        dist = _1091;\n        l = to_light / max(_1091, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1105 = reach / max(_896.w, 0.001000000047497451305389404296875f);\n        float _1111 = clamp(1.0f - (_1105 * _1105), 0.0f, 1.0f);\n        float _1113;\n        if (front)\n        {\n            _1113 = _1111 * _1111;\n        }\n        else\n        {\n            _1113 = 0.0f;\n        }\n        atten = _1113;\n        bool _1124 = _904 < 2.5f;\n        if ((_904 > 1.5f) && _1124)\n        {\n            int param_22 = _888 + 2;\n            float4 _1132 = fa_light_texel(param_22);\n            float _1142 = _1132.w;\n            int param_23 = _888 + 3;\n            float4 _1147 = fa_light_texel(param_23);\n            float _1148 = _1147.x;\n            float cos_inner = _1148;\n            if (_1148 > 1.5f)\n            {\n                cos_inner = lerp(_1142, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1142, cos_inner, dot(-l, normalize(_1132.xyz)));\n        }\n        if (_892 && (_904 < 1.5f))\n        {\n            int param_24 = _888 + 6;\n            float4 _1172 = fa_light_texel(param_24);\n            if (_1172.z > 0.5f)\n            {\n                float3 _1180 = -to_light;\n                int param_25 = _888 + 4;\n                int param_26 = _888 + 5;\n                float3 _1194 = fa_light_texel(param_25).xyz;\n                float3 _1198 = fa_light_texel(param_26).xyz;\n                float3 _1207 = float3(dot(_1180, _1194), dot(_1180, _1198), dot(_1180, cross(_1194, _1198)));\n                float3 param_27 = _1207;\n                int _1211 = fa_cube_face(param_27);\n                int param_28 = _1211;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1238 = float2(dot(_1207, cross(param_29, param_30)), dot(_1207, param_30)) / max(dot(_1207, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1242 = _1211 / 3;\n                float2 param_31 = _1172.xy + (float2(float(_1211 - (_1242 * 3)), float(_1242)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1238.x), 0.5f - (0.5f * _1238.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _888 + 7;\n            float4 _1272 = fa_light_texel(param_33);\n            if (_1272.z > 0.5f)\n            {\n                int param_34 = _888 + 2;\n                int param_35 = _888 + 4;\n                int param_36 = _888 + 5;\n                float2 param_37 = _1272.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_892 && _1124)\n            {\n                int param_42 = _888 + 6;\n                float4 _1319 = fa_light_texel(param_42);\n                int param_43 = _888 + 7;\n                float4 _1324 = fa_light_texel(param_43);\n                bool _1327 = _1319.z > 0.5f;\n                bool _1334;\n                if (!_1327)\n                {\n                    _1334 = _1324.z > 0.5f;\n                }\n                else\n                {\n                    _1334 = _1327;\n                }\n                if (_1334)\n                {\n                    int param_44 = _888 + 2;\n                    float4 _1341 = fa_light_texel(param_44);\n                    float3 _1345 = normalize(_1341.xyz);\n                    int param_45 = _888 + 4;\n                    float4 _1350 = fa_light_texel(param_45);\n                    int param_46 = _888 + 5;\n                    float4 _1355 = fa_light_texel(param_46);\n                    if (_1327)\n                    {\n                        float3 _1363 = -to_light;\n                        float _1370 = _1341.w;\n                        float _1386 = 0.5f / max(dot(_1363, _1345) * (sqrt(max(1.0f - (_1370 * _1370), 0.0f)) / max(_1370, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1319.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1363, _1350.xyz) * _1386), 0.5f - (dot(_1363, _1355.xyz) * _1386));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1324.z > 0.5f)\n                    {\n                        float2 param_49 = _1324.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1345;\n                        float3 param_52 = _1350.xyz;\n                        float3 param_53 = _1355.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _6609 = _901.xyz * atten;\n    if (_892)\n    {\n        _6609 *= fa_light_tint;\n    }\n    int _1455;\n    if (_918)\n    {\n        _1455 = 0;\n    }\n    else\n    {\n        _1455 = ((_904 > 1.5f) && (_904 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _6620 = { l, _6609, atten, 1.0f, dist, _1455 };\n    return _6620;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2192;\n    if (i == 0)\n    {\n        _2192 = _2202_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2208;\n        if (i == 1)\n        {\n            _2208 = _2202_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2216;\n            if (i == 2)\n            {\n                _2216 = _2202_fa_shadow_split.z;\n            }\n            else\n            {\n                _2216 = _2202_fa_shadow_split.w;\n            }\n            _2208 = _2216;\n        }\n        _2192 = _2208;\n    }\n    return _2192;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2249 = fa_shadow_depth(param, param_1);\n    float _2253;\n    if (conv.x < 0.5f)\n    {\n        _2253 = _2249;\n    }\n    else\n    {\n        _2253 = (conv.y * conv.z) / (conv.z - (_2249 * (conv.z - conv.y)));\n    }\n    return _2253;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2180 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2180), sin(_2180)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2299 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2308;\n        if (k < 0.0f)\n        {\n            _2308 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2308 = k;\n        }\n        float _2328 = clamp((_2308 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2299;\n            float2 _2347 = fa_shadow_vogel(param_3, param_4, param_5) * _2328;\n            float2 param_6 = uv + (_2347 * _2202_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2359 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2359 < (zr - (length(_2347) * plane)))\n            {\n                sum += _2359;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2385 = sum / cnt;\n        float _2395;\n        if (k < 0.0f)\n        {\n            _2395 = (-k) / max(_2385, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2395 = k;\n        }\n        radius = clamp(((max(zr - _2385, 0.0f) * unit) * _2395) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2417 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2417; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2417;\n        float param_11 = _2299;\n        float2 _2436 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2436 * _2202_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2436) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2417);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2478 = max(_2202_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2483 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2489 = sqrt(1.0f - (_2483 * _2483));\n    float _2496 = min(_2489 / max(_2483, 0.20000000298023223876953125f), 4.0f);\n    float _2501;\n    if (_2202_fa_shadow_bias.y > 0.0f)\n    {\n        _2501 = _2202_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2501 = 1.5f * _2202_fa_shadow_info[ci].x;\n    }\n    float4 _2526 = mul(float4(world + (n * (_2501 * _2489)), 1.0f), _2202_fa_shadow_mat[ci]);\n    float _2533 = _2526.x;\n    bool _2536 = _2533 < _2202_fa_shadow_rect[ci].x;\n    bool _2545;\n    if (!_2536)\n    {\n        _2545 = _2533 > _2202_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2545 = _2536;\n    }\n    bool _2554;\n    if (!_2545)\n    {\n        _2554 = _2526.y < _2202_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2554 = _2545;\n    }\n    bool _2563;\n    if (!_2554)\n    {\n        _2563 = _2526.y > _2202_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2563 = _2554;\n    }\n    bool _2570;\n    if (!_2563)\n    {\n        _2570 = _2526.z > 1.0f;\n    }\n    else\n    {\n        _2570 = _2563;\n    }\n    if (_2570)\n    {\n        return -1.0f;\n    }\n    float _2578;\n    if (_2202_fa_shadow_bias.x > 0.0f)\n    {\n        _2578 = _2202_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2578 = 1.5f * _2202_fa_shadow_info[ci].x;\n    }\n    float2 param = _2526.xy;\n    float4 param_1 = _2202_fa_shadow_rect[ci];\n    float param_2 = _2526.z - ((_2578 * (1.0f + (0.5f * _2496))) / _2478);\n    float param_3 = _2202_fa_shadow_info[ci].x;\n    float param_4 = _2478;\n    float param_5 = _2478 * 0.25f;\n    float param_6 = ((_2202_fa_shadow_info[ci].x * min(_2496, 3.0f)) * 0.5f) / _2478;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2202_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2202_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_485_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2966 = int(_2202_fa_shadow_cfg.x + 0.5f);\n    if (_2966 < 1)\n    {\n        return 1.0f;\n    }\n    float _2981 = dot(world - _2202_fa_shadow_eye.xyz, _2202_fa_shadow_fwd.xyz);\n    int param = _2966 - 1;\n    if (_2981 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2993 = _2966 > 1;\n    bool _3000;\n    if (_2993)\n    {\n        _3000 = _2981 > _2202_fa_shadow_split.x;\n    }\n    else\n    {\n        _3000 = _2993;\n    }\n    if (_3000)\n    {\n        ci = 1;\n    }\n    bool _3004 = _2966 > 2;\n    bool _3011;\n    if (_3004)\n    {\n        _3011 = _2981 > _2202_fa_shadow_split.y;\n    }\n    else\n    {\n        _3011 = _3004;\n    }\n    if (_3011)\n    {\n        ci = 2;\n    }\n    bool _3015 = _2966 > 3;\n    bool _3022;\n    if (_3015)\n    {\n        _3022 = _2981 > _2202_fa_shadow_split.z;\n    }\n    else\n    {\n        _3022 = _3015;\n    }\n    if (_3022)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2966)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _3048 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3048;\n        if (_3048 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2202_fa_shadow_cfg.y > 0.0f)\n    {\n        float _3073;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3073 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3073 = _2202_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _3092 = _2202_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3073, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _3103 = clamp((_2981 - (fa_shadow_split_at(param_7) - _3092)) / _3092, 0.0f, 1.0f);\n        if (_3103 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2966)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _3124 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3124;\n                if (_3124 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _3103);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _2636 = _485_fa_pbr.z < 0.5f;\n    bool _2643;\n    if (!_2636)\n    {\n        _2643 = _2202_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2643 = _2636;\n    }\n    if (_2643)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2202_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2656 = fa_light_texel(param);\n    float _2657 = _2656.x;\n    if (_2657 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2666 = int(_2657 + 0.5f);\n    int param_1 = _2666;\n    float4 _2670 = fa_light_texel(param_1);\n    int param_2 = _2666 + 1;\n    float4 _2675 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2678 = _2670.y;\n    if (_2678 > 0.0f)\n    {\n        float _2695 = 1.0f - smoothstep(0.75f * _2678, _2678, length(world - _2202_fa_shadow_eye.xyz));\n        fade = _2695;\n        if (_2695 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2670.x > 1.5f)\n    {\n        int param_3 = li;\n        int param_4 = fa_light_base(param_3);\n        float3 param_5 = world - fa_light_texel(param_4).xyz;\n        face = fa_cube_face(param_5);\n    }\n    int _2724 = (_2666 + 2) + (face * 6);\n    int param_6 = _2724;\n    int param_7 = _2724 + 1;\n    int param_8 = _2724 + 3;\n    float4 _2738 = fa_light_texel(param_8);\n    int param_9 = _2724 + 4;\n    float4 _2743 = fa_light_texel(param_9);\n    int param_10 = _2724 + 5;\n    float4 _2748 = fa_light_texel(param_10);\n    float _2760 = _2748.x * max(dot(_2738, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2765 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2788 = clamp(dot(n, _2738.xyz), -1.0f, 1.0f);\n    int param_11 = li;\n    int param_12 = fa_light_base(param_11);\n    float _2812 = min(sqrt(1.0f - (_2788 * _2788)) / max(abs(dot(n, world - fa_light_texel(param_12).xyz)) / max(dot(_2738, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2815 = _2675.y;\n    float _2817;\n    if (_2815 > 0.0f)\n    {\n        _2817 = _2815;\n    }\n    else\n    {\n        _2817 = 1.5f * _2760;\n    }\n    float4 _2837 = float4(world + (n * (_2817 * sqrt(1.0f - (_2765 * _2765)))), 1.0f);\n    float _2841 = dot(_2738, _2837);\n    float _2844 = _2748.y;\n    if (_2841 < _2844)\n    {\n        return 1.0f;\n    }\n    float2 _2859 = float2(dot(fa_light_texel(param_6), _2837), dot(fa_light_texel(param_7), _2837)) / _2841.xx;\n    float _2861 = _2859.x;\n    bool _2864 = _2861 < _2743.x;\n    bool _2873;\n    if (!_2864)\n    {\n        _2873 = _2861 > _2743.z;\n    }\n    else\n    {\n        _2873 = _2864;\n    }\n    bool _2882;\n    if (!_2873)\n    {\n        _2882 = _2859.y < _2743.y;\n    }\n    else\n    {\n        _2882 = _2873;\n    }\n    bool _2891;\n    if (!_2882)\n    {\n        _2891 = _2859.y > _2743.w;\n    }\n    else\n    {\n        _2891 = _2882;\n    }\n    if (_2891)\n    {\n        return 1.0f;\n    }\n    float _2897 = _2675.x;\n    float _2899;\n    if (_2897 > 0.0f)\n    {\n        _2899 = _2897;\n    }\n    else\n    {\n        _2899 = 1.5f * _2760;\n    }\n    float2 param_13 = _2859;\n    float4 param_14 = _2743;\n    float param_15 = _2841 - (_2899 * (1.0f + (0.5f * _2812)));\n    float param_16 = _2760;\n    float param_17 = 1.0f;\n    float param_18 = _2748.z * 0.25f;\n    float param_19 = (_2760 * min(_2812, 3.0f)) * 0.5f;\n    float3 param_20 = float3(1.0f, _2844, _2748.z);\n    int param_21 = int(_2670.z + 0.5f);\n    float param_22 = _2670.w;\n    return lerp(1.0f, fa_shadow_filter(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _4344 = fa_lm.z > 0.5f;\n    bool _4350;\n    if (_4344)\n    {\n        int param = li;\n        _4350 = fa_light_baked(param);\n    }\n    else\n    {\n        _4350 = _4344;\n    }\n    if (_4350)\n    {\n        int param_1 = li;\n        LightSample _6676 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _6676;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4374 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _6678 = _4374.color;\n    float _6680 = _4374.shadow;\n    if ((_4374.type == 0) && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4374.direction;\n        float _4388 = fa_shadow_factor(param_5, param_6);\n        _6680 = _4388;\n        _6678 *= _4388;\n    }\n    else\n    {\n        bool _4399 = _4374.type != 0;\n        bool _4405;\n        if (_4399)\n        {\n            _4405 = _4374.attenuation > 0.0f;\n        }\n        else\n        {\n            _4405 = _4399;\n        }\n        if (_4405)\n        {\n            int param_7 = li;\n            float3 param_8 = world_pos;\n            float3 param_9 = gn;\n            float3 param_10 = _4374.direction;\n            float _4417 = fa_shadow_local(param_7, param_8, param_9, param_10);\n            _6680 = _4417;\n            _6678 *= _4417;\n        }\n    }\n    LightSample _6695 = { _4374.direction, _6678, _4374.attenuation, _6680, _4374._distance, _4374.type };\n    return _6695;\n}\n\nfloat3 fa_ltc_tangent(float3 n, float3 v)\n{\n    float3 _4457 = v - (n * dot(v, n));\n    float3 t = _4457;\n    float _4461 = dot(_4457, _4457);\n    float l2 = _4461;\n    if (_4461 < 1.0000000133514319600180897396058e-10f)\n    {\n        float3 _4471;\n        if (abs(n.z) < 0.999000012874603271484375f)\n        {\n            _4471 = cross(n, float3(0.0f, 0.0f, 1.0f));\n        }\n        else\n        {\n            _4471 = cross(n, float3(1.0f, 0.0f, 0.0f));\n        }\n        t = _4471;\n        l2 = dot(_4471, _4471);\n    }\n    return t * rsqrt(l2);\n}\n\nfloat3 fa_ltc_local(float3 t1, float3 n, float3 p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nfloat3 fa_ltc_edge_vector(float3 a, float3 b)\n{\n    float _4506 = dot(a, a);\n    float _4510 = dot(b, b);\n    if ((_4506 < 1.0000000195414813782625560981111e-24f) || (_4510 < 1.0000000195414813782625560981111e-24f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _4524 = a * rsqrt(_4506);\n    float3 _4529 = b * rsqrt(_4510);\n    float _4533 = dot(_4524, _4529);\n    float _4536 = abs(_4533);\n    float g = (((((((((((0.0416471660137176513671875f * _4536) - 0.1924748718738555908203125f) * _4536) + 0.4179156124591827392578125f) * _4536) - 0.616057217121124267578125f) * _4536) + 0.777722418308258056640625f) * _4536) - 0.999542415142059326171875f) * _4536) + 1.570791721343994140625f;\n    if (_4533 < 0.0f)\n    {\n        g = (3.1415927410125732421875f * rsqrt(max(1.0f - (_4533 * _4533), 1.0000000116860974230803549289703e-07f))) - g;\n    }\n    return cross(_4524, _4529) * g;\n}\n\nvoid fa_ltc_clip_edge(float3 a, float3 b, inout float3 sum, inout float3 leave, inout float3 enter, inout float2 seen)\n{\n    bool _4593 = a.z > 0.0f;\n    bool _4597 = b.z > 0.0f;\n    if (_4593 && _4597)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_4593 != _4597)\n        {\n            float3 _4632 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _4632.z = 0.0f;\n            if (_4593)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _4632;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _4632;\n                seen.x = 1.0f;\n            }\n            else\n            {\n                float3 param_4 = _4632;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _4632;\n                seen.y = 1.0f;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(float4 abcd, float3 p0, float3 p1, float3 p2, float3 p3)\n{\n    float3 _4681 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _4707 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _4733 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _4759 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = 0.0f.xxx;\n    float3 leave = 0.0f.xxx;\n    float3 enter = 0.0f.xxx;\n    float3 param = _4681;\n    float3 param_1 = _4707;\n    float3 param_2 = 0.0f.xxx;\n    float3 param_3 = 0.0f.xxx;\n    float3 param_4 = 0.0f.xxx;\n    float2 param_5 = 0.0f.xx;\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _4707;\n    float3 param_7 = _4733;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _4733;\n    float3 param_13 = _4759;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _4759;\n    float3 param_19 = _4681;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5f)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875f;\n}\n\nfloat fa_ltc_rect(float4 abcd, float3 center, float3 ex, float3 ey)\n{\n    float4 param = abcd;\n    float3 param_1 = (center - ex) - ey;\n    float3 param_2 = (center + ex) - ey;\n    float3 param_3 = (center + ex) + ey;\n    float3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(float4 m, float shape, float3 pc, float3 ex, float3 ey)\n{\n    if ((shape < 0.5f) || (shape > 1.5f))\n    {\n        float4 param = m;\n        float3 param_1 = pc;\n        float3 param_2 = ex;\n        float3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    float3 _4909 = (pc + (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _4933 = (pc - (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _4949 = (pc - (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float4 param_4 = m;\n    float3 param_5 = _4909;\n    float3 param_6 = (pc + (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_7 = (pc - (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_8 = _4933;\n    float4 param_9 = m;\n    float3 param_10 = _4909;\n    float3 param_11 = _4933;\n    float3 param_12 = (pc - (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    float3 param_13 = _4949;\n    float4 param_14 = m;\n    float3 param_15 = _4909;\n    float3 param_16 = _4949;\n    float3 param_17 = (pc + (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float3 param_18 = (pc + (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nfloat2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((float2(clamp((roughness - 0.0500000007450580596923828125f) * 1.0526316165924072265625f, 0.0f, 1.0f), sqrt(clamp(1.0f - ndv, 0.0f, 1.0f))) * 63.0f) + 0.5f.xx) * 0.015625f.xx;\n}\n\nfloat3 fa_area_shade(int li, float3 world_pos, float3 n, float3 v, float3 diffuse_color, float3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _5007 = fa_light_base(param);\n    int param_1 = _5007;\n    int param_2 = _5007 + 1;\n    int param_3 = _5007 + 2;\n    int param_4 = _5007 + 4;\n    float4 _5029 = fa_light_texel(param_4);\n    int param_5 = _5007 + 5;\n    float4 _5034 = fa_light_texel(param_5);\n    int param_6 = _5007 + 6;\n    float4 _5039 = fa_light_texel(param_6);\n    float _5040 = _5039.w;\n    float3 _5045 = fa_light_texel(param_1).xyz - world_pos;\n    bool _5047 = _5040 < 1.5f;\n    bool _5054;\n    if (_5047)\n    {\n        _5054 = dot(normalize(fa_light_texel(param_3).xyz), _5045) >= 0.0f;\n    }\n    else\n    {\n        _5054 = _5047;\n    }\n    if (_5054)\n    {\n        return 0.0f.xxx;\n    }\n    bool _5063 = (_5040 > 0.5f) && _5047;\n    float _5067 = _5063 ? 1.0539000034332275390625f : 1.0f;\n    float3 _5070 = _5029.xyz;\n    float _5072 = _5029.w;\n    float3 _5078 = _5034.xyz;\n    float _5080 = _5034.w;\n    float3 up = _5078 * (_5080 * _5067);\n    float _5086;\n    if (_5063)\n    {\n        _5086 = (3.1415927410125732421875f * _5072) * _5072;\n    }\n    else\n    {\n        _5086 = (4.0f * _5072) * _5080;\n    }\n    if (_5040 > 1.5f)\n    {\n        float3 _5112 = cross(_5070, -_5045);\n        float3 perp = _5112;\n        float _5116 = dot(_5112, _5112);\n        float3 _5119;\n        if (_5116 > 1.0000000133514319600180897396058e-10f)\n        {\n            _5119 = perp * rsqrt(_5116);\n        }\n        else\n        {\n            _5119 = _5078;\n        }\n        perp = _5119;\n        up = _5119 * _5080;\n    }\n    float _5140 = max(_5086, 9.9999999747524270787835121154785e-07f);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _5150 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _5150;\n    float3 param_10 = n;\n    float3 param_11 = _5045;\n    float3 _5158 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_12 = _5150;\n    float3 param_13 = n;\n    float3 param_14 = _5070 * (_5072 * _5067);\n    float3 _5166 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_15 = _5150;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float3 _5174 = fa_ltc_local(param_15, param_16, param_17);\n    float4 param_18 = float4(1.0f, 0.0f, 0.0f, 1.0f);\n    float param_19 = _5040;\n    float3 param_20 = _5158;\n    float3 param_21 = _5166;\n    float3 param_22 = _5174;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    float2 _5193 = fa_ltc_uv(param_23, param_24) * 64.0f;\n    float2 param_25 = _5193;\n    float2 param_26 = _5193 + float2(64.0f, 0.0f);\n    float4 _5203 = fa_atlas_fetch(param_26);\n    float4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _5040;\n    float3 param_29 = _5158;\n    float3 param_30 = _5166;\n    float3 param_31 = _5174;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _5203.x) + ((f90.xxx - f0) * _5203.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875f * dot(_5045, _5045)) + _5140) / _5140) * window);\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4047 = 1.0f / alpha;\n    return ((2.0f + _4047) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _4047)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat fa_layers_coat(FaLayers L, float3 l, float3 h, float vdh)\n{\n    float _4082 = max(dot(L.nc, l), 0.0f);\n    float _4088 = max(dot(L.nc, h), 0.0f);\n    float _4097 = ((_4088 * _4088) * (L.coat_a2 - 1.0f)) + 1.0f;\n    return (((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _4097) * _4097)) * (0.5f / max(lerp((2.0f * _4082) * L.coat_ndv, _4082 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _4082)) * _4082;\n}\n\nfloat3 fa_area_layers(FaLayers L, int li, float3 world_pos, float3 n, float3 v, float3 l, float3 diffuse_color, float3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    float3 param_2 = n;\n    float3 param_3 = v;\n    float3 param_4 = diffuse_color;\n    float3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _5271;\n    if (L.sheen_on)\n    {\n        _5271 = L.sheen_scale;\n    }\n    else\n    {\n        _5271 = 1.0f;\n    }\n    float3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _5271);\n    float3 _5284 = normalize(l + v);\n    int param_10 = li;\n    float3 _5295 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _5304 = max(dot(n, l), 0.0f);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _5284), 0.0f);\n        float param_13 = _5304;\n        float param_14 = ndv;\n        result += ((L.sheen * _5295) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875f) * step(9.9999997473787516355514526367188e-05f, _5304)) * _5304) * L.keep));\n    }\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_15 = L;\n        float3 param_16 = l;\n        float3 param_17 = _5284;\n        float param_18 = max(dot(v, _5284), 0.0f);\n        result += (_5295 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _3950 = tdh / at;\n    float _3954 = bdh / ab;\n    float _3966 = ((_3950 * _3950) + (_3954 * _3954)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _3966) * _3966);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4146 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4225 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _4225) * _4225);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _4146);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _4146));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_17 = L;\n        float3 param_18 = l;\n        float3 param_19 = h;\n        float param_20 = vdh;\n        result += fa_layers_coat(param_17, param_18, param_19, param_20).xxx;\n    }\n    return result;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3353 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3356 = _3353.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3356 * _3356, exp2((-9.27999973297119140625f) * ndv)) * _3356) + _3353.y)) + _3353.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_485_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _485_fa_env_horizon.w).xyz;\n    }\n    float _3259 = rough * rough;\n    float _3289 = 0.60000002384185791015625f * _3259;\n    return lerp(lerp(_485_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_485_fa_env_horizon.xyz, _485_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3259)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3289, 0.0500000007450580596923828125f + _3289, d.y).xxx), ((_485_fa_env_sky.xyz + _485_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3259 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _3833;\n        if (L.aniso >= 0.0f)\n        {\n            _3833 = L.b;\n        }\n        else\n        {\n            _3833 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_3833, v), _3833), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3866 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _3866.x) + (L.f90.xxx * _3866.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3921 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _3921.x) + _3921.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3395 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3395.x) + _3395.y.xxx);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2202_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3148 = int(_2202_fa_shadow_cfg.x + 0.5f);\n    float _3158 = dot(world - _2202_fa_shadow_eye.xyz, _2202_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3163 = _3148 > 0;\n    bool _3172;\n    if (_3163)\n    {\n        int param = _3148 - 1;\n        _3172 = _3158 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3172 = _3163;\n    }\n    if (_3172)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3178 = _3148 > 1;\n        bool _3185;\n        if (_3178)\n        {\n            _3185 = _3158 > _2202_fa_shadow_split.x;\n        }\n        else\n        {\n            _3185 = _3178;\n        }\n        if (_3185)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3191 = _3148 > 2;\n        bool _3198;\n        if (_3191)\n        {\n            _3198 = _3158 > _2202_fa_shadow_split.y;\n        }\n        else\n        {\n            _3198 = _3191;\n        }\n        if (_3198)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3204 = _3148 > 3;\n        bool _3211;\n        if (_3204)\n        {\n            _3211 = _3158 > _2202_fa_shadow_split.z;\n        }\n        else\n        {\n            _3211 = _3204;\n        }\n        if (_3211)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _6378 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6378 = -_6378;\n    }\n    float3 _5725 = normalize(_485_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _6391 = { fa_world_pos, _6378, fa_world_tangent, fa_uv, fa_vertex_color, _5725, gl_FrontFacing };\n    SurfaceInput param_1 = _6391;\n    Surface _5733 = fa_standard_surface(param_1);\n    float3 _6409 = _5733.albedo;\n    float _6410 = _5733.alpha;\n    float3 _6411 = _5733.normal;\n    float _6412 = _5733.metallic;\n    float _6413 = _5733.roughness;\n    float _6414 = _5733.occlusion;\n    float3 _6415 = _5733.emission;\n    float _6416 = _5733.clearcoat;\n    float _6417 = _5733.clearcoat_roughness;\n    float3 _6418 = _5733.sheen_color;\n    float _6419 = _5733.sheen_roughness;\n    float _6420 = _5733.anisotropy;\n    float _6421 = _5733.anisotropy_rotation;\n    float _6422 = _5733.specular;\n    float _6423 = _5733.ior;\n    float3 _6424 = _5733.specular_color;\n    SurfaceInput _6399 = { fa_world_pos, _6378, fa_world_tangent, fa_uv, fa_vertex_color, _5725, gl_FrontFacing };\n    SurfaceInput param_2 = _6399;\n    Surface param_3 = _5733;\n    surface(param_2, param_3);\n    _6409 = param_3.albedo;\n    _6410 = param_3.alpha;\n    _6411 = param_3.normal;\n    _6412 = param_3.metallic;\n    _6413 = param_3.roughness;\n    _6414 = param_3.occlusion;\n    _6415 = param_3.emission;\n    _6416 = param_3.clearcoat;\n    _6417 = param_3.clearcoat_roughness;\n    _6418 = param_3.sheen_color;\n    _6419 = param_3.sheen_roughness;\n    _6420 = param_3.anisotropy;\n    _6421 = param_3.anisotropy_rotation;\n    _6422 = param_3.specular;\n    _6423 = param_3.ior;\n    _6424 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _6378;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6409 = param_6;\n    _6411 = param_7;\n    if (_6410 < _5761_alphaCutoff)\n    {\n        discard;\n    }\n    float3 result;\n    if (_485_fa_emissive.w > 0.5f)\n    {\n        result = _6409;\n    }\n    else\n    {\n        float3 _5783 = normalize(_6411);\n        float _5790 = clamp(_6412, 0.0f, 1.0f);\n        float _5794 = clamp(_6413, 0.0500000007450580596923828125f, 1.0f);\n        float _5798 = _5794 * _5794;\n        float _5802 = _5798 * _5798;\n        float _5807 = max(dot(_5783, _5725), 9.9999997473787516355514526367188e-05f);\n        float3 _5813 = _6409 * (1.0f - _5790);\n        float3 _5820 = lerp(0.039999999105930328369140625f.xxx, _6409, _5790.xxx);\n        float3 f0 = _5820;\n        SurfaceInput _6407 = { fa_world_pos, _6378, fa_world_tangent, fa_uv, fa_vertex_color, _5725, gl_FrontFacing };\n        SurfaceInput param_8 = _6407;\n        Surface _6490 = { _6409, _6410, _6411, _6412, _6413, _6414, _6415, _6416, _6417, _6418, _6419, _6420, _6421, _6422, _6423, _6424 };\n        Surface param_9 = _6490;\n        float3 param_10 = _5783;\n        float3 param_11 = _5725;\n        float param_12 = _5790;\n        float param_13 = _5794;\n        float3 param_14 = _5820;\n        FaLayers _5836 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _5783;\n        float3 lit = (fa_indirect_diffuse(param_15) * _5813) * _6414;\n        if (_5836.on)\n        {\n            lit *= _5836.base_scale;\n        }\n        int _5858 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5858; ln++)\n        {\n            int param_16 = ln;\n            int _5871 = fa_cl_light(param_16);\n            bool _5874 = fa_lm.z > 0.5f;\n            bool _5880;\n            if (_5874)\n            {\n                int param_17 = _5871;\n                _5880 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _5880 = _5874;\n            }\n            if (_5880)\n            {\n                continue;\n            }\n            int param_18 = _5871;\n            float3 param_19 = fa_world_pos;\n            float3 param_20 = _6378;\n            LightSample _5892 = fa_light_shadowed(param_18, param_19, param_20);\n            float _5900 = max(dot(_5783, _5892.direction), 0.0f);\n            float _5906 = _5892.attenuation * _5892.shadow;\n            float3 _5911 = normalize(_5892.direction + _5725);\n            float _5916 = max(dot(_5783, _5911), 0.0f);\n            float _5921 = max(dot(_5725, _5911), 0.0f);\n            bool _5928;\n            if (fa_light_is_area)\n            {\n                _5928 = !_5836.on;\n            }\n            else\n            {\n                _5928 = fa_light_is_area;\n            }\n            if (_5928)\n            {\n                int param_21 = _5871;\n                float3 param_22 = fa_world_pos;\n                float3 param_23 = _5783;\n                float3 param_24 = _5725;\n                float3 param_25 = _5813;\n                float3 param_26 = f0;\n                float param_27 = 1.0f;\n                float param_28 = _5794;\n                float param_29 = _5807;\n                float param_30 = _5906;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _5836;\n                    int param_32 = _5871;\n                    float3 param_33 = fa_world_pos;\n                    float3 param_34 = _5783;\n                    float3 param_35 = _5725;\n                    float3 param_36 = _5892.direction;\n                    float3 param_37 = _5813;\n                    float3 param_38 = f0;\n                    float param_39 = _5794;\n                    float param_40 = _5807;\n                    float param_41 = _5906;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_5836.on)\n                    {\n                        FaLayers param_42 = _5836;\n                        float3 param_43 = _5813;\n                        float3 param_44 = f0;\n                        float3 param_45 = _5783;\n                        float3 param_46 = _5725;\n                        float3 param_47 = _5892.direction;\n                        float3 param_48 = _5911;\n                        float param_49 = _5900;\n                        float param_50 = _5807;\n                        float param_51 = _5916;\n                        float param_52 = _5921;\n                        float param_53 = _5798;\n                        float param_54 = _5802;\n                        int param_55 = _5871;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _5906));\n                    }\n                    else\n                    {\n                        float _6034 = ((_5916 * _5916) * (_5802 - 1.0f)) + 1.0f;\n                        int param_56 = _5871;\n                        lit += (((_5813 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _5921, 5.0f))) * (((_5802 / ((3.1415927410125732421875f * _6034) * _6034)) * (0.5f / max(lerp((2.0f * _5900) * _5807, _5900 + _5807, _5798), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _5900))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_5900 * _5906));\n                    }\n                }\n            }\n        }\n        if (_5836.on)\n        {\n            FaLayers param_57 = _5836;\n            float3 param_58 = _5783;\n            float3 param_59 = _5725;\n            float3 param_60 = f0;\n            float param_61 = _5794;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _6414);\n        }\n        else\n        {\n            float3 param_62 = _5783;\n            float3 param_63 = _5725;\n            float3 param_64 = f0;\n            float param_65 = _5794;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _6414);\n        }\n        result = lit;\n    }\n    float3 _6129 = result;\n    float3 _6130 = _6129 + _6415;\n    result = _6130;\n    float3 param_66 = _6130;\n    float3 param_67 = fa_world_pos;\n    result = fa_shadow_debug(param_66, param_67);\n    bool _6139 = _485_fa_fog.w > 0.0f;\n    bool _6146;\n    if (!_6139)\n    {\n        _6146 = _485_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _6146 = _6139;\n    }\n    if (_6146)\n    {\n        float3 _6155 = fa_world_pos - _485_fa_camera_pos.xyz;\n        float _6161 = dot(_6155, _485_fa_fog_c.xyz);\n        bool _6165 = _485_fa_fog_c.w > 0.5f;\n        float _6166;\n        if (_6165)\n        {\n            _6166 = _6161;\n        }\n        else\n        {\n            _6166 = length(_6155);\n        }\n        float _6178 = _6166 - _485_fa_fog_b.x;\n        if (_6178 > 0.0f)\n        {\n            float _6187 = _485_fa_fog.w * _6178;\n            float tau = _6187 * _6187;\n            if (_485_fa_fog_b.y > 0.0f)\n            {\n                float _6203;\n                if (_6165)\n                {\n                    _6203 = fa_world_pos.y - (_485_fa_fog_c.y * _6161);\n                }\n                else\n                {\n                    _6203 = _485_fa_camera_pos.y;\n                }\n                float _6224 = lerp(_6203, fa_world_pos.y, clamp(_485_fa_fog_b.x / _6166, 0.0f, 1.0f));\n                float _6228 = fa_world_pos.y - _6224;\n                float _6233 = _6224 - _485_fa_fog_b.z;\n                float _6238 = fa_world_pos.y - _485_fa_fog_b.z;\n                bool _6241 = _6233 <= 0.0f;\n                bool _6242 = !_6241;\n                bool _6248;\n                if (_6242)\n                {\n                    _6248 = _485_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6248 = _6241;\n                }\n                float _6249;\n                if (_6248)\n                {\n                    _6249 = _485_fa_fog_b.y;\n                }\n                else\n                {\n                    _6249 = _485_fa_fog_b.y * exp(-min(_485_fa_fog_b.w * _6233, 80.0f));\n                }\n                bool _6276;\n                if (_6242)\n                {\n                    _6276 = _485_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6276 = _6241;\n                }\n                float _6277;\n                if (_6276)\n                {\n                    _6277 = _485_fa_fog_b.y * _6233;\n                }\n                else\n                {\n                    _6277 = (_485_fa_fog_b.y * (1.0f - exp(-min(_485_fa_fog_b.w * _6233, 80.0f)))) / _485_fa_fog_b.w;\n                }\n                bool _6302 = _6238 <= 0.0f;\n                bool _6309;\n                if (!_6302)\n                {\n                    _6309 = _485_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6309 = _6302;\n                }\n                float _6310;\n                if (_6309)\n                {\n                    _6310 = _485_fa_fog_b.y * _6238;\n                }\n                else\n                {\n                    _6310 = (_485_fa_fog_b.y * (1.0f - exp(-min(_485_fa_fog_b.w * _6238, 80.0f)))) / _485_fa_fog_b.w;\n                }\n                float _6337;\n                if (abs(_6228) < 0.001000000047497451305389404296875f)\n                {\n                    _6337 = _6249;\n                }\n                else\n                {\n                    _6337 = (_6310 - _6277) / _6228;\n                }\n                tau += (_6178 * max(_6337, 0.0f));\n            }\n            result = lerp(result, _485_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _6410);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_2202",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_5761",
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _3496[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _485_fa_camera_pos : packoffset(c0);\n    float4 _485_fa_ambient : packoffset(c1);\n    float4 _485_fa_base_color : packoffset(c2);\n    float4 _485_fa_emissive : packoffset(c3);\n    float4 _485_fa_model_emissive : packoffset(c4);\n    float4 _485_fa_pbr : packoffset(c5);\n    float4 _485_fa_maps : packoffset(c6);\n    float4 _485_fa_fog : packoffset(c7);\n    float4 _485_fa_fog_b : packoffset(c8);\n    float4 _485_fa_fog_c : packoffset(c9);\n    float4 _485_fa_counts : packoffset(c10);\n    float4 _485_fa_env_sky : packoffset(c11);\n    float4 _485_fa_env_horizon : packoffset(c12);\n    float4 _485_fa_time : packoffset(c13);\n    float4 _485_fa_cl_vpx : packoffset(c14);\n    float4 _485_fa_cl_vpy : packoffset(c15);\n    float4 _485_fa_cl_vpw : packoffset(c16);\n    float4 _485_fa_cl_fwd : packoffset(c17);\n    float4 _485_fa_cl_grid : packoffset(c18);\n    float4 _485_fa_cl_info : packoffset(c19);\n    float4 _485_fa_layers_a : packoffset(c20);\n    float4 _485_fa_layers_b : packoffset(c21);\n    float4 _485_fa_layers_c : packoffset(c22);\n    float4 _485_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2202_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2202_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2202_fa_shadow_info[4] : packoffset(c20);\n    float4 _2202_fa_shadow_split : packoffset(c24);\n    float4 _2202_fa_shadow_cfg : packoffset(c25);\n    float4 _2202_fa_shadow_bias : packoffset(c26);\n    float4 _2202_fa_shadow_eye : packoffset(c27);\n    float4 _2202_fa_shadow_fwd : packoffset(c28);\n    float4 _2202_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _5761_alphaCutoff : packoffset(c0);\n    float _5761_fa_pad0 : packoffset(c0.y);\n    float _5761_fa_pad1 : packoffset(c0.z);\n    float _5761_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t11);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t10);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1473 = _485_fa_cl_info.x < 0.0f;\n    bool _1480;\n    if (!_1473)\n    {\n        _1480 = _485_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1480 = _1473;\n    }\n    bool _1488;\n    if (!_1480)\n    {\n        _1488 = _485_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1488 = _1480;\n    }\n    bool _1495;\n    if (!_1488)\n    {\n        _1495 = _485_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1495 = _1488;\n    }\n    bool _1502;\n    if (!_1495)\n    {\n        _1502 = _485_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1502 = _1495;\n    }\n    if (_1502)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1512 = float4(world_pos, 1.0f);\n    float _1518 = dot(_485_fa_cl_vpw, _1512);\n    if (!(_1518 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1540 = float2(dot(_485_fa_cl_vpx, _1512), dot(_485_fa_cl_vpy, _1512)) / _1518.xx;\n    int _1544 = int(_485_fa_cl_grid.x);\n    int _1548 = int(_485_fa_cl_grid.y);\n    int param = (int(_485_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_485_fa_cl_fwd.xyz, world_pos) + _485_fa_cl_fwd.w, _485_fa_cl_grid.w) / _485_fa_cl_grid.w) * _485_fa_cl_grid.z)), 0, int(_485_fa_cl_info.y) - 1) * _1548) + clamp(int(floor(((_1540.y * 0.5f) + 0.5f) * _485_fa_cl_grid.y)), 0, _1548 - 1)) * _1544)) + clamp(int(floor(((_1540.x * 0.5f) + 0.5f) * _485_fa_cl_grid.x)), 0, _1544 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1624 = fa_cluster_texel(param);\n    return int2(int(_1624.x), int(_1624.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_485_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4317 = fa_cluster_lookup(param);\n    fa_cl_slot = _4317.x;\n    fa_cl_local = _4317.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _5395 = fa_linear_to_srgb(param);\n        c = _5395;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _5403 = fa_srgb_to_linear(param_1);\n            c = _5403;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _417;\n    if (i.front_facing)\n    {\n        _417 = i.world_normal;\n    }\n    else\n    {\n        _417 = -i.world_normal;\n    }\n    float3 _441 = normalize(i.world_tangent.xyz - (_417 * dot(_417, i.world_tangent.xyz)));\n    float3 _469 = normalize(((_441 * m.x) + ((cross(_417, _441) * i.world_tangent.w) * m.y)) + (_417 * m.z));\n    float3 _472;\n    if (i.front_facing)\n    {\n        _472 = _469;\n    }\n    else\n    {\n        _472 = -_469;\n    }\n    return _472;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _485_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _5434 = fa_tex_fix(param_2, param_3);\n    float4 _6860 = base_t;\n    _6860.x = _5434.x;\n    _6860.y = _5434.y;\n    _6860.z = _5434.z;\n    base_t = _6860;\n    float4 _5448 = (_6860 * _485_fa_base_color) * i.vertex_color;\n    float3 _6698 = i.world_normal;\n    if (_485_fa_maps.z > 0.5f)\n    {\n        float param_4 = _485_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _5480 = fa_tex_fix(param_6, param_7);\n        float3 _5483 = (_5480 * 2.0f) - 1.0f.xxx;\n        float2 _5488 = _5483.xy * _485_fa_maps.x;\n        float3 _6868 = _5483;\n        _6868.x = _5488.x;\n        _6868.y = _5488.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _6868;\n        _6698 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _485_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _5516 = fa_tex_fix(param_12, param_13);\n    float4 _6871 = mrt;\n    _6871.x = _5516.x;\n    _6871.y = _5516.y;\n    _6871.z = _5516.z;\n    mrt = _6871;\n    float4 _5544 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _485_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _5544.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _5555 = fa_tex_fix(param_16, param_17);\n    float param_18 = _485_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _5585 = fa_tex_fix(param_20, param_21);\n    float _6703 = _485_fa_layers_a.x;\n    float _6704 = _485_fa_layers_a.y;\n    float _6707 = _485_fa_layers_a.z;\n    float _6706 = _485_fa_layers_b.w;\n    float _6709 = _485_fa_layers_c.x;\n    if (_485_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_485_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _6703 *= _5555.y;\n            _6704 *= _5555.z;\n            _6706 *= _5544.w;\n        }\n        if (_485_fa_layers_c.z > 1.5f)\n        {\n            _6707 *= mrt.x;\n            _6709 *= mrt.w;\n        }\n    }\n    Surface _6728 = { _5448.xyz, _5448.w, _6698, clamp(_485_fa_pbr.x * _5516.z, 0.0f, 1.0f), clamp(_485_fa_pbr.y * _5516.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_485_fa_maps.y * (_5555.x - 1.0f)), _485_fa_emissive.xyz + (_485_fa_model_emissive.xyz * _5585), _6703, _6704, _485_fa_layers_b.xyz, _6706, _6707, _485_fa_layers_a.w, _6709, _485_fa_layers_c.y, _485_fa_layers_d.xyz };\n    return _6728;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1704 = rect.zw - rect.xy;\n    float2 _1708 = _1704 * atlas;\n    float2 _1712 = ddx * _1708;\n    float2 _1716 = ddy * _1708;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1704), clamp(0.5f * log2(max(max(dot(_1712, _1712), dot(_1716, _1716)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1749 = _485_fa_counts.y < 0.5f;\n    bool _1756;\n    if (!_1749)\n    {\n        _1756 = _485_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1756 = _1749;\n    }\n    if (_1756)\n    {\n        return;\n    }\n    float3 _1762 = ddx(world_pos);\n    float3 _1765 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1769 = fa_cluster_texel(param);\n    int _1773 = int(_1769.w);\n    if (_1773 < 1)\n    {\n        return;\n    }\n    int _1783 = int(_485_fa_counts.y + 0.5f);\n    int param_1 = _1783;\n    float4 _1787 = fa_light_texel(param_1);\n    float2 _1790 = _1787.yz;\n    int _1794 = int(_1787.w);\n    int param_2 = _1783 + 1;\n    float4 _1799 = fa_light_texel(param_2);\n    float _1800 = _1799.x;\n    int _1806 = int(_485_fa_counts.w + 0.5f) - 1;\n    int _1810 = int(_1769.z);\n    float3 _2075;\n    for (int k = 0; k < _1773; k++)\n    {\n        int _1823 = _1810 + k;\n        int param_3 = _1794 + (_1823 >> 2);\n        int _1840 = (_1783 + 2) + (int(fa_light_texel(param_3)[_1823 & 3]) * 7);\n        int param_4 = _1840 + 6;\n        float4 _1845 = fa_light_texel(param_4);\n        if (((int(_1845.w + 0.5f) >> _1806) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1840;\n        float4 _1860 = fa_light_texel(param_5);\n        int param_6 = _1840 + 1;\n        float4 _1865 = fa_light_texel(param_6);\n        int param_7 = _1840 + 2;\n        float4 _1870 = fa_light_texel(param_7);\n        float3 _1873 = _1860.xyz;\n        float _1878 = dot(_1873, world_pos) + _1860.w;\n        float3 _1880 = _1865.xyz;\n        float _1885 = dot(_1880, world_pos) + _1865.w;\n        float3 _1887 = _1870.xyz;\n        float _1892 = dot(_1887, world_pos) + _1870.w;\n        bool _1897 = abs(_1878) > 0.5f;\n        bool _1905;\n        if (!_1897)\n        {\n            _1905 = abs(_1885) > 0.5f;\n        }\n        else\n        {\n            _1905 = _1897;\n        }\n        bool _1913;\n        if (!_1905)\n        {\n            _1913 = abs(_1892) > 0.5f;\n        }\n        else\n        {\n            _1913 = _1905;\n        }\n        if (_1913)\n        {\n            continue;\n        }\n        float _1928 = clamp(dot(geo_normal, normalize(_1887)) * _1845.z, 0.0f, 1.0f);\n        if (_1928 <= 0.0f)\n        {\n            continue;\n        }\n        float _1948 = (clamp((0.5f - abs(_1892)) * 10.0f, 0.0f, 1.0f) * _1928) * _1845.x;\n        float2 _1956 = float2(_1878 + 0.5f, 0.5f - _1885);\n        float2 _1966 = float2(dot(_1873, _1762), dot(_1880, _1762));\n        float2 _1976 = float2(dot(_1873, _1765), dot(_1880, _1765));\n        int param_8 = _1840 + 5;\n        float4 _1981 = fa_light_texel(param_8);\n        int param_9 = _1840 + 3;\n        float4 _1986 = fa_light_texel(param_9);\n        int param_10 = _1840 + 4;\n        float4 _1991 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1981.xyz;\n        bool _2001 = _1986.z > _1986.x;\n        if (_2001)\n        {\n            float4 param_11 = _1986;\n            float2 param_12 = _1956;\n            float2 param_13 = _1790;\n            float2 param_14 = _1966;\n            float2 param_15 = _1976;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1800 > 0.5f) && (_1800 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _2027 = fa_dc_to_linear(param_16);\n                float4 _6778 = tx;\n                _6778.x = _2027.x;\n                _6778.y = _2027.y;\n                _6778.z = _2027.z;\n                tx = _6778;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1948 * tex_a) * _1981.w, 0.0f, 1.0f).xxx);\n        if (_1991.z > _1991.x)\n        {\n            float4 param_17 = _1991;\n            float2 param_18 = _1956;\n            float2 param_19 = _1790;\n            float2 param_20 = _1966;\n            float2 param_21 = _1976;\n            float4 _2071 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1800 > 1.5f)\n            {\n                float3 param_22 = _2071.xyz;\n                float3 _2081 = fa_dc_to_srgb(param_22);\n                _2075 = _2081;\n            }\n            else\n            {\n                _2075 = _2071.xyz;\n            }\n            float3 _2090 = (_2075 * 2.0f) - 1.0f.xxx;\n            float2 _2095 = _2090.xy * _1845.y;\n            float3 _2117 = (normalize(_1873) * _2095.x) + (normalize(_1880) * _2095.y);\n            float3 _2120 = normalize(normal);\n            normal = normalize(lerp(_2120, normalize((_2120 * max(_2090.z, 0.0500000007450580596923828125f)) + (_2117 - (_2120 * dot(_2120, _2117)))), clamp(_1948 * (_2001 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3421 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3429 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3432 = int(_3421);\n    int _3435 = int(_3429);\n    float _3445 = _3429 - float(_3435);\n    int _3501 = (_3432 * 9) + _3435;\n    int _3521 = ((_3432 + 1) * 9) + _3435;\n    return lerp(lerp(_3496[_3501], _3496[_3501 + 1], _3445), lerp(_3496[_3521], _3496[_3521 + 1], _3445), _3421 - float(_3432));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _6621 = false;\n    float _6622 = 1.0f;\n    float _6623 = 1.0f;\n    float _6624 = 1.0f;\n    float _6625 = 0.0f;\n    float _6626 = 0.0f;\n    float _6627 = 0.0f;\n    float _6628 = 0.0f;\n    float _6630 = 1.0f;\n    bool _6631 = false;\n    float3 _6632 = 0.0f.xxx;\n    float _6633 = 1.0f;\n    float _6634 = 1.0f;\n    float _6635 = 1.0f;\n    float _6636 = 0.0f;\n    float _6637 = 0.0f;\n    float3 _6638 = float3(1.0f, 0.0f, 0.0f);\n    float3 _6639 = float3(0.0f, 0.0f, 1.0f);\n    float _6640 = 1.0f;\n    float _6641 = 1.0f;\n    float _3572 = clamp(s.specular, 0.0f, 1.0f);\n    float _3576 = clamp(s.ior, 1.0f, 3.0f);\n    bool _3581 = (_3572 != 1.0f) || (_3576 != 1.5f);\n    bool _3590;\n    if (!_3581)\n    {\n        _3590 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _3590 = _3581;\n    }\n    if (_3590)\n    {\n        float _3598 = (_3576 - 1.0f) / (_3576 + 1.0f);\n        f0 = lerp(min((_3598 * _3598).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _3572, s.albedo, metallic.xxx);\n        _6622 = lerp(_3572, 1.0f, metallic);\n        _6621 = true;\n    }\n    float _3625 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_3625 > 0.0f)\n    {\n        float _3633 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _6625 = _3625;\n        _6626 = _3633;\n        float _3640 = _3633 * _3633;\n        _6627 = _3640;\n        _6628 = _3640 * _3640;\n        float _3652 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _6630 = _3652;\n        _6623 = 1.0f - (_3625 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _3652, 0.0f, 1.0f), 5.0f))));\n        _6621 = true;\n    }\n    float3 _3672 = max(s.sheen_color, 0.0f.xxx);\n    float _3681 = max(_3672.x, max(_3672.y, _3672.z));\n    if (_3681 > 0.0f)\n    {\n        float _3689 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _6631 = true;\n        _6632 = _3672;\n        _6633 = _3689;\n        _6634 = _3689 * _3689;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _3689;\n        float _3706 = fa_sheen_albedo(param, param_1);\n        _6636 = _3706;\n        _6635 = 1.0f - min(_3681 * _3706, 1.0f);\n        _6621 = true;\n    }\n    _6624 = _6623 * _6635;\n    float _3725 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_3725 != 0.0f)\n    {\n        float3 _3740 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _3740;\n        if (dot(_3740, _3740) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _3752 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_3752.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _3752.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _3752.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _3756 = t;\n        float3 _3757 = normalize(_3756);\n        t = _3757;\n        float3 _3782 = normalize((_3757 * cos(s.anisotropy_rotation)) + ((cross(n, _3757) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _6638 = _3782;\n        _6639 = cross(n, _3782);\n        float _3792 = roughness * roughness;\n        float _3798 = lerp(_3792, 1.0f, _3725 * _3725);\n        bool _3800 = _3725 > 0.0f;\n        _6640 = _3800 ? _3798 : _3792;\n        _6641 = _3800 ? _3792 : _3798;\n        _6637 = _3725;\n        _6621 = true;\n    }\n    FaLayers _6663 = { _6621, _6622, _6623, _6624, _6625, _6626, _6627, _6628, i.world_normal, _6630, _6631, _6632, _6633, _6634, _6635, _6636, _6637, _6638, _6639, _6640, _6641 };\n    return _6663;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_485_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _485_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_485_fa_cl_info.x) + int(_485_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_485_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _556_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _556_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _722 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _735 = (c - (ru * hx)) - p;\n        float3 _741 = ru * (2.0f * hx);\n        float _747 = max(dot(_741, _741), 9.9999999392252902907785028219223e-09f);\n        float _751 = dot(_735, _741);\n        float t = clamp((-_751) / _747, 0.0f, 1.0f);\n        if (_722)\n        {\n            float _766 = dot(r, _741);\n            float _772 = _747 - (_766 * _766);\n            if (abs(_772) > (9.9999997473787516355514526367188e-06f * _747))\n            {\n                t = clamp(((dot(r, _735) * _766) - _751) / _772, 0.0f, 1.0f);\n            }\n        }\n        return (p + _735) + (_741 * t);\n    }\n    float3 q = p;\n    float _804 = dot(r, axis);\n    bool _812;\n    if (_722)\n    {\n        _812 = abs(_804) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _812 = _722;\n    }\n    if (_812)\n    {\n        float _822 = dot(c - p, axis) / _804;\n        if (_822 > 0.0f)\n        {\n            q = p + (r * _822);\n        }\n    }\n    float3 _835 = q - c;\n    float2 xy = float2(dot(_835, ru), dot(_835, uu));\n    if (shape > 0.5f)\n    {\n        float _850 = length(xy);\n        if (_850 > hx)\n        {\n            xy *= (hx / _850);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _643 = abs(d);\n    float _645 = _643.x;\n    float _647 = _643.y;\n    bool _648 = _645 >= _647;\n    bool _656;\n    if (_648)\n    {\n        _656 = _645 >= _643.z;\n    }\n    else\n    {\n        _656 = _648;\n    }\n    int _657;\n    if (_656)\n    {\n        _657 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _670;\n        if (_647 >= _643.z)\n        {\n            _670 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _670 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _657 = _670;\n    }\n    return _657;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _596 = dot(d, right);\n    float _600 = dot(d, up);\n    float _611;\n    if (((_596 * _596) + (_600 * _600)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _611 = atan2(_600, _596) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _611 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_611 - floor(_611)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _888 = fa_light_base(param);\n    bool _892 = _485_fa_ambient.w > 4.5f;\n    int param_1 = _888;\n    float4 _896 = fa_light_texel(param_1);\n    int param_2 = _888 + 1;\n    float4 _901 = fa_light_texel(param_2);\n    float _904 = _901.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _916 = _892 && (_904 > 2.5f);\n    fa_light_is_area = _916;\n    bool _918 = _904 < 0.5f;\n    float3 l;\n    if (_918)\n    {\n        l = normalize(_896.xyz);\n        if (_892)\n        {\n            int param_3 = _888 + 6;\n            float4 _932 = fa_light_texel(param_3);\n            if (_932.z > 0.5f)\n            {\n                int param_4 = _888 + 4;\n                float4 _942 = fa_light_texel(param_4);\n                int param_5 = _888 + 5;\n                float4 _947 = fa_light_texel(param_5);\n                float2 param_6 = _932.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _942.xyz) * _942.w, (-dot(world_pos, _947.xyz)) * _947.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _977 = _896.xyz;\n        float3 _979 = _977 - world_pos;\n        float3 to_light = _979;\n        float _982 = length(_979);\n        float reach = _982;\n        bool front = true;\n        if (_916)\n        {\n            int param_8 = _888 + 7;\n            reach = max(_982 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _888 + 4;\n            float4 _1006 = fa_light_texel(param_9);\n            int param_10 = _888 + 5;\n            float4 _1011 = fa_light_texel(param_10);\n            int param_11 = _888 + 6;\n            float4 _1016 = fa_light_texel(param_11);\n            float _1017 = _1016.w;\n            int param_12 = _888 + 2;\n            float3 _1024 = normalize(fa_light_texel(param_12).xyz);\n            bool _1026 = _1017 > 1.5f;\n            bool _1034;\n            if (!_1026)\n            {\n                _1034 = dot(_1024, to_light) < 0.0f;\n            }\n            else\n            {\n                _1034 = _1026;\n            }\n            front = _1034;\n            float3 r = 0.0f.xxx;\n            float3 _1043 = _485_fa_camera_pos.xyz - world_pos;\n            bool _1047 = dot(n, n) > 0.5f;\n            bool _1055;\n            if (_1047)\n            {\n                _1055 = dot(_1043, _1043) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _1055 = _1047;\n            }\n            if (_1055)\n            {\n                r = reflect(-normalize(_1043), normalize(n));\n            }\n            float3 param_13 = _977;\n            float3 param_14 = _1024;\n            float3 param_15 = _1006.xyz;\n            float3 param_16 = _1011.xyz;\n            float param_17 = _1006.w;\n            float param_18 = _1011.w;\n            float param_19 = _1017;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1091 = length(to_light);\n        dist = _1091;\n        l = to_light / max(_1091, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1105 = reach / max(_896.w, 0.001000000047497451305389404296875f);\n        float _1111 = clamp(1.0f - (_1105 * _1105), 0.0f, 1.0f);\n        float _1113;\n        if (front)\n        {\n            _1113 = _1111 * _1111;\n        }\n        else\n        {\n            _1113 = 0.0f;\n        }\n        atten = _1113;\n        bool _1124 = _904 < 2.5f;\n        if ((_904 > 1.5f) && _1124)\n        {\n            int param_22 = _888 + 2;\n            float4 _1132 = fa_light_texel(param_22);\n            float _1142 = _1132.w;\n            int param_23 = _888 + 3;\n            float4 _1147 = fa_light_texel(param_23);\n            float _1148 = _1147.x;\n            float cos_inner = _1148;\n            if (_1148 > 1.5f)\n            {\n                cos_inner = lerp(_1142, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1142, cos_inner, dot(-l, normalize(_1132.xyz)));\n        }\n        if (_892 && (_904 < 1.5f))\n        {\n            int param_24 = _888 + 6;\n            float4 _1172 = fa_light_texel(param_24);\n            if (_1172.z > 0.5f)\n            {\n                float3 _1180 = -to_light;\n                int param_25 = _888 + 4;\n                int param_26 = _888 + 5;\n                float3 _1194 = fa_light_texel(param_25).xyz;\n                float3 _1198 = fa_light_texel(param_26).xyz;\n                float3 _1207 = float3(dot(_1180, _1194), dot(_1180, _1198), dot(_1180, cross(_1194, _1198)));\n                float3 param_27 = _1207;\n                int _1211 = fa_cube_face(param_27);\n                int param_28 = _1211;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1238 = float2(dot(_1207, cross(param_29, param_30)), dot(_1207, param_30)) / max(dot(_1207, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1242 = _1211 / 3;\n                float2 param_31 = _1172.xy + (float2(float(_1211 - (_1242 * 3)), float(_1242)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1238.x), 0.5f - (0.5f * _1238.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _888 + 7;\n            float4 _1272 = fa_light_texel(param_33);\n            if (_1272.z > 0.5f)\n            {\n                int param_34 = _888 + 2;\n                int param_35 = _888 + 4;\n                int param_36 = _888 + 5;\n                float2 param_37 = _1272.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_892 && _1124)\n            {\n                int param_42 = _888 + 6;\n                float4 _1319 = fa_light_texel(param_42);\n                int param_43 = _888 + 7;\n                float4 _1324 = fa_light_texel(param_43);\n                bool _1327 = _1319.z > 0.5f;\n                bool _1334;\n                if (!_1327)\n                {\n                    _1334 = _1324.z > 0.5f;\n                }\n                else\n                {\n                    _1334 = _1327;\n                }\n                if (_1334)\n                {\n                    int param_44 = _888 + 2;\n                    float4 _1341 = fa_light_texel(param_44);\n                    float3 _1345 = normalize(_1341.xyz);\n                    int param_45 = _888 + 4;\n                    float4 _1350 = fa_light_texel(param_45);\n                    int param_46 = _888 + 5;\n                    float4 _1355 = fa_light_texel(param_46);\n                    if (_1327)\n                    {\n                        float3 _1363 = -to_light;\n                        float _1370 = _1341.w;\n                        float _1386 = 0.5f / max(dot(_1363, _1345) * (sqrt(max(1.0f - (_1370 * _1370), 0.0f)) / max(_1370, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1319.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1363, _1350.xyz) * _1386), 0.5f - (dot(_1363, _1355.xyz) * _1386));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1324.z > 0.5f)\n                    {\n                        float2 param_49 = _1324.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1345;\n                        float3 param_52 = _1350.xyz;\n                        float3 param_53 = _1355.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _6609 = _901.xyz * atten;\n    if (_892)\n    {\n        _6609 *= fa_light_tint;\n    }\n    int _1455;\n    if (_918)\n    {\n        _1455 = 0;\n    }\n    else\n    {\n        _1455 = ((_904 > 1.5f) && (_904 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _6620 = { l, _6609, atten, 1.0f, dist, _1455 };\n    return _6620;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2192;\n    if (i == 0)\n    {\n        _2192 = _2202_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2208;\n        if (i == 1)\n        {\n            _2208 = _2202_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2216;\n            if (i == 2)\n            {\n                _2216 = _2202_fa_shadow_split.z;\n            }\n            else\n            {\n                _2216 = _2202_fa_shadow_split.w;\n            }\n            _2208 = _2216;\n        }\n        _2192 = _2208;\n    }\n    return _2192;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2249 = fa_shadow_depth(param, param_1);\n    float _2253;\n    if (conv.x < 0.5f)\n    {\n        _2253 = _2249;\n    }\n    else\n    {\n        _2253 = (conv.y * conv.z) / (conv.z - (_2249 * (conv.z - conv.y)));\n    }\n    return _2253;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2180 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2180), sin(_2180)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2299 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2308;\n        if (k < 0.0f)\n        {\n            _2308 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2308 = k;\n        }\n        float _2328 = clamp((_2308 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2299;\n            float2 _2347 = fa_shadow_vogel(param_3, param_4, param_5) * _2328;\n            float2 param_6 = uv + (_2347 * _2202_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2359 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2359 < (zr - (length(_2347) * plane)))\n            {\n                sum += _2359;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2385 = sum / cnt;\n        float _2395;\n        if (k < 0.0f)\n        {\n            _2395 = (-k) / max(_2385, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2395 = k;\n        }\n        radius = clamp(((max(zr - _2385, 0.0f) * unit) * _2395) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2417 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2417; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2417;\n        float param_11 = _2299;\n        float2 _2436 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2436 * _2202_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2436) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2417);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2478 = max(_2202_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2483 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2489 = sqrt(1.0f - (_2483 * _2483));\n    float _2496 = min(_2489 / max(_2483, 0.20000000298023223876953125f), 4.0f);\n    float _2501;\n    if (_2202_fa_shadow_bias.y > 0.0f)\n    {\n        _2501 = _2202_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2501 = 1.5f * _2202_fa_shadow_info[ci].x;\n    }\n    float4 _2526 = mul(float4(world + (n * (_2501 * _2489)), 1.0f), _2202_fa_shadow_mat[ci]);\n    float _2533 = _2526.x;\n    bool _2536 = _2533 < _2202_fa_shadow_rect[ci].x;\n    bool _2545;\n    if (!_2536)\n    {\n        _2545 = _2533 > _2202_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2545 = _2536;\n    }\n    bool _2554;\n    if (!_2545)\n    {\n        _2554 = _2526.y < _2202_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2554 = _2545;\n    }\n    bool _2563;\n    if (!_2554)\n    {\n        _2563 = _2526.y > _2202_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2563 = _2554;\n    }\n    bool _2570;\n    if (!_2563)\n    {\n        _2570 = _2526.z > 1.0f;\n    }\n    else\n    {\n        _2570 = _2563;\n    }\n    if (_2570)\n    {\n        return -1.0f;\n    }\n    float _2578;\n    if (_2202_fa_shadow_bias.x > 0.0f)\n    {\n        _2578 = _2202_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2578 = 1.5f * _2202_fa_shadow_info[ci].x;\n    }\n    float2 param = _2526.xy;\n    float4 param_1 = _2202_fa_shadow_rect[ci];\n    float param_2 = _2526.z - ((_2578 * (1.0f + (0.5f * _2496))) / _2478);\n    float param_3 = _2202_fa_shadow_info[ci].x;\n    float param_4 = _2478;\n    float param_5 = _2478 * 0.25f;\n    float param_6 = ((_2202_fa_shadow_info[ci].x * min(_2496, 3.0f)) * 0.5f) / _2478;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2202_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2202_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_485_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2966 = int(_2202_fa_shadow_cfg.x + 0.5f);\n    if (_2966 < 1)\n    {\n        return 1.0f;\n    }\n    float _2981 = dot(world - _2202_fa_shadow_eye.xyz, _2202_fa_shadow_fwd.xyz);\n    int param = _2966 - 1;\n    if (_2981 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2993 = _2966 > 1;\n    bool _3000;\n    if (_2993)\n    {\n        _3000 = _2981 > _2202_fa_shadow_split.x;\n    }\n    else\n    {\n        _3000 = _2993;\n    }\n    if (_3000)\n    {\n        ci = 1;\n    }\n    bool _3004 = _2966 > 2;\n    bool _3011;\n    if (_3004)\n    {\n        _3011 = _2981 > _2202_fa_shadow_split.y;\n    }\n    else\n    {\n        _3011 = _3004;\n    }\n    if (_3011)\n    {\n        ci = 2;\n    }\n    bool _3015 = _2966 > 3;\n    bool _3022;\n    if (_3015)\n    {\n        _3022 = _2981 > _2202_fa_shadow_split.z;\n    }\n    else\n    {\n        _3022 = _3015;\n    }\n    if (_3022)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2966)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _3048 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3048;\n        if (_3048 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2202_fa_shadow_cfg.y > 0.0f)\n    {\n        float _3073;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3073 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3073 = _2202_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _3092 = _2202_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3073, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _3103 = clamp((_2981 - (fa_shadow_split_at(param_7) - _3092)) / _3092, 0.0f, 1.0f);\n        if (_3103 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2966)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _3124 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3124;\n                if (_3124 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _3103);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _2636 = _485_fa_pbr.z < 0.5f;\n    bool _2643;\n    if (!_2636)\n    {\n        _2643 = _2202_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2643 = _2636;\n    }\n    if (_2643)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2202_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2656 = fa_light_texel(param);\n    float _2657 = _2656.x;\n    if (_2657 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2666 = int(_2657 + 0.5f);\n    int param_1 = _2666;\n    float4 _2670 = fa_light_texel(param_1);\n    int param_2 = _2666 + 1;\n    float4 _2675 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2678 = _2670.y;\n    if (_2678 > 0.0f)\n    {\n        float _2695 = 1.0f - smoothstep(0.75f * _2678, _2678, length(world - _2202_fa_shadow_eye.xyz));\n        fade = _2695;\n        if (_2695 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2670.x > 1.5f)\n    {\n        int param_3 = li;\n        int param_4 = fa_light_base(param_3);\n        float3 param_5 = world - fa_light_texel(param_4).xyz;\n        face = fa_cube_face(param_5);\n    }\n    int _2724 = (_2666 + 2) + (face * 6);\n    int param_6 = _2724;\n    int param_7 = _2724 + 1;\n    int param_8 = _2724 + 3;\n    float4 _2738 = fa_light_texel(param_8);\n    int param_9 = _2724 + 4;\n    float4 _2743 = fa_light_texel(param_9);\n    int param_10 = _2724 + 5;\n    float4 _2748 = fa_light_texel(param_10);\n    float _2760 = _2748.x * max(dot(_2738, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2765 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2788 = clamp(dot(n, _2738.xyz), -1.0f, 1.0f);\n    int param_11 = li;\n    int param_12 = fa_light_base(param_11);\n    float _2812 = min(sqrt(1.0f - (_2788 * _2788)) / max(abs(dot(n, world - fa_light_texel(param_12).xyz)) / max(dot(_2738, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2815 = _2675.y;\n    float _2817;\n    if (_2815 > 0.0f)\n    {\n        _2817 = _2815;\n    }\n    else\n    {\n        _2817 = 1.5f * _2760;\n    }\n    float4 _2837 = float4(world + (n * (_2817 * sqrt(1.0f - (_2765 * _2765)))), 1.0f);\n    float _2841 = dot(_2738, _2837);\n    float _2844 = _2748.y;\n    if (_2841 < _2844)\n    {\n        return 1.0f;\n    }\n    float2 _2859 = float2(dot(fa_light_texel(param_6), _2837), dot(fa_light_texel(param_7), _2837)) / _2841.xx;\n    float _2861 = _2859.x;\n    bool _2864 = _2861 < _2743.x;\n    bool _2873;\n    if (!_2864)\n    {\n        _2873 = _2861 > _2743.z;\n    }\n    else\n    {\n        _2873 = _2864;\n    }\n    bool _2882;\n    if (!_2873)\n    {\n        _2882 = _2859.y < _2743.y;\n    }\n    else\n    {\n        _2882 = _2873;\n    }\n    bool _2891;\n    if (!_2882)\n    {\n        _2891 = _2859.y > _2743.w;\n    }\n    else\n    {\n        _2891 = _2882;\n    }\n    if (_2891)\n    {\n        return 1.0f;\n    }\n    float _2897 = _2675.x;\n    float _2899;\n    if (_2897 > 0.0f)\n    {\n        _2899 = _2897;\n    }\n    else\n    {\n        _2899 = 1.5f * _2760;\n    }\n    float2 param_13 = _2859;\n    float4 param_14 = _2743;\n    float param_15 = _2841 - (_2899 * (1.0f + (0.5f * _2812)));\n    float param_16 = _2760;\n    float param_17 = 1.0f;\n    float param_18 = _2748.z * 0.25f;\n    float param_19 = (_2760 * min(_2812, 3.0f)) * 0.5f;\n    float3 param_20 = float3(1.0f, _2844, _2748.z);\n    int param_21 = int(_2670.z + 0.5f);\n    float param_22 = _2670.w;\n    return lerp(1.0f, fa_shadow_filter(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _4344 = fa_lm.z > 0.5f;\n    bool _4350;\n    if (_4344)\n    {\n        int param = li;\n        _4350 = fa_light_baked(param);\n    }\n    else\n    {\n        _4350 = _4344;\n    }\n    if (_4350)\n    {\n        int param_1 = li;\n        LightSample _6676 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _6676;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4374 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _6678 = _4374.color;\n    float _6680 = _4374.shadow;\n    if ((_4374.type == 0) && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4374.direction;\n        float _4388 = fa_shadow_factor(param_5, param_6);\n        _6680 = _4388;\n        _6678 *= _4388;\n    }\n    else\n    {\n        bool _4399 = _4374.type != 0;\n        bool _4405;\n        if (_4399)\n        {\n            _4405 = _4374.attenuation > 0.0f;\n        }\n        else\n        {\n            _4405 = _4399;\n        }\n        if (_4405)\n        {\n            int param_7 = li;\n            float3 param_8 = world_pos;\n            float3 param_9 = gn;\n            float3 param_10 = _4374.direction;\n            float _4417 = fa_shadow_local(param_7, param_8, param_9, param_10);\n            _6680 = _4417;\n            _6678 *= _4417;\n        }\n    }\n    LightSample _6695 = { _4374.direction, _6678, _4374.attenuation, _6680, _4374._distance, _4374.type };\n    return _6695;\n}\n\nfloat3 fa_ltc_tangent(float3 n, float3 v)\n{\n    float3 _4457 = v - (n * dot(v, n));\n    float3 t = _4457;\n    float _4461 = dot(_4457, _4457);\n    float l2 = _4461;\n    if (_4461 < 1.0000000133514319600180897396058e-10f)\n    {\n        float3 _4471;\n        if (abs(n.z) < 0.999000012874603271484375f)\n        {\n            _4471 = cross(n, float3(0.0f, 0.0f, 1.0f));\n        }\n        else\n        {\n            _4471 = cross(n, float3(1.0f, 0.0f, 0.0f));\n        }\n        t = _4471;\n        l2 = dot(_4471, _4471);\n    }\n    return t * rsqrt(l2);\n}\n\nfloat3 fa_ltc_local(float3 t1, float3 n, float3 p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nfloat3 fa_ltc_edge_vector(float3 a, float3 b)\n{\n    float _4506 = dot(a, a);\n    float _4510 = dot(b, b);\n    if ((_4506 < 1.0000000195414813782625560981111e-24f) || (_4510 < 1.0000000195414813782625560981111e-24f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _4524 = a * rsqrt(_4506);\n    float3 _4529 = b * rsqrt(_4510);\n    float _4533 = dot(_4524, _4529);\n    float _4536 = abs(_4533);\n    float g = (((((((((((0.0416471660137176513671875f * _4536) - 0.1924748718738555908203125f) * _4536) + 0.4179156124591827392578125f) * _4536) - 0.616057217121124267578125f) * _4536) + 0.777722418308258056640625f) * _4536) - 0.999542415142059326171875f) * _4536) + 1.570791721343994140625f;\n    if (_4533 < 0.0f)\n    {\n        g = (3.1415927410125732421875f * rsqrt(max(1.0f - (_4533 * _4533), 1.0000000116860974230803549289703e-07f))) - g;\n    }\n    return cross(_4524, _4529) * g;\n}\n\nvoid fa_ltc_clip_edge(float3 a, float3 b, inout float3 sum, inout float3 leave, inout float3 enter, inout float2 seen)\n{\n    bool _4593 = a.z > 0.0f;\n    bool _4597 = b.z > 0.0f;\n    if (_4593 && _4597)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_4593 != _4597)\n        {\n            float3 _4632 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _4632.z = 0.0f;\n            if (_4593)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _4632;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _4632;\n                seen.x = 1.0f;\n            }\n            else\n            {\n                float3 param_4 = _4632;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _4632;\n                seen.y = 1.0f;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(float4 abcd, float3 p0, float3 p1, float3 p2, float3 p3)\n{\n    float3 _4681 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _4707 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _4733 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _4759 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = 0.0f.xxx;\n    float3 leave = 0.0f.xxx;\n    float3 enter = 0.0f.xxx;\n    float3 param = _4681;\n    float3 param_1 = _4707;\n    float3 param_2 = 0.0f.xxx;\n    float3 param_3 = 0.0f.xxx;\n    float3 param_4 = 0.0f.xxx;\n    float2 param_5 = 0.0f.xx;\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _4707;\n    float3 param_7 = _4733;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _4733;\n    float3 param_13 = _4759;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _4759;\n    float3 param_19 = _4681;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5f)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875f;\n}\n\nfloat fa_ltc_rect(float4 abcd, float3 center, float3 ex, float3 ey)\n{\n    float4 param = abcd;\n    float3 param_1 = (center - ex) - ey;\n    float3 param_2 = (center + ex) - ey;\n    float3 param_3 = (center + ex) + ey;\n    float3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(float4 m, float shape, float3 pc, float3 ex, float3 ey)\n{\n    if ((shape < 0.5f) || (shape > 1.5f))\n    {\n        float4 param = m;\n        float3 param_1 = pc;\n        float3 param_2 = ex;\n        float3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    float3 _4909 = (pc + (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _4933 = (pc - (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _4949 = (pc - (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float4 param_4 = m;\n    float3 param_5 = _4909;\n    float3 param_6 = (pc + (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_7 = (pc - (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_8 = _4933;\n    float4 param_9 = m;\n    float3 param_10 = _4909;\n    float3 param_11 = _4933;\n    float3 param_12 = (pc - (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    float3 param_13 = _4949;\n    float4 param_14 = m;\n    float3 param_15 = _4909;\n    float3 param_16 = _4949;\n    float3 param_17 = (pc + (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float3 param_18 = (pc + (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nfloat2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((float2(clamp((roughness - 0.0500000007450580596923828125f) * 1.0526316165924072265625f, 0.0f, 1.0f), sqrt(clamp(1.0f - ndv, 0.0f, 1.0f))) * 63.0f) + 0.5f.xx) * 0.015625f.xx;\n}\n\nfloat3 fa_area_shade(int li, float3 world_pos, float3 n, float3 v, float3 diffuse_color, float3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _5007 = fa_light_base(param);\n    int param_1 = _5007;\n    int param_2 = _5007 + 1;\n    int param_3 = _5007 + 2;\n    int param_4 = _5007 + 4;\n    float4 _5029 = fa_light_texel(param_4);\n    int param_5 = _5007 + 5;\n    float4 _5034 = fa_light_texel(param_5);\n    int param_6 = _5007 + 6;\n    float4 _5039 = fa_light_texel(param_6);\n    float _5040 = _5039.w;\n    float3 _5045 = fa_light_texel(param_1).xyz - world_pos;\n    bool _5047 = _5040 < 1.5f;\n    bool _5054;\n    if (_5047)\n    {\n        _5054 = dot(normalize(fa_light_texel(param_3).xyz), _5045) >= 0.0f;\n    }\n    else\n    {\n        _5054 = _5047;\n    }\n    if (_5054)\n    {\n        return 0.0f.xxx;\n    }\n    bool _5063 = (_5040 > 0.5f) && _5047;\n    float _5067 = _5063 ? 1.0539000034332275390625f : 1.0f;\n    float3 _5070 = _5029.xyz;\n    float _5072 = _5029.w;\n    float3 _5078 = _5034.xyz;\n    float _5080 = _5034.w;\n    float3 up = _5078 * (_5080 * _5067);\n    float _5086;\n    if (_5063)\n    {\n        _5086 = (3.1415927410125732421875f * _5072) * _5072;\n    }\n    else\n    {\n        _5086 = (4.0f * _5072) * _5080;\n    }\n    if (_5040 > 1.5f)\n    {\n        float3 _5112 = cross(_5070, -_5045);\n        float3 perp = _5112;\n        float _5116 = dot(_5112, _5112);\n        float3 _5119;\n        if (_5116 > 1.0000000133514319600180897396058e-10f)\n        {\n            _5119 = perp * rsqrt(_5116);\n        }\n        else\n        {\n            _5119 = _5078;\n        }\n        perp = _5119;\n        up = _5119 * _5080;\n    }\n    float _5140 = max(_5086, 9.9999999747524270787835121154785e-07f);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _5150 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _5150;\n    float3 param_10 = n;\n    float3 param_11 = _5045;\n    float3 _5158 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_12 = _5150;\n    float3 param_13 = n;\n    float3 param_14 = _5070 * (_5072 * _5067);\n    float3 _5166 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_15 = _5150;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float3 _5174 = fa_ltc_local(param_15, param_16, param_17);\n    float4 param_18 = float4(1.0f, 0.0f, 0.0f, 1.0f);\n    float param_19 = _5040;\n    float3 param_20 = _5158;\n    float3 param_21 = _5166;\n    float3 param_22 = _5174;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    float2 _5193 = fa_ltc_uv(param_23, param_24) * 64.0f;\n    float2 param_25 = _5193;\n    float2 param_26 = _5193 + float2(64.0f, 0.0f);\n    float4 _5203 = fa_atlas_fetch(param_26);\n    float4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _5040;\n    float3 param_29 = _5158;\n    float3 param_30 = _5166;\n    float3 param_31 = _5174;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _5203.x) + ((f90.xxx - f0) * _5203.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875f * dot(_5045, _5045)) + _5140) / _5140) * window);\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4047 = 1.0f / alpha;\n    return ((2.0f + _4047) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _4047)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat fa_layers_coat(FaLayers L, float3 l, float3 h, float vdh)\n{\n    float _4082 = max(dot(L.nc, l), 0.0f);\n    float _4088 = max(dot(L.nc, h), 0.0f);\n    float _4097 = ((_4088 * _4088) * (L.coat_a2 - 1.0f)) + 1.0f;\n    return (((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _4097) * _4097)) * (0.5f / max(lerp((2.0f * _4082) * L.coat_ndv, _4082 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _4082)) * _4082;\n}\n\nfloat3 fa_area_layers(FaLayers L, int li, float3 world_pos, float3 n, float3 v, float3 l, float3 diffuse_color, float3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    float3 param_2 = n;\n    float3 param_3 = v;\n    float3 param_4 = diffuse_color;\n    float3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _5271;\n    if (L.sheen_on)\n    {\n        _5271 = L.sheen_scale;\n    }\n    else\n    {\n        _5271 = 1.0f;\n    }\n    float3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _5271);\n    float3 _5284 = normalize(l + v);\n    int param_10 = li;\n    float3 _5295 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _5304 = max(dot(n, l), 0.0f);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _5284), 0.0f);\n        float param_13 = _5304;\n        float param_14 = ndv;\n        result += ((L.sheen * _5295) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875f) * step(9.9999997473787516355514526367188e-05f, _5304)) * _5304) * L.keep));\n    }\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_15 = L;\n        float3 param_16 = l;\n        float3 param_17 = _5284;\n        float param_18 = max(dot(v, _5284), 0.0f);\n        result += (_5295 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _3950 = tdh / at;\n    float _3954 = bdh / ab;\n    float _3966 = ((_3950 * _3950) + (_3954 * _3954)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _3966) * _3966);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4146 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4225 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _4225) * _4225);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _4146);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _4146));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_17 = L;\n        float3 param_18 = l;\n        float3 param_19 = h;\n        float param_20 = vdh;\n        result += fa_layers_coat(param_17, param_18, param_19, param_20).xxx;\n    }\n    return result;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3353 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3356 = _3353.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3356 * _3356, exp2((-9.27999973297119140625f) * ndv)) * _3356) + _3353.y)) + _3353.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_485_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _485_fa_env_horizon.w).xyz;\n    }\n    float _3259 = rough * rough;\n    float _3289 = 0.60000002384185791015625f * _3259;\n    return lerp(lerp(_485_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_485_fa_env_horizon.xyz, _485_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3259)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3289, 0.0500000007450580596923828125f + _3289, d.y).xxx), ((_485_fa_env_sky.xyz + _485_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3259 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _3833;\n        if (L.aniso >= 0.0f)\n        {\n            _3833 = L.b;\n        }\n        else\n        {\n            _3833 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_3833, v), _3833), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3866 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _3866.x) + (L.f90.xxx * _3866.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3921 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _3921.x) + _3921.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3395 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3395.x) + _3395.y.xxx);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2202_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3148 = int(_2202_fa_shadow_cfg.x + 0.5f);\n    float _3158 = dot(world - _2202_fa_shadow_eye.xyz, _2202_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3163 = _3148 > 0;\n    bool _3172;\n    if (_3163)\n    {\n        int param = _3148 - 1;\n        _3172 = _3158 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3172 = _3163;\n    }\n    if (_3172)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3178 = _3148 > 1;\n        bool _3185;\n        if (_3178)\n        {\n            _3185 = _3158 > _2202_fa_shadow_split.x;\n        }\n        else\n        {\n            _3185 = _3178;\n        }\n        if (_3185)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3191 = _3148 > 2;\n        bool _3198;\n        if (_3191)\n        {\n            _3198 = _3158 > _2202_fa_shadow_split.y;\n        }\n        else\n        {\n            _3198 = _3191;\n        }\n        if (_3198)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3204 = _3148 > 3;\n        bool _3211;\n        if (_3204)\n        {\n            _3211 = _3158 > _2202_fa_shadow_split.z;\n        }\n        else\n        {\n            _3211 = _3204;\n        }\n        if (_3211)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _6378 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6378 = -_6378;\n    }\n    float3 _5725 = normalize(_485_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _6391 = { fa_world_pos, _6378, fa_world_tangent, fa_uv, fa_vertex_color, _5725, gl_FrontFacing };\n    SurfaceInput param_1 = _6391;\n    Surface _5733 = fa_standard_surface(param_1);\n    float3 _6409 = _5733.albedo;\n    float _6410 = _5733.alpha;\n    float3 _6411 = _5733.normal;\n    float _6412 = _5733.metallic;\n    float _6413 = _5733.roughness;\n    float _6414 = _5733.occlusion;\n    float3 _6415 = _5733.emission;\n    float _6416 = _5733.clearcoat;\n    float _6417 = _5733.clearcoat_roughness;\n    float3 _6418 = _5733.sheen_color;\n    float _6419 = _5733.sheen_roughness;\n    float _6420 = _5733.anisotropy;\n    float _6421 = _5733.anisotropy_rotation;\n    float _6422 = _5733.specular;\n    float _6423 = _5733.ior;\n    float3 _6424 = _5733.specular_color;\n    SurfaceInput _6399 = { fa_world_pos, _6378, fa_world_tangent, fa_uv, fa_vertex_color, _5725, gl_FrontFacing };\n    SurfaceInput param_2 = _6399;\n    Surface param_3 = _5733;\n    surface(param_2, param_3);\n    _6409 = param_3.albedo;\n    _6410 = param_3.alpha;\n    _6411 = param_3.normal;\n    _6412 = param_3.metallic;\n    _6413 = param_3.roughness;\n    _6414 = param_3.occlusion;\n    _6415 = param_3.emission;\n    _6416 = param_3.clearcoat;\n    _6417 = param_3.clearcoat_roughness;\n    _6418 = param_3.sheen_color;\n    _6419 = param_3.sheen_roughness;\n    _6420 = param_3.anisotropy;\n    _6421 = param_3.anisotropy_rotation;\n    _6422 = param_3.specular;\n    _6423 = param_3.ior;\n    _6424 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _6378;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6409 = param_6;\n    _6411 = param_7;\n    if (_6410 < _5761_alphaCutoff)\n    {\n        discard;\n    }\n    float3 result;\n    if (_485_fa_emissive.w > 0.5f)\n    {\n        result = _6409;\n    }\n    else\n    {\n        float3 _5783 = normalize(_6411);\n        float _5790 = clamp(_6412, 0.0f, 1.0f);\n        float _5794 = clamp(_6413, 0.0500000007450580596923828125f, 1.0f);\n        float _5798 = _5794 * _5794;\n        float _5802 = _5798 * _5798;\n        float _5807 = max(dot(_5783, _5725), 9.9999997473787516355514526367188e-05f);\n        float3 _5813 = _6409 * (1.0f - _5790);\n        float3 _5820 = lerp(0.039999999105930328369140625f.xxx, _6409, _5790.xxx);\n        float3 f0 = _5820;\n        SurfaceInput _6407 = { fa_world_pos, _6378, fa_world_tangent, fa_uv, fa_vertex_color, _5725, gl_FrontFacing };\n        SurfaceInput param_8 = _6407;\n        Surface _6490 = { _6409, _6410, _6411, _6412, _6413, _6414, _6415, _6416, _6417, _6418, _6419, _6420, _6421, _6422, _6423, _6424 };\n        Surface param_9 = _6490;\n        float3 param_10 = _5783;\n        float3 param_11 = _5725;\n        float param_12 = _5790;\n        float param_13 = _5794;\n        float3 param_14 = _5820;\n        FaLayers _5836 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _5783;\n        float3 lit = (fa_indirect_diffuse(param_15) * _5813) * _6414;\n        if (_5836.on)\n        {\n            lit *= _5836.base_scale;\n        }\n        int _5858 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5858; ln++)\n        {\n            int param_16 = ln;\n            int _5871 = fa_cl_light(param_16);\n            bool _5874 = fa_lm.z > 0.5f;\n            bool _5880;\n            if (_5874)\n            {\n                int param_17 = _5871;\n                _5880 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _5880 = _5874;\n            }\n            if (_5880)\n            {\n                continue;\n            }\n            int param_18 = _5871;\n            float3 param_19 = fa_world_pos;\n            float3 param_20 = _6378;\n            LightSample _5892 = fa_light_shadowed(param_18, param_19, param_20);\n            float _5900 = max(dot(_5783, _5892.direction), 0.0f);\n            float _5906 = _5892.attenuation * _5892.shadow;\n            float3 _5911 = normalize(_5892.direction + _5725);\n            float _5916 = max(dot(_5783, _5911), 0.0f);\n            float _5921 = max(dot(_5725, _5911), 0.0f);\n            bool _5928;\n            if (fa_light_is_area)\n            {\n                _5928 = !_5836.on;\n            }\n            else\n            {\n                _5928 = fa_light_is_area;\n            }\n            if (_5928)\n            {\n                int param_21 = _5871;\n                float3 param_22 = fa_world_pos;\n                float3 param_23 = _5783;\n                float3 param_24 = _5725;\n                float3 param_25 = _5813;\n                float3 param_26 = f0;\n                float param_27 = 1.0f;\n                float param_28 = _5794;\n                float param_29 = _5807;\n                float param_30 = _5906;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _5836;\n                    int param_32 = _5871;\n                    float3 param_33 = fa_world_pos;\n                    float3 param_34 = _5783;\n                    float3 param_35 = _5725;\n                    float3 param_36 = _5892.direction;\n                    float3 param_37 = _5813;\n                    float3 param_38 = f0;\n                    float param_39 = _5794;\n                    float param_40 = _5807;\n                    float param_41 = _5906;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_5836.on)\n                    {\n                        FaLayers param_42 = _5836;\n                        float3 param_43 = _5813;\n                        float3 param_44 = f0;\n                        float3 param_45 = _5783;\n                        float3 param_46 = _5725;\n                        float3 param_47 = _5892.direction;\n                        float3 param_48 = _5911;\n                        float param_49 = _5900;\n                        float param_50 = _5807;\n                        float param_51 = _5916;\n                        float param_52 = _5921;\n                        float param_53 = _5798;\n                        float param_54 = _5802;\n                        int param_55 = _5871;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _5906));\n                    }\n                    else\n                    {\n                        float _6034 = ((_5916 * _5916) * (_5802 - 1.0f)) + 1.0f;\n                        int param_56 = _5871;\n                        lit += (((_5813 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _5921, 5.0f))) * (((_5802 / ((3.1415927410125732421875f * _6034) * _6034)) * (0.5f / max(lerp((2.0f * _5900) * _5807, _5900 + _5807, _5798), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _5900))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_5900 * _5906));\n                    }\n                }\n            }\n        }\n        if (_5836.on)\n        {\n            FaLayers param_57 = _5836;\n            float3 param_58 = _5783;\n            float3 param_59 = _5725;\n            float3 param_60 = f0;\n            float param_61 = _5794;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _6414);\n        }\n        else\n        {\n            float3 param_62 = _5783;\n            float3 param_63 = _5725;\n            float3 param_64 = f0;\n            float param_65 = _5794;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _6414);\n        }\n        result = lit;\n    }\n    float3 _6129 = result;\n    float3 _6130 = _6129 + _6415;\n    result = _6130;\n    float3 param_66 = _6130;\n    float3 param_67 = fa_world_pos;\n    result = fa_shadow_debug(param_66, param_67);\n    bool _6139 = _485_fa_fog.w > 0.0f;\n    bool _6146;\n    if (!_6139)\n    {\n        _6146 = _485_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _6146 = _6139;\n    }\n    if (_6146)\n    {\n        float3 _6155 = fa_world_pos - _485_fa_camera_pos.xyz;\n        float _6161 = dot(_6155, _485_fa_fog_c.xyz);\n        bool _6165 = _485_fa_fog_c.w > 0.5f;\n        float _6166;\n        if (_6165)\n        {\n            _6166 = _6161;\n        }\n        else\n        {\n            _6166 = length(_6155);\n        }\n        float _6178 = _6166 - _485_fa_fog_b.x;\n        if (_6178 > 0.0f)\n        {\n            float _6187 = _485_fa_fog.w * _6178;\n            float tau = _6187 * _6187;\n            if (_485_fa_fog_b.y > 0.0f)\n            {\n                float _6203;\n                if (_6165)\n                {\n                    _6203 = fa_world_pos.y - (_485_fa_fog_c.y * _6161);\n                }\n                else\n                {\n                    _6203 = _485_fa_camera_pos.y;\n                }\n                float _6224 = lerp(_6203, fa_world_pos.y, clamp(_485_fa_fog_b.x / _6166, 0.0f, 1.0f));\n                float _6228 = fa_world_pos.y - _6224;\n                float _6233 = _6224 - _485_fa_fog_b.z;\n                float _6238 = fa_world_pos.y - _485_fa_fog_b.z;\n                bool _6241 = _6233 <= 0.0f;\n                bool _6242 = !_6241;\n                bool _6248;\n                if (_6242)\n                {\n                    _6248 = _485_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6248 = _6241;\n                }\n                float _6249;\n                if (_6248)\n                {\n                    _6249 = _485_fa_fog_b.y;\n                }\n                else\n                {\n                    _6249 = _485_fa_fog_b.y * exp(-min(_485_fa_fog_b.w * _6233, 80.0f));\n                }\n                bool _6276;\n                if (_6242)\n                {\n                    _6276 = _485_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6276 = _6241;\n                }\n                float _6277;\n                if (_6276)\n                {\n                    _6277 = _485_fa_fog_b.y * _6233;\n                }\n                else\n                {\n                    _6277 = (_485_fa_fog_b.y * (1.0f - exp(-min(_485_fa_fog_b.w * _6233, 80.0f)))) / _485_fa_fog_b.w;\n                }\n                bool _6302 = _6238 <= 0.0f;\n                bool _6309;\n                if (!_6302)\n                {\n                    _6309 = _485_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6309 = _6302;\n                }\n                float _6310;\n                if (_6309)\n                {\n                    _6310 = _485_fa_fog_b.y * _6238;\n                }\n                else\n                {\n                    _6310 = (_485_fa_fog_b.y * (1.0f - exp(-min(_485_fa_fog_b.w * _6238, 80.0f)))) / _485_fa_fog_b.w;\n                }\n                float _6337;\n                if (abs(_6228) < 0.001000000047497451305389404296875f)\n                {\n                    _6337 = _6249;\n                }\n                else\n                {\n                    _6337 = (_6310 - _6277) / _6228;\n                }\n                tau += (_6178 * max(_6337, 0.0f));\n            }\n            result = lerp(result, _485_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _6410);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_2202",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_5761",
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _535_alphaCutoff : packoffset(c0);\n    float _535_fa_pad0 : packoffset(c0.y);\n    float _535_fa_pad1 : packoffset(c0.z);\n    float _535_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _746 = base_t;\n    _746.x = _225.x;\n    _746.y = _225.y;\n    _746.z = _225.z;\n    base_t = _746;\n    float4 _241 = (_746 * _213_fa_base_color) * i.vertex_color;\n    float3 _709 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _754 = _279;\n        _754.x = _284.x;\n        _754.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _754;\n        _709 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _757 = mrt;\n    _757.x = _313.x;\n    _757.y = _313.y;\n    _757.z = _313.z;\n    mrt = _757;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _714 = _213_fa_layers_a.x;\n    float _715 = _213_fa_layers_a.y;\n    float _718 = _213_fa_layers_a.z;\n    float _717 = _213_fa_layers_b.w;\n    float _720 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _714 *= _355.y;\n            _715 *= _355.z;\n            _717 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _718 *= mrt.x;\n            _720 *= mrt.w;\n        }\n    }\n    Surface _739 = { _241.xyz, _241.w, _709, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _714, _715, _213_fa_layers_b.xyz, _717, _718, _213_fa_layers_a.w, _720, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _739;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _620 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _620 = -_620;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _633 = { fa_world_pos, _620, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _633;\n    Surface _524 = fa_standard_surface(param);\n    float3 _644 = _524.normal;\n    SurfaceInput _641 = { fa_world_pos, _620, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _641;\n    Surface param_2 = _524;\n    surface(param_1, param_2);\n    _644 = param_2.normal;\n    if (param_2.alpha < _535_alphaCutoff)\n    {\n        discard;\n    }\n    float3 _545 = normalize(_644);\n    float3 _560 = normalize(float3(dot(fa_pre_r0, _545), dot(fa_pre_r1, _545), dot(fa_pre_r2, _545)));\n    float _572 = _560.z;\n    float2 e = _560.xy / ((abs(_560.x) + abs(_560.y)) + abs(_572)).xx;\n    if (_572 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_535",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _535_alphaCutoff : packoffset(c0);\n    float _535_fa_pad0 : packoffset(c0.y);\n    float _535_fa_pad1 : packoffset(c0.z);\n    float _535_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _746 = base_t;\n    _746.x = _225.x;\n    _746.y = _225.y;\n    _746.z = _225.z;\n    base_t = _746;\n    float4 _241 = (_746 * _213_fa_base_color) * i.vertex_color;\n    float3 _709 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _754 = _279;\n        _754.x = _284.x;\n        _754.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _754;\n        _709 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _757 = mrt;\n    _757.x = _313.x;\n    _757.y = _313.y;\n    _757.z = _313.z;\n    mrt = _757;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _714 = _213_fa_layers_a.x;\n    float _715 = _213_fa_layers_a.y;\n    float _718 = _213_fa_layers_a.z;\n    float _717 = _213_fa_layers_b.w;\n    float _720 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _714 *= _355.y;\n            _715 *= _355.z;\n            _717 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _718 *= mrt.x;\n            _720 *= mrt.w;\n        }\n    }\n    Surface _739 = { _241.xyz, _241.w, _709, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _714, _715, _213_fa_layers_b.xyz, _717, _718, _213_fa_layers_a.w, _720, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _739;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _620 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _620 = -_620;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _633 = { fa_world_pos, _620, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _633;\n    Surface _524 = fa_standard_surface(param);\n    float3 _644 = _524.normal;\n    SurfaceInput _641 = { fa_world_pos, _620, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _641;\n    Surface param_2 = _524;\n    surface(param_1, param_2);\n    _644 = param_2.normal;\n    if (param_2.alpha < _535_alphaCutoff)\n    {\n        discard;\n    }\n    float3 _545 = normalize(_644);\n    float3 _560 = normalize(float3(dot(fa_pre_r0, _545), dot(fa_pre_r1, _545), dot(fa_pre_r2, _545)));\n    float _572 = _560.z;\n    float2 e = _560.xy / ((abs(_560.x) + abs(_560.y)) + abs(_572)).xx;\n    if (_572 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_535",
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
    "shadow": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _122_fa_view_proj : packoffset(c0);\n    row_major float4x4 _122_fa_light_vp : packoffset(c4);\n    float4 _122_fa_uv_scale : packoffset(c8);\n    float4 _122_fa_time : packoffset(c9);\n    float4 _122_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float3 fa_normal : TEXCOORD5;\n    float2 fa_texcoord0 : TEXCOORD6;\n    float4 fa_tangent : TEXCOORD7;\n    float4 fa_color : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _60 = cross(model[1].xyz, model[2].xyz);\n    float _66 = (dot(model[0].xyz, _60) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _250 = { mul(float4(position, 1.0f), model).xyz, (((_60 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _66, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _66), texcoord0 * _122_fa_uv_scale.xy, color, position };\n    return _250;\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    VertexData _190 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _233 = _190.world_pos;\n    fa_world_pos = _233;\n    fa_world_normal = _190.world_normal;\n    fa_world_tangent = _190.world_tangent;\n    fa_uv = _190.uv;\n    fa_vertex_color = _190.color;\n    gl_Position = mul(float4(_233, 1.0f), _122_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _535_alphaCutoff : packoffset(c0);\n    float _535_fa_pad0 : packoffset(c0.y);\n    float _535_fa_pad1 : packoffset(c0.z);\n    float _535_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _680 = base_t;\n    _680.x = _225.x;\n    _680.y = _225.y;\n    _680.z = _225.z;\n    base_t = _680;\n    float4 _241 = (_680 * _213_fa_base_color) * i.vertex_color;\n    float3 _649 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _688 = _279;\n        _688.x = _284.x;\n        _688.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _688;\n        _649 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _691 = mrt;\n    _691.x = _313.x;\n    _691.y = _313.y;\n    _691.z = _313.z;\n    mrt = _691;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _654 = _213_fa_layers_a.x;\n    float _655 = _213_fa_layers_a.y;\n    float _658 = _213_fa_layers_a.z;\n    float _657 = _213_fa_layers_b.w;\n    float _660 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _654 *= _355.y;\n            _655 *= _355.z;\n            _657 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _658 *= mrt.x;\n            _660 *= mrt.w;\n        }\n    }\n    Surface _679 = { _241.xyz, _241.w, _649, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _654, _655, _213_fa_layers_b.xyz, _657, _658, _213_fa_layers_a.w, _660, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _679;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _560 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _560 = -_560;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _573 = { fa_world_pos, _560, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _573;\n    SurfaceInput _581 = { fa_world_pos, _560, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _581;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    if (param_2.alpha < _535_alphaCutoff)\n    {\n        discard;\n    }\n    fa_frag_color = float4(gl_FragCoord.z, 0.0f, 0.0f, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_213",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_535",
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
    "shadow_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _127_fa_view_proj : packoffset(c0);\n    row_major float4x4 _127_fa_light_vp : packoffset(c4);\n    float4 _127_fa_uv_scale : packoffset(c8);\n    float4 _127_fa_time : packoffset(c9);\n    float4 _127_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _174_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float4 fa_joints : TEXCOORD5;\n    float4 fa_weights : TEXCOORD6;\n    float3 fa_normal : TEXCOORD7;\n    float2 fa_texcoord0 : TEXCOORD8;\n    float4 fa_tangent : TEXCOORD9;\n    float4 fa_color : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _165 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_174_fa_joint_rows[_165] * weights[i]);\n        r1 += (_174_fa_joint_rows[_165 + 1] * weights[i]);\n        r2 += (_174_fa_joint_rows[_165 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _65 = cross(model[1].xyz, model[2].xyz);\n    float _71 = (dot(model[0].xyz, _65) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _371 = { mul(float4(position, 1.0f), model).xyz, (((_65 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _71, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _71), texcoord0 * _127_fa_uv_scale.xy, color, position };\n    return _371;\n}\n\nvoid vert_main()\n{\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    fa_inst_begin();\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    VertexData _311 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    float3 _354 = _311.world_pos;\n    fa_world_pos = _354;\n    fa_world_normal = _311.world_normal;\n    fa_world_tangent = _311.world_tangent;\n    fa_uv = _311.uv;\n    fa_vertex_color = _311.color;\n    gl_Position = mul(float4(_354, 1.0f), _127_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _535_alphaCutoff : packoffset(c0);\n    float _535_fa_pad0 : packoffset(c0.y);\n    float _535_fa_pad1 : packoffset(c0.z);\n    float _535_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _680 = base_t;\n    _680.x = _225.x;\n    _680.y = _225.y;\n    _680.z = _225.z;\n    base_t = _680;\n    float4 _241 = (_680 * _213_fa_base_color) * i.vertex_color;\n    float3 _649 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _688 = _279;\n        _688.x = _284.x;\n        _688.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _688;\n        _649 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _691 = mrt;\n    _691.x = _313.x;\n    _691.y = _313.y;\n    _691.z = _313.z;\n    mrt = _691;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _654 = _213_fa_layers_a.x;\n    float _655 = _213_fa_layers_a.y;\n    float _658 = _213_fa_layers_a.z;\n    float _657 = _213_fa_layers_b.w;\n    float _660 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _654 *= _355.y;\n            _655 *= _355.z;\n            _657 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _658 *= mrt.x;\n            _660 *= mrt.w;\n        }\n    }\n    Surface _679 = { _241.xyz, _241.w, _649, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _654, _655, _213_fa_layers_b.xyz, _657, _658, _213_fa_layers_a.w, _660, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _679;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _560 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _560 = -_560;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _573 = { fa_world_pos, _560, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _573;\n    SurfaceInput _581 = { fa_world_pos, _560, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _581;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    if (param_2.alpha < _535_alphaCutoff)\n    {\n        discard;\n    }\n    fa_frag_color = float4(gl_FragCoord.z, 0.0f, 0.0f, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_213",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_535",
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
