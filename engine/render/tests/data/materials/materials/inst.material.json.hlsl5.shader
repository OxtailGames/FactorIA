{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "b9137a7fd5249b4222bedebb6ca5e740fb7c4a348474dd42da5706fae9a2d4c0",
  "slang": "hlsl5",
  "params": [
    "boost"
  ],
  "textures": [],
  "instanced": [
    {
      "name": "raise",
      "vec4": 0,
      "offset": 0,
      "components": 1
    },
    {
      "name": "tint",
      "vec4": 1,
      "offset": 0,
      "components": 4
    }
  ],
  "instanceVec4": 2,
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _153_fa_view_proj : packoffset(c0);\n    row_major float4x4 _153_fa_light_vp : packoffset(c4);\n    float4 _153_fa_uv_scale : packoffset(c8);\n    float4 _153_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_d0;\nstatic float4 fa_inst_d1;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_inst_d0 : TEXCOORD9;\n    float4 fa_inst_d1 : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float raise;\nstatic float4 tint;\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _100 = (dot(model[0].xyz, _94) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _300 = { mul(float4(position, 1.0f), model).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _100, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _100), texcoord0 * _153_fa_uv_scale.xy, color, position };\n    return _300;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _153_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_d0 = stage_input.fa_inst_d0;\n    fa_inst_d1 = stage_input.fa_inst_d1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_inst_v0 = fa_inst_v0;\n    stage_output.fa_inst_v1 = fa_inst_v1;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _1595[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _465_fa_camera_pos : packoffset(c0);\n    float4 _465_fa_ambient : packoffset(c1);\n    float4 _465_fa_base_color : packoffset(c2);\n    float4 _465_fa_emissive : packoffset(c3);\n    float4 _465_fa_model_emissive : packoffset(c4);\n    float4 _465_fa_pbr : packoffset(c5);\n    float4 _465_fa_maps : packoffset(c6);\n    float4 _465_fa_fog : packoffset(c7);\n    float4 _465_fa_fog_b : packoffset(c8);\n    float4 _465_fa_fog_c : packoffset(c9);\n    float4 _465_fa_counts : packoffset(c10);\n    float4 _465_fa_env_sky : packoffset(c11);\n    float4 _465_fa_env_horizon : packoffset(c12);\n    float4 _465_fa_time : packoffset(c13);\n    float4 _465_fa_cl_vpx : packoffset(c14);\n    float4 _465_fa_cl_vpy : packoffset(c15);\n    float4 _465_fa_cl_vpw : packoffset(c16);\n    float4 _465_fa_cl_fwd : packoffset(c17);\n    float4 _465_fa_cl_grid : packoffset(c18);\n    float4 _465_fa_cl_info : packoffset(c19);\n    float4 _465_fa_layers_a : packoffset(c20);\n    float4 _465_fa_layers_b : packoffset(c21);\n    float4 _465_fa_layers_c : packoffset(c22);\n    float4 _465_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _701_fa_shadow_mat[4] : packoffset(c0);\n    float4 _701_fa_shadow_rect[4] : packoffset(c16);\n    float4 _701_fa_shadow_info[4] : packoffset(c20);\n    float4 _701_fa_shadow_split : packoffset(c24);\n    float4 _701_fa_shadow_cfg : packoffset(c25);\n    float4 _701_fa_shadow_bias : packoffset(c26);\n    float4 _701_fa_shadow_eye : packoffset(c27);\n    float4 _701_fa_shadow_fwd : packoffset(c28);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _2481_boost : packoffset(c0);\n    float _2481_fa_pad0 : packoffset(c0.y);\n    float _2481_fa_pad1 : packoffset(c0.z);\n    float _2481_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\nstatic float raise;\nstatic float4 tint;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _470 = _465_fa_cl_info.x < 0.0f;\n    bool _477;\n    if (!_470)\n    {\n        _477 = _465_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _477 = _470;\n    }\n    bool _485;\n    if (!_477)\n    {\n        _485 = _465_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _485 = _477;\n    }\n    bool _492;\n    if (!_485)\n    {\n        _492 = _465_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _492 = _485;\n    }\n    bool _499;\n    if (!_492)\n    {\n        _499 = _465_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _499 = _492;\n    }\n    if (_499)\n    {\n        return int2(0, 0);\n    }\n    float4 _509 = float4(world_pos, 1.0f);\n    float _516 = dot(_465_fa_cl_vpw, _509);\n    if (!(_516 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _538 = float2(dot(_465_fa_cl_vpx, _509), dot(_465_fa_cl_vpy, _509)) / _516.xx;\n    int _542 = int(_465_fa_cl_grid.x);\n    int _546 = int(_465_fa_cl_grid.y);\n    int param = (int(_465_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_465_fa_cl_fwd.xyz, world_pos) + _465_fa_cl_fwd.w, _465_fa_cl_grid.w) / _465_fa_cl_grid.w) * _465_fa_cl_grid.z)), 0, int(_465_fa_cl_info.y) - 1) * _546) + clamp(int(floor(((_538.y * 0.5f) + 0.5f) * _465_fa_cl_grid.y)), 0, _546 - 1)) * _542)) + clamp(int(floor(((_538.x * 0.5f) + 0.5f) * _465_fa_cl_grid.x)), 0, _542 - 1);\n    float4 _617 = fa_light_texel(param);\n    return int2(int(_617.x), int(_617.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_465_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2414 = fa_cluster_lookup(param);\n    fa_cl_slot = _2414.x;\n    fa_cl_local = _2414.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _2545 = fa_linear_to_srgb(param);\n        c = _2545;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _2553 = fa_srgb_to_linear(param_1);\n            c = _2553;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _237;\n    if (i.front_facing)\n    {\n        _237 = i.world_normal;\n    }\n    else\n    {\n        _237 = -i.world_normal;\n    }\n    float3 _261 = normalize(i.world_tangent.xyz - (_237 * dot(_237, i.world_tangent.xyz)));\n    float3 _289 = normalize(((_261 * m.x) + ((cross(_237, _261) * i.world_tangent.w) * m.y)) + (_237 * m.z));\n    float3 _292;\n    if (i.front_facing)\n    {\n        _292 = _289;\n    }\n    else\n    {\n        _292 = -_289;\n    }\n    return _292;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _465_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2584 = fa_tex_fix(param_2, param_3);\n    float4 _3755 = base_t;\n    _3755.x = _2584.x;\n    _3755.y = _2584.y;\n    _3755.z = _2584.z;\n    base_t = _3755;\n    float4 _2598 = (_3755 * _465_fa_base_color) * i.vertex_color;\n    float3 _3689 = i.world_normal;\n    if (_465_fa_maps.z > 0.5f)\n    {\n        float param_4 = _465_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2630 = fa_tex_fix(param_6, param_7);\n        float3 _2633 = (_2630 * 2.0f) - 1.0f.xxx;\n        float2 _2638 = _2633.xy * _465_fa_maps.x;\n        float3 _3763 = _2633;\n        _3763.x = _2638.x;\n        _3763.y = _2638.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3763;\n        _3689 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _465_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2667 = fa_tex_fix(param_12, param_13);\n    float4 _3766 = mrt;\n    _3766.x = _2667.x;\n    _3766.y = _2667.y;\n    _3766.z = _2667.z;\n    mrt = _3766;\n    float4 _2695 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _465_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _2695.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2707 = fa_tex_fix(param_16, param_17);\n    float param_18 = _465_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2737 = fa_tex_fix(param_20, param_21);\n    float _3694 = _465_fa_layers_a.x;\n    float _3695 = _465_fa_layers_a.y;\n    float _3698 = _465_fa_layers_a.z;\n    float _3697 = _465_fa_layers_b.w;\n    float _3700 = _465_fa_layers_c.x;\n    if (_465_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_465_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _3694 *= _2707.y;\n            _3695 *= _2707.z;\n            _3697 *= _2695.w;\n        }\n        if (_465_fa_layers_c.z > 1.5f)\n        {\n            _3698 *= mrt.x;\n            _3700 *= mrt.w;\n        }\n    }\n    Surface _3719 = { _2598.xyz, _2598.w, _3689, clamp(_465_fa_pbr.x * _2667.z, 0.0f, 1.0f), clamp(_465_fa_pbr.y * _2667.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_465_fa_maps.y * (_2707.x - 1.0f)), _465_fa_emissive.xyz + (_465_fa_model_emissive.xyz * _2737), _3694, _3695, _465_fa_layers_b.xyz, _3697, _3698, _465_fa_layers_a.w, _3700, _465_fa_layers_c.y, _465_fa_layers_d.xyz };\n    return _3719;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * _2481_boost);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1520 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _1528 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _1531 = int(_1520);\n    int _1534 = int(_1528);\n    float _1544 = _1528 - float(_1534);\n    int _1600 = (_1531 * 9) + _1534;\n    int _1620 = ((_1531 + 1) * 9) + _1534;\n    return lerp(lerp(_1595[_1600], _1595[_1600 + 1], _1544), lerp(_1595[_1620], _1595[_1620 + 1], _1544), _1520 - float(_1531));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _3625 = false;\n    float _3626 = 1.0f;\n    float _3627 = 1.0f;\n    float _3628 = 1.0f;\n    float _3629 = 0.0f;\n    float _3630 = 0.0f;\n    float _3631 = 0.0f;\n    float _3632 = 0.0f;\n    float _3634 = 1.0f;\n    bool _3635 = false;\n    float3 _3636 = 0.0f.xxx;\n    float _3637 = 1.0f;\n    float _3638 = 1.0f;\n    float _3639 = 1.0f;\n    float _3640 = 0.0f;\n    float _3641 = 0.0f;\n    float3 _3642 = float3(1.0f, 0.0f, 0.0f);\n    float3 _3643 = float3(0.0f, 0.0f, 1.0f);\n    float _3644 = 1.0f;\n    float _3645 = 1.0f;\n    float _1675 = clamp(s.specular, 0.0f, 1.0f);\n    float _1679 = clamp(s.ior, 1.0f, 3.0f);\n    bool _1684 = (_1675 != 1.0f) || (_1679 != 1.5f);\n    bool _1694;\n    if (!_1684)\n    {\n        _1694 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _1694 = _1684;\n    }\n    if (_1694)\n    {\n        float _1702 = (_1679 - 1.0f) / (_1679 + 1.0f);\n        f0 = lerp(min((_1702 * _1702).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _1675, s.albedo, metallic.xxx);\n        _3626 = lerp(_1675, 1.0f, metallic);\n        _3625 = true;\n    }\n    float _1730 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_1730 > 0.0f)\n    {\n        float _1738 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _3629 = _1730;\n        _3630 = _1738;\n        float _1745 = _1738 * _1738;\n        _3631 = _1745;\n        _3632 = _1745 * _1745;\n        float _1757 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _3634 = _1757;\n        _3627 = 1.0f - (_1730 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _1757, 0.0f, 1.0f), 5.0f))));\n        _3625 = true;\n    }\n    float3 _1777 = max(s.sheen_color, 0.0f.xxx);\n    float _1786 = max(_1777.x, max(_1777.y, _1777.z));\n    if (_1786 > 0.0f)\n    {\n        float _1794 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _3635 = true;\n        _3636 = _1777;\n        _3637 = _1794;\n        _3638 = _1794 * _1794;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _1794;\n        float _1811 = fa_sheen_albedo(param, param_1);\n        _3640 = _1811;\n        _3639 = 1.0f - min(_1786 * _1811, 1.0f);\n        _3625 = true;\n    }\n    _3628 = _3627 * _3639;\n    float _1830 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_1830 != 0.0f)\n    {\n        float3 _1845 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _1845;\n        if (dot(_1845, _1845) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _1859 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_1859.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _1859.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _1859.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _1863 = t;\n        float3 _1864 = normalize(_1863);\n        t = _1864;\n        float3 _1889 = normalize((_1864 * cos(s.anisotropy_rotation)) + ((cross(n, _1864) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _3642 = _1889;\n        _3643 = cross(n, _1889);\n        float _1899 = roughness * roughness;\n        float _1905 = lerp(_1899, 1.0f, _1830 * _1830);\n        bool _1907 = _1830 > 0.0f;\n        _3644 = _1907 ? _1905 : _1899;\n        _3645 = _1907 ? _1899 : _1905;\n        _3641 = _1830;\n        _3625 = true;\n    }\n    FaLayers _3667 = { _3625, _3626, _3627, _3628, _3629, _3630, _3631, _3632, i.world_normal, _3634, _3635, _3636, _3637, _3638, _3639, _3640, _3641, _3642, _3643, _3644, _3645 };\n    return _3667;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_465_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _465_fa_ambient.xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_465_fa_cl_info.x) + int(_465_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _337 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _343 = fa_light_texel(param_1);\n    float _346 = _343.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _353 = _346 < 0.5f;\n    float3 l;\n    if (_353)\n    {\n        l = normalize(_337.xyz);\n    }\n    else\n    {\n        float3 _365 = _337.xyz - world_pos;\n        float _367 = length(_365);\n        dist = _367;\n        l = _365 / max(_367, 9.9999997473787516355514526367188e-05f).xxx;\n        float _382 = _367 / max(_337.w, 0.001000000047497451305389404296875f);\n        float _388 = clamp(1.0f - (_382 * _382), 0.0f, 1.0f);\n        atten = _388 * _388;\n        if (_346 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _402 = fa_light_texel(param_2);\n            float _412 = _402.w;\n            int param_3 = (li * 4) + 3;\n            float4 _419 = fa_light_texel(param_3);\n            float _420 = _419.x;\n            float cos_inner = _420;\n            if (_420 > 1.5f)\n            {\n                cos_inner = lerp(_412, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_412, cos_inner, dot(-l, normalize(_402.xyz)));\n        }\n    }\n    int _451;\n    if (_353)\n    {\n        _451 = 0;\n    }\n    else\n    {\n        _451 = (_346 > 1.5f) ? 2 : 1;\n    }\n    LightSample _3624 = { l, _343.xyz * atten, atten, 1.0f, dist, _451 };\n    return _3624;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _691;\n    if (i == 0)\n    {\n        _691 = _701_fa_shadow_split.x;\n    }\n    else\n    {\n        float _707;\n        if (i == 1)\n        {\n            _707 = _701_fa_shadow_split.y;\n        }\n        else\n        {\n            float _715;\n            if (i == 2)\n            {\n                _715 = _701_fa_shadow_split.z;\n            }\n            else\n            {\n                _715 = _701_fa_shadow_split.w;\n            }\n            _707 = _715;\n        }\n        _691 = _707;\n    }\n    return _691;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _679 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_679), sin(_679)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _753 = max(_701_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _758 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _764 = sqrt(1.0f - (_758 * _758));\n    float _772 = min(_764 / max(_758, 0.20000000298023223876953125f), 4.0f);\n    float _777;\n    if (_701_fa_shadow_bias.y > 0.0f)\n    {\n        _777 = _701_fa_shadow_bias.y;\n    }\n    else\n    {\n        _777 = 1.5f * _701_fa_shadow_info[ci].x;\n    }\n    float4 _802 = mul(float4(world + (n * (_777 * _764)), 1.0f), _701_fa_shadow_mat[ci]);\n    float _809 = _802.x;\n    bool _812 = _809 < _701_fa_shadow_rect[ci].x;\n    bool _821;\n    if (!_812)\n    {\n        _821 = _809 > _701_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _821 = _812;\n    }\n    bool _830;\n    if (!_821)\n    {\n        _830 = _802.y < _701_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _830 = _821;\n    }\n    bool _839;\n    if (!_830)\n    {\n        _839 = _802.y > _701_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _839 = _830;\n    }\n    bool _846;\n    if (!_839)\n    {\n        _846 = _802.z > 1.0f;\n    }\n    else\n    {\n        _846 = _839;\n    }\n    if (_846)\n    {\n        return -1.0f;\n    }\n    float _855;\n    if (_701_fa_shadow_bias.x > 0.0f)\n    {\n        _855 = _701_fa_shadow_bias.x;\n    }\n    else\n    {\n        _855 = 1.5f * _701_fa_shadow_info[ci].x;\n    }\n    float _874 = _802.z - ((_855 * (1.0f + (0.5f * _772))) / _753);\n    float _883 = ((_701_fa_shadow_info[ci].x * min(_772, 3.0f)) * 0.5f) / _753;\n    int _892 = int(_701_fa_shadow_cfg.z + 0.5f);\n    if (_892 == 1)\n    {\n        float2 param = _802.xy;\n        float4 param_1 = _701_fa_shadow_rect[ci];\n        float _903 = fa_shadow_depth(param, param_1);\n        return float(_874 <= _903);\n    }\n    float _910 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _913 = _892 == 2;\n    if (_913)\n    {\n        float _927 = clamp(((_701_fa_shadow_cfg.w * _753) * 0.25f) / _701_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _910;\n            float2 _946 = fa_shadow_vogel(param_2, param_3, param_4) * _927;\n            float2 param_5 = _802.xy + (_946 * _701_fa_shadow_bias.zw);\n            float4 param_6 = _701_fa_shadow_rect[ci];\n            float _957 = fa_shadow_depth(param_5, param_6);\n            if (_957 < (_874 - (length(_946) * _883)))\n            {\n                sum += _957;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_874 - (sum / cnt), 0.0f) * _753) * _701_fa_shadow_cfg.w) / _701_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _1001 = _913 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1001; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1001;\n        float param_9 = _910;\n        float2 _1020 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _802.xy + (_1020 * _701_fa_shadow_bias.zw);\n        float4 param_11 = _701_fa_shadow_rect[ci];\n        float _1031 = fa_shadow_depth(param_10, param_11);\n        lit += float((_874 - (length(_1020) * _883)) <= _1031);\n    }\n    return lit / float(_1001);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_465_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1061 = int(_701_fa_shadow_cfg.x + 0.5f);\n    if (_1061 < 1)\n    {\n        return 1.0f;\n    }\n    float _1077 = dot(world - _701_fa_shadow_eye.xyz, _701_fa_shadow_fwd.xyz);\n    int param = _1061 - 1;\n    if (_1077 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1089 = _1061 > 1;\n    bool _1096;\n    if (_1089)\n    {\n        _1096 = _1077 > _701_fa_shadow_split.x;\n    }\n    else\n    {\n        _1096 = _1089;\n    }\n    if (_1096)\n    {\n        ci = 1;\n    }\n    bool _1100 = _1061 > 2;\n    bool _1107;\n    if (_1100)\n    {\n        _1107 = _1077 > _701_fa_shadow_split.y;\n    }\n    else\n    {\n        _1107 = _1100;\n    }\n    if (_1107)\n    {\n        ci = 2;\n    }\n    bool _1111 = _1061 > 3;\n    bool _1118;\n    if (_1111)\n    {\n        _1118 = _1077 > _701_fa_shadow_split.z;\n    }\n    else\n    {\n        _1118 = _1111;\n    }\n    if (_1118)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1061)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1144 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1144;\n        if (_1144 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_701_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1169;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1169 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1169 = _701_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1188 = _701_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1169, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1199 = clamp((_1077 - (fa_shadow_split_at(param_7) - _1188)) / _1188, 0.0f, 1.0f);\n        if (_1199 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1061)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1220 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1220;\n                if (_1220 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1199);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _2442 = fa_light_sample(param, param_1);\n    float3 _3674 = _2442.direction;\n    float3 _3669 = _2442.color;\n    float _3671 = _2442.shadow;\n    int _3679 = _2442.type;\n    if ((_3679 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _3674;\n        float _2456 = fa_shadow_factor(param_2, param_3);\n        _3671 = _2456;\n        _3669 *= _2456;\n    }\n    LightSample _3686 = { _3674, _3669, _2442.attenuation, _3671, _2442._distance, _3679 };\n    return _3686;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _2057 = tdh / at;\n    float _2061 = bdh / ab;\n    float _2073 = ((_2057 * _2057) + (_2061 * _2061)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _2073) * _2073);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _2154 = 1.0f / alpha;\n    return ((2.0f + _2154) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _2154)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _2187 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _2266 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _2266) * _2266);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _2187);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _2187));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        float _2339 = max(dot(L.nc, l), 0.0f);\n        float _2345 = max(dot(L.nc, h), 0.0f);\n        float _2354 = ((_2345 * _2345) * (L.coat_a2 - 1.0f)) + 1.0f;\n        result += ((((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _2354) * _2354)) * (0.5f / max(lerp((2.0f * _2339) * L.coat_ndv, _2339 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _2339)) * _2339).xxx;\n    }\n    return result;\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _1452 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _1455 = _1452.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_1455 * _1455, exp2((-9.27999973297119140625f) * ndv)) * _1455) + _1452.y)) + _1452.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_465_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _465_fa_env_horizon.w).xyz;\n    }\n    float _1357 = rough * rough;\n    float _1387 = 0.60000002384185791015625f * _1357;\n    return lerp(lerp(_465_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_465_fa_env_horizon.xyz, _465_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _1357)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _1387, 0.0500000007450580596923828125f + _1387, d.y).xxx), ((_465_fa_env_sky.xyz + _465_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_1357 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _1940;\n        if (L.aniso >= 0.0f)\n        {\n            _1940 = L.b;\n        }\n        else\n        {\n            _1940 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_1940, v), _1940), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1973 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _1973.x) + (L.f90.xxx * _1973.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2028 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _2028.x) + _2028.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1494 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1494.x) + _1494.y.xxx);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_701_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1244 = int(_701_fa_shadow_cfg.x + 0.5f);\n    float _1254 = dot(world - _701_fa_shadow_eye.xyz, _701_fa_shadow_fwd.xyz);\n    float3 tint_1 = 0.3499999940395355224609375f.xxx;\n    bool _1259 = _1244 > 0;\n    bool _1268;\n    if (_1259)\n    {\n        int param = _1244 - 1;\n        _1268 = _1254 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1268 = _1259;\n    }\n    if (_1268)\n    {\n        tint_1 = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1275 = _1244 > 1;\n        bool _1282;\n        if (_1275)\n        {\n            _1282 = _1254 > _701_fa_shadow_split.x;\n        }\n        else\n        {\n            _1282 = _1275;\n        }\n        if (_1282)\n        {\n            tint_1 = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1288 = _1244 > 2;\n        bool _1295;\n        if (_1288)\n        {\n            _1295 = _1254 > _701_fa_shadow_split.y;\n        }\n        else\n        {\n            _1295 = _1288;\n        }\n        if (_1295)\n        {\n            tint_1 = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1301 = _1244 > 3;\n        bool _1308;\n        if (_1301)\n        {\n            _1308 = _1254 > _701_fa_shadow_split.z;\n        }\n        else\n        {\n            _1308 = _1301;\n        }\n        if (_1308)\n        {\n            tint_1 = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint_1, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _3404 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3404 = -_3404;\n    }\n    float3 _2858 = normalize(_465_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _3417 = { fa_world_pos, _3404, fa_world_tangent, fa_uv, fa_vertex_color, _2858, gl_FrontFacing };\n    SurfaceInput param_1 = _3417;\n    Surface _2866 = fa_standard_surface(param_1);\n    float3 _3435 = _2866.albedo;\n    float _3436 = _2866.alpha;\n    float3 _3437 = _2866.normal;\n    float _3438 = _2866.metallic;\n    float _3439 = _2866.roughness;\n    float _3440 = _2866.occlusion;\n    float3 _3441 = _2866.emission;\n    float _3442 = _2866.clearcoat;\n    float _3443 = _2866.clearcoat_roughness;\n    float3 _3444 = _2866.sheen_color;\n    float _3445 = _2866.sheen_roughness;\n    float _3446 = _2866.anisotropy;\n    float _3447 = _2866.anisotropy_rotation;\n    float _3448 = _2866.specular;\n    float _3449 = _2866.ior;\n    float3 _3450 = _2866.specular_color;\n    SurfaceInput _3425 = { fa_world_pos, _3404, fa_world_tangent, fa_uv, fa_vertex_color, _2858, gl_FrontFacing };\n    SurfaceInput param_2 = _3425;\n    Surface param_3 = _2866;\n    surface(param_2, param_3);\n    _3435 = param_3.albedo;\n    _3436 = param_3.alpha;\n    _3437 = param_3.normal;\n    _3438 = param_3.metallic;\n    _3439 = param_3.roughness;\n    _3440 = param_3.occlusion;\n    _3441 = param_3.emission;\n    _3442 = param_3.clearcoat;\n    _3443 = param_3.clearcoat_roughness;\n    _3444 = param_3.sheen_color;\n    _3445 = param_3.sheen_roughness;\n    _3446 = param_3.anisotropy;\n    _3447 = param_3.anisotropy_rotation;\n    _3448 = param_3.specular;\n    _3449 = param_3.ior;\n    _3450 = param_3.specular_color;\n    float3 result;\n    if (_465_fa_emissive.w > 0.5f)\n    {\n        result = _3435;\n    }\n    else\n    {\n        float3 _2888 = normalize(_3437);\n        float _2895 = clamp(_3438, 0.0f, 1.0f);\n        float _2899 = clamp(_3439, 0.0500000007450580596923828125f, 1.0f);\n        float _2903 = _2899 * _2899;\n        float _2907 = _2903 * _2903;\n        float _2912 = max(dot(_2888, _2858), 9.9999997473787516355514526367188e-05f);\n        float3 _2918 = _3435 * (1.0f - _2895);\n        float3 _2925 = lerp(0.039999999105930328369140625f.xxx, _3435, _2895.xxx);\n        float3 f0 = _2925;\n        SurfaceInput _3433 = { fa_world_pos, _3404, fa_world_tangent, fa_uv, fa_vertex_color, _2858, gl_FrontFacing };\n        SurfaceInput param_4 = _3433;\n        Surface _3516 = { _3435, _3436, _3437, _3438, _3439, _3440, _3441, _3442, _3443, _3444, _3445, _3446, _3447, _3448, _3449, _3450 };\n        Surface param_5 = _3516;\n        float3 param_6 = _2888;\n        float3 param_7 = _2858;\n        float param_8 = _2895;\n        float param_9 = _2899;\n        float3 param_10 = _2925;\n        FaLayers _2941 = fa_layers_setup(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        f0 = param_10;\n        float3 param_11 = _2888;\n        float3 lit = (fa_ambient_light(param_11) * _2918) * _3440;\n        if (_2941.on)\n        {\n            lit *= _2941.base_scale;\n        }\n        int _2963 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2963; ln++)\n        {\n            int param_12 = ln;\n            int _2976 = fa_cl_light(param_12);\n            int param_13 = _2976;\n            float3 param_14 = fa_world_pos;\n            float3 param_15 = _3404;\n            LightSample _2985 = fa_light_shadowed(param_13, param_14, param_15);\n            float3 _3609 = _2985.direction;\n            float _2993 = max(dot(_2888, _3609), 0.0f);\n            float _2999 = _2985.attenuation * _2985.shadow;\n            float3 _3004 = normalize(_3609 + _2858);\n            float _3009 = max(dot(_2888, _3004), 0.0f);\n            float _3014 = max(dot(_2858, _3004), 0.0f);\n            if (_2941.on)\n            {\n                FaLayers param_16 = _2941;\n                float3 param_17 = _2918;\n                float3 param_18 = f0;\n                float3 param_19 = _2888;\n                float3 param_20 = _2858;\n                float3 param_21 = _3609;\n                float3 param_22 = _3004;\n                float param_23 = _2993;\n                float param_24 = _2912;\n                float param_25 = _3009;\n                float param_26 = _3014;\n                float param_27 = _2903;\n                float param_28 = _2907;\n                int param_29 = _2976;\n                lit += (fa_layers_light(param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28) * (fa_light_rgb(param_29) * _2999));\n            }\n            else\n            {\n                float _3062 = ((_3009 * _3009) * (_2907 - 1.0f)) + 1.0f;\n                int param_30 = _2976;\n                lit += (((_2918 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _3014, 5.0f))) * (((_2907 / ((3.1415927410125732421875f * _3062) * _3062)) * (0.5f / max(lerp((2.0f * _2993) * _2912, _2993 + _2912, _2903), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _2993))) * fa_light_rgb(param_30)) * (_2993 * _2999));\n            }\n        }\n        if (_2941.on)\n        {\n            FaLayers param_31 = _2941;\n            float3 param_32 = _2888;\n            float3 param_33 = _2858;\n            float3 param_34 = f0;\n            float param_35 = _2899;\n            lit += (fa_layers_ibl(param_31, param_32, param_33, param_34, param_35) * _3440);\n        }\n        else\n        {\n            float3 param_36 = _2888;\n            float3 param_37 = _2858;\n            float3 param_38 = f0;\n            float param_39 = _2899;\n            lit += (fa_sky_reflection(param_36, param_37, param_38, param_39) * _3440);\n        }\n        result = lit;\n    }\n    float3 _3155 = result;\n    float3 _3156 = _3155 + _3441;\n    result = _3156;\n    float3 param_40 = _3156;\n    float3 param_41 = fa_world_pos;\n    result = fa_shadow_debug(param_40, param_41);\n    bool _3165 = _465_fa_fog.w > 0.0f;\n    bool _3172;\n    if (!_3165)\n    {\n        _3172 = _465_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _3172 = _3165;\n    }\n    if (_3172)\n    {\n        float3 _3181 = fa_world_pos - _465_fa_camera_pos.xyz;\n        float _3187 = dot(_3181, _465_fa_fog_c.xyz);\n        bool _3191 = _465_fa_fog_c.w > 0.5f;\n        float _3192;\n        if (_3191)\n        {\n            _3192 = _3187;\n        }\n        else\n        {\n            _3192 = length(_3181);\n        }\n        float _3204 = _3192 - _465_fa_fog_b.x;\n        if (_3204 > 0.0f)\n        {\n            float _3213 = _465_fa_fog.w * _3204;\n            float tau = _3213 * _3213;\n            if (_465_fa_fog_b.y > 0.0f)\n            {\n                float _3229;\n                if (_3191)\n                {\n                    _3229 = fa_world_pos.y - (_465_fa_fog_c.y * _3187);\n                }\n                else\n                {\n                    _3229 = _465_fa_camera_pos.y;\n                }\n                float _3250 = lerp(_3229, fa_world_pos.y, clamp(_465_fa_fog_b.x / _3192, 0.0f, 1.0f));\n                float _3254 = fa_world_pos.y - _3250;\n                float _3259 = _3250 - _465_fa_fog_b.z;\n                float _3264 = fa_world_pos.y - _465_fa_fog_b.z;\n                bool _3267 = _3259 <= 0.0f;\n                bool _3268 = !_3267;\n                bool _3274;\n                if (_3268)\n                {\n                    _3274 = _465_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3274 = _3267;\n                }\n                float _3275;\n                if (_3274)\n                {\n                    _3275 = _465_fa_fog_b.y;\n                }\n                else\n                {\n                    _3275 = _465_fa_fog_b.y * exp(-min(_465_fa_fog_b.w * _3259, 80.0f));\n                }\n                bool _3302;\n                if (_3268)\n                {\n                    _3302 = _465_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3302 = _3267;\n                }\n                float _3303;\n                if (_3302)\n                {\n                    _3303 = _465_fa_fog_b.y * _3259;\n                }\n                else\n                {\n                    _3303 = (_465_fa_fog_b.y * (1.0f - exp(-min(_465_fa_fog_b.w * _3259, 80.0f)))) / _465_fa_fog_b.w;\n                }\n                bool _3328 = _3264 <= 0.0f;\n                bool _3335;\n                if (!_3328)\n                {\n                    _3335 = _465_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3335 = _3328;\n                }\n                float _3336;\n                if (_3335)\n                {\n                    _3336 = _465_fa_fog_b.y * _3264;\n                }\n                else\n                {\n                    _3336 = (_465_fa_fog_b.y * (1.0f - exp(-min(_465_fa_fog_b.w * _3264, 80.0f)))) / _465_fa_fog_b.w;\n                }\n                float _3363;\n                if (abs(_3254) < 0.001000000047497451305389404296875f)\n                {\n                    _3363 = _3275;\n                }\n                else\n                {\n                    _3363 = (_3336 - _3303) / _3254;\n                }\n                tau += (_3204 * max(_3363, 0.0f));\n            }\n            result = lerp(result, _465_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _3436);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_inst_v0 = stage_input.fa_inst_v0;\n    fa_inst_v1 = stage_input.fa_inst_v1;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_153",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_465",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_701",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_2481",
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 8,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _158_fa_view_proj : packoffset(c0);\n    row_major float4x4 _158_fa_light_vp : packoffset(c4);\n    float4 _158_fa_uv_scale : packoffset(c8);\n    float4 _158_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _205_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_d0;\nstatic float4 fa_inst_d1;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n    float4 fa_inst_d0 : TEXCOORD11;\n    float4 fa_inst_d1 : TEXCOORD12;\n};\n\nstruct SPIRV_Cross_Output\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float raise;\nstatic float4 tint;\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_205_fa_joint_rows[_196] * weights[i]);\n        r1 += (_205_fa_joint_rows[_196 + 1] * weights[i]);\n        r2 += (_205_fa_joint_rows[_196 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _420 = { mul(float4(position, 1.0f), model).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * _158_fa_uv_scale.xy, color, position };\n    return _420;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _158_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_d0 = stage_input.fa_inst_d0;\n    fa_inst_d1 = stage_input.fa_inst_d1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_inst_v0 = fa_inst_v0;\n    stage_output.fa_inst_v1 = fa_inst_v1;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _1595[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _465_fa_camera_pos : packoffset(c0);\n    float4 _465_fa_ambient : packoffset(c1);\n    float4 _465_fa_base_color : packoffset(c2);\n    float4 _465_fa_emissive : packoffset(c3);\n    float4 _465_fa_model_emissive : packoffset(c4);\n    float4 _465_fa_pbr : packoffset(c5);\n    float4 _465_fa_maps : packoffset(c6);\n    float4 _465_fa_fog : packoffset(c7);\n    float4 _465_fa_fog_b : packoffset(c8);\n    float4 _465_fa_fog_c : packoffset(c9);\n    float4 _465_fa_counts : packoffset(c10);\n    float4 _465_fa_env_sky : packoffset(c11);\n    float4 _465_fa_env_horizon : packoffset(c12);\n    float4 _465_fa_time : packoffset(c13);\n    float4 _465_fa_cl_vpx : packoffset(c14);\n    float4 _465_fa_cl_vpy : packoffset(c15);\n    float4 _465_fa_cl_vpw : packoffset(c16);\n    float4 _465_fa_cl_fwd : packoffset(c17);\n    float4 _465_fa_cl_grid : packoffset(c18);\n    float4 _465_fa_cl_info : packoffset(c19);\n    float4 _465_fa_layers_a : packoffset(c20);\n    float4 _465_fa_layers_b : packoffset(c21);\n    float4 _465_fa_layers_c : packoffset(c22);\n    float4 _465_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _701_fa_shadow_mat[4] : packoffset(c0);\n    float4 _701_fa_shadow_rect[4] : packoffset(c16);\n    float4 _701_fa_shadow_info[4] : packoffset(c20);\n    float4 _701_fa_shadow_split : packoffset(c24);\n    float4 _701_fa_shadow_cfg : packoffset(c25);\n    float4 _701_fa_shadow_bias : packoffset(c26);\n    float4 _701_fa_shadow_eye : packoffset(c27);\n    float4 _701_fa_shadow_fwd : packoffset(c28);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _2481_boost : packoffset(c0);\n    float _2481_fa_pad0 : packoffset(c0.y);\n    float _2481_fa_pad1 : packoffset(c0.z);\n    float _2481_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\nstatic float raise;\nstatic float4 tint;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _470 = _465_fa_cl_info.x < 0.0f;\n    bool _477;\n    if (!_470)\n    {\n        _477 = _465_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _477 = _470;\n    }\n    bool _485;\n    if (!_477)\n    {\n        _485 = _465_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _485 = _477;\n    }\n    bool _492;\n    if (!_485)\n    {\n        _492 = _465_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _492 = _485;\n    }\n    bool _499;\n    if (!_492)\n    {\n        _499 = _465_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _499 = _492;\n    }\n    if (_499)\n    {\n        return int2(0, 0);\n    }\n    float4 _509 = float4(world_pos, 1.0f);\n    float _516 = dot(_465_fa_cl_vpw, _509);\n    if (!(_516 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _538 = float2(dot(_465_fa_cl_vpx, _509), dot(_465_fa_cl_vpy, _509)) / _516.xx;\n    int _542 = int(_465_fa_cl_grid.x);\n    int _546 = int(_465_fa_cl_grid.y);\n    int param = (int(_465_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_465_fa_cl_fwd.xyz, world_pos) + _465_fa_cl_fwd.w, _465_fa_cl_grid.w) / _465_fa_cl_grid.w) * _465_fa_cl_grid.z)), 0, int(_465_fa_cl_info.y) - 1) * _546) + clamp(int(floor(((_538.y * 0.5f) + 0.5f) * _465_fa_cl_grid.y)), 0, _546 - 1)) * _542)) + clamp(int(floor(((_538.x * 0.5f) + 0.5f) * _465_fa_cl_grid.x)), 0, _542 - 1);\n    float4 _617 = fa_light_texel(param);\n    return int2(int(_617.x), int(_617.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_465_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2414 = fa_cluster_lookup(param);\n    fa_cl_slot = _2414.x;\n    fa_cl_local = _2414.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _2545 = fa_linear_to_srgb(param);\n        c = _2545;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _2553 = fa_srgb_to_linear(param_1);\n            c = _2553;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _237;\n    if (i.front_facing)\n    {\n        _237 = i.world_normal;\n    }\n    else\n    {\n        _237 = -i.world_normal;\n    }\n    float3 _261 = normalize(i.world_tangent.xyz - (_237 * dot(_237, i.world_tangent.xyz)));\n    float3 _289 = normalize(((_261 * m.x) + ((cross(_237, _261) * i.world_tangent.w) * m.y)) + (_237 * m.z));\n    float3 _292;\n    if (i.front_facing)\n    {\n        _292 = _289;\n    }\n    else\n    {\n        _292 = -_289;\n    }\n    return _292;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _465_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2584 = fa_tex_fix(param_2, param_3);\n    float4 _3755 = base_t;\n    _3755.x = _2584.x;\n    _3755.y = _2584.y;\n    _3755.z = _2584.z;\n    base_t = _3755;\n    float4 _2598 = (_3755 * _465_fa_base_color) * i.vertex_color;\n    float3 _3689 = i.world_normal;\n    if (_465_fa_maps.z > 0.5f)\n    {\n        float param_4 = _465_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2630 = fa_tex_fix(param_6, param_7);\n        float3 _2633 = (_2630 * 2.0f) - 1.0f.xxx;\n        float2 _2638 = _2633.xy * _465_fa_maps.x;\n        float3 _3763 = _2633;\n        _3763.x = _2638.x;\n        _3763.y = _2638.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3763;\n        _3689 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _465_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2667 = fa_tex_fix(param_12, param_13);\n    float4 _3766 = mrt;\n    _3766.x = _2667.x;\n    _3766.y = _2667.y;\n    _3766.z = _2667.z;\n    mrt = _3766;\n    float4 _2695 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _465_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _2695.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2707 = fa_tex_fix(param_16, param_17);\n    float param_18 = _465_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2737 = fa_tex_fix(param_20, param_21);\n    float _3694 = _465_fa_layers_a.x;\n    float _3695 = _465_fa_layers_a.y;\n    float _3698 = _465_fa_layers_a.z;\n    float _3697 = _465_fa_layers_b.w;\n    float _3700 = _465_fa_layers_c.x;\n    if (_465_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_465_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _3694 *= _2707.y;\n            _3695 *= _2707.z;\n            _3697 *= _2695.w;\n        }\n        if (_465_fa_layers_c.z > 1.5f)\n        {\n            _3698 *= mrt.x;\n            _3700 *= mrt.w;\n        }\n    }\n    Surface _3719 = { _2598.xyz, _2598.w, _3689, clamp(_465_fa_pbr.x * _2667.z, 0.0f, 1.0f), clamp(_465_fa_pbr.y * _2667.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_465_fa_maps.y * (_2707.x - 1.0f)), _465_fa_emissive.xyz + (_465_fa_model_emissive.xyz * _2737), _3694, _3695, _465_fa_layers_b.xyz, _3697, _3698, _465_fa_layers_a.w, _3700, _465_fa_layers_c.y, _465_fa_layers_d.xyz };\n    return _3719;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * _2481_boost);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1520 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _1528 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _1531 = int(_1520);\n    int _1534 = int(_1528);\n    float _1544 = _1528 - float(_1534);\n    int _1600 = (_1531 * 9) + _1534;\n    int _1620 = ((_1531 + 1) * 9) + _1534;\n    return lerp(lerp(_1595[_1600], _1595[_1600 + 1], _1544), lerp(_1595[_1620], _1595[_1620 + 1], _1544), _1520 - float(_1531));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _3625 = false;\n    float _3626 = 1.0f;\n    float _3627 = 1.0f;\n    float _3628 = 1.0f;\n    float _3629 = 0.0f;\n    float _3630 = 0.0f;\n    float _3631 = 0.0f;\n    float _3632 = 0.0f;\n    float _3634 = 1.0f;\n    bool _3635 = false;\n    float3 _3636 = 0.0f.xxx;\n    float _3637 = 1.0f;\n    float _3638 = 1.0f;\n    float _3639 = 1.0f;\n    float _3640 = 0.0f;\n    float _3641 = 0.0f;\n    float3 _3642 = float3(1.0f, 0.0f, 0.0f);\n    float3 _3643 = float3(0.0f, 0.0f, 1.0f);\n    float _3644 = 1.0f;\n    float _3645 = 1.0f;\n    float _1675 = clamp(s.specular, 0.0f, 1.0f);\n    float _1679 = clamp(s.ior, 1.0f, 3.0f);\n    bool _1684 = (_1675 != 1.0f) || (_1679 != 1.5f);\n    bool _1694;\n    if (!_1684)\n    {\n        _1694 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _1694 = _1684;\n    }\n    if (_1694)\n    {\n        float _1702 = (_1679 - 1.0f) / (_1679 + 1.0f);\n        f0 = lerp(min((_1702 * _1702).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _1675, s.albedo, metallic.xxx);\n        _3626 = lerp(_1675, 1.0f, metallic);\n        _3625 = true;\n    }\n    float _1730 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_1730 > 0.0f)\n    {\n        float _1738 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _3629 = _1730;\n        _3630 = _1738;\n        float _1745 = _1738 * _1738;\n        _3631 = _1745;\n        _3632 = _1745 * _1745;\n        float _1757 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _3634 = _1757;\n        _3627 = 1.0f - (_1730 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _1757, 0.0f, 1.0f), 5.0f))));\n        _3625 = true;\n    }\n    float3 _1777 = max(s.sheen_color, 0.0f.xxx);\n    float _1786 = max(_1777.x, max(_1777.y, _1777.z));\n    if (_1786 > 0.0f)\n    {\n        float _1794 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _3635 = true;\n        _3636 = _1777;\n        _3637 = _1794;\n        _3638 = _1794 * _1794;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _1794;\n        float _1811 = fa_sheen_albedo(param, param_1);\n        _3640 = _1811;\n        _3639 = 1.0f - min(_1786 * _1811, 1.0f);\n        _3625 = true;\n    }\n    _3628 = _3627 * _3639;\n    float _1830 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_1830 != 0.0f)\n    {\n        float3 _1845 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _1845;\n        if (dot(_1845, _1845) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _1859 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_1859.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _1859.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _1859.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _1863 = t;\n        float3 _1864 = normalize(_1863);\n        t = _1864;\n        float3 _1889 = normalize((_1864 * cos(s.anisotropy_rotation)) + ((cross(n, _1864) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _3642 = _1889;\n        _3643 = cross(n, _1889);\n        float _1899 = roughness * roughness;\n        float _1905 = lerp(_1899, 1.0f, _1830 * _1830);\n        bool _1907 = _1830 > 0.0f;\n        _3644 = _1907 ? _1905 : _1899;\n        _3645 = _1907 ? _1899 : _1905;\n        _3641 = _1830;\n        _3625 = true;\n    }\n    FaLayers _3667 = { _3625, _3626, _3627, _3628, _3629, _3630, _3631, _3632, i.world_normal, _3634, _3635, _3636, _3637, _3638, _3639, _3640, _3641, _3642, _3643, _3644, _3645 };\n    return _3667;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_465_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _465_fa_ambient.xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_465_fa_cl_info.x) + int(_465_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _337 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _343 = fa_light_texel(param_1);\n    float _346 = _343.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _353 = _346 < 0.5f;\n    float3 l;\n    if (_353)\n    {\n        l = normalize(_337.xyz);\n    }\n    else\n    {\n        float3 _365 = _337.xyz - world_pos;\n        float _367 = length(_365);\n        dist = _367;\n        l = _365 / max(_367, 9.9999997473787516355514526367188e-05f).xxx;\n        float _382 = _367 / max(_337.w, 0.001000000047497451305389404296875f);\n        float _388 = clamp(1.0f - (_382 * _382), 0.0f, 1.0f);\n        atten = _388 * _388;\n        if (_346 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _402 = fa_light_texel(param_2);\n            float _412 = _402.w;\n            int param_3 = (li * 4) + 3;\n            float4 _419 = fa_light_texel(param_3);\n            float _420 = _419.x;\n            float cos_inner = _420;\n            if (_420 > 1.5f)\n            {\n                cos_inner = lerp(_412, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_412, cos_inner, dot(-l, normalize(_402.xyz)));\n        }\n    }\n    int _451;\n    if (_353)\n    {\n        _451 = 0;\n    }\n    else\n    {\n        _451 = (_346 > 1.5f) ? 2 : 1;\n    }\n    LightSample _3624 = { l, _343.xyz * atten, atten, 1.0f, dist, _451 };\n    return _3624;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _691;\n    if (i == 0)\n    {\n        _691 = _701_fa_shadow_split.x;\n    }\n    else\n    {\n        float _707;\n        if (i == 1)\n        {\n            _707 = _701_fa_shadow_split.y;\n        }\n        else\n        {\n            float _715;\n            if (i == 2)\n            {\n                _715 = _701_fa_shadow_split.z;\n            }\n            else\n            {\n                _715 = _701_fa_shadow_split.w;\n            }\n            _707 = _715;\n        }\n        _691 = _707;\n    }\n    return _691;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _679 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_679), sin(_679)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _753 = max(_701_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _758 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _764 = sqrt(1.0f - (_758 * _758));\n    float _772 = min(_764 / max(_758, 0.20000000298023223876953125f), 4.0f);\n    float _777;\n    if (_701_fa_shadow_bias.y > 0.0f)\n    {\n        _777 = _701_fa_shadow_bias.y;\n    }\n    else\n    {\n        _777 = 1.5f * _701_fa_shadow_info[ci].x;\n    }\n    float4 _802 = mul(float4(world + (n * (_777 * _764)), 1.0f), _701_fa_shadow_mat[ci]);\n    float _809 = _802.x;\n    bool _812 = _809 < _701_fa_shadow_rect[ci].x;\n    bool _821;\n    if (!_812)\n    {\n        _821 = _809 > _701_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _821 = _812;\n    }\n    bool _830;\n    if (!_821)\n    {\n        _830 = _802.y < _701_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _830 = _821;\n    }\n    bool _839;\n    if (!_830)\n    {\n        _839 = _802.y > _701_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _839 = _830;\n    }\n    bool _846;\n    if (!_839)\n    {\n        _846 = _802.z > 1.0f;\n    }\n    else\n    {\n        _846 = _839;\n    }\n    if (_846)\n    {\n        return -1.0f;\n    }\n    float _855;\n    if (_701_fa_shadow_bias.x > 0.0f)\n    {\n        _855 = _701_fa_shadow_bias.x;\n    }\n    else\n    {\n        _855 = 1.5f * _701_fa_shadow_info[ci].x;\n    }\n    float _874 = _802.z - ((_855 * (1.0f + (0.5f * _772))) / _753);\n    float _883 = ((_701_fa_shadow_info[ci].x * min(_772, 3.0f)) * 0.5f) / _753;\n    int _892 = int(_701_fa_shadow_cfg.z + 0.5f);\n    if (_892 == 1)\n    {\n        float2 param = _802.xy;\n        float4 param_1 = _701_fa_shadow_rect[ci];\n        float _903 = fa_shadow_depth(param, param_1);\n        return float(_874 <= _903);\n    }\n    float _910 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _913 = _892 == 2;\n    if (_913)\n    {\n        float _927 = clamp(((_701_fa_shadow_cfg.w * _753) * 0.25f) / _701_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _910;\n            float2 _946 = fa_shadow_vogel(param_2, param_3, param_4) * _927;\n            float2 param_5 = _802.xy + (_946 * _701_fa_shadow_bias.zw);\n            float4 param_6 = _701_fa_shadow_rect[ci];\n            float _957 = fa_shadow_depth(param_5, param_6);\n            if (_957 < (_874 - (length(_946) * _883)))\n            {\n                sum += _957;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_874 - (sum / cnt), 0.0f) * _753) * _701_fa_shadow_cfg.w) / _701_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _1001 = _913 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1001; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1001;\n        float param_9 = _910;\n        float2 _1020 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _802.xy + (_1020 * _701_fa_shadow_bias.zw);\n        float4 param_11 = _701_fa_shadow_rect[ci];\n        float _1031 = fa_shadow_depth(param_10, param_11);\n        lit += float((_874 - (length(_1020) * _883)) <= _1031);\n    }\n    return lit / float(_1001);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_465_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1061 = int(_701_fa_shadow_cfg.x + 0.5f);\n    if (_1061 < 1)\n    {\n        return 1.0f;\n    }\n    float _1077 = dot(world - _701_fa_shadow_eye.xyz, _701_fa_shadow_fwd.xyz);\n    int param = _1061 - 1;\n    if (_1077 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1089 = _1061 > 1;\n    bool _1096;\n    if (_1089)\n    {\n        _1096 = _1077 > _701_fa_shadow_split.x;\n    }\n    else\n    {\n        _1096 = _1089;\n    }\n    if (_1096)\n    {\n        ci = 1;\n    }\n    bool _1100 = _1061 > 2;\n    bool _1107;\n    if (_1100)\n    {\n        _1107 = _1077 > _701_fa_shadow_split.y;\n    }\n    else\n    {\n        _1107 = _1100;\n    }\n    if (_1107)\n    {\n        ci = 2;\n    }\n    bool _1111 = _1061 > 3;\n    bool _1118;\n    if (_1111)\n    {\n        _1118 = _1077 > _701_fa_shadow_split.z;\n    }\n    else\n    {\n        _1118 = _1111;\n    }\n    if (_1118)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1061)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1144 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1144;\n        if (_1144 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_701_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1169;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1169 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1169 = _701_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1188 = _701_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1169, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1199 = clamp((_1077 - (fa_shadow_split_at(param_7) - _1188)) / _1188, 0.0f, 1.0f);\n        if (_1199 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1061)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1220 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1220;\n                if (_1220 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1199);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _2442 = fa_light_sample(param, param_1);\n    float3 _3674 = _2442.direction;\n    float3 _3669 = _2442.color;\n    float _3671 = _2442.shadow;\n    int _3679 = _2442.type;\n    if ((_3679 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _3674;\n        float _2456 = fa_shadow_factor(param_2, param_3);\n        _3671 = _2456;\n        _3669 *= _2456;\n    }\n    LightSample _3686 = { _3674, _3669, _2442.attenuation, _3671, _2442._distance, _3679 };\n    return _3686;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _2057 = tdh / at;\n    float _2061 = bdh / ab;\n    float _2073 = ((_2057 * _2057) + (_2061 * _2061)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _2073) * _2073);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _2154 = 1.0f / alpha;\n    return ((2.0f + _2154) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _2154)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _2187 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _2266 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _2266) * _2266);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _2187);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _2187));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        float _2339 = max(dot(L.nc, l), 0.0f);\n        float _2345 = max(dot(L.nc, h), 0.0f);\n        float _2354 = ((_2345 * _2345) * (L.coat_a2 - 1.0f)) + 1.0f;\n        result += ((((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _2354) * _2354)) * (0.5f / max(lerp((2.0f * _2339) * L.coat_ndv, _2339 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _2339)) * _2339).xxx;\n    }\n    return result;\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _1452 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _1455 = _1452.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_1455 * _1455, exp2((-9.27999973297119140625f) * ndv)) * _1455) + _1452.y)) + _1452.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_465_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _465_fa_env_horizon.w).xyz;\n    }\n    float _1357 = rough * rough;\n    float _1387 = 0.60000002384185791015625f * _1357;\n    return lerp(lerp(_465_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_465_fa_env_horizon.xyz, _465_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _1357)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _1387, 0.0500000007450580596923828125f + _1387, d.y).xxx), ((_465_fa_env_sky.xyz + _465_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_1357 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _1940;\n        if (L.aniso >= 0.0f)\n        {\n            _1940 = L.b;\n        }\n        else\n        {\n            _1940 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_1940, v), _1940), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1973 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _1973.x) + (L.f90.xxx * _1973.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2028 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _2028.x) + _2028.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1494 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1494.x) + _1494.y.xxx);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_701_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1244 = int(_701_fa_shadow_cfg.x + 0.5f);\n    float _1254 = dot(world - _701_fa_shadow_eye.xyz, _701_fa_shadow_fwd.xyz);\n    float3 tint_1 = 0.3499999940395355224609375f.xxx;\n    bool _1259 = _1244 > 0;\n    bool _1268;\n    if (_1259)\n    {\n        int param = _1244 - 1;\n        _1268 = _1254 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1268 = _1259;\n    }\n    if (_1268)\n    {\n        tint_1 = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1275 = _1244 > 1;\n        bool _1282;\n        if (_1275)\n        {\n            _1282 = _1254 > _701_fa_shadow_split.x;\n        }\n        else\n        {\n            _1282 = _1275;\n        }\n        if (_1282)\n        {\n            tint_1 = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1288 = _1244 > 2;\n        bool _1295;\n        if (_1288)\n        {\n            _1295 = _1254 > _701_fa_shadow_split.y;\n        }\n        else\n        {\n            _1295 = _1288;\n        }\n        if (_1295)\n        {\n            tint_1 = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1301 = _1244 > 3;\n        bool _1308;\n        if (_1301)\n        {\n            _1308 = _1254 > _701_fa_shadow_split.z;\n        }\n        else\n        {\n            _1308 = _1301;\n        }\n        if (_1308)\n        {\n            tint_1 = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint_1, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _3404 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3404 = -_3404;\n    }\n    float3 _2858 = normalize(_465_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _3417 = { fa_world_pos, _3404, fa_world_tangent, fa_uv, fa_vertex_color, _2858, gl_FrontFacing };\n    SurfaceInput param_1 = _3417;\n    Surface _2866 = fa_standard_surface(param_1);\n    float3 _3435 = _2866.albedo;\n    float _3436 = _2866.alpha;\n    float3 _3437 = _2866.normal;\n    float _3438 = _2866.metallic;\n    float _3439 = _2866.roughness;\n    float _3440 = _2866.occlusion;\n    float3 _3441 = _2866.emission;\n    float _3442 = _2866.clearcoat;\n    float _3443 = _2866.clearcoat_roughness;\n    float3 _3444 = _2866.sheen_color;\n    float _3445 = _2866.sheen_roughness;\n    float _3446 = _2866.anisotropy;\n    float _3447 = _2866.anisotropy_rotation;\n    float _3448 = _2866.specular;\n    float _3449 = _2866.ior;\n    float3 _3450 = _2866.specular_color;\n    SurfaceInput _3425 = { fa_world_pos, _3404, fa_world_tangent, fa_uv, fa_vertex_color, _2858, gl_FrontFacing };\n    SurfaceInput param_2 = _3425;\n    Surface param_3 = _2866;\n    surface(param_2, param_3);\n    _3435 = param_3.albedo;\n    _3436 = param_3.alpha;\n    _3437 = param_3.normal;\n    _3438 = param_3.metallic;\n    _3439 = param_3.roughness;\n    _3440 = param_3.occlusion;\n    _3441 = param_3.emission;\n    _3442 = param_3.clearcoat;\n    _3443 = param_3.clearcoat_roughness;\n    _3444 = param_3.sheen_color;\n    _3445 = param_3.sheen_roughness;\n    _3446 = param_3.anisotropy;\n    _3447 = param_3.anisotropy_rotation;\n    _3448 = param_3.specular;\n    _3449 = param_3.ior;\n    _3450 = param_3.specular_color;\n    float3 result;\n    if (_465_fa_emissive.w > 0.5f)\n    {\n        result = _3435;\n    }\n    else\n    {\n        float3 _2888 = normalize(_3437);\n        float _2895 = clamp(_3438, 0.0f, 1.0f);\n        float _2899 = clamp(_3439, 0.0500000007450580596923828125f, 1.0f);\n        float _2903 = _2899 * _2899;\n        float _2907 = _2903 * _2903;\n        float _2912 = max(dot(_2888, _2858), 9.9999997473787516355514526367188e-05f);\n        float3 _2918 = _3435 * (1.0f - _2895);\n        float3 _2925 = lerp(0.039999999105930328369140625f.xxx, _3435, _2895.xxx);\n        float3 f0 = _2925;\n        SurfaceInput _3433 = { fa_world_pos, _3404, fa_world_tangent, fa_uv, fa_vertex_color, _2858, gl_FrontFacing };\n        SurfaceInput param_4 = _3433;\n        Surface _3516 = { _3435, _3436, _3437, _3438, _3439, _3440, _3441, _3442, _3443, _3444, _3445, _3446, _3447, _3448, _3449, _3450 };\n        Surface param_5 = _3516;\n        float3 param_6 = _2888;\n        float3 param_7 = _2858;\n        float param_8 = _2895;\n        float param_9 = _2899;\n        float3 param_10 = _2925;\n        FaLayers _2941 = fa_layers_setup(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        f0 = param_10;\n        float3 param_11 = _2888;\n        float3 lit = (fa_ambient_light(param_11) * _2918) * _3440;\n        if (_2941.on)\n        {\n            lit *= _2941.base_scale;\n        }\n        int _2963 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2963; ln++)\n        {\n            int param_12 = ln;\n            int _2976 = fa_cl_light(param_12);\n            int param_13 = _2976;\n            float3 param_14 = fa_world_pos;\n            float3 param_15 = _3404;\n            LightSample _2985 = fa_light_shadowed(param_13, param_14, param_15);\n            float3 _3609 = _2985.direction;\n            float _2993 = max(dot(_2888, _3609), 0.0f);\n            float _2999 = _2985.attenuation * _2985.shadow;\n            float3 _3004 = normalize(_3609 + _2858);\n            float _3009 = max(dot(_2888, _3004), 0.0f);\n            float _3014 = max(dot(_2858, _3004), 0.0f);\n            if (_2941.on)\n            {\n                FaLayers param_16 = _2941;\n                float3 param_17 = _2918;\n                float3 param_18 = f0;\n                float3 param_19 = _2888;\n                float3 param_20 = _2858;\n                float3 param_21 = _3609;\n                float3 param_22 = _3004;\n                float param_23 = _2993;\n                float param_24 = _2912;\n                float param_25 = _3009;\n                float param_26 = _3014;\n                float param_27 = _2903;\n                float param_28 = _2907;\n                int param_29 = _2976;\n                lit += (fa_layers_light(param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28) * (fa_light_rgb(param_29) * _2999));\n            }\n            else\n            {\n                float _3062 = ((_3009 * _3009) * (_2907 - 1.0f)) + 1.0f;\n                int param_30 = _2976;\n                lit += (((_2918 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _3014, 5.0f))) * (((_2907 / ((3.1415927410125732421875f * _3062) * _3062)) * (0.5f / max(lerp((2.0f * _2993) * _2912, _2993 + _2912, _2903), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _2993))) * fa_light_rgb(param_30)) * (_2993 * _2999));\n            }\n        }\n        if (_2941.on)\n        {\n            FaLayers param_31 = _2941;\n            float3 param_32 = _2888;\n            float3 param_33 = _2858;\n            float3 param_34 = f0;\n            float param_35 = _2899;\n            lit += (fa_layers_ibl(param_31, param_32, param_33, param_34, param_35) * _3440);\n        }\n        else\n        {\n            float3 param_36 = _2888;\n            float3 param_37 = _2858;\n            float3 param_38 = f0;\n            float param_39 = _2899;\n            lit += (fa_sky_reflection(param_36, param_37, param_38, param_39) * _3440);\n        }\n        result = lit;\n    }\n    float3 _3155 = result;\n    float3 _3156 = _3155 + _3441;\n    result = _3156;\n    float3 param_40 = _3156;\n    float3 param_41 = fa_world_pos;\n    result = fa_shadow_debug(param_40, param_41);\n    bool _3165 = _465_fa_fog.w > 0.0f;\n    bool _3172;\n    if (!_3165)\n    {\n        _3172 = _465_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _3172 = _3165;\n    }\n    if (_3172)\n    {\n        float3 _3181 = fa_world_pos - _465_fa_camera_pos.xyz;\n        float _3187 = dot(_3181, _465_fa_fog_c.xyz);\n        bool _3191 = _465_fa_fog_c.w > 0.5f;\n        float _3192;\n        if (_3191)\n        {\n            _3192 = _3187;\n        }\n        else\n        {\n            _3192 = length(_3181);\n        }\n        float _3204 = _3192 - _465_fa_fog_b.x;\n        if (_3204 > 0.0f)\n        {\n            float _3213 = _465_fa_fog.w * _3204;\n            float tau = _3213 * _3213;\n            if (_465_fa_fog_b.y > 0.0f)\n            {\n                float _3229;\n                if (_3191)\n                {\n                    _3229 = fa_world_pos.y - (_465_fa_fog_c.y * _3187);\n                }\n                else\n                {\n                    _3229 = _465_fa_camera_pos.y;\n                }\n                float _3250 = lerp(_3229, fa_world_pos.y, clamp(_465_fa_fog_b.x / _3192, 0.0f, 1.0f));\n                float _3254 = fa_world_pos.y - _3250;\n                float _3259 = _3250 - _465_fa_fog_b.z;\n                float _3264 = fa_world_pos.y - _465_fa_fog_b.z;\n                bool _3267 = _3259 <= 0.0f;\n                bool _3268 = !_3267;\n                bool _3274;\n                if (_3268)\n                {\n                    _3274 = _465_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3274 = _3267;\n                }\n                float _3275;\n                if (_3274)\n                {\n                    _3275 = _465_fa_fog_b.y;\n                }\n                else\n                {\n                    _3275 = _465_fa_fog_b.y * exp(-min(_465_fa_fog_b.w * _3259, 80.0f));\n                }\n                bool _3302;\n                if (_3268)\n                {\n                    _3302 = _465_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3302 = _3267;\n                }\n                float _3303;\n                if (_3302)\n                {\n                    _3303 = _465_fa_fog_b.y * _3259;\n                }\n                else\n                {\n                    _3303 = (_465_fa_fog_b.y * (1.0f - exp(-min(_465_fa_fog_b.w * _3259, 80.0f)))) / _465_fa_fog_b.w;\n                }\n                bool _3328 = _3264 <= 0.0f;\n                bool _3335;\n                if (!_3328)\n                {\n                    _3335 = _465_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3335 = _3328;\n                }\n                float _3336;\n                if (_3335)\n                {\n                    _3336 = _465_fa_fog_b.y * _3264;\n                }\n                else\n                {\n                    _3336 = (_465_fa_fog_b.y * (1.0f - exp(-min(_465_fa_fog_b.w * _3264, 80.0f)))) / _465_fa_fog_b.w;\n                }\n                float _3363;\n                if (abs(_3254) < 0.001000000047497451305389404296875f)\n                {\n                    _3363 = _3275;\n                }\n                else\n                {\n                    _3363 = (_3336 - _3303) / _3254;\n                }\n                tau += (_3204 * max(_3363, 0.0f));\n            }\n            result = lerp(result, _465_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _3436);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_inst_v0 = stage_input.fa_inst_v0;\n    fa_inst_v1 = stage_input.fa_inst_v1;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "type": "vec4",
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
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_158",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_205",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_465",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_701",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_2481",
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 8,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _153_fa_view_proj : packoffset(c0);\n    row_major float4x4 _153_fa_light_vp : packoffset(c4);\n    float4 _153_fa_uv_scale : packoffset(c8);\n    float4 _153_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_d0;\nstatic float4 fa_inst_d1;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_inst_d0 : TEXCOORD9;\n    float4 fa_inst_d1 : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float fa_pre_depth : TEXCOORD7;\n    float3 fa_pre_r0 : TEXCOORD8;\n    float3 fa_pre_r1 : TEXCOORD9;\n    float3 fa_pre_r2 : TEXCOORD10;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float raise;\nstatic float4 tint;\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _100 = (dot(model[0].xyz, _94) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _334 = { mul(float4(position, 1.0f), model).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _100, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _100), texcoord0 * _153_fa_uv_scale.xy, color, position };\n    return _334;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _197 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -mul(_197, _153_fa_light_vp).z;\n    fa_pre_r0 = float3(_153_fa_light_vp[0].x, _153_fa_light_vp[1].x, _153_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_153_fa_light_vp[0].y, _153_fa_light_vp[1].y, _153_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_153_fa_light_vp[0].z, _153_fa_light_vp[1].z, _153_fa_light_vp[2].z);\n    gl_Position = mul(_197, _153_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_d0 = stage_input.fa_inst_d0;\n    fa_inst_d1 = stage_input.fa_inst_d1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    stage_output.fa_inst_v0 = fa_inst_v0;\n    stage_output.fa_inst_v1 = fa_inst_v1;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _142_boost : packoffset(c0);\n    float _142_fa_pad0 : packoffset(c0.y);\n    float _142_fa_pad1 : packoffset(c0.z);\n    float _142_fa_pad2 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _253_fa_camera_pos : packoffset(c0);\n    float4 _253_fa_ambient : packoffset(c1);\n    float4 _253_fa_base_color : packoffset(c2);\n    float4 _253_fa_emissive : packoffset(c3);\n    float4 _253_fa_model_emissive : packoffset(c4);\n    float4 _253_fa_pbr : packoffset(c5);\n    float4 _253_fa_maps : packoffset(c6);\n    float4 _253_fa_fog : packoffset(c7);\n    float4 _253_fa_fog_b : packoffset(c8);\n    float4 _253_fa_fog_c : packoffset(c9);\n    float4 _253_fa_counts : packoffset(c10);\n    float4 _253_fa_env_sky : packoffset(c11);\n    float4 _253_fa_env_horizon : packoffset(c12);\n    float4 _253_fa_time : packoffset(c13);\n    float4 _253_fa_cl_vpx : packoffset(c14);\n    float4 _253_fa_cl_vpy : packoffset(c15);\n    float4 _253_fa_cl_vpw : packoffset(c16);\n    float4 _253_fa_cl_fwd : packoffset(c17);\n    float4 _253_fa_cl_grid : packoffset(c18);\n    float4 _253_fa_cl_info : packoffset(c19);\n    float4 _253_fa_layers_a : packoffset(c20);\n    float4 _253_fa_layers_b : packoffset(c21);\n    float4 _253_fa_layers_c : packoffset(c22);\n    float4 _253_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float fa_pre_depth : TEXCOORD7;\n    float3 fa_pre_r0 : TEXCOORD8;\n    float3 fa_pre_r1 : TEXCOORD9;\n    float3 fa_pre_r2 : TEXCOORD10;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float raise;\nstatic float4 tint;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    float3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    float3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    float3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _253_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _264 = fa_tex_fix(param_2, param_3);\n    float4 _770 = base_t;\n    _770.x = _264.x;\n    _770.y = _264.y;\n    _770.z = _264.z;\n    base_t = _770;\n    float4 _280 = (_770 * _253_fa_base_color) * i.vertex_color;\n    float3 _733 = i.world_normal;\n    if (_253_fa_maps.z > 0.5f)\n    {\n        float param_4 = _253_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _313 = fa_tex_fix(param_6, param_7);\n        float3 _317 = (_313 * 2.0f) - 1.0f.xxx;\n        float2 _322 = _317.xy * _253_fa_maps.x;\n        float3 _778 = _317;\n        _778.x = _322.x;\n        _778.y = _322.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _778;\n        _733 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _253_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _351 = fa_tex_fix(param_12, param_13);\n    float4 _781 = mrt;\n    _781.x = _351.x;\n    _781.y = _351.y;\n    _781.z = _351.z;\n    mrt = _781;\n    float4 _381 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _253_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _381.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _393 = fa_tex_fix(param_16, param_17);\n    float param_18 = _253_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _423 = fa_tex_fix(param_20, param_21);\n    float _738 = _253_fa_layers_a.x;\n    float _739 = _253_fa_layers_a.y;\n    float _742 = _253_fa_layers_a.z;\n    float _741 = _253_fa_layers_b.w;\n    float _744 = _253_fa_layers_c.x;\n    if (_253_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_253_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _738 *= _393.y;\n            _739 *= _393.z;\n            _741 *= _381.w;\n        }\n        if (_253_fa_layers_c.z > 1.5f)\n        {\n            _742 *= mrt.x;\n            _744 *= mrt.w;\n        }\n    }\n    Surface _763 = { _280.xyz, _280.w, _733, clamp(_253_fa_pbr.x * _351.z, 0.0f, 1.0f), clamp(_253_fa_pbr.y * _351.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_253_fa_maps.y * (_393.x - 1.0f)), _253_fa_emissive.xyz + (_253_fa_model_emissive.xyz * _423), _738, _739, _253_fa_layers_b.xyz, _741, _742, _253_fa_layers_a.w, _744, _253_fa_layers_c.y, _253_fa_layers_d.xyz };\n    return _763;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * _142_boost);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _644 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _644 = -_644;\n    }\n    float3 _556 = normalize(_253_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _657 = { fa_world_pos, _644, fa_world_tangent, fa_uv, fa_vertex_color, _556, gl_FrontFacing };\n    SurfaceInput param = _657;\n    SurfaceInput _665 = { fa_world_pos, _644, fa_world_tangent, fa_uv, fa_vertex_color, _556, gl_FrontFacing };\n    SurfaceInput param_1 = _665;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _571 = normalize(param_2.normal);\n    float3 _586 = normalize(float3(dot(fa_pre_r0, _571), dot(fa_pre_r1, _571), dot(fa_pre_r2, _571)));\n    float _598 = _586.z;\n    float2 e = _586.xy / ((abs(_586.x) + abs(_586.y)) + abs(_598)).xx;\n    if (_598 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_inst_v0 = stage_input.fa_inst_v0;\n    fa_inst_v1 = stage_input.fa_inst_v1;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_153",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_142",
            "hlsl_register_b_n": 5
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_253",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _158_fa_view_proj : packoffset(c0);\n    row_major float4x4 _158_fa_light_vp : packoffset(c4);\n    float4 _158_fa_uv_scale : packoffset(c8);\n    float4 _158_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _205_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_d0;\nstatic float4 fa_inst_d1;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n    float4 fa_inst_d0 : TEXCOORD11;\n    float4 fa_inst_d1 : TEXCOORD12;\n};\n\nstruct SPIRV_Cross_Output\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float fa_pre_depth : TEXCOORD7;\n    float3 fa_pre_r0 : TEXCOORD8;\n    float3 fa_pre_r1 : TEXCOORD9;\n    float3 fa_pre_r2 : TEXCOORD10;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float raise;\nstatic float4 tint;\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_205_fa_joint_rows[_196] * weights[i]);\n        r1 += (_205_fa_joint_rows[_196 + 1] * weights[i]);\n        r2 += (_205_fa_joint_rows[_196 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _454 = { mul(float4(position, 1.0f), model).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * _158_fa_uv_scale.xy, color, position };\n    return _454;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _310 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -mul(_310, _158_fa_light_vp).z;\n    fa_pre_r0 = float3(_158_fa_light_vp[0].x, _158_fa_light_vp[1].x, _158_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_158_fa_light_vp[0].y, _158_fa_light_vp[1].y, _158_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_158_fa_light_vp[0].z, _158_fa_light_vp[1].z, _158_fa_light_vp[2].z);\n    gl_Position = mul(_310, _158_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_d0 = stage_input.fa_inst_d0;\n    fa_inst_d1 = stage_input.fa_inst_d1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    stage_output.fa_inst_v0 = fa_inst_v0;\n    stage_output.fa_inst_v1 = fa_inst_v1;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _142_boost : packoffset(c0);\n    float _142_fa_pad0 : packoffset(c0.y);\n    float _142_fa_pad1 : packoffset(c0.z);\n    float _142_fa_pad2 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _253_fa_camera_pos : packoffset(c0);\n    float4 _253_fa_ambient : packoffset(c1);\n    float4 _253_fa_base_color : packoffset(c2);\n    float4 _253_fa_emissive : packoffset(c3);\n    float4 _253_fa_model_emissive : packoffset(c4);\n    float4 _253_fa_pbr : packoffset(c5);\n    float4 _253_fa_maps : packoffset(c6);\n    float4 _253_fa_fog : packoffset(c7);\n    float4 _253_fa_fog_b : packoffset(c8);\n    float4 _253_fa_fog_c : packoffset(c9);\n    float4 _253_fa_counts : packoffset(c10);\n    float4 _253_fa_env_sky : packoffset(c11);\n    float4 _253_fa_env_horizon : packoffset(c12);\n    float4 _253_fa_time : packoffset(c13);\n    float4 _253_fa_cl_vpx : packoffset(c14);\n    float4 _253_fa_cl_vpy : packoffset(c15);\n    float4 _253_fa_cl_vpw : packoffset(c16);\n    float4 _253_fa_cl_fwd : packoffset(c17);\n    float4 _253_fa_cl_grid : packoffset(c18);\n    float4 _253_fa_cl_info : packoffset(c19);\n    float4 _253_fa_layers_a : packoffset(c20);\n    float4 _253_fa_layers_b : packoffset(c21);\n    float4 _253_fa_layers_c : packoffset(c22);\n    float4 _253_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float fa_pre_depth : TEXCOORD7;\n    float3 fa_pre_r0 : TEXCOORD8;\n    float3 fa_pre_r1 : TEXCOORD9;\n    float3 fa_pre_r2 : TEXCOORD10;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float raise;\nstatic float4 tint;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    float3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    float3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    float3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _253_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _264 = fa_tex_fix(param_2, param_3);\n    float4 _770 = base_t;\n    _770.x = _264.x;\n    _770.y = _264.y;\n    _770.z = _264.z;\n    base_t = _770;\n    float4 _280 = (_770 * _253_fa_base_color) * i.vertex_color;\n    float3 _733 = i.world_normal;\n    if (_253_fa_maps.z > 0.5f)\n    {\n        float param_4 = _253_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _313 = fa_tex_fix(param_6, param_7);\n        float3 _317 = (_313 * 2.0f) - 1.0f.xxx;\n        float2 _322 = _317.xy * _253_fa_maps.x;\n        float3 _778 = _317;\n        _778.x = _322.x;\n        _778.y = _322.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _778;\n        _733 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _253_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _351 = fa_tex_fix(param_12, param_13);\n    float4 _781 = mrt;\n    _781.x = _351.x;\n    _781.y = _351.y;\n    _781.z = _351.z;\n    mrt = _781;\n    float4 _381 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _253_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _381.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _393 = fa_tex_fix(param_16, param_17);\n    float param_18 = _253_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _423 = fa_tex_fix(param_20, param_21);\n    float _738 = _253_fa_layers_a.x;\n    float _739 = _253_fa_layers_a.y;\n    float _742 = _253_fa_layers_a.z;\n    float _741 = _253_fa_layers_b.w;\n    float _744 = _253_fa_layers_c.x;\n    if (_253_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_253_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _738 *= _393.y;\n            _739 *= _393.z;\n            _741 *= _381.w;\n        }\n        if (_253_fa_layers_c.z > 1.5f)\n        {\n            _742 *= mrt.x;\n            _744 *= mrt.w;\n        }\n    }\n    Surface _763 = { _280.xyz, _280.w, _733, clamp(_253_fa_pbr.x * _351.z, 0.0f, 1.0f), clamp(_253_fa_pbr.y * _351.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_253_fa_maps.y * (_393.x - 1.0f)), _253_fa_emissive.xyz + (_253_fa_model_emissive.xyz * _423), _738, _739, _253_fa_layers_b.xyz, _741, _742, _253_fa_layers_a.w, _744, _253_fa_layers_c.y, _253_fa_layers_d.xyz };\n    return _763;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * _142_boost);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _644 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _644 = -_644;\n    }\n    float3 _556 = normalize(_253_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _657 = { fa_world_pos, _644, fa_world_tangent, fa_uv, fa_vertex_color, _556, gl_FrontFacing };\n    SurfaceInput param = _657;\n    SurfaceInput _665 = { fa_world_pos, _644, fa_world_tangent, fa_uv, fa_vertex_color, _556, gl_FrontFacing };\n    SurfaceInput param_1 = _665;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _571 = normalize(param_2.normal);\n    float3 _586 = normalize(float3(dot(fa_pre_r0, _571), dot(fa_pre_r1, _571), dot(fa_pre_r2, _571)));\n    float _598 = _586.z;\n    float2 e = _586.xy / ((abs(_586.x) + abs(_586.y)) + abs(_598)).xx;\n    if (_598 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_inst_v0 = stage_input.fa_inst_v0;\n    fa_inst_v1 = stage_input.fa_inst_v1;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "type": "vec4",
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
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_158",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_205",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_142",
            "hlsl_register_b_n": 5
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_253",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _144_fa_view_proj : packoffset(c0);\n    row_major float4x4 _144_fa_light_vp : packoffset(c4);\n    float4 _144_fa_uv_scale : packoffset(c8);\n    float4 _144_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_d0;\nstatic float4 fa_inst_d1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float3 fa_normal : TEXCOORD5;\n    float2 fa_texcoord0 : TEXCOORD6;\n    float4 fa_tangent : TEXCOORD7;\n    float4 fa_color : TEXCOORD8;\n    float4 fa_inst_d0 : TEXCOORD9;\n    float4 fa_inst_d1 : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 gl_Position : SV_Position;\n};\n\nstatic float raise;\nstatic float4 tint;\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _85 = cross(model[1].xyz, model[2].xyz);\n    float _91 = (dot(model[0].xyz, _85) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _282 = { mul(float4(position, 1.0f), model).xyz, (((_85 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _91, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _91), texcoord0 * _144_fa_uv_scale.xy, color, position };\n    return _282;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _144_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_d0 = stage_input.fa_inst_d0;\n    fa_inst_d1 = stage_input.fa_inst_d1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    return stage_output;\n}\n",
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
            "inst_name": "_144",
            "hlsl_register_b_n": 0
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _149_fa_view_proj : packoffset(c0);\n    row_major float4x4 _149_fa_light_vp : packoffset(c4);\n    float4 _149_fa_uv_scale : packoffset(c8);\n    float4 _149_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _196_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_d0;\nstatic float4 fa_inst_d1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float4 fa_joints : TEXCOORD5;\n    float4 fa_weights : TEXCOORD6;\n    float3 fa_normal : TEXCOORD7;\n    float2 fa_texcoord0 : TEXCOORD8;\n    float4 fa_tangent : TEXCOORD9;\n    float4 fa_color : TEXCOORD10;\n    float4 fa_inst_d0 : TEXCOORD11;\n    float4 fa_inst_d1 : TEXCOORD12;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 gl_Position : SV_Position;\n};\n\nstatic float raise;\nstatic float4 tint;\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _187 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_196_fa_joint_rows[_187] * weights[i]);\n        r1 += (_196_fa_joint_rows[_187 + 1] * weights[i]);\n        r2 += (_196_fa_joint_rows[_187 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _90 = cross(model[1].xyz, model[2].xyz);\n    float _96 = (dot(model[0].xyz, _90) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _402 = { mul(float4(position, 1.0f), model).xyz, (((_90 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _96, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _96), texcoord0 * _149_fa_uv_scale.xy, color, position };\n    return _402;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid vert_main()\n{\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    fa_inst_begin();\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    vertex(param_8);\n    gl_Position = mul(float4(param_8.world_pos, 1.0f), _149_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_d0 = stage_input.fa_inst_d0;\n    fa_inst_d1 = stage_input.fa_inst_d1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    return stage_output;\n}\n",
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
            "type": "vec4",
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
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_149",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_196",
            "hlsl_register_b_n": 3
          }
        ]
      }
    }
  }
}
