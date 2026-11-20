{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "57cbd5df71b0000e548dcd5fbfe873bc15510a64a336f6248792368f21adbf33",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _260 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _260;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_267, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _4155[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _482_fa_camera_pos : packoffset(c0);\n    float4 _482_fa_ambient : packoffset(c1);\n    float4 _482_fa_base_color : packoffset(c2);\n    float4 _482_fa_emissive : packoffset(c3);\n    float4 _482_fa_model_emissive : packoffset(c4);\n    float4 _482_fa_pbr : packoffset(c5);\n    float4 _482_fa_maps : packoffset(c6);\n    float4 _482_fa_fog : packoffset(c7);\n    float4 _482_fa_fog_b : packoffset(c8);\n    float4 _482_fa_fog_c : packoffset(c9);\n    float4 _482_fa_counts : packoffset(c10);\n    float4 _482_fa_env_sky : packoffset(c11);\n    float4 _482_fa_env_horizon : packoffset(c12);\n    float4 _482_fa_time : packoffset(c13);\n    float4 _482_fa_cl_vpx : packoffset(c14);\n    float4 _482_fa_cl_vpy : packoffset(c15);\n    float4 _482_fa_cl_vpw : packoffset(c16);\n    float4 _482_fa_cl_fwd : packoffset(c17);\n    float4 _482_fa_cl_grid : packoffset(c18);\n    float4 _482_fa_cl_info : packoffset(c19);\n    float4 _482_fa_layers_a : packoffset(c20);\n    float4 _482_fa_layers_b : packoffset(c21);\n    float4 _482_fa_layers_c : packoffset(c22);\n    float4 _482_fa_layers_d : packoffset(c23);\n    float4 _482_fa_ct_a : packoffset(c24);\n    float4 _482_fa_ct_b : packoffset(c25);\n    float4 _482_fa_ct_vpx : packoffset(c26);\n    float4 _482_fa_ct_vpy : packoffset(c27);\n    float4 _482_fa_ct_vpw : packoffset(c28);\n    float4 _482_fa_ct_fwd : packoffset(c29);\n    float4 _482_fa_probe_sh[9] : packoffset(c30);\n    float4 _482_fa_atlas : packoffset(c39);\n    float4 _482_fa_rpa_tile : packoffset(c40);\n    float4 _482_fa_rpa_pos : packoffset(c41);\n    float4 _482_fa_rpa_bx : packoffset(c42);\n    float4 _482_fa_rpa_by : packoffset(c43);\n    float4 _482_fa_rpa_bz : packoffset(c44);\n    float4 _482_fa_rpb_tile : packoffset(c45);\n    float4 _482_fa_rpb_pos : packoffset(c46);\n    float4 _482_fa_rpb_bx : packoffset(c47);\n    float4 _482_fa_rpb_by : packoffset(c48);\n    float4 _482_fa_rpb_bz : packoffset(c49);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2139_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2139_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2139_fa_shadow_info[4] : packoffset(c20);\n    float4 _2139_fa_shadow_split : packoffset(c24);\n    float4 _2139_fa_shadow_cfg : packoffset(c25);\n    float4 _2139_fa_shadow_bias : packoffset(c26);\n    float4 _2139_fa_shadow_eye : packoffset(c27);\n    float4 _2139_fa_shadow_fwd : packoffset(c28);\n    float4 _2139_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_probe_atlas : register(t6);\nTexture2D<float4> fa_screen_tex : register(t11);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1410 = _482_fa_cl_info.x < 0.0f;\n    bool _1417;\n    if (!_1410)\n    {\n        _1417 = _482_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1417 = _1410;\n    }\n    bool _1425;\n    if (!_1417)\n    {\n        _1425 = _482_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1425 = _1417;\n    }\n    bool _1432;\n    if (!_1425)\n    {\n        _1432 = _482_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1432 = _1425;\n    }\n    bool _1439;\n    if (!_1432)\n    {\n        _1439 = _482_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1439 = _1432;\n    }\n    if (_1439)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1449 = float4(world_pos, 1.0f);\n    float _1455 = dot(_482_fa_cl_vpw, _1449);\n    if (!(_1455 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1477 = float2(dot(_482_fa_cl_vpx, _1449), dot(_482_fa_cl_vpy, _1449)) / _1455.xx;\n    int _1481 = int(_482_fa_cl_grid.x);\n    int _1485 = int(_482_fa_cl_grid.y);\n    int param = (int(_482_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_482_fa_cl_fwd.xyz, world_pos) + _482_fa_cl_fwd.w, _482_fa_cl_grid.w) / _482_fa_cl_grid.w) * _482_fa_cl_grid.z)), 0, int(_482_fa_cl_info.y) - 1) * _1485) + clamp(int(floor(((_1477.y * 0.5f) + 0.5f) * _482_fa_cl_grid.y)), 0, _1485 - 1)) * _1481)) + clamp(int(floor(((_1477.x * 0.5f) + 0.5f) * _482_fa_cl_grid.x)), 0, _1481 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1561 = fa_cluster_texel(param);\n    return int2(int(_1561.x), int(_1561.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_482_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4964 = fa_cluster_lookup(param);\n    fa_cl_slot = _4964.x;\n    fa_cl_local = _4964.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _5176 = fa_linear_to_srgb(param);\n        c = _5176;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _5184 = fa_srgb_to_linear(param_1);\n            c = _5184;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _364;\n    if (i.front_facing)\n    {\n        _364 = i.world_normal;\n    }\n    else\n    {\n        _364 = -i.world_normal;\n    }\n    float3 _388 = normalize(i.world_tangent.xyz - (_364 * dot(_364, i.world_tangent.xyz)));\n    float3 _415 = normalize(((_388 * m.x) + ((cross(_364, _388) * i.world_tangent.w) * m.y)) + (_364 * m.z));\n    float3 _418;\n    if (i.front_facing)\n    {\n        _418 = _415;\n    }\n    else\n    {\n        _418 = -_415;\n    }\n    return _418;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _482_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _5215 = fa_tex_fix(param_2, param_3);\n    float4 _6400 = base_t;\n    _6400.x = _5215.x;\n    _6400.y = _5215.y;\n    _6400.z = _5215.z;\n    base_t = _6400;\n    float4 _5229 = (_6400 * _482_fa_base_color) * i.vertex_color;\n    float3 _6214 = i.world_normal;\n    if (_482_fa_maps.z > 0.5f)\n    {\n        float param_4 = _482_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _5261 = fa_tex_fix(param_6, param_7);\n        float3 _5264 = (_5261 * 2.0f) - 1.0f.xxx;\n        float2 _5269 = _5264.xy * _482_fa_maps.x;\n        float3 _6408 = _5264;\n        _6408.x = _5269.x;\n        _6408.y = _5269.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _6408;\n        _6214 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _482_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _5297 = fa_tex_fix(param_12, param_13);\n    float4 _6411 = mrt;\n    _6411.x = _5297.x;\n    _6411.y = _5297.y;\n    _6411.z = _5297.z;\n    mrt = _6411;\n    float4 _5325 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _482_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _5325.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _5336 = fa_tex_fix(param_16, param_17);\n    float param_18 = _482_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _5366 = fa_tex_fix(param_20, param_21);\n    float _6219 = _482_fa_layers_a.x;\n    float _6220 = _482_fa_layers_a.y;\n    float _6223 = _482_fa_layers_a.z;\n    float _6222 = _482_fa_layers_b.w;\n    float _6225 = _482_fa_layers_c.x;\n    if (_482_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_482_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _6219 *= _5336.y;\n            _6220 *= _5336.z;\n            _6222 *= _5325.w;\n        }\n        if (_482_fa_layers_c.z > 1.5f)\n        {\n            _6223 *= mrt.x;\n            _6225 *= mrt.w;\n        }\n    }\n    Surface _6244 = { _5229.xyz, _5229.w, _6214, clamp(_482_fa_pbr.x * _5297.z, 0.0f, 1.0f), clamp(_482_fa_pbr.y * _5297.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_482_fa_maps.y * (_5336.x - 1.0f)), _482_fa_emissive.xyz + (_482_fa_model_emissive.xyz * _5366), _6219, _6220, _482_fa_layers_b.xyz, _6222, _6223, _482_fa_layers_a.w, _6225, _482_fa_layers_c.y, _482_fa_layers_d.xyz };\n    return _6244;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1641 = rect.zw - rect.xy;\n    float2 _1645 = _1641 * atlas;\n    float2 _1649 = ddx * _1645;\n    float2 _1653 = ddy * _1645;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1641), clamp(0.5f * log2(max(max(dot(_1649, _1649), dot(_1653, _1653)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1686 = _482_fa_counts.y < 0.5f;\n    bool _1693;\n    if (!_1686)\n    {\n        _1693 = _482_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1693 = _1686;\n    }\n    if (_1693)\n    {\n        return;\n    }\n    float3 _1699 = ddx(world_pos);\n    float3 _1702 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1706 = fa_cluster_texel(param);\n    int _1710 = int(_1706.w);\n    if (_1710 < 1)\n    {\n        return;\n    }\n    int _1720 = int(_482_fa_counts.y + 0.5f);\n    int param_1 = _1720;\n    float4 _1724 = fa_light_texel(param_1);\n    float2 _1727 = _1724.yz;\n    int _1731 = int(_1724.w);\n    int param_2 = _1720 + 1;\n    float4 _1736 = fa_light_texel(param_2);\n    float _1737 = _1736.x;\n    int _1743 = int(_482_fa_counts.w + 0.5f) - 1;\n    int _1747 = int(_1706.z);\n    float3 _2012;\n    for (int k = 0; k < _1710; k++)\n    {\n        int _1760 = _1747 + k;\n        int param_3 = _1731 + (_1760 >> 2);\n        int _1777 = (_1720 + 2) + (int(fa_light_texel(param_3)[_1760 & 3]) * 7);\n        int param_4 = _1777 + 6;\n        float4 _1782 = fa_light_texel(param_4);\n        if (((int(_1782.w + 0.5f) >> _1743) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1777;\n        float4 _1797 = fa_light_texel(param_5);\n        int param_6 = _1777 + 1;\n        float4 _1802 = fa_light_texel(param_6);\n        int param_7 = _1777 + 2;\n        float4 _1807 = fa_light_texel(param_7);\n        float3 _1810 = _1797.xyz;\n        float _1815 = dot(_1810, world_pos) + _1797.w;\n        float3 _1817 = _1802.xyz;\n        float _1822 = dot(_1817, world_pos) + _1802.w;\n        float3 _1824 = _1807.xyz;\n        float _1829 = dot(_1824, world_pos) + _1807.w;\n        bool _1834 = abs(_1815) > 0.5f;\n        bool _1842;\n        if (!_1834)\n        {\n            _1842 = abs(_1822) > 0.5f;\n        }\n        else\n        {\n            _1842 = _1834;\n        }\n        bool _1850;\n        if (!_1842)\n        {\n            _1850 = abs(_1829) > 0.5f;\n        }\n        else\n        {\n            _1850 = _1842;\n        }\n        if (_1850)\n        {\n            continue;\n        }\n        float _1865 = clamp(dot(geo_normal, normalize(_1824)) * _1782.z, 0.0f, 1.0f);\n        if (_1865 <= 0.0f)\n        {\n            continue;\n        }\n        float _1885 = (clamp((0.5f - abs(_1829)) * 10.0f, 0.0f, 1.0f) * _1865) * _1782.x;\n        float2 _1893 = float2(_1815 + 0.5f, 0.5f - _1822);\n        float2 _1903 = float2(dot(_1810, _1699), dot(_1817, _1699));\n        float2 _1913 = float2(dot(_1810, _1702), dot(_1817, _1702));\n        int param_8 = _1777 + 5;\n        float4 _1918 = fa_light_texel(param_8);\n        int param_9 = _1777 + 3;\n        float4 _1923 = fa_light_texel(param_9);\n        int param_10 = _1777 + 4;\n        float4 _1928 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1918.xyz;\n        bool _1938 = _1923.z > _1923.x;\n        if (_1938)\n        {\n            float4 param_11 = _1923;\n            float2 param_12 = _1893;\n            float2 param_13 = _1727;\n            float2 param_14 = _1903;\n            float2 param_15 = _1913;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1737 > 0.5f) && (_1737 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1964 = fa_dc_to_linear(param_16);\n                float4 _6294 = tx;\n                _6294.x = _1964.x;\n                _6294.y = _1964.y;\n                _6294.z = _1964.z;\n                tx = _6294;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1885 * tex_a) * _1918.w, 0.0f, 1.0f).xxx);\n        if (_1928.z > _1928.x)\n        {\n            float4 param_17 = _1928;\n            float2 param_18 = _1893;\n            float2 param_19 = _1727;\n            float2 param_20 = _1903;\n            float2 param_21 = _1913;\n            float4 _2008 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1737 > 1.5f)\n            {\n                float3 param_22 = _2008.xyz;\n                float3 _2018 = fa_dc_to_srgb(param_22);\n                _2012 = _2018;\n            }\n            else\n            {\n                _2012 = _2008.xyz;\n            }\n            float3 _2027 = (_2012 * 2.0f) - 1.0f.xxx;\n            float2 _2032 = _2027.xy * _1782.y;\n            float3 _2054 = (normalize(_1810) * _2032.x) + (normalize(_1817) * _2032.y);\n            float3 _2057 = normalize(normal);\n            normal = normalize(lerp(_2057, normalize((_2057 * max(_2027.z, 0.0500000007450580596923828125f)) + (_2054 - (_2057 * dot(_2057, _2054)))), clamp(_1885 * (_1938 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3311_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3311_dummy_parameter)));\n}\n\nfloat3 fa_probe_sh_coef(float2 origin, float res, int k)\n{\n    float3 v = fa_probe_atlas.SampleLevel(fa_env_smp, (origin + float2(float(k) + 0.5f, res + 2.5f)) / fa_atlas_size(), 0.0f).xyz;\n    if (_482_fa_atlas.y > 0.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3252 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3252;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    float _3862 = (1.0f - _482_fa_rpa_tile.w) - _482_fa_rpb_tile.w;\n    float3 amb = 0.0f.xxx;\n    bool _3867 = _482_fa_env_sky.w > 0.5f;\n    float3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = 0.0f.xxx;\n    }\n    if (_3862 > 0.0005000000237487256526947021484375f)\n    {\n        if (_3867)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _482_fa_atlas.zw;\n                float param_1 = 128.0f;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3862;\n            }\n        }\n        else\n        {\n            amb = _482_fa_ambient.xyz * _3862;\n        }\n    }\n    bool _3918 = _482_fa_rpa_tile.w > 0.0f;\n    if (_3918)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _482_fa_rpa_tile.xy;\n            float param_4 = _482_fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * _482_fa_rpa_tile.w);\n        }\n    }\n    bool _3949 = _482_fa_rpb_tile.w > 0.0f;\n    if (_3949)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _482_fa_rpb_tile.xy;\n            float param_7 = _482_fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * _482_fa_rpb_tile.w);\n        }\n    }\n    if ((_3867 || _3918) || _3949)\n    {\n        float3 param_9[9] = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_482_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _482_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_482_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4081 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _4088 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _4091 = int(_4081);\n    int _4094 = int(_4088);\n    float _4104 = _4088 - float(_4094);\n    int _4159 = (_4091 * 9) + _4094;\n    int _4179 = ((_4091 + 1) * 9) + _4094;\n    return lerp(lerp(_4155[_4159], _4155[_4159 + 1], _4104), lerp(_4155[_4179], _4155[_4179 + 1], _4104), _4081 - float(_4091));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _6073 = false;\n    float _6074 = 1.0f;\n    float _6075 = 1.0f;\n    float _6076 = 1.0f;\n    float _6077 = 0.0f;\n    float _6078 = 0.0f;\n    float _6079 = 0.0f;\n    float _6080 = 0.0f;\n    float _6082 = 1.0f;\n    bool _6083 = false;\n    float3 _6084 = 0.0f.xxx;\n    float _6085 = 1.0f;\n    float _6086 = 1.0f;\n    float _6087 = 1.0f;\n    float _6088 = 0.0f;\n    float _6089 = 0.0f;\n    float3 _6090 = float3(1.0f, 0.0f, 0.0f);\n    float3 _6091 = float3(0.0f, 0.0f, 1.0f);\n    float _6092 = 1.0f;\n    float _6093 = 1.0f;\n    float _4230 = clamp(s.specular, 0.0f, 1.0f);\n    float _4234 = clamp(s.ior, 1.0f, 3.0f);\n    bool _4239 = (_4230 != 1.0f) || (_4234 != 1.5f);\n    bool _4248;\n    if (!_4239)\n    {\n        _4248 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _4248 = _4239;\n    }\n    if (_4248)\n    {\n        float _4256 = (_4234 - 1.0f) / (_4234 + 1.0f);\n        f0 = lerp(min((_4256 * _4256).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _4230, s.albedo, metallic.xxx);\n        _6074 = lerp(_4230, 1.0f, metallic);\n        _6073 = true;\n    }\n    float _4283 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_4283 > 0.0f)\n    {\n        float _4291 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _6077 = _4283;\n        _6078 = _4291;\n        float _4298 = _4291 * _4291;\n        _6079 = _4298;\n        _6080 = _4298 * _4298;\n        float _4310 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _6082 = _4310;\n        _6075 = 1.0f - (_4283 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _4310, 0.0f, 1.0f), 5.0f))));\n        _6073 = true;\n    }\n    float3 _4329 = max(s.sheen_color, 0.0f.xxx);\n    float _4338 = max(_4329.x, max(_4329.y, _4329.z));\n    if (_4338 > 0.0f)\n    {\n        float _4346 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _6083 = true;\n        _6084 = _4329;\n        _6085 = _4346;\n        _6086 = _4346 * _4346;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _4346;\n        float _4363 = fa_sheen_albedo(param, param_1);\n        _6088 = _4363;\n        _6087 = 1.0f - min(_4338 * _4363, 1.0f);\n        _6073 = true;\n    }\n    _6076 = _6075 * _6087;\n    float _4382 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_4382 != 0.0f)\n    {\n        float3 _4397 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _4397;\n        if (dot(_4397, _4397) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _4409 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_4409.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _4409.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _4409.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _4413 = t;\n        float3 _4414 = normalize(_4413);\n        t = _4414;\n        float3 _4439 = normalize((_4414 * cos(s.anisotropy_rotation)) + ((cross(n, _4414) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _6090 = _4439;\n        _6091 = cross(n, _4439);\n        float _4449 = roughness * roughness;\n        float _4455 = lerp(_4449, 1.0f, _4382 * _4382);\n        bool _4457 = _4382 > 0.0f;\n        _6092 = _4457 ? _4455 : _4449;\n        _6093 = _4457 ? _4449 : _4455;\n        _6089 = _4382;\n        _6073 = true;\n    }\n    FaLayers _6115 = { _6073, _6074, _6075, _6076, _6077, _6078, _6079, _6080, i.world_normal, _6082, _6083, _6084, _6085, _6086, _6087, _6088, _6089, _6090, _6091, _6092, _6093 };\n    return _6115;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _4013 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _4016 = _4013.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_4016 * _4016, exp2((-9.27999973297119140625f) * ndv)) * _4016) + _4013.y)) + _4013.zw;\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3272 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3275 = _3272.x;\n    float _3277 = _3272.z;\n    float2 e = float2(_3275, _3277);\n    if (_3272.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3277)) * ((_3275 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3275)) * ((_3277 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat3 fa_probe_level(float2 origin, float res, int lv, float2 e)\n{\n    float _3324;\n    if (lv == 0)\n    {\n        _3324 = 0.0f;\n    }\n    else\n    {\n        _3324 = res + 2.0f;\n    }\n    float _3334;\n    if (lv == 0)\n    {\n        _3334 = 0.0f;\n    }\n    else\n    {\n        _3334 = (res - (res / float(1 << (lv - 1)))) + (2.0f * float(lv - 1));\n    }\n    return fa_probe_atlas.SampleLevel(fa_env_smp, (((origin + float2(_3324, _3334)) + 1.0f.xx) + (((e * 0.5f) + 0.5f.xx) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0f).xyz;\n}\n\nfloat3 fa_probe_radiance(float2 origin, float res, float3 d, float rough)\n{\n    float _3379;\n    if (res > 64.5f)\n    {\n        _3379 = 5.0f;\n    }\n    else\n    {\n        _3379 = (res > 32.5f) ? 4.0f : 3.0f;\n    }\n    float _3394 = clamp(rough, 0.0f, 1.0f) * (_3379 - 1.0f);\n    int _3401 = int(min(floor(_3394), _3379 - 2.0f));\n    float _3406 = _3394 - float(_3401);\n    float3 param = d;\n    float2 _3410 = fa_oct_encode(param);\n    float2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3401;\n    float2 param_4 = _3410;\n    float3 _3420 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3406 < 0.00200000009499490261077880859375f)\n    {\n        return _3420;\n    }\n    float2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3401 + 1;\n    float2 param_8 = _3410;\n    return lerp(_3420, fa_probe_level(param_5, param_6, param_7, param_8), _3406.xxx);\n}\n\nfloat3 fa_probe_box_dir(float3 d, float4 posw, float4 bx, float4 by, float4 bz)\n{\n    if (posw.w < 0.5f)\n    {\n        return d;\n    }\n    float _3490 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3497 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3504 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3510 = dot(bx.xyz, d);\n    float _3514 = dot(by.xyz, d);\n    float _3518 = dot(bz.xyz, d);\n    float _3524;\n    if (_3510 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3524 = (1.0f - _3490) / _3510;\n    }\n    else\n    {\n        float _3538;\n        if (_3510 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3538 = ((-1.0f) - _3490) / _3510;\n        }\n        else\n        {\n            _3538 = 1000000015047466219876688855040.0f;\n        }\n        _3524 = _3538;\n    }\n    float tx = _3524;\n    float _3555;\n    if (_3514 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3555 = (1.0f - _3497) / _3514;\n    }\n    else\n    {\n        float _3568;\n        if (_3514 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3568 = ((-1.0f) - _3497) / _3514;\n        }\n        else\n        {\n            _3568 = 1000000015047466219876688855040.0f;\n        }\n        _3555 = _3568;\n    }\n    float ty = _3555;\n    float _3584;\n    if (_3518 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3584 = (1.0f - _3504) / _3518;\n    }\n    else\n    {\n        float _3597;\n        if (_3518 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3597 = ((-1.0f) - _3504) / _3518;\n        }\n        else\n        {\n            _3597 = 1000000015047466219876688855040.0f;\n        }\n        _3584 = _3597;\n    }\n    float _3609 = tx;\n    float _3612 = (_3609 > 0.0f) ? _3609 : 1000000015047466219876688855040.0f;\n    tx = _3612;\n    float _3613 = ty;\n    float _3616 = (_3613 > 0.0f) ? _3613 : 1000000015047466219876688855040.0f;\n    ty = _3616;\n    float _3626 = min(_3612, min(_3616, (_3584 > 0.0f) ? _3584 : 1000000015047466219876688855040.0f));\n    if (_3626 > 100000001504746621987668885504.0f)\n    {\n        return d;\n    }\n    float3 _3642 = (fa_world_pos + (d * _3626)) - posw.xyz;\n    float3 _3647;\n    if (dot(_3642, _3642) > 1.0000000133514319600180897396058e-10f)\n    {\n        _3647 = normalize(_3642);\n    }\n    else\n    {\n        _3647 = d;\n    }\n    return _3647;\n}\n\nfloat3 fa_probe_environment(float4 tile, float4 posw, float4 bx, float4 by, float4 bz, inout float3 d, float rough)\n{\n    float3 param = d;\n    float4 param_1 = posw;\n    float4 param_2 = bx;\n    float4 param_3 = by;\n    float4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    float2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    float3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _3693 = (1.0f - _482_fa_rpa_tile.w) - _482_fa_rpb_tile.w;\n    float3 outc = 0.0f.xxx;\n    if (_3693 > 0.0005000000237487256526947021484375f)\n    {\n        float3 base;\n        if (_482_fa_env_sky.w > 0.5f)\n        {\n            float2 param = _482_fa_atlas.zw;\n            float param_1 = 128.0f;\n            float3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3722 = rough * rough;\n            float _3753 = 0.60000002384185791015625f * _3722;\n            base = lerp(lerp(_482_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_482_fa_env_horizon.xyz, _482_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3722)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3753, 0.0500000007450580596923828125f + _3753, d.y).xxx), ((_482_fa_env_sky.xyz + _482_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3722 * 0.60000002384185791015625f).xxx);\n        }\n        outc = base * _3693;\n    }\n    if (_482_fa_rpa_tile.w > 0.0f)\n    {\n        float4 param_4 = _482_fa_rpa_tile;\n        float4 param_5 = _482_fa_rpa_pos;\n        float4 param_6 = _482_fa_rpa_bx;\n        float4 param_7 = _482_fa_rpa_by;\n        float4 param_8 = _482_fa_rpa_bz;\n        float3 param_9 = d;\n        float param_10 = rough;\n        float3 _3812 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3812 * _482_fa_rpa_tile.w);\n    }\n    if (_482_fa_rpb_tile.w > 0.0f)\n    {\n        float4 param_11 = _482_fa_rpb_tile;\n        float4 param_12 = _482_fa_rpb_pos;\n        float4 param_13 = _482_fa_rpb_bx;\n        float4 param_14 = _482_fa_rpb_by;\n        float4 param_15 = _482_fa_rpb_bz;\n        float3 param_16 = d;\n        float param_17 = rough;\n        float3 _3844 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_3844 * _482_fa_rpb_tile.w);\n    }\n    return outc;\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _4490;\n        if (L.aniso >= 0.0f)\n        {\n            _4490 = L.b;\n        }\n        else\n        {\n            _4490 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_4490, v), _4490), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4523 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _4523.x) + (L.f90.xxx * _4523.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _4578 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _4578.x) + _4578.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4055 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4055.x) + _4055.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _4607 = clamp(s.metallic, 0.0f, 1.0f);\n    float _4611 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _4618 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _4607.xxx);\n    float3 f0 = _4618;\n    float3 _4622 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _4622;\n    float3 param_3 = i.view_dir;\n    float param_4 = _4607;\n    float param_5 = _4611;\n    float3 param_6 = _4618;\n    FaLayers _4639 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4639.on)\n    {\n        FaLayers param_7 = _4639;\n        float3 param_8 = _4622;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _4611;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _4622;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _4611;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_482_fa_cl_info.x) + int(_482_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_482_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4934;\n    if (fa_lm.z > 0.5f)\n    {\n        _4934 = 0.0f;\n    }\n    else\n    {\n        _4934 = 1.0f - clamp(_482_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _4945 = _4934 < 1.0f;\n    bool _4951;\n    if (_4945)\n    {\n        int param = li;\n        _4951 = fa_light_baked(param);\n    }\n    else\n    {\n        _4951 = _4945;\n    }\n    return _4951 ? _4934 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _541_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _541_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _660 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _673 = (c - (ru * hx)) - p;\n        float3 _679 = ru * (2.0f * hx);\n        float _685 = max(dot(_679, _679), 9.9999999392252902907785028219223e-09f);\n        float _689 = dot(_673, _679);\n        float t = clamp((-_689) / _685, 0.0f, 1.0f);\n        if (_660)\n        {\n            float _704 = dot(r, _679);\n            float _710 = _685 - (_704 * _704);\n            if (abs(_710) > (9.9999997473787516355514526367188e-06f * _685))\n            {\n                t = clamp(((dot(r, _673) * _704) - _689) / _710, 0.0f, 1.0f);\n            }\n        }\n        return (p + _673) + (_679 * t);\n    }\n    float3 q = p;\n    float _742 = dot(r, axis);\n    bool _750;\n    if (_660)\n    {\n        _750 = abs(_742) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _750 = _660;\n    }\n    if (_750)\n    {\n        float _760 = dot(c - p, axis) / _742;\n        if (_760 > 0.0f)\n        {\n            q = p + (r * _760);\n        }\n    }\n    float3 _773 = q - c;\n    float2 xy = float2(dot(_773, ru), dot(_773, uu));\n    if (shape > 0.5f)\n    {\n        float _788 = length(xy);\n        if (_788 > hx)\n        {\n            xy *= (hx / _788);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _430 = abs(d);\n    float _432 = _430.x;\n    float _434 = _430.y;\n    bool _435 = _432 >= _434;\n    bool _443;\n    if (_435)\n    {\n        _443 = _432 >= _430.z;\n    }\n    else\n    {\n        _443 = _435;\n    }\n    int _444;\n    if (_443)\n    {\n        _444 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _459;\n        if (_434 >= _430.z)\n        {\n            _459 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _459 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _444 = _459;\n    }\n    return _444;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _580 = dot(d, right);\n    float _584 = dot(d, up);\n    float _595;\n    if (((_580 * _580) + (_584 * _584)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _595 = atan2(_584, _580) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _595 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_595 - floor(_595)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _826 = fa_light_base(param);\n    bool _830 = _482_fa_ambient.w > 4.5f;\n    int param_1 = _826;\n    float4 _834 = fa_light_texel(param_1);\n    int param_2 = _826 + 1;\n    float4 _839 = fa_light_texel(param_2);\n    float _842 = _839.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _854 = _830 && (_842 > 2.5f);\n    fa_light_is_area = _854;\n    bool _856 = _842 < 0.5f;\n    float3 l;\n    if (_856)\n    {\n        l = normalize(_834.xyz);\n        if (_830)\n        {\n            int param_3 = _826 + 6;\n            float4 _870 = fa_light_texel(param_3);\n            if (_870.z > 0.5f)\n            {\n                int param_4 = _826 + 4;\n                float4 _880 = fa_light_texel(param_4);\n                int param_5 = _826 + 5;\n                float4 _885 = fa_light_texel(param_5);\n                float2 param_6 = _870.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _880.xyz) * _880.w, (-dot(world_pos, _885.xyz)) * _885.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _915 = _834.xyz;\n        float3 _917 = _915 - world_pos;\n        float3 to_light = _917;\n        float _920 = length(_917);\n        float reach = _920;\n        bool front = true;\n        if (_854)\n        {\n            int param_8 = _826 + 7;\n            reach = max(_920 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _826 + 4;\n            float4 _944 = fa_light_texel(param_9);\n            int param_10 = _826 + 5;\n            float4 _949 = fa_light_texel(param_10);\n            int param_11 = _826 + 6;\n            float4 _954 = fa_light_texel(param_11);\n            float _955 = _954.w;\n            int param_12 = _826 + 2;\n            float3 _962 = normalize(fa_light_texel(param_12).xyz);\n            bool _964 = _955 > 1.5f;\n            bool _972;\n            if (!_964)\n            {\n                _972 = dot(_962, to_light) < 0.0f;\n            }\n            else\n            {\n                _972 = _964;\n            }\n            front = _972;\n            float3 r = 0.0f.xxx;\n            float3 _981 = _482_fa_camera_pos.xyz - world_pos;\n            bool _985 = dot(n, n) > 0.5f;\n            bool _993;\n            if (_985)\n            {\n                _993 = dot(_981, _981) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _993 = _985;\n            }\n            if (_993)\n            {\n                r = reflect(-normalize(_981), normalize(n));\n            }\n            float3 param_13 = _915;\n            float3 param_14 = _962;\n            float3 param_15 = _944.xyz;\n            float3 param_16 = _949.xyz;\n            float param_17 = _944.w;\n            float param_18 = _949.w;\n            float param_19 = _955;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1029 = length(to_light);\n        dist = _1029;\n        l = to_light / max(_1029, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1043 = reach / max(_834.w, 0.001000000047497451305389404296875f);\n        float _1049 = clamp(1.0f - (_1043 * _1043), 0.0f, 1.0f);\n        float _1051;\n        if (front)\n        {\n            _1051 = _1049 * _1049;\n        }\n        else\n        {\n            _1051 = 0.0f;\n        }\n        atten = _1051;\n        bool _1062 = _842 < 2.5f;\n        if ((_842 > 1.5f) && _1062)\n        {\n            int param_22 = _826 + 2;\n            float4 _1070 = fa_light_texel(param_22);\n            float _1080 = _1070.w;\n            int param_23 = _826 + 3;\n            float4 _1085 = fa_light_texel(param_23);\n            float _1086 = _1085.x;\n            float cos_inner = _1086;\n            if (_1086 > 1.5f)\n            {\n                cos_inner = lerp(_1080, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1080, cos_inner, dot(-l, normalize(_1070.xyz)));\n        }\n        if (_830 && (_842 < 1.5f))\n        {\n            int param_24 = _826 + 6;\n            float4 _1110 = fa_light_texel(param_24);\n            if (_1110.z > 0.5f)\n            {\n                float3 _1118 = -to_light;\n                int param_25 = _826 + 4;\n                int param_26 = _826 + 5;\n                float3 _1132 = fa_light_texel(param_25).xyz;\n                float3 _1136 = fa_light_texel(param_26).xyz;\n                float3 _1145 = float3(dot(_1118, _1132), dot(_1118, _1136), dot(_1118, cross(_1132, _1136)));\n                float3 param_27 = _1145;\n                int _1149 = fa_cube_face(param_27);\n                int param_28 = _1149;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1176 = float2(dot(_1145, cross(param_29, param_30)), dot(_1145, param_30)) / max(dot(_1145, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1180 = _1149 / 3;\n                float2 param_31 = _1110.xy + (float2(float(_1149 - (_1180 * 3)), float(_1180)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1176.x), 0.5f - (0.5f * _1176.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _826 + 7;\n            float4 _1210 = fa_light_texel(param_33);\n            if (_1210.z > 0.5f)\n            {\n                int param_34 = _826 + 2;\n                int param_35 = _826 + 4;\n                int param_36 = _826 + 5;\n                float2 param_37 = _1210.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_830 && _1062)\n            {\n                int param_42 = _826 + 6;\n                float4 _1257 = fa_light_texel(param_42);\n                int param_43 = _826 + 7;\n                float4 _1262 = fa_light_texel(param_43);\n                bool _1265 = _1257.z > 0.5f;\n                bool _1272;\n                if (!_1265)\n                {\n                    _1272 = _1262.z > 0.5f;\n                }\n                else\n                {\n                    _1272 = _1265;\n                }\n                if (_1272)\n                {\n                    int param_44 = _826 + 2;\n                    float4 _1279 = fa_light_texel(param_44);\n                    float3 _1283 = normalize(_1279.xyz);\n                    int param_45 = _826 + 4;\n                    float4 _1288 = fa_light_texel(param_45);\n                    int param_46 = _826 + 5;\n                    float4 _1293 = fa_light_texel(param_46);\n                    if (_1265)\n                    {\n                        float3 _1301 = -to_light;\n                        float _1308 = _1279.w;\n                        float _1324 = 0.5f / max(dot(_1301, _1283) * (sqrt(max(1.0f - (_1308 * _1308), 0.0f)) / max(_1308, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1257.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1301, _1288.xyz) * _1324), 0.5f - (dot(_1301, _1293.xyz) * _1324));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1262.z > 0.5f)\n                    {\n                        float2 param_49 = _1262.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1283;\n                        float3 param_52 = _1288.xyz;\n                        float3 param_53 = _1293.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _6061 = _839.xyz * atten;\n    if (_830)\n    {\n        _6061 *= fa_light_tint;\n    }\n    int _1392;\n    if (_856)\n    {\n        _1392 = 0;\n    }\n    else\n    {\n        _1392 = ((_842 > 1.5f) && (_842 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _6072 = { l, _6061, atten, 1.0f, dist, _1392 };\n    return _6072;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2129;\n    if (i == 0)\n    {\n        _2129 = _2139_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2145;\n        if (i == 1)\n        {\n            _2145 = _2139_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2153;\n            if (i == 2)\n            {\n                _2153 = _2139_fa_shadow_split.z;\n            }\n            else\n            {\n                _2153 = _2139_fa_shadow_split.w;\n            }\n            _2145 = _2153;\n        }\n        _2129 = _2145;\n    }\n    return _2129;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2186 = fa_shadow_depth(param, param_1);\n    float _2190;\n    if (conv.x < 0.5f)\n    {\n        _2190 = _2186;\n    }\n    else\n    {\n        _2190 = (conv.y * conv.z) / (conv.z - (_2186 * (conv.z - conv.y)));\n    }\n    return _2190;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2117 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2117), sin(_2117)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2236 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2245;\n        if (k < 0.0f)\n        {\n            _2245 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2245 = k;\n        }\n        float _2265 = clamp((_2245 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2236;\n            float2 _2284 = fa_shadow_vogel(param_3, param_4, param_5) * _2265;\n            float2 param_6 = uv + (_2284 * _2139_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2296 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2296 < (zr - (length(_2284) * plane)))\n            {\n                sum += _2296;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2322 = sum / cnt;\n        float _2332;\n        if (k < 0.0f)\n        {\n            _2332 = (-k) / max(_2322, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2332 = k;\n        }\n        radius = clamp(((max(zr - _2322, 0.0f) * unit) * _2332) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2354 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2354; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2354;\n        float param_11 = _2236;\n        float2 _2373 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2373 * _2139_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2373) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2354);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2415 = max(_2139_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2420 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2426 = sqrt(1.0f - (_2420 * _2420));\n    float _2433 = min(_2426 / max(_2420, 0.20000000298023223876953125f), 4.0f);\n    float _2438;\n    if (_2139_fa_shadow_bias.y > 0.0f)\n    {\n        _2438 = _2139_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2438 = 1.5f * _2139_fa_shadow_info[ci].x;\n    }\n    float4 _2463 = mul(float4(world + (n * (_2438 * _2426)), 1.0f), _2139_fa_shadow_mat[ci]);\n    float _2470 = _2463.x;\n    bool _2473 = _2470 < _2139_fa_shadow_rect[ci].x;\n    bool _2482;\n    if (!_2473)\n    {\n        _2482 = _2470 > _2139_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2482 = _2473;\n    }\n    bool _2491;\n    if (!_2482)\n    {\n        _2491 = _2463.y < _2139_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2491 = _2482;\n    }\n    bool _2500;\n    if (!_2491)\n    {\n        _2500 = _2463.y > _2139_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2500 = _2491;\n    }\n    bool _2507;\n    if (!_2500)\n    {\n        _2507 = _2463.z > 1.0f;\n    }\n    else\n    {\n        _2507 = _2500;\n    }\n    if (_2507)\n    {\n        return -1.0f;\n    }\n    float _2515;\n    if (_2139_fa_shadow_bias.x > 0.0f)\n    {\n        _2515 = _2139_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2515 = 1.5f * _2139_fa_shadow_info[ci].x;\n    }\n    float2 param = _2463.xy;\n    float4 param_1 = _2139_fa_shadow_rect[ci];\n    float param_2 = _2463.z - ((_2515 * (1.0f + (0.5f * _2433))) / _2415);\n    float param_3 = _2139_fa_shadow_info[ci].x;\n    float param_4 = _2415;\n    float param_5 = _2415 * 0.25f;\n    float param_6 = ((_2139_fa_shadow_info[ci].x * min(_2433, 3.0f)) * 0.5f) / _2415;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2139_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2139_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_482_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2893 = int(_2139_fa_shadow_cfg.x + 0.5f);\n    if (_2893 < 1)\n    {\n        return 1.0f;\n    }\n    float _2908 = dot(world - _2139_fa_shadow_eye.xyz, _2139_fa_shadow_fwd.xyz);\n    int param = _2893 - 1;\n    if (_2908 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2920 = _2893 > 1;\n    bool _2927;\n    if (_2920)\n    {\n        _2927 = _2908 > _2139_fa_shadow_split.x;\n    }\n    else\n    {\n        _2927 = _2920;\n    }\n    if (_2927)\n    {\n        ci = 1;\n    }\n    bool _2931 = _2893 > 2;\n    bool _2938;\n    if (_2931)\n    {\n        _2938 = _2908 > _2139_fa_shadow_split.y;\n    }\n    else\n    {\n        _2938 = _2931;\n    }\n    if (_2938)\n    {\n        ci = 2;\n    }\n    bool _2942 = _2893 > 3;\n    bool _2949;\n    if (_2942)\n    {\n        _2949 = _2908 > _2139_fa_shadow_split.z;\n    }\n    else\n    {\n        _2949 = _2942;\n    }\n    if (_2949)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2893)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2975 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2975;\n        if (_2975 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2139_fa_shadow_cfg.y > 0.0f)\n    {\n        float _3000;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3000 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3000 = _2139_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _3019 = _2139_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3000, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _3030 = clamp((_2908 - (fa_shadow_split_at(param_7) - _3019)) / _3019, 0.0f, 1.0f);\n        if (_3030 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2893)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _3051 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3051;\n                if (_3051 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _3030);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2573 = _482_fa_pbr.z < 0.5f;\n    bool _2580;\n    if (!_2573)\n    {\n        _2580 = _2139_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2580 = _2573;\n    }\n    if (_2580)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2139_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2593 = fa_light_texel(param);\n    float _2594 = _2593.x;\n    if (_2594 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2603 = int(_2594 + 0.5f);\n    int param_1 = _2603;\n    float4 _2607 = fa_light_texel(param_1);\n    int param_2 = _2603 + 1;\n    float4 _2612 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2615 = _2607.y;\n    if (_2615 > 0.0f)\n    {\n        float _2632 = 1.0f - smoothstep(0.75f * _2615, _2615, length(world - _2139_fa_shadow_eye.xyz));\n        fade = _2632;\n        if (_2632 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2607.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2656 = (_2603 + 2) + (face * 6);\n    int param_4 = _2656;\n    int param_5 = _2656 + 1;\n    int param_6 = _2656 + 3;\n    float4 _2670 = fa_light_texel(param_6);\n    int param_7 = _2656 + 4;\n    float4 _2675 = fa_light_texel(param_7);\n    int param_8 = _2656 + 5;\n    float4 _2680 = fa_light_texel(param_8);\n    float _2692 = _2680.x * max(dot(_2670, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2697 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2720 = clamp(dot(n, _2670.xyz), -1.0f, 1.0f);\n    float _2739 = min(sqrt(1.0f - (_2720 * _2720)) / max(abs(dot(n, world - lpos)) / max(dot(_2670, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2742 = _2612.y;\n    float _2744;\n    if (_2742 > 0.0f)\n    {\n        _2744 = _2742;\n    }\n    else\n    {\n        _2744 = 1.5f * _2692;\n    }\n    float4 _2764 = float4(world + (n * (_2744 * sqrt(1.0f - (_2697 * _2697)))), 1.0f);\n    float _2768 = dot(_2670, _2764);\n    float _2771 = _2680.y;\n    if (_2768 < _2771)\n    {\n        return 1.0f;\n    }\n    float2 _2786 = float2(dot(fa_light_texel(param_4), _2764), dot(fa_light_texel(param_5), _2764)) / _2768.xx;\n    float _2788 = _2786.x;\n    bool _2791 = _2788 < _2675.x;\n    bool _2800;\n    if (!_2791)\n    {\n        _2800 = _2788 > _2675.z;\n    }\n    else\n    {\n        _2800 = _2791;\n    }\n    bool _2809;\n    if (!_2800)\n    {\n        _2809 = _2786.y < _2675.y;\n    }\n    else\n    {\n        _2809 = _2800;\n    }\n    bool _2818;\n    if (!_2809)\n    {\n        _2818 = _2786.y > _2675.w;\n    }\n    else\n    {\n        _2818 = _2809;\n    }\n    if (_2818)\n    {\n        return 1.0f;\n    }\n    float _2824 = _2612.x;\n    float _2826;\n    if (_2824 > 0.0f)\n    {\n        _2826 = _2824;\n    }\n    else\n    {\n        _2826 = 1.5f * _2692;\n    }\n    float2 param_9 = _2786;\n    float4 param_10 = _2675;\n    float param_11 = _2768 - (_2826 * (1.0f + (0.5f * _2739)));\n    float param_12 = _2692;\n    float param_13 = 1.0f;\n    float param_14 = _2680.z * 0.25f;\n    float param_15 = (_2692 * min(_2739, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2771, _2680.z);\n    int param_17 = int(_2607.z + 0.5f);\n    float param_18 = _2607.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _4678 = _482_fa_ct_a.x < 0.5f;\n    bool _4685;\n    if (!_4678)\n    {\n        _4685 = _2139_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _4685 = _4678;\n    }\n    if (_4685)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2139_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _4698 = fa_light_texel(param);\n    float _4699 = _4698.y;\n    float len = _4699;\n    if (_4699 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4711 = length(world - _482_fa_camera_pos.xyz);\n    float _4721 = 1.0f - smoothstep(0.5f * _482_fa_ct_b.x, _482_fa_ct_b.x, _4711);\n    if (_4721 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4727 = len;\n    float _4730 = min(_4727, 0.89999997615814208984375f * dist);\n    len = _4730;\n    float _4735 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _4711);\n    float _4740 = _4735 + (0.5f * _4730);\n    float3 _4746 = world + (gn * _4735);\n    float _4748 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _4812;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4763 = (float(k) + _4748) * 0.083333335816860198974609375f;\n        float3 _4771 = _4746 + (l * (_4763 * len));\n        float4 _4777 = float4(_4771, 1.0f);\n        float _4783 = dot(_482_fa_ct_vpw, _4777);\n        if (_4783 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _4803 = float2(dot(_482_fa_ct_vpx, _4777), dot(_482_fa_ct_vpy, _4777)) / _4783.xx;\n        float _4807 = _4803.x * 0.5f;\n        float _4808 = _4807 + 0.5f;\n        if (_482_fa_ct_a.y > 0.5f)\n        {\n            _4812 = (_4803.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _4812 = 0.5f - (_4803.y * 0.5f);\n        }\n        bool _4828 = _4808 < 0.0f;\n        bool _4835;\n        if (!_4828)\n        {\n            _4835 = _4808 >= 1.0f;\n        }\n        else\n        {\n            _4835 = _4828;\n        }\n        bool _4842;\n        if (!_4835)\n        {\n            _4842 = _4812 < 0.0f;\n        }\n        else\n        {\n            _4842 = _4835;\n        }\n        bool _4849;\n        if (!_4842)\n        {\n            _4849 = _4812 >= 1.0f;\n        }\n        else\n        {\n            _4849 = _4842;\n        }\n        if (_4849)\n        {\n            break;\n        }\n        float4 _4868 = fa_screen_tex.Load(int3(int2(float2(_4808, _4812) * _482_fa_ct_a.zw), 0));\n        if (_4868.w < 0.5f)\n        {\n            continue;\n        }\n        float _4887 = (dot(_482_fa_ct_fwd.xyz, _4771) + _482_fa_ct_fwd.w) - _4868.x;\n        if ((_4887 > _4735) && (_4887 < _4740))\n        {\n            occ = max(occ, (1.0f - (_4763 * _4763)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_4808, 0.5f - _4807), min(_4812, 1.0f - _4812))));\n        }\n    }\n    return 1.0f - (occ * _4721);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _4990 = fa_baked_keep(param);\n    if (_4990 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _6192 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _6192;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _5016 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _6194 = _5016.color;\n    float _6195 = _5016.attenuation;\n    float _6196 = _5016.shadow;\n    bool _5019 = _5016.type == 0;\n    if (_5019 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _5016.direction;\n        float _5030 = fa_shadow_factor(param_5, param_6);\n        _6196 = _5030;\n        _6194 *= _5030;\n    }\n    else\n    {\n        bool _5041 = _5016.type != 0;\n        bool _5047;\n        if (_5041)\n        {\n            _5047 = _6195 > 0.0f;\n        }\n        else\n        {\n            _5047 = _5041;\n        }\n        if (_5047)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _5016.direction;\n            float _5066 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _6196 = _5066;\n            _6194 *= _5066;\n        }\n    }\n    bool _5076 = _482_fa_ct_a.x > 0.5f;\n    bool _5082;\n    if (_5076)\n    {\n        _5082 = _6195 > 0.0f;\n    }\n    else\n    {\n        _5082 = _5076;\n    }\n    if (_5082)\n    {\n        float _5089;\n        if (_5019)\n        {\n            _5089 = 1000000000.0f;\n        }\n        else\n        {\n            _5089 = _5016._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _5016.direction;\n        float param_18 = _5089;\n        float _5107 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6196 *= _5107;\n        _6194 *= _5107;\n    }\n    float _5120 = _6195;\n    float _5121 = _5120 * _4990;\n    _6195 = _5121;\n    float3 _5125 = _6194;\n    float3 _5126 = _5125 * _4990;\n    _6194 = _5126;\n    LightSample _6211 = { _5016.direction, _5126, _5121, _6196, _5016._distance, _5016.type };\n    return _6211;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2139_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3075 = int(_2139_fa_shadow_cfg.x + 0.5f);\n    float _3085 = dot(world - _2139_fa_shadow_eye.xyz, _2139_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3090 = _3075 > 0;\n    bool _3099;\n    if (_3090)\n    {\n        int param = _3075 - 1;\n        _3099 = _3085 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3099 = _3090;\n    }\n    if (_3099)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3105 = _3075 > 1;\n        bool _3112;\n        if (_3105)\n        {\n            _3112 = _3085 > _2139_fa_shadow_split.x;\n        }\n        else\n        {\n            _3112 = _3105;\n        }\n        if (_3112)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3118 = _3075 > 2;\n        bool _3125;\n        if (_3118)\n        {\n            _3125 = _3085 > _2139_fa_shadow_split.y;\n        }\n        else\n        {\n            _3125 = _3118;\n        }\n        if (_3125)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3131 = _3075 > 3;\n        bool _3138;\n        if (_3131)\n        {\n            _3138 = _3085 > _2139_fa_shadow_split.z;\n        }\n        else\n        {\n            _3138 = _3131;\n        }\n        if (_3138)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _5903 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5903 = -_5903;\n    }\n    float3 _5543 = normalize(_482_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _5916 = { fa_world_pos, _5903, fa_world_tangent, fa_uv, fa_vertex_color, _5543, gl_FrontFacing };\n    SurfaceInput param_1 = _5916;\n    Surface _5551 = fa_standard_surface(param_1);\n    float3 _5942 = _5551.albedo;\n    float _5943 = _5551.alpha;\n    float3 _5944 = _5551.normal;\n    float _5945 = _5551.metallic;\n    float _5946 = _5551.roughness;\n    float _5947 = _5551.occlusion;\n    float3 _5948 = _5551.emission;\n    float _5949 = _5551.clearcoat;\n    float _5950 = _5551.clearcoat_roughness;\n    float3 _5951 = _5551.sheen_color;\n    float _5952 = _5551.sheen_roughness;\n    float _5953 = _5551.anisotropy;\n    float _5954 = _5551.anisotropy_rotation;\n    float _5955 = _5551.specular;\n    float _5956 = _5551.ior;\n    float3 _5957 = _5551.specular_color;\n    SurfaceInput _5924 = { fa_world_pos, _5903, fa_world_tangent, fa_uv, fa_vertex_color, _5543, gl_FrontFacing };\n    SurfaceInput param_2 = _5924;\n    Surface param_3 = _5551;\n    surface(param_2, param_3);\n    _5942 = param_3.albedo;\n    _5943 = param_3.alpha;\n    _5944 = param_3.normal;\n    _5945 = param_3.metallic;\n    _5946 = param_3.roughness;\n    _5947 = param_3.occlusion;\n    _5948 = param_3.emission;\n    _5949 = param_3.clearcoat;\n    _5950 = param_3.clearcoat_roughness;\n    _5951 = param_3.sheen_color;\n    _5952 = param_3.sheen_roughness;\n    _5953 = param_3.anisotropy;\n    _5954 = param_3.anisotropy_rotation;\n    _5955 = param_3.specular;\n    _5956 = param_3.ior;\n    _5957 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _5903;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5942 = param_6;\n    _5944 = param_7;\n    float3 result;\n    if (_482_fa_emissive.w > 0.5f)\n    {\n        result = _5942;\n    }\n    else\n    {\n        float3 _5589 = _5944;\n        float3 _5590 = normalize(_5589);\n        _5944 = _5590;\n        float3 param_8 = _5590;\n        SurfaceInput _5932 = { fa_world_pos, _5903, fa_world_tangent, fa_uv, fa_vertex_color, _5543, gl_FrontFacing };\n        SurfaceInput param_9 = _5932;\n        Surface _6023 = { _5942, _5943, _5944, _5945, _5946, _5947, _5948, _5949, _5950, _5951, _5952, _5953, _5954, _5955, _5956, _5957 };\n        Surface param_10 = _6023;\n        float3 param_11 = fa_indirect_diffuse(param_8);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _5609 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5609; ln++)\n        {\n            int param_12 = ln;\n            int _5622 = fa_cl_light(param_12);\n            int param_13 = _5622;\n            if (fa_baked_keep(param_13) <= 0.0f)\n            {\n                continue;\n            }\n            int param_14 = _5622;\n            float3 param_15 = fa_world_pos;\n            float3 param_16 = _5903;\n            LightSample _5638 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput _5940 = { fa_world_pos, _5903, fa_world_tangent, fa_uv, fa_vertex_color, _5543, gl_FrontFacing };\n            SurfaceInput param_17 = _5940;\n            Surface _6040 = { _5942, _5943, _5944, _5945, _5946, _5947, _5948, _5949, _5950, _5951, _5952, _5953, _5954, _5955, _5956, _5957 };\n            Surface param_18 = _6040;\n            LightSample param_19 = _5638;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _5653 = result;\n    float3 _5654 = _5653 + _5948;\n    result = _5654;\n    float3 param_20 = _5654;\n    float3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _5663 = _482_fa_fog.w > 0.0f;\n    bool _5670;\n    if (!_5663)\n    {\n        _5670 = _482_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _5670 = _5663;\n    }\n    if (_5670)\n    {\n        float3 _5679 = fa_world_pos - _482_fa_camera_pos.xyz;\n        float _5685 = dot(_5679, _482_fa_fog_c.xyz);\n        bool _5689 = _482_fa_fog_c.w > 0.5f;\n        float _5690;\n        if (_5689)\n        {\n            _5690 = _5685;\n        }\n        else\n        {\n            _5690 = length(_5679);\n        }\n        float _5702 = _5690 - _482_fa_fog_b.x;\n        if (_5702 > 0.0f)\n        {\n            float _5711 = _482_fa_fog.w * _5702;\n            float tau = _5711 * _5711;\n            if (_482_fa_fog_b.y > 0.0f)\n            {\n                float _5727;\n                if (_5689)\n                {\n                    _5727 = fa_world_pos.y - (_482_fa_fog_c.y * _5685);\n                }\n                else\n                {\n                    _5727 = _482_fa_camera_pos.y;\n                }\n                float _5748 = lerp(_5727, fa_world_pos.y, clamp(_482_fa_fog_b.x / _5690, 0.0f, 1.0f));\n                float _5752 = fa_world_pos.y - _5748;\n                float _5757 = _5748 - _482_fa_fog_b.z;\n                float _5762 = fa_world_pos.y - _482_fa_fog_b.z;\n                bool _5765 = _5757 <= 0.0f;\n                bool _5766 = !_5765;\n                bool _5772;\n                if (_5766)\n                {\n                    _5772 = _482_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5772 = _5765;\n                }\n                float _5773;\n                if (_5772)\n                {\n                    _5773 = _482_fa_fog_b.y;\n                }\n                else\n                {\n                    _5773 = _482_fa_fog_b.y * exp(-min(_482_fa_fog_b.w * _5757, 80.0f));\n                }\n                bool _5800;\n                if (_5766)\n                {\n                    _5800 = _482_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5800 = _5765;\n                }\n                float _5801;\n                if (_5800)\n                {\n                    _5801 = _482_fa_fog_b.y * _5757;\n                }\n                else\n                {\n                    _5801 = (_482_fa_fog_b.y * (1.0f - exp(-min(_482_fa_fog_b.w * _5757, 80.0f)))) / _482_fa_fog_b.w;\n                }\n                bool _5826 = _5762 <= 0.0f;\n                bool _5833;\n                if (!_5826)\n                {\n                    _5833 = _482_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5833 = _5826;\n                }\n                float _5834;\n                if (_5833)\n                {\n                    _5834 = _482_fa_fog_b.y * _5762;\n                }\n                else\n                {\n                    _5834 = (_482_fa_fog_b.y * (1.0f - exp(-min(_482_fa_fog_b.w * _5762, 80.0f)))) / _482_fa_fog_b.w;\n                }\n                float _5861;\n                if (abs(_5752) < 0.001000000047497451305389404296875f)\n                {\n                    _5861 = _5773;\n                }\n                else\n                {\n                    _5861 = (_5834 - _5801) / _5752;\n                }\n                tau += (_5702 * max(_5861, 0.0f));\n            }\n            result = lerp(result, _482_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _5943);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 800,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_482",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2139",
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
              "name": "fa_probe_atlas",
              "multisampled": false,
              "type": "2d",
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
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _381 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _381;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _388 = _273.world_pos;\n    fa_world_pos = _388;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_388, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _4155[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _482_fa_camera_pos : packoffset(c0);\n    float4 _482_fa_ambient : packoffset(c1);\n    float4 _482_fa_base_color : packoffset(c2);\n    float4 _482_fa_emissive : packoffset(c3);\n    float4 _482_fa_model_emissive : packoffset(c4);\n    float4 _482_fa_pbr : packoffset(c5);\n    float4 _482_fa_maps : packoffset(c6);\n    float4 _482_fa_fog : packoffset(c7);\n    float4 _482_fa_fog_b : packoffset(c8);\n    float4 _482_fa_fog_c : packoffset(c9);\n    float4 _482_fa_counts : packoffset(c10);\n    float4 _482_fa_env_sky : packoffset(c11);\n    float4 _482_fa_env_horizon : packoffset(c12);\n    float4 _482_fa_time : packoffset(c13);\n    float4 _482_fa_cl_vpx : packoffset(c14);\n    float4 _482_fa_cl_vpy : packoffset(c15);\n    float4 _482_fa_cl_vpw : packoffset(c16);\n    float4 _482_fa_cl_fwd : packoffset(c17);\n    float4 _482_fa_cl_grid : packoffset(c18);\n    float4 _482_fa_cl_info : packoffset(c19);\n    float4 _482_fa_layers_a : packoffset(c20);\n    float4 _482_fa_layers_b : packoffset(c21);\n    float4 _482_fa_layers_c : packoffset(c22);\n    float4 _482_fa_layers_d : packoffset(c23);\n    float4 _482_fa_ct_a : packoffset(c24);\n    float4 _482_fa_ct_b : packoffset(c25);\n    float4 _482_fa_ct_vpx : packoffset(c26);\n    float4 _482_fa_ct_vpy : packoffset(c27);\n    float4 _482_fa_ct_vpw : packoffset(c28);\n    float4 _482_fa_ct_fwd : packoffset(c29);\n    float4 _482_fa_probe_sh[9] : packoffset(c30);\n    float4 _482_fa_atlas : packoffset(c39);\n    float4 _482_fa_rpa_tile : packoffset(c40);\n    float4 _482_fa_rpa_pos : packoffset(c41);\n    float4 _482_fa_rpa_bx : packoffset(c42);\n    float4 _482_fa_rpa_by : packoffset(c43);\n    float4 _482_fa_rpa_bz : packoffset(c44);\n    float4 _482_fa_rpb_tile : packoffset(c45);\n    float4 _482_fa_rpb_pos : packoffset(c46);\n    float4 _482_fa_rpb_bx : packoffset(c47);\n    float4 _482_fa_rpb_by : packoffset(c48);\n    float4 _482_fa_rpb_bz : packoffset(c49);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2139_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2139_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2139_fa_shadow_info[4] : packoffset(c20);\n    float4 _2139_fa_shadow_split : packoffset(c24);\n    float4 _2139_fa_shadow_cfg : packoffset(c25);\n    float4 _2139_fa_shadow_bias : packoffset(c26);\n    float4 _2139_fa_shadow_eye : packoffset(c27);\n    float4 _2139_fa_shadow_fwd : packoffset(c28);\n    float4 _2139_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_probe_atlas : register(t6);\nTexture2D<float4> fa_screen_tex : register(t11);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1410 = _482_fa_cl_info.x < 0.0f;\n    bool _1417;\n    if (!_1410)\n    {\n        _1417 = _482_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1417 = _1410;\n    }\n    bool _1425;\n    if (!_1417)\n    {\n        _1425 = _482_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1425 = _1417;\n    }\n    bool _1432;\n    if (!_1425)\n    {\n        _1432 = _482_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1432 = _1425;\n    }\n    bool _1439;\n    if (!_1432)\n    {\n        _1439 = _482_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1439 = _1432;\n    }\n    if (_1439)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1449 = float4(world_pos, 1.0f);\n    float _1455 = dot(_482_fa_cl_vpw, _1449);\n    if (!(_1455 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1477 = float2(dot(_482_fa_cl_vpx, _1449), dot(_482_fa_cl_vpy, _1449)) / _1455.xx;\n    int _1481 = int(_482_fa_cl_grid.x);\n    int _1485 = int(_482_fa_cl_grid.y);\n    int param = (int(_482_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_482_fa_cl_fwd.xyz, world_pos) + _482_fa_cl_fwd.w, _482_fa_cl_grid.w) / _482_fa_cl_grid.w) * _482_fa_cl_grid.z)), 0, int(_482_fa_cl_info.y) - 1) * _1485) + clamp(int(floor(((_1477.y * 0.5f) + 0.5f) * _482_fa_cl_grid.y)), 0, _1485 - 1)) * _1481)) + clamp(int(floor(((_1477.x * 0.5f) + 0.5f) * _482_fa_cl_grid.x)), 0, _1481 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1561 = fa_cluster_texel(param);\n    return int2(int(_1561.x), int(_1561.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_482_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4964 = fa_cluster_lookup(param);\n    fa_cl_slot = _4964.x;\n    fa_cl_local = _4964.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _5176 = fa_linear_to_srgb(param);\n        c = _5176;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _5184 = fa_srgb_to_linear(param_1);\n            c = _5184;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _364;\n    if (i.front_facing)\n    {\n        _364 = i.world_normal;\n    }\n    else\n    {\n        _364 = -i.world_normal;\n    }\n    float3 _388 = normalize(i.world_tangent.xyz - (_364 * dot(_364, i.world_tangent.xyz)));\n    float3 _415 = normalize(((_388 * m.x) + ((cross(_364, _388) * i.world_tangent.w) * m.y)) + (_364 * m.z));\n    float3 _418;\n    if (i.front_facing)\n    {\n        _418 = _415;\n    }\n    else\n    {\n        _418 = -_415;\n    }\n    return _418;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _482_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _5215 = fa_tex_fix(param_2, param_3);\n    float4 _6400 = base_t;\n    _6400.x = _5215.x;\n    _6400.y = _5215.y;\n    _6400.z = _5215.z;\n    base_t = _6400;\n    float4 _5229 = (_6400 * _482_fa_base_color) * i.vertex_color;\n    float3 _6214 = i.world_normal;\n    if (_482_fa_maps.z > 0.5f)\n    {\n        float param_4 = _482_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _5261 = fa_tex_fix(param_6, param_7);\n        float3 _5264 = (_5261 * 2.0f) - 1.0f.xxx;\n        float2 _5269 = _5264.xy * _482_fa_maps.x;\n        float3 _6408 = _5264;\n        _6408.x = _5269.x;\n        _6408.y = _5269.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _6408;\n        _6214 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _482_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _5297 = fa_tex_fix(param_12, param_13);\n    float4 _6411 = mrt;\n    _6411.x = _5297.x;\n    _6411.y = _5297.y;\n    _6411.z = _5297.z;\n    mrt = _6411;\n    float4 _5325 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _482_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _5325.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _5336 = fa_tex_fix(param_16, param_17);\n    float param_18 = _482_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _5366 = fa_tex_fix(param_20, param_21);\n    float _6219 = _482_fa_layers_a.x;\n    float _6220 = _482_fa_layers_a.y;\n    float _6223 = _482_fa_layers_a.z;\n    float _6222 = _482_fa_layers_b.w;\n    float _6225 = _482_fa_layers_c.x;\n    if (_482_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_482_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _6219 *= _5336.y;\n            _6220 *= _5336.z;\n            _6222 *= _5325.w;\n        }\n        if (_482_fa_layers_c.z > 1.5f)\n        {\n            _6223 *= mrt.x;\n            _6225 *= mrt.w;\n        }\n    }\n    Surface _6244 = { _5229.xyz, _5229.w, _6214, clamp(_482_fa_pbr.x * _5297.z, 0.0f, 1.0f), clamp(_482_fa_pbr.y * _5297.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_482_fa_maps.y * (_5336.x - 1.0f)), _482_fa_emissive.xyz + (_482_fa_model_emissive.xyz * _5366), _6219, _6220, _482_fa_layers_b.xyz, _6222, _6223, _482_fa_layers_a.w, _6225, _482_fa_layers_c.y, _482_fa_layers_d.xyz };\n    return _6244;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1641 = rect.zw - rect.xy;\n    float2 _1645 = _1641 * atlas;\n    float2 _1649 = ddx * _1645;\n    float2 _1653 = ddy * _1645;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1641), clamp(0.5f * log2(max(max(dot(_1649, _1649), dot(_1653, _1653)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1686 = _482_fa_counts.y < 0.5f;\n    bool _1693;\n    if (!_1686)\n    {\n        _1693 = _482_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1693 = _1686;\n    }\n    if (_1693)\n    {\n        return;\n    }\n    float3 _1699 = ddx(world_pos);\n    float3 _1702 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1706 = fa_cluster_texel(param);\n    int _1710 = int(_1706.w);\n    if (_1710 < 1)\n    {\n        return;\n    }\n    int _1720 = int(_482_fa_counts.y + 0.5f);\n    int param_1 = _1720;\n    float4 _1724 = fa_light_texel(param_1);\n    float2 _1727 = _1724.yz;\n    int _1731 = int(_1724.w);\n    int param_2 = _1720 + 1;\n    float4 _1736 = fa_light_texel(param_2);\n    float _1737 = _1736.x;\n    int _1743 = int(_482_fa_counts.w + 0.5f) - 1;\n    int _1747 = int(_1706.z);\n    float3 _2012;\n    for (int k = 0; k < _1710; k++)\n    {\n        int _1760 = _1747 + k;\n        int param_3 = _1731 + (_1760 >> 2);\n        int _1777 = (_1720 + 2) + (int(fa_light_texel(param_3)[_1760 & 3]) * 7);\n        int param_4 = _1777 + 6;\n        float4 _1782 = fa_light_texel(param_4);\n        if (((int(_1782.w + 0.5f) >> _1743) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1777;\n        float4 _1797 = fa_light_texel(param_5);\n        int param_6 = _1777 + 1;\n        float4 _1802 = fa_light_texel(param_6);\n        int param_7 = _1777 + 2;\n        float4 _1807 = fa_light_texel(param_7);\n        float3 _1810 = _1797.xyz;\n        float _1815 = dot(_1810, world_pos) + _1797.w;\n        float3 _1817 = _1802.xyz;\n        float _1822 = dot(_1817, world_pos) + _1802.w;\n        float3 _1824 = _1807.xyz;\n        float _1829 = dot(_1824, world_pos) + _1807.w;\n        bool _1834 = abs(_1815) > 0.5f;\n        bool _1842;\n        if (!_1834)\n        {\n            _1842 = abs(_1822) > 0.5f;\n        }\n        else\n        {\n            _1842 = _1834;\n        }\n        bool _1850;\n        if (!_1842)\n        {\n            _1850 = abs(_1829) > 0.5f;\n        }\n        else\n        {\n            _1850 = _1842;\n        }\n        if (_1850)\n        {\n            continue;\n        }\n        float _1865 = clamp(dot(geo_normal, normalize(_1824)) * _1782.z, 0.0f, 1.0f);\n        if (_1865 <= 0.0f)\n        {\n            continue;\n        }\n        float _1885 = (clamp((0.5f - abs(_1829)) * 10.0f, 0.0f, 1.0f) * _1865) * _1782.x;\n        float2 _1893 = float2(_1815 + 0.5f, 0.5f - _1822);\n        float2 _1903 = float2(dot(_1810, _1699), dot(_1817, _1699));\n        float2 _1913 = float2(dot(_1810, _1702), dot(_1817, _1702));\n        int param_8 = _1777 + 5;\n        float4 _1918 = fa_light_texel(param_8);\n        int param_9 = _1777 + 3;\n        float4 _1923 = fa_light_texel(param_9);\n        int param_10 = _1777 + 4;\n        float4 _1928 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1918.xyz;\n        bool _1938 = _1923.z > _1923.x;\n        if (_1938)\n        {\n            float4 param_11 = _1923;\n            float2 param_12 = _1893;\n            float2 param_13 = _1727;\n            float2 param_14 = _1903;\n            float2 param_15 = _1913;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1737 > 0.5f) && (_1737 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1964 = fa_dc_to_linear(param_16);\n                float4 _6294 = tx;\n                _6294.x = _1964.x;\n                _6294.y = _1964.y;\n                _6294.z = _1964.z;\n                tx = _6294;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1885 * tex_a) * _1918.w, 0.0f, 1.0f).xxx);\n        if (_1928.z > _1928.x)\n        {\n            float4 param_17 = _1928;\n            float2 param_18 = _1893;\n            float2 param_19 = _1727;\n            float2 param_20 = _1903;\n            float2 param_21 = _1913;\n            float4 _2008 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1737 > 1.5f)\n            {\n                float3 param_22 = _2008.xyz;\n                float3 _2018 = fa_dc_to_srgb(param_22);\n                _2012 = _2018;\n            }\n            else\n            {\n                _2012 = _2008.xyz;\n            }\n            float3 _2027 = (_2012 * 2.0f) - 1.0f.xxx;\n            float2 _2032 = _2027.xy * _1782.y;\n            float3 _2054 = (normalize(_1810) * _2032.x) + (normalize(_1817) * _2032.y);\n            float3 _2057 = normalize(normal);\n            normal = normalize(lerp(_2057, normalize((_2057 * max(_2027.z, 0.0500000007450580596923828125f)) + (_2054 - (_2057 * dot(_2057, _2054)))), clamp(_1885 * (_1938 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3311_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3311_dummy_parameter)));\n}\n\nfloat3 fa_probe_sh_coef(float2 origin, float res, int k)\n{\n    float3 v = fa_probe_atlas.SampleLevel(fa_env_smp, (origin + float2(float(k) + 0.5f, res + 2.5f)) / fa_atlas_size(), 0.0f).xyz;\n    if (_482_fa_atlas.y > 0.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3252 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3252;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    float _3862 = (1.0f - _482_fa_rpa_tile.w) - _482_fa_rpb_tile.w;\n    float3 amb = 0.0f.xxx;\n    bool _3867 = _482_fa_env_sky.w > 0.5f;\n    float3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = 0.0f.xxx;\n    }\n    if (_3862 > 0.0005000000237487256526947021484375f)\n    {\n        if (_3867)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _482_fa_atlas.zw;\n                float param_1 = 128.0f;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3862;\n            }\n        }\n        else\n        {\n            amb = _482_fa_ambient.xyz * _3862;\n        }\n    }\n    bool _3918 = _482_fa_rpa_tile.w > 0.0f;\n    if (_3918)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _482_fa_rpa_tile.xy;\n            float param_4 = _482_fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * _482_fa_rpa_tile.w);\n        }\n    }\n    bool _3949 = _482_fa_rpb_tile.w > 0.0f;\n    if (_3949)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _482_fa_rpb_tile.xy;\n            float param_7 = _482_fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * _482_fa_rpb_tile.w);\n        }\n    }\n    if ((_3867 || _3918) || _3949)\n    {\n        float3 param_9[9] = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_482_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _482_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_482_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4081 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _4088 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _4091 = int(_4081);\n    int _4094 = int(_4088);\n    float _4104 = _4088 - float(_4094);\n    int _4159 = (_4091 * 9) + _4094;\n    int _4179 = ((_4091 + 1) * 9) + _4094;\n    return lerp(lerp(_4155[_4159], _4155[_4159 + 1], _4104), lerp(_4155[_4179], _4155[_4179 + 1], _4104), _4081 - float(_4091));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _6073 = false;\n    float _6074 = 1.0f;\n    float _6075 = 1.0f;\n    float _6076 = 1.0f;\n    float _6077 = 0.0f;\n    float _6078 = 0.0f;\n    float _6079 = 0.0f;\n    float _6080 = 0.0f;\n    float _6082 = 1.0f;\n    bool _6083 = false;\n    float3 _6084 = 0.0f.xxx;\n    float _6085 = 1.0f;\n    float _6086 = 1.0f;\n    float _6087 = 1.0f;\n    float _6088 = 0.0f;\n    float _6089 = 0.0f;\n    float3 _6090 = float3(1.0f, 0.0f, 0.0f);\n    float3 _6091 = float3(0.0f, 0.0f, 1.0f);\n    float _6092 = 1.0f;\n    float _6093 = 1.0f;\n    float _4230 = clamp(s.specular, 0.0f, 1.0f);\n    float _4234 = clamp(s.ior, 1.0f, 3.0f);\n    bool _4239 = (_4230 != 1.0f) || (_4234 != 1.5f);\n    bool _4248;\n    if (!_4239)\n    {\n        _4248 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _4248 = _4239;\n    }\n    if (_4248)\n    {\n        float _4256 = (_4234 - 1.0f) / (_4234 + 1.0f);\n        f0 = lerp(min((_4256 * _4256).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _4230, s.albedo, metallic.xxx);\n        _6074 = lerp(_4230, 1.0f, metallic);\n        _6073 = true;\n    }\n    float _4283 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_4283 > 0.0f)\n    {\n        float _4291 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _6077 = _4283;\n        _6078 = _4291;\n        float _4298 = _4291 * _4291;\n        _6079 = _4298;\n        _6080 = _4298 * _4298;\n        float _4310 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _6082 = _4310;\n        _6075 = 1.0f - (_4283 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _4310, 0.0f, 1.0f), 5.0f))));\n        _6073 = true;\n    }\n    float3 _4329 = max(s.sheen_color, 0.0f.xxx);\n    float _4338 = max(_4329.x, max(_4329.y, _4329.z));\n    if (_4338 > 0.0f)\n    {\n        float _4346 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _6083 = true;\n        _6084 = _4329;\n        _6085 = _4346;\n        _6086 = _4346 * _4346;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _4346;\n        float _4363 = fa_sheen_albedo(param, param_1);\n        _6088 = _4363;\n        _6087 = 1.0f - min(_4338 * _4363, 1.0f);\n        _6073 = true;\n    }\n    _6076 = _6075 * _6087;\n    float _4382 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_4382 != 0.0f)\n    {\n        float3 _4397 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _4397;\n        if (dot(_4397, _4397) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _4409 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_4409.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _4409.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _4409.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _4413 = t;\n        float3 _4414 = normalize(_4413);\n        t = _4414;\n        float3 _4439 = normalize((_4414 * cos(s.anisotropy_rotation)) + ((cross(n, _4414) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _6090 = _4439;\n        _6091 = cross(n, _4439);\n        float _4449 = roughness * roughness;\n        float _4455 = lerp(_4449, 1.0f, _4382 * _4382);\n        bool _4457 = _4382 > 0.0f;\n        _6092 = _4457 ? _4455 : _4449;\n        _6093 = _4457 ? _4449 : _4455;\n        _6089 = _4382;\n        _6073 = true;\n    }\n    FaLayers _6115 = { _6073, _6074, _6075, _6076, _6077, _6078, _6079, _6080, i.world_normal, _6082, _6083, _6084, _6085, _6086, _6087, _6088, _6089, _6090, _6091, _6092, _6093 };\n    return _6115;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _4013 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _4016 = _4013.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_4016 * _4016, exp2((-9.27999973297119140625f) * ndv)) * _4016) + _4013.y)) + _4013.zw;\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3272 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3275 = _3272.x;\n    float _3277 = _3272.z;\n    float2 e = float2(_3275, _3277);\n    if (_3272.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3277)) * ((_3275 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3275)) * ((_3277 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat3 fa_probe_level(float2 origin, float res, int lv, float2 e)\n{\n    float _3324;\n    if (lv == 0)\n    {\n        _3324 = 0.0f;\n    }\n    else\n    {\n        _3324 = res + 2.0f;\n    }\n    float _3334;\n    if (lv == 0)\n    {\n        _3334 = 0.0f;\n    }\n    else\n    {\n        _3334 = (res - (res / float(1 << (lv - 1)))) + (2.0f * float(lv - 1));\n    }\n    return fa_probe_atlas.SampleLevel(fa_env_smp, (((origin + float2(_3324, _3334)) + 1.0f.xx) + (((e * 0.5f) + 0.5f.xx) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0f).xyz;\n}\n\nfloat3 fa_probe_radiance(float2 origin, float res, float3 d, float rough)\n{\n    float _3379;\n    if (res > 64.5f)\n    {\n        _3379 = 5.0f;\n    }\n    else\n    {\n        _3379 = (res > 32.5f) ? 4.0f : 3.0f;\n    }\n    float _3394 = clamp(rough, 0.0f, 1.0f) * (_3379 - 1.0f);\n    int _3401 = int(min(floor(_3394), _3379 - 2.0f));\n    float _3406 = _3394 - float(_3401);\n    float3 param = d;\n    float2 _3410 = fa_oct_encode(param);\n    float2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3401;\n    float2 param_4 = _3410;\n    float3 _3420 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3406 < 0.00200000009499490261077880859375f)\n    {\n        return _3420;\n    }\n    float2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3401 + 1;\n    float2 param_8 = _3410;\n    return lerp(_3420, fa_probe_level(param_5, param_6, param_7, param_8), _3406.xxx);\n}\n\nfloat3 fa_probe_box_dir(float3 d, float4 posw, float4 bx, float4 by, float4 bz)\n{\n    if (posw.w < 0.5f)\n    {\n        return d;\n    }\n    float _3490 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3497 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3504 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3510 = dot(bx.xyz, d);\n    float _3514 = dot(by.xyz, d);\n    float _3518 = dot(bz.xyz, d);\n    float _3524;\n    if (_3510 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3524 = (1.0f - _3490) / _3510;\n    }\n    else\n    {\n        float _3538;\n        if (_3510 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3538 = ((-1.0f) - _3490) / _3510;\n        }\n        else\n        {\n            _3538 = 1000000015047466219876688855040.0f;\n        }\n        _3524 = _3538;\n    }\n    float tx = _3524;\n    float _3555;\n    if (_3514 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3555 = (1.0f - _3497) / _3514;\n    }\n    else\n    {\n        float _3568;\n        if (_3514 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3568 = ((-1.0f) - _3497) / _3514;\n        }\n        else\n        {\n            _3568 = 1000000015047466219876688855040.0f;\n        }\n        _3555 = _3568;\n    }\n    float ty = _3555;\n    float _3584;\n    if (_3518 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3584 = (1.0f - _3504) / _3518;\n    }\n    else\n    {\n        float _3597;\n        if (_3518 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3597 = ((-1.0f) - _3504) / _3518;\n        }\n        else\n        {\n            _3597 = 1000000015047466219876688855040.0f;\n        }\n        _3584 = _3597;\n    }\n    float _3609 = tx;\n    float _3612 = (_3609 > 0.0f) ? _3609 : 1000000015047466219876688855040.0f;\n    tx = _3612;\n    float _3613 = ty;\n    float _3616 = (_3613 > 0.0f) ? _3613 : 1000000015047466219876688855040.0f;\n    ty = _3616;\n    float _3626 = min(_3612, min(_3616, (_3584 > 0.0f) ? _3584 : 1000000015047466219876688855040.0f));\n    if (_3626 > 100000001504746621987668885504.0f)\n    {\n        return d;\n    }\n    float3 _3642 = (fa_world_pos + (d * _3626)) - posw.xyz;\n    float3 _3647;\n    if (dot(_3642, _3642) > 1.0000000133514319600180897396058e-10f)\n    {\n        _3647 = normalize(_3642);\n    }\n    else\n    {\n        _3647 = d;\n    }\n    return _3647;\n}\n\nfloat3 fa_probe_environment(float4 tile, float4 posw, float4 bx, float4 by, float4 bz, inout float3 d, float rough)\n{\n    float3 param = d;\n    float4 param_1 = posw;\n    float4 param_2 = bx;\n    float4 param_3 = by;\n    float4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    float2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    float3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _3693 = (1.0f - _482_fa_rpa_tile.w) - _482_fa_rpb_tile.w;\n    float3 outc = 0.0f.xxx;\n    if (_3693 > 0.0005000000237487256526947021484375f)\n    {\n        float3 base;\n        if (_482_fa_env_sky.w > 0.5f)\n        {\n            float2 param = _482_fa_atlas.zw;\n            float param_1 = 128.0f;\n            float3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3722 = rough * rough;\n            float _3753 = 0.60000002384185791015625f * _3722;\n            base = lerp(lerp(_482_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_482_fa_env_horizon.xyz, _482_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3722)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3753, 0.0500000007450580596923828125f + _3753, d.y).xxx), ((_482_fa_env_sky.xyz + _482_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3722 * 0.60000002384185791015625f).xxx);\n        }\n        outc = base * _3693;\n    }\n    if (_482_fa_rpa_tile.w > 0.0f)\n    {\n        float4 param_4 = _482_fa_rpa_tile;\n        float4 param_5 = _482_fa_rpa_pos;\n        float4 param_6 = _482_fa_rpa_bx;\n        float4 param_7 = _482_fa_rpa_by;\n        float4 param_8 = _482_fa_rpa_bz;\n        float3 param_9 = d;\n        float param_10 = rough;\n        float3 _3812 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3812 * _482_fa_rpa_tile.w);\n    }\n    if (_482_fa_rpb_tile.w > 0.0f)\n    {\n        float4 param_11 = _482_fa_rpb_tile;\n        float4 param_12 = _482_fa_rpb_pos;\n        float4 param_13 = _482_fa_rpb_bx;\n        float4 param_14 = _482_fa_rpb_by;\n        float4 param_15 = _482_fa_rpb_bz;\n        float3 param_16 = d;\n        float param_17 = rough;\n        float3 _3844 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_3844 * _482_fa_rpb_tile.w);\n    }\n    return outc;\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _4490;\n        if (L.aniso >= 0.0f)\n        {\n            _4490 = L.b;\n        }\n        else\n        {\n            _4490 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_4490, v), _4490), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4523 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _4523.x) + (L.f90.xxx * _4523.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _4578 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _4578.x) + _4578.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4055 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4055.x) + _4055.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _4607 = clamp(s.metallic, 0.0f, 1.0f);\n    float _4611 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _4618 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _4607.xxx);\n    float3 f0 = _4618;\n    float3 _4622 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _4622;\n    float3 param_3 = i.view_dir;\n    float param_4 = _4607;\n    float param_5 = _4611;\n    float3 param_6 = _4618;\n    FaLayers _4639 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4639.on)\n    {\n        FaLayers param_7 = _4639;\n        float3 param_8 = _4622;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _4611;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _4622;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _4611;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_482_fa_cl_info.x) + int(_482_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_482_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4934;\n    if (fa_lm.z > 0.5f)\n    {\n        _4934 = 0.0f;\n    }\n    else\n    {\n        _4934 = 1.0f - clamp(_482_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _4945 = _4934 < 1.0f;\n    bool _4951;\n    if (_4945)\n    {\n        int param = li;\n        _4951 = fa_light_baked(param);\n    }\n    else\n    {\n        _4951 = _4945;\n    }\n    return _4951 ? _4934 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _541_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _541_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _660 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _673 = (c - (ru * hx)) - p;\n        float3 _679 = ru * (2.0f * hx);\n        float _685 = max(dot(_679, _679), 9.9999999392252902907785028219223e-09f);\n        float _689 = dot(_673, _679);\n        float t = clamp((-_689) / _685, 0.0f, 1.0f);\n        if (_660)\n        {\n            float _704 = dot(r, _679);\n            float _710 = _685 - (_704 * _704);\n            if (abs(_710) > (9.9999997473787516355514526367188e-06f * _685))\n            {\n                t = clamp(((dot(r, _673) * _704) - _689) / _710, 0.0f, 1.0f);\n            }\n        }\n        return (p + _673) + (_679 * t);\n    }\n    float3 q = p;\n    float _742 = dot(r, axis);\n    bool _750;\n    if (_660)\n    {\n        _750 = abs(_742) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _750 = _660;\n    }\n    if (_750)\n    {\n        float _760 = dot(c - p, axis) / _742;\n        if (_760 > 0.0f)\n        {\n            q = p + (r * _760);\n        }\n    }\n    float3 _773 = q - c;\n    float2 xy = float2(dot(_773, ru), dot(_773, uu));\n    if (shape > 0.5f)\n    {\n        float _788 = length(xy);\n        if (_788 > hx)\n        {\n            xy *= (hx / _788);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _430 = abs(d);\n    float _432 = _430.x;\n    float _434 = _430.y;\n    bool _435 = _432 >= _434;\n    bool _443;\n    if (_435)\n    {\n        _443 = _432 >= _430.z;\n    }\n    else\n    {\n        _443 = _435;\n    }\n    int _444;\n    if (_443)\n    {\n        _444 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _459;\n        if (_434 >= _430.z)\n        {\n            _459 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _459 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _444 = _459;\n    }\n    return _444;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _580 = dot(d, right);\n    float _584 = dot(d, up);\n    float _595;\n    if (((_580 * _580) + (_584 * _584)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _595 = atan2(_584, _580) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _595 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_595 - floor(_595)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _826 = fa_light_base(param);\n    bool _830 = _482_fa_ambient.w > 4.5f;\n    int param_1 = _826;\n    float4 _834 = fa_light_texel(param_1);\n    int param_2 = _826 + 1;\n    float4 _839 = fa_light_texel(param_2);\n    float _842 = _839.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _854 = _830 && (_842 > 2.5f);\n    fa_light_is_area = _854;\n    bool _856 = _842 < 0.5f;\n    float3 l;\n    if (_856)\n    {\n        l = normalize(_834.xyz);\n        if (_830)\n        {\n            int param_3 = _826 + 6;\n            float4 _870 = fa_light_texel(param_3);\n            if (_870.z > 0.5f)\n            {\n                int param_4 = _826 + 4;\n                float4 _880 = fa_light_texel(param_4);\n                int param_5 = _826 + 5;\n                float4 _885 = fa_light_texel(param_5);\n                float2 param_6 = _870.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _880.xyz) * _880.w, (-dot(world_pos, _885.xyz)) * _885.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _915 = _834.xyz;\n        float3 _917 = _915 - world_pos;\n        float3 to_light = _917;\n        float _920 = length(_917);\n        float reach = _920;\n        bool front = true;\n        if (_854)\n        {\n            int param_8 = _826 + 7;\n            reach = max(_920 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _826 + 4;\n            float4 _944 = fa_light_texel(param_9);\n            int param_10 = _826 + 5;\n            float4 _949 = fa_light_texel(param_10);\n            int param_11 = _826 + 6;\n            float4 _954 = fa_light_texel(param_11);\n            float _955 = _954.w;\n            int param_12 = _826 + 2;\n            float3 _962 = normalize(fa_light_texel(param_12).xyz);\n            bool _964 = _955 > 1.5f;\n            bool _972;\n            if (!_964)\n            {\n                _972 = dot(_962, to_light) < 0.0f;\n            }\n            else\n            {\n                _972 = _964;\n            }\n            front = _972;\n            float3 r = 0.0f.xxx;\n            float3 _981 = _482_fa_camera_pos.xyz - world_pos;\n            bool _985 = dot(n, n) > 0.5f;\n            bool _993;\n            if (_985)\n            {\n                _993 = dot(_981, _981) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _993 = _985;\n            }\n            if (_993)\n            {\n                r = reflect(-normalize(_981), normalize(n));\n            }\n            float3 param_13 = _915;\n            float3 param_14 = _962;\n            float3 param_15 = _944.xyz;\n            float3 param_16 = _949.xyz;\n            float param_17 = _944.w;\n            float param_18 = _949.w;\n            float param_19 = _955;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1029 = length(to_light);\n        dist = _1029;\n        l = to_light / max(_1029, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1043 = reach / max(_834.w, 0.001000000047497451305389404296875f);\n        float _1049 = clamp(1.0f - (_1043 * _1043), 0.0f, 1.0f);\n        float _1051;\n        if (front)\n        {\n            _1051 = _1049 * _1049;\n        }\n        else\n        {\n            _1051 = 0.0f;\n        }\n        atten = _1051;\n        bool _1062 = _842 < 2.5f;\n        if ((_842 > 1.5f) && _1062)\n        {\n            int param_22 = _826 + 2;\n            float4 _1070 = fa_light_texel(param_22);\n            float _1080 = _1070.w;\n            int param_23 = _826 + 3;\n            float4 _1085 = fa_light_texel(param_23);\n            float _1086 = _1085.x;\n            float cos_inner = _1086;\n            if (_1086 > 1.5f)\n            {\n                cos_inner = lerp(_1080, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1080, cos_inner, dot(-l, normalize(_1070.xyz)));\n        }\n        if (_830 && (_842 < 1.5f))\n        {\n            int param_24 = _826 + 6;\n            float4 _1110 = fa_light_texel(param_24);\n            if (_1110.z > 0.5f)\n            {\n                float3 _1118 = -to_light;\n                int param_25 = _826 + 4;\n                int param_26 = _826 + 5;\n                float3 _1132 = fa_light_texel(param_25).xyz;\n                float3 _1136 = fa_light_texel(param_26).xyz;\n                float3 _1145 = float3(dot(_1118, _1132), dot(_1118, _1136), dot(_1118, cross(_1132, _1136)));\n                float3 param_27 = _1145;\n                int _1149 = fa_cube_face(param_27);\n                int param_28 = _1149;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1176 = float2(dot(_1145, cross(param_29, param_30)), dot(_1145, param_30)) / max(dot(_1145, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1180 = _1149 / 3;\n                float2 param_31 = _1110.xy + (float2(float(_1149 - (_1180 * 3)), float(_1180)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1176.x), 0.5f - (0.5f * _1176.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _826 + 7;\n            float4 _1210 = fa_light_texel(param_33);\n            if (_1210.z > 0.5f)\n            {\n                int param_34 = _826 + 2;\n                int param_35 = _826 + 4;\n                int param_36 = _826 + 5;\n                float2 param_37 = _1210.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_830 && _1062)\n            {\n                int param_42 = _826 + 6;\n                float4 _1257 = fa_light_texel(param_42);\n                int param_43 = _826 + 7;\n                float4 _1262 = fa_light_texel(param_43);\n                bool _1265 = _1257.z > 0.5f;\n                bool _1272;\n                if (!_1265)\n                {\n                    _1272 = _1262.z > 0.5f;\n                }\n                else\n                {\n                    _1272 = _1265;\n                }\n                if (_1272)\n                {\n                    int param_44 = _826 + 2;\n                    float4 _1279 = fa_light_texel(param_44);\n                    float3 _1283 = normalize(_1279.xyz);\n                    int param_45 = _826 + 4;\n                    float4 _1288 = fa_light_texel(param_45);\n                    int param_46 = _826 + 5;\n                    float4 _1293 = fa_light_texel(param_46);\n                    if (_1265)\n                    {\n                        float3 _1301 = -to_light;\n                        float _1308 = _1279.w;\n                        float _1324 = 0.5f / max(dot(_1301, _1283) * (sqrt(max(1.0f - (_1308 * _1308), 0.0f)) / max(_1308, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1257.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1301, _1288.xyz) * _1324), 0.5f - (dot(_1301, _1293.xyz) * _1324));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1262.z > 0.5f)\n                    {\n                        float2 param_49 = _1262.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1283;\n                        float3 param_52 = _1288.xyz;\n                        float3 param_53 = _1293.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _6061 = _839.xyz * atten;\n    if (_830)\n    {\n        _6061 *= fa_light_tint;\n    }\n    int _1392;\n    if (_856)\n    {\n        _1392 = 0;\n    }\n    else\n    {\n        _1392 = ((_842 > 1.5f) && (_842 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _6072 = { l, _6061, atten, 1.0f, dist, _1392 };\n    return _6072;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2129;\n    if (i == 0)\n    {\n        _2129 = _2139_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2145;\n        if (i == 1)\n        {\n            _2145 = _2139_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2153;\n            if (i == 2)\n            {\n                _2153 = _2139_fa_shadow_split.z;\n            }\n            else\n            {\n                _2153 = _2139_fa_shadow_split.w;\n            }\n            _2145 = _2153;\n        }\n        _2129 = _2145;\n    }\n    return _2129;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2186 = fa_shadow_depth(param, param_1);\n    float _2190;\n    if (conv.x < 0.5f)\n    {\n        _2190 = _2186;\n    }\n    else\n    {\n        _2190 = (conv.y * conv.z) / (conv.z - (_2186 * (conv.z - conv.y)));\n    }\n    return _2190;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2117 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2117), sin(_2117)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2236 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2245;\n        if (k < 0.0f)\n        {\n            _2245 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2245 = k;\n        }\n        float _2265 = clamp((_2245 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2236;\n            float2 _2284 = fa_shadow_vogel(param_3, param_4, param_5) * _2265;\n            float2 param_6 = uv + (_2284 * _2139_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2296 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2296 < (zr - (length(_2284) * plane)))\n            {\n                sum += _2296;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2322 = sum / cnt;\n        float _2332;\n        if (k < 0.0f)\n        {\n            _2332 = (-k) / max(_2322, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2332 = k;\n        }\n        radius = clamp(((max(zr - _2322, 0.0f) * unit) * _2332) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2354 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2354; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2354;\n        float param_11 = _2236;\n        float2 _2373 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2373 * _2139_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2373) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2354);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2415 = max(_2139_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2420 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2426 = sqrt(1.0f - (_2420 * _2420));\n    float _2433 = min(_2426 / max(_2420, 0.20000000298023223876953125f), 4.0f);\n    float _2438;\n    if (_2139_fa_shadow_bias.y > 0.0f)\n    {\n        _2438 = _2139_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2438 = 1.5f * _2139_fa_shadow_info[ci].x;\n    }\n    float4 _2463 = mul(float4(world + (n * (_2438 * _2426)), 1.0f), _2139_fa_shadow_mat[ci]);\n    float _2470 = _2463.x;\n    bool _2473 = _2470 < _2139_fa_shadow_rect[ci].x;\n    bool _2482;\n    if (!_2473)\n    {\n        _2482 = _2470 > _2139_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2482 = _2473;\n    }\n    bool _2491;\n    if (!_2482)\n    {\n        _2491 = _2463.y < _2139_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2491 = _2482;\n    }\n    bool _2500;\n    if (!_2491)\n    {\n        _2500 = _2463.y > _2139_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2500 = _2491;\n    }\n    bool _2507;\n    if (!_2500)\n    {\n        _2507 = _2463.z > 1.0f;\n    }\n    else\n    {\n        _2507 = _2500;\n    }\n    if (_2507)\n    {\n        return -1.0f;\n    }\n    float _2515;\n    if (_2139_fa_shadow_bias.x > 0.0f)\n    {\n        _2515 = _2139_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2515 = 1.5f * _2139_fa_shadow_info[ci].x;\n    }\n    float2 param = _2463.xy;\n    float4 param_1 = _2139_fa_shadow_rect[ci];\n    float param_2 = _2463.z - ((_2515 * (1.0f + (0.5f * _2433))) / _2415);\n    float param_3 = _2139_fa_shadow_info[ci].x;\n    float param_4 = _2415;\n    float param_5 = _2415 * 0.25f;\n    float param_6 = ((_2139_fa_shadow_info[ci].x * min(_2433, 3.0f)) * 0.5f) / _2415;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2139_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2139_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_482_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2893 = int(_2139_fa_shadow_cfg.x + 0.5f);\n    if (_2893 < 1)\n    {\n        return 1.0f;\n    }\n    float _2908 = dot(world - _2139_fa_shadow_eye.xyz, _2139_fa_shadow_fwd.xyz);\n    int param = _2893 - 1;\n    if (_2908 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2920 = _2893 > 1;\n    bool _2927;\n    if (_2920)\n    {\n        _2927 = _2908 > _2139_fa_shadow_split.x;\n    }\n    else\n    {\n        _2927 = _2920;\n    }\n    if (_2927)\n    {\n        ci = 1;\n    }\n    bool _2931 = _2893 > 2;\n    bool _2938;\n    if (_2931)\n    {\n        _2938 = _2908 > _2139_fa_shadow_split.y;\n    }\n    else\n    {\n        _2938 = _2931;\n    }\n    if (_2938)\n    {\n        ci = 2;\n    }\n    bool _2942 = _2893 > 3;\n    bool _2949;\n    if (_2942)\n    {\n        _2949 = _2908 > _2139_fa_shadow_split.z;\n    }\n    else\n    {\n        _2949 = _2942;\n    }\n    if (_2949)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2893)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2975 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2975;\n        if (_2975 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2139_fa_shadow_cfg.y > 0.0f)\n    {\n        float _3000;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3000 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3000 = _2139_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _3019 = _2139_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3000, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _3030 = clamp((_2908 - (fa_shadow_split_at(param_7) - _3019)) / _3019, 0.0f, 1.0f);\n        if (_3030 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2893)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _3051 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3051;\n                if (_3051 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _3030);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2573 = _482_fa_pbr.z < 0.5f;\n    bool _2580;\n    if (!_2573)\n    {\n        _2580 = _2139_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2580 = _2573;\n    }\n    if (_2580)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2139_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2593 = fa_light_texel(param);\n    float _2594 = _2593.x;\n    if (_2594 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2603 = int(_2594 + 0.5f);\n    int param_1 = _2603;\n    float4 _2607 = fa_light_texel(param_1);\n    int param_2 = _2603 + 1;\n    float4 _2612 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2615 = _2607.y;\n    if (_2615 > 0.0f)\n    {\n        float _2632 = 1.0f - smoothstep(0.75f * _2615, _2615, length(world - _2139_fa_shadow_eye.xyz));\n        fade = _2632;\n        if (_2632 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2607.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2656 = (_2603 + 2) + (face * 6);\n    int param_4 = _2656;\n    int param_5 = _2656 + 1;\n    int param_6 = _2656 + 3;\n    float4 _2670 = fa_light_texel(param_6);\n    int param_7 = _2656 + 4;\n    float4 _2675 = fa_light_texel(param_7);\n    int param_8 = _2656 + 5;\n    float4 _2680 = fa_light_texel(param_8);\n    float _2692 = _2680.x * max(dot(_2670, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2697 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2720 = clamp(dot(n, _2670.xyz), -1.0f, 1.0f);\n    float _2739 = min(sqrt(1.0f - (_2720 * _2720)) / max(abs(dot(n, world - lpos)) / max(dot(_2670, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2742 = _2612.y;\n    float _2744;\n    if (_2742 > 0.0f)\n    {\n        _2744 = _2742;\n    }\n    else\n    {\n        _2744 = 1.5f * _2692;\n    }\n    float4 _2764 = float4(world + (n * (_2744 * sqrt(1.0f - (_2697 * _2697)))), 1.0f);\n    float _2768 = dot(_2670, _2764);\n    float _2771 = _2680.y;\n    if (_2768 < _2771)\n    {\n        return 1.0f;\n    }\n    float2 _2786 = float2(dot(fa_light_texel(param_4), _2764), dot(fa_light_texel(param_5), _2764)) / _2768.xx;\n    float _2788 = _2786.x;\n    bool _2791 = _2788 < _2675.x;\n    bool _2800;\n    if (!_2791)\n    {\n        _2800 = _2788 > _2675.z;\n    }\n    else\n    {\n        _2800 = _2791;\n    }\n    bool _2809;\n    if (!_2800)\n    {\n        _2809 = _2786.y < _2675.y;\n    }\n    else\n    {\n        _2809 = _2800;\n    }\n    bool _2818;\n    if (!_2809)\n    {\n        _2818 = _2786.y > _2675.w;\n    }\n    else\n    {\n        _2818 = _2809;\n    }\n    if (_2818)\n    {\n        return 1.0f;\n    }\n    float _2824 = _2612.x;\n    float _2826;\n    if (_2824 > 0.0f)\n    {\n        _2826 = _2824;\n    }\n    else\n    {\n        _2826 = 1.5f * _2692;\n    }\n    float2 param_9 = _2786;\n    float4 param_10 = _2675;\n    float param_11 = _2768 - (_2826 * (1.0f + (0.5f * _2739)));\n    float param_12 = _2692;\n    float param_13 = 1.0f;\n    float param_14 = _2680.z * 0.25f;\n    float param_15 = (_2692 * min(_2739, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2771, _2680.z);\n    int param_17 = int(_2607.z + 0.5f);\n    float param_18 = _2607.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _4678 = _482_fa_ct_a.x < 0.5f;\n    bool _4685;\n    if (!_4678)\n    {\n        _4685 = _2139_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _4685 = _4678;\n    }\n    if (_4685)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2139_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _4698 = fa_light_texel(param);\n    float _4699 = _4698.y;\n    float len = _4699;\n    if (_4699 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4711 = length(world - _482_fa_camera_pos.xyz);\n    float _4721 = 1.0f - smoothstep(0.5f * _482_fa_ct_b.x, _482_fa_ct_b.x, _4711);\n    if (_4721 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4727 = len;\n    float _4730 = min(_4727, 0.89999997615814208984375f * dist);\n    len = _4730;\n    float _4735 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _4711);\n    float _4740 = _4735 + (0.5f * _4730);\n    float3 _4746 = world + (gn * _4735);\n    float _4748 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _4812;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4763 = (float(k) + _4748) * 0.083333335816860198974609375f;\n        float3 _4771 = _4746 + (l * (_4763 * len));\n        float4 _4777 = float4(_4771, 1.0f);\n        float _4783 = dot(_482_fa_ct_vpw, _4777);\n        if (_4783 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _4803 = float2(dot(_482_fa_ct_vpx, _4777), dot(_482_fa_ct_vpy, _4777)) / _4783.xx;\n        float _4807 = _4803.x * 0.5f;\n        float _4808 = _4807 + 0.5f;\n        if (_482_fa_ct_a.y > 0.5f)\n        {\n            _4812 = (_4803.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _4812 = 0.5f - (_4803.y * 0.5f);\n        }\n        bool _4828 = _4808 < 0.0f;\n        bool _4835;\n        if (!_4828)\n        {\n            _4835 = _4808 >= 1.0f;\n        }\n        else\n        {\n            _4835 = _4828;\n        }\n        bool _4842;\n        if (!_4835)\n        {\n            _4842 = _4812 < 0.0f;\n        }\n        else\n        {\n            _4842 = _4835;\n        }\n        bool _4849;\n        if (!_4842)\n        {\n            _4849 = _4812 >= 1.0f;\n        }\n        else\n        {\n            _4849 = _4842;\n        }\n        if (_4849)\n        {\n            break;\n        }\n        float4 _4868 = fa_screen_tex.Load(int3(int2(float2(_4808, _4812) * _482_fa_ct_a.zw), 0));\n        if (_4868.w < 0.5f)\n        {\n            continue;\n        }\n        float _4887 = (dot(_482_fa_ct_fwd.xyz, _4771) + _482_fa_ct_fwd.w) - _4868.x;\n        if ((_4887 > _4735) && (_4887 < _4740))\n        {\n            occ = max(occ, (1.0f - (_4763 * _4763)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_4808, 0.5f - _4807), min(_4812, 1.0f - _4812))));\n        }\n    }\n    return 1.0f - (occ * _4721);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _4990 = fa_baked_keep(param);\n    if (_4990 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _6192 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _6192;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _5016 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _6194 = _5016.color;\n    float _6195 = _5016.attenuation;\n    float _6196 = _5016.shadow;\n    bool _5019 = _5016.type == 0;\n    if (_5019 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _5016.direction;\n        float _5030 = fa_shadow_factor(param_5, param_6);\n        _6196 = _5030;\n        _6194 *= _5030;\n    }\n    else\n    {\n        bool _5041 = _5016.type != 0;\n        bool _5047;\n        if (_5041)\n        {\n            _5047 = _6195 > 0.0f;\n        }\n        else\n        {\n            _5047 = _5041;\n        }\n        if (_5047)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _5016.direction;\n            float _5066 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _6196 = _5066;\n            _6194 *= _5066;\n        }\n    }\n    bool _5076 = _482_fa_ct_a.x > 0.5f;\n    bool _5082;\n    if (_5076)\n    {\n        _5082 = _6195 > 0.0f;\n    }\n    else\n    {\n        _5082 = _5076;\n    }\n    if (_5082)\n    {\n        float _5089;\n        if (_5019)\n        {\n            _5089 = 1000000000.0f;\n        }\n        else\n        {\n            _5089 = _5016._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _5016.direction;\n        float param_18 = _5089;\n        float _5107 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6196 *= _5107;\n        _6194 *= _5107;\n    }\n    float _5120 = _6195;\n    float _5121 = _5120 * _4990;\n    _6195 = _5121;\n    float3 _5125 = _6194;\n    float3 _5126 = _5125 * _4990;\n    _6194 = _5126;\n    LightSample _6211 = { _5016.direction, _5126, _5121, _6196, _5016._distance, _5016.type };\n    return _6211;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2139_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3075 = int(_2139_fa_shadow_cfg.x + 0.5f);\n    float _3085 = dot(world - _2139_fa_shadow_eye.xyz, _2139_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3090 = _3075 > 0;\n    bool _3099;\n    if (_3090)\n    {\n        int param = _3075 - 1;\n        _3099 = _3085 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3099 = _3090;\n    }\n    if (_3099)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3105 = _3075 > 1;\n        bool _3112;\n        if (_3105)\n        {\n            _3112 = _3085 > _2139_fa_shadow_split.x;\n        }\n        else\n        {\n            _3112 = _3105;\n        }\n        if (_3112)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3118 = _3075 > 2;\n        bool _3125;\n        if (_3118)\n        {\n            _3125 = _3085 > _2139_fa_shadow_split.y;\n        }\n        else\n        {\n            _3125 = _3118;\n        }\n        if (_3125)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3131 = _3075 > 3;\n        bool _3138;\n        if (_3131)\n        {\n            _3138 = _3085 > _2139_fa_shadow_split.z;\n        }\n        else\n        {\n            _3138 = _3131;\n        }\n        if (_3138)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _5903 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5903 = -_5903;\n    }\n    float3 _5543 = normalize(_482_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _5916 = { fa_world_pos, _5903, fa_world_tangent, fa_uv, fa_vertex_color, _5543, gl_FrontFacing };\n    SurfaceInput param_1 = _5916;\n    Surface _5551 = fa_standard_surface(param_1);\n    float3 _5942 = _5551.albedo;\n    float _5943 = _5551.alpha;\n    float3 _5944 = _5551.normal;\n    float _5945 = _5551.metallic;\n    float _5946 = _5551.roughness;\n    float _5947 = _5551.occlusion;\n    float3 _5948 = _5551.emission;\n    float _5949 = _5551.clearcoat;\n    float _5950 = _5551.clearcoat_roughness;\n    float3 _5951 = _5551.sheen_color;\n    float _5952 = _5551.sheen_roughness;\n    float _5953 = _5551.anisotropy;\n    float _5954 = _5551.anisotropy_rotation;\n    float _5955 = _5551.specular;\n    float _5956 = _5551.ior;\n    float3 _5957 = _5551.specular_color;\n    SurfaceInput _5924 = { fa_world_pos, _5903, fa_world_tangent, fa_uv, fa_vertex_color, _5543, gl_FrontFacing };\n    SurfaceInput param_2 = _5924;\n    Surface param_3 = _5551;\n    surface(param_2, param_3);\n    _5942 = param_3.albedo;\n    _5943 = param_3.alpha;\n    _5944 = param_3.normal;\n    _5945 = param_3.metallic;\n    _5946 = param_3.roughness;\n    _5947 = param_3.occlusion;\n    _5948 = param_3.emission;\n    _5949 = param_3.clearcoat;\n    _5950 = param_3.clearcoat_roughness;\n    _5951 = param_3.sheen_color;\n    _5952 = param_3.sheen_roughness;\n    _5953 = param_3.anisotropy;\n    _5954 = param_3.anisotropy_rotation;\n    _5955 = param_3.specular;\n    _5956 = param_3.ior;\n    _5957 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _5903;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5942 = param_6;\n    _5944 = param_7;\n    float3 result;\n    if (_482_fa_emissive.w > 0.5f)\n    {\n        result = _5942;\n    }\n    else\n    {\n        float3 _5589 = _5944;\n        float3 _5590 = normalize(_5589);\n        _5944 = _5590;\n        float3 param_8 = _5590;\n        SurfaceInput _5932 = { fa_world_pos, _5903, fa_world_tangent, fa_uv, fa_vertex_color, _5543, gl_FrontFacing };\n        SurfaceInput param_9 = _5932;\n        Surface _6023 = { _5942, _5943, _5944, _5945, _5946, _5947, _5948, _5949, _5950, _5951, _5952, _5953, _5954, _5955, _5956, _5957 };\n        Surface param_10 = _6023;\n        float3 param_11 = fa_indirect_diffuse(param_8);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _5609 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5609; ln++)\n        {\n            int param_12 = ln;\n            int _5622 = fa_cl_light(param_12);\n            int param_13 = _5622;\n            if (fa_baked_keep(param_13) <= 0.0f)\n            {\n                continue;\n            }\n            int param_14 = _5622;\n            float3 param_15 = fa_world_pos;\n            float3 param_16 = _5903;\n            LightSample _5638 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput _5940 = { fa_world_pos, _5903, fa_world_tangent, fa_uv, fa_vertex_color, _5543, gl_FrontFacing };\n            SurfaceInput param_17 = _5940;\n            Surface _6040 = { _5942, _5943, _5944, _5945, _5946, _5947, _5948, _5949, _5950, _5951, _5952, _5953, _5954, _5955, _5956, _5957 };\n            Surface param_18 = _6040;\n            LightSample param_19 = _5638;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _5653 = result;\n    float3 _5654 = _5653 + _5948;\n    result = _5654;\n    float3 param_20 = _5654;\n    float3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _5663 = _482_fa_fog.w > 0.0f;\n    bool _5670;\n    if (!_5663)\n    {\n        _5670 = _482_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _5670 = _5663;\n    }\n    if (_5670)\n    {\n        float3 _5679 = fa_world_pos - _482_fa_camera_pos.xyz;\n        float _5685 = dot(_5679, _482_fa_fog_c.xyz);\n        bool _5689 = _482_fa_fog_c.w > 0.5f;\n        float _5690;\n        if (_5689)\n        {\n            _5690 = _5685;\n        }\n        else\n        {\n            _5690 = length(_5679);\n        }\n        float _5702 = _5690 - _482_fa_fog_b.x;\n        if (_5702 > 0.0f)\n        {\n            float _5711 = _482_fa_fog.w * _5702;\n            float tau = _5711 * _5711;\n            if (_482_fa_fog_b.y > 0.0f)\n            {\n                float _5727;\n                if (_5689)\n                {\n                    _5727 = fa_world_pos.y - (_482_fa_fog_c.y * _5685);\n                }\n                else\n                {\n                    _5727 = _482_fa_camera_pos.y;\n                }\n                float _5748 = lerp(_5727, fa_world_pos.y, clamp(_482_fa_fog_b.x / _5690, 0.0f, 1.0f));\n                float _5752 = fa_world_pos.y - _5748;\n                float _5757 = _5748 - _482_fa_fog_b.z;\n                float _5762 = fa_world_pos.y - _482_fa_fog_b.z;\n                bool _5765 = _5757 <= 0.0f;\n                bool _5766 = !_5765;\n                bool _5772;\n                if (_5766)\n                {\n                    _5772 = _482_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5772 = _5765;\n                }\n                float _5773;\n                if (_5772)\n                {\n                    _5773 = _482_fa_fog_b.y;\n                }\n                else\n                {\n                    _5773 = _482_fa_fog_b.y * exp(-min(_482_fa_fog_b.w * _5757, 80.0f));\n                }\n                bool _5800;\n                if (_5766)\n                {\n                    _5800 = _482_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5800 = _5765;\n                }\n                float _5801;\n                if (_5800)\n                {\n                    _5801 = _482_fa_fog_b.y * _5757;\n                }\n                else\n                {\n                    _5801 = (_482_fa_fog_b.y * (1.0f - exp(-min(_482_fa_fog_b.w * _5757, 80.0f)))) / _482_fa_fog_b.w;\n                }\n                bool _5826 = _5762 <= 0.0f;\n                bool _5833;\n                if (!_5826)\n                {\n                    _5833 = _482_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5833 = _5826;\n                }\n                float _5834;\n                if (_5833)\n                {\n                    _5834 = _482_fa_fog_b.y * _5762;\n                }\n                else\n                {\n                    _5834 = (_482_fa_fog_b.y * (1.0f - exp(-min(_482_fa_fog_b.w * _5762, 80.0f)))) / _482_fa_fog_b.w;\n                }\n                float _5861;\n                if (abs(_5752) < 0.001000000047497451305389404296875f)\n                {\n                    _5861 = _5773;\n                }\n                else\n                {\n                    _5861 = (_5834 - _5801) / _5752;\n                }\n                tau += (_5702 * max(_5861, 0.0f));\n            }\n            result = lerp(result, _482_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _5943);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 800,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_482",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2139",
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
              "name": "fa_probe_atlas",
              "multisampled": false,
              "type": "2d",
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
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _292 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _292;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _299 = _160.world_pos;\n    float4 _171 = float4(_299, 1.0f);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -mul(_171, _131_fa_light_vp).z;\n    fa_pre_r0 = float3(_131_fa_light_vp[0].x, _131_fa_light_vp[1].x, _131_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131_fa_light_vp[0].y, _131_fa_light_vp[1].y, _131_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131_fa_light_vp[0].z, _131_fa_light_vp[1].z, _131_fa_light_vp[2].z);\n    gl_Position = mul(_171, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _215_fa_camera_pos : packoffset(c0);\n    float4 _215_fa_ambient : packoffset(c1);\n    float4 _215_fa_base_color : packoffset(c2);\n    float4 _215_fa_emissive : packoffset(c3);\n    float4 _215_fa_model_emissive : packoffset(c4);\n    float4 _215_fa_pbr : packoffset(c5);\n    float4 _215_fa_maps : packoffset(c6);\n    float4 _215_fa_fog : packoffset(c7);\n    float4 _215_fa_fog_b : packoffset(c8);\n    float4 _215_fa_fog_c : packoffset(c9);\n    float4 _215_fa_counts : packoffset(c10);\n    float4 _215_fa_env_sky : packoffset(c11);\n    float4 _215_fa_env_horizon : packoffset(c12);\n    float4 _215_fa_time : packoffset(c13);\n    float4 _215_fa_cl_vpx : packoffset(c14);\n    float4 _215_fa_cl_vpy : packoffset(c15);\n    float4 _215_fa_cl_vpw : packoffset(c16);\n    float4 _215_fa_cl_fwd : packoffset(c17);\n    float4 _215_fa_cl_grid : packoffset(c18);\n    float4 _215_fa_cl_info : packoffset(c19);\n    float4 _215_fa_layers_a : packoffset(c20);\n    float4 _215_fa_layers_b : packoffset(c21);\n    float4 _215_fa_layers_c : packoffset(c22);\n    float4 _215_fa_layers_d : packoffset(c23);\n    float4 _215_fa_ct_a : packoffset(c24);\n    float4 _215_fa_ct_b : packoffset(c25);\n    float4 _215_fa_ct_vpx : packoffset(c26);\n    float4 _215_fa_ct_vpy : packoffset(c27);\n    float4 _215_fa_ct_vpw : packoffset(c28);\n    float4 _215_fa_ct_fwd : packoffset(c29);\n    float4 _215_fa_probe_sh[9] : packoffset(c30);\n    float4 _215_fa_atlas : packoffset(c39);\n    float4 _215_fa_rpa_tile : packoffset(c40);\n    float4 _215_fa_rpa_pos : packoffset(c41);\n    float4 _215_fa_rpa_bx : packoffset(c42);\n    float4 _215_fa_rpa_by : packoffset(c43);\n    float4 _215_fa_rpa_bz : packoffset(c44);\n    float4 _215_fa_rpb_tile : packoffset(c45);\n    float4 _215_fa_rpb_pos : packoffset(c46);\n    float4 _215_fa_rpb_bx : packoffset(c47);\n    float4 _215_fa_rpb_by : packoffset(c48);\n    float4 _215_fa_rpb_bz : packoffset(c49);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _215_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _227 = fa_tex_fix(param_2, param_3);\n    float4 _785 = base_t;\n    _785.x = _227.x;\n    _785.y = _227.y;\n    _785.z = _227.z;\n    base_t = _785;\n    float4 _243 = (_785 * _215_fa_base_color) * i.vertex_color;\n    float3 _748 = i.world_normal;\n    if (_215_fa_maps.z > 0.5f)\n    {\n        float param_4 = _215_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _277 = fa_tex_fix(param_6, param_7);\n        float3 _281 = (_277 * 2.0f) - 1.0f.xxx;\n        float2 _286 = _281.xy * _215_fa_maps.x;\n        float3 _793 = _281;\n        _793.x = _286.x;\n        _793.y = _286.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _793;\n        _748 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _215_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _315 = fa_tex_fix(param_12, param_13);\n    float4 _796 = mrt;\n    _796.x = _315.x;\n    _796.y = _315.y;\n    _796.z = _315.z;\n    mrt = _796;\n    float4 _345 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _215_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = _215_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _387 = fa_tex_fix(param_20, param_21);\n    float _753 = _215_fa_layers_a.x;\n    float _754 = _215_fa_layers_a.y;\n    float _757 = _215_fa_layers_a.z;\n    float _756 = _215_fa_layers_b.w;\n    float _759 = _215_fa_layers_c.x;\n    if (_215_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_215_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _753 *= _357.y;\n            _754 *= _357.z;\n            _756 *= _345.w;\n        }\n        if (_215_fa_layers_c.z > 1.5f)\n        {\n            _757 *= mrt.x;\n            _759 *= mrt.w;\n        }\n    }\n    Surface _778 = { _243.xyz, _243.w, _748, clamp(_215_fa_pbr.x * _315.z, 0.0f, 1.0f), clamp(_215_fa_pbr.y * _315.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_215_fa_maps.y * (_357.x - 1.0f)), _215_fa_emissive.xyz + (_215_fa_model_emissive.xyz * _387), _753, _754, _215_fa_layers_b.xyz, _756, _757, _215_fa_layers_a.w, _759, _215_fa_layers_c.y, _215_fa_layers_d.xyz };\n    return _778;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _659 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _659 = -_659;\n    }\n    float3 _521 = normalize(_215_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _672 = { fa_world_pos, _659, fa_world_tangent, fa_uv, fa_vertex_color, _521, gl_FrontFacing };\n    SurfaceInput param = _672;\n    SurfaceInput _680 = { fa_world_pos, _659, fa_world_tangent, fa_uv, fa_vertex_color, _521, gl_FrontFacing };\n    SurfaceInput param_1 = _680;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _536 = normalize(param_2.normal);\n    float3 _551 = normalize(float3(dot(fa_pre_r0, _536), dot(fa_pre_r1, _536), dot(fa_pre_r2, _536)));\n    float _563 = _551.z;\n    float2 e = _551.xy / ((abs(_551.x) + abs(_551.y)) + abs(_563)).xx;\n    if (_563 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 800,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_215",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _215_fa_camera_pos : packoffset(c0);\n    float4 _215_fa_ambient : packoffset(c1);\n    float4 _215_fa_base_color : packoffset(c2);\n    float4 _215_fa_emissive : packoffset(c3);\n    float4 _215_fa_model_emissive : packoffset(c4);\n    float4 _215_fa_pbr : packoffset(c5);\n    float4 _215_fa_maps : packoffset(c6);\n    float4 _215_fa_fog : packoffset(c7);\n    float4 _215_fa_fog_b : packoffset(c8);\n    float4 _215_fa_fog_c : packoffset(c9);\n    float4 _215_fa_counts : packoffset(c10);\n    float4 _215_fa_env_sky : packoffset(c11);\n    float4 _215_fa_env_horizon : packoffset(c12);\n    float4 _215_fa_time : packoffset(c13);\n    float4 _215_fa_cl_vpx : packoffset(c14);\n    float4 _215_fa_cl_vpy : packoffset(c15);\n    float4 _215_fa_cl_vpw : packoffset(c16);\n    float4 _215_fa_cl_fwd : packoffset(c17);\n    float4 _215_fa_cl_grid : packoffset(c18);\n    float4 _215_fa_cl_info : packoffset(c19);\n    float4 _215_fa_layers_a : packoffset(c20);\n    float4 _215_fa_layers_b : packoffset(c21);\n    float4 _215_fa_layers_c : packoffset(c22);\n    float4 _215_fa_layers_d : packoffset(c23);\n    float4 _215_fa_ct_a : packoffset(c24);\n    float4 _215_fa_ct_b : packoffset(c25);\n    float4 _215_fa_ct_vpx : packoffset(c26);\n    float4 _215_fa_ct_vpy : packoffset(c27);\n    float4 _215_fa_ct_vpw : packoffset(c28);\n    float4 _215_fa_ct_fwd : packoffset(c29);\n    float4 _215_fa_probe_sh[9] : packoffset(c30);\n    float4 _215_fa_atlas : packoffset(c39);\n    float4 _215_fa_rpa_tile : packoffset(c40);\n    float4 _215_fa_rpa_pos : packoffset(c41);\n    float4 _215_fa_rpa_bx : packoffset(c42);\n    float4 _215_fa_rpa_by : packoffset(c43);\n    float4 _215_fa_rpa_bz : packoffset(c44);\n    float4 _215_fa_rpb_tile : packoffset(c45);\n    float4 _215_fa_rpb_pos : packoffset(c46);\n    float4 _215_fa_rpb_bx : packoffset(c47);\n    float4 _215_fa_rpb_by : packoffset(c48);\n    float4 _215_fa_rpb_bz : packoffset(c49);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _215_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _227 = fa_tex_fix(param_2, param_3);\n    float4 _785 = base_t;\n    _785.x = _227.x;\n    _785.y = _227.y;\n    _785.z = _227.z;\n    base_t = _785;\n    float4 _243 = (_785 * _215_fa_base_color) * i.vertex_color;\n    float3 _748 = i.world_normal;\n    if (_215_fa_maps.z > 0.5f)\n    {\n        float param_4 = _215_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _277 = fa_tex_fix(param_6, param_7);\n        float3 _281 = (_277 * 2.0f) - 1.0f.xxx;\n        float2 _286 = _281.xy * _215_fa_maps.x;\n        float3 _793 = _281;\n        _793.x = _286.x;\n        _793.y = _286.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _793;\n        _748 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _215_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _315 = fa_tex_fix(param_12, param_13);\n    float4 _796 = mrt;\n    _796.x = _315.x;\n    _796.y = _315.y;\n    _796.z = _315.z;\n    mrt = _796;\n    float4 _345 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _215_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = _215_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _387 = fa_tex_fix(param_20, param_21);\n    float _753 = _215_fa_layers_a.x;\n    float _754 = _215_fa_layers_a.y;\n    float _757 = _215_fa_layers_a.z;\n    float _756 = _215_fa_layers_b.w;\n    float _759 = _215_fa_layers_c.x;\n    if (_215_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_215_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _753 *= _357.y;\n            _754 *= _357.z;\n            _756 *= _345.w;\n        }\n        if (_215_fa_layers_c.z > 1.5f)\n        {\n            _757 *= mrt.x;\n            _759 *= mrt.w;\n        }\n    }\n    Surface _778 = { _243.xyz, _243.w, _748, clamp(_215_fa_pbr.x * _315.z, 0.0f, 1.0f), clamp(_215_fa_pbr.y * _315.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_215_fa_maps.y * (_357.x - 1.0f)), _215_fa_emissive.xyz + (_215_fa_model_emissive.xyz * _387), _753, _754, _215_fa_layers_b.xyz, _756, _757, _215_fa_layers_a.w, _759, _215_fa_layers_c.y, _215_fa_layers_d.xyz };\n    return _778;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _659 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _659 = -_659;\n    }\n    float3 _521 = normalize(_215_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _672 = { fa_world_pos, _659, fa_world_tangent, fa_uv, fa_vertex_color, _521, gl_FrontFacing };\n    SurfaceInput param = _672;\n    SurfaceInput _680 = { fa_world_pos, _659, fa_world_tangent, fa_uv, fa_vertex_color, _521, gl_FrontFacing };\n    SurfaceInput param_1 = _680;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _536 = normalize(param_2.normal);\n    float3 _551 = normalize(float3(dot(fa_pre_r0, _536), dot(fa_pre_r1, _536), dot(fa_pre_r2, _536)));\n    float _563 = _551.z;\n    float2 e = _551.xy / ((abs(_551.x) + abs(_551.y)) + abs(_563)).xx;\n    if (_563 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 800,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_215",
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
