{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "fc5698cd941e0af057040ef4c307a7106b1e2971cc74f7501935817daedb7ce8",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _260 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _260;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_267, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _3366[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _365_fa_camera_pos : packoffset(c0);\n    float4 _365_fa_ambient : packoffset(c1);\n    float4 _365_fa_base_color : packoffset(c2);\n    float4 _365_fa_emissive : packoffset(c3);\n    float4 _365_fa_model_emissive : packoffset(c4);\n    float4 _365_fa_pbr : packoffset(c5);\n    float4 _365_fa_maps : packoffset(c6);\n    float4 _365_fa_fog : packoffset(c7);\n    float4 _365_fa_fog_b : packoffset(c8);\n    float4 _365_fa_fog_c : packoffset(c9);\n    float4 _365_fa_counts : packoffset(c10);\n    float4 _365_fa_env_sky : packoffset(c11);\n    float4 _365_fa_env_horizon : packoffset(c12);\n    float4 _365_fa_time : packoffset(c13);\n    float4 _365_fa_cl_vpx : packoffset(c14);\n    float4 _365_fa_cl_vpy : packoffset(c15);\n    float4 _365_fa_cl_vpw : packoffset(c16);\n    float4 _365_fa_cl_fwd : packoffset(c17);\n    float4 _365_fa_cl_grid : packoffset(c18);\n    float4 _365_fa_cl_info : packoffset(c19);\n    float4 _365_fa_layers_a : packoffset(c20);\n    float4 _365_fa_layers_b : packoffset(c21);\n    float4 _365_fa_layers_c : packoffset(c22);\n    float4 _365_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2072_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2072_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2072_fa_shadow_info[4] : packoffset(c20);\n    float4 _2072_fa_shadow_split : packoffset(c24);\n    float4 _2072_fa_shadow_cfg : packoffset(c25);\n    float4 _2072_fa_shadow_bias : packoffset(c26);\n    float4 _2072_fa_shadow_eye : packoffset(c27);\n    float4 _2072_fa_shadow_fwd : packoffset(c28);\n    float4 _2072_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t11);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t10);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1343 = _365_fa_cl_info.x < 0.0f;\n    bool _1350;\n    if (!_1343)\n    {\n        _1350 = _365_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1350 = _1343;\n    }\n    bool _1358;\n    if (!_1350)\n    {\n        _1358 = _365_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1358 = _1350;\n    }\n    bool _1365;\n    if (!_1358)\n    {\n        _1365 = _365_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1365 = _1358;\n    }\n    bool _1372;\n    if (!_1365)\n    {\n        _1372 = _365_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1372 = _1365;\n    }\n    if (_1372)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1382 = float4(world_pos, 1.0f);\n    float _1388 = dot(_365_fa_cl_vpw, _1382);\n    if (!(_1388 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1410 = float2(dot(_365_fa_cl_vpx, _1382), dot(_365_fa_cl_vpy, _1382)) / _1388.xx;\n    int _1414 = int(_365_fa_cl_grid.x);\n    int _1418 = int(_365_fa_cl_grid.y);\n    int param = (int(_365_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_365_fa_cl_fwd.xyz, world_pos) + _365_fa_cl_fwd.w, _365_fa_cl_grid.w) / _365_fa_cl_grid.w) * _365_fa_cl_grid.z)), 0, int(_365_fa_cl_info.y) - 1) * _1418) + clamp(int(floor(((_1410.y * 0.5f) + 0.5f) * _365_fa_cl_grid.y)), 0, _1418 - 1)) * _1414)) + clamp(int(floor(((_1410.x * 0.5f) + 0.5f) * _365_fa_cl_grid.x)), 0, _1414 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1494 = fa_cluster_texel(param);\n    return int2(int(_1494.x), int(_1494.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_365_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3898 = fa_cluster_lookup(param);\n    fa_cl_slot = _3898.x;\n    fa_cl_local = _3898.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _4054 = fa_linear_to_srgb(param);\n        c = _4054;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _4062 = fa_srgb_to_linear(param_1);\n            c = _4062;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _297;\n    if (i.front_facing)\n    {\n        _297 = i.world_normal;\n    }\n    else\n    {\n        _297 = -i.world_normal;\n    }\n    float3 _321 = normalize(i.world_tangent.xyz - (_297 * dot(_297, i.world_tangent.xyz)));\n    float3 _349 = normalize(((_321 * m.x) + ((cross(_297, _321) * i.world_tangent.w) * m.y)) + (_297 * m.z));\n    float3 _352;\n    if (i.front_facing)\n    {\n        _352 = _349;\n    }\n    else\n    {\n        _352 = -_349;\n    }\n    return _352;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _365_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _4093 = fa_tex_fix(param_2, param_3);\n    float4 _5208 = base_t;\n    _5208.x = _4093.x;\n    _5208.y = _4093.y;\n    _5208.z = _4093.z;\n    base_t = _5208;\n    float4 _4107 = (_5208 * _365_fa_base_color) * i.vertex_color;\n    float3 _5060 = i.world_normal;\n    if (_365_fa_maps.z > 0.5f)\n    {\n        float param_4 = _365_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4139 = fa_tex_fix(param_6, param_7);\n        float3 _4142 = (_4139 * 2.0f) - 1.0f.xxx;\n        float2 _4147 = _4142.xy * _365_fa_maps.x;\n        float3 _5216 = _4142;\n        _5216.x = _4147.x;\n        _5216.y = _4147.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5216;\n        _5060 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _365_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4175 = fa_tex_fix(param_12, param_13);\n    float4 _5219 = mrt;\n    _5219.x = _4175.x;\n    _5219.y = _4175.y;\n    _5219.z = _4175.z;\n    mrt = _5219;\n    float4 _4203 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _365_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _4203.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4214 = fa_tex_fix(param_16, param_17);\n    float param_18 = _365_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4244 = fa_tex_fix(param_20, param_21);\n    float _5065 = _365_fa_layers_a.x;\n    float _5066 = _365_fa_layers_a.y;\n    float _5069 = _365_fa_layers_a.z;\n    float _5068 = _365_fa_layers_b.w;\n    float _5071 = _365_fa_layers_c.x;\n    if (_365_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_365_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _5065 *= _4214.y;\n            _5066 *= _4214.z;\n            _5068 *= _4203.w;\n        }\n        if (_365_fa_layers_c.z > 1.5f)\n        {\n            _5069 *= mrt.x;\n            _5071 *= mrt.w;\n        }\n    }\n    Surface _5090 = { _4107.xyz, _4107.w, _5060, clamp(_365_fa_pbr.x * _4175.z, 0.0f, 1.0f), clamp(_365_fa_pbr.y * _4175.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_365_fa_maps.y * (_4214.x - 1.0f)), _365_fa_emissive.xyz + (_365_fa_model_emissive.xyz * _4244), _5065, _5066, _365_fa_layers_b.xyz, _5068, _5069, _365_fa_layers_a.w, _5071, _365_fa_layers_c.y, _365_fa_layers_d.xyz };\n    return _5090;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1574 = rect.zw - rect.xy;\n    float2 _1578 = _1574 * atlas;\n    float2 _1582 = ddx * _1578;\n    float2 _1586 = ddy * _1578;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1574), clamp(0.5f * log2(max(max(dot(_1582, _1582), dot(_1586, _1586)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1619 = _365_fa_counts.y < 0.5f;\n    bool _1626;\n    if (!_1619)\n    {\n        _1626 = _365_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1626 = _1619;\n    }\n    if (_1626)\n    {\n        return;\n    }\n    float3 _1632 = ddx(world_pos);\n    float3 _1635 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1639 = fa_cluster_texel(param);\n    int _1643 = int(_1639.w);\n    if (_1643 < 1)\n    {\n        return;\n    }\n    int _1653 = int(_365_fa_counts.y + 0.5f);\n    int param_1 = _1653;\n    float4 _1657 = fa_light_texel(param_1);\n    float2 _1660 = _1657.yz;\n    int _1664 = int(_1657.w);\n    int param_2 = _1653 + 1;\n    float4 _1669 = fa_light_texel(param_2);\n    float _1670 = _1669.x;\n    int _1676 = int(_365_fa_counts.w + 0.5f) - 1;\n    int _1680 = int(_1639.z);\n    float3 _1945;\n    for (int k = 0; k < _1643; k++)\n    {\n        int _1693 = _1680 + k;\n        int param_3 = _1664 + (_1693 >> 2);\n        int _1710 = (_1653 + 2) + (int(fa_light_texel(param_3)[_1693 & 3]) * 7);\n        int param_4 = _1710 + 6;\n        float4 _1715 = fa_light_texel(param_4);\n        if (((int(_1715.w + 0.5f) >> _1676) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1710;\n        float4 _1730 = fa_light_texel(param_5);\n        int param_6 = _1710 + 1;\n        float4 _1735 = fa_light_texel(param_6);\n        int param_7 = _1710 + 2;\n        float4 _1740 = fa_light_texel(param_7);\n        float3 _1743 = _1730.xyz;\n        float _1748 = dot(_1743, world_pos) + _1730.w;\n        float3 _1750 = _1735.xyz;\n        float _1755 = dot(_1750, world_pos) + _1735.w;\n        float3 _1757 = _1740.xyz;\n        float _1762 = dot(_1757, world_pos) + _1740.w;\n        bool _1767 = abs(_1748) > 0.5f;\n        bool _1775;\n        if (!_1767)\n        {\n            _1775 = abs(_1755) > 0.5f;\n        }\n        else\n        {\n            _1775 = _1767;\n        }\n        bool _1783;\n        if (!_1775)\n        {\n            _1783 = abs(_1762) > 0.5f;\n        }\n        else\n        {\n            _1783 = _1775;\n        }\n        if (_1783)\n        {\n            continue;\n        }\n        float _1798 = clamp(dot(geo_normal, normalize(_1757)) * _1715.z, 0.0f, 1.0f);\n        if (_1798 <= 0.0f)\n        {\n            continue;\n        }\n        float _1818 = (clamp((0.5f - abs(_1762)) * 10.0f, 0.0f, 1.0f) * _1798) * _1715.x;\n        float2 _1826 = float2(_1748 + 0.5f, 0.5f - _1755);\n        float2 _1836 = float2(dot(_1743, _1632), dot(_1750, _1632));\n        float2 _1846 = float2(dot(_1743, _1635), dot(_1750, _1635));\n        int param_8 = _1710 + 5;\n        float4 _1851 = fa_light_texel(param_8);\n        int param_9 = _1710 + 3;\n        float4 _1856 = fa_light_texel(param_9);\n        int param_10 = _1710 + 4;\n        float4 _1861 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1851.xyz;\n        bool _1871 = _1856.z > _1856.x;\n        if (_1871)\n        {\n            float4 param_11 = _1856;\n            float2 param_12 = _1826;\n            float2 param_13 = _1660;\n            float2 param_14 = _1836;\n            float2 param_15 = _1846;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1670 > 0.5f) && (_1670 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1897 = fa_dc_to_linear(param_16);\n                float4 _5140 = tx;\n                _5140.x = _1897.x;\n                _5140.y = _1897.y;\n                _5140.z = _1897.z;\n                tx = _5140;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1818 * tex_a) * _1851.w, 0.0f, 1.0f).xxx);\n        if (_1861.z > _1861.x)\n        {\n            float4 param_17 = _1861;\n            float2 param_18 = _1826;\n            float2 param_19 = _1660;\n            float2 param_20 = _1836;\n            float2 param_21 = _1846;\n            float4 _1941 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1670 > 1.5f)\n            {\n                float3 param_22 = _1941.xyz;\n                float3 _1951 = fa_dc_to_srgb(param_22);\n                _1945 = _1951;\n            }\n            else\n            {\n                _1945 = _1941.xyz;\n            }\n            float3 _1960 = (_1945 * 2.0f) - 1.0f.xxx;\n            float2 _1965 = _1960.xy * _1715.y;\n            float3 _1987 = (normalize(_1743) * _1965.x) + (normalize(_1750) * _1965.y);\n            float3 _1990 = normalize(normal);\n            normal = normalize(lerp(_1990, normalize((_1990 * max(_1960.z, 0.0500000007450580596923828125f)) + (_1987 - (_1990 * dot(_1990, _1987)))), clamp(_1818 * (_1871 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_365_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _365_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3291 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3299 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3302 = int(_3291);\n    int _3305 = int(_3299);\n    float _3315 = _3299 - float(_3305);\n    int _3371 = (_3302 * 9) + _3305;\n    int _3391 = ((_3302 + 1) * 9) + _3305;\n    return lerp(lerp(_3366[_3371], _3366[_3371 + 1], _3315), lerp(_3366[_3391], _3366[_3391 + 1], _3315), _3291 - float(_3302));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _4919 = false;\n    float _4920 = 1.0f;\n    float _4921 = 1.0f;\n    float _4922 = 1.0f;\n    float _4923 = 0.0f;\n    float _4924 = 0.0f;\n    float _4925 = 0.0f;\n    float _4926 = 0.0f;\n    float _4928 = 1.0f;\n    bool _4929 = false;\n    float3 _4930 = 0.0f.xxx;\n    float _4931 = 1.0f;\n    float _4932 = 1.0f;\n    float _4933 = 1.0f;\n    float _4934 = 0.0f;\n    float _4935 = 0.0f;\n    float3 _4936 = float3(1.0f, 0.0f, 0.0f);\n    float3 _4937 = float3(0.0f, 0.0f, 1.0f);\n    float _4938 = 1.0f;\n    float _4939 = 1.0f;\n    float _3442 = clamp(s.specular, 0.0f, 1.0f);\n    float _3446 = clamp(s.ior, 1.0f, 3.0f);\n    bool _3451 = (_3442 != 1.0f) || (_3446 != 1.5f);\n    bool _3460;\n    if (!_3451)\n    {\n        _3460 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _3460 = _3451;\n    }\n    if (_3460)\n    {\n        float _3468 = (_3446 - 1.0f) / (_3446 + 1.0f);\n        f0 = lerp(min((_3468 * _3468).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _3442, s.albedo, metallic.xxx);\n        _4920 = lerp(_3442, 1.0f, metallic);\n        _4919 = true;\n    }\n    float _3495 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_3495 > 0.0f)\n    {\n        float _3503 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _4923 = _3495;\n        _4924 = _3503;\n        float _3510 = _3503 * _3503;\n        _4925 = _3510;\n        _4926 = _3510 * _3510;\n        float _3522 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _4928 = _3522;\n        _4921 = 1.0f - (_3495 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _3522, 0.0f, 1.0f), 5.0f))));\n        _4919 = true;\n    }\n    float3 _3542 = max(s.sheen_color, 0.0f.xxx);\n    float _3551 = max(_3542.x, max(_3542.y, _3542.z));\n    if (_3551 > 0.0f)\n    {\n        float _3559 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _4929 = true;\n        _4930 = _3542;\n        _4931 = _3559;\n        _4932 = _3559 * _3559;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _3559;\n        float _3576 = fa_sheen_albedo(param, param_1);\n        _4934 = _3576;\n        _4933 = 1.0f - min(_3551 * _3576, 1.0f);\n        _4919 = true;\n    }\n    _4922 = _4921 * _4933;\n    float _3595 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_3595 != 0.0f)\n    {\n        float3 _3610 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _3610;\n        if (dot(_3610, _3610) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _3622 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_3622.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _3622.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _3622.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _3626 = t;\n        float3 _3627 = normalize(_3626);\n        t = _3627;\n        float3 _3652 = normalize((_3627 * cos(s.anisotropy_rotation)) + ((cross(n, _3627) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _4936 = _3652;\n        _4937 = cross(n, _3652);\n        float _3662 = roughness * roughness;\n        float _3668 = lerp(_3662, 1.0f, _3595 * _3595);\n        bool _3670 = _3595 > 0.0f;\n        _4938 = _3670 ? _3668 : _3662;\n        _4939 = _3670 ? _3662 : _3668;\n        _4935 = _3595;\n        _4919 = true;\n    }\n    FaLayers _4961 = { _4919, _4920, _4921, _4922, _4923, _4924, _4925, _4926, i.world_normal, _4928, _4929, _4930, _4931, _4932, _4933, _4934, _4935, _4936, _4937, _4938, _4939 };\n    return _4961;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3223 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3226 = _3223.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3226 * _3226, exp2((-9.27999973297119140625f) * ndv)) * _3226) + _3223.y)) + _3223.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_365_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _365_fa_env_horizon.w).xyz;\n    }\n    float _3129 = rough * rough;\n    float _3159 = 0.60000002384185791015625f * _3129;\n    return lerp(lerp(_365_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_365_fa_env_horizon.xyz, _365_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3129)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3159, 0.0500000007450580596923828125f + _3159, d.y).xxx), ((_365_fa_env_sky.xyz + _365_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3129 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _3703;\n        if (L.aniso >= 0.0f)\n        {\n            _3703 = L.b;\n        }\n        else\n        {\n            _3703 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_3703, v), _3703), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3736 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _3736.x) + (L.f90.xxx * _3736.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3791 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _3791.x) + _3791.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3265 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3265.x) + _3265.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _3820 = clamp(s.metallic, 0.0f, 1.0f);\n    float _3824 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _3831 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _3820.xxx);\n    float3 f0 = _3831;\n    float3 _3835 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _3835;\n    float3 param_3 = i.view_dir;\n    float param_4 = _3820;\n    float param_5 = _3824;\n    float3 param_6 = _3831;\n    FaLayers _3852 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_3852.on)\n    {\n        FaLayers param_7 = _3852;\n        float3 param_8 = _3835;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _3824;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _3835;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _3824;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_365_fa_cl_info.x) + int(_365_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_365_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _427_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _427_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _593 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _606 = (c - (ru * hx)) - p;\n        float3 _612 = ru * (2.0f * hx);\n        float _618 = max(dot(_612, _612), 9.9999999392252902907785028219223e-09f);\n        float _622 = dot(_606, _612);\n        float t = clamp((-_622) / _618, 0.0f, 1.0f);\n        if (_593)\n        {\n            float _637 = dot(r, _612);\n            float _643 = _618 - (_637 * _637);\n            if (abs(_643) > (9.9999997473787516355514526367188e-06f * _618))\n            {\n                t = clamp(((dot(r, _606) * _637) - _622) / _643, 0.0f, 1.0f);\n            }\n        }\n        return (p + _606) + (_612 * t);\n    }\n    float3 q = p;\n    float _675 = dot(r, axis);\n    bool _683;\n    if (_593)\n    {\n        _683 = abs(_675) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _683 = _593;\n    }\n    if (_683)\n    {\n        float _693 = dot(c - p, axis) / _675;\n        if (_693 > 0.0f)\n        {\n            q = p + (r * _693);\n        }\n    }\n    float3 _706 = q - c;\n    float2 xy = float2(dot(_706, ru), dot(_706, uu));\n    if (shape > 0.5f)\n    {\n        float _721 = length(xy);\n        if (_721 > hx)\n        {\n            xy *= (hx / _721);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _514 = abs(d);\n    float _516 = _514.x;\n    float _518 = _514.y;\n    bool _519 = _516 >= _518;\n    bool _527;\n    if (_519)\n    {\n        _527 = _516 >= _514.z;\n    }\n    else\n    {\n        _527 = _519;\n    }\n    int _528;\n    if (_527)\n    {\n        _528 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _541;\n        if (_518 >= _514.z)\n        {\n            _541 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _541 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _528 = _541;\n    }\n    return _528;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _467 = dot(d, right);\n    float _471 = dot(d, up);\n    float _482;\n    if (((_467 * _467) + (_471 * _471)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _482 = atan2(_471, _467) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _482 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_482 - floor(_482)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _759 = fa_light_base(param);\n    bool _763 = _365_fa_ambient.w > 4.5f;\n    int param_1 = _759;\n    float4 _767 = fa_light_texel(param_1);\n    int param_2 = _759 + 1;\n    float4 _772 = fa_light_texel(param_2);\n    float _775 = _772.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _787 = _763 && (_775 > 2.5f);\n    fa_light_is_area = _787;\n    bool _789 = _775 < 0.5f;\n    float3 l;\n    if (_789)\n    {\n        l = normalize(_767.xyz);\n        if (_763)\n        {\n            int param_3 = _759 + 6;\n            float4 _803 = fa_light_texel(param_3);\n            if (_803.z > 0.5f)\n            {\n                int param_4 = _759 + 4;\n                float4 _813 = fa_light_texel(param_4);\n                int param_5 = _759 + 5;\n                float4 _818 = fa_light_texel(param_5);\n                float2 param_6 = _803.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _813.xyz) * _813.w, (-dot(world_pos, _818.xyz)) * _818.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _848 = _767.xyz;\n        float3 _850 = _848 - world_pos;\n        float3 to_light = _850;\n        float _853 = length(_850);\n        float reach = _853;\n        bool front = true;\n        if (_787)\n        {\n            int param_8 = _759 + 7;\n            reach = max(_853 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _759 + 4;\n            float4 _877 = fa_light_texel(param_9);\n            int param_10 = _759 + 5;\n            float4 _882 = fa_light_texel(param_10);\n            int param_11 = _759 + 6;\n            float4 _887 = fa_light_texel(param_11);\n            float _888 = _887.w;\n            int param_12 = _759 + 2;\n            float3 _895 = normalize(fa_light_texel(param_12).xyz);\n            bool _897 = _888 > 1.5f;\n            bool _905;\n            if (!_897)\n            {\n                _905 = dot(_895, to_light) < 0.0f;\n            }\n            else\n            {\n                _905 = _897;\n            }\n            front = _905;\n            float3 r = 0.0f.xxx;\n            float3 _914 = _365_fa_camera_pos.xyz - world_pos;\n            bool _918 = dot(n, n) > 0.5f;\n            bool _926;\n            if (_918)\n            {\n                _926 = dot(_914, _914) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _926 = _918;\n            }\n            if (_926)\n            {\n                r = reflect(-normalize(_914), normalize(n));\n            }\n            float3 param_13 = _848;\n            float3 param_14 = _895;\n            float3 param_15 = _877.xyz;\n            float3 param_16 = _882.xyz;\n            float param_17 = _877.w;\n            float param_18 = _882.w;\n            float param_19 = _888;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _962 = length(to_light);\n        dist = _962;\n        l = to_light / max(_962, 9.9999997473787516355514526367188e-05f).xxx;\n        float _976 = reach / max(_767.w, 0.001000000047497451305389404296875f);\n        float _982 = clamp(1.0f - (_976 * _976), 0.0f, 1.0f);\n        float _984;\n        if (front)\n        {\n            _984 = _982 * _982;\n        }\n        else\n        {\n            _984 = 0.0f;\n        }\n        atten = _984;\n        bool _995 = _775 < 2.5f;\n        if ((_775 > 1.5f) && _995)\n        {\n            int param_22 = _759 + 2;\n            float4 _1003 = fa_light_texel(param_22);\n            float _1013 = _1003.w;\n            int param_23 = _759 + 3;\n            float4 _1018 = fa_light_texel(param_23);\n            float _1019 = _1018.x;\n            float cos_inner = _1019;\n            if (_1019 > 1.5f)\n            {\n                cos_inner = lerp(_1013, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1013, cos_inner, dot(-l, normalize(_1003.xyz)));\n        }\n        if (_763 && (_775 < 1.5f))\n        {\n            int param_24 = _759 + 6;\n            float4 _1043 = fa_light_texel(param_24);\n            if (_1043.z > 0.5f)\n            {\n                float3 _1051 = -to_light;\n                int param_25 = _759 + 4;\n                int param_26 = _759 + 5;\n                float3 _1065 = fa_light_texel(param_25).xyz;\n                float3 _1069 = fa_light_texel(param_26).xyz;\n                float3 _1078 = float3(dot(_1051, _1065), dot(_1051, _1069), dot(_1051, cross(_1065, _1069)));\n                float3 param_27 = _1078;\n                int _1082 = fa_cube_face(param_27);\n                int param_28 = _1082;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1109 = float2(dot(_1078, cross(param_29, param_30)), dot(_1078, param_30)) / max(dot(_1078, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1113 = _1082 / 3;\n                float2 param_31 = _1043.xy + (float2(float(_1082 - (_1113 * 3)), float(_1113)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1109.x), 0.5f - (0.5f * _1109.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _759 + 7;\n            float4 _1143 = fa_light_texel(param_33);\n            if (_1143.z > 0.5f)\n            {\n                int param_34 = _759 + 2;\n                int param_35 = _759 + 4;\n                int param_36 = _759 + 5;\n                float2 param_37 = _1143.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_763 && _995)\n            {\n                int param_42 = _759 + 6;\n                float4 _1190 = fa_light_texel(param_42);\n                int param_43 = _759 + 7;\n                float4 _1195 = fa_light_texel(param_43);\n                bool _1198 = _1190.z > 0.5f;\n                bool _1205;\n                if (!_1198)\n                {\n                    _1205 = _1195.z > 0.5f;\n                }\n                else\n                {\n                    _1205 = _1198;\n                }\n                if (_1205)\n                {\n                    int param_44 = _759 + 2;\n                    float4 _1212 = fa_light_texel(param_44);\n                    float3 _1216 = normalize(_1212.xyz);\n                    int param_45 = _759 + 4;\n                    float4 _1221 = fa_light_texel(param_45);\n                    int param_46 = _759 + 5;\n                    float4 _1226 = fa_light_texel(param_46);\n                    if (_1198)\n                    {\n                        float3 _1234 = -to_light;\n                        float _1241 = _1212.w;\n                        float _1257 = 0.5f / max(dot(_1234, _1216) * (sqrt(max(1.0f - (_1241 * _1241), 0.0f)) / max(_1241, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1190.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1234, _1221.xyz) * _1257), 0.5f - (dot(_1234, _1226.xyz) * _1257));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1195.z > 0.5f)\n                    {\n                        float2 param_49 = _1195.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1216;\n                        float3 param_52 = _1221.xyz;\n                        float3 param_53 = _1226.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4907 = _772.xyz * atten;\n    if (_763)\n    {\n        _4907 *= fa_light_tint;\n    }\n    int _1325;\n    if (_789)\n    {\n        _1325 = 0;\n    }\n    else\n    {\n        _1325 = ((_775 > 1.5f) && (_775 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _4918 = { l, _4907, atten, 1.0f, dist, _1325 };\n    return _4918;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2062;\n    if (i == 0)\n    {\n        _2062 = _2072_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2078;\n        if (i == 1)\n        {\n            _2078 = _2072_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2086;\n            if (i == 2)\n            {\n                _2086 = _2072_fa_shadow_split.z;\n            }\n            else\n            {\n                _2086 = _2072_fa_shadow_split.w;\n            }\n            _2078 = _2086;\n        }\n        _2062 = _2078;\n    }\n    return _2062;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2119 = fa_shadow_depth(param, param_1);\n    float _2123;\n    if (conv.x < 0.5f)\n    {\n        _2123 = _2119;\n    }\n    else\n    {\n        _2123 = (conv.y * conv.z) / (conv.z - (_2119 * (conv.z - conv.y)));\n    }\n    return _2123;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2050 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2050), sin(_2050)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2169 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2178;\n        if (k < 0.0f)\n        {\n            _2178 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2178 = k;\n        }\n        float _2198 = clamp((_2178 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2169;\n            float2 _2217 = fa_shadow_vogel(param_3, param_4, param_5) * _2198;\n            float2 param_6 = uv + (_2217 * _2072_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2229 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2229 < (zr - (length(_2217) * plane)))\n            {\n                sum += _2229;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2255 = sum / cnt;\n        float _2265;\n        if (k < 0.0f)\n        {\n            _2265 = (-k) / max(_2255, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2265 = k;\n        }\n        radius = clamp(((max(zr - _2255, 0.0f) * unit) * _2265) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2287 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2287; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2287;\n        float param_11 = _2169;\n        float2 _2306 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2306 * _2072_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2306) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2287);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2348 = max(_2072_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2353 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2359 = sqrt(1.0f - (_2353 * _2353));\n    float _2366 = min(_2359 / max(_2353, 0.20000000298023223876953125f), 4.0f);\n    float _2371;\n    if (_2072_fa_shadow_bias.y > 0.0f)\n    {\n        _2371 = _2072_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2371 = 1.5f * _2072_fa_shadow_info[ci].x;\n    }\n    float4 _2396 = mul(float4(world + (n * (_2371 * _2359)), 1.0f), _2072_fa_shadow_mat[ci]);\n    float _2403 = _2396.x;\n    bool _2406 = _2403 < _2072_fa_shadow_rect[ci].x;\n    bool _2415;\n    if (!_2406)\n    {\n        _2415 = _2403 > _2072_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2415 = _2406;\n    }\n    bool _2424;\n    if (!_2415)\n    {\n        _2424 = _2396.y < _2072_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2424 = _2415;\n    }\n    bool _2433;\n    if (!_2424)\n    {\n        _2433 = _2396.y > _2072_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2433 = _2424;\n    }\n    bool _2440;\n    if (!_2433)\n    {\n        _2440 = _2396.z > 1.0f;\n    }\n    else\n    {\n        _2440 = _2433;\n    }\n    if (_2440)\n    {\n        return -1.0f;\n    }\n    float _2448;\n    if (_2072_fa_shadow_bias.x > 0.0f)\n    {\n        _2448 = _2072_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2448 = 1.5f * _2072_fa_shadow_info[ci].x;\n    }\n    float2 param = _2396.xy;\n    float4 param_1 = _2072_fa_shadow_rect[ci];\n    float param_2 = _2396.z - ((_2448 * (1.0f + (0.5f * _2366))) / _2348);\n    float param_3 = _2072_fa_shadow_info[ci].x;\n    float param_4 = _2348;\n    float param_5 = _2348 * 0.25f;\n    float param_6 = ((_2072_fa_shadow_info[ci].x * min(_2366, 3.0f)) * 0.5f) / _2348;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2072_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2072_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_365_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2836 = int(_2072_fa_shadow_cfg.x + 0.5f);\n    if (_2836 < 1)\n    {\n        return 1.0f;\n    }\n    float _2851 = dot(world - _2072_fa_shadow_eye.xyz, _2072_fa_shadow_fwd.xyz);\n    int param = _2836 - 1;\n    if (_2851 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2863 = _2836 > 1;\n    bool _2870;\n    if (_2863)\n    {\n        _2870 = _2851 > _2072_fa_shadow_split.x;\n    }\n    else\n    {\n        _2870 = _2863;\n    }\n    if (_2870)\n    {\n        ci = 1;\n    }\n    bool _2874 = _2836 > 2;\n    bool _2881;\n    if (_2874)\n    {\n        _2881 = _2851 > _2072_fa_shadow_split.y;\n    }\n    else\n    {\n        _2881 = _2874;\n    }\n    if (_2881)\n    {\n        ci = 2;\n    }\n    bool _2885 = _2836 > 3;\n    bool _2892;\n    if (_2885)\n    {\n        _2892 = _2851 > _2072_fa_shadow_split.z;\n    }\n    else\n    {\n        _2892 = _2885;\n    }\n    if (_2892)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2836)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2918 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2918;\n        if (_2918 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2072_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2943;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2943 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2943 = _2072_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2962 = _2072_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2943, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2973 = clamp((_2851 - (fa_shadow_split_at(param_7) - _2962)) / _2962, 0.0f, 1.0f);\n        if (_2973 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2836)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2994 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2994;\n                if (_2994 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2973);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _2506 = _365_fa_pbr.z < 0.5f;\n    bool _2513;\n    if (!_2506)\n    {\n        _2513 = _2072_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2513 = _2506;\n    }\n    if (_2513)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2072_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2526 = fa_light_texel(param);\n    float _2527 = _2526.x;\n    if (_2527 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2536 = int(_2527 + 0.5f);\n    int param_1 = _2536;\n    float4 _2540 = fa_light_texel(param_1);\n    int param_2 = _2536 + 1;\n    float4 _2545 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2548 = _2540.y;\n    if (_2548 > 0.0f)\n    {\n        float _2565 = 1.0f - smoothstep(0.75f * _2548, _2548, length(world - _2072_fa_shadow_eye.xyz));\n        fade = _2565;\n        if (_2565 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2540.x > 1.5f)\n    {\n        int param_3 = li;\n        int param_4 = fa_light_base(param_3);\n        float3 param_5 = world - fa_light_texel(param_4).xyz;\n        face = fa_cube_face(param_5);\n    }\n    int _2594 = (_2536 + 2) + (face * 6);\n    int param_6 = _2594;\n    int param_7 = _2594 + 1;\n    int param_8 = _2594 + 3;\n    float4 _2608 = fa_light_texel(param_8);\n    int param_9 = _2594 + 4;\n    float4 _2613 = fa_light_texel(param_9);\n    int param_10 = _2594 + 5;\n    float4 _2618 = fa_light_texel(param_10);\n    float _2630 = _2618.x * max(dot(_2608, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2635 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2658 = clamp(dot(n, _2608.xyz), -1.0f, 1.0f);\n    int param_11 = li;\n    int param_12 = fa_light_base(param_11);\n    float _2682 = min(sqrt(1.0f - (_2658 * _2658)) / max(abs(dot(n, world - fa_light_texel(param_12).xyz)) / max(dot(_2608, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2685 = _2545.y;\n    float _2687;\n    if (_2685 > 0.0f)\n    {\n        _2687 = _2685;\n    }\n    else\n    {\n        _2687 = 1.5f * _2630;\n    }\n    float4 _2707 = float4(world + (n * (_2687 * sqrt(1.0f - (_2635 * _2635)))), 1.0f);\n    float _2711 = dot(_2608, _2707);\n    float _2714 = _2618.y;\n    if (_2711 < _2714)\n    {\n        return 1.0f;\n    }\n    float2 _2729 = float2(dot(fa_light_texel(param_6), _2707), dot(fa_light_texel(param_7), _2707)) / _2711.xx;\n    float _2731 = _2729.x;\n    bool _2734 = _2731 < _2613.x;\n    bool _2743;\n    if (!_2734)\n    {\n        _2743 = _2731 > _2613.z;\n    }\n    else\n    {\n        _2743 = _2734;\n    }\n    bool _2752;\n    if (!_2743)\n    {\n        _2752 = _2729.y < _2613.y;\n    }\n    else\n    {\n        _2752 = _2743;\n    }\n    bool _2761;\n    if (!_2752)\n    {\n        _2761 = _2729.y > _2613.w;\n    }\n    else\n    {\n        _2761 = _2752;\n    }\n    if (_2761)\n    {\n        return 1.0f;\n    }\n    float _2767 = _2545.x;\n    float _2769;\n    if (_2767 > 0.0f)\n    {\n        _2769 = _2767;\n    }\n    else\n    {\n        _2769 = 1.5f * _2630;\n    }\n    float2 param_13 = _2729;\n    float4 param_14 = _2613;\n    float param_15 = _2711 - (_2769 * (1.0f + (0.5f * _2682)));\n    float param_16 = _2630;\n    float param_17 = 1.0f;\n    float param_18 = _2618.z * 0.25f;\n    float param_19 = (_2630 * min(_2682, 3.0f)) * 0.5f;\n    float3 param_20 = float3(1.0f, _2714, _2618.z);\n    int param_21 = int(_2540.z + 0.5f);\n    float param_22 = _2540.w;\n    return lerp(1.0f, fa_shadow_filter(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _3925 = fa_lm.z > 0.5f;\n    bool _3931;\n    if (_3925)\n    {\n        int param = li;\n        _3931 = fa_light_baked(param);\n    }\n    else\n    {\n        _3931 = _3925;\n    }\n    if (_3931)\n    {\n        int param_1 = li;\n        LightSample _5038 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _5038;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3955 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _5040 = _3955.color;\n    float _5042 = _3955.shadow;\n    if ((_3955.type == 0) && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3955.direction;\n        float _3969 = fa_shadow_factor(param_5, param_6);\n        _5042 = _3969;\n        _5040 *= _3969;\n    }\n    else\n    {\n        bool _3980 = _3955.type != 0;\n        bool _3986;\n        if (_3980)\n        {\n            _3986 = _3955.attenuation > 0.0f;\n        }\n        else\n        {\n            _3986 = _3980;\n        }\n        if (_3986)\n        {\n            int param_7 = li;\n            float3 param_8 = world_pos;\n            float3 param_9 = gn;\n            float3 param_10 = _3955.direction;\n            float _3998 = fa_shadow_local(param_7, param_8, param_9, param_10);\n            _5042 = _3998;\n            _5040 *= _3998;\n        }\n    }\n    LightSample _5057 = { _3955.direction, _5040, _3955.attenuation, _5042, _3955._distance, _3955.type };\n    return _5057;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2072_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3018 = int(_2072_fa_shadow_cfg.x + 0.5f);\n    float _3028 = dot(world - _2072_fa_shadow_eye.xyz, _2072_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3033 = _3018 > 0;\n    bool _3042;\n    if (_3033)\n    {\n        int param = _3018 - 1;\n        _3042 = _3028 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3042 = _3033;\n    }\n    if (_3042)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3048 = _3018 > 1;\n        bool _3055;\n        if (_3048)\n        {\n            _3055 = _3028 > _2072_fa_shadow_split.x;\n        }\n        else\n        {\n            _3055 = _3048;\n        }\n        if (_3055)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3061 = _3018 > 2;\n        bool _3068;\n        if (_3061)\n        {\n            _3068 = _3028 > _2072_fa_shadow_split.y;\n        }\n        else\n        {\n            _3068 = _3061;\n        }\n        if (_3068)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3074 = _3018 > 3;\n        bool _3081;\n        if (_3074)\n        {\n            _3081 = _3028 > _2072_fa_shadow_split.z;\n        }\n        else\n        {\n            _3081 = _3074;\n        }\n        if (_3081)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _4749 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4749 = -_4749;\n    }\n    float3 _4384 = normalize(_365_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _4762 = { fa_world_pos, _4749, fa_world_tangent, fa_uv, fa_vertex_color, _4384, gl_FrontFacing };\n    SurfaceInput param_1 = _4762;\n    Surface _4392 = fa_standard_surface(param_1);\n    float3 _4788 = _4392.albedo;\n    float _4789 = _4392.alpha;\n    float3 _4790 = _4392.normal;\n    float _4791 = _4392.metallic;\n    float _4792 = _4392.roughness;\n    float _4793 = _4392.occlusion;\n    float3 _4794 = _4392.emission;\n    float _4795 = _4392.clearcoat;\n    float _4796 = _4392.clearcoat_roughness;\n    float3 _4797 = _4392.sheen_color;\n    float _4798 = _4392.sheen_roughness;\n    float _4799 = _4392.anisotropy;\n    float _4800 = _4392.anisotropy_rotation;\n    float _4801 = _4392.specular;\n    float _4802 = _4392.ior;\n    float3 _4803 = _4392.specular_color;\n    SurfaceInput _4770 = { fa_world_pos, _4749, fa_world_tangent, fa_uv, fa_vertex_color, _4384, gl_FrontFacing };\n    SurfaceInput param_2 = _4770;\n    Surface param_3 = _4392;\n    surface(param_2, param_3);\n    _4788 = param_3.albedo;\n    _4789 = param_3.alpha;\n    _4790 = param_3.normal;\n    _4791 = param_3.metallic;\n    _4792 = param_3.roughness;\n    _4793 = param_3.occlusion;\n    _4794 = param_3.emission;\n    _4795 = param_3.clearcoat;\n    _4796 = param_3.clearcoat_roughness;\n    _4797 = param_3.sheen_color;\n    _4798 = param_3.sheen_roughness;\n    _4799 = param_3.anisotropy;\n    _4800 = param_3.anisotropy_rotation;\n    _4801 = param_3.specular;\n    _4802 = param_3.ior;\n    _4803 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _4749;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4788 = param_6;\n    _4790 = param_7;\n    float3 result;\n    if (_365_fa_emissive.w > 0.5f)\n    {\n        result = _4788;\n    }\n    else\n    {\n        float3 _4430 = _4790;\n        float3 _4431 = normalize(_4430);\n        _4790 = _4431;\n        float3 param_8 = _4431;\n        SurfaceInput _4778 = { fa_world_pos, _4749, fa_world_tangent, fa_uv, fa_vertex_color, _4384, gl_FrontFacing };\n        SurfaceInput param_9 = _4778;\n        Surface _4869 = { _4788, _4789, _4790, _4791, _4792, _4793, _4794, _4795, _4796, _4797, _4798, _4799, _4800, _4801, _4802, _4803 };\n        Surface param_10 = _4869;\n        float3 param_11 = fa_indirect_diffuse(param_8);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _4450 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4450; ln++)\n        {\n            int param_12 = ln;\n            int _4463 = fa_cl_light(param_12);\n            bool _4466 = fa_lm.z > 0.5f;\n            bool _4472;\n            if (_4466)\n            {\n                int param_13 = _4463;\n                _4472 = fa_light_baked(param_13);\n            }\n            else\n            {\n                _4472 = _4466;\n            }\n            if (_4472)\n            {\n                continue;\n            }\n            int param_14 = _4463;\n            float3 param_15 = fa_world_pos;\n            float3 param_16 = _4749;\n            LightSample _4484 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput _4786 = { fa_world_pos, _4749, fa_world_tangent, fa_uv, fa_vertex_color, _4384, gl_FrontFacing };\n            SurfaceInput param_17 = _4786;\n            Surface _4886 = { _4788, _4789, _4790, _4791, _4792, _4793, _4794, _4795, _4796, _4797, _4798, _4799, _4800, _4801, _4802, _4803 };\n            Surface param_18 = _4886;\n            LightSample param_19 = _4484;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _4499 = result;\n    float3 _4500 = _4499 + _4794;\n    result = _4500;\n    float3 param_20 = _4500;\n    float3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _4509 = _365_fa_fog.w > 0.0f;\n    bool _4516;\n    if (!_4509)\n    {\n        _4516 = _365_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _4516 = _4509;\n    }\n    if (_4516)\n    {\n        float3 _4525 = fa_world_pos - _365_fa_camera_pos.xyz;\n        float _4531 = dot(_4525, _365_fa_fog_c.xyz);\n        bool _4535 = _365_fa_fog_c.w > 0.5f;\n        float _4536;\n        if (_4535)\n        {\n            _4536 = _4531;\n        }\n        else\n        {\n            _4536 = length(_4525);\n        }\n        float _4548 = _4536 - _365_fa_fog_b.x;\n        if (_4548 > 0.0f)\n        {\n            float _4557 = _365_fa_fog.w * _4548;\n            float tau = _4557 * _4557;\n            if (_365_fa_fog_b.y > 0.0f)\n            {\n                float _4573;\n                if (_4535)\n                {\n                    _4573 = fa_world_pos.y - (_365_fa_fog_c.y * _4531);\n                }\n                else\n                {\n                    _4573 = _365_fa_camera_pos.y;\n                }\n                float _4594 = lerp(_4573, fa_world_pos.y, clamp(_365_fa_fog_b.x / _4536, 0.0f, 1.0f));\n                float _4598 = fa_world_pos.y - _4594;\n                float _4603 = _4594 - _365_fa_fog_b.z;\n                float _4608 = fa_world_pos.y - _365_fa_fog_b.z;\n                bool _4611 = _4603 <= 0.0f;\n                bool _4612 = !_4611;\n                bool _4618;\n                if (_4612)\n                {\n                    _4618 = _365_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4618 = _4611;\n                }\n                float _4619;\n                if (_4618)\n                {\n                    _4619 = _365_fa_fog_b.y;\n                }\n                else\n                {\n                    _4619 = _365_fa_fog_b.y * exp(-min(_365_fa_fog_b.w * _4603, 80.0f));\n                }\n                bool _4646;\n                if (_4612)\n                {\n                    _4646 = _365_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4646 = _4611;\n                }\n                float _4647;\n                if (_4646)\n                {\n                    _4647 = _365_fa_fog_b.y * _4603;\n                }\n                else\n                {\n                    _4647 = (_365_fa_fog_b.y * (1.0f - exp(-min(_365_fa_fog_b.w * _4603, 80.0f)))) / _365_fa_fog_b.w;\n                }\n                bool _4672 = _4608 <= 0.0f;\n                bool _4679;\n                if (!_4672)\n                {\n                    _4679 = _365_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4679 = _4672;\n                }\n                float _4680;\n                if (_4679)\n                {\n                    _4680 = _365_fa_fog_b.y * _4608;\n                }\n                else\n                {\n                    _4680 = (_365_fa_fog_b.y * (1.0f - exp(-min(_365_fa_fog_b.w * _4608, 80.0f)))) / _365_fa_fog_b.w;\n                }\n                float _4707;\n                if (abs(_4598) < 0.001000000047497451305389404296875f)\n                {\n                    _4707 = _4619;\n                }\n                else\n                {\n                    _4707 = (_4680 - _4647) / _4598;\n                }\n                tau += (_4548 * max(_4707, 0.0f));\n            }\n            result = lerp(result, _365_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4789);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_365",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2072",
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
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
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
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _381 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _381;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _388 = _273.world_pos;\n    fa_world_pos = _388;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_388, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _3366[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _365_fa_camera_pos : packoffset(c0);\n    float4 _365_fa_ambient : packoffset(c1);\n    float4 _365_fa_base_color : packoffset(c2);\n    float4 _365_fa_emissive : packoffset(c3);\n    float4 _365_fa_model_emissive : packoffset(c4);\n    float4 _365_fa_pbr : packoffset(c5);\n    float4 _365_fa_maps : packoffset(c6);\n    float4 _365_fa_fog : packoffset(c7);\n    float4 _365_fa_fog_b : packoffset(c8);\n    float4 _365_fa_fog_c : packoffset(c9);\n    float4 _365_fa_counts : packoffset(c10);\n    float4 _365_fa_env_sky : packoffset(c11);\n    float4 _365_fa_env_horizon : packoffset(c12);\n    float4 _365_fa_time : packoffset(c13);\n    float4 _365_fa_cl_vpx : packoffset(c14);\n    float4 _365_fa_cl_vpy : packoffset(c15);\n    float4 _365_fa_cl_vpw : packoffset(c16);\n    float4 _365_fa_cl_fwd : packoffset(c17);\n    float4 _365_fa_cl_grid : packoffset(c18);\n    float4 _365_fa_cl_info : packoffset(c19);\n    float4 _365_fa_layers_a : packoffset(c20);\n    float4 _365_fa_layers_b : packoffset(c21);\n    float4 _365_fa_layers_c : packoffset(c22);\n    float4 _365_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2072_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2072_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2072_fa_shadow_info[4] : packoffset(c20);\n    float4 _2072_fa_shadow_split : packoffset(c24);\n    float4 _2072_fa_shadow_cfg : packoffset(c25);\n    float4 _2072_fa_shadow_bias : packoffset(c26);\n    float4 _2072_fa_shadow_eye : packoffset(c27);\n    float4 _2072_fa_shadow_fwd : packoffset(c28);\n    float4 _2072_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t11);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t10);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1343 = _365_fa_cl_info.x < 0.0f;\n    bool _1350;\n    if (!_1343)\n    {\n        _1350 = _365_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1350 = _1343;\n    }\n    bool _1358;\n    if (!_1350)\n    {\n        _1358 = _365_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1358 = _1350;\n    }\n    bool _1365;\n    if (!_1358)\n    {\n        _1365 = _365_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1365 = _1358;\n    }\n    bool _1372;\n    if (!_1365)\n    {\n        _1372 = _365_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1372 = _1365;\n    }\n    if (_1372)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1382 = float4(world_pos, 1.0f);\n    float _1388 = dot(_365_fa_cl_vpw, _1382);\n    if (!(_1388 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1410 = float2(dot(_365_fa_cl_vpx, _1382), dot(_365_fa_cl_vpy, _1382)) / _1388.xx;\n    int _1414 = int(_365_fa_cl_grid.x);\n    int _1418 = int(_365_fa_cl_grid.y);\n    int param = (int(_365_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_365_fa_cl_fwd.xyz, world_pos) + _365_fa_cl_fwd.w, _365_fa_cl_grid.w) / _365_fa_cl_grid.w) * _365_fa_cl_grid.z)), 0, int(_365_fa_cl_info.y) - 1) * _1418) + clamp(int(floor(((_1410.y * 0.5f) + 0.5f) * _365_fa_cl_grid.y)), 0, _1418 - 1)) * _1414)) + clamp(int(floor(((_1410.x * 0.5f) + 0.5f) * _365_fa_cl_grid.x)), 0, _1414 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1494 = fa_cluster_texel(param);\n    return int2(int(_1494.x), int(_1494.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_365_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3898 = fa_cluster_lookup(param);\n    fa_cl_slot = _3898.x;\n    fa_cl_local = _3898.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _4054 = fa_linear_to_srgb(param);\n        c = _4054;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _4062 = fa_srgb_to_linear(param_1);\n            c = _4062;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _297;\n    if (i.front_facing)\n    {\n        _297 = i.world_normal;\n    }\n    else\n    {\n        _297 = -i.world_normal;\n    }\n    float3 _321 = normalize(i.world_tangent.xyz - (_297 * dot(_297, i.world_tangent.xyz)));\n    float3 _349 = normalize(((_321 * m.x) + ((cross(_297, _321) * i.world_tangent.w) * m.y)) + (_297 * m.z));\n    float3 _352;\n    if (i.front_facing)\n    {\n        _352 = _349;\n    }\n    else\n    {\n        _352 = -_349;\n    }\n    return _352;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _365_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _4093 = fa_tex_fix(param_2, param_3);\n    float4 _5208 = base_t;\n    _5208.x = _4093.x;\n    _5208.y = _4093.y;\n    _5208.z = _4093.z;\n    base_t = _5208;\n    float4 _4107 = (_5208 * _365_fa_base_color) * i.vertex_color;\n    float3 _5060 = i.world_normal;\n    if (_365_fa_maps.z > 0.5f)\n    {\n        float param_4 = _365_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4139 = fa_tex_fix(param_6, param_7);\n        float3 _4142 = (_4139 * 2.0f) - 1.0f.xxx;\n        float2 _4147 = _4142.xy * _365_fa_maps.x;\n        float3 _5216 = _4142;\n        _5216.x = _4147.x;\n        _5216.y = _4147.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5216;\n        _5060 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _365_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4175 = fa_tex_fix(param_12, param_13);\n    float4 _5219 = mrt;\n    _5219.x = _4175.x;\n    _5219.y = _4175.y;\n    _5219.z = _4175.z;\n    mrt = _5219;\n    float4 _4203 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _365_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _4203.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4214 = fa_tex_fix(param_16, param_17);\n    float param_18 = _365_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4244 = fa_tex_fix(param_20, param_21);\n    float _5065 = _365_fa_layers_a.x;\n    float _5066 = _365_fa_layers_a.y;\n    float _5069 = _365_fa_layers_a.z;\n    float _5068 = _365_fa_layers_b.w;\n    float _5071 = _365_fa_layers_c.x;\n    if (_365_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_365_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _5065 *= _4214.y;\n            _5066 *= _4214.z;\n            _5068 *= _4203.w;\n        }\n        if (_365_fa_layers_c.z > 1.5f)\n        {\n            _5069 *= mrt.x;\n            _5071 *= mrt.w;\n        }\n    }\n    Surface _5090 = { _4107.xyz, _4107.w, _5060, clamp(_365_fa_pbr.x * _4175.z, 0.0f, 1.0f), clamp(_365_fa_pbr.y * _4175.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_365_fa_maps.y * (_4214.x - 1.0f)), _365_fa_emissive.xyz + (_365_fa_model_emissive.xyz * _4244), _5065, _5066, _365_fa_layers_b.xyz, _5068, _5069, _365_fa_layers_a.w, _5071, _365_fa_layers_c.y, _365_fa_layers_d.xyz };\n    return _5090;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1574 = rect.zw - rect.xy;\n    float2 _1578 = _1574 * atlas;\n    float2 _1582 = ddx * _1578;\n    float2 _1586 = ddy * _1578;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1574), clamp(0.5f * log2(max(max(dot(_1582, _1582), dot(_1586, _1586)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1619 = _365_fa_counts.y < 0.5f;\n    bool _1626;\n    if (!_1619)\n    {\n        _1626 = _365_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1626 = _1619;\n    }\n    if (_1626)\n    {\n        return;\n    }\n    float3 _1632 = ddx(world_pos);\n    float3 _1635 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1639 = fa_cluster_texel(param);\n    int _1643 = int(_1639.w);\n    if (_1643 < 1)\n    {\n        return;\n    }\n    int _1653 = int(_365_fa_counts.y + 0.5f);\n    int param_1 = _1653;\n    float4 _1657 = fa_light_texel(param_1);\n    float2 _1660 = _1657.yz;\n    int _1664 = int(_1657.w);\n    int param_2 = _1653 + 1;\n    float4 _1669 = fa_light_texel(param_2);\n    float _1670 = _1669.x;\n    int _1676 = int(_365_fa_counts.w + 0.5f) - 1;\n    int _1680 = int(_1639.z);\n    float3 _1945;\n    for (int k = 0; k < _1643; k++)\n    {\n        int _1693 = _1680 + k;\n        int param_3 = _1664 + (_1693 >> 2);\n        int _1710 = (_1653 + 2) + (int(fa_light_texel(param_3)[_1693 & 3]) * 7);\n        int param_4 = _1710 + 6;\n        float4 _1715 = fa_light_texel(param_4);\n        if (((int(_1715.w + 0.5f) >> _1676) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1710;\n        float4 _1730 = fa_light_texel(param_5);\n        int param_6 = _1710 + 1;\n        float4 _1735 = fa_light_texel(param_6);\n        int param_7 = _1710 + 2;\n        float4 _1740 = fa_light_texel(param_7);\n        float3 _1743 = _1730.xyz;\n        float _1748 = dot(_1743, world_pos) + _1730.w;\n        float3 _1750 = _1735.xyz;\n        float _1755 = dot(_1750, world_pos) + _1735.w;\n        float3 _1757 = _1740.xyz;\n        float _1762 = dot(_1757, world_pos) + _1740.w;\n        bool _1767 = abs(_1748) > 0.5f;\n        bool _1775;\n        if (!_1767)\n        {\n            _1775 = abs(_1755) > 0.5f;\n        }\n        else\n        {\n            _1775 = _1767;\n        }\n        bool _1783;\n        if (!_1775)\n        {\n            _1783 = abs(_1762) > 0.5f;\n        }\n        else\n        {\n            _1783 = _1775;\n        }\n        if (_1783)\n        {\n            continue;\n        }\n        float _1798 = clamp(dot(geo_normal, normalize(_1757)) * _1715.z, 0.0f, 1.0f);\n        if (_1798 <= 0.0f)\n        {\n            continue;\n        }\n        float _1818 = (clamp((0.5f - abs(_1762)) * 10.0f, 0.0f, 1.0f) * _1798) * _1715.x;\n        float2 _1826 = float2(_1748 + 0.5f, 0.5f - _1755);\n        float2 _1836 = float2(dot(_1743, _1632), dot(_1750, _1632));\n        float2 _1846 = float2(dot(_1743, _1635), dot(_1750, _1635));\n        int param_8 = _1710 + 5;\n        float4 _1851 = fa_light_texel(param_8);\n        int param_9 = _1710 + 3;\n        float4 _1856 = fa_light_texel(param_9);\n        int param_10 = _1710 + 4;\n        float4 _1861 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1851.xyz;\n        bool _1871 = _1856.z > _1856.x;\n        if (_1871)\n        {\n            float4 param_11 = _1856;\n            float2 param_12 = _1826;\n            float2 param_13 = _1660;\n            float2 param_14 = _1836;\n            float2 param_15 = _1846;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1670 > 0.5f) && (_1670 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1897 = fa_dc_to_linear(param_16);\n                float4 _5140 = tx;\n                _5140.x = _1897.x;\n                _5140.y = _1897.y;\n                _5140.z = _1897.z;\n                tx = _5140;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1818 * tex_a) * _1851.w, 0.0f, 1.0f).xxx);\n        if (_1861.z > _1861.x)\n        {\n            float4 param_17 = _1861;\n            float2 param_18 = _1826;\n            float2 param_19 = _1660;\n            float2 param_20 = _1836;\n            float2 param_21 = _1846;\n            float4 _1941 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1670 > 1.5f)\n            {\n                float3 param_22 = _1941.xyz;\n                float3 _1951 = fa_dc_to_srgb(param_22);\n                _1945 = _1951;\n            }\n            else\n            {\n                _1945 = _1941.xyz;\n            }\n            float3 _1960 = (_1945 * 2.0f) - 1.0f.xxx;\n            float2 _1965 = _1960.xy * _1715.y;\n            float3 _1987 = (normalize(_1743) * _1965.x) + (normalize(_1750) * _1965.y);\n            float3 _1990 = normalize(normal);\n            normal = normalize(lerp(_1990, normalize((_1990 * max(_1960.z, 0.0500000007450580596923828125f)) + (_1987 - (_1990 * dot(_1990, _1987)))), clamp(_1818 * (_1871 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_365_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _365_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3291 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3299 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3302 = int(_3291);\n    int _3305 = int(_3299);\n    float _3315 = _3299 - float(_3305);\n    int _3371 = (_3302 * 9) + _3305;\n    int _3391 = ((_3302 + 1) * 9) + _3305;\n    return lerp(lerp(_3366[_3371], _3366[_3371 + 1], _3315), lerp(_3366[_3391], _3366[_3391 + 1], _3315), _3291 - float(_3302));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _4919 = false;\n    float _4920 = 1.0f;\n    float _4921 = 1.0f;\n    float _4922 = 1.0f;\n    float _4923 = 0.0f;\n    float _4924 = 0.0f;\n    float _4925 = 0.0f;\n    float _4926 = 0.0f;\n    float _4928 = 1.0f;\n    bool _4929 = false;\n    float3 _4930 = 0.0f.xxx;\n    float _4931 = 1.0f;\n    float _4932 = 1.0f;\n    float _4933 = 1.0f;\n    float _4934 = 0.0f;\n    float _4935 = 0.0f;\n    float3 _4936 = float3(1.0f, 0.0f, 0.0f);\n    float3 _4937 = float3(0.0f, 0.0f, 1.0f);\n    float _4938 = 1.0f;\n    float _4939 = 1.0f;\n    float _3442 = clamp(s.specular, 0.0f, 1.0f);\n    float _3446 = clamp(s.ior, 1.0f, 3.0f);\n    bool _3451 = (_3442 != 1.0f) || (_3446 != 1.5f);\n    bool _3460;\n    if (!_3451)\n    {\n        _3460 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _3460 = _3451;\n    }\n    if (_3460)\n    {\n        float _3468 = (_3446 - 1.0f) / (_3446 + 1.0f);\n        f0 = lerp(min((_3468 * _3468).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _3442, s.albedo, metallic.xxx);\n        _4920 = lerp(_3442, 1.0f, metallic);\n        _4919 = true;\n    }\n    float _3495 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_3495 > 0.0f)\n    {\n        float _3503 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _4923 = _3495;\n        _4924 = _3503;\n        float _3510 = _3503 * _3503;\n        _4925 = _3510;\n        _4926 = _3510 * _3510;\n        float _3522 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _4928 = _3522;\n        _4921 = 1.0f - (_3495 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _3522, 0.0f, 1.0f), 5.0f))));\n        _4919 = true;\n    }\n    float3 _3542 = max(s.sheen_color, 0.0f.xxx);\n    float _3551 = max(_3542.x, max(_3542.y, _3542.z));\n    if (_3551 > 0.0f)\n    {\n        float _3559 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _4929 = true;\n        _4930 = _3542;\n        _4931 = _3559;\n        _4932 = _3559 * _3559;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _3559;\n        float _3576 = fa_sheen_albedo(param, param_1);\n        _4934 = _3576;\n        _4933 = 1.0f - min(_3551 * _3576, 1.0f);\n        _4919 = true;\n    }\n    _4922 = _4921 * _4933;\n    float _3595 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_3595 != 0.0f)\n    {\n        float3 _3610 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _3610;\n        if (dot(_3610, _3610) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _3622 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_3622.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _3622.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _3622.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _3626 = t;\n        float3 _3627 = normalize(_3626);\n        t = _3627;\n        float3 _3652 = normalize((_3627 * cos(s.anisotropy_rotation)) + ((cross(n, _3627) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _4936 = _3652;\n        _4937 = cross(n, _3652);\n        float _3662 = roughness * roughness;\n        float _3668 = lerp(_3662, 1.0f, _3595 * _3595);\n        bool _3670 = _3595 > 0.0f;\n        _4938 = _3670 ? _3668 : _3662;\n        _4939 = _3670 ? _3662 : _3668;\n        _4935 = _3595;\n        _4919 = true;\n    }\n    FaLayers _4961 = { _4919, _4920, _4921, _4922, _4923, _4924, _4925, _4926, i.world_normal, _4928, _4929, _4930, _4931, _4932, _4933, _4934, _4935, _4936, _4937, _4938, _4939 };\n    return _4961;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3223 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3226 = _3223.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3226 * _3226, exp2((-9.27999973297119140625f) * ndv)) * _3226) + _3223.y)) + _3223.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_365_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _365_fa_env_horizon.w).xyz;\n    }\n    float _3129 = rough * rough;\n    float _3159 = 0.60000002384185791015625f * _3129;\n    return lerp(lerp(_365_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_365_fa_env_horizon.xyz, _365_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3129)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3159, 0.0500000007450580596923828125f + _3159, d.y).xxx), ((_365_fa_env_sky.xyz + _365_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3129 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _3703;\n        if (L.aniso >= 0.0f)\n        {\n            _3703 = L.b;\n        }\n        else\n        {\n            _3703 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_3703, v), _3703), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3736 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _3736.x) + (L.f90.xxx * _3736.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3791 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _3791.x) + _3791.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3265 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3265.x) + _3265.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _3820 = clamp(s.metallic, 0.0f, 1.0f);\n    float _3824 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _3831 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _3820.xxx);\n    float3 f0 = _3831;\n    float3 _3835 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _3835;\n    float3 param_3 = i.view_dir;\n    float param_4 = _3820;\n    float param_5 = _3824;\n    float3 param_6 = _3831;\n    FaLayers _3852 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_3852.on)\n    {\n        FaLayers param_7 = _3852;\n        float3 param_8 = _3835;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _3824;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _3835;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _3824;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_365_fa_cl_info.x) + int(_365_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_365_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _427_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _427_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _593 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _606 = (c - (ru * hx)) - p;\n        float3 _612 = ru * (2.0f * hx);\n        float _618 = max(dot(_612, _612), 9.9999999392252902907785028219223e-09f);\n        float _622 = dot(_606, _612);\n        float t = clamp((-_622) / _618, 0.0f, 1.0f);\n        if (_593)\n        {\n            float _637 = dot(r, _612);\n            float _643 = _618 - (_637 * _637);\n            if (abs(_643) > (9.9999997473787516355514526367188e-06f * _618))\n            {\n                t = clamp(((dot(r, _606) * _637) - _622) / _643, 0.0f, 1.0f);\n            }\n        }\n        return (p + _606) + (_612 * t);\n    }\n    float3 q = p;\n    float _675 = dot(r, axis);\n    bool _683;\n    if (_593)\n    {\n        _683 = abs(_675) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _683 = _593;\n    }\n    if (_683)\n    {\n        float _693 = dot(c - p, axis) / _675;\n        if (_693 > 0.0f)\n        {\n            q = p + (r * _693);\n        }\n    }\n    float3 _706 = q - c;\n    float2 xy = float2(dot(_706, ru), dot(_706, uu));\n    if (shape > 0.5f)\n    {\n        float _721 = length(xy);\n        if (_721 > hx)\n        {\n            xy *= (hx / _721);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _514 = abs(d);\n    float _516 = _514.x;\n    float _518 = _514.y;\n    bool _519 = _516 >= _518;\n    bool _527;\n    if (_519)\n    {\n        _527 = _516 >= _514.z;\n    }\n    else\n    {\n        _527 = _519;\n    }\n    int _528;\n    if (_527)\n    {\n        _528 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _541;\n        if (_518 >= _514.z)\n        {\n            _541 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _541 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _528 = _541;\n    }\n    return _528;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _467 = dot(d, right);\n    float _471 = dot(d, up);\n    float _482;\n    if (((_467 * _467) + (_471 * _471)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _482 = atan2(_471, _467) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _482 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_482 - floor(_482)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _759 = fa_light_base(param);\n    bool _763 = _365_fa_ambient.w > 4.5f;\n    int param_1 = _759;\n    float4 _767 = fa_light_texel(param_1);\n    int param_2 = _759 + 1;\n    float4 _772 = fa_light_texel(param_2);\n    float _775 = _772.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _787 = _763 && (_775 > 2.5f);\n    fa_light_is_area = _787;\n    bool _789 = _775 < 0.5f;\n    float3 l;\n    if (_789)\n    {\n        l = normalize(_767.xyz);\n        if (_763)\n        {\n            int param_3 = _759 + 6;\n            float4 _803 = fa_light_texel(param_3);\n            if (_803.z > 0.5f)\n            {\n                int param_4 = _759 + 4;\n                float4 _813 = fa_light_texel(param_4);\n                int param_5 = _759 + 5;\n                float4 _818 = fa_light_texel(param_5);\n                float2 param_6 = _803.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _813.xyz) * _813.w, (-dot(world_pos, _818.xyz)) * _818.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _848 = _767.xyz;\n        float3 _850 = _848 - world_pos;\n        float3 to_light = _850;\n        float _853 = length(_850);\n        float reach = _853;\n        bool front = true;\n        if (_787)\n        {\n            int param_8 = _759 + 7;\n            reach = max(_853 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _759 + 4;\n            float4 _877 = fa_light_texel(param_9);\n            int param_10 = _759 + 5;\n            float4 _882 = fa_light_texel(param_10);\n            int param_11 = _759 + 6;\n            float4 _887 = fa_light_texel(param_11);\n            float _888 = _887.w;\n            int param_12 = _759 + 2;\n            float3 _895 = normalize(fa_light_texel(param_12).xyz);\n            bool _897 = _888 > 1.5f;\n            bool _905;\n            if (!_897)\n            {\n                _905 = dot(_895, to_light) < 0.0f;\n            }\n            else\n            {\n                _905 = _897;\n            }\n            front = _905;\n            float3 r = 0.0f.xxx;\n            float3 _914 = _365_fa_camera_pos.xyz - world_pos;\n            bool _918 = dot(n, n) > 0.5f;\n            bool _926;\n            if (_918)\n            {\n                _926 = dot(_914, _914) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _926 = _918;\n            }\n            if (_926)\n            {\n                r = reflect(-normalize(_914), normalize(n));\n            }\n            float3 param_13 = _848;\n            float3 param_14 = _895;\n            float3 param_15 = _877.xyz;\n            float3 param_16 = _882.xyz;\n            float param_17 = _877.w;\n            float param_18 = _882.w;\n            float param_19 = _888;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _962 = length(to_light);\n        dist = _962;\n        l = to_light / max(_962, 9.9999997473787516355514526367188e-05f).xxx;\n        float _976 = reach / max(_767.w, 0.001000000047497451305389404296875f);\n        float _982 = clamp(1.0f - (_976 * _976), 0.0f, 1.0f);\n        float _984;\n        if (front)\n        {\n            _984 = _982 * _982;\n        }\n        else\n        {\n            _984 = 0.0f;\n        }\n        atten = _984;\n        bool _995 = _775 < 2.5f;\n        if ((_775 > 1.5f) && _995)\n        {\n            int param_22 = _759 + 2;\n            float4 _1003 = fa_light_texel(param_22);\n            float _1013 = _1003.w;\n            int param_23 = _759 + 3;\n            float4 _1018 = fa_light_texel(param_23);\n            float _1019 = _1018.x;\n            float cos_inner = _1019;\n            if (_1019 > 1.5f)\n            {\n                cos_inner = lerp(_1013, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1013, cos_inner, dot(-l, normalize(_1003.xyz)));\n        }\n        if (_763 && (_775 < 1.5f))\n        {\n            int param_24 = _759 + 6;\n            float4 _1043 = fa_light_texel(param_24);\n            if (_1043.z > 0.5f)\n            {\n                float3 _1051 = -to_light;\n                int param_25 = _759 + 4;\n                int param_26 = _759 + 5;\n                float3 _1065 = fa_light_texel(param_25).xyz;\n                float3 _1069 = fa_light_texel(param_26).xyz;\n                float3 _1078 = float3(dot(_1051, _1065), dot(_1051, _1069), dot(_1051, cross(_1065, _1069)));\n                float3 param_27 = _1078;\n                int _1082 = fa_cube_face(param_27);\n                int param_28 = _1082;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1109 = float2(dot(_1078, cross(param_29, param_30)), dot(_1078, param_30)) / max(dot(_1078, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1113 = _1082 / 3;\n                float2 param_31 = _1043.xy + (float2(float(_1082 - (_1113 * 3)), float(_1113)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1109.x), 0.5f - (0.5f * _1109.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _759 + 7;\n            float4 _1143 = fa_light_texel(param_33);\n            if (_1143.z > 0.5f)\n            {\n                int param_34 = _759 + 2;\n                int param_35 = _759 + 4;\n                int param_36 = _759 + 5;\n                float2 param_37 = _1143.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_763 && _995)\n            {\n                int param_42 = _759 + 6;\n                float4 _1190 = fa_light_texel(param_42);\n                int param_43 = _759 + 7;\n                float4 _1195 = fa_light_texel(param_43);\n                bool _1198 = _1190.z > 0.5f;\n                bool _1205;\n                if (!_1198)\n                {\n                    _1205 = _1195.z > 0.5f;\n                }\n                else\n                {\n                    _1205 = _1198;\n                }\n                if (_1205)\n                {\n                    int param_44 = _759 + 2;\n                    float4 _1212 = fa_light_texel(param_44);\n                    float3 _1216 = normalize(_1212.xyz);\n                    int param_45 = _759 + 4;\n                    float4 _1221 = fa_light_texel(param_45);\n                    int param_46 = _759 + 5;\n                    float4 _1226 = fa_light_texel(param_46);\n                    if (_1198)\n                    {\n                        float3 _1234 = -to_light;\n                        float _1241 = _1212.w;\n                        float _1257 = 0.5f / max(dot(_1234, _1216) * (sqrt(max(1.0f - (_1241 * _1241), 0.0f)) / max(_1241, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1190.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1234, _1221.xyz) * _1257), 0.5f - (dot(_1234, _1226.xyz) * _1257));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1195.z > 0.5f)\n                    {\n                        float2 param_49 = _1195.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1216;\n                        float3 param_52 = _1221.xyz;\n                        float3 param_53 = _1226.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4907 = _772.xyz * atten;\n    if (_763)\n    {\n        _4907 *= fa_light_tint;\n    }\n    int _1325;\n    if (_789)\n    {\n        _1325 = 0;\n    }\n    else\n    {\n        _1325 = ((_775 > 1.5f) && (_775 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _4918 = { l, _4907, atten, 1.0f, dist, _1325 };\n    return _4918;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2062;\n    if (i == 0)\n    {\n        _2062 = _2072_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2078;\n        if (i == 1)\n        {\n            _2078 = _2072_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2086;\n            if (i == 2)\n            {\n                _2086 = _2072_fa_shadow_split.z;\n            }\n            else\n            {\n                _2086 = _2072_fa_shadow_split.w;\n            }\n            _2078 = _2086;\n        }\n        _2062 = _2078;\n    }\n    return _2062;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2119 = fa_shadow_depth(param, param_1);\n    float _2123;\n    if (conv.x < 0.5f)\n    {\n        _2123 = _2119;\n    }\n    else\n    {\n        _2123 = (conv.y * conv.z) / (conv.z - (_2119 * (conv.z - conv.y)));\n    }\n    return _2123;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2050 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2050), sin(_2050)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2169 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2178;\n        if (k < 0.0f)\n        {\n            _2178 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2178 = k;\n        }\n        float _2198 = clamp((_2178 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2169;\n            float2 _2217 = fa_shadow_vogel(param_3, param_4, param_5) * _2198;\n            float2 param_6 = uv + (_2217 * _2072_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2229 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2229 < (zr - (length(_2217) * plane)))\n            {\n                sum += _2229;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2255 = sum / cnt;\n        float _2265;\n        if (k < 0.0f)\n        {\n            _2265 = (-k) / max(_2255, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2265 = k;\n        }\n        radius = clamp(((max(zr - _2255, 0.0f) * unit) * _2265) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2287 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2287; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2287;\n        float param_11 = _2169;\n        float2 _2306 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2306 * _2072_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2306) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2287);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2348 = max(_2072_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2353 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2359 = sqrt(1.0f - (_2353 * _2353));\n    float _2366 = min(_2359 / max(_2353, 0.20000000298023223876953125f), 4.0f);\n    float _2371;\n    if (_2072_fa_shadow_bias.y > 0.0f)\n    {\n        _2371 = _2072_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2371 = 1.5f * _2072_fa_shadow_info[ci].x;\n    }\n    float4 _2396 = mul(float4(world + (n * (_2371 * _2359)), 1.0f), _2072_fa_shadow_mat[ci]);\n    float _2403 = _2396.x;\n    bool _2406 = _2403 < _2072_fa_shadow_rect[ci].x;\n    bool _2415;\n    if (!_2406)\n    {\n        _2415 = _2403 > _2072_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2415 = _2406;\n    }\n    bool _2424;\n    if (!_2415)\n    {\n        _2424 = _2396.y < _2072_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2424 = _2415;\n    }\n    bool _2433;\n    if (!_2424)\n    {\n        _2433 = _2396.y > _2072_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2433 = _2424;\n    }\n    bool _2440;\n    if (!_2433)\n    {\n        _2440 = _2396.z > 1.0f;\n    }\n    else\n    {\n        _2440 = _2433;\n    }\n    if (_2440)\n    {\n        return -1.0f;\n    }\n    float _2448;\n    if (_2072_fa_shadow_bias.x > 0.0f)\n    {\n        _2448 = _2072_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2448 = 1.5f * _2072_fa_shadow_info[ci].x;\n    }\n    float2 param = _2396.xy;\n    float4 param_1 = _2072_fa_shadow_rect[ci];\n    float param_2 = _2396.z - ((_2448 * (1.0f + (0.5f * _2366))) / _2348);\n    float param_3 = _2072_fa_shadow_info[ci].x;\n    float param_4 = _2348;\n    float param_5 = _2348 * 0.25f;\n    float param_6 = ((_2072_fa_shadow_info[ci].x * min(_2366, 3.0f)) * 0.5f) / _2348;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2072_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2072_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_365_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2836 = int(_2072_fa_shadow_cfg.x + 0.5f);\n    if (_2836 < 1)\n    {\n        return 1.0f;\n    }\n    float _2851 = dot(world - _2072_fa_shadow_eye.xyz, _2072_fa_shadow_fwd.xyz);\n    int param = _2836 - 1;\n    if (_2851 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2863 = _2836 > 1;\n    bool _2870;\n    if (_2863)\n    {\n        _2870 = _2851 > _2072_fa_shadow_split.x;\n    }\n    else\n    {\n        _2870 = _2863;\n    }\n    if (_2870)\n    {\n        ci = 1;\n    }\n    bool _2874 = _2836 > 2;\n    bool _2881;\n    if (_2874)\n    {\n        _2881 = _2851 > _2072_fa_shadow_split.y;\n    }\n    else\n    {\n        _2881 = _2874;\n    }\n    if (_2881)\n    {\n        ci = 2;\n    }\n    bool _2885 = _2836 > 3;\n    bool _2892;\n    if (_2885)\n    {\n        _2892 = _2851 > _2072_fa_shadow_split.z;\n    }\n    else\n    {\n        _2892 = _2885;\n    }\n    if (_2892)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2836)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2918 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2918;\n        if (_2918 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2072_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2943;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2943 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2943 = _2072_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2962 = _2072_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2943, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2973 = clamp((_2851 - (fa_shadow_split_at(param_7) - _2962)) / _2962, 0.0f, 1.0f);\n        if (_2973 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2836)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2994 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2994;\n                if (_2994 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2973);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _2506 = _365_fa_pbr.z < 0.5f;\n    bool _2513;\n    if (!_2506)\n    {\n        _2513 = _2072_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2513 = _2506;\n    }\n    if (_2513)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2072_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2526 = fa_light_texel(param);\n    float _2527 = _2526.x;\n    if (_2527 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2536 = int(_2527 + 0.5f);\n    int param_1 = _2536;\n    float4 _2540 = fa_light_texel(param_1);\n    int param_2 = _2536 + 1;\n    float4 _2545 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2548 = _2540.y;\n    if (_2548 > 0.0f)\n    {\n        float _2565 = 1.0f - smoothstep(0.75f * _2548, _2548, length(world - _2072_fa_shadow_eye.xyz));\n        fade = _2565;\n        if (_2565 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2540.x > 1.5f)\n    {\n        int param_3 = li;\n        int param_4 = fa_light_base(param_3);\n        float3 param_5 = world - fa_light_texel(param_4).xyz;\n        face = fa_cube_face(param_5);\n    }\n    int _2594 = (_2536 + 2) + (face * 6);\n    int param_6 = _2594;\n    int param_7 = _2594 + 1;\n    int param_8 = _2594 + 3;\n    float4 _2608 = fa_light_texel(param_8);\n    int param_9 = _2594 + 4;\n    float4 _2613 = fa_light_texel(param_9);\n    int param_10 = _2594 + 5;\n    float4 _2618 = fa_light_texel(param_10);\n    float _2630 = _2618.x * max(dot(_2608, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2635 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2658 = clamp(dot(n, _2608.xyz), -1.0f, 1.0f);\n    int param_11 = li;\n    int param_12 = fa_light_base(param_11);\n    float _2682 = min(sqrt(1.0f - (_2658 * _2658)) / max(abs(dot(n, world - fa_light_texel(param_12).xyz)) / max(dot(_2608, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2685 = _2545.y;\n    float _2687;\n    if (_2685 > 0.0f)\n    {\n        _2687 = _2685;\n    }\n    else\n    {\n        _2687 = 1.5f * _2630;\n    }\n    float4 _2707 = float4(world + (n * (_2687 * sqrt(1.0f - (_2635 * _2635)))), 1.0f);\n    float _2711 = dot(_2608, _2707);\n    float _2714 = _2618.y;\n    if (_2711 < _2714)\n    {\n        return 1.0f;\n    }\n    float2 _2729 = float2(dot(fa_light_texel(param_6), _2707), dot(fa_light_texel(param_7), _2707)) / _2711.xx;\n    float _2731 = _2729.x;\n    bool _2734 = _2731 < _2613.x;\n    bool _2743;\n    if (!_2734)\n    {\n        _2743 = _2731 > _2613.z;\n    }\n    else\n    {\n        _2743 = _2734;\n    }\n    bool _2752;\n    if (!_2743)\n    {\n        _2752 = _2729.y < _2613.y;\n    }\n    else\n    {\n        _2752 = _2743;\n    }\n    bool _2761;\n    if (!_2752)\n    {\n        _2761 = _2729.y > _2613.w;\n    }\n    else\n    {\n        _2761 = _2752;\n    }\n    if (_2761)\n    {\n        return 1.0f;\n    }\n    float _2767 = _2545.x;\n    float _2769;\n    if (_2767 > 0.0f)\n    {\n        _2769 = _2767;\n    }\n    else\n    {\n        _2769 = 1.5f * _2630;\n    }\n    float2 param_13 = _2729;\n    float4 param_14 = _2613;\n    float param_15 = _2711 - (_2769 * (1.0f + (0.5f * _2682)));\n    float param_16 = _2630;\n    float param_17 = 1.0f;\n    float param_18 = _2618.z * 0.25f;\n    float param_19 = (_2630 * min(_2682, 3.0f)) * 0.5f;\n    float3 param_20 = float3(1.0f, _2714, _2618.z);\n    int param_21 = int(_2540.z + 0.5f);\n    float param_22 = _2540.w;\n    return lerp(1.0f, fa_shadow_filter(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _3925 = fa_lm.z > 0.5f;\n    bool _3931;\n    if (_3925)\n    {\n        int param = li;\n        _3931 = fa_light_baked(param);\n    }\n    else\n    {\n        _3931 = _3925;\n    }\n    if (_3931)\n    {\n        int param_1 = li;\n        LightSample _5038 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _5038;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3955 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _5040 = _3955.color;\n    float _5042 = _3955.shadow;\n    if ((_3955.type == 0) && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3955.direction;\n        float _3969 = fa_shadow_factor(param_5, param_6);\n        _5042 = _3969;\n        _5040 *= _3969;\n    }\n    else\n    {\n        bool _3980 = _3955.type != 0;\n        bool _3986;\n        if (_3980)\n        {\n            _3986 = _3955.attenuation > 0.0f;\n        }\n        else\n        {\n            _3986 = _3980;\n        }\n        if (_3986)\n        {\n            int param_7 = li;\n            float3 param_8 = world_pos;\n            float3 param_9 = gn;\n            float3 param_10 = _3955.direction;\n            float _3998 = fa_shadow_local(param_7, param_8, param_9, param_10);\n            _5042 = _3998;\n            _5040 *= _3998;\n        }\n    }\n    LightSample _5057 = { _3955.direction, _5040, _3955.attenuation, _5042, _3955._distance, _3955.type };\n    return _5057;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2072_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3018 = int(_2072_fa_shadow_cfg.x + 0.5f);\n    float _3028 = dot(world - _2072_fa_shadow_eye.xyz, _2072_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3033 = _3018 > 0;\n    bool _3042;\n    if (_3033)\n    {\n        int param = _3018 - 1;\n        _3042 = _3028 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3042 = _3033;\n    }\n    if (_3042)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3048 = _3018 > 1;\n        bool _3055;\n        if (_3048)\n        {\n            _3055 = _3028 > _2072_fa_shadow_split.x;\n        }\n        else\n        {\n            _3055 = _3048;\n        }\n        if (_3055)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3061 = _3018 > 2;\n        bool _3068;\n        if (_3061)\n        {\n            _3068 = _3028 > _2072_fa_shadow_split.y;\n        }\n        else\n        {\n            _3068 = _3061;\n        }\n        if (_3068)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3074 = _3018 > 3;\n        bool _3081;\n        if (_3074)\n        {\n            _3081 = _3028 > _2072_fa_shadow_split.z;\n        }\n        else\n        {\n            _3081 = _3074;\n        }\n        if (_3081)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _4749 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4749 = -_4749;\n    }\n    float3 _4384 = normalize(_365_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _4762 = { fa_world_pos, _4749, fa_world_tangent, fa_uv, fa_vertex_color, _4384, gl_FrontFacing };\n    SurfaceInput param_1 = _4762;\n    Surface _4392 = fa_standard_surface(param_1);\n    float3 _4788 = _4392.albedo;\n    float _4789 = _4392.alpha;\n    float3 _4790 = _4392.normal;\n    float _4791 = _4392.metallic;\n    float _4792 = _4392.roughness;\n    float _4793 = _4392.occlusion;\n    float3 _4794 = _4392.emission;\n    float _4795 = _4392.clearcoat;\n    float _4796 = _4392.clearcoat_roughness;\n    float3 _4797 = _4392.sheen_color;\n    float _4798 = _4392.sheen_roughness;\n    float _4799 = _4392.anisotropy;\n    float _4800 = _4392.anisotropy_rotation;\n    float _4801 = _4392.specular;\n    float _4802 = _4392.ior;\n    float3 _4803 = _4392.specular_color;\n    SurfaceInput _4770 = { fa_world_pos, _4749, fa_world_tangent, fa_uv, fa_vertex_color, _4384, gl_FrontFacing };\n    SurfaceInput param_2 = _4770;\n    Surface param_3 = _4392;\n    surface(param_2, param_3);\n    _4788 = param_3.albedo;\n    _4789 = param_3.alpha;\n    _4790 = param_3.normal;\n    _4791 = param_3.metallic;\n    _4792 = param_3.roughness;\n    _4793 = param_3.occlusion;\n    _4794 = param_3.emission;\n    _4795 = param_3.clearcoat;\n    _4796 = param_3.clearcoat_roughness;\n    _4797 = param_3.sheen_color;\n    _4798 = param_3.sheen_roughness;\n    _4799 = param_3.anisotropy;\n    _4800 = param_3.anisotropy_rotation;\n    _4801 = param_3.specular;\n    _4802 = param_3.ior;\n    _4803 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _4749;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4788 = param_6;\n    _4790 = param_7;\n    float3 result;\n    if (_365_fa_emissive.w > 0.5f)\n    {\n        result = _4788;\n    }\n    else\n    {\n        float3 _4430 = _4790;\n        float3 _4431 = normalize(_4430);\n        _4790 = _4431;\n        float3 param_8 = _4431;\n        SurfaceInput _4778 = { fa_world_pos, _4749, fa_world_tangent, fa_uv, fa_vertex_color, _4384, gl_FrontFacing };\n        SurfaceInput param_9 = _4778;\n        Surface _4869 = { _4788, _4789, _4790, _4791, _4792, _4793, _4794, _4795, _4796, _4797, _4798, _4799, _4800, _4801, _4802, _4803 };\n        Surface param_10 = _4869;\n        float3 param_11 = fa_indirect_diffuse(param_8);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _4450 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4450; ln++)\n        {\n            int param_12 = ln;\n            int _4463 = fa_cl_light(param_12);\n            bool _4466 = fa_lm.z > 0.5f;\n            bool _4472;\n            if (_4466)\n            {\n                int param_13 = _4463;\n                _4472 = fa_light_baked(param_13);\n            }\n            else\n            {\n                _4472 = _4466;\n            }\n            if (_4472)\n            {\n                continue;\n            }\n            int param_14 = _4463;\n            float3 param_15 = fa_world_pos;\n            float3 param_16 = _4749;\n            LightSample _4484 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput _4786 = { fa_world_pos, _4749, fa_world_tangent, fa_uv, fa_vertex_color, _4384, gl_FrontFacing };\n            SurfaceInput param_17 = _4786;\n            Surface _4886 = { _4788, _4789, _4790, _4791, _4792, _4793, _4794, _4795, _4796, _4797, _4798, _4799, _4800, _4801, _4802, _4803 };\n            Surface param_18 = _4886;\n            LightSample param_19 = _4484;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _4499 = result;\n    float3 _4500 = _4499 + _4794;\n    result = _4500;\n    float3 param_20 = _4500;\n    float3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _4509 = _365_fa_fog.w > 0.0f;\n    bool _4516;\n    if (!_4509)\n    {\n        _4516 = _365_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _4516 = _4509;\n    }\n    if (_4516)\n    {\n        float3 _4525 = fa_world_pos - _365_fa_camera_pos.xyz;\n        float _4531 = dot(_4525, _365_fa_fog_c.xyz);\n        bool _4535 = _365_fa_fog_c.w > 0.5f;\n        float _4536;\n        if (_4535)\n        {\n            _4536 = _4531;\n        }\n        else\n        {\n            _4536 = length(_4525);\n        }\n        float _4548 = _4536 - _365_fa_fog_b.x;\n        if (_4548 > 0.0f)\n        {\n            float _4557 = _365_fa_fog.w * _4548;\n            float tau = _4557 * _4557;\n            if (_365_fa_fog_b.y > 0.0f)\n            {\n                float _4573;\n                if (_4535)\n                {\n                    _4573 = fa_world_pos.y - (_365_fa_fog_c.y * _4531);\n                }\n                else\n                {\n                    _4573 = _365_fa_camera_pos.y;\n                }\n                float _4594 = lerp(_4573, fa_world_pos.y, clamp(_365_fa_fog_b.x / _4536, 0.0f, 1.0f));\n                float _4598 = fa_world_pos.y - _4594;\n                float _4603 = _4594 - _365_fa_fog_b.z;\n                float _4608 = fa_world_pos.y - _365_fa_fog_b.z;\n                bool _4611 = _4603 <= 0.0f;\n                bool _4612 = !_4611;\n                bool _4618;\n                if (_4612)\n                {\n                    _4618 = _365_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4618 = _4611;\n                }\n                float _4619;\n                if (_4618)\n                {\n                    _4619 = _365_fa_fog_b.y;\n                }\n                else\n                {\n                    _4619 = _365_fa_fog_b.y * exp(-min(_365_fa_fog_b.w * _4603, 80.0f));\n                }\n                bool _4646;\n                if (_4612)\n                {\n                    _4646 = _365_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4646 = _4611;\n                }\n                float _4647;\n                if (_4646)\n                {\n                    _4647 = _365_fa_fog_b.y * _4603;\n                }\n                else\n                {\n                    _4647 = (_365_fa_fog_b.y * (1.0f - exp(-min(_365_fa_fog_b.w * _4603, 80.0f)))) / _365_fa_fog_b.w;\n                }\n                bool _4672 = _4608 <= 0.0f;\n                bool _4679;\n                if (!_4672)\n                {\n                    _4679 = _365_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4679 = _4672;\n                }\n                float _4680;\n                if (_4679)\n                {\n                    _4680 = _365_fa_fog_b.y * _4608;\n                }\n                else\n                {\n                    _4680 = (_365_fa_fog_b.y * (1.0f - exp(-min(_365_fa_fog_b.w * _4608, 80.0f)))) / _365_fa_fog_b.w;\n                }\n                float _4707;\n                if (abs(_4598) < 0.001000000047497451305389404296875f)\n                {\n                    _4707 = _4619;\n                }\n                else\n                {\n                    _4707 = (_4680 - _4647) / _4598;\n                }\n                tau += (_4548 * max(_4707, 0.0f));\n            }\n            result = lerp(result, _365_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4789);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_365",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2072",
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
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
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
          }
        ]
      }
    },
    "prepass": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _292 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _292;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _299 = _160.world_pos;\n    float4 _171 = float4(_299, 1.0f);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -mul(_171, _131_fa_light_vp).z;\n    fa_pre_r0 = float3(_131_fa_light_vp[0].x, _131_fa_light_vp[1].x, _131_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131_fa_light_vp[0].y, _131_fa_light_vp[1].y, _131_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131_fa_light_vp[0].z, _131_fa_light_vp[1].z, _131_fa_light_vp[2].z);\n    gl_Position = mul(_171, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _785 = base_t;\n    _785.x = _225.x;\n    _785.y = _225.y;\n    _785.z = _225.z;\n    base_t = _785;\n    float4 _241 = (_785 * _213_fa_base_color) * i.vertex_color;\n    float3 _748 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _793 = _279;\n        _793.x = _284.x;\n        _793.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _793;\n        _748 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _796 = mrt;\n    _796.x = _313.x;\n    _796.y = _313.y;\n    _796.z = _313.z;\n    mrt = _796;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _753 = _213_fa_layers_a.x;\n    float _754 = _213_fa_layers_a.y;\n    float _757 = _213_fa_layers_a.z;\n    float _756 = _213_fa_layers_b.w;\n    float _759 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _753 *= _355.y;\n            _754 *= _355.z;\n            _756 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _757 *= mrt.x;\n            _759 *= mrt.w;\n        }\n    }\n    Surface _778 = { _241.xyz, _241.w, _748, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _753, _754, _213_fa_layers_b.xyz, _756, _757, _213_fa_layers_a.w, _759, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _778;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _659 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _659 = -_659;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _672 = { fa_world_pos, _659, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _672;\n    SurfaceInput _680 = { fa_world_pos, _659, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _680;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _785 = base_t;\n    _785.x = _225.x;\n    _785.y = _225.y;\n    _785.z = _225.z;\n    base_t = _785;\n    float4 _241 = (_785 * _213_fa_base_color) * i.vertex_color;\n    float3 _748 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _793 = _279;\n        _793.x = _284.x;\n        _793.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _793;\n        _748 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _796 = mrt;\n    _796.x = _313.x;\n    _796.y = _313.y;\n    _796.z = _313.z;\n    mrt = _796;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _753 = _213_fa_layers_a.x;\n    float _754 = _213_fa_layers_a.y;\n    float _757 = _213_fa_layers_a.z;\n    float _756 = _213_fa_layers_b.w;\n    float _759 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _753 *= _355.y;\n            _754 *= _355.z;\n            _756 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _757 *= mrt.x;\n            _759 *= mrt.w;\n        }\n    }\n    Surface _778 = { _241.xyz, _241.w, _748, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _753, _754, _213_fa_layers_b.xyz, _756, _757, _213_fa_layers_a.w, _759, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _778;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _659 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _659 = -_659;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _672 = { fa_world_pos, _659, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _672;\n    SurfaceInput _680 = { fa_world_pos, _659, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _680;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
