{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "70ec7addbf81ecb38af52c4a5f6d5b8f2213a6d2ef6305cbd78b3ce14189ad63",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "vertexAttributes": [
    "color1",
    "uv1"
  ],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _144_fa_view_proj : packoffset(c0);\n    row_major float4x4 _144_fa_light_vp : packoffset(c4);\n    float4 _144_fa_uv_scale : packoffset(c8);\n    float4 _144_fa_time : packoffset(c9);\n    float4 _144_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float2 fa_attr_uv1;\nstatic float4 fa_attr_color1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float2 fa_attr_uv1 : TEXCOORD9;\n    float4 fa_attr_color1 : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4 vertex_color1;\nstatic float2 vertex_uv1;\n\nvoid fa_inst_begin()\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _83 = cross(model[1].xyz, model[2].xyz);\n    float _89 = (dot(model[0].xyz, _83) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _296 = { mul(float4(position, 1.0f), model).xyz, (((_83 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _89, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _89), texcoord0 * _144_fa_uv_scale.xy, color, position };\n    return _296;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.color = vertex_color1;\n    v.uv = vertex_uv1;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _144_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = float3((fa_attr_uv1 * _144_fa_lm_so.xy) + _144_fa_lm_so.zw, float(_144_fa_lm_so.x > 0.0f));\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_attr_uv1 = stage_input.fa_attr_uv1;\n    fa_attr_color1 = stage_input.fa_attr_color1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _3688[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _591_fa_camera_pos : packoffset(c0);\n    float4 _591_fa_ambient : packoffset(c1);\n    float4 _591_fa_base_color : packoffset(c2);\n    float4 _591_fa_emissive : packoffset(c3);\n    float4 _591_fa_model_emissive : packoffset(c4);\n    float4 _591_fa_pbr : packoffset(c5);\n    float4 _591_fa_maps : packoffset(c6);\n    float4 _591_fa_fog : packoffset(c7);\n    float4 _591_fa_fog_b : packoffset(c8);\n    float4 _591_fa_fog_c : packoffset(c9);\n    float4 _591_fa_counts : packoffset(c10);\n    float4 _591_fa_env_sky : packoffset(c11);\n    float4 _591_fa_env_horizon : packoffset(c12);\n    float4 _591_fa_time : packoffset(c13);\n    float4 _591_fa_cl_vpx : packoffset(c14);\n    float4 _591_fa_cl_vpy : packoffset(c15);\n    float4 _591_fa_cl_vpw : packoffset(c16);\n    float4 _591_fa_cl_fwd : packoffset(c17);\n    float4 _591_fa_cl_grid : packoffset(c18);\n    float4 _591_fa_cl_info : packoffset(c19);\n    float4 _591_fa_layers_a : packoffset(c20);\n    float4 _591_fa_layers_b : packoffset(c21);\n    float4 _591_fa_layers_c : packoffset(c22);\n    float4 _591_fa_layers_d : packoffset(c23);\n    float4 _591_fa_ct_a : packoffset(c24);\n    float4 _591_fa_ct_b : packoffset(c25);\n    float4 _591_fa_ct_vpx : packoffset(c26);\n    float4 _591_fa_ct_vpy : packoffset(c27);\n    float4 _591_fa_ct_vpw : packoffset(c28);\n    float4 _591_fa_ct_fwd : packoffset(c29);\n    float4 _591_fa_tr_a : packoffset(c30);\n    float4 _591_fa_tr_b : packoffset(c31);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2258_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2258_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2258_fa_shadow_info[4] : packoffset(c20);\n    float4 _2258_fa_shadow_split : packoffset(c24);\n    float4 _2258_fa_shadow_cfg : packoffset(c25);\n    float4 _2258_fa_shadow_bias : packoffset(c26);\n    float4 _2258_fa_shadow_eye : packoffset(c27);\n    float4 _2258_fa_shadow_fwd : packoffset(c28);\n    float4 _2258_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_screen_tex : register(t11);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1529 = _591_fa_cl_info.x < 0.0f;\n    bool _1536;\n    if (!_1529)\n    {\n        _1536 = _591_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1536 = _1529;\n    }\n    bool _1544;\n    if (!_1536)\n    {\n        _1544 = _591_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1544 = _1536;\n    }\n    bool _1551;\n    if (!_1544)\n    {\n        _1551 = _591_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1551 = _1544;\n    }\n    bool _1558;\n    if (!_1551)\n    {\n        _1558 = _591_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1558 = _1551;\n    }\n    if (_1558)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1568 = float4(world_pos, 1.0f);\n    float _1574 = dot(_591_fa_cl_vpw, _1568);\n    if (!(_1574 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1596 = float2(dot(_591_fa_cl_vpx, _1568), dot(_591_fa_cl_vpy, _1568)) / _1574.xx;\n    int _1600 = int(_591_fa_cl_grid.x);\n    int _1604 = int(_591_fa_cl_grid.y);\n    int param = (int(_591_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_591_fa_cl_fwd.xyz, world_pos) + _591_fa_cl_fwd.w, _591_fa_cl_grid.w) / _591_fa_cl_grid.w) * _591_fa_cl_grid.z)), 0, int(_591_fa_cl_info.y) - 1) * _1604) + clamp(int(floor(((_1596.y * 0.5f) + 0.5f) * _591_fa_cl_grid.y)), 0, _1604 - 1)) * _1600)) + clamp(int(floor(((_1596.x * 0.5f) + 0.5f) * _591_fa_cl_grid.x)), 0, _1600 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1680 = fa_cluster_texel(param);\n    return int2(int(_1680.x), int(_1680.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_591_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _5121 = fa_cluster_lookup(param);\n    fa_cl_slot = _5121.x;\n    fa_cl_local = _5121.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _6260 = fa_linear_to_srgb(param);\n        c = _6260;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _6268 = fa_srgb_to_linear(param_1);\n            c = _6268;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _474;\n    if (i.front_facing)\n    {\n        _474 = i.world_normal;\n    }\n    else\n    {\n        _474 = -i.world_normal;\n    }\n    float3 _498 = normalize(i.world_tangent.xyz - (_474 * dot(_474, i.world_tangent.xyz)));\n    float3 _525 = normalize(((_498 * m.x) + ((cross(_474, _498) * i.world_tangent.w) * m.y)) + (_474 * m.z));\n    float3 _528;\n    if (i.front_facing)\n    {\n        _528 = _525;\n    }\n    else\n    {\n        _528 = -_525;\n    }\n    return _528;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _591_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _6299 = fa_tex_fix(param_2, param_3);\n    float4 _7865 = base_t;\n    _7865.x = _6299.x;\n    _7865.y = _6299.y;\n    _7865.z = _6299.z;\n    base_t = _7865;\n    float4 _6313 = (_7865 * _591_fa_base_color) * i.vertex_color;\n    float3 _7674 = i.world_normal;\n    if (_591_fa_maps.z > 0.5f)\n    {\n        float param_4 = _591_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _6345 = fa_tex_fix(param_6, param_7);\n        float3 _6348 = (_6345 * 2.0f) - 1.0f.xxx;\n        float2 _6353 = _6348.xy * _591_fa_maps.x;\n        float3 _7873 = _6348;\n        _7873.x = _6353.x;\n        _7873.y = _6353.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _7873;\n        _7674 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _591_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _6381 = fa_tex_fix(param_12, param_13);\n    float4 _7876 = mrt;\n    _7876.x = _6381.x;\n    _7876.y = _6381.y;\n    _7876.z = _6381.z;\n    mrt = _7876;\n    float4 _6409 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _591_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _6409.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _6420 = fa_tex_fix(param_16, param_17);\n    float param_18 = _591_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _6450 = fa_tex_fix(param_20, param_21);\n    float _7679 = _591_fa_layers_a.x;\n    float _7680 = _591_fa_layers_a.y;\n    float _7683 = _591_fa_layers_a.z;\n    float _7682 = _591_fa_layers_b.w;\n    float _7685 = _591_fa_layers_c.x;\n    if (_591_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_591_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _7679 *= _6420.y;\n            _7680 *= _6420.z;\n            _7682 *= _6409.w;\n        }\n        if (_591_fa_layers_c.z > 1.5f)\n        {\n            _7683 *= mrt.x;\n            _7685 *= mrt.w;\n        }\n    }\n    Surface _7712 = { _6313.xyz, _6313.w, _7674, clamp(_591_fa_pbr.x * _6381.z, 0.0f, 1.0f), clamp(_591_fa_pbr.y * _6381.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_591_fa_maps.y * (_6420.x - 1.0f)), _591_fa_emissive.xyz + (_591_fa_model_emissive.xyz * _6450), _7679, _7680, _591_fa_layers_b.xyz, _7682, _7683, _591_fa_layers_a.w, _7685, _591_fa_layers_c.y, _591_fa_layers_d.xyz, _591_fa_tr_a.x, _591_fa_tr_a.y, _591_fa_tr_b.xyz, _591_fa_tr_a.z };\n    return _7712;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * (i.uv.x * 2.0f));\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1760 = rect.zw - rect.xy;\n    float2 _1764 = _1760 * atlas;\n    float2 _1768 = ddx * _1764;\n    float2 _1772 = ddy * _1764;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1760), clamp(0.5f * log2(max(max(dot(_1768, _1768), dot(_1772, _1772)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1805 = _591_fa_counts.y < 0.5f;\n    bool _1812;\n    if (!_1805)\n    {\n        _1812 = _591_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1812 = _1805;\n    }\n    if (_1812)\n    {\n        return;\n    }\n    float3 _1818 = ddx(world_pos);\n    float3 _1821 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1825 = fa_cluster_texel(param);\n    int _1829 = int(_1825.w);\n    if (_1829 < 1)\n    {\n        return;\n    }\n    int _1839 = int(_591_fa_counts.y + 0.5f);\n    int param_1 = _1839;\n    float4 _1843 = fa_light_texel(param_1);\n    float2 _1846 = _1843.yz;\n    int _1850 = int(_1843.w);\n    int param_2 = _1839 + 1;\n    float4 _1855 = fa_light_texel(param_2);\n    float _1856 = _1855.x;\n    int _1862 = int(_591_fa_counts.w + 0.5f) - 1;\n    int _1866 = int(_1825.z);\n    float3 _2131;\n    for (int k = 0; k < _1829; k++)\n    {\n        int _1879 = _1866 + k;\n        int param_3 = _1850 + (_1879 >> 2);\n        int _1896 = (_1839 + 2) + (int(fa_light_texel(param_3)[_1879 & 3]) * 7);\n        int param_4 = _1896 + 6;\n        float4 _1901 = fa_light_texel(param_4);\n        if (((int(_1901.w + 0.5f) >> _1862) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1896;\n        float4 _1916 = fa_light_texel(param_5);\n        int param_6 = _1896 + 1;\n        float4 _1921 = fa_light_texel(param_6);\n        int param_7 = _1896 + 2;\n        float4 _1926 = fa_light_texel(param_7);\n        float3 _1929 = _1916.xyz;\n        float _1934 = dot(_1929, world_pos) + _1916.w;\n        float3 _1936 = _1921.xyz;\n        float _1941 = dot(_1936, world_pos) + _1921.w;\n        float3 _1943 = _1926.xyz;\n        float _1948 = dot(_1943, world_pos) + _1926.w;\n        bool _1953 = abs(_1934) > 0.5f;\n        bool _1961;\n        if (!_1953)\n        {\n            _1961 = abs(_1941) > 0.5f;\n        }\n        else\n        {\n            _1961 = _1953;\n        }\n        bool _1969;\n        if (!_1961)\n        {\n            _1969 = abs(_1948) > 0.5f;\n        }\n        else\n        {\n            _1969 = _1961;\n        }\n        if (_1969)\n        {\n            continue;\n        }\n        float _1984 = clamp(dot(geo_normal, normalize(_1943)) * _1901.z, 0.0f, 1.0f);\n        if (_1984 <= 0.0f)\n        {\n            continue;\n        }\n        float _2004 = (clamp((0.5f - abs(_1948)) * 10.0f, 0.0f, 1.0f) * _1984) * _1901.x;\n        float2 _2012 = float2(_1934 + 0.5f, 0.5f - _1941);\n        float2 _2022 = float2(dot(_1929, _1818), dot(_1936, _1818));\n        float2 _2032 = float2(dot(_1929, _1821), dot(_1936, _1821));\n        int param_8 = _1896 + 5;\n        float4 _2037 = fa_light_texel(param_8);\n        int param_9 = _1896 + 3;\n        float4 _2042 = fa_light_texel(param_9);\n        int param_10 = _1896 + 4;\n        float4 _2047 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _2037.xyz;\n        bool _2057 = _2042.z > _2042.x;\n        if (_2057)\n        {\n            float4 param_11 = _2042;\n            float2 param_12 = _2012;\n            float2 param_13 = _1846;\n            float2 param_14 = _2022;\n            float2 param_15 = _2032;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1856 > 0.5f) && (_1856 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _2083 = fa_dc_to_linear(param_16);\n                float4 _7762 = tx;\n                _7762.x = _2083.x;\n                _7762.y = _2083.y;\n                _7762.z = _2083.z;\n                tx = _7762;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_2004 * tex_a) * _2037.w, 0.0f, 1.0f).xxx);\n        if (_2047.z > _2047.x)\n        {\n            float4 param_17 = _2047;\n            float2 param_18 = _2012;\n            float2 param_19 = _1846;\n            float2 param_20 = _2022;\n            float2 param_21 = _2032;\n            float4 _2127 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1856 > 1.5f)\n            {\n                float3 param_22 = _2127.xyz;\n                float3 _2137 = fa_dc_to_srgb(param_22);\n                _2131 = _2137;\n            }\n            else\n            {\n                _2131 = _2127.xyz;\n            }\n            float3 _2146 = (_2131 * 2.0f) - 1.0f.xxx;\n            float2 _2151 = _2146.xy * _1901.y;\n            float3 _2173 = (normalize(_1929) * _2151.x) + (normalize(_1936) * _2151.y);\n            float3 _2176 = normalize(normal);\n            normal = normalize(lerp(_2176, normalize((_2176 * max(_2146.z, 0.0500000007450580596923828125f)) + (_2173 - (_2176 * dot(_2176, _2173)))), clamp(_2004 * (_2057 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3614 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3621 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3624 = int(_3614);\n    int _3627 = int(_3621);\n    float _3637 = _3621 - float(_3627);\n    int _3692 = (_3624 * 9) + _3627;\n    int _3712 = ((_3624 + 1) * 9) + _3627;\n    return lerp(lerp(_3688[_3692], _3688[_3692 + 1], _3637), lerp(_3688[_3712], _3688[_3712 + 1], _3637), _3614 - float(_3624));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _7597 = false;\n    float _7598 = 1.0f;\n    float _7599 = 1.0f;\n    float _7600 = 1.0f;\n    float _7601 = 0.0f;\n    float _7602 = 0.0f;\n    float _7603 = 0.0f;\n    float _7604 = 0.0f;\n    float _7606 = 1.0f;\n    bool _7607 = false;\n    float3 _7608 = 0.0f.xxx;\n    float _7609 = 1.0f;\n    float _7610 = 1.0f;\n    float _7611 = 1.0f;\n    float _7612 = 0.0f;\n    float _7613 = 0.0f;\n    float3 _7614 = float3(1.0f, 0.0f, 0.0f);\n    float3 _7615 = float3(0.0f, 0.0f, 1.0f);\n    float _7616 = 1.0f;\n    float _7617 = 1.0f;\n    float _3763 = clamp(s.specular, 0.0f, 1.0f);\n    float _3767 = clamp(s.ior, 1.0f, 3.0f);\n    bool _3772 = (_3763 != 1.0f) || (_3767 != 1.5f);\n    bool _3781;\n    if (!_3772)\n    {\n        _3781 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _3781 = _3772;\n    }\n    if (_3781)\n    {\n        float _3789 = (_3767 - 1.0f) / (_3767 + 1.0f);\n        f0 = lerp(min((_3789 * _3789).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _3763, s.albedo, metallic.xxx);\n        _7598 = lerp(_3763, 1.0f, metallic);\n        _7597 = true;\n    }\n    float _3816 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_3816 > 0.0f)\n    {\n        float _3824 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _7601 = _3816;\n        _7602 = _3824;\n        float _3831 = _3824 * _3824;\n        _7603 = _3831;\n        _7604 = _3831 * _3831;\n        float _3843 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _7606 = _3843;\n        _7599 = 1.0f - (_3816 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _3843, 0.0f, 1.0f), 5.0f))));\n        _7597 = true;\n    }\n    float3 _3862 = max(s.sheen_color, 0.0f.xxx);\n    float _3871 = max(_3862.x, max(_3862.y, _3862.z));\n    if (_3871 > 0.0f)\n    {\n        float _3879 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _7607 = true;\n        _7608 = _3862;\n        _7609 = _3879;\n        _7610 = _3879 * _3879;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _3879;\n        float _3896 = fa_sheen_albedo(param, param_1);\n        _7612 = _3896;\n        _7611 = 1.0f - min(_3871 * _3896, 1.0f);\n        _7597 = true;\n    }\n    _7600 = _7599 * _7611;\n    float _3915 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_3915 != 0.0f)\n    {\n        float3 _3930 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _3930;\n        if (dot(_3930, _3930) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _3942 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_3942.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _3942.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _3942.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _3946 = t;\n        float3 _3947 = normalize(_3946);\n        t = _3947;\n        float3 _3972 = normalize((_3947 * cos(s.anisotropy_rotation)) + ((cross(n, _3947) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _7614 = _3972;\n        _7615 = cross(n, _3972);\n        float _3982 = roughness * roughness;\n        float _3988 = lerp(_3982, 1.0f, _3915 * _3915);\n        bool _3990 = _3915 > 0.0f;\n        _7616 = _3990 ? _3988 : _3982;\n        _7617 = _3990 ? _3982 : _3988;\n        _7613 = _3915;\n        _7597 = true;\n    }\n    FaLayers _7639 = { _7597, _7598, _7599, _7600, _7601, _7602, _7603, _7604, i.world_normal, _7606, _7607, _7608, _7609, _7610, _7611, _7612, _7613, _7614, _7615, _7616, _7617 };\n    return _7639;\n}\n\nfloat3 fa_sky_sh_coef(int k)\n{\n    float3 v = fa_env_tex.SampleLevel(fa_env_smp, float3(1.0f, 1.0f - (float((2 * (k >> 2)) + 1) * 0.25f), 1.0f - (float((2 * (k & 3)) + 1) * 0.25f)), 5.0f).xyz;\n    if (_591_fa_env_sky.w > 1.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3371 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3371;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_591_fa_env_sky.w > 0.5f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _591_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_591_fa_cl_info.x) + int(_591_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_591_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _659_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _659_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _778 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _791 = (c - (ru * hx)) - p;\n        float3 _797 = ru * (2.0f * hx);\n        float _803 = max(dot(_797, _797), 9.9999999392252902907785028219223e-09f);\n        float _807 = dot(_791, _797);\n        float t = clamp((-_807) / _803, 0.0f, 1.0f);\n        if (_778)\n        {\n            float _822 = dot(r, _797);\n            float _828 = _803 - (_822 * _822);\n            if (abs(_828) > (9.9999997473787516355514526367188e-06f * _803))\n            {\n                t = clamp(((dot(r, _791) * _822) - _807) / _828, 0.0f, 1.0f);\n            }\n        }\n        return (p + _791) + (_797 * t);\n    }\n    float3 q = p;\n    float _860 = dot(r, axis);\n    bool _868;\n    if (_778)\n    {\n        _868 = abs(_860) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _868 = _778;\n    }\n    if (_868)\n    {\n        float _878 = dot(c - p, axis) / _860;\n        if (_878 > 0.0f)\n        {\n            q = p + (r * _878);\n        }\n    }\n    float3 _891 = q - c;\n    float2 xy = float2(dot(_891, ru), dot(_891, uu));\n    if (shape > 0.5f)\n    {\n        float _906 = length(xy);\n        if (_906 > hx)\n        {\n            xy *= (hx / _906);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _540 = abs(d);\n    float _542 = _540.x;\n    float _544 = _540.y;\n    bool _545 = _542 >= _544;\n    bool _553;\n    if (_545)\n    {\n        _553 = _542 >= _540.z;\n    }\n    else\n    {\n        _553 = _545;\n    }\n    int _554;\n    if (_553)\n    {\n        _554 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _569;\n        if (_544 >= _540.z)\n        {\n            _569 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _569 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _554 = _569;\n    }\n    return _554;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _698 = dot(d, right);\n    float _702 = dot(d, up);\n    float _713;\n    if (((_698 * _698) + (_702 * _702)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _713 = atan2(_702, _698) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _713 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_713 - floor(_713)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _944 = fa_light_base(param);\n    bool _948 = _591_fa_ambient.w > 4.5f;\n    int param_1 = _944;\n    float4 _952 = fa_light_texel(param_1);\n    int param_2 = _944 + 1;\n    float4 _957 = fa_light_texel(param_2);\n    float _960 = _957.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _972 = _948 && (_960 > 2.5f);\n    fa_light_is_area = _972;\n    bool _974 = _960 < 0.5f;\n    float3 l;\n    if (_974)\n    {\n        l = normalize(_952.xyz);\n        if (_948)\n        {\n            int param_3 = _944 + 6;\n            float4 _988 = fa_light_texel(param_3);\n            if (_988.z > 0.5f)\n            {\n                int param_4 = _944 + 4;\n                float4 _998 = fa_light_texel(param_4);\n                int param_5 = _944 + 5;\n                float4 _1003 = fa_light_texel(param_5);\n                float2 param_6 = _988.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _998.xyz) * _998.w, (-dot(world_pos, _1003.xyz)) * _1003.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _1033 = _952.xyz;\n        float3 _1035 = _1033 - world_pos;\n        float3 to_light = _1035;\n        float _1038 = length(_1035);\n        float reach = _1038;\n        bool front = true;\n        if (_972)\n        {\n            int param_8 = _944 + 7;\n            reach = max(_1038 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _944 + 4;\n            float4 _1062 = fa_light_texel(param_9);\n            int param_10 = _944 + 5;\n            float4 _1067 = fa_light_texel(param_10);\n            int param_11 = _944 + 6;\n            float4 _1072 = fa_light_texel(param_11);\n            float _1073 = _1072.w;\n            int param_12 = _944 + 2;\n            float3 _1080 = normalize(fa_light_texel(param_12).xyz);\n            bool _1082 = _1073 > 1.5f;\n            bool _1090;\n            if (!_1082)\n            {\n                _1090 = dot(_1080, to_light) < 0.0f;\n            }\n            else\n            {\n                _1090 = _1082;\n            }\n            front = _1090;\n            float3 r = 0.0f.xxx;\n            float3 _1099 = _591_fa_camera_pos.xyz - world_pos;\n            bool _1103 = dot(n, n) > 0.5f;\n            bool _1111;\n            if (_1103)\n            {\n                _1111 = dot(_1099, _1099) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _1111 = _1103;\n            }\n            if (_1111)\n            {\n                r = reflect(-normalize(_1099), normalize(n));\n            }\n            float3 param_13 = _1033;\n            float3 param_14 = _1080;\n            float3 param_15 = _1062.xyz;\n            float3 param_16 = _1067.xyz;\n            float param_17 = _1062.w;\n            float param_18 = _1067.w;\n            float param_19 = _1073;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1147 = length(to_light);\n        dist = _1147;\n        l = to_light / max(_1147, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1161 = reach / max(_952.w, 0.001000000047497451305389404296875f);\n        float _1167 = clamp(1.0f - (_1161 * _1161), 0.0f, 1.0f);\n        float _1169;\n        if (front)\n        {\n            _1169 = _1167 * _1167;\n        }\n        else\n        {\n            _1169 = 0.0f;\n        }\n        atten = _1169;\n        bool _1180 = _960 < 2.5f;\n        if ((_960 > 1.5f) && _1180)\n        {\n            int param_22 = _944 + 2;\n            float4 _1188 = fa_light_texel(param_22);\n            float _1198 = _1188.w;\n            int param_23 = _944 + 3;\n            float4 _1203 = fa_light_texel(param_23);\n            float _1204 = _1203.x;\n            float cos_inner = _1204;\n            if (_1204 > 1.5f)\n            {\n                cos_inner = lerp(_1198, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1198, cos_inner, dot(-l, normalize(_1188.xyz)));\n        }\n        if (_948 && (_960 < 1.5f))\n        {\n            int param_24 = _944 + 6;\n            float4 _1228 = fa_light_texel(param_24);\n            if (_1228.z > 0.5f)\n            {\n                float3 _1236 = -to_light;\n                int param_25 = _944 + 4;\n                int param_26 = _944 + 5;\n                float3 _1250 = fa_light_texel(param_25).xyz;\n                float3 _1254 = fa_light_texel(param_26).xyz;\n                float3 _1263 = float3(dot(_1236, _1250), dot(_1236, _1254), dot(_1236, cross(_1250, _1254)));\n                float3 param_27 = _1263;\n                int _1267 = fa_cube_face(param_27);\n                int param_28 = _1267;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1294 = float2(dot(_1263, cross(param_29, param_30)), dot(_1263, param_30)) / max(dot(_1263, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1298 = _1267 / 3;\n                float2 param_31 = _1228.xy + (float2(float(_1267 - (_1298 * 3)), float(_1298)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1294.x), 0.5f - (0.5f * _1294.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _944 + 7;\n            float4 _1328 = fa_light_texel(param_33);\n            if (_1328.z > 0.5f)\n            {\n                int param_34 = _944 + 2;\n                int param_35 = _944 + 4;\n                int param_36 = _944 + 5;\n                float2 param_37 = _1328.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_948 && _1180)\n            {\n                int param_42 = _944 + 6;\n                float4 _1375 = fa_light_texel(param_42);\n                int param_43 = _944 + 7;\n                float4 _1380 = fa_light_texel(param_43);\n                bool _1383 = _1375.z > 0.5f;\n                bool _1390;\n                if (!_1383)\n                {\n                    _1390 = _1380.z > 0.5f;\n                }\n                else\n                {\n                    _1390 = _1383;\n                }\n                if (_1390)\n                {\n                    int param_44 = _944 + 2;\n                    float4 _1397 = fa_light_texel(param_44);\n                    float3 _1401 = normalize(_1397.xyz);\n                    int param_45 = _944 + 4;\n                    float4 _1406 = fa_light_texel(param_45);\n                    int param_46 = _944 + 5;\n                    float4 _1411 = fa_light_texel(param_46);\n                    if (_1383)\n                    {\n                        float3 _1419 = -to_light;\n                        float _1426 = _1397.w;\n                        float _1442 = 0.5f / max(dot(_1419, _1401) * (sqrt(max(1.0f - (_1426 * _1426), 0.0f)) / max(_1426, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1375.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1419, _1406.xyz) * _1442), 0.5f - (dot(_1419, _1411.xyz) * _1442));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1380.z > 0.5f)\n                    {\n                        float2 param_49 = _1380.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1401;\n                        float3 param_52 = _1406.xyz;\n                        float3 param_53 = _1411.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _7585 = _957.xyz * atten;\n    if (_948)\n    {\n        _7585 *= fa_light_tint;\n    }\n    int _1511;\n    if (_974)\n    {\n        _1511 = 0;\n    }\n    else\n    {\n        _1511 = ((_960 > 1.5f) && (_960 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _7596 = { l, _7585, atten, 1.0f, dist, _1511 };\n    return _7596;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2248;\n    if (i == 0)\n    {\n        _2248 = _2258_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2264;\n        if (i == 1)\n        {\n            _2264 = _2258_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2272;\n            if (i == 2)\n            {\n                _2272 = _2258_fa_shadow_split.z;\n            }\n            else\n            {\n                _2272 = _2258_fa_shadow_split.w;\n            }\n            _2264 = _2272;\n        }\n        _2248 = _2264;\n    }\n    return _2248;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2305 = fa_shadow_depth(param, param_1);\n    float _2309;\n    if (conv.x < 0.5f)\n    {\n        _2309 = _2305;\n    }\n    else\n    {\n        _2309 = (conv.y * conv.z) / (conv.z - (_2305 * (conv.z - conv.y)));\n    }\n    return _2309;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2236 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2236), sin(_2236)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2355 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2364;\n        if (k < 0.0f)\n        {\n            _2364 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2364 = k;\n        }\n        float _2384 = clamp((_2364 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2355;\n            float2 _2403 = fa_shadow_vogel(param_3, param_4, param_5) * _2384;\n            float2 param_6 = uv + (_2403 * _2258_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2415 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2415 < (zr - (length(_2403) * plane)))\n            {\n                sum += _2415;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2441 = sum / cnt;\n        float _2451;\n        if (k < 0.0f)\n        {\n            _2451 = (-k) / max(_2441, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2451 = k;\n        }\n        radius = clamp(((max(zr - _2441, 0.0f) * unit) * _2451) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2473 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2473; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2473;\n        float param_11 = _2355;\n        float2 _2492 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2492 * _2258_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2492) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2473);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2534 = max(_2258_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2539 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2545 = sqrt(1.0f - (_2539 * _2539));\n    float _2552 = min(_2545 / max(_2539, 0.20000000298023223876953125f), 4.0f);\n    float _2557;\n    if (_2258_fa_shadow_bias.y > 0.0f)\n    {\n        _2557 = _2258_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2557 = 1.5f * _2258_fa_shadow_info[ci].x;\n    }\n    float4 _2582 = mul(float4(world + (n * (_2557 * _2545)), 1.0f), _2258_fa_shadow_mat[ci]);\n    float _2589 = _2582.x;\n    bool _2592 = _2589 < _2258_fa_shadow_rect[ci].x;\n    bool _2601;\n    if (!_2592)\n    {\n        _2601 = _2589 > _2258_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2601 = _2592;\n    }\n    bool _2610;\n    if (!_2601)\n    {\n        _2610 = _2582.y < _2258_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2610 = _2601;\n    }\n    bool _2619;\n    if (!_2610)\n    {\n        _2619 = _2582.y > _2258_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2619 = _2610;\n    }\n    bool _2626;\n    if (!_2619)\n    {\n        _2626 = _2582.z > 1.0f;\n    }\n    else\n    {\n        _2626 = _2619;\n    }\n    if (_2626)\n    {\n        return -1.0f;\n    }\n    float _2634;\n    if (_2258_fa_shadow_bias.x > 0.0f)\n    {\n        _2634 = _2258_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2634 = 1.5f * _2258_fa_shadow_info[ci].x;\n    }\n    float2 param = _2582.xy;\n    float4 param_1 = _2258_fa_shadow_rect[ci];\n    float param_2 = _2582.z - ((_2634 * (1.0f + (0.5f * _2552))) / _2534);\n    float param_3 = _2258_fa_shadow_info[ci].x;\n    float param_4 = _2534;\n    float param_5 = _2534 * 0.25f;\n    float param_6 = ((_2258_fa_shadow_info[ci].x * min(_2552, 3.0f)) * 0.5f) / _2534;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2258_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2258_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_591_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _3012 = int(_2258_fa_shadow_cfg.x + 0.5f);\n    if (_3012 < 1)\n    {\n        return 1.0f;\n    }\n    float _3027 = dot(world - _2258_fa_shadow_eye.xyz, _2258_fa_shadow_fwd.xyz);\n    int param = _3012 - 1;\n    if (_3027 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _3039 = _3012 > 1;\n    bool _3046;\n    if (_3039)\n    {\n        _3046 = _3027 > _2258_fa_shadow_split.x;\n    }\n    else\n    {\n        _3046 = _3039;\n    }\n    if (_3046)\n    {\n        ci = 1;\n    }\n    bool _3050 = _3012 > 2;\n    bool _3057;\n    if (_3050)\n    {\n        _3057 = _3027 > _2258_fa_shadow_split.y;\n    }\n    else\n    {\n        _3057 = _3050;\n    }\n    if (_3057)\n    {\n        ci = 2;\n    }\n    bool _3061 = _3012 > 3;\n    bool _3068;\n    if (_3061)\n    {\n        _3068 = _3027 > _2258_fa_shadow_split.z;\n    }\n    else\n    {\n        _3068 = _3061;\n    }\n    if (_3068)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _3012)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _3094 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3094;\n        if (_3094 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2258_fa_shadow_cfg.y > 0.0f)\n    {\n        float _3119;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3119 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3119 = _2258_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _3138 = _2258_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3119, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _3149 = clamp((_3027 - (fa_shadow_split_at(param_7) - _3138)) / _3138, 0.0f, 1.0f);\n        if (_3149 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _3012)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _3170 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3170;\n                if (_3170 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _3149);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2692 = _591_fa_pbr.z < 0.5f;\n    bool _2699;\n    if (!_2692)\n    {\n        _2699 = _2258_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2699 = _2692;\n    }\n    if (_2699)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2258_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2712 = fa_light_texel(param);\n    float _2713 = _2712.x;\n    if (_2713 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2722 = int(_2713 + 0.5f);\n    int param_1 = _2722;\n    float4 _2726 = fa_light_texel(param_1);\n    int param_2 = _2722 + 1;\n    float4 _2731 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2734 = _2726.y;\n    if (_2734 > 0.0f)\n    {\n        float _2751 = 1.0f - smoothstep(0.75f * _2734, _2734, length(world - _2258_fa_shadow_eye.xyz));\n        fade = _2751;\n        if (_2751 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2726.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2775 = (_2722 + 2) + (face * 6);\n    int param_4 = _2775;\n    int param_5 = _2775 + 1;\n    int param_6 = _2775 + 3;\n    float4 _2789 = fa_light_texel(param_6);\n    int param_7 = _2775 + 4;\n    float4 _2794 = fa_light_texel(param_7);\n    int param_8 = _2775 + 5;\n    float4 _2799 = fa_light_texel(param_8);\n    float _2811 = _2799.x * max(dot(_2789, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2816 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2839 = clamp(dot(n, _2789.xyz), -1.0f, 1.0f);\n    float _2858 = min(sqrt(1.0f - (_2839 * _2839)) / max(abs(dot(n, world - lpos)) / max(dot(_2789, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2861 = _2731.y;\n    float _2863;\n    if (_2861 > 0.0f)\n    {\n        _2863 = _2861;\n    }\n    else\n    {\n        _2863 = 1.5f * _2811;\n    }\n    float4 _2883 = float4(world + (n * (_2863 * sqrt(1.0f - (_2816 * _2816)))), 1.0f);\n    float _2887 = dot(_2789, _2883);\n    float _2890 = _2799.y;\n    if (_2887 < _2890)\n    {\n        return 1.0f;\n    }\n    float2 _2905 = float2(dot(fa_light_texel(param_4), _2883), dot(fa_light_texel(param_5), _2883)) / _2887.xx;\n    float _2907 = _2905.x;\n    bool _2910 = _2907 < _2794.x;\n    bool _2919;\n    if (!_2910)\n    {\n        _2919 = _2907 > _2794.z;\n    }\n    else\n    {\n        _2919 = _2910;\n    }\n    bool _2928;\n    if (!_2919)\n    {\n        _2928 = _2905.y < _2794.y;\n    }\n    else\n    {\n        _2928 = _2919;\n    }\n    bool _2937;\n    if (!_2928)\n    {\n        _2937 = _2905.y > _2794.w;\n    }\n    else\n    {\n        _2937 = _2928;\n    }\n    if (_2937)\n    {\n        return 1.0f;\n    }\n    float _2943 = _2731.x;\n    float _2945;\n    if (_2943 > 0.0f)\n    {\n        _2945 = _2943;\n    }\n    else\n    {\n        _2945 = 1.5f * _2811;\n    }\n    float2 param_9 = _2905;\n    float4 param_10 = _2794;\n    float param_11 = _2887 - (_2945 * (1.0f + (0.5f * _2858)));\n    float param_12 = _2811;\n    float param_13 = 1.0f;\n    float param_14 = _2799.z * 0.25f;\n    float param_15 = (_2811 * min(_2858, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2890, _2799.z);\n    int param_17 = int(_2726.z + 0.5f);\n    float param_18 = _2726.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _4500 = _591_fa_ct_a.x < 0.5f;\n    bool _4507;\n    if (!_4500)\n    {\n        _4507 = _2258_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _4507 = _4500;\n    }\n    if (_4507)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2258_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _4520 = fa_light_texel(param);\n    float _4521 = _4520.y;\n    float len = _4521;\n    if (_4521 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4533 = length(world - _591_fa_camera_pos.xyz);\n    float _4543 = 1.0f - smoothstep(0.5f * _591_fa_ct_b.x, _591_fa_ct_b.x, _4533);\n    if (_4543 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4549 = len;\n    float _4552 = min(_4549, 0.89999997615814208984375f * dist);\n    len = _4552;\n    float _4557 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _4533);\n    float _4562 = _4557 + (0.5f * _4552);\n    float3 _4568 = world + (gn * _4557);\n    float _4570 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _4634;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4585 = (float(k) + _4570) * 0.083333335816860198974609375f;\n        float3 _4593 = _4568 + (l * (_4585 * len));\n        float4 _4599 = float4(_4593, 1.0f);\n        float _4605 = dot(_591_fa_ct_vpw, _4599);\n        if (_4605 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _4625 = float2(dot(_591_fa_ct_vpx, _4599), dot(_591_fa_ct_vpy, _4599)) / _4605.xx;\n        float _4629 = _4625.x * 0.5f;\n        float _4630 = _4629 + 0.5f;\n        if (_591_fa_ct_a.y > 0.5f)\n        {\n            _4634 = (_4625.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _4634 = 0.5f - (_4625.y * 0.5f);\n        }\n        bool _4650 = _4630 < 0.0f;\n        bool _4657;\n        if (!_4650)\n        {\n            _4657 = _4630 >= 1.0f;\n        }\n        else\n        {\n            _4657 = _4650;\n        }\n        bool _4664;\n        if (!_4657)\n        {\n            _4664 = _4634 < 0.0f;\n        }\n        else\n        {\n            _4664 = _4657;\n        }\n        bool _4671;\n        if (!_4664)\n        {\n            _4671 = _4634 >= 1.0f;\n        }\n        else\n        {\n            _4671 = _4664;\n        }\n        if (_4671)\n        {\n            break;\n        }\n        float4 _4690 = fa_screen_tex.Load(int3(int2(float2(_4630, _4634) * _591_fa_ct_a.zw), 0));\n        if (_4690.w < 0.5f)\n        {\n            continue;\n        }\n        float _4709 = (dot(_591_fa_ct_fwd.xyz, _4593) + _591_fa_ct_fwd.w) - _4690.x;\n        if ((_4709 > _4557) && (_4709 < _4562))\n        {\n            occ = max(occ, (1.0f - (_4585 * _4585)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_4630, 0.5f - _4629), min(_4634, 1.0f - _4634))));\n        }\n    }\n    return 1.0f - (occ * _4543);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _5148 = fa_lm.z > 0.5f;\n    bool _5154;\n    if (_5148)\n    {\n        int param = li;\n        _5154 = fa_light_baked(param);\n    }\n    else\n    {\n        _5154 = _5148;\n    }\n    if (_5154)\n    {\n        int param_1 = li;\n        LightSample _7652 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _7652;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _5178 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _7654 = _5178.color;\n    float _7656 = _5178.shadow;\n    bool _5181 = _5178.type == 0;\n    if (_5181 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _5178.direction;\n        float _5192 = fa_shadow_factor(param_5, param_6);\n        _7656 = _5192;\n        _7654 *= _5192;\n    }\n    else\n    {\n        bool _5203 = _5178.type != 0;\n        bool _5209;\n        if (_5203)\n        {\n            _5209 = _5178.attenuation > 0.0f;\n        }\n        else\n        {\n            _5209 = _5203;\n        }\n        if (_5209)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _5178.direction;\n            float _5228 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _7656 = _5228;\n            _7654 *= _5228;\n        }\n    }\n    bool _5238 = _591_fa_ct_a.x > 0.5f;\n    bool _5244;\n    if (_5238)\n    {\n        _5244 = _5178.attenuation > 0.0f;\n    }\n    else\n    {\n        _5244 = _5238;\n    }\n    if (_5244)\n    {\n        float _5251;\n        if (_5181)\n        {\n            _5251 = 1000000000.0f;\n        }\n        else\n        {\n            _5251 = _5178._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _5178.direction;\n        float param_18 = _5251;\n        float _5269 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _7656 *= _5269;\n        _7654 *= _5269;\n    }\n    LightSample _7671 = { _5178.direction, _7654, _5178.attenuation, _7656, _5178._distance, _5178.type };\n    return _7671;\n}\n\nfloat3 fa_ltc_tangent(float3 n, float3 v)\n{\n    float3 _5312 = v - (n * dot(v, n));\n    float3 t = _5312;\n    float _5316 = dot(_5312, _5312);\n    float l2 = _5316;\n    if (_5316 < 1.0000000133514319600180897396058e-10f)\n    {\n        float3 _5326;\n        if (abs(n.z) < 0.999000012874603271484375f)\n        {\n            _5326 = cross(n, float3(0.0f, 0.0f, 1.0f));\n        }\n        else\n        {\n            _5326 = cross(n, float3(1.0f, 0.0f, 0.0f));\n        }\n        t = _5326;\n        l2 = dot(_5326, _5326);\n    }\n    return t * rsqrt(l2);\n}\n\nfloat3 fa_ltc_local(float3 t1, float3 n, float3 p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nfloat3 fa_ltc_edge_vector(float3 a, float3 b)\n{\n    float _5361 = dot(a, a);\n    float _5365 = dot(b, b);\n    if ((_5361 < 1.0000000195414813782625560981111e-24f) || (_5365 < 1.0000000195414813782625560981111e-24f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _5379 = a * rsqrt(_5361);\n    float3 _5384 = b * rsqrt(_5365);\n    float _5388 = dot(_5379, _5384);\n    float _5391 = abs(_5388);\n    float g = (((((((((((0.0416471660137176513671875f * _5391) - 0.1924748718738555908203125f) * _5391) + 0.4179156124591827392578125f) * _5391) - 0.616057217121124267578125f) * _5391) + 0.777722418308258056640625f) * _5391) - 0.999542415142059326171875f) * _5391) + 1.570791721343994140625f;\n    if (_5388 < 0.0f)\n    {\n        g = (3.1415927410125732421875f * rsqrt(max(1.0f - (_5388 * _5388), 1.0000000116860974230803549289703e-07f))) - g;\n    }\n    return cross(_5379, _5384) * g;\n}\n\nvoid fa_ltc_clip_edge(float3 a, float3 b, inout float3 sum, inout float3 leave, inout float3 enter, inout float2 seen)\n{\n    bool _5448 = a.z > 0.0f;\n    bool _5452 = b.z > 0.0f;\n    if (_5448 && _5452)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_5448 != _5452)\n        {\n            float3 _5487 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _5487.z = 0.0f;\n            if (_5448)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _5487;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _5487;\n                seen.x = 1.0f;\n            }\n            else\n            {\n                float3 param_4 = _5487;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _5487;\n                seen.y = 1.0f;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(float4 abcd, float3 p0, float3 p1, float3 p2, float3 p3)\n{\n    float3 _5536 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _5562 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _5588 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _5614 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = 0.0f.xxx;\n    float3 leave = 0.0f.xxx;\n    float3 enter = 0.0f.xxx;\n    float3 param = _5536;\n    float3 param_1 = _5562;\n    float3 param_2 = 0.0f.xxx;\n    float3 param_3 = 0.0f.xxx;\n    float3 param_4 = 0.0f.xxx;\n    float2 param_5 = 0.0f.xx;\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _5562;\n    float3 param_7 = _5588;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _5588;\n    float3 param_13 = _5614;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _5614;\n    float3 param_19 = _5536;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5f)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875f;\n}\n\nfloat fa_ltc_rect(float4 abcd, float3 center, float3 ex, float3 ey)\n{\n    float4 param = abcd;\n    float3 param_1 = (center - ex) - ey;\n    float3 param_2 = (center + ex) - ey;\n    float3 param_3 = (center + ex) + ey;\n    float3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(float4 m, float shape, float3 pc, float3 ex, float3 ey)\n{\n    if ((shape < 0.5f) || (shape > 1.5f))\n    {\n        float4 param = m;\n        float3 param_1 = pc;\n        float3 param_2 = ex;\n        float3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    float3 _5763 = (pc + (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _5787 = (pc - (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _5803 = (pc - (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float4 param_4 = m;\n    float3 param_5 = _5763;\n    float3 param_6 = (pc + (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_7 = (pc - (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_8 = _5787;\n    float4 param_9 = m;\n    float3 param_10 = _5763;\n    float3 param_11 = _5787;\n    float3 param_12 = (pc - (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    float3 param_13 = _5803;\n    float4 param_14 = m;\n    float3 param_15 = _5763;\n    float3 param_16 = _5803;\n    float3 param_17 = (pc + (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float3 param_18 = (pc + (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nfloat2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((float2(clamp((roughness - 0.0500000007450580596923828125f) * 1.0526316165924072265625f, 0.0f, 1.0f), sqrt(clamp(1.0f - ndv, 0.0f, 1.0f))) * 63.0f) + 0.5f.xx) * 0.015625f.xx;\n}\n\nfloat3 fa_area_shade(int li, float3 world_pos, float3 n, float3 v, float3 diffuse_color, float3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _5861 = fa_light_base(param);\n    int param_1 = _5861;\n    int param_2 = _5861 + 1;\n    int param_3 = _5861 + 2;\n    int param_4 = _5861 + 4;\n    float4 _5883 = fa_light_texel(param_4);\n    int param_5 = _5861 + 5;\n    float4 _5888 = fa_light_texel(param_5);\n    int param_6 = _5861 + 6;\n    float4 _5893 = fa_light_texel(param_6);\n    float _5894 = _5893.w;\n    float3 _5899 = fa_light_texel(param_1).xyz - world_pos;\n    bool _5901 = _5894 < 1.5f;\n    bool _5908;\n    if (_5901)\n    {\n        _5908 = dot(normalize(fa_light_texel(param_3).xyz), _5899) >= 0.0f;\n    }\n    else\n    {\n        _5908 = _5901;\n    }\n    if (_5908)\n    {\n        return 0.0f.xxx;\n    }\n    bool _5917 = (_5894 > 0.5f) && _5901;\n    float _5921 = _5917 ? 1.0539000034332275390625f : 1.0f;\n    float3 _5924 = _5883.xyz;\n    float _5926 = _5883.w;\n    float3 _5932 = _5888.xyz;\n    float _5934 = _5888.w;\n    float3 up = _5932 * (_5934 * _5921);\n    float _5940;\n    if (_5917)\n    {\n        _5940 = (3.1415927410125732421875f * _5926) * _5926;\n    }\n    else\n    {\n        _5940 = (4.0f * _5926) * _5934;\n    }\n    if (_5894 > 1.5f)\n    {\n        float3 _5966 = cross(_5924, -_5899);\n        float3 perp = _5966;\n        float _5970 = dot(_5966, _5966);\n        float3 _5973;\n        if (_5970 > 1.0000000133514319600180897396058e-10f)\n        {\n            _5973 = perp * rsqrt(_5970);\n        }\n        else\n        {\n            _5973 = _5932;\n        }\n        perp = _5973;\n        up = _5973 * _5934;\n    }\n    float _5994 = max(_5940, 9.9999999747524270787835121154785e-07f);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _6004 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _6004;\n    float3 param_10 = n;\n    float3 param_11 = _5899;\n    float3 _6012 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_12 = _6004;\n    float3 param_13 = n;\n    float3 param_14 = _5924 * (_5926 * _5921);\n    float3 _6020 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_15 = _6004;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float3 _6028 = fa_ltc_local(param_15, param_16, param_17);\n    float4 param_18 = float4(1.0f, 0.0f, 0.0f, 1.0f);\n    float param_19 = _5894;\n    float3 param_20 = _6012;\n    float3 param_21 = _6020;\n    float3 param_22 = _6028;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    float2 _6047 = fa_ltc_uv(param_23, param_24) * 64.0f;\n    float2 param_25 = _6047;\n    float2 param_26 = _6047 + float2(64.0f, 0.0f);\n    float4 _6057 = fa_atlas_fetch(param_26);\n    float4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _5894;\n    float3 param_29 = _6012;\n    float3 param_30 = _6020;\n    float3 param_31 = _6028;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _6057.x) + ((f90.xxx - f0) * _6057.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875f * dot(_5899, _5899)) + _5994) / _5994) * window);\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4237 = 1.0f / alpha;\n    return ((2.0f + _4237) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _4237)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat fa_layers_coat(FaLayers L, float3 l, float3 h, float vdh)\n{\n    float _4272 = max(dot(L.nc, l), 0.0f);\n    float _4278 = max(dot(L.nc, h), 0.0f);\n    float _4287 = ((_4278 * _4278) * (L.coat_a2 - 1.0f)) + 1.0f;\n    return (((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _4287) * _4287)) * (0.5f / max(lerp((2.0f * _4272) * L.coat_ndv, _4272 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _4272)) * _4272;\n}\n\nfloat3 fa_area_layers(FaLayers L, int li, float3 world_pos, float3 n, float3 v, float3 l, float3 diffuse_color, float3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    float3 param_2 = n;\n    float3 param_3 = v;\n    float3 param_4 = diffuse_color;\n    float3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _6125;\n    if (L.sheen_on)\n    {\n        _6125 = L.sheen_scale;\n    }\n    else\n    {\n        _6125 = 1.0f;\n    }\n    float3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _6125);\n    float3 _6138 = normalize(l + v);\n    int param_10 = li;\n    float3 _6149 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _6158 = max(dot(n, l), 0.0f);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _6138), 0.0f);\n        float param_13 = _6158;\n        float param_14 = ndv;\n        result += ((L.sheen * _6149) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875f) * step(9.9999997473787516355514526367188e-05f, _6158)) * _6158) * L.keep));\n    }\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_15 = L;\n        float3 param_16 = l;\n        float3 param_17 = _6138;\n        float param_18 = max(dot(v, _6138), 0.0f);\n        result += (_6149 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4140 = tdh / at;\n    float _4144 = bdh / ab;\n    float _4156 = ((_4140 * _4140) + (_4144 * _4144)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _4156) * _4156);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4336 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4415 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _4415) * _4415);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _4336);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _4336));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_17 = L;\n        float3 param_18 = l;\n        float3 param_19 = h;\n        float param_20 = vdh;\n        result += fa_layers_coat(param_17, param_18, param_19, param_20).xxx;\n    }\n    return result;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3546 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3549 = _3546.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3549 * _3549, exp2((-9.27999973297119140625f) * ndv)) * _3549) + _3546.y)) + _3546.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_591_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _591_fa_env_horizon.w).xyz;\n    }\n    float _3400 = rough * rough;\n    float _3430 = 0.60000002384185791015625f * _3400;\n    return lerp(lerp(_591_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_591_fa_env_horizon.xyz, _591_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3400)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3430, 0.0500000007450580596923828125f + _3430, d.y).xxx), ((_591_fa_env_sky.xyz + _591_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3400 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _4023;\n        if (L.aniso >= 0.0f)\n        {\n            _4023 = L.b;\n        }\n        else\n        {\n            _4023 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_4023, v), _4023), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4056 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _4056.x) + (L.f90.xxx * _4056.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _4111 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _4111.x) + _4111.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3588 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3588.x) + _3588.y.xxx);\n}\n\nfloat2 fa_xm_size(int k)\n{\n    return max(floor(_591_fa_ct_a.zw / exp2(float(k)).xx), 1.0f.xx);\n}\n\nfloat2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return 0.0f.xx;\n    }\n    float y = 0.0f;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return float2(_591_fa_ct_a.z, y);\n}\n\nfloat3 fa_xm_texel(float2 size, float2 origin, float2 p)\n{\n    return fa_screen_tex.Load(int3(int2(origin + clamp(p, 0.0f.xx, size - 1.0f.xx)), 0)).xyz;\n}\n\nfloat3 fa_xm_level(int k, float2 uv)\n{\n    int param = k;\n    float2 _4813 = fa_xm_size(param);\n    int param_1 = k;\n    float2 _4817 = fa_xm_origin(param_1);\n    float2 _4823 = (uv * _4813) - 0.5f.xx;\n    float2 _4826 = frac(_4823);\n    float2 _4829 = floor(_4823);\n    float2 param_2 = _4813;\n    float2 param_3 = _4817;\n    float2 param_4 = _4829;\n    float2 param_5 = _4813;\n    float2 param_6 = _4817;\n    float2 param_7 = _4829 + float2(1.0f, 0.0f);\n    float2 param_8 = _4813;\n    float2 param_9 = _4817;\n    float2 param_10 = _4829 + float2(0.0f, 1.0f);\n    float2 param_11 = _4813;\n    float2 param_12 = _4817;\n    float2 param_13 = _4829 + 1.0f.xx;\n    float3 _4871 = _4826.x.xxx;\n    return lerp(lerp(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _4871), lerp(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _4871), _4826.y.xxx);\n}\n\nfloat3 fa_xm_sample(float2 uv, float lod)\n{\n    float _4890 = max(_591_fa_tr_b.w - 1.0f, 0.0f);\n    float _4894 = clamp(lod, 0.0f, _4890);\n    int _4898 = int(floor(_4894));\n    int param = _4898;\n    float2 param_1 = uv;\n    float3 c = fa_xm_level(param, param_1);\n    float _4908 = float(_4898);\n    float _4909 = _4894 - _4908;\n    bool _4911 = _4909 > 0.001000000047497451305389404296875f;\n    bool _4918;\n    if (_4911)\n    {\n        _4918 = _4908 < _4890;\n    }\n    else\n    {\n        _4918 = _4911;\n    }\n    if (_4918)\n    {\n        int param_2 = _4898 + 1;\n        float2 param_3 = uv;\n        c = lerp(c, fa_xm_level(param_2, param_3), _4909.xxx);\n    }\n    return c;\n}\n\nfloat3 fa_transmitted(Surface s, float3 n, float3 v, float roughness, float3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4944 = fa_env_brdf(param, param_1);\n    float3 through = ((1.0f.xxx - clamp((f0 * _4944.x) + (f90.xxx * _4944.y), 0.0f.xxx, 1.0f.xxx)) * s.albedo) * (tr * keep);\n    float _4972 = max(s.thickness, 0.0f);\n    bool _4977 = _4972 > 0.0f;\n    if ((s.attenuation_distance > 0.0f) && _4977)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, 9.9999997473787516355514526367188e-05f.xxx, 1.0f.xxx))) / s.attenuation_distance.xxx)) * _4972);\n    }\n    bool _5002 = _591_fa_tr_a.w > 1.5f;\n    bool _5009;\n    if (!_5002)\n    {\n        _5009 = _591_fa_tr_a.w < 0.5f;\n    }\n    else\n    {\n        _5009 = _5002;\n    }\n    if (_5009)\n    {\n        blend = clamp(dot(through, 0.3333333432674407958984375f.xxx), 0.0f, 0.980000019073486328125f);\n        return 0.0f.xxx;\n    }\n    float3 world = fa_world_pos;\n    if (_4977)\n    {\n        world += (refract(-v, n, 1.0f / max(s.ior, 1.0f)) * _4972);\n    }\n    float4 _5044 = float4(world, 1.0f);\n    float _5049 = dot(_591_fa_ct_vpw, _5044);\n    float2 uv = 0.5f.xx;\n    if (_5049 > 9.9999997473787516355514526367188e-05f)\n    {\n        float2 _5067 = float2(dot(_591_fa_ct_vpx, _5044), dot(_591_fa_ct_vpy, _5044)) / _5049.xx;\n        float _5075;\n        if (_591_fa_ct_a.y > 0.5f)\n        {\n            _5075 = (_5067.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _5075 = 0.5f - (_5067.y * 0.5f);\n        }\n        uv = float2((_5067.x * 0.5f) + 0.5f, _5075);\n    }\n    float2 param_2 = clamp(uv, 0.0f.xx, 1.0f.xx);\n    float param_3 = (clamp(roughness, 0.0f, 1.0f) * clamp((2.0f * s.ior) - 2.0f, 0.0f, 1.0f)) * max(_591_fa_tr_b.w - 1.0f, 0.0f);\n    return through * fa_xm_sample(param_2, param_3);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2258_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3194 = int(_2258_fa_shadow_cfg.x + 0.5f);\n    float _3204 = dot(world - _2258_fa_shadow_eye.xyz, _2258_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3209 = _3194 > 0;\n    bool _3218;\n    if (_3209)\n    {\n        int param = _3194 - 1;\n        _3218 = _3204 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3218 = _3209;\n    }\n    if (_3218)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3224 = _3194 > 1;\n        bool _3231;\n        if (_3224)\n        {\n            _3231 = _3204 > _2258_fa_shadow_split.x;\n        }\n        else\n        {\n            _3231 = _3224;\n        }\n        if (_3231)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3237 = _3194 > 2;\n        bool _3244;\n        if (_3237)\n        {\n            _3244 = _3204 > _2258_fa_shadow_split.y;\n        }\n        else\n        {\n            _3244 = _3237;\n        }\n        if (_3244)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3250 = _3194 > 3;\n        bool _3257;\n        if (_3250)\n        {\n            _3257 = _3204 > _2258_fa_shadow_split.z;\n        }\n        else\n        {\n            _3257 = _3250;\n        }\n        if (_3257)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _7313 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _7313 = -_7313;\n    }\n    float3 _6603 = normalize(_591_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _7326 = { fa_world_pos, _7313, fa_world_tangent, fa_uv, fa_vertex_color, _6603, gl_FrontFacing };\n    SurfaceInput param_1 = _7326;\n    Surface _6611 = fa_standard_surface(param_1);\n    float3 _7344 = _6611.albedo;\n    float _7345 = _6611.alpha;\n    float3 _7346 = _6611.normal;\n    float _7347 = _6611.metallic;\n    float _7348 = _6611.roughness;\n    float _7349 = _6611.occlusion;\n    float3 _7350 = _6611.emission;\n    float _7351 = _6611.clearcoat;\n    float _7352 = _6611.clearcoat_roughness;\n    float3 _7353 = _6611.sheen_color;\n    float _7354 = _6611.sheen_roughness;\n    float _7355 = _6611.anisotropy;\n    float _7356 = _6611.anisotropy_rotation;\n    float _7357 = _6611.specular;\n    float _7358 = _6611.ior;\n    float3 _7359 = _6611.specular_color;\n    float _7360 = _6611.transmission;\n    float _7361 = _6611.thickness;\n    float3 _7362 = _6611.attenuation_color;\n    float _7363 = _6611.attenuation_distance;\n    SurfaceInput _7334 = { fa_world_pos, _7313, fa_world_tangent, fa_uv, fa_vertex_color, _6603, gl_FrontFacing };\n    SurfaceInput param_2 = _7334;\n    Surface param_3 = _6611;\n    surface(param_2, param_3);\n    _7344 = param_3.albedo;\n    _7345 = param_3.alpha;\n    _7346 = param_3.normal;\n    _7347 = param_3.metallic;\n    _7348 = param_3.roughness;\n    _7349 = param_3.occlusion;\n    _7350 = param_3.emission;\n    _7351 = param_3.clearcoat;\n    _7352 = param_3.clearcoat_roughness;\n    _7353 = param_3.sheen_color;\n    _7354 = param_3.sheen_roughness;\n    _7355 = param_3.anisotropy;\n    _7356 = param_3.anisotropy_rotation;\n    _7357 = param_3.specular;\n    _7358 = param_3.ior;\n    _7359 = param_3.specular_color;\n    _7360 = param_3.transmission;\n    _7361 = param_3.thickness;\n    _7362 = param_3.attenuation_color;\n    _7363 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _7313;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _7344 = param_6;\n    _7346 = param_7;\n    float fa_tr_blend = 0.0f;\n    float3 result;\n    if (_591_fa_emissive.w > 0.5f)\n    {\n        result = _7344;\n    }\n    else\n    {\n        float3 _6651 = normalize(_7346);\n        float _6658 = clamp(_7347, 0.0f, 1.0f);\n        float _6662 = clamp(_7348, 0.0500000007450580596923828125f, 1.0f);\n        float _6666 = _6662 * _6662;\n        float _6670 = _6666 * _6666;\n        float _6675 = max(dot(_6651, _6603), 9.9999997473787516355514526367188e-05f);\n        float _6681 = 1.0f - _6658;\n        float _6682 = clamp(_7360, 0.0f, 1.0f) * _6681;\n        float3 _6691 = (_7344 * _6681) * (1.0f - _6682);\n        float3 _6698 = lerp(0.039999999105930328369140625f.xxx, _7344, _6658.xxx);\n        float3 f0 = _6698;\n        SurfaceInput _7342 = { fa_world_pos, _7313, fa_world_tangent, fa_uv, fa_vertex_color, _6603, gl_FrontFacing };\n        SurfaceInput param_8 = _7342;\n        Surface _7445 = { _7344, _7345, _7346, _7347, _7348, _7349, _7350, _7351, _7352, _7353, _7354, _7355, _7356, _7357, _7358, _7359, _7360, _7361, _7362, _7363 };\n        Surface param_9 = _7445;\n        float3 param_10 = _6651;\n        float3 param_11 = _6603;\n        float param_12 = _6658;\n        float param_13 = _6662;\n        float3 param_14 = _6698;\n        FaLayers _6714 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _6651;\n        float3 lit = (fa_indirect_diffuse(param_15) * _6691) * _7349;\n        if (_6714.on)\n        {\n            lit *= _6714.base_scale;\n        }\n        int _6736 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6736; ln++)\n        {\n            int param_16 = ln;\n            int _6749 = fa_cl_light(param_16);\n            bool _6752 = fa_lm.z > 0.5f;\n            bool _6758;\n            if (_6752)\n            {\n                int param_17 = _6749;\n                _6758 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _6758 = _6752;\n            }\n            if (_6758)\n            {\n                continue;\n            }\n            int param_18 = _6749;\n            float3 param_19 = fa_world_pos;\n            float3 param_20 = _7313;\n            LightSample _6770 = fa_light_shadowed(param_18, param_19, param_20);\n            float _6778 = max(dot(_6651, _6770.direction), 0.0f);\n            float _6784 = _6770.attenuation * _6770.shadow;\n            float3 _6789 = normalize(_6770.direction + _6603);\n            float _6794 = max(dot(_6651, _6789), 0.0f);\n            float _6799 = max(dot(_6603, _6789), 0.0f);\n            bool _6806;\n            if (fa_light_is_area)\n            {\n                _6806 = !_6714.on;\n            }\n            else\n            {\n                _6806 = fa_light_is_area;\n            }\n            if (_6806)\n            {\n                int param_21 = _6749;\n                float3 param_22 = fa_world_pos;\n                float3 param_23 = _6651;\n                float3 param_24 = _6603;\n                float3 param_25 = _6691;\n                float3 param_26 = f0;\n                float param_27 = 1.0f;\n                float param_28 = _6662;\n                float param_29 = _6675;\n                float param_30 = _6784;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _6714;\n                    int param_32 = _6749;\n                    float3 param_33 = fa_world_pos;\n                    float3 param_34 = _6651;\n                    float3 param_35 = _6603;\n                    float3 param_36 = _6770.direction;\n                    float3 param_37 = _6691;\n                    float3 param_38 = f0;\n                    float param_39 = _6662;\n                    float param_40 = _6675;\n                    float param_41 = _6784;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_6714.on)\n                    {\n                        FaLayers param_42 = _6714;\n                        float3 param_43 = _6691;\n                        float3 param_44 = f0;\n                        float3 param_45 = _6651;\n                        float3 param_46 = _6603;\n                        float3 param_47 = _6770.direction;\n                        float3 param_48 = _6789;\n                        float param_49 = _6778;\n                        float param_50 = _6675;\n                        float param_51 = _6794;\n                        float param_52 = _6799;\n                        float param_53 = _6666;\n                        float param_54 = _6670;\n                        int param_55 = _6749;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _6784));\n                    }\n                    else\n                    {\n                        float _6912 = ((_6794 * _6794) * (_6670 - 1.0f)) + 1.0f;\n                        int param_56 = _6749;\n                        lit += (((_6691 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _6799, 5.0f))) * (((_6670 / ((3.1415927410125732421875f * _6912) * _6912)) * (0.5f / max(lerp((2.0f * _6778) * _6675, _6778 + _6675, _6666), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _6778))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_6778 * _6784));\n                    }\n                }\n            }\n        }\n        if (_6714.on)\n        {\n            FaLayers param_57 = _6714;\n            float3 param_58 = _6651;\n            float3 param_59 = _6603;\n            float3 param_60 = f0;\n            float param_61 = _6662;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _7349);\n        }\n        else\n        {\n            float3 param_62 = _6651;\n            float3 param_63 = _6603;\n            float3 param_64 = f0;\n            float param_65 = _6662;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _7349);\n        }\n        if (_6682 > 0.0f)\n        {\n            float _7010;\n            if (_6714.on)\n            {\n                _7010 = _6714.f90;\n            }\n            else\n            {\n                _7010 = 1.0f;\n            }\n            float _7018;\n            if (_6714.on)\n            {\n                _7018 = _6714.base_scale;\n            }\n            else\n            {\n                _7018 = 1.0f;\n            }\n            Surface _7466 = { _7344, _7345, _7346, _7347, _7348, _7349, _7350, _7351, _7352, _7353, _7354, _7355, _7356, _7357, _7358, _7359, _7360, _7361, _7362, _7363 };\n            Surface param_66 = _7466;\n            float3 param_67 = _6651;\n            float3 param_68 = _6603;\n            float param_69 = _6662;\n            float3 param_70 = f0;\n            float param_71 = _7010;\n            float param_72 = _7018;\n            float param_73 = _6682;\n            float param_74 = fa_tr_blend;\n            float3 _7042 = fa_transmitted(param_66, param_67, param_68, param_69, param_70, param_71, param_72, param_73, param_74);\n            fa_tr_blend = param_74;\n            lit += _7042;\n        }\n        result = lit;\n    }\n    float3 _7049 = result;\n    float3 _7050 = _7049 + _7350;\n    result = _7050;\n    float3 param_75 = _7050;\n    float3 param_76 = fa_world_pos;\n    result = fa_shadow_debug(param_75, param_76);\n    bool _7059 = _591_fa_fog.w > 0.0f;\n    bool _7066;\n    if (!_7059)\n    {\n        _7066 = _591_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _7066 = _7059;\n    }\n    if (_7066)\n    {\n        float3 _7075 = fa_world_pos - _591_fa_camera_pos.xyz;\n        float _7081 = dot(_7075, _591_fa_fog_c.xyz);\n        bool _7085 = _591_fa_fog_c.w > 0.5f;\n        float _7086;\n        if (_7085)\n        {\n            _7086 = _7081;\n        }\n        else\n        {\n            _7086 = length(_7075);\n        }\n        float _7098 = _7086 - _591_fa_fog_b.x;\n        if (_7098 > 0.0f)\n        {\n            float _7107 = _591_fa_fog.w * _7098;\n            float tau = _7107 * _7107;\n            if (_591_fa_fog_b.y > 0.0f)\n            {\n                float _7123;\n                if (_7085)\n                {\n                    _7123 = fa_world_pos.y - (_591_fa_fog_c.y * _7081);\n                }\n                else\n                {\n                    _7123 = _591_fa_camera_pos.y;\n                }\n                float _7144 = lerp(_7123, fa_world_pos.y, clamp(_591_fa_fog_b.x / _7086, 0.0f, 1.0f));\n                float _7148 = fa_world_pos.y - _7144;\n                float _7153 = _7144 - _591_fa_fog_b.z;\n                float _7158 = fa_world_pos.y - _591_fa_fog_b.z;\n                bool _7161 = _7153 <= 0.0f;\n                bool _7162 = !_7161;\n                bool _7168;\n                if (_7162)\n                {\n                    _7168 = _591_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _7168 = _7161;\n                }\n                float _7169;\n                if (_7168)\n                {\n                    _7169 = _591_fa_fog_b.y;\n                }\n                else\n                {\n                    _7169 = _591_fa_fog_b.y * exp(-min(_591_fa_fog_b.w * _7153, 80.0f));\n                }\n                bool _7196;\n                if (_7162)\n                {\n                    _7196 = _591_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _7196 = _7161;\n                }\n                float _7197;\n                if (_7196)\n                {\n                    _7197 = _591_fa_fog_b.y * _7153;\n                }\n                else\n                {\n                    _7197 = (_591_fa_fog_b.y * (1.0f - exp(-min(_591_fa_fog_b.w * _7153, 80.0f)))) / _591_fa_fog_b.w;\n                }\n                bool _7222 = _7158 <= 0.0f;\n                bool _7229;\n                if (!_7222)\n                {\n                    _7229 = _591_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _7229 = _7222;\n                }\n                float _7230;\n                if (_7229)\n                {\n                    _7230 = _591_fa_fog_b.y * _7158;\n                }\n                else\n                {\n                    _7230 = (_591_fa_fog_b.y * (1.0f - exp(-min(_591_fa_fog_b.w * _7158, 80.0f)))) / _591_fa_fog_b.w;\n                }\n                float _7257;\n                if (abs(_7148) < 0.001000000047497451305389404296875f)\n                {\n                    _7257 = _7169;\n                }\n                else\n                {\n                    _7257 = (_7230 - _7197) / _7148;\n                }\n                tau += (_7098 * max(_7257, 0.0f));\n            }\n            result = lerp(result, _591_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    if (fa_tr_blend > 0.0f)\n    {\n        float _7293 = 1.0f - fa_tr_blend;\n        result /= _7293.xxx;\n        _7345 *= _7293;\n    }\n    fa_frag_color = float4(result, _7345);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "type": "vec2",
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
            "inst_name": "_144",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 512,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_591",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2258",
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
          },
          {
            "texture": {
              "slot": 28,
              "stage": "fragment",
              "name": "fa_screen_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
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
          },
          {
            "slot": 11,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _149_fa_view_proj : packoffset(c0);\n    row_major float4x4 _149_fa_light_vp : packoffset(c4);\n    float4 _149_fa_uv_scale : packoffset(c8);\n    float4 _149_fa_time : packoffset(c9);\n    float4 _149_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _195_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float2 fa_attr_uv1;\nstatic float4 fa_attr_color1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n    float2 fa_attr_uv1 : TEXCOORD11;\n    float4 fa_attr_color1 : TEXCOORD12;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4 vertex_color1;\nstatic float2 vertex_uv1;\n\nvoid fa_inst_begin()\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _186 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_195_fa_joint_rows[_186] * weights[i]);\n        r1 += (_195_fa_joint_rows[_186 + 1] * weights[i]);\n        r2 += (_195_fa_joint_rows[_186 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _88 = cross(model[1].xyz, model[2].xyz);\n    float _94 = (dot(model[0].xyz, _88) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _401 = { mul(float4(position, 1.0f), model).xyz, (((_88 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _94, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _94), texcoord0 * _149_fa_uv_scale.xy, color, position };\n    return _401;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.color = vertex_color1;\n    v.uv = vertex_uv1;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _149_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_attr_uv1 = stage_input.fa_attr_uv1;\n    fa_attr_color1 = stage_input.fa_attr_color1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _3688[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _591_fa_camera_pos : packoffset(c0);\n    float4 _591_fa_ambient : packoffset(c1);\n    float4 _591_fa_base_color : packoffset(c2);\n    float4 _591_fa_emissive : packoffset(c3);\n    float4 _591_fa_model_emissive : packoffset(c4);\n    float4 _591_fa_pbr : packoffset(c5);\n    float4 _591_fa_maps : packoffset(c6);\n    float4 _591_fa_fog : packoffset(c7);\n    float4 _591_fa_fog_b : packoffset(c8);\n    float4 _591_fa_fog_c : packoffset(c9);\n    float4 _591_fa_counts : packoffset(c10);\n    float4 _591_fa_env_sky : packoffset(c11);\n    float4 _591_fa_env_horizon : packoffset(c12);\n    float4 _591_fa_time : packoffset(c13);\n    float4 _591_fa_cl_vpx : packoffset(c14);\n    float4 _591_fa_cl_vpy : packoffset(c15);\n    float4 _591_fa_cl_vpw : packoffset(c16);\n    float4 _591_fa_cl_fwd : packoffset(c17);\n    float4 _591_fa_cl_grid : packoffset(c18);\n    float4 _591_fa_cl_info : packoffset(c19);\n    float4 _591_fa_layers_a : packoffset(c20);\n    float4 _591_fa_layers_b : packoffset(c21);\n    float4 _591_fa_layers_c : packoffset(c22);\n    float4 _591_fa_layers_d : packoffset(c23);\n    float4 _591_fa_ct_a : packoffset(c24);\n    float4 _591_fa_ct_b : packoffset(c25);\n    float4 _591_fa_ct_vpx : packoffset(c26);\n    float4 _591_fa_ct_vpy : packoffset(c27);\n    float4 _591_fa_ct_vpw : packoffset(c28);\n    float4 _591_fa_ct_fwd : packoffset(c29);\n    float4 _591_fa_tr_a : packoffset(c30);\n    float4 _591_fa_tr_b : packoffset(c31);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2258_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2258_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2258_fa_shadow_info[4] : packoffset(c20);\n    float4 _2258_fa_shadow_split : packoffset(c24);\n    float4 _2258_fa_shadow_cfg : packoffset(c25);\n    float4 _2258_fa_shadow_bias : packoffset(c26);\n    float4 _2258_fa_shadow_eye : packoffset(c27);\n    float4 _2258_fa_shadow_fwd : packoffset(c28);\n    float4 _2258_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_screen_tex : register(t11);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1529 = _591_fa_cl_info.x < 0.0f;\n    bool _1536;\n    if (!_1529)\n    {\n        _1536 = _591_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1536 = _1529;\n    }\n    bool _1544;\n    if (!_1536)\n    {\n        _1544 = _591_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1544 = _1536;\n    }\n    bool _1551;\n    if (!_1544)\n    {\n        _1551 = _591_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1551 = _1544;\n    }\n    bool _1558;\n    if (!_1551)\n    {\n        _1558 = _591_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1558 = _1551;\n    }\n    if (_1558)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1568 = float4(world_pos, 1.0f);\n    float _1574 = dot(_591_fa_cl_vpw, _1568);\n    if (!(_1574 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1596 = float2(dot(_591_fa_cl_vpx, _1568), dot(_591_fa_cl_vpy, _1568)) / _1574.xx;\n    int _1600 = int(_591_fa_cl_grid.x);\n    int _1604 = int(_591_fa_cl_grid.y);\n    int param = (int(_591_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_591_fa_cl_fwd.xyz, world_pos) + _591_fa_cl_fwd.w, _591_fa_cl_grid.w) / _591_fa_cl_grid.w) * _591_fa_cl_grid.z)), 0, int(_591_fa_cl_info.y) - 1) * _1604) + clamp(int(floor(((_1596.y * 0.5f) + 0.5f) * _591_fa_cl_grid.y)), 0, _1604 - 1)) * _1600)) + clamp(int(floor(((_1596.x * 0.5f) + 0.5f) * _591_fa_cl_grid.x)), 0, _1600 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1680 = fa_cluster_texel(param);\n    return int2(int(_1680.x), int(_1680.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_591_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _5121 = fa_cluster_lookup(param);\n    fa_cl_slot = _5121.x;\n    fa_cl_local = _5121.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _6260 = fa_linear_to_srgb(param);\n        c = _6260;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _6268 = fa_srgb_to_linear(param_1);\n            c = _6268;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _474;\n    if (i.front_facing)\n    {\n        _474 = i.world_normal;\n    }\n    else\n    {\n        _474 = -i.world_normal;\n    }\n    float3 _498 = normalize(i.world_tangent.xyz - (_474 * dot(_474, i.world_tangent.xyz)));\n    float3 _525 = normalize(((_498 * m.x) + ((cross(_474, _498) * i.world_tangent.w) * m.y)) + (_474 * m.z));\n    float3 _528;\n    if (i.front_facing)\n    {\n        _528 = _525;\n    }\n    else\n    {\n        _528 = -_525;\n    }\n    return _528;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _591_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _6299 = fa_tex_fix(param_2, param_3);\n    float4 _7865 = base_t;\n    _7865.x = _6299.x;\n    _7865.y = _6299.y;\n    _7865.z = _6299.z;\n    base_t = _7865;\n    float4 _6313 = (_7865 * _591_fa_base_color) * i.vertex_color;\n    float3 _7674 = i.world_normal;\n    if (_591_fa_maps.z > 0.5f)\n    {\n        float param_4 = _591_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _6345 = fa_tex_fix(param_6, param_7);\n        float3 _6348 = (_6345 * 2.0f) - 1.0f.xxx;\n        float2 _6353 = _6348.xy * _591_fa_maps.x;\n        float3 _7873 = _6348;\n        _7873.x = _6353.x;\n        _7873.y = _6353.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _7873;\n        _7674 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _591_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _6381 = fa_tex_fix(param_12, param_13);\n    float4 _7876 = mrt;\n    _7876.x = _6381.x;\n    _7876.y = _6381.y;\n    _7876.z = _6381.z;\n    mrt = _7876;\n    float4 _6409 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _591_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _6409.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _6420 = fa_tex_fix(param_16, param_17);\n    float param_18 = _591_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _6450 = fa_tex_fix(param_20, param_21);\n    float _7679 = _591_fa_layers_a.x;\n    float _7680 = _591_fa_layers_a.y;\n    float _7683 = _591_fa_layers_a.z;\n    float _7682 = _591_fa_layers_b.w;\n    float _7685 = _591_fa_layers_c.x;\n    if (_591_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_591_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _7679 *= _6420.y;\n            _7680 *= _6420.z;\n            _7682 *= _6409.w;\n        }\n        if (_591_fa_layers_c.z > 1.5f)\n        {\n            _7683 *= mrt.x;\n            _7685 *= mrt.w;\n        }\n    }\n    Surface _7712 = { _6313.xyz, _6313.w, _7674, clamp(_591_fa_pbr.x * _6381.z, 0.0f, 1.0f), clamp(_591_fa_pbr.y * _6381.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_591_fa_maps.y * (_6420.x - 1.0f)), _591_fa_emissive.xyz + (_591_fa_model_emissive.xyz * _6450), _7679, _7680, _591_fa_layers_b.xyz, _7682, _7683, _591_fa_layers_a.w, _7685, _591_fa_layers_c.y, _591_fa_layers_d.xyz, _591_fa_tr_a.x, _591_fa_tr_a.y, _591_fa_tr_b.xyz, _591_fa_tr_a.z };\n    return _7712;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * (i.uv.x * 2.0f));\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1760 = rect.zw - rect.xy;\n    float2 _1764 = _1760 * atlas;\n    float2 _1768 = ddx * _1764;\n    float2 _1772 = ddy * _1764;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1760), clamp(0.5f * log2(max(max(dot(_1768, _1768), dot(_1772, _1772)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1805 = _591_fa_counts.y < 0.5f;\n    bool _1812;\n    if (!_1805)\n    {\n        _1812 = _591_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1812 = _1805;\n    }\n    if (_1812)\n    {\n        return;\n    }\n    float3 _1818 = ddx(world_pos);\n    float3 _1821 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1825 = fa_cluster_texel(param);\n    int _1829 = int(_1825.w);\n    if (_1829 < 1)\n    {\n        return;\n    }\n    int _1839 = int(_591_fa_counts.y + 0.5f);\n    int param_1 = _1839;\n    float4 _1843 = fa_light_texel(param_1);\n    float2 _1846 = _1843.yz;\n    int _1850 = int(_1843.w);\n    int param_2 = _1839 + 1;\n    float4 _1855 = fa_light_texel(param_2);\n    float _1856 = _1855.x;\n    int _1862 = int(_591_fa_counts.w + 0.5f) - 1;\n    int _1866 = int(_1825.z);\n    float3 _2131;\n    for (int k = 0; k < _1829; k++)\n    {\n        int _1879 = _1866 + k;\n        int param_3 = _1850 + (_1879 >> 2);\n        int _1896 = (_1839 + 2) + (int(fa_light_texel(param_3)[_1879 & 3]) * 7);\n        int param_4 = _1896 + 6;\n        float4 _1901 = fa_light_texel(param_4);\n        if (((int(_1901.w + 0.5f) >> _1862) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1896;\n        float4 _1916 = fa_light_texel(param_5);\n        int param_6 = _1896 + 1;\n        float4 _1921 = fa_light_texel(param_6);\n        int param_7 = _1896 + 2;\n        float4 _1926 = fa_light_texel(param_7);\n        float3 _1929 = _1916.xyz;\n        float _1934 = dot(_1929, world_pos) + _1916.w;\n        float3 _1936 = _1921.xyz;\n        float _1941 = dot(_1936, world_pos) + _1921.w;\n        float3 _1943 = _1926.xyz;\n        float _1948 = dot(_1943, world_pos) + _1926.w;\n        bool _1953 = abs(_1934) > 0.5f;\n        bool _1961;\n        if (!_1953)\n        {\n            _1961 = abs(_1941) > 0.5f;\n        }\n        else\n        {\n            _1961 = _1953;\n        }\n        bool _1969;\n        if (!_1961)\n        {\n            _1969 = abs(_1948) > 0.5f;\n        }\n        else\n        {\n            _1969 = _1961;\n        }\n        if (_1969)\n        {\n            continue;\n        }\n        float _1984 = clamp(dot(geo_normal, normalize(_1943)) * _1901.z, 0.0f, 1.0f);\n        if (_1984 <= 0.0f)\n        {\n            continue;\n        }\n        float _2004 = (clamp((0.5f - abs(_1948)) * 10.0f, 0.0f, 1.0f) * _1984) * _1901.x;\n        float2 _2012 = float2(_1934 + 0.5f, 0.5f - _1941);\n        float2 _2022 = float2(dot(_1929, _1818), dot(_1936, _1818));\n        float2 _2032 = float2(dot(_1929, _1821), dot(_1936, _1821));\n        int param_8 = _1896 + 5;\n        float4 _2037 = fa_light_texel(param_8);\n        int param_9 = _1896 + 3;\n        float4 _2042 = fa_light_texel(param_9);\n        int param_10 = _1896 + 4;\n        float4 _2047 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _2037.xyz;\n        bool _2057 = _2042.z > _2042.x;\n        if (_2057)\n        {\n            float4 param_11 = _2042;\n            float2 param_12 = _2012;\n            float2 param_13 = _1846;\n            float2 param_14 = _2022;\n            float2 param_15 = _2032;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1856 > 0.5f) && (_1856 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _2083 = fa_dc_to_linear(param_16);\n                float4 _7762 = tx;\n                _7762.x = _2083.x;\n                _7762.y = _2083.y;\n                _7762.z = _2083.z;\n                tx = _7762;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_2004 * tex_a) * _2037.w, 0.0f, 1.0f).xxx);\n        if (_2047.z > _2047.x)\n        {\n            float4 param_17 = _2047;\n            float2 param_18 = _2012;\n            float2 param_19 = _1846;\n            float2 param_20 = _2022;\n            float2 param_21 = _2032;\n            float4 _2127 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1856 > 1.5f)\n            {\n                float3 param_22 = _2127.xyz;\n                float3 _2137 = fa_dc_to_srgb(param_22);\n                _2131 = _2137;\n            }\n            else\n            {\n                _2131 = _2127.xyz;\n            }\n            float3 _2146 = (_2131 * 2.0f) - 1.0f.xxx;\n            float2 _2151 = _2146.xy * _1901.y;\n            float3 _2173 = (normalize(_1929) * _2151.x) + (normalize(_1936) * _2151.y);\n            float3 _2176 = normalize(normal);\n            normal = normalize(lerp(_2176, normalize((_2176 * max(_2146.z, 0.0500000007450580596923828125f)) + (_2173 - (_2176 * dot(_2176, _2173)))), clamp(_2004 * (_2057 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3614 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3621 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3624 = int(_3614);\n    int _3627 = int(_3621);\n    float _3637 = _3621 - float(_3627);\n    int _3692 = (_3624 * 9) + _3627;\n    int _3712 = ((_3624 + 1) * 9) + _3627;\n    return lerp(lerp(_3688[_3692], _3688[_3692 + 1], _3637), lerp(_3688[_3712], _3688[_3712 + 1], _3637), _3614 - float(_3624));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _7597 = false;\n    float _7598 = 1.0f;\n    float _7599 = 1.0f;\n    float _7600 = 1.0f;\n    float _7601 = 0.0f;\n    float _7602 = 0.0f;\n    float _7603 = 0.0f;\n    float _7604 = 0.0f;\n    float _7606 = 1.0f;\n    bool _7607 = false;\n    float3 _7608 = 0.0f.xxx;\n    float _7609 = 1.0f;\n    float _7610 = 1.0f;\n    float _7611 = 1.0f;\n    float _7612 = 0.0f;\n    float _7613 = 0.0f;\n    float3 _7614 = float3(1.0f, 0.0f, 0.0f);\n    float3 _7615 = float3(0.0f, 0.0f, 1.0f);\n    float _7616 = 1.0f;\n    float _7617 = 1.0f;\n    float _3763 = clamp(s.specular, 0.0f, 1.0f);\n    float _3767 = clamp(s.ior, 1.0f, 3.0f);\n    bool _3772 = (_3763 != 1.0f) || (_3767 != 1.5f);\n    bool _3781;\n    if (!_3772)\n    {\n        _3781 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _3781 = _3772;\n    }\n    if (_3781)\n    {\n        float _3789 = (_3767 - 1.0f) / (_3767 + 1.0f);\n        f0 = lerp(min((_3789 * _3789).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _3763, s.albedo, metallic.xxx);\n        _7598 = lerp(_3763, 1.0f, metallic);\n        _7597 = true;\n    }\n    float _3816 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_3816 > 0.0f)\n    {\n        float _3824 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _7601 = _3816;\n        _7602 = _3824;\n        float _3831 = _3824 * _3824;\n        _7603 = _3831;\n        _7604 = _3831 * _3831;\n        float _3843 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _7606 = _3843;\n        _7599 = 1.0f - (_3816 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _3843, 0.0f, 1.0f), 5.0f))));\n        _7597 = true;\n    }\n    float3 _3862 = max(s.sheen_color, 0.0f.xxx);\n    float _3871 = max(_3862.x, max(_3862.y, _3862.z));\n    if (_3871 > 0.0f)\n    {\n        float _3879 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _7607 = true;\n        _7608 = _3862;\n        _7609 = _3879;\n        _7610 = _3879 * _3879;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _3879;\n        float _3896 = fa_sheen_albedo(param, param_1);\n        _7612 = _3896;\n        _7611 = 1.0f - min(_3871 * _3896, 1.0f);\n        _7597 = true;\n    }\n    _7600 = _7599 * _7611;\n    float _3915 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_3915 != 0.0f)\n    {\n        float3 _3930 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _3930;\n        if (dot(_3930, _3930) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _3942 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_3942.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _3942.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _3942.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _3946 = t;\n        float3 _3947 = normalize(_3946);\n        t = _3947;\n        float3 _3972 = normalize((_3947 * cos(s.anisotropy_rotation)) + ((cross(n, _3947) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _7614 = _3972;\n        _7615 = cross(n, _3972);\n        float _3982 = roughness * roughness;\n        float _3988 = lerp(_3982, 1.0f, _3915 * _3915);\n        bool _3990 = _3915 > 0.0f;\n        _7616 = _3990 ? _3988 : _3982;\n        _7617 = _3990 ? _3982 : _3988;\n        _7613 = _3915;\n        _7597 = true;\n    }\n    FaLayers _7639 = { _7597, _7598, _7599, _7600, _7601, _7602, _7603, _7604, i.world_normal, _7606, _7607, _7608, _7609, _7610, _7611, _7612, _7613, _7614, _7615, _7616, _7617 };\n    return _7639;\n}\n\nfloat3 fa_sky_sh_coef(int k)\n{\n    float3 v = fa_env_tex.SampleLevel(fa_env_smp, float3(1.0f, 1.0f - (float((2 * (k >> 2)) + 1) * 0.25f), 1.0f - (float((2 * (k & 3)) + 1) * 0.25f)), 5.0f).xyz;\n    if (_591_fa_env_sky.w > 1.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3371 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3371;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_591_fa_env_sky.w > 0.5f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _591_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_591_fa_cl_info.x) + int(_591_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_591_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _659_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _659_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _778 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _791 = (c - (ru * hx)) - p;\n        float3 _797 = ru * (2.0f * hx);\n        float _803 = max(dot(_797, _797), 9.9999999392252902907785028219223e-09f);\n        float _807 = dot(_791, _797);\n        float t = clamp((-_807) / _803, 0.0f, 1.0f);\n        if (_778)\n        {\n            float _822 = dot(r, _797);\n            float _828 = _803 - (_822 * _822);\n            if (abs(_828) > (9.9999997473787516355514526367188e-06f * _803))\n            {\n                t = clamp(((dot(r, _791) * _822) - _807) / _828, 0.0f, 1.0f);\n            }\n        }\n        return (p + _791) + (_797 * t);\n    }\n    float3 q = p;\n    float _860 = dot(r, axis);\n    bool _868;\n    if (_778)\n    {\n        _868 = abs(_860) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _868 = _778;\n    }\n    if (_868)\n    {\n        float _878 = dot(c - p, axis) / _860;\n        if (_878 > 0.0f)\n        {\n            q = p + (r * _878);\n        }\n    }\n    float3 _891 = q - c;\n    float2 xy = float2(dot(_891, ru), dot(_891, uu));\n    if (shape > 0.5f)\n    {\n        float _906 = length(xy);\n        if (_906 > hx)\n        {\n            xy *= (hx / _906);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _540 = abs(d);\n    float _542 = _540.x;\n    float _544 = _540.y;\n    bool _545 = _542 >= _544;\n    bool _553;\n    if (_545)\n    {\n        _553 = _542 >= _540.z;\n    }\n    else\n    {\n        _553 = _545;\n    }\n    int _554;\n    if (_553)\n    {\n        _554 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _569;\n        if (_544 >= _540.z)\n        {\n            _569 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _569 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _554 = _569;\n    }\n    return _554;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _698 = dot(d, right);\n    float _702 = dot(d, up);\n    float _713;\n    if (((_698 * _698) + (_702 * _702)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _713 = atan2(_702, _698) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _713 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_713 - floor(_713)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _944 = fa_light_base(param);\n    bool _948 = _591_fa_ambient.w > 4.5f;\n    int param_1 = _944;\n    float4 _952 = fa_light_texel(param_1);\n    int param_2 = _944 + 1;\n    float4 _957 = fa_light_texel(param_2);\n    float _960 = _957.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _972 = _948 && (_960 > 2.5f);\n    fa_light_is_area = _972;\n    bool _974 = _960 < 0.5f;\n    float3 l;\n    if (_974)\n    {\n        l = normalize(_952.xyz);\n        if (_948)\n        {\n            int param_3 = _944 + 6;\n            float4 _988 = fa_light_texel(param_3);\n            if (_988.z > 0.5f)\n            {\n                int param_4 = _944 + 4;\n                float4 _998 = fa_light_texel(param_4);\n                int param_5 = _944 + 5;\n                float4 _1003 = fa_light_texel(param_5);\n                float2 param_6 = _988.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _998.xyz) * _998.w, (-dot(world_pos, _1003.xyz)) * _1003.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _1033 = _952.xyz;\n        float3 _1035 = _1033 - world_pos;\n        float3 to_light = _1035;\n        float _1038 = length(_1035);\n        float reach = _1038;\n        bool front = true;\n        if (_972)\n        {\n            int param_8 = _944 + 7;\n            reach = max(_1038 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _944 + 4;\n            float4 _1062 = fa_light_texel(param_9);\n            int param_10 = _944 + 5;\n            float4 _1067 = fa_light_texel(param_10);\n            int param_11 = _944 + 6;\n            float4 _1072 = fa_light_texel(param_11);\n            float _1073 = _1072.w;\n            int param_12 = _944 + 2;\n            float3 _1080 = normalize(fa_light_texel(param_12).xyz);\n            bool _1082 = _1073 > 1.5f;\n            bool _1090;\n            if (!_1082)\n            {\n                _1090 = dot(_1080, to_light) < 0.0f;\n            }\n            else\n            {\n                _1090 = _1082;\n            }\n            front = _1090;\n            float3 r = 0.0f.xxx;\n            float3 _1099 = _591_fa_camera_pos.xyz - world_pos;\n            bool _1103 = dot(n, n) > 0.5f;\n            bool _1111;\n            if (_1103)\n            {\n                _1111 = dot(_1099, _1099) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _1111 = _1103;\n            }\n            if (_1111)\n            {\n                r = reflect(-normalize(_1099), normalize(n));\n            }\n            float3 param_13 = _1033;\n            float3 param_14 = _1080;\n            float3 param_15 = _1062.xyz;\n            float3 param_16 = _1067.xyz;\n            float param_17 = _1062.w;\n            float param_18 = _1067.w;\n            float param_19 = _1073;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1147 = length(to_light);\n        dist = _1147;\n        l = to_light / max(_1147, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1161 = reach / max(_952.w, 0.001000000047497451305389404296875f);\n        float _1167 = clamp(1.0f - (_1161 * _1161), 0.0f, 1.0f);\n        float _1169;\n        if (front)\n        {\n            _1169 = _1167 * _1167;\n        }\n        else\n        {\n            _1169 = 0.0f;\n        }\n        atten = _1169;\n        bool _1180 = _960 < 2.5f;\n        if ((_960 > 1.5f) && _1180)\n        {\n            int param_22 = _944 + 2;\n            float4 _1188 = fa_light_texel(param_22);\n            float _1198 = _1188.w;\n            int param_23 = _944 + 3;\n            float4 _1203 = fa_light_texel(param_23);\n            float _1204 = _1203.x;\n            float cos_inner = _1204;\n            if (_1204 > 1.5f)\n            {\n                cos_inner = lerp(_1198, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1198, cos_inner, dot(-l, normalize(_1188.xyz)));\n        }\n        if (_948 && (_960 < 1.5f))\n        {\n            int param_24 = _944 + 6;\n            float4 _1228 = fa_light_texel(param_24);\n            if (_1228.z > 0.5f)\n            {\n                float3 _1236 = -to_light;\n                int param_25 = _944 + 4;\n                int param_26 = _944 + 5;\n                float3 _1250 = fa_light_texel(param_25).xyz;\n                float3 _1254 = fa_light_texel(param_26).xyz;\n                float3 _1263 = float3(dot(_1236, _1250), dot(_1236, _1254), dot(_1236, cross(_1250, _1254)));\n                float3 param_27 = _1263;\n                int _1267 = fa_cube_face(param_27);\n                int param_28 = _1267;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1294 = float2(dot(_1263, cross(param_29, param_30)), dot(_1263, param_30)) / max(dot(_1263, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1298 = _1267 / 3;\n                float2 param_31 = _1228.xy + (float2(float(_1267 - (_1298 * 3)), float(_1298)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1294.x), 0.5f - (0.5f * _1294.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _944 + 7;\n            float4 _1328 = fa_light_texel(param_33);\n            if (_1328.z > 0.5f)\n            {\n                int param_34 = _944 + 2;\n                int param_35 = _944 + 4;\n                int param_36 = _944 + 5;\n                float2 param_37 = _1328.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_948 && _1180)\n            {\n                int param_42 = _944 + 6;\n                float4 _1375 = fa_light_texel(param_42);\n                int param_43 = _944 + 7;\n                float4 _1380 = fa_light_texel(param_43);\n                bool _1383 = _1375.z > 0.5f;\n                bool _1390;\n                if (!_1383)\n                {\n                    _1390 = _1380.z > 0.5f;\n                }\n                else\n                {\n                    _1390 = _1383;\n                }\n                if (_1390)\n                {\n                    int param_44 = _944 + 2;\n                    float4 _1397 = fa_light_texel(param_44);\n                    float3 _1401 = normalize(_1397.xyz);\n                    int param_45 = _944 + 4;\n                    float4 _1406 = fa_light_texel(param_45);\n                    int param_46 = _944 + 5;\n                    float4 _1411 = fa_light_texel(param_46);\n                    if (_1383)\n                    {\n                        float3 _1419 = -to_light;\n                        float _1426 = _1397.w;\n                        float _1442 = 0.5f / max(dot(_1419, _1401) * (sqrt(max(1.0f - (_1426 * _1426), 0.0f)) / max(_1426, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1375.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1419, _1406.xyz) * _1442), 0.5f - (dot(_1419, _1411.xyz) * _1442));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1380.z > 0.5f)\n                    {\n                        float2 param_49 = _1380.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1401;\n                        float3 param_52 = _1406.xyz;\n                        float3 param_53 = _1411.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _7585 = _957.xyz * atten;\n    if (_948)\n    {\n        _7585 *= fa_light_tint;\n    }\n    int _1511;\n    if (_974)\n    {\n        _1511 = 0;\n    }\n    else\n    {\n        _1511 = ((_960 > 1.5f) && (_960 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _7596 = { l, _7585, atten, 1.0f, dist, _1511 };\n    return _7596;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2248;\n    if (i == 0)\n    {\n        _2248 = _2258_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2264;\n        if (i == 1)\n        {\n            _2264 = _2258_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2272;\n            if (i == 2)\n            {\n                _2272 = _2258_fa_shadow_split.z;\n            }\n            else\n            {\n                _2272 = _2258_fa_shadow_split.w;\n            }\n            _2264 = _2272;\n        }\n        _2248 = _2264;\n    }\n    return _2248;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2305 = fa_shadow_depth(param, param_1);\n    float _2309;\n    if (conv.x < 0.5f)\n    {\n        _2309 = _2305;\n    }\n    else\n    {\n        _2309 = (conv.y * conv.z) / (conv.z - (_2305 * (conv.z - conv.y)));\n    }\n    return _2309;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2236 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2236), sin(_2236)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2355 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2364;\n        if (k < 0.0f)\n        {\n            _2364 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2364 = k;\n        }\n        float _2384 = clamp((_2364 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2355;\n            float2 _2403 = fa_shadow_vogel(param_3, param_4, param_5) * _2384;\n            float2 param_6 = uv + (_2403 * _2258_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2415 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2415 < (zr - (length(_2403) * plane)))\n            {\n                sum += _2415;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2441 = sum / cnt;\n        float _2451;\n        if (k < 0.0f)\n        {\n            _2451 = (-k) / max(_2441, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2451 = k;\n        }\n        radius = clamp(((max(zr - _2441, 0.0f) * unit) * _2451) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2473 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2473; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2473;\n        float param_11 = _2355;\n        float2 _2492 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2492 * _2258_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2492) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2473);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2534 = max(_2258_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2539 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2545 = sqrt(1.0f - (_2539 * _2539));\n    float _2552 = min(_2545 / max(_2539, 0.20000000298023223876953125f), 4.0f);\n    float _2557;\n    if (_2258_fa_shadow_bias.y > 0.0f)\n    {\n        _2557 = _2258_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2557 = 1.5f * _2258_fa_shadow_info[ci].x;\n    }\n    float4 _2582 = mul(float4(world + (n * (_2557 * _2545)), 1.0f), _2258_fa_shadow_mat[ci]);\n    float _2589 = _2582.x;\n    bool _2592 = _2589 < _2258_fa_shadow_rect[ci].x;\n    bool _2601;\n    if (!_2592)\n    {\n        _2601 = _2589 > _2258_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2601 = _2592;\n    }\n    bool _2610;\n    if (!_2601)\n    {\n        _2610 = _2582.y < _2258_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2610 = _2601;\n    }\n    bool _2619;\n    if (!_2610)\n    {\n        _2619 = _2582.y > _2258_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2619 = _2610;\n    }\n    bool _2626;\n    if (!_2619)\n    {\n        _2626 = _2582.z > 1.0f;\n    }\n    else\n    {\n        _2626 = _2619;\n    }\n    if (_2626)\n    {\n        return -1.0f;\n    }\n    float _2634;\n    if (_2258_fa_shadow_bias.x > 0.0f)\n    {\n        _2634 = _2258_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2634 = 1.5f * _2258_fa_shadow_info[ci].x;\n    }\n    float2 param = _2582.xy;\n    float4 param_1 = _2258_fa_shadow_rect[ci];\n    float param_2 = _2582.z - ((_2634 * (1.0f + (0.5f * _2552))) / _2534);\n    float param_3 = _2258_fa_shadow_info[ci].x;\n    float param_4 = _2534;\n    float param_5 = _2534 * 0.25f;\n    float param_6 = ((_2258_fa_shadow_info[ci].x * min(_2552, 3.0f)) * 0.5f) / _2534;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2258_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2258_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_591_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _3012 = int(_2258_fa_shadow_cfg.x + 0.5f);\n    if (_3012 < 1)\n    {\n        return 1.0f;\n    }\n    float _3027 = dot(world - _2258_fa_shadow_eye.xyz, _2258_fa_shadow_fwd.xyz);\n    int param = _3012 - 1;\n    if (_3027 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _3039 = _3012 > 1;\n    bool _3046;\n    if (_3039)\n    {\n        _3046 = _3027 > _2258_fa_shadow_split.x;\n    }\n    else\n    {\n        _3046 = _3039;\n    }\n    if (_3046)\n    {\n        ci = 1;\n    }\n    bool _3050 = _3012 > 2;\n    bool _3057;\n    if (_3050)\n    {\n        _3057 = _3027 > _2258_fa_shadow_split.y;\n    }\n    else\n    {\n        _3057 = _3050;\n    }\n    if (_3057)\n    {\n        ci = 2;\n    }\n    bool _3061 = _3012 > 3;\n    bool _3068;\n    if (_3061)\n    {\n        _3068 = _3027 > _2258_fa_shadow_split.z;\n    }\n    else\n    {\n        _3068 = _3061;\n    }\n    if (_3068)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _3012)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _3094 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3094;\n        if (_3094 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2258_fa_shadow_cfg.y > 0.0f)\n    {\n        float _3119;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3119 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3119 = _2258_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _3138 = _2258_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3119, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _3149 = clamp((_3027 - (fa_shadow_split_at(param_7) - _3138)) / _3138, 0.0f, 1.0f);\n        if (_3149 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _3012)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _3170 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3170;\n                if (_3170 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _3149);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2692 = _591_fa_pbr.z < 0.5f;\n    bool _2699;\n    if (!_2692)\n    {\n        _2699 = _2258_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2699 = _2692;\n    }\n    if (_2699)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2258_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2712 = fa_light_texel(param);\n    float _2713 = _2712.x;\n    if (_2713 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2722 = int(_2713 + 0.5f);\n    int param_1 = _2722;\n    float4 _2726 = fa_light_texel(param_1);\n    int param_2 = _2722 + 1;\n    float4 _2731 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2734 = _2726.y;\n    if (_2734 > 0.0f)\n    {\n        float _2751 = 1.0f - smoothstep(0.75f * _2734, _2734, length(world - _2258_fa_shadow_eye.xyz));\n        fade = _2751;\n        if (_2751 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2726.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2775 = (_2722 + 2) + (face * 6);\n    int param_4 = _2775;\n    int param_5 = _2775 + 1;\n    int param_6 = _2775 + 3;\n    float4 _2789 = fa_light_texel(param_6);\n    int param_7 = _2775 + 4;\n    float4 _2794 = fa_light_texel(param_7);\n    int param_8 = _2775 + 5;\n    float4 _2799 = fa_light_texel(param_8);\n    float _2811 = _2799.x * max(dot(_2789, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2816 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2839 = clamp(dot(n, _2789.xyz), -1.0f, 1.0f);\n    float _2858 = min(sqrt(1.0f - (_2839 * _2839)) / max(abs(dot(n, world - lpos)) / max(dot(_2789, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2861 = _2731.y;\n    float _2863;\n    if (_2861 > 0.0f)\n    {\n        _2863 = _2861;\n    }\n    else\n    {\n        _2863 = 1.5f * _2811;\n    }\n    float4 _2883 = float4(world + (n * (_2863 * sqrt(1.0f - (_2816 * _2816)))), 1.0f);\n    float _2887 = dot(_2789, _2883);\n    float _2890 = _2799.y;\n    if (_2887 < _2890)\n    {\n        return 1.0f;\n    }\n    float2 _2905 = float2(dot(fa_light_texel(param_4), _2883), dot(fa_light_texel(param_5), _2883)) / _2887.xx;\n    float _2907 = _2905.x;\n    bool _2910 = _2907 < _2794.x;\n    bool _2919;\n    if (!_2910)\n    {\n        _2919 = _2907 > _2794.z;\n    }\n    else\n    {\n        _2919 = _2910;\n    }\n    bool _2928;\n    if (!_2919)\n    {\n        _2928 = _2905.y < _2794.y;\n    }\n    else\n    {\n        _2928 = _2919;\n    }\n    bool _2937;\n    if (!_2928)\n    {\n        _2937 = _2905.y > _2794.w;\n    }\n    else\n    {\n        _2937 = _2928;\n    }\n    if (_2937)\n    {\n        return 1.0f;\n    }\n    float _2943 = _2731.x;\n    float _2945;\n    if (_2943 > 0.0f)\n    {\n        _2945 = _2943;\n    }\n    else\n    {\n        _2945 = 1.5f * _2811;\n    }\n    float2 param_9 = _2905;\n    float4 param_10 = _2794;\n    float param_11 = _2887 - (_2945 * (1.0f + (0.5f * _2858)));\n    float param_12 = _2811;\n    float param_13 = 1.0f;\n    float param_14 = _2799.z * 0.25f;\n    float param_15 = (_2811 * min(_2858, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2890, _2799.z);\n    int param_17 = int(_2726.z + 0.5f);\n    float param_18 = _2726.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _4500 = _591_fa_ct_a.x < 0.5f;\n    bool _4507;\n    if (!_4500)\n    {\n        _4507 = _2258_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _4507 = _4500;\n    }\n    if (_4507)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2258_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _4520 = fa_light_texel(param);\n    float _4521 = _4520.y;\n    float len = _4521;\n    if (_4521 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4533 = length(world - _591_fa_camera_pos.xyz);\n    float _4543 = 1.0f - smoothstep(0.5f * _591_fa_ct_b.x, _591_fa_ct_b.x, _4533);\n    if (_4543 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4549 = len;\n    float _4552 = min(_4549, 0.89999997615814208984375f * dist);\n    len = _4552;\n    float _4557 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _4533);\n    float _4562 = _4557 + (0.5f * _4552);\n    float3 _4568 = world + (gn * _4557);\n    float _4570 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _4634;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4585 = (float(k) + _4570) * 0.083333335816860198974609375f;\n        float3 _4593 = _4568 + (l * (_4585 * len));\n        float4 _4599 = float4(_4593, 1.0f);\n        float _4605 = dot(_591_fa_ct_vpw, _4599);\n        if (_4605 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _4625 = float2(dot(_591_fa_ct_vpx, _4599), dot(_591_fa_ct_vpy, _4599)) / _4605.xx;\n        float _4629 = _4625.x * 0.5f;\n        float _4630 = _4629 + 0.5f;\n        if (_591_fa_ct_a.y > 0.5f)\n        {\n            _4634 = (_4625.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _4634 = 0.5f - (_4625.y * 0.5f);\n        }\n        bool _4650 = _4630 < 0.0f;\n        bool _4657;\n        if (!_4650)\n        {\n            _4657 = _4630 >= 1.0f;\n        }\n        else\n        {\n            _4657 = _4650;\n        }\n        bool _4664;\n        if (!_4657)\n        {\n            _4664 = _4634 < 0.0f;\n        }\n        else\n        {\n            _4664 = _4657;\n        }\n        bool _4671;\n        if (!_4664)\n        {\n            _4671 = _4634 >= 1.0f;\n        }\n        else\n        {\n            _4671 = _4664;\n        }\n        if (_4671)\n        {\n            break;\n        }\n        float4 _4690 = fa_screen_tex.Load(int3(int2(float2(_4630, _4634) * _591_fa_ct_a.zw), 0));\n        if (_4690.w < 0.5f)\n        {\n            continue;\n        }\n        float _4709 = (dot(_591_fa_ct_fwd.xyz, _4593) + _591_fa_ct_fwd.w) - _4690.x;\n        if ((_4709 > _4557) && (_4709 < _4562))\n        {\n            occ = max(occ, (1.0f - (_4585 * _4585)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_4630, 0.5f - _4629), min(_4634, 1.0f - _4634))));\n        }\n    }\n    return 1.0f - (occ * _4543);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _5148 = fa_lm.z > 0.5f;\n    bool _5154;\n    if (_5148)\n    {\n        int param = li;\n        _5154 = fa_light_baked(param);\n    }\n    else\n    {\n        _5154 = _5148;\n    }\n    if (_5154)\n    {\n        int param_1 = li;\n        LightSample _7652 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _7652;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _5178 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _7654 = _5178.color;\n    float _7656 = _5178.shadow;\n    bool _5181 = _5178.type == 0;\n    if (_5181 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _5178.direction;\n        float _5192 = fa_shadow_factor(param_5, param_6);\n        _7656 = _5192;\n        _7654 *= _5192;\n    }\n    else\n    {\n        bool _5203 = _5178.type != 0;\n        bool _5209;\n        if (_5203)\n        {\n            _5209 = _5178.attenuation > 0.0f;\n        }\n        else\n        {\n            _5209 = _5203;\n        }\n        if (_5209)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _5178.direction;\n            float _5228 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _7656 = _5228;\n            _7654 *= _5228;\n        }\n    }\n    bool _5238 = _591_fa_ct_a.x > 0.5f;\n    bool _5244;\n    if (_5238)\n    {\n        _5244 = _5178.attenuation > 0.0f;\n    }\n    else\n    {\n        _5244 = _5238;\n    }\n    if (_5244)\n    {\n        float _5251;\n        if (_5181)\n        {\n            _5251 = 1000000000.0f;\n        }\n        else\n        {\n            _5251 = _5178._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _5178.direction;\n        float param_18 = _5251;\n        float _5269 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _7656 *= _5269;\n        _7654 *= _5269;\n    }\n    LightSample _7671 = { _5178.direction, _7654, _5178.attenuation, _7656, _5178._distance, _5178.type };\n    return _7671;\n}\n\nfloat3 fa_ltc_tangent(float3 n, float3 v)\n{\n    float3 _5312 = v - (n * dot(v, n));\n    float3 t = _5312;\n    float _5316 = dot(_5312, _5312);\n    float l2 = _5316;\n    if (_5316 < 1.0000000133514319600180897396058e-10f)\n    {\n        float3 _5326;\n        if (abs(n.z) < 0.999000012874603271484375f)\n        {\n            _5326 = cross(n, float3(0.0f, 0.0f, 1.0f));\n        }\n        else\n        {\n            _5326 = cross(n, float3(1.0f, 0.0f, 0.0f));\n        }\n        t = _5326;\n        l2 = dot(_5326, _5326);\n    }\n    return t * rsqrt(l2);\n}\n\nfloat3 fa_ltc_local(float3 t1, float3 n, float3 p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nfloat3 fa_ltc_edge_vector(float3 a, float3 b)\n{\n    float _5361 = dot(a, a);\n    float _5365 = dot(b, b);\n    if ((_5361 < 1.0000000195414813782625560981111e-24f) || (_5365 < 1.0000000195414813782625560981111e-24f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _5379 = a * rsqrt(_5361);\n    float3 _5384 = b * rsqrt(_5365);\n    float _5388 = dot(_5379, _5384);\n    float _5391 = abs(_5388);\n    float g = (((((((((((0.0416471660137176513671875f * _5391) - 0.1924748718738555908203125f) * _5391) + 0.4179156124591827392578125f) * _5391) - 0.616057217121124267578125f) * _5391) + 0.777722418308258056640625f) * _5391) - 0.999542415142059326171875f) * _5391) + 1.570791721343994140625f;\n    if (_5388 < 0.0f)\n    {\n        g = (3.1415927410125732421875f * rsqrt(max(1.0f - (_5388 * _5388), 1.0000000116860974230803549289703e-07f))) - g;\n    }\n    return cross(_5379, _5384) * g;\n}\n\nvoid fa_ltc_clip_edge(float3 a, float3 b, inout float3 sum, inout float3 leave, inout float3 enter, inout float2 seen)\n{\n    bool _5448 = a.z > 0.0f;\n    bool _5452 = b.z > 0.0f;\n    if (_5448 && _5452)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_5448 != _5452)\n        {\n            float3 _5487 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _5487.z = 0.0f;\n            if (_5448)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _5487;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _5487;\n                seen.x = 1.0f;\n            }\n            else\n            {\n                float3 param_4 = _5487;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _5487;\n                seen.y = 1.0f;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(float4 abcd, float3 p0, float3 p1, float3 p2, float3 p3)\n{\n    float3 _5536 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _5562 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _5588 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _5614 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = 0.0f.xxx;\n    float3 leave = 0.0f.xxx;\n    float3 enter = 0.0f.xxx;\n    float3 param = _5536;\n    float3 param_1 = _5562;\n    float3 param_2 = 0.0f.xxx;\n    float3 param_3 = 0.0f.xxx;\n    float3 param_4 = 0.0f.xxx;\n    float2 param_5 = 0.0f.xx;\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _5562;\n    float3 param_7 = _5588;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _5588;\n    float3 param_13 = _5614;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _5614;\n    float3 param_19 = _5536;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5f)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875f;\n}\n\nfloat fa_ltc_rect(float4 abcd, float3 center, float3 ex, float3 ey)\n{\n    float4 param = abcd;\n    float3 param_1 = (center - ex) - ey;\n    float3 param_2 = (center + ex) - ey;\n    float3 param_3 = (center + ex) + ey;\n    float3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(float4 m, float shape, float3 pc, float3 ex, float3 ey)\n{\n    if ((shape < 0.5f) || (shape > 1.5f))\n    {\n        float4 param = m;\n        float3 param_1 = pc;\n        float3 param_2 = ex;\n        float3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    float3 _5763 = (pc + (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _5787 = (pc - (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _5803 = (pc - (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float4 param_4 = m;\n    float3 param_5 = _5763;\n    float3 param_6 = (pc + (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_7 = (pc - (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_8 = _5787;\n    float4 param_9 = m;\n    float3 param_10 = _5763;\n    float3 param_11 = _5787;\n    float3 param_12 = (pc - (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    float3 param_13 = _5803;\n    float4 param_14 = m;\n    float3 param_15 = _5763;\n    float3 param_16 = _5803;\n    float3 param_17 = (pc + (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float3 param_18 = (pc + (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nfloat2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((float2(clamp((roughness - 0.0500000007450580596923828125f) * 1.0526316165924072265625f, 0.0f, 1.0f), sqrt(clamp(1.0f - ndv, 0.0f, 1.0f))) * 63.0f) + 0.5f.xx) * 0.015625f.xx;\n}\n\nfloat3 fa_area_shade(int li, float3 world_pos, float3 n, float3 v, float3 diffuse_color, float3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _5861 = fa_light_base(param);\n    int param_1 = _5861;\n    int param_2 = _5861 + 1;\n    int param_3 = _5861 + 2;\n    int param_4 = _5861 + 4;\n    float4 _5883 = fa_light_texel(param_4);\n    int param_5 = _5861 + 5;\n    float4 _5888 = fa_light_texel(param_5);\n    int param_6 = _5861 + 6;\n    float4 _5893 = fa_light_texel(param_6);\n    float _5894 = _5893.w;\n    float3 _5899 = fa_light_texel(param_1).xyz - world_pos;\n    bool _5901 = _5894 < 1.5f;\n    bool _5908;\n    if (_5901)\n    {\n        _5908 = dot(normalize(fa_light_texel(param_3).xyz), _5899) >= 0.0f;\n    }\n    else\n    {\n        _5908 = _5901;\n    }\n    if (_5908)\n    {\n        return 0.0f.xxx;\n    }\n    bool _5917 = (_5894 > 0.5f) && _5901;\n    float _5921 = _5917 ? 1.0539000034332275390625f : 1.0f;\n    float3 _5924 = _5883.xyz;\n    float _5926 = _5883.w;\n    float3 _5932 = _5888.xyz;\n    float _5934 = _5888.w;\n    float3 up = _5932 * (_5934 * _5921);\n    float _5940;\n    if (_5917)\n    {\n        _5940 = (3.1415927410125732421875f * _5926) * _5926;\n    }\n    else\n    {\n        _5940 = (4.0f * _5926) * _5934;\n    }\n    if (_5894 > 1.5f)\n    {\n        float3 _5966 = cross(_5924, -_5899);\n        float3 perp = _5966;\n        float _5970 = dot(_5966, _5966);\n        float3 _5973;\n        if (_5970 > 1.0000000133514319600180897396058e-10f)\n        {\n            _5973 = perp * rsqrt(_5970);\n        }\n        else\n        {\n            _5973 = _5932;\n        }\n        perp = _5973;\n        up = _5973 * _5934;\n    }\n    float _5994 = max(_5940, 9.9999999747524270787835121154785e-07f);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _6004 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _6004;\n    float3 param_10 = n;\n    float3 param_11 = _5899;\n    float3 _6012 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_12 = _6004;\n    float3 param_13 = n;\n    float3 param_14 = _5924 * (_5926 * _5921);\n    float3 _6020 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_15 = _6004;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float3 _6028 = fa_ltc_local(param_15, param_16, param_17);\n    float4 param_18 = float4(1.0f, 0.0f, 0.0f, 1.0f);\n    float param_19 = _5894;\n    float3 param_20 = _6012;\n    float3 param_21 = _6020;\n    float3 param_22 = _6028;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    float2 _6047 = fa_ltc_uv(param_23, param_24) * 64.0f;\n    float2 param_25 = _6047;\n    float2 param_26 = _6047 + float2(64.0f, 0.0f);\n    float4 _6057 = fa_atlas_fetch(param_26);\n    float4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _5894;\n    float3 param_29 = _6012;\n    float3 param_30 = _6020;\n    float3 param_31 = _6028;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _6057.x) + ((f90.xxx - f0) * _6057.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875f * dot(_5899, _5899)) + _5994) / _5994) * window);\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4237 = 1.0f / alpha;\n    return ((2.0f + _4237) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _4237)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat fa_layers_coat(FaLayers L, float3 l, float3 h, float vdh)\n{\n    float _4272 = max(dot(L.nc, l), 0.0f);\n    float _4278 = max(dot(L.nc, h), 0.0f);\n    float _4287 = ((_4278 * _4278) * (L.coat_a2 - 1.0f)) + 1.0f;\n    return (((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _4287) * _4287)) * (0.5f / max(lerp((2.0f * _4272) * L.coat_ndv, _4272 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _4272)) * _4272;\n}\n\nfloat3 fa_area_layers(FaLayers L, int li, float3 world_pos, float3 n, float3 v, float3 l, float3 diffuse_color, float3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    float3 param_2 = n;\n    float3 param_3 = v;\n    float3 param_4 = diffuse_color;\n    float3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _6125;\n    if (L.sheen_on)\n    {\n        _6125 = L.sheen_scale;\n    }\n    else\n    {\n        _6125 = 1.0f;\n    }\n    float3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _6125);\n    float3 _6138 = normalize(l + v);\n    int param_10 = li;\n    float3 _6149 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _6158 = max(dot(n, l), 0.0f);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _6138), 0.0f);\n        float param_13 = _6158;\n        float param_14 = ndv;\n        result += ((L.sheen * _6149) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875f) * step(9.9999997473787516355514526367188e-05f, _6158)) * _6158) * L.keep));\n    }\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_15 = L;\n        float3 param_16 = l;\n        float3 param_17 = _6138;\n        float param_18 = max(dot(v, _6138), 0.0f);\n        result += (_6149 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4140 = tdh / at;\n    float _4144 = bdh / ab;\n    float _4156 = ((_4140 * _4140) + (_4144 * _4144)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _4156) * _4156);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4336 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4415 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _4415) * _4415);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _4336);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _4336));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_17 = L;\n        float3 param_18 = l;\n        float3 param_19 = h;\n        float param_20 = vdh;\n        result += fa_layers_coat(param_17, param_18, param_19, param_20).xxx;\n    }\n    return result;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3546 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3549 = _3546.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3549 * _3549, exp2((-9.27999973297119140625f) * ndv)) * _3549) + _3546.y)) + _3546.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_591_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _591_fa_env_horizon.w).xyz;\n    }\n    float _3400 = rough * rough;\n    float _3430 = 0.60000002384185791015625f * _3400;\n    return lerp(lerp(_591_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_591_fa_env_horizon.xyz, _591_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3400)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3430, 0.0500000007450580596923828125f + _3430, d.y).xxx), ((_591_fa_env_sky.xyz + _591_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3400 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _4023;\n        if (L.aniso >= 0.0f)\n        {\n            _4023 = L.b;\n        }\n        else\n        {\n            _4023 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_4023, v), _4023), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4056 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _4056.x) + (L.f90.xxx * _4056.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _4111 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _4111.x) + _4111.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3588 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3588.x) + _3588.y.xxx);\n}\n\nfloat2 fa_xm_size(int k)\n{\n    return max(floor(_591_fa_ct_a.zw / exp2(float(k)).xx), 1.0f.xx);\n}\n\nfloat2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return 0.0f.xx;\n    }\n    float y = 0.0f;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return float2(_591_fa_ct_a.z, y);\n}\n\nfloat3 fa_xm_texel(float2 size, float2 origin, float2 p)\n{\n    return fa_screen_tex.Load(int3(int2(origin + clamp(p, 0.0f.xx, size - 1.0f.xx)), 0)).xyz;\n}\n\nfloat3 fa_xm_level(int k, float2 uv)\n{\n    int param = k;\n    float2 _4813 = fa_xm_size(param);\n    int param_1 = k;\n    float2 _4817 = fa_xm_origin(param_1);\n    float2 _4823 = (uv * _4813) - 0.5f.xx;\n    float2 _4826 = frac(_4823);\n    float2 _4829 = floor(_4823);\n    float2 param_2 = _4813;\n    float2 param_3 = _4817;\n    float2 param_4 = _4829;\n    float2 param_5 = _4813;\n    float2 param_6 = _4817;\n    float2 param_7 = _4829 + float2(1.0f, 0.0f);\n    float2 param_8 = _4813;\n    float2 param_9 = _4817;\n    float2 param_10 = _4829 + float2(0.0f, 1.0f);\n    float2 param_11 = _4813;\n    float2 param_12 = _4817;\n    float2 param_13 = _4829 + 1.0f.xx;\n    float3 _4871 = _4826.x.xxx;\n    return lerp(lerp(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _4871), lerp(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _4871), _4826.y.xxx);\n}\n\nfloat3 fa_xm_sample(float2 uv, float lod)\n{\n    float _4890 = max(_591_fa_tr_b.w - 1.0f, 0.0f);\n    float _4894 = clamp(lod, 0.0f, _4890);\n    int _4898 = int(floor(_4894));\n    int param = _4898;\n    float2 param_1 = uv;\n    float3 c = fa_xm_level(param, param_1);\n    float _4908 = float(_4898);\n    float _4909 = _4894 - _4908;\n    bool _4911 = _4909 > 0.001000000047497451305389404296875f;\n    bool _4918;\n    if (_4911)\n    {\n        _4918 = _4908 < _4890;\n    }\n    else\n    {\n        _4918 = _4911;\n    }\n    if (_4918)\n    {\n        int param_2 = _4898 + 1;\n        float2 param_3 = uv;\n        c = lerp(c, fa_xm_level(param_2, param_3), _4909.xxx);\n    }\n    return c;\n}\n\nfloat3 fa_transmitted(Surface s, float3 n, float3 v, float roughness, float3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4944 = fa_env_brdf(param, param_1);\n    float3 through = ((1.0f.xxx - clamp((f0 * _4944.x) + (f90.xxx * _4944.y), 0.0f.xxx, 1.0f.xxx)) * s.albedo) * (tr * keep);\n    float _4972 = max(s.thickness, 0.0f);\n    bool _4977 = _4972 > 0.0f;\n    if ((s.attenuation_distance > 0.0f) && _4977)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, 9.9999997473787516355514526367188e-05f.xxx, 1.0f.xxx))) / s.attenuation_distance.xxx)) * _4972);\n    }\n    bool _5002 = _591_fa_tr_a.w > 1.5f;\n    bool _5009;\n    if (!_5002)\n    {\n        _5009 = _591_fa_tr_a.w < 0.5f;\n    }\n    else\n    {\n        _5009 = _5002;\n    }\n    if (_5009)\n    {\n        blend = clamp(dot(through, 0.3333333432674407958984375f.xxx), 0.0f, 0.980000019073486328125f);\n        return 0.0f.xxx;\n    }\n    float3 world = fa_world_pos;\n    if (_4977)\n    {\n        world += (refract(-v, n, 1.0f / max(s.ior, 1.0f)) * _4972);\n    }\n    float4 _5044 = float4(world, 1.0f);\n    float _5049 = dot(_591_fa_ct_vpw, _5044);\n    float2 uv = 0.5f.xx;\n    if (_5049 > 9.9999997473787516355514526367188e-05f)\n    {\n        float2 _5067 = float2(dot(_591_fa_ct_vpx, _5044), dot(_591_fa_ct_vpy, _5044)) / _5049.xx;\n        float _5075;\n        if (_591_fa_ct_a.y > 0.5f)\n        {\n            _5075 = (_5067.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _5075 = 0.5f - (_5067.y * 0.5f);\n        }\n        uv = float2((_5067.x * 0.5f) + 0.5f, _5075);\n    }\n    float2 param_2 = clamp(uv, 0.0f.xx, 1.0f.xx);\n    float param_3 = (clamp(roughness, 0.0f, 1.0f) * clamp((2.0f * s.ior) - 2.0f, 0.0f, 1.0f)) * max(_591_fa_tr_b.w - 1.0f, 0.0f);\n    return through * fa_xm_sample(param_2, param_3);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2258_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3194 = int(_2258_fa_shadow_cfg.x + 0.5f);\n    float _3204 = dot(world - _2258_fa_shadow_eye.xyz, _2258_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3209 = _3194 > 0;\n    bool _3218;\n    if (_3209)\n    {\n        int param = _3194 - 1;\n        _3218 = _3204 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3218 = _3209;\n    }\n    if (_3218)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3224 = _3194 > 1;\n        bool _3231;\n        if (_3224)\n        {\n            _3231 = _3204 > _2258_fa_shadow_split.x;\n        }\n        else\n        {\n            _3231 = _3224;\n        }\n        if (_3231)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3237 = _3194 > 2;\n        bool _3244;\n        if (_3237)\n        {\n            _3244 = _3204 > _2258_fa_shadow_split.y;\n        }\n        else\n        {\n            _3244 = _3237;\n        }\n        if (_3244)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3250 = _3194 > 3;\n        bool _3257;\n        if (_3250)\n        {\n            _3257 = _3204 > _2258_fa_shadow_split.z;\n        }\n        else\n        {\n            _3257 = _3250;\n        }\n        if (_3257)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _7313 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _7313 = -_7313;\n    }\n    float3 _6603 = normalize(_591_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _7326 = { fa_world_pos, _7313, fa_world_tangent, fa_uv, fa_vertex_color, _6603, gl_FrontFacing };\n    SurfaceInput param_1 = _7326;\n    Surface _6611 = fa_standard_surface(param_1);\n    float3 _7344 = _6611.albedo;\n    float _7345 = _6611.alpha;\n    float3 _7346 = _6611.normal;\n    float _7347 = _6611.metallic;\n    float _7348 = _6611.roughness;\n    float _7349 = _6611.occlusion;\n    float3 _7350 = _6611.emission;\n    float _7351 = _6611.clearcoat;\n    float _7352 = _6611.clearcoat_roughness;\n    float3 _7353 = _6611.sheen_color;\n    float _7354 = _6611.sheen_roughness;\n    float _7355 = _6611.anisotropy;\n    float _7356 = _6611.anisotropy_rotation;\n    float _7357 = _6611.specular;\n    float _7358 = _6611.ior;\n    float3 _7359 = _6611.specular_color;\n    float _7360 = _6611.transmission;\n    float _7361 = _6611.thickness;\n    float3 _7362 = _6611.attenuation_color;\n    float _7363 = _6611.attenuation_distance;\n    SurfaceInput _7334 = { fa_world_pos, _7313, fa_world_tangent, fa_uv, fa_vertex_color, _6603, gl_FrontFacing };\n    SurfaceInput param_2 = _7334;\n    Surface param_3 = _6611;\n    surface(param_2, param_3);\n    _7344 = param_3.albedo;\n    _7345 = param_3.alpha;\n    _7346 = param_3.normal;\n    _7347 = param_3.metallic;\n    _7348 = param_3.roughness;\n    _7349 = param_3.occlusion;\n    _7350 = param_3.emission;\n    _7351 = param_3.clearcoat;\n    _7352 = param_3.clearcoat_roughness;\n    _7353 = param_3.sheen_color;\n    _7354 = param_3.sheen_roughness;\n    _7355 = param_3.anisotropy;\n    _7356 = param_3.anisotropy_rotation;\n    _7357 = param_3.specular;\n    _7358 = param_3.ior;\n    _7359 = param_3.specular_color;\n    _7360 = param_3.transmission;\n    _7361 = param_3.thickness;\n    _7362 = param_3.attenuation_color;\n    _7363 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _7313;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _7344 = param_6;\n    _7346 = param_7;\n    float fa_tr_blend = 0.0f;\n    float3 result;\n    if (_591_fa_emissive.w > 0.5f)\n    {\n        result = _7344;\n    }\n    else\n    {\n        float3 _6651 = normalize(_7346);\n        float _6658 = clamp(_7347, 0.0f, 1.0f);\n        float _6662 = clamp(_7348, 0.0500000007450580596923828125f, 1.0f);\n        float _6666 = _6662 * _6662;\n        float _6670 = _6666 * _6666;\n        float _6675 = max(dot(_6651, _6603), 9.9999997473787516355514526367188e-05f);\n        float _6681 = 1.0f - _6658;\n        float _6682 = clamp(_7360, 0.0f, 1.0f) * _6681;\n        float3 _6691 = (_7344 * _6681) * (1.0f - _6682);\n        float3 _6698 = lerp(0.039999999105930328369140625f.xxx, _7344, _6658.xxx);\n        float3 f0 = _6698;\n        SurfaceInput _7342 = { fa_world_pos, _7313, fa_world_tangent, fa_uv, fa_vertex_color, _6603, gl_FrontFacing };\n        SurfaceInput param_8 = _7342;\n        Surface _7445 = { _7344, _7345, _7346, _7347, _7348, _7349, _7350, _7351, _7352, _7353, _7354, _7355, _7356, _7357, _7358, _7359, _7360, _7361, _7362, _7363 };\n        Surface param_9 = _7445;\n        float3 param_10 = _6651;\n        float3 param_11 = _6603;\n        float param_12 = _6658;\n        float param_13 = _6662;\n        float3 param_14 = _6698;\n        FaLayers _6714 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _6651;\n        float3 lit = (fa_indirect_diffuse(param_15) * _6691) * _7349;\n        if (_6714.on)\n        {\n            lit *= _6714.base_scale;\n        }\n        int _6736 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6736; ln++)\n        {\n            int param_16 = ln;\n            int _6749 = fa_cl_light(param_16);\n            bool _6752 = fa_lm.z > 0.5f;\n            bool _6758;\n            if (_6752)\n            {\n                int param_17 = _6749;\n                _6758 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _6758 = _6752;\n            }\n            if (_6758)\n            {\n                continue;\n            }\n            int param_18 = _6749;\n            float3 param_19 = fa_world_pos;\n            float3 param_20 = _7313;\n            LightSample _6770 = fa_light_shadowed(param_18, param_19, param_20);\n            float _6778 = max(dot(_6651, _6770.direction), 0.0f);\n            float _6784 = _6770.attenuation * _6770.shadow;\n            float3 _6789 = normalize(_6770.direction + _6603);\n            float _6794 = max(dot(_6651, _6789), 0.0f);\n            float _6799 = max(dot(_6603, _6789), 0.0f);\n            bool _6806;\n            if (fa_light_is_area)\n            {\n                _6806 = !_6714.on;\n            }\n            else\n            {\n                _6806 = fa_light_is_area;\n            }\n            if (_6806)\n            {\n                int param_21 = _6749;\n                float3 param_22 = fa_world_pos;\n                float3 param_23 = _6651;\n                float3 param_24 = _6603;\n                float3 param_25 = _6691;\n                float3 param_26 = f0;\n                float param_27 = 1.0f;\n                float param_28 = _6662;\n                float param_29 = _6675;\n                float param_30 = _6784;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _6714;\n                    int param_32 = _6749;\n                    float3 param_33 = fa_world_pos;\n                    float3 param_34 = _6651;\n                    float3 param_35 = _6603;\n                    float3 param_36 = _6770.direction;\n                    float3 param_37 = _6691;\n                    float3 param_38 = f0;\n                    float param_39 = _6662;\n                    float param_40 = _6675;\n                    float param_41 = _6784;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_6714.on)\n                    {\n                        FaLayers param_42 = _6714;\n                        float3 param_43 = _6691;\n                        float3 param_44 = f0;\n                        float3 param_45 = _6651;\n                        float3 param_46 = _6603;\n                        float3 param_47 = _6770.direction;\n                        float3 param_48 = _6789;\n                        float param_49 = _6778;\n                        float param_50 = _6675;\n                        float param_51 = _6794;\n                        float param_52 = _6799;\n                        float param_53 = _6666;\n                        float param_54 = _6670;\n                        int param_55 = _6749;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _6784));\n                    }\n                    else\n                    {\n                        float _6912 = ((_6794 * _6794) * (_6670 - 1.0f)) + 1.0f;\n                        int param_56 = _6749;\n                        lit += (((_6691 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _6799, 5.0f))) * (((_6670 / ((3.1415927410125732421875f * _6912) * _6912)) * (0.5f / max(lerp((2.0f * _6778) * _6675, _6778 + _6675, _6666), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _6778))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_6778 * _6784));\n                    }\n                }\n            }\n        }\n        if (_6714.on)\n        {\n            FaLayers param_57 = _6714;\n            float3 param_58 = _6651;\n            float3 param_59 = _6603;\n            float3 param_60 = f0;\n            float param_61 = _6662;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _7349);\n        }\n        else\n        {\n            float3 param_62 = _6651;\n            float3 param_63 = _6603;\n            float3 param_64 = f0;\n            float param_65 = _6662;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _7349);\n        }\n        if (_6682 > 0.0f)\n        {\n            float _7010;\n            if (_6714.on)\n            {\n                _7010 = _6714.f90;\n            }\n            else\n            {\n                _7010 = 1.0f;\n            }\n            float _7018;\n            if (_6714.on)\n            {\n                _7018 = _6714.base_scale;\n            }\n            else\n            {\n                _7018 = 1.0f;\n            }\n            Surface _7466 = { _7344, _7345, _7346, _7347, _7348, _7349, _7350, _7351, _7352, _7353, _7354, _7355, _7356, _7357, _7358, _7359, _7360, _7361, _7362, _7363 };\n            Surface param_66 = _7466;\n            float3 param_67 = _6651;\n            float3 param_68 = _6603;\n            float param_69 = _6662;\n            float3 param_70 = f0;\n            float param_71 = _7010;\n            float param_72 = _7018;\n            float param_73 = _6682;\n            float param_74 = fa_tr_blend;\n            float3 _7042 = fa_transmitted(param_66, param_67, param_68, param_69, param_70, param_71, param_72, param_73, param_74);\n            fa_tr_blend = param_74;\n            lit += _7042;\n        }\n        result = lit;\n    }\n    float3 _7049 = result;\n    float3 _7050 = _7049 + _7350;\n    result = _7050;\n    float3 param_75 = _7050;\n    float3 param_76 = fa_world_pos;\n    result = fa_shadow_debug(param_75, param_76);\n    bool _7059 = _591_fa_fog.w > 0.0f;\n    bool _7066;\n    if (!_7059)\n    {\n        _7066 = _591_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _7066 = _7059;\n    }\n    if (_7066)\n    {\n        float3 _7075 = fa_world_pos - _591_fa_camera_pos.xyz;\n        float _7081 = dot(_7075, _591_fa_fog_c.xyz);\n        bool _7085 = _591_fa_fog_c.w > 0.5f;\n        float _7086;\n        if (_7085)\n        {\n            _7086 = _7081;\n        }\n        else\n        {\n            _7086 = length(_7075);\n        }\n        float _7098 = _7086 - _591_fa_fog_b.x;\n        if (_7098 > 0.0f)\n        {\n            float _7107 = _591_fa_fog.w * _7098;\n            float tau = _7107 * _7107;\n            if (_591_fa_fog_b.y > 0.0f)\n            {\n                float _7123;\n                if (_7085)\n                {\n                    _7123 = fa_world_pos.y - (_591_fa_fog_c.y * _7081);\n                }\n                else\n                {\n                    _7123 = _591_fa_camera_pos.y;\n                }\n                float _7144 = lerp(_7123, fa_world_pos.y, clamp(_591_fa_fog_b.x / _7086, 0.0f, 1.0f));\n                float _7148 = fa_world_pos.y - _7144;\n                float _7153 = _7144 - _591_fa_fog_b.z;\n                float _7158 = fa_world_pos.y - _591_fa_fog_b.z;\n                bool _7161 = _7153 <= 0.0f;\n                bool _7162 = !_7161;\n                bool _7168;\n                if (_7162)\n                {\n                    _7168 = _591_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _7168 = _7161;\n                }\n                float _7169;\n                if (_7168)\n                {\n                    _7169 = _591_fa_fog_b.y;\n                }\n                else\n                {\n                    _7169 = _591_fa_fog_b.y * exp(-min(_591_fa_fog_b.w * _7153, 80.0f));\n                }\n                bool _7196;\n                if (_7162)\n                {\n                    _7196 = _591_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _7196 = _7161;\n                }\n                float _7197;\n                if (_7196)\n                {\n                    _7197 = _591_fa_fog_b.y * _7153;\n                }\n                else\n                {\n                    _7197 = (_591_fa_fog_b.y * (1.0f - exp(-min(_591_fa_fog_b.w * _7153, 80.0f)))) / _591_fa_fog_b.w;\n                }\n                bool _7222 = _7158 <= 0.0f;\n                bool _7229;\n                if (!_7222)\n                {\n                    _7229 = _591_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _7229 = _7222;\n                }\n                float _7230;\n                if (_7229)\n                {\n                    _7230 = _591_fa_fog_b.y * _7158;\n                }\n                else\n                {\n                    _7230 = (_591_fa_fog_b.y * (1.0f - exp(-min(_591_fa_fog_b.w * _7158, 80.0f)))) / _591_fa_fog_b.w;\n                }\n                float _7257;\n                if (abs(_7148) < 0.001000000047497451305389404296875f)\n                {\n                    _7257 = _7169;\n                }\n                else\n                {\n                    _7257 = (_7230 - _7197) / _7148;\n                }\n                tau += (_7098 * max(_7257, 0.0f));\n            }\n            result = lerp(result, _591_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    if (fa_tr_blend > 0.0f)\n    {\n        float _7293 = 1.0f - fa_tr_blend;\n        result /= _7293.xxx;\n        _7345 *= _7293;\n    }\n    fa_frag_color = float4(result, _7345);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
          },
          {
            "slot": 11,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 11
          },
          {
            "slot": 12,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 12
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_149",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_195",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 512,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_591",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2258",
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
          },
          {
            "texture": {
              "slot": 28,
              "stage": "fragment",
              "name": "fa_screen_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
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
          },
          {
            "slot": 11,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _144_fa_view_proj : packoffset(c0);\n    row_major float4x4 _144_fa_light_vp : packoffset(c4);\n    float4 _144_fa_uv_scale : packoffset(c8);\n    float4 _144_fa_time : packoffset(c9);\n    float4 _144_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float2 fa_attr_uv1;\nstatic float4 fa_attr_color1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float2 fa_attr_uv1 : TEXCOORD9;\n    float4 fa_attr_color1 : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4 vertex_color1;\nstatic float2 vertex_uv1;\n\nvoid fa_inst_begin()\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _83 = cross(model[1].xyz, model[2].xyz);\n    float _89 = (dot(model[0].xyz, _83) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _312 = { mul(float4(position, 1.0f), model).xyz, (((_83 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _89, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _89), texcoord0 * _144_fa_uv_scale.xy, color, position };\n    return _312;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.color = vertex_color1;\n    v.uv = vertex_uv1;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _187 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -mul(_187, _144_fa_light_vp).z;\n    fa_pre_r0 = float3(_144_fa_light_vp[0].x, _144_fa_light_vp[1].x, _144_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_144_fa_light_vp[0].y, _144_fa_light_vp[1].y, _144_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_144_fa_light_vp[0].z, _144_fa_light_vp[1].z, _144_fa_light_vp[2].z);\n    gl_Position = mul(_187, _144_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_attr_uv1 = stage_input.fa_attr_uv1;\n    fa_attr_color1 = stage_input.fa_attr_color1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _226_fa_camera_pos : packoffset(c0);\n    float4 _226_fa_ambient : packoffset(c1);\n    float4 _226_fa_base_color : packoffset(c2);\n    float4 _226_fa_emissive : packoffset(c3);\n    float4 _226_fa_model_emissive : packoffset(c4);\n    float4 _226_fa_pbr : packoffset(c5);\n    float4 _226_fa_maps : packoffset(c6);\n    float4 _226_fa_fog : packoffset(c7);\n    float4 _226_fa_fog_b : packoffset(c8);\n    float4 _226_fa_fog_c : packoffset(c9);\n    float4 _226_fa_counts : packoffset(c10);\n    float4 _226_fa_env_sky : packoffset(c11);\n    float4 _226_fa_env_horizon : packoffset(c12);\n    float4 _226_fa_time : packoffset(c13);\n    float4 _226_fa_cl_vpx : packoffset(c14);\n    float4 _226_fa_cl_vpy : packoffset(c15);\n    float4 _226_fa_cl_vpw : packoffset(c16);\n    float4 _226_fa_cl_fwd : packoffset(c17);\n    float4 _226_fa_cl_grid : packoffset(c18);\n    float4 _226_fa_cl_info : packoffset(c19);\n    float4 _226_fa_layers_a : packoffset(c20);\n    float4 _226_fa_layers_b : packoffset(c21);\n    float4 _226_fa_layers_c : packoffset(c22);\n    float4 _226_fa_layers_d : packoffset(c23);\n    float4 _226_fa_ct_a : packoffset(c24);\n    float4 _226_fa_ct_b : packoffset(c25);\n    float4 _226_fa_ct_vpx : packoffset(c26);\n    float4 _226_fa_ct_vpy : packoffset(c27);\n    float4 _226_fa_ct_vpw : packoffset(c28);\n    float4 _226_fa_ct_fwd : packoffset(c29);\n    float4 _226_fa_tr_a : packoffset(c30);\n    float4 _226_fa_tr_b : packoffset(c31);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _186 = fa_linear_to_srgb(param);\n        c = _186;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _195 = fa_srgb_to_linear(param_1);\n            c = _195;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _226_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _238 = fa_tex_fix(param_2, param_3);\n    float4 _789 = base_t;\n    _789.x = _238.x;\n    _789.y = _238.y;\n    _789.z = _238.z;\n    base_t = _789;\n    float4 _253 = (_789 * _226_fa_base_color) * i.vertex_color;\n    float3 _744 = i.world_normal;\n    if (_226_fa_maps.z > 0.5f)\n    {\n        float param_4 = _226_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _287 = fa_tex_fix(param_6, param_7);\n        float3 _290 = (_287 * 2.0f) - 1.0f.xxx;\n        float2 _295 = _290.xy * _226_fa_maps.x;\n        float3 _797 = _290;\n        _797.x = _295.x;\n        _797.y = _295.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _797;\n        _744 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _226_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _324 = fa_tex_fix(param_12, param_13);\n    float4 _800 = mrt;\n    _800.x = _324.x;\n    _800.y = _324.y;\n    _800.z = _324.z;\n    mrt = _800;\n    float4 _354 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _226_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = _226_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _396 = fa_tex_fix(param_20, param_21);\n    float _749 = _226_fa_layers_a.x;\n    float _750 = _226_fa_layers_a.y;\n    float _753 = _226_fa_layers_a.z;\n    float _752 = _226_fa_layers_b.w;\n    float _755 = _226_fa_layers_c.x;\n    if (_226_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_226_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _749 *= _366.y;\n            _750 *= _366.z;\n            _752 *= _354.w;\n        }\n        if (_226_fa_layers_c.z > 1.5f)\n        {\n            _753 *= mrt.x;\n            _755 *= mrt.w;\n        }\n    }\n    Surface _782 = { _253.xyz, _253.w, _744, clamp(_226_fa_pbr.x * _324.z, 0.0f, 1.0f), clamp(_226_fa_pbr.y * _324.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_226_fa_maps.y * (_366.x - 1.0f)), _226_fa_emissive.xyz + (_226_fa_model_emissive.xyz * _396), _749, _750, _226_fa_layers_b.xyz, _752, _753, _226_fa_layers_a.w, _755, _226_fa_layers_c.y, _226_fa_layers_d.xyz, _226_fa_tr_a.x, _226_fa_tr_a.y, _226_fa_tr_b.xyz, _226_fa_tr_a.z };\n    return _782;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * (i.uv.x * 2.0f));\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _639 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _639 = -_639;\n    }\n    float3 _549 = normalize(_226_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _652 = { fa_world_pos, _639, fa_world_tangent, fa_uv, fa_vertex_color, _549, gl_FrontFacing };\n    SurfaceInput param = _652;\n    SurfaceInput _660 = { fa_world_pos, _639, fa_world_tangent, fa_uv, fa_vertex_color, _549, gl_FrontFacing };\n    SurfaceInput param_1 = _660;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _564 = normalize(param_2.normal);\n    float3 _579 = normalize(float3(dot(fa_pre_r0, _564), dot(fa_pre_r1, _564), dot(fa_pre_r2, _564)));\n    float _591 = _579.z;\n    float2 e = _579.xy / ((abs(_579.x) + abs(_579.y)) + abs(_591)).xx;\n    if (_591 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "type": "vec2",
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
            "inst_name": "_144",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 512,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_226",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _149_fa_view_proj : packoffset(c0);\n    row_major float4x4 _149_fa_light_vp : packoffset(c4);\n    float4 _149_fa_uv_scale : packoffset(c8);\n    float4 _149_fa_time : packoffset(c9);\n    float4 _149_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _195_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float2 fa_attr_uv1;\nstatic float4 fa_attr_color1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n    float2 fa_attr_uv1 : TEXCOORD11;\n    float4 fa_attr_color1 : TEXCOORD12;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4 vertex_color1;\nstatic float2 vertex_uv1;\n\nvoid fa_inst_begin()\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _186 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_195_fa_joint_rows[_186] * weights[i]);\n        r1 += (_195_fa_joint_rows[_186 + 1] * weights[i]);\n        r2 += (_195_fa_joint_rows[_186 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _88 = cross(model[1].xyz, model[2].xyz);\n    float _94 = (dot(model[0].xyz, _88) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _433 = { mul(float4(position, 1.0f), model).xyz, (((_88 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _94, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _94), texcoord0 * _149_fa_uv_scale.xy, color, position };\n    return _433;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.color = vertex_color1;\n    v.uv = vertex_uv1;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _300 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -mul(_300, _149_fa_light_vp).z;\n    fa_pre_r0 = float3(_149_fa_light_vp[0].x, _149_fa_light_vp[1].x, _149_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_149_fa_light_vp[0].y, _149_fa_light_vp[1].y, _149_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_149_fa_light_vp[0].z, _149_fa_light_vp[1].z, _149_fa_light_vp[2].z);\n    gl_Position = mul(_300, _149_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_attr_uv1 = stage_input.fa_attr_uv1;\n    fa_attr_color1 = stage_input.fa_attr_color1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _226_fa_camera_pos : packoffset(c0);\n    float4 _226_fa_ambient : packoffset(c1);\n    float4 _226_fa_base_color : packoffset(c2);\n    float4 _226_fa_emissive : packoffset(c3);\n    float4 _226_fa_model_emissive : packoffset(c4);\n    float4 _226_fa_pbr : packoffset(c5);\n    float4 _226_fa_maps : packoffset(c6);\n    float4 _226_fa_fog : packoffset(c7);\n    float4 _226_fa_fog_b : packoffset(c8);\n    float4 _226_fa_fog_c : packoffset(c9);\n    float4 _226_fa_counts : packoffset(c10);\n    float4 _226_fa_env_sky : packoffset(c11);\n    float4 _226_fa_env_horizon : packoffset(c12);\n    float4 _226_fa_time : packoffset(c13);\n    float4 _226_fa_cl_vpx : packoffset(c14);\n    float4 _226_fa_cl_vpy : packoffset(c15);\n    float4 _226_fa_cl_vpw : packoffset(c16);\n    float4 _226_fa_cl_fwd : packoffset(c17);\n    float4 _226_fa_cl_grid : packoffset(c18);\n    float4 _226_fa_cl_info : packoffset(c19);\n    float4 _226_fa_layers_a : packoffset(c20);\n    float4 _226_fa_layers_b : packoffset(c21);\n    float4 _226_fa_layers_c : packoffset(c22);\n    float4 _226_fa_layers_d : packoffset(c23);\n    float4 _226_fa_ct_a : packoffset(c24);\n    float4 _226_fa_ct_b : packoffset(c25);\n    float4 _226_fa_ct_vpx : packoffset(c26);\n    float4 _226_fa_ct_vpy : packoffset(c27);\n    float4 _226_fa_ct_vpw : packoffset(c28);\n    float4 _226_fa_ct_fwd : packoffset(c29);\n    float4 _226_fa_tr_a : packoffset(c30);\n    float4 _226_fa_tr_b : packoffset(c31);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _186 = fa_linear_to_srgb(param);\n        c = _186;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _195 = fa_srgb_to_linear(param_1);\n            c = _195;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _226_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _238 = fa_tex_fix(param_2, param_3);\n    float4 _789 = base_t;\n    _789.x = _238.x;\n    _789.y = _238.y;\n    _789.z = _238.z;\n    base_t = _789;\n    float4 _253 = (_789 * _226_fa_base_color) * i.vertex_color;\n    float3 _744 = i.world_normal;\n    if (_226_fa_maps.z > 0.5f)\n    {\n        float param_4 = _226_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _287 = fa_tex_fix(param_6, param_7);\n        float3 _290 = (_287 * 2.0f) - 1.0f.xxx;\n        float2 _295 = _290.xy * _226_fa_maps.x;\n        float3 _797 = _290;\n        _797.x = _295.x;\n        _797.y = _295.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _797;\n        _744 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _226_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _324 = fa_tex_fix(param_12, param_13);\n    float4 _800 = mrt;\n    _800.x = _324.x;\n    _800.y = _324.y;\n    _800.z = _324.z;\n    mrt = _800;\n    float4 _354 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _226_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = _226_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _396 = fa_tex_fix(param_20, param_21);\n    float _749 = _226_fa_layers_a.x;\n    float _750 = _226_fa_layers_a.y;\n    float _753 = _226_fa_layers_a.z;\n    float _752 = _226_fa_layers_b.w;\n    float _755 = _226_fa_layers_c.x;\n    if (_226_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_226_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _749 *= _366.y;\n            _750 *= _366.z;\n            _752 *= _354.w;\n        }\n        if (_226_fa_layers_c.z > 1.5f)\n        {\n            _753 *= mrt.x;\n            _755 *= mrt.w;\n        }\n    }\n    Surface _782 = { _253.xyz, _253.w, _744, clamp(_226_fa_pbr.x * _324.z, 0.0f, 1.0f), clamp(_226_fa_pbr.y * _324.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_226_fa_maps.y * (_366.x - 1.0f)), _226_fa_emissive.xyz + (_226_fa_model_emissive.xyz * _396), _749, _750, _226_fa_layers_b.xyz, _752, _753, _226_fa_layers_a.w, _755, _226_fa_layers_c.y, _226_fa_layers_d.xyz, _226_fa_tr_a.x, _226_fa_tr_a.y, _226_fa_tr_b.xyz, _226_fa_tr_a.z };\n    return _782;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * (i.uv.x * 2.0f));\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _639 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _639 = -_639;\n    }\n    float3 _549 = normalize(_226_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _652 = { fa_world_pos, _639, fa_world_tangent, fa_uv, fa_vertex_color, _549, gl_FrontFacing };\n    SurfaceInput param = _652;\n    SurfaceInput _660 = { fa_world_pos, _639, fa_world_tangent, fa_uv, fa_vertex_color, _549, gl_FrontFacing };\n    SurfaceInput param_1 = _660;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _564 = normalize(param_2.normal);\n    float3 _579 = normalize(float3(dot(fa_pre_r0, _564), dot(fa_pre_r1, _564), dot(fa_pre_r2, _564)));\n    float _591 = _579.z;\n    float2 e = _579.xy / ((abs(_579.x) + abs(_579.y)) + abs(_591)).xx;\n    if (_591 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
          },
          {
            "slot": 11,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 11
          },
          {
            "slot": 12,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 12
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_149",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_195",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 512,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_226",
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
    "shadow": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _135_fa_view_proj : packoffset(c0);\n    row_major float4x4 _135_fa_light_vp : packoffset(c4);\n    float4 _135_fa_uv_scale : packoffset(c8);\n    float4 _135_fa_time : packoffset(c9);\n    float4 _135_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float2 fa_attr_uv1;\nstatic float4 fa_attr_color1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float3 fa_normal : TEXCOORD5;\n    float2 fa_texcoord0 : TEXCOORD6;\n    float4 fa_tangent : TEXCOORD7;\n    float4 fa_color : TEXCOORD8;\n    float2 fa_attr_uv1 : TEXCOORD9;\n    float4 fa_attr_color1 : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4 vertex_color1;\nstatic float2 vertex_uv1;\n\nvoid fa_inst_begin()\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _264 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _135_fa_uv_scale.xy, color, position };\n    return _264;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.color = vertex_color1;\n    v.uv = vertex_uv1;\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _135_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_attr_uv1 = stage_input.fa_attr_uv1;\n    fa_attr_color1 = stage_input.fa_attr_color1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    return stage_output;\n}\n",
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
          },
          {
            "slot": 9,
            "type": "vec2",
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
            "inst_name": "_135",
            "hlsl_register_b_n": 0
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _140_fa_view_proj : packoffset(c0);\n    row_major float4x4 _140_fa_light_vp : packoffset(c4);\n    float4 _140_fa_uv_scale : packoffset(c8);\n    float4 _140_fa_time : packoffset(c9);\n    float4 _140_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _186_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float2 fa_attr_uv1;\nstatic float4 fa_attr_color1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float4 fa_joints : TEXCOORD5;\n    float4 fa_weights : TEXCOORD6;\n    float3 fa_normal : TEXCOORD7;\n    float2 fa_texcoord0 : TEXCOORD8;\n    float4 fa_tangent : TEXCOORD9;\n    float4 fa_color : TEXCOORD10;\n    float2 fa_attr_uv1 : TEXCOORD11;\n    float4 fa_attr_color1 : TEXCOORD12;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4 vertex_color1;\nstatic float2 vertex_uv1;\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _177 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_186_fa_joint_rows[_177] * weights[i]);\n        r1 += (_186_fa_joint_rows[_177 + 1] * weights[i]);\n        r2 += (_186_fa_joint_rows[_177 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nvoid fa_inst_begin()\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _79 = cross(model[1].xyz, model[2].xyz);\n    float _85 = (dot(model[0].xyz, _79) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _385 = { mul(float4(position, 1.0f), model).xyz, (((_79 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _85, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _85), texcoord0 * _140_fa_uv_scale.xy, color, position };\n    return _385;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.color = vertex_color1;\n    v.uv = vertex_uv1;\n}\n\nvoid vert_main()\n{\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    fa_inst_begin();\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    vertex(param_8);\n    gl_Position = mul(float4(param_8.world_pos, 1.0f), _140_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_attr_uv1 = stage_input.fa_attr_uv1;\n    fa_attr_color1 = stage_input.fa_attr_color1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    return stage_output;\n}\n",
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
          },
          {
            "slot": 11,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 11
          },
          {
            "slot": 12,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 12
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_140",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_186",
            "hlsl_register_b_n": 3
          }
        ]
      }
    }
  }
}
