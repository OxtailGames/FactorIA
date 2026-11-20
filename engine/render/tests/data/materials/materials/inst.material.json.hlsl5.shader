{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "fc5698cd941e0af057040ef4c307a7106b1e2971cc74f7501935817daedb7ce8",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _3502[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _491_fa_camera_pos : packoffset(c0);\n    float4 _491_fa_ambient : packoffset(c1);\n    float4 _491_fa_base_color : packoffset(c2);\n    float4 _491_fa_emissive : packoffset(c3);\n    float4 _491_fa_model_emissive : packoffset(c4);\n    float4 _491_fa_pbr : packoffset(c5);\n    float4 _491_fa_maps : packoffset(c6);\n    float4 _491_fa_fog : packoffset(c7);\n    float4 _491_fa_fog_b : packoffset(c8);\n    float4 _491_fa_fog_c : packoffset(c9);\n    float4 _491_fa_counts : packoffset(c10);\n    float4 _491_fa_env_sky : packoffset(c11);\n    float4 _491_fa_env_horizon : packoffset(c12);\n    float4 _491_fa_time : packoffset(c13);\n    float4 _491_fa_cl_vpx : packoffset(c14);\n    float4 _491_fa_cl_vpy : packoffset(c15);\n    float4 _491_fa_cl_vpw : packoffset(c16);\n    float4 _491_fa_cl_fwd : packoffset(c17);\n    float4 _491_fa_cl_grid : packoffset(c18);\n    float4 _491_fa_cl_info : packoffset(c19);\n    float4 _491_fa_layers_a : packoffset(c20);\n    float4 _491_fa_layers_b : packoffset(c21);\n    float4 _491_fa_layers_c : packoffset(c22);\n    float4 _491_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2208_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2208_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2208_fa_shadow_info[4] : packoffset(c20);\n    float4 _2208_fa_shadow_split : packoffset(c24);\n    float4 _2208_fa_shadow_cfg : packoffset(c25);\n    float4 _2208_fa_shadow_bias : packoffset(c26);\n    float4 _2208_fa_shadow_eye : packoffset(c27);\n    float4 _2208_fa_shadow_fwd : packoffset(c28);\n    float4 _2208_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _5379_boost : packoffset(c0);\n    float _5379_fa_pad0 : packoffset(c0.y);\n    float _5379_fa_pad1 : packoffset(c0.z);\n    float _5379_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t11);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t10);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float3 fa_lm : TEXCOORD7;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\nstatic float raise;\nstatic float4 tint;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1479 = _491_fa_cl_info.x < 0.0f;\n    bool _1486;\n    if (!_1479)\n    {\n        _1486 = _491_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1486 = _1479;\n    }\n    bool _1494;\n    if (!_1486)\n    {\n        _1494 = _491_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1494 = _1486;\n    }\n    bool _1501;\n    if (!_1494)\n    {\n        _1501 = _491_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1501 = _1494;\n    }\n    bool _1508;\n    if (!_1501)\n    {\n        _1508 = _491_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1508 = _1501;\n    }\n    if (_1508)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1518 = float4(world_pos, 1.0f);\n    float _1524 = dot(_491_fa_cl_vpw, _1518);\n    if (!(_1524 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1546 = float2(dot(_491_fa_cl_vpx, _1518), dot(_491_fa_cl_vpy, _1518)) / _1524.xx;\n    int _1550 = int(_491_fa_cl_grid.x);\n    int _1554 = int(_491_fa_cl_grid.y);\n    int param = (int(_491_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_491_fa_cl_fwd.xyz, world_pos) + _491_fa_cl_fwd.w, _491_fa_cl_grid.w) / _491_fa_cl_grid.w) * _491_fa_cl_grid.z)), 0, int(_491_fa_cl_info.y) - 1) * _1554) + clamp(int(floor(((_1546.y * 0.5f) + 0.5f) * _491_fa_cl_grid.y)), 0, _1554 - 1)) * _1550)) + clamp(int(floor(((_1546.x * 0.5f) + 0.5f) * _491_fa_cl_grid.x)), 0, _1550 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1630 = fa_cluster_texel(param);\n    return int2(int(_1630.x), int(_1630.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_491_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4323 = fa_cluster_lookup(param);\n    fa_cl_slot = _4323.x;\n    fa_cl_local = _4323.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _5431 = fa_linear_to_srgb(param);\n        c = _5431;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _5439 = fa_srgb_to_linear(param_1);\n            c = _5439;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _423;\n    if (i.front_facing)\n    {\n        _423 = i.world_normal;\n    }\n    else\n    {\n        _423 = -i.world_normal;\n    }\n    float3 _447 = normalize(i.world_tangent.xyz - (_423 * dot(_423, i.world_tangent.xyz)));\n    float3 _475 = normalize(((_447 * m.x) + ((cross(_423, _447) * i.world_tangent.w) * m.y)) + (_423 * m.z));\n    float3 _478;\n    if (i.front_facing)\n    {\n        _478 = _475;\n    }\n    else\n    {\n        _478 = -_475;\n    }\n    return _478;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _491_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _5470 = fa_tex_fix(param_2, param_3);\n    float4 _6885 = base_t;\n    _6885.x = _5470.x;\n    _6885.y = _5470.y;\n    _6885.z = _5470.z;\n    base_t = _6885;\n    float4 _5484 = (_6885 * _491_fa_base_color) * i.vertex_color;\n    float3 _6723 = i.world_normal;\n    if (_491_fa_maps.z > 0.5f)\n    {\n        float param_4 = _491_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _5516 = fa_tex_fix(param_6, param_7);\n        float3 _5519 = (_5516 * 2.0f) - 1.0f.xxx;\n        float2 _5524 = _5519.xy * _491_fa_maps.x;\n        float3 _6893 = _5519;\n        _6893.x = _5524.x;\n        _6893.y = _5524.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _6893;\n        _6723 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _491_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _5552 = fa_tex_fix(param_12, param_13);\n    float4 _6896 = mrt;\n    _6896.x = _5552.x;\n    _6896.y = _5552.y;\n    _6896.z = _5552.z;\n    mrt = _6896;\n    float4 _5580 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _491_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _5580.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _5591 = fa_tex_fix(param_16, param_17);\n    float param_18 = _491_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _5621 = fa_tex_fix(param_20, param_21);\n    float _6728 = _491_fa_layers_a.x;\n    float _6729 = _491_fa_layers_a.y;\n    float _6732 = _491_fa_layers_a.z;\n    float _6731 = _491_fa_layers_b.w;\n    float _6734 = _491_fa_layers_c.x;\n    if (_491_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_491_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _6728 *= _5591.y;\n            _6729 *= _5591.z;\n            _6731 *= _5580.w;\n        }\n        if (_491_fa_layers_c.z > 1.5f)\n        {\n            _6732 *= mrt.x;\n            _6734 *= mrt.w;\n        }\n    }\n    Surface _6753 = { _5484.xyz, _5484.w, _6723, clamp(_491_fa_pbr.x * _5552.z, 0.0f, 1.0f), clamp(_491_fa_pbr.y * _5552.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_491_fa_maps.y * (_5591.x - 1.0f)), _491_fa_emissive.xyz + (_491_fa_model_emissive.xyz * _5621), _6728, _6729, _491_fa_layers_b.xyz, _6731, _6732, _491_fa_layers_a.w, _6734, _491_fa_layers_c.y, _491_fa_layers_d.xyz };\n    return _6753;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * _5379_boost);\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1710 = rect.zw - rect.xy;\n    float2 _1714 = _1710 * atlas;\n    float2 _1718 = ddx * _1714;\n    float2 _1722 = ddy * _1714;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1710), clamp(0.5f * log2(max(max(dot(_1718, _1718), dot(_1722, _1722)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1755 = _491_fa_counts.y < 0.5f;\n    bool _1762;\n    if (!_1755)\n    {\n        _1762 = _491_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1762 = _1755;\n    }\n    if (_1762)\n    {\n        return;\n    }\n    float3 _1768 = ddx(world_pos);\n    float3 _1771 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1775 = fa_cluster_texel(param);\n    int _1779 = int(_1775.w);\n    if (_1779 < 1)\n    {\n        return;\n    }\n    int _1789 = int(_491_fa_counts.y + 0.5f);\n    int param_1 = _1789;\n    float4 _1793 = fa_light_texel(param_1);\n    float2 _1796 = _1793.yz;\n    int _1800 = int(_1793.w);\n    int param_2 = _1789 + 1;\n    float4 _1805 = fa_light_texel(param_2);\n    float _1806 = _1805.x;\n    int _1812 = int(_491_fa_counts.w + 0.5f) - 1;\n    int _1816 = int(_1775.z);\n    float3 _2081;\n    for (int k = 0; k < _1779; k++)\n    {\n        int _1829 = _1816 + k;\n        int param_3 = _1800 + (_1829 >> 2);\n        int _1846 = (_1789 + 2) + (int(fa_light_texel(param_3)[_1829 & 3]) * 7);\n        int param_4 = _1846 + 6;\n        float4 _1851 = fa_light_texel(param_4);\n        if (((int(_1851.w + 0.5f) >> _1812) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1846;\n        float4 _1866 = fa_light_texel(param_5);\n        int param_6 = _1846 + 1;\n        float4 _1871 = fa_light_texel(param_6);\n        int param_7 = _1846 + 2;\n        float4 _1876 = fa_light_texel(param_7);\n        float3 _1879 = _1866.xyz;\n        float _1884 = dot(_1879, world_pos) + _1866.w;\n        float3 _1886 = _1871.xyz;\n        float _1891 = dot(_1886, world_pos) + _1871.w;\n        float3 _1893 = _1876.xyz;\n        float _1898 = dot(_1893, world_pos) + _1876.w;\n        bool _1903 = abs(_1884) > 0.5f;\n        bool _1911;\n        if (!_1903)\n        {\n            _1911 = abs(_1891) > 0.5f;\n        }\n        else\n        {\n            _1911 = _1903;\n        }\n        bool _1919;\n        if (!_1911)\n        {\n            _1919 = abs(_1898) > 0.5f;\n        }\n        else\n        {\n            _1919 = _1911;\n        }\n        if (_1919)\n        {\n            continue;\n        }\n        float _1934 = clamp(dot(geo_normal, normalize(_1893)) * _1851.z, 0.0f, 1.0f);\n        if (_1934 <= 0.0f)\n        {\n            continue;\n        }\n        float _1954 = (clamp((0.5f - abs(_1898)) * 10.0f, 0.0f, 1.0f) * _1934) * _1851.x;\n        float2 _1962 = float2(_1884 + 0.5f, 0.5f - _1891);\n        float2 _1972 = float2(dot(_1879, _1768), dot(_1886, _1768));\n        float2 _1982 = float2(dot(_1879, _1771), dot(_1886, _1771));\n        int param_8 = _1846 + 5;\n        float4 _1987 = fa_light_texel(param_8);\n        int param_9 = _1846 + 3;\n        float4 _1992 = fa_light_texel(param_9);\n        int param_10 = _1846 + 4;\n        float4 _1997 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1987.xyz;\n        bool _2007 = _1992.z > _1992.x;\n        if (_2007)\n        {\n            float4 param_11 = _1992;\n            float2 param_12 = _1962;\n            float2 param_13 = _1796;\n            float2 param_14 = _1972;\n            float2 param_15 = _1982;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1806 > 0.5f) && (_1806 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _2033 = fa_dc_to_linear(param_16);\n                float4 _6803 = tx;\n                _6803.x = _2033.x;\n                _6803.y = _2033.y;\n                _6803.z = _2033.z;\n                tx = _6803;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1954 * tex_a) * _1987.w, 0.0f, 1.0f).xxx);\n        if (_1997.z > _1997.x)\n        {\n            float4 param_17 = _1997;\n            float2 param_18 = _1962;\n            float2 param_19 = _1796;\n            float2 param_20 = _1972;\n            float2 param_21 = _1982;\n            float4 _2077 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1806 > 1.5f)\n            {\n                float3 param_22 = _2077.xyz;\n                float3 _2087 = fa_dc_to_srgb(param_22);\n                _2081 = _2087;\n            }\n            else\n            {\n                _2081 = _2077.xyz;\n            }\n            float3 _2096 = (_2081 * 2.0f) - 1.0f.xxx;\n            float2 _2101 = _2096.xy * _1851.y;\n            float3 _2123 = (normalize(_1879) * _2101.x) + (normalize(_1886) * _2101.y);\n            float3 _2126 = normalize(normal);\n            normal = normalize(lerp(_2126, normalize((_2126 * max(_2096.z, 0.0500000007450580596923828125f)) + (_2123 - (_2126 * dot(_2126, _2123)))), clamp(_1954 * (_2007 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3427 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3435 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3438 = int(_3427);\n    int _3441 = int(_3435);\n    float _3451 = _3435 - float(_3441);\n    int _3507 = (_3438 * 9) + _3441;\n    int _3527 = ((_3438 + 1) * 9) + _3441;\n    return lerp(lerp(_3502[_3507], _3502[_3507 + 1], _3451), lerp(_3502[_3527], _3502[_3527 + 1], _3451), _3427 - float(_3438));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _6646 = false;\n    float _6647 = 1.0f;\n    float _6648 = 1.0f;\n    float _6649 = 1.0f;\n    float _6650 = 0.0f;\n    float _6651 = 0.0f;\n    float _6652 = 0.0f;\n    float _6653 = 0.0f;\n    float _6655 = 1.0f;\n    bool _6656 = false;\n    float3 _6657 = 0.0f.xxx;\n    float _6658 = 1.0f;\n    float _6659 = 1.0f;\n    float _6660 = 1.0f;\n    float _6661 = 0.0f;\n    float _6662 = 0.0f;\n    float3 _6663 = float3(1.0f, 0.0f, 0.0f);\n    float3 _6664 = float3(0.0f, 0.0f, 1.0f);\n    float _6665 = 1.0f;\n    float _6666 = 1.0f;\n    float _3578 = clamp(s.specular, 0.0f, 1.0f);\n    float _3582 = clamp(s.ior, 1.0f, 3.0f);\n    bool _3587 = (_3578 != 1.0f) || (_3582 != 1.5f);\n    bool _3596;\n    if (!_3587)\n    {\n        _3596 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _3596 = _3587;\n    }\n    if (_3596)\n    {\n        float _3604 = (_3582 - 1.0f) / (_3582 + 1.0f);\n        f0 = lerp(min((_3604 * _3604).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _3578, s.albedo, metallic.xxx);\n        _6647 = lerp(_3578, 1.0f, metallic);\n        _6646 = true;\n    }\n    float _3631 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_3631 > 0.0f)\n    {\n        float _3639 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _6650 = _3631;\n        _6651 = _3639;\n        float _3646 = _3639 * _3639;\n        _6652 = _3646;\n        _6653 = _3646 * _3646;\n        float _3658 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _6655 = _3658;\n        _6648 = 1.0f - (_3631 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _3658, 0.0f, 1.0f), 5.0f))));\n        _6646 = true;\n    }\n    float3 _3678 = max(s.sheen_color, 0.0f.xxx);\n    float _3687 = max(_3678.x, max(_3678.y, _3678.z));\n    if (_3687 > 0.0f)\n    {\n        float _3695 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _6656 = true;\n        _6657 = _3678;\n        _6658 = _3695;\n        _6659 = _3695 * _3695;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _3695;\n        float _3712 = fa_sheen_albedo(param, param_1);\n        _6661 = _3712;\n        _6660 = 1.0f - min(_3687 * _3712, 1.0f);\n        _6646 = true;\n    }\n    _6649 = _6648 * _6660;\n    float _3731 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_3731 != 0.0f)\n    {\n        float3 _3746 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _3746;\n        if (dot(_3746, _3746) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _3758 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_3758.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _3758.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _3758.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _3762 = t;\n        float3 _3763 = normalize(_3762);\n        t = _3763;\n        float3 _3788 = normalize((_3763 * cos(s.anisotropy_rotation)) + ((cross(n, _3763) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _6663 = _3788;\n        _6664 = cross(n, _3788);\n        float _3798 = roughness * roughness;\n        float _3804 = lerp(_3798, 1.0f, _3731 * _3731);\n        bool _3806 = _3731 > 0.0f;\n        _6665 = _3806 ? _3804 : _3798;\n        _6666 = _3806 ? _3798 : _3804;\n        _6662 = _3731;\n        _6646 = true;\n    }\n    FaLayers _6688 = { _6646, _6647, _6648, _6649, _6650, _6651, _6652, _6653, i.world_normal, _6655, _6656, _6657, _6658, _6659, _6660, _6661, _6662, _6663, _6664, _6665, _6666 };\n    return _6688;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_491_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _491_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_491_fa_cl_info.x) + int(_491_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_491_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _562_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _562_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _728 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _741 = (c - (ru * hx)) - p;\n        float3 _747 = ru * (2.0f * hx);\n        float _753 = max(dot(_747, _747), 9.9999999392252902907785028219223e-09f);\n        float _757 = dot(_741, _747);\n        float t = clamp((-_757) / _753, 0.0f, 1.0f);\n        if (_728)\n        {\n            float _772 = dot(r, _747);\n            float _778 = _753 - (_772 * _772);\n            if (abs(_778) > (9.9999997473787516355514526367188e-06f * _753))\n            {\n                t = clamp(((dot(r, _741) * _772) - _757) / _778, 0.0f, 1.0f);\n            }\n        }\n        return (p + _741) + (_747 * t);\n    }\n    float3 q = p;\n    float _810 = dot(r, axis);\n    bool _818;\n    if (_728)\n    {\n        _818 = abs(_810) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _818 = _728;\n    }\n    if (_818)\n    {\n        float _828 = dot(c - p, axis) / _810;\n        if (_828 > 0.0f)\n        {\n            q = p + (r * _828);\n        }\n    }\n    float3 _841 = q - c;\n    float2 xy = float2(dot(_841, ru), dot(_841, uu));\n    if (shape > 0.5f)\n    {\n        float _856 = length(xy);\n        if (_856 > hx)\n        {\n            xy *= (hx / _856);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _649 = abs(d);\n    float _651 = _649.x;\n    float _653 = _649.y;\n    bool _654 = _651 >= _653;\n    bool _662;\n    if (_654)\n    {\n        _662 = _651 >= _649.z;\n    }\n    else\n    {\n        _662 = _654;\n    }\n    int _663;\n    if (_662)\n    {\n        _663 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _676;\n        if (_653 >= _649.z)\n        {\n            _676 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _676 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _663 = _676;\n    }\n    return _663;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _602 = dot(d, right);\n    float _606 = dot(d, up);\n    float _617;\n    if (((_602 * _602) + (_606 * _606)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _617 = atan2(_606, _602) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _617 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_617 - floor(_617)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _894 = fa_light_base(param);\n    bool _898 = _491_fa_ambient.w > 4.5f;\n    int param_1 = _894;\n    float4 _902 = fa_light_texel(param_1);\n    int param_2 = _894 + 1;\n    float4 _907 = fa_light_texel(param_2);\n    float _910 = _907.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _922 = _898 && (_910 > 2.5f);\n    fa_light_is_area = _922;\n    bool _924 = _910 < 0.5f;\n    float3 l;\n    if (_924)\n    {\n        l = normalize(_902.xyz);\n        if (_898)\n        {\n            int param_3 = _894 + 6;\n            float4 _938 = fa_light_texel(param_3);\n            if (_938.z > 0.5f)\n            {\n                int param_4 = _894 + 4;\n                float4 _948 = fa_light_texel(param_4);\n                int param_5 = _894 + 5;\n                float4 _953 = fa_light_texel(param_5);\n                float2 param_6 = _938.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _948.xyz) * _948.w, (-dot(world_pos, _953.xyz)) * _953.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _983 = _902.xyz;\n        float3 _985 = _983 - world_pos;\n        float3 to_light = _985;\n        float _988 = length(_985);\n        float reach = _988;\n        bool front = true;\n        if (_922)\n        {\n            int param_8 = _894 + 7;\n            reach = max(_988 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _894 + 4;\n            float4 _1012 = fa_light_texel(param_9);\n            int param_10 = _894 + 5;\n            float4 _1017 = fa_light_texel(param_10);\n            int param_11 = _894 + 6;\n            float4 _1022 = fa_light_texel(param_11);\n            float _1023 = _1022.w;\n            int param_12 = _894 + 2;\n            float3 _1030 = normalize(fa_light_texel(param_12).xyz);\n            bool _1032 = _1023 > 1.5f;\n            bool _1040;\n            if (!_1032)\n            {\n                _1040 = dot(_1030, to_light) < 0.0f;\n            }\n            else\n            {\n                _1040 = _1032;\n            }\n            front = _1040;\n            float3 r = 0.0f.xxx;\n            float3 _1049 = _491_fa_camera_pos.xyz - world_pos;\n            bool _1053 = dot(n, n) > 0.5f;\n            bool _1061;\n            if (_1053)\n            {\n                _1061 = dot(_1049, _1049) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _1061 = _1053;\n            }\n            if (_1061)\n            {\n                r = reflect(-normalize(_1049), normalize(n));\n            }\n            float3 param_13 = _983;\n            float3 param_14 = _1030;\n            float3 param_15 = _1012.xyz;\n            float3 param_16 = _1017.xyz;\n            float param_17 = _1012.w;\n            float param_18 = _1017.w;\n            float param_19 = _1023;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1097 = length(to_light);\n        dist = _1097;\n        l = to_light / max(_1097, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1111 = reach / max(_902.w, 0.001000000047497451305389404296875f);\n        float _1117 = clamp(1.0f - (_1111 * _1111), 0.0f, 1.0f);\n        float _1119;\n        if (front)\n        {\n            _1119 = _1117 * _1117;\n        }\n        else\n        {\n            _1119 = 0.0f;\n        }\n        atten = _1119;\n        bool _1130 = _910 < 2.5f;\n        if ((_910 > 1.5f) && _1130)\n        {\n            int param_22 = _894 + 2;\n            float4 _1138 = fa_light_texel(param_22);\n            float _1148 = _1138.w;\n            int param_23 = _894 + 3;\n            float4 _1153 = fa_light_texel(param_23);\n            float _1154 = _1153.x;\n            float cos_inner = _1154;\n            if (_1154 > 1.5f)\n            {\n                cos_inner = lerp(_1148, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1148, cos_inner, dot(-l, normalize(_1138.xyz)));\n        }\n        if (_898 && (_910 < 1.5f))\n        {\n            int param_24 = _894 + 6;\n            float4 _1178 = fa_light_texel(param_24);\n            if (_1178.z > 0.5f)\n            {\n                float3 _1186 = -to_light;\n                int param_25 = _894 + 4;\n                int param_26 = _894 + 5;\n                float3 _1200 = fa_light_texel(param_25).xyz;\n                float3 _1204 = fa_light_texel(param_26).xyz;\n                float3 _1213 = float3(dot(_1186, _1200), dot(_1186, _1204), dot(_1186, cross(_1200, _1204)));\n                float3 param_27 = _1213;\n                int _1217 = fa_cube_face(param_27);\n                int param_28 = _1217;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1244 = float2(dot(_1213, cross(param_29, param_30)), dot(_1213, param_30)) / max(dot(_1213, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1248 = _1217 / 3;\n                float2 param_31 = _1178.xy + (float2(float(_1217 - (_1248 * 3)), float(_1248)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1244.x), 0.5f - (0.5f * _1244.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _894 + 7;\n            float4 _1278 = fa_light_texel(param_33);\n            if (_1278.z > 0.5f)\n            {\n                int param_34 = _894 + 2;\n                int param_35 = _894 + 4;\n                int param_36 = _894 + 5;\n                float2 param_37 = _1278.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_898 && _1130)\n            {\n                int param_42 = _894 + 6;\n                float4 _1325 = fa_light_texel(param_42);\n                int param_43 = _894 + 7;\n                float4 _1330 = fa_light_texel(param_43);\n                bool _1333 = _1325.z > 0.5f;\n                bool _1340;\n                if (!_1333)\n                {\n                    _1340 = _1330.z > 0.5f;\n                }\n                else\n                {\n                    _1340 = _1333;\n                }\n                if (_1340)\n                {\n                    int param_44 = _894 + 2;\n                    float4 _1347 = fa_light_texel(param_44);\n                    float3 _1351 = normalize(_1347.xyz);\n                    int param_45 = _894 + 4;\n                    float4 _1356 = fa_light_texel(param_45);\n                    int param_46 = _894 + 5;\n                    float4 _1361 = fa_light_texel(param_46);\n                    if (_1333)\n                    {\n                        float3 _1369 = -to_light;\n                        float _1376 = _1347.w;\n                        float _1392 = 0.5f / max(dot(_1369, _1351) * (sqrt(max(1.0f - (_1376 * _1376), 0.0f)) / max(_1376, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1325.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1369, _1356.xyz) * _1392), 0.5f - (dot(_1369, _1361.xyz) * _1392));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1330.z > 0.5f)\n                    {\n                        float2 param_49 = _1330.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1351;\n                        float3 param_52 = _1356.xyz;\n                        float3 param_53 = _1361.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _6634 = _907.xyz * atten;\n    if (_898)\n    {\n        _6634 *= fa_light_tint;\n    }\n    int _1461;\n    if (_924)\n    {\n        _1461 = 0;\n    }\n    else\n    {\n        _1461 = ((_910 > 1.5f) && (_910 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _6645 = { l, _6634, atten, 1.0f, dist, _1461 };\n    return _6645;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2198;\n    if (i == 0)\n    {\n        _2198 = _2208_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2214;\n        if (i == 1)\n        {\n            _2214 = _2208_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2222;\n            if (i == 2)\n            {\n                _2222 = _2208_fa_shadow_split.z;\n            }\n            else\n            {\n                _2222 = _2208_fa_shadow_split.w;\n            }\n            _2214 = _2222;\n        }\n        _2198 = _2214;\n    }\n    return _2198;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2255 = fa_shadow_depth(param, param_1);\n    float _2259;\n    if (conv.x < 0.5f)\n    {\n        _2259 = _2255;\n    }\n    else\n    {\n        _2259 = (conv.y * conv.z) / (conv.z - (_2255 * (conv.z - conv.y)));\n    }\n    return _2259;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2186 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2186), sin(_2186)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2305 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2314;\n        if (k < 0.0f)\n        {\n            _2314 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2314 = k;\n        }\n        float _2334 = clamp((_2314 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2305;\n            float2 _2353 = fa_shadow_vogel(param_3, param_4, param_5) * _2334;\n            float2 param_6 = uv + (_2353 * _2208_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2365 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2365 < (zr - (length(_2353) * plane)))\n            {\n                sum += _2365;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2391 = sum / cnt;\n        float _2401;\n        if (k < 0.0f)\n        {\n            _2401 = (-k) / max(_2391, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2401 = k;\n        }\n        radius = clamp(((max(zr - _2391, 0.0f) * unit) * _2401) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2423 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2423; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2423;\n        float param_11 = _2305;\n        float2 _2442 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2442 * _2208_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2442) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2423);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2484 = max(_2208_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2489 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2495 = sqrt(1.0f - (_2489 * _2489));\n    float _2502 = min(_2495 / max(_2489, 0.20000000298023223876953125f), 4.0f);\n    float _2507;\n    if (_2208_fa_shadow_bias.y > 0.0f)\n    {\n        _2507 = _2208_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2507 = 1.5f * _2208_fa_shadow_info[ci].x;\n    }\n    float4 _2532 = mul(float4(world + (n * (_2507 * _2495)), 1.0f), _2208_fa_shadow_mat[ci]);\n    float _2539 = _2532.x;\n    bool _2542 = _2539 < _2208_fa_shadow_rect[ci].x;\n    bool _2551;\n    if (!_2542)\n    {\n        _2551 = _2539 > _2208_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2551 = _2542;\n    }\n    bool _2560;\n    if (!_2551)\n    {\n        _2560 = _2532.y < _2208_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2560 = _2551;\n    }\n    bool _2569;\n    if (!_2560)\n    {\n        _2569 = _2532.y > _2208_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2569 = _2560;\n    }\n    bool _2576;\n    if (!_2569)\n    {\n        _2576 = _2532.z > 1.0f;\n    }\n    else\n    {\n        _2576 = _2569;\n    }\n    if (_2576)\n    {\n        return -1.0f;\n    }\n    float _2584;\n    if (_2208_fa_shadow_bias.x > 0.0f)\n    {\n        _2584 = _2208_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2584 = 1.5f * _2208_fa_shadow_info[ci].x;\n    }\n    float2 param = _2532.xy;\n    float4 param_1 = _2208_fa_shadow_rect[ci];\n    float param_2 = _2532.z - ((_2584 * (1.0f + (0.5f * _2502))) / _2484);\n    float param_3 = _2208_fa_shadow_info[ci].x;\n    float param_4 = _2484;\n    float param_5 = _2484 * 0.25f;\n    float param_6 = ((_2208_fa_shadow_info[ci].x * min(_2502, 3.0f)) * 0.5f) / _2484;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2208_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2208_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_491_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2972 = int(_2208_fa_shadow_cfg.x + 0.5f);\n    if (_2972 < 1)\n    {\n        return 1.0f;\n    }\n    float _2987 = dot(world - _2208_fa_shadow_eye.xyz, _2208_fa_shadow_fwd.xyz);\n    int param = _2972 - 1;\n    if (_2987 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2999 = _2972 > 1;\n    bool _3006;\n    if (_2999)\n    {\n        _3006 = _2987 > _2208_fa_shadow_split.x;\n    }\n    else\n    {\n        _3006 = _2999;\n    }\n    if (_3006)\n    {\n        ci = 1;\n    }\n    bool _3010 = _2972 > 2;\n    bool _3017;\n    if (_3010)\n    {\n        _3017 = _2987 > _2208_fa_shadow_split.y;\n    }\n    else\n    {\n        _3017 = _3010;\n    }\n    if (_3017)\n    {\n        ci = 2;\n    }\n    bool _3021 = _2972 > 3;\n    bool _3028;\n    if (_3021)\n    {\n        _3028 = _2987 > _2208_fa_shadow_split.z;\n    }\n    else\n    {\n        _3028 = _3021;\n    }\n    if (_3028)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2972)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _3054 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3054;\n        if (_3054 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2208_fa_shadow_cfg.y > 0.0f)\n    {\n        float _3079;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3079 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3079 = _2208_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _3098 = _2208_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3079, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _3109 = clamp((_2987 - (fa_shadow_split_at(param_7) - _3098)) / _3098, 0.0f, 1.0f);\n        if (_3109 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2972)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _3130 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3130;\n                if (_3130 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _3109);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _2642 = _491_fa_pbr.z < 0.5f;\n    bool _2649;\n    if (!_2642)\n    {\n        _2649 = _2208_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2649 = _2642;\n    }\n    if (_2649)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2208_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2662 = fa_light_texel(param);\n    float _2663 = _2662.x;\n    if (_2663 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2672 = int(_2663 + 0.5f);\n    int param_1 = _2672;\n    float4 _2676 = fa_light_texel(param_1);\n    int param_2 = _2672 + 1;\n    float4 _2681 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2684 = _2676.y;\n    if (_2684 > 0.0f)\n    {\n        float _2701 = 1.0f - smoothstep(0.75f * _2684, _2684, length(world - _2208_fa_shadow_eye.xyz));\n        fade = _2701;\n        if (_2701 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2676.x > 1.5f)\n    {\n        int param_3 = li;\n        int param_4 = fa_light_base(param_3);\n        float3 param_5 = world - fa_light_texel(param_4).xyz;\n        face = fa_cube_face(param_5);\n    }\n    int _2730 = (_2672 + 2) + (face * 6);\n    int param_6 = _2730;\n    int param_7 = _2730 + 1;\n    int param_8 = _2730 + 3;\n    float4 _2744 = fa_light_texel(param_8);\n    int param_9 = _2730 + 4;\n    float4 _2749 = fa_light_texel(param_9);\n    int param_10 = _2730 + 5;\n    float4 _2754 = fa_light_texel(param_10);\n    float _2766 = _2754.x * max(dot(_2744, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2771 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2794 = clamp(dot(n, _2744.xyz), -1.0f, 1.0f);\n    int param_11 = li;\n    int param_12 = fa_light_base(param_11);\n    float _2818 = min(sqrt(1.0f - (_2794 * _2794)) / max(abs(dot(n, world - fa_light_texel(param_12).xyz)) / max(dot(_2744, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2821 = _2681.y;\n    float _2823;\n    if (_2821 > 0.0f)\n    {\n        _2823 = _2821;\n    }\n    else\n    {\n        _2823 = 1.5f * _2766;\n    }\n    float4 _2843 = float4(world + (n * (_2823 * sqrt(1.0f - (_2771 * _2771)))), 1.0f);\n    float _2847 = dot(_2744, _2843);\n    float _2850 = _2754.y;\n    if (_2847 < _2850)\n    {\n        return 1.0f;\n    }\n    float2 _2865 = float2(dot(fa_light_texel(param_6), _2843), dot(fa_light_texel(param_7), _2843)) / _2847.xx;\n    float _2867 = _2865.x;\n    bool _2870 = _2867 < _2749.x;\n    bool _2879;\n    if (!_2870)\n    {\n        _2879 = _2867 > _2749.z;\n    }\n    else\n    {\n        _2879 = _2870;\n    }\n    bool _2888;\n    if (!_2879)\n    {\n        _2888 = _2865.y < _2749.y;\n    }\n    else\n    {\n        _2888 = _2879;\n    }\n    bool _2897;\n    if (!_2888)\n    {\n        _2897 = _2865.y > _2749.w;\n    }\n    else\n    {\n        _2897 = _2888;\n    }\n    if (_2897)\n    {\n        return 1.0f;\n    }\n    float _2903 = _2681.x;\n    float _2905;\n    if (_2903 > 0.0f)\n    {\n        _2905 = _2903;\n    }\n    else\n    {\n        _2905 = 1.5f * _2766;\n    }\n    float2 param_13 = _2865;\n    float4 param_14 = _2749;\n    float param_15 = _2847 - (_2905 * (1.0f + (0.5f * _2818)));\n    float param_16 = _2766;\n    float param_17 = 1.0f;\n    float param_18 = _2754.z * 0.25f;\n    float param_19 = (_2766 * min(_2818, 3.0f)) * 0.5f;\n    float3 param_20 = float3(1.0f, _2850, _2754.z);\n    int param_21 = int(_2676.z + 0.5f);\n    float param_22 = _2676.w;\n    return lerp(1.0f, fa_shadow_filter(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _4350 = fa_lm.z > 0.5f;\n    bool _4356;\n    if (_4350)\n    {\n        int param = li;\n        _4356 = fa_light_baked(param);\n    }\n    else\n    {\n        _4356 = _4350;\n    }\n    if (_4356)\n    {\n        int param_1 = li;\n        LightSample _6701 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _6701;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4380 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _6703 = _4380.color;\n    float _6705 = _4380.shadow;\n    if ((_4380.type == 0) && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4380.direction;\n        float _4394 = fa_shadow_factor(param_5, param_6);\n        _6705 = _4394;\n        _6703 *= _4394;\n    }\n    else\n    {\n        bool _4405 = _4380.type != 0;\n        bool _4411;\n        if (_4405)\n        {\n            _4411 = _4380.attenuation > 0.0f;\n        }\n        else\n        {\n            _4411 = _4405;\n        }\n        if (_4411)\n        {\n            int param_7 = li;\n            float3 param_8 = world_pos;\n            float3 param_9 = gn;\n            float3 param_10 = _4380.direction;\n            float _4423 = fa_shadow_local(param_7, param_8, param_9, param_10);\n            _6705 = _4423;\n            _6703 *= _4423;\n        }\n    }\n    LightSample _6720 = { _4380.direction, _6703, _4380.attenuation, _6705, _4380._distance, _4380.type };\n    return _6720;\n}\n\nfloat3 fa_ltc_tangent(float3 n, float3 v)\n{\n    float3 _4463 = v - (n * dot(v, n));\n    float3 t = _4463;\n    float _4467 = dot(_4463, _4463);\n    float l2 = _4467;\n    if (_4467 < 1.0000000133514319600180897396058e-10f)\n    {\n        float3 _4477;\n        if (abs(n.z) < 0.999000012874603271484375f)\n        {\n            _4477 = cross(n, float3(0.0f, 0.0f, 1.0f));\n        }\n        else\n        {\n            _4477 = cross(n, float3(1.0f, 0.0f, 0.0f));\n        }\n        t = _4477;\n        l2 = dot(_4477, _4477);\n    }\n    return t * rsqrt(l2);\n}\n\nfloat3 fa_ltc_local(float3 t1, float3 n, float3 p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nfloat3 fa_ltc_edge_vector(float3 a, float3 b)\n{\n    float _4512 = dot(a, a);\n    float _4516 = dot(b, b);\n    if ((_4512 < 1.0000000195414813782625560981111e-24f) || (_4516 < 1.0000000195414813782625560981111e-24f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _4530 = a * rsqrt(_4512);\n    float3 _4535 = b * rsqrt(_4516);\n    float _4539 = dot(_4530, _4535);\n    float _4542 = abs(_4539);\n    float g = (((((((((((0.0416471660137176513671875f * _4542) - 0.1924748718738555908203125f) * _4542) + 0.4179156124591827392578125f) * _4542) - 0.616057217121124267578125f) * _4542) + 0.777722418308258056640625f) * _4542) - 0.999542415142059326171875f) * _4542) + 1.570791721343994140625f;\n    if (_4539 < 0.0f)\n    {\n        g = (3.1415927410125732421875f * rsqrt(max(1.0f - (_4539 * _4539), 1.0000000116860974230803549289703e-07f))) - g;\n    }\n    return cross(_4530, _4535) * g;\n}\n\nvoid fa_ltc_clip_edge(float3 a, float3 b, inout float3 sum, inout float3 leave, inout float3 enter, inout float2 seen)\n{\n    bool _4599 = a.z > 0.0f;\n    bool _4603 = b.z > 0.0f;\n    if (_4599 && _4603)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_4599 != _4603)\n        {\n            float3 _4638 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _4638.z = 0.0f;\n            if (_4599)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _4638;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _4638;\n                seen.x = 1.0f;\n            }\n            else\n            {\n                float3 param_4 = _4638;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _4638;\n                seen.y = 1.0f;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(float4 abcd, float3 p0, float3 p1, float3 p2, float3 p3)\n{\n    float3 _4687 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _4713 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _4739 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _4765 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = 0.0f.xxx;\n    float3 leave = 0.0f.xxx;\n    float3 enter = 0.0f.xxx;\n    float3 param = _4687;\n    float3 param_1 = _4713;\n    float3 param_2 = 0.0f.xxx;\n    float3 param_3 = 0.0f.xxx;\n    float3 param_4 = 0.0f.xxx;\n    float2 param_5 = 0.0f.xx;\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _4713;\n    float3 param_7 = _4739;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _4739;\n    float3 param_13 = _4765;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _4765;\n    float3 param_19 = _4687;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5f)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875f;\n}\n\nfloat fa_ltc_rect(float4 abcd, float3 center, float3 ex, float3 ey)\n{\n    float4 param = abcd;\n    float3 param_1 = (center - ex) - ey;\n    float3 param_2 = (center + ex) - ey;\n    float3 param_3 = (center + ex) + ey;\n    float3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(float4 m, float shape, float3 pc, float3 ex, float3 ey)\n{\n    if ((shape < 0.5f) || (shape > 1.5f))\n    {\n        float4 param = m;\n        float3 param_1 = pc;\n        float3 param_2 = ex;\n        float3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    float3 _4915 = (pc + (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _4939 = (pc - (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _4955 = (pc - (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float4 param_4 = m;\n    float3 param_5 = _4915;\n    float3 param_6 = (pc + (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_7 = (pc - (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_8 = _4939;\n    float4 param_9 = m;\n    float3 param_10 = _4915;\n    float3 param_11 = _4939;\n    float3 param_12 = (pc - (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    float3 param_13 = _4955;\n    float4 param_14 = m;\n    float3 param_15 = _4915;\n    float3 param_16 = _4955;\n    float3 param_17 = (pc + (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float3 param_18 = (pc + (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nfloat2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((float2(clamp((roughness - 0.0500000007450580596923828125f) * 1.0526316165924072265625f, 0.0f, 1.0f), sqrt(clamp(1.0f - ndv, 0.0f, 1.0f))) * 63.0f) + 0.5f.xx) * 0.015625f.xx;\n}\n\nfloat3 fa_area_shade(int li, float3 world_pos, float3 n, float3 v, float3 diffuse_color, float3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _5013 = fa_light_base(param);\n    int param_1 = _5013;\n    int param_2 = _5013 + 1;\n    int param_3 = _5013 + 2;\n    int param_4 = _5013 + 4;\n    float4 _5035 = fa_light_texel(param_4);\n    int param_5 = _5013 + 5;\n    float4 _5040 = fa_light_texel(param_5);\n    int param_6 = _5013 + 6;\n    float4 _5045 = fa_light_texel(param_6);\n    float _5046 = _5045.w;\n    float3 _5051 = fa_light_texel(param_1).xyz - world_pos;\n    bool _5053 = _5046 < 1.5f;\n    bool _5060;\n    if (_5053)\n    {\n        _5060 = dot(normalize(fa_light_texel(param_3).xyz), _5051) >= 0.0f;\n    }\n    else\n    {\n        _5060 = _5053;\n    }\n    if (_5060)\n    {\n        return 0.0f.xxx;\n    }\n    bool _5069 = (_5046 > 0.5f) && _5053;\n    float _5073 = _5069 ? 1.0539000034332275390625f : 1.0f;\n    float3 _5076 = _5035.xyz;\n    float _5078 = _5035.w;\n    float3 _5084 = _5040.xyz;\n    float _5086 = _5040.w;\n    float3 up = _5084 * (_5086 * _5073);\n    float _5092;\n    if (_5069)\n    {\n        _5092 = (3.1415927410125732421875f * _5078) * _5078;\n    }\n    else\n    {\n        _5092 = (4.0f * _5078) * _5086;\n    }\n    if (_5046 > 1.5f)\n    {\n        float3 _5118 = cross(_5076, -_5051);\n        float3 perp = _5118;\n        float _5122 = dot(_5118, _5118);\n        float3 _5125;\n        if (_5122 > 1.0000000133514319600180897396058e-10f)\n        {\n            _5125 = perp * rsqrt(_5122);\n        }\n        else\n        {\n            _5125 = _5084;\n        }\n        perp = _5125;\n        up = _5125 * _5086;\n    }\n    float _5146 = max(_5092, 9.9999999747524270787835121154785e-07f);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _5156 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _5156;\n    float3 param_10 = n;\n    float3 param_11 = _5051;\n    float3 _5164 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_12 = _5156;\n    float3 param_13 = n;\n    float3 param_14 = _5076 * (_5078 * _5073);\n    float3 _5172 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_15 = _5156;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float3 _5180 = fa_ltc_local(param_15, param_16, param_17);\n    float4 param_18 = float4(1.0f, 0.0f, 0.0f, 1.0f);\n    float param_19 = _5046;\n    float3 param_20 = _5164;\n    float3 param_21 = _5172;\n    float3 param_22 = _5180;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    float2 _5199 = fa_ltc_uv(param_23, param_24) * 64.0f;\n    float2 param_25 = _5199;\n    float2 param_26 = _5199 + float2(64.0f, 0.0f);\n    float4 _5209 = fa_atlas_fetch(param_26);\n    float4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _5046;\n    float3 param_29 = _5164;\n    float3 param_30 = _5172;\n    float3 param_31 = _5180;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _5209.x) + ((f90.xxx - f0) * _5209.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875f * dot(_5051, _5051)) + _5146) / _5146) * window);\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4053 = 1.0f / alpha;\n    return ((2.0f + _4053) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _4053)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat fa_layers_coat(FaLayers L, float3 l, float3 h, float vdh)\n{\n    float _4088 = max(dot(L.nc, l), 0.0f);\n    float _4094 = max(dot(L.nc, h), 0.0f);\n    float _4103 = ((_4094 * _4094) * (L.coat_a2 - 1.0f)) + 1.0f;\n    return (((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _4103) * _4103)) * (0.5f / max(lerp((2.0f * _4088) * L.coat_ndv, _4088 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _4088)) * _4088;\n}\n\nfloat3 fa_area_layers(FaLayers L, int li, float3 world_pos, float3 n, float3 v, float3 l, float3 diffuse_color, float3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    float3 param_2 = n;\n    float3 param_3 = v;\n    float3 param_4 = diffuse_color;\n    float3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _5277;\n    if (L.sheen_on)\n    {\n        _5277 = L.sheen_scale;\n    }\n    else\n    {\n        _5277 = 1.0f;\n    }\n    float3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _5277);\n    float3 _5290 = normalize(l + v);\n    int param_10 = li;\n    float3 _5301 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _5310 = max(dot(n, l), 0.0f);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _5290), 0.0f);\n        float param_13 = _5310;\n        float param_14 = ndv;\n        result += ((L.sheen * _5301) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875f) * step(9.9999997473787516355514526367188e-05f, _5310)) * _5310) * L.keep));\n    }\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_15 = L;\n        float3 param_16 = l;\n        float3 param_17 = _5290;\n        float param_18 = max(dot(v, _5290), 0.0f);\n        result += (_5301 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _3956 = tdh / at;\n    float _3960 = bdh / ab;\n    float _3972 = ((_3956 * _3956) + (_3960 * _3960)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _3972) * _3972);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4152 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4231 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _4231) * _4231);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _4152);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _4152));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_17 = L;\n        float3 param_18 = l;\n        float3 param_19 = h;\n        float param_20 = vdh;\n        result += fa_layers_coat(param_17, param_18, param_19, param_20).xxx;\n    }\n    return result;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3359 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3362 = _3359.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3362 * _3362, exp2((-9.27999973297119140625f) * ndv)) * _3362) + _3359.y)) + _3359.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_491_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _491_fa_env_horizon.w).xyz;\n    }\n    float _3265 = rough * rough;\n    float _3295 = 0.60000002384185791015625f * _3265;\n    return lerp(lerp(_491_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_491_fa_env_horizon.xyz, _491_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3265)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3295, 0.0500000007450580596923828125f + _3295, d.y).xxx), ((_491_fa_env_sky.xyz + _491_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3265 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _3839;\n        if (L.aniso >= 0.0f)\n        {\n            _3839 = L.b;\n        }\n        else\n        {\n            _3839 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_3839, v), _3839), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3872 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _3872.x) + (L.f90.xxx * _3872.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3927 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _3927.x) + _3927.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3401 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3401.x) + _3401.y.xxx);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2208_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3154 = int(_2208_fa_shadow_cfg.x + 0.5f);\n    float _3164 = dot(world - _2208_fa_shadow_eye.xyz, _2208_fa_shadow_fwd.xyz);\n    float3 tint_1 = 0.3499999940395355224609375f.xxx;\n    bool _3169 = _3154 > 0;\n    bool _3178;\n    if (_3169)\n    {\n        int param = _3154 - 1;\n        _3178 = _3164 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3178 = _3169;\n    }\n    if (_3178)\n    {\n        tint_1 = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3184 = _3154 > 1;\n        bool _3191;\n        if (_3184)\n        {\n            _3191 = _3164 > _2208_fa_shadow_split.x;\n        }\n        else\n        {\n            _3191 = _3184;\n        }\n        if (_3191)\n        {\n            tint_1 = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3197 = _3154 > 2;\n        bool _3204;\n        if (_3197)\n        {\n            _3204 = _3164 > _2208_fa_shadow_split.y;\n        }\n        else\n        {\n            _3204 = _3197;\n        }\n        if (_3204)\n        {\n            tint_1 = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3210 = _3154 > 3;\n        bool _3217;\n        if (_3210)\n        {\n            _3217 = _3164 > _2208_fa_shadow_split.z;\n        }\n        else\n        {\n            _3217 = _3210;\n        }\n        if (_3217)\n        {\n            tint_1 = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint_1, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _6403 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6403 = -_6403;\n    }\n    float3 _5761 = normalize(_491_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _6416 = { fa_world_pos, _6403, fa_world_tangent, fa_uv, fa_vertex_color, _5761, gl_FrontFacing };\n    SurfaceInput param_1 = _6416;\n    Surface _5769 = fa_standard_surface(param_1);\n    float3 _6434 = _5769.albedo;\n    float _6435 = _5769.alpha;\n    float3 _6436 = _5769.normal;\n    float _6437 = _5769.metallic;\n    float _6438 = _5769.roughness;\n    float _6439 = _5769.occlusion;\n    float3 _6440 = _5769.emission;\n    float _6441 = _5769.clearcoat;\n    float _6442 = _5769.clearcoat_roughness;\n    float3 _6443 = _5769.sheen_color;\n    float _6444 = _5769.sheen_roughness;\n    float _6445 = _5769.anisotropy;\n    float _6446 = _5769.anisotropy_rotation;\n    float _6447 = _5769.specular;\n    float _6448 = _5769.ior;\n    float3 _6449 = _5769.specular_color;\n    SurfaceInput _6424 = { fa_world_pos, _6403, fa_world_tangent, fa_uv, fa_vertex_color, _5761, gl_FrontFacing };\n    SurfaceInput param_2 = _6424;\n    Surface param_3 = _5769;\n    surface(param_2, param_3);\n    _6434 = param_3.albedo;\n    _6435 = param_3.alpha;\n    _6436 = param_3.normal;\n    _6437 = param_3.metallic;\n    _6438 = param_3.roughness;\n    _6439 = param_3.occlusion;\n    _6440 = param_3.emission;\n    _6441 = param_3.clearcoat;\n    _6442 = param_3.clearcoat_roughness;\n    _6443 = param_3.sheen_color;\n    _6444 = param_3.sheen_roughness;\n    _6445 = param_3.anisotropy;\n    _6446 = param_3.anisotropy_rotation;\n    _6447 = param_3.specular;\n    _6448 = param_3.ior;\n    _6449 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _6403;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6434 = param_6;\n    _6436 = param_7;\n    float3 result;\n    if (_491_fa_emissive.w > 0.5f)\n    {\n        result = _6434;\n    }\n    else\n    {\n        float3 _5808 = normalize(_6436);\n        float _5815 = clamp(_6437, 0.0f, 1.0f);\n        float _5819 = clamp(_6438, 0.0500000007450580596923828125f, 1.0f);\n        float _5823 = _5819 * _5819;\n        float _5827 = _5823 * _5823;\n        float _5832 = max(dot(_5808, _5761), 9.9999997473787516355514526367188e-05f);\n        float3 _5838 = _6434 * (1.0f - _5815);\n        float3 _5845 = lerp(0.039999999105930328369140625f.xxx, _6434, _5815.xxx);\n        float3 f0 = _5845;\n        SurfaceInput _6432 = { fa_world_pos, _6403, fa_world_tangent, fa_uv, fa_vertex_color, _5761, gl_FrontFacing };\n        SurfaceInput param_8 = _6432;\n        Surface _6515 = { _6434, _6435, _6436, _6437, _6438, _6439, _6440, _6441, _6442, _6443, _6444, _6445, _6446, _6447, _6448, _6449 };\n        Surface param_9 = _6515;\n        float3 param_10 = _5808;\n        float3 param_11 = _5761;\n        float param_12 = _5815;\n        float param_13 = _5819;\n        float3 param_14 = _5845;\n        FaLayers _5861 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _5808;\n        float3 lit = (fa_indirect_diffuse(param_15) * _5838) * _6439;\n        if (_5861.on)\n        {\n            lit *= _5861.base_scale;\n        }\n        int _5883 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5883; ln++)\n        {\n            int param_16 = ln;\n            int _5896 = fa_cl_light(param_16);\n            bool _5899 = fa_lm.z > 0.5f;\n            bool _5905;\n            if (_5899)\n            {\n                int param_17 = _5896;\n                _5905 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _5905 = _5899;\n            }\n            if (_5905)\n            {\n                continue;\n            }\n            int param_18 = _5896;\n            float3 param_19 = fa_world_pos;\n            float3 param_20 = _6403;\n            LightSample _5917 = fa_light_shadowed(param_18, param_19, param_20);\n            float _5925 = max(dot(_5808, _5917.direction), 0.0f);\n            float _5931 = _5917.attenuation * _5917.shadow;\n            float3 _5936 = normalize(_5917.direction + _5761);\n            float _5941 = max(dot(_5808, _5936), 0.0f);\n            float _5946 = max(dot(_5761, _5936), 0.0f);\n            bool _5953;\n            if (fa_light_is_area)\n            {\n                _5953 = !_5861.on;\n            }\n            else\n            {\n                _5953 = fa_light_is_area;\n            }\n            if (_5953)\n            {\n                int param_21 = _5896;\n                float3 param_22 = fa_world_pos;\n                float3 param_23 = _5808;\n                float3 param_24 = _5761;\n                float3 param_25 = _5838;\n                float3 param_26 = f0;\n                float param_27 = 1.0f;\n                float param_28 = _5819;\n                float param_29 = _5832;\n                float param_30 = _5931;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _5861;\n                    int param_32 = _5896;\n                    float3 param_33 = fa_world_pos;\n                    float3 param_34 = _5808;\n                    float3 param_35 = _5761;\n                    float3 param_36 = _5917.direction;\n                    float3 param_37 = _5838;\n                    float3 param_38 = f0;\n                    float param_39 = _5819;\n                    float param_40 = _5832;\n                    float param_41 = _5931;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_5861.on)\n                    {\n                        FaLayers param_42 = _5861;\n                        float3 param_43 = _5838;\n                        float3 param_44 = f0;\n                        float3 param_45 = _5808;\n                        float3 param_46 = _5761;\n                        float3 param_47 = _5917.direction;\n                        float3 param_48 = _5936;\n                        float param_49 = _5925;\n                        float param_50 = _5832;\n                        float param_51 = _5941;\n                        float param_52 = _5946;\n                        float param_53 = _5823;\n                        float param_54 = _5827;\n                        int param_55 = _5896;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _5931));\n                    }\n                    else\n                    {\n                        float _6059 = ((_5941 * _5941) * (_5827 - 1.0f)) + 1.0f;\n                        int param_56 = _5896;\n                        lit += (((_5838 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _5946, 5.0f))) * (((_5827 / ((3.1415927410125732421875f * _6059) * _6059)) * (0.5f / max(lerp((2.0f * _5925) * _5832, _5925 + _5832, _5823), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _5925))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_5925 * _5931));\n                    }\n                }\n            }\n        }\n        if (_5861.on)\n        {\n            FaLayers param_57 = _5861;\n            float3 param_58 = _5808;\n            float3 param_59 = _5761;\n            float3 param_60 = f0;\n            float param_61 = _5819;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _6439);\n        }\n        else\n        {\n            float3 param_62 = _5808;\n            float3 param_63 = _5761;\n            float3 param_64 = f0;\n            float param_65 = _5819;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _6439);\n        }\n        result = lit;\n    }\n    float3 _6154 = result;\n    float3 _6155 = _6154 + _6440;\n    result = _6155;\n    float3 param_66 = _6155;\n    float3 param_67 = fa_world_pos;\n    result = fa_shadow_debug(param_66, param_67);\n    bool _6164 = _491_fa_fog.w > 0.0f;\n    bool _6171;\n    if (!_6164)\n    {\n        _6171 = _491_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _6171 = _6164;\n    }\n    if (_6171)\n    {\n        float3 _6180 = fa_world_pos - _491_fa_camera_pos.xyz;\n        float _6186 = dot(_6180, _491_fa_fog_c.xyz);\n        bool _6190 = _491_fa_fog_c.w > 0.5f;\n        float _6191;\n        if (_6190)\n        {\n            _6191 = _6186;\n        }\n        else\n        {\n            _6191 = length(_6180);\n        }\n        float _6203 = _6191 - _491_fa_fog_b.x;\n        if (_6203 > 0.0f)\n        {\n            float _6212 = _491_fa_fog.w * _6203;\n            float tau = _6212 * _6212;\n            if (_491_fa_fog_b.y > 0.0f)\n            {\n                float _6228;\n                if (_6190)\n                {\n                    _6228 = fa_world_pos.y - (_491_fa_fog_c.y * _6186);\n                }\n                else\n                {\n                    _6228 = _491_fa_camera_pos.y;\n                }\n                float _6249 = lerp(_6228, fa_world_pos.y, clamp(_491_fa_fog_b.x / _6191, 0.0f, 1.0f));\n                float _6253 = fa_world_pos.y - _6249;\n                float _6258 = _6249 - _491_fa_fog_b.z;\n                float _6263 = fa_world_pos.y - _491_fa_fog_b.z;\n                bool _6266 = _6258 <= 0.0f;\n                bool _6267 = !_6266;\n                bool _6273;\n                if (_6267)\n                {\n                    _6273 = _491_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6273 = _6266;\n                }\n                float _6274;\n                if (_6273)\n                {\n                    _6274 = _491_fa_fog_b.y;\n                }\n                else\n                {\n                    _6274 = _491_fa_fog_b.y * exp(-min(_491_fa_fog_b.w * _6258, 80.0f));\n                }\n                bool _6301;\n                if (_6267)\n                {\n                    _6301 = _491_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6301 = _6266;\n                }\n                float _6302;\n                if (_6301)\n                {\n                    _6302 = _491_fa_fog_b.y * _6258;\n                }\n                else\n                {\n                    _6302 = (_491_fa_fog_b.y * (1.0f - exp(-min(_491_fa_fog_b.w * _6258, 80.0f)))) / _491_fa_fog_b.w;\n                }\n                bool _6327 = _6263 <= 0.0f;\n                bool _6334;\n                if (!_6327)\n                {\n                    _6334 = _491_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6334 = _6327;\n                }\n                float _6335;\n                if (_6334)\n                {\n                    _6335 = _491_fa_fog_b.y * _6263;\n                }\n                else\n                {\n                    _6335 = (_491_fa_fog_b.y * (1.0f - exp(-min(_491_fa_fog_b.w * _6263, 80.0f)))) / _491_fa_fog_b.w;\n                }\n                float _6362;\n                if (abs(_6253) < 0.001000000047497451305389404296875f)\n                {\n                    _6362 = _6274;\n                }\n                else\n                {\n                    _6362 = (_6335 - _6302) / _6253;\n                }\n                tau += (_6203 * max(_6362, 0.0f));\n            }\n            result = lerp(result, _491_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _6435);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_inst_v0 = stage_input.fa_inst_v0;\n    fa_inst_v1 = stage_input.fa_inst_v1;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_2208",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_5379",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _3502[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _491_fa_camera_pos : packoffset(c0);\n    float4 _491_fa_ambient : packoffset(c1);\n    float4 _491_fa_base_color : packoffset(c2);\n    float4 _491_fa_emissive : packoffset(c3);\n    float4 _491_fa_model_emissive : packoffset(c4);\n    float4 _491_fa_pbr : packoffset(c5);\n    float4 _491_fa_maps : packoffset(c6);\n    float4 _491_fa_fog : packoffset(c7);\n    float4 _491_fa_fog_b : packoffset(c8);\n    float4 _491_fa_fog_c : packoffset(c9);\n    float4 _491_fa_counts : packoffset(c10);\n    float4 _491_fa_env_sky : packoffset(c11);\n    float4 _491_fa_env_horizon : packoffset(c12);\n    float4 _491_fa_time : packoffset(c13);\n    float4 _491_fa_cl_vpx : packoffset(c14);\n    float4 _491_fa_cl_vpy : packoffset(c15);\n    float4 _491_fa_cl_vpw : packoffset(c16);\n    float4 _491_fa_cl_fwd : packoffset(c17);\n    float4 _491_fa_cl_grid : packoffset(c18);\n    float4 _491_fa_cl_info : packoffset(c19);\n    float4 _491_fa_layers_a : packoffset(c20);\n    float4 _491_fa_layers_b : packoffset(c21);\n    float4 _491_fa_layers_c : packoffset(c22);\n    float4 _491_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2208_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2208_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2208_fa_shadow_info[4] : packoffset(c20);\n    float4 _2208_fa_shadow_split : packoffset(c24);\n    float4 _2208_fa_shadow_cfg : packoffset(c25);\n    float4 _2208_fa_shadow_bias : packoffset(c26);\n    float4 _2208_fa_shadow_eye : packoffset(c27);\n    float4 _2208_fa_shadow_fwd : packoffset(c28);\n    float4 _2208_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _5379_boost : packoffset(c0);\n    float _5379_fa_pad0 : packoffset(c0.y);\n    float _5379_fa_pad1 : packoffset(c0.z);\n    float _5379_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t11);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t10);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float3 fa_lm : TEXCOORD7;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\nstatic float raise;\nstatic float4 tint;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1479 = _491_fa_cl_info.x < 0.0f;\n    bool _1486;\n    if (!_1479)\n    {\n        _1486 = _491_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1486 = _1479;\n    }\n    bool _1494;\n    if (!_1486)\n    {\n        _1494 = _491_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1494 = _1486;\n    }\n    bool _1501;\n    if (!_1494)\n    {\n        _1501 = _491_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1501 = _1494;\n    }\n    bool _1508;\n    if (!_1501)\n    {\n        _1508 = _491_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1508 = _1501;\n    }\n    if (_1508)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1518 = float4(world_pos, 1.0f);\n    float _1524 = dot(_491_fa_cl_vpw, _1518);\n    if (!(_1524 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1546 = float2(dot(_491_fa_cl_vpx, _1518), dot(_491_fa_cl_vpy, _1518)) / _1524.xx;\n    int _1550 = int(_491_fa_cl_grid.x);\n    int _1554 = int(_491_fa_cl_grid.y);\n    int param = (int(_491_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_491_fa_cl_fwd.xyz, world_pos) + _491_fa_cl_fwd.w, _491_fa_cl_grid.w) / _491_fa_cl_grid.w) * _491_fa_cl_grid.z)), 0, int(_491_fa_cl_info.y) - 1) * _1554) + clamp(int(floor(((_1546.y * 0.5f) + 0.5f) * _491_fa_cl_grid.y)), 0, _1554 - 1)) * _1550)) + clamp(int(floor(((_1546.x * 0.5f) + 0.5f) * _491_fa_cl_grid.x)), 0, _1550 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1630 = fa_cluster_texel(param);\n    return int2(int(_1630.x), int(_1630.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_491_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4323 = fa_cluster_lookup(param);\n    fa_cl_slot = _4323.x;\n    fa_cl_local = _4323.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _5431 = fa_linear_to_srgb(param);\n        c = _5431;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _5439 = fa_srgb_to_linear(param_1);\n            c = _5439;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _423;\n    if (i.front_facing)\n    {\n        _423 = i.world_normal;\n    }\n    else\n    {\n        _423 = -i.world_normal;\n    }\n    float3 _447 = normalize(i.world_tangent.xyz - (_423 * dot(_423, i.world_tangent.xyz)));\n    float3 _475 = normalize(((_447 * m.x) + ((cross(_423, _447) * i.world_tangent.w) * m.y)) + (_423 * m.z));\n    float3 _478;\n    if (i.front_facing)\n    {\n        _478 = _475;\n    }\n    else\n    {\n        _478 = -_475;\n    }\n    return _478;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _491_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _5470 = fa_tex_fix(param_2, param_3);\n    float4 _6885 = base_t;\n    _6885.x = _5470.x;\n    _6885.y = _5470.y;\n    _6885.z = _5470.z;\n    base_t = _6885;\n    float4 _5484 = (_6885 * _491_fa_base_color) * i.vertex_color;\n    float3 _6723 = i.world_normal;\n    if (_491_fa_maps.z > 0.5f)\n    {\n        float param_4 = _491_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _5516 = fa_tex_fix(param_6, param_7);\n        float3 _5519 = (_5516 * 2.0f) - 1.0f.xxx;\n        float2 _5524 = _5519.xy * _491_fa_maps.x;\n        float3 _6893 = _5519;\n        _6893.x = _5524.x;\n        _6893.y = _5524.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _6893;\n        _6723 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _491_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _5552 = fa_tex_fix(param_12, param_13);\n    float4 _6896 = mrt;\n    _6896.x = _5552.x;\n    _6896.y = _5552.y;\n    _6896.z = _5552.z;\n    mrt = _6896;\n    float4 _5580 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _491_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _5580.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _5591 = fa_tex_fix(param_16, param_17);\n    float param_18 = _491_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _5621 = fa_tex_fix(param_20, param_21);\n    float _6728 = _491_fa_layers_a.x;\n    float _6729 = _491_fa_layers_a.y;\n    float _6732 = _491_fa_layers_a.z;\n    float _6731 = _491_fa_layers_b.w;\n    float _6734 = _491_fa_layers_c.x;\n    if (_491_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_491_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _6728 *= _5591.y;\n            _6729 *= _5591.z;\n            _6731 *= _5580.w;\n        }\n        if (_491_fa_layers_c.z > 1.5f)\n        {\n            _6732 *= mrt.x;\n            _6734 *= mrt.w;\n        }\n    }\n    Surface _6753 = { _5484.xyz, _5484.w, _6723, clamp(_491_fa_pbr.x * _5552.z, 0.0f, 1.0f), clamp(_491_fa_pbr.y * _5552.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_491_fa_maps.y * (_5591.x - 1.0f)), _491_fa_emissive.xyz + (_491_fa_model_emissive.xyz * _5621), _6728, _6729, _491_fa_layers_b.xyz, _6731, _6732, _491_fa_layers_a.w, _6734, _491_fa_layers_c.y, _491_fa_layers_d.xyz };\n    return _6753;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * _5379_boost);\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1710 = rect.zw - rect.xy;\n    float2 _1714 = _1710 * atlas;\n    float2 _1718 = ddx * _1714;\n    float2 _1722 = ddy * _1714;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1710), clamp(0.5f * log2(max(max(dot(_1718, _1718), dot(_1722, _1722)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1755 = _491_fa_counts.y < 0.5f;\n    bool _1762;\n    if (!_1755)\n    {\n        _1762 = _491_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1762 = _1755;\n    }\n    if (_1762)\n    {\n        return;\n    }\n    float3 _1768 = ddx(world_pos);\n    float3 _1771 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1775 = fa_cluster_texel(param);\n    int _1779 = int(_1775.w);\n    if (_1779 < 1)\n    {\n        return;\n    }\n    int _1789 = int(_491_fa_counts.y + 0.5f);\n    int param_1 = _1789;\n    float4 _1793 = fa_light_texel(param_1);\n    float2 _1796 = _1793.yz;\n    int _1800 = int(_1793.w);\n    int param_2 = _1789 + 1;\n    float4 _1805 = fa_light_texel(param_2);\n    float _1806 = _1805.x;\n    int _1812 = int(_491_fa_counts.w + 0.5f) - 1;\n    int _1816 = int(_1775.z);\n    float3 _2081;\n    for (int k = 0; k < _1779; k++)\n    {\n        int _1829 = _1816 + k;\n        int param_3 = _1800 + (_1829 >> 2);\n        int _1846 = (_1789 + 2) + (int(fa_light_texel(param_3)[_1829 & 3]) * 7);\n        int param_4 = _1846 + 6;\n        float4 _1851 = fa_light_texel(param_4);\n        if (((int(_1851.w + 0.5f) >> _1812) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1846;\n        float4 _1866 = fa_light_texel(param_5);\n        int param_6 = _1846 + 1;\n        float4 _1871 = fa_light_texel(param_6);\n        int param_7 = _1846 + 2;\n        float4 _1876 = fa_light_texel(param_7);\n        float3 _1879 = _1866.xyz;\n        float _1884 = dot(_1879, world_pos) + _1866.w;\n        float3 _1886 = _1871.xyz;\n        float _1891 = dot(_1886, world_pos) + _1871.w;\n        float3 _1893 = _1876.xyz;\n        float _1898 = dot(_1893, world_pos) + _1876.w;\n        bool _1903 = abs(_1884) > 0.5f;\n        bool _1911;\n        if (!_1903)\n        {\n            _1911 = abs(_1891) > 0.5f;\n        }\n        else\n        {\n            _1911 = _1903;\n        }\n        bool _1919;\n        if (!_1911)\n        {\n            _1919 = abs(_1898) > 0.5f;\n        }\n        else\n        {\n            _1919 = _1911;\n        }\n        if (_1919)\n        {\n            continue;\n        }\n        float _1934 = clamp(dot(geo_normal, normalize(_1893)) * _1851.z, 0.0f, 1.0f);\n        if (_1934 <= 0.0f)\n        {\n            continue;\n        }\n        float _1954 = (clamp((0.5f - abs(_1898)) * 10.0f, 0.0f, 1.0f) * _1934) * _1851.x;\n        float2 _1962 = float2(_1884 + 0.5f, 0.5f - _1891);\n        float2 _1972 = float2(dot(_1879, _1768), dot(_1886, _1768));\n        float2 _1982 = float2(dot(_1879, _1771), dot(_1886, _1771));\n        int param_8 = _1846 + 5;\n        float4 _1987 = fa_light_texel(param_8);\n        int param_9 = _1846 + 3;\n        float4 _1992 = fa_light_texel(param_9);\n        int param_10 = _1846 + 4;\n        float4 _1997 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1987.xyz;\n        bool _2007 = _1992.z > _1992.x;\n        if (_2007)\n        {\n            float4 param_11 = _1992;\n            float2 param_12 = _1962;\n            float2 param_13 = _1796;\n            float2 param_14 = _1972;\n            float2 param_15 = _1982;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1806 > 0.5f) && (_1806 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _2033 = fa_dc_to_linear(param_16);\n                float4 _6803 = tx;\n                _6803.x = _2033.x;\n                _6803.y = _2033.y;\n                _6803.z = _2033.z;\n                tx = _6803;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1954 * tex_a) * _1987.w, 0.0f, 1.0f).xxx);\n        if (_1997.z > _1997.x)\n        {\n            float4 param_17 = _1997;\n            float2 param_18 = _1962;\n            float2 param_19 = _1796;\n            float2 param_20 = _1972;\n            float2 param_21 = _1982;\n            float4 _2077 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1806 > 1.5f)\n            {\n                float3 param_22 = _2077.xyz;\n                float3 _2087 = fa_dc_to_srgb(param_22);\n                _2081 = _2087;\n            }\n            else\n            {\n                _2081 = _2077.xyz;\n            }\n            float3 _2096 = (_2081 * 2.0f) - 1.0f.xxx;\n            float2 _2101 = _2096.xy * _1851.y;\n            float3 _2123 = (normalize(_1879) * _2101.x) + (normalize(_1886) * _2101.y);\n            float3 _2126 = normalize(normal);\n            normal = normalize(lerp(_2126, normalize((_2126 * max(_2096.z, 0.0500000007450580596923828125f)) + (_2123 - (_2126 * dot(_2126, _2123)))), clamp(_1954 * (_2007 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3427 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3435 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3438 = int(_3427);\n    int _3441 = int(_3435);\n    float _3451 = _3435 - float(_3441);\n    int _3507 = (_3438 * 9) + _3441;\n    int _3527 = ((_3438 + 1) * 9) + _3441;\n    return lerp(lerp(_3502[_3507], _3502[_3507 + 1], _3451), lerp(_3502[_3527], _3502[_3527 + 1], _3451), _3427 - float(_3438));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _6646 = false;\n    float _6647 = 1.0f;\n    float _6648 = 1.0f;\n    float _6649 = 1.0f;\n    float _6650 = 0.0f;\n    float _6651 = 0.0f;\n    float _6652 = 0.0f;\n    float _6653 = 0.0f;\n    float _6655 = 1.0f;\n    bool _6656 = false;\n    float3 _6657 = 0.0f.xxx;\n    float _6658 = 1.0f;\n    float _6659 = 1.0f;\n    float _6660 = 1.0f;\n    float _6661 = 0.0f;\n    float _6662 = 0.0f;\n    float3 _6663 = float3(1.0f, 0.0f, 0.0f);\n    float3 _6664 = float3(0.0f, 0.0f, 1.0f);\n    float _6665 = 1.0f;\n    float _6666 = 1.0f;\n    float _3578 = clamp(s.specular, 0.0f, 1.0f);\n    float _3582 = clamp(s.ior, 1.0f, 3.0f);\n    bool _3587 = (_3578 != 1.0f) || (_3582 != 1.5f);\n    bool _3596;\n    if (!_3587)\n    {\n        _3596 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _3596 = _3587;\n    }\n    if (_3596)\n    {\n        float _3604 = (_3582 - 1.0f) / (_3582 + 1.0f);\n        f0 = lerp(min((_3604 * _3604).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _3578, s.albedo, metallic.xxx);\n        _6647 = lerp(_3578, 1.0f, metallic);\n        _6646 = true;\n    }\n    float _3631 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_3631 > 0.0f)\n    {\n        float _3639 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _6650 = _3631;\n        _6651 = _3639;\n        float _3646 = _3639 * _3639;\n        _6652 = _3646;\n        _6653 = _3646 * _3646;\n        float _3658 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _6655 = _3658;\n        _6648 = 1.0f - (_3631 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _3658, 0.0f, 1.0f), 5.0f))));\n        _6646 = true;\n    }\n    float3 _3678 = max(s.sheen_color, 0.0f.xxx);\n    float _3687 = max(_3678.x, max(_3678.y, _3678.z));\n    if (_3687 > 0.0f)\n    {\n        float _3695 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _6656 = true;\n        _6657 = _3678;\n        _6658 = _3695;\n        _6659 = _3695 * _3695;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _3695;\n        float _3712 = fa_sheen_albedo(param, param_1);\n        _6661 = _3712;\n        _6660 = 1.0f - min(_3687 * _3712, 1.0f);\n        _6646 = true;\n    }\n    _6649 = _6648 * _6660;\n    float _3731 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_3731 != 0.0f)\n    {\n        float3 _3746 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _3746;\n        if (dot(_3746, _3746) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _3758 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_3758.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _3758.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _3758.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _3762 = t;\n        float3 _3763 = normalize(_3762);\n        t = _3763;\n        float3 _3788 = normalize((_3763 * cos(s.anisotropy_rotation)) + ((cross(n, _3763) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _6663 = _3788;\n        _6664 = cross(n, _3788);\n        float _3798 = roughness * roughness;\n        float _3804 = lerp(_3798, 1.0f, _3731 * _3731);\n        bool _3806 = _3731 > 0.0f;\n        _6665 = _3806 ? _3804 : _3798;\n        _6666 = _3806 ? _3798 : _3804;\n        _6662 = _3731;\n        _6646 = true;\n    }\n    FaLayers _6688 = { _6646, _6647, _6648, _6649, _6650, _6651, _6652, _6653, i.world_normal, _6655, _6656, _6657, _6658, _6659, _6660, _6661, _6662, _6663, _6664, _6665, _6666 };\n    return _6688;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_491_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _491_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_491_fa_cl_info.x) + int(_491_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_491_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _562_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _562_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _728 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _741 = (c - (ru * hx)) - p;\n        float3 _747 = ru * (2.0f * hx);\n        float _753 = max(dot(_747, _747), 9.9999999392252902907785028219223e-09f);\n        float _757 = dot(_741, _747);\n        float t = clamp((-_757) / _753, 0.0f, 1.0f);\n        if (_728)\n        {\n            float _772 = dot(r, _747);\n            float _778 = _753 - (_772 * _772);\n            if (abs(_778) > (9.9999997473787516355514526367188e-06f * _753))\n            {\n                t = clamp(((dot(r, _741) * _772) - _757) / _778, 0.0f, 1.0f);\n            }\n        }\n        return (p + _741) + (_747 * t);\n    }\n    float3 q = p;\n    float _810 = dot(r, axis);\n    bool _818;\n    if (_728)\n    {\n        _818 = abs(_810) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _818 = _728;\n    }\n    if (_818)\n    {\n        float _828 = dot(c - p, axis) / _810;\n        if (_828 > 0.0f)\n        {\n            q = p + (r * _828);\n        }\n    }\n    float3 _841 = q - c;\n    float2 xy = float2(dot(_841, ru), dot(_841, uu));\n    if (shape > 0.5f)\n    {\n        float _856 = length(xy);\n        if (_856 > hx)\n        {\n            xy *= (hx / _856);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _649 = abs(d);\n    float _651 = _649.x;\n    float _653 = _649.y;\n    bool _654 = _651 >= _653;\n    bool _662;\n    if (_654)\n    {\n        _662 = _651 >= _649.z;\n    }\n    else\n    {\n        _662 = _654;\n    }\n    int _663;\n    if (_662)\n    {\n        _663 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _676;\n        if (_653 >= _649.z)\n        {\n            _676 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _676 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _663 = _676;\n    }\n    return _663;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _602 = dot(d, right);\n    float _606 = dot(d, up);\n    float _617;\n    if (((_602 * _602) + (_606 * _606)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _617 = atan2(_606, _602) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _617 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_617 - floor(_617)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _894 = fa_light_base(param);\n    bool _898 = _491_fa_ambient.w > 4.5f;\n    int param_1 = _894;\n    float4 _902 = fa_light_texel(param_1);\n    int param_2 = _894 + 1;\n    float4 _907 = fa_light_texel(param_2);\n    float _910 = _907.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _922 = _898 && (_910 > 2.5f);\n    fa_light_is_area = _922;\n    bool _924 = _910 < 0.5f;\n    float3 l;\n    if (_924)\n    {\n        l = normalize(_902.xyz);\n        if (_898)\n        {\n            int param_3 = _894 + 6;\n            float4 _938 = fa_light_texel(param_3);\n            if (_938.z > 0.5f)\n            {\n                int param_4 = _894 + 4;\n                float4 _948 = fa_light_texel(param_4);\n                int param_5 = _894 + 5;\n                float4 _953 = fa_light_texel(param_5);\n                float2 param_6 = _938.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _948.xyz) * _948.w, (-dot(world_pos, _953.xyz)) * _953.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _983 = _902.xyz;\n        float3 _985 = _983 - world_pos;\n        float3 to_light = _985;\n        float _988 = length(_985);\n        float reach = _988;\n        bool front = true;\n        if (_922)\n        {\n            int param_8 = _894 + 7;\n            reach = max(_988 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _894 + 4;\n            float4 _1012 = fa_light_texel(param_9);\n            int param_10 = _894 + 5;\n            float4 _1017 = fa_light_texel(param_10);\n            int param_11 = _894 + 6;\n            float4 _1022 = fa_light_texel(param_11);\n            float _1023 = _1022.w;\n            int param_12 = _894 + 2;\n            float3 _1030 = normalize(fa_light_texel(param_12).xyz);\n            bool _1032 = _1023 > 1.5f;\n            bool _1040;\n            if (!_1032)\n            {\n                _1040 = dot(_1030, to_light) < 0.0f;\n            }\n            else\n            {\n                _1040 = _1032;\n            }\n            front = _1040;\n            float3 r = 0.0f.xxx;\n            float3 _1049 = _491_fa_camera_pos.xyz - world_pos;\n            bool _1053 = dot(n, n) > 0.5f;\n            bool _1061;\n            if (_1053)\n            {\n                _1061 = dot(_1049, _1049) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _1061 = _1053;\n            }\n            if (_1061)\n            {\n                r = reflect(-normalize(_1049), normalize(n));\n            }\n            float3 param_13 = _983;\n            float3 param_14 = _1030;\n            float3 param_15 = _1012.xyz;\n            float3 param_16 = _1017.xyz;\n            float param_17 = _1012.w;\n            float param_18 = _1017.w;\n            float param_19 = _1023;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1097 = length(to_light);\n        dist = _1097;\n        l = to_light / max(_1097, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1111 = reach / max(_902.w, 0.001000000047497451305389404296875f);\n        float _1117 = clamp(1.0f - (_1111 * _1111), 0.0f, 1.0f);\n        float _1119;\n        if (front)\n        {\n            _1119 = _1117 * _1117;\n        }\n        else\n        {\n            _1119 = 0.0f;\n        }\n        atten = _1119;\n        bool _1130 = _910 < 2.5f;\n        if ((_910 > 1.5f) && _1130)\n        {\n            int param_22 = _894 + 2;\n            float4 _1138 = fa_light_texel(param_22);\n            float _1148 = _1138.w;\n            int param_23 = _894 + 3;\n            float4 _1153 = fa_light_texel(param_23);\n            float _1154 = _1153.x;\n            float cos_inner = _1154;\n            if (_1154 > 1.5f)\n            {\n                cos_inner = lerp(_1148, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1148, cos_inner, dot(-l, normalize(_1138.xyz)));\n        }\n        if (_898 && (_910 < 1.5f))\n        {\n            int param_24 = _894 + 6;\n            float4 _1178 = fa_light_texel(param_24);\n            if (_1178.z > 0.5f)\n            {\n                float3 _1186 = -to_light;\n                int param_25 = _894 + 4;\n                int param_26 = _894 + 5;\n                float3 _1200 = fa_light_texel(param_25).xyz;\n                float3 _1204 = fa_light_texel(param_26).xyz;\n                float3 _1213 = float3(dot(_1186, _1200), dot(_1186, _1204), dot(_1186, cross(_1200, _1204)));\n                float3 param_27 = _1213;\n                int _1217 = fa_cube_face(param_27);\n                int param_28 = _1217;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1244 = float2(dot(_1213, cross(param_29, param_30)), dot(_1213, param_30)) / max(dot(_1213, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1248 = _1217 / 3;\n                float2 param_31 = _1178.xy + (float2(float(_1217 - (_1248 * 3)), float(_1248)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1244.x), 0.5f - (0.5f * _1244.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _894 + 7;\n            float4 _1278 = fa_light_texel(param_33);\n            if (_1278.z > 0.5f)\n            {\n                int param_34 = _894 + 2;\n                int param_35 = _894 + 4;\n                int param_36 = _894 + 5;\n                float2 param_37 = _1278.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_898 && _1130)\n            {\n                int param_42 = _894 + 6;\n                float4 _1325 = fa_light_texel(param_42);\n                int param_43 = _894 + 7;\n                float4 _1330 = fa_light_texel(param_43);\n                bool _1333 = _1325.z > 0.5f;\n                bool _1340;\n                if (!_1333)\n                {\n                    _1340 = _1330.z > 0.5f;\n                }\n                else\n                {\n                    _1340 = _1333;\n                }\n                if (_1340)\n                {\n                    int param_44 = _894 + 2;\n                    float4 _1347 = fa_light_texel(param_44);\n                    float3 _1351 = normalize(_1347.xyz);\n                    int param_45 = _894 + 4;\n                    float4 _1356 = fa_light_texel(param_45);\n                    int param_46 = _894 + 5;\n                    float4 _1361 = fa_light_texel(param_46);\n                    if (_1333)\n                    {\n                        float3 _1369 = -to_light;\n                        float _1376 = _1347.w;\n                        float _1392 = 0.5f / max(dot(_1369, _1351) * (sqrt(max(1.0f - (_1376 * _1376), 0.0f)) / max(_1376, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1325.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1369, _1356.xyz) * _1392), 0.5f - (dot(_1369, _1361.xyz) * _1392));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1330.z > 0.5f)\n                    {\n                        float2 param_49 = _1330.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1351;\n                        float3 param_52 = _1356.xyz;\n                        float3 param_53 = _1361.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _6634 = _907.xyz * atten;\n    if (_898)\n    {\n        _6634 *= fa_light_tint;\n    }\n    int _1461;\n    if (_924)\n    {\n        _1461 = 0;\n    }\n    else\n    {\n        _1461 = ((_910 > 1.5f) && (_910 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _6645 = { l, _6634, atten, 1.0f, dist, _1461 };\n    return _6645;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2198;\n    if (i == 0)\n    {\n        _2198 = _2208_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2214;\n        if (i == 1)\n        {\n            _2214 = _2208_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2222;\n            if (i == 2)\n            {\n                _2222 = _2208_fa_shadow_split.z;\n            }\n            else\n            {\n                _2222 = _2208_fa_shadow_split.w;\n            }\n            _2214 = _2222;\n        }\n        _2198 = _2214;\n    }\n    return _2198;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2255 = fa_shadow_depth(param, param_1);\n    float _2259;\n    if (conv.x < 0.5f)\n    {\n        _2259 = _2255;\n    }\n    else\n    {\n        _2259 = (conv.y * conv.z) / (conv.z - (_2255 * (conv.z - conv.y)));\n    }\n    return _2259;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2186 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2186), sin(_2186)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2305 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2314;\n        if (k < 0.0f)\n        {\n            _2314 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2314 = k;\n        }\n        float _2334 = clamp((_2314 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2305;\n            float2 _2353 = fa_shadow_vogel(param_3, param_4, param_5) * _2334;\n            float2 param_6 = uv + (_2353 * _2208_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2365 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2365 < (zr - (length(_2353) * plane)))\n            {\n                sum += _2365;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2391 = sum / cnt;\n        float _2401;\n        if (k < 0.0f)\n        {\n            _2401 = (-k) / max(_2391, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2401 = k;\n        }\n        radius = clamp(((max(zr - _2391, 0.0f) * unit) * _2401) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2423 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2423; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2423;\n        float param_11 = _2305;\n        float2 _2442 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2442 * _2208_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2442) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2423);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2484 = max(_2208_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2489 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2495 = sqrt(1.0f - (_2489 * _2489));\n    float _2502 = min(_2495 / max(_2489, 0.20000000298023223876953125f), 4.0f);\n    float _2507;\n    if (_2208_fa_shadow_bias.y > 0.0f)\n    {\n        _2507 = _2208_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2507 = 1.5f * _2208_fa_shadow_info[ci].x;\n    }\n    float4 _2532 = mul(float4(world + (n * (_2507 * _2495)), 1.0f), _2208_fa_shadow_mat[ci]);\n    float _2539 = _2532.x;\n    bool _2542 = _2539 < _2208_fa_shadow_rect[ci].x;\n    bool _2551;\n    if (!_2542)\n    {\n        _2551 = _2539 > _2208_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2551 = _2542;\n    }\n    bool _2560;\n    if (!_2551)\n    {\n        _2560 = _2532.y < _2208_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2560 = _2551;\n    }\n    bool _2569;\n    if (!_2560)\n    {\n        _2569 = _2532.y > _2208_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2569 = _2560;\n    }\n    bool _2576;\n    if (!_2569)\n    {\n        _2576 = _2532.z > 1.0f;\n    }\n    else\n    {\n        _2576 = _2569;\n    }\n    if (_2576)\n    {\n        return -1.0f;\n    }\n    float _2584;\n    if (_2208_fa_shadow_bias.x > 0.0f)\n    {\n        _2584 = _2208_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2584 = 1.5f * _2208_fa_shadow_info[ci].x;\n    }\n    float2 param = _2532.xy;\n    float4 param_1 = _2208_fa_shadow_rect[ci];\n    float param_2 = _2532.z - ((_2584 * (1.0f + (0.5f * _2502))) / _2484);\n    float param_3 = _2208_fa_shadow_info[ci].x;\n    float param_4 = _2484;\n    float param_5 = _2484 * 0.25f;\n    float param_6 = ((_2208_fa_shadow_info[ci].x * min(_2502, 3.0f)) * 0.5f) / _2484;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2208_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2208_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_491_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2972 = int(_2208_fa_shadow_cfg.x + 0.5f);\n    if (_2972 < 1)\n    {\n        return 1.0f;\n    }\n    float _2987 = dot(world - _2208_fa_shadow_eye.xyz, _2208_fa_shadow_fwd.xyz);\n    int param = _2972 - 1;\n    if (_2987 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2999 = _2972 > 1;\n    bool _3006;\n    if (_2999)\n    {\n        _3006 = _2987 > _2208_fa_shadow_split.x;\n    }\n    else\n    {\n        _3006 = _2999;\n    }\n    if (_3006)\n    {\n        ci = 1;\n    }\n    bool _3010 = _2972 > 2;\n    bool _3017;\n    if (_3010)\n    {\n        _3017 = _2987 > _2208_fa_shadow_split.y;\n    }\n    else\n    {\n        _3017 = _3010;\n    }\n    if (_3017)\n    {\n        ci = 2;\n    }\n    bool _3021 = _2972 > 3;\n    bool _3028;\n    if (_3021)\n    {\n        _3028 = _2987 > _2208_fa_shadow_split.z;\n    }\n    else\n    {\n        _3028 = _3021;\n    }\n    if (_3028)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2972)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _3054 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3054;\n        if (_3054 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2208_fa_shadow_cfg.y > 0.0f)\n    {\n        float _3079;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3079 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3079 = _2208_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _3098 = _2208_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3079, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _3109 = clamp((_2987 - (fa_shadow_split_at(param_7) - _3098)) / _3098, 0.0f, 1.0f);\n        if (_3109 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2972)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _3130 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3130;\n                if (_3130 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _3109);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _2642 = _491_fa_pbr.z < 0.5f;\n    bool _2649;\n    if (!_2642)\n    {\n        _2649 = _2208_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2649 = _2642;\n    }\n    if (_2649)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2208_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2662 = fa_light_texel(param);\n    float _2663 = _2662.x;\n    if (_2663 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2672 = int(_2663 + 0.5f);\n    int param_1 = _2672;\n    float4 _2676 = fa_light_texel(param_1);\n    int param_2 = _2672 + 1;\n    float4 _2681 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2684 = _2676.y;\n    if (_2684 > 0.0f)\n    {\n        float _2701 = 1.0f - smoothstep(0.75f * _2684, _2684, length(world - _2208_fa_shadow_eye.xyz));\n        fade = _2701;\n        if (_2701 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2676.x > 1.5f)\n    {\n        int param_3 = li;\n        int param_4 = fa_light_base(param_3);\n        float3 param_5 = world - fa_light_texel(param_4).xyz;\n        face = fa_cube_face(param_5);\n    }\n    int _2730 = (_2672 + 2) + (face * 6);\n    int param_6 = _2730;\n    int param_7 = _2730 + 1;\n    int param_8 = _2730 + 3;\n    float4 _2744 = fa_light_texel(param_8);\n    int param_9 = _2730 + 4;\n    float4 _2749 = fa_light_texel(param_9);\n    int param_10 = _2730 + 5;\n    float4 _2754 = fa_light_texel(param_10);\n    float _2766 = _2754.x * max(dot(_2744, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2771 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2794 = clamp(dot(n, _2744.xyz), -1.0f, 1.0f);\n    int param_11 = li;\n    int param_12 = fa_light_base(param_11);\n    float _2818 = min(sqrt(1.0f - (_2794 * _2794)) / max(abs(dot(n, world - fa_light_texel(param_12).xyz)) / max(dot(_2744, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2821 = _2681.y;\n    float _2823;\n    if (_2821 > 0.0f)\n    {\n        _2823 = _2821;\n    }\n    else\n    {\n        _2823 = 1.5f * _2766;\n    }\n    float4 _2843 = float4(world + (n * (_2823 * sqrt(1.0f - (_2771 * _2771)))), 1.0f);\n    float _2847 = dot(_2744, _2843);\n    float _2850 = _2754.y;\n    if (_2847 < _2850)\n    {\n        return 1.0f;\n    }\n    float2 _2865 = float2(dot(fa_light_texel(param_6), _2843), dot(fa_light_texel(param_7), _2843)) / _2847.xx;\n    float _2867 = _2865.x;\n    bool _2870 = _2867 < _2749.x;\n    bool _2879;\n    if (!_2870)\n    {\n        _2879 = _2867 > _2749.z;\n    }\n    else\n    {\n        _2879 = _2870;\n    }\n    bool _2888;\n    if (!_2879)\n    {\n        _2888 = _2865.y < _2749.y;\n    }\n    else\n    {\n        _2888 = _2879;\n    }\n    bool _2897;\n    if (!_2888)\n    {\n        _2897 = _2865.y > _2749.w;\n    }\n    else\n    {\n        _2897 = _2888;\n    }\n    if (_2897)\n    {\n        return 1.0f;\n    }\n    float _2903 = _2681.x;\n    float _2905;\n    if (_2903 > 0.0f)\n    {\n        _2905 = _2903;\n    }\n    else\n    {\n        _2905 = 1.5f * _2766;\n    }\n    float2 param_13 = _2865;\n    float4 param_14 = _2749;\n    float param_15 = _2847 - (_2905 * (1.0f + (0.5f * _2818)));\n    float param_16 = _2766;\n    float param_17 = 1.0f;\n    float param_18 = _2754.z * 0.25f;\n    float param_19 = (_2766 * min(_2818, 3.0f)) * 0.5f;\n    float3 param_20 = float3(1.0f, _2850, _2754.z);\n    int param_21 = int(_2676.z + 0.5f);\n    float param_22 = _2676.w;\n    return lerp(1.0f, fa_shadow_filter(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _4350 = fa_lm.z > 0.5f;\n    bool _4356;\n    if (_4350)\n    {\n        int param = li;\n        _4356 = fa_light_baked(param);\n    }\n    else\n    {\n        _4356 = _4350;\n    }\n    if (_4356)\n    {\n        int param_1 = li;\n        LightSample _6701 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _6701;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4380 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _6703 = _4380.color;\n    float _6705 = _4380.shadow;\n    if ((_4380.type == 0) && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4380.direction;\n        float _4394 = fa_shadow_factor(param_5, param_6);\n        _6705 = _4394;\n        _6703 *= _4394;\n    }\n    else\n    {\n        bool _4405 = _4380.type != 0;\n        bool _4411;\n        if (_4405)\n        {\n            _4411 = _4380.attenuation > 0.0f;\n        }\n        else\n        {\n            _4411 = _4405;\n        }\n        if (_4411)\n        {\n            int param_7 = li;\n            float3 param_8 = world_pos;\n            float3 param_9 = gn;\n            float3 param_10 = _4380.direction;\n            float _4423 = fa_shadow_local(param_7, param_8, param_9, param_10);\n            _6705 = _4423;\n            _6703 *= _4423;\n        }\n    }\n    LightSample _6720 = { _4380.direction, _6703, _4380.attenuation, _6705, _4380._distance, _4380.type };\n    return _6720;\n}\n\nfloat3 fa_ltc_tangent(float3 n, float3 v)\n{\n    float3 _4463 = v - (n * dot(v, n));\n    float3 t = _4463;\n    float _4467 = dot(_4463, _4463);\n    float l2 = _4467;\n    if (_4467 < 1.0000000133514319600180897396058e-10f)\n    {\n        float3 _4477;\n        if (abs(n.z) < 0.999000012874603271484375f)\n        {\n            _4477 = cross(n, float3(0.0f, 0.0f, 1.0f));\n        }\n        else\n        {\n            _4477 = cross(n, float3(1.0f, 0.0f, 0.0f));\n        }\n        t = _4477;\n        l2 = dot(_4477, _4477);\n    }\n    return t * rsqrt(l2);\n}\n\nfloat3 fa_ltc_local(float3 t1, float3 n, float3 p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nfloat3 fa_ltc_edge_vector(float3 a, float3 b)\n{\n    float _4512 = dot(a, a);\n    float _4516 = dot(b, b);\n    if ((_4512 < 1.0000000195414813782625560981111e-24f) || (_4516 < 1.0000000195414813782625560981111e-24f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _4530 = a * rsqrt(_4512);\n    float3 _4535 = b * rsqrt(_4516);\n    float _4539 = dot(_4530, _4535);\n    float _4542 = abs(_4539);\n    float g = (((((((((((0.0416471660137176513671875f * _4542) - 0.1924748718738555908203125f) * _4542) + 0.4179156124591827392578125f) * _4542) - 0.616057217121124267578125f) * _4542) + 0.777722418308258056640625f) * _4542) - 0.999542415142059326171875f) * _4542) + 1.570791721343994140625f;\n    if (_4539 < 0.0f)\n    {\n        g = (3.1415927410125732421875f * rsqrt(max(1.0f - (_4539 * _4539), 1.0000000116860974230803549289703e-07f))) - g;\n    }\n    return cross(_4530, _4535) * g;\n}\n\nvoid fa_ltc_clip_edge(float3 a, float3 b, inout float3 sum, inout float3 leave, inout float3 enter, inout float2 seen)\n{\n    bool _4599 = a.z > 0.0f;\n    bool _4603 = b.z > 0.0f;\n    if (_4599 && _4603)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_4599 != _4603)\n        {\n            float3 _4638 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _4638.z = 0.0f;\n            if (_4599)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _4638;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _4638;\n                seen.x = 1.0f;\n            }\n            else\n            {\n                float3 param_4 = _4638;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _4638;\n                seen.y = 1.0f;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(float4 abcd, float3 p0, float3 p1, float3 p2, float3 p3)\n{\n    float3 _4687 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _4713 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _4739 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _4765 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = 0.0f.xxx;\n    float3 leave = 0.0f.xxx;\n    float3 enter = 0.0f.xxx;\n    float3 param = _4687;\n    float3 param_1 = _4713;\n    float3 param_2 = 0.0f.xxx;\n    float3 param_3 = 0.0f.xxx;\n    float3 param_4 = 0.0f.xxx;\n    float2 param_5 = 0.0f.xx;\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _4713;\n    float3 param_7 = _4739;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _4739;\n    float3 param_13 = _4765;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _4765;\n    float3 param_19 = _4687;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5f)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875f;\n}\n\nfloat fa_ltc_rect(float4 abcd, float3 center, float3 ex, float3 ey)\n{\n    float4 param = abcd;\n    float3 param_1 = (center - ex) - ey;\n    float3 param_2 = (center + ex) - ey;\n    float3 param_3 = (center + ex) + ey;\n    float3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(float4 m, float shape, float3 pc, float3 ex, float3 ey)\n{\n    if ((shape < 0.5f) || (shape > 1.5f))\n    {\n        float4 param = m;\n        float3 param_1 = pc;\n        float3 param_2 = ex;\n        float3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    float3 _4915 = (pc + (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _4939 = (pc - (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _4955 = (pc - (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float4 param_4 = m;\n    float3 param_5 = _4915;\n    float3 param_6 = (pc + (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_7 = (pc - (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_8 = _4939;\n    float4 param_9 = m;\n    float3 param_10 = _4915;\n    float3 param_11 = _4939;\n    float3 param_12 = (pc - (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    float3 param_13 = _4955;\n    float4 param_14 = m;\n    float3 param_15 = _4915;\n    float3 param_16 = _4955;\n    float3 param_17 = (pc + (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float3 param_18 = (pc + (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nfloat2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((float2(clamp((roughness - 0.0500000007450580596923828125f) * 1.0526316165924072265625f, 0.0f, 1.0f), sqrt(clamp(1.0f - ndv, 0.0f, 1.0f))) * 63.0f) + 0.5f.xx) * 0.015625f.xx;\n}\n\nfloat3 fa_area_shade(int li, float3 world_pos, float3 n, float3 v, float3 diffuse_color, float3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _5013 = fa_light_base(param);\n    int param_1 = _5013;\n    int param_2 = _5013 + 1;\n    int param_3 = _5013 + 2;\n    int param_4 = _5013 + 4;\n    float4 _5035 = fa_light_texel(param_4);\n    int param_5 = _5013 + 5;\n    float4 _5040 = fa_light_texel(param_5);\n    int param_6 = _5013 + 6;\n    float4 _5045 = fa_light_texel(param_6);\n    float _5046 = _5045.w;\n    float3 _5051 = fa_light_texel(param_1).xyz - world_pos;\n    bool _5053 = _5046 < 1.5f;\n    bool _5060;\n    if (_5053)\n    {\n        _5060 = dot(normalize(fa_light_texel(param_3).xyz), _5051) >= 0.0f;\n    }\n    else\n    {\n        _5060 = _5053;\n    }\n    if (_5060)\n    {\n        return 0.0f.xxx;\n    }\n    bool _5069 = (_5046 > 0.5f) && _5053;\n    float _5073 = _5069 ? 1.0539000034332275390625f : 1.0f;\n    float3 _5076 = _5035.xyz;\n    float _5078 = _5035.w;\n    float3 _5084 = _5040.xyz;\n    float _5086 = _5040.w;\n    float3 up = _5084 * (_5086 * _5073);\n    float _5092;\n    if (_5069)\n    {\n        _5092 = (3.1415927410125732421875f * _5078) * _5078;\n    }\n    else\n    {\n        _5092 = (4.0f * _5078) * _5086;\n    }\n    if (_5046 > 1.5f)\n    {\n        float3 _5118 = cross(_5076, -_5051);\n        float3 perp = _5118;\n        float _5122 = dot(_5118, _5118);\n        float3 _5125;\n        if (_5122 > 1.0000000133514319600180897396058e-10f)\n        {\n            _5125 = perp * rsqrt(_5122);\n        }\n        else\n        {\n            _5125 = _5084;\n        }\n        perp = _5125;\n        up = _5125 * _5086;\n    }\n    float _5146 = max(_5092, 9.9999999747524270787835121154785e-07f);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _5156 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _5156;\n    float3 param_10 = n;\n    float3 param_11 = _5051;\n    float3 _5164 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_12 = _5156;\n    float3 param_13 = n;\n    float3 param_14 = _5076 * (_5078 * _5073);\n    float3 _5172 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_15 = _5156;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float3 _5180 = fa_ltc_local(param_15, param_16, param_17);\n    float4 param_18 = float4(1.0f, 0.0f, 0.0f, 1.0f);\n    float param_19 = _5046;\n    float3 param_20 = _5164;\n    float3 param_21 = _5172;\n    float3 param_22 = _5180;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    float2 _5199 = fa_ltc_uv(param_23, param_24) * 64.0f;\n    float2 param_25 = _5199;\n    float2 param_26 = _5199 + float2(64.0f, 0.0f);\n    float4 _5209 = fa_atlas_fetch(param_26);\n    float4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _5046;\n    float3 param_29 = _5164;\n    float3 param_30 = _5172;\n    float3 param_31 = _5180;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _5209.x) + ((f90.xxx - f0) * _5209.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875f * dot(_5051, _5051)) + _5146) / _5146) * window);\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4053 = 1.0f / alpha;\n    return ((2.0f + _4053) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _4053)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat fa_layers_coat(FaLayers L, float3 l, float3 h, float vdh)\n{\n    float _4088 = max(dot(L.nc, l), 0.0f);\n    float _4094 = max(dot(L.nc, h), 0.0f);\n    float _4103 = ((_4094 * _4094) * (L.coat_a2 - 1.0f)) + 1.0f;\n    return (((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _4103) * _4103)) * (0.5f / max(lerp((2.0f * _4088) * L.coat_ndv, _4088 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _4088)) * _4088;\n}\n\nfloat3 fa_area_layers(FaLayers L, int li, float3 world_pos, float3 n, float3 v, float3 l, float3 diffuse_color, float3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    float3 param_2 = n;\n    float3 param_3 = v;\n    float3 param_4 = diffuse_color;\n    float3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _5277;\n    if (L.sheen_on)\n    {\n        _5277 = L.sheen_scale;\n    }\n    else\n    {\n        _5277 = 1.0f;\n    }\n    float3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _5277);\n    float3 _5290 = normalize(l + v);\n    int param_10 = li;\n    float3 _5301 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _5310 = max(dot(n, l), 0.0f);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _5290), 0.0f);\n        float param_13 = _5310;\n        float param_14 = ndv;\n        result += ((L.sheen * _5301) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875f) * step(9.9999997473787516355514526367188e-05f, _5310)) * _5310) * L.keep));\n    }\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_15 = L;\n        float3 param_16 = l;\n        float3 param_17 = _5290;\n        float param_18 = max(dot(v, _5290), 0.0f);\n        result += (_5301 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _3956 = tdh / at;\n    float _3960 = bdh / ab;\n    float _3972 = ((_3956 * _3956) + (_3960 * _3960)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _3972) * _3972);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4152 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4231 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _4231) * _4231);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _4152);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _4152));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_17 = L;\n        float3 param_18 = l;\n        float3 param_19 = h;\n        float param_20 = vdh;\n        result += fa_layers_coat(param_17, param_18, param_19, param_20).xxx;\n    }\n    return result;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3359 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3362 = _3359.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3362 * _3362, exp2((-9.27999973297119140625f) * ndv)) * _3362) + _3359.y)) + _3359.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_491_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _491_fa_env_horizon.w).xyz;\n    }\n    float _3265 = rough * rough;\n    float _3295 = 0.60000002384185791015625f * _3265;\n    return lerp(lerp(_491_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_491_fa_env_horizon.xyz, _491_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3265)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3295, 0.0500000007450580596923828125f + _3295, d.y).xxx), ((_491_fa_env_sky.xyz + _491_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3265 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _3839;\n        if (L.aniso >= 0.0f)\n        {\n            _3839 = L.b;\n        }\n        else\n        {\n            _3839 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_3839, v), _3839), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3872 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _3872.x) + (L.f90.xxx * _3872.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3927 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _3927.x) + _3927.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3401 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3401.x) + _3401.y.xxx);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2208_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3154 = int(_2208_fa_shadow_cfg.x + 0.5f);\n    float _3164 = dot(world - _2208_fa_shadow_eye.xyz, _2208_fa_shadow_fwd.xyz);\n    float3 tint_1 = 0.3499999940395355224609375f.xxx;\n    bool _3169 = _3154 > 0;\n    bool _3178;\n    if (_3169)\n    {\n        int param = _3154 - 1;\n        _3178 = _3164 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3178 = _3169;\n    }\n    if (_3178)\n    {\n        tint_1 = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3184 = _3154 > 1;\n        bool _3191;\n        if (_3184)\n        {\n            _3191 = _3164 > _2208_fa_shadow_split.x;\n        }\n        else\n        {\n            _3191 = _3184;\n        }\n        if (_3191)\n        {\n            tint_1 = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3197 = _3154 > 2;\n        bool _3204;\n        if (_3197)\n        {\n            _3204 = _3164 > _2208_fa_shadow_split.y;\n        }\n        else\n        {\n            _3204 = _3197;\n        }\n        if (_3204)\n        {\n            tint_1 = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3210 = _3154 > 3;\n        bool _3217;\n        if (_3210)\n        {\n            _3217 = _3164 > _2208_fa_shadow_split.z;\n        }\n        else\n        {\n            _3217 = _3210;\n        }\n        if (_3217)\n        {\n            tint_1 = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint_1, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _6403 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6403 = -_6403;\n    }\n    float3 _5761 = normalize(_491_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _6416 = { fa_world_pos, _6403, fa_world_tangent, fa_uv, fa_vertex_color, _5761, gl_FrontFacing };\n    SurfaceInput param_1 = _6416;\n    Surface _5769 = fa_standard_surface(param_1);\n    float3 _6434 = _5769.albedo;\n    float _6435 = _5769.alpha;\n    float3 _6436 = _5769.normal;\n    float _6437 = _5769.metallic;\n    float _6438 = _5769.roughness;\n    float _6439 = _5769.occlusion;\n    float3 _6440 = _5769.emission;\n    float _6441 = _5769.clearcoat;\n    float _6442 = _5769.clearcoat_roughness;\n    float3 _6443 = _5769.sheen_color;\n    float _6444 = _5769.sheen_roughness;\n    float _6445 = _5769.anisotropy;\n    float _6446 = _5769.anisotropy_rotation;\n    float _6447 = _5769.specular;\n    float _6448 = _5769.ior;\n    float3 _6449 = _5769.specular_color;\n    SurfaceInput _6424 = { fa_world_pos, _6403, fa_world_tangent, fa_uv, fa_vertex_color, _5761, gl_FrontFacing };\n    SurfaceInput param_2 = _6424;\n    Surface param_3 = _5769;\n    surface(param_2, param_3);\n    _6434 = param_3.albedo;\n    _6435 = param_3.alpha;\n    _6436 = param_3.normal;\n    _6437 = param_3.metallic;\n    _6438 = param_3.roughness;\n    _6439 = param_3.occlusion;\n    _6440 = param_3.emission;\n    _6441 = param_3.clearcoat;\n    _6442 = param_3.clearcoat_roughness;\n    _6443 = param_3.sheen_color;\n    _6444 = param_3.sheen_roughness;\n    _6445 = param_3.anisotropy;\n    _6446 = param_3.anisotropy_rotation;\n    _6447 = param_3.specular;\n    _6448 = param_3.ior;\n    _6449 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _6403;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6434 = param_6;\n    _6436 = param_7;\n    float3 result;\n    if (_491_fa_emissive.w > 0.5f)\n    {\n        result = _6434;\n    }\n    else\n    {\n        float3 _5808 = normalize(_6436);\n        float _5815 = clamp(_6437, 0.0f, 1.0f);\n        float _5819 = clamp(_6438, 0.0500000007450580596923828125f, 1.0f);\n        float _5823 = _5819 * _5819;\n        float _5827 = _5823 * _5823;\n        float _5832 = max(dot(_5808, _5761), 9.9999997473787516355514526367188e-05f);\n        float3 _5838 = _6434 * (1.0f - _5815);\n        float3 _5845 = lerp(0.039999999105930328369140625f.xxx, _6434, _5815.xxx);\n        float3 f0 = _5845;\n        SurfaceInput _6432 = { fa_world_pos, _6403, fa_world_tangent, fa_uv, fa_vertex_color, _5761, gl_FrontFacing };\n        SurfaceInput param_8 = _6432;\n        Surface _6515 = { _6434, _6435, _6436, _6437, _6438, _6439, _6440, _6441, _6442, _6443, _6444, _6445, _6446, _6447, _6448, _6449 };\n        Surface param_9 = _6515;\n        float3 param_10 = _5808;\n        float3 param_11 = _5761;\n        float param_12 = _5815;\n        float param_13 = _5819;\n        float3 param_14 = _5845;\n        FaLayers _5861 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _5808;\n        float3 lit = (fa_indirect_diffuse(param_15) * _5838) * _6439;\n        if (_5861.on)\n        {\n            lit *= _5861.base_scale;\n        }\n        int _5883 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5883; ln++)\n        {\n            int param_16 = ln;\n            int _5896 = fa_cl_light(param_16);\n            bool _5899 = fa_lm.z > 0.5f;\n            bool _5905;\n            if (_5899)\n            {\n                int param_17 = _5896;\n                _5905 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _5905 = _5899;\n            }\n            if (_5905)\n            {\n                continue;\n            }\n            int param_18 = _5896;\n            float3 param_19 = fa_world_pos;\n            float3 param_20 = _6403;\n            LightSample _5917 = fa_light_shadowed(param_18, param_19, param_20);\n            float _5925 = max(dot(_5808, _5917.direction), 0.0f);\n            float _5931 = _5917.attenuation * _5917.shadow;\n            float3 _5936 = normalize(_5917.direction + _5761);\n            float _5941 = max(dot(_5808, _5936), 0.0f);\n            float _5946 = max(dot(_5761, _5936), 0.0f);\n            bool _5953;\n            if (fa_light_is_area)\n            {\n                _5953 = !_5861.on;\n            }\n            else\n            {\n                _5953 = fa_light_is_area;\n            }\n            if (_5953)\n            {\n                int param_21 = _5896;\n                float3 param_22 = fa_world_pos;\n                float3 param_23 = _5808;\n                float3 param_24 = _5761;\n                float3 param_25 = _5838;\n                float3 param_26 = f0;\n                float param_27 = 1.0f;\n                float param_28 = _5819;\n                float param_29 = _5832;\n                float param_30 = _5931;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _5861;\n                    int param_32 = _5896;\n                    float3 param_33 = fa_world_pos;\n                    float3 param_34 = _5808;\n                    float3 param_35 = _5761;\n                    float3 param_36 = _5917.direction;\n                    float3 param_37 = _5838;\n                    float3 param_38 = f0;\n                    float param_39 = _5819;\n                    float param_40 = _5832;\n                    float param_41 = _5931;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_5861.on)\n                    {\n                        FaLayers param_42 = _5861;\n                        float3 param_43 = _5838;\n                        float3 param_44 = f0;\n                        float3 param_45 = _5808;\n                        float3 param_46 = _5761;\n                        float3 param_47 = _5917.direction;\n                        float3 param_48 = _5936;\n                        float param_49 = _5925;\n                        float param_50 = _5832;\n                        float param_51 = _5941;\n                        float param_52 = _5946;\n                        float param_53 = _5823;\n                        float param_54 = _5827;\n                        int param_55 = _5896;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _5931));\n                    }\n                    else\n                    {\n                        float _6059 = ((_5941 * _5941) * (_5827 - 1.0f)) + 1.0f;\n                        int param_56 = _5896;\n                        lit += (((_5838 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _5946, 5.0f))) * (((_5827 / ((3.1415927410125732421875f * _6059) * _6059)) * (0.5f / max(lerp((2.0f * _5925) * _5832, _5925 + _5832, _5823), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _5925))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_5925 * _5931));\n                    }\n                }\n            }\n        }\n        if (_5861.on)\n        {\n            FaLayers param_57 = _5861;\n            float3 param_58 = _5808;\n            float3 param_59 = _5761;\n            float3 param_60 = f0;\n            float param_61 = _5819;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _6439);\n        }\n        else\n        {\n            float3 param_62 = _5808;\n            float3 param_63 = _5761;\n            float3 param_64 = f0;\n            float param_65 = _5819;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _6439);\n        }\n        result = lit;\n    }\n    float3 _6154 = result;\n    float3 _6155 = _6154 + _6440;\n    result = _6155;\n    float3 param_66 = _6155;\n    float3 param_67 = fa_world_pos;\n    result = fa_shadow_debug(param_66, param_67);\n    bool _6164 = _491_fa_fog.w > 0.0f;\n    bool _6171;\n    if (!_6164)\n    {\n        _6171 = _491_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _6171 = _6164;\n    }\n    if (_6171)\n    {\n        float3 _6180 = fa_world_pos - _491_fa_camera_pos.xyz;\n        float _6186 = dot(_6180, _491_fa_fog_c.xyz);\n        bool _6190 = _491_fa_fog_c.w > 0.5f;\n        float _6191;\n        if (_6190)\n        {\n            _6191 = _6186;\n        }\n        else\n        {\n            _6191 = length(_6180);\n        }\n        float _6203 = _6191 - _491_fa_fog_b.x;\n        if (_6203 > 0.0f)\n        {\n            float _6212 = _491_fa_fog.w * _6203;\n            float tau = _6212 * _6212;\n            if (_491_fa_fog_b.y > 0.0f)\n            {\n                float _6228;\n                if (_6190)\n                {\n                    _6228 = fa_world_pos.y - (_491_fa_fog_c.y * _6186);\n                }\n                else\n                {\n                    _6228 = _491_fa_camera_pos.y;\n                }\n                float _6249 = lerp(_6228, fa_world_pos.y, clamp(_491_fa_fog_b.x / _6191, 0.0f, 1.0f));\n                float _6253 = fa_world_pos.y - _6249;\n                float _6258 = _6249 - _491_fa_fog_b.z;\n                float _6263 = fa_world_pos.y - _491_fa_fog_b.z;\n                bool _6266 = _6258 <= 0.0f;\n                bool _6267 = !_6266;\n                bool _6273;\n                if (_6267)\n                {\n                    _6273 = _491_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6273 = _6266;\n                }\n                float _6274;\n                if (_6273)\n                {\n                    _6274 = _491_fa_fog_b.y;\n                }\n                else\n                {\n                    _6274 = _491_fa_fog_b.y * exp(-min(_491_fa_fog_b.w * _6258, 80.0f));\n                }\n                bool _6301;\n                if (_6267)\n                {\n                    _6301 = _491_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6301 = _6266;\n                }\n                float _6302;\n                if (_6301)\n                {\n                    _6302 = _491_fa_fog_b.y * _6258;\n                }\n                else\n                {\n                    _6302 = (_491_fa_fog_b.y * (1.0f - exp(-min(_491_fa_fog_b.w * _6258, 80.0f)))) / _491_fa_fog_b.w;\n                }\n                bool _6327 = _6263 <= 0.0f;\n                bool _6334;\n                if (!_6327)\n                {\n                    _6334 = _491_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6334 = _6327;\n                }\n                float _6335;\n                if (_6334)\n                {\n                    _6335 = _491_fa_fog_b.y * _6263;\n                }\n                else\n                {\n                    _6335 = (_491_fa_fog_b.y * (1.0f - exp(-min(_491_fa_fog_b.w * _6263, 80.0f)))) / _491_fa_fog_b.w;\n                }\n                float _6362;\n                if (abs(_6253) < 0.001000000047497451305389404296875f)\n                {\n                    _6362 = _6274;\n                }\n                else\n                {\n                    _6362 = (_6335 - _6302) / _6253;\n                }\n                tau += (_6203 * max(_6362, 0.0f));\n            }\n            result = lerp(result, _491_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _6435);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_inst_v0 = stage_input.fa_inst_v0;\n    fa_inst_v1 = stage_input.fa_inst_v1;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_2208",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_5379",
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
