{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "5f457c7d0bc8edbcdea422ba00c093c613745eefd8db6d8c8f93fc5e235db1e8",
  "slang": "hlsl5",
  "params": [
    "offset"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_material_vs : register(b4)\n{\n    float3 _45_offset : packoffset(c0);\n    float _45_fa_pad0 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _145_fa_view_proj : packoffset(c0);\n    row_major float4x4 _145_fa_light_vp : packoffset(c4);\n    float4 _145_fa_uv_scale : packoffset(c8);\n    float4 _145_fa_time : packoffset(c9);\n    float4 _145_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _83 = cross(model[1].xyz, model[2].xyz);\n    float _89 = (dot(model[0].xyz, _83) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _278 = { mul(float4(position, 1.0f), model).xyz, (((_83 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _89, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _89), texcoord0 * _145_fa_uv_scale.xy, color, position };\n    return _278;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos += _45_offset;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _145_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _3645[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _548_fa_camera_pos : packoffset(c0);\n    float4 _548_fa_ambient : packoffset(c1);\n    float4 _548_fa_base_color : packoffset(c2);\n    float4 _548_fa_emissive : packoffset(c3);\n    float4 _548_fa_model_emissive : packoffset(c4);\n    float4 _548_fa_pbr : packoffset(c5);\n    float4 _548_fa_maps : packoffset(c6);\n    float4 _548_fa_fog : packoffset(c7);\n    float4 _548_fa_fog_b : packoffset(c8);\n    float4 _548_fa_fog_c : packoffset(c9);\n    float4 _548_fa_counts : packoffset(c10);\n    float4 _548_fa_env_sky : packoffset(c11);\n    float4 _548_fa_env_horizon : packoffset(c12);\n    float4 _548_fa_time : packoffset(c13);\n    float4 _548_fa_cl_vpx : packoffset(c14);\n    float4 _548_fa_cl_vpy : packoffset(c15);\n    float4 _548_fa_cl_vpw : packoffset(c16);\n    float4 _548_fa_cl_fwd : packoffset(c17);\n    float4 _548_fa_cl_grid : packoffset(c18);\n    float4 _548_fa_cl_info : packoffset(c19);\n    float4 _548_fa_layers_a : packoffset(c20);\n    float4 _548_fa_layers_b : packoffset(c21);\n    float4 _548_fa_layers_c : packoffset(c22);\n    float4 _548_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2215_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2215_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2215_fa_shadow_info[4] : packoffset(c20);\n    float4 _2215_fa_shadow_split : packoffset(c24);\n    float4 _2215_fa_shadow_cfg : packoffset(c25);\n    float4 _2215_fa_shadow_bias : packoffset(c26);\n    float4 _2215_fa_shadow_eye : packoffset(c27);\n    float4 _2215_fa_shadow_fwd : packoffset(c28);\n    float4 _2215_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1486 = _548_fa_cl_info.x < 0.0f;\n    bool _1493;\n    if (!_1486)\n    {\n        _1493 = _548_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1493 = _1486;\n    }\n    bool _1501;\n    if (!_1493)\n    {\n        _1501 = _548_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1501 = _1493;\n    }\n    bool _1508;\n    if (!_1501)\n    {\n        _1508 = _548_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1508 = _1501;\n    }\n    bool _1515;\n    if (!_1508)\n    {\n        _1515 = _548_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1515 = _1508;\n    }\n    if (_1515)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1525 = float4(world_pos, 1.0f);\n    float _1531 = dot(_548_fa_cl_vpw, _1525);\n    if (!(_1531 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1553 = float2(dot(_548_fa_cl_vpx, _1525), dot(_548_fa_cl_vpy, _1525)) / _1531.xx;\n    int _1557 = int(_548_fa_cl_grid.x);\n    int _1561 = int(_548_fa_cl_grid.y);\n    int param = (int(_548_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_548_fa_cl_fwd.xyz, world_pos) + _548_fa_cl_fwd.w, _548_fa_cl_grid.w) / _548_fa_cl_grid.w) * _548_fa_cl_grid.z)), 0, int(_548_fa_cl_info.y) - 1) * _1561) + clamp(int(floor(((_1553.y * 0.5f) + 0.5f) * _548_fa_cl_grid.y)), 0, _1561 - 1)) * _1557)) + clamp(int(floor(((_1553.x * 0.5f) + 0.5f) * _548_fa_cl_grid.x)), 0, _1557 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1637 = fa_cluster_texel(param);\n    return int2(int(_1637.x), int(_1637.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_548_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4464 = fa_cluster_lookup(param);\n    fa_cl_slot = _4464.x;\n    fa_cl_local = _4464.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _5549 = fa_linear_to_srgb(param);\n        c = _5549;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _5557 = fa_srgb_to_linear(param_1);\n            c = _5557;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _431;\n    if (i.front_facing)\n    {\n        _431 = i.world_normal;\n    }\n    else\n    {\n        _431 = -i.world_normal;\n    }\n    float3 _455 = normalize(i.world_tangent.xyz - (_431 * dot(_431, i.world_tangent.xyz)));\n    float3 _482 = normalize(((_455 * m.x) + ((cross(_431, _455) * i.world_tangent.w) * m.y)) + (_431 * m.z));\n    float3 _485;\n    if (i.front_facing)\n    {\n        _485 = _482;\n    }\n    else\n    {\n        _485 = -_482;\n    }\n    return _485;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _548_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _5588 = fa_tex_fix(param_2, param_3);\n    float4 _7006 = base_t;\n    _7006.x = _5588.x;\n    _7006.y = _5588.y;\n    _7006.z = _5588.z;\n    base_t = _7006;\n    float4 _5602 = (_7006 * _548_fa_base_color) * i.vertex_color;\n    float3 _6844 = i.world_normal;\n    if (_548_fa_maps.z > 0.5f)\n    {\n        float param_4 = _548_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _5634 = fa_tex_fix(param_6, param_7);\n        float3 _5637 = (_5634 * 2.0f) - 1.0f.xxx;\n        float2 _5642 = _5637.xy * _548_fa_maps.x;\n        float3 _7014 = _5637;\n        _7014.x = _5642.x;\n        _7014.y = _5642.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _7014;\n        _6844 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _548_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _5670 = fa_tex_fix(param_12, param_13);\n    float4 _7017 = mrt;\n    _7017.x = _5670.x;\n    _7017.y = _5670.y;\n    _7017.z = _5670.z;\n    mrt = _7017;\n    float4 _5698 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _548_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _5698.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _5709 = fa_tex_fix(param_16, param_17);\n    float param_18 = _548_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _5739 = fa_tex_fix(param_20, param_21);\n    float _6849 = _548_fa_layers_a.x;\n    float _6850 = _548_fa_layers_a.y;\n    float _6853 = _548_fa_layers_a.z;\n    float _6852 = _548_fa_layers_b.w;\n    float _6855 = _548_fa_layers_c.x;\n    if (_548_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_548_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _6849 *= _5709.y;\n            _6850 *= _5709.z;\n            _6852 *= _5698.w;\n        }\n        if (_548_fa_layers_c.z > 1.5f)\n        {\n            _6853 *= mrt.x;\n            _6855 *= mrt.w;\n        }\n    }\n    Surface _6874 = { _5602.xyz, _5602.w, _6844, clamp(_548_fa_pbr.x * _5670.z, 0.0f, 1.0f), clamp(_548_fa_pbr.y * _5670.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_548_fa_maps.y * (_5709.x - 1.0f)), _548_fa_emissive.xyz + (_548_fa_model_emissive.xyz * _5739), _6849, _6850, _548_fa_layers_b.xyz, _6852, _6853, _548_fa_layers_a.w, _6855, _548_fa_layers_c.y, _548_fa_layers_d.xyz };\n    return _6874;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1717 = rect.zw - rect.xy;\n    float2 _1721 = _1717 * atlas;\n    float2 _1725 = ddx * _1721;\n    float2 _1729 = ddy * _1721;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1717), clamp(0.5f * log2(max(max(dot(_1725, _1725), dot(_1729, _1729)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1762 = _548_fa_counts.y < 0.5f;\n    bool _1769;\n    if (!_1762)\n    {\n        _1769 = _548_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1769 = _1762;\n    }\n    if (_1769)\n    {\n        return;\n    }\n    float3 _1775 = ddx(world_pos);\n    float3 _1778 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1782 = fa_cluster_texel(param);\n    int _1786 = int(_1782.w);\n    if (_1786 < 1)\n    {\n        return;\n    }\n    int _1796 = int(_548_fa_counts.y + 0.5f);\n    int param_1 = _1796;\n    float4 _1800 = fa_light_texel(param_1);\n    float2 _1803 = _1800.yz;\n    int _1807 = int(_1800.w);\n    int param_2 = _1796 + 1;\n    float4 _1812 = fa_light_texel(param_2);\n    float _1813 = _1812.x;\n    int _1819 = int(_548_fa_counts.w + 0.5f) - 1;\n    int _1823 = int(_1782.z);\n    float3 _2088;\n    for (int k = 0; k < _1786; k++)\n    {\n        int _1836 = _1823 + k;\n        int param_3 = _1807 + (_1836 >> 2);\n        int _1853 = (_1796 + 2) + (int(fa_light_texel(param_3)[_1836 & 3]) * 7);\n        int param_4 = _1853 + 6;\n        float4 _1858 = fa_light_texel(param_4);\n        if (((int(_1858.w + 0.5f) >> _1819) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1853;\n        float4 _1873 = fa_light_texel(param_5);\n        int param_6 = _1853 + 1;\n        float4 _1878 = fa_light_texel(param_6);\n        int param_7 = _1853 + 2;\n        float4 _1883 = fa_light_texel(param_7);\n        float3 _1886 = _1873.xyz;\n        float _1891 = dot(_1886, world_pos) + _1873.w;\n        float3 _1893 = _1878.xyz;\n        float _1898 = dot(_1893, world_pos) + _1878.w;\n        float3 _1900 = _1883.xyz;\n        float _1905 = dot(_1900, world_pos) + _1883.w;\n        bool _1910 = abs(_1891) > 0.5f;\n        bool _1918;\n        if (!_1910)\n        {\n            _1918 = abs(_1898) > 0.5f;\n        }\n        else\n        {\n            _1918 = _1910;\n        }\n        bool _1926;\n        if (!_1918)\n        {\n            _1926 = abs(_1905) > 0.5f;\n        }\n        else\n        {\n            _1926 = _1918;\n        }\n        if (_1926)\n        {\n            continue;\n        }\n        float _1941 = clamp(dot(geo_normal, normalize(_1900)) * _1858.z, 0.0f, 1.0f);\n        if (_1941 <= 0.0f)\n        {\n            continue;\n        }\n        float _1961 = (clamp((0.5f - abs(_1905)) * 10.0f, 0.0f, 1.0f) * _1941) * _1858.x;\n        float2 _1969 = float2(_1891 + 0.5f, 0.5f - _1898);\n        float2 _1979 = float2(dot(_1886, _1775), dot(_1893, _1775));\n        float2 _1989 = float2(dot(_1886, _1778), dot(_1893, _1778));\n        int param_8 = _1853 + 5;\n        float4 _1994 = fa_light_texel(param_8);\n        int param_9 = _1853 + 3;\n        float4 _1999 = fa_light_texel(param_9);\n        int param_10 = _1853 + 4;\n        float4 _2004 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1994.xyz;\n        bool _2014 = _1999.z > _1999.x;\n        if (_2014)\n        {\n            float4 param_11 = _1999;\n            float2 param_12 = _1969;\n            float2 param_13 = _1803;\n            float2 param_14 = _1979;\n            float2 param_15 = _1989;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1813 > 0.5f) && (_1813 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _2040 = fa_dc_to_linear(param_16);\n                float4 _6924 = tx;\n                _6924.x = _2040.x;\n                _6924.y = _2040.y;\n                _6924.z = _2040.z;\n                tx = _6924;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1961 * tex_a) * _1994.w, 0.0f, 1.0f).xxx);\n        if (_2004.z > _2004.x)\n        {\n            float4 param_17 = _2004;\n            float2 param_18 = _1969;\n            float2 param_19 = _1803;\n            float2 param_20 = _1979;\n            float2 param_21 = _1989;\n            float4 _2084 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1813 > 1.5f)\n            {\n                float3 param_22 = _2084.xyz;\n                float3 _2094 = fa_dc_to_srgb(param_22);\n                _2088 = _2094;\n            }\n            else\n            {\n                _2088 = _2084.xyz;\n            }\n            float3 _2103 = (_2088 * 2.0f) - 1.0f.xxx;\n            float2 _2108 = _2103.xy * _1858.y;\n            float3 _2130 = (normalize(_1886) * _2108.x) + (normalize(_1893) * _2108.y);\n            float3 _2133 = normalize(normal);\n            normal = normalize(lerp(_2133, normalize((_2133 * max(_2103.z, 0.0500000007450580596923828125f)) + (_2130 - (_2133 * dot(_2133, _2130)))), clamp(_1961 * (_2014 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3571 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3578 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3581 = int(_3571);\n    int _3584 = int(_3578);\n    float _3594 = _3578 - float(_3584);\n    int _3649 = (_3581 * 9) + _3584;\n    int _3669 = ((_3581 + 1) * 9) + _3584;\n    return lerp(lerp(_3645[_3649], _3645[_3649 + 1], _3594), lerp(_3645[_3669], _3645[_3669 + 1], _3594), _3571 - float(_3581));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _6767 = false;\n    float _6768 = 1.0f;\n    float _6769 = 1.0f;\n    float _6770 = 1.0f;\n    float _6771 = 0.0f;\n    float _6772 = 0.0f;\n    float _6773 = 0.0f;\n    float _6774 = 0.0f;\n    float _6776 = 1.0f;\n    bool _6777 = false;\n    float3 _6778 = 0.0f.xxx;\n    float _6779 = 1.0f;\n    float _6780 = 1.0f;\n    float _6781 = 1.0f;\n    float _6782 = 0.0f;\n    float _6783 = 0.0f;\n    float3 _6784 = float3(1.0f, 0.0f, 0.0f);\n    float3 _6785 = float3(0.0f, 0.0f, 1.0f);\n    float _6786 = 1.0f;\n    float _6787 = 1.0f;\n    float _3720 = clamp(s.specular, 0.0f, 1.0f);\n    float _3724 = clamp(s.ior, 1.0f, 3.0f);\n    bool _3729 = (_3720 != 1.0f) || (_3724 != 1.5f);\n    bool _3738;\n    if (!_3729)\n    {\n        _3738 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _3738 = _3729;\n    }\n    if (_3738)\n    {\n        float _3746 = (_3724 - 1.0f) / (_3724 + 1.0f);\n        f0 = lerp(min((_3746 * _3746).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _3720, s.albedo, metallic.xxx);\n        _6768 = lerp(_3720, 1.0f, metallic);\n        _6767 = true;\n    }\n    float _3773 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_3773 > 0.0f)\n    {\n        float _3781 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _6771 = _3773;\n        _6772 = _3781;\n        float _3788 = _3781 * _3781;\n        _6773 = _3788;\n        _6774 = _3788 * _3788;\n        float _3800 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _6776 = _3800;\n        _6769 = 1.0f - (_3773 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _3800, 0.0f, 1.0f), 5.0f))));\n        _6767 = true;\n    }\n    float3 _3819 = max(s.sheen_color, 0.0f.xxx);\n    float _3828 = max(_3819.x, max(_3819.y, _3819.z));\n    if (_3828 > 0.0f)\n    {\n        float _3836 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _6777 = true;\n        _6778 = _3819;\n        _6779 = _3836;\n        _6780 = _3836 * _3836;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _3836;\n        float _3853 = fa_sheen_albedo(param, param_1);\n        _6782 = _3853;\n        _6781 = 1.0f - min(_3828 * _3853, 1.0f);\n        _6767 = true;\n    }\n    _6770 = _6769 * _6781;\n    float _3872 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_3872 != 0.0f)\n    {\n        float3 _3887 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _3887;\n        if (dot(_3887, _3887) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _3899 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_3899.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _3899.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _3899.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _3903 = t;\n        float3 _3904 = normalize(_3903);\n        t = _3904;\n        float3 _3929 = normalize((_3904 * cos(s.anisotropy_rotation)) + ((cross(n, _3904) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _6784 = _3929;\n        _6785 = cross(n, _3929);\n        float _3939 = roughness * roughness;\n        float _3945 = lerp(_3939, 1.0f, _3872 * _3872);\n        bool _3947 = _3872 > 0.0f;\n        _6786 = _3947 ? _3945 : _3939;\n        _6787 = _3947 ? _3939 : _3945;\n        _6783 = _3872;\n        _6767 = true;\n    }\n    FaLayers _6809 = { _6767, _6768, _6769, _6770, _6771, _6772, _6773, _6774, i.world_normal, _6776, _6777, _6778, _6779, _6780, _6781, _6782, _6783, _6784, _6785, _6786, _6787 };\n    return _6809;\n}\n\nfloat3 fa_sky_sh_coef(int k)\n{\n    float3 v = fa_env_tex.SampleLevel(fa_env_smp, float3(1.0f, 1.0f - (float((2 * (k >> 2)) + 1) * 0.25f), 1.0f - (float((2 * (k & 3)) + 1) * 0.25f)), 5.0f).xyz;\n    if (_548_fa_env_sky.w > 1.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3328 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3328;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_548_fa_env_sky.w > 0.5f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _548_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_548_fa_cl_info.x) + int(_548_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_548_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _616_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _616_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _735 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _748 = (c - (ru * hx)) - p;\n        float3 _754 = ru * (2.0f * hx);\n        float _760 = max(dot(_754, _754), 9.9999999392252902907785028219223e-09f);\n        float _764 = dot(_748, _754);\n        float t = clamp((-_764) / _760, 0.0f, 1.0f);\n        if (_735)\n        {\n            float _779 = dot(r, _754);\n            float _785 = _760 - (_779 * _779);\n            if (abs(_785) > (9.9999997473787516355514526367188e-06f * _760))\n            {\n                t = clamp(((dot(r, _748) * _779) - _764) / _785, 0.0f, 1.0f);\n            }\n        }\n        return (p + _748) + (_754 * t);\n    }\n    float3 q = p;\n    float _817 = dot(r, axis);\n    bool _825;\n    if (_735)\n    {\n        _825 = abs(_817) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _825 = _735;\n    }\n    if (_825)\n    {\n        float _835 = dot(c - p, axis) / _817;\n        if (_835 > 0.0f)\n        {\n            q = p + (r * _835);\n        }\n    }\n    float3 _848 = q - c;\n    float2 xy = float2(dot(_848, ru), dot(_848, uu));\n    if (shape > 0.5f)\n    {\n        float _863 = length(xy);\n        if (_863 > hx)\n        {\n            xy *= (hx / _863);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _497 = abs(d);\n    float _499 = _497.x;\n    float _501 = _497.y;\n    bool _502 = _499 >= _501;\n    bool _510;\n    if (_502)\n    {\n        _510 = _499 >= _497.z;\n    }\n    else\n    {\n        _510 = _502;\n    }\n    int _511;\n    if (_510)\n    {\n        _511 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _526;\n        if (_501 >= _497.z)\n        {\n            _526 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _526 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _511 = _526;\n    }\n    return _511;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _655 = dot(d, right);\n    float _659 = dot(d, up);\n    float _670;\n    if (((_655 * _655) + (_659 * _659)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _670 = atan2(_659, _655) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _670 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_670 - floor(_670)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _901 = fa_light_base(param);\n    bool _905 = _548_fa_ambient.w > 4.5f;\n    int param_1 = _901;\n    float4 _909 = fa_light_texel(param_1);\n    int param_2 = _901 + 1;\n    float4 _914 = fa_light_texel(param_2);\n    float _917 = _914.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _929 = _905 && (_917 > 2.5f);\n    fa_light_is_area = _929;\n    bool _931 = _917 < 0.5f;\n    float3 l;\n    if (_931)\n    {\n        l = normalize(_909.xyz);\n        if (_905)\n        {\n            int param_3 = _901 + 6;\n            float4 _945 = fa_light_texel(param_3);\n            if (_945.z > 0.5f)\n            {\n                int param_4 = _901 + 4;\n                float4 _955 = fa_light_texel(param_4);\n                int param_5 = _901 + 5;\n                float4 _960 = fa_light_texel(param_5);\n                float2 param_6 = _945.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _955.xyz) * _955.w, (-dot(world_pos, _960.xyz)) * _960.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _990 = _909.xyz;\n        float3 _992 = _990 - world_pos;\n        float3 to_light = _992;\n        float _995 = length(_992);\n        float reach = _995;\n        bool front = true;\n        if (_929)\n        {\n            int param_8 = _901 + 7;\n            reach = max(_995 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _901 + 4;\n            float4 _1019 = fa_light_texel(param_9);\n            int param_10 = _901 + 5;\n            float4 _1024 = fa_light_texel(param_10);\n            int param_11 = _901 + 6;\n            float4 _1029 = fa_light_texel(param_11);\n            float _1030 = _1029.w;\n            int param_12 = _901 + 2;\n            float3 _1037 = normalize(fa_light_texel(param_12).xyz);\n            bool _1039 = _1030 > 1.5f;\n            bool _1047;\n            if (!_1039)\n            {\n                _1047 = dot(_1037, to_light) < 0.0f;\n            }\n            else\n            {\n                _1047 = _1039;\n            }\n            front = _1047;\n            float3 r = 0.0f.xxx;\n            float3 _1056 = _548_fa_camera_pos.xyz - world_pos;\n            bool _1060 = dot(n, n) > 0.5f;\n            bool _1068;\n            if (_1060)\n            {\n                _1068 = dot(_1056, _1056) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _1068 = _1060;\n            }\n            if (_1068)\n            {\n                r = reflect(-normalize(_1056), normalize(n));\n            }\n            float3 param_13 = _990;\n            float3 param_14 = _1037;\n            float3 param_15 = _1019.xyz;\n            float3 param_16 = _1024.xyz;\n            float param_17 = _1019.w;\n            float param_18 = _1024.w;\n            float param_19 = _1030;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1104 = length(to_light);\n        dist = _1104;\n        l = to_light / max(_1104, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1118 = reach / max(_909.w, 0.001000000047497451305389404296875f);\n        float _1124 = clamp(1.0f - (_1118 * _1118), 0.0f, 1.0f);\n        float _1126;\n        if (front)\n        {\n            _1126 = _1124 * _1124;\n        }\n        else\n        {\n            _1126 = 0.0f;\n        }\n        atten = _1126;\n        bool _1137 = _917 < 2.5f;\n        if ((_917 > 1.5f) && _1137)\n        {\n            int param_22 = _901 + 2;\n            float4 _1145 = fa_light_texel(param_22);\n            float _1155 = _1145.w;\n            int param_23 = _901 + 3;\n            float4 _1160 = fa_light_texel(param_23);\n            float _1161 = _1160.x;\n            float cos_inner = _1161;\n            if (_1161 > 1.5f)\n            {\n                cos_inner = lerp(_1155, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1155, cos_inner, dot(-l, normalize(_1145.xyz)));\n        }\n        if (_905 && (_917 < 1.5f))\n        {\n            int param_24 = _901 + 6;\n            float4 _1185 = fa_light_texel(param_24);\n            if (_1185.z > 0.5f)\n            {\n                float3 _1193 = -to_light;\n                int param_25 = _901 + 4;\n                int param_26 = _901 + 5;\n                float3 _1207 = fa_light_texel(param_25).xyz;\n                float3 _1211 = fa_light_texel(param_26).xyz;\n                float3 _1220 = float3(dot(_1193, _1207), dot(_1193, _1211), dot(_1193, cross(_1207, _1211)));\n                float3 param_27 = _1220;\n                int _1224 = fa_cube_face(param_27);\n                int param_28 = _1224;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1251 = float2(dot(_1220, cross(param_29, param_30)), dot(_1220, param_30)) / max(dot(_1220, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1255 = _1224 / 3;\n                float2 param_31 = _1185.xy + (float2(float(_1224 - (_1255 * 3)), float(_1255)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1251.x), 0.5f - (0.5f * _1251.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _901 + 7;\n            float4 _1285 = fa_light_texel(param_33);\n            if (_1285.z > 0.5f)\n            {\n                int param_34 = _901 + 2;\n                int param_35 = _901 + 4;\n                int param_36 = _901 + 5;\n                float2 param_37 = _1285.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_905 && _1137)\n            {\n                int param_42 = _901 + 6;\n                float4 _1332 = fa_light_texel(param_42);\n                int param_43 = _901 + 7;\n                float4 _1337 = fa_light_texel(param_43);\n                bool _1340 = _1332.z > 0.5f;\n                bool _1347;\n                if (!_1340)\n                {\n                    _1347 = _1337.z > 0.5f;\n                }\n                else\n                {\n                    _1347 = _1340;\n                }\n                if (_1347)\n                {\n                    int param_44 = _901 + 2;\n                    float4 _1354 = fa_light_texel(param_44);\n                    float3 _1358 = normalize(_1354.xyz);\n                    int param_45 = _901 + 4;\n                    float4 _1363 = fa_light_texel(param_45);\n                    int param_46 = _901 + 5;\n                    float4 _1368 = fa_light_texel(param_46);\n                    if (_1340)\n                    {\n                        float3 _1376 = -to_light;\n                        float _1383 = _1354.w;\n                        float _1399 = 0.5f / max(dot(_1376, _1358) * (sqrt(max(1.0f - (_1383 * _1383), 0.0f)) / max(_1383, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1332.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1376, _1363.xyz) * _1399), 0.5f - (dot(_1376, _1368.xyz) * _1399));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1337.z > 0.5f)\n                    {\n                        float2 param_49 = _1337.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1358;\n                        float3 param_52 = _1363.xyz;\n                        float3 param_53 = _1368.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _6755 = _914.xyz * atten;\n    if (_905)\n    {\n        _6755 *= fa_light_tint;\n    }\n    int _1468;\n    if (_931)\n    {\n        _1468 = 0;\n    }\n    else\n    {\n        _1468 = ((_917 > 1.5f) && (_917 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _6766 = { l, _6755, atten, 1.0f, dist, _1468 };\n    return _6766;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2205;\n    if (i == 0)\n    {\n        _2205 = _2215_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2221;\n        if (i == 1)\n        {\n            _2221 = _2215_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2229;\n            if (i == 2)\n            {\n                _2229 = _2215_fa_shadow_split.z;\n            }\n            else\n            {\n                _2229 = _2215_fa_shadow_split.w;\n            }\n            _2221 = _2229;\n        }\n        _2205 = _2221;\n    }\n    return _2205;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2262 = fa_shadow_depth(param, param_1);\n    float _2266;\n    if (conv.x < 0.5f)\n    {\n        _2266 = _2262;\n    }\n    else\n    {\n        _2266 = (conv.y * conv.z) / (conv.z - (_2262 * (conv.z - conv.y)));\n    }\n    return _2266;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2193 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2193), sin(_2193)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2312 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2321;\n        if (k < 0.0f)\n        {\n            _2321 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2321 = k;\n        }\n        float _2341 = clamp((_2321 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2312;\n            float2 _2360 = fa_shadow_vogel(param_3, param_4, param_5) * _2341;\n            float2 param_6 = uv + (_2360 * _2215_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2372 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2372 < (zr - (length(_2360) * plane)))\n            {\n                sum += _2372;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2398 = sum / cnt;\n        float _2408;\n        if (k < 0.0f)\n        {\n            _2408 = (-k) / max(_2398, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2408 = k;\n        }\n        radius = clamp(((max(zr - _2398, 0.0f) * unit) * _2408) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2430 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2430; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2430;\n        float param_11 = _2312;\n        float2 _2449 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2449 * _2215_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2449) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2430);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2491 = max(_2215_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2496 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2502 = sqrt(1.0f - (_2496 * _2496));\n    float _2509 = min(_2502 / max(_2496, 0.20000000298023223876953125f), 4.0f);\n    float _2514;\n    if (_2215_fa_shadow_bias.y > 0.0f)\n    {\n        _2514 = _2215_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2514 = 1.5f * _2215_fa_shadow_info[ci].x;\n    }\n    float4 _2539 = mul(float4(world + (n * (_2514 * _2502)), 1.0f), _2215_fa_shadow_mat[ci]);\n    float _2546 = _2539.x;\n    bool _2549 = _2546 < _2215_fa_shadow_rect[ci].x;\n    bool _2558;\n    if (!_2549)\n    {\n        _2558 = _2546 > _2215_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2558 = _2549;\n    }\n    bool _2567;\n    if (!_2558)\n    {\n        _2567 = _2539.y < _2215_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2567 = _2558;\n    }\n    bool _2576;\n    if (!_2567)\n    {\n        _2576 = _2539.y > _2215_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2576 = _2567;\n    }\n    bool _2583;\n    if (!_2576)\n    {\n        _2583 = _2539.z > 1.0f;\n    }\n    else\n    {\n        _2583 = _2576;\n    }\n    if (_2583)\n    {\n        return -1.0f;\n    }\n    float _2591;\n    if (_2215_fa_shadow_bias.x > 0.0f)\n    {\n        _2591 = _2215_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2591 = 1.5f * _2215_fa_shadow_info[ci].x;\n    }\n    float2 param = _2539.xy;\n    float4 param_1 = _2215_fa_shadow_rect[ci];\n    float param_2 = _2539.z - ((_2591 * (1.0f + (0.5f * _2509))) / _2491);\n    float param_3 = _2215_fa_shadow_info[ci].x;\n    float param_4 = _2491;\n    float param_5 = _2491 * 0.25f;\n    float param_6 = ((_2215_fa_shadow_info[ci].x * min(_2509, 3.0f)) * 0.5f) / _2491;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2215_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2215_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_548_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2969 = int(_2215_fa_shadow_cfg.x + 0.5f);\n    if (_2969 < 1)\n    {\n        return 1.0f;\n    }\n    float _2984 = dot(world - _2215_fa_shadow_eye.xyz, _2215_fa_shadow_fwd.xyz);\n    int param = _2969 - 1;\n    if (_2984 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2996 = _2969 > 1;\n    bool _3003;\n    if (_2996)\n    {\n        _3003 = _2984 > _2215_fa_shadow_split.x;\n    }\n    else\n    {\n        _3003 = _2996;\n    }\n    if (_3003)\n    {\n        ci = 1;\n    }\n    bool _3007 = _2969 > 2;\n    bool _3014;\n    if (_3007)\n    {\n        _3014 = _2984 > _2215_fa_shadow_split.y;\n    }\n    else\n    {\n        _3014 = _3007;\n    }\n    if (_3014)\n    {\n        ci = 2;\n    }\n    bool _3018 = _2969 > 3;\n    bool _3025;\n    if (_3018)\n    {\n        _3025 = _2984 > _2215_fa_shadow_split.z;\n    }\n    else\n    {\n        _3025 = _3018;\n    }\n    if (_3025)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2969)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _3051 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3051;\n        if (_3051 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2215_fa_shadow_cfg.y > 0.0f)\n    {\n        float _3076;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3076 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3076 = _2215_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _3095 = _2215_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3076, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _3106 = clamp((_2984 - (fa_shadow_split_at(param_7) - _3095)) / _3095, 0.0f, 1.0f);\n        if (_3106 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2969)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _3127 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3127;\n                if (_3127 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _3106);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2649 = _548_fa_pbr.z < 0.5f;\n    bool _2656;\n    if (!_2649)\n    {\n        _2656 = _2215_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2656 = _2649;\n    }\n    if (_2656)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2215_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2669 = fa_light_texel(param);\n    float _2670 = _2669.x;\n    if (_2670 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2679 = int(_2670 + 0.5f);\n    int param_1 = _2679;\n    float4 _2683 = fa_light_texel(param_1);\n    int param_2 = _2679 + 1;\n    float4 _2688 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2691 = _2683.y;\n    if (_2691 > 0.0f)\n    {\n        float _2708 = 1.0f - smoothstep(0.75f * _2691, _2691, length(world - _2215_fa_shadow_eye.xyz));\n        fade = _2708;\n        if (_2708 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2683.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2732 = (_2679 + 2) + (face * 6);\n    int param_4 = _2732;\n    int param_5 = _2732 + 1;\n    int param_6 = _2732 + 3;\n    float4 _2746 = fa_light_texel(param_6);\n    int param_7 = _2732 + 4;\n    float4 _2751 = fa_light_texel(param_7);\n    int param_8 = _2732 + 5;\n    float4 _2756 = fa_light_texel(param_8);\n    float _2768 = _2756.x * max(dot(_2746, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2773 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2796 = clamp(dot(n, _2746.xyz), -1.0f, 1.0f);\n    float _2815 = min(sqrt(1.0f - (_2796 * _2796)) / max(abs(dot(n, world - lpos)) / max(dot(_2746, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2818 = _2688.y;\n    float _2820;\n    if (_2818 > 0.0f)\n    {\n        _2820 = _2818;\n    }\n    else\n    {\n        _2820 = 1.5f * _2768;\n    }\n    float4 _2840 = float4(world + (n * (_2820 * sqrt(1.0f - (_2773 * _2773)))), 1.0f);\n    float _2844 = dot(_2746, _2840);\n    float _2847 = _2756.y;\n    if (_2844 < _2847)\n    {\n        return 1.0f;\n    }\n    float2 _2862 = float2(dot(fa_light_texel(param_4), _2840), dot(fa_light_texel(param_5), _2840)) / _2844.xx;\n    float _2864 = _2862.x;\n    bool _2867 = _2864 < _2751.x;\n    bool _2876;\n    if (!_2867)\n    {\n        _2876 = _2864 > _2751.z;\n    }\n    else\n    {\n        _2876 = _2867;\n    }\n    bool _2885;\n    if (!_2876)\n    {\n        _2885 = _2862.y < _2751.y;\n    }\n    else\n    {\n        _2885 = _2876;\n    }\n    bool _2894;\n    if (!_2885)\n    {\n        _2894 = _2862.y > _2751.w;\n    }\n    else\n    {\n        _2894 = _2885;\n    }\n    if (_2894)\n    {\n        return 1.0f;\n    }\n    float _2900 = _2688.x;\n    float _2902;\n    if (_2900 > 0.0f)\n    {\n        _2902 = _2900;\n    }\n    else\n    {\n        _2902 = 1.5f * _2768;\n    }\n    float2 param_9 = _2862;\n    float4 param_10 = _2751;\n    float param_11 = _2844 - (_2902 * (1.0f + (0.5f * _2815)));\n    float param_12 = _2768;\n    float param_13 = 1.0f;\n    float param_14 = _2756.z * 0.25f;\n    float param_15 = (_2768 * min(_2815, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2847, _2756.z);\n    int param_17 = int(_2683.z + 0.5f);\n    float param_18 = _2683.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _4491 = fa_lm.z > 0.5f;\n    bool _4497;\n    if (_4491)\n    {\n        int param = li;\n        _4497 = fa_light_baked(param);\n    }\n    else\n    {\n        _4497 = _4491;\n    }\n    if (_4497)\n    {\n        int param_1 = li;\n        LightSample _6822 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _6822;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4521 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _6824 = _4521.color;\n    float _6826 = _4521.shadow;\n    if ((_4521.type == 0) && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4521.direction;\n        float _4535 = fa_shadow_factor(param_5, param_6);\n        _6826 = _4535;\n        _6824 *= _4535;\n    }\n    else\n    {\n        bool _4546 = _4521.type != 0;\n        bool _4552;\n        if (_4546)\n        {\n            _4552 = _4521.attenuation > 0.0f;\n        }\n        else\n        {\n            _4552 = _4546;\n        }\n        if (_4552)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _4521.direction;\n            float _4571 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _6826 = _4571;\n            _6824 *= _4571;\n        }\n    }\n    LightSample _6841 = { _4521.direction, _6824, _4521.attenuation, _6826, _4521._distance, _4521.type };\n    return _6841;\n}\n\nfloat3 fa_ltc_tangent(float3 n, float3 v)\n{\n    float3 _4611 = v - (n * dot(v, n));\n    float3 t = _4611;\n    float _4615 = dot(_4611, _4611);\n    float l2 = _4615;\n    if (_4615 < 1.0000000133514319600180897396058e-10f)\n    {\n        float3 _4625;\n        if (abs(n.z) < 0.999000012874603271484375f)\n        {\n            _4625 = cross(n, float3(0.0f, 0.0f, 1.0f));\n        }\n        else\n        {\n            _4625 = cross(n, float3(1.0f, 0.0f, 0.0f));\n        }\n        t = _4625;\n        l2 = dot(_4625, _4625);\n    }\n    return t * rsqrt(l2);\n}\n\nfloat3 fa_ltc_local(float3 t1, float3 n, float3 p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nfloat3 fa_ltc_edge_vector(float3 a, float3 b)\n{\n    float _4660 = dot(a, a);\n    float _4664 = dot(b, b);\n    if ((_4660 < 1.0000000195414813782625560981111e-24f) || (_4664 < 1.0000000195414813782625560981111e-24f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _4678 = a * rsqrt(_4660);\n    float3 _4683 = b * rsqrt(_4664);\n    float _4687 = dot(_4678, _4683);\n    float _4690 = abs(_4687);\n    float g = (((((((((((0.0416471660137176513671875f * _4690) - 0.1924748718738555908203125f) * _4690) + 0.4179156124591827392578125f) * _4690) - 0.616057217121124267578125f) * _4690) + 0.777722418308258056640625f) * _4690) - 0.999542415142059326171875f) * _4690) + 1.570791721343994140625f;\n    if (_4687 < 0.0f)\n    {\n        g = (3.1415927410125732421875f * rsqrt(max(1.0f - (_4687 * _4687), 1.0000000116860974230803549289703e-07f))) - g;\n    }\n    return cross(_4678, _4683) * g;\n}\n\nvoid fa_ltc_clip_edge(float3 a, float3 b, inout float3 sum, inout float3 leave, inout float3 enter, inout float2 seen)\n{\n    bool _4747 = a.z > 0.0f;\n    bool _4751 = b.z > 0.0f;\n    if (_4747 && _4751)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_4747 != _4751)\n        {\n            float3 _4786 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _4786.z = 0.0f;\n            if (_4747)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _4786;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _4786;\n                seen.x = 1.0f;\n            }\n            else\n            {\n                float3 param_4 = _4786;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _4786;\n                seen.y = 1.0f;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(float4 abcd, float3 p0, float3 p1, float3 p2, float3 p3)\n{\n    float3 _4835 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _4861 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _4887 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _4913 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = 0.0f.xxx;\n    float3 leave = 0.0f.xxx;\n    float3 enter = 0.0f.xxx;\n    float3 param = _4835;\n    float3 param_1 = _4861;\n    float3 param_2 = 0.0f.xxx;\n    float3 param_3 = 0.0f.xxx;\n    float3 param_4 = 0.0f.xxx;\n    float2 param_5 = 0.0f.xx;\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _4861;\n    float3 param_7 = _4887;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _4887;\n    float3 param_13 = _4913;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _4913;\n    float3 param_19 = _4835;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5f)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875f;\n}\n\nfloat fa_ltc_rect(float4 abcd, float3 center, float3 ex, float3 ey)\n{\n    float4 param = abcd;\n    float3 param_1 = (center - ex) - ey;\n    float3 param_2 = (center + ex) - ey;\n    float3 param_3 = (center + ex) + ey;\n    float3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(float4 m, float shape, float3 pc, float3 ex, float3 ey)\n{\n    if ((shape < 0.5f) || (shape > 1.5f))\n    {\n        float4 param = m;\n        float3 param_1 = pc;\n        float3 param_2 = ex;\n        float3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    float3 _5063 = (pc + (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _5087 = (pc - (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _5103 = (pc - (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float4 param_4 = m;\n    float3 param_5 = _5063;\n    float3 param_6 = (pc + (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_7 = (pc - (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_8 = _5087;\n    float4 param_9 = m;\n    float3 param_10 = _5063;\n    float3 param_11 = _5087;\n    float3 param_12 = (pc - (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    float3 param_13 = _5103;\n    float4 param_14 = m;\n    float3 param_15 = _5063;\n    float3 param_16 = _5103;\n    float3 param_17 = (pc + (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float3 param_18 = (pc + (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nfloat2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((float2(clamp((roughness - 0.0500000007450580596923828125f) * 1.0526316165924072265625f, 0.0f, 1.0f), sqrt(clamp(1.0f - ndv, 0.0f, 1.0f))) * 63.0f) + 0.5f.xx) * 0.015625f.xx;\n}\n\nfloat3 fa_area_shade(int li, float3 world_pos, float3 n, float3 v, float3 diffuse_color, float3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _5161 = fa_light_base(param);\n    int param_1 = _5161;\n    int param_2 = _5161 + 1;\n    int param_3 = _5161 + 2;\n    int param_4 = _5161 + 4;\n    float4 _5183 = fa_light_texel(param_4);\n    int param_5 = _5161 + 5;\n    float4 _5188 = fa_light_texel(param_5);\n    int param_6 = _5161 + 6;\n    float4 _5193 = fa_light_texel(param_6);\n    float _5194 = _5193.w;\n    float3 _5199 = fa_light_texel(param_1).xyz - world_pos;\n    bool _5201 = _5194 < 1.5f;\n    bool _5208;\n    if (_5201)\n    {\n        _5208 = dot(normalize(fa_light_texel(param_3).xyz), _5199) >= 0.0f;\n    }\n    else\n    {\n        _5208 = _5201;\n    }\n    if (_5208)\n    {\n        return 0.0f.xxx;\n    }\n    bool _5217 = (_5194 > 0.5f) && _5201;\n    float _5221 = _5217 ? 1.0539000034332275390625f : 1.0f;\n    float3 _5224 = _5183.xyz;\n    float _5226 = _5183.w;\n    float3 _5232 = _5188.xyz;\n    float _5234 = _5188.w;\n    float3 up = _5232 * (_5234 * _5221);\n    float _5240;\n    if (_5217)\n    {\n        _5240 = (3.1415927410125732421875f * _5226) * _5226;\n    }\n    else\n    {\n        _5240 = (4.0f * _5226) * _5234;\n    }\n    if (_5194 > 1.5f)\n    {\n        float3 _5266 = cross(_5224, -_5199);\n        float3 perp = _5266;\n        float _5270 = dot(_5266, _5266);\n        float3 _5273;\n        if (_5270 > 1.0000000133514319600180897396058e-10f)\n        {\n            _5273 = perp * rsqrt(_5270);\n        }\n        else\n        {\n            _5273 = _5232;\n        }\n        perp = _5273;\n        up = _5273 * _5234;\n    }\n    float _5294 = max(_5240, 9.9999999747524270787835121154785e-07f);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _5304 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _5304;\n    float3 param_10 = n;\n    float3 param_11 = _5199;\n    float3 _5312 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_12 = _5304;\n    float3 param_13 = n;\n    float3 param_14 = _5224 * (_5226 * _5221);\n    float3 _5320 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_15 = _5304;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float3 _5328 = fa_ltc_local(param_15, param_16, param_17);\n    float4 param_18 = float4(1.0f, 0.0f, 0.0f, 1.0f);\n    float param_19 = _5194;\n    float3 param_20 = _5312;\n    float3 param_21 = _5320;\n    float3 param_22 = _5328;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    float2 _5347 = fa_ltc_uv(param_23, param_24) * 64.0f;\n    float2 param_25 = _5347;\n    float2 param_26 = _5347 + float2(64.0f, 0.0f);\n    float4 _5357 = fa_atlas_fetch(param_26);\n    float4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _5194;\n    float3 param_29 = _5312;\n    float3 param_30 = _5320;\n    float3 param_31 = _5328;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _5357.x) + ((f90.xxx - f0) * _5357.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875f * dot(_5199, _5199)) + _5294) / _5294) * window);\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4194 = 1.0f / alpha;\n    return ((2.0f + _4194) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _4194)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat fa_layers_coat(FaLayers L, float3 l, float3 h, float vdh)\n{\n    float _4229 = max(dot(L.nc, l), 0.0f);\n    float _4235 = max(dot(L.nc, h), 0.0f);\n    float _4244 = ((_4235 * _4235) * (L.coat_a2 - 1.0f)) + 1.0f;\n    return (((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _4244) * _4244)) * (0.5f / max(lerp((2.0f * _4229) * L.coat_ndv, _4229 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _4229)) * _4229;\n}\n\nfloat3 fa_area_layers(FaLayers L, int li, float3 world_pos, float3 n, float3 v, float3 l, float3 diffuse_color, float3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    float3 param_2 = n;\n    float3 param_3 = v;\n    float3 param_4 = diffuse_color;\n    float3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _5425;\n    if (L.sheen_on)\n    {\n        _5425 = L.sheen_scale;\n    }\n    else\n    {\n        _5425 = 1.0f;\n    }\n    float3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _5425);\n    float3 _5438 = normalize(l + v);\n    int param_10 = li;\n    float3 _5449 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _5458 = max(dot(n, l), 0.0f);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _5438), 0.0f);\n        float param_13 = _5458;\n        float param_14 = ndv;\n        result += ((L.sheen * _5449) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875f) * step(9.9999997473787516355514526367188e-05f, _5458)) * _5458) * L.keep));\n    }\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_15 = L;\n        float3 param_16 = l;\n        float3 param_17 = _5438;\n        float param_18 = max(dot(v, _5438), 0.0f);\n        result += (_5449 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4097 = tdh / at;\n    float _4101 = bdh / ab;\n    float _4113 = ((_4097 * _4097) + (_4101 * _4101)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _4113) * _4113);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4293 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4372 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _4372) * _4372);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _4293);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _4293));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_17 = L;\n        float3 param_18 = l;\n        float3 param_19 = h;\n        float param_20 = vdh;\n        result += fa_layers_coat(param_17, param_18, param_19, param_20).xxx;\n    }\n    return result;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3503 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3506 = _3503.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3506 * _3506, exp2((-9.27999973297119140625f) * ndv)) * _3506) + _3503.y)) + _3503.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_548_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _548_fa_env_horizon.w).xyz;\n    }\n    float _3357 = rough * rough;\n    float _3387 = 0.60000002384185791015625f * _3357;\n    return lerp(lerp(_548_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_548_fa_env_horizon.xyz, _548_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3357)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3387, 0.0500000007450580596923828125f + _3387, d.y).xxx), ((_548_fa_env_sky.xyz + _548_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3357 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _3980;\n        if (L.aniso >= 0.0f)\n        {\n            _3980 = L.b;\n        }\n        else\n        {\n            _3980 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_3980, v), _3980), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4013 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _4013.x) + (L.f90.xxx * _4013.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _4068 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _4068.x) + _4068.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3545 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3545.x) + _3545.y.xxx);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2215_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3151 = int(_2215_fa_shadow_cfg.x + 0.5f);\n    float _3161 = dot(world - _2215_fa_shadow_eye.xyz, _2215_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3166 = _3151 > 0;\n    bool _3175;\n    if (_3166)\n    {\n        int param = _3151 - 1;\n        _3175 = _3161 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3175 = _3166;\n    }\n    if (_3175)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3181 = _3151 > 1;\n        bool _3188;\n        if (_3181)\n        {\n            _3188 = _3161 > _2215_fa_shadow_split.x;\n        }\n        else\n        {\n            _3188 = _3181;\n        }\n        if (_3188)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3194 = _3151 > 2;\n        bool _3201;\n        if (_3194)\n        {\n            _3201 = _3161 > _2215_fa_shadow_split.y;\n        }\n        else\n        {\n            _3201 = _3194;\n        }\n        if (_3201)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3207 = _3151 > 3;\n        bool _3214;\n        if (_3207)\n        {\n            _3214 = _3161 > _2215_fa_shadow_split.z;\n        }\n        else\n        {\n            _3214 = _3207;\n        }\n        if (_3214)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _6524 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6524 = -_6524;\n    }\n    float3 _5879 = normalize(_548_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _6537 = { fa_world_pos, _6524, fa_world_tangent, fa_uv, fa_vertex_color, _5879, gl_FrontFacing };\n    SurfaceInput param_1 = _6537;\n    Surface _5887 = fa_standard_surface(param_1);\n    float3 _6555 = _5887.albedo;\n    float _6556 = _5887.alpha;\n    float3 _6557 = _5887.normal;\n    float _6558 = _5887.metallic;\n    float _6559 = _5887.roughness;\n    float _6560 = _5887.occlusion;\n    float3 _6561 = _5887.emission;\n    float _6562 = _5887.clearcoat;\n    float _6563 = _5887.clearcoat_roughness;\n    float3 _6564 = _5887.sheen_color;\n    float _6565 = _5887.sheen_roughness;\n    float _6566 = _5887.anisotropy;\n    float _6567 = _5887.anisotropy_rotation;\n    float _6568 = _5887.specular;\n    float _6569 = _5887.ior;\n    float3 _6570 = _5887.specular_color;\n    SurfaceInput _6545 = { fa_world_pos, _6524, fa_world_tangent, fa_uv, fa_vertex_color, _5879, gl_FrontFacing };\n    SurfaceInput param_2 = _6545;\n    Surface param_3 = _5887;\n    surface(param_2, param_3);\n    _6555 = param_3.albedo;\n    _6556 = param_3.alpha;\n    _6557 = param_3.normal;\n    _6558 = param_3.metallic;\n    _6559 = param_3.roughness;\n    _6560 = param_3.occlusion;\n    _6561 = param_3.emission;\n    _6562 = param_3.clearcoat;\n    _6563 = param_3.clearcoat_roughness;\n    _6564 = param_3.sheen_color;\n    _6565 = param_3.sheen_roughness;\n    _6566 = param_3.anisotropy;\n    _6567 = param_3.anisotropy_rotation;\n    _6568 = param_3.specular;\n    _6569 = param_3.ior;\n    _6570 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _6524;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6555 = param_6;\n    _6557 = param_7;\n    float3 result;\n    if (_548_fa_emissive.w > 0.5f)\n    {\n        result = _6555;\n    }\n    else\n    {\n        float3 _5926 = normalize(_6557);\n        float _5933 = clamp(_6558, 0.0f, 1.0f);\n        float _5937 = clamp(_6559, 0.0500000007450580596923828125f, 1.0f);\n        float _5941 = _5937 * _5937;\n        float _5945 = _5941 * _5941;\n        float _5950 = max(dot(_5926, _5879), 9.9999997473787516355514526367188e-05f);\n        float3 _5956 = _6555 * (1.0f - _5933);\n        float3 _5963 = lerp(0.039999999105930328369140625f.xxx, _6555, _5933.xxx);\n        float3 f0 = _5963;\n        SurfaceInput _6553 = { fa_world_pos, _6524, fa_world_tangent, fa_uv, fa_vertex_color, _5879, gl_FrontFacing };\n        SurfaceInput param_8 = _6553;\n        Surface _6636 = { _6555, _6556, _6557, _6558, _6559, _6560, _6561, _6562, _6563, _6564, _6565, _6566, _6567, _6568, _6569, _6570 };\n        Surface param_9 = _6636;\n        float3 param_10 = _5926;\n        float3 param_11 = _5879;\n        float param_12 = _5933;\n        float param_13 = _5937;\n        float3 param_14 = _5963;\n        FaLayers _5979 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _5926;\n        float3 lit = (fa_indirect_diffuse(param_15) * _5956) * _6560;\n        if (_5979.on)\n        {\n            lit *= _5979.base_scale;\n        }\n        int _6001 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6001; ln++)\n        {\n            int param_16 = ln;\n            int _6014 = fa_cl_light(param_16);\n            bool _6017 = fa_lm.z > 0.5f;\n            bool _6023;\n            if (_6017)\n            {\n                int param_17 = _6014;\n                _6023 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _6023 = _6017;\n            }\n            if (_6023)\n            {\n                continue;\n            }\n            int param_18 = _6014;\n            float3 param_19 = fa_world_pos;\n            float3 param_20 = _6524;\n            LightSample _6035 = fa_light_shadowed(param_18, param_19, param_20);\n            float _6043 = max(dot(_5926, _6035.direction), 0.0f);\n            float _6049 = _6035.attenuation * _6035.shadow;\n            float3 _6054 = normalize(_6035.direction + _5879);\n            float _6059 = max(dot(_5926, _6054), 0.0f);\n            float _6064 = max(dot(_5879, _6054), 0.0f);\n            bool _6071;\n            if (fa_light_is_area)\n            {\n                _6071 = !_5979.on;\n            }\n            else\n            {\n                _6071 = fa_light_is_area;\n            }\n            if (_6071)\n            {\n                int param_21 = _6014;\n                float3 param_22 = fa_world_pos;\n                float3 param_23 = _5926;\n                float3 param_24 = _5879;\n                float3 param_25 = _5956;\n                float3 param_26 = f0;\n                float param_27 = 1.0f;\n                float param_28 = _5937;\n                float param_29 = _5950;\n                float param_30 = _6049;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _5979;\n                    int param_32 = _6014;\n                    float3 param_33 = fa_world_pos;\n                    float3 param_34 = _5926;\n                    float3 param_35 = _5879;\n                    float3 param_36 = _6035.direction;\n                    float3 param_37 = _5956;\n                    float3 param_38 = f0;\n                    float param_39 = _5937;\n                    float param_40 = _5950;\n                    float param_41 = _6049;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_5979.on)\n                    {\n                        FaLayers param_42 = _5979;\n                        float3 param_43 = _5956;\n                        float3 param_44 = f0;\n                        float3 param_45 = _5926;\n                        float3 param_46 = _5879;\n                        float3 param_47 = _6035.direction;\n                        float3 param_48 = _6054;\n                        float param_49 = _6043;\n                        float param_50 = _5950;\n                        float param_51 = _6059;\n                        float param_52 = _6064;\n                        float param_53 = _5941;\n                        float param_54 = _5945;\n                        int param_55 = _6014;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _6049));\n                    }\n                    else\n                    {\n                        float _6177 = ((_6059 * _6059) * (_5945 - 1.0f)) + 1.0f;\n                        int param_56 = _6014;\n                        lit += (((_5956 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _6064, 5.0f))) * (((_5945 / ((3.1415927410125732421875f * _6177) * _6177)) * (0.5f / max(lerp((2.0f * _6043) * _5950, _6043 + _5950, _5941), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _6043))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_6043 * _6049));\n                    }\n                }\n            }\n        }\n        if (_5979.on)\n        {\n            FaLayers param_57 = _5979;\n            float3 param_58 = _5926;\n            float3 param_59 = _5879;\n            float3 param_60 = f0;\n            float param_61 = _5937;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _6560);\n        }\n        else\n        {\n            float3 param_62 = _5926;\n            float3 param_63 = _5879;\n            float3 param_64 = f0;\n            float param_65 = _5937;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _6560);\n        }\n        result = lit;\n    }\n    float3 _6272 = result;\n    float3 _6273 = _6272 + _6561;\n    result = _6273;\n    float3 param_66 = _6273;\n    float3 param_67 = fa_world_pos;\n    result = fa_shadow_debug(param_66, param_67);\n    bool _6282 = _548_fa_fog.w > 0.0f;\n    bool _6289;\n    if (!_6282)\n    {\n        _6289 = _548_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _6289 = _6282;\n    }\n    if (_6289)\n    {\n        float3 _6298 = fa_world_pos - _548_fa_camera_pos.xyz;\n        float _6304 = dot(_6298, _548_fa_fog_c.xyz);\n        bool _6308 = _548_fa_fog_c.w > 0.5f;\n        float _6309;\n        if (_6308)\n        {\n            _6309 = _6304;\n        }\n        else\n        {\n            _6309 = length(_6298);\n        }\n        float _6321 = _6309 - _548_fa_fog_b.x;\n        if (_6321 > 0.0f)\n        {\n            float _6330 = _548_fa_fog.w * _6321;\n            float tau = _6330 * _6330;\n            if (_548_fa_fog_b.y > 0.0f)\n            {\n                float _6346;\n                if (_6308)\n                {\n                    _6346 = fa_world_pos.y - (_548_fa_fog_c.y * _6304);\n                }\n                else\n                {\n                    _6346 = _548_fa_camera_pos.y;\n                }\n                float _6367 = lerp(_6346, fa_world_pos.y, clamp(_548_fa_fog_b.x / _6309, 0.0f, 1.0f));\n                float _6371 = fa_world_pos.y - _6367;\n                float _6376 = _6367 - _548_fa_fog_b.z;\n                float _6381 = fa_world_pos.y - _548_fa_fog_b.z;\n                bool _6384 = _6376 <= 0.0f;\n                bool _6385 = !_6384;\n                bool _6391;\n                if (_6385)\n                {\n                    _6391 = _548_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6391 = _6384;\n                }\n                float _6392;\n                if (_6391)\n                {\n                    _6392 = _548_fa_fog_b.y;\n                }\n                else\n                {\n                    _6392 = _548_fa_fog_b.y * exp(-min(_548_fa_fog_b.w * _6376, 80.0f));\n                }\n                bool _6419;\n                if (_6385)\n                {\n                    _6419 = _548_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6419 = _6384;\n                }\n                float _6420;\n                if (_6419)\n                {\n                    _6420 = _548_fa_fog_b.y * _6376;\n                }\n                else\n                {\n                    _6420 = (_548_fa_fog_b.y * (1.0f - exp(-min(_548_fa_fog_b.w * _6376, 80.0f)))) / _548_fa_fog_b.w;\n                }\n                bool _6445 = _6381 <= 0.0f;\n                bool _6452;\n                if (!_6445)\n                {\n                    _6452 = _548_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6452 = _6445;\n                }\n                float _6453;\n                if (_6452)\n                {\n                    _6453 = _548_fa_fog_b.y * _6381;\n                }\n                else\n                {\n                    _6453 = (_548_fa_fog_b.y * (1.0f - exp(-min(_548_fa_fog_b.w * _6381, 80.0f)))) / _548_fa_fog_b.w;\n                }\n                float _6480;\n                if (abs(_6371) < 0.001000000047497451305389404296875f)\n                {\n                    _6480 = _6392;\n                }\n                else\n                {\n                    _6480 = (_6453 - _6420) / _6371;\n                }\n                tau += (_6321 * max(_6480, 0.0f));\n            }\n            result = lerp(result, _548_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _6556);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_45",
            "hlsl_register_b_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_145",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_548",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2215",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_material_vs : register(b4)\n{\n    float3 _50_offset : packoffset(c0);\n    float _50_fa_pad0 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _150_fa_view_proj : packoffset(c0);\n    row_major float4x4 _150_fa_light_vp : packoffset(c4);\n    float4 _150_fa_uv_scale : packoffset(c8);\n    float4 _150_fa_time : packoffset(c9);\n    float4 _150_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _197_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _188 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_197_fa_joint_rows[_188] * weights[i]);\n        r1 += (_197_fa_joint_rows[_188 + 1] * weights[i]);\n        r2 += (_197_fa_joint_rows[_188 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _88 = cross(model[1].xyz, model[2].xyz);\n    float _94 = (dot(model[0].xyz, _88) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _399 = { mul(float4(position, 1.0f), model).xyz, (((_88 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _94, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _94), texcoord0 * _150_fa_uv_scale.xy, color, position };\n    return _399;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos += _50_offset;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _150_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _3645[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _548_fa_camera_pos : packoffset(c0);\n    float4 _548_fa_ambient : packoffset(c1);\n    float4 _548_fa_base_color : packoffset(c2);\n    float4 _548_fa_emissive : packoffset(c3);\n    float4 _548_fa_model_emissive : packoffset(c4);\n    float4 _548_fa_pbr : packoffset(c5);\n    float4 _548_fa_maps : packoffset(c6);\n    float4 _548_fa_fog : packoffset(c7);\n    float4 _548_fa_fog_b : packoffset(c8);\n    float4 _548_fa_fog_c : packoffset(c9);\n    float4 _548_fa_counts : packoffset(c10);\n    float4 _548_fa_env_sky : packoffset(c11);\n    float4 _548_fa_env_horizon : packoffset(c12);\n    float4 _548_fa_time : packoffset(c13);\n    float4 _548_fa_cl_vpx : packoffset(c14);\n    float4 _548_fa_cl_vpy : packoffset(c15);\n    float4 _548_fa_cl_vpw : packoffset(c16);\n    float4 _548_fa_cl_fwd : packoffset(c17);\n    float4 _548_fa_cl_grid : packoffset(c18);\n    float4 _548_fa_cl_info : packoffset(c19);\n    float4 _548_fa_layers_a : packoffset(c20);\n    float4 _548_fa_layers_b : packoffset(c21);\n    float4 _548_fa_layers_c : packoffset(c22);\n    float4 _548_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2215_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2215_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2215_fa_shadow_info[4] : packoffset(c20);\n    float4 _2215_fa_shadow_split : packoffset(c24);\n    float4 _2215_fa_shadow_cfg : packoffset(c25);\n    float4 _2215_fa_shadow_bias : packoffset(c26);\n    float4 _2215_fa_shadow_eye : packoffset(c27);\n    float4 _2215_fa_shadow_fwd : packoffset(c28);\n    float4 _2215_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1486 = _548_fa_cl_info.x < 0.0f;\n    bool _1493;\n    if (!_1486)\n    {\n        _1493 = _548_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1493 = _1486;\n    }\n    bool _1501;\n    if (!_1493)\n    {\n        _1501 = _548_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1501 = _1493;\n    }\n    bool _1508;\n    if (!_1501)\n    {\n        _1508 = _548_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1508 = _1501;\n    }\n    bool _1515;\n    if (!_1508)\n    {\n        _1515 = _548_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1515 = _1508;\n    }\n    if (_1515)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1525 = float4(world_pos, 1.0f);\n    float _1531 = dot(_548_fa_cl_vpw, _1525);\n    if (!(_1531 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1553 = float2(dot(_548_fa_cl_vpx, _1525), dot(_548_fa_cl_vpy, _1525)) / _1531.xx;\n    int _1557 = int(_548_fa_cl_grid.x);\n    int _1561 = int(_548_fa_cl_grid.y);\n    int param = (int(_548_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_548_fa_cl_fwd.xyz, world_pos) + _548_fa_cl_fwd.w, _548_fa_cl_grid.w) / _548_fa_cl_grid.w) * _548_fa_cl_grid.z)), 0, int(_548_fa_cl_info.y) - 1) * _1561) + clamp(int(floor(((_1553.y * 0.5f) + 0.5f) * _548_fa_cl_grid.y)), 0, _1561 - 1)) * _1557)) + clamp(int(floor(((_1553.x * 0.5f) + 0.5f) * _548_fa_cl_grid.x)), 0, _1557 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1637 = fa_cluster_texel(param);\n    return int2(int(_1637.x), int(_1637.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_548_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4464 = fa_cluster_lookup(param);\n    fa_cl_slot = _4464.x;\n    fa_cl_local = _4464.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _5549 = fa_linear_to_srgb(param);\n        c = _5549;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _5557 = fa_srgb_to_linear(param_1);\n            c = _5557;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _431;\n    if (i.front_facing)\n    {\n        _431 = i.world_normal;\n    }\n    else\n    {\n        _431 = -i.world_normal;\n    }\n    float3 _455 = normalize(i.world_tangent.xyz - (_431 * dot(_431, i.world_tangent.xyz)));\n    float3 _482 = normalize(((_455 * m.x) + ((cross(_431, _455) * i.world_tangent.w) * m.y)) + (_431 * m.z));\n    float3 _485;\n    if (i.front_facing)\n    {\n        _485 = _482;\n    }\n    else\n    {\n        _485 = -_482;\n    }\n    return _485;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _548_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _5588 = fa_tex_fix(param_2, param_3);\n    float4 _7006 = base_t;\n    _7006.x = _5588.x;\n    _7006.y = _5588.y;\n    _7006.z = _5588.z;\n    base_t = _7006;\n    float4 _5602 = (_7006 * _548_fa_base_color) * i.vertex_color;\n    float3 _6844 = i.world_normal;\n    if (_548_fa_maps.z > 0.5f)\n    {\n        float param_4 = _548_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _5634 = fa_tex_fix(param_6, param_7);\n        float3 _5637 = (_5634 * 2.0f) - 1.0f.xxx;\n        float2 _5642 = _5637.xy * _548_fa_maps.x;\n        float3 _7014 = _5637;\n        _7014.x = _5642.x;\n        _7014.y = _5642.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _7014;\n        _6844 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _548_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _5670 = fa_tex_fix(param_12, param_13);\n    float4 _7017 = mrt;\n    _7017.x = _5670.x;\n    _7017.y = _5670.y;\n    _7017.z = _5670.z;\n    mrt = _7017;\n    float4 _5698 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _548_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _5698.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _5709 = fa_tex_fix(param_16, param_17);\n    float param_18 = _548_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _5739 = fa_tex_fix(param_20, param_21);\n    float _6849 = _548_fa_layers_a.x;\n    float _6850 = _548_fa_layers_a.y;\n    float _6853 = _548_fa_layers_a.z;\n    float _6852 = _548_fa_layers_b.w;\n    float _6855 = _548_fa_layers_c.x;\n    if (_548_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_548_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _6849 *= _5709.y;\n            _6850 *= _5709.z;\n            _6852 *= _5698.w;\n        }\n        if (_548_fa_layers_c.z > 1.5f)\n        {\n            _6853 *= mrt.x;\n            _6855 *= mrt.w;\n        }\n    }\n    Surface _6874 = { _5602.xyz, _5602.w, _6844, clamp(_548_fa_pbr.x * _5670.z, 0.0f, 1.0f), clamp(_548_fa_pbr.y * _5670.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_548_fa_maps.y * (_5709.x - 1.0f)), _548_fa_emissive.xyz + (_548_fa_model_emissive.xyz * _5739), _6849, _6850, _548_fa_layers_b.xyz, _6852, _6853, _548_fa_layers_a.w, _6855, _548_fa_layers_c.y, _548_fa_layers_d.xyz };\n    return _6874;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1717 = rect.zw - rect.xy;\n    float2 _1721 = _1717 * atlas;\n    float2 _1725 = ddx * _1721;\n    float2 _1729 = ddy * _1721;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1717), clamp(0.5f * log2(max(max(dot(_1725, _1725), dot(_1729, _1729)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1762 = _548_fa_counts.y < 0.5f;\n    bool _1769;\n    if (!_1762)\n    {\n        _1769 = _548_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1769 = _1762;\n    }\n    if (_1769)\n    {\n        return;\n    }\n    float3 _1775 = ddx(world_pos);\n    float3 _1778 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1782 = fa_cluster_texel(param);\n    int _1786 = int(_1782.w);\n    if (_1786 < 1)\n    {\n        return;\n    }\n    int _1796 = int(_548_fa_counts.y + 0.5f);\n    int param_1 = _1796;\n    float4 _1800 = fa_light_texel(param_1);\n    float2 _1803 = _1800.yz;\n    int _1807 = int(_1800.w);\n    int param_2 = _1796 + 1;\n    float4 _1812 = fa_light_texel(param_2);\n    float _1813 = _1812.x;\n    int _1819 = int(_548_fa_counts.w + 0.5f) - 1;\n    int _1823 = int(_1782.z);\n    float3 _2088;\n    for (int k = 0; k < _1786; k++)\n    {\n        int _1836 = _1823 + k;\n        int param_3 = _1807 + (_1836 >> 2);\n        int _1853 = (_1796 + 2) + (int(fa_light_texel(param_3)[_1836 & 3]) * 7);\n        int param_4 = _1853 + 6;\n        float4 _1858 = fa_light_texel(param_4);\n        if (((int(_1858.w + 0.5f) >> _1819) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1853;\n        float4 _1873 = fa_light_texel(param_5);\n        int param_6 = _1853 + 1;\n        float4 _1878 = fa_light_texel(param_6);\n        int param_7 = _1853 + 2;\n        float4 _1883 = fa_light_texel(param_7);\n        float3 _1886 = _1873.xyz;\n        float _1891 = dot(_1886, world_pos) + _1873.w;\n        float3 _1893 = _1878.xyz;\n        float _1898 = dot(_1893, world_pos) + _1878.w;\n        float3 _1900 = _1883.xyz;\n        float _1905 = dot(_1900, world_pos) + _1883.w;\n        bool _1910 = abs(_1891) > 0.5f;\n        bool _1918;\n        if (!_1910)\n        {\n            _1918 = abs(_1898) > 0.5f;\n        }\n        else\n        {\n            _1918 = _1910;\n        }\n        bool _1926;\n        if (!_1918)\n        {\n            _1926 = abs(_1905) > 0.5f;\n        }\n        else\n        {\n            _1926 = _1918;\n        }\n        if (_1926)\n        {\n            continue;\n        }\n        float _1941 = clamp(dot(geo_normal, normalize(_1900)) * _1858.z, 0.0f, 1.0f);\n        if (_1941 <= 0.0f)\n        {\n            continue;\n        }\n        float _1961 = (clamp((0.5f - abs(_1905)) * 10.0f, 0.0f, 1.0f) * _1941) * _1858.x;\n        float2 _1969 = float2(_1891 + 0.5f, 0.5f - _1898);\n        float2 _1979 = float2(dot(_1886, _1775), dot(_1893, _1775));\n        float2 _1989 = float2(dot(_1886, _1778), dot(_1893, _1778));\n        int param_8 = _1853 + 5;\n        float4 _1994 = fa_light_texel(param_8);\n        int param_9 = _1853 + 3;\n        float4 _1999 = fa_light_texel(param_9);\n        int param_10 = _1853 + 4;\n        float4 _2004 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1994.xyz;\n        bool _2014 = _1999.z > _1999.x;\n        if (_2014)\n        {\n            float4 param_11 = _1999;\n            float2 param_12 = _1969;\n            float2 param_13 = _1803;\n            float2 param_14 = _1979;\n            float2 param_15 = _1989;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1813 > 0.5f) && (_1813 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _2040 = fa_dc_to_linear(param_16);\n                float4 _6924 = tx;\n                _6924.x = _2040.x;\n                _6924.y = _2040.y;\n                _6924.z = _2040.z;\n                tx = _6924;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1961 * tex_a) * _1994.w, 0.0f, 1.0f).xxx);\n        if (_2004.z > _2004.x)\n        {\n            float4 param_17 = _2004;\n            float2 param_18 = _1969;\n            float2 param_19 = _1803;\n            float2 param_20 = _1979;\n            float2 param_21 = _1989;\n            float4 _2084 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1813 > 1.5f)\n            {\n                float3 param_22 = _2084.xyz;\n                float3 _2094 = fa_dc_to_srgb(param_22);\n                _2088 = _2094;\n            }\n            else\n            {\n                _2088 = _2084.xyz;\n            }\n            float3 _2103 = (_2088 * 2.0f) - 1.0f.xxx;\n            float2 _2108 = _2103.xy * _1858.y;\n            float3 _2130 = (normalize(_1886) * _2108.x) + (normalize(_1893) * _2108.y);\n            float3 _2133 = normalize(normal);\n            normal = normalize(lerp(_2133, normalize((_2133 * max(_2103.z, 0.0500000007450580596923828125f)) + (_2130 - (_2133 * dot(_2133, _2130)))), clamp(_1961 * (_2014 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3571 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3578 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3581 = int(_3571);\n    int _3584 = int(_3578);\n    float _3594 = _3578 - float(_3584);\n    int _3649 = (_3581 * 9) + _3584;\n    int _3669 = ((_3581 + 1) * 9) + _3584;\n    return lerp(lerp(_3645[_3649], _3645[_3649 + 1], _3594), lerp(_3645[_3669], _3645[_3669 + 1], _3594), _3571 - float(_3581));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _6767 = false;\n    float _6768 = 1.0f;\n    float _6769 = 1.0f;\n    float _6770 = 1.0f;\n    float _6771 = 0.0f;\n    float _6772 = 0.0f;\n    float _6773 = 0.0f;\n    float _6774 = 0.0f;\n    float _6776 = 1.0f;\n    bool _6777 = false;\n    float3 _6778 = 0.0f.xxx;\n    float _6779 = 1.0f;\n    float _6780 = 1.0f;\n    float _6781 = 1.0f;\n    float _6782 = 0.0f;\n    float _6783 = 0.0f;\n    float3 _6784 = float3(1.0f, 0.0f, 0.0f);\n    float3 _6785 = float3(0.0f, 0.0f, 1.0f);\n    float _6786 = 1.0f;\n    float _6787 = 1.0f;\n    float _3720 = clamp(s.specular, 0.0f, 1.0f);\n    float _3724 = clamp(s.ior, 1.0f, 3.0f);\n    bool _3729 = (_3720 != 1.0f) || (_3724 != 1.5f);\n    bool _3738;\n    if (!_3729)\n    {\n        _3738 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _3738 = _3729;\n    }\n    if (_3738)\n    {\n        float _3746 = (_3724 - 1.0f) / (_3724 + 1.0f);\n        f0 = lerp(min((_3746 * _3746).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _3720, s.albedo, metallic.xxx);\n        _6768 = lerp(_3720, 1.0f, metallic);\n        _6767 = true;\n    }\n    float _3773 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_3773 > 0.0f)\n    {\n        float _3781 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _6771 = _3773;\n        _6772 = _3781;\n        float _3788 = _3781 * _3781;\n        _6773 = _3788;\n        _6774 = _3788 * _3788;\n        float _3800 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _6776 = _3800;\n        _6769 = 1.0f - (_3773 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _3800, 0.0f, 1.0f), 5.0f))));\n        _6767 = true;\n    }\n    float3 _3819 = max(s.sheen_color, 0.0f.xxx);\n    float _3828 = max(_3819.x, max(_3819.y, _3819.z));\n    if (_3828 > 0.0f)\n    {\n        float _3836 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _6777 = true;\n        _6778 = _3819;\n        _6779 = _3836;\n        _6780 = _3836 * _3836;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _3836;\n        float _3853 = fa_sheen_albedo(param, param_1);\n        _6782 = _3853;\n        _6781 = 1.0f - min(_3828 * _3853, 1.0f);\n        _6767 = true;\n    }\n    _6770 = _6769 * _6781;\n    float _3872 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_3872 != 0.0f)\n    {\n        float3 _3887 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _3887;\n        if (dot(_3887, _3887) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _3899 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_3899.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _3899.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _3899.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _3903 = t;\n        float3 _3904 = normalize(_3903);\n        t = _3904;\n        float3 _3929 = normalize((_3904 * cos(s.anisotropy_rotation)) + ((cross(n, _3904) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _6784 = _3929;\n        _6785 = cross(n, _3929);\n        float _3939 = roughness * roughness;\n        float _3945 = lerp(_3939, 1.0f, _3872 * _3872);\n        bool _3947 = _3872 > 0.0f;\n        _6786 = _3947 ? _3945 : _3939;\n        _6787 = _3947 ? _3939 : _3945;\n        _6783 = _3872;\n        _6767 = true;\n    }\n    FaLayers _6809 = { _6767, _6768, _6769, _6770, _6771, _6772, _6773, _6774, i.world_normal, _6776, _6777, _6778, _6779, _6780, _6781, _6782, _6783, _6784, _6785, _6786, _6787 };\n    return _6809;\n}\n\nfloat3 fa_sky_sh_coef(int k)\n{\n    float3 v = fa_env_tex.SampleLevel(fa_env_smp, float3(1.0f, 1.0f - (float((2 * (k >> 2)) + 1) * 0.25f), 1.0f - (float((2 * (k & 3)) + 1) * 0.25f)), 5.0f).xyz;\n    if (_548_fa_env_sky.w > 1.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3328 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3328;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_548_fa_env_sky.w > 0.5f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _548_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_548_fa_cl_info.x) + int(_548_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_548_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _616_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _616_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _735 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _748 = (c - (ru * hx)) - p;\n        float3 _754 = ru * (2.0f * hx);\n        float _760 = max(dot(_754, _754), 9.9999999392252902907785028219223e-09f);\n        float _764 = dot(_748, _754);\n        float t = clamp((-_764) / _760, 0.0f, 1.0f);\n        if (_735)\n        {\n            float _779 = dot(r, _754);\n            float _785 = _760 - (_779 * _779);\n            if (abs(_785) > (9.9999997473787516355514526367188e-06f * _760))\n            {\n                t = clamp(((dot(r, _748) * _779) - _764) / _785, 0.0f, 1.0f);\n            }\n        }\n        return (p + _748) + (_754 * t);\n    }\n    float3 q = p;\n    float _817 = dot(r, axis);\n    bool _825;\n    if (_735)\n    {\n        _825 = abs(_817) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _825 = _735;\n    }\n    if (_825)\n    {\n        float _835 = dot(c - p, axis) / _817;\n        if (_835 > 0.0f)\n        {\n            q = p + (r * _835);\n        }\n    }\n    float3 _848 = q - c;\n    float2 xy = float2(dot(_848, ru), dot(_848, uu));\n    if (shape > 0.5f)\n    {\n        float _863 = length(xy);\n        if (_863 > hx)\n        {\n            xy *= (hx / _863);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _497 = abs(d);\n    float _499 = _497.x;\n    float _501 = _497.y;\n    bool _502 = _499 >= _501;\n    bool _510;\n    if (_502)\n    {\n        _510 = _499 >= _497.z;\n    }\n    else\n    {\n        _510 = _502;\n    }\n    int _511;\n    if (_510)\n    {\n        _511 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _526;\n        if (_501 >= _497.z)\n        {\n            _526 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _526 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _511 = _526;\n    }\n    return _511;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _655 = dot(d, right);\n    float _659 = dot(d, up);\n    float _670;\n    if (((_655 * _655) + (_659 * _659)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _670 = atan2(_659, _655) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _670 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_670 - floor(_670)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _901 = fa_light_base(param);\n    bool _905 = _548_fa_ambient.w > 4.5f;\n    int param_1 = _901;\n    float4 _909 = fa_light_texel(param_1);\n    int param_2 = _901 + 1;\n    float4 _914 = fa_light_texel(param_2);\n    float _917 = _914.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _929 = _905 && (_917 > 2.5f);\n    fa_light_is_area = _929;\n    bool _931 = _917 < 0.5f;\n    float3 l;\n    if (_931)\n    {\n        l = normalize(_909.xyz);\n        if (_905)\n        {\n            int param_3 = _901 + 6;\n            float4 _945 = fa_light_texel(param_3);\n            if (_945.z > 0.5f)\n            {\n                int param_4 = _901 + 4;\n                float4 _955 = fa_light_texel(param_4);\n                int param_5 = _901 + 5;\n                float4 _960 = fa_light_texel(param_5);\n                float2 param_6 = _945.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _955.xyz) * _955.w, (-dot(world_pos, _960.xyz)) * _960.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _990 = _909.xyz;\n        float3 _992 = _990 - world_pos;\n        float3 to_light = _992;\n        float _995 = length(_992);\n        float reach = _995;\n        bool front = true;\n        if (_929)\n        {\n            int param_8 = _901 + 7;\n            reach = max(_995 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _901 + 4;\n            float4 _1019 = fa_light_texel(param_9);\n            int param_10 = _901 + 5;\n            float4 _1024 = fa_light_texel(param_10);\n            int param_11 = _901 + 6;\n            float4 _1029 = fa_light_texel(param_11);\n            float _1030 = _1029.w;\n            int param_12 = _901 + 2;\n            float3 _1037 = normalize(fa_light_texel(param_12).xyz);\n            bool _1039 = _1030 > 1.5f;\n            bool _1047;\n            if (!_1039)\n            {\n                _1047 = dot(_1037, to_light) < 0.0f;\n            }\n            else\n            {\n                _1047 = _1039;\n            }\n            front = _1047;\n            float3 r = 0.0f.xxx;\n            float3 _1056 = _548_fa_camera_pos.xyz - world_pos;\n            bool _1060 = dot(n, n) > 0.5f;\n            bool _1068;\n            if (_1060)\n            {\n                _1068 = dot(_1056, _1056) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _1068 = _1060;\n            }\n            if (_1068)\n            {\n                r = reflect(-normalize(_1056), normalize(n));\n            }\n            float3 param_13 = _990;\n            float3 param_14 = _1037;\n            float3 param_15 = _1019.xyz;\n            float3 param_16 = _1024.xyz;\n            float param_17 = _1019.w;\n            float param_18 = _1024.w;\n            float param_19 = _1030;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1104 = length(to_light);\n        dist = _1104;\n        l = to_light / max(_1104, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1118 = reach / max(_909.w, 0.001000000047497451305389404296875f);\n        float _1124 = clamp(1.0f - (_1118 * _1118), 0.0f, 1.0f);\n        float _1126;\n        if (front)\n        {\n            _1126 = _1124 * _1124;\n        }\n        else\n        {\n            _1126 = 0.0f;\n        }\n        atten = _1126;\n        bool _1137 = _917 < 2.5f;\n        if ((_917 > 1.5f) && _1137)\n        {\n            int param_22 = _901 + 2;\n            float4 _1145 = fa_light_texel(param_22);\n            float _1155 = _1145.w;\n            int param_23 = _901 + 3;\n            float4 _1160 = fa_light_texel(param_23);\n            float _1161 = _1160.x;\n            float cos_inner = _1161;\n            if (_1161 > 1.5f)\n            {\n                cos_inner = lerp(_1155, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1155, cos_inner, dot(-l, normalize(_1145.xyz)));\n        }\n        if (_905 && (_917 < 1.5f))\n        {\n            int param_24 = _901 + 6;\n            float4 _1185 = fa_light_texel(param_24);\n            if (_1185.z > 0.5f)\n            {\n                float3 _1193 = -to_light;\n                int param_25 = _901 + 4;\n                int param_26 = _901 + 5;\n                float3 _1207 = fa_light_texel(param_25).xyz;\n                float3 _1211 = fa_light_texel(param_26).xyz;\n                float3 _1220 = float3(dot(_1193, _1207), dot(_1193, _1211), dot(_1193, cross(_1207, _1211)));\n                float3 param_27 = _1220;\n                int _1224 = fa_cube_face(param_27);\n                int param_28 = _1224;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1251 = float2(dot(_1220, cross(param_29, param_30)), dot(_1220, param_30)) / max(dot(_1220, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1255 = _1224 / 3;\n                float2 param_31 = _1185.xy + (float2(float(_1224 - (_1255 * 3)), float(_1255)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1251.x), 0.5f - (0.5f * _1251.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _901 + 7;\n            float4 _1285 = fa_light_texel(param_33);\n            if (_1285.z > 0.5f)\n            {\n                int param_34 = _901 + 2;\n                int param_35 = _901 + 4;\n                int param_36 = _901 + 5;\n                float2 param_37 = _1285.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_905 && _1137)\n            {\n                int param_42 = _901 + 6;\n                float4 _1332 = fa_light_texel(param_42);\n                int param_43 = _901 + 7;\n                float4 _1337 = fa_light_texel(param_43);\n                bool _1340 = _1332.z > 0.5f;\n                bool _1347;\n                if (!_1340)\n                {\n                    _1347 = _1337.z > 0.5f;\n                }\n                else\n                {\n                    _1347 = _1340;\n                }\n                if (_1347)\n                {\n                    int param_44 = _901 + 2;\n                    float4 _1354 = fa_light_texel(param_44);\n                    float3 _1358 = normalize(_1354.xyz);\n                    int param_45 = _901 + 4;\n                    float4 _1363 = fa_light_texel(param_45);\n                    int param_46 = _901 + 5;\n                    float4 _1368 = fa_light_texel(param_46);\n                    if (_1340)\n                    {\n                        float3 _1376 = -to_light;\n                        float _1383 = _1354.w;\n                        float _1399 = 0.5f / max(dot(_1376, _1358) * (sqrt(max(1.0f - (_1383 * _1383), 0.0f)) / max(_1383, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1332.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1376, _1363.xyz) * _1399), 0.5f - (dot(_1376, _1368.xyz) * _1399));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1337.z > 0.5f)\n                    {\n                        float2 param_49 = _1337.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1358;\n                        float3 param_52 = _1363.xyz;\n                        float3 param_53 = _1368.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _6755 = _914.xyz * atten;\n    if (_905)\n    {\n        _6755 *= fa_light_tint;\n    }\n    int _1468;\n    if (_931)\n    {\n        _1468 = 0;\n    }\n    else\n    {\n        _1468 = ((_917 > 1.5f) && (_917 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _6766 = { l, _6755, atten, 1.0f, dist, _1468 };\n    return _6766;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2205;\n    if (i == 0)\n    {\n        _2205 = _2215_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2221;\n        if (i == 1)\n        {\n            _2221 = _2215_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2229;\n            if (i == 2)\n            {\n                _2229 = _2215_fa_shadow_split.z;\n            }\n            else\n            {\n                _2229 = _2215_fa_shadow_split.w;\n            }\n            _2221 = _2229;\n        }\n        _2205 = _2221;\n    }\n    return _2205;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2262 = fa_shadow_depth(param, param_1);\n    float _2266;\n    if (conv.x < 0.5f)\n    {\n        _2266 = _2262;\n    }\n    else\n    {\n        _2266 = (conv.y * conv.z) / (conv.z - (_2262 * (conv.z - conv.y)));\n    }\n    return _2266;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2193 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2193), sin(_2193)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2312 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2321;\n        if (k < 0.0f)\n        {\n            _2321 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2321 = k;\n        }\n        float _2341 = clamp((_2321 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2312;\n            float2 _2360 = fa_shadow_vogel(param_3, param_4, param_5) * _2341;\n            float2 param_6 = uv + (_2360 * _2215_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2372 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2372 < (zr - (length(_2360) * plane)))\n            {\n                sum += _2372;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2398 = sum / cnt;\n        float _2408;\n        if (k < 0.0f)\n        {\n            _2408 = (-k) / max(_2398, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2408 = k;\n        }\n        radius = clamp(((max(zr - _2398, 0.0f) * unit) * _2408) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2430 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2430; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2430;\n        float param_11 = _2312;\n        float2 _2449 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2449 * _2215_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2449) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2430);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2491 = max(_2215_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2496 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2502 = sqrt(1.0f - (_2496 * _2496));\n    float _2509 = min(_2502 / max(_2496, 0.20000000298023223876953125f), 4.0f);\n    float _2514;\n    if (_2215_fa_shadow_bias.y > 0.0f)\n    {\n        _2514 = _2215_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2514 = 1.5f * _2215_fa_shadow_info[ci].x;\n    }\n    float4 _2539 = mul(float4(world + (n * (_2514 * _2502)), 1.0f), _2215_fa_shadow_mat[ci]);\n    float _2546 = _2539.x;\n    bool _2549 = _2546 < _2215_fa_shadow_rect[ci].x;\n    bool _2558;\n    if (!_2549)\n    {\n        _2558 = _2546 > _2215_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2558 = _2549;\n    }\n    bool _2567;\n    if (!_2558)\n    {\n        _2567 = _2539.y < _2215_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2567 = _2558;\n    }\n    bool _2576;\n    if (!_2567)\n    {\n        _2576 = _2539.y > _2215_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2576 = _2567;\n    }\n    bool _2583;\n    if (!_2576)\n    {\n        _2583 = _2539.z > 1.0f;\n    }\n    else\n    {\n        _2583 = _2576;\n    }\n    if (_2583)\n    {\n        return -1.0f;\n    }\n    float _2591;\n    if (_2215_fa_shadow_bias.x > 0.0f)\n    {\n        _2591 = _2215_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2591 = 1.5f * _2215_fa_shadow_info[ci].x;\n    }\n    float2 param = _2539.xy;\n    float4 param_1 = _2215_fa_shadow_rect[ci];\n    float param_2 = _2539.z - ((_2591 * (1.0f + (0.5f * _2509))) / _2491);\n    float param_3 = _2215_fa_shadow_info[ci].x;\n    float param_4 = _2491;\n    float param_5 = _2491 * 0.25f;\n    float param_6 = ((_2215_fa_shadow_info[ci].x * min(_2509, 3.0f)) * 0.5f) / _2491;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2215_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2215_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_548_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2969 = int(_2215_fa_shadow_cfg.x + 0.5f);\n    if (_2969 < 1)\n    {\n        return 1.0f;\n    }\n    float _2984 = dot(world - _2215_fa_shadow_eye.xyz, _2215_fa_shadow_fwd.xyz);\n    int param = _2969 - 1;\n    if (_2984 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2996 = _2969 > 1;\n    bool _3003;\n    if (_2996)\n    {\n        _3003 = _2984 > _2215_fa_shadow_split.x;\n    }\n    else\n    {\n        _3003 = _2996;\n    }\n    if (_3003)\n    {\n        ci = 1;\n    }\n    bool _3007 = _2969 > 2;\n    bool _3014;\n    if (_3007)\n    {\n        _3014 = _2984 > _2215_fa_shadow_split.y;\n    }\n    else\n    {\n        _3014 = _3007;\n    }\n    if (_3014)\n    {\n        ci = 2;\n    }\n    bool _3018 = _2969 > 3;\n    bool _3025;\n    if (_3018)\n    {\n        _3025 = _2984 > _2215_fa_shadow_split.z;\n    }\n    else\n    {\n        _3025 = _3018;\n    }\n    if (_3025)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2969)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _3051 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3051;\n        if (_3051 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2215_fa_shadow_cfg.y > 0.0f)\n    {\n        float _3076;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3076 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3076 = _2215_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _3095 = _2215_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3076, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _3106 = clamp((_2984 - (fa_shadow_split_at(param_7) - _3095)) / _3095, 0.0f, 1.0f);\n        if (_3106 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2969)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _3127 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3127;\n                if (_3127 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _3106);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2649 = _548_fa_pbr.z < 0.5f;\n    bool _2656;\n    if (!_2649)\n    {\n        _2656 = _2215_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2656 = _2649;\n    }\n    if (_2656)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2215_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2669 = fa_light_texel(param);\n    float _2670 = _2669.x;\n    if (_2670 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2679 = int(_2670 + 0.5f);\n    int param_1 = _2679;\n    float4 _2683 = fa_light_texel(param_1);\n    int param_2 = _2679 + 1;\n    float4 _2688 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2691 = _2683.y;\n    if (_2691 > 0.0f)\n    {\n        float _2708 = 1.0f - smoothstep(0.75f * _2691, _2691, length(world - _2215_fa_shadow_eye.xyz));\n        fade = _2708;\n        if (_2708 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2683.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2732 = (_2679 + 2) + (face * 6);\n    int param_4 = _2732;\n    int param_5 = _2732 + 1;\n    int param_6 = _2732 + 3;\n    float4 _2746 = fa_light_texel(param_6);\n    int param_7 = _2732 + 4;\n    float4 _2751 = fa_light_texel(param_7);\n    int param_8 = _2732 + 5;\n    float4 _2756 = fa_light_texel(param_8);\n    float _2768 = _2756.x * max(dot(_2746, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2773 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2796 = clamp(dot(n, _2746.xyz), -1.0f, 1.0f);\n    float _2815 = min(sqrt(1.0f - (_2796 * _2796)) / max(abs(dot(n, world - lpos)) / max(dot(_2746, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2818 = _2688.y;\n    float _2820;\n    if (_2818 > 0.0f)\n    {\n        _2820 = _2818;\n    }\n    else\n    {\n        _2820 = 1.5f * _2768;\n    }\n    float4 _2840 = float4(world + (n * (_2820 * sqrt(1.0f - (_2773 * _2773)))), 1.0f);\n    float _2844 = dot(_2746, _2840);\n    float _2847 = _2756.y;\n    if (_2844 < _2847)\n    {\n        return 1.0f;\n    }\n    float2 _2862 = float2(dot(fa_light_texel(param_4), _2840), dot(fa_light_texel(param_5), _2840)) / _2844.xx;\n    float _2864 = _2862.x;\n    bool _2867 = _2864 < _2751.x;\n    bool _2876;\n    if (!_2867)\n    {\n        _2876 = _2864 > _2751.z;\n    }\n    else\n    {\n        _2876 = _2867;\n    }\n    bool _2885;\n    if (!_2876)\n    {\n        _2885 = _2862.y < _2751.y;\n    }\n    else\n    {\n        _2885 = _2876;\n    }\n    bool _2894;\n    if (!_2885)\n    {\n        _2894 = _2862.y > _2751.w;\n    }\n    else\n    {\n        _2894 = _2885;\n    }\n    if (_2894)\n    {\n        return 1.0f;\n    }\n    float _2900 = _2688.x;\n    float _2902;\n    if (_2900 > 0.0f)\n    {\n        _2902 = _2900;\n    }\n    else\n    {\n        _2902 = 1.5f * _2768;\n    }\n    float2 param_9 = _2862;\n    float4 param_10 = _2751;\n    float param_11 = _2844 - (_2902 * (1.0f + (0.5f * _2815)));\n    float param_12 = _2768;\n    float param_13 = 1.0f;\n    float param_14 = _2756.z * 0.25f;\n    float param_15 = (_2768 * min(_2815, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2847, _2756.z);\n    int param_17 = int(_2683.z + 0.5f);\n    float param_18 = _2683.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _4491 = fa_lm.z > 0.5f;\n    bool _4497;\n    if (_4491)\n    {\n        int param = li;\n        _4497 = fa_light_baked(param);\n    }\n    else\n    {\n        _4497 = _4491;\n    }\n    if (_4497)\n    {\n        int param_1 = li;\n        LightSample _6822 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _6822;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4521 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _6824 = _4521.color;\n    float _6826 = _4521.shadow;\n    if ((_4521.type == 0) && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4521.direction;\n        float _4535 = fa_shadow_factor(param_5, param_6);\n        _6826 = _4535;\n        _6824 *= _4535;\n    }\n    else\n    {\n        bool _4546 = _4521.type != 0;\n        bool _4552;\n        if (_4546)\n        {\n            _4552 = _4521.attenuation > 0.0f;\n        }\n        else\n        {\n            _4552 = _4546;\n        }\n        if (_4552)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _4521.direction;\n            float _4571 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _6826 = _4571;\n            _6824 *= _4571;\n        }\n    }\n    LightSample _6841 = { _4521.direction, _6824, _4521.attenuation, _6826, _4521._distance, _4521.type };\n    return _6841;\n}\n\nfloat3 fa_ltc_tangent(float3 n, float3 v)\n{\n    float3 _4611 = v - (n * dot(v, n));\n    float3 t = _4611;\n    float _4615 = dot(_4611, _4611);\n    float l2 = _4615;\n    if (_4615 < 1.0000000133514319600180897396058e-10f)\n    {\n        float3 _4625;\n        if (abs(n.z) < 0.999000012874603271484375f)\n        {\n            _4625 = cross(n, float3(0.0f, 0.0f, 1.0f));\n        }\n        else\n        {\n            _4625 = cross(n, float3(1.0f, 0.0f, 0.0f));\n        }\n        t = _4625;\n        l2 = dot(_4625, _4625);\n    }\n    return t * rsqrt(l2);\n}\n\nfloat3 fa_ltc_local(float3 t1, float3 n, float3 p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nfloat3 fa_ltc_edge_vector(float3 a, float3 b)\n{\n    float _4660 = dot(a, a);\n    float _4664 = dot(b, b);\n    if ((_4660 < 1.0000000195414813782625560981111e-24f) || (_4664 < 1.0000000195414813782625560981111e-24f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _4678 = a * rsqrt(_4660);\n    float3 _4683 = b * rsqrt(_4664);\n    float _4687 = dot(_4678, _4683);\n    float _4690 = abs(_4687);\n    float g = (((((((((((0.0416471660137176513671875f * _4690) - 0.1924748718738555908203125f) * _4690) + 0.4179156124591827392578125f) * _4690) - 0.616057217121124267578125f) * _4690) + 0.777722418308258056640625f) * _4690) - 0.999542415142059326171875f) * _4690) + 1.570791721343994140625f;\n    if (_4687 < 0.0f)\n    {\n        g = (3.1415927410125732421875f * rsqrt(max(1.0f - (_4687 * _4687), 1.0000000116860974230803549289703e-07f))) - g;\n    }\n    return cross(_4678, _4683) * g;\n}\n\nvoid fa_ltc_clip_edge(float3 a, float3 b, inout float3 sum, inout float3 leave, inout float3 enter, inout float2 seen)\n{\n    bool _4747 = a.z > 0.0f;\n    bool _4751 = b.z > 0.0f;\n    if (_4747 && _4751)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_4747 != _4751)\n        {\n            float3 _4786 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _4786.z = 0.0f;\n            if (_4747)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _4786;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _4786;\n                seen.x = 1.0f;\n            }\n            else\n            {\n                float3 param_4 = _4786;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _4786;\n                seen.y = 1.0f;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(float4 abcd, float3 p0, float3 p1, float3 p2, float3 p3)\n{\n    float3 _4835 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _4861 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _4887 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _4913 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = 0.0f.xxx;\n    float3 leave = 0.0f.xxx;\n    float3 enter = 0.0f.xxx;\n    float3 param = _4835;\n    float3 param_1 = _4861;\n    float3 param_2 = 0.0f.xxx;\n    float3 param_3 = 0.0f.xxx;\n    float3 param_4 = 0.0f.xxx;\n    float2 param_5 = 0.0f.xx;\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _4861;\n    float3 param_7 = _4887;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _4887;\n    float3 param_13 = _4913;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _4913;\n    float3 param_19 = _4835;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5f)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875f;\n}\n\nfloat fa_ltc_rect(float4 abcd, float3 center, float3 ex, float3 ey)\n{\n    float4 param = abcd;\n    float3 param_1 = (center - ex) - ey;\n    float3 param_2 = (center + ex) - ey;\n    float3 param_3 = (center + ex) + ey;\n    float3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(float4 m, float shape, float3 pc, float3 ex, float3 ey)\n{\n    if ((shape < 0.5f) || (shape > 1.5f))\n    {\n        float4 param = m;\n        float3 param_1 = pc;\n        float3 param_2 = ex;\n        float3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    float3 _5063 = (pc + (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _5087 = (pc - (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _5103 = (pc - (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float4 param_4 = m;\n    float3 param_5 = _5063;\n    float3 param_6 = (pc + (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_7 = (pc - (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_8 = _5087;\n    float4 param_9 = m;\n    float3 param_10 = _5063;\n    float3 param_11 = _5087;\n    float3 param_12 = (pc - (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    float3 param_13 = _5103;\n    float4 param_14 = m;\n    float3 param_15 = _5063;\n    float3 param_16 = _5103;\n    float3 param_17 = (pc + (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float3 param_18 = (pc + (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nfloat2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((float2(clamp((roughness - 0.0500000007450580596923828125f) * 1.0526316165924072265625f, 0.0f, 1.0f), sqrt(clamp(1.0f - ndv, 0.0f, 1.0f))) * 63.0f) + 0.5f.xx) * 0.015625f.xx;\n}\n\nfloat3 fa_area_shade(int li, float3 world_pos, float3 n, float3 v, float3 diffuse_color, float3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _5161 = fa_light_base(param);\n    int param_1 = _5161;\n    int param_2 = _5161 + 1;\n    int param_3 = _5161 + 2;\n    int param_4 = _5161 + 4;\n    float4 _5183 = fa_light_texel(param_4);\n    int param_5 = _5161 + 5;\n    float4 _5188 = fa_light_texel(param_5);\n    int param_6 = _5161 + 6;\n    float4 _5193 = fa_light_texel(param_6);\n    float _5194 = _5193.w;\n    float3 _5199 = fa_light_texel(param_1).xyz - world_pos;\n    bool _5201 = _5194 < 1.5f;\n    bool _5208;\n    if (_5201)\n    {\n        _5208 = dot(normalize(fa_light_texel(param_3).xyz), _5199) >= 0.0f;\n    }\n    else\n    {\n        _5208 = _5201;\n    }\n    if (_5208)\n    {\n        return 0.0f.xxx;\n    }\n    bool _5217 = (_5194 > 0.5f) && _5201;\n    float _5221 = _5217 ? 1.0539000034332275390625f : 1.0f;\n    float3 _5224 = _5183.xyz;\n    float _5226 = _5183.w;\n    float3 _5232 = _5188.xyz;\n    float _5234 = _5188.w;\n    float3 up = _5232 * (_5234 * _5221);\n    float _5240;\n    if (_5217)\n    {\n        _5240 = (3.1415927410125732421875f * _5226) * _5226;\n    }\n    else\n    {\n        _5240 = (4.0f * _5226) * _5234;\n    }\n    if (_5194 > 1.5f)\n    {\n        float3 _5266 = cross(_5224, -_5199);\n        float3 perp = _5266;\n        float _5270 = dot(_5266, _5266);\n        float3 _5273;\n        if (_5270 > 1.0000000133514319600180897396058e-10f)\n        {\n            _5273 = perp * rsqrt(_5270);\n        }\n        else\n        {\n            _5273 = _5232;\n        }\n        perp = _5273;\n        up = _5273 * _5234;\n    }\n    float _5294 = max(_5240, 9.9999999747524270787835121154785e-07f);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _5304 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _5304;\n    float3 param_10 = n;\n    float3 param_11 = _5199;\n    float3 _5312 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_12 = _5304;\n    float3 param_13 = n;\n    float3 param_14 = _5224 * (_5226 * _5221);\n    float3 _5320 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_15 = _5304;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float3 _5328 = fa_ltc_local(param_15, param_16, param_17);\n    float4 param_18 = float4(1.0f, 0.0f, 0.0f, 1.0f);\n    float param_19 = _5194;\n    float3 param_20 = _5312;\n    float3 param_21 = _5320;\n    float3 param_22 = _5328;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    float2 _5347 = fa_ltc_uv(param_23, param_24) * 64.0f;\n    float2 param_25 = _5347;\n    float2 param_26 = _5347 + float2(64.0f, 0.0f);\n    float4 _5357 = fa_atlas_fetch(param_26);\n    float4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _5194;\n    float3 param_29 = _5312;\n    float3 param_30 = _5320;\n    float3 param_31 = _5328;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _5357.x) + ((f90.xxx - f0) * _5357.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875f * dot(_5199, _5199)) + _5294) / _5294) * window);\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4194 = 1.0f / alpha;\n    return ((2.0f + _4194) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _4194)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat fa_layers_coat(FaLayers L, float3 l, float3 h, float vdh)\n{\n    float _4229 = max(dot(L.nc, l), 0.0f);\n    float _4235 = max(dot(L.nc, h), 0.0f);\n    float _4244 = ((_4235 * _4235) * (L.coat_a2 - 1.0f)) + 1.0f;\n    return (((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _4244) * _4244)) * (0.5f / max(lerp((2.0f * _4229) * L.coat_ndv, _4229 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _4229)) * _4229;\n}\n\nfloat3 fa_area_layers(FaLayers L, int li, float3 world_pos, float3 n, float3 v, float3 l, float3 diffuse_color, float3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    float3 param_2 = n;\n    float3 param_3 = v;\n    float3 param_4 = diffuse_color;\n    float3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _5425;\n    if (L.sheen_on)\n    {\n        _5425 = L.sheen_scale;\n    }\n    else\n    {\n        _5425 = 1.0f;\n    }\n    float3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _5425);\n    float3 _5438 = normalize(l + v);\n    int param_10 = li;\n    float3 _5449 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _5458 = max(dot(n, l), 0.0f);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _5438), 0.0f);\n        float param_13 = _5458;\n        float param_14 = ndv;\n        result += ((L.sheen * _5449) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875f) * step(9.9999997473787516355514526367188e-05f, _5458)) * _5458) * L.keep));\n    }\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_15 = L;\n        float3 param_16 = l;\n        float3 param_17 = _5438;\n        float param_18 = max(dot(v, _5438), 0.0f);\n        result += (_5449 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4097 = tdh / at;\n    float _4101 = bdh / ab;\n    float _4113 = ((_4097 * _4097) + (_4101 * _4101)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _4113) * _4113);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4293 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4372 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _4372) * _4372);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _4293);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _4293));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_17 = L;\n        float3 param_18 = l;\n        float3 param_19 = h;\n        float param_20 = vdh;\n        result += fa_layers_coat(param_17, param_18, param_19, param_20).xxx;\n    }\n    return result;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3503 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3506 = _3503.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3506 * _3506, exp2((-9.27999973297119140625f) * ndv)) * _3506) + _3503.y)) + _3503.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_548_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _548_fa_env_horizon.w).xyz;\n    }\n    float _3357 = rough * rough;\n    float _3387 = 0.60000002384185791015625f * _3357;\n    return lerp(lerp(_548_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_548_fa_env_horizon.xyz, _548_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3357)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3387, 0.0500000007450580596923828125f + _3387, d.y).xxx), ((_548_fa_env_sky.xyz + _548_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3357 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _3980;\n        if (L.aniso >= 0.0f)\n        {\n            _3980 = L.b;\n        }\n        else\n        {\n            _3980 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_3980, v), _3980), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4013 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _4013.x) + (L.f90.xxx * _4013.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _4068 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _4068.x) + _4068.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3545 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3545.x) + _3545.y.xxx);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2215_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3151 = int(_2215_fa_shadow_cfg.x + 0.5f);\n    float _3161 = dot(world - _2215_fa_shadow_eye.xyz, _2215_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3166 = _3151 > 0;\n    bool _3175;\n    if (_3166)\n    {\n        int param = _3151 - 1;\n        _3175 = _3161 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3175 = _3166;\n    }\n    if (_3175)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3181 = _3151 > 1;\n        bool _3188;\n        if (_3181)\n        {\n            _3188 = _3161 > _2215_fa_shadow_split.x;\n        }\n        else\n        {\n            _3188 = _3181;\n        }\n        if (_3188)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3194 = _3151 > 2;\n        bool _3201;\n        if (_3194)\n        {\n            _3201 = _3161 > _2215_fa_shadow_split.y;\n        }\n        else\n        {\n            _3201 = _3194;\n        }\n        if (_3201)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3207 = _3151 > 3;\n        bool _3214;\n        if (_3207)\n        {\n            _3214 = _3161 > _2215_fa_shadow_split.z;\n        }\n        else\n        {\n            _3214 = _3207;\n        }\n        if (_3214)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _6524 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6524 = -_6524;\n    }\n    float3 _5879 = normalize(_548_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _6537 = { fa_world_pos, _6524, fa_world_tangent, fa_uv, fa_vertex_color, _5879, gl_FrontFacing };\n    SurfaceInput param_1 = _6537;\n    Surface _5887 = fa_standard_surface(param_1);\n    float3 _6555 = _5887.albedo;\n    float _6556 = _5887.alpha;\n    float3 _6557 = _5887.normal;\n    float _6558 = _5887.metallic;\n    float _6559 = _5887.roughness;\n    float _6560 = _5887.occlusion;\n    float3 _6561 = _5887.emission;\n    float _6562 = _5887.clearcoat;\n    float _6563 = _5887.clearcoat_roughness;\n    float3 _6564 = _5887.sheen_color;\n    float _6565 = _5887.sheen_roughness;\n    float _6566 = _5887.anisotropy;\n    float _6567 = _5887.anisotropy_rotation;\n    float _6568 = _5887.specular;\n    float _6569 = _5887.ior;\n    float3 _6570 = _5887.specular_color;\n    SurfaceInput _6545 = { fa_world_pos, _6524, fa_world_tangent, fa_uv, fa_vertex_color, _5879, gl_FrontFacing };\n    SurfaceInput param_2 = _6545;\n    Surface param_3 = _5887;\n    surface(param_2, param_3);\n    _6555 = param_3.albedo;\n    _6556 = param_3.alpha;\n    _6557 = param_3.normal;\n    _6558 = param_3.metallic;\n    _6559 = param_3.roughness;\n    _6560 = param_3.occlusion;\n    _6561 = param_3.emission;\n    _6562 = param_3.clearcoat;\n    _6563 = param_3.clearcoat_roughness;\n    _6564 = param_3.sheen_color;\n    _6565 = param_3.sheen_roughness;\n    _6566 = param_3.anisotropy;\n    _6567 = param_3.anisotropy_rotation;\n    _6568 = param_3.specular;\n    _6569 = param_3.ior;\n    _6570 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _6524;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6555 = param_6;\n    _6557 = param_7;\n    float3 result;\n    if (_548_fa_emissive.w > 0.5f)\n    {\n        result = _6555;\n    }\n    else\n    {\n        float3 _5926 = normalize(_6557);\n        float _5933 = clamp(_6558, 0.0f, 1.0f);\n        float _5937 = clamp(_6559, 0.0500000007450580596923828125f, 1.0f);\n        float _5941 = _5937 * _5937;\n        float _5945 = _5941 * _5941;\n        float _5950 = max(dot(_5926, _5879), 9.9999997473787516355514526367188e-05f);\n        float3 _5956 = _6555 * (1.0f - _5933);\n        float3 _5963 = lerp(0.039999999105930328369140625f.xxx, _6555, _5933.xxx);\n        float3 f0 = _5963;\n        SurfaceInput _6553 = { fa_world_pos, _6524, fa_world_tangent, fa_uv, fa_vertex_color, _5879, gl_FrontFacing };\n        SurfaceInput param_8 = _6553;\n        Surface _6636 = { _6555, _6556, _6557, _6558, _6559, _6560, _6561, _6562, _6563, _6564, _6565, _6566, _6567, _6568, _6569, _6570 };\n        Surface param_9 = _6636;\n        float3 param_10 = _5926;\n        float3 param_11 = _5879;\n        float param_12 = _5933;\n        float param_13 = _5937;\n        float3 param_14 = _5963;\n        FaLayers _5979 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _5926;\n        float3 lit = (fa_indirect_diffuse(param_15) * _5956) * _6560;\n        if (_5979.on)\n        {\n            lit *= _5979.base_scale;\n        }\n        int _6001 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6001; ln++)\n        {\n            int param_16 = ln;\n            int _6014 = fa_cl_light(param_16);\n            bool _6017 = fa_lm.z > 0.5f;\n            bool _6023;\n            if (_6017)\n            {\n                int param_17 = _6014;\n                _6023 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _6023 = _6017;\n            }\n            if (_6023)\n            {\n                continue;\n            }\n            int param_18 = _6014;\n            float3 param_19 = fa_world_pos;\n            float3 param_20 = _6524;\n            LightSample _6035 = fa_light_shadowed(param_18, param_19, param_20);\n            float _6043 = max(dot(_5926, _6035.direction), 0.0f);\n            float _6049 = _6035.attenuation * _6035.shadow;\n            float3 _6054 = normalize(_6035.direction + _5879);\n            float _6059 = max(dot(_5926, _6054), 0.0f);\n            float _6064 = max(dot(_5879, _6054), 0.0f);\n            bool _6071;\n            if (fa_light_is_area)\n            {\n                _6071 = !_5979.on;\n            }\n            else\n            {\n                _6071 = fa_light_is_area;\n            }\n            if (_6071)\n            {\n                int param_21 = _6014;\n                float3 param_22 = fa_world_pos;\n                float3 param_23 = _5926;\n                float3 param_24 = _5879;\n                float3 param_25 = _5956;\n                float3 param_26 = f0;\n                float param_27 = 1.0f;\n                float param_28 = _5937;\n                float param_29 = _5950;\n                float param_30 = _6049;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _5979;\n                    int param_32 = _6014;\n                    float3 param_33 = fa_world_pos;\n                    float3 param_34 = _5926;\n                    float3 param_35 = _5879;\n                    float3 param_36 = _6035.direction;\n                    float3 param_37 = _5956;\n                    float3 param_38 = f0;\n                    float param_39 = _5937;\n                    float param_40 = _5950;\n                    float param_41 = _6049;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_5979.on)\n                    {\n                        FaLayers param_42 = _5979;\n                        float3 param_43 = _5956;\n                        float3 param_44 = f0;\n                        float3 param_45 = _5926;\n                        float3 param_46 = _5879;\n                        float3 param_47 = _6035.direction;\n                        float3 param_48 = _6054;\n                        float param_49 = _6043;\n                        float param_50 = _5950;\n                        float param_51 = _6059;\n                        float param_52 = _6064;\n                        float param_53 = _5941;\n                        float param_54 = _5945;\n                        int param_55 = _6014;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _6049));\n                    }\n                    else\n                    {\n                        float _6177 = ((_6059 * _6059) * (_5945 - 1.0f)) + 1.0f;\n                        int param_56 = _6014;\n                        lit += (((_5956 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _6064, 5.0f))) * (((_5945 / ((3.1415927410125732421875f * _6177) * _6177)) * (0.5f / max(lerp((2.0f * _6043) * _5950, _6043 + _5950, _5941), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _6043))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_6043 * _6049));\n                    }\n                }\n            }\n        }\n        if (_5979.on)\n        {\n            FaLayers param_57 = _5979;\n            float3 param_58 = _5926;\n            float3 param_59 = _5879;\n            float3 param_60 = f0;\n            float param_61 = _5937;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _6560);\n        }\n        else\n        {\n            float3 param_62 = _5926;\n            float3 param_63 = _5879;\n            float3 param_64 = f0;\n            float param_65 = _5937;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _6560);\n        }\n        result = lit;\n    }\n    float3 _6272 = result;\n    float3 _6273 = _6272 + _6561;\n    result = _6273;\n    float3 param_66 = _6273;\n    float3 param_67 = fa_world_pos;\n    result = fa_shadow_debug(param_66, param_67);\n    bool _6282 = _548_fa_fog.w > 0.0f;\n    bool _6289;\n    if (!_6282)\n    {\n        _6289 = _548_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _6289 = _6282;\n    }\n    if (_6289)\n    {\n        float3 _6298 = fa_world_pos - _548_fa_camera_pos.xyz;\n        float _6304 = dot(_6298, _548_fa_fog_c.xyz);\n        bool _6308 = _548_fa_fog_c.w > 0.5f;\n        float _6309;\n        if (_6308)\n        {\n            _6309 = _6304;\n        }\n        else\n        {\n            _6309 = length(_6298);\n        }\n        float _6321 = _6309 - _548_fa_fog_b.x;\n        if (_6321 > 0.0f)\n        {\n            float _6330 = _548_fa_fog.w * _6321;\n            float tau = _6330 * _6330;\n            if (_548_fa_fog_b.y > 0.0f)\n            {\n                float _6346;\n                if (_6308)\n                {\n                    _6346 = fa_world_pos.y - (_548_fa_fog_c.y * _6304);\n                }\n                else\n                {\n                    _6346 = _548_fa_camera_pos.y;\n                }\n                float _6367 = lerp(_6346, fa_world_pos.y, clamp(_548_fa_fog_b.x / _6309, 0.0f, 1.0f));\n                float _6371 = fa_world_pos.y - _6367;\n                float _6376 = _6367 - _548_fa_fog_b.z;\n                float _6381 = fa_world_pos.y - _548_fa_fog_b.z;\n                bool _6384 = _6376 <= 0.0f;\n                bool _6385 = !_6384;\n                bool _6391;\n                if (_6385)\n                {\n                    _6391 = _548_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6391 = _6384;\n                }\n                float _6392;\n                if (_6391)\n                {\n                    _6392 = _548_fa_fog_b.y;\n                }\n                else\n                {\n                    _6392 = _548_fa_fog_b.y * exp(-min(_548_fa_fog_b.w * _6376, 80.0f));\n                }\n                bool _6419;\n                if (_6385)\n                {\n                    _6419 = _548_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6419 = _6384;\n                }\n                float _6420;\n                if (_6419)\n                {\n                    _6420 = _548_fa_fog_b.y * _6376;\n                }\n                else\n                {\n                    _6420 = (_548_fa_fog_b.y * (1.0f - exp(-min(_548_fa_fog_b.w * _6376, 80.0f)))) / _548_fa_fog_b.w;\n                }\n                bool _6445 = _6381 <= 0.0f;\n                bool _6452;\n                if (!_6445)\n                {\n                    _6452 = _548_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6452 = _6445;\n                }\n                float _6453;\n                if (_6452)\n                {\n                    _6453 = _548_fa_fog_b.y * _6381;\n                }\n                else\n                {\n                    _6453 = (_548_fa_fog_b.y * (1.0f - exp(-min(_548_fa_fog_b.w * _6381, 80.0f)))) / _548_fa_fog_b.w;\n                }\n                float _6480;\n                if (abs(_6371) < 0.001000000047497451305389404296875f)\n                {\n                    _6480 = _6392;\n                }\n                else\n                {\n                    _6480 = (_6453 - _6420) / _6371;\n                }\n                tau += (_6321 * max(_6480, 0.0f));\n            }\n            result = lerp(result, _548_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _6556);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_50",
            "hlsl_register_b_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_150",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_197",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_548",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2215",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_material_vs : register(b4)\n{\n    float3 _45_offset : packoffset(c0);\n    float _45_fa_pad0 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _145_fa_view_proj : packoffset(c0);\n    row_major float4x4 _145_fa_light_vp : packoffset(c4);\n    float4 _145_fa_uv_scale : packoffset(c8);\n    float4 _145_fa_time : packoffset(c9);\n    float4 _145_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _83 = cross(model[1].xyz, model[2].xyz);\n    float _89 = (dot(model[0].xyz, _83) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _310 = { mul(float4(position, 1.0f), model).xyz, (((_83 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _89, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _89), texcoord0 * _145_fa_uv_scale.xy, color, position };\n    return _310;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos += _45_offset;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _189 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -mul(_189, _145_fa_light_vp).z;\n    fa_pre_r0 = float3(_145_fa_light_vp[0].x, _145_fa_light_vp[1].x, _145_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_145_fa_light_vp[0].y, _145_fa_light_vp[1].y, _145_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_145_fa_light_vp[0].z, _145_fa_light_vp[1].z, _145_fa_light_vp[2].z);\n    gl_Position = mul(_189, _145_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _737 = base_t;\n    _737.x = _225.x;\n    _737.y = _225.y;\n    _737.z = _225.z;\n    base_t = _737;\n    float4 _241 = (_737 * _213_fa_base_color) * i.vertex_color;\n    float3 _700 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _745 = _279;\n        _745.x = _284.x;\n        _745.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _745;\n        _700 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _748 = mrt;\n    _748.x = _313.x;\n    _748.y = _313.y;\n    _748.z = _313.z;\n    mrt = _748;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _705 = _213_fa_layers_a.x;\n    float _706 = _213_fa_layers_a.y;\n    float _709 = _213_fa_layers_a.z;\n    float _708 = _213_fa_layers_b.w;\n    float _711 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _705 *= _355.y;\n            _706 *= _355.z;\n            _708 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _709 *= mrt.x;\n            _711 *= mrt.w;\n        }\n    }\n    Surface _730 = { _241.xyz, _241.w, _700, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _705, _706, _213_fa_layers_b.xyz, _708, _709, _213_fa_layers_a.w, _711, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _730;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _611 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _611 = -_611;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _624 = { fa_world_pos, _611, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _624;\n    SurfaceInput _632 = { fa_world_pos, _611, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _632;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_45",
            "hlsl_register_b_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_145",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_material_vs : register(b4)\n{\n    float3 _50_offset : packoffset(c0);\n    float _50_fa_pad0 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _150_fa_view_proj : packoffset(c0);\n    row_major float4x4 _150_fa_light_vp : packoffset(c4);\n    float4 _150_fa_uv_scale : packoffset(c8);\n    float4 _150_fa_time : packoffset(c9);\n    float4 _150_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _197_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _188 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_197_fa_joint_rows[_188] * weights[i]);\n        r1 += (_197_fa_joint_rows[_188 + 1] * weights[i]);\n        r2 += (_197_fa_joint_rows[_188 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _88 = cross(model[1].xyz, model[2].xyz);\n    float _94 = (dot(model[0].xyz, _88) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _431 = { mul(float4(position, 1.0f), model).xyz, (((_88 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _94, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _94), texcoord0 * _150_fa_uv_scale.xy, color, position };\n    return _431;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos += _50_offset;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _302 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -mul(_302, _150_fa_light_vp).z;\n    fa_pre_r0 = float3(_150_fa_light_vp[0].x, _150_fa_light_vp[1].x, _150_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_150_fa_light_vp[0].y, _150_fa_light_vp[1].y, _150_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_150_fa_light_vp[0].z, _150_fa_light_vp[1].z, _150_fa_light_vp[2].z);\n    gl_Position = mul(_302, _150_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _737 = base_t;\n    _737.x = _225.x;\n    _737.y = _225.y;\n    _737.z = _225.z;\n    base_t = _737;\n    float4 _241 = (_737 * _213_fa_base_color) * i.vertex_color;\n    float3 _700 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _745 = _279;\n        _745.x = _284.x;\n        _745.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _745;\n        _700 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _748 = mrt;\n    _748.x = _313.x;\n    _748.y = _313.y;\n    _748.z = _313.z;\n    mrt = _748;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _705 = _213_fa_layers_a.x;\n    float _706 = _213_fa_layers_a.y;\n    float _709 = _213_fa_layers_a.z;\n    float _708 = _213_fa_layers_b.w;\n    float _711 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _705 *= _355.y;\n            _706 *= _355.z;\n            _708 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _709 *= mrt.x;\n            _711 *= mrt.w;\n        }\n    }\n    Surface _730 = { _241.xyz, _241.w, _700, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _705, _706, _213_fa_layers_b.xyz, _708, _709, _213_fa_layers_a.w, _711, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _730;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _611 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _611 = -_611;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _624 = { fa_world_pos, _611, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _624;\n    SurfaceInput _632 = { fa_world_pos, _611, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _632;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_50",
            "hlsl_register_b_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_150",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_197",
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
    },
    "shadow": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_material_vs : register(b4)\n{\n    float3 _36_offset : packoffset(c0);\n    float _36_fa_pad0 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float3 fa_normal : TEXCOORD5;\n    float2 fa_texcoord0 : TEXCOORD6;\n    float4 fa_tangent : TEXCOORD7;\n    float4 fa_color : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _262 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _262;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos += _36_offset;\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _136_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    return stage_output;\n}\n",
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
            "inst_name": "_36",
            "hlsl_register_b_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_136",
            "hlsl_register_b_n": 0
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_material_vs : register(b4)\n{\n    float3 _41_offset : packoffset(c0);\n    float _41_fa_pad0 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _141_fa_view_proj : packoffset(c0);\n    row_major float4x4 _141_fa_light_vp : packoffset(c4);\n    float4 _141_fa_uv_scale : packoffset(c8);\n    float4 _141_fa_time : packoffset(c9);\n    float4 _141_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _188_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float4 fa_joints : TEXCOORD5;\n    float4 fa_weights : TEXCOORD6;\n    float3 fa_normal : TEXCOORD7;\n    float2 fa_texcoord0 : TEXCOORD8;\n    float4 fa_tangent : TEXCOORD9;\n    float4 fa_color : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 gl_Position : SV_Position;\n};\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _179 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_188_fa_joint_rows[_179] * weights[i]);\n        r1 += (_188_fa_joint_rows[_179 + 1] * weights[i]);\n        r2 += (_188_fa_joint_rows[_179 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _79 = cross(model[1].xyz, model[2].xyz);\n    float _85 = (dot(model[0].xyz, _79) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _383 = { mul(float4(position, 1.0f), model).xyz, (((_79 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _85, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _85), texcoord0 * _141_fa_uv_scale.xy, color, position };\n    return _383;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos += _41_offset;\n}\n\nvoid vert_main()\n{\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    fa_inst_begin();\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    vertex(param_8);\n    gl_Position = mul(float4(param_8.world_pos, 1.0f), _141_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    return stage_output;\n}\n",
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
            "inst_name": "_41",
            "hlsl_register_b_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_141",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_188",
            "hlsl_register_b_n": 3
          }
        ]
      }
    }
  }
}
