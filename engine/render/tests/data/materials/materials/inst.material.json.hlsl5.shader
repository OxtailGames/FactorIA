{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "5c278b25d8ce4341984c8bf2a53e1ca7890b6a924713889b53c089df056597d0",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _153_fa_view_proj : packoffset(c0);\n    row_major float4x4 _153_fa_light_vp : packoffset(c4);\n    float4 _153_fa_uv_scale : packoffset(c8);\n    float4 _153_fa_time : packoffset(c9);\n    float4 _153_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_d0;\nstatic float4 fa_inst_d1;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_inst_d0 : TEXCOORD9;\n    float4 fa_inst_d1 : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float3 fa_lm : TEXCOORD7;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float raise;\nstatic float4 tint;\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _100 = (dot(model[0].xyz, _94) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _302 = { mul(float4(position, 1.0f), model).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _100, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _100), texcoord0 * _153_fa_uv_scale.xy, color, position };\n    return _302;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _153_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_d0 = stage_input.fa_inst_d0;\n    fa_inst_d1 = stage_input.fa_inst_d1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_inst_v0 = fa_inst_v0;\n    stage_output.fa_inst_v1 = fa_inst_v1;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _2745[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _553_fa_camera_pos : packoffset(c0);\n    float4 _553_fa_ambient : packoffset(c1);\n    float4 _553_fa_base_color : packoffset(c2);\n    float4 _553_fa_emissive : packoffset(c3);\n    float4 _553_fa_model_emissive : packoffset(c4);\n    float4 _553_fa_pbr : packoffset(c5);\n    float4 _553_fa_maps : packoffset(c6);\n    float4 _553_fa_fog : packoffset(c7);\n    float4 _553_fa_fog_b : packoffset(c8);\n    float4 _553_fa_fog_c : packoffset(c9);\n    float4 _553_fa_counts : packoffset(c10);\n    float4 _553_fa_env_sky : packoffset(c11);\n    float4 _553_fa_env_horizon : packoffset(c12);\n    float4 _553_fa_time : packoffset(c13);\n    float4 _553_fa_cl_vpx : packoffset(c14);\n    float4 _553_fa_cl_vpy : packoffset(c15);\n    float4 _553_fa_cl_vpw : packoffset(c16);\n    float4 _553_fa_cl_fwd : packoffset(c17);\n    float4 _553_fa_cl_grid : packoffset(c18);\n    float4 _553_fa_cl_info : packoffset(c19);\n    float4 _553_fa_layers_a : packoffset(c20);\n    float4 _553_fa_layers_b : packoffset(c21);\n    float4 _553_fa_layers_c : packoffset(c22);\n    float4 _553_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _1293_fa_shadow_mat[4] : packoffset(c0);\n    float4 _1293_fa_shadow_rect[4] : packoffset(c16);\n    float4 _1293_fa_shadow_info[4] : packoffset(c20);\n    float4 _1293_fa_shadow_split : packoffset(c24);\n    float4 _1293_fa_shadow_cfg : packoffset(c25);\n    float4 _1293_fa_shadow_bias : packoffset(c26);\n    float4 _1293_fa_shadow_eye : packoffset(c27);\n    float4 _1293_fa_shadow_fwd : packoffset(c28);\n    float4 _1293_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _3681_boost : packoffset(c0);\n    float _3681_fa_pad0 : packoffset(c0.y);\n    float _3681_fa_pad1 : packoffset(c0.z);\n    float _3681_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_decal_tex : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t8);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float3 fa_lm : TEXCOORD7;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\nstatic float raise;\nstatic float4 tint;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _558 = _553_fa_cl_info.x < 0.0f;\n    bool _565;\n    if (!_558)\n    {\n        _565 = _553_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _565 = _558;\n    }\n    bool _573;\n    if (!_565)\n    {\n        _573 = _553_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _573 = _565;\n    }\n    bool _580;\n    if (!_573)\n    {\n        _580 = _553_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _580 = _573;\n    }\n    bool _587;\n    if (!_580)\n    {\n        _587 = _553_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _587 = _580;\n    }\n    if (_587)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _597 = float4(world_pos, 1.0f);\n    float _604 = dot(_553_fa_cl_vpw, _597);\n    if (!(_604 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _626 = float2(dot(_553_fa_cl_vpx, _597), dot(_553_fa_cl_vpy, _597)) / _604.xx;\n    int _630 = int(_553_fa_cl_grid.x);\n    int _634 = int(_553_fa_cl_grid.y);\n    int param = (int(_553_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_553_fa_cl_fwd.xyz, world_pos) + _553_fa_cl_fwd.w, _553_fa_cl_grid.w) / _553_fa_cl_grid.w) * _553_fa_cl_grid.z)), 0, int(_553_fa_cl_info.y) - 1) * _634) + clamp(int(floor(((_626.y * 0.5f) + 0.5f) * _553_fa_cl_grid.y)), 0, _634 - 1)) * _630)) + clamp(int(floor(((_626.x * 0.5f) + 0.5f) * _553_fa_cl_grid.x)), 0, _630 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _710 = fa_cluster_texel(param);\n    return int2(int(_710.x), int(_710.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_553_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3558 = fa_cluster_lookup(param);\n    fa_cl_slot = _3558.x;\n    fa_cl_local = _3558.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _3733 = fa_linear_to_srgb(param);\n        c = _3733;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _3741 = fa_srgb_to_linear(param_1);\n            c = _3741;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _309;\n    if (i.front_facing)\n    {\n        _309 = i.world_normal;\n    }\n    else\n    {\n        _309 = -i.world_normal;\n    }\n    float3 _333 = normalize(i.world_tangent.xyz - (_309 * dot(_309, i.world_tangent.xyz)));\n    float3 _360 = normalize(((_333 * m.x) + ((cross(_309, _333) * i.world_tangent.w) * m.y)) + (_309 * m.z));\n    float3 _363;\n    if (i.front_facing)\n    {\n        _363 = _360;\n    }\n    else\n    {\n        _363 = -_360;\n    }\n    return _363;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _553_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3772 = fa_tex_fix(param_2, param_3);\n    float4 _5071 = base_t;\n    _5071.x = _3772.x;\n    _5071.y = _3772.y;\n    _5071.z = _3772.z;\n    base_t = _5071;\n    float4 _3786 = (_5071 * _553_fa_base_color) * i.vertex_color;\n    float3 _4938 = i.world_normal;\n    if (_553_fa_maps.z > 0.5f)\n    {\n        float param_4 = _553_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3818 = fa_tex_fix(param_6, param_7);\n        float3 _3821 = (_3818 * 2.0f) - 1.0f.xxx;\n        float2 _3826 = _3821.xy * _553_fa_maps.x;\n        float3 _5079 = _3821;\n        _5079.x = _3826.x;\n        _5079.y = _3826.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5079;\n        _4938 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _553_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3855 = fa_tex_fix(param_12, param_13);\n    float4 _5082 = mrt;\n    _5082.x = _3855.x;\n    _5082.y = _3855.y;\n    _5082.z = _3855.z;\n    mrt = _5082;\n    float4 _3883 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _553_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _3883.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3895 = fa_tex_fix(param_16, param_17);\n    float param_18 = _553_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3925 = fa_tex_fix(param_20, param_21);\n    float _4943 = _553_fa_layers_a.x;\n    float _4944 = _553_fa_layers_a.y;\n    float _4947 = _553_fa_layers_a.z;\n    float _4946 = _553_fa_layers_b.w;\n    float _4949 = _553_fa_layers_c.x;\n    if (_553_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_553_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _4943 *= _3895.y;\n            _4944 *= _3895.z;\n            _4946 *= _3883.w;\n        }\n        if (_553_fa_layers_c.z > 1.5f)\n        {\n            _4947 *= mrt.x;\n            _4949 *= mrt.w;\n        }\n    }\n    Surface _4968 = { _3786.xyz, _3786.w, _4938, clamp(_553_fa_pbr.x * _3855.z, 0.0f, 1.0f), clamp(_553_fa_pbr.y * _3855.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_553_fa_maps.y * (_3895.x - 1.0f)), _553_fa_emissive.xyz + (_553_fa_model_emissive.xyz * _3925), _4943, _4944, _553_fa_layers_b.xyz, _4946, _4947, _553_fa_layers_a.w, _4949, _553_fa_layers_c.y, _553_fa_layers_d.xyz };\n    return _4968;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * _3681_boost);\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _791 = rect.zw - rect.xy;\n    float2 _795 = _791 * atlas;\n    float2 _799 = ddx * _795;\n    float2 _803 = ddy * _795;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _791), clamp(0.5f * log2(max(max(dot(_799, _799), dot(_803, _803)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _838 = _553_fa_counts.y < 0.5f;\n    bool _845;\n    if (!_838)\n    {\n        _845 = _553_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _845 = _838;\n    }\n    if (_845)\n    {\n        return;\n    }\n    float3 _851 = ddx(world_pos);\n    float3 _854 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _858 = fa_cluster_texel(param);\n    int _862 = int(_858.w);\n    if (_862 < 1)\n    {\n        return;\n    }\n    int _872 = int(_553_fa_counts.y + 0.5f);\n    int param_1 = _872;\n    float4 _876 = fa_light_texel(param_1);\n    float2 _879 = _876.yz;\n    int _883 = int(_876.w);\n    int param_2 = _872 + 1;\n    float4 _888 = fa_light_texel(param_2);\n    float _889 = _888.x;\n    int _895 = int(_553_fa_counts.w + 0.5f) - 1;\n    int _899 = int(_858.z);\n    float3 _1165;\n    for (int k = 0; k < _862; k++)\n    {\n        int _912 = _899 + k;\n        int param_3 = _883 + (_912 >> 2);\n        int _930 = (_872 + 2) + (int(fa_light_texel(param_3)[_912 & 3]) * 7);\n        int param_4 = _930 + 6;\n        float4 _935 = fa_light_texel(param_4);\n        if (((int(_935.w + 0.5f) >> _895) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _930;\n        float4 _950 = fa_light_texel(param_5);\n        int param_6 = _930 + 1;\n        float4 _955 = fa_light_texel(param_6);\n        int param_7 = _930 + 2;\n        float4 _960 = fa_light_texel(param_7);\n        float3 _963 = _950.xyz;\n        float _968 = dot(_963, world_pos) + _950.w;\n        float3 _970 = _955.xyz;\n        float _975 = dot(_970, world_pos) + _955.w;\n        float3 _977 = _960.xyz;\n        float _982 = dot(_977, world_pos) + _960.w;\n        bool _987 = abs(_968) > 0.5f;\n        bool _995;\n        if (!_987)\n        {\n            _995 = abs(_975) > 0.5f;\n        }\n        else\n        {\n            _995 = _987;\n        }\n        bool _1003;\n        if (!_995)\n        {\n            _1003 = abs(_982) > 0.5f;\n        }\n        else\n        {\n            _1003 = _995;\n        }\n        if (_1003)\n        {\n            continue;\n        }\n        float _1018 = clamp(dot(geo_normal, normalize(_977)) * _935.z, 0.0f, 1.0f);\n        if (_1018 <= 0.0f)\n        {\n            continue;\n        }\n        float _1038 = (clamp((0.5f - abs(_982)) * 10.0f, 0.0f, 1.0f) * _1018) * _935.x;\n        float2 _1046 = float2(_968 + 0.5f, 0.5f - _975);\n        float2 _1056 = float2(dot(_963, _851), dot(_970, _851));\n        float2 _1066 = float2(dot(_963, _854), dot(_970, _854));\n        int param_8 = _930 + 5;\n        float4 _1071 = fa_light_texel(param_8);\n        int param_9 = _930 + 3;\n        float4 _1076 = fa_light_texel(param_9);\n        int param_10 = _930 + 4;\n        float4 _1081 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1071.xyz;\n        bool _1091 = _1076.z > _1076.x;\n        if (_1091)\n        {\n            float4 param_11 = _1076;\n            float2 param_12 = _1046;\n            float2 param_13 = _879;\n            float2 param_14 = _1056;\n            float2 param_15 = _1066;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_889 > 0.5f) && (_889 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1117 = fa_dc_to_linear(param_16);\n                float4 _4994 = tx;\n                _4994.x = _1117.x;\n                _4994.y = _1117.y;\n                _4994.z = _1117.z;\n                tx = _4994;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1038 * tex_a) * _1071.w, 0.0f, 1.0f).xxx);\n        if (_1081.z > _1081.x)\n        {\n            float4 param_17 = _1081;\n            float2 param_18 = _1046;\n            float2 param_19 = _879;\n            float2 param_20 = _1056;\n            float2 param_21 = _1066;\n            float4 _1161 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_889 > 1.5f)\n            {\n                float3 param_22 = _1161.xyz;\n                float3 _1171 = fa_dc_to_srgb(param_22);\n                _1165 = _1171;\n            }\n            else\n            {\n                _1165 = _1161.xyz;\n            }\n            float3 _1181 = (_1165 * 2.0f) - 1.0f.xxx;\n            float2 _1186 = _1181.xy * _935.y;\n            float3 _1208 = (normalize(_963) * _1186.x) + (normalize(_970) * _1186.y);\n            float3 _1211 = normalize(normal);\n            normal = normalize(lerp(_1211, normalize((_1211 * max(_1181.z, 0.0500000007450580596923828125f)) + (_1208 - (_1211 * dot(_1211, _1208)))), clamp(_1038 * (_1091 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _2671 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _2678 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _2681 = int(_2671);\n    int _2684 = int(_2678);\n    float _2694 = _2678 - float(_2684);\n    int _2749 = (_2681 * 9) + _2684;\n    int _2769 = ((_2681 + 1) * 9) + _2684;\n    return lerp(lerp(_2745[_2749], _2745[_2749 + 1], _2694), lerp(_2745[_2769], _2745[_2769 + 1], _2694), _2671 - float(_2681));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _4861 = false;\n    float _4862 = 1.0f;\n    float _4863 = 1.0f;\n    float _4864 = 1.0f;\n    float _4865 = 0.0f;\n    float _4866 = 0.0f;\n    float _4867 = 0.0f;\n    float _4868 = 0.0f;\n    float _4870 = 1.0f;\n    bool _4871 = false;\n    float3 _4872 = 0.0f.xxx;\n    float _4873 = 1.0f;\n    float _4874 = 1.0f;\n    float _4875 = 1.0f;\n    float _4876 = 0.0f;\n    float _4877 = 0.0f;\n    float3 _4878 = float3(1.0f, 0.0f, 0.0f);\n    float3 _4879 = float3(0.0f, 0.0f, 1.0f);\n    float _4880 = 1.0f;\n    float _4881 = 1.0f;\n    float _2822 = clamp(s.specular, 0.0f, 1.0f);\n    float _2826 = clamp(s.ior, 1.0f, 3.0f);\n    bool _2831 = (_2822 != 1.0f) || (_2826 != 1.5f);\n    bool _2841;\n    if (!_2831)\n    {\n        _2841 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _2841 = _2831;\n    }\n    if (_2841)\n    {\n        float _2849 = (_2826 - 1.0f) / (_2826 + 1.0f);\n        f0 = lerp(min((_2849 * _2849).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _2822, s.albedo, metallic.xxx);\n        _4862 = lerp(_2822, 1.0f, metallic);\n        _4861 = true;\n    }\n    float _2877 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_2877 > 0.0f)\n    {\n        float _2885 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _4865 = _2877;\n        _4866 = _2885;\n        float _2892 = _2885 * _2885;\n        _4867 = _2892;\n        _4868 = _2892 * _2892;\n        float _2904 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _4870 = _2904;\n        _4863 = 1.0f - (_2877 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _2904, 0.0f, 1.0f), 5.0f))));\n        _4861 = true;\n    }\n    float3 _2923 = max(s.sheen_color, 0.0f.xxx);\n    float _2932 = max(_2923.x, max(_2923.y, _2923.z));\n    if (_2932 > 0.0f)\n    {\n        float _2940 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _4871 = true;\n        _4872 = _2923;\n        _4873 = _2940;\n        _4874 = _2940 * _2940;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _2940;\n        float _2957 = fa_sheen_albedo(param, param_1);\n        _4876 = _2957;\n        _4875 = 1.0f - min(_2932 * _2957, 1.0f);\n        _4861 = true;\n    }\n    _4864 = _4863 * _4875;\n    float _2976 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_2976 != 0.0f)\n    {\n        float3 _2991 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2991;\n        if (dot(_2991, _2991) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _3004 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_3004.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _3004.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _3004.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _3008 = t;\n        float3 _3009 = normalize(_3008);\n        t = _3009;\n        float3 _3034 = normalize((_3009 * cos(s.anisotropy_rotation)) + ((cross(n, _3009) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _4878 = _3034;\n        _4879 = cross(n, _3034);\n        float _3044 = roughness * roughness;\n        float _3050 = lerp(_3044, 1.0f, _2976 * _2976);\n        bool _3052 = _2976 > 0.0f;\n        _4880 = _3052 ? _3050 : _3044;\n        _4881 = _3052 ? _3044 : _3050;\n        _4877 = _2976;\n        _4861 = true;\n    }\n    FaLayers _4903 = { _4861, _4862, _4863, _4864, _4865, _4866, _4867, _4868, i.world_normal, _4870, _4871, _4872, _4873, _4874, _4875, _4876, _4877, _4878, _4879, _4880, _4881 };\n    return _4903;\n}\n\nfloat3 fa_sky_sh_coef(int k)\n{\n    float3 v = fa_env_tex.SampleLevel(fa_env_smp, float3(1.0f, 1.0f - (float((2 * (k >> 2)) + 1) * 0.25f), 1.0f - (float((2 * (k & 3)) + 1) * 0.25f)), 5.0f).xyz;\n    if (_553_fa_env_sky.w > 1.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _2428 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _2428;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_553_fa_env_sky.w > 0.5f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _553_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_553_fa_cl_info.x) + int(_553_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _427 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _433 = fa_light_texel(param_1);\n    float _436 = _433.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _442 = _436 < 0.5f;\n    float3 l;\n    if (_442)\n    {\n        l = normalize(_427.xyz);\n    }\n    else\n    {\n        float3 _454 = _427.xyz - world_pos;\n        float _456 = length(_454);\n        dist = _456;\n        l = _454 / max(_456, 9.9999997473787516355514526367188e-05f).xxx;\n        float _471 = _456 / max(_427.w, 0.001000000047497451305389404296875f);\n        float _477 = clamp(1.0f - (_471 * _471), 0.0f, 1.0f);\n        atten = _477 * _477;\n        if (_436 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _491 = fa_light_texel(param_2);\n            float _501 = _491.w;\n            int param_3 = (li * 4) + 3;\n            float4 _507 = fa_light_texel(param_3);\n            float _508 = _507.x;\n            float cos_inner = _508;\n            if (_508 > 1.5f)\n            {\n                cos_inner = lerp(_501, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_501, cos_inner, dot(-l, normalize(_491.xyz)));\n        }\n    }\n    int _539;\n    if (_442)\n    {\n        _539 = 0;\n    }\n    else\n    {\n        _539 = (_436 > 1.5f) ? 2 : 1;\n    }\n    LightSample _4860 = { l, _433.xyz * atten, atten, 1.0f, dist, _539 };\n    return _4860;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1283;\n    if (i == 0)\n    {\n        _1283 = _1293_fa_shadow_split.x;\n    }\n    else\n    {\n        float _1299;\n        if (i == 1)\n        {\n            _1299 = _1293_fa_shadow_split.y;\n        }\n        else\n        {\n            float _1307;\n            if (i == 2)\n            {\n                _1307 = _1293_fa_shadow_split.z;\n            }\n            else\n            {\n                _1307 = _1293_fa_shadow_split.w;\n            }\n            _1299 = _1307;\n        }\n        _1283 = _1299;\n    }\n    return _1283;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1340 = fa_shadow_depth(param, param_1);\n    float _1344;\n    if (conv.x < 0.5f)\n    {\n        _1344 = _1340;\n    }\n    else\n    {\n        _1344 = (conv.y * conv.z) / (conv.z - (_1340 * (conv.z - conv.y)));\n    }\n    return _1344;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1271 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_1271), sin(_1271)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1390 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _1404 = clamp((k * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1390;\n            float2 _1423 = fa_shadow_vogel(param_3, param_4, param_5) * _1404;\n            float2 param_6 = uv + (_1423 * _1293_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1435 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1435 < (zr - (length(_1423) * plane)))\n            {\n                sum += _1435;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0f) * unit) * k) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _1479 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1479; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1479;\n        float param_11 = _1390;\n        float2 _1498 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1498 * _1293_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1498) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1479);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _1540 = max(_1293_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _1545 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1551 = sqrt(1.0f - (_1545 * _1545));\n    float _1558 = min(_1551 / max(_1545, 0.20000000298023223876953125f), 4.0f);\n    float _1563;\n    if (_1293_fa_shadow_bias.y > 0.0f)\n    {\n        _1563 = _1293_fa_shadow_bias.y;\n    }\n    else\n    {\n        _1563 = 1.5f * _1293_fa_shadow_info[ci].x;\n    }\n    float4 _1588 = mul(float4(world + (n * (_1563 * _1551)), 1.0f), _1293_fa_shadow_mat[ci]);\n    float _1595 = _1588.x;\n    bool _1598 = _1595 < _1293_fa_shadow_rect[ci].x;\n    bool _1607;\n    if (!_1598)\n    {\n        _1607 = _1595 > _1293_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1607 = _1598;\n    }\n    bool _1616;\n    if (!_1607)\n    {\n        _1616 = _1588.y < _1293_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1616 = _1607;\n    }\n    bool _1625;\n    if (!_1616)\n    {\n        _1625 = _1588.y > _1293_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1625 = _1616;\n    }\n    bool _1632;\n    if (!_1625)\n    {\n        _1632 = _1588.z > 1.0f;\n    }\n    else\n    {\n        _1632 = _1625;\n    }\n    if (_1632)\n    {\n        return -1.0f;\n    }\n    float _1641;\n    if (_1293_fa_shadow_bias.x > 0.0f)\n    {\n        _1641 = _1293_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1641 = 1.5f * _1293_fa_shadow_info[ci].x;\n    }\n    float2 param = _1588.xy;\n    float4 param_1 = _1293_fa_shadow_rect[ci];\n    float param_2 = _1588.z - ((_1641 * (1.0f + (0.5f * _1558))) / _1540);\n    float param_3 = _1293_fa_shadow_info[ci].x;\n    float param_4 = _1540;\n    float param_5 = _1540 * 0.25f;\n    float param_6 = ((_1293_fa_shadow_info[ci].x * min(_1558, 3.0f)) * 0.5f) / _1540;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_1293_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _1293_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_553_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2068 = int(_1293_fa_shadow_cfg.x + 0.5f);\n    if (_2068 < 1)\n    {\n        return 1.0f;\n    }\n    float _2083 = dot(world - _1293_fa_shadow_eye.xyz, _1293_fa_shadow_fwd.xyz);\n    int param = _2068 - 1;\n    if (_2083 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2095 = _2068 > 1;\n    bool _2102;\n    if (_2095)\n    {\n        _2102 = _2083 > _1293_fa_shadow_split.x;\n    }\n    else\n    {\n        _2102 = _2095;\n    }\n    if (_2102)\n    {\n        ci = 1;\n    }\n    bool _2106 = _2068 > 2;\n    bool _2113;\n    if (_2106)\n    {\n        _2113 = _2083 > _1293_fa_shadow_split.y;\n    }\n    else\n    {\n        _2113 = _2106;\n    }\n    if (_2113)\n    {\n        ci = 2;\n    }\n    bool _2117 = _2068 > 3;\n    bool _2124;\n    if (_2117)\n    {\n        _2124 = _2083 > _1293_fa_shadow_split.z;\n    }\n    else\n    {\n        _2124 = _2117;\n    }\n    if (_2124)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2068)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2150 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2150;\n        if (_2150 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_1293_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2175;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2175 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2175 = _1293_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2194 = _1293_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2175, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2205 = clamp((_2083 - (fa_shadow_split_at(param_7) - _2194)) / _2194, 0.0f, 1.0f);\n        if (_2205 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2068)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2226 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2226;\n                if (_2226 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2205);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _1699 = _553_fa_pbr.z < 0.5f;\n    bool _1707;\n    if (!_1699)\n    {\n        _1707 = _1293_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _1707 = _1699;\n    }\n    if (_1707)\n    {\n        return 1.0f;\n    }\n    int param = (int(_1293_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _1720 = fa_light_texel(param);\n    float _1721 = _1720.x;\n    if (_1721 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _1730 = int(_1721 + 0.5f);\n    int param_1 = _1730;\n    float4 _1734 = fa_light_texel(param_1);\n    int param_2 = _1730 + 1;\n    float4 _1739 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _1742 = _1734.y;\n    if (_1742 > 0.0f)\n    {\n        float _1759 = 1.0f - smoothstep(0.75f * _1742, _1742, length(world - _1293_fa_shadow_eye.xyz));\n        fade = _1759;\n        if (_1759 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_1734.x > 1.5f)\n    {\n        int param_3 = li * 4;\n        float3 _1778 = world - fa_light_texel(param_3).xyz;\n        float3 _1781 = abs(_1778);\n        float _1783 = _1781.x;\n        float _1785 = _1781.y;\n        bool _1786 = _1783 >= _1785;\n        bool _1794;\n        if (_1786)\n        {\n            _1794 = _1783 >= _1781.z;\n        }\n        else\n        {\n            _1794 = _1786;\n        }\n        int _1795;\n        if (_1794)\n        {\n            _1795 = (_1778.x > 0.0f) ? 0 : 1;\n        }\n        else\n        {\n            int _1808;\n            if (_1785 >= _1781.z)\n            {\n                _1808 = (_1778.y > 0.0f) ? 2 : 3;\n            }\n            else\n            {\n                _1808 = (_1778.z > 0.0f) ? 4 : 5;\n            }\n            _1795 = _1808;\n        }\n        face = _1795;\n    }\n    int _1827 = (_1730 + 2) + (face * 6);\n    int param_4 = _1827;\n    int param_5 = _1827 + 1;\n    int param_6 = _1827 + 3;\n    float4 _1841 = fa_light_texel(param_6);\n    int param_7 = _1827 + 4;\n    float4 _1846 = fa_light_texel(param_7);\n    int param_8 = _1827 + 5;\n    float4 _1851 = fa_light_texel(param_8);\n    float _1863 = _1851.x * max(dot(_1841, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _1868 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1891 = clamp(dot(n, _1841.xyz), -1.0f, 1.0f);\n    int param_9 = li * 4;\n    float _1914 = min(sqrt(1.0f - (_1891 * _1891)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1841, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _1917 = _1739.y;\n    float _1919;\n    if (_1917 > 0.0f)\n    {\n        _1919 = _1917;\n    }\n    else\n    {\n        _1919 = 1.5f * _1863;\n    }\n    float4 _1939 = float4(world + (n * (_1919 * sqrt(1.0f - (_1868 * _1868)))), 1.0f);\n    float _1943 = dot(_1841, _1939);\n    float _1946 = _1851.y;\n    if (_1943 < _1946)\n    {\n        return 1.0f;\n    }\n    float2 _1961 = float2(dot(fa_light_texel(param_4), _1939), dot(fa_light_texel(param_5), _1939)) / _1943.xx;\n    float _1963 = _1961.x;\n    bool _1966 = _1963 < _1846.x;\n    bool _1975;\n    if (!_1966)\n    {\n        _1975 = _1963 > _1846.z;\n    }\n    else\n    {\n        _1975 = _1966;\n    }\n    bool _1984;\n    if (!_1975)\n    {\n        _1984 = _1961.y < _1846.y;\n    }\n    else\n    {\n        _1984 = _1975;\n    }\n    bool _1993;\n    if (!_1984)\n    {\n        _1993 = _1961.y > _1846.w;\n    }\n    else\n    {\n        _1993 = _1984;\n    }\n    if (_1993)\n    {\n        return 1.0f;\n    }\n    float _1999 = _1739.x;\n    float _2001;\n    if (_1999 > 0.0f)\n    {\n        _2001 = _1999;\n    }\n    else\n    {\n        _2001 = 1.5f * _1863;\n    }\n    float2 param_10 = _1961;\n    float4 param_11 = _1846;\n    float param_12 = _1943 - (_2001 * (1.0f + (0.5f * _1914)));\n    float param_13 = _1863;\n    float param_14 = 1.0f;\n    float param_15 = _1851.z * 0.25f;\n    float param_16 = (_1863 * min(_1914, 3.0f)) * 0.5f;\n    float3 param_17 = float3(1.0f, _1946, _1851.z);\n    int param_18 = int(_1734.z + 0.5f);\n    float param_19 = _1734.w;\n    return lerp(1.0f, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _3585 = fa_lm.z > 0.5f;\n    bool _3591;\n    if (_3585)\n    {\n        int param = li;\n        _3591 = fa_light_baked(param);\n    }\n    else\n    {\n        _3591 = _3585;\n    }\n    if (_3591)\n    {\n        int param_1 = li;\n        LightSample _4916 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _4916;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _3613 = fa_light_sample(param_2, param_3);\n    float3 _4923 = _3613.direction;\n    float3 _4918 = _3613.color;\n    float _4925 = _3613.attenuation;\n    float _4920 = _3613.shadow;\n    int _4928 = _3613.type;\n    if ((_4928 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _4923;\n        float _3627 = fa_shadow_factor(param_4, param_5);\n        _4920 = _3627;\n        _4918 *= _3627;\n    }\n    else\n    {\n        bool _3638 = _4928 != 0;\n        bool _3644;\n        if (_3638)\n        {\n            _3644 = _4925 > 0.0f;\n        }\n        else\n        {\n            _3644 = _3638;\n        }\n        if (_3644)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _4923;\n            float _3656 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _4920 = _3656;\n            _4918 *= _3656;\n        }\n    }\n    LightSample _4935 = { _4923, _4918, _4925, _4920, _3613._distance, _4928 };\n    return _4935;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _3202 = tdh / at;\n    float _3206 = bdh / ab;\n    float _3218 = ((_3202 * _3202) + (_3206 * _3206)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _3218) * _3218);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _3299 = 1.0f / alpha;\n    return ((2.0f + _3299) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _3299)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _3331 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _3410 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _3410) * _3410);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _3331);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _3331));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        float _3483 = max(dot(L.nc, l), 0.0f);\n        float _3489 = max(dot(L.nc, h), 0.0f);\n        float _3498 = ((_3489 * _3489) * (L.coat_a2 - 1.0f)) + 1.0f;\n        result += ((((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _3498) * _3498)) * (0.5f / max(lerp((2.0f * _3483) * L.coat_ndv, _3483 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _3483)) * _3483).xxx;\n    }\n    return result;\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _2603 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _2606 = _2603.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_2606 * _2606, exp2((-9.27999973297119140625f) * ndv)) * _2606) + _2603.y)) + _2603.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_553_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _553_fa_env_horizon.w).xyz;\n    }\n    float _2457 = rough * rough;\n    float _2487 = 0.60000002384185791015625f * _2457;\n    return lerp(lerp(_553_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_553_fa_env_horizon.xyz, _553_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _2457)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _2487, 0.0500000007450580596923828125f + _2487, d.y).xxx), ((_553_fa_env_sky.xyz + _553_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_2457 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _3085;\n        if (L.aniso >= 0.0f)\n        {\n            _3085 = L.b;\n        }\n        else\n        {\n            _3085 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_3085, v), _3085), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3118 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _3118.x) + (L.f90.xxx * _3118.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3173 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _3173.x) + _3173.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _2645 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _2645.x) + _2645.y.xxx);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_1293_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _2250 = int(_1293_fa_shadow_cfg.x + 0.5f);\n    float _2260 = dot(world - _1293_fa_shadow_eye.xyz, _1293_fa_shadow_fwd.xyz);\n    float3 tint_1 = 0.3499999940395355224609375f.xxx;\n    bool _2265 = _2250 > 0;\n    bool _2274;\n    if (_2265)\n    {\n        int param = _2250 - 1;\n        _2274 = _2260 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2274 = _2265;\n    }\n    if (_2274)\n    {\n        tint_1 = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _2281 = _2250 > 1;\n        bool _2288;\n        if (_2281)\n        {\n            _2288 = _2260 > _1293_fa_shadow_split.x;\n        }\n        else\n        {\n            _2288 = _2281;\n        }\n        if (_2288)\n        {\n            tint_1 = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _2294 = _2250 > 2;\n        bool _2301;\n        if (_2294)\n        {\n            _2301 = _2260 > _1293_fa_shadow_split.y;\n        }\n        else\n        {\n            _2301 = _2294;\n        }\n        if (_2301)\n        {\n            tint_1 = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _2307 = _2250 > 3;\n        bool _2314;\n        if (_2307)\n        {\n            _2314 = _2260 > _1293_fa_shadow_split.z;\n        }\n        else\n        {\n            _2314 = _2307;\n        }\n        if (_2314)\n        {\n            tint_1 = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint_1, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _4640 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4640 = -_4640;\n    }\n    float3 _4065 = normalize(_553_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _4653 = { fa_world_pos, _4640, fa_world_tangent, fa_uv, fa_vertex_color, _4065, gl_FrontFacing };\n    SurfaceInput param_1 = _4653;\n    Surface _4073 = fa_standard_surface(param_1);\n    float3 _4671 = _4073.albedo;\n    float _4672 = _4073.alpha;\n    float3 _4673 = _4073.normal;\n    float _4674 = _4073.metallic;\n    float _4675 = _4073.roughness;\n    float _4676 = _4073.occlusion;\n    float3 _4677 = _4073.emission;\n    float _4678 = _4073.clearcoat;\n    float _4679 = _4073.clearcoat_roughness;\n    float3 _4680 = _4073.sheen_color;\n    float _4681 = _4073.sheen_roughness;\n    float _4682 = _4073.anisotropy;\n    float _4683 = _4073.anisotropy_rotation;\n    float _4684 = _4073.specular;\n    float _4685 = _4073.ior;\n    float3 _4686 = _4073.specular_color;\n    SurfaceInput _4661 = { fa_world_pos, _4640, fa_world_tangent, fa_uv, fa_vertex_color, _4065, gl_FrontFacing };\n    SurfaceInput param_2 = _4661;\n    Surface param_3 = _4073;\n    surface(param_2, param_3);\n    _4671 = param_3.albedo;\n    _4672 = param_3.alpha;\n    _4673 = param_3.normal;\n    _4674 = param_3.metallic;\n    _4675 = param_3.roughness;\n    _4676 = param_3.occlusion;\n    _4677 = param_3.emission;\n    _4678 = param_3.clearcoat;\n    _4679 = param_3.clearcoat_roughness;\n    _4680 = param_3.sheen_color;\n    _4681 = param_3.sheen_roughness;\n    _4682 = param_3.anisotropy;\n    _4683 = param_3.anisotropy_rotation;\n    _4684 = param_3.specular;\n    _4685 = param_3.ior;\n    _4686 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _4640;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4671 = param_6;\n    _4673 = param_7;\n    float3 result;\n    if (_553_fa_emissive.w > 0.5f)\n    {\n        result = _4671;\n    }\n    else\n    {\n        float3 _4112 = normalize(_4673);\n        float _4119 = clamp(_4674, 0.0f, 1.0f);\n        float _4123 = clamp(_4675, 0.0500000007450580596923828125f, 1.0f);\n        float _4127 = _4123 * _4123;\n        float _4131 = _4127 * _4127;\n        float _4136 = max(dot(_4112, _4065), 9.9999997473787516355514526367188e-05f);\n        float3 _4142 = _4671 * (1.0f - _4119);\n        float3 _4149 = lerp(0.039999999105930328369140625f.xxx, _4671, _4119.xxx);\n        float3 f0 = _4149;\n        SurfaceInput _4669 = { fa_world_pos, _4640, fa_world_tangent, fa_uv, fa_vertex_color, _4065, gl_FrontFacing };\n        SurfaceInput param_8 = _4669;\n        Surface _4752 = { _4671, _4672, _4673, _4674, _4675, _4676, _4677, _4678, _4679, _4680, _4681, _4682, _4683, _4684, _4685, _4686 };\n        Surface param_9 = _4752;\n        float3 param_10 = _4112;\n        float3 param_11 = _4065;\n        float param_12 = _4119;\n        float param_13 = _4123;\n        float3 param_14 = _4149;\n        FaLayers _4165 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _4112;\n        float3 lit = (fa_indirect_diffuse(param_15) * _4142) * _4676;\n        if (_4165.on)\n        {\n            lit *= _4165.base_scale;\n        }\n        int _4187 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4187; ln++)\n        {\n            int param_16 = ln;\n            int _4200 = fa_cl_light(param_16);\n            bool _4203 = fa_lm.z > 0.5f;\n            bool _4209;\n            if (_4203)\n            {\n                int param_17 = _4200;\n                _4209 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _4209 = _4203;\n            }\n            if (_4209)\n            {\n                continue;\n            }\n            int param_18 = _4200;\n            float3 param_19 = fa_world_pos;\n            float3 param_20 = _4640;\n            LightSample _4221 = fa_light_shadowed(param_18, param_19, param_20);\n            float3 _4845 = _4221.direction;\n            float _4229 = max(dot(_4112, _4845), 0.0f);\n            float _4235 = _4221.attenuation * _4221.shadow;\n            float3 _4240 = normalize(_4845 + _4065);\n            float _4245 = max(dot(_4112, _4240), 0.0f);\n            float _4250 = max(dot(_4065, _4240), 0.0f);\n            if (_4165.on)\n            {\n                FaLayers param_21 = _4165;\n                float3 param_22 = _4142;\n                float3 param_23 = f0;\n                float3 param_24 = _4112;\n                float3 param_25 = _4065;\n                float3 param_26 = _4845;\n                float3 param_27 = _4240;\n                float param_28 = _4229;\n                float param_29 = _4136;\n                float param_30 = _4245;\n                float param_31 = _4250;\n                float param_32 = _4127;\n                float param_33 = _4131;\n                int param_34 = _4200;\n                lit += (fa_layers_light(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30, param_31, param_32, param_33) * (fa_light_rgb(param_34) * _4235));\n            }\n            else\n            {\n                float _4298 = ((_4245 * _4245) * (_4131 - 1.0f)) + 1.0f;\n                int param_35 = _4200;\n                lit += (((_4142 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _4250, 5.0f))) * (((_4131 / ((3.1415927410125732421875f * _4298) * _4298)) * (0.5f / max(lerp((2.0f * _4229) * _4136, _4229 + _4136, _4127), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _4229))) * fa_light_rgb(param_35)) * (_4229 * _4235));\n            }\n        }\n        if (_4165.on)\n        {\n            FaLayers param_36 = _4165;\n            float3 param_37 = _4112;\n            float3 param_38 = _4065;\n            float3 param_39 = f0;\n            float param_40 = _4123;\n            lit += (fa_layers_ibl(param_36, param_37, param_38, param_39, param_40) * _4676);\n        }\n        else\n        {\n            float3 param_41 = _4112;\n            float3 param_42 = _4065;\n            float3 param_43 = f0;\n            float param_44 = _4123;\n            lit += (fa_sky_reflection(param_41, param_42, param_43, param_44) * _4676);\n        }\n        result = lit;\n    }\n    float3 _4391 = result;\n    float3 _4392 = _4391 + _4677;\n    result = _4392;\n    float3 param_45 = _4392;\n    float3 param_46 = fa_world_pos;\n    result = fa_shadow_debug(param_45, param_46);\n    bool _4401 = _553_fa_fog.w > 0.0f;\n    bool _4408;\n    if (!_4401)\n    {\n        _4408 = _553_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _4408 = _4401;\n    }\n    if (_4408)\n    {\n        float3 _4417 = fa_world_pos - _553_fa_camera_pos.xyz;\n        float _4423 = dot(_4417, _553_fa_fog_c.xyz);\n        bool _4427 = _553_fa_fog_c.w > 0.5f;\n        float _4428;\n        if (_4427)\n        {\n            _4428 = _4423;\n        }\n        else\n        {\n            _4428 = length(_4417);\n        }\n        float _4440 = _4428 - _553_fa_fog_b.x;\n        if (_4440 > 0.0f)\n        {\n            float _4449 = _553_fa_fog.w * _4440;\n            float tau = _4449 * _4449;\n            if (_553_fa_fog_b.y > 0.0f)\n            {\n                float _4465;\n                if (_4427)\n                {\n                    _4465 = fa_world_pos.y - (_553_fa_fog_c.y * _4423);\n                }\n                else\n                {\n                    _4465 = _553_fa_camera_pos.y;\n                }\n                float _4486 = lerp(_4465, fa_world_pos.y, clamp(_553_fa_fog_b.x / _4428, 0.0f, 1.0f));\n                float _4490 = fa_world_pos.y - _4486;\n                float _4495 = _4486 - _553_fa_fog_b.z;\n                float _4500 = fa_world_pos.y - _553_fa_fog_b.z;\n                bool _4503 = _4495 <= 0.0f;\n                bool _4504 = !_4503;\n                bool _4510;\n                if (_4504)\n                {\n                    _4510 = _553_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4510 = _4503;\n                }\n                float _4511;\n                if (_4510)\n                {\n                    _4511 = _553_fa_fog_b.y;\n                }\n                else\n                {\n                    _4511 = _553_fa_fog_b.y * exp(-min(_553_fa_fog_b.w * _4495, 80.0f));\n                }\n                bool _4538;\n                if (_4504)\n                {\n                    _4538 = _553_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4538 = _4503;\n                }\n                float _4539;\n                if (_4538)\n                {\n                    _4539 = _553_fa_fog_b.y * _4495;\n                }\n                else\n                {\n                    _4539 = (_553_fa_fog_b.y * (1.0f - exp(-min(_553_fa_fog_b.w * _4495, 80.0f)))) / _553_fa_fog_b.w;\n                }\n                bool _4564 = _4500 <= 0.0f;\n                bool _4571;\n                if (!_4564)\n                {\n                    _4571 = _553_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4571 = _4564;\n                }\n                float _4572;\n                if (_4571)\n                {\n                    _4572 = _553_fa_fog_b.y * _4500;\n                }\n                else\n                {\n                    _4572 = (_553_fa_fog_b.y * (1.0f - exp(-min(_553_fa_fog_b.w * _4500, 80.0f)))) / _553_fa_fog_b.w;\n                }\n                float _4599;\n                if (abs(_4490) < 0.001000000047497451305389404296875f)\n                {\n                    _4599 = _4511;\n                }\n                else\n                {\n                    _4599 = (_4572 - _4539) / _4490;\n                }\n                tau += (_4440 * max(_4599, 0.0f));\n            }\n            result = lerp(result, _553_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4672);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_inst_v0 = stage_input.fa_inst_v0;\n    fa_inst_v1 = stage_input.fa_inst_v1;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_153",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_553",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1293",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_3681",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _158_fa_view_proj : packoffset(c0);\n    row_major float4x4 _158_fa_light_vp : packoffset(c4);\n    float4 _158_fa_uv_scale : packoffset(c8);\n    float4 _158_fa_time : packoffset(c9);\n    float4 _158_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _205_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_d0;\nstatic float4 fa_inst_d1;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n    float4 fa_inst_d0 : TEXCOORD11;\n    float4 fa_inst_d1 : TEXCOORD12;\n};\n\nstruct SPIRV_Cross_Output\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float3 fa_lm : TEXCOORD7;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float raise;\nstatic float4 tint;\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_205_fa_joint_rows[_196] * weights[i]);\n        r1 += (_205_fa_joint_rows[_196 + 1] * weights[i]);\n        r2 += (_205_fa_joint_rows[_196 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _422 = { mul(float4(position, 1.0f), model).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * _158_fa_uv_scale.xy, color, position };\n    return _422;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _158_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_d0 = stage_input.fa_inst_d0;\n    fa_inst_d1 = stage_input.fa_inst_d1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_inst_v0 = fa_inst_v0;\n    stage_output.fa_inst_v1 = fa_inst_v1;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _2745[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _553_fa_camera_pos : packoffset(c0);\n    float4 _553_fa_ambient : packoffset(c1);\n    float4 _553_fa_base_color : packoffset(c2);\n    float4 _553_fa_emissive : packoffset(c3);\n    float4 _553_fa_model_emissive : packoffset(c4);\n    float4 _553_fa_pbr : packoffset(c5);\n    float4 _553_fa_maps : packoffset(c6);\n    float4 _553_fa_fog : packoffset(c7);\n    float4 _553_fa_fog_b : packoffset(c8);\n    float4 _553_fa_fog_c : packoffset(c9);\n    float4 _553_fa_counts : packoffset(c10);\n    float4 _553_fa_env_sky : packoffset(c11);\n    float4 _553_fa_env_horizon : packoffset(c12);\n    float4 _553_fa_time : packoffset(c13);\n    float4 _553_fa_cl_vpx : packoffset(c14);\n    float4 _553_fa_cl_vpy : packoffset(c15);\n    float4 _553_fa_cl_vpw : packoffset(c16);\n    float4 _553_fa_cl_fwd : packoffset(c17);\n    float4 _553_fa_cl_grid : packoffset(c18);\n    float4 _553_fa_cl_info : packoffset(c19);\n    float4 _553_fa_layers_a : packoffset(c20);\n    float4 _553_fa_layers_b : packoffset(c21);\n    float4 _553_fa_layers_c : packoffset(c22);\n    float4 _553_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _1293_fa_shadow_mat[4] : packoffset(c0);\n    float4 _1293_fa_shadow_rect[4] : packoffset(c16);\n    float4 _1293_fa_shadow_info[4] : packoffset(c20);\n    float4 _1293_fa_shadow_split : packoffset(c24);\n    float4 _1293_fa_shadow_cfg : packoffset(c25);\n    float4 _1293_fa_shadow_bias : packoffset(c26);\n    float4 _1293_fa_shadow_eye : packoffset(c27);\n    float4 _1293_fa_shadow_fwd : packoffset(c28);\n    float4 _1293_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _3681_boost : packoffset(c0);\n    float _3681_fa_pad0 : packoffset(c0.y);\n    float _3681_fa_pad1 : packoffset(c0.z);\n    float _3681_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_decal_tex : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t8);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float3 fa_lm : TEXCOORD7;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\nstatic float raise;\nstatic float4 tint;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _558 = _553_fa_cl_info.x < 0.0f;\n    bool _565;\n    if (!_558)\n    {\n        _565 = _553_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _565 = _558;\n    }\n    bool _573;\n    if (!_565)\n    {\n        _573 = _553_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _573 = _565;\n    }\n    bool _580;\n    if (!_573)\n    {\n        _580 = _553_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _580 = _573;\n    }\n    bool _587;\n    if (!_580)\n    {\n        _587 = _553_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _587 = _580;\n    }\n    if (_587)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _597 = float4(world_pos, 1.0f);\n    float _604 = dot(_553_fa_cl_vpw, _597);\n    if (!(_604 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _626 = float2(dot(_553_fa_cl_vpx, _597), dot(_553_fa_cl_vpy, _597)) / _604.xx;\n    int _630 = int(_553_fa_cl_grid.x);\n    int _634 = int(_553_fa_cl_grid.y);\n    int param = (int(_553_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_553_fa_cl_fwd.xyz, world_pos) + _553_fa_cl_fwd.w, _553_fa_cl_grid.w) / _553_fa_cl_grid.w) * _553_fa_cl_grid.z)), 0, int(_553_fa_cl_info.y) - 1) * _634) + clamp(int(floor(((_626.y * 0.5f) + 0.5f) * _553_fa_cl_grid.y)), 0, _634 - 1)) * _630)) + clamp(int(floor(((_626.x * 0.5f) + 0.5f) * _553_fa_cl_grid.x)), 0, _630 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _710 = fa_cluster_texel(param);\n    return int2(int(_710.x), int(_710.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_553_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3558 = fa_cluster_lookup(param);\n    fa_cl_slot = _3558.x;\n    fa_cl_local = _3558.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _3733 = fa_linear_to_srgb(param);\n        c = _3733;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _3741 = fa_srgb_to_linear(param_1);\n            c = _3741;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _309;\n    if (i.front_facing)\n    {\n        _309 = i.world_normal;\n    }\n    else\n    {\n        _309 = -i.world_normal;\n    }\n    float3 _333 = normalize(i.world_tangent.xyz - (_309 * dot(_309, i.world_tangent.xyz)));\n    float3 _360 = normalize(((_333 * m.x) + ((cross(_309, _333) * i.world_tangent.w) * m.y)) + (_309 * m.z));\n    float3 _363;\n    if (i.front_facing)\n    {\n        _363 = _360;\n    }\n    else\n    {\n        _363 = -_360;\n    }\n    return _363;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _553_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3772 = fa_tex_fix(param_2, param_3);\n    float4 _5071 = base_t;\n    _5071.x = _3772.x;\n    _5071.y = _3772.y;\n    _5071.z = _3772.z;\n    base_t = _5071;\n    float4 _3786 = (_5071 * _553_fa_base_color) * i.vertex_color;\n    float3 _4938 = i.world_normal;\n    if (_553_fa_maps.z > 0.5f)\n    {\n        float param_4 = _553_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3818 = fa_tex_fix(param_6, param_7);\n        float3 _3821 = (_3818 * 2.0f) - 1.0f.xxx;\n        float2 _3826 = _3821.xy * _553_fa_maps.x;\n        float3 _5079 = _3821;\n        _5079.x = _3826.x;\n        _5079.y = _3826.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5079;\n        _4938 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _553_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3855 = fa_tex_fix(param_12, param_13);\n    float4 _5082 = mrt;\n    _5082.x = _3855.x;\n    _5082.y = _3855.y;\n    _5082.z = _3855.z;\n    mrt = _5082;\n    float4 _3883 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _553_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _3883.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3895 = fa_tex_fix(param_16, param_17);\n    float param_18 = _553_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3925 = fa_tex_fix(param_20, param_21);\n    float _4943 = _553_fa_layers_a.x;\n    float _4944 = _553_fa_layers_a.y;\n    float _4947 = _553_fa_layers_a.z;\n    float _4946 = _553_fa_layers_b.w;\n    float _4949 = _553_fa_layers_c.x;\n    if (_553_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_553_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _4943 *= _3895.y;\n            _4944 *= _3895.z;\n            _4946 *= _3883.w;\n        }\n        if (_553_fa_layers_c.z > 1.5f)\n        {\n            _4947 *= mrt.x;\n            _4949 *= mrt.w;\n        }\n    }\n    Surface _4968 = { _3786.xyz, _3786.w, _4938, clamp(_553_fa_pbr.x * _3855.z, 0.0f, 1.0f), clamp(_553_fa_pbr.y * _3855.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_553_fa_maps.y * (_3895.x - 1.0f)), _553_fa_emissive.xyz + (_553_fa_model_emissive.xyz * _3925), _4943, _4944, _553_fa_layers_b.xyz, _4946, _4947, _553_fa_layers_a.w, _4949, _553_fa_layers_c.y, _553_fa_layers_d.xyz };\n    return _4968;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * _3681_boost);\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _791 = rect.zw - rect.xy;\n    float2 _795 = _791 * atlas;\n    float2 _799 = ddx * _795;\n    float2 _803 = ddy * _795;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _791), clamp(0.5f * log2(max(max(dot(_799, _799), dot(_803, _803)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _838 = _553_fa_counts.y < 0.5f;\n    bool _845;\n    if (!_838)\n    {\n        _845 = _553_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _845 = _838;\n    }\n    if (_845)\n    {\n        return;\n    }\n    float3 _851 = ddx(world_pos);\n    float3 _854 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _858 = fa_cluster_texel(param);\n    int _862 = int(_858.w);\n    if (_862 < 1)\n    {\n        return;\n    }\n    int _872 = int(_553_fa_counts.y + 0.5f);\n    int param_1 = _872;\n    float4 _876 = fa_light_texel(param_1);\n    float2 _879 = _876.yz;\n    int _883 = int(_876.w);\n    int param_2 = _872 + 1;\n    float4 _888 = fa_light_texel(param_2);\n    float _889 = _888.x;\n    int _895 = int(_553_fa_counts.w + 0.5f) - 1;\n    int _899 = int(_858.z);\n    float3 _1165;\n    for (int k = 0; k < _862; k++)\n    {\n        int _912 = _899 + k;\n        int param_3 = _883 + (_912 >> 2);\n        int _930 = (_872 + 2) + (int(fa_light_texel(param_3)[_912 & 3]) * 7);\n        int param_4 = _930 + 6;\n        float4 _935 = fa_light_texel(param_4);\n        if (((int(_935.w + 0.5f) >> _895) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _930;\n        float4 _950 = fa_light_texel(param_5);\n        int param_6 = _930 + 1;\n        float4 _955 = fa_light_texel(param_6);\n        int param_7 = _930 + 2;\n        float4 _960 = fa_light_texel(param_7);\n        float3 _963 = _950.xyz;\n        float _968 = dot(_963, world_pos) + _950.w;\n        float3 _970 = _955.xyz;\n        float _975 = dot(_970, world_pos) + _955.w;\n        float3 _977 = _960.xyz;\n        float _982 = dot(_977, world_pos) + _960.w;\n        bool _987 = abs(_968) > 0.5f;\n        bool _995;\n        if (!_987)\n        {\n            _995 = abs(_975) > 0.5f;\n        }\n        else\n        {\n            _995 = _987;\n        }\n        bool _1003;\n        if (!_995)\n        {\n            _1003 = abs(_982) > 0.5f;\n        }\n        else\n        {\n            _1003 = _995;\n        }\n        if (_1003)\n        {\n            continue;\n        }\n        float _1018 = clamp(dot(geo_normal, normalize(_977)) * _935.z, 0.0f, 1.0f);\n        if (_1018 <= 0.0f)\n        {\n            continue;\n        }\n        float _1038 = (clamp((0.5f - abs(_982)) * 10.0f, 0.0f, 1.0f) * _1018) * _935.x;\n        float2 _1046 = float2(_968 + 0.5f, 0.5f - _975);\n        float2 _1056 = float2(dot(_963, _851), dot(_970, _851));\n        float2 _1066 = float2(dot(_963, _854), dot(_970, _854));\n        int param_8 = _930 + 5;\n        float4 _1071 = fa_light_texel(param_8);\n        int param_9 = _930 + 3;\n        float4 _1076 = fa_light_texel(param_9);\n        int param_10 = _930 + 4;\n        float4 _1081 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1071.xyz;\n        bool _1091 = _1076.z > _1076.x;\n        if (_1091)\n        {\n            float4 param_11 = _1076;\n            float2 param_12 = _1046;\n            float2 param_13 = _879;\n            float2 param_14 = _1056;\n            float2 param_15 = _1066;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_889 > 0.5f) && (_889 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1117 = fa_dc_to_linear(param_16);\n                float4 _4994 = tx;\n                _4994.x = _1117.x;\n                _4994.y = _1117.y;\n                _4994.z = _1117.z;\n                tx = _4994;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1038 * tex_a) * _1071.w, 0.0f, 1.0f).xxx);\n        if (_1081.z > _1081.x)\n        {\n            float4 param_17 = _1081;\n            float2 param_18 = _1046;\n            float2 param_19 = _879;\n            float2 param_20 = _1056;\n            float2 param_21 = _1066;\n            float4 _1161 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_889 > 1.5f)\n            {\n                float3 param_22 = _1161.xyz;\n                float3 _1171 = fa_dc_to_srgb(param_22);\n                _1165 = _1171;\n            }\n            else\n            {\n                _1165 = _1161.xyz;\n            }\n            float3 _1181 = (_1165 * 2.0f) - 1.0f.xxx;\n            float2 _1186 = _1181.xy * _935.y;\n            float3 _1208 = (normalize(_963) * _1186.x) + (normalize(_970) * _1186.y);\n            float3 _1211 = normalize(normal);\n            normal = normalize(lerp(_1211, normalize((_1211 * max(_1181.z, 0.0500000007450580596923828125f)) + (_1208 - (_1211 * dot(_1211, _1208)))), clamp(_1038 * (_1091 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _2671 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _2678 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _2681 = int(_2671);\n    int _2684 = int(_2678);\n    float _2694 = _2678 - float(_2684);\n    int _2749 = (_2681 * 9) + _2684;\n    int _2769 = ((_2681 + 1) * 9) + _2684;\n    return lerp(lerp(_2745[_2749], _2745[_2749 + 1], _2694), lerp(_2745[_2769], _2745[_2769 + 1], _2694), _2671 - float(_2681));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _4861 = false;\n    float _4862 = 1.0f;\n    float _4863 = 1.0f;\n    float _4864 = 1.0f;\n    float _4865 = 0.0f;\n    float _4866 = 0.0f;\n    float _4867 = 0.0f;\n    float _4868 = 0.0f;\n    float _4870 = 1.0f;\n    bool _4871 = false;\n    float3 _4872 = 0.0f.xxx;\n    float _4873 = 1.0f;\n    float _4874 = 1.0f;\n    float _4875 = 1.0f;\n    float _4876 = 0.0f;\n    float _4877 = 0.0f;\n    float3 _4878 = float3(1.0f, 0.0f, 0.0f);\n    float3 _4879 = float3(0.0f, 0.0f, 1.0f);\n    float _4880 = 1.0f;\n    float _4881 = 1.0f;\n    float _2822 = clamp(s.specular, 0.0f, 1.0f);\n    float _2826 = clamp(s.ior, 1.0f, 3.0f);\n    bool _2831 = (_2822 != 1.0f) || (_2826 != 1.5f);\n    bool _2841;\n    if (!_2831)\n    {\n        _2841 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _2841 = _2831;\n    }\n    if (_2841)\n    {\n        float _2849 = (_2826 - 1.0f) / (_2826 + 1.0f);\n        f0 = lerp(min((_2849 * _2849).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _2822, s.albedo, metallic.xxx);\n        _4862 = lerp(_2822, 1.0f, metallic);\n        _4861 = true;\n    }\n    float _2877 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_2877 > 0.0f)\n    {\n        float _2885 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _4865 = _2877;\n        _4866 = _2885;\n        float _2892 = _2885 * _2885;\n        _4867 = _2892;\n        _4868 = _2892 * _2892;\n        float _2904 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _4870 = _2904;\n        _4863 = 1.0f - (_2877 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _2904, 0.0f, 1.0f), 5.0f))));\n        _4861 = true;\n    }\n    float3 _2923 = max(s.sheen_color, 0.0f.xxx);\n    float _2932 = max(_2923.x, max(_2923.y, _2923.z));\n    if (_2932 > 0.0f)\n    {\n        float _2940 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _4871 = true;\n        _4872 = _2923;\n        _4873 = _2940;\n        _4874 = _2940 * _2940;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _2940;\n        float _2957 = fa_sheen_albedo(param, param_1);\n        _4876 = _2957;\n        _4875 = 1.0f - min(_2932 * _2957, 1.0f);\n        _4861 = true;\n    }\n    _4864 = _4863 * _4875;\n    float _2976 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_2976 != 0.0f)\n    {\n        float3 _2991 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2991;\n        if (dot(_2991, _2991) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _3004 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_3004.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _3004.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _3004.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _3008 = t;\n        float3 _3009 = normalize(_3008);\n        t = _3009;\n        float3 _3034 = normalize((_3009 * cos(s.anisotropy_rotation)) + ((cross(n, _3009) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _4878 = _3034;\n        _4879 = cross(n, _3034);\n        float _3044 = roughness * roughness;\n        float _3050 = lerp(_3044, 1.0f, _2976 * _2976);\n        bool _3052 = _2976 > 0.0f;\n        _4880 = _3052 ? _3050 : _3044;\n        _4881 = _3052 ? _3044 : _3050;\n        _4877 = _2976;\n        _4861 = true;\n    }\n    FaLayers _4903 = { _4861, _4862, _4863, _4864, _4865, _4866, _4867, _4868, i.world_normal, _4870, _4871, _4872, _4873, _4874, _4875, _4876, _4877, _4878, _4879, _4880, _4881 };\n    return _4903;\n}\n\nfloat3 fa_sky_sh_coef(int k)\n{\n    float3 v = fa_env_tex.SampleLevel(fa_env_smp, float3(1.0f, 1.0f - (float((2 * (k >> 2)) + 1) * 0.25f), 1.0f - (float((2 * (k & 3)) + 1) * 0.25f)), 5.0f).xyz;\n    if (_553_fa_env_sky.w > 1.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _2428 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _2428;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_553_fa_env_sky.w > 0.5f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _553_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_553_fa_cl_info.x) + int(_553_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _427 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _433 = fa_light_texel(param_1);\n    float _436 = _433.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _442 = _436 < 0.5f;\n    float3 l;\n    if (_442)\n    {\n        l = normalize(_427.xyz);\n    }\n    else\n    {\n        float3 _454 = _427.xyz - world_pos;\n        float _456 = length(_454);\n        dist = _456;\n        l = _454 / max(_456, 9.9999997473787516355514526367188e-05f).xxx;\n        float _471 = _456 / max(_427.w, 0.001000000047497451305389404296875f);\n        float _477 = clamp(1.0f - (_471 * _471), 0.0f, 1.0f);\n        atten = _477 * _477;\n        if (_436 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _491 = fa_light_texel(param_2);\n            float _501 = _491.w;\n            int param_3 = (li * 4) + 3;\n            float4 _507 = fa_light_texel(param_3);\n            float _508 = _507.x;\n            float cos_inner = _508;\n            if (_508 > 1.5f)\n            {\n                cos_inner = lerp(_501, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_501, cos_inner, dot(-l, normalize(_491.xyz)));\n        }\n    }\n    int _539;\n    if (_442)\n    {\n        _539 = 0;\n    }\n    else\n    {\n        _539 = (_436 > 1.5f) ? 2 : 1;\n    }\n    LightSample _4860 = { l, _433.xyz * atten, atten, 1.0f, dist, _539 };\n    return _4860;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1283;\n    if (i == 0)\n    {\n        _1283 = _1293_fa_shadow_split.x;\n    }\n    else\n    {\n        float _1299;\n        if (i == 1)\n        {\n            _1299 = _1293_fa_shadow_split.y;\n        }\n        else\n        {\n            float _1307;\n            if (i == 2)\n            {\n                _1307 = _1293_fa_shadow_split.z;\n            }\n            else\n            {\n                _1307 = _1293_fa_shadow_split.w;\n            }\n            _1299 = _1307;\n        }\n        _1283 = _1299;\n    }\n    return _1283;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1340 = fa_shadow_depth(param, param_1);\n    float _1344;\n    if (conv.x < 0.5f)\n    {\n        _1344 = _1340;\n    }\n    else\n    {\n        _1344 = (conv.y * conv.z) / (conv.z - (_1340 * (conv.z - conv.y)));\n    }\n    return _1344;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1271 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_1271), sin(_1271)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1390 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _1404 = clamp((k * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1390;\n            float2 _1423 = fa_shadow_vogel(param_3, param_4, param_5) * _1404;\n            float2 param_6 = uv + (_1423 * _1293_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1435 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1435 < (zr - (length(_1423) * plane)))\n            {\n                sum += _1435;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0f) * unit) * k) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _1479 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1479; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1479;\n        float param_11 = _1390;\n        float2 _1498 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1498 * _1293_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1498) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1479);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _1540 = max(_1293_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _1545 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1551 = sqrt(1.0f - (_1545 * _1545));\n    float _1558 = min(_1551 / max(_1545, 0.20000000298023223876953125f), 4.0f);\n    float _1563;\n    if (_1293_fa_shadow_bias.y > 0.0f)\n    {\n        _1563 = _1293_fa_shadow_bias.y;\n    }\n    else\n    {\n        _1563 = 1.5f * _1293_fa_shadow_info[ci].x;\n    }\n    float4 _1588 = mul(float4(world + (n * (_1563 * _1551)), 1.0f), _1293_fa_shadow_mat[ci]);\n    float _1595 = _1588.x;\n    bool _1598 = _1595 < _1293_fa_shadow_rect[ci].x;\n    bool _1607;\n    if (!_1598)\n    {\n        _1607 = _1595 > _1293_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1607 = _1598;\n    }\n    bool _1616;\n    if (!_1607)\n    {\n        _1616 = _1588.y < _1293_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1616 = _1607;\n    }\n    bool _1625;\n    if (!_1616)\n    {\n        _1625 = _1588.y > _1293_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1625 = _1616;\n    }\n    bool _1632;\n    if (!_1625)\n    {\n        _1632 = _1588.z > 1.0f;\n    }\n    else\n    {\n        _1632 = _1625;\n    }\n    if (_1632)\n    {\n        return -1.0f;\n    }\n    float _1641;\n    if (_1293_fa_shadow_bias.x > 0.0f)\n    {\n        _1641 = _1293_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1641 = 1.5f * _1293_fa_shadow_info[ci].x;\n    }\n    float2 param = _1588.xy;\n    float4 param_1 = _1293_fa_shadow_rect[ci];\n    float param_2 = _1588.z - ((_1641 * (1.0f + (0.5f * _1558))) / _1540);\n    float param_3 = _1293_fa_shadow_info[ci].x;\n    float param_4 = _1540;\n    float param_5 = _1540 * 0.25f;\n    float param_6 = ((_1293_fa_shadow_info[ci].x * min(_1558, 3.0f)) * 0.5f) / _1540;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_1293_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _1293_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_553_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2068 = int(_1293_fa_shadow_cfg.x + 0.5f);\n    if (_2068 < 1)\n    {\n        return 1.0f;\n    }\n    float _2083 = dot(world - _1293_fa_shadow_eye.xyz, _1293_fa_shadow_fwd.xyz);\n    int param = _2068 - 1;\n    if (_2083 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2095 = _2068 > 1;\n    bool _2102;\n    if (_2095)\n    {\n        _2102 = _2083 > _1293_fa_shadow_split.x;\n    }\n    else\n    {\n        _2102 = _2095;\n    }\n    if (_2102)\n    {\n        ci = 1;\n    }\n    bool _2106 = _2068 > 2;\n    bool _2113;\n    if (_2106)\n    {\n        _2113 = _2083 > _1293_fa_shadow_split.y;\n    }\n    else\n    {\n        _2113 = _2106;\n    }\n    if (_2113)\n    {\n        ci = 2;\n    }\n    bool _2117 = _2068 > 3;\n    bool _2124;\n    if (_2117)\n    {\n        _2124 = _2083 > _1293_fa_shadow_split.z;\n    }\n    else\n    {\n        _2124 = _2117;\n    }\n    if (_2124)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2068)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2150 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2150;\n        if (_2150 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_1293_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2175;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2175 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2175 = _1293_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2194 = _1293_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2175, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2205 = clamp((_2083 - (fa_shadow_split_at(param_7) - _2194)) / _2194, 0.0f, 1.0f);\n        if (_2205 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2068)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2226 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2226;\n                if (_2226 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2205);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _1699 = _553_fa_pbr.z < 0.5f;\n    bool _1707;\n    if (!_1699)\n    {\n        _1707 = _1293_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _1707 = _1699;\n    }\n    if (_1707)\n    {\n        return 1.0f;\n    }\n    int param = (int(_1293_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _1720 = fa_light_texel(param);\n    float _1721 = _1720.x;\n    if (_1721 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _1730 = int(_1721 + 0.5f);\n    int param_1 = _1730;\n    float4 _1734 = fa_light_texel(param_1);\n    int param_2 = _1730 + 1;\n    float4 _1739 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _1742 = _1734.y;\n    if (_1742 > 0.0f)\n    {\n        float _1759 = 1.0f - smoothstep(0.75f * _1742, _1742, length(world - _1293_fa_shadow_eye.xyz));\n        fade = _1759;\n        if (_1759 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_1734.x > 1.5f)\n    {\n        int param_3 = li * 4;\n        float3 _1778 = world - fa_light_texel(param_3).xyz;\n        float3 _1781 = abs(_1778);\n        float _1783 = _1781.x;\n        float _1785 = _1781.y;\n        bool _1786 = _1783 >= _1785;\n        bool _1794;\n        if (_1786)\n        {\n            _1794 = _1783 >= _1781.z;\n        }\n        else\n        {\n            _1794 = _1786;\n        }\n        int _1795;\n        if (_1794)\n        {\n            _1795 = (_1778.x > 0.0f) ? 0 : 1;\n        }\n        else\n        {\n            int _1808;\n            if (_1785 >= _1781.z)\n            {\n                _1808 = (_1778.y > 0.0f) ? 2 : 3;\n            }\n            else\n            {\n                _1808 = (_1778.z > 0.0f) ? 4 : 5;\n            }\n            _1795 = _1808;\n        }\n        face = _1795;\n    }\n    int _1827 = (_1730 + 2) + (face * 6);\n    int param_4 = _1827;\n    int param_5 = _1827 + 1;\n    int param_6 = _1827 + 3;\n    float4 _1841 = fa_light_texel(param_6);\n    int param_7 = _1827 + 4;\n    float4 _1846 = fa_light_texel(param_7);\n    int param_8 = _1827 + 5;\n    float4 _1851 = fa_light_texel(param_8);\n    float _1863 = _1851.x * max(dot(_1841, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _1868 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1891 = clamp(dot(n, _1841.xyz), -1.0f, 1.0f);\n    int param_9 = li * 4;\n    float _1914 = min(sqrt(1.0f - (_1891 * _1891)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1841, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _1917 = _1739.y;\n    float _1919;\n    if (_1917 > 0.0f)\n    {\n        _1919 = _1917;\n    }\n    else\n    {\n        _1919 = 1.5f * _1863;\n    }\n    float4 _1939 = float4(world + (n * (_1919 * sqrt(1.0f - (_1868 * _1868)))), 1.0f);\n    float _1943 = dot(_1841, _1939);\n    float _1946 = _1851.y;\n    if (_1943 < _1946)\n    {\n        return 1.0f;\n    }\n    float2 _1961 = float2(dot(fa_light_texel(param_4), _1939), dot(fa_light_texel(param_5), _1939)) / _1943.xx;\n    float _1963 = _1961.x;\n    bool _1966 = _1963 < _1846.x;\n    bool _1975;\n    if (!_1966)\n    {\n        _1975 = _1963 > _1846.z;\n    }\n    else\n    {\n        _1975 = _1966;\n    }\n    bool _1984;\n    if (!_1975)\n    {\n        _1984 = _1961.y < _1846.y;\n    }\n    else\n    {\n        _1984 = _1975;\n    }\n    bool _1993;\n    if (!_1984)\n    {\n        _1993 = _1961.y > _1846.w;\n    }\n    else\n    {\n        _1993 = _1984;\n    }\n    if (_1993)\n    {\n        return 1.0f;\n    }\n    float _1999 = _1739.x;\n    float _2001;\n    if (_1999 > 0.0f)\n    {\n        _2001 = _1999;\n    }\n    else\n    {\n        _2001 = 1.5f * _1863;\n    }\n    float2 param_10 = _1961;\n    float4 param_11 = _1846;\n    float param_12 = _1943 - (_2001 * (1.0f + (0.5f * _1914)));\n    float param_13 = _1863;\n    float param_14 = 1.0f;\n    float param_15 = _1851.z * 0.25f;\n    float param_16 = (_1863 * min(_1914, 3.0f)) * 0.5f;\n    float3 param_17 = float3(1.0f, _1946, _1851.z);\n    int param_18 = int(_1734.z + 0.5f);\n    float param_19 = _1734.w;\n    return lerp(1.0f, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _3585 = fa_lm.z > 0.5f;\n    bool _3591;\n    if (_3585)\n    {\n        int param = li;\n        _3591 = fa_light_baked(param);\n    }\n    else\n    {\n        _3591 = _3585;\n    }\n    if (_3591)\n    {\n        int param_1 = li;\n        LightSample _4916 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _4916;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _3613 = fa_light_sample(param_2, param_3);\n    float3 _4923 = _3613.direction;\n    float3 _4918 = _3613.color;\n    float _4925 = _3613.attenuation;\n    float _4920 = _3613.shadow;\n    int _4928 = _3613.type;\n    if ((_4928 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _4923;\n        float _3627 = fa_shadow_factor(param_4, param_5);\n        _4920 = _3627;\n        _4918 *= _3627;\n    }\n    else\n    {\n        bool _3638 = _4928 != 0;\n        bool _3644;\n        if (_3638)\n        {\n            _3644 = _4925 > 0.0f;\n        }\n        else\n        {\n            _3644 = _3638;\n        }\n        if (_3644)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _4923;\n            float _3656 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _4920 = _3656;\n            _4918 *= _3656;\n        }\n    }\n    LightSample _4935 = { _4923, _4918, _4925, _4920, _3613._distance, _4928 };\n    return _4935;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _3202 = tdh / at;\n    float _3206 = bdh / ab;\n    float _3218 = ((_3202 * _3202) + (_3206 * _3206)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _3218) * _3218);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _3299 = 1.0f / alpha;\n    return ((2.0f + _3299) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _3299)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _3331 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _3410 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _3410) * _3410);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _3331);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _3331));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        float _3483 = max(dot(L.nc, l), 0.0f);\n        float _3489 = max(dot(L.nc, h), 0.0f);\n        float _3498 = ((_3489 * _3489) * (L.coat_a2 - 1.0f)) + 1.0f;\n        result += ((((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _3498) * _3498)) * (0.5f / max(lerp((2.0f * _3483) * L.coat_ndv, _3483 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _3483)) * _3483).xxx;\n    }\n    return result;\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _2603 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _2606 = _2603.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_2606 * _2606, exp2((-9.27999973297119140625f) * ndv)) * _2606) + _2603.y)) + _2603.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_553_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _553_fa_env_horizon.w).xyz;\n    }\n    float _2457 = rough * rough;\n    float _2487 = 0.60000002384185791015625f * _2457;\n    return lerp(lerp(_553_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_553_fa_env_horizon.xyz, _553_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _2457)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _2487, 0.0500000007450580596923828125f + _2487, d.y).xxx), ((_553_fa_env_sky.xyz + _553_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_2457 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _3085;\n        if (L.aniso >= 0.0f)\n        {\n            _3085 = L.b;\n        }\n        else\n        {\n            _3085 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_3085, v), _3085), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3118 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _3118.x) + (L.f90.xxx * _3118.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3173 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _3173.x) + _3173.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _2645 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _2645.x) + _2645.y.xxx);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_1293_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _2250 = int(_1293_fa_shadow_cfg.x + 0.5f);\n    float _2260 = dot(world - _1293_fa_shadow_eye.xyz, _1293_fa_shadow_fwd.xyz);\n    float3 tint_1 = 0.3499999940395355224609375f.xxx;\n    bool _2265 = _2250 > 0;\n    bool _2274;\n    if (_2265)\n    {\n        int param = _2250 - 1;\n        _2274 = _2260 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2274 = _2265;\n    }\n    if (_2274)\n    {\n        tint_1 = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _2281 = _2250 > 1;\n        bool _2288;\n        if (_2281)\n        {\n            _2288 = _2260 > _1293_fa_shadow_split.x;\n        }\n        else\n        {\n            _2288 = _2281;\n        }\n        if (_2288)\n        {\n            tint_1 = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _2294 = _2250 > 2;\n        bool _2301;\n        if (_2294)\n        {\n            _2301 = _2260 > _1293_fa_shadow_split.y;\n        }\n        else\n        {\n            _2301 = _2294;\n        }\n        if (_2301)\n        {\n            tint_1 = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _2307 = _2250 > 3;\n        bool _2314;\n        if (_2307)\n        {\n            _2314 = _2260 > _1293_fa_shadow_split.z;\n        }\n        else\n        {\n            _2314 = _2307;\n        }\n        if (_2314)\n        {\n            tint_1 = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint_1, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _4640 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4640 = -_4640;\n    }\n    float3 _4065 = normalize(_553_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _4653 = { fa_world_pos, _4640, fa_world_tangent, fa_uv, fa_vertex_color, _4065, gl_FrontFacing };\n    SurfaceInput param_1 = _4653;\n    Surface _4073 = fa_standard_surface(param_1);\n    float3 _4671 = _4073.albedo;\n    float _4672 = _4073.alpha;\n    float3 _4673 = _4073.normal;\n    float _4674 = _4073.metallic;\n    float _4675 = _4073.roughness;\n    float _4676 = _4073.occlusion;\n    float3 _4677 = _4073.emission;\n    float _4678 = _4073.clearcoat;\n    float _4679 = _4073.clearcoat_roughness;\n    float3 _4680 = _4073.sheen_color;\n    float _4681 = _4073.sheen_roughness;\n    float _4682 = _4073.anisotropy;\n    float _4683 = _4073.anisotropy_rotation;\n    float _4684 = _4073.specular;\n    float _4685 = _4073.ior;\n    float3 _4686 = _4073.specular_color;\n    SurfaceInput _4661 = { fa_world_pos, _4640, fa_world_tangent, fa_uv, fa_vertex_color, _4065, gl_FrontFacing };\n    SurfaceInput param_2 = _4661;\n    Surface param_3 = _4073;\n    surface(param_2, param_3);\n    _4671 = param_3.albedo;\n    _4672 = param_3.alpha;\n    _4673 = param_3.normal;\n    _4674 = param_3.metallic;\n    _4675 = param_3.roughness;\n    _4676 = param_3.occlusion;\n    _4677 = param_3.emission;\n    _4678 = param_3.clearcoat;\n    _4679 = param_3.clearcoat_roughness;\n    _4680 = param_3.sheen_color;\n    _4681 = param_3.sheen_roughness;\n    _4682 = param_3.anisotropy;\n    _4683 = param_3.anisotropy_rotation;\n    _4684 = param_3.specular;\n    _4685 = param_3.ior;\n    _4686 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _4640;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4671 = param_6;\n    _4673 = param_7;\n    float3 result;\n    if (_553_fa_emissive.w > 0.5f)\n    {\n        result = _4671;\n    }\n    else\n    {\n        float3 _4112 = normalize(_4673);\n        float _4119 = clamp(_4674, 0.0f, 1.0f);\n        float _4123 = clamp(_4675, 0.0500000007450580596923828125f, 1.0f);\n        float _4127 = _4123 * _4123;\n        float _4131 = _4127 * _4127;\n        float _4136 = max(dot(_4112, _4065), 9.9999997473787516355514526367188e-05f);\n        float3 _4142 = _4671 * (1.0f - _4119);\n        float3 _4149 = lerp(0.039999999105930328369140625f.xxx, _4671, _4119.xxx);\n        float3 f0 = _4149;\n        SurfaceInput _4669 = { fa_world_pos, _4640, fa_world_tangent, fa_uv, fa_vertex_color, _4065, gl_FrontFacing };\n        SurfaceInput param_8 = _4669;\n        Surface _4752 = { _4671, _4672, _4673, _4674, _4675, _4676, _4677, _4678, _4679, _4680, _4681, _4682, _4683, _4684, _4685, _4686 };\n        Surface param_9 = _4752;\n        float3 param_10 = _4112;\n        float3 param_11 = _4065;\n        float param_12 = _4119;\n        float param_13 = _4123;\n        float3 param_14 = _4149;\n        FaLayers _4165 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _4112;\n        float3 lit = (fa_indirect_diffuse(param_15) * _4142) * _4676;\n        if (_4165.on)\n        {\n            lit *= _4165.base_scale;\n        }\n        int _4187 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4187; ln++)\n        {\n            int param_16 = ln;\n            int _4200 = fa_cl_light(param_16);\n            bool _4203 = fa_lm.z > 0.5f;\n            bool _4209;\n            if (_4203)\n            {\n                int param_17 = _4200;\n                _4209 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _4209 = _4203;\n            }\n            if (_4209)\n            {\n                continue;\n            }\n            int param_18 = _4200;\n            float3 param_19 = fa_world_pos;\n            float3 param_20 = _4640;\n            LightSample _4221 = fa_light_shadowed(param_18, param_19, param_20);\n            float3 _4845 = _4221.direction;\n            float _4229 = max(dot(_4112, _4845), 0.0f);\n            float _4235 = _4221.attenuation * _4221.shadow;\n            float3 _4240 = normalize(_4845 + _4065);\n            float _4245 = max(dot(_4112, _4240), 0.0f);\n            float _4250 = max(dot(_4065, _4240), 0.0f);\n            if (_4165.on)\n            {\n                FaLayers param_21 = _4165;\n                float3 param_22 = _4142;\n                float3 param_23 = f0;\n                float3 param_24 = _4112;\n                float3 param_25 = _4065;\n                float3 param_26 = _4845;\n                float3 param_27 = _4240;\n                float param_28 = _4229;\n                float param_29 = _4136;\n                float param_30 = _4245;\n                float param_31 = _4250;\n                float param_32 = _4127;\n                float param_33 = _4131;\n                int param_34 = _4200;\n                lit += (fa_layers_light(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30, param_31, param_32, param_33) * (fa_light_rgb(param_34) * _4235));\n            }\n            else\n            {\n                float _4298 = ((_4245 * _4245) * (_4131 - 1.0f)) + 1.0f;\n                int param_35 = _4200;\n                lit += (((_4142 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _4250, 5.0f))) * (((_4131 / ((3.1415927410125732421875f * _4298) * _4298)) * (0.5f / max(lerp((2.0f * _4229) * _4136, _4229 + _4136, _4127), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _4229))) * fa_light_rgb(param_35)) * (_4229 * _4235));\n            }\n        }\n        if (_4165.on)\n        {\n            FaLayers param_36 = _4165;\n            float3 param_37 = _4112;\n            float3 param_38 = _4065;\n            float3 param_39 = f0;\n            float param_40 = _4123;\n            lit += (fa_layers_ibl(param_36, param_37, param_38, param_39, param_40) * _4676);\n        }\n        else\n        {\n            float3 param_41 = _4112;\n            float3 param_42 = _4065;\n            float3 param_43 = f0;\n            float param_44 = _4123;\n            lit += (fa_sky_reflection(param_41, param_42, param_43, param_44) * _4676);\n        }\n        result = lit;\n    }\n    float3 _4391 = result;\n    float3 _4392 = _4391 + _4677;\n    result = _4392;\n    float3 param_45 = _4392;\n    float3 param_46 = fa_world_pos;\n    result = fa_shadow_debug(param_45, param_46);\n    bool _4401 = _553_fa_fog.w > 0.0f;\n    bool _4408;\n    if (!_4401)\n    {\n        _4408 = _553_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _4408 = _4401;\n    }\n    if (_4408)\n    {\n        float3 _4417 = fa_world_pos - _553_fa_camera_pos.xyz;\n        float _4423 = dot(_4417, _553_fa_fog_c.xyz);\n        bool _4427 = _553_fa_fog_c.w > 0.5f;\n        float _4428;\n        if (_4427)\n        {\n            _4428 = _4423;\n        }\n        else\n        {\n            _4428 = length(_4417);\n        }\n        float _4440 = _4428 - _553_fa_fog_b.x;\n        if (_4440 > 0.0f)\n        {\n            float _4449 = _553_fa_fog.w * _4440;\n            float tau = _4449 * _4449;\n            if (_553_fa_fog_b.y > 0.0f)\n            {\n                float _4465;\n                if (_4427)\n                {\n                    _4465 = fa_world_pos.y - (_553_fa_fog_c.y * _4423);\n                }\n                else\n                {\n                    _4465 = _553_fa_camera_pos.y;\n                }\n                float _4486 = lerp(_4465, fa_world_pos.y, clamp(_553_fa_fog_b.x / _4428, 0.0f, 1.0f));\n                float _4490 = fa_world_pos.y - _4486;\n                float _4495 = _4486 - _553_fa_fog_b.z;\n                float _4500 = fa_world_pos.y - _553_fa_fog_b.z;\n                bool _4503 = _4495 <= 0.0f;\n                bool _4504 = !_4503;\n                bool _4510;\n                if (_4504)\n                {\n                    _4510 = _553_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4510 = _4503;\n                }\n                float _4511;\n                if (_4510)\n                {\n                    _4511 = _553_fa_fog_b.y;\n                }\n                else\n                {\n                    _4511 = _553_fa_fog_b.y * exp(-min(_553_fa_fog_b.w * _4495, 80.0f));\n                }\n                bool _4538;\n                if (_4504)\n                {\n                    _4538 = _553_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4538 = _4503;\n                }\n                float _4539;\n                if (_4538)\n                {\n                    _4539 = _553_fa_fog_b.y * _4495;\n                }\n                else\n                {\n                    _4539 = (_553_fa_fog_b.y * (1.0f - exp(-min(_553_fa_fog_b.w * _4495, 80.0f)))) / _553_fa_fog_b.w;\n                }\n                bool _4564 = _4500 <= 0.0f;\n                bool _4571;\n                if (!_4564)\n                {\n                    _4571 = _553_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4571 = _4564;\n                }\n                float _4572;\n                if (_4571)\n                {\n                    _4572 = _553_fa_fog_b.y * _4500;\n                }\n                else\n                {\n                    _4572 = (_553_fa_fog_b.y * (1.0f - exp(-min(_553_fa_fog_b.w * _4500, 80.0f)))) / _553_fa_fog_b.w;\n                }\n                float _4599;\n                if (abs(_4490) < 0.001000000047497451305389404296875f)\n                {\n                    _4599 = _4511;\n                }\n                else\n                {\n                    _4599 = (_4572 - _4539) / _4490;\n                }\n                tau += (_4440 * max(_4599, 0.0f));\n            }\n            result = lerp(result, _553_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4672);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_inst_v0 = stage_input.fa_inst_v0;\n    fa_inst_v1 = stage_input.fa_inst_v1;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 176,
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
            "inst_name": "_553",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1293",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_3681",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _153_fa_view_proj : packoffset(c0);\n    row_major float4x4 _153_fa_light_vp : packoffset(c4);\n    float4 _153_fa_uv_scale : packoffset(c8);\n    float4 _153_fa_time : packoffset(c9);\n    float4 _153_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_d0;\nstatic float4 fa_inst_d1;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_inst_d0 : TEXCOORD9;\n    float4 fa_inst_d1 : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float fa_pre_depth : TEXCOORD7;\n    float3 fa_pre_r0 : TEXCOORD8;\n    float3 fa_pre_r1 : TEXCOORD9;\n    float3 fa_pre_r2 : TEXCOORD10;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float raise;\nstatic float4 tint;\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _100 = (dot(model[0].xyz, _94) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _334 = { mul(float4(position, 1.0f), model).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _100, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _100), texcoord0 * _153_fa_uv_scale.xy, color, position };\n    return _334;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _197 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -mul(_197, _153_fa_light_vp).z;\n    fa_pre_r0 = float3(_153_fa_light_vp[0].x, _153_fa_light_vp[1].x, _153_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_153_fa_light_vp[0].y, _153_fa_light_vp[1].y, _153_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_153_fa_light_vp[0].z, _153_fa_light_vp[1].z, _153_fa_light_vp[2].z);\n    gl_Position = mul(_197, _153_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_d0 = stage_input.fa_inst_d0;\n    fa_inst_d1 = stage_input.fa_inst_d1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    stage_output.fa_inst_v0 = fa_inst_v0;\n    stage_output.fa_inst_v1 = fa_inst_v1;\n    return stage_output;\n}\n",
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
            "size": 176,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _158_fa_view_proj : packoffset(c0);\n    row_major float4x4 _158_fa_light_vp : packoffset(c4);\n    float4 _158_fa_uv_scale : packoffset(c8);\n    float4 _158_fa_time : packoffset(c9);\n    float4 _158_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _205_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_d0;\nstatic float4 fa_inst_d1;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n    float4 fa_inst_d0 : TEXCOORD11;\n    float4 fa_inst_d1 : TEXCOORD12;\n};\n\nstruct SPIRV_Cross_Output\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float fa_pre_depth : TEXCOORD7;\n    float3 fa_pre_r0 : TEXCOORD8;\n    float3 fa_pre_r1 : TEXCOORD9;\n    float3 fa_pre_r2 : TEXCOORD10;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float raise;\nstatic float4 tint;\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_205_fa_joint_rows[_196] * weights[i]);\n        r1 += (_205_fa_joint_rows[_196 + 1] * weights[i]);\n        r2 += (_205_fa_joint_rows[_196 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _454 = { mul(float4(position, 1.0f), model).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * _158_fa_uv_scale.xy, color, position };\n    return _454;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _310 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -mul(_310, _158_fa_light_vp).z;\n    fa_pre_r0 = float3(_158_fa_light_vp[0].x, _158_fa_light_vp[1].x, _158_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_158_fa_light_vp[0].y, _158_fa_light_vp[1].y, _158_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_158_fa_light_vp[0].z, _158_fa_light_vp[1].z, _158_fa_light_vp[2].z);\n    gl_Position = mul(_310, _158_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_d0 = stage_input.fa_inst_d0;\n    fa_inst_d1 = stage_input.fa_inst_d1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    stage_output.fa_inst_v0 = fa_inst_v0;\n    stage_output.fa_inst_v1 = fa_inst_v1;\n    return stage_output;\n}\n",
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
            "size": 176,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _144_fa_view_proj : packoffset(c0);\n    row_major float4x4 _144_fa_light_vp : packoffset(c4);\n    float4 _144_fa_uv_scale : packoffset(c8);\n    float4 _144_fa_time : packoffset(c9);\n    float4 _144_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_d0;\nstatic float4 fa_inst_d1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float3 fa_normal : TEXCOORD5;\n    float2 fa_texcoord0 : TEXCOORD6;\n    float4 fa_tangent : TEXCOORD7;\n    float4 fa_color : TEXCOORD8;\n    float4 fa_inst_d0 : TEXCOORD9;\n    float4 fa_inst_d1 : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 gl_Position : SV_Position;\n};\n\nstatic float raise;\nstatic float4 tint;\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _85 = cross(model[1].xyz, model[2].xyz);\n    float _91 = (dot(model[0].xyz, _85) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _282 = { mul(float4(position, 1.0f), model).xyz, (((_85 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _91, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _91), texcoord0 * _144_fa_uv_scale.xy, color, position };\n    return _282;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _144_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_d0 = stage_input.fa_inst_d0;\n    fa_inst_d1 = stage_input.fa_inst_d1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    return stage_output;\n}\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_144",
            "hlsl_register_b_n": 0
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _149_fa_view_proj : packoffset(c0);\n    row_major float4x4 _149_fa_light_vp : packoffset(c4);\n    float4 _149_fa_uv_scale : packoffset(c8);\n    float4 _149_fa_time : packoffset(c9);\n    float4 _149_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _196_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_d0;\nstatic float4 fa_inst_d1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float4 fa_joints : TEXCOORD5;\n    float4 fa_weights : TEXCOORD6;\n    float3 fa_normal : TEXCOORD7;\n    float2 fa_texcoord0 : TEXCOORD8;\n    float4 fa_tangent : TEXCOORD9;\n    float4 fa_color : TEXCOORD10;\n    float4 fa_inst_d0 : TEXCOORD11;\n    float4 fa_inst_d1 : TEXCOORD12;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 gl_Position : SV_Position;\n};\n\nstatic float raise;\nstatic float4 tint;\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _187 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_196_fa_joint_rows[_187] * weights[i]);\n        r1 += (_196_fa_joint_rows[_187 + 1] * weights[i]);\n        r2 += (_196_fa_joint_rows[_187 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _90 = cross(model[1].xyz, model[2].xyz);\n    float _96 = (dot(model[0].xyz, _90) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _402 = { mul(float4(position, 1.0f), model).xyz, (((_90 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _96, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _96), texcoord0 * _149_fa_uv_scale.xy, color, position };\n    return _402;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid vert_main()\n{\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    fa_inst_begin();\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    vertex(param_8);\n    gl_Position = mul(float4(param_8.world_pos, 1.0f), _149_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_d0 = stage_input.fa_inst_d0;\n    fa_inst_d1 = stage_input.fa_inst_d1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    return stage_output;\n}\n",
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
            "inst_name": "_196",
            "hlsl_register_b_n": 3
          }
        ]
      }
    }
  }
}
