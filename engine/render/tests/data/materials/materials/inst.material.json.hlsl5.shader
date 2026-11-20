{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "63c8ed9ef72f0fba56beb38b3018a9ae9876604a67ae71ca005757f89f9b9e64",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _3492[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _491_fa_camera_pos : packoffset(c0);\n    float4 _491_fa_ambient : packoffset(c1);\n    float4 _491_fa_base_color : packoffset(c2);\n    float4 _491_fa_emissive : packoffset(c3);\n    float4 _491_fa_model_emissive : packoffset(c4);\n    float4 _491_fa_pbr : packoffset(c5);\n    float4 _491_fa_maps : packoffset(c6);\n    float4 _491_fa_fog : packoffset(c7);\n    float4 _491_fa_fog_b : packoffset(c8);\n    float4 _491_fa_fog_c : packoffset(c9);\n    float4 _491_fa_counts : packoffset(c10);\n    float4 _491_fa_env_sky : packoffset(c11);\n    float4 _491_fa_env_horizon : packoffset(c12);\n    float4 _491_fa_time : packoffset(c13);\n    float4 _491_fa_cl_vpx : packoffset(c14);\n    float4 _491_fa_cl_vpy : packoffset(c15);\n    float4 _491_fa_cl_vpw : packoffset(c16);\n    float4 _491_fa_cl_fwd : packoffset(c17);\n    float4 _491_fa_cl_grid : packoffset(c18);\n    float4 _491_fa_cl_info : packoffset(c19);\n    float4 _491_fa_layers_a : packoffset(c20);\n    float4 _491_fa_layers_b : packoffset(c21);\n    float4 _491_fa_layers_c : packoffset(c22);\n    float4 _491_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2198_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2198_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2198_fa_shadow_info[4] : packoffset(c20);\n    float4 _2198_fa_shadow_split : packoffset(c24);\n    float4 _2198_fa_shadow_cfg : packoffset(c25);\n    float4 _2198_fa_shadow_bias : packoffset(c26);\n    float4 _2198_fa_shadow_eye : packoffset(c27);\n    float4 _2198_fa_shadow_fwd : packoffset(c28);\n    float4 _2198_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _5369_boost : packoffset(c0);\n    float _5369_fa_pad0 : packoffset(c0.y);\n    float _5369_fa_pad1 : packoffset(c0.z);\n    float _5369_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t11);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t10);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float3 fa_lm : TEXCOORD7;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\nstatic float raise;\nstatic float4 tint;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1469 = _491_fa_cl_info.x < 0.0f;\n    bool _1476;\n    if (!_1469)\n    {\n        _1476 = _491_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1476 = _1469;\n    }\n    bool _1484;\n    if (!_1476)\n    {\n        _1484 = _491_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1484 = _1476;\n    }\n    bool _1491;\n    if (!_1484)\n    {\n        _1491 = _491_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1491 = _1484;\n    }\n    bool _1498;\n    if (!_1491)\n    {\n        _1498 = _491_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1498 = _1491;\n    }\n    if (_1498)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1508 = float4(world_pos, 1.0f);\n    float _1514 = dot(_491_fa_cl_vpw, _1508);\n    if (!(_1514 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1536 = float2(dot(_491_fa_cl_vpx, _1508), dot(_491_fa_cl_vpy, _1508)) / _1514.xx;\n    int _1540 = int(_491_fa_cl_grid.x);\n    int _1544 = int(_491_fa_cl_grid.y);\n    int param = (int(_491_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_491_fa_cl_fwd.xyz, world_pos) + _491_fa_cl_fwd.w, _491_fa_cl_grid.w) / _491_fa_cl_grid.w) * _491_fa_cl_grid.z)), 0, int(_491_fa_cl_info.y) - 1) * _1544) + clamp(int(floor(((_1536.y * 0.5f) + 0.5f) * _491_fa_cl_grid.y)), 0, _1544 - 1)) * _1540)) + clamp(int(floor(((_1536.x * 0.5f) + 0.5f) * _491_fa_cl_grid.x)), 0, _1540 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1620 = fa_cluster_texel(param);\n    return int2(int(_1620.x), int(_1620.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_491_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4313 = fa_cluster_lookup(param);\n    fa_cl_slot = _4313.x;\n    fa_cl_local = _4313.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _5421 = fa_linear_to_srgb(param);\n        c = _5421;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _5429 = fa_srgb_to_linear(param_1);\n            c = _5429;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _423;\n    if (i.front_facing)\n    {\n        _423 = i.world_normal;\n    }\n    else\n    {\n        _423 = -i.world_normal;\n    }\n    float3 _447 = normalize(i.world_tangent.xyz - (_423 * dot(_423, i.world_tangent.xyz)));\n    float3 _475 = normalize(((_447 * m.x) + ((cross(_423, _447) * i.world_tangent.w) * m.y)) + (_423 * m.z));\n    float3 _478;\n    if (i.front_facing)\n    {\n        _478 = _475;\n    }\n    else\n    {\n        _478 = -_475;\n    }\n    return _478;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _491_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _5460 = fa_tex_fix(param_2, param_3);\n    float4 _6875 = base_t;\n    _6875.x = _5460.x;\n    _6875.y = _5460.y;\n    _6875.z = _5460.z;\n    base_t = _6875;\n    float4 _5474 = (_6875 * _491_fa_base_color) * i.vertex_color;\n    float3 _6713 = i.world_normal;\n    if (_491_fa_maps.z > 0.5f)\n    {\n        float param_4 = _491_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _5506 = fa_tex_fix(param_6, param_7);\n        float3 _5509 = (_5506 * 2.0f) - 1.0f.xxx;\n        float2 _5514 = _5509.xy * _491_fa_maps.x;\n        float3 _6883 = _5509;\n        _6883.x = _5514.x;\n        _6883.y = _5514.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _6883;\n        _6713 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _491_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _5542 = fa_tex_fix(param_12, param_13);\n    float4 _6886 = mrt;\n    _6886.x = _5542.x;\n    _6886.y = _5542.y;\n    _6886.z = _5542.z;\n    mrt = _6886;\n    float4 _5570 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _491_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _5570.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _5581 = fa_tex_fix(param_16, param_17);\n    float param_18 = _491_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _5611 = fa_tex_fix(param_20, param_21);\n    float _6718 = _491_fa_layers_a.x;\n    float _6719 = _491_fa_layers_a.y;\n    float _6722 = _491_fa_layers_a.z;\n    float _6721 = _491_fa_layers_b.w;\n    float _6724 = _491_fa_layers_c.x;\n    if (_491_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_491_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _6718 *= _5581.y;\n            _6719 *= _5581.z;\n            _6721 *= _5570.w;\n        }\n        if (_491_fa_layers_c.z > 1.5f)\n        {\n            _6722 *= mrt.x;\n            _6724 *= mrt.w;\n        }\n    }\n    Surface _6743 = { _5474.xyz, _5474.w, _6713, clamp(_491_fa_pbr.x * _5542.z, 0.0f, 1.0f), clamp(_491_fa_pbr.y * _5542.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_491_fa_maps.y * (_5581.x - 1.0f)), _491_fa_emissive.xyz + (_491_fa_model_emissive.xyz * _5611), _6718, _6719, _491_fa_layers_b.xyz, _6721, _6722, _491_fa_layers_a.w, _6724, _491_fa_layers_c.y, _491_fa_layers_d.xyz };\n    return _6743;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * _5369_boost);\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1700 = rect.zw - rect.xy;\n    float2 _1704 = _1700 * atlas;\n    float2 _1708 = ddx * _1704;\n    float2 _1712 = ddy * _1704;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1700), clamp(0.5f * log2(max(max(dot(_1708, _1708), dot(_1712, _1712)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1745 = _491_fa_counts.y < 0.5f;\n    bool _1752;\n    if (!_1745)\n    {\n        _1752 = _491_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1752 = _1745;\n    }\n    if (_1752)\n    {\n        return;\n    }\n    float3 _1758 = ddx(world_pos);\n    float3 _1761 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1765 = fa_cluster_texel(param);\n    int _1769 = int(_1765.w);\n    if (_1769 < 1)\n    {\n        return;\n    }\n    int _1779 = int(_491_fa_counts.y + 0.5f);\n    int param_1 = _1779;\n    float4 _1783 = fa_light_texel(param_1);\n    float2 _1786 = _1783.yz;\n    int _1790 = int(_1783.w);\n    int param_2 = _1779 + 1;\n    float4 _1795 = fa_light_texel(param_2);\n    float _1796 = _1795.x;\n    int _1802 = int(_491_fa_counts.w + 0.5f) - 1;\n    int _1806 = int(_1765.z);\n    float3 _2071;\n    for (int k = 0; k < _1769; k++)\n    {\n        int _1819 = _1806 + k;\n        int param_3 = _1790 + (_1819 >> 2);\n        int _1836 = (_1779 + 2) + (int(fa_light_texel(param_3)[_1819 & 3]) * 7);\n        int param_4 = _1836 + 6;\n        float4 _1841 = fa_light_texel(param_4);\n        if (((int(_1841.w + 0.5f) >> _1802) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1836;\n        float4 _1856 = fa_light_texel(param_5);\n        int param_6 = _1836 + 1;\n        float4 _1861 = fa_light_texel(param_6);\n        int param_7 = _1836 + 2;\n        float4 _1866 = fa_light_texel(param_7);\n        float3 _1869 = _1856.xyz;\n        float _1874 = dot(_1869, world_pos) + _1856.w;\n        float3 _1876 = _1861.xyz;\n        float _1881 = dot(_1876, world_pos) + _1861.w;\n        float3 _1883 = _1866.xyz;\n        float _1888 = dot(_1883, world_pos) + _1866.w;\n        bool _1893 = abs(_1874) > 0.5f;\n        bool _1901;\n        if (!_1893)\n        {\n            _1901 = abs(_1881) > 0.5f;\n        }\n        else\n        {\n            _1901 = _1893;\n        }\n        bool _1909;\n        if (!_1901)\n        {\n            _1909 = abs(_1888) > 0.5f;\n        }\n        else\n        {\n            _1909 = _1901;\n        }\n        if (_1909)\n        {\n            continue;\n        }\n        float _1924 = clamp(dot(geo_normal, normalize(_1883)) * _1841.z, 0.0f, 1.0f);\n        if (_1924 <= 0.0f)\n        {\n            continue;\n        }\n        float _1944 = (clamp((0.5f - abs(_1888)) * 10.0f, 0.0f, 1.0f) * _1924) * _1841.x;\n        float2 _1952 = float2(_1874 + 0.5f, 0.5f - _1881);\n        float2 _1962 = float2(dot(_1869, _1758), dot(_1876, _1758));\n        float2 _1972 = float2(dot(_1869, _1761), dot(_1876, _1761));\n        int param_8 = _1836 + 5;\n        float4 _1977 = fa_light_texel(param_8);\n        int param_9 = _1836 + 3;\n        float4 _1982 = fa_light_texel(param_9);\n        int param_10 = _1836 + 4;\n        float4 _1987 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1977.xyz;\n        bool _1997 = _1982.z > _1982.x;\n        if (_1997)\n        {\n            float4 param_11 = _1982;\n            float2 param_12 = _1952;\n            float2 param_13 = _1786;\n            float2 param_14 = _1962;\n            float2 param_15 = _1972;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1796 > 0.5f) && (_1796 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _2023 = fa_dc_to_linear(param_16);\n                float4 _6793 = tx;\n                _6793.x = _2023.x;\n                _6793.y = _2023.y;\n                _6793.z = _2023.z;\n                tx = _6793;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1944 * tex_a) * _1977.w, 0.0f, 1.0f).xxx);\n        if (_1987.z > _1987.x)\n        {\n            float4 param_17 = _1987;\n            float2 param_18 = _1952;\n            float2 param_19 = _1786;\n            float2 param_20 = _1962;\n            float2 param_21 = _1972;\n            float4 _2067 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1796 > 1.5f)\n            {\n                float3 param_22 = _2067.xyz;\n                float3 _2077 = fa_dc_to_srgb(param_22);\n                _2071 = _2077;\n            }\n            else\n            {\n                _2071 = _2067.xyz;\n            }\n            float3 _2086 = (_2071 * 2.0f) - 1.0f.xxx;\n            float2 _2091 = _2086.xy * _1841.y;\n            float3 _2113 = (normalize(_1869) * _2091.x) + (normalize(_1876) * _2091.y);\n            float3 _2116 = normalize(normal);\n            normal = normalize(lerp(_2116, normalize((_2116 * max(_2086.z, 0.0500000007450580596923828125f)) + (_2113 - (_2116 * dot(_2116, _2113)))), clamp(_1944 * (_1997 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3417 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3425 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3428 = int(_3417);\n    int _3431 = int(_3425);\n    float _3441 = _3425 - float(_3431);\n    int _3497 = (_3428 * 9) + _3431;\n    int _3517 = ((_3428 + 1) * 9) + _3431;\n    return lerp(lerp(_3492[_3497], _3492[_3497 + 1], _3441), lerp(_3492[_3517], _3492[_3517 + 1], _3441), _3417 - float(_3428));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _6636 = false;\n    float _6637 = 1.0f;\n    float _6638 = 1.0f;\n    float _6639 = 1.0f;\n    float _6640 = 0.0f;\n    float _6641 = 0.0f;\n    float _6642 = 0.0f;\n    float _6643 = 0.0f;\n    float _6645 = 1.0f;\n    bool _6646 = false;\n    float3 _6647 = 0.0f.xxx;\n    float _6648 = 1.0f;\n    float _6649 = 1.0f;\n    float _6650 = 1.0f;\n    float _6651 = 0.0f;\n    float _6652 = 0.0f;\n    float3 _6653 = float3(1.0f, 0.0f, 0.0f);\n    float3 _6654 = float3(0.0f, 0.0f, 1.0f);\n    float _6655 = 1.0f;\n    float _6656 = 1.0f;\n    float _3568 = clamp(s.specular, 0.0f, 1.0f);\n    float _3572 = clamp(s.ior, 1.0f, 3.0f);\n    bool _3577 = (_3568 != 1.0f) || (_3572 != 1.5f);\n    bool _3586;\n    if (!_3577)\n    {\n        _3586 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _3586 = _3577;\n    }\n    if (_3586)\n    {\n        float _3594 = (_3572 - 1.0f) / (_3572 + 1.0f);\n        f0 = lerp(min((_3594 * _3594).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _3568, s.albedo, metallic.xxx);\n        _6637 = lerp(_3568, 1.0f, metallic);\n        _6636 = true;\n    }\n    float _3621 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_3621 > 0.0f)\n    {\n        float _3629 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _6640 = _3621;\n        _6641 = _3629;\n        float _3636 = _3629 * _3629;\n        _6642 = _3636;\n        _6643 = _3636 * _3636;\n        float _3648 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _6645 = _3648;\n        _6638 = 1.0f - (_3621 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _3648, 0.0f, 1.0f), 5.0f))));\n        _6636 = true;\n    }\n    float3 _3668 = max(s.sheen_color, 0.0f.xxx);\n    float _3677 = max(_3668.x, max(_3668.y, _3668.z));\n    if (_3677 > 0.0f)\n    {\n        float _3685 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _6646 = true;\n        _6647 = _3668;\n        _6648 = _3685;\n        _6649 = _3685 * _3685;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _3685;\n        float _3702 = fa_sheen_albedo(param, param_1);\n        _6651 = _3702;\n        _6650 = 1.0f - min(_3677 * _3702, 1.0f);\n        _6636 = true;\n    }\n    _6639 = _6638 * _6650;\n    float _3721 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_3721 != 0.0f)\n    {\n        float3 _3736 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _3736;\n        if (dot(_3736, _3736) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _3748 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_3748.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _3748.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _3748.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _3752 = t;\n        float3 _3753 = normalize(_3752);\n        t = _3753;\n        float3 _3778 = normalize((_3753 * cos(s.anisotropy_rotation)) + ((cross(n, _3753) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _6653 = _3778;\n        _6654 = cross(n, _3778);\n        float _3788 = roughness * roughness;\n        float _3794 = lerp(_3788, 1.0f, _3721 * _3721);\n        bool _3796 = _3721 > 0.0f;\n        _6655 = _3796 ? _3794 : _3788;\n        _6656 = _3796 ? _3788 : _3794;\n        _6652 = _3721;\n        _6636 = true;\n    }\n    FaLayers _6678 = { _6636, _6637, _6638, _6639, _6640, _6641, _6642, _6643, i.world_normal, _6645, _6646, _6647, _6648, _6649, _6650, _6651, _6652, _6653, _6654, _6655, _6656 };\n    return _6678;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_491_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _491_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_491_fa_cl_info.x) + int(_491_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_491_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _562_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _562_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _728 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _741 = (c - (ru * hx)) - p;\n        float3 _747 = ru * (2.0f * hx);\n        float _753 = max(dot(_747, _747), 9.9999999392252902907785028219223e-09f);\n        float _757 = dot(_741, _747);\n        float t = clamp((-_757) / _753, 0.0f, 1.0f);\n        if (_728)\n        {\n            float _772 = dot(r, _747);\n            float _778 = _753 - (_772 * _772);\n            if (abs(_778) > (9.9999997473787516355514526367188e-06f * _753))\n            {\n                t = clamp(((dot(r, _741) * _772) - _757) / _778, 0.0f, 1.0f);\n            }\n        }\n        return (p + _741) + (_747 * t);\n    }\n    float3 q = p;\n    float _810 = dot(r, axis);\n    bool _818;\n    if (_728)\n    {\n        _818 = abs(_810) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _818 = _728;\n    }\n    if (_818)\n    {\n        float _828 = dot(c - p, axis) / _810;\n        if (_828 > 0.0f)\n        {\n            q = p + (r * _828);\n        }\n    }\n    float3 _841 = q - c;\n    float2 xy = float2(dot(_841, ru), dot(_841, uu));\n    if (shape > 0.5f)\n    {\n        float _856 = length(xy);\n        if (_856 > hx)\n        {\n            xy *= (hx / _856);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _649 = abs(d);\n    float _651 = _649.x;\n    float _653 = _649.y;\n    bool _654 = _651 >= _653;\n    bool _662;\n    if (_654)\n    {\n        _662 = _651 >= _649.z;\n    }\n    else\n    {\n        _662 = _654;\n    }\n    int _663;\n    if (_662)\n    {\n        _663 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _676;\n        if (_653 >= _649.z)\n        {\n            _676 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _676 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _663 = _676;\n    }\n    return _663;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _602 = dot(d, right);\n    float _606 = dot(d, up);\n    float _617;\n    if (((_602 * _602) + (_606 * _606)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _617 = atan2(_606, _602) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _617 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_617 - floor(_617)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _894 = fa_light_base(param);\n    bool _898 = _491_fa_ambient.w > 4.5f;\n    int param_1 = _894;\n    float4 _902 = fa_light_texel(param_1);\n    int param_2 = _894 + 1;\n    float4 _907 = fa_light_texel(param_2);\n    float _910 = _907.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _922 = _898 && (_910 > 2.5f);\n    fa_light_is_area = _922;\n    bool _924 = _910 < 0.5f;\n    float3 l;\n    if (_924)\n    {\n        l = normalize(_902.xyz);\n        if (_898)\n        {\n            int param_3 = _894 + 6;\n            float4 _938 = fa_light_texel(param_3);\n            if (_938.z > 0.5f)\n            {\n                int param_4 = _894 + 4;\n                float4 _948 = fa_light_texel(param_4);\n                int param_5 = _894 + 5;\n                float4 _953 = fa_light_texel(param_5);\n                float2 param_6 = _938.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _948.xyz) * _948.w, (-dot(world_pos, _953.xyz)) * _953.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _983 = _902.xyz;\n        float3 _985 = _983 - world_pos;\n        float3 to_light = _985;\n        float _988 = length(_985);\n        float reach = _988;\n        bool front = true;\n        if (_922)\n        {\n            int param_8 = _894 + 7;\n            reach = max(_988 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _894 + 4;\n            float4 _1012 = fa_light_texel(param_9);\n            int param_10 = _894 + 5;\n            float4 _1017 = fa_light_texel(param_10);\n            int param_11 = _894 + 6;\n            float4 _1022 = fa_light_texel(param_11);\n            float _1023 = _1022.w;\n            int param_12 = _894 + 2;\n            float3 _1030 = normalize(fa_light_texel(param_12).xyz);\n            bool _1032 = _1023 > 1.5f;\n            bool _1040;\n            if (!_1032)\n            {\n                _1040 = dot(_1030, to_light) < 0.0f;\n            }\n            else\n            {\n                _1040 = _1032;\n            }\n            front = _1040;\n            float3 r = 0.0f.xxx;\n            if (dot(n, n) > 0.5f)\n            {\n                r = reflect(-normalize(_491_fa_camera_pos.xyz - world_pos), normalize(n));\n            }\n            float3 param_13 = _983;\n            float3 param_14 = _1030;\n            float3 param_15 = _1012.xyz;\n            float3 param_16 = _1017.xyz;\n            float param_17 = _1012.w;\n            float param_18 = _1017.w;\n            float param_19 = _1023;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1087 = length(to_light);\n        dist = _1087;\n        l = to_light / max(_1087, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1101 = reach / max(_902.w, 0.001000000047497451305389404296875f);\n        float _1107 = clamp(1.0f - (_1101 * _1101), 0.0f, 1.0f);\n        float _1109;\n        if (front)\n        {\n            _1109 = _1107 * _1107;\n        }\n        else\n        {\n            _1109 = 0.0f;\n        }\n        atten = _1109;\n        bool _1120 = _910 < 2.5f;\n        if ((_910 > 1.5f) && _1120)\n        {\n            int param_22 = _894 + 2;\n            float4 _1128 = fa_light_texel(param_22);\n            float _1138 = _1128.w;\n            int param_23 = _894 + 3;\n            float4 _1143 = fa_light_texel(param_23);\n            float _1144 = _1143.x;\n            float cos_inner = _1144;\n            if (_1144 > 1.5f)\n            {\n                cos_inner = lerp(_1138, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1138, cos_inner, dot(-l, normalize(_1128.xyz)));\n        }\n        if (_898 && (_910 < 1.5f))\n        {\n            int param_24 = _894 + 6;\n            float4 _1168 = fa_light_texel(param_24);\n            if (_1168.z > 0.5f)\n            {\n                float3 _1176 = -to_light;\n                int param_25 = _894 + 4;\n                int param_26 = _894 + 5;\n                float3 _1190 = fa_light_texel(param_25).xyz;\n                float3 _1194 = fa_light_texel(param_26).xyz;\n                float3 _1203 = float3(dot(_1176, _1190), dot(_1176, _1194), dot(_1176, cross(_1190, _1194)));\n                float3 param_27 = _1203;\n                int _1207 = fa_cube_face(param_27);\n                int param_28 = _1207;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1234 = float2(dot(_1203, cross(param_29, param_30)), dot(_1203, param_30)) / max(dot(_1203, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1238 = _1207 / 3;\n                float2 param_31 = _1168.xy + (float2(float(_1207 - (_1238 * 3)), float(_1238)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1234.x), 0.5f - (0.5f * _1234.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _894 + 7;\n            float4 _1268 = fa_light_texel(param_33);\n            if (_1268.z > 0.5f)\n            {\n                int param_34 = _894 + 2;\n                int param_35 = _894 + 4;\n                int param_36 = _894 + 5;\n                float2 param_37 = _1268.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_898 && _1120)\n            {\n                int param_42 = _894 + 6;\n                float4 _1315 = fa_light_texel(param_42);\n                int param_43 = _894 + 7;\n                float4 _1320 = fa_light_texel(param_43);\n                bool _1323 = _1315.z > 0.5f;\n                bool _1330;\n                if (!_1323)\n                {\n                    _1330 = _1320.z > 0.5f;\n                }\n                else\n                {\n                    _1330 = _1323;\n                }\n                if (_1330)\n                {\n                    int param_44 = _894 + 2;\n                    float4 _1337 = fa_light_texel(param_44);\n                    float3 _1341 = normalize(_1337.xyz);\n                    int param_45 = _894 + 4;\n                    float4 _1346 = fa_light_texel(param_45);\n                    int param_46 = _894 + 5;\n                    float4 _1351 = fa_light_texel(param_46);\n                    if (_1323)\n                    {\n                        float3 _1359 = -to_light;\n                        float _1366 = _1337.w;\n                        float _1382 = 0.5f / max(dot(_1359, _1341) * (sqrt(max(1.0f - (_1366 * _1366), 0.0f)) / max(_1366, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1315.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1359, _1346.xyz) * _1382), 0.5f - (dot(_1359, _1351.xyz) * _1382));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1320.z > 0.5f)\n                    {\n                        float2 param_49 = _1320.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1341;\n                        float3 param_52 = _1346.xyz;\n                        float3 param_53 = _1351.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _6624 = _907.xyz * atten;\n    if (_898)\n    {\n        _6624 *= fa_light_tint;\n    }\n    int _1451;\n    if (_924)\n    {\n        _1451 = 0;\n    }\n    else\n    {\n        _1451 = ((_910 > 1.5f) && (_910 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _6635 = { l, _6624, atten, 1.0f, dist, _1451 };\n    return _6635;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2188;\n    if (i == 0)\n    {\n        _2188 = _2198_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2204;\n        if (i == 1)\n        {\n            _2204 = _2198_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2212;\n            if (i == 2)\n            {\n                _2212 = _2198_fa_shadow_split.z;\n            }\n            else\n            {\n                _2212 = _2198_fa_shadow_split.w;\n            }\n            _2204 = _2212;\n        }\n        _2188 = _2204;\n    }\n    return _2188;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2245 = fa_shadow_depth(param, param_1);\n    float _2249;\n    if (conv.x < 0.5f)\n    {\n        _2249 = _2245;\n    }\n    else\n    {\n        _2249 = (conv.y * conv.z) / (conv.z - (_2245 * (conv.z - conv.y)));\n    }\n    return _2249;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2176 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2176), sin(_2176)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2295 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2304;\n        if (k < 0.0f)\n        {\n            _2304 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2304 = k;\n        }\n        float _2324 = clamp((_2304 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2295;\n            float2 _2343 = fa_shadow_vogel(param_3, param_4, param_5) * _2324;\n            float2 param_6 = uv + (_2343 * _2198_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2355 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2355 < (zr - (length(_2343) * plane)))\n            {\n                sum += _2355;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2381 = sum / cnt;\n        float _2391;\n        if (k < 0.0f)\n        {\n            _2391 = (-k) / max(_2381, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2391 = k;\n        }\n        radius = clamp(((max(zr - _2381, 0.0f) * unit) * _2391) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2413 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2413; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2413;\n        float param_11 = _2295;\n        float2 _2432 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2432 * _2198_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2432) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2413);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2474 = max(_2198_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2479 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2485 = sqrt(1.0f - (_2479 * _2479));\n    float _2492 = min(_2485 / max(_2479, 0.20000000298023223876953125f), 4.0f);\n    float _2497;\n    if (_2198_fa_shadow_bias.y > 0.0f)\n    {\n        _2497 = _2198_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2497 = 1.5f * _2198_fa_shadow_info[ci].x;\n    }\n    float4 _2522 = mul(float4(world + (n * (_2497 * _2485)), 1.0f), _2198_fa_shadow_mat[ci]);\n    float _2529 = _2522.x;\n    bool _2532 = _2529 < _2198_fa_shadow_rect[ci].x;\n    bool _2541;\n    if (!_2532)\n    {\n        _2541 = _2529 > _2198_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2541 = _2532;\n    }\n    bool _2550;\n    if (!_2541)\n    {\n        _2550 = _2522.y < _2198_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2550 = _2541;\n    }\n    bool _2559;\n    if (!_2550)\n    {\n        _2559 = _2522.y > _2198_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2559 = _2550;\n    }\n    bool _2566;\n    if (!_2559)\n    {\n        _2566 = _2522.z > 1.0f;\n    }\n    else\n    {\n        _2566 = _2559;\n    }\n    if (_2566)\n    {\n        return -1.0f;\n    }\n    float _2574;\n    if (_2198_fa_shadow_bias.x > 0.0f)\n    {\n        _2574 = _2198_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2574 = 1.5f * _2198_fa_shadow_info[ci].x;\n    }\n    float2 param = _2522.xy;\n    float4 param_1 = _2198_fa_shadow_rect[ci];\n    float param_2 = _2522.z - ((_2574 * (1.0f + (0.5f * _2492))) / _2474);\n    float param_3 = _2198_fa_shadow_info[ci].x;\n    float param_4 = _2474;\n    float param_5 = _2474 * 0.25f;\n    float param_6 = ((_2198_fa_shadow_info[ci].x * min(_2492, 3.0f)) * 0.5f) / _2474;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2198_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2198_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_491_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2962 = int(_2198_fa_shadow_cfg.x + 0.5f);\n    if (_2962 < 1)\n    {\n        return 1.0f;\n    }\n    float _2977 = dot(world - _2198_fa_shadow_eye.xyz, _2198_fa_shadow_fwd.xyz);\n    int param = _2962 - 1;\n    if (_2977 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2989 = _2962 > 1;\n    bool _2996;\n    if (_2989)\n    {\n        _2996 = _2977 > _2198_fa_shadow_split.x;\n    }\n    else\n    {\n        _2996 = _2989;\n    }\n    if (_2996)\n    {\n        ci = 1;\n    }\n    bool _3000 = _2962 > 2;\n    bool _3007;\n    if (_3000)\n    {\n        _3007 = _2977 > _2198_fa_shadow_split.y;\n    }\n    else\n    {\n        _3007 = _3000;\n    }\n    if (_3007)\n    {\n        ci = 2;\n    }\n    bool _3011 = _2962 > 3;\n    bool _3018;\n    if (_3011)\n    {\n        _3018 = _2977 > _2198_fa_shadow_split.z;\n    }\n    else\n    {\n        _3018 = _3011;\n    }\n    if (_3018)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2962)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _3044 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3044;\n        if (_3044 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2198_fa_shadow_cfg.y > 0.0f)\n    {\n        float _3069;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3069 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3069 = _2198_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _3088 = _2198_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3069, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _3099 = clamp((_2977 - (fa_shadow_split_at(param_7) - _3088)) / _3088, 0.0f, 1.0f);\n        if (_3099 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2962)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _3120 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3120;\n                if (_3120 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _3099);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _2632 = _491_fa_pbr.z < 0.5f;\n    bool _2639;\n    if (!_2632)\n    {\n        _2639 = _2198_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2639 = _2632;\n    }\n    if (_2639)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2198_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2652 = fa_light_texel(param);\n    float _2653 = _2652.x;\n    if (_2653 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2662 = int(_2653 + 0.5f);\n    int param_1 = _2662;\n    float4 _2666 = fa_light_texel(param_1);\n    int param_2 = _2662 + 1;\n    float4 _2671 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2674 = _2666.y;\n    if (_2674 > 0.0f)\n    {\n        float _2691 = 1.0f - smoothstep(0.75f * _2674, _2674, length(world - _2198_fa_shadow_eye.xyz));\n        fade = _2691;\n        if (_2691 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2666.x > 1.5f)\n    {\n        int param_3 = li;\n        int param_4 = fa_light_base(param_3);\n        float3 param_5 = world - fa_light_texel(param_4).xyz;\n        face = fa_cube_face(param_5);\n    }\n    int _2720 = (_2662 + 2) + (face * 6);\n    int param_6 = _2720;\n    int param_7 = _2720 + 1;\n    int param_8 = _2720 + 3;\n    float4 _2734 = fa_light_texel(param_8);\n    int param_9 = _2720 + 4;\n    float4 _2739 = fa_light_texel(param_9);\n    int param_10 = _2720 + 5;\n    float4 _2744 = fa_light_texel(param_10);\n    float _2756 = _2744.x * max(dot(_2734, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2761 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2784 = clamp(dot(n, _2734.xyz), -1.0f, 1.0f);\n    int param_11 = li;\n    int param_12 = fa_light_base(param_11);\n    float _2808 = min(sqrt(1.0f - (_2784 * _2784)) / max(abs(dot(n, world - fa_light_texel(param_12).xyz)) / max(dot(_2734, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2811 = _2671.y;\n    float _2813;\n    if (_2811 > 0.0f)\n    {\n        _2813 = _2811;\n    }\n    else\n    {\n        _2813 = 1.5f * _2756;\n    }\n    float4 _2833 = float4(world + (n * (_2813 * sqrt(1.0f - (_2761 * _2761)))), 1.0f);\n    float _2837 = dot(_2734, _2833);\n    float _2840 = _2744.y;\n    if (_2837 < _2840)\n    {\n        return 1.0f;\n    }\n    float2 _2855 = float2(dot(fa_light_texel(param_6), _2833), dot(fa_light_texel(param_7), _2833)) / _2837.xx;\n    float _2857 = _2855.x;\n    bool _2860 = _2857 < _2739.x;\n    bool _2869;\n    if (!_2860)\n    {\n        _2869 = _2857 > _2739.z;\n    }\n    else\n    {\n        _2869 = _2860;\n    }\n    bool _2878;\n    if (!_2869)\n    {\n        _2878 = _2855.y < _2739.y;\n    }\n    else\n    {\n        _2878 = _2869;\n    }\n    bool _2887;\n    if (!_2878)\n    {\n        _2887 = _2855.y > _2739.w;\n    }\n    else\n    {\n        _2887 = _2878;\n    }\n    if (_2887)\n    {\n        return 1.0f;\n    }\n    float _2893 = _2671.x;\n    float _2895;\n    if (_2893 > 0.0f)\n    {\n        _2895 = _2893;\n    }\n    else\n    {\n        _2895 = 1.5f * _2756;\n    }\n    float2 param_13 = _2855;\n    float4 param_14 = _2739;\n    float param_15 = _2837 - (_2895 * (1.0f + (0.5f * _2808)));\n    float param_16 = _2756;\n    float param_17 = 1.0f;\n    float param_18 = _2744.z * 0.25f;\n    float param_19 = (_2756 * min(_2808, 3.0f)) * 0.5f;\n    float3 param_20 = float3(1.0f, _2840, _2744.z);\n    int param_21 = int(_2666.z + 0.5f);\n    float param_22 = _2666.w;\n    return lerp(1.0f, fa_shadow_filter(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _4340 = fa_lm.z > 0.5f;\n    bool _4346;\n    if (_4340)\n    {\n        int param = li;\n        _4346 = fa_light_baked(param);\n    }\n    else\n    {\n        _4346 = _4340;\n    }\n    if (_4346)\n    {\n        int param_1 = li;\n        LightSample _6691 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _6691;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4370 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _6693 = _4370.color;\n    float _6695 = _4370.shadow;\n    if ((_4370.type == 0) && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4370.direction;\n        float _4384 = fa_shadow_factor(param_5, param_6);\n        _6695 = _4384;\n        _6693 *= _4384;\n    }\n    else\n    {\n        bool _4395 = _4370.type != 0;\n        bool _4401;\n        if (_4395)\n        {\n            _4401 = _4370.attenuation > 0.0f;\n        }\n        else\n        {\n            _4401 = _4395;\n        }\n        if (_4401)\n        {\n            int param_7 = li;\n            float3 param_8 = world_pos;\n            float3 param_9 = gn;\n            float3 param_10 = _4370.direction;\n            float _4413 = fa_shadow_local(param_7, param_8, param_9, param_10);\n            _6695 = _4413;\n            _6693 *= _4413;\n        }\n    }\n    LightSample _6710 = { _4370.direction, _6693, _4370.attenuation, _6695, _4370._distance, _4370.type };\n    return _6710;\n}\n\nfloat3 fa_ltc_tangent(float3 n, float3 v)\n{\n    float3 _4453 = v - (n * dot(v, n));\n    float3 t = _4453;\n    float _4457 = dot(_4453, _4453);\n    float l2 = _4457;\n    if (_4457 < 1.0000000133514319600180897396058e-10f)\n    {\n        float3 _4467;\n        if (abs(n.z) < 0.999000012874603271484375f)\n        {\n            _4467 = cross(n, float3(0.0f, 0.0f, 1.0f));\n        }\n        else\n        {\n            _4467 = cross(n, float3(1.0f, 0.0f, 0.0f));\n        }\n        t = _4467;\n        l2 = dot(_4467, _4467);\n    }\n    return t * rsqrt(l2);\n}\n\nfloat3 fa_ltc_local(float3 t1, float3 n, float3 p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nfloat3 fa_ltc_edge_vector(float3 a, float3 b)\n{\n    float _4502 = dot(a, a);\n    float _4506 = dot(b, b);\n    if ((_4502 < 1.0000000195414813782625560981111e-24f) || (_4506 < 1.0000000195414813782625560981111e-24f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _4520 = a * rsqrt(_4502);\n    float3 _4525 = b * rsqrt(_4506);\n    float _4529 = dot(_4520, _4525);\n    float _4532 = abs(_4529);\n    float g = (((((((((((0.0416471660137176513671875f * _4532) - 0.1924748718738555908203125f) * _4532) + 0.4179156124591827392578125f) * _4532) - 0.616057217121124267578125f) * _4532) + 0.777722418308258056640625f) * _4532) - 0.999542415142059326171875f) * _4532) + 1.570791721343994140625f;\n    if (_4529 < 0.0f)\n    {\n        g = (3.1415927410125732421875f * rsqrt(max(1.0f - (_4529 * _4529), 1.0000000116860974230803549289703e-07f))) - g;\n    }\n    return cross(_4520, _4525) * g;\n}\n\nvoid fa_ltc_clip_edge(float3 a, float3 b, inout float3 sum, inout float3 leave, inout float3 enter, inout float2 seen)\n{\n    bool _4589 = a.z > 0.0f;\n    bool _4593 = b.z > 0.0f;\n    if (_4589 && _4593)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_4589 != _4593)\n        {\n            float3 _4628 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _4628.z = 0.0f;\n            if (_4589)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _4628;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _4628;\n                seen.x = 1.0f;\n            }\n            else\n            {\n                float3 param_4 = _4628;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _4628;\n                seen.y = 1.0f;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(float4 abcd, float3 p0, float3 p1, float3 p2, float3 p3)\n{\n    float3 _4677 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _4703 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _4729 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _4755 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = 0.0f.xxx;\n    float3 leave = 0.0f.xxx;\n    float3 enter = 0.0f.xxx;\n    float3 param = _4677;\n    float3 param_1 = _4703;\n    float3 param_2 = 0.0f.xxx;\n    float3 param_3 = 0.0f.xxx;\n    float3 param_4 = 0.0f.xxx;\n    float2 param_5 = 0.0f.xx;\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _4703;\n    float3 param_7 = _4729;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _4729;\n    float3 param_13 = _4755;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _4755;\n    float3 param_19 = _4677;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5f)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875f;\n}\n\nfloat fa_ltc_rect(float4 abcd, float3 center, float3 ex, float3 ey)\n{\n    float4 param = abcd;\n    float3 param_1 = (center - ex) - ey;\n    float3 param_2 = (center + ex) - ey;\n    float3 param_3 = (center + ex) + ey;\n    float3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(float4 m, float shape, float3 pc, float3 ex, float3 ey)\n{\n    if ((shape < 0.5f) || (shape > 1.5f))\n    {\n        float4 param = m;\n        float3 param_1 = pc;\n        float3 param_2 = ex;\n        float3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    float3 _4905 = (pc + (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _4929 = (pc - (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _4945 = (pc - (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float4 param_4 = m;\n    float3 param_5 = _4905;\n    float3 param_6 = (pc + (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_7 = (pc - (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_8 = _4929;\n    float4 param_9 = m;\n    float3 param_10 = _4905;\n    float3 param_11 = _4929;\n    float3 param_12 = (pc - (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    float3 param_13 = _4945;\n    float4 param_14 = m;\n    float3 param_15 = _4905;\n    float3 param_16 = _4945;\n    float3 param_17 = (pc + (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float3 param_18 = (pc + (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nfloat2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((float2(clamp((roughness - 0.0500000007450580596923828125f) * 1.0526316165924072265625f, 0.0f, 1.0f), sqrt(clamp(1.0f - ndv, 0.0f, 1.0f))) * 63.0f) + 0.5f.xx) * 0.015625f.xx;\n}\n\nfloat3 fa_area_shade(int li, float3 world_pos, float3 n, float3 v, float3 diffuse_color, float3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _5003 = fa_light_base(param);\n    int param_1 = _5003;\n    int param_2 = _5003 + 1;\n    int param_3 = _5003 + 2;\n    int param_4 = _5003 + 4;\n    float4 _5025 = fa_light_texel(param_4);\n    int param_5 = _5003 + 5;\n    float4 _5030 = fa_light_texel(param_5);\n    int param_6 = _5003 + 6;\n    float4 _5035 = fa_light_texel(param_6);\n    float _5036 = _5035.w;\n    float3 _5041 = fa_light_texel(param_1).xyz - world_pos;\n    bool _5043 = _5036 < 1.5f;\n    bool _5050;\n    if (_5043)\n    {\n        _5050 = dot(normalize(fa_light_texel(param_3).xyz), _5041) >= 0.0f;\n    }\n    else\n    {\n        _5050 = _5043;\n    }\n    if (_5050)\n    {\n        return 0.0f.xxx;\n    }\n    bool _5059 = (_5036 > 0.5f) && _5043;\n    float _5063 = _5059 ? 1.0539000034332275390625f : 1.0f;\n    float3 _5066 = _5025.xyz;\n    float _5068 = _5025.w;\n    float3 _5074 = _5030.xyz;\n    float _5076 = _5030.w;\n    float3 up = _5074 * (_5076 * _5063);\n    float _5082;\n    if (_5059)\n    {\n        _5082 = (3.1415927410125732421875f * _5068) * _5068;\n    }\n    else\n    {\n        _5082 = (4.0f * _5068) * _5076;\n    }\n    if (_5036 > 1.5f)\n    {\n        float3 _5108 = cross(_5066, -_5041);\n        float3 perp = _5108;\n        float _5112 = dot(_5108, _5108);\n        float3 _5115;\n        if (_5112 > 1.0000000133514319600180897396058e-10f)\n        {\n            _5115 = perp * rsqrt(_5112);\n        }\n        else\n        {\n            _5115 = _5074;\n        }\n        perp = _5115;\n        up = _5115 * _5076;\n    }\n    float _5136 = max(_5082, 9.9999999747524270787835121154785e-07f);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _5146 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _5146;\n    float3 param_10 = n;\n    float3 param_11 = _5041;\n    float3 _5154 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_12 = _5146;\n    float3 param_13 = n;\n    float3 param_14 = _5066 * (_5068 * _5063);\n    float3 _5162 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_15 = _5146;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float3 _5170 = fa_ltc_local(param_15, param_16, param_17);\n    float4 param_18 = float4(1.0f, 0.0f, 0.0f, 1.0f);\n    float param_19 = _5036;\n    float3 param_20 = _5154;\n    float3 param_21 = _5162;\n    float3 param_22 = _5170;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    float2 _5189 = fa_ltc_uv(param_23, param_24) * 64.0f;\n    float2 param_25 = _5189;\n    float2 param_26 = _5189 + float2(64.0f, 0.0f);\n    float4 _5199 = fa_atlas_fetch(param_26);\n    float4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _5036;\n    float3 param_29 = _5154;\n    float3 param_30 = _5162;\n    float3 param_31 = _5170;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _5199.x) + ((f90.xxx - f0) * _5199.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875f * dot(_5041, _5041)) + _5136) / _5136) * window);\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4043 = 1.0f / alpha;\n    return ((2.0f + _4043) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _4043)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat fa_layers_coat(FaLayers L, float3 l, float3 h, float vdh)\n{\n    float _4078 = max(dot(L.nc, l), 0.0f);\n    float _4084 = max(dot(L.nc, h), 0.0f);\n    float _4093 = ((_4084 * _4084) * (L.coat_a2 - 1.0f)) + 1.0f;\n    return (((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _4093) * _4093)) * (0.5f / max(lerp((2.0f * _4078) * L.coat_ndv, _4078 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _4078)) * _4078;\n}\n\nfloat3 fa_area_layers(FaLayers L, int li, float3 world_pos, float3 n, float3 v, float3 l, float3 diffuse_color, float3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    float3 param_2 = n;\n    float3 param_3 = v;\n    float3 param_4 = diffuse_color;\n    float3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _5267;\n    if (L.sheen_on)\n    {\n        _5267 = L.sheen_scale;\n    }\n    else\n    {\n        _5267 = 1.0f;\n    }\n    float3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _5267);\n    float3 _5280 = normalize(l + v);\n    int param_10 = li;\n    float3 _5291 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _5300 = max(dot(n, l), 0.0f);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _5280), 0.0f);\n        float param_13 = _5300;\n        float param_14 = ndv;\n        result += ((L.sheen * _5291) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875f) * step(9.9999997473787516355514526367188e-05f, _5300)) * _5300) * L.keep));\n    }\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_15 = L;\n        float3 param_16 = l;\n        float3 param_17 = _5280;\n        float param_18 = max(dot(v, _5280), 0.0f);\n        result += (_5291 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _3946 = tdh / at;\n    float _3950 = bdh / ab;\n    float _3962 = ((_3946 * _3946) + (_3950 * _3950)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _3962) * _3962);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4142 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4221 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _4221) * _4221);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _4142);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _4142));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_17 = L;\n        float3 param_18 = l;\n        float3 param_19 = h;\n        float param_20 = vdh;\n        result += fa_layers_coat(param_17, param_18, param_19, param_20).xxx;\n    }\n    return result;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3349 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3352 = _3349.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3352 * _3352, exp2((-9.27999973297119140625f) * ndv)) * _3352) + _3349.y)) + _3349.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_491_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _491_fa_env_horizon.w).xyz;\n    }\n    float _3255 = rough * rough;\n    float _3285 = 0.60000002384185791015625f * _3255;\n    return lerp(lerp(_491_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_491_fa_env_horizon.xyz, _491_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3255)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3285, 0.0500000007450580596923828125f + _3285, d.y).xxx), ((_491_fa_env_sky.xyz + _491_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3255 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _3829;\n        if (L.aniso >= 0.0f)\n        {\n            _3829 = L.b;\n        }\n        else\n        {\n            _3829 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_3829, v), _3829), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3862 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _3862.x) + (L.f90.xxx * _3862.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3917 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _3917.x) + _3917.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3391 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3391.x) + _3391.y.xxx);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2198_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3144 = int(_2198_fa_shadow_cfg.x + 0.5f);\n    float _3154 = dot(world - _2198_fa_shadow_eye.xyz, _2198_fa_shadow_fwd.xyz);\n    float3 tint_1 = 0.3499999940395355224609375f.xxx;\n    bool _3159 = _3144 > 0;\n    bool _3168;\n    if (_3159)\n    {\n        int param = _3144 - 1;\n        _3168 = _3154 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3168 = _3159;\n    }\n    if (_3168)\n    {\n        tint_1 = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3174 = _3144 > 1;\n        bool _3181;\n        if (_3174)\n        {\n            _3181 = _3154 > _2198_fa_shadow_split.x;\n        }\n        else\n        {\n            _3181 = _3174;\n        }\n        if (_3181)\n        {\n            tint_1 = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3187 = _3144 > 2;\n        bool _3194;\n        if (_3187)\n        {\n            _3194 = _3154 > _2198_fa_shadow_split.y;\n        }\n        else\n        {\n            _3194 = _3187;\n        }\n        if (_3194)\n        {\n            tint_1 = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3200 = _3144 > 3;\n        bool _3207;\n        if (_3200)\n        {\n            _3207 = _3154 > _2198_fa_shadow_split.z;\n        }\n        else\n        {\n            _3207 = _3200;\n        }\n        if (_3207)\n        {\n            tint_1 = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint_1, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _6393 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6393 = -_6393;\n    }\n    float3 _5751 = normalize(_491_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _6406 = { fa_world_pos, _6393, fa_world_tangent, fa_uv, fa_vertex_color, _5751, gl_FrontFacing };\n    SurfaceInput param_1 = _6406;\n    Surface _5759 = fa_standard_surface(param_1);\n    float3 _6424 = _5759.albedo;\n    float _6425 = _5759.alpha;\n    float3 _6426 = _5759.normal;\n    float _6427 = _5759.metallic;\n    float _6428 = _5759.roughness;\n    float _6429 = _5759.occlusion;\n    float3 _6430 = _5759.emission;\n    float _6431 = _5759.clearcoat;\n    float _6432 = _5759.clearcoat_roughness;\n    float3 _6433 = _5759.sheen_color;\n    float _6434 = _5759.sheen_roughness;\n    float _6435 = _5759.anisotropy;\n    float _6436 = _5759.anisotropy_rotation;\n    float _6437 = _5759.specular;\n    float _6438 = _5759.ior;\n    float3 _6439 = _5759.specular_color;\n    SurfaceInput _6414 = { fa_world_pos, _6393, fa_world_tangent, fa_uv, fa_vertex_color, _5751, gl_FrontFacing };\n    SurfaceInput param_2 = _6414;\n    Surface param_3 = _5759;\n    surface(param_2, param_3);\n    _6424 = param_3.albedo;\n    _6425 = param_3.alpha;\n    _6426 = param_3.normal;\n    _6427 = param_3.metallic;\n    _6428 = param_3.roughness;\n    _6429 = param_3.occlusion;\n    _6430 = param_3.emission;\n    _6431 = param_3.clearcoat;\n    _6432 = param_3.clearcoat_roughness;\n    _6433 = param_3.sheen_color;\n    _6434 = param_3.sheen_roughness;\n    _6435 = param_3.anisotropy;\n    _6436 = param_3.anisotropy_rotation;\n    _6437 = param_3.specular;\n    _6438 = param_3.ior;\n    _6439 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _6393;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6424 = param_6;\n    _6426 = param_7;\n    float3 result;\n    if (_491_fa_emissive.w > 0.5f)\n    {\n        result = _6424;\n    }\n    else\n    {\n        float3 _5798 = normalize(_6426);\n        float _5805 = clamp(_6427, 0.0f, 1.0f);\n        float _5809 = clamp(_6428, 0.0500000007450580596923828125f, 1.0f);\n        float _5813 = _5809 * _5809;\n        float _5817 = _5813 * _5813;\n        float _5822 = max(dot(_5798, _5751), 9.9999997473787516355514526367188e-05f);\n        float3 _5828 = _6424 * (1.0f - _5805);\n        float3 _5835 = lerp(0.039999999105930328369140625f.xxx, _6424, _5805.xxx);\n        float3 f0 = _5835;\n        SurfaceInput _6422 = { fa_world_pos, _6393, fa_world_tangent, fa_uv, fa_vertex_color, _5751, gl_FrontFacing };\n        SurfaceInput param_8 = _6422;\n        Surface _6505 = { _6424, _6425, _6426, _6427, _6428, _6429, _6430, _6431, _6432, _6433, _6434, _6435, _6436, _6437, _6438, _6439 };\n        Surface param_9 = _6505;\n        float3 param_10 = _5798;\n        float3 param_11 = _5751;\n        float param_12 = _5805;\n        float param_13 = _5809;\n        float3 param_14 = _5835;\n        FaLayers _5851 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _5798;\n        float3 lit = (fa_indirect_diffuse(param_15) * _5828) * _6429;\n        if (_5851.on)\n        {\n            lit *= _5851.base_scale;\n        }\n        int _5873 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5873; ln++)\n        {\n            int param_16 = ln;\n            int _5886 = fa_cl_light(param_16);\n            bool _5889 = fa_lm.z > 0.5f;\n            bool _5895;\n            if (_5889)\n            {\n                int param_17 = _5886;\n                _5895 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _5895 = _5889;\n            }\n            if (_5895)\n            {\n                continue;\n            }\n            int param_18 = _5886;\n            float3 param_19 = fa_world_pos;\n            float3 param_20 = _6393;\n            LightSample _5907 = fa_light_shadowed(param_18, param_19, param_20);\n            float _5915 = max(dot(_5798, _5907.direction), 0.0f);\n            float _5921 = _5907.attenuation * _5907.shadow;\n            float3 _5926 = normalize(_5907.direction + _5751);\n            float _5931 = max(dot(_5798, _5926), 0.0f);\n            float _5936 = max(dot(_5751, _5926), 0.0f);\n            bool _5943;\n            if (fa_light_is_area)\n            {\n                _5943 = !_5851.on;\n            }\n            else\n            {\n                _5943 = fa_light_is_area;\n            }\n            if (_5943)\n            {\n                int param_21 = _5886;\n                float3 param_22 = fa_world_pos;\n                float3 param_23 = _5798;\n                float3 param_24 = _5751;\n                float3 param_25 = _5828;\n                float3 param_26 = f0;\n                float param_27 = 1.0f;\n                float param_28 = _5809;\n                float param_29 = _5822;\n                float param_30 = _5921;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _5851;\n                    int param_32 = _5886;\n                    float3 param_33 = fa_world_pos;\n                    float3 param_34 = _5798;\n                    float3 param_35 = _5751;\n                    float3 param_36 = _5907.direction;\n                    float3 param_37 = _5828;\n                    float3 param_38 = f0;\n                    float param_39 = _5809;\n                    float param_40 = _5822;\n                    float param_41 = _5921;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_5851.on)\n                    {\n                        FaLayers param_42 = _5851;\n                        float3 param_43 = _5828;\n                        float3 param_44 = f0;\n                        float3 param_45 = _5798;\n                        float3 param_46 = _5751;\n                        float3 param_47 = _5907.direction;\n                        float3 param_48 = _5926;\n                        float param_49 = _5915;\n                        float param_50 = _5822;\n                        float param_51 = _5931;\n                        float param_52 = _5936;\n                        float param_53 = _5813;\n                        float param_54 = _5817;\n                        int param_55 = _5886;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _5921));\n                    }\n                    else\n                    {\n                        float _6049 = ((_5931 * _5931) * (_5817 - 1.0f)) + 1.0f;\n                        int param_56 = _5886;\n                        lit += (((_5828 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _5936, 5.0f))) * (((_5817 / ((3.1415927410125732421875f * _6049) * _6049)) * (0.5f / max(lerp((2.0f * _5915) * _5822, _5915 + _5822, _5813), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _5915))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_5915 * _5921));\n                    }\n                }\n            }\n        }\n        if (_5851.on)\n        {\n            FaLayers param_57 = _5851;\n            float3 param_58 = _5798;\n            float3 param_59 = _5751;\n            float3 param_60 = f0;\n            float param_61 = _5809;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _6429);\n        }\n        else\n        {\n            float3 param_62 = _5798;\n            float3 param_63 = _5751;\n            float3 param_64 = f0;\n            float param_65 = _5809;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _6429);\n        }\n        result = lit;\n    }\n    float3 _6144 = result;\n    float3 _6145 = _6144 + _6430;\n    result = _6145;\n    float3 param_66 = _6145;\n    float3 param_67 = fa_world_pos;\n    result = fa_shadow_debug(param_66, param_67);\n    bool _6154 = _491_fa_fog.w > 0.0f;\n    bool _6161;\n    if (!_6154)\n    {\n        _6161 = _491_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _6161 = _6154;\n    }\n    if (_6161)\n    {\n        float3 _6170 = fa_world_pos - _491_fa_camera_pos.xyz;\n        float _6176 = dot(_6170, _491_fa_fog_c.xyz);\n        bool _6180 = _491_fa_fog_c.w > 0.5f;\n        float _6181;\n        if (_6180)\n        {\n            _6181 = _6176;\n        }\n        else\n        {\n            _6181 = length(_6170);\n        }\n        float _6193 = _6181 - _491_fa_fog_b.x;\n        if (_6193 > 0.0f)\n        {\n            float _6202 = _491_fa_fog.w * _6193;\n            float tau = _6202 * _6202;\n            if (_491_fa_fog_b.y > 0.0f)\n            {\n                float _6218;\n                if (_6180)\n                {\n                    _6218 = fa_world_pos.y - (_491_fa_fog_c.y * _6176);\n                }\n                else\n                {\n                    _6218 = _491_fa_camera_pos.y;\n                }\n                float _6239 = lerp(_6218, fa_world_pos.y, clamp(_491_fa_fog_b.x / _6181, 0.0f, 1.0f));\n                float _6243 = fa_world_pos.y - _6239;\n                float _6248 = _6239 - _491_fa_fog_b.z;\n                float _6253 = fa_world_pos.y - _491_fa_fog_b.z;\n                bool _6256 = _6248 <= 0.0f;\n                bool _6257 = !_6256;\n                bool _6263;\n                if (_6257)\n                {\n                    _6263 = _491_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6263 = _6256;\n                }\n                float _6264;\n                if (_6263)\n                {\n                    _6264 = _491_fa_fog_b.y;\n                }\n                else\n                {\n                    _6264 = _491_fa_fog_b.y * exp(-min(_491_fa_fog_b.w * _6248, 80.0f));\n                }\n                bool _6291;\n                if (_6257)\n                {\n                    _6291 = _491_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6291 = _6256;\n                }\n                float _6292;\n                if (_6291)\n                {\n                    _6292 = _491_fa_fog_b.y * _6248;\n                }\n                else\n                {\n                    _6292 = (_491_fa_fog_b.y * (1.0f - exp(-min(_491_fa_fog_b.w * _6248, 80.0f)))) / _491_fa_fog_b.w;\n                }\n                bool _6317 = _6253 <= 0.0f;\n                bool _6324;\n                if (!_6317)\n                {\n                    _6324 = _491_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6324 = _6317;\n                }\n                float _6325;\n                if (_6324)\n                {\n                    _6325 = _491_fa_fog_b.y * _6253;\n                }\n                else\n                {\n                    _6325 = (_491_fa_fog_b.y * (1.0f - exp(-min(_491_fa_fog_b.w * _6253, 80.0f)))) / _491_fa_fog_b.w;\n                }\n                float _6352;\n                if (abs(_6243) < 0.001000000047497451305389404296875f)\n                {\n                    _6352 = _6264;\n                }\n                else\n                {\n                    _6352 = (_6325 - _6292) / _6243;\n                }\n                tau += (_6193 * max(_6352, 0.0f));\n            }\n            result = lerp(result, _491_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _6425);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_inst_v0 = stage_input.fa_inst_v0;\n    fa_inst_v1 = stage_input.fa_inst_v1;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_491",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2198",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_5369",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _158_fa_view_proj : packoffset(c0);\n    row_major float4x4 _158_fa_light_vp : packoffset(c4);\n    float4 _158_fa_uv_scale : packoffset(c8);\n    float4 _158_fa_time : packoffset(c9);\n    float4 _158_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _205_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_d0;\nstatic float4 fa_inst_d1;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n    float4 fa_inst_d0 : TEXCOORD11;\n    float4 fa_inst_d1 : TEXCOORD12;\n};\n\nstruct SPIRV_Cross_Output\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float3 fa_lm : TEXCOORD7;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float raise;\nstatic float4 tint;\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_205_fa_joint_rows[_196] * weights[i]);\n        r1 += (_205_fa_joint_rows[_196 + 1] * weights[i]);\n        r2 += (_205_fa_joint_rows[_196 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _422 = { mul(float4(position, 1.0f), model).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * _158_fa_uv_scale.xy, color, position };\n    return _422;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _158_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_d0 = stage_input.fa_inst_d0;\n    fa_inst_d1 = stage_input.fa_inst_d1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_inst_v0 = fa_inst_v0;\n    stage_output.fa_inst_v1 = fa_inst_v1;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _3492[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _491_fa_camera_pos : packoffset(c0);\n    float4 _491_fa_ambient : packoffset(c1);\n    float4 _491_fa_base_color : packoffset(c2);\n    float4 _491_fa_emissive : packoffset(c3);\n    float4 _491_fa_model_emissive : packoffset(c4);\n    float4 _491_fa_pbr : packoffset(c5);\n    float4 _491_fa_maps : packoffset(c6);\n    float4 _491_fa_fog : packoffset(c7);\n    float4 _491_fa_fog_b : packoffset(c8);\n    float4 _491_fa_fog_c : packoffset(c9);\n    float4 _491_fa_counts : packoffset(c10);\n    float4 _491_fa_env_sky : packoffset(c11);\n    float4 _491_fa_env_horizon : packoffset(c12);\n    float4 _491_fa_time : packoffset(c13);\n    float4 _491_fa_cl_vpx : packoffset(c14);\n    float4 _491_fa_cl_vpy : packoffset(c15);\n    float4 _491_fa_cl_vpw : packoffset(c16);\n    float4 _491_fa_cl_fwd : packoffset(c17);\n    float4 _491_fa_cl_grid : packoffset(c18);\n    float4 _491_fa_cl_info : packoffset(c19);\n    float4 _491_fa_layers_a : packoffset(c20);\n    float4 _491_fa_layers_b : packoffset(c21);\n    float4 _491_fa_layers_c : packoffset(c22);\n    float4 _491_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2198_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2198_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2198_fa_shadow_info[4] : packoffset(c20);\n    float4 _2198_fa_shadow_split : packoffset(c24);\n    float4 _2198_fa_shadow_cfg : packoffset(c25);\n    float4 _2198_fa_shadow_bias : packoffset(c26);\n    float4 _2198_fa_shadow_eye : packoffset(c27);\n    float4 _2198_fa_shadow_fwd : packoffset(c28);\n    float4 _2198_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _5369_boost : packoffset(c0);\n    float _5369_fa_pad0 : packoffset(c0.y);\n    float _5369_fa_pad1 : packoffset(c0.z);\n    float _5369_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t11);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t10);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float3 fa_lm : TEXCOORD7;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\nstatic float raise;\nstatic float4 tint;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1469 = _491_fa_cl_info.x < 0.0f;\n    bool _1476;\n    if (!_1469)\n    {\n        _1476 = _491_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1476 = _1469;\n    }\n    bool _1484;\n    if (!_1476)\n    {\n        _1484 = _491_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1484 = _1476;\n    }\n    bool _1491;\n    if (!_1484)\n    {\n        _1491 = _491_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1491 = _1484;\n    }\n    bool _1498;\n    if (!_1491)\n    {\n        _1498 = _491_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1498 = _1491;\n    }\n    if (_1498)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1508 = float4(world_pos, 1.0f);\n    float _1514 = dot(_491_fa_cl_vpw, _1508);\n    if (!(_1514 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1536 = float2(dot(_491_fa_cl_vpx, _1508), dot(_491_fa_cl_vpy, _1508)) / _1514.xx;\n    int _1540 = int(_491_fa_cl_grid.x);\n    int _1544 = int(_491_fa_cl_grid.y);\n    int param = (int(_491_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_491_fa_cl_fwd.xyz, world_pos) + _491_fa_cl_fwd.w, _491_fa_cl_grid.w) / _491_fa_cl_grid.w) * _491_fa_cl_grid.z)), 0, int(_491_fa_cl_info.y) - 1) * _1544) + clamp(int(floor(((_1536.y * 0.5f) + 0.5f) * _491_fa_cl_grid.y)), 0, _1544 - 1)) * _1540)) + clamp(int(floor(((_1536.x * 0.5f) + 0.5f) * _491_fa_cl_grid.x)), 0, _1540 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1620 = fa_cluster_texel(param);\n    return int2(int(_1620.x), int(_1620.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_491_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4313 = fa_cluster_lookup(param);\n    fa_cl_slot = _4313.x;\n    fa_cl_local = _4313.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _5421 = fa_linear_to_srgb(param);\n        c = _5421;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _5429 = fa_srgb_to_linear(param_1);\n            c = _5429;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _423;\n    if (i.front_facing)\n    {\n        _423 = i.world_normal;\n    }\n    else\n    {\n        _423 = -i.world_normal;\n    }\n    float3 _447 = normalize(i.world_tangent.xyz - (_423 * dot(_423, i.world_tangent.xyz)));\n    float3 _475 = normalize(((_447 * m.x) + ((cross(_423, _447) * i.world_tangent.w) * m.y)) + (_423 * m.z));\n    float3 _478;\n    if (i.front_facing)\n    {\n        _478 = _475;\n    }\n    else\n    {\n        _478 = -_475;\n    }\n    return _478;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _491_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _5460 = fa_tex_fix(param_2, param_3);\n    float4 _6875 = base_t;\n    _6875.x = _5460.x;\n    _6875.y = _5460.y;\n    _6875.z = _5460.z;\n    base_t = _6875;\n    float4 _5474 = (_6875 * _491_fa_base_color) * i.vertex_color;\n    float3 _6713 = i.world_normal;\n    if (_491_fa_maps.z > 0.5f)\n    {\n        float param_4 = _491_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _5506 = fa_tex_fix(param_6, param_7);\n        float3 _5509 = (_5506 * 2.0f) - 1.0f.xxx;\n        float2 _5514 = _5509.xy * _491_fa_maps.x;\n        float3 _6883 = _5509;\n        _6883.x = _5514.x;\n        _6883.y = _5514.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _6883;\n        _6713 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _491_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _5542 = fa_tex_fix(param_12, param_13);\n    float4 _6886 = mrt;\n    _6886.x = _5542.x;\n    _6886.y = _5542.y;\n    _6886.z = _5542.z;\n    mrt = _6886;\n    float4 _5570 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _491_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _5570.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _5581 = fa_tex_fix(param_16, param_17);\n    float param_18 = _491_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _5611 = fa_tex_fix(param_20, param_21);\n    float _6718 = _491_fa_layers_a.x;\n    float _6719 = _491_fa_layers_a.y;\n    float _6722 = _491_fa_layers_a.z;\n    float _6721 = _491_fa_layers_b.w;\n    float _6724 = _491_fa_layers_c.x;\n    if (_491_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_491_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _6718 *= _5581.y;\n            _6719 *= _5581.z;\n            _6721 *= _5570.w;\n        }\n        if (_491_fa_layers_c.z > 1.5f)\n        {\n            _6722 *= mrt.x;\n            _6724 *= mrt.w;\n        }\n    }\n    Surface _6743 = { _5474.xyz, _5474.w, _6713, clamp(_491_fa_pbr.x * _5542.z, 0.0f, 1.0f), clamp(_491_fa_pbr.y * _5542.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_491_fa_maps.y * (_5581.x - 1.0f)), _491_fa_emissive.xyz + (_491_fa_model_emissive.xyz * _5611), _6718, _6719, _491_fa_layers_b.xyz, _6721, _6722, _491_fa_layers_a.w, _6724, _491_fa_layers_c.y, _491_fa_layers_d.xyz };\n    return _6743;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * _5369_boost);\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1700 = rect.zw - rect.xy;\n    float2 _1704 = _1700 * atlas;\n    float2 _1708 = ddx * _1704;\n    float2 _1712 = ddy * _1704;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1700), clamp(0.5f * log2(max(max(dot(_1708, _1708), dot(_1712, _1712)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1745 = _491_fa_counts.y < 0.5f;\n    bool _1752;\n    if (!_1745)\n    {\n        _1752 = _491_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1752 = _1745;\n    }\n    if (_1752)\n    {\n        return;\n    }\n    float3 _1758 = ddx(world_pos);\n    float3 _1761 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1765 = fa_cluster_texel(param);\n    int _1769 = int(_1765.w);\n    if (_1769 < 1)\n    {\n        return;\n    }\n    int _1779 = int(_491_fa_counts.y + 0.5f);\n    int param_1 = _1779;\n    float4 _1783 = fa_light_texel(param_1);\n    float2 _1786 = _1783.yz;\n    int _1790 = int(_1783.w);\n    int param_2 = _1779 + 1;\n    float4 _1795 = fa_light_texel(param_2);\n    float _1796 = _1795.x;\n    int _1802 = int(_491_fa_counts.w + 0.5f) - 1;\n    int _1806 = int(_1765.z);\n    float3 _2071;\n    for (int k = 0; k < _1769; k++)\n    {\n        int _1819 = _1806 + k;\n        int param_3 = _1790 + (_1819 >> 2);\n        int _1836 = (_1779 + 2) + (int(fa_light_texel(param_3)[_1819 & 3]) * 7);\n        int param_4 = _1836 + 6;\n        float4 _1841 = fa_light_texel(param_4);\n        if (((int(_1841.w + 0.5f) >> _1802) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1836;\n        float4 _1856 = fa_light_texel(param_5);\n        int param_6 = _1836 + 1;\n        float4 _1861 = fa_light_texel(param_6);\n        int param_7 = _1836 + 2;\n        float4 _1866 = fa_light_texel(param_7);\n        float3 _1869 = _1856.xyz;\n        float _1874 = dot(_1869, world_pos) + _1856.w;\n        float3 _1876 = _1861.xyz;\n        float _1881 = dot(_1876, world_pos) + _1861.w;\n        float3 _1883 = _1866.xyz;\n        float _1888 = dot(_1883, world_pos) + _1866.w;\n        bool _1893 = abs(_1874) > 0.5f;\n        bool _1901;\n        if (!_1893)\n        {\n            _1901 = abs(_1881) > 0.5f;\n        }\n        else\n        {\n            _1901 = _1893;\n        }\n        bool _1909;\n        if (!_1901)\n        {\n            _1909 = abs(_1888) > 0.5f;\n        }\n        else\n        {\n            _1909 = _1901;\n        }\n        if (_1909)\n        {\n            continue;\n        }\n        float _1924 = clamp(dot(geo_normal, normalize(_1883)) * _1841.z, 0.0f, 1.0f);\n        if (_1924 <= 0.0f)\n        {\n            continue;\n        }\n        float _1944 = (clamp((0.5f - abs(_1888)) * 10.0f, 0.0f, 1.0f) * _1924) * _1841.x;\n        float2 _1952 = float2(_1874 + 0.5f, 0.5f - _1881);\n        float2 _1962 = float2(dot(_1869, _1758), dot(_1876, _1758));\n        float2 _1972 = float2(dot(_1869, _1761), dot(_1876, _1761));\n        int param_8 = _1836 + 5;\n        float4 _1977 = fa_light_texel(param_8);\n        int param_9 = _1836 + 3;\n        float4 _1982 = fa_light_texel(param_9);\n        int param_10 = _1836 + 4;\n        float4 _1987 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1977.xyz;\n        bool _1997 = _1982.z > _1982.x;\n        if (_1997)\n        {\n            float4 param_11 = _1982;\n            float2 param_12 = _1952;\n            float2 param_13 = _1786;\n            float2 param_14 = _1962;\n            float2 param_15 = _1972;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1796 > 0.5f) && (_1796 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _2023 = fa_dc_to_linear(param_16);\n                float4 _6793 = tx;\n                _6793.x = _2023.x;\n                _6793.y = _2023.y;\n                _6793.z = _2023.z;\n                tx = _6793;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1944 * tex_a) * _1977.w, 0.0f, 1.0f).xxx);\n        if (_1987.z > _1987.x)\n        {\n            float4 param_17 = _1987;\n            float2 param_18 = _1952;\n            float2 param_19 = _1786;\n            float2 param_20 = _1962;\n            float2 param_21 = _1972;\n            float4 _2067 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1796 > 1.5f)\n            {\n                float3 param_22 = _2067.xyz;\n                float3 _2077 = fa_dc_to_srgb(param_22);\n                _2071 = _2077;\n            }\n            else\n            {\n                _2071 = _2067.xyz;\n            }\n            float3 _2086 = (_2071 * 2.0f) - 1.0f.xxx;\n            float2 _2091 = _2086.xy * _1841.y;\n            float3 _2113 = (normalize(_1869) * _2091.x) + (normalize(_1876) * _2091.y);\n            float3 _2116 = normalize(normal);\n            normal = normalize(lerp(_2116, normalize((_2116 * max(_2086.z, 0.0500000007450580596923828125f)) + (_2113 - (_2116 * dot(_2116, _2113)))), clamp(_1944 * (_1997 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3417 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3425 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3428 = int(_3417);\n    int _3431 = int(_3425);\n    float _3441 = _3425 - float(_3431);\n    int _3497 = (_3428 * 9) + _3431;\n    int _3517 = ((_3428 + 1) * 9) + _3431;\n    return lerp(lerp(_3492[_3497], _3492[_3497 + 1], _3441), lerp(_3492[_3517], _3492[_3517 + 1], _3441), _3417 - float(_3428));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _6636 = false;\n    float _6637 = 1.0f;\n    float _6638 = 1.0f;\n    float _6639 = 1.0f;\n    float _6640 = 0.0f;\n    float _6641 = 0.0f;\n    float _6642 = 0.0f;\n    float _6643 = 0.0f;\n    float _6645 = 1.0f;\n    bool _6646 = false;\n    float3 _6647 = 0.0f.xxx;\n    float _6648 = 1.0f;\n    float _6649 = 1.0f;\n    float _6650 = 1.0f;\n    float _6651 = 0.0f;\n    float _6652 = 0.0f;\n    float3 _6653 = float3(1.0f, 0.0f, 0.0f);\n    float3 _6654 = float3(0.0f, 0.0f, 1.0f);\n    float _6655 = 1.0f;\n    float _6656 = 1.0f;\n    float _3568 = clamp(s.specular, 0.0f, 1.0f);\n    float _3572 = clamp(s.ior, 1.0f, 3.0f);\n    bool _3577 = (_3568 != 1.0f) || (_3572 != 1.5f);\n    bool _3586;\n    if (!_3577)\n    {\n        _3586 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _3586 = _3577;\n    }\n    if (_3586)\n    {\n        float _3594 = (_3572 - 1.0f) / (_3572 + 1.0f);\n        f0 = lerp(min((_3594 * _3594).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _3568, s.albedo, metallic.xxx);\n        _6637 = lerp(_3568, 1.0f, metallic);\n        _6636 = true;\n    }\n    float _3621 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_3621 > 0.0f)\n    {\n        float _3629 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _6640 = _3621;\n        _6641 = _3629;\n        float _3636 = _3629 * _3629;\n        _6642 = _3636;\n        _6643 = _3636 * _3636;\n        float _3648 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _6645 = _3648;\n        _6638 = 1.0f - (_3621 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _3648, 0.0f, 1.0f), 5.0f))));\n        _6636 = true;\n    }\n    float3 _3668 = max(s.sheen_color, 0.0f.xxx);\n    float _3677 = max(_3668.x, max(_3668.y, _3668.z));\n    if (_3677 > 0.0f)\n    {\n        float _3685 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _6646 = true;\n        _6647 = _3668;\n        _6648 = _3685;\n        _6649 = _3685 * _3685;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _3685;\n        float _3702 = fa_sheen_albedo(param, param_1);\n        _6651 = _3702;\n        _6650 = 1.0f - min(_3677 * _3702, 1.0f);\n        _6636 = true;\n    }\n    _6639 = _6638 * _6650;\n    float _3721 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_3721 != 0.0f)\n    {\n        float3 _3736 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _3736;\n        if (dot(_3736, _3736) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _3748 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_3748.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _3748.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _3748.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _3752 = t;\n        float3 _3753 = normalize(_3752);\n        t = _3753;\n        float3 _3778 = normalize((_3753 * cos(s.anisotropy_rotation)) + ((cross(n, _3753) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _6653 = _3778;\n        _6654 = cross(n, _3778);\n        float _3788 = roughness * roughness;\n        float _3794 = lerp(_3788, 1.0f, _3721 * _3721);\n        bool _3796 = _3721 > 0.0f;\n        _6655 = _3796 ? _3794 : _3788;\n        _6656 = _3796 ? _3788 : _3794;\n        _6652 = _3721;\n        _6636 = true;\n    }\n    FaLayers _6678 = { _6636, _6637, _6638, _6639, _6640, _6641, _6642, _6643, i.world_normal, _6645, _6646, _6647, _6648, _6649, _6650, _6651, _6652, _6653, _6654, _6655, _6656 };\n    return _6678;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_491_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _491_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_491_fa_cl_info.x) + int(_491_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_491_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _562_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _562_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _728 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _741 = (c - (ru * hx)) - p;\n        float3 _747 = ru * (2.0f * hx);\n        float _753 = max(dot(_747, _747), 9.9999999392252902907785028219223e-09f);\n        float _757 = dot(_741, _747);\n        float t = clamp((-_757) / _753, 0.0f, 1.0f);\n        if (_728)\n        {\n            float _772 = dot(r, _747);\n            float _778 = _753 - (_772 * _772);\n            if (abs(_778) > (9.9999997473787516355514526367188e-06f * _753))\n            {\n                t = clamp(((dot(r, _741) * _772) - _757) / _778, 0.0f, 1.0f);\n            }\n        }\n        return (p + _741) + (_747 * t);\n    }\n    float3 q = p;\n    float _810 = dot(r, axis);\n    bool _818;\n    if (_728)\n    {\n        _818 = abs(_810) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _818 = _728;\n    }\n    if (_818)\n    {\n        float _828 = dot(c - p, axis) / _810;\n        if (_828 > 0.0f)\n        {\n            q = p + (r * _828);\n        }\n    }\n    float3 _841 = q - c;\n    float2 xy = float2(dot(_841, ru), dot(_841, uu));\n    if (shape > 0.5f)\n    {\n        float _856 = length(xy);\n        if (_856 > hx)\n        {\n            xy *= (hx / _856);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _649 = abs(d);\n    float _651 = _649.x;\n    float _653 = _649.y;\n    bool _654 = _651 >= _653;\n    bool _662;\n    if (_654)\n    {\n        _662 = _651 >= _649.z;\n    }\n    else\n    {\n        _662 = _654;\n    }\n    int _663;\n    if (_662)\n    {\n        _663 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _676;\n        if (_653 >= _649.z)\n        {\n            _676 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _676 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _663 = _676;\n    }\n    return _663;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _602 = dot(d, right);\n    float _606 = dot(d, up);\n    float _617;\n    if (((_602 * _602) + (_606 * _606)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _617 = atan2(_606, _602) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _617 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_617 - floor(_617)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _894 = fa_light_base(param);\n    bool _898 = _491_fa_ambient.w > 4.5f;\n    int param_1 = _894;\n    float4 _902 = fa_light_texel(param_1);\n    int param_2 = _894 + 1;\n    float4 _907 = fa_light_texel(param_2);\n    float _910 = _907.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _922 = _898 && (_910 > 2.5f);\n    fa_light_is_area = _922;\n    bool _924 = _910 < 0.5f;\n    float3 l;\n    if (_924)\n    {\n        l = normalize(_902.xyz);\n        if (_898)\n        {\n            int param_3 = _894 + 6;\n            float4 _938 = fa_light_texel(param_3);\n            if (_938.z > 0.5f)\n            {\n                int param_4 = _894 + 4;\n                float4 _948 = fa_light_texel(param_4);\n                int param_5 = _894 + 5;\n                float4 _953 = fa_light_texel(param_5);\n                float2 param_6 = _938.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _948.xyz) * _948.w, (-dot(world_pos, _953.xyz)) * _953.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _983 = _902.xyz;\n        float3 _985 = _983 - world_pos;\n        float3 to_light = _985;\n        float _988 = length(_985);\n        float reach = _988;\n        bool front = true;\n        if (_922)\n        {\n            int param_8 = _894 + 7;\n            reach = max(_988 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _894 + 4;\n            float4 _1012 = fa_light_texel(param_9);\n            int param_10 = _894 + 5;\n            float4 _1017 = fa_light_texel(param_10);\n            int param_11 = _894 + 6;\n            float4 _1022 = fa_light_texel(param_11);\n            float _1023 = _1022.w;\n            int param_12 = _894 + 2;\n            float3 _1030 = normalize(fa_light_texel(param_12).xyz);\n            bool _1032 = _1023 > 1.5f;\n            bool _1040;\n            if (!_1032)\n            {\n                _1040 = dot(_1030, to_light) < 0.0f;\n            }\n            else\n            {\n                _1040 = _1032;\n            }\n            front = _1040;\n            float3 r = 0.0f.xxx;\n            if (dot(n, n) > 0.5f)\n            {\n                r = reflect(-normalize(_491_fa_camera_pos.xyz - world_pos), normalize(n));\n            }\n            float3 param_13 = _983;\n            float3 param_14 = _1030;\n            float3 param_15 = _1012.xyz;\n            float3 param_16 = _1017.xyz;\n            float param_17 = _1012.w;\n            float param_18 = _1017.w;\n            float param_19 = _1023;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1087 = length(to_light);\n        dist = _1087;\n        l = to_light / max(_1087, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1101 = reach / max(_902.w, 0.001000000047497451305389404296875f);\n        float _1107 = clamp(1.0f - (_1101 * _1101), 0.0f, 1.0f);\n        float _1109;\n        if (front)\n        {\n            _1109 = _1107 * _1107;\n        }\n        else\n        {\n            _1109 = 0.0f;\n        }\n        atten = _1109;\n        bool _1120 = _910 < 2.5f;\n        if ((_910 > 1.5f) && _1120)\n        {\n            int param_22 = _894 + 2;\n            float4 _1128 = fa_light_texel(param_22);\n            float _1138 = _1128.w;\n            int param_23 = _894 + 3;\n            float4 _1143 = fa_light_texel(param_23);\n            float _1144 = _1143.x;\n            float cos_inner = _1144;\n            if (_1144 > 1.5f)\n            {\n                cos_inner = lerp(_1138, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1138, cos_inner, dot(-l, normalize(_1128.xyz)));\n        }\n        if (_898 && (_910 < 1.5f))\n        {\n            int param_24 = _894 + 6;\n            float4 _1168 = fa_light_texel(param_24);\n            if (_1168.z > 0.5f)\n            {\n                float3 _1176 = -to_light;\n                int param_25 = _894 + 4;\n                int param_26 = _894 + 5;\n                float3 _1190 = fa_light_texel(param_25).xyz;\n                float3 _1194 = fa_light_texel(param_26).xyz;\n                float3 _1203 = float3(dot(_1176, _1190), dot(_1176, _1194), dot(_1176, cross(_1190, _1194)));\n                float3 param_27 = _1203;\n                int _1207 = fa_cube_face(param_27);\n                int param_28 = _1207;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1234 = float2(dot(_1203, cross(param_29, param_30)), dot(_1203, param_30)) / max(dot(_1203, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1238 = _1207 / 3;\n                float2 param_31 = _1168.xy + (float2(float(_1207 - (_1238 * 3)), float(_1238)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1234.x), 0.5f - (0.5f * _1234.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _894 + 7;\n            float4 _1268 = fa_light_texel(param_33);\n            if (_1268.z > 0.5f)\n            {\n                int param_34 = _894 + 2;\n                int param_35 = _894 + 4;\n                int param_36 = _894 + 5;\n                float2 param_37 = _1268.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_898 && _1120)\n            {\n                int param_42 = _894 + 6;\n                float4 _1315 = fa_light_texel(param_42);\n                int param_43 = _894 + 7;\n                float4 _1320 = fa_light_texel(param_43);\n                bool _1323 = _1315.z > 0.5f;\n                bool _1330;\n                if (!_1323)\n                {\n                    _1330 = _1320.z > 0.5f;\n                }\n                else\n                {\n                    _1330 = _1323;\n                }\n                if (_1330)\n                {\n                    int param_44 = _894 + 2;\n                    float4 _1337 = fa_light_texel(param_44);\n                    float3 _1341 = normalize(_1337.xyz);\n                    int param_45 = _894 + 4;\n                    float4 _1346 = fa_light_texel(param_45);\n                    int param_46 = _894 + 5;\n                    float4 _1351 = fa_light_texel(param_46);\n                    if (_1323)\n                    {\n                        float3 _1359 = -to_light;\n                        float _1366 = _1337.w;\n                        float _1382 = 0.5f / max(dot(_1359, _1341) * (sqrt(max(1.0f - (_1366 * _1366), 0.0f)) / max(_1366, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1315.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1359, _1346.xyz) * _1382), 0.5f - (dot(_1359, _1351.xyz) * _1382));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1320.z > 0.5f)\n                    {\n                        float2 param_49 = _1320.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1341;\n                        float3 param_52 = _1346.xyz;\n                        float3 param_53 = _1351.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _6624 = _907.xyz * atten;\n    if (_898)\n    {\n        _6624 *= fa_light_tint;\n    }\n    int _1451;\n    if (_924)\n    {\n        _1451 = 0;\n    }\n    else\n    {\n        _1451 = ((_910 > 1.5f) && (_910 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _6635 = { l, _6624, atten, 1.0f, dist, _1451 };\n    return _6635;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2188;\n    if (i == 0)\n    {\n        _2188 = _2198_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2204;\n        if (i == 1)\n        {\n            _2204 = _2198_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2212;\n            if (i == 2)\n            {\n                _2212 = _2198_fa_shadow_split.z;\n            }\n            else\n            {\n                _2212 = _2198_fa_shadow_split.w;\n            }\n            _2204 = _2212;\n        }\n        _2188 = _2204;\n    }\n    return _2188;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2245 = fa_shadow_depth(param, param_1);\n    float _2249;\n    if (conv.x < 0.5f)\n    {\n        _2249 = _2245;\n    }\n    else\n    {\n        _2249 = (conv.y * conv.z) / (conv.z - (_2245 * (conv.z - conv.y)));\n    }\n    return _2249;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2176 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2176), sin(_2176)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2295 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2304;\n        if (k < 0.0f)\n        {\n            _2304 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2304 = k;\n        }\n        float _2324 = clamp((_2304 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2295;\n            float2 _2343 = fa_shadow_vogel(param_3, param_4, param_5) * _2324;\n            float2 param_6 = uv + (_2343 * _2198_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2355 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2355 < (zr - (length(_2343) * plane)))\n            {\n                sum += _2355;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2381 = sum / cnt;\n        float _2391;\n        if (k < 0.0f)\n        {\n            _2391 = (-k) / max(_2381, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2391 = k;\n        }\n        radius = clamp(((max(zr - _2381, 0.0f) * unit) * _2391) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2413 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2413; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2413;\n        float param_11 = _2295;\n        float2 _2432 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2432 * _2198_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2432) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2413);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2474 = max(_2198_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2479 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2485 = sqrt(1.0f - (_2479 * _2479));\n    float _2492 = min(_2485 / max(_2479, 0.20000000298023223876953125f), 4.0f);\n    float _2497;\n    if (_2198_fa_shadow_bias.y > 0.0f)\n    {\n        _2497 = _2198_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2497 = 1.5f * _2198_fa_shadow_info[ci].x;\n    }\n    float4 _2522 = mul(float4(world + (n * (_2497 * _2485)), 1.0f), _2198_fa_shadow_mat[ci]);\n    float _2529 = _2522.x;\n    bool _2532 = _2529 < _2198_fa_shadow_rect[ci].x;\n    bool _2541;\n    if (!_2532)\n    {\n        _2541 = _2529 > _2198_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2541 = _2532;\n    }\n    bool _2550;\n    if (!_2541)\n    {\n        _2550 = _2522.y < _2198_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2550 = _2541;\n    }\n    bool _2559;\n    if (!_2550)\n    {\n        _2559 = _2522.y > _2198_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2559 = _2550;\n    }\n    bool _2566;\n    if (!_2559)\n    {\n        _2566 = _2522.z > 1.0f;\n    }\n    else\n    {\n        _2566 = _2559;\n    }\n    if (_2566)\n    {\n        return -1.0f;\n    }\n    float _2574;\n    if (_2198_fa_shadow_bias.x > 0.0f)\n    {\n        _2574 = _2198_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2574 = 1.5f * _2198_fa_shadow_info[ci].x;\n    }\n    float2 param = _2522.xy;\n    float4 param_1 = _2198_fa_shadow_rect[ci];\n    float param_2 = _2522.z - ((_2574 * (1.0f + (0.5f * _2492))) / _2474);\n    float param_3 = _2198_fa_shadow_info[ci].x;\n    float param_4 = _2474;\n    float param_5 = _2474 * 0.25f;\n    float param_6 = ((_2198_fa_shadow_info[ci].x * min(_2492, 3.0f)) * 0.5f) / _2474;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2198_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2198_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_491_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2962 = int(_2198_fa_shadow_cfg.x + 0.5f);\n    if (_2962 < 1)\n    {\n        return 1.0f;\n    }\n    float _2977 = dot(world - _2198_fa_shadow_eye.xyz, _2198_fa_shadow_fwd.xyz);\n    int param = _2962 - 1;\n    if (_2977 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2989 = _2962 > 1;\n    bool _2996;\n    if (_2989)\n    {\n        _2996 = _2977 > _2198_fa_shadow_split.x;\n    }\n    else\n    {\n        _2996 = _2989;\n    }\n    if (_2996)\n    {\n        ci = 1;\n    }\n    bool _3000 = _2962 > 2;\n    bool _3007;\n    if (_3000)\n    {\n        _3007 = _2977 > _2198_fa_shadow_split.y;\n    }\n    else\n    {\n        _3007 = _3000;\n    }\n    if (_3007)\n    {\n        ci = 2;\n    }\n    bool _3011 = _2962 > 3;\n    bool _3018;\n    if (_3011)\n    {\n        _3018 = _2977 > _2198_fa_shadow_split.z;\n    }\n    else\n    {\n        _3018 = _3011;\n    }\n    if (_3018)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2962)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _3044 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3044;\n        if (_3044 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2198_fa_shadow_cfg.y > 0.0f)\n    {\n        float _3069;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3069 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3069 = _2198_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _3088 = _2198_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3069, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _3099 = clamp((_2977 - (fa_shadow_split_at(param_7) - _3088)) / _3088, 0.0f, 1.0f);\n        if (_3099 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2962)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _3120 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3120;\n                if (_3120 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _3099);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _2632 = _491_fa_pbr.z < 0.5f;\n    bool _2639;\n    if (!_2632)\n    {\n        _2639 = _2198_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2639 = _2632;\n    }\n    if (_2639)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2198_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2652 = fa_light_texel(param);\n    float _2653 = _2652.x;\n    if (_2653 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2662 = int(_2653 + 0.5f);\n    int param_1 = _2662;\n    float4 _2666 = fa_light_texel(param_1);\n    int param_2 = _2662 + 1;\n    float4 _2671 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2674 = _2666.y;\n    if (_2674 > 0.0f)\n    {\n        float _2691 = 1.0f - smoothstep(0.75f * _2674, _2674, length(world - _2198_fa_shadow_eye.xyz));\n        fade = _2691;\n        if (_2691 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2666.x > 1.5f)\n    {\n        int param_3 = li;\n        int param_4 = fa_light_base(param_3);\n        float3 param_5 = world - fa_light_texel(param_4).xyz;\n        face = fa_cube_face(param_5);\n    }\n    int _2720 = (_2662 + 2) + (face * 6);\n    int param_6 = _2720;\n    int param_7 = _2720 + 1;\n    int param_8 = _2720 + 3;\n    float4 _2734 = fa_light_texel(param_8);\n    int param_9 = _2720 + 4;\n    float4 _2739 = fa_light_texel(param_9);\n    int param_10 = _2720 + 5;\n    float4 _2744 = fa_light_texel(param_10);\n    float _2756 = _2744.x * max(dot(_2734, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2761 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2784 = clamp(dot(n, _2734.xyz), -1.0f, 1.0f);\n    int param_11 = li;\n    int param_12 = fa_light_base(param_11);\n    float _2808 = min(sqrt(1.0f - (_2784 * _2784)) / max(abs(dot(n, world - fa_light_texel(param_12).xyz)) / max(dot(_2734, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2811 = _2671.y;\n    float _2813;\n    if (_2811 > 0.0f)\n    {\n        _2813 = _2811;\n    }\n    else\n    {\n        _2813 = 1.5f * _2756;\n    }\n    float4 _2833 = float4(world + (n * (_2813 * sqrt(1.0f - (_2761 * _2761)))), 1.0f);\n    float _2837 = dot(_2734, _2833);\n    float _2840 = _2744.y;\n    if (_2837 < _2840)\n    {\n        return 1.0f;\n    }\n    float2 _2855 = float2(dot(fa_light_texel(param_6), _2833), dot(fa_light_texel(param_7), _2833)) / _2837.xx;\n    float _2857 = _2855.x;\n    bool _2860 = _2857 < _2739.x;\n    bool _2869;\n    if (!_2860)\n    {\n        _2869 = _2857 > _2739.z;\n    }\n    else\n    {\n        _2869 = _2860;\n    }\n    bool _2878;\n    if (!_2869)\n    {\n        _2878 = _2855.y < _2739.y;\n    }\n    else\n    {\n        _2878 = _2869;\n    }\n    bool _2887;\n    if (!_2878)\n    {\n        _2887 = _2855.y > _2739.w;\n    }\n    else\n    {\n        _2887 = _2878;\n    }\n    if (_2887)\n    {\n        return 1.0f;\n    }\n    float _2893 = _2671.x;\n    float _2895;\n    if (_2893 > 0.0f)\n    {\n        _2895 = _2893;\n    }\n    else\n    {\n        _2895 = 1.5f * _2756;\n    }\n    float2 param_13 = _2855;\n    float4 param_14 = _2739;\n    float param_15 = _2837 - (_2895 * (1.0f + (0.5f * _2808)));\n    float param_16 = _2756;\n    float param_17 = 1.0f;\n    float param_18 = _2744.z * 0.25f;\n    float param_19 = (_2756 * min(_2808, 3.0f)) * 0.5f;\n    float3 param_20 = float3(1.0f, _2840, _2744.z);\n    int param_21 = int(_2666.z + 0.5f);\n    float param_22 = _2666.w;\n    return lerp(1.0f, fa_shadow_filter(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _4340 = fa_lm.z > 0.5f;\n    bool _4346;\n    if (_4340)\n    {\n        int param = li;\n        _4346 = fa_light_baked(param);\n    }\n    else\n    {\n        _4346 = _4340;\n    }\n    if (_4346)\n    {\n        int param_1 = li;\n        LightSample _6691 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _6691;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4370 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _6693 = _4370.color;\n    float _6695 = _4370.shadow;\n    if ((_4370.type == 0) && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4370.direction;\n        float _4384 = fa_shadow_factor(param_5, param_6);\n        _6695 = _4384;\n        _6693 *= _4384;\n    }\n    else\n    {\n        bool _4395 = _4370.type != 0;\n        bool _4401;\n        if (_4395)\n        {\n            _4401 = _4370.attenuation > 0.0f;\n        }\n        else\n        {\n            _4401 = _4395;\n        }\n        if (_4401)\n        {\n            int param_7 = li;\n            float3 param_8 = world_pos;\n            float3 param_9 = gn;\n            float3 param_10 = _4370.direction;\n            float _4413 = fa_shadow_local(param_7, param_8, param_9, param_10);\n            _6695 = _4413;\n            _6693 *= _4413;\n        }\n    }\n    LightSample _6710 = { _4370.direction, _6693, _4370.attenuation, _6695, _4370._distance, _4370.type };\n    return _6710;\n}\n\nfloat3 fa_ltc_tangent(float3 n, float3 v)\n{\n    float3 _4453 = v - (n * dot(v, n));\n    float3 t = _4453;\n    float _4457 = dot(_4453, _4453);\n    float l2 = _4457;\n    if (_4457 < 1.0000000133514319600180897396058e-10f)\n    {\n        float3 _4467;\n        if (abs(n.z) < 0.999000012874603271484375f)\n        {\n            _4467 = cross(n, float3(0.0f, 0.0f, 1.0f));\n        }\n        else\n        {\n            _4467 = cross(n, float3(1.0f, 0.0f, 0.0f));\n        }\n        t = _4467;\n        l2 = dot(_4467, _4467);\n    }\n    return t * rsqrt(l2);\n}\n\nfloat3 fa_ltc_local(float3 t1, float3 n, float3 p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nfloat3 fa_ltc_edge_vector(float3 a, float3 b)\n{\n    float _4502 = dot(a, a);\n    float _4506 = dot(b, b);\n    if ((_4502 < 1.0000000195414813782625560981111e-24f) || (_4506 < 1.0000000195414813782625560981111e-24f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _4520 = a * rsqrt(_4502);\n    float3 _4525 = b * rsqrt(_4506);\n    float _4529 = dot(_4520, _4525);\n    float _4532 = abs(_4529);\n    float g = (((((((((((0.0416471660137176513671875f * _4532) - 0.1924748718738555908203125f) * _4532) + 0.4179156124591827392578125f) * _4532) - 0.616057217121124267578125f) * _4532) + 0.777722418308258056640625f) * _4532) - 0.999542415142059326171875f) * _4532) + 1.570791721343994140625f;\n    if (_4529 < 0.0f)\n    {\n        g = (3.1415927410125732421875f * rsqrt(max(1.0f - (_4529 * _4529), 1.0000000116860974230803549289703e-07f))) - g;\n    }\n    return cross(_4520, _4525) * g;\n}\n\nvoid fa_ltc_clip_edge(float3 a, float3 b, inout float3 sum, inout float3 leave, inout float3 enter, inout float2 seen)\n{\n    bool _4589 = a.z > 0.0f;\n    bool _4593 = b.z > 0.0f;\n    if (_4589 && _4593)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_4589 != _4593)\n        {\n            float3 _4628 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _4628.z = 0.0f;\n            if (_4589)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _4628;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _4628;\n                seen.x = 1.0f;\n            }\n            else\n            {\n                float3 param_4 = _4628;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _4628;\n                seen.y = 1.0f;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(float4 abcd, float3 p0, float3 p1, float3 p2, float3 p3)\n{\n    float3 _4677 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _4703 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _4729 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _4755 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = 0.0f.xxx;\n    float3 leave = 0.0f.xxx;\n    float3 enter = 0.0f.xxx;\n    float3 param = _4677;\n    float3 param_1 = _4703;\n    float3 param_2 = 0.0f.xxx;\n    float3 param_3 = 0.0f.xxx;\n    float3 param_4 = 0.0f.xxx;\n    float2 param_5 = 0.0f.xx;\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _4703;\n    float3 param_7 = _4729;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _4729;\n    float3 param_13 = _4755;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _4755;\n    float3 param_19 = _4677;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5f)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875f;\n}\n\nfloat fa_ltc_rect(float4 abcd, float3 center, float3 ex, float3 ey)\n{\n    float4 param = abcd;\n    float3 param_1 = (center - ex) - ey;\n    float3 param_2 = (center + ex) - ey;\n    float3 param_3 = (center + ex) + ey;\n    float3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(float4 m, float shape, float3 pc, float3 ex, float3 ey)\n{\n    if ((shape < 0.5f) || (shape > 1.5f))\n    {\n        float4 param = m;\n        float3 param_1 = pc;\n        float3 param_2 = ex;\n        float3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    float3 _4905 = (pc + (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _4929 = (pc - (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _4945 = (pc - (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float4 param_4 = m;\n    float3 param_5 = _4905;\n    float3 param_6 = (pc + (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_7 = (pc - (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_8 = _4929;\n    float4 param_9 = m;\n    float3 param_10 = _4905;\n    float3 param_11 = _4929;\n    float3 param_12 = (pc - (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    float3 param_13 = _4945;\n    float4 param_14 = m;\n    float3 param_15 = _4905;\n    float3 param_16 = _4945;\n    float3 param_17 = (pc + (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float3 param_18 = (pc + (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nfloat2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((float2(clamp((roughness - 0.0500000007450580596923828125f) * 1.0526316165924072265625f, 0.0f, 1.0f), sqrt(clamp(1.0f - ndv, 0.0f, 1.0f))) * 63.0f) + 0.5f.xx) * 0.015625f.xx;\n}\n\nfloat3 fa_area_shade(int li, float3 world_pos, float3 n, float3 v, float3 diffuse_color, float3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _5003 = fa_light_base(param);\n    int param_1 = _5003;\n    int param_2 = _5003 + 1;\n    int param_3 = _5003 + 2;\n    int param_4 = _5003 + 4;\n    float4 _5025 = fa_light_texel(param_4);\n    int param_5 = _5003 + 5;\n    float4 _5030 = fa_light_texel(param_5);\n    int param_6 = _5003 + 6;\n    float4 _5035 = fa_light_texel(param_6);\n    float _5036 = _5035.w;\n    float3 _5041 = fa_light_texel(param_1).xyz - world_pos;\n    bool _5043 = _5036 < 1.5f;\n    bool _5050;\n    if (_5043)\n    {\n        _5050 = dot(normalize(fa_light_texel(param_3).xyz), _5041) >= 0.0f;\n    }\n    else\n    {\n        _5050 = _5043;\n    }\n    if (_5050)\n    {\n        return 0.0f.xxx;\n    }\n    bool _5059 = (_5036 > 0.5f) && _5043;\n    float _5063 = _5059 ? 1.0539000034332275390625f : 1.0f;\n    float3 _5066 = _5025.xyz;\n    float _5068 = _5025.w;\n    float3 _5074 = _5030.xyz;\n    float _5076 = _5030.w;\n    float3 up = _5074 * (_5076 * _5063);\n    float _5082;\n    if (_5059)\n    {\n        _5082 = (3.1415927410125732421875f * _5068) * _5068;\n    }\n    else\n    {\n        _5082 = (4.0f * _5068) * _5076;\n    }\n    if (_5036 > 1.5f)\n    {\n        float3 _5108 = cross(_5066, -_5041);\n        float3 perp = _5108;\n        float _5112 = dot(_5108, _5108);\n        float3 _5115;\n        if (_5112 > 1.0000000133514319600180897396058e-10f)\n        {\n            _5115 = perp * rsqrt(_5112);\n        }\n        else\n        {\n            _5115 = _5074;\n        }\n        perp = _5115;\n        up = _5115 * _5076;\n    }\n    float _5136 = max(_5082, 9.9999999747524270787835121154785e-07f);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _5146 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _5146;\n    float3 param_10 = n;\n    float3 param_11 = _5041;\n    float3 _5154 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_12 = _5146;\n    float3 param_13 = n;\n    float3 param_14 = _5066 * (_5068 * _5063);\n    float3 _5162 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_15 = _5146;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float3 _5170 = fa_ltc_local(param_15, param_16, param_17);\n    float4 param_18 = float4(1.0f, 0.0f, 0.0f, 1.0f);\n    float param_19 = _5036;\n    float3 param_20 = _5154;\n    float3 param_21 = _5162;\n    float3 param_22 = _5170;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    float2 _5189 = fa_ltc_uv(param_23, param_24) * 64.0f;\n    float2 param_25 = _5189;\n    float2 param_26 = _5189 + float2(64.0f, 0.0f);\n    float4 _5199 = fa_atlas_fetch(param_26);\n    float4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _5036;\n    float3 param_29 = _5154;\n    float3 param_30 = _5162;\n    float3 param_31 = _5170;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _5199.x) + ((f90.xxx - f0) * _5199.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875f * dot(_5041, _5041)) + _5136) / _5136) * window);\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4043 = 1.0f / alpha;\n    return ((2.0f + _4043) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _4043)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat fa_layers_coat(FaLayers L, float3 l, float3 h, float vdh)\n{\n    float _4078 = max(dot(L.nc, l), 0.0f);\n    float _4084 = max(dot(L.nc, h), 0.0f);\n    float _4093 = ((_4084 * _4084) * (L.coat_a2 - 1.0f)) + 1.0f;\n    return (((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _4093) * _4093)) * (0.5f / max(lerp((2.0f * _4078) * L.coat_ndv, _4078 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _4078)) * _4078;\n}\n\nfloat3 fa_area_layers(FaLayers L, int li, float3 world_pos, float3 n, float3 v, float3 l, float3 diffuse_color, float3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    float3 param_2 = n;\n    float3 param_3 = v;\n    float3 param_4 = diffuse_color;\n    float3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _5267;\n    if (L.sheen_on)\n    {\n        _5267 = L.sheen_scale;\n    }\n    else\n    {\n        _5267 = 1.0f;\n    }\n    float3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _5267);\n    float3 _5280 = normalize(l + v);\n    int param_10 = li;\n    float3 _5291 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _5300 = max(dot(n, l), 0.0f);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _5280), 0.0f);\n        float param_13 = _5300;\n        float param_14 = ndv;\n        result += ((L.sheen * _5291) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875f) * step(9.9999997473787516355514526367188e-05f, _5300)) * _5300) * L.keep));\n    }\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_15 = L;\n        float3 param_16 = l;\n        float3 param_17 = _5280;\n        float param_18 = max(dot(v, _5280), 0.0f);\n        result += (_5291 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _3946 = tdh / at;\n    float _3950 = bdh / ab;\n    float _3962 = ((_3946 * _3946) + (_3950 * _3950)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _3962) * _3962);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4142 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4221 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _4221) * _4221);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _4142);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _4142));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_17 = L;\n        float3 param_18 = l;\n        float3 param_19 = h;\n        float param_20 = vdh;\n        result += fa_layers_coat(param_17, param_18, param_19, param_20).xxx;\n    }\n    return result;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3349 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3352 = _3349.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3352 * _3352, exp2((-9.27999973297119140625f) * ndv)) * _3352) + _3349.y)) + _3349.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_491_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _491_fa_env_horizon.w).xyz;\n    }\n    float _3255 = rough * rough;\n    float _3285 = 0.60000002384185791015625f * _3255;\n    return lerp(lerp(_491_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_491_fa_env_horizon.xyz, _491_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3255)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3285, 0.0500000007450580596923828125f + _3285, d.y).xxx), ((_491_fa_env_sky.xyz + _491_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3255 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _3829;\n        if (L.aniso >= 0.0f)\n        {\n            _3829 = L.b;\n        }\n        else\n        {\n            _3829 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_3829, v), _3829), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3862 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _3862.x) + (L.f90.xxx * _3862.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3917 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _3917.x) + _3917.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3391 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3391.x) + _3391.y.xxx);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2198_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3144 = int(_2198_fa_shadow_cfg.x + 0.5f);\n    float _3154 = dot(world - _2198_fa_shadow_eye.xyz, _2198_fa_shadow_fwd.xyz);\n    float3 tint_1 = 0.3499999940395355224609375f.xxx;\n    bool _3159 = _3144 > 0;\n    bool _3168;\n    if (_3159)\n    {\n        int param = _3144 - 1;\n        _3168 = _3154 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3168 = _3159;\n    }\n    if (_3168)\n    {\n        tint_1 = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3174 = _3144 > 1;\n        bool _3181;\n        if (_3174)\n        {\n            _3181 = _3154 > _2198_fa_shadow_split.x;\n        }\n        else\n        {\n            _3181 = _3174;\n        }\n        if (_3181)\n        {\n            tint_1 = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3187 = _3144 > 2;\n        bool _3194;\n        if (_3187)\n        {\n            _3194 = _3154 > _2198_fa_shadow_split.y;\n        }\n        else\n        {\n            _3194 = _3187;\n        }\n        if (_3194)\n        {\n            tint_1 = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3200 = _3144 > 3;\n        bool _3207;\n        if (_3200)\n        {\n            _3207 = _3154 > _2198_fa_shadow_split.z;\n        }\n        else\n        {\n            _3207 = _3200;\n        }\n        if (_3207)\n        {\n            tint_1 = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint_1, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _6393 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6393 = -_6393;\n    }\n    float3 _5751 = normalize(_491_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _6406 = { fa_world_pos, _6393, fa_world_tangent, fa_uv, fa_vertex_color, _5751, gl_FrontFacing };\n    SurfaceInput param_1 = _6406;\n    Surface _5759 = fa_standard_surface(param_1);\n    float3 _6424 = _5759.albedo;\n    float _6425 = _5759.alpha;\n    float3 _6426 = _5759.normal;\n    float _6427 = _5759.metallic;\n    float _6428 = _5759.roughness;\n    float _6429 = _5759.occlusion;\n    float3 _6430 = _5759.emission;\n    float _6431 = _5759.clearcoat;\n    float _6432 = _5759.clearcoat_roughness;\n    float3 _6433 = _5759.sheen_color;\n    float _6434 = _5759.sheen_roughness;\n    float _6435 = _5759.anisotropy;\n    float _6436 = _5759.anisotropy_rotation;\n    float _6437 = _5759.specular;\n    float _6438 = _5759.ior;\n    float3 _6439 = _5759.specular_color;\n    SurfaceInput _6414 = { fa_world_pos, _6393, fa_world_tangent, fa_uv, fa_vertex_color, _5751, gl_FrontFacing };\n    SurfaceInput param_2 = _6414;\n    Surface param_3 = _5759;\n    surface(param_2, param_3);\n    _6424 = param_3.albedo;\n    _6425 = param_3.alpha;\n    _6426 = param_3.normal;\n    _6427 = param_3.metallic;\n    _6428 = param_3.roughness;\n    _6429 = param_3.occlusion;\n    _6430 = param_3.emission;\n    _6431 = param_3.clearcoat;\n    _6432 = param_3.clearcoat_roughness;\n    _6433 = param_3.sheen_color;\n    _6434 = param_3.sheen_roughness;\n    _6435 = param_3.anisotropy;\n    _6436 = param_3.anisotropy_rotation;\n    _6437 = param_3.specular;\n    _6438 = param_3.ior;\n    _6439 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _6393;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6424 = param_6;\n    _6426 = param_7;\n    float3 result;\n    if (_491_fa_emissive.w > 0.5f)\n    {\n        result = _6424;\n    }\n    else\n    {\n        float3 _5798 = normalize(_6426);\n        float _5805 = clamp(_6427, 0.0f, 1.0f);\n        float _5809 = clamp(_6428, 0.0500000007450580596923828125f, 1.0f);\n        float _5813 = _5809 * _5809;\n        float _5817 = _5813 * _5813;\n        float _5822 = max(dot(_5798, _5751), 9.9999997473787516355514526367188e-05f);\n        float3 _5828 = _6424 * (1.0f - _5805);\n        float3 _5835 = lerp(0.039999999105930328369140625f.xxx, _6424, _5805.xxx);\n        float3 f0 = _5835;\n        SurfaceInput _6422 = { fa_world_pos, _6393, fa_world_tangent, fa_uv, fa_vertex_color, _5751, gl_FrontFacing };\n        SurfaceInput param_8 = _6422;\n        Surface _6505 = { _6424, _6425, _6426, _6427, _6428, _6429, _6430, _6431, _6432, _6433, _6434, _6435, _6436, _6437, _6438, _6439 };\n        Surface param_9 = _6505;\n        float3 param_10 = _5798;\n        float3 param_11 = _5751;\n        float param_12 = _5805;\n        float param_13 = _5809;\n        float3 param_14 = _5835;\n        FaLayers _5851 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _5798;\n        float3 lit = (fa_indirect_diffuse(param_15) * _5828) * _6429;\n        if (_5851.on)\n        {\n            lit *= _5851.base_scale;\n        }\n        int _5873 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5873; ln++)\n        {\n            int param_16 = ln;\n            int _5886 = fa_cl_light(param_16);\n            bool _5889 = fa_lm.z > 0.5f;\n            bool _5895;\n            if (_5889)\n            {\n                int param_17 = _5886;\n                _5895 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _5895 = _5889;\n            }\n            if (_5895)\n            {\n                continue;\n            }\n            int param_18 = _5886;\n            float3 param_19 = fa_world_pos;\n            float3 param_20 = _6393;\n            LightSample _5907 = fa_light_shadowed(param_18, param_19, param_20);\n            float _5915 = max(dot(_5798, _5907.direction), 0.0f);\n            float _5921 = _5907.attenuation * _5907.shadow;\n            float3 _5926 = normalize(_5907.direction + _5751);\n            float _5931 = max(dot(_5798, _5926), 0.0f);\n            float _5936 = max(dot(_5751, _5926), 0.0f);\n            bool _5943;\n            if (fa_light_is_area)\n            {\n                _5943 = !_5851.on;\n            }\n            else\n            {\n                _5943 = fa_light_is_area;\n            }\n            if (_5943)\n            {\n                int param_21 = _5886;\n                float3 param_22 = fa_world_pos;\n                float3 param_23 = _5798;\n                float3 param_24 = _5751;\n                float3 param_25 = _5828;\n                float3 param_26 = f0;\n                float param_27 = 1.0f;\n                float param_28 = _5809;\n                float param_29 = _5822;\n                float param_30 = _5921;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _5851;\n                    int param_32 = _5886;\n                    float3 param_33 = fa_world_pos;\n                    float3 param_34 = _5798;\n                    float3 param_35 = _5751;\n                    float3 param_36 = _5907.direction;\n                    float3 param_37 = _5828;\n                    float3 param_38 = f0;\n                    float param_39 = _5809;\n                    float param_40 = _5822;\n                    float param_41 = _5921;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_5851.on)\n                    {\n                        FaLayers param_42 = _5851;\n                        float3 param_43 = _5828;\n                        float3 param_44 = f0;\n                        float3 param_45 = _5798;\n                        float3 param_46 = _5751;\n                        float3 param_47 = _5907.direction;\n                        float3 param_48 = _5926;\n                        float param_49 = _5915;\n                        float param_50 = _5822;\n                        float param_51 = _5931;\n                        float param_52 = _5936;\n                        float param_53 = _5813;\n                        float param_54 = _5817;\n                        int param_55 = _5886;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _5921));\n                    }\n                    else\n                    {\n                        float _6049 = ((_5931 * _5931) * (_5817 - 1.0f)) + 1.0f;\n                        int param_56 = _5886;\n                        lit += (((_5828 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _5936, 5.0f))) * (((_5817 / ((3.1415927410125732421875f * _6049) * _6049)) * (0.5f / max(lerp((2.0f * _5915) * _5822, _5915 + _5822, _5813), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _5915))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_5915 * _5921));\n                    }\n                }\n            }\n        }\n        if (_5851.on)\n        {\n            FaLayers param_57 = _5851;\n            float3 param_58 = _5798;\n            float3 param_59 = _5751;\n            float3 param_60 = f0;\n            float param_61 = _5809;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _6429);\n        }\n        else\n        {\n            float3 param_62 = _5798;\n            float3 param_63 = _5751;\n            float3 param_64 = f0;\n            float param_65 = _5809;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _6429);\n        }\n        result = lit;\n    }\n    float3 _6144 = result;\n    float3 _6145 = _6144 + _6430;\n    result = _6145;\n    float3 param_66 = _6145;\n    float3 param_67 = fa_world_pos;\n    result = fa_shadow_debug(param_66, param_67);\n    bool _6154 = _491_fa_fog.w > 0.0f;\n    bool _6161;\n    if (!_6154)\n    {\n        _6161 = _491_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _6161 = _6154;\n    }\n    if (_6161)\n    {\n        float3 _6170 = fa_world_pos - _491_fa_camera_pos.xyz;\n        float _6176 = dot(_6170, _491_fa_fog_c.xyz);\n        bool _6180 = _491_fa_fog_c.w > 0.5f;\n        float _6181;\n        if (_6180)\n        {\n            _6181 = _6176;\n        }\n        else\n        {\n            _6181 = length(_6170);\n        }\n        float _6193 = _6181 - _491_fa_fog_b.x;\n        if (_6193 > 0.0f)\n        {\n            float _6202 = _491_fa_fog.w * _6193;\n            float tau = _6202 * _6202;\n            if (_491_fa_fog_b.y > 0.0f)\n            {\n                float _6218;\n                if (_6180)\n                {\n                    _6218 = fa_world_pos.y - (_491_fa_fog_c.y * _6176);\n                }\n                else\n                {\n                    _6218 = _491_fa_camera_pos.y;\n                }\n                float _6239 = lerp(_6218, fa_world_pos.y, clamp(_491_fa_fog_b.x / _6181, 0.0f, 1.0f));\n                float _6243 = fa_world_pos.y - _6239;\n                float _6248 = _6239 - _491_fa_fog_b.z;\n                float _6253 = fa_world_pos.y - _491_fa_fog_b.z;\n                bool _6256 = _6248 <= 0.0f;\n                bool _6257 = !_6256;\n                bool _6263;\n                if (_6257)\n                {\n                    _6263 = _491_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6263 = _6256;\n                }\n                float _6264;\n                if (_6263)\n                {\n                    _6264 = _491_fa_fog_b.y;\n                }\n                else\n                {\n                    _6264 = _491_fa_fog_b.y * exp(-min(_491_fa_fog_b.w * _6248, 80.0f));\n                }\n                bool _6291;\n                if (_6257)\n                {\n                    _6291 = _491_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6291 = _6256;\n                }\n                float _6292;\n                if (_6291)\n                {\n                    _6292 = _491_fa_fog_b.y * _6248;\n                }\n                else\n                {\n                    _6292 = (_491_fa_fog_b.y * (1.0f - exp(-min(_491_fa_fog_b.w * _6248, 80.0f)))) / _491_fa_fog_b.w;\n                }\n                bool _6317 = _6253 <= 0.0f;\n                bool _6324;\n                if (!_6317)\n                {\n                    _6324 = _491_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6324 = _6317;\n                }\n                float _6325;\n                if (_6324)\n                {\n                    _6325 = _491_fa_fog_b.y * _6253;\n                }\n                else\n                {\n                    _6325 = (_491_fa_fog_b.y * (1.0f - exp(-min(_491_fa_fog_b.w * _6253, 80.0f)))) / _491_fa_fog_b.w;\n                }\n                float _6352;\n                if (abs(_6243) < 0.001000000047497451305389404296875f)\n                {\n                    _6352 = _6264;\n                }\n                else\n                {\n                    _6352 = (_6325 - _6292) / _6243;\n                }\n                tau += (_6193 * max(_6352, 0.0f));\n            }\n            result = lerp(result, _491_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _6425);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_inst_v0 = stage_input.fa_inst_v0;\n    fa_inst_v1 = stage_input.fa_inst_v1;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_491",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2198",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_5369",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _153_fa_view_proj : packoffset(c0);\n    row_major float4x4 _153_fa_light_vp : packoffset(c4);\n    float4 _153_fa_uv_scale : packoffset(c8);\n    float4 _153_fa_time : packoffset(c9);\n    float4 _153_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_d0;\nstatic float4 fa_inst_d1;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_inst_d0 : TEXCOORD9;\n    float4 fa_inst_d1 : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float fa_pre_depth : TEXCOORD7;\n    float3 fa_pre_r0 : TEXCOORD8;\n    float3 fa_pre_r1 : TEXCOORD9;\n    float3 fa_pre_r2 : TEXCOORD10;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float raise;\nstatic float4 tint;\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _100 = (dot(model[0].xyz, _94) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _334 = { mul(float4(position, 1.0f), model).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _100, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _100), texcoord0 * _153_fa_uv_scale.xy, color, position };\n    return _334;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _197 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -mul(_197, _153_fa_light_vp).z;\n    fa_pre_r0 = float3(_153_fa_light_vp[0].x, _153_fa_light_vp[1].x, _153_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_153_fa_light_vp[0].y, _153_fa_light_vp[1].y, _153_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_153_fa_light_vp[0].z, _153_fa_light_vp[1].z, _153_fa_light_vp[2].z);\n    gl_Position = mul(_197, _153_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_d0 = stage_input.fa_inst_d0;\n    fa_inst_d1 = stage_input.fa_inst_d1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    stage_output.fa_inst_v0 = fa_inst_v0;\n    stage_output.fa_inst_v1 = fa_inst_v1;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _142_boost : packoffset(c0);\n    float _142_fa_pad0 : packoffset(c0.y);\n    float _142_fa_pad1 : packoffset(c0.z);\n    float _142_fa_pad2 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _253_fa_camera_pos : packoffset(c0);\n    float4 _253_fa_ambient : packoffset(c1);\n    float4 _253_fa_base_color : packoffset(c2);\n    float4 _253_fa_emissive : packoffset(c3);\n    float4 _253_fa_model_emissive : packoffset(c4);\n    float4 _253_fa_pbr : packoffset(c5);\n    float4 _253_fa_maps : packoffset(c6);\n    float4 _253_fa_fog : packoffset(c7);\n    float4 _253_fa_fog_b : packoffset(c8);\n    float4 _253_fa_fog_c : packoffset(c9);\n    float4 _253_fa_counts : packoffset(c10);\n    float4 _253_fa_env_sky : packoffset(c11);\n    float4 _253_fa_env_horizon : packoffset(c12);\n    float4 _253_fa_time : packoffset(c13);\n    float4 _253_fa_cl_vpx : packoffset(c14);\n    float4 _253_fa_cl_vpy : packoffset(c15);\n    float4 _253_fa_cl_vpw : packoffset(c16);\n    float4 _253_fa_cl_fwd : packoffset(c17);\n    float4 _253_fa_cl_grid : packoffset(c18);\n    float4 _253_fa_cl_info : packoffset(c19);\n    float4 _253_fa_layers_a : packoffset(c20);\n    float4 _253_fa_layers_b : packoffset(c21);\n    float4 _253_fa_layers_c : packoffset(c22);\n    float4 _253_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float fa_pre_depth : TEXCOORD7;\n    float3 fa_pre_r0 : TEXCOORD8;\n    float3 fa_pre_r1 : TEXCOORD9;\n    float3 fa_pre_r2 : TEXCOORD10;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float raise;\nstatic float4 tint;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    float3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    float3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    float3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _253_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _264 = fa_tex_fix(param_2, param_3);\n    float4 _772 = base_t;\n    _772.x = _264.x;\n    _772.y = _264.y;\n    _772.z = _264.z;\n    base_t = _772;\n    float4 _280 = (_772 * _253_fa_base_color) * i.vertex_color;\n    float3 _735 = i.world_normal;\n    if (_253_fa_maps.z > 0.5f)\n    {\n        float param_4 = _253_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _313 = fa_tex_fix(param_6, param_7);\n        float3 _317 = (_313 * 2.0f) - 1.0f.xxx;\n        float2 _322 = _317.xy * _253_fa_maps.x;\n        float3 _780 = _317;\n        _780.x = _322.x;\n        _780.y = _322.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _780;\n        _735 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _253_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _351 = fa_tex_fix(param_12, param_13);\n    float4 _783 = mrt;\n    _783.x = _351.x;\n    _783.y = _351.y;\n    _783.z = _351.z;\n    mrt = _783;\n    float4 _381 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _253_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _381.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _393 = fa_tex_fix(param_16, param_17);\n    float param_18 = _253_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _423 = fa_tex_fix(param_20, param_21);\n    float _740 = _253_fa_layers_a.x;\n    float _741 = _253_fa_layers_a.y;\n    float _744 = _253_fa_layers_a.z;\n    float _743 = _253_fa_layers_b.w;\n    float _746 = _253_fa_layers_c.x;\n    if (_253_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_253_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _740 *= _393.y;\n            _741 *= _393.z;\n            _743 *= _381.w;\n        }\n        if (_253_fa_layers_c.z > 1.5f)\n        {\n            _744 *= mrt.x;\n            _746 *= mrt.w;\n        }\n    }\n    Surface _765 = { _280.xyz, _280.w, _735, clamp(_253_fa_pbr.x * _351.z, 0.0f, 1.0f), clamp(_253_fa_pbr.y * _351.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_253_fa_maps.y * (_393.x - 1.0f)), _253_fa_emissive.xyz + (_253_fa_model_emissive.xyz * _423), _740, _741, _253_fa_layers_b.xyz, _743, _744, _253_fa_layers_a.w, _746, _253_fa_layers_c.y, _253_fa_layers_d.xyz };\n    return _765;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * _142_boost);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _646 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _646 = -_646;\n    }\n    float3 _556 = normalize(_253_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _659 = { fa_world_pos, _646, fa_world_tangent, fa_uv, fa_vertex_color, _556, gl_FrontFacing };\n    SurfaceInput param = _659;\n    SurfaceInput _667 = { fa_world_pos, _646, fa_world_tangent, fa_uv, fa_vertex_color, _556, gl_FrontFacing };\n    SurfaceInput param_1 = _667;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _571 = normalize(param_2.normal);\n    float3 _586 = normalize(float3(dot(fa_pre_r0, _571), dot(fa_pre_r1, _571), dot(fa_pre_r2, _571)));\n    float _598 = _586.z;\n    float2 e = _586.xy / ((abs(_586.x) + abs(_586.y)) + abs(_598)).xx;\n    if (_598 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_inst_v0 = stage_input.fa_inst_v0;\n    fa_inst_v1 = stage_input.fa_inst_v1;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _142_boost : packoffset(c0);\n    float _142_fa_pad0 : packoffset(c0.y);\n    float _142_fa_pad1 : packoffset(c0.z);\n    float _142_fa_pad2 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _253_fa_camera_pos : packoffset(c0);\n    float4 _253_fa_ambient : packoffset(c1);\n    float4 _253_fa_base_color : packoffset(c2);\n    float4 _253_fa_emissive : packoffset(c3);\n    float4 _253_fa_model_emissive : packoffset(c4);\n    float4 _253_fa_pbr : packoffset(c5);\n    float4 _253_fa_maps : packoffset(c6);\n    float4 _253_fa_fog : packoffset(c7);\n    float4 _253_fa_fog_b : packoffset(c8);\n    float4 _253_fa_fog_c : packoffset(c9);\n    float4 _253_fa_counts : packoffset(c10);\n    float4 _253_fa_env_sky : packoffset(c11);\n    float4 _253_fa_env_horizon : packoffset(c12);\n    float4 _253_fa_time : packoffset(c13);\n    float4 _253_fa_cl_vpx : packoffset(c14);\n    float4 _253_fa_cl_vpy : packoffset(c15);\n    float4 _253_fa_cl_vpw : packoffset(c16);\n    float4 _253_fa_cl_fwd : packoffset(c17);\n    float4 _253_fa_cl_grid : packoffset(c18);\n    float4 _253_fa_cl_info : packoffset(c19);\n    float4 _253_fa_layers_a : packoffset(c20);\n    float4 _253_fa_layers_b : packoffset(c21);\n    float4 _253_fa_layers_c : packoffset(c22);\n    float4 _253_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float fa_pre_depth : TEXCOORD7;\n    float3 fa_pre_r0 : TEXCOORD8;\n    float3 fa_pre_r1 : TEXCOORD9;\n    float3 fa_pre_r2 : TEXCOORD10;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float raise;\nstatic float4 tint;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    float3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    float3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    float3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _253_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _264 = fa_tex_fix(param_2, param_3);\n    float4 _772 = base_t;\n    _772.x = _264.x;\n    _772.y = _264.y;\n    _772.z = _264.z;\n    base_t = _772;\n    float4 _280 = (_772 * _253_fa_base_color) * i.vertex_color;\n    float3 _735 = i.world_normal;\n    if (_253_fa_maps.z > 0.5f)\n    {\n        float param_4 = _253_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _313 = fa_tex_fix(param_6, param_7);\n        float3 _317 = (_313 * 2.0f) - 1.0f.xxx;\n        float2 _322 = _317.xy * _253_fa_maps.x;\n        float3 _780 = _317;\n        _780.x = _322.x;\n        _780.y = _322.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _780;\n        _735 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _253_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _351 = fa_tex_fix(param_12, param_13);\n    float4 _783 = mrt;\n    _783.x = _351.x;\n    _783.y = _351.y;\n    _783.z = _351.z;\n    mrt = _783;\n    float4 _381 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _253_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _381.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _393 = fa_tex_fix(param_16, param_17);\n    float param_18 = _253_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _423 = fa_tex_fix(param_20, param_21);\n    float _740 = _253_fa_layers_a.x;\n    float _741 = _253_fa_layers_a.y;\n    float _744 = _253_fa_layers_a.z;\n    float _743 = _253_fa_layers_b.w;\n    float _746 = _253_fa_layers_c.x;\n    if (_253_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_253_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _740 *= _393.y;\n            _741 *= _393.z;\n            _743 *= _381.w;\n        }\n        if (_253_fa_layers_c.z > 1.5f)\n        {\n            _744 *= mrt.x;\n            _746 *= mrt.w;\n        }\n    }\n    Surface _765 = { _280.xyz, _280.w, _735, clamp(_253_fa_pbr.x * _351.z, 0.0f, 1.0f), clamp(_253_fa_pbr.y * _351.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_253_fa_maps.y * (_393.x - 1.0f)), _253_fa_emissive.xyz + (_253_fa_model_emissive.xyz * _423), _740, _741, _253_fa_layers_b.xyz, _743, _744, _253_fa_layers_a.w, _746, _253_fa_layers_c.y, _253_fa_layers_d.xyz };\n    return _765;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * _142_boost);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _646 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _646 = -_646;\n    }\n    float3 _556 = normalize(_253_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _659 = { fa_world_pos, _646, fa_world_tangent, fa_uv, fa_vertex_color, _556, gl_FrontFacing };\n    SurfaceInput param = _659;\n    SurfaceInput _667 = { fa_world_pos, _646, fa_world_tangent, fa_uv, fa_vertex_color, _556, gl_FrontFacing };\n    SurfaceInput param_1 = _667;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _571 = normalize(param_2.normal);\n    float3 _586 = normalize(float3(dot(fa_pre_r0, _571), dot(fa_pre_r1, _571), dot(fa_pre_r2, _571)));\n    float _598 = _586.z;\n    float2 e = _586.xy / ((abs(_586.x) + abs(_586.y)) + abs(_598)).xx;\n    if (_598 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_inst_v0 = stage_input.fa_inst_v0;\n    fa_inst_v1 = stage_input.fa_inst_v1;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
