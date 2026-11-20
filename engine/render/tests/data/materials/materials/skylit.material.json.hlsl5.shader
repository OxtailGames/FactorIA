{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "5c278b25d8ce4341984c8bf2a53e1ca7890b6a924713889b53c089df056597d0",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _260 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _260;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_267, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _2695[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _503_fa_camera_pos : packoffset(c0);\n    float4 _503_fa_ambient : packoffset(c1);\n    float4 _503_fa_base_color : packoffset(c2);\n    float4 _503_fa_emissive : packoffset(c3);\n    float4 _503_fa_model_emissive : packoffset(c4);\n    float4 _503_fa_pbr : packoffset(c5);\n    float4 _503_fa_maps : packoffset(c6);\n    float4 _503_fa_fog : packoffset(c7);\n    float4 _503_fa_fog_b : packoffset(c8);\n    float4 _503_fa_fog_c : packoffset(c9);\n    float4 _503_fa_counts : packoffset(c10);\n    float4 _503_fa_env_sky : packoffset(c11);\n    float4 _503_fa_env_horizon : packoffset(c12);\n    float4 _503_fa_time : packoffset(c13);\n    float4 _503_fa_cl_vpx : packoffset(c14);\n    float4 _503_fa_cl_vpy : packoffset(c15);\n    float4 _503_fa_cl_vpw : packoffset(c16);\n    float4 _503_fa_cl_fwd : packoffset(c17);\n    float4 _503_fa_cl_grid : packoffset(c18);\n    float4 _503_fa_cl_info : packoffset(c19);\n    float4 _503_fa_layers_a : packoffset(c20);\n    float4 _503_fa_layers_b : packoffset(c21);\n    float4 _503_fa_layers_c : packoffset(c22);\n    float4 _503_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _1243_fa_shadow_mat[4] : packoffset(c0);\n    float4 _1243_fa_shadow_rect[4] : packoffset(c16);\n    float4 _1243_fa_shadow_info[4] : packoffset(c20);\n    float4 _1243_fa_shadow_split : packoffset(c24);\n    float4 _1243_fa_shadow_cfg : packoffset(c25);\n    float4 _1243_fa_shadow_bias : packoffset(c26);\n    float4 _1243_fa_shadow_eye : packoffset(c27);\n    float4 _1243_fa_shadow_fwd : packoffset(c28);\n    float4 _1243_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_decal_tex : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t8);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _508 = _503_fa_cl_info.x < 0.0f;\n    bool _515;\n    if (!_508)\n    {\n        _515 = _503_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _515 = _508;\n    }\n    bool _523;\n    if (!_515)\n    {\n        _523 = _503_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _523 = _515;\n    }\n    bool _530;\n    if (!_523)\n    {\n        _530 = _503_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _530 = _523;\n    }\n    bool _537;\n    if (!_530)\n    {\n        _537 = _503_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _537 = _530;\n    }\n    if (_537)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _547 = float4(world_pos, 1.0f);\n    float _554 = dot(_503_fa_cl_vpw, _547);\n    if (!(_554 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _576 = float2(dot(_503_fa_cl_vpx, _547), dot(_503_fa_cl_vpy, _547)) / _554.xx;\n    int _580 = int(_503_fa_cl_grid.x);\n    int _584 = int(_503_fa_cl_grid.y);\n    int param = (int(_503_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_503_fa_cl_fwd.xyz, world_pos) + _503_fa_cl_fwd.w, _503_fa_cl_grid.w) / _503_fa_cl_grid.w) * _503_fa_cl_grid.z)), 0, int(_503_fa_cl_info.y) - 1) * _584) + clamp(int(floor(((_576.y * 0.5f) + 0.5f) * _503_fa_cl_grid.y)), 0, _584 - 1)) * _580)) + clamp(int(floor(((_576.x * 0.5f) + 0.5f) * _503_fa_cl_grid.x)), 0, _580 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _660 = fa_cluster_texel(param);\n    return int2(int(_660.x), int(_660.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_503_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3230 = fa_cluster_lookup(param);\n    fa_cl_slot = _3230.x;\n    fa_cl_local = _3230.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _3384 = fa_linear_to_srgb(param);\n        c = _3384;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _3392 = fa_srgb_to_linear(param_1);\n            c = _3392;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _268;\n    if (i.front_facing)\n    {\n        _268 = i.world_normal;\n    }\n    else\n    {\n        _268 = -i.world_normal;\n    }\n    float3 _292 = normalize(i.world_tangent.xyz - (_268 * dot(_268, i.world_tangent.xyz)));\n    float3 _319 = normalize(((_292 * m.x) + ((cross(_268, _292) * i.world_tangent.w) * m.y)) + (_268 * m.z));\n    float3 _322;\n    if (i.front_facing)\n    {\n        _322 = _319;\n    }\n    else\n    {\n        _322 = -_319;\n    }\n    return _322;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _503_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3423 = fa_tex_fix(param_2, param_3);\n    float4 _4525 = base_t;\n    _4525.x = _3423.x;\n    _4525.y = _3423.y;\n    _4525.z = _3423.z;\n    base_t = _4525;\n    float4 _3437 = (_4525 * _503_fa_base_color) * i.vertex_color;\n    float3 _4392 = i.world_normal;\n    if (_503_fa_maps.z > 0.5f)\n    {\n        float param_4 = _503_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3469 = fa_tex_fix(param_6, param_7);\n        float3 _3472 = (_3469 * 2.0f) - 1.0f.xxx;\n        float2 _3477 = _3472.xy * _503_fa_maps.x;\n        float3 _4533 = _3472;\n        _4533.x = _3477.x;\n        _4533.y = _3477.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4533;\n        _4392 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _503_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3506 = fa_tex_fix(param_12, param_13);\n    float4 _4536 = mrt;\n    _4536.x = _3506.x;\n    _4536.y = _3506.y;\n    _4536.z = _3506.z;\n    mrt = _4536;\n    float4 _3534 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _503_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _3534.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3546 = fa_tex_fix(param_16, param_17);\n    float param_18 = _503_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3576 = fa_tex_fix(param_20, param_21);\n    float _4397 = _503_fa_layers_a.x;\n    float _4398 = _503_fa_layers_a.y;\n    float _4401 = _503_fa_layers_a.z;\n    float _4400 = _503_fa_layers_b.w;\n    float _4403 = _503_fa_layers_c.x;\n    if (_503_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_503_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _4397 *= _3546.y;\n            _4398 *= _3546.z;\n            _4400 *= _3534.w;\n        }\n        if (_503_fa_layers_c.z > 1.5f)\n        {\n            _4401 *= mrt.x;\n            _4403 *= mrt.w;\n        }\n    }\n    Surface _4422 = { _3437.xyz, _3437.w, _4392, clamp(_503_fa_pbr.x * _3506.z, 0.0f, 1.0f), clamp(_503_fa_pbr.y * _3506.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_503_fa_maps.y * (_3546.x - 1.0f)), _503_fa_emissive.xyz + (_503_fa_model_emissive.xyz * _3576), _4397, _4398, _503_fa_layers_b.xyz, _4400, _4401, _503_fa_layers_a.w, _4403, _503_fa_layers_c.y, _503_fa_layers_d.xyz };\n    return _4422;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _741 = rect.zw - rect.xy;\n    float2 _745 = _741 * atlas;\n    float2 _749 = ddx * _745;\n    float2 _753 = ddy * _745;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _741), clamp(0.5f * log2(max(max(dot(_749, _749), dot(_753, _753)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _788 = _503_fa_counts.y < 0.5f;\n    bool _795;\n    if (!_788)\n    {\n        _795 = _503_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _795 = _788;\n    }\n    if (_795)\n    {\n        return;\n    }\n    float3 _801 = ddx(world_pos);\n    float3 _804 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _808 = fa_cluster_texel(param);\n    int _812 = int(_808.w);\n    if (_812 < 1)\n    {\n        return;\n    }\n    int _822 = int(_503_fa_counts.y + 0.5f);\n    int param_1 = _822;\n    float4 _826 = fa_light_texel(param_1);\n    float2 _829 = _826.yz;\n    int _833 = int(_826.w);\n    int param_2 = _822 + 1;\n    float4 _838 = fa_light_texel(param_2);\n    float _839 = _838.x;\n    int _845 = int(_503_fa_counts.w + 0.5f) - 1;\n    int _849 = int(_808.z);\n    float3 _1115;\n    for (int k = 0; k < _812; k++)\n    {\n        int _862 = _849 + k;\n        int param_3 = _833 + (_862 >> 2);\n        int _880 = (_822 + 2) + (int(fa_light_texel(param_3)[_862 & 3]) * 7);\n        int param_4 = _880 + 6;\n        float4 _885 = fa_light_texel(param_4);\n        if (((int(_885.w + 0.5f) >> _845) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _880;\n        float4 _900 = fa_light_texel(param_5);\n        int param_6 = _880 + 1;\n        float4 _905 = fa_light_texel(param_6);\n        int param_7 = _880 + 2;\n        float4 _910 = fa_light_texel(param_7);\n        float3 _913 = _900.xyz;\n        float _918 = dot(_913, world_pos) + _900.w;\n        float3 _920 = _905.xyz;\n        float _925 = dot(_920, world_pos) + _905.w;\n        float3 _927 = _910.xyz;\n        float _932 = dot(_927, world_pos) + _910.w;\n        bool _937 = abs(_918) > 0.5f;\n        bool _945;\n        if (!_937)\n        {\n            _945 = abs(_925) > 0.5f;\n        }\n        else\n        {\n            _945 = _937;\n        }\n        bool _953;\n        if (!_945)\n        {\n            _953 = abs(_932) > 0.5f;\n        }\n        else\n        {\n            _953 = _945;\n        }\n        if (_953)\n        {\n            continue;\n        }\n        float _968 = clamp(dot(geo_normal, normalize(_927)) * _885.z, 0.0f, 1.0f);\n        if (_968 <= 0.0f)\n        {\n            continue;\n        }\n        float _988 = (clamp((0.5f - abs(_932)) * 10.0f, 0.0f, 1.0f) * _968) * _885.x;\n        float2 _996 = float2(_918 + 0.5f, 0.5f - _925);\n        float2 _1006 = float2(dot(_913, _801), dot(_920, _801));\n        float2 _1016 = float2(dot(_913, _804), dot(_920, _804));\n        int param_8 = _880 + 5;\n        float4 _1021 = fa_light_texel(param_8);\n        int param_9 = _880 + 3;\n        float4 _1026 = fa_light_texel(param_9);\n        int param_10 = _880 + 4;\n        float4 _1031 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1021.xyz;\n        bool _1041 = _1026.z > _1026.x;\n        if (_1041)\n        {\n            float4 param_11 = _1026;\n            float2 param_12 = _996;\n            float2 param_13 = _829;\n            float2 param_14 = _1006;\n            float2 param_15 = _1016;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_839 > 0.5f) && (_839 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1067 = fa_dc_to_linear(param_16);\n                float4 _4448 = tx;\n                _4448.x = _1067.x;\n                _4448.y = _1067.y;\n                _4448.z = _1067.z;\n                tx = _4448;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_988 * tex_a) * _1021.w, 0.0f, 1.0f).xxx);\n        if (_1031.z > _1031.x)\n        {\n            float4 param_17 = _1031;\n            float2 param_18 = _996;\n            float2 param_19 = _829;\n            float2 param_20 = _1006;\n            float2 param_21 = _1016;\n            float4 _1111 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_839 > 1.5f)\n            {\n                float3 param_22 = _1111.xyz;\n                float3 _1121 = fa_dc_to_srgb(param_22);\n                _1115 = _1121;\n            }\n            else\n            {\n                _1115 = _1111.xyz;\n            }\n            float3 _1131 = (_1115 * 2.0f) - 1.0f.xxx;\n            float2 _1136 = _1131.xy * _885.y;\n            float3 _1158 = (normalize(_913) * _1136.x) + (normalize(_920) * _1136.y);\n            float3 _1161 = normalize(normal);\n            normal = normalize(lerp(_1161, normalize((_1161 * max(_1131.z, 0.0500000007450580596923828125f)) + (_1158 - (_1161 * dot(_1161, _1158)))), clamp(_988 * (_1041 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_sky_sh_coef(int k)\n{\n    float3 v = fa_env_tex.SampleLevel(fa_env_smp, float3(1.0f, 1.0f - (float((2 * (k >> 2)) + 1) * 0.25f), 1.0f - (float((2 * (k & 3)) + 1) * 0.25f)), 5.0f).xyz;\n    if (_503_fa_env_sky.w > 1.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _2378 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _2378;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_503_fa_env_sky.w > 0.5f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _503_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _2621 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _2628 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _2631 = int(_2621);\n    int _2634 = int(_2628);\n    float _2644 = _2628 - float(_2634);\n    int _2699 = (_2631 * 9) + _2634;\n    int _2719 = ((_2631 + 1) * 9) + _2634;\n    return lerp(lerp(_2695[_2699], _2695[_2699 + 1], _2644), lerp(_2695[_2719], _2695[_2719 + 1], _2644), _2621 - float(_2631));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _4251 = false;\n    float _4252 = 1.0f;\n    float _4253 = 1.0f;\n    float _4254 = 1.0f;\n    float _4255 = 0.0f;\n    float _4256 = 0.0f;\n    float _4257 = 0.0f;\n    float _4258 = 0.0f;\n    float _4260 = 1.0f;\n    bool _4261 = false;\n    float3 _4262 = 0.0f.xxx;\n    float _4263 = 1.0f;\n    float _4264 = 1.0f;\n    float _4265 = 1.0f;\n    float _4266 = 0.0f;\n    float _4267 = 0.0f;\n    float3 _4268 = float3(1.0f, 0.0f, 0.0f);\n    float3 _4269 = float3(0.0f, 0.0f, 1.0f);\n    float _4270 = 1.0f;\n    float _4271 = 1.0f;\n    float _2772 = clamp(s.specular, 0.0f, 1.0f);\n    float _2776 = clamp(s.ior, 1.0f, 3.0f);\n    bool _2781 = (_2772 != 1.0f) || (_2776 != 1.5f);\n    bool _2791;\n    if (!_2781)\n    {\n        _2791 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _2791 = _2781;\n    }\n    if (_2791)\n    {\n        float _2799 = (_2776 - 1.0f) / (_2776 + 1.0f);\n        f0 = lerp(min((_2799 * _2799).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _2772, s.albedo, metallic.xxx);\n        _4252 = lerp(_2772, 1.0f, metallic);\n        _4251 = true;\n    }\n    float _2827 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_2827 > 0.0f)\n    {\n        float _2835 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _4255 = _2827;\n        _4256 = _2835;\n        float _2842 = _2835 * _2835;\n        _4257 = _2842;\n        _4258 = _2842 * _2842;\n        float _2854 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _4260 = _2854;\n        _4253 = 1.0f - (_2827 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _2854, 0.0f, 1.0f), 5.0f))));\n        _4251 = true;\n    }\n    float3 _2873 = max(s.sheen_color, 0.0f.xxx);\n    float _2882 = max(_2873.x, max(_2873.y, _2873.z));\n    if (_2882 > 0.0f)\n    {\n        float _2890 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _4261 = true;\n        _4262 = _2873;\n        _4263 = _2890;\n        _4264 = _2890 * _2890;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _2890;\n        float _2907 = fa_sheen_albedo(param, param_1);\n        _4266 = _2907;\n        _4265 = 1.0f - min(_2882 * _2907, 1.0f);\n        _4251 = true;\n    }\n    _4254 = _4253 * _4265;\n    float _2926 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_2926 != 0.0f)\n    {\n        float3 _2941 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2941;\n        if (dot(_2941, _2941) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _2954 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_2954.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _2954.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _2954.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _2958 = t;\n        float3 _2959 = normalize(_2958);\n        t = _2959;\n        float3 _2984 = normalize((_2959 * cos(s.anisotropy_rotation)) + ((cross(n, _2959) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _4268 = _2984;\n        _4269 = cross(n, _2984);\n        float _2994 = roughness * roughness;\n        float _3000 = lerp(_2994, 1.0f, _2926 * _2926);\n        bool _3002 = _2926 > 0.0f;\n        _4270 = _3002 ? _3000 : _2994;\n        _4271 = _3002 ? _2994 : _3000;\n        _4267 = _2926;\n        _4251 = true;\n    }\n    FaLayers _4293 = { _4251, _4252, _4253, _4254, _4255, _4256, _4257, _4258, i.world_normal, _4260, _4261, _4262, _4263, _4264, _4265, _4266, _4267, _4268, _4269, _4270, _4271 };\n    return _4293;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _2553 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _2556 = _2553.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_2556 * _2556, exp2((-9.27999973297119140625f) * ndv)) * _2556) + _2553.y)) + _2553.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_503_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _503_fa_env_horizon.w).xyz;\n    }\n    float _2407 = rough * rough;\n    float _2437 = 0.60000002384185791015625f * _2407;\n    return lerp(lerp(_503_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_503_fa_env_horizon.xyz, _503_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _2407)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _2437, 0.0500000007450580596923828125f + _2437, d.y).xxx), ((_503_fa_env_sky.xyz + _503_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_2407 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _3035;\n        if (L.aniso >= 0.0f)\n        {\n            _3035 = L.b;\n        }\n        else\n        {\n            _3035 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_3035, v), _3035), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3068 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _3068.x) + (L.f90.xxx * _3068.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3123 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _3123.x) + _3123.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _2595 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _2595.x) + _2595.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _3152 = clamp(s.metallic, 0.0f, 1.0f);\n    float _3156 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _3163 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _3152.xxx);\n    float3 f0 = _3163;\n    float3 _3167 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _3167;\n    float3 param_3 = i.view_dir;\n    float param_4 = _3152;\n    float param_5 = _3156;\n    float3 param_6 = _3163;\n    FaLayers _3184 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_3184.on)\n    {\n        FaLayers param_7 = _3184;\n        float3 param_8 = _3167;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _3156;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _3167;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _3156;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_503_fa_cl_info.x) + int(_503_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _378 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _384 = fa_light_texel(param_1);\n    float _387 = _384.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _393 = _387 < 0.5f;\n    float3 l;\n    if (_393)\n    {\n        l = normalize(_378.xyz);\n    }\n    else\n    {\n        float3 _405 = _378.xyz - world_pos;\n        float _407 = length(_405);\n        dist = _407;\n        l = _405 / max(_407, 9.9999997473787516355514526367188e-05f).xxx;\n        float _422 = _407 / max(_378.w, 0.001000000047497451305389404296875f);\n        float _428 = clamp(1.0f - (_422 * _422), 0.0f, 1.0f);\n        atten = _428 * _428;\n        if (_387 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _442 = fa_light_texel(param_2);\n            float _452 = _442.w;\n            int param_3 = (li * 4) + 3;\n            float4 _458 = fa_light_texel(param_3);\n            float _459 = _458.x;\n            float cos_inner = _459;\n            if (_459 > 1.5f)\n            {\n                cos_inner = lerp(_452, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_452, cos_inner, dot(-l, normalize(_442.xyz)));\n        }\n    }\n    int _489;\n    if (_393)\n    {\n        _489 = 0;\n    }\n    else\n    {\n        _489 = (_387 > 1.5f) ? 2 : 1;\n    }\n    LightSample _4250 = { l, _384.xyz * atten, atten, 1.0f, dist, _489 };\n    return _4250;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1233;\n    if (i == 0)\n    {\n        _1233 = _1243_fa_shadow_split.x;\n    }\n    else\n    {\n        float _1249;\n        if (i == 1)\n        {\n            _1249 = _1243_fa_shadow_split.y;\n        }\n        else\n        {\n            float _1257;\n            if (i == 2)\n            {\n                _1257 = _1243_fa_shadow_split.z;\n            }\n            else\n            {\n                _1257 = _1243_fa_shadow_split.w;\n            }\n            _1249 = _1257;\n        }\n        _1233 = _1249;\n    }\n    return _1233;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1290 = fa_shadow_depth(param, param_1);\n    float _1294;\n    if (conv.x < 0.5f)\n    {\n        _1294 = _1290;\n    }\n    else\n    {\n        _1294 = (conv.y * conv.z) / (conv.z - (_1290 * (conv.z - conv.y)));\n    }\n    return _1294;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1221 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_1221), sin(_1221)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1340 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _1354 = clamp((k * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1340;\n            float2 _1373 = fa_shadow_vogel(param_3, param_4, param_5) * _1354;\n            float2 param_6 = uv + (_1373 * _1243_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1385 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1385 < (zr - (length(_1373) * plane)))\n            {\n                sum += _1385;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0f) * unit) * k) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _1429 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1429; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1429;\n        float param_11 = _1340;\n        float2 _1448 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1448 * _1243_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1448) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1429);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _1490 = max(_1243_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _1495 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1501 = sqrt(1.0f - (_1495 * _1495));\n    float _1508 = min(_1501 / max(_1495, 0.20000000298023223876953125f), 4.0f);\n    float _1513;\n    if (_1243_fa_shadow_bias.y > 0.0f)\n    {\n        _1513 = _1243_fa_shadow_bias.y;\n    }\n    else\n    {\n        _1513 = 1.5f * _1243_fa_shadow_info[ci].x;\n    }\n    float4 _1538 = mul(float4(world + (n * (_1513 * _1501)), 1.0f), _1243_fa_shadow_mat[ci]);\n    float _1545 = _1538.x;\n    bool _1548 = _1545 < _1243_fa_shadow_rect[ci].x;\n    bool _1557;\n    if (!_1548)\n    {\n        _1557 = _1545 > _1243_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1557 = _1548;\n    }\n    bool _1566;\n    if (!_1557)\n    {\n        _1566 = _1538.y < _1243_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1566 = _1557;\n    }\n    bool _1575;\n    if (!_1566)\n    {\n        _1575 = _1538.y > _1243_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1575 = _1566;\n    }\n    bool _1582;\n    if (!_1575)\n    {\n        _1582 = _1538.z > 1.0f;\n    }\n    else\n    {\n        _1582 = _1575;\n    }\n    if (_1582)\n    {\n        return -1.0f;\n    }\n    float _1591;\n    if (_1243_fa_shadow_bias.x > 0.0f)\n    {\n        _1591 = _1243_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1591 = 1.5f * _1243_fa_shadow_info[ci].x;\n    }\n    float2 param = _1538.xy;\n    float4 param_1 = _1243_fa_shadow_rect[ci];\n    float param_2 = _1538.z - ((_1591 * (1.0f + (0.5f * _1508))) / _1490);\n    float param_3 = _1243_fa_shadow_info[ci].x;\n    float param_4 = _1490;\n    float param_5 = _1490 * 0.25f;\n    float param_6 = ((_1243_fa_shadow_info[ci].x * min(_1508, 3.0f)) * 0.5f) / _1490;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_1243_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _1243_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_503_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2018 = int(_1243_fa_shadow_cfg.x + 0.5f);\n    if (_2018 < 1)\n    {\n        return 1.0f;\n    }\n    float _2033 = dot(world - _1243_fa_shadow_eye.xyz, _1243_fa_shadow_fwd.xyz);\n    int param = _2018 - 1;\n    if (_2033 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2045 = _2018 > 1;\n    bool _2052;\n    if (_2045)\n    {\n        _2052 = _2033 > _1243_fa_shadow_split.x;\n    }\n    else\n    {\n        _2052 = _2045;\n    }\n    if (_2052)\n    {\n        ci = 1;\n    }\n    bool _2056 = _2018 > 2;\n    bool _2063;\n    if (_2056)\n    {\n        _2063 = _2033 > _1243_fa_shadow_split.y;\n    }\n    else\n    {\n        _2063 = _2056;\n    }\n    if (_2063)\n    {\n        ci = 2;\n    }\n    bool _2067 = _2018 > 3;\n    bool _2074;\n    if (_2067)\n    {\n        _2074 = _2033 > _1243_fa_shadow_split.z;\n    }\n    else\n    {\n        _2074 = _2067;\n    }\n    if (_2074)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2018)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2100 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2100;\n        if (_2100 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_1243_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2125;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2125 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2125 = _1243_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2144 = _1243_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2125, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2155 = clamp((_2033 - (fa_shadow_split_at(param_7) - _2144)) / _2144, 0.0f, 1.0f);\n        if (_2155 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2018)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2176 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2176;\n                if (_2176 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2155);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _1649 = _503_fa_pbr.z < 0.5f;\n    bool _1657;\n    if (!_1649)\n    {\n        _1657 = _1243_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _1657 = _1649;\n    }\n    if (_1657)\n    {\n        return 1.0f;\n    }\n    int param = (int(_1243_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _1670 = fa_light_texel(param);\n    float _1671 = _1670.x;\n    if (_1671 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _1680 = int(_1671 + 0.5f);\n    int param_1 = _1680;\n    float4 _1684 = fa_light_texel(param_1);\n    int param_2 = _1680 + 1;\n    float4 _1689 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _1692 = _1684.y;\n    if (_1692 > 0.0f)\n    {\n        float _1709 = 1.0f - smoothstep(0.75f * _1692, _1692, length(world - _1243_fa_shadow_eye.xyz));\n        fade = _1709;\n        if (_1709 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_1684.x > 1.5f)\n    {\n        int param_3 = li * 4;\n        float3 _1728 = world - fa_light_texel(param_3).xyz;\n        float3 _1731 = abs(_1728);\n        float _1733 = _1731.x;\n        float _1735 = _1731.y;\n        bool _1736 = _1733 >= _1735;\n        bool _1744;\n        if (_1736)\n        {\n            _1744 = _1733 >= _1731.z;\n        }\n        else\n        {\n            _1744 = _1736;\n        }\n        int _1745;\n        if (_1744)\n        {\n            _1745 = (_1728.x > 0.0f) ? 0 : 1;\n        }\n        else\n        {\n            int _1758;\n            if (_1735 >= _1731.z)\n            {\n                _1758 = (_1728.y > 0.0f) ? 2 : 3;\n            }\n            else\n            {\n                _1758 = (_1728.z > 0.0f) ? 4 : 5;\n            }\n            _1745 = _1758;\n        }\n        face = _1745;\n    }\n    int _1777 = (_1680 + 2) + (face * 6);\n    int param_4 = _1777;\n    int param_5 = _1777 + 1;\n    int param_6 = _1777 + 3;\n    float4 _1791 = fa_light_texel(param_6);\n    int param_7 = _1777 + 4;\n    float4 _1796 = fa_light_texel(param_7);\n    int param_8 = _1777 + 5;\n    float4 _1801 = fa_light_texel(param_8);\n    float _1813 = _1801.x * max(dot(_1791, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _1818 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1841 = clamp(dot(n, _1791.xyz), -1.0f, 1.0f);\n    int param_9 = li * 4;\n    float _1864 = min(sqrt(1.0f - (_1841 * _1841)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1791, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _1867 = _1689.y;\n    float _1869;\n    if (_1867 > 0.0f)\n    {\n        _1869 = _1867;\n    }\n    else\n    {\n        _1869 = 1.5f * _1813;\n    }\n    float4 _1889 = float4(world + (n * (_1869 * sqrt(1.0f - (_1818 * _1818)))), 1.0f);\n    float _1893 = dot(_1791, _1889);\n    float _1896 = _1801.y;\n    if (_1893 < _1896)\n    {\n        return 1.0f;\n    }\n    float2 _1911 = float2(dot(fa_light_texel(param_4), _1889), dot(fa_light_texel(param_5), _1889)) / _1893.xx;\n    float _1913 = _1911.x;\n    bool _1916 = _1913 < _1796.x;\n    bool _1925;\n    if (!_1916)\n    {\n        _1925 = _1913 > _1796.z;\n    }\n    else\n    {\n        _1925 = _1916;\n    }\n    bool _1934;\n    if (!_1925)\n    {\n        _1934 = _1911.y < _1796.y;\n    }\n    else\n    {\n        _1934 = _1925;\n    }\n    bool _1943;\n    if (!_1934)\n    {\n        _1943 = _1911.y > _1796.w;\n    }\n    else\n    {\n        _1943 = _1934;\n    }\n    if (_1943)\n    {\n        return 1.0f;\n    }\n    float _1949 = _1689.x;\n    float _1951;\n    if (_1949 > 0.0f)\n    {\n        _1951 = _1949;\n    }\n    else\n    {\n        _1951 = 1.5f * _1813;\n    }\n    float2 param_10 = _1911;\n    float4 param_11 = _1796;\n    float param_12 = _1893 - (_1951 * (1.0f + (0.5f * _1864)));\n    float param_13 = _1813;\n    float param_14 = 1.0f;\n    float param_15 = _1801.z * 0.25f;\n    float param_16 = (_1813 * min(_1864, 3.0f)) * 0.5f;\n    float3 param_17 = float3(1.0f, _1896, _1801.z);\n    int param_18 = int(_1684.z + 0.5f);\n    float param_19 = _1684.w;\n    return lerp(1.0f, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _3257 = fa_lm.z > 0.5f;\n    bool _3263;\n    if (_3257)\n    {\n        int param = li;\n        _3263 = fa_light_baked(param);\n    }\n    else\n    {\n        _3263 = _3257;\n    }\n    if (_3263)\n    {\n        int param_1 = li;\n        LightSample _4370 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _4370;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _3285 = fa_light_sample(param_2, param_3);\n    float3 _4377 = _3285.direction;\n    float3 _4372 = _3285.color;\n    float _4379 = _3285.attenuation;\n    float _4374 = _3285.shadow;\n    int _4382 = _3285.type;\n    if ((_4382 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _4377;\n        float _3299 = fa_shadow_factor(param_4, param_5);\n        _4374 = _3299;\n        _4372 *= _3299;\n    }\n    else\n    {\n        bool _3310 = _4382 != 0;\n        bool _3316;\n        if (_3310)\n        {\n            _3316 = _4379 > 0.0f;\n        }\n        else\n        {\n            _3316 = _3310;\n        }\n        if (_3316)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _4377;\n            float _3328 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _4374 = _3328;\n            _4372 *= _3328;\n        }\n    }\n    LightSample _4389 = { _4377, _4372, _4379, _4374, _3285._distance, _4382 };\n    return _4389;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_1243_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _2200 = int(_1243_fa_shadow_cfg.x + 0.5f);\n    float _2210 = dot(world - _1243_fa_shadow_eye.xyz, _1243_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _2215 = _2200 > 0;\n    bool _2224;\n    if (_2215)\n    {\n        int param = _2200 - 1;\n        _2224 = _2210 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2224 = _2215;\n    }\n    if (_2224)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _2231 = _2200 > 1;\n        bool _2238;\n        if (_2231)\n        {\n            _2238 = _2210 > _1243_fa_shadow_split.x;\n        }\n        else\n        {\n            _2238 = _2231;\n        }\n        if (_2238)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _2244 = _2200 > 2;\n        bool _2251;\n        if (_2244)\n        {\n            _2251 = _2210 > _1243_fa_shadow_split.y;\n        }\n        else\n        {\n            _2251 = _2244;\n        }\n        if (_2251)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _2257 = _2200 > 3;\n        bool _2264;\n        if (_2257)\n        {\n            _2264 = _2210 > _1243_fa_shadow_split.z;\n        }\n        else\n        {\n            _2264 = _2257;\n        }\n        if (_2264)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _4081 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4081 = -_4081;\n    }\n    float3 _3716 = normalize(_503_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _4094 = { fa_world_pos, _4081, fa_world_tangent, fa_uv, fa_vertex_color, _3716, gl_FrontFacing };\n    SurfaceInput param_1 = _4094;\n    Surface _3724 = fa_standard_surface(param_1);\n    float3 _4120 = _3724.albedo;\n    float _4121 = _3724.alpha;\n    float3 _4122 = _3724.normal;\n    float _4123 = _3724.metallic;\n    float _4124 = _3724.roughness;\n    float _4125 = _3724.occlusion;\n    float3 _4126 = _3724.emission;\n    float _4127 = _3724.clearcoat;\n    float _4128 = _3724.clearcoat_roughness;\n    float3 _4129 = _3724.sheen_color;\n    float _4130 = _3724.sheen_roughness;\n    float _4131 = _3724.anisotropy;\n    float _4132 = _3724.anisotropy_rotation;\n    float _4133 = _3724.specular;\n    float _4134 = _3724.ior;\n    float3 _4135 = _3724.specular_color;\n    SurfaceInput _4102 = { fa_world_pos, _4081, fa_world_tangent, fa_uv, fa_vertex_color, _3716, gl_FrontFacing };\n    SurfaceInput param_2 = _4102;\n    Surface param_3 = _3724;\n    surface(param_2, param_3);\n    _4120 = param_3.albedo;\n    _4121 = param_3.alpha;\n    _4122 = param_3.normal;\n    _4123 = param_3.metallic;\n    _4124 = param_3.roughness;\n    _4125 = param_3.occlusion;\n    _4126 = param_3.emission;\n    _4127 = param_3.clearcoat;\n    _4128 = param_3.clearcoat_roughness;\n    _4129 = param_3.sheen_color;\n    _4130 = param_3.sheen_roughness;\n    _4131 = param_3.anisotropy;\n    _4132 = param_3.anisotropy_rotation;\n    _4133 = param_3.specular;\n    _4134 = param_3.ior;\n    _4135 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _4081;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4120 = param_6;\n    _4122 = param_7;\n    float3 result;\n    if (_503_fa_emissive.w > 0.5f)\n    {\n        result = _4120;\n    }\n    else\n    {\n        float3 _3762 = _4122;\n        float3 _3763 = normalize(_3762);\n        _4122 = _3763;\n        float3 param_8 = _3763;\n        SurfaceInput _4110 = { fa_world_pos, _4081, fa_world_tangent, fa_uv, fa_vertex_color, _3716, gl_FrontFacing };\n        SurfaceInput param_9 = _4110;\n        Surface _4201 = { _4120, _4121, _4122, _4123, _4124, _4125, _4126, _4127, _4128, _4129, _4130, _4131, _4132, _4133, _4134, _4135 };\n        Surface param_10 = _4201;\n        float3 param_11 = fa_indirect_diffuse(param_8);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _3782 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3782; ln++)\n        {\n            int param_12 = ln;\n            int _3795 = fa_cl_light(param_12);\n            bool _3798 = fa_lm.z > 0.5f;\n            bool _3804;\n            if (_3798)\n            {\n                int param_13 = _3795;\n                _3804 = fa_light_baked(param_13);\n            }\n            else\n            {\n                _3804 = _3798;\n            }\n            if (_3804)\n            {\n                continue;\n            }\n            int param_14 = _3795;\n            float3 param_15 = fa_world_pos;\n            float3 param_16 = _4081;\n            SurfaceInput _4118 = { fa_world_pos, _4081, fa_world_tangent, fa_uv, fa_vertex_color, _3716, gl_FrontFacing };\n            SurfaceInput param_17 = _4118;\n            Surface _4218 = { _4120, _4121, _4122, _4123, _4124, _4125, _4126, _4127, _4128, _4129, _4130, _4131, _4132, _4133, _4134, _4135 };\n            Surface param_18 = _4218;\n            LightSample param_19 = fa_light_shadowed(param_14, param_15, param_16);\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _3831 = result;\n    float3 _3832 = _3831 + _4126;\n    result = _3832;\n    float3 param_20 = _3832;\n    float3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _3841 = _503_fa_fog.w > 0.0f;\n    bool _3848;\n    if (!_3841)\n    {\n        _3848 = _503_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _3848 = _3841;\n    }\n    if (_3848)\n    {\n        float3 _3857 = fa_world_pos - _503_fa_camera_pos.xyz;\n        float _3863 = dot(_3857, _503_fa_fog_c.xyz);\n        bool _3867 = _503_fa_fog_c.w > 0.5f;\n        float _3868;\n        if (_3867)\n        {\n            _3868 = _3863;\n        }\n        else\n        {\n            _3868 = length(_3857);\n        }\n        float _3880 = _3868 - _503_fa_fog_b.x;\n        if (_3880 > 0.0f)\n        {\n            float _3889 = _503_fa_fog.w * _3880;\n            float tau = _3889 * _3889;\n            if (_503_fa_fog_b.y > 0.0f)\n            {\n                float _3905;\n                if (_3867)\n                {\n                    _3905 = fa_world_pos.y - (_503_fa_fog_c.y * _3863);\n                }\n                else\n                {\n                    _3905 = _503_fa_camera_pos.y;\n                }\n                float _3926 = lerp(_3905, fa_world_pos.y, clamp(_503_fa_fog_b.x / _3868, 0.0f, 1.0f));\n                float _3930 = fa_world_pos.y - _3926;\n                float _3935 = _3926 - _503_fa_fog_b.z;\n                float _3940 = fa_world_pos.y - _503_fa_fog_b.z;\n                bool _3943 = _3935 <= 0.0f;\n                bool _3944 = !_3943;\n                bool _3950;\n                if (_3944)\n                {\n                    _3950 = _503_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3950 = _3943;\n                }\n                float _3951;\n                if (_3950)\n                {\n                    _3951 = _503_fa_fog_b.y;\n                }\n                else\n                {\n                    _3951 = _503_fa_fog_b.y * exp(-min(_503_fa_fog_b.w * _3935, 80.0f));\n                }\n                bool _3978;\n                if (_3944)\n                {\n                    _3978 = _503_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3978 = _3943;\n                }\n                float _3979;\n                if (_3978)\n                {\n                    _3979 = _503_fa_fog_b.y * _3935;\n                }\n                else\n                {\n                    _3979 = (_503_fa_fog_b.y * (1.0f - exp(-min(_503_fa_fog_b.w * _3935, 80.0f)))) / _503_fa_fog_b.w;\n                }\n                bool _4004 = _3940 <= 0.0f;\n                bool _4011;\n                if (!_4004)\n                {\n                    _4011 = _503_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4011 = _4004;\n                }\n                float _4012;\n                if (_4011)\n                {\n                    _4012 = _503_fa_fog_b.y * _3940;\n                }\n                else\n                {\n                    _4012 = (_503_fa_fog_b.y * (1.0f - exp(-min(_503_fa_fog_b.w * _3940, 80.0f)))) / _503_fa_fog_b.w;\n                }\n                float _4039;\n                if (abs(_3930) < 0.001000000047497451305389404296875f)\n                {\n                    _4039 = _3951;\n                }\n                else\n                {\n                    _4039 = (_4012 - _3979) / _3930;\n                }\n                tau += (_3880 * max(_4039, 0.0f));\n            }\n            result = lerp(result, _503_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4121);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_503",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1243",
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
              "slot": 26,
              "stage": "fragment",
              "name": "fa_lightmap",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _2695[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _503_fa_camera_pos : packoffset(c0);\n    float4 _503_fa_ambient : packoffset(c1);\n    float4 _503_fa_base_color : packoffset(c2);\n    float4 _503_fa_emissive : packoffset(c3);\n    float4 _503_fa_model_emissive : packoffset(c4);\n    float4 _503_fa_pbr : packoffset(c5);\n    float4 _503_fa_maps : packoffset(c6);\n    float4 _503_fa_fog : packoffset(c7);\n    float4 _503_fa_fog_b : packoffset(c8);\n    float4 _503_fa_fog_c : packoffset(c9);\n    float4 _503_fa_counts : packoffset(c10);\n    float4 _503_fa_env_sky : packoffset(c11);\n    float4 _503_fa_env_horizon : packoffset(c12);\n    float4 _503_fa_time : packoffset(c13);\n    float4 _503_fa_cl_vpx : packoffset(c14);\n    float4 _503_fa_cl_vpy : packoffset(c15);\n    float4 _503_fa_cl_vpw : packoffset(c16);\n    float4 _503_fa_cl_fwd : packoffset(c17);\n    float4 _503_fa_cl_grid : packoffset(c18);\n    float4 _503_fa_cl_info : packoffset(c19);\n    float4 _503_fa_layers_a : packoffset(c20);\n    float4 _503_fa_layers_b : packoffset(c21);\n    float4 _503_fa_layers_c : packoffset(c22);\n    float4 _503_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _1243_fa_shadow_mat[4] : packoffset(c0);\n    float4 _1243_fa_shadow_rect[4] : packoffset(c16);\n    float4 _1243_fa_shadow_info[4] : packoffset(c20);\n    float4 _1243_fa_shadow_split : packoffset(c24);\n    float4 _1243_fa_shadow_cfg : packoffset(c25);\n    float4 _1243_fa_shadow_bias : packoffset(c26);\n    float4 _1243_fa_shadow_eye : packoffset(c27);\n    float4 _1243_fa_shadow_fwd : packoffset(c28);\n    float4 _1243_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_decal_tex : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t8);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _508 = _503_fa_cl_info.x < 0.0f;\n    bool _515;\n    if (!_508)\n    {\n        _515 = _503_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _515 = _508;\n    }\n    bool _523;\n    if (!_515)\n    {\n        _523 = _503_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _523 = _515;\n    }\n    bool _530;\n    if (!_523)\n    {\n        _530 = _503_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _530 = _523;\n    }\n    bool _537;\n    if (!_530)\n    {\n        _537 = _503_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _537 = _530;\n    }\n    if (_537)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _547 = float4(world_pos, 1.0f);\n    float _554 = dot(_503_fa_cl_vpw, _547);\n    if (!(_554 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _576 = float2(dot(_503_fa_cl_vpx, _547), dot(_503_fa_cl_vpy, _547)) / _554.xx;\n    int _580 = int(_503_fa_cl_grid.x);\n    int _584 = int(_503_fa_cl_grid.y);\n    int param = (int(_503_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_503_fa_cl_fwd.xyz, world_pos) + _503_fa_cl_fwd.w, _503_fa_cl_grid.w) / _503_fa_cl_grid.w) * _503_fa_cl_grid.z)), 0, int(_503_fa_cl_info.y) - 1) * _584) + clamp(int(floor(((_576.y * 0.5f) + 0.5f) * _503_fa_cl_grid.y)), 0, _584 - 1)) * _580)) + clamp(int(floor(((_576.x * 0.5f) + 0.5f) * _503_fa_cl_grid.x)), 0, _580 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _660 = fa_cluster_texel(param);\n    return int2(int(_660.x), int(_660.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_503_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3230 = fa_cluster_lookup(param);\n    fa_cl_slot = _3230.x;\n    fa_cl_local = _3230.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _3384 = fa_linear_to_srgb(param);\n        c = _3384;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _3392 = fa_srgb_to_linear(param_1);\n            c = _3392;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _268;\n    if (i.front_facing)\n    {\n        _268 = i.world_normal;\n    }\n    else\n    {\n        _268 = -i.world_normal;\n    }\n    float3 _292 = normalize(i.world_tangent.xyz - (_268 * dot(_268, i.world_tangent.xyz)));\n    float3 _319 = normalize(((_292 * m.x) + ((cross(_268, _292) * i.world_tangent.w) * m.y)) + (_268 * m.z));\n    float3 _322;\n    if (i.front_facing)\n    {\n        _322 = _319;\n    }\n    else\n    {\n        _322 = -_319;\n    }\n    return _322;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _503_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3423 = fa_tex_fix(param_2, param_3);\n    float4 _4525 = base_t;\n    _4525.x = _3423.x;\n    _4525.y = _3423.y;\n    _4525.z = _3423.z;\n    base_t = _4525;\n    float4 _3437 = (_4525 * _503_fa_base_color) * i.vertex_color;\n    float3 _4392 = i.world_normal;\n    if (_503_fa_maps.z > 0.5f)\n    {\n        float param_4 = _503_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3469 = fa_tex_fix(param_6, param_7);\n        float3 _3472 = (_3469 * 2.0f) - 1.0f.xxx;\n        float2 _3477 = _3472.xy * _503_fa_maps.x;\n        float3 _4533 = _3472;\n        _4533.x = _3477.x;\n        _4533.y = _3477.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4533;\n        _4392 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _503_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3506 = fa_tex_fix(param_12, param_13);\n    float4 _4536 = mrt;\n    _4536.x = _3506.x;\n    _4536.y = _3506.y;\n    _4536.z = _3506.z;\n    mrt = _4536;\n    float4 _3534 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _503_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _3534.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3546 = fa_tex_fix(param_16, param_17);\n    float param_18 = _503_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3576 = fa_tex_fix(param_20, param_21);\n    float _4397 = _503_fa_layers_a.x;\n    float _4398 = _503_fa_layers_a.y;\n    float _4401 = _503_fa_layers_a.z;\n    float _4400 = _503_fa_layers_b.w;\n    float _4403 = _503_fa_layers_c.x;\n    if (_503_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_503_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _4397 *= _3546.y;\n            _4398 *= _3546.z;\n            _4400 *= _3534.w;\n        }\n        if (_503_fa_layers_c.z > 1.5f)\n        {\n            _4401 *= mrt.x;\n            _4403 *= mrt.w;\n        }\n    }\n    Surface _4422 = { _3437.xyz, _3437.w, _4392, clamp(_503_fa_pbr.x * _3506.z, 0.0f, 1.0f), clamp(_503_fa_pbr.y * _3506.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_503_fa_maps.y * (_3546.x - 1.0f)), _503_fa_emissive.xyz + (_503_fa_model_emissive.xyz * _3576), _4397, _4398, _503_fa_layers_b.xyz, _4400, _4401, _503_fa_layers_a.w, _4403, _503_fa_layers_c.y, _503_fa_layers_d.xyz };\n    return _4422;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _741 = rect.zw - rect.xy;\n    float2 _745 = _741 * atlas;\n    float2 _749 = ddx * _745;\n    float2 _753 = ddy * _745;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _741), clamp(0.5f * log2(max(max(dot(_749, _749), dot(_753, _753)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _788 = _503_fa_counts.y < 0.5f;\n    bool _795;\n    if (!_788)\n    {\n        _795 = _503_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _795 = _788;\n    }\n    if (_795)\n    {\n        return;\n    }\n    float3 _801 = ddx(world_pos);\n    float3 _804 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _808 = fa_cluster_texel(param);\n    int _812 = int(_808.w);\n    if (_812 < 1)\n    {\n        return;\n    }\n    int _822 = int(_503_fa_counts.y + 0.5f);\n    int param_1 = _822;\n    float4 _826 = fa_light_texel(param_1);\n    float2 _829 = _826.yz;\n    int _833 = int(_826.w);\n    int param_2 = _822 + 1;\n    float4 _838 = fa_light_texel(param_2);\n    float _839 = _838.x;\n    int _845 = int(_503_fa_counts.w + 0.5f) - 1;\n    int _849 = int(_808.z);\n    float3 _1115;\n    for (int k = 0; k < _812; k++)\n    {\n        int _862 = _849 + k;\n        int param_3 = _833 + (_862 >> 2);\n        int _880 = (_822 + 2) + (int(fa_light_texel(param_3)[_862 & 3]) * 7);\n        int param_4 = _880 + 6;\n        float4 _885 = fa_light_texel(param_4);\n        if (((int(_885.w + 0.5f) >> _845) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _880;\n        float4 _900 = fa_light_texel(param_5);\n        int param_6 = _880 + 1;\n        float4 _905 = fa_light_texel(param_6);\n        int param_7 = _880 + 2;\n        float4 _910 = fa_light_texel(param_7);\n        float3 _913 = _900.xyz;\n        float _918 = dot(_913, world_pos) + _900.w;\n        float3 _920 = _905.xyz;\n        float _925 = dot(_920, world_pos) + _905.w;\n        float3 _927 = _910.xyz;\n        float _932 = dot(_927, world_pos) + _910.w;\n        bool _937 = abs(_918) > 0.5f;\n        bool _945;\n        if (!_937)\n        {\n            _945 = abs(_925) > 0.5f;\n        }\n        else\n        {\n            _945 = _937;\n        }\n        bool _953;\n        if (!_945)\n        {\n            _953 = abs(_932) > 0.5f;\n        }\n        else\n        {\n            _953 = _945;\n        }\n        if (_953)\n        {\n            continue;\n        }\n        float _968 = clamp(dot(geo_normal, normalize(_927)) * _885.z, 0.0f, 1.0f);\n        if (_968 <= 0.0f)\n        {\n            continue;\n        }\n        float _988 = (clamp((0.5f - abs(_932)) * 10.0f, 0.0f, 1.0f) * _968) * _885.x;\n        float2 _996 = float2(_918 + 0.5f, 0.5f - _925);\n        float2 _1006 = float2(dot(_913, _801), dot(_920, _801));\n        float2 _1016 = float2(dot(_913, _804), dot(_920, _804));\n        int param_8 = _880 + 5;\n        float4 _1021 = fa_light_texel(param_8);\n        int param_9 = _880 + 3;\n        float4 _1026 = fa_light_texel(param_9);\n        int param_10 = _880 + 4;\n        float4 _1031 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1021.xyz;\n        bool _1041 = _1026.z > _1026.x;\n        if (_1041)\n        {\n            float4 param_11 = _1026;\n            float2 param_12 = _996;\n            float2 param_13 = _829;\n            float2 param_14 = _1006;\n            float2 param_15 = _1016;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_839 > 0.5f) && (_839 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1067 = fa_dc_to_linear(param_16);\n                float4 _4448 = tx;\n                _4448.x = _1067.x;\n                _4448.y = _1067.y;\n                _4448.z = _1067.z;\n                tx = _4448;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_988 * tex_a) * _1021.w, 0.0f, 1.0f).xxx);\n        if (_1031.z > _1031.x)\n        {\n            float4 param_17 = _1031;\n            float2 param_18 = _996;\n            float2 param_19 = _829;\n            float2 param_20 = _1006;\n            float2 param_21 = _1016;\n            float4 _1111 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_839 > 1.5f)\n            {\n                float3 param_22 = _1111.xyz;\n                float3 _1121 = fa_dc_to_srgb(param_22);\n                _1115 = _1121;\n            }\n            else\n            {\n                _1115 = _1111.xyz;\n            }\n            float3 _1131 = (_1115 * 2.0f) - 1.0f.xxx;\n            float2 _1136 = _1131.xy * _885.y;\n            float3 _1158 = (normalize(_913) * _1136.x) + (normalize(_920) * _1136.y);\n            float3 _1161 = normalize(normal);\n            normal = normalize(lerp(_1161, normalize((_1161 * max(_1131.z, 0.0500000007450580596923828125f)) + (_1158 - (_1161 * dot(_1161, _1158)))), clamp(_988 * (_1041 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_sky_sh_coef(int k)\n{\n    float3 v = fa_env_tex.SampleLevel(fa_env_smp, float3(1.0f, 1.0f - (float((2 * (k >> 2)) + 1) * 0.25f), 1.0f - (float((2 * (k & 3)) + 1) * 0.25f)), 5.0f).xyz;\n    if (_503_fa_env_sky.w > 1.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _2378 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _2378;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_503_fa_env_sky.w > 0.5f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _503_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _2621 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _2628 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _2631 = int(_2621);\n    int _2634 = int(_2628);\n    float _2644 = _2628 - float(_2634);\n    int _2699 = (_2631 * 9) + _2634;\n    int _2719 = ((_2631 + 1) * 9) + _2634;\n    return lerp(lerp(_2695[_2699], _2695[_2699 + 1], _2644), lerp(_2695[_2719], _2695[_2719 + 1], _2644), _2621 - float(_2631));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _4251 = false;\n    float _4252 = 1.0f;\n    float _4253 = 1.0f;\n    float _4254 = 1.0f;\n    float _4255 = 0.0f;\n    float _4256 = 0.0f;\n    float _4257 = 0.0f;\n    float _4258 = 0.0f;\n    float _4260 = 1.0f;\n    bool _4261 = false;\n    float3 _4262 = 0.0f.xxx;\n    float _4263 = 1.0f;\n    float _4264 = 1.0f;\n    float _4265 = 1.0f;\n    float _4266 = 0.0f;\n    float _4267 = 0.0f;\n    float3 _4268 = float3(1.0f, 0.0f, 0.0f);\n    float3 _4269 = float3(0.0f, 0.0f, 1.0f);\n    float _4270 = 1.0f;\n    float _4271 = 1.0f;\n    float _2772 = clamp(s.specular, 0.0f, 1.0f);\n    float _2776 = clamp(s.ior, 1.0f, 3.0f);\n    bool _2781 = (_2772 != 1.0f) || (_2776 != 1.5f);\n    bool _2791;\n    if (!_2781)\n    {\n        _2791 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _2791 = _2781;\n    }\n    if (_2791)\n    {\n        float _2799 = (_2776 - 1.0f) / (_2776 + 1.0f);\n        f0 = lerp(min((_2799 * _2799).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _2772, s.albedo, metallic.xxx);\n        _4252 = lerp(_2772, 1.0f, metallic);\n        _4251 = true;\n    }\n    float _2827 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_2827 > 0.0f)\n    {\n        float _2835 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _4255 = _2827;\n        _4256 = _2835;\n        float _2842 = _2835 * _2835;\n        _4257 = _2842;\n        _4258 = _2842 * _2842;\n        float _2854 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _4260 = _2854;\n        _4253 = 1.0f - (_2827 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _2854, 0.0f, 1.0f), 5.0f))));\n        _4251 = true;\n    }\n    float3 _2873 = max(s.sheen_color, 0.0f.xxx);\n    float _2882 = max(_2873.x, max(_2873.y, _2873.z));\n    if (_2882 > 0.0f)\n    {\n        float _2890 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _4261 = true;\n        _4262 = _2873;\n        _4263 = _2890;\n        _4264 = _2890 * _2890;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _2890;\n        float _2907 = fa_sheen_albedo(param, param_1);\n        _4266 = _2907;\n        _4265 = 1.0f - min(_2882 * _2907, 1.0f);\n        _4251 = true;\n    }\n    _4254 = _4253 * _4265;\n    float _2926 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_2926 != 0.0f)\n    {\n        float3 _2941 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2941;\n        if (dot(_2941, _2941) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _2954 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_2954.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _2954.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _2954.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _2958 = t;\n        float3 _2959 = normalize(_2958);\n        t = _2959;\n        float3 _2984 = normalize((_2959 * cos(s.anisotropy_rotation)) + ((cross(n, _2959) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _4268 = _2984;\n        _4269 = cross(n, _2984);\n        float _2994 = roughness * roughness;\n        float _3000 = lerp(_2994, 1.0f, _2926 * _2926);\n        bool _3002 = _2926 > 0.0f;\n        _4270 = _3002 ? _3000 : _2994;\n        _4271 = _3002 ? _2994 : _3000;\n        _4267 = _2926;\n        _4251 = true;\n    }\n    FaLayers _4293 = { _4251, _4252, _4253, _4254, _4255, _4256, _4257, _4258, i.world_normal, _4260, _4261, _4262, _4263, _4264, _4265, _4266, _4267, _4268, _4269, _4270, _4271 };\n    return _4293;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _2553 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _2556 = _2553.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_2556 * _2556, exp2((-9.27999973297119140625f) * ndv)) * _2556) + _2553.y)) + _2553.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_503_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _503_fa_env_horizon.w).xyz;\n    }\n    float _2407 = rough * rough;\n    float _2437 = 0.60000002384185791015625f * _2407;\n    return lerp(lerp(_503_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_503_fa_env_horizon.xyz, _503_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _2407)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _2437, 0.0500000007450580596923828125f + _2437, d.y).xxx), ((_503_fa_env_sky.xyz + _503_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_2407 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _3035;\n        if (L.aniso >= 0.0f)\n        {\n            _3035 = L.b;\n        }\n        else\n        {\n            _3035 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_3035, v), _3035), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3068 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _3068.x) + (L.f90.xxx * _3068.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3123 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _3123.x) + _3123.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _2595 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _2595.x) + _2595.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _3152 = clamp(s.metallic, 0.0f, 1.0f);\n    float _3156 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _3163 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _3152.xxx);\n    float3 f0 = _3163;\n    float3 _3167 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _3167;\n    float3 param_3 = i.view_dir;\n    float param_4 = _3152;\n    float param_5 = _3156;\n    float3 param_6 = _3163;\n    FaLayers _3184 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_3184.on)\n    {\n        FaLayers param_7 = _3184;\n        float3 param_8 = _3167;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _3156;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _3167;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _3156;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_503_fa_cl_info.x) + int(_503_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _378 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _384 = fa_light_texel(param_1);\n    float _387 = _384.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _393 = _387 < 0.5f;\n    float3 l;\n    if (_393)\n    {\n        l = normalize(_378.xyz);\n    }\n    else\n    {\n        float3 _405 = _378.xyz - world_pos;\n        float _407 = length(_405);\n        dist = _407;\n        l = _405 / max(_407, 9.9999997473787516355514526367188e-05f).xxx;\n        float _422 = _407 / max(_378.w, 0.001000000047497451305389404296875f);\n        float _428 = clamp(1.0f - (_422 * _422), 0.0f, 1.0f);\n        atten = _428 * _428;\n        if (_387 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _442 = fa_light_texel(param_2);\n            float _452 = _442.w;\n            int param_3 = (li * 4) + 3;\n            float4 _458 = fa_light_texel(param_3);\n            float _459 = _458.x;\n            float cos_inner = _459;\n            if (_459 > 1.5f)\n            {\n                cos_inner = lerp(_452, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_452, cos_inner, dot(-l, normalize(_442.xyz)));\n        }\n    }\n    int _489;\n    if (_393)\n    {\n        _489 = 0;\n    }\n    else\n    {\n        _489 = (_387 > 1.5f) ? 2 : 1;\n    }\n    LightSample _4250 = { l, _384.xyz * atten, atten, 1.0f, dist, _489 };\n    return _4250;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1233;\n    if (i == 0)\n    {\n        _1233 = _1243_fa_shadow_split.x;\n    }\n    else\n    {\n        float _1249;\n        if (i == 1)\n        {\n            _1249 = _1243_fa_shadow_split.y;\n        }\n        else\n        {\n            float _1257;\n            if (i == 2)\n            {\n                _1257 = _1243_fa_shadow_split.z;\n            }\n            else\n            {\n                _1257 = _1243_fa_shadow_split.w;\n            }\n            _1249 = _1257;\n        }\n        _1233 = _1249;\n    }\n    return _1233;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1290 = fa_shadow_depth(param, param_1);\n    float _1294;\n    if (conv.x < 0.5f)\n    {\n        _1294 = _1290;\n    }\n    else\n    {\n        _1294 = (conv.y * conv.z) / (conv.z - (_1290 * (conv.z - conv.y)));\n    }\n    return _1294;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1221 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_1221), sin(_1221)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1340 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _1354 = clamp((k * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1340;\n            float2 _1373 = fa_shadow_vogel(param_3, param_4, param_5) * _1354;\n            float2 param_6 = uv + (_1373 * _1243_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1385 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1385 < (zr - (length(_1373) * plane)))\n            {\n                sum += _1385;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0f) * unit) * k) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _1429 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1429; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1429;\n        float param_11 = _1340;\n        float2 _1448 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1448 * _1243_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1448) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1429);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _1490 = max(_1243_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _1495 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1501 = sqrt(1.0f - (_1495 * _1495));\n    float _1508 = min(_1501 / max(_1495, 0.20000000298023223876953125f), 4.0f);\n    float _1513;\n    if (_1243_fa_shadow_bias.y > 0.0f)\n    {\n        _1513 = _1243_fa_shadow_bias.y;\n    }\n    else\n    {\n        _1513 = 1.5f * _1243_fa_shadow_info[ci].x;\n    }\n    float4 _1538 = mul(float4(world + (n * (_1513 * _1501)), 1.0f), _1243_fa_shadow_mat[ci]);\n    float _1545 = _1538.x;\n    bool _1548 = _1545 < _1243_fa_shadow_rect[ci].x;\n    bool _1557;\n    if (!_1548)\n    {\n        _1557 = _1545 > _1243_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1557 = _1548;\n    }\n    bool _1566;\n    if (!_1557)\n    {\n        _1566 = _1538.y < _1243_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1566 = _1557;\n    }\n    bool _1575;\n    if (!_1566)\n    {\n        _1575 = _1538.y > _1243_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1575 = _1566;\n    }\n    bool _1582;\n    if (!_1575)\n    {\n        _1582 = _1538.z > 1.0f;\n    }\n    else\n    {\n        _1582 = _1575;\n    }\n    if (_1582)\n    {\n        return -1.0f;\n    }\n    float _1591;\n    if (_1243_fa_shadow_bias.x > 0.0f)\n    {\n        _1591 = _1243_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1591 = 1.5f * _1243_fa_shadow_info[ci].x;\n    }\n    float2 param = _1538.xy;\n    float4 param_1 = _1243_fa_shadow_rect[ci];\n    float param_2 = _1538.z - ((_1591 * (1.0f + (0.5f * _1508))) / _1490);\n    float param_3 = _1243_fa_shadow_info[ci].x;\n    float param_4 = _1490;\n    float param_5 = _1490 * 0.25f;\n    float param_6 = ((_1243_fa_shadow_info[ci].x * min(_1508, 3.0f)) * 0.5f) / _1490;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_1243_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _1243_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_503_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2018 = int(_1243_fa_shadow_cfg.x + 0.5f);\n    if (_2018 < 1)\n    {\n        return 1.0f;\n    }\n    float _2033 = dot(world - _1243_fa_shadow_eye.xyz, _1243_fa_shadow_fwd.xyz);\n    int param = _2018 - 1;\n    if (_2033 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2045 = _2018 > 1;\n    bool _2052;\n    if (_2045)\n    {\n        _2052 = _2033 > _1243_fa_shadow_split.x;\n    }\n    else\n    {\n        _2052 = _2045;\n    }\n    if (_2052)\n    {\n        ci = 1;\n    }\n    bool _2056 = _2018 > 2;\n    bool _2063;\n    if (_2056)\n    {\n        _2063 = _2033 > _1243_fa_shadow_split.y;\n    }\n    else\n    {\n        _2063 = _2056;\n    }\n    if (_2063)\n    {\n        ci = 2;\n    }\n    bool _2067 = _2018 > 3;\n    bool _2074;\n    if (_2067)\n    {\n        _2074 = _2033 > _1243_fa_shadow_split.z;\n    }\n    else\n    {\n        _2074 = _2067;\n    }\n    if (_2074)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2018)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2100 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2100;\n        if (_2100 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_1243_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2125;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2125 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2125 = _1243_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2144 = _1243_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2125, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2155 = clamp((_2033 - (fa_shadow_split_at(param_7) - _2144)) / _2144, 0.0f, 1.0f);\n        if (_2155 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2018)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2176 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2176;\n                if (_2176 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2155);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _1649 = _503_fa_pbr.z < 0.5f;\n    bool _1657;\n    if (!_1649)\n    {\n        _1657 = _1243_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _1657 = _1649;\n    }\n    if (_1657)\n    {\n        return 1.0f;\n    }\n    int param = (int(_1243_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _1670 = fa_light_texel(param);\n    float _1671 = _1670.x;\n    if (_1671 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _1680 = int(_1671 + 0.5f);\n    int param_1 = _1680;\n    float4 _1684 = fa_light_texel(param_1);\n    int param_2 = _1680 + 1;\n    float4 _1689 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _1692 = _1684.y;\n    if (_1692 > 0.0f)\n    {\n        float _1709 = 1.0f - smoothstep(0.75f * _1692, _1692, length(world - _1243_fa_shadow_eye.xyz));\n        fade = _1709;\n        if (_1709 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_1684.x > 1.5f)\n    {\n        int param_3 = li * 4;\n        float3 _1728 = world - fa_light_texel(param_3).xyz;\n        float3 _1731 = abs(_1728);\n        float _1733 = _1731.x;\n        float _1735 = _1731.y;\n        bool _1736 = _1733 >= _1735;\n        bool _1744;\n        if (_1736)\n        {\n            _1744 = _1733 >= _1731.z;\n        }\n        else\n        {\n            _1744 = _1736;\n        }\n        int _1745;\n        if (_1744)\n        {\n            _1745 = (_1728.x > 0.0f) ? 0 : 1;\n        }\n        else\n        {\n            int _1758;\n            if (_1735 >= _1731.z)\n            {\n                _1758 = (_1728.y > 0.0f) ? 2 : 3;\n            }\n            else\n            {\n                _1758 = (_1728.z > 0.0f) ? 4 : 5;\n            }\n            _1745 = _1758;\n        }\n        face = _1745;\n    }\n    int _1777 = (_1680 + 2) + (face * 6);\n    int param_4 = _1777;\n    int param_5 = _1777 + 1;\n    int param_6 = _1777 + 3;\n    float4 _1791 = fa_light_texel(param_6);\n    int param_7 = _1777 + 4;\n    float4 _1796 = fa_light_texel(param_7);\n    int param_8 = _1777 + 5;\n    float4 _1801 = fa_light_texel(param_8);\n    float _1813 = _1801.x * max(dot(_1791, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _1818 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1841 = clamp(dot(n, _1791.xyz), -1.0f, 1.0f);\n    int param_9 = li * 4;\n    float _1864 = min(sqrt(1.0f - (_1841 * _1841)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1791, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _1867 = _1689.y;\n    float _1869;\n    if (_1867 > 0.0f)\n    {\n        _1869 = _1867;\n    }\n    else\n    {\n        _1869 = 1.5f * _1813;\n    }\n    float4 _1889 = float4(world + (n * (_1869 * sqrt(1.0f - (_1818 * _1818)))), 1.0f);\n    float _1893 = dot(_1791, _1889);\n    float _1896 = _1801.y;\n    if (_1893 < _1896)\n    {\n        return 1.0f;\n    }\n    float2 _1911 = float2(dot(fa_light_texel(param_4), _1889), dot(fa_light_texel(param_5), _1889)) / _1893.xx;\n    float _1913 = _1911.x;\n    bool _1916 = _1913 < _1796.x;\n    bool _1925;\n    if (!_1916)\n    {\n        _1925 = _1913 > _1796.z;\n    }\n    else\n    {\n        _1925 = _1916;\n    }\n    bool _1934;\n    if (!_1925)\n    {\n        _1934 = _1911.y < _1796.y;\n    }\n    else\n    {\n        _1934 = _1925;\n    }\n    bool _1943;\n    if (!_1934)\n    {\n        _1943 = _1911.y > _1796.w;\n    }\n    else\n    {\n        _1943 = _1934;\n    }\n    if (_1943)\n    {\n        return 1.0f;\n    }\n    float _1949 = _1689.x;\n    float _1951;\n    if (_1949 > 0.0f)\n    {\n        _1951 = _1949;\n    }\n    else\n    {\n        _1951 = 1.5f * _1813;\n    }\n    float2 param_10 = _1911;\n    float4 param_11 = _1796;\n    float param_12 = _1893 - (_1951 * (1.0f + (0.5f * _1864)));\n    float param_13 = _1813;\n    float param_14 = 1.0f;\n    float param_15 = _1801.z * 0.25f;\n    float param_16 = (_1813 * min(_1864, 3.0f)) * 0.5f;\n    float3 param_17 = float3(1.0f, _1896, _1801.z);\n    int param_18 = int(_1684.z + 0.5f);\n    float param_19 = _1684.w;\n    return lerp(1.0f, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _3257 = fa_lm.z > 0.5f;\n    bool _3263;\n    if (_3257)\n    {\n        int param = li;\n        _3263 = fa_light_baked(param);\n    }\n    else\n    {\n        _3263 = _3257;\n    }\n    if (_3263)\n    {\n        int param_1 = li;\n        LightSample _4370 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _4370;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _3285 = fa_light_sample(param_2, param_3);\n    float3 _4377 = _3285.direction;\n    float3 _4372 = _3285.color;\n    float _4379 = _3285.attenuation;\n    float _4374 = _3285.shadow;\n    int _4382 = _3285.type;\n    if ((_4382 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _4377;\n        float _3299 = fa_shadow_factor(param_4, param_5);\n        _4374 = _3299;\n        _4372 *= _3299;\n    }\n    else\n    {\n        bool _3310 = _4382 != 0;\n        bool _3316;\n        if (_3310)\n        {\n            _3316 = _4379 > 0.0f;\n        }\n        else\n        {\n            _3316 = _3310;\n        }\n        if (_3316)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _4377;\n            float _3328 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _4374 = _3328;\n            _4372 *= _3328;\n        }\n    }\n    LightSample _4389 = { _4377, _4372, _4379, _4374, _3285._distance, _4382 };\n    return _4389;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_1243_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _2200 = int(_1243_fa_shadow_cfg.x + 0.5f);\n    float _2210 = dot(world - _1243_fa_shadow_eye.xyz, _1243_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _2215 = _2200 > 0;\n    bool _2224;\n    if (_2215)\n    {\n        int param = _2200 - 1;\n        _2224 = _2210 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2224 = _2215;\n    }\n    if (_2224)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _2231 = _2200 > 1;\n        bool _2238;\n        if (_2231)\n        {\n            _2238 = _2210 > _1243_fa_shadow_split.x;\n        }\n        else\n        {\n            _2238 = _2231;\n        }\n        if (_2238)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _2244 = _2200 > 2;\n        bool _2251;\n        if (_2244)\n        {\n            _2251 = _2210 > _1243_fa_shadow_split.y;\n        }\n        else\n        {\n            _2251 = _2244;\n        }\n        if (_2251)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _2257 = _2200 > 3;\n        bool _2264;\n        if (_2257)\n        {\n            _2264 = _2210 > _1243_fa_shadow_split.z;\n        }\n        else\n        {\n            _2264 = _2257;\n        }\n        if (_2264)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _4081 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4081 = -_4081;\n    }\n    float3 _3716 = normalize(_503_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _4094 = { fa_world_pos, _4081, fa_world_tangent, fa_uv, fa_vertex_color, _3716, gl_FrontFacing };\n    SurfaceInput param_1 = _4094;\n    Surface _3724 = fa_standard_surface(param_1);\n    float3 _4120 = _3724.albedo;\n    float _4121 = _3724.alpha;\n    float3 _4122 = _3724.normal;\n    float _4123 = _3724.metallic;\n    float _4124 = _3724.roughness;\n    float _4125 = _3724.occlusion;\n    float3 _4126 = _3724.emission;\n    float _4127 = _3724.clearcoat;\n    float _4128 = _3724.clearcoat_roughness;\n    float3 _4129 = _3724.sheen_color;\n    float _4130 = _3724.sheen_roughness;\n    float _4131 = _3724.anisotropy;\n    float _4132 = _3724.anisotropy_rotation;\n    float _4133 = _3724.specular;\n    float _4134 = _3724.ior;\n    float3 _4135 = _3724.specular_color;\n    SurfaceInput _4102 = { fa_world_pos, _4081, fa_world_tangent, fa_uv, fa_vertex_color, _3716, gl_FrontFacing };\n    SurfaceInput param_2 = _4102;\n    Surface param_3 = _3724;\n    surface(param_2, param_3);\n    _4120 = param_3.albedo;\n    _4121 = param_3.alpha;\n    _4122 = param_3.normal;\n    _4123 = param_3.metallic;\n    _4124 = param_3.roughness;\n    _4125 = param_3.occlusion;\n    _4126 = param_3.emission;\n    _4127 = param_3.clearcoat;\n    _4128 = param_3.clearcoat_roughness;\n    _4129 = param_3.sheen_color;\n    _4130 = param_3.sheen_roughness;\n    _4131 = param_3.anisotropy;\n    _4132 = param_3.anisotropy_rotation;\n    _4133 = param_3.specular;\n    _4134 = param_3.ior;\n    _4135 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _4081;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4120 = param_6;\n    _4122 = param_7;\n    float3 result;\n    if (_503_fa_emissive.w > 0.5f)\n    {\n        result = _4120;\n    }\n    else\n    {\n        float3 _3762 = _4122;\n        float3 _3763 = normalize(_3762);\n        _4122 = _3763;\n        float3 param_8 = _3763;\n        SurfaceInput _4110 = { fa_world_pos, _4081, fa_world_tangent, fa_uv, fa_vertex_color, _3716, gl_FrontFacing };\n        SurfaceInput param_9 = _4110;\n        Surface _4201 = { _4120, _4121, _4122, _4123, _4124, _4125, _4126, _4127, _4128, _4129, _4130, _4131, _4132, _4133, _4134, _4135 };\n        Surface param_10 = _4201;\n        float3 param_11 = fa_indirect_diffuse(param_8);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _3782 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3782; ln++)\n        {\n            int param_12 = ln;\n            int _3795 = fa_cl_light(param_12);\n            bool _3798 = fa_lm.z > 0.5f;\n            bool _3804;\n            if (_3798)\n            {\n                int param_13 = _3795;\n                _3804 = fa_light_baked(param_13);\n            }\n            else\n            {\n                _3804 = _3798;\n            }\n            if (_3804)\n            {\n                continue;\n            }\n            int param_14 = _3795;\n            float3 param_15 = fa_world_pos;\n            float3 param_16 = _4081;\n            SurfaceInput _4118 = { fa_world_pos, _4081, fa_world_tangent, fa_uv, fa_vertex_color, _3716, gl_FrontFacing };\n            SurfaceInput param_17 = _4118;\n            Surface _4218 = { _4120, _4121, _4122, _4123, _4124, _4125, _4126, _4127, _4128, _4129, _4130, _4131, _4132, _4133, _4134, _4135 };\n            Surface param_18 = _4218;\n            LightSample param_19 = fa_light_shadowed(param_14, param_15, param_16);\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _3831 = result;\n    float3 _3832 = _3831 + _4126;\n    result = _3832;\n    float3 param_20 = _3832;\n    float3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _3841 = _503_fa_fog.w > 0.0f;\n    bool _3848;\n    if (!_3841)\n    {\n        _3848 = _503_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _3848 = _3841;\n    }\n    if (_3848)\n    {\n        float3 _3857 = fa_world_pos - _503_fa_camera_pos.xyz;\n        float _3863 = dot(_3857, _503_fa_fog_c.xyz);\n        bool _3867 = _503_fa_fog_c.w > 0.5f;\n        float _3868;\n        if (_3867)\n        {\n            _3868 = _3863;\n        }\n        else\n        {\n            _3868 = length(_3857);\n        }\n        float _3880 = _3868 - _503_fa_fog_b.x;\n        if (_3880 > 0.0f)\n        {\n            float _3889 = _503_fa_fog.w * _3880;\n            float tau = _3889 * _3889;\n            if (_503_fa_fog_b.y > 0.0f)\n            {\n                float _3905;\n                if (_3867)\n                {\n                    _3905 = fa_world_pos.y - (_503_fa_fog_c.y * _3863);\n                }\n                else\n                {\n                    _3905 = _503_fa_camera_pos.y;\n                }\n                float _3926 = lerp(_3905, fa_world_pos.y, clamp(_503_fa_fog_b.x / _3868, 0.0f, 1.0f));\n                float _3930 = fa_world_pos.y - _3926;\n                float _3935 = _3926 - _503_fa_fog_b.z;\n                float _3940 = fa_world_pos.y - _503_fa_fog_b.z;\n                bool _3943 = _3935 <= 0.0f;\n                bool _3944 = !_3943;\n                bool _3950;\n                if (_3944)\n                {\n                    _3950 = _503_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3950 = _3943;\n                }\n                float _3951;\n                if (_3950)\n                {\n                    _3951 = _503_fa_fog_b.y;\n                }\n                else\n                {\n                    _3951 = _503_fa_fog_b.y * exp(-min(_503_fa_fog_b.w * _3935, 80.0f));\n                }\n                bool _3978;\n                if (_3944)\n                {\n                    _3978 = _503_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3978 = _3943;\n                }\n                float _3979;\n                if (_3978)\n                {\n                    _3979 = _503_fa_fog_b.y * _3935;\n                }\n                else\n                {\n                    _3979 = (_503_fa_fog_b.y * (1.0f - exp(-min(_503_fa_fog_b.w * _3935, 80.0f)))) / _503_fa_fog_b.w;\n                }\n                bool _4004 = _3940 <= 0.0f;\n                bool _4011;\n                if (!_4004)\n                {\n                    _4011 = _503_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4011 = _4004;\n                }\n                float _4012;\n                if (_4011)\n                {\n                    _4012 = _503_fa_fog_b.y * _3940;\n                }\n                else\n                {\n                    _4012 = (_503_fa_fog_b.y * (1.0f - exp(-min(_503_fa_fog_b.w * _3940, 80.0f)))) / _503_fa_fog_b.w;\n                }\n                float _4039;\n                if (abs(_3930) < 0.001000000047497451305389404296875f)\n                {\n                    _4039 = _3951;\n                }\n                else\n                {\n                    _4039 = (_4012 - _3979) / _3930;\n                }\n                tau += (_3880 * max(_4039, 0.0f));\n            }\n            result = lerp(result, _503_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4121);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_503",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1243",
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
              "slot": 26,
              "stage": "fragment",
              "name": "fa_lightmap",
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
