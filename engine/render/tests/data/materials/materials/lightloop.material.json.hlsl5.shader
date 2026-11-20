{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "5f457c7d0bc8edbcdea422ba00c093c613745eefd8db6d8c8f93fc5e235db1e8",
  "slang": "hlsl5",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _263 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _263;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_270, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _3341[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\nstatic const LightSample _5300 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, 0 };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _417_fa_camera_pos : packoffset(c0);\n    float4 _417_fa_ambient : packoffset(c1);\n    float4 _417_fa_base_color : packoffset(c2);\n    float4 _417_fa_emissive : packoffset(c3);\n    float4 _417_fa_model_emissive : packoffset(c4);\n    float4 _417_fa_pbr : packoffset(c5);\n    float4 _417_fa_maps : packoffset(c6);\n    float4 _417_fa_fog : packoffset(c7);\n    float4 _417_fa_fog_b : packoffset(c8);\n    float4 _417_fa_fog_c : packoffset(c9);\n    float4 _417_fa_counts : packoffset(c10);\n    float4 _417_fa_env_sky : packoffset(c11);\n    float4 _417_fa_env_horizon : packoffset(c12);\n    float4 _417_fa_time : packoffset(c13);\n    float4 _417_fa_cl_vpx : packoffset(c14);\n    float4 _417_fa_cl_vpy : packoffset(c15);\n    float4 _417_fa_cl_vpw : packoffset(c16);\n    float4 _417_fa_cl_fwd : packoffset(c17);\n    float4 _417_fa_cl_grid : packoffset(c18);\n    float4 _417_fa_cl_info : packoffset(c19);\n    float4 _417_fa_layers_a : packoffset(c20);\n    float4 _417_fa_layers_b : packoffset(c21);\n    float4 _417_fa_layers_c : packoffset(c22);\n    float4 _417_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2075_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2075_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2075_fa_shadow_info[4] : packoffset(c20);\n    float4 _2075_fa_shadow_split : packoffset(c24);\n    float4 _2075_fa_shadow_cfg : packoffset(c25);\n    float4 _2075_fa_shadow_bias : packoffset(c26);\n    float4 _2075_fa_shadow_eye : packoffset(c27);\n    float4 _2075_fa_shadow_fwd : packoffset(c28);\n    float4 _2075_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _4141_dark : packoffset(c0);\n    float _4141_fa_pad0 : packoffset(c0.y);\n    float _4141_fa_pad1 : packoffset(c0.z);\n    float _4141_fa_pad2 : packoffset(c0.w);\n    float _4141_skyAmount : packoffset(c1);\n    float _4141_fa_pad3 : packoffset(c1.y);\n    float _4141_fa_pad4 : packoffset(c1.z);\n    float _4141_fa_pad5 : packoffset(c1.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t9);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1346 = _417_fa_cl_info.x < 0.0f;\n    bool _1353;\n    if (!_1346)\n    {\n        _1353 = _417_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1353 = _1346;\n    }\n    bool _1361;\n    if (!_1353)\n    {\n        _1361 = _417_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1361 = _1353;\n    }\n    bool _1368;\n    if (!_1361)\n    {\n        _1368 = _417_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1368 = _1361;\n    }\n    bool _1375;\n    if (!_1368)\n    {\n        _1375 = _417_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1375 = _1368;\n    }\n    if (_1375)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1385 = float4(world_pos, 1.0f);\n    float _1391 = dot(_417_fa_cl_vpw, _1385);\n    if (!(_1391 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1413 = float2(dot(_417_fa_cl_vpx, _1385), dot(_417_fa_cl_vpy, _1385)) / _1391.xx;\n    int _1417 = int(_417_fa_cl_grid.x);\n    int _1421 = int(_417_fa_cl_grid.y);\n    int param = (int(_417_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_417_fa_cl_fwd.xyz, world_pos) + _417_fa_cl_fwd.w, _417_fa_cl_grid.w) / _417_fa_cl_grid.w) * _417_fa_cl_grid.z)), 0, int(_417_fa_cl_info.y) - 1) * _1421) + clamp(int(floor(((_1413.y * 0.5f) + 0.5f) * _417_fa_cl_grid.y)), 0, _1421 - 1)) * _1417)) + clamp(int(floor(((_1413.x * 0.5f) + 0.5f) * _417_fa_cl_grid.x)), 0, _1417 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1497 = fa_cluster_texel(param);\n    return int2(int(_1497.x), int(_1497.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_417_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3883 = fa_cluster_lookup(param);\n    fa_cl_slot = _3883.x;\n    fa_cl_local = _3883.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _4202 = fa_linear_to_srgb(param);\n        c = _4202;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _4210 = fa_srgb_to_linear(param_1);\n            c = _4210;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _299;\n    if (i.front_facing)\n    {\n        _299 = i.world_normal;\n    }\n    else\n    {\n        _299 = -i.world_normal;\n    }\n    float3 _323 = normalize(i.world_tangent.xyz - (_299 * dot(_299, i.world_tangent.xyz)));\n    float3 _351 = normalize(((_323 * m.x) + ((cross(_299, _323) * i.world_tangent.w) * m.y)) + (_299 * m.z));\n    float3 _354;\n    if (i.front_facing)\n    {\n        _354 = _351;\n    }\n    else\n    {\n        _354 = -_351;\n    }\n    return _354;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _417_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _4241 = fa_tex_fix(param_2, param_3);\n    float4 _5263 = base_t;\n    _5263.x = _4241.x;\n    _5263.y = _4241.y;\n    _5263.z = _4241.z;\n    base_t = _5263;\n    float4 _4255 = (_5263 * _417_fa_base_color) * i.vertex_color;\n    float3 _5115 = i.world_normal;\n    if (_417_fa_maps.z > 0.5f)\n    {\n        float param_4 = _417_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4287 = fa_tex_fix(param_6, param_7);\n        float3 _4290 = (_4287 * 2.0f) - 1.0f.xxx;\n        float2 _4295 = _4290.xy * _417_fa_maps.x;\n        float3 _5271 = _4290;\n        _5271.x = _4295.x;\n        _5271.y = _4295.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5271;\n        _5115 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _417_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4323 = fa_tex_fix(param_12, param_13);\n    float4 _5274 = mrt;\n    _5274.x = _4323.x;\n    _5274.y = _4323.y;\n    _5274.z = _4323.z;\n    mrt = _5274;\n    float4 _4351 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _417_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _4351.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4362 = fa_tex_fix(param_16, param_17);\n    float param_18 = _417_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4392 = fa_tex_fix(param_20, param_21);\n    float _5120 = _417_fa_layers_a.x;\n    float _5121 = _417_fa_layers_a.y;\n    float _5124 = _417_fa_layers_a.z;\n    float _5123 = _417_fa_layers_b.w;\n    float _5126 = _417_fa_layers_c.x;\n    if (_417_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_417_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _5120 *= _4362.y;\n            _5121 *= _4362.z;\n            _5123 *= _4351.w;\n        }\n        if (_417_fa_layers_c.z > 1.5f)\n        {\n            _5124 *= mrt.x;\n            _5126 *= mrt.w;\n        }\n    }\n    Surface _5145 = { _4255.xyz, _4255.w, _5115, clamp(_417_fa_pbr.x * _4323.z, 0.0f, 1.0f), clamp(_417_fa_pbr.y * _4323.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_417_fa_maps.y * (_4362.x - 1.0f)), _417_fa_emissive.xyz + (_417_fa_model_emissive.xyz * _4392), _5120, _5121, _417_fa_layers_b.xyz, _5123, _5124, _417_fa_layers_a.w, _5126, _417_fa_layers_c.y, _417_fa_layers_d.xyz };\n    return _5145;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1577 = rect.zw - rect.xy;\n    float2 _1581 = _1577 * atlas;\n    float2 _1585 = ddx * _1581;\n    float2 _1589 = ddy * _1581;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1577), clamp(0.5f * log2(max(max(dot(_1585, _1585), dot(_1589, _1589)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1622 = _417_fa_counts.y < 0.5f;\n    bool _1629;\n    if (!_1622)\n    {\n        _1629 = _417_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1629 = _1622;\n    }\n    if (_1629)\n    {\n        return;\n    }\n    float3 _1635 = ddx(world_pos);\n    float3 _1638 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1642 = fa_cluster_texel(param);\n    int _1646 = int(_1642.w);\n    if (_1646 < 1)\n    {\n        return;\n    }\n    int _1656 = int(_417_fa_counts.y + 0.5f);\n    int param_1 = _1656;\n    float4 _1660 = fa_light_texel(param_1);\n    float2 _1663 = _1660.yz;\n    int _1667 = int(_1660.w);\n    int param_2 = _1656 + 1;\n    float4 _1672 = fa_light_texel(param_2);\n    float _1673 = _1672.x;\n    int _1679 = int(_417_fa_counts.w + 0.5f) - 1;\n    int _1683 = int(_1642.z);\n    float3 _1948;\n    for (int k = 0; k < _1646; k++)\n    {\n        int _1696 = _1683 + k;\n        int param_3 = _1667 + (_1696 >> 2);\n        int _1713 = (_1656 + 2) + (int(fa_light_texel(param_3)[_1696 & 3]) * 7);\n        int param_4 = _1713 + 6;\n        float4 _1718 = fa_light_texel(param_4);\n        if (((int(_1718.w + 0.5f) >> _1679) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1713;\n        float4 _1733 = fa_light_texel(param_5);\n        int param_6 = _1713 + 1;\n        float4 _1738 = fa_light_texel(param_6);\n        int param_7 = _1713 + 2;\n        float4 _1743 = fa_light_texel(param_7);\n        float3 _1746 = _1733.xyz;\n        float _1751 = dot(_1746, world_pos) + _1733.w;\n        float3 _1753 = _1738.xyz;\n        float _1758 = dot(_1753, world_pos) + _1738.w;\n        float3 _1760 = _1743.xyz;\n        float _1765 = dot(_1760, world_pos) + _1743.w;\n        bool _1770 = abs(_1751) > 0.5f;\n        bool _1778;\n        if (!_1770)\n        {\n            _1778 = abs(_1758) > 0.5f;\n        }\n        else\n        {\n            _1778 = _1770;\n        }\n        bool _1786;\n        if (!_1778)\n        {\n            _1786 = abs(_1765) > 0.5f;\n        }\n        else\n        {\n            _1786 = _1778;\n        }\n        if (_1786)\n        {\n            continue;\n        }\n        float _1801 = clamp(dot(geo_normal, normalize(_1760)) * _1718.z, 0.0f, 1.0f);\n        if (_1801 <= 0.0f)\n        {\n            continue;\n        }\n        float _1821 = (clamp((0.5f - abs(_1765)) * 10.0f, 0.0f, 1.0f) * _1801) * _1718.x;\n        float2 _1829 = float2(_1751 + 0.5f, 0.5f - _1758);\n        float2 _1839 = float2(dot(_1746, _1635), dot(_1753, _1635));\n        float2 _1849 = float2(dot(_1746, _1638), dot(_1753, _1638));\n        int param_8 = _1713 + 5;\n        float4 _1854 = fa_light_texel(param_8);\n        int param_9 = _1713 + 3;\n        float4 _1859 = fa_light_texel(param_9);\n        int param_10 = _1713 + 4;\n        float4 _1864 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1854.xyz;\n        bool _1874 = _1859.z > _1859.x;\n        if (_1874)\n        {\n            float4 param_11 = _1859;\n            float2 param_12 = _1829;\n            float2 param_13 = _1663;\n            float2 param_14 = _1839;\n            float2 param_15 = _1849;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1673 > 0.5f) && (_1673 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1900 = fa_dc_to_linear(param_16);\n                float4 _5195 = tx;\n                _5195.x = _1900.x;\n                _5195.y = _1900.y;\n                _5195.z = _1900.z;\n                tx = _5195;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1821 * tex_a) * _1854.w, 0.0f, 1.0f).xxx);\n        if (_1864.z > _1864.x)\n        {\n            float4 param_17 = _1864;\n            float2 param_18 = _1829;\n            float2 param_19 = _1663;\n            float2 param_20 = _1839;\n            float2 param_21 = _1849;\n            float4 _1944 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1673 > 1.5f)\n            {\n                float3 param_22 = _1944.xyz;\n                float3 _1954 = fa_dc_to_srgb(param_22);\n                _1948 = _1954;\n            }\n            else\n            {\n                _1948 = _1944.xyz;\n            }\n            float3 _1963 = (_1948 * 2.0f) - 1.0f.xxx;\n            float2 _1968 = _1963.xy * _1718.y;\n            float3 _1990 = (normalize(_1746) * _1968.x) + (normalize(_1753) * _1968.y);\n            float3 _1993 = normalize(normal);\n            normal = normalize(lerp(_1993, normalize((_1993 * max(_1963.z, 0.0500000007450580596923828125f)) + (_1990 - (_1993 * dot(_1993, _1990)))), clamp(_1821 * (_1874 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return _5300;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_417_fa_cl_info.x) + int(_417_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_417_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _476_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _476_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _595 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _608 = (c - (ru * hx)) - p;\n        float3 _614 = ru * (2.0f * hx);\n        float _620 = max(dot(_614, _614), 9.9999999392252902907785028219223e-09f);\n        float _624 = dot(_608, _614);\n        float t = clamp((-_624) / _620, 0.0f, 1.0f);\n        if (_595)\n        {\n            float _639 = dot(r, _614);\n            float _645 = _620 - (_639 * _639);\n            if (abs(_645) > (9.9999997473787516355514526367188e-06f * _620))\n            {\n                t = clamp(((dot(r, _608) * _639) - _624) / _645, 0.0f, 1.0f);\n            }\n        }\n        return (p + _608) + (_614 * t);\n    }\n    float3 q = p;\n    float _677 = dot(r, axis);\n    bool _685;\n    if (_595)\n    {\n        _685 = abs(_677) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _685 = _595;\n    }\n    if (_685)\n    {\n        float _695 = dot(c - p, axis) / _677;\n        if (_695 > 0.0f)\n        {\n            q = p + (r * _695);\n        }\n    }\n    float3 _708 = q - c;\n    float2 xy = float2(dot(_708, ru), dot(_708, uu));\n    if (shape > 0.5f)\n    {\n        float _723 = length(xy);\n        if (_723 > hx)\n        {\n            xy *= (hx / _723);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _366 = abs(d);\n    float _368 = _366.x;\n    float _370 = _366.y;\n    bool _371 = _368 >= _370;\n    bool _379;\n    if (_371)\n    {\n        _379 = _368 >= _366.z;\n    }\n    else\n    {\n        _379 = _371;\n    }\n    int _380;\n    if (_379)\n    {\n        _380 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _395;\n        if (_370 >= _366.z)\n        {\n            _395 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _395 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _380 = _395;\n    }\n    return _380;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _515 = dot(d, right);\n    float _519 = dot(d, up);\n    float _530;\n    if (((_515 * _515) + (_519 * _519)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _530 = atan2(_519, _515) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _530 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_530 - floor(_530)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _761 = fa_light_base(param);\n    bool _765 = _417_fa_ambient.w > 4.5f;\n    int param_1 = _761;\n    float4 _769 = fa_light_texel(param_1);\n    int param_2 = _761 + 1;\n    float4 _774 = fa_light_texel(param_2);\n    float _777 = _774.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _789 = _765 && (_777 > 2.5f);\n    fa_light_is_area = _789;\n    bool _791 = _777 < 0.5f;\n    float3 l;\n    if (_791)\n    {\n        l = normalize(_769.xyz);\n        if (_765)\n        {\n            int param_3 = _761 + 6;\n            float4 _805 = fa_light_texel(param_3);\n            if (_805.z > 0.5f)\n            {\n                int param_4 = _761 + 4;\n                float4 _815 = fa_light_texel(param_4);\n                int param_5 = _761 + 5;\n                float4 _820 = fa_light_texel(param_5);\n                float2 param_6 = _805.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _815.xyz) * _815.w, (-dot(world_pos, _820.xyz)) * _820.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _850 = _769.xyz;\n        float3 _852 = _850 - world_pos;\n        float3 to_light = _852;\n        float _855 = length(_852);\n        float reach = _855;\n        bool front = true;\n        if (_789)\n        {\n            int param_8 = _761 + 7;\n            reach = max(_855 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _761 + 4;\n            float4 _879 = fa_light_texel(param_9);\n            int param_10 = _761 + 5;\n            float4 _884 = fa_light_texel(param_10);\n            int param_11 = _761 + 6;\n            float4 _889 = fa_light_texel(param_11);\n            float _890 = _889.w;\n            int param_12 = _761 + 2;\n            float3 _897 = normalize(fa_light_texel(param_12).xyz);\n            bool _899 = _890 > 1.5f;\n            bool _907;\n            if (!_899)\n            {\n                _907 = dot(_897, to_light) < 0.0f;\n            }\n            else\n            {\n                _907 = _899;\n            }\n            front = _907;\n            float3 r = 0.0f.xxx;\n            float3 _916 = _417_fa_camera_pos.xyz - world_pos;\n            bool _920 = dot(n, n) > 0.5f;\n            bool _928;\n            if (_920)\n            {\n                _928 = dot(_916, _916) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _928 = _920;\n            }\n            if (_928)\n            {\n                r = reflect(-normalize(_916), normalize(n));\n            }\n            float3 param_13 = _850;\n            float3 param_14 = _897;\n            float3 param_15 = _879.xyz;\n            float3 param_16 = _884.xyz;\n            float param_17 = _879.w;\n            float param_18 = _884.w;\n            float param_19 = _890;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _964 = length(to_light);\n        dist = _964;\n        l = to_light / max(_964, 9.9999997473787516355514526367188e-05f).xxx;\n        float _978 = reach / max(_769.w, 0.001000000047497451305389404296875f);\n        float _984 = clamp(1.0f - (_978 * _978), 0.0f, 1.0f);\n        float _986;\n        if (front)\n        {\n            _986 = _984 * _984;\n        }\n        else\n        {\n            _986 = 0.0f;\n        }\n        atten = _986;\n        bool _997 = _777 < 2.5f;\n        if ((_777 > 1.5f) && _997)\n        {\n            int param_22 = _761 + 2;\n            float4 _1005 = fa_light_texel(param_22);\n            float _1015 = _1005.w;\n            int param_23 = _761 + 3;\n            float4 _1020 = fa_light_texel(param_23);\n            float _1021 = _1020.x;\n            float cos_inner = _1021;\n            if (_1021 > 1.5f)\n            {\n                cos_inner = lerp(_1015, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1015, cos_inner, dot(-l, normalize(_1005.xyz)));\n        }\n        if (_765 && (_777 < 1.5f))\n        {\n            int param_24 = _761 + 6;\n            float4 _1045 = fa_light_texel(param_24);\n            if (_1045.z > 0.5f)\n            {\n                float3 _1053 = -to_light;\n                int param_25 = _761 + 4;\n                int param_26 = _761 + 5;\n                float3 _1067 = fa_light_texel(param_25).xyz;\n                float3 _1071 = fa_light_texel(param_26).xyz;\n                float3 _1080 = float3(dot(_1053, _1067), dot(_1053, _1071), dot(_1053, cross(_1067, _1071)));\n                float3 param_27 = _1080;\n                int _1084 = fa_cube_face(param_27);\n                int param_28 = _1084;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1111 = float2(dot(_1080, cross(param_29, param_30)), dot(_1080, param_30)) / max(dot(_1080, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1115 = _1084 / 3;\n                float2 param_31 = _1045.xy + (float2(float(_1084 - (_1115 * 3)), float(_1115)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1111.x), 0.5f - (0.5f * _1111.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _761 + 7;\n            float4 _1145 = fa_light_texel(param_33);\n            if (_1145.z > 0.5f)\n            {\n                int param_34 = _761 + 2;\n                int param_35 = _761 + 4;\n                int param_36 = _761 + 5;\n                float2 param_37 = _1145.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_765 && _997)\n            {\n                int param_42 = _761 + 6;\n                float4 _1192 = fa_light_texel(param_42);\n                int param_43 = _761 + 7;\n                float4 _1197 = fa_light_texel(param_43);\n                bool _1200 = _1192.z > 0.5f;\n                bool _1207;\n                if (!_1200)\n                {\n                    _1207 = _1197.z > 0.5f;\n                }\n                else\n                {\n                    _1207 = _1200;\n                }\n                if (_1207)\n                {\n                    int param_44 = _761 + 2;\n                    float4 _1214 = fa_light_texel(param_44);\n                    float3 _1218 = normalize(_1214.xyz);\n                    int param_45 = _761 + 4;\n                    float4 _1223 = fa_light_texel(param_45);\n                    int param_46 = _761 + 5;\n                    float4 _1228 = fa_light_texel(param_46);\n                    if (_1200)\n                    {\n                        float3 _1236 = -to_light;\n                        float _1243 = _1214.w;\n                        float _1259 = 0.5f / max(dot(_1236, _1218) * (sqrt(max(1.0f - (_1243 * _1243), 0.0f)) / max(_1243, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1192.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1236, _1223.xyz) * _1259), 0.5f - (dot(_1236, _1228.xyz) * _1259));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1197.z > 0.5f)\n                    {\n                        float2 param_49 = _1197.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1218;\n                        float3 param_52 = _1223.xyz;\n                        float3 param_53 = _1228.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4940 = _774.xyz * atten;\n    if (_765)\n    {\n        _4940 *= fa_light_tint;\n    }\n    int _1328;\n    if (_791)\n    {\n        _1328 = 0;\n    }\n    else\n    {\n        _1328 = ((_777 > 1.5f) && (_777 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _4951 = { l, _4940, atten, 1.0f, dist, _1328 };\n    return _4951;\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _4033 = n < 0;\n    bool _4040;\n    if (!_4033)\n    {\n        _4040 = n >= fa_light_count();\n    }\n    else\n    {\n        _4040 = _4033;\n    }\n    if (_4040)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _4048 = fa_cl_light(param);\n    bool _4051 = fa_lm.z > 0.5f;\n    bool _4057;\n    if (_4051)\n    {\n        int param_1 = _4048;\n        _4057 = fa_light_baked(param_1);\n    }\n    else\n    {\n        _4057 = _4051;\n    }\n    if (_4057)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _4048;\n    float3 param_3 = i.world_pos;\n    float3 param_4 = i.world_normal;\n    LightSample _4070 = fa_light_sample_n(param_2, param_3, param_4);\n    return _4070;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2065;\n    if (i == 0)\n    {\n        _2065 = _2075_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2081;\n        if (i == 1)\n        {\n            _2081 = _2075_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2089;\n            if (i == 2)\n            {\n                _2089 = _2075_fa_shadow_split.z;\n            }\n            else\n            {\n                _2089 = _2075_fa_shadow_split.w;\n            }\n            _2081 = _2089;\n        }\n        _2065 = _2081;\n    }\n    return _2065;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2122 = fa_shadow_depth(param, param_1);\n    float _2126;\n    if (conv.x < 0.5f)\n    {\n        _2126 = _2122;\n    }\n    else\n    {\n        _2126 = (conv.y * conv.z) / (conv.z - (_2122 * (conv.z - conv.y)));\n    }\n    return _2126;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2053 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2053), sin(_2053)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2172 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2181;\n        if (k < 0.0f)\n        {\n            _2181 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2181 = k;\n        }\n        float _2201 = clamp((_2181 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2172;\n            float2 _2220 = fa_shadow_vogel(param_3, param_4, param_5) * _2201;\n            float2 param_6 = uv + (_2220 * _2075_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2232 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2232 < (zr - (length(_2220) * plane)))\n            {\n                sum += _2232;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2258 = sum / cnt;\n        float _2268;\n        if (k < 0.0f)\n        {\n            _2268 = (-k) / max(_2258, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2268 = k;\n        }\n        radius = clamp(((max(zr - _2258, 0.0f) * unit) * _2268) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2290 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2290; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2290;\n        float param_11 = _2172;\n        float2 _2309 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2309 * _2075_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2309) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2290);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2351 = max(_2075_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2356 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2362 = sqrt(1.0f - (_2356 * _2356));\n    float _2369 = min(_2362 / max(_2356, 0.20000000298023223876953125f), 4.0f);\n    float _2374;\n    if (_2075_fa_shadow_bias.y > 0.0f)\n    {\n        _2374 = _2075_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2374 = 1.5f * _2075_fa_shadow_info[ci].x;\n    }\n    float4 _2399 = mul(float4(world + (n * (_2374 * _2362)), 1.0f), _2075_fa_shadow_mat[ci]);\n    float _2406 = _2399.x;\n    bool _2409 = _2406 < _2075_fa_shadow_rect[ci].x;\n    bool _2418;\n    if (!_2409)\n    {\n        _2418 = _2406 > _2075_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2418 = _2409;\n    }\n    bool _2427;\n    if (!_2418)\n    {\n        _2427 = _2399.y < _2075_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2427 = _2418;\n    }\n    bool _2436;\n    if (!_2427)\n    {\n        _2436 = _2399.y > _2075_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2436 = _2427;\n    }\n    bool _2443;\n    if (!_2436)\n    {\n        _2443 = _2399.z > 1.0f;\n    }\n    else\n    {\n        _2443 = _2436;\n    }\n    if (_2443)\n    {\n        return -1.0f;\n    }\n    float _2451;\n    if (_2075_fa_shadow_bias.x > 0.0f)\n    {\n        _2451 = _2075_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2451 = 1.5f * _2075_fa_shadow_info[ci].x;\n    }\n    float2 param = _2399.xy;\n    float4 param_1 = _2075_fa_shadow_rect[ci];\n    float param_2 = _2399.z - ((_2451 * (1.0f + (0.5f * _2369))) / _2351);\n    float param_3 = _2075_fa_shadow_info[ci].x;\n    float param_4 = _2351;\n    float param_5 = _2351 * 0.25f;\n    float param_6 = ((_2075_fa_shadow_info[ci].x * min(_2369, 3.0f)) * 0.5f) / _2351;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2075_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2075_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_417_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2829 = int(_2075_fa_shadow_cfg.x + 0.5f);\n    if (_2829 < 1)\n    {\n        return 1.0f;\n    }\n    float _2844 = dot(world - _2075_fa_shadow_eye.xyz, _2075_fa_shadow_fwd.xyz);\n    int param = _2829 - 1;\n    if (_2844 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2856 = _2829 > 1;\n    bool _2863;\n    if (_2856)\n    {\n        _2863 = _2844 > _2075_fa_shadow_split.x;\n    }\n    else\n    {\n        _2863 = _2856;\n    }\n    if (_2863)\n    {\n        ci = 1;\n    }\n    bool _2867 = _2829 > 2;\n    bool _2874;\n    if (_2867)\n    {\n        _2874 = _2844 > _2075_fa_shadow_split.y;\n    }\n    else\n    {\n        _2874 = _2867;\n    }\n    if (_2874)\n    {\n        ci = 2;\n    }\n    bool _2878 = _2829 > 3;\n    bool _2885;\n    if (_2878)\n    {\n        _2885 = _2844 > _2075_fa_shadow_split.z;\n    }\n    else\n    {\n        _2885 = _2878;\n    }\n    if (_2885)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2829)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2911 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2911;\n        if (_2911 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2075_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2936;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2936 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2936 = _2075_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2955 = _2075_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2936, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2966 = clamp((_2844 - (fa_shadow_split_at(param_7) - _2955)) / _2955, 0.0f, 1.0f);\n        if (_2966 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2829)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2987 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2987;\n                if (_2987 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2966);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2509 = _417_fa_pbr.z < 0.5f;\n    bool _2516;\n    if (!_2509)\n    {\n        _2516 = _2075_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2516 = _2509;\n    }\n    if (_2516)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2075_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2529 = fa_light_texel(param);\n    float _2530 = _2529.x;\n    if (_2530 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2539 = int(_2530 + 0.5f);\n    int param_1 = _2539;\n    float4 _2543 = fa_light_texel(param_1);\n    int param_2 = _2539 + 1;\n    float4 _2548 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2551 = _2543.y;\n    if (_2551 > 0.0f)\n    {\n        float _2568 = 1.0f - smoothstep(0.75f * _2551, _2551, length(world - _2075_fa_shadow_eye.xyz));\n        fade = _2568;\n        if (_2568 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2543.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2592 = (_2539 + 2) + (face * 6);\n    int param_4 = _2592;\n    int param_5 = _2592 + 1;\n    int param_6 = _2592 + 3;\n    float4 _2606 = fa_light_texel(param_6);\n    int param_7 = _2592 + 4;\n    float4 _2611 = fa_light_texel(param_7);\n    int param_8 = _2592 + 5;\n    float4 _2616 = fa_light_texel(param_8);\n    float _2628 = _2616.x * max(dot(_2606, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2633 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2656 = clamp(dot(n, _2606.xyz), -1.0f, 1.0f);\n    float _2675 = min(sqrt(1.0f - (_2656 * _2656)) / max(abs(dot(n, world - lpos)) / max(dot(_2606, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2678 = _2548.y;\n    float _2680;\n    if (_2678 > 0.0f)\n    {\n        _2680 = _2678;\n    }\n    else\n    {\n        _2680 = 1.5f * _2628;\n    }\n    float4 _2700 = float4(world + (n * (_2680 * sqrt(1.0f - (_2633 * _2633)))), 1.0f);\n    float _2704 = dot(_2606, _2700);\n    float _2707 = _2616.y;\n    if (_2704 < _2707)\n    {\n        return 1.0f;\n    }\n    float2 _2722 = float2(dot(fa_light_texel(param_4), _2700), dot(fa_light_texel(param_5), _2700)) / _2704.xx;\n    float _2724 = _2722.x;\n    bool _2727 = _2724 < _2611.x;\n    bool _2736;\n    if (!_2727)\n    {\n        _2736 = _2724 > _2611.z;\n    }\n    else\n    {\n        _2736 = _2727;\n    }\n    bool _2745;\n    if (!_2736)\n    {\n        _2745 = _2722.y < _2611.y;\n    }\n    else\n    {\n        _2745 = _2736;\n    }\n    bool _2754;\n    if (!_2745)\n    {\n        _2754 = _2722.y > _2611.w;\n    }\n    else\n    {\n        _2754 = _2745;\n    }\n    if (_2754)\n    {\n        return 1.0f;\n    }\n    float _2760 = _2548.x;\n    float _2762;\n    if (_2760 > 0.0f)\n    {\n        _2762 = _2760;\n    }\n    else\n    {\n        _2762 = 1.5f * _2628;\n    }\n    float2 param_9 = _2722;\n    float4 param_10 = _2611;\n    float param_11 = _2704 - (_2762 * (1.0f + (0.5f * _2675)));\n    float param_12 = _2628;\n    float param_13 = 1.0f;\n    float param_14 = _2616.z * 0.25f;\n    float param_15 = (_2628 * min(_2675, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2707, _2616.z);\n    int param_17 = int(_2543.z + 0.5f);\n    float param_18 = _2543.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _3910 = fa_lm.z > 0.5f;\n    bool _3916;\n    if (_3910)\n    {\n        int param = li;\n        _3916 = fa_light_baked(param);\n    }\n    else\n    {\n        _3916 = _3910;\n    }\n    if (_3916)\n    {\n        int param_1 = li;\n        LightSample _5084 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _5084;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3940 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _5086 = _3940.color;\n    float _5088 = _3940.shadow;\n    if ((_3940.type == 0) && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3940.direction;\n        float _3954 = fa_shadow_factor(param_5, param_6);\n        _5088 = _3954;\n        _5086 *= _3954;\n    }\n    else\n    {\n        bool _3965 = _3940.type != 0;\n        bool _3971;\n        if (_3965)\n        {\n            _3971 = _3940.attenuation > 0.0f;\n        }\n        else\n        {\n            _3971 = _3965;\n        }\n        if (_3971)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _3940.direction;\n            float _3990 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _5088 = _3990;\n            _5086 *= _3990;\n        }\n    }\n    LightSample _5103 = { _3940.direction, _5086, _3940.attenuation, _5088, _3940._distance, _3940.type };\n    return _5103;\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _4007 = n < 0;\n    bool _4014;\n    if (!_4007)\n    {\n        _4014 = n >= fa_light_count();\n    }\n    else\n    {\n        _4014 = _4007;\n    }\n    if (_4014)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    LightSample _4029 = fa_light_shadowed(param_1, param_2, param_3);\n    return _4029;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3266 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3274 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3277 = int(_3266);\n    int _3280 = int(_3274);\n    float _3290 = _3274 - float(_3280);\n    int _3346 = (_3277 * 9) + _3280;\n    int _3366 = ((_3277 + 1) * 9) + _3280;\n    return lerp(lerp(_3341[_3346], _3341[_3346 + 1], _3290), lerp(_3341[_3366], _3341[_3366 + 1], _3290), _3266 - float(_3277));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _4952 = false;\n    float _4953 = 1.0f;\n    float _4954 = 1.0f;\n    float _4955 = 1.0f;\n    float _4956 = 0.0f;\n    float _4957 = 0.0f;\n    float _4958 = 0.0f;\n    float _4959 = 0.0f;\n    float _4961 = 1.0f;\n    bool _4962 = false;\n    float3 _4963 = 0.0f.xxx;\n    float _4964 = 1.0f;\n    float _4965 = 1.0f;\n    float _4966 = 1.0f;\n    float _4967 = 0.0f;\n    float _4968 = 0.0f;\n    float3 _4969 = float3(1.0f, 0.0f, 0.0f);\n    float3 _4970 = float3(0.0f, 0.0f, 1.0f);\n    float _4971 = 1.0f;\n    float _4972 = 1.0f;\n    float _3417 = clamp(s.specular, 0.0f, 1.0f);\n    float _3421 = clamp(s.ior, 1.0f, 3.0f);\n    bool _3426 = (_3417 != 1.0f) || (_3421 != 1.5f);\n    bool _3435;\n    if (!_3426)\n    {\n        _3435 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _3435 = _3426;\n    }\n    if (_3435)\n    {\n        float _3443 = (_3421 - 1.0f) / (_3421 + 1.0f);\n        f0 = lerp(min((_3443 * _3443).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _3417, s.albedo, metallic.xxx);\n        _4953 = lerp(_3417, 1.0f, metallic);\n        _4952 = true;\n    }\n    float _3470 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_3470 > 0.0f)\n    {\n        float _3478 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _4956 = _3470;\n        _4957 = _3478;\n        float _3485 = _3478 * _3478;\n        _4958 = _3485;\n        _4959 = _3485 * _3485;\n        float _3497 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _4961 = _3497;\n        _4954 = 1.0f - (_3470 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _3497, 0.0f, 1.0f), 5.0f))));\n        _4952 = true;\n    }\n    float3 _3517 = max(s.sheen_color, 0.0f.xxx);\n    float _3526 = max(_3517.x, max(_3517.y, _3517.z));\n    if (_3526 > 0.0f)\n    {\n        float _3534 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _4962 = true;\n        _4963 = _3517;\n        _4964 = _3534;\n        _4965 = _3534 * _3534;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _3534;\n        float _3551 = fa_sheen_albedo(param, param_1);\n        _4967 = _3551;\n        _4966 = 1.0f - min(_3526 * _3551, 1.0f);\n        _4952 = true;\n    }\n    _4955 = _4954 * _4966;\n    float _3570 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_3570 != 0.0f)\n    {\n        float3 _3585 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _3585;\n        if (dot(_3585, _3585) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _3597 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_3597.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _3597.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _3597.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _3601 = t;\n        float3 _3602 = normalize(_3601);\n        t = _3602;\n        float3 _3627 = normalize((_3602 * cos(s.anisotropy_rotation)) + ((cross(n, _3602) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _4969 = _3627;\n        _4970 = cross(n, _3627);\n        float _3637 = roughness * roughness;\n        float _3643 = lerp(_3637, 1.0f, _3570 * _3570);\n        bool _3645 = _3570 > 0.0f;\n        _4971 = _3645 ? _3643 : _3637;\n        _4972 = _3645 ? _3637 : _3643;\n        _4968 = _3570;\n        _4952 = true;\n    }\n    FaLayers _4994 = { _4952, _4953, _4954, _4955, _4956, _4957, _4958, _4959, i.world_normal, _4961, _4962, _4963, _4964, _4965, _4966, _4967, _4968, _4969, _4970, _4971, _4972 };\n    return _4994;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3198 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3201 = _3198.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3201 * _3201, exp2((-9.27999973297119140625f) * ndv)) * _3201) + _3198.y)) + _3198.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_417_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _417_fa_env_horizon.w).xyz;\n    }\n    float _3122 = rough * rough;\n    float _3152 = 0.60000002384185791015625f * _3122;\n    return lerp(lerp(_417_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_417_fa_env_horizon.xyz, _417_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3122)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3152, 0.0500000007450580596923828125f + _3152, d.y).xxx), ((_417_fa_env_sky.xyz + _417_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3122 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _3678;\n        if (L.aniso >= 0.0f)\n        {\n            _3678 = L.b;\n        }\n        else\n        {\n            _3678 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_3678, v), _3678), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3711 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _3711.x) + (L.f90.xxx * _3711.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3766 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _3766.x) + _3766.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3240 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3240.x) + _3240.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _3805 = clamp(s.metallic, 0.0f, 1.0f);\n    float _3809 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _3816 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _3805.xxx);\n    float3 f0 = _3816;\n    float3 _3820 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _3820;\n    float3 param_3 = i.view_dir;\n    float param_4 = _3805;\n    float param_5 = _3809;\n    float3 param_6 = _3816;\n    FaLayers _3837 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_3837.on)\n    {\n        FaLayers param_7 = _3837;\n        float3 param_8 = _3820;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _3809;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _3820;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _3809;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0f;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _4090 = fa_light_unshadowed(param, param_1);\n        float _4098 = dot(_4090.color, float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));\n        if (_4098 > bestPower)\n        {\n            bestPower = _4098;\n            best = n;\n        }\n    }\n    float3 lit = (_417_fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _4127 = fa_light(param_2, param_3);\n        float _4135;\n        if (dot(s.normal, _4127.direction) > 0.5f)\n        {\n            _4135 = 1.0f;\n        }\n        else\n        {\n            _4135 = _4141_dark;\n        }\n        lit += ((s.albedo * _4127.color) * _4135);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * _4141_skyAmount);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2075_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3011 = int(_2075_fa_shadow_cfg.x + 0.5f);\n    float _3021 = dot(world - _2075_fa_shadow_eye.xyz, _2075_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3026 = _3011 > 0;\n    bool _3035;\n    if (_3026)\n    {\n        int param = _3011 - 1;\n        _3035 = _3021 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3035 = _3026;\n    }\n    if (_3035)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3041 = _3011 > 1;\n        bool _3048;\n        if (_3041)\n        {\n            _3048 = _3021 > _2075_fa_shadow_split.x;\n        }\n        else\n        {\n            _3048 = _3041;\n        }\n        if (_3048)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3054 = _3011 > 2;\n        bool _3061;\n        if (_3054)\n        {\n            _3061 = _3021 > _2075_fa_shadow_split.y;\n        }\n        else\n        {\n            _3061 = _3054;\n        }\n        if (_3061)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3067 = _3011 > 3;\n        bool _3074;\n        if (_3067)\n        {\n            _3074 = _3021 > _2075_fa_shadow_split.z;\n        }\n        else\n        {\n            _3074 = _3067;\n        }\n        if (_3074)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _4826 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4826 = -_4826;\n    }\n    float3 _4513 = normalize(_417_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _4839 = { fa_world_pos, _4826, fa_world_tangent, fa_uv, fa_vertex_color, _4513, gl_FrontFacing };\n    SurfaceInput param_1 = _4839;\n    Surface _4521 = fa_standard_surface(param_1);\n    float3 _4857 = _4521.albedo;\n    float _4858 = _4521.alpha;\n    float3 _4859 = _4521.normal;\n    float _4860 = _4521.metallic;\n    float _4861 = _4521.roughness;\n    float _4862 = _4521.occlusion;\n    float3 _4863 = _4521.emission;\n    float _4864 = _4521.clearcoat;\n    float _4865 = _4521.clearcoat_roughness;\n    float3 _4866 = _4521.sheen_color;\n    float _4867 = _4521.sheen_roughness;\n    float _4868 = _4521.anisotropy;\n    float _4869 = _4521.anisotropy_rotation;\n    float _4870 = _4521.specular;\n    float _4871 = _4521.ior;\n    float3 _4872 = _4521.specular_color;\n    SurfaceInput _4847 = { fa_world_pos, _4826, fa_world_tangent, fa_uv, fa_vertex_color, _4513, gl_FrontFacing };\n    SurfaceInput param_2 = _4847;\n    Surface param_3 = _4521;\n    surface(param_2, param_3);\n    _4857 = param_3.albedo;\n    _4858 = param_3.alpha;\n    _4859 = param_3.normal;\n    _4860 = param_3.metallic;\n    _4861 = param_3.roughness;\n    _4862 = param_3.occlusion;\n    _4863 = param_3.emission;\n    _4864 = param_3.clearcoat;\n    _4865 = param_3.clearcoat_roughness;\n    _4866 = param_3.sheen_color;\n    _4867 = param_3.sheen_roughness;\n    _4868 = param_3.anisotropy;\n    _4869 = param_3.anisotropy_rotation;\n    _4870 = param_3.specular;\n    _4871 = param_3.ior;\n    _4872 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _4826;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4857 = param_6;\n    _4859 = param_7;\n    float3 result;\n    if (_417_fa_emissive.w > 0.5f)\n    {\n        result = _4857;\n    }\n    else\n    {\n        float3 _4559 = _4859;\n        float3 _4560 = normalize(_4559);\n        _4859 = _4560;\n        SurfaceInput _4855 = { fa_world_pos, _4826, fa_world_tangent, fa_uv, fa_vertex_color, _4513, gl_FrontFacing };\n        SurfaceInput param_8 = _4855;\n        Surface _4938 = { _4857, _4858, _4560, _4860, _4861, _4862, _4863, _4864, _4865, _4866, _4867, _4868, _4869, _4870, _4871, _4872 };\n        Surface param_9 = _4938;\n        float3 _4571 = lighting(param_8, param_9);\n        result = _4571;\n    }\n    float3 _4575 = result;\n    float3 _4576 = _4575 + _4863;\n    result = _4576;\n    float3 param_10 = _4576;\n    float3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _4585 = _417_fa_fog.w > 0.0f;\n    bool _4592;\n    if (!_4585)\n    {\n        _4592 = _417_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _4592 = _4585;\n    }\n    if (_4592)\n    {\n        float3 _4601 = fa_world_pos - _417_fa_camera_pos.xyz;\n        float _4607 = dot(_4601, _417_fa_fog_c.xyz);\n        bool _4611 = _417_fa_fog_c.w > 0.5f;\n        float _4612;\n        if (_4611)\n        {\n            _4612 = _4607;\n        }\n        else\n        {\n            _4612 = length(_4601);\n        }\n        float _4624 = _4612 - _417_fa_fog_b.x;\n        if (_4624 > 0.0f)\n        {\n            float _4633 = _417_fa_fog.w * _4624;\n            float tau = _4633 * _4633;\n            if (_417_fa_fog_b.y > 0.0f)\n            {\n                float _4649;\n                if (_4611)\n                {\n                    _4649 = fa_world_pos.y - (_417_fa_fog_c.y * _4607);\n                }\n                else\n                {\n                    _4649 = _417_fa_camera_pos.y;\n                }\n                float _4670 = lerp(_4649, fa_world_pos.y, clamp(_417_fa_fog_b.x / _4612, 0.0f, 1.0f));\n                float _4674 = fa_world_pos.y - _4670;\n                float _4679 = _4670 - _417_fa_fog_b.z;\n                float _4684 = fa_world_pos.y - _417_fa_fog_b.z;\n                bool _4687 = _4679 <= 0.0f;\n                bool _4688 = !_4687;\n                bool _4694;\n                if (_4688)\n                {\n                    _4694 = _417_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4694 = _4687;\n                }\n                float _4695;\n                if (_4694)\n                {\n                    _4695 = _417_fa_fog_b.y;\n                }\n                else\n                {\n                    _4695 = _417_fa_fog_b.y * exp(-min(_417_fa_fog_b.w * _4679, 80.0f));\n                }\n                bool _4722;\n                if (_4688)\n                {\n                    _4722 = _417_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4722 = _4687;\n                }\n                float _4723;\n                if (_4722)\n                {\n                    _4723 = _417_fa_fog_b.y * _4679;\n                }\n                else\n                {\n                    _4723 = (_417_fa_fog_b.y * (1.0f - exp(-min(_417_fa_fog_b.w * _4679, 80.0f)))) / _417_fa_fog_b.w;\n                }\n                bool _4748 = _4684 <= 0.0f;\n                bool _4755;\n                if (!_4748)\n                {\n                    _4755 = _417_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4755 = _4748;\n                }\n                float _4756;\n                if (_4755)\n                {\n                    _4756 = _417_fa_fog_b.y * _4684;\n                }\n                else\n                {\n                    _4756 = (_417_fa_fog_b.y * (1.0f - exp(-min(_417_fa_fog_b.w * _4684, 80.0f)))) / _417_fa_fog_b.w;\n                }\n                float _4783;\n                if (abs(_4674) < 0.001000000047497451305389404296875f)\n                {\n                    _4783 = _4695;\n                }\n                else\n                {\n                    _4783 = (_4756 - _4723) / _4674;\n                }\n                tau += (_4624 * max(_4783, 0.0f));\n            }\n            result = lerp(result, _417_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4858);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_417",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2075",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_4141",
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
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 9
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
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
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
          },
          {
            "slot": 9,
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _3341[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\nstatic const LightSample _5300 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, 0 };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _417_fa_camera_pos : packoffset(c0);\n    float4 _417_fa_ambient : packoffset(c1);\n    float4 _417_fa_base_color : packoffset(c2);\n    float4 _417_fa_emissive : packoffset(c3);\n    float4 _417_fa_model_emissive : packoffset(c4);\n    float4 _417_fa_pbr : packoffset(c5);\n    float4 _417_fa_maps : packoffset(c6);\n    float4 _417_fa_fog : packoffset(c7);\n    float4 _417_fa_fog_b : packoffset(c8);\n    float4 _417_fa_fog_c : packoffset(c9);\n    float4 _417_fa_counts : packoffset(c10);\n    float4 _417_fa_env_sky : packoffset(c11);\n    float4 _417_fa_env_horizon : packoffset(c12);\n    float4 _417_fa_time : packoffset(c13);\n    float4 _417_fa_cl_vpx : packoffset(c14);\n    float4 _417_fa_cl_vpy : packoffset(c15);\n    float4 _417_fa_cl_vpw : packoffset(c16);\n    float4 _417_fa_cl_fwd : packoffset(c17);\n    float4 _417_fa_cl_grid : packoffset(c18);\n    float4 _417_fa_cl_info : packoffset(c19);\n    float4 _417_fa_layers_a : packoffset(c20);\n    float4 _417_fa_layers_b : packoffset(c21);\n    float4 _417_fa_layers_c : packoffset(c22);\n    float4 _417_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2075_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2075_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2075_fa_shadow_info[4] : packoffset(c20);\n    float4 _2075_fa_shadow_split : packoffset(c24);\n    float4 _2075_fa_shadow_cfg : packoffset(c25);\n    float4 _2075_fa_shadow_bias : packoffset(c26);\n    float4 _2075_fa_shadow_eye : packoffset(c27);\n    float4 _2075_fa_shadow_fwd : packoffset(c28);\n    float4 _2075_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _4141_dark : packoffset(c0);\n    float _4141_fa_pad0 : packoffset(c0.y);\n    float _4141_fa_pad1 : packoffset(c0.z);\n    float _4141_fa_pad2 : packoffset(c0.w);\n    float _4141_skyAmount : packoffset(c1);\n    float _4141_fa_pad3 : packoffset(c1.y);\n    float _4141_fa_pad4 : packoffset(c1.z);\n    float _4141_fa_pad5 : packoffset(c1.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t9);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1346 = _417_fa_cl_info.x < 0.0f;\n    bool _1353;\n    if (!_1346)\n    {\n        _1353 = _417_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1353 = _1346;\n    }\n    bool _1361;\n    if (!_1353)\n    {\n        _1361 = _417_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1361 = _1353;\n    }\n    bool _1368;\n    if (!_1361)\n    {\n        _1368 = _417_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1368 = _1361;\n    }\n    bool _1375;\n    if (!_1368)\n    {\n        _1375 = _417_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1375 = _1368;\n    }\n    if (_1375)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1385 = float4(world_pos, 1.0f);\n    float _1391 = dot(_417_fa_cl_vpw, _1385);\n    if (!(_1391 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1413 = float2(dot(_417_fa_cl_vpx, _1385), dot(_417_fa_cl_vpy, _1385)) / _1391.xx;\n    int _1417 = int(_417_fa_cl_grid.x);\n    int _1421 = int(_417_fa_cl_grid.y);\n    int param = (int(_417_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_417_fa_cl_fwd.xyz, world_pos) + _417_fa_cl_fwd.w, _417_fa_cl_grid.w) / _417_fa_cl_grid.w) * _417_fa_cl_grid.z)), 0, int(_417_fa_cl_info.y) - 1) * _1421) + clamp(int(floor(((_1413.y * 0.5f) + 0.5f) * _417_fa_cl_grid.y)), 0, _1421 - 1)) * _1417)) + clamp(int(floor(((_1413.x * 0.5f) + 0.5f) * _417_fa_cl_grid.x)), 0, _1417 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1497 = fa_cluster_texel(param);\n    return int2(int(_1497.x), int(_1497.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_417_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3883 = fa_cluster_lookup(param);\n    fa_cl_slot = _3883.x;\n    fa_cl_local = _3883.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _4202 = fa_linear_to_srgb(param);\n        c = _4202;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _4210 = fa_srgb_to_linear(param_1);\n            c = _4210;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _299;\n    if (i.front_facing)\n    {\n        _299 = i.world_normal;\n    }\n    else\n    {\n        _299 = -i.world_normal;\n    }\n    float3 _323 = normalize(i.world_tangent.xyz - (_299 * dot(_299, i.world_tangent.xyz)));\n    float3 _351 = normalize(((_323 * m.x) + ((cross(_299, _323) * i.world_tangent.w) * m.y)) + (_299 * m.z));\n    float3 _354;\n    if (i.front_facing)\n    {\n        _354 = _351;\n    }\n    else\n    {\n        _354 = -_351;\n    }\n    return _354;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _417_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _4241 = fa_tex_fix(param_2, param_3);\n    float4 _5263 = base_t;\n    _5263.x = _4241.x;\n    _5263.y = _4241.y;\n    _5263.z = _4241.z;\n    base_t = _5263;\n    float4 _4255 = (_5263 * _417_fa_base_color) * i.vertex_color;\n    float3 _5115 = i.world_normal;\n    if (_417_fa_maps.z > 0.5f)\n    {\n        float param_4 = _417_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4287 = fa_tex_fix(param_6, param_7);\n        float3 _4290 = (_4287 * 2.0f) - 1.0f.xxx;\n        float2 _4295 = _4290.xy * _417_fa_maps.x;\n        float3 _5271 = _4290;\n        _5271.x = _4295.x;\n        _5271.y = _4295.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5271;\n        _5115 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _417_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4323 = fa_tex_fix(param_12, param_13);\n    float4 _5274 = mrt;\n    _5274.x = _4323.x;\n    _5274.y = _4323.y;\n    _5274.z = _4323.z;\n    mrt = _5274;\n    float4 _4351 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _417_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _4351.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4362 = fa_tex_fix(param_16, param_17);\n    float param_18 = _417_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4392 = fa_tex_fix(param_20, param_21);\n    float _5120 = _417_fa_layers_a.x;\n    float _5121 = _417_fa_layers_a.y;\n    float _5124 = _417_fa_layers_a.z;\n    float _5123 = _417_fa_layers_b.w;\n    float _5126 = _417_fa_layers_c.x;\n    if (_417_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_417_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _5120 *= _4362.y;\n            _5121 *= _4362.z;\n            _5123 *= _4351.w;\n        }\n        if (_417_fa_layers_c.z > 1.5f)\n        {\n            _5124 *= mrt.x;\n            _5126 *= mrt.w;\n        }\n    }\n    Surface _5145 = { _4255.xyz, _4255.w, _5115, clamp(_417_fa_pbr.x * _4323.z, 0.0f, 1.0f), clamp(_417_fa_pbr.y * _4323.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_417_fa_maps.y * (_4362.x - 1.0f)), _417_fa_emissive.xyz + (_417_fa_model_emissive.xyz * _4392), _5120, _5121, _417_fa_layers_b.xyz, _5123, _5124, _417_fa_layers_a.w, _5126, _417_fa_layers_c.y, _417_fa_layers_d.xyz };\n    return _5145;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1577 = rect.zw - rect.xy;\n    float2 _1581 = _1577 * atlas;\n    float2 _1585 = ddx * _1581;\n    float2 _1589 = ddy * _1581;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1577), clamp(0.5f * log2(max(max(dot(_1585, _1585), dot(_1589, _1589)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1622 = _417_fa_counts.y < 0.5f;\n    bool _1629;\n    if (!_1622)\n    {\n        _1629 = _417_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1629 = _1622;\n    }\n    if (_1629)\n    {\n        return;\n    }\n    float3 _1635 = ddx(world_pos);\n    float3 _1638 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1642 = fa_cluster_texel(param);\n    int _1646 = int(_1642.w);\n    if (_1646 < 1)\n    {\n        return;\n    }\n    int _1656 = int(_417_fa_counts.y + 0.5f);\n    int param_1 = _1656;\n    float4 _1660 = fa_light_texel(param_1);\n    float2 _1663 = _1660.yz;\n    int _1667 = int(_1660.w);\n    int param_2 = _1656 + 1;\n    float4 _1672 = fa_light_texel(param_2);\n    float _1673 = _1672.x;\n    int _1679 = int(_417_fa_counts.w + 0.5f) - 1;\n    int _1683 = int(_1642.z);\n    float3 _1948;\n    for (int k = 0; k < _1646; k++)\n    {\n        int _1696 = _1683 + k;\n        int param_3 = _1667 + (_1696 >> 2);\n        int _1713 = (_1656 + 2) + (int(fa_light_texel(param_3)[_1696 & 3]) * 7);\n        int param_4 = _1713 + 6;\n        float4 _1718 = fa_light_texel(param_4);\n        if (((int(_1718.w + 0.5f) >> _1679) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1713;\n        float4 _1733 = fa_light_texel(param_5);\n        int param_6 = _1713 + 1;\n        float4 _1738 = fa_light_texel(param_6);\n        int param_7 = _1713 + 2;\n        float4 _1743 = fa_light_texel(param_7);\n        float3 _1746 = _1733.xyz;\n        float _1751 = dot(_1746, world_pos) + _1733.w;\n        float3 _1753 = _1738.xyz;\n        float _1758 = dot(_1753, world_pos) + _1738.w;\n        float3 _1760 = _1743.xyz;\n        float _1765 = dot(_1760, world_pos) + _1743.w;\n        bool _1770 = abs(_1751) > 0.5f;\n        bool _1778;\n        if (!_1770)\n        {\n            _1778 = abs(_1758) > 0.5f;\n        }\n        else\n        {\n            _1778 = _1770;\n        }\n        bool _1786;\n        if (!_1778)\n        {\n            _1786 = abs(_1765) > 0.5f;\n        }\n        else\n        {\n            _1786 = _1778;\n        }\n        if (_1786)\n        {\n            continue;\n        }\n        float _1801 = clamp(dot(geo_normal, normalize(_1760)) * _1718.z, 0.0f, 1.0f);\n        if (_1801 <= 0.0f)\n        {\n            continue;\n        }\n        float _1821 = (clamp((0.5f - abs(_1765)) * 10.0f, 0.0f, 1.0f) * _1801) * _1718.x;\n        float2 _1829 = float2(_1751 + 0.5f, 0.5f - _1758);\n        float2 _1839 = float2(dot(_1746, _1635), dot(_1753, _1635));\n        float2 _1849 = float2(dot(_1746, _1638), dot(_1753, _1638));\n        int param_8 = _1713 + 5;\n        float4 _1854 = fa_light_texel(param_8);\n        int param_9 = _1713 + 3;\n        float4 _1859 = fa_light_texel(param_9);\n        int param_10 = _1713 + 4;\n        float4 _1864 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1854.xyz;\n        bool _1874 = _1859.z > _1859.x;\n        if (_1874)\n        {\n            float4 param_11 = _1859;\n            float2 param_12 = _1829;\n            float2 param_13 = _1663;\n            float2 param_14 = _1839;\n            float2 param_15 = _1849;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1673 > 0.5f) && (_1673 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1900 = fa_dc_to_linear(param_16);\n                float4 _5195 = tx;\n                _5195.x = _1900.x;\n                _5195.y = _1900.y;\n                _5195.z = _1900.z;\n                tx = _5195;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1821 * tex_a) * _1854.w, 0.0f, 1.0f).xxx);\n        if (_1864.z > _1864.x)\n        {\n            float4 param_17 = _1864;\n            float2 param_18 = _1829;\n            float2 param_19 = _1663;\n            float2 param_20 = _1839;\n            float2 param_21 = _1849;\n            float4 _1944 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1673 > 1.5f)\n            {\n                float3 param_22 = _1944.xyz;\n                float3 _1954 = fa_dc_to_srgb(param_22);\n                _1948 = _1954;\n            }\n            else\n            {\n                _1948 = _1944.xyz;\n            }\n            float3 _1963 = (_1948 * 2.0f) - 1.0f.xxx;\n            float2 _1968 = _1963.xy * _1718.y;\n            float3 _1990 = (normalize(_1746) * _1968.x) + (normalize(_1753) * _1968.y);\n            float3 _1993 = normalize(normal);\n            normal = normalize(lerp(_1993, normalize((_1993 * max(_1963.z, 0.0500000007450580596923828125f)) + (_1990 - (_1993 * dot(_1993, _1990)))), clamp(_1821 * (_1874 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return _5300;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_417_fa_cl_info.x) + int(_417_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_417_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _476_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _476_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _595 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _608 = (c - (ru * hx)) - p;\n        float3 _614 = ru * (2.0f * hx);\n        float _620 = max(dot(_614, _614), 9.9999999392252902907785028219223e-09f);\n        float _624 = dot(_608, _614);\n        float t = clamp((-_624) / _620, 0.0f, 1.0f);\n        if (_595)\n        {\n            float _639 = dot(r, _614);\n            float _645 = _620 - (_639 * _639);\n            if (abs(_645) > (9.9999997473787516355514526367188e-06f * _620))\n            {\n                t = clamp(((dot(r, _608) * _639) - _624) / _645, 0.0f, 1.0f);\n            }\n        }\n        return (p + _608) + (_614 * t);\n    }\n    float3 q = p;\n    float _677 = dot(r, axis);\n    bool _685;\n    if (_595)\n    {\n        _685 = abs(_677) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _685 = _595;\n    }\n    if (_685)\n    {\n        float _695 = dot(c - p, axis) / _677;\n        if (_695 > 0.0f)\n        {\n            q = p + (r * _695);\n        }\n    }\n    float3 _708 = q - c;\n    float2 xy = float2(dot(_708, ru), dot(_708, uu));\n    if (shape > 0.5f)\n    {\n        float _723 = length(xy);\n        if (_723 > hx)\n        {\n            xy *= (hx / _723);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _366 = abs(d);\n    float _368 = _366.x;\n    float _370 = _366.y;\n    bool _371 = _368 >= _370;\n    bool _379;\n    if (_371)\n    {\n        _379 = _368 >= _366.z;\n    }\n    else\n    {\n        _379 = _371;\n    }\n    int _380;\n    if (_379)\n    {\n        _380 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _395;\n        if (_370 >= _366.z)\n        {\n            _395 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _395 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _380 = _395;\n    }\n    return _380;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _515 = dot(d, right);\n    float _519 = dot(d, up);\n    float _530;\n    if (((_515 * _515) + (_519 * _519)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _530 = atan2(_519, _515) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _530 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_530 - floor(_530)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _761 = fa_light_base(param);\n    bool _765 = _417_fa_ambient.w > 4.5f;\n    int param_1 = _761;\n    float4 _769 = fa_light_texel(param_1);\n    int param_2 = _761 + 1;\n    float4 _774 = fa_light_texel(param_2);\n    float _777 = _774.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _789 = _765 && (_777 > 2.5f);\n    fa_light_is_area = _789;\n    bool _791 = _777 < 0.5f;\n    float3 l;\n    if (_791)\n    {\n        l = normalize(_769.xyz);\n        if (_765)\n        {\n            int param_3 = _761 + 6;\n            float4 _805 = fa_light_texel(param_3);\n            if (_805.z > 0.5f)\n            {\n                int param_4 = _761 + 4;\n                float4 _815 = fa_light_texel(param_4);\n                int param_5 = _761 + 5;\n                float4 _820 = fa_light_texel(param_5);\n                float2 param_6 = _805.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _815.xyz) * _815.w, (-dot(world_pos, _820.xyz)) * _820.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _850 = _769.xyz;\n        float3 _852 = _850 - world_pos;\n        float3 to_light = _852;\n        float _855 = length(_852);\n        float reach = _855;\n        bool front = true;\n        if (_789)\n        {\n            int param_8 = _761 + 7;\n            reach = max(_855 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _761 + 4;\n            float4 _879 = fa_light_texel(param_9);\n            int param_10 = _761 + 5;\n            float4 _884 = fa_light_texel(param_10);\n            int param_11 = _761 + 6;\n            float4 _889 = fa_light_texel(param_11);\n            float _890 = _889.w;\n            int param_12 = _761 + 2;\n            float3 _897 = normalize(fa_light_texel(param_12).xyz);\n            bool _899 = _890 > 1.5f;\n            bool _907;\n            if (!_899)\n            {\n                _907 = dot(_897, to_light) < 0.0f;\n            }\n            else\n            {\n                _907 = _899;\n            }\n            front = _907;\n            float3 r = 0.0f.xxx;\n            float3 _916 = _417_fa_camera_pos.xyz - world_pos;\n            bool _920 = dot(n, n) > 0.5f;\n            bool _928;\n            if (_920)\n            {\n                _928 = dot(_916, _916) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _928 = _920;\n            }\n            if (_928)\n            {\n                r = reflect(-normalize(_916), normalize(n));\n            }\n            float3 param_13 = _850;\n            float3 param_14 = _897;\n            float3 param_15 = _879.xyz;\n            float3 param_16 = _884.xyz;\n            float param_17 = _879.w;\n            float param_18 = _884.w;\n            float param_19 = _890;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _964 = length(to_light);\n        dist = _964;\n        l = to_light / max(_964, 9.9999997473787516355514526367188e-05f).xxx;\n        float _978 = reach / max(_769.w, 0.001000000047497451305389404296875f);\n        float _984 = clamp(1.0f - (_978 * _978), 0.0f, 1.0f);\n        float _986;\n        if (front)\n        {\n            _986 = _984 * _984;\n        }\n        else\n        {\n            _986 = 0.0f;\n        }\n        atten = _986;\n        bool _997 = _777 < 2.5f;\n        if ((_777 > 1.5f) && _997)\n        {\n            int param_22 = _761 + 2;\n            float4 _1005 = fa_light_texel(param_22);\n            float _1015 = _1005.w;\n            int param_23 = _761 + 3;\n            float4 _1020 = fa_light_texel(param_23);\n            float _1021 = _1020.x;\n            float cos_inner = _1021;\n            if (_1021 > 1.5f)\n            {\n                cos_inner = lerp(_1015, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1015, cos_inner, dot(-l, normalize(_1005.xyz)));\n        }\n        if (_765 && (_777 < 1.5f))\n        {\n            int param_24 = _761 + 6;\n            float4 _1045 = fa_light_texel(param_24);\n            if (_1045.z > 0.5f)\n            {\n                float3 _1053 = -to_light;\n                int param_25 = _761 + 4;\n                int param_26 = _761 + 5;\n                float3 _1067 = fa_light_texel(param_25).xyz;\n                float3 _1071 = fa_light_texel(param_26).xyz;\n                float3 _1080 = float3(dot(_1053, _1067), dot(_1053, _1071), dot(_1053, cross(_1067, _1071)));\n                float3 param_27 = _1080;\n                int _1084 = fa_cube_face(param_27);\n                int param_28 = _1084;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1111 = float2(dot(_1080, cross(param_29, param_30)), dot(_1080, param_30)) / max(dot(_1080, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1115 = _1084 / 3;\n                float2 param_31 = _1045.xy + (float2(float(_1084 - (_1115 * 3)), float(_1115)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1111.x), 0.5f - (0.5f * _1111.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _761 + 7;\n            float4 _1145 = fa_light_texel(param_33);\n            if (_1145.z > 0.5f)\n            {\n                int param_34 = _761 + 2;\n                int param_35 = _761 + 4;\n                int param_36 = _761 + 5;\n                float2 param_37 = _1145.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_765 && _997)\n            {\n                int param_42 = _761 + 6;\n                float4 _1192 = fa_light_texel(param_42);\n                int param_43 = _761 + 7;\n                float4 _1197 = fa_light_texel(param_43);\n                bool _1200 = _1192.z > 0.5f;\n                bool _1207;\n                if (!_1200)\n                {\n                    _1207 = _1197.z > 0.5f;\n                }\n                else\n                {\n                    _1207 = _1200;\n                }\n                if (_1207)\n                {\n                    int param_44 = _761 + 2;\n                    float4 _1214 = fa_light_texel(param_44);\n                    float3 _1218 = normalize(_1214.xyz);\n                    int param_45 = _761 + 4;\n                    float4 _1223 = fa_light_texel(param_45);\n                    int param_46 = _761 + 5;\n                    float4 _1228 = fa_light_texel(param_46);\n                    if (_1200)\n                    {\n                        float3 _1236 = -to_light;\n                        float _1243 = _1214.w;\n                        float _1259 = 0.5f / max(dot(_1236, _1218) * (sqrt(max(1.0f - (_1243 * _1243), 0.0f)) / max(_1243, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1192.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1236, _1223.xyz) * _1259), 0.5f - (dot(_1236, _1228.xyz) * _1259));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1197.z > 0.5f)\n                    {\n                        float2 param_49 = _1197.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1218;\n                        float3 param_52 = _1223.xyz;\n                        float3 param_53 = _1228.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4940 = _774.xyz * atten;\n    if (_765)\n    {\n        _4940 *= fa_light_tint;\n    }\n    int _1328;\n    if (_791)\n    {\n        _1328 = 0;\n    }\n    else\n    {\n        _1328 = ((_777 > 1.5f) && (_777 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _4951 = { l, _4940, atten, 1.0f, dist, _1328 };\n    return _4951;\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _4033 = n < 0;\n    bool _4040;\n    if (!_4033)\n    {\n        _4040 = n >= fa_light_count();\n    }\n    else\n    {\n        _4040 = _4033;\n    }\n    if (_4040)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _4048 = fa_cl_light(param);\n    bool _4051 = fa_lm.z > 0.5f;\n    bool _4057;\n    if (_4051)\n    {\n        int param_1 = _4048;\n        _4057 = fa_light_baked(param_1);\n    }\n    else\n    {\n        _4057 = _4051;\n    }\n    if (_4057)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _4048;\n    float3 param_3 = i.world_pos;\n    float3 param_4 = i.world_normal;\n    LightSample _4070 = fa_light_sample_n(param_2, param_3, param_4);\n    return _4070;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2065;\n    if (i == 0)\n    {\n        _2065 = _2075_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2081;\n        if (i == 1)\n        {\n            _2081 = _2075_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2089;\n            if (i == 2)\n            {\n                _2089 = _2075_fa_shadow_split.z;\n            }\n            else\n            {\n                _2089 = _2075_fa_shadow_split.w;\n            }\n            _2081 = _2089;\n        }\n        _2065 = _2081;\n    }\n    return _2065;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2122 = fa_shadow_depth(param, param_1);\n    float _2126;\n    if (conv.x < 0.5f)\n    {\n        _2126 = _2122;\n    }\n    else\n    {\n        _2126 = (conv.y * conv.z) / (conv.z - (_2122 * (conv.z - conv.y)));\n    }\n    return _2126;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2053 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2053), sin(_2053)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2172 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2181;\n        if (k < 0.0f)\n        {\n            _2181 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2181 = k;\n        }\n        float _2201 = clamp((_2181 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2172;\n            float2 _2220 = fa_shadow_vogel(param_3, param_4, param_5) * _2201;\n            float2 param_6 = uv + (_2220 * _2075_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2232 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2232 < (zr - (length(_2220) * plane)))\n            {\n                sum += _2232;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2258 = sum / cnt;\n        float _2268;\n        if (k < 0.0f)\n        {\n            _2268 = (-k) / max(_2258, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2268 = k;\n        }\n        radius = clamp(((max(zr - _2258, 0.0f) * unit) * _2268) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2290 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2290; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2290;\n        float param_11 = _2172;\n        float2 _2309 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2309 * _2075_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2309) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2290);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2351 = max(_2075_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2356 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2362 = sqrt(1.0f - (_2356 * _2356));\n    float _2369 = min(_2362 / max(_2356, 0.20000000298023223876953125f), 4.0f);\n    float _2374;\n    if (_2075_fa_shadow_bias.y > 0.0f)\n    {\n        _2374 = _2075_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2374 = 1.5f * _2075_fa_shadow_info[ci].x;\n    }\n    float4 _2399 = mul(float4(world + (n * (_2374 * _2362)), 1.0f), _2075_fa_shadow_mat[ci]);\n    float _2406 = _2399.x;\n    bool _2409 = _2406 < _2075_fa_shadow_rect[ci].x;\n    bool _2418;\n    if (!_2409)\n    {\n        _2418 = _2406 > _2075_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2418 = _2409;\n    }\n    bool _2427;\n    if (!_2418)\n    {\n        _2427 = _2399.y < _2075_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2427 = _2418;\n    }\n    bool _2436;\n    if (!_2427)\n    {\n        _2436 = _2399.y > _2075_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2436 = _2427;\n    }\n    bool _2443;\n    if (!_2436)\n    {\n        _2443 = _2399.z > 1.0f;\n    }\n    else\n    {\n        _2443 = _2436;\n    }\n    if (_2443)\n    {\n        return -1.0f;\n    }\n    float _2451;\n    if (_2075_fa_shadow_bias.x > 0.0f)\n    {\n        _2451 = _2075_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2451 = 1.5f * _2075_fa_shadow_info[ci].x;\n    }\n    float2 param = _2399.xy;\n    float4 param_1 = _2075_fa_shadow_rect[ci];\n    float param_2 = _2399.z - ((_2451 * (1.0f + (0.5f * _2369))) / _2351);\n    float param_3 = _2075_fa_shadow_info[ci].x;\n    float param_4 = _2351;\n    float param_5 = _2351 * 0.25f;\n    float param_6 = ((_2075_fa_shadow_info[ci].x * min(_2369, 3.0f)) * 0.5f) / _2351;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2075_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2075_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_417_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2829 = int(_2075_fa_shadow_cfg.x + 0.5f);\n    if (_2829 < 1)\n    {\n        return 1.0f;\n    }\n    float _2844 = dot(world - _2075_fa_shadow_eye.xyz, _2075_fa_shadow_fwd.xyz);\n    int param = _2829 - 1;\n    if (_2844 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2856 = _2829 > 1;\n    bool _2863;\n    if (_2856)\n    {\n        _2863 = _2844 > _2075_fa_shadow_split.x;\n    }\n    else\n    {\n        _2863 = _2856;\n    }\n    if (_2863)\n    {\n        ci = 1;\n    }\n    bool _2867 = _2829 > 2;\n    bool _2874;\n    if (_2867)\n    {\n        _2874 = _2844 > _2075_fa_shadow_split.y;\n    }\n    else\n    {\n        _2874 = _2867;\n    }\n    if (_2874)\n    {\n        ci = 2;\n    }\n    bool _2878 = _2829 > 3;\n    bool _2885;\n    if (_2878)\n    {\n        _2885 = _2844 > _2075_fa_shadow_split.z;\n    }\n    else\n    {\n        _2885 = _2878;\n    }\n    if (_2885)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2829)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2911 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2911;\n        if (_2911 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2075_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2936;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2936 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2936 = _2075_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2955 = _2075_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2936, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2966 = clamp((_2844 - (fa_shadow_split_at(param_7) - _2955)) / _2955, 0.0f, 1.0f);\n        if (_2966 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2829)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2987 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2987;\n                if (_2987 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2966);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2509 = _417_fa_pbr.z < 0.5f;\n    bool _2516;\n    if (!_2509)\n    {\n        _2516 = _2075_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2516 = _2509;\n    }\n    if (_2516)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2075_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2529 = fa_light_texel(param);\n    float _2530 = _2529.x;\n    if (_2530 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2539 = int(_2530 + 0.5f);\n    int param_1 = _2539;\n    float4 _2543 = fa_light_texel(param_1);\n    int param_2 = _2539 + 1;\n    float4 _2548 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2551 = _2543.y;\n    if (_2551 > 0.0f)\n    {\n        float _2568 = 1.0f - smoothstep(0.75f * _2551, _2551, length(world - _2075_fa_shadow_eye.xyz));\n        fade = _2568;\n        if (_2568 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2543.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2592 = (_2539 + 2) + (face * 6);\n    int param_4 = _2592;\n    int param_5 = _2592 + 1;\n    int param_6 = _2592 + 3;\n    float4 _2606 = fa_light_texel(param_6);\n    int param_7 = _2592 + 4;\n    float4 _2611 = fa_light_texel(param_7);\n    int param_8 = _2592 + 5;\n    float4 _2616 = fa_light_texel(param_8);\n    float _2628 = _2616.x * max(dot(_2606, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2633 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2656 = clamp(dot(n, _2606.xyz), -1.0f, 1.0f);\n    float _2675 = min(sqrt(1.0f - (_2656 * _2656)) / max(abs(dot(n, world - lpos)) / max(dot(_2606, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2678 = _2548.y;\n    float _2680;\n    if (_2678 > 0.0f)\n    {\n        _2680 = _2678;\n    }\n    else\n    {\n        _2680 = 1.5f * _2628;\n    }\n    float4 _2700 = float4(world + (n * (_2680 * sqrt(1.0f - (_2633 * _2633)))), 1.0f);\n    float _2704 = dot(_2606, _2700);\n    float _2707 = _2616.y;\n    if (_2704 < _2707)\n    {\n        return 1.0f;\n    }\n    float2 _2722 = float2(dot(fa_light_texel(param_4), _2700), dot(fa_light_texel(param_5), _2700)) / _2704.xx;\n    float _2724 = _2722.x;\n    bool _2727 = _2724 < _2611.x;\n    bool _2736;\n    if (!_2727)\n    {\n        _2736 = _2724 > _2611.z;\n    }\n    else\n    {\n        _2736 = _2727;\n    }\n    bool _2745;\n    if (!_2736)\n    {\n        _2745 = _2722.y < _2611.y;\n    }\n    else\n    {\n        _2745 = _2736;\n    }\n    bool _2754;\n    if (!_2745)\n    {\n        _2754 = _2722.y > _2611.w;\n    }\n    else\n    {\n        _2754 = _2745;\n    }\n    if (_2754)\n    {\n        return 1.0f;\n    }\n    float _2760 = _2548.x;\n    float _2762;\n    if (_2760 > 0.0f)\n    {\n        _2762 = _2760;\n    }\n    else\n    {\n        _2762 = 1.5f * _2628;\n    }\n    float2 param_9 = _2722;\n    float4 param_10 = _2611;\n    float param_11 = _2704 - (_2762 * (1.0f + (0.5f * _2675)));\n    float param_12 = _2628;\n    float param_13 = 1.0f;\n    float param_14 = _2616.z * 0.25f;\n    float param_15 = (_2628 * min(_2675, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2707, _2616.z);\n    int param_17 = int(_2543.z + 0.5f);\n    float param_18 = _2543.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _3910 = fa_lm.z > 0.5f;\n    bool _3916;\n    if (_3910)\n    {\n        int param = li;\n        _3916 = fa_light_baked(param);\n    }\n    else\n    {\n        _3916 = _3910;\n    }\n    if (_3916)\n    {\n        int param_1 = li;\n        LightSample _5084 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _5084;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3940 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _5086 = _3940.color;\n    float _5088 = _3940.shadow;\n    if ((_3940.type == 0) && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3940.direction;\n        float _3954 = fa_shadow_factor(param_5, param_6);\n        _5088 = _3954;\n        _5086 *= _3954;\n    }\n    else\n    {\n        bool _3965 = _3940.type != 0;\n        bool _3971;\n        if (_3965)\n        {\n            _3971 = _3940.attenuation > 0.0f;\n        }\n        else\n        {\n            _3971 = _3965;\n        }\n        if (_3971)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _3940.direction;\n            float _3990 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _5088 = _3990;\n            _5086 *= _3990;\n        }\n    }\n    LightSample _5103 = { _3940.direction, _5086, _3940.attenuation, _5088, _3940._distance, _3940.type };\n    return _5103;\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _4007 = n < 0;\n    bool _4014;\n    if (!_4007)\n    {\n        _4014 = n >= fa_light_count();\n    }\n    else\n    {\n        _4014 = _4007;\n    }\n    if (_4014)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    LightSample _4029 = fa_light_shadowed(param_1, param_2, param_3);\n    return _4029;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3266 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3274 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3277 = int(_3266);\n    int _3280 = int(_3274);\n    float _3290 = _3274 - float(_3280);\n    int _3346 = (_3277 * 9) + _3280;\n    int _3366 = ((_3277 + 1) * 9) + _3280;\n    return lerp(lerp(_3341[_3346], _3341[_3346 + 1], _3290), lerp(_3341[_3366], _3341[_3366 + 1], _3290), _3266 - float(_3277));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _4952 = false;\n    float _4953 = 1.0f;\n    float _4954 = 1.0f;\n    float _4955 = 1.0f;\n    float _4956 = 0.0f;\n    float _4957 = 0.0f;\n    float _4958 = 0.0f;\n    float _4959 = 0.0f;\n    float _4961 = 1.0f;\n    bool _4962 = false;\n    float3 _4963 = 0.0f.xxx;\n    float _4964 = 1.0f;\n    float _4965 = 1.0f;\n    float _4966 = 1.0f;\n    float _4967 = 0.0f;\n    float _4968 = 0.0f;\n    float3 _4969 = float3(1.0f, 0.0f, 0.0f);\n    float3 _4970 = float3(0.0f, 0.0f, 1.0f);\n    float _4971 = 1.0f;\n    float _4972 = 1.0f;\n    float _3417 = clamp(s.specular, 0.0f, 1.0f);\n    float _3421 = clamp(s.ior, 1.0f, 3.0f);\n    bool _3426 = (_3417 != 1.0f) || (_3421 != 1.5f);\n    bool _3435;\n    if (!_3426)\n    {\n        _3435 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _3435 = _3426;\n    }\n    if (_3435)\n    {\n        float _3443 = (_3421 - 1.0f) / (_3421 + 1.0f);\n        f0 = lerp(min((_3443 * _3443).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _3417, s.albedo, metallic.xxx);\n        _4953 = lerp(_3417, 1.0f, metallic);\n        _4952 = true;\n    }\n    float _3470 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_3470 > 0.0f)\n    {\n        float _3478 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _4956 = _3470;\n        _4957 = _3478;\n        float _3485 = _3478 * _3478;\n        _4958 = _3485;\n        _4959 = _3485 * _3485;\n        float _3497 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _4961 = _3497;\n        _4954 = 1.0f - (_3470 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _3497, 0.0f, 1.0f), 5.0f))));\n        _4952 = true;\n    }\n    float3 _3517 = max(s.sheen_color, 0.0f.xxx);\n    float _3526 = max(_3517.x, max(_3517.y, _3517.z));\n    if (_3526 > 0.0f)\n    {\n        float _3534 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _4962 = true;\n        _4963 = _3517;\n        _4964 = _3534;\n        _4965 = _3534 * _3534;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _3534;\n        float _3551 = fa_sheen_albedo(param, param_1);\n        _4967 = _3551;\n        _4966 = 1.0f - min(_3526 * _3551, 1.0f);\n        _4952 = true;\n    }\n    _4955 = _4954 * _4966;\n    float _3570 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_3570 != 0.0f)\n    {\n        float3 _3585 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _3585;\n        if (dot(_3585, _3585) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _3597 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_3597.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _3597.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _3597.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _3601 = t;\n        float3 _3602 = normalize(_3601);\n        t = _3602;\n        float3 _3627 = normalize((_3602 * cos(s.anisotropy_rotation)) + ((cross(n, _3602) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _4969 = _3627;\n        _4970 = cross(n, _3627);\n        float _3637 = roughness * roughness;\n        float _3643 = lerp(_3637, 1.0f, _3570 * _3570);\n        bool _3645 = _3570 > 0.0f;\n        _4971 = _3645 ? _3643 : _3637;\n        _4972 = _3645 ? _3637 : _3643;\n        _4968 = _3570;\n        _4952 = true;\n    }\n    FaLayers _4994 = { _4952, _4953, _4954, _4955, _4956, _4957, _4958, _4959, i.world_normal, _4961, _4962, _4963, _4964, _4965, _4966, _4967, _4968, _4969, _4970, _4971, _4972 };\n    return _4994;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3198 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3201 = _3198.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3201 * _3201, exp2((-9.27999973297119140625f) * ndv)) * _3201) + _3198.y)) + _3198.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_417_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _417_fa_env_horizon.w).xyz;\n    }\n    float _3122 = rough * rough;\n    float _3152 = 0.60000002384185791015625f * _3122;\n    return lerp(lerp(_417_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_417_fa_env_horizon.xyz, _417_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3122)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3152, 0.0500000007450580596923828125f + _3152, d.y).xxx), ((_417_fa_env_sky.xyz + _417_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3122 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _3678;\n        if (L.aniso >= 0.0f)\n        {\n            _3678 = L.b;\n        }\n        else\n        {\n            _3678 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_3678, v), _3678), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3711 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _3711.x) + (L.f90.xxx * _3711.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3766 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _3766.x) + _3766.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3240 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3240.x) + _3240.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _3805 = clamp(s.metallic, 0.0f, 1.0f);\n    float _3809 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _3816 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _3805.xxx);\n    float3 f0 = _3816;\n    float3 _3820 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _3820;\n    float3 param_3 = i.view_dir;\n    float param_4 = _3805;\n    float param_5 = _3809;\n    float3 param_6 = _3816;\n    FaLayers _3837 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_3837.on)\n    {\n        FaLayers param_7 = _3837;\n        float3 param_8 = _3820;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _3809;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _3820;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _3809;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0f;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _4090 = fa_light_unshadowed(param, param_1);\n        float _4098 = dot(_4090.color, float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));\n        if (_4098 > bestPower)\n        {\n            bestPower = _4098;\n            best = n;\n        }\n    }\n    float3 lit = (_417_fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _4127 = fa_light(param_2, param_3);\n        float _4135;\n        if (dot(s.normal, _4127.direction) > 0.5f)\n        {\n            _4135 = 1.0f;\n        }\n        else\n        {\n            _4135 = _4141_dark;\n        }\n        lit += ((s.albedo * _4127.color) * _4135);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * _4141_skyAmount);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2075_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3011 = int(_2075_fa_shadow_cfg.x + 0.5f);\n    float _3021 = dot(world - _2075_fa_shadow_eye.xyz, _2075_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3026 = _3011 > 0;\n    bool _3035;\n    if (_3026)\n    {\n        int param = _3011 - 1;\n        _3035 = _3021 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3035 = _3026;\n    }\n    if (_3035)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3041 = _3011 > 1;\n        bool _3048;\n        if (_3041)\n        {\n            _3048 = _3021 > _2075_fa_shadow_split.x;\n        }\n        else\n        {\n            _3048 = _3041;\n        }\n        if (_3048)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3054 = _3011 > 2;\n        bool _3061;\n        if (_3054)\n        {\n            _3061 = _3021 > _2075_fa_shadow_split.y;\n        }\n        else\n        {\n            _3061 = _3054;\n        }\n        if (_3061)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3067 = _3011 > 3;\n        bool _3074;\n        if (_3067)\n        {\n            _3074 = _3021 > _2075_fa_shadow_split.z;\n        }\n        else\n        {\n            _3074 = _3067;\n        }\n        if (_3074)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _4826 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4826 = -_4826;\n    }\n    float3 _4513 = normalize(_417_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _4839 = { fa_world_pos, _4826, fa_world_tangent, fa_uv, fa_vertex_color, _4513, gl_FrontFacing };\n    SurfaceInput param_1 = _4839;\n    Surface _4521 = fa_standard_surface(param_1);\n    float3 _4857 = _4521.albedo;\n    float _4858 = _4521.alpha;\n    float3 _4859 = _4521.normal;\n    float _4860 = _4521.metallic;\n    float _4861 = _4521.roughness;\n    float _4862 = _4521.occlusion;\n    float3 _4863 = _4521.emission;\n    float _4864 = _4521.clearcoat;\n    float _4865 = _4521.clearcoat_roughness;\n    float3 _4866 = _4521.sheen_color;\n    float _4867 = _4521.sheen_roughness;\n    float _4868 = _4521.anisotropy;\n    float _4869 = _4521.anisotropy_rotation;\n    float _4870 = _4521.specular;\n    float _4871 = _4521.ior;\n    float3 _4872 = _4521.specular_color;\n    SurfaceInput _4847 = { fa_world_pos, _4826, fa_world_tangent, fa_uv, fa_vertex_color, _4513, gl_FrontFacing };\n    SurfaceInput param_2 = _4847;\n    Surface param_3 = _4521;\n    surface(param_2, param_3);\n    _4857 = param_3.albedo;\n    _4858 = param_3.alpha;\n    _4859 = param_3.normal;\n    _4860 = param_3.metallic;\n    _4861 = param_3.roughness;\n    _4862 = param_3.occlusion;\n    _4863 = param_3.emission;\n    _4864 = param_3.clearcoat;\n    _4865 = param_3.clearcoat_roughness;\n    _4866 = param_3.sheen_color;\n    _4867 = param_3.sheen_roughness;\n    _4868 = param_3.anisotropy;\n    _4869 = param_3.anisotropy_rotation;\n    _4870 = param_3.specular;\n    _4871 = param_3.ior;\n    _4872 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _4826;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4857 = param_6;\n    _4859 = param_7;\n    float3 result;\n    if (_417_fa_emissive.w > 0.5f)\n    {\n        result = _4857;\n    }\n    else\n    {\n        float3 _4559 = _4859;\n        float3 _4560 = normalize(_4559);\n        _4859 = _4560;\n        SurfaceInput _4855 = { fa_world_pos, _4826, fa_world_tangent, fa_uv, fa_vertex_color, _4513, gl_FrontFacing };\n        SurfaceInput param_8 = _4855;\n        Surface _4938 = { _4857, _4858, _4560, _4860, _4861, _4862, _4863, _4864, _4865, _4866, _4867, _4868, _4869, _4870, _4871, _4872 };\n        Surface param_9 = _4938;\n        float3 _4571 = lighting(param_8, param_9);\n        result = _4571;\n    }\n    float3 _4575 = result;\n    float3 _4576 = _4575 + _4863;\n    result = _4576;\n    float3 param_10 = _4576;\n    float3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _4585 = _417_fa_fog.w > 0.0f;\n    bool _4592;\n    if (!_4585)\n    {\n        _4592 = _417_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _4592 = _4585;\n    }\n    if (_4592)\n    {\n        float3 _4601 = fa_world_pos - _417_fa_camera_pos.xyz;\n        float _4607 = dot(_4601, _417_fa_fog_c.xyz);\n        bool _4611 = _417_fa_fog_c.w > 0.5f;\n        float _4612;\n        if (_4611)\n        {\n            _4612 = _4607;\n        }\n        else\n        {\n            _4612 = length(_4601);\n        }\n        float _4624 = _4612 - _417_fa_fog_b.x;\n        if (_4624 > 0.0f)\n        {\n            float _4633 = _417_fa_fog.w * _4624;\n            float tau = _4633 * _4633;\n            if (_417_fa_fog_b.y > 0.0f)\n            {\n                float _4649;\n                if (_4611)\n                {\n                    _4649 = fa_world_pos.y - (_417_fa_fog_c.y * _4607);\n                }\n                else\n                {\n                    _4649 = _417_fa_camera_pos.y;\n                }\n                float _4670 = lerp(_4649, fa_world_pos.y, clamp(_417_fa_fog_b.x / _4612, 0.0f, 1.0f));\n                float _4674 = fa_world_pos.y - _4670;\n                float _4679 = _4670 - _417_fa_fog_b.z;\n                float _4684 = fa_world_pos.y - _417_fa_fog_b.z;\n                bool _4687 = _4679 <= 0.0f;\n                bool _4688 = !_4687;\n                bool _4694;\n                if (_4688)\n                {\n                    _4694 = _417_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4694 = _4687;\n                }\n                float _4695;\n                if (_4694)\n                {\n                    _4695 = _417_fa_fog_b.y;\n                }\n                else\n                {\n                    _4695 = _417_fa_fog_b.y * exp(-min(_417_fa_fog_b.w * _4679, 80.0f));\n                }\n                bool _4722;\n                if (_4688)\n                {\n                    _4722 = _417_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4722 = _4687;\n                }\n                float _4723;\n                if (_4722)\n                {\n                    _4723 = _417_fa_fog_b.y * _4679;\n                }\n                else\n                {\n                    _4723 = (_417_fa_fog_b.y * (1.0f - exp(-min(_417_fa_fog_b.w * _4679, 80.0f)))) / _417_fa_fog_b.w;\n                }\n                bool _4748 = _4684 <= 0.0f;\n                bool _4755;\n                if (!_4748)\n                {\n                    _4755 = _417_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4755 = _4748;\n                }\n                float _4756;\n                if (_4755)\n                {\n                    _4756 = _417_fa_fog_b.y * _4684;\n                }\n                else\n                {\n                    _4756 = (_417_fa_fog_b.y * (1.0f - exp(-min(_417_fa_fog_b.w * _4684, 80.0f)))) / _417_fa_fog_b.w;\n                }\n                float _4783;\n                if (abs(_4674) < 0.001000000047497451305389404296875f)\n                {\n                    _4783 = _4695;\n                }\n                else\n                {\n                    _4783 = (_4756 - _4723) / _4674;\n                }\n                tau += (_4624 * max(_4783, 0.0f));\n            }\n            result = lerp(result, _417_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4858);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_417",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2075",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_4141",
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
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 9
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
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
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
          },
          {
            "slot": 9,
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _787 = base_t;\n    _787.x = _225.x;\n    _787.y = _225.y;\n    _787.z = _225.z;\n    base_t = _787;\n    float4 _241 = (_787 * _213_fa_base_color) * i.vertex_color;\n    float3 _750 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _795 = _279;\n        _795.x = _284.x;\n        _795.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _795;\n        _750 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _798 = mrt;\n    _798.x = _313.x;\n    _798.y = _313.y;\n    _798.z = _313.z;\n    mrt = _798;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _755 = _213_fa_layers_a.x;\n    float _756 = _213_fa_layers_a.y;\n    float _759 = _213_fa_layers_a.z;\n    float _758 = _213_fa_layers_b.w;\n    float _761 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _755 *= _355.y;\n            _756 *= _355.z;\n            _758 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _759 *= mrt.x;\n            _761 *= mrt.w;\n        }\n    }\n    Surface _780 = { _241.xyz, _241.w, _750, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _755, _756, _213_fa_layers_b.xyz, _758, _759, _213_fa_layers_a.w, _761, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _780;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _661 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _661 = -_661;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _674 = { fa_world_pos, _661, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _674;\n    SurfaceInput _682 = { fa_world_pos, _661, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _682;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _787 = base_t;\n    _787.x = _225.x;\n    _787.y = _225.y;\n    _787.z = _225.z;\n    base_t = _787;\n    float4 _241 = (_787 * _213_fa_base_color) * i.vertex_color;\n    float3 _750 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _795 = _279;\n        _795.x = _284.x;\n        _795.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _795;\n        _750 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _798 = mrt;\n    _798.x = _313.x;\n    _798.y = _313.y;\n    _798.z = _313.z;\n    mrt = _798;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _755 = _213_fa_layers_a.x;\n    float _756 = _213_fa_layers_a.y;\n    float _759 = _213_fa_layers_a.z;\n    float _758 = _213_fa_layers_b.w;\n    float _761 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _755 *= _355.y;\n            _756 *= _355.z;\n            _758 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _759 *= mrt.x;\n            _761 *= mrt.w;\n        }\n    }\n    Surface _780 = { _241.xyz, _241.w, _750, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _755, _756, _213_fa_layers_b.xyz, _758, _759, _213_fa_layers_a.w, _761, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _780;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _661 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _661 = -_661;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _674 = { fa_world_pos, _661, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _674;\n    SurfaceInput _682 = { fa_world_pos, _661, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _682;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
