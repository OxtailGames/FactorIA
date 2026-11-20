{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "5c7bc8cc90909f1ebab7aa9dd758cdced3d658fca63fc282b6949a210c4a3347",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _3659[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _562_fa_camera_pos : packoffset(c0);\n    float4 _562_fa_ambient : packoffset(c1);\n    float4 _562_fa_base_color : packoffset(c2);\n    float4 _562_fa_emissive : packoffset(c3);\n    float4 _562_fa_model_emissive : packoffset(c4);\n    float4 _562_fa_pbr : packoffset(c5);\n    float4 _562_fa_maps : packoffset(c6);\n    float4 _562_fa_fog : packoffset(c7);\n    float4 _562_fa_fog_b : packoffset(c8);\n    float4 _562_fa_fog_c : packoffset(c9);\n    float4 _562_fa_counts : packoffset(c10);\n    float4 _562_fa_env_sky : packoffset(c11);\n    float4 _562_fa_env_horizon : packoffset(c12);\n    float4 _562_fa_time : packoffset(c13);\n    float4 _562_fa_cl_vpx : packoffset(c14);\n    float4 _562_fa_cl_vpy : packoffset(c15);\n    float4 _562_fa_cl_vpw : packoffset(c16);\n    float4 _562_fa_cl_fwd : packoffset(c17);\n    float4 _562_fa_cl_grid : packoffset(c18);\n    float4 _562_fa_cl_info : packoffset(c19);\n    float4 _562_fa_layers_a : packoffset(c20);\n    float4 _562_fa_layers_b : packoffset(c21);\n    float4 _562_fa_layers_c : packoffset(c22);\n    float4 _562_fa_layers_d : packoffset(c23);\n    float4 _562_fa_ct_a : packoffset(c24);\n    float4 _562_fa_ct_b : packoffset(c25);\n    float4 _562_fa_ct_vpx : packoffset(c26);\n    float4 _562_fa_ct_vpy : packoffset(c27);\n    float4 _562_fa_ct_vpw : packoffset(c28);\n    float4 _562_fa_ct_fwd : packoffset(c29);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2229_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2229_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2229_fa_shadow_info[4] : packoffset(c20);\n    float4 _2229_fa_shadow_split : packoffset(c24);\n    float4 _2229_fa_shadow_cfg : packoffset(c25);\n    float4 _2229_fa_shadow_bias : packoffset(c26);\n    float4 _2229_fa_shadow_eye : packoffset(c27);\n    float4 _2229_fa_shadow_fwd : packoffset(c28);\n    float4 _2229_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _5836_boost : packoffset(c0);\n    float _5836_fa_pad0 : packoffset(c0.y);\n    float _5836_fa_pad1 : packoffset(c0.z);\n    float _5836_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_screen_tex : register(t11);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float3 fa_lm : TEXCOORD7;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\nstatic float raise;\nstatic float4 tint;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1500 = _562_fa_cl_info.x < 0.0f;\n    bool _1507;\n    if (!_1500)\n    {\n        _1507 = _562_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1507 = _1500;\n    }\n    bool _1515;\n    if (!_1507)\n    {\n        _1515 = _562_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1515 = _1507;\n    }\n    bool _1522;\n    if (!_1515)\n    {\n        _1522 = _562_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1522 = _1515;\n    }\n    bool _1529;\n    if (!_1522)\n    {\n        _1529 = _562_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1529 = _1522;\n    }\n    if (_1529)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1539 = float4(world_pos, 1.0f);\n    float _1545 = dot(_562_fa_cl_vpw, _1539);\n    if (!(_1545 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1567 = float2(dot(_562_fa_cl_vpx, _1539), dot(_562_fa_cl_vpy, _1539)) / _1545.xx;\n    int _1571 = int(_562_fa_cl_grid.x);\n    int _1575 = int(_562_fa_cl_grid.y);\n    int param = (int(_562_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_562_fa_cl_fwd.xyz, world_pos) + _562_fa_cl_fwd.w, _562_fa_cl_grid.w) / _562_fa_cl_grid.w) * _562_fa_cl_grid.z)), 0, int(_562_fa_cl_info.y) - 1) * _1575) + clamp(int(floor(((_1567.y * 0.5f) + 0.5f) * _562_fa_cl_grid.y)), 0, _1575 - 1)) * _1571)) + clamp(int(floor(((_1567.x * 0.5f) + 0.5f) * _562_fa_cl_grid.x)), 0, _1571 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1651 = fa_cluster_texel(param);\n    return int2(int(_1651.x), int(_1651.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_562_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4729 = fa_cluster_lookup(param);\n    fa_cl_slot = _4729.x;\n    fa_cl_local = _4729.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _5888 = fa_linear_to_srgb(param);\n        c = _5888;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _5896 = fa_srgb_to_linear(param_1);\n            c = _5896;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _445;\n    if (i.front_facing)\n    {\n        _445 = i.world_normal;\n    }\n    else\n    {\n        _445 = -i.world_normal;\n    }\n    float3 _469 = normalize(i.world_tangent.xyz - (_445 * dot(_445, i.world_tangent.xyz)));\n    float3 _496 = normalize(((_469 * m.x) + ((cross(_445, _469) * i.world_tangent.w) * m.y)) + (_445 * m.z));\n    float3 _499;\n    if (i.front_facing)\n    {\n        _499 = _496;\n    }\n    else\n    {\n        _499 = -_496;\n    }\n    return _499;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _562_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _5927 = fa_tex_fix(param_2, param_3);\n    float4 _7355 = base_t;\n    _7355.x = _5927.x;\n    _7355.y = _5927.y;\n    _7355.z = _5927.z;\n    base_t = _7355;\n    float4 _5941 = (_7355 * _562_fa_base_color) * i.vertex_color;\n    float3 _7180 = i.world_normal;\n    if (_562_fa_maps.z > 0.5f)\n    {\n        float param_4 = _562_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _5973 = fa_tex_fix(param_6, param_7);\n        float3 _5976 = (_5973 * 2.0f) - 1.0f.xxx;\n        float2 _5981 = _5976.xy * _562_fa_maps.x;\n        float3 _7363 = _5976;\n        _7363.x = _5981.x;\n        _7363.y = _5981.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _7363;\n        _7180 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _562_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _6009 = fa_tex_fix(param_12, param_13);\n    float4 _7366 = mrt;\n    _7366.x = _6009.x;\n    _7366.y = _6009.y;\n    _7366.z = _6009.z;\n    mrt = _7366;\n    float4 _6037 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _562_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _6037.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _6048 = fa_tex_fix(param_16, param_17);\n    float param_18 = _562_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _6078 = fa_tex_fix(param_20, param_21);\n    float _7185 = _562_fa_layers_a.x;\n    float _7186 = _562_fa_layers_a.y;\n    float _7189 = _562_fa_layers_a.z;\n    float _7188 = _562_fa_layers_b.w;\n    float _7191 = _562_fa_layers_c.x;\n    if (_562_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_562_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _7185 *= _6048.y;\n            _7186 *= _6048.z;\n            _7188 *= _6037.w;\n        }\n        if (_562_fa_layers_c.z > 1.5f)\n        {\n            _7189 *= mrt.x;\n            _7191 *= mrt.w;\n        }\n    }\n    Surface _7210 = { _5941.xyz, _5941.w, _7180, clamp(_562_fa_pbr.x * _6009.z, 0.0f, 1.0f), clamp(_562_fa_pbr.y * _6009.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_562_fa_maps.y * (_6048.x - 1.0f)), _562_fa_emissive.xyz + (_562_fa_model_emissive.xyz * _6078), _7185, _7186, _562_fa_layers_b.xyz, _7188, _7189, _562_fa_layers_a.w, _7191, _562_fa_layers_c.y, _562_fa_layers_d.xyz };\n    return _7210;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * _5836_boost);\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1731 = rect.zw - rect.xy;\n    float2 _1735 = _1731 * atlas;\n    float2 _1739 = ddx * _1735;\n    float2 _1743 = ddy * _1735;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1731), clamp(0.5f * log2(max(max(dot(_1739, _1739), dot(_1743, _1743)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1776 = _562_fa_counts.y < 0.5f;\n    bool _1783;\n    if (!_1776)\n    {\n        _1783 = _562_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1783 = _1776;\n    }\n    if (_1783)\n    {\n        return;\n    }\n    float3 _1789 = ddx(world_pos);\n    float3 _1792 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1796 = fa_cluster_texel(param);\n    int _1800 = int(_1796.w);\n    if (_1800 < 1)\n    {\n        return;\n    }\n    int _1810 = int(_562_fa_counts.y + 0.5f);\n    int param_1 = _1810;\n    float4 _1814 = fa_light_texel(param_1);\n    float2 _1817 = _1814.yz;\n    int _1821 = int(_1814.w);\n    int param_2 = _1810 + 1;\n    float4 _1826 = fa_light_texel(param_2);\n    float _1827 = _1826.x;\n    int _1833 = int(_562_fa_counts.w + 0.5f) - 1;\n    int _1837 = int(_1796.z);\n    float3 _2102;\n    for (int k = 0; k < _1800; k++)\n    {\n        int _1850 = _1837 + k;\n        int param_3 = _1821 + (_1850 >> 2);\n        int _1867 = (_1810 + 2) + (int(fa_light_texel(param_3)[_1850 & 3]) * 7);\n        int param_4 = _1867 + 6;\n        float4 _1872 = fa_light_texel(param_4);\n        if (((int(_1872.w + 0.5f) >> _1833) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1867;\n        float4 _1887 = fa_light_texel(param_5);\n        int param_6 = _1867 + 1;\n        float4 _1892 = fa_light_texel(param_6);\n        int param_7 = _1867 + 2;\n        float4 _1897 = fa_light_texel(param_7);\n        float3 _1900 = _1887.xyz;\n        float _1905 = dot(_1900, world_pos) + _1887.w;\n        float3 _1907 = _1892.xyz;\n        float _1912 = dot(_1907, world_pos) + _1892.w;\n        float3 _1914 = _1897.xyz;\n        float _1919 = dot(_1914, world_pos) + _1897.w;\n        bool _1924 = abs(_1905) > 0.5f;\n        bool _1932;\n        if (!_1924)\n        {\n            _1932 = abs(_1912) > 0.5f;\n        }\n        else\n        {\n            _1932 = _1924;\n        }\n        bool _1940;\n        if (!_1932)\n        {\n            _1940 = abs(_1919) > 0.5f;\n        }\n        else\n        {\n            _1940 = _1932;\n        }\n        if (_1940)\n        {\n            continue;\n        }\n        float _1955 = clamp(dot(geo_normal, normalize(_1914)) * _1872.z, 0.0f, 1.0f);\n        if (_1955 <= 0.0f)\n        {\n            continue;\n        }\n        float _1975 = (clamp((0.5f - abs(_1919)) * 10.0f, 0.0f, 1.0f) * _1955) * _1872.x;\n        float2 _1983 = float2(_1905 + 0.5f, 0.5f - _1912);\n        float2 _1993 = float2(dot(_1900, _1789), dot(_1907, _1789));\n        float2 _2003 = float2(dot(_1900, _1792), dot(_1907, _1792));\n        int param_8 = _1867 + 5;\n        float4 _2008 = fa_light_texel(param_8);\n        int param_9 = _1867 + 3;\n        float4 _2013 = fa_light_texel(param_9);\n        int param_10 = _1867 + 4;\n        float4 _2018 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _2008.xyz;\n        bool _2028 = _2013.z > _2013.x;\n        if (_2028)\n        {\n            float4 param_11 = _2013;\n            float2 param_12 = _1983;\n            float2 param_13 = _1817;\n            float2 param_14 = _1993;\n            float2 param_15 = _2003;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1827 > 0.5f) && (_1827 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _2054 = fa_dc_to_linear(param_16);\n                float4 _7260 = tx;\n                _7260.x = _2054.x;\n                _7260.y = _2054.y;\n                _7260.z = _2054.z;\n                tx = _7260;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1975 * tex_a) * _2008.w, 0.0f, 1.0f).xxx);\n        if (_2018.z > _2018.x)\n        {\n            float4 param_17 = _2018;\n            float2 param_18 = _1983;\n            float2 param_19 = _1817;\n            float2 param_20 = _1993;\n            float2 param_21 = _2003;\n            float4 _2098 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1827 > 1.5f)\n            {\n                float3 param_22 = _2098.xyz;\n                float3 _2108 = fa_dc_to_srgb(param_22);\n                _2102 = _2108;\n            }\n            else\n            {\n                _2102 = _2098.xyz;\n            }\n            float3 _2117 = (_2102 * 2.0f) - 1.0f.xxx;\n            float2 _2122 = _2117.xy * _1872.y;\n            float3 _2144 = (normalize(_1900) * _2122.x) + (normalize(_1907) * _2122.y);\n            float3 _2147 = normalize(normal);\n            normal = normalize(lerp(_2147, normalize((_2147 * max(_2117.z, 0.0500000007450580596923828125f)) + (_2144 - (_2147 * dot(_2147, _2144)))), clamp(_1975 * (_2028 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3585 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3592 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3595 = int(_3585);\n    int _3598 = int(_3592);\n    float _3608 = _3592 - float(_3598);\n    int _3663 = (_3595 * 9) + _3598;\n    int _3683 = ((_3595 + 1) * 9) + _3598;\n    return lerp(lerp(_3659[_3663], _3659[_3663 + 1], _3608), lerp(_3659[_3683], _3659[_3683 + 1], _3608), _3585 - float(_3595));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _7103 = false;\n    float _7104 = 1.0f;\n    float _7105 = 1.0f;\n    float _7106 = 1.0f;\n    float _7107 = 0.0f;\n    float _7108 = 0.0f;\n    float _7109 = 0.0f;\n    float _7110 = 0.0f;\n    float _7112 = 1.0f;\n    bool _7113 = false;\n    float3 _7114 = 0.0f.xxx;\n    float _7115 = 1.0f;\n    float _7116 = 1.0f;\n    float _7117 = 1.0f;\n    float _7118 = 0.0f;\n    float _7119 = 0.0f;\n    float3 _7120 = float3(1.0f, 0.0f, 0.0f);\n    float3 _7121 = float3(0.0f, 0.0f, 1.0f);\n    float _7122 = 1.0f;\n    float _7123 = 1.0f;\n    float _3734 = clamp(s.specular, 0.0f, 1.0f);\n    float _3738 = clamp(s.ior, 1.0f, 3.0f);\n    bool _3743 = (_3734 != 1.0f) || (_3738 != 1.5f);\n    bool _3752;\n    if (!_3743)\n    {\n        _3752 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _3752 = _3743;\n    }\n    if (_3752)\n    {\n        float _3760 = (_3738 - 1.0f) / (_3738 + 1.0f);\n        f0 = lerp(min((_3760 * _3760).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _3734, s.albedo, metallic.xxx);\n        _7104 = lerp(_3734, 1.0f, metallic);\n        _7103 = true;\n    }\n    float _3787 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_3787 > 0.0f)\n    {\n        float _3795 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _7107 = _3787;\n        _7108 = _3795;\n        float _3802 = _3795 * _3795;\n        _7109 = _3802;\n        _7110 = _3802 * _3802;\n        float _3814 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _7112 = _3814;\n        _7105 = 1.0f - (_3787 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _3814, 0.0f, 1.0f), 5.0f))));\n        _7103 = true;\n    }\n    float3 _3833 = max(s.sheen_color, 0.0f.xxx);\n    float _3842 = max(_3833.x, max(_3833.y, _3833.z));\n    if (_3842 > 0.0f)\n    {\n        float _3850 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _7113 = true;\n        _7114 = _3833;\n        _7115 = _3850;\n        _7116 = _3850 * _3850;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _3850;\n        float _3867 = fa_sheen_albedo(param, param_1);\n        _7118 = _3867;\n        _7117 = 1.0f - min(_3842 * _3867, 1.0f);\n        _7103 = true;\n    }\n    _7106 = _7105 * _7117;\n    float _3886 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_3886 != 0.0f)\n    {\n        float3 _3901 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _3901;\n        if (dot(_3901, _3901) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _3913 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_3913.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _3913.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _3913.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _3917 = t;\n        float3 _3918 = normalize(_3917);\n        t = _3918;\n        float3 _3943 = normalize((_3918 * cos(s.anisotropy_rotation)) + ((cross(n, _3918) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _7120 = _3943;\n        _7121 = cross(n, _3943);\n        float _3953 = roughness * roughness;\n        float _3959 = lerp(_3953, 1.0f, _3886 * _3886);\n        bool _3961 = _3886 > 0.0f;\n        _7122 = _3961 ? _3959 : _3953;\n        _7123 = _3961 ? _3953 : _3959;\n        _7119 = _3886;\n        _7103 = true;\n    }\n    FaLayers _7145 = { _7103, _7104, _7105, _7106, _7107, _7108, _7109, _7110, i.world_normal, _7112, _7113, _7114, _7115, _7116, _7117, _7118, _7119, _7120, _7121, _7122, _7123 };\n    return _7145;\n}\n\nfloat3 fa_sky_sh_coef(int k)\n{\n    float3 v = fa_env_tex.SampleLevel(fa_env_smp, float3(1.0f, 1.0f - (float((2 * (k >> 2)) + 1) * 0.25f), 1.0f - (float((2 * (k & 3)) + 1) * 0.25f)), 5.0f).xyz;\n    if (_562_fa_env_sky.w > 1.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3342 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3342;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_562_fa_env_sky.w > 0.5f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _562_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_562_fa_cl_info.x) + int(_562_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_562_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _630_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _630_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _749 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _762 = (c - (ru * hx)) - p;\n        float3 _768 = ru * (2.0f * hx);\n        float _774 = max(dot(_768, _768), 9.9999999392252902907785028219223e-09f);\n        float _778 = dot(_762, _768);\n        float t = clamp((-_778) / _774, 0.0f, 1.0f);\n        if (_749)\n        {\n            float _793 = dot(r, _768);\n            float _799 = _774 - (_793 * _793);\n            if (abs(_799) > (9.9999997473787516355514526367188e-06f * _774))\n            {\n                t = clamp(((dot(r, _762) * _793) - _778) / _799, 0.0f, 1.0f);\n            }\n        }\n        return (p + _762) + (_768 * t);\n    }\n    float3 q = p;\n    float _831 = dot(r, axis);\n    bool _839;\n    if (_749)\n    {\n        _839 = abs(_831) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _839 = _749;\n    }\n    if (_839)\n    {\n        float _849 = dot(c - p, axis) / _831;\n        if (_849 > 0.0f)\n        {\n            q = p + (r * _849);\n        }\n    }\n    float3 _862 = q - c;\n    float2 xy = float2(dot(_862, ru), dot(_862, uu));\n    if (shape > 0.5f)\n    {\n        float _877 = length(xy);\n        if (_877 > hx)\n        {\n            xy *= (hx / _877);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _511 = abs(d);\n    float _513 = _511.x;\n    float _515 = _511.y;\n    bool _516 = _513 >= _515;\n    bool _524;\n    if (_516)\n    {\n        _524 = _513 >= _511.z;\n    }\n    else\n    {\n        _524 = _516;\n    }\n    int _525;\n    if (_524)\n    {\n        _525 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _540;\n        if (_515 >= _511.z)\n        {\n            _540 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _540 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _525 = _540;\n    }\n    return _525;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _669 = dot(d, right);\n    float _673 = dot(d, up);\n    float _684;\n    if (((_669 * _669) + (_673 * _673)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _684 = atan2(_673, _669) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _684 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_684 - floor(_684)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _915 = fa_light_base(param);\n    bool _919 = _562_fa_ambient.w > 4.5f;\n    int param_1 = _915;\n    float4 _923 = fa_light_texel(param_1);\n    int param_2 = _915 + 1;\n    float4 _928 = fa_light_texel(param_2);\n    float _931 = _928.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _943 = _919 && (_931 > 2.5f);\n    fa_light_is_area = _943;\n    bool _945 = _931 < 0.5f;\n    float3 l;\n    if (_945)\n    {\n        l = normalize(_923.xyz);\n        if (_919)\n        {\n            int param_3 = _915 + 6;\n            float4 _959 = fa_light_texel(param_3);\n            if (_959.z > 0.5f)\n            {\n                int param_4 = _915 + 4;\n                float4 _969 = fa_light_texel(param_4);\n                int param_5 = _915 + 5;\n                float4 _974 = fa_light_texel(param_5);\n                float2 param_6 = _959.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _969.xyz) * _969.w, (-dot(world_pos, _974.xyz)) * _974.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _1004 = _923.xyz;\n        float3 _1006 = _1004 - world_pos;\n        float3 to_light = _1006;\n        float _1009 = length(_1006);\n        float reach = _1009;\n        bool front = true;\n        if (_943)\n        {\n            int param_8 = _915 + 7;\n            reach = max(_1009 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _915 + 4;\n            float4 _1033 = fa_light_texel(param_9);\n            int param_10 = _915 + 5;\n            float4 _1038 = fa_light_texel(param_10);\n            int param_11 = _915 + 6;\n            float4 _1043 = fa_light_texel(param_11);\n            float _1044 = _1043.w;\n            int param_12 = _915 + 2;\n            float3 _1051 = normalize(fa_light_texel(param_12).xyz);\n            bool _1053 = _1044 > 1.5f;\n            bool _1061;\n            if (!_1053)\n            {\n                _1061 = dot(_1051, to_light) < 0.0f;\n            }\n            else\n            {\n                _1061 = _1053;\n            }\n            front = _1061;\n            float3 r = 0.0f.xxx;\n            float3 _1070 = _562_fa_camera_pos.xyz - world_pos;\n            bool _1074 = dot(n, n) > 0.5f;\n            bool _1082;\n            if (_1074)\n            {\n                _1082 = dot(_1070, _1070) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _1082 = _1074;\n            }\n            if (_1082)\n            {\n                r = reflect(-normalize(_1070), normalize(n));\n            }\n            float3 param_13 = _1004;\n            float3 param_14 = _1051;\n            float3 param_15 = _1033.xyz;\n            float3 param_16 = _1038.xyz;\n            float param_17 = _1033.w;\n            float param_18 = _1038.w;\n            float param_19 = _1044;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1118 = length(to_light);\n        dist = _1118;\n        l = to_light / max(_1118, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1132 = reach / max(_923.w, 0.001000000047497451305389404296875f);\n        float _1138 = clamp(1.0f - (_1132 * _1132), 0.0f, 1.0f);\n        float _1140;\n        if (front)\n        {\n            _1140 = _1138 * _1138;\n        }\n        else\n        {\n            _1140 = 0.0f;\n        }\n        atten = _1140;\n        bool _1151 = _931 < 2.5f;\n        if ((_931 > 1.5f) && _1151)\n        {\n            int param_22 = _915 + 2;\n            float4 _1159 = fa_light_texel(param_22);\n            float _1169 = _1159.w;\n            int param_23 = _915 + 3;\n            float4 _1174 = fa_light_texel(param_23);\n            float _1175 = _1174.x;\n            float cos_inner = _1175;\n            if (_1175 > 1.5f)\n            {\n                cos_inner = lerp(_1169, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1169, cos_inner, dot(-l, normalize(_1159.xyz)));\n        }\n        if (_919 && (_931 < 1.5f))\n        {\n            int param_24 = _915 + 6;\n            float4 _1199 = fa_light_texel(param_24);\n            if (_1199.z > 0.5f)\n            {\n                float3 _1207 = -to_light;\n                int param_25 = _915 + 4;\n                int param_26 = _915 + 5;\n                float3 _1221 = fa_light_texel(param_25).xyz;\n                float3 _1225 = fa_light_texel(param_26).xyz;\n                float3 _1234 = float3(dot(_1207, _1221), dot(_1207, _1225), dot(_1207, cross(_1221, _1225)));\n                float3 param_27 = _1234;\n                int _1238 = fa_cube_face(param_27);\n                int param_28 = _1238;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1265 = float2(dot(_1234, cross(param_29, param_30)), dot(_1234, param_30)) / max(dot(_1234, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1269 = _1238 / 3;\n                float2 param_31 = _1199.xy + (float2(float(_1238 - (_1269 * 3)), float(_1269)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1265.x), 0.5f - (0.5f * _1265.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _915 + 7;\n            float4 _1299 = fa_light_texel(param_33);\n            if (_1299.z > 0.5f)\n            {\n                int param_34 = _915 + 2;\n                int param_35 = _915 + 4;\n                int param_36 = _915 + 5;\n                float2 param_37 = _1299.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_919 && _1151)\n            {\n                int param_42 = _915 + 6;\n                float4 _1346 = fa_light_texel(param_42);\n                int param_43 = _915 + 7;\n                float4 _1351 = fa_light_texel(param_43);\n                bool _1354 = _1346.z > 0.5f;\n                bool _1361;\n                if (!_1354)\n                {\n                    _1361 = _1351.z > 0.5f;\n                }\n                else\n                {\n                    _1361 = _1354;\n                }\n                if (_1361)\n                {\n                    int param_44 = _915 + 2;\n                    float4 _1368 = fa_light_texel(param_44);\n                    float3 _1372 = normalize(_1368.xyz);\n                    int param_45 = _915 + 4;\n                    float4 _1377 = fa_light_texel(param_45);\n                    int param_46 = _915 + 5;\n                    float4 _1382 = fa_light_texel(param_46);\n                    if (_1354)\n                    {\n                        float3 _1390 = -to_light;\n                        float _1397 = _1368.w;\n                        float _1413 = 0.5f / max(dot(_1390, _1372) * (sqrt(max(1.0f - (_1397 * _1397), 0.0f)) / max(_1397, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1346.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1390, _1377.xyz) * _1413), 0.5f - (dot(_1390, _1382.xyz) * _1413));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1351.z > 0.5f)\n                    {\n                        float2 param_49 = _1351.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1372;\n                        float3 param_52 = _1377.xyz;\n                        float3 param_53 = _1382.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _7091 = _928.xyz * atten;\n    if (_919)\n    {\n        _7091 *= fa_light_tint;\n    }\n    int _1482;\n    if (_945)\n    {\n        _1482 = 0;\n    }\n    else\n    {\n        _1482 = ((_931 > 1.5f) && (_931 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _7102 = { l, _7091, atten, 1.0f, dist, _1482 };\n    return _7102;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2219;\n    if (i == 0)\n    {\n        _2219 = _2229_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2235;\n        if (i == 1)\n        {\n            _2235 = _2229_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2243;\n            if (i == 2)\n            {\n                _2243 = _2229_fa_shadow_split.z;\n            }\n            else\n            {\n                _2243 = _2229_fa_shadow_split.w;\n            }\n            _2235 = _2243;\n        }\n        _2219 = _2235;\n    }\n    return _2219;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2276 = fa_shadow_depth(param, param_1);\n    float _2280;\n    if (conv.x < 0.5f)\n    {\n        _2280 = _2276;\n    }\n    else\n    {\n        _2280 = (conv.y * conv.z) / (conv.z - (_2276 * (conv.z - conv.y)));\n    }\n    return _2280;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2207 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2207), sin(_2207)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2326 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2335;\n        if (k < 0.0f)\n        {\n            _2335 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2335 = k;\n        }\n        float _2355 = clamp((_2335 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2326;\n            float2 _2374 = fa_shadow_vogel(param_3, param_4, param_5) * _2355;\n            float2 param_6 = uv + (_2374 * _2229_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2386 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2386 < (zr - (length(_2374) * plane)))\n            {\n                sum += _2386;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2412 = sum / cnt;\n        float _2422;\n        if (k < 0.0f)\n        {\n            _2422 = (-k) / max(_2412, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2422 = k;\n        }\n        radius = clamp(((max(zr - _2412, 0.0f) * unit) * _2422) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2444 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2444; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2444;\n        float param_11 = _2326;\n        float2 _2463 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2463 * _2229_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2463) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2444);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2505 = max(_2229_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2510 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2516 = sqrt(1.0f - (_2510 * _2510));\n    float _2523 = min(_2516 / max(_2510, 0.20000000298023223876953125f), 4.0f);\n    float _2528;\n    if (_2229_fa_shadow_bias.y > 0.0f)\n    {\n        _2528 = _2229_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2528 = 1.5f * _2229_fa_shadow_info[ci].x;\n    }\n    float4 _2553 = mul(float4(world + (n * (_2528 * _2516)), 1.0f), _2229_fa_shadow_mat[ci]);\n    float _2560 = _2553.x;\n    bool _2563 = _2560 < _2229_fa_shadow_rect[ci].x;\n    bool _2572;\n    if (!_2563)\n    {\n        _2572 = _2560 > _2229_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2572 = _2563;\n    }\n    bool _2581;\n    if (!_2572)\n    {\n        _2581 = _2553.y < _2229_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2581 = _2572;\n    }\n    bool _2590;\n    if (!_2581)\n    {\n        _2590 = _2553.y > _2229_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2590 = _2581;\n    }\n    bool _2597;\n    if (!_2590)\n    {\n        _2597 = _2553.z > 1.0f;\n    }\n    else\n    {\n        _2597 = _2590;\n    }\n    if (_2597)\n    {\n        return -1.0f;\n    }\n    float _2605;\n    if (_2229_fa_shadow_bias.x > 0.0f)\n    {\n        _2605 = _2229_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2605 = 1.5f * _2229_fa_shadow_info[ci].x;\n    }\n    float2 param = _2553.xy;\n    float4 param_1 = _2229_fa_shadow_rect[ci];\n    float param_2 = _2553.z - ((_2605 * (1.0f + (0.5f * _2523))) / _2505);\n    float param_3 = _2229_fa_shadow_info[ci].x;\n    float param_4 = _2505;\n    float param_5 = _2505 * 0.25f;\n    float param_6 = ((_2229_fa_shadow_info[ci].x * min(_2523, 3.0f)) * 0.5f) / _2505;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2229_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2229_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_562_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2983 = int(_2229_fa_shadow_cfg.x + 0.5f);\n    if (_2983 < 1)\n    {\n        return 1.0f;\n    }\n    float _2998 = dot(world - _2229_fa_shadow_eye.xyz, _2229_fa_shadow_fwd.xyz);\n    int param = _2983 - 1;\n    if (_2998 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _3010 = _2983 > 1;\n    bool _3017;\n    if (_3010)\n    {\n        _3017 = _2998 > _2229_fa_shadow_split.x;\n    }\n    else\n    {\n        _3017 = _3010;\n    }\n    if (_3017)\n    {\n        ci = 1;\n    }\n    bool _3021 = _2983 > 2;\n    bool _3028;\n    if (_3021)\n    {\n        _3028 = _2998 > _2229_fa_shadow_split.y;\n    }\n    else\n    {\n        _3028 = _3021;\n    }\n    if (_3028)\n    {\n        ci = 2;\n    }\n    bool _3032 = _2983 > 3;\n    bool _3039;\n    if (_3032)\n    {\n        _3039 = _2998 > _2229_fa_shadow_split.z;\n    }\n    else\n    {\n        _3039 = _3032;\n    }\n    if (_3039)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2983)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _3065 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3065;\n        if (_3065 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2229_fa_shadow_cfg.y > 0.0f)\n    {\n        float _3090;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3090 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3090 = _2229_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _3109 = _2229_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3090, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _3120 = clamp((_2998 - (fa_shadow_split_at(param_7) - _3109)) / _3109, 0.0f, 1.0f);\n        if (_3120 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2983)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _3141 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3141;\n                if (_3141 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _3120);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2663 = _562_fa_pbr.z < 0.5f;\n    bool _2670;\n    if (!_2663)\n    {\n        _2670 = _2229_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2670 = _2663;\n    }\n    if (_2670)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2229_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2683 = fa_light_texel(param);\n    float _2684 = _2683.x;\n    if (_2684 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2693 = int(_2684 + 0.5f);\n    int param_1 = _2693;\n    float4 _2697 = fa_light_texel(param_1);\n    int param_2 = _2693 + 1;\n    float4 _2702 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2705 = _2697.y;\n    if (_2705 > 0.0f)\n    {\n        float _2722 = 1.0f - smoothstep(0.75f * _2705, _2705, length(world - _2229_fa_shadow_eye.xyz));\n        fade = _2722;\n        if (_2722 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2697.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2746 = (_2693 + 2) + (face * 6);\n    int param_4 = _2746;\n    int param_5 = _2746 + 1;\n    int param_6 = _2746 + 3;\n    float4 _2760 = fa_light_texel(param_6);\n    int param_7 = _2746 + 4;\n    float4 _2765 = fa_light_texel(param_7);\n    int param_8 = _2746 + 5;\n    float4 _2770 = fa_light_texel(param_8);\n    float _2782 = _2770.x * max(dot(_2760, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2787 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2810 = clamp(dot(n, _2760.xyz), -1.0f, 1.0f);\n    float _2829 = min(sqrt(1.0f - (_2810 * _2810)) / max(abs(dot(n, world - lpos)) / max(dot(_2760, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2832 = _2702.y;\n    float _2834;\n    if (_2832 > 0.0f)\n    {\n        _2834 = _2832;\n    }\n    else\n    {\n        _2834 = 1.5f * _2782;\n    }\n    float4 _2854 = float4(world + (n * (_2834 * sqrt(1.0f - (_2787 * _2787)))), 1.0f);\n    float _2858 = dot(_2760, _2854);\n    float _2861 = _2770.y;\n    if (_2858 < _2861)\n    {\n        return 1.0f;\n    }\n    float2 _2876 = float2(dot(fa_light_texel(param_4), _2854), dot(fa_light_texel(param_5), _2854)) / _2858.xx;\n    float _2878 = _2876.x;\n    bool _2881 = _2878 < _2765.x;\n    bool _2890;\n    if (!_2881)\n    {\n        _2890 = _2878 > _2765.z;\n    }\n    else\n    {\n        _2890 = _2881;\n    }\n    bool _2899;\n    if (!_2890)\n    {\n        _2899 = _2876.y < _2765.y;\n    }\n    else\n    {\n        _2899 = _2890;\n    }\n    bool _2908;\n    if (!_2899)\n    {\n        _2908 = _2876.y > _2765.w;\n    }\n    else\n    {\n        _2908 = _2899;\n    }\n    if (_2908)\n    {\n        return 1.0f;\n    }\n    float _2914 = _2702.x;\n    float _2916;\n    if (_2914 > 0.0f)\n    {\n        _2916 = _2914;\n    }\n    else\n    {\n        _2916 = 1.5f * _2782;\n    }\n    float2 param_9 = _2876;\n    float4 param_10 = _2765;\n    float param_11 = _2858 - (_2916 * (1.0f + (0.5f * _2829)));\n    float param_12 = _2782;\n    float param_13 = 1.0f;\n    float param_14 = _2770.z * 0.25f;\n    float param_15 = (_2782 * min(_2829, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2861, _2770.z);\n    int param_17 = int(_2697.z + 0.5f);\n    float param_18 = _2697.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _4471 = _562_fa_ct_a.x < 0.5f;\n    bool _4478;\n    if (!_4471)\n    {\n        _4478 = _2229_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _4478 = _4471;\n    }\n    if (_4478)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2229_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _4491 = fa_light_texel(param);\n    float _4492 = _4491.y;\n    float len = _4492;\n    if (_4492 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4504 = length(world - _562_fa_camera_pos.xyz);\n    float _4514 = 1.0f - smoothstep(0.5f * _562_fa_ct_b.x, _562_fa_ct_b.x, _4504);\n    if (_4514 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4520 = len;\n    float _4523 = min(_4520, 0.89999997615814208984375f * dist);\n    len = _4523;\n    float _4528 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _4504);\n    float _4533 = _4528 + (0.5f * _4523);\n    float3 _4539 = world + (gn * _4528);\n    float _4541 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _4605;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4556 = (float(k) + _4541) * 0.083333335816860198974609375f;\n        float3 _4564 = _4539 + (l * (_4556 * len));\n        float4 _4570 = float4(_4564, 1.0f);\n        float _4576 = dot(_562_fa_ct_vpw, _4570);\n        if (_4576 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _4596 = float2(dot(_562_fa_ct_vpx, _4570), dot(_562_fa_ct_vpy, _4570)) / _4576.xx;\n        float _4600 = _4596.x * 0.5f;\n        float _4601 = _4600 + 0.5f;\n        if (_562_fa_ct_a.y > 0.5f)\n        {\n            _4605 = (_4596.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _4605 = 0.5f - (_4596.y * 0.5f);\n        }\n        bool _4621 = _4601 < 0.0f;\n        bool _4628;\n        if (!_4621)\n        {\n            _4628 = _4601 >= 1.0f;\n        }\n        else\n        {\n            _4628 = _4621;\n        }\n        bool _4635;\n        if (!_4628)\n        {\n            _4635 = _4605 < 0.0f;\n        }\n        else\n        {\n            _4635 = _4628;\n        }\n        bool _4642;\n        if (!_4635)\n        {\n            _4642 = _4605 >= 1.0f;\n        }\n        else\n        {\n            _4642 = _4635;\n        }\n        if (_4642)\n        {\n            break;\n        }\n        float4 _4661 = fa_screen_tex.Load(int3(int2(float2(_4601, _4605) * _562_fa_ct_a.zw), 0));\n        if (_4661.w < 0.5f)\n        {\n            continue;\n        }\n        float _4680 = (dot(_562_fa_ct_fwd.xyz, _4564) + _562_fa_ct_fwd.w) - _4661.x;\n        if ((_4680 > _4528) && (_4680 < _4533))\n        {\n            occ = max(occ, (1.0f - (_4556 * _4556)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_4601, 0.5f - _4600), min(_4605, 1.0f - _4605))));\n        }\n    }\n    return 1.0f - (occ * _4514);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _4756 = fa_lm.z > 0.5f;\n    bool _4762;\n    if (_4756)\n    {\n        int param = li;\n        _4762 = fa_light_baked(param);\n    }\n    else\n    {\n        _4762 = _4756;\n    }\n    if (_4762)\n    {\n        int param_1 = li;\n        LightSample _7158 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _7158;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4786 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _7160 = _4786.color;\n    float _7162 = _4786.shadow;\n    bool _4789 = _4786.type == 0;\n    if (_4789 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4786.direction;\n        float _4800 = fa_shadow_factor(param_5, param_6);\n        _7162 = _4800;\n        _7160 *= _4800;\n    }\n    else\n    {\n        bool _4811 = _4786.type != 0;\n        bool _4817;\n        if (_4811)\n        {\n            _4817 = _4786.attenuation > 0.0f;\n        }\n        else\n        {\n            _4817 = _4811;\n        }\n        if (_4817)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _4786.direction;\n            float _4836 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _7162 = _4836;\n            _7160 *= _4836;\n        }\n    }\n    bool _4846 = _562_fa_ct_a.x > 0.5f;\n    bool _4852;\n    if (_4846)\n    {\n        _4852 = _4786.attenuation > 0.0f;\n    }\n    else\n    {\n        _4852 = _4846;\n    }\n    if (_4852)\n    {\n        float _4859;\n        if (_4789)\n        {\n            _4859 = 1000000000.0f;\n        }\n        else\n        {\n            _4859 = _4786._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _4786.direction;\n        float param_18 = _4859;\n        float _4877 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _7162 *= _4877;\n        _7160 *= _4877;\n    }\n    LightSample _7177 = { _4786.direction, _7160, _4786.attenuation, _7162, _4786._distance, _4786.type };\n    return _7177;\n}\n\nfloat3 fa_ltc_tangent(float3 n, float3 v)\n{\n    float3 _4920 = v - (n * dot(v, n));\n    float3 t = _4920;\n    float _4924 = dot(_4920, _4920);\n    float l2 = _4924;\n    if (_4924 < 1.0000000133514319600180897396058e-10f)\n    {\n        float3 _4934;\n        if (abs(n.z) < 0.999000012874603271484375f)\n        {\n            _4934 = cross(n, float3(0.0f, 0.0f, 1.0f));\n        }\n        else\n        {\n            _4934 = cross(n, float3(1.0f, 0.0f, 0.0f));\n        }\n        t = _4934;\n        l2 = dot(_4934, _4934);\n    }\n    return t * rsqrt(l2);\n}\n\nfloat3 fa_ltc_local(float3 t1, float3 n, float3 p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nfloat3 fa_ltc_edge_vector(float3 a, float3 b)\n{\n    float _4969 = dot(a, a);\n    float _4973 = dot(b, b);\n    if ((_4969 < 1.0000000195414813782625560981111e-24f) || (_4973 < 1.0000000195414813782625560981111e-24f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _4987 = a * rsqrt(_4969);\n    float3 _4992 = b * rsqrt(_4973);\n    float _4996 = dot(_4987, _4992);\n    float _4999 = abs(_4996);\n    float g = (((((((((((0.0416471660137176513671875f * _4999) - 0.1924748718738555908203125f) * _4999) + 0.4179156124591827392578125f) * _4999) - 0.616057217121124267578125f) * _4999) + 0.777722418308258056640625f) * _4999) - 0.999542415142059326171875f) * _4999) + 1.570791721343994140625f;\n    if (_4996 < 0.0f)\n    {\n        g = (3.1415927410125732421875f * rsqrt(max(1.0f - (_4996 * _4996), 1.0000000116860974230803549289703e-07f))) - g;\n    }\n    return cross(_4987, _4992) * g;\n}\n\nvoid fa_ltc_clip_edge(float3 a, float3 b, inout float3 sum, inout float3 leave, inout float3 enter, inout float2 seen)\n{\n    bool _5056 = a.z > 0.0f;\n    bool _5060 = b.z > 0.0f;\n    if (_5056 && _5060)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_5056 != _5060)\n        {\n            float3 _5095 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _5095.z = 0.0f;\n            if (_5056)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _5095;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _5095;\n                seen.x = 1.0f;\n            }\n            else\n            {\n                float3 param_4 = _5095;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _5095;\n                seen.y = 1.0f;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(float4 abcd, float3 p0, float3 p1, float3 p2, float3 p3)\n{\n    float3 _5144 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _5170 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _5196 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _5222 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = 0.0f.xxx;\n    float3 leave = 0.0f.xxx;\n    float3 enter = 0.0f.xxx;\n    float3 param = _5144;\n    float3 param_1 = _5170;\n    float3 param_2 = 0.0f.xxx;\n    float3 param_3 = 0.0f.xxx;\n    float3 param_4 = 0.0f.xxx;\n    float2 param_5 = 0.0f.xx;\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _5170;\n    float3 param_7 = _5196;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _5196;\n    float3 param_13 = _5222;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _5222;\n    float3 param_19 = _5144;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5f)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875f;\n}\n\nfloat fa_ltc_rect(float4 abcd, float3 center, float3 ex, float3 ey)\n{\n    float4 param = abcd;\n    float3 param_1 = (center - ex) - ey;\n    float3 param_2 = (center + ex) - ey;\n    float3 param_3 = (center + ex) + ey;\n    float3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(float4 m, float shape, float3 pc, float3 ex, float3 ey)\n{\n    if ((shape < 0.5f) || (shape > 1.5f))\n    {\n        float4 param = m;\n        float3 param_1 = pc;\n        float3 param_2 = ex;\n        float3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    float3 _5372 = (pc + (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _5396 = (pc - (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _5412 = (pc - (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float4 param_4 = m;\n    float3 param_5 = _5372;\n    float3 param_6 = (pc + (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_7 = (pc - (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_8 = _5396;\n    float4 param_9 = m;\n    float3 param_10 = _5372;\n    float3 param_11 = _5396;\n    float3 param_12 = (pc - (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    float3 param_13 = _5412;\n    float4 param_14 = m;\n    float3 param_15 = _5372;\n    float3 param_16 = _5412;\n    float3 param_17 = (pc + (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float3 param_18 = (pc + (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nfloat2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((float2(clamp((roughness - 0.0500000007450580596923828125f) * 1.0526316165924072265625f, 0.0f, 1.0f), sqrt(clamp(1.0f - ndv, 0.0f, 1.0f))) * 63.0f) + 0.5f.xx) * 0.015625f.xx;\n}\n\nfloat3 fa_area_shade(int li, float3 world_pos, float3 n, float3 v, float3 diffuse_color, float3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _5470 = fa_light_base(param);\n    int param_1 = _5470;\n    int param_2 = _5470 + 1;\n    int param_3 = _5470 + 2;\n    int param_4 = _5470 + 4;\n    float4 _5492 = fa_light_texel(param_4);\n    int param_5 = _5470 + 5;\n    float4 _5497 = fa_light_texel(param_5);\n    int param_6 = _5470 + 6;\n    float4 _5502 = fa_light_texel(param_6);\n    float _5503 = _5502.w;\n    float3 _5508 = fa_light_texel(param_1).xyz - world_pos;\n    bool _5510 = _5503 < 1.5f;\n    bool _5517;\n    if (_5510)\n    {\n        _5517 = dot(normalize(fa_light_texel(param_3).xyz), _5508) >= 0.0f;\n    }\n    else\n    {\n        _5517 = _5510;\n    }\n    if (_5517)\n    {\n        return 0.0f.xxx;\n    }\n    bool _5526 = (_5503 > 0.5f) && _5510;\n    float _5530 = _5526 ? 1.0539000034332275390625f : 1.0f;\n    float3 _5533 = _5492.xyz;\n    float _5535 = _5492.w;\n    float3 _5541 = _5497.xyz;\n    float _5543 = _5497.w;\n    float3 up = _5541 * (_5543 * _5530);\n    float _5549;\n    if (_5526)\n    {\n        _5549 = (3.1415927410125732421875f * _5535) * _5535;\n    }\n    else\n    {\n        _5549 = (4.0f * _5535) * _5543;\n    }\n    if (_5503 > 1.5f)\n    {\n        float3 _5575 = cross(_5533, -_5508);\n        float3 perp = _5575;\n        float _5579 = dot(_5575, _5575);\n        float3 _5582;\n        if (_5579 > 1.0000000133514319600180897396058e-10f)\n        {\n            _5582 = perp * rsqrt(_5579);\n        }\n        else\n        {\n            _5582 = _5541;\n        }\n        perp = _5582;\n        up = _5582 * _5543;\n    }\n    float _5603 = max(_5549, 9.9999999747524270787835121154785e-07f);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _5613 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _5613;\n    float3 param_10 = n;\n    float3 param_11 = _5508;\n    float3 _5621 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_12 = _5613;\n    float3 param_13 = n;\n    float3 param_14 = _5533 * (_5535 * _5530);\n    float3 _5629 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_15 = _5613;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float3 _5637 = fa_ltc_local(param_15, param_16, param_17);\n    float4 param_18 = float4(1.0f, 0.0f, 0.0f, 1.0f);\n    float param_19 = _5503;\n    float3 param_20 = _5621;\n    float3 param_21 = _5629;\n    float3 param_22 = _5637;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    float2 _5656 = fa_ltc_uv(param_23, param_24) * 64.0f;\n    float2 param_25 = _5656;\n    float2 param_26 = _5656 + float2(64.0f, 0.0f);\n    float4 _5666 = fa_atlas_fetch(param_26);\n    float4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _5503;\n    float3 param_29 = _5621;\n    float3 param_30 = _5629;\n    float3 param_31 = _5637;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _5666.x) + ((f90.xxx - f0) * _5666.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875f * dot(_5508, _5508)) + _5603) / _5603) * window);\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4208 = 1.0f / alpha;\n    return ((2.0f + _4208) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _4208)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat fa_layers_coat(FaLayers L, float3 l, float3 h, float vdh)\n{\n    float _4243 = max(dot(L.nc, l), 0.0f);\n    float _4249 = max(dot(L.nc, h), 0.0f);\n    float _4258 = ((_4249 * _4249) * (L.coat_a2 - 1.0f)) + 1.0f;\n    return (((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _4258) * _4258)) * (0.5f / max(lerp((2.0f * _4243) * L.coat_ndv, _4243 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _4243)) * _4243;\n}\n\nfloat3 fa_area_layers(FaLayers L, int li, float3 world_pos, float3 n, float3 v, float3 l, float3 diffuse_color, float3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    float3 param_2 = n;\n    float3 param_3 = v;\n    float3 param_4 = diffuse_color;\n    float3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _5734;\n    if (L.sheen_on)\n    {\n        _5734 = L.sheen_scale;\n    }\n    else\n    {\n        _5734 = 1.0f;\n    }\n    float3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _5734);\n    float3 _5747 = normalize(l + v);\n    int param_10 = li;\n    float3 _5758 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _5767 = max(dot(n, l), 0.0f);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _5747), 0.0f);\n        float param_13 = _5767;\n        float param_14 = ndv;\n        result += ((L.sheen * _5758) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875f) * step(9.9999997473787516355514526367188e-05f, _5767)) * _5767) * L.keep));\n    }\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_15 = L;\n        float3 param_16 = l;\n        float3 param_17 = _5747;\n        float param_18 = max(dot(v, _5747), 0.0f);\n        result += (_5758 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4111 = tdh / at;\n    float _4115 = bdh / ab;\n    float _4127 = ((_4111 * _4111) + (_4115 * _4115)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _4127) * _4127);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4307 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4386 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _4386) * _4386);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _4307);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _4307));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_17 = L;\n        float3 param_18 = l;\n        float3 param_19 = h;\n        float param_20 = vdh;\n        result += fa_layers_coat(param_17, param_18, param_19, param_20).xxx;\n    }\n    return result;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3517 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3520 = _3517.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3520 * _3520, exp2((-9.27999973297119140625f) * ndv)) * _3520) + _3517.y)) + _3517.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_562_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _562_fa_env_horizon.w).xyz;\n    }\n    float _3371 = rough * rough;\n    float _3401 = 0.60000002384185791015625f * _3371;\n    return lerp(lerp(_562_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_562_fa_env_horizon.xyz, _562_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3371)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3401, 0.0500000007450580596923828125f + _3401, d.y).xxx), ((_562_fa_env_sky.xyz + _562_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3371 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _3994;\n        if (L.aniso >= 0.0f)\n        {\n            _3994 = L.b;\n        }\n        else\n        {\n            _3994 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_3994, v), _3994), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4027 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _4027.x) + (L.f90.xxx * _4027.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _4082 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _4082.x) + _4082.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3559 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3559.x) + _3559.y.xxx);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2229_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3165 = int(_2229_fa_shadow_cfg.x + 0.5f);\n    float _3175 = dot(world - _2229_fa_shadow_eye.xyz, _2229_fa_shadow_fwd.xyz);\n    float3 tint_1 = 0.3499999940395355224609375f.xxx;\n    bool _3180 = _3165 > 0;\n    bool _3189;\n    if (_3180)\n    {\n        int param = _3165 - 1;\n        _3189 = _3175 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3189 = _3180;\n    }\n    if (_3189)\n    {\n        tint_1 = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3195 = _3165 > 1;\n        bool _3202;\n        if (_3195)\n        {\n            _3202 = _3175 > _2229_fa_shadow_split.x;\n        }\n        else\n        {\n            _3202 = _3195;\n        }\n        if (_3202)\n        {\n            tint_1 = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3208 = _3165 > 2;\n        bool _3215;\n        if (_3208)\n        {\n            _3215 = _3175 > _2229_fa_shadow_split.y;\n        }\n        else\n        {\n            _3215 = _3208;\n        }\n        if (_3215)\n        {\n            tint_1 = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3221 = _3165 > 3;\n        bool _3228;\n        if (_3221)\n        {\n            _3228 = _3175 > _2229_fa_shadow_split.z;\n        }\n        else\n        {\n            _3228 = _3221;\n        }\n        if (_3228)\n        {\n            tint_1 = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint_1, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _6860 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6860 = -_6860;\n    }\n    float3 _6218 = normalize(_562_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _6873 = { fa_world_pos, _6860, fa_world_tangent, fa_uv, fa_vertex_color, _6218, gl_FrontFacing };\n    SurfaceInput param_1 = _6873;\n    Surface _6226 = fa_standard_surface(param_1);\n    float3 _6891 = _6226.albedo;\n    float _6892 = _6226.alpha;\n    float3 _6893 = _6226.normal;\n    float _6894 = _6226.metallic;\n    float _6895 = _6226.roughness;\n    float _6896 = _6226.occlusion;\n    float3 _6897 = _6226.emission;\n    float _6898 = _6226.clearcoat;\n    float _6899 = _6226.clearcoat_roughness;\n    float3 _6900 = _6226.sheen_color;\n    float _6901 = _6226.sheen_roughness;\n    float _6902 = _6226.anisotropy;\n    float _6903 = _6226.anisotropy_rotation;\n    float _6904 = _6226.specular;\n    float _6905 = _6226.ior;\n    float3 _6906 = _6226.specular_color;\n    SurfaceInput _6881 = { fa_world_pos, _6860, fa_world_tangent, fa_uv, fa_vertex_color, _6218, gl_FrontFacing };\n    SurfaceInput param_2 = _6881;\n    Surface param_3 = _6226;\n    surface(param_2, param_3);\n    _6891 = param_3.albedo;\n    _6892 = param_3.alpha;\n    _6893 = param_3.normal;\n    _6894 = param_3.metallic;\n    _6895 = param_3.roughness;\n    _6896 = param_3.occlusion;\n    _6897 = param_3.emission;\n    _6898 = param_3.clearcoat;\n    _6899 = param_3.clearcoat_roughness;\n    _6900 = param_3.sheen_color;\n    _6901 = param_3.sheen_roughness;\n    _6902 = param_3.anisotropy;\n    _6903 = param_3.anisotropy_rotation;\n    _6904 = param_3.specular;\n    _6905 = param_3.ior;\n    _6906 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _6860;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6891 = param_6;\n    _6893 = param_7;\n    float3 result;\n    if (_562_fa_emissive.w > 0.5f)\n    {\n        result = _6891;\n    }\n    else\n    {\n        float3 _6265 = normalize(_6893);\n        float _6272 = clamp(_6894, 0.0f, 1.0f);\n        float _6276 = clamp(_6895, 0.0500000007450580596923828125f, 1.0f);\n        float _6280 = _6276 * _6276;\n        float _6284 = _6280 * _6280;\n        float _6289 = max(dot(_6265, _6218), 9.9999997473787516355514526367188e-05f);\n        float3 _6295 = _6891 * (1.0f - _6272);\n        float3 _6302 = lerp(0.039999999105930328369140625f.xxx, _6891, _6272.xxx);\n        float3 f0 = _6302;\n        SurfaceInput _6889 = { fa_world_pos, _6860, fa_world_tangent, fa_uv, fa_vertex_color, _6218, gl_FrontFacing };\n        SurfaceInput param_8 = _6889;\n        Surface _6972 = { _6891, _6892, _6893, _6894, _6895, _6896, _6897, _6898, _6899, _6900, _6901, _6902, _6903, _6904, _6905, _6906 };\n        Surface param_9 = _6972;\n        float3 param_10 = _6265;\n        float3 param_11 = _6218;\n        float param_12 = _6272;\n        float param_13 = _6276;\n        float3 param_14 = _6302;\n        FaLayers _6318 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _6265;\n        float3 lit = (fa_indirect_diffuse(param_15) * _6295) * _6896;\n        if (_6318.on)\n        {\n            lit *= _6318.base_scale;\n        }\n        int _6340 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6340; ln++)\n        {\n            int param_16 = ln;\n            int _6353 = fa_cl_light(param_16);\n            bool _6356 = fa_lm.z > 0.5f;\n            bool _6362;\n            if (_6356)\n            {\n                int param_17 = _6353;\n                _6362 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _6362 = _6356;\n            }\n            if (_6362)\n            {\n                continue;\n            }\n            int param_18 = _6353;\n            float3 param_19 = fa_world_pos;\n            float3 param_20 = _6860;\n            LightSample _6374 = fa_light_shadowed(param_18, param_19, param_20);\n            float _6382 = max(dot(_6265, _6374.direction), 0.0f);\n            float _6388 = _6374.attenuation * _6374.shadow;\n            float3 _6393 = normalize(_6374.direction + _6218);\n            float _6398 = max(dot(_6265, _6393), 0.0f);\n            float _6403 = max(dot(_6218, _6393), 0.0f);\n            bool _6410;\n            if (fa_light_is_area)\n            {\n                _6410 = !_6318.on;\n            }\n            else\n            {\n                _6410 = fa_light_is_area;\n            }\n            if (_6410)\n            {\n                int param_21 = _6353;\n                float3 param_22 = fa_world_pos;\n                float3 param_23 = _6265;\n                float3 param_24 = _6218;\n                float3 param_25 = _6295;\n                float3 param_26 = f0;\n                float param_27 = 1.0f;\n                float param_28 = _6276;\n                float param_29 = _6289;\n                float param_30 = _6388;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _6318;\n                    int param_32 = _6353;\n                    float3 param_33 = fa_world_pos;\n                    float3 param_34 = _6265;\n                    float3 param_35 = _6218;\n                    float3 param_36 = _6374.direction;\n                    float3 param_37 = _6295;\n                    float3 param_38 = f0;\n                    float param_39 = _6276;\n                    float param_40 = _6289;\n                    float param_41 = _6388;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_6318.on)\n                    {\n                        FaLayers param_42 = _6318;\n                        float3 param_43 = _6295;\n                        float3 param_44 = f0;\n                        float3 param_45 = _6265;\n                        float3 param_46 = _6218;\n                        float3 param_47 = _6374.direction;\n                        float3 param_48 = _6393;\n                        float param_49 = _6382;\n                        float param_50 = _6289;\n                        float param_51 = _6398;\n                        float param_52 = _6403;\n                        float param_53 = _6280;\n                        float param_54 = _6284;\n                        int param_55 = _6353;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _6388));\n                    }\n                    else\n                    {\n                        float _6516 = ((_6398 * _6398) * (_6284 - 1.0f)) + 1.0f;\n                        int param_56 = _6353;\n                        lit += (((_6295 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _6403, 5.0f))) * (((_6284 / ((3.1415927410125732421875f * _6516) * _6516)) * (0.5f / max(lerp((2.0f * _6382) * _6289, _6382 + _6289, _6280), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _6382))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_6382 * _6388));\n                    }\n                }\n            }\n        }\n        if (_6318.on)\n        {\n            FaLayers param_57 = _6318;\n            float3 param_58 = _6265;\n            float3 param_59 = _6218;\n            float3 param_60 = f0;\n            float param_61 = _6276;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _6896);\n        }\n        else\n        {\n            float3 param_62 = _6265;\n            float3 param_63 = _6218;\n            float3 param_64 = f0;\n            float param_65 = _6276;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _6896);\n        }\n        result = lit;\n    }\n    float3 _6611 = result;\n    float3 _6612 = _6611 + _6897;\n    result = _6612;\n    float3 param_66 = _6612;\n    float3 param_67 = fa_world_pos;\n    result = fa_shadow_debug(param_66, param_67);\n    bool _6621 = _562_fa_fog.w > 0.0f;\n    bool _6628;\n    if (!_6621)\n    {\n        _6628 = _562_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _6628 = _6621;\n    }\n    if (_6628)\n    {\n        float3 _6637 = fa_world_pos - _562_fa_camera_pos.xyz;\n        float _6643 = dot(_6637, _562_fa_fog_c.xyz);\n        bool _6647 = _562_fa_fog_c.w > 0.5f;\n        float _6648;\n        if (_6647)\n        {\n            _6648 = _6643;\n        }\n        else\n        {\n            _6648 = length(_6637);\n        }\n        float _6660 = _6648 - _562_fa_fog_b.x;\n        if (_6660 > 0.0f)\n        {\n            float _6669 = _562_fa_fog.w * _6660;\n            float tau = _6669 * _6669;\n            if (_562_fa_fog_b.y > 0.0f)\n            {\n                float _6685;\n                if (_6647)\n                {\n                    _6685 = fa_world_pos.y - (_562_fa_fog_c.y * _6643);\n                }\n                else\n                {\n                    _6685 = _562_fa_camera_pos.y;\n                }\n                float _6706 = lerp(_6685, fa_world_pos.y, clamp(_562_fa_fog_b.x / _6648, 0.0f, 1.0f));\n                float _6710 = fa_world_pos.y - _6706;\n                float _6715 = _6706 - _562_fa_fog_b.z;\n                float _6720 = fa_world_pos.y - _562_fa_fog_b.z;\n                bool _6723 = _6715 <= 0.0f;\n                bool _6724 = !_6723;\n                bool _6730;\n                if (_6724)\n                {\n                    _6730 = _562_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6730 = _6723;\n                }\n                float _6731;\n                if (_6730)\n                {\n                    _6731 = _562_fa_fog_b.y;\n                }\n                else\n                {\n                    _6731 = _562_fa_fog_b.y * exp(-min(_562_fa_fog_b.w * _6715, 80.0f));\n                }\n                bool _6758;\n                if (_6724)\n                {\n                    _6758 = _562_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6758 = _6723;\n                }\n                float _6759;\n                if (_6758)\n                {\n                    _6759 = _562_fa_fog_b.y * _6715;\n                }\n                else\n                {\n                    _6759 = (_562_fa_fog_b.y * (1.0f - exp(-min(_562_fa_fog_b.w * _6715, 80.0f)))) / _562_fa_fog_b.w;\n                }\n                bool _6784 = _6720 <= 0.0f;\n                bool _6791;\n                if (!_6784)\n                {\n                    _6791 = _562_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6791 = _6784;\n                }\n                float _6792;\n                if (_6791)\n                {\n                    _6792 = _562_fa_fog_b.y * _6720;\n                }\n                else\n                {\n                    _6792 = (_562_fa_fog_b.y * (1.0f - exp(-min(_562_fa_fog_b.w * _6720, 80.0f)))) / _562_fa_fog_b.w;\n                }\n                float _6819;\n                if (abs(_6710) < 0.001000000047497451305389404296875f)\n                {\n                    _6819 = _6731;\n                }\n                else\n                {\n                    _6819 = (_6792 - _6759) / _6710;\n                }\n                tau += (_6660 * max(_6819, 0.0f));\n            }\n            result = lerp(result, _562_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _6892);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_inst_v0 = stage_input.fa_inst_v0;\n    fa_inst_v1 = stage_input.fa_inst_v1;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_562",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2229",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_5836",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _158_fa_view_proj : packoffset(c0);\n    row_major float4x4 _158_fa_light_vp : packoffset(c4);\n    float4 _158_fa_uv_scale : packoffset(c8);\n    float4 _158_fa_time : packoffset(c9);\n    float4 _158_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _205_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_d0;\nstatic float4 fa_inst_d1;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n    float4 fa_inst_d0 : TEXCOORD11;\n    float4 fa_inst_d1 : TEXCOORD12;\n};\n\nstruct SPIRV_Cross_Output\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float3 fa_lm : TEXCOORD7;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float raise;\nstatic float4 tint;\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_205_fa_joint_rows[_196] * weights[i]);\n        r1 += (_205_fa_joint_rows[_196 + 1] * weights[i]);\n        r2 += (_205_fa_joint_rows[_196 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _422 = { mul(float4(position, 1.0f), model).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * _158_fa_uv_scale.xy, color, position };\n    return _422;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _158_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_d0 = stage_input.fa_inst_d0;\n    fa_inst_d1 = stage_input.fa_inst_d1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_inst_v0 = fa_inst_v0;\n    stage_output.fa_inst_v1 = fa_inst_v1;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _3659[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _562_fa_camera_pos : packoffset(c0);\n    float4 _562_fa_ambient : packoffset(c1);\n    float4 _562_fa_base_color : packoffset(c2);\n    float4 _562_fa_emissive : packoffset(c3);\n    float4 _562_fa_model_emissive : packoffset(c4);\n    float4 _562_fa_pbr : packoffset(c5);\n    float4 _562_fa_maps : packoffset(c6);\n    float4 _562_fa_fog : packoffset(c7);\n    float4 _562_fa_fog_b : packoffset(c8);\n    float4 _562_fa_fog_c : packoffset(c9);\n    float4 _562_fa_counts : packoffset(c10);\n    float4 _562_fa_env_sky : packoffset(c11);\n    float4 _562_fa_env_horizon : packoffset(c12);\n    float4 _562_fa_time : packoffset(c13);\n    float4 _562_fa_cl_vpx : packoffset(c14);\n    float4 _562_fa_cl_vpy : packoffset(c15);\n    float4 _562_fa_cl_vpw : packoffset(c16);\n    float4 _562_fa_cl_fwd : packoffset(c17);\n    float4 _562_fa_cl_grid : packoffset(c18);\n    float4 _562_fa_cl_info : packoffset(c19);\n    float4 _562_fa_layers_a : packoffset(c20);\n    float4 _562_fa_layers_b : packoffset(c21);\n    float4 _562_fa_layers_c : packoffset(c22);\n    float4 _562_fa_layers_d : packoffset(c23);\n    float4 _562_fa_ct_a : packoffset(c24);\n    float4 _562_fa_ct_b : packoffset(c25);\n    float4 _562_fa_ct_vpx : packoffset(c26);\n    float4 _562_fa_ct_vpy : packoffset(c27);\n    float4 _562_fa_ct_vpw : packoffset(c28);\n    float4 _562_fa_ct_fwd : packoffset(c29);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2229_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2229_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2229_fa_shadow_info[4] : packoffset(c20);\n    float4 _2229_fa_shadow_split : packoffset(c24);\n    float4 _2229_fa_shadow_cfg : packoffset(c25);\n    float4 _2229_fa_shadow_bias : packoffset(c26);\n    float4 _2229_fa_shadow_eye : packoffset(c27);\n    float4 _2229_fa_shadow_fwd : packoffset(c28);\n    float4 _2229_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _5836_boost : packoffset(c0);\n    float _5836_fa_pad0 : packoffset(c0.y);\n    float _5836_fa_pad1 : packoffset(c0.z);\n    float _5836_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_screen_tex : register(t11);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float3 fa_lm : TEXCOORD7;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\nstatic float raise;\nstatic float4 tint;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1500 = _562_fa_cl_info.x < 0.0f;\n    bool _1507;\n    if (!_1500)\n    {\n        _1507 = _562_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1507 = _1500;\n    }\n    bool _1515;\n    if (!_1507)\n    {\n        _1515 = _562_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1515 = _1507;\n    }\n    bool _1522;\n    if (!_1515)\n    {\n        _1522 = _562_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1522 = _1515;\n    }\n    bool _1529;\n    if (!_1522)\n    {\n        _1529 = _562_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1529 = _1522;\n    }\n    if (_1529)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1539 = float4(world_pos, 1.0f);\n    float _1545 = dot(_562_fa_cl_vpw, _1539);\n    if (!(_1545 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1567 = float2(dot(_562_fa_cl_vpx, _1539), dot(_562_fa_cl_vpy, _1539)) / _1545.xx;\n    int _1571 = int(_562_fa_cl_grid.x);\n    int _1575 = int(_562_fa_cl_grid.y);\n    int param = (int(_562_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_562_fa_cl_fwd.xyz, world_pos) + _562_fa_cl_fwd.w, _562_fa_cl_grid.w) / _562_fa_cl_grid.w) * _562_fa_cl_grid.z)), 0, int(_562_fa_cl_info.y) - 1) * _1575) + clamp(int(floor(((_1567.y * 0.5f) + 0.5f) * _562_fa_cl_grid.y)), 0, _1575 - 1)) * _1571)) + clamp(int(floor(((_1567.x * 0.5f) + 0.5f) * _562_fa_cl_grid.x)), 0, _1571 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1651 = fa_cluster_texel(param);\n    return int2(int(_1651.x), int(_1651.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_562_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4729 = fa_cluster_lookup(param);\n    fa_cl_slot = _4729.x;\n    fa_cl_local = _4729.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _5888 = fa_linear_to_srgb(param);\n        c = _5888;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _5896 = fa_srgb_to_linear(param_1);\n            c = _5896;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _445;\n    if (i.front_facing)\n    {\n        _445 = i.world_normal;\n    }\n    else\n    {\n        _445 = -i.world_normal;\n    }\n    float3 _469 = normalize(i.world_tangent.xyz - (_445 * dot(_445, i.world_tangent.xyz)));\n    float3 _496 = normalize(((_469 * m.x) + ((cross(_445, _469) * i.world_tangent.w) * m.y)) + (_445 * m.z));\n    float3 _499;\n    if (i.front_facing)\n    {\n        _499 = _496;\n    }\n    else\n    {\n        _499 = -_496;\n    }\n    return _499;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _562_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _5927 = fa_tex_fix(param_2, param_3);\n    float4 _7355 = base_t;\n    _7355.x = _5927.x;\n    _7355.y = _5927.y;\n    _7355.z = _5927.z;\n    base_t = _7355;\n    float4 _5941 = (_7355 * _562_fa_base_color) * i.vertex_color;\n    float3 _7180 = i.world_normal;\n    if (_562_fa_maps.z > 0.5f)\n    {\n        float param_4 = _562_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _5973 = fa_tex_fix(param_6, param_7);\n        float3 _5976 = (_5973 * 2.0f) - 1.0f.xxx;\n        float2 _5981 = _5976.xy * _562_fa_maps.x;\n        float3 _7363 = _5976;\n        _7363.x = _5981.x;\n        _7363.y = _5981.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _7363;\n        _7180 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _562_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _6009 = fa_tex_fix(param_12, param_13);\n    float4 _7366 = mrt;\n    _7366.x = _6009.x;\n    _7366.y = _6009.y;\n    _7366.z = _6009.z;\n    mrt = _7366;\n    float4 _6037 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _562_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _6037.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _6048 = fa_tex_fix(param_16, param_17);\n    float param_18 = _562_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _6078 = fa_tex_fix(param_20, param_21);\n    float _7185 = _562_fa_layers_a.x;\n    float _7186 = _562_fa_layers_a.y;\n    float _7189 = _562_fa_layers_a.z;\n    float _7188 = _562_fa_layers_b.w;\n    float _7191 = _562_fa_layers_c.x;\n    if (_562_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_562_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _7185 *= _6048.y;\n            _7186 *= _6048.z;\n            _7188 *= _6037.w;\n        }\n        if (_562_fa_layers_c.z > 1.5f)\n        {\n            _7189 *= mrt.x;\n            _7191 *= mrt.w;\n        }\n    }\n    Surface _7210 = { _5941.xyz, _5941.w, _7180, clamp(_562_fa_pbr.x * _6009.z, 0.0f, 1.0f), clamp(_562_fa_pbr.y * _6009.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_562_fa_maps.y * (_6048.x - 1.0f)), _562_fa_emissive.xyz + (_562_fa_model_emissive.xyz * _6078), _7185, _7186, _562_fa_layers_b.xyz, _7188, _7189, _562_fa_layers_a.w, _7191, _562_fa_layers_c.y, _562_fa_layers_d.xyz };\n    return _7210;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * _5836_boost);\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1731 = rect.zw - rect.xy;\n    float2 _1735 = _1731 * atlas;\n    float2 _1739 = ddx * _1735;\n    float2 _1743 = ddy * _1735;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1731), clamp(0.5f * log2(max(max(dot(_1739, _1739), dot(_1743, _1743)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1776 = _562_fa_counts.y < 0.5f;\n    bool _1783;\n    if (!_1776)\n    {\n        _1783 = _562_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1783 = _1776;\n    }\n    if (_1783)\n    {\n        return;\n    }\n    float3 _1789 = ddx(world_pos);\n    float3 _1792 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1796 = fa_cluster_texel(param);\n    int _1800 = int(_1796.w);\n    if (_1800 < 1)\n    {\n        return;\n    }\n    int _1810 = int(_562_fa_counts.y + 0.5f);\n    int param_1 = _1810;\n    float4 _1814 = fa_light_texel(param_1);\n    float2 _1817 = _1814.yz;\n    int _1821 = int(_1814.w);\n    int param_2 = _1810 + 1;\n    float4 _1826 = fa_light_texel(param_2);\n    float _1827 = _1826.x;\n    int _1833 = int(_562_fa_counts.w + 0.5f) - 1;\n    int _1837 = int(_1796.z);\n    float3 _2102;\n    for (int k = 0; k < _1800; k++)\n    {\n        int _1850 = _1837 + k;\n        int param_3 = _1821 + (_1850 >> 2);\n        int _1867 = (_1810 + 2) + (int(fa_light_texel(param_3)[_1850 & 3]) * 7);\n        int param_4 = _1867 + 6;\n        float4 _1872 = fa_light_texel(param_4);\n        if (((int(_1872.w + 0.5f) >> _1833) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1867;\n        float4 _1887 = fa_light_texel(param_5);\n        int param_6 = _1867 + 1;\n        float4 _1892 = fa_light_texel(param_6);\n        int param_7 = _1867 + 2;\n        float4 _1897 = fa_light_texel(param_7);\n        float3 _1900 = _1887.xyz;\n        float _1905 = dot(_1900, world_pos) + _1887.w;\n        float3 _1907 = _1892.xyz;\n        float _1912 = dot(_1907, world_pos) + _1892.w;\n        float3 _1914 = _1897.xyz;\n        float _1919 = dot(_1914, world_pos) + _1897.w;\n        bool _1924 = abs(_1905) > 0.5f;\n        bool _1932;\n        if (!_1924)\n        {\n            _1932 = abs(_1912) > 0.5f;\n        }\n        else\n        {\n            _1932 = _1924;\n        }\n        bool _1940;\n        if (!_1932)\n        {\n            _1940 = abs(_1919) > 0.5f;\n        }\n        else\n        {\n            _1940 = _1932;\n        }\n        if (_1940)\n        {\n            continue;\n        }\n        float _1955 = clamp(dot(geo_normal, normalize(_1914)) * _1872.z, 0.0f, 1.0f);\n        if (_1955 <= 0.0f)\n        {\n            continue;\n        }\n        float _1975 = (clamp((0.5f - abs(_1919)) * 10.0f, 0.0f, 1.0f) * _1955) * _1872.x;\n        float2 _1983 = float2(_1905 + 0.5f, 0.5f - _1912);\n        float2 _1993 = float2(dot(_1900, _1789), dot(_1907, _1789));\n        float2 _2003 = float2(dot(_1900, _1792), dot(_1907, _1792));\n        int param_8 = _1867 + 5;\n        float4 _2008 = fa_light_texel(param_8);\n        int param_9 = _1867 + 3;\n        float4 _2013 = fa_light_texel(param_9);\n        int param_10 = _1867 + 4;\n        float4 _2018 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _2008.xyz;\n        bool _2028 = _2013.z > _2013.x;\n        if (_2028)\n        {\n            float4 param_11 = _2013;\n            float2 param_12 = _1983;\n            float2 param_13 = _1817;\n            float2 param_14 = _1993;\n            float2 param_15 = _2003;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1827 > 0.5f) && (_1827 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _2054 = fa_dc_to_linear(param_16);\n                float4 _7260 = tx;\n                _7260.x = _2054.x;\n                _7260.y = _2054.y;\n                _7260.z = _2054.z;\n                tx = _7260;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1975 * tex_a) * _2008.w, 0.0f, 1.0f).xxx);\n        if (_2018.z > _2018.x)\n        {\n            float4 param_17 = _2018;\n            float2 param_18 = _1983;\n            float2 param_19 = _1817;\n            float2 param_20 = _1993;\n            float2 param_21 = _2003;\n            float4 _2098 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1827 > 1.5f)\n            {\n                float3 param_22 = _2098.xyz;\n                float3 _2108 = fa_dc_to_srgb(param_22);\n                _2102 = _2108;\n            }\n            else\n            {\n                _2102 = _2098.xyz;\n            }\n            float3 _2117 = (_2102 * 2.0f) - 1.0f.xxx;\n            float2 _2122 = _2117.xy * _1872.y;\n            float3 _2144 = (normalize(_1900) * _2122.x) + (normalize(_1907) * _2122.y);\n            float3 _2147 = normalize(normal);\n            normal = normalize(lerp(_2147, normalize((_2147 * max(_2117.z, 0.0500000007450580596923828125f)) + (_2144 - (_2147 * dot(_2147, _2144)))), clamp(_1975 * (_2028 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3585 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3592 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3595 = int(_3585);\n    int _3598 = int(_3592);\n    float _3608 = _3592 - float(_3598);\n    int _3663 = (_3595 * 9) + _3598;\n    int _3683 = ((_3595 + 1) * 9) + _3598;\n    return lerp(lerp(_3659[_3663], _3659[_3663 + 1], _3608), lerp(_3659[_3683], _3659[_3683 + 1], _3608), _3585 - float(_3595));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _7103 = false;\n    float _7104 = 1.0f;\n    float _7105 = 1.0f;\n    float _7106 = 1.0f;\n    float _7107 = 0.0f;\n    float _7108 = 0.0f;\n    float _7109 = 0.0f;\n    float _7110 = 0.0f;\n    float _7112 = 1.0f;\n    bool _7113 = false;\n    float3 _7114 = 0.0f.xxx;\n    float _7115 = 1.0f;\n    float _7116 = 1.0f;\n    float _7117 = 1.0f;\n    float _7118 = 0.0f;\n    float _7119 = 0.0f;\n    float3 _7120 = float3(1.0f, 0.0f, 0.0f);\n    float3 _7121 = float3(0.0f, 0.0f, 1.0f);\n    float _7122 = 1.0f;\n    float _7123 = 1.0f;\n    float _3734 = clamp(s.specular, 0.0f, 1.0f);\n    float _3738 = clamp(s.ior, 1.0f, 3.0f);\n    bool _3743 = (_3734 != 1.0f) || (_3738 != 1.5f);\n    bool _3752;\n    if (!_3743)\n    {\n        _3752 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _3752 = _3743;\n    }\n    if (_3752)\n    {\n        float _3760 = (_3738 - 1.0f) / (_3738 + 1.0f);\n        f0 = lerp(min((_3760 * _3760).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _3734, s.albedo, metallic.xxx);\n        _7104 = lerp(_3734, 1.0f, metallic);\n        _7103 = true;\n    }\n    float _3787 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_3787 > 0.0f)\n    {\n        float _3795 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _7107 = _3787;\n        _7108 = _3795;\n        float _3802 = _3795 * _3795;\n        _7109 = _3802;\n        _7110 = _3802 * _3802;\n        float _3814 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _7112 = _3814;\n        _7105 = 1.0f - (_3787 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _3814, 0.0f, 1.0f), 5.0f))));\n        _7103 = true;\n    }\n    float3 _3833 = max(s.sheen_color, 0.0f.xxx);\n    float _3842 = max(_3833.x, max(_3833.y, _3833.z));\n    if (_3842 > 0.0f)\n    {\n        float _3850 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _7113 = true;\n        _7114 = _3833;\n        _7115 = _3850;\n        _7116 = _3850 * _3850;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _3850;\n        float _3867 = fa_sheen_albedo(param, param_1);\n        _7118 = _3867;\n        _7117 = 1.0f - min(_3842 * _3867, 1.0f);\n        _7103 = true;\n    }\n    _7106 = _7105 * _7117;\n    float _3886 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_3886 != 0.0f)\n    {\n        float3 _3901 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _3901;\n        if (dot(_3901, _3901) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _3913 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_3913.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _3913.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _3913.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _3917 = t;\n        float3 _3918 = normalize(_3917);\n        t = _3918;\n        float3 _3943 = normalize((_3918 * cos(s.anisotropy_rotation)) + ((cross(n, _3918) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _7120 = _3943;\n        _7121 = cross(n, _3943);\n        float _3953 = roughness * roughness;\n        float _3959 = lerp(_3953, 1.0f, _3886 * _3886);\n        bool _3961 = _3886 > 0.0f;\n        _7122 = _3961 ? _3959 : _3953;\n        _7123 = _3961 ? _3953 : _3959;\n        _7119 = _3886;\n        _7103 = true;\n    }\n    FaLayers _7145 = { _7103, _7104, _7105, _7106, _7107, _7108, _7109, _7110, i.world_normal, _7112, _7113, _7114, _7115, _7116, _7117, _7118, _7119, _7120, _7121, _7122, _7123 };\n    return _7145;\n}\n\nfloat3 fa_sky_sh_coef(int k)\n{\n    float3 v = fa_env_tex.SampleLevel(fa_env_smp, float3(1.0f, 1.0f - (float((2 * (k >> 2)) + 1) * 0.25f), 1.0f - (float((2 * (k & 3)) + 1) * 0.25f)), 5.0f).xyz;\n    if (_562_fa_env_sky.w > 1.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3342 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3342;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_562_fa_env_sky.w > 0.5f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _562_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_562_fa_cl_info.x) + int(_562_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_562_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _630_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _630_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _749 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _762 = (c - (ru * hx)) - p;\n        float3 _768 = ru * (2.0f * hx);\n        float _774 = max(dot(_768, _768), 9.9999999392252902907785028219223e-09f);\n        float _778 = dot(_762, _768);\n        float t = clamp((-_778) / _774, 0.0f, 1.0f);\n        if (_749)\n        {\n            float _793 = dot(r, _768);\n            float _799 = _774 - (_793 * _793);\n            if (abs(_799) > (9.9999997473787516355514526367188e-06f * _774))\n            {\n                t = clamp(((dot(r, _762) * _793) - _778) / _799, 0.0f, 1.0f);\n            }\n        }\n        return (p + _762) + (_768 * t);\n    }\n    float3 q = p;\n    float _831 = dot(r, axis);\n    bool _839;\n    if (_749)\n    {\n        _839 = abs(_831) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _839 = _749;\n    }\n    if (_839)\n    {\n        float _849 = dot(c - p, axis) / _831;\n        if (_849 > 0.0f)\n        {\n            q = p + (r * _849);\n        }\n    }\n    float3 _862 = q - c;\n    float2 xy = float2(dot(_862, ru), dot(_862, uu));\n    if (shape > 0.5f)\n    {\n        float _877 = length(xy);\n        if (_877 > hx)\n        {\n            xy *= (hx / _877);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _511 = abs(d);\n    float _513 = _511.x;\n    float _515 = _511.y;\n    bool _516 = _513 >= _515;\n    bool _524;\n    if (_516)\n    {\n        _524 = _513 >= _511.z;\n    }\n    else\n    {\n        _524 = _516;\n    }\n    int _525;\n    if (_524)\n    {\n        _525 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _540;\n        if (_515 >= _511.z)\n        {\n            _540 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _540 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _525 = _540;\n    }\n    return _525;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _669 = dot(d, right);\n    float _673 = dot(d, up);\n    float _684;\n    if (((_669 * _669) + (_673 * _673)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _684 = atan2(_673, _669) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _684 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_684 - floor(_684)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _915 = fa_light_base(param);\n    bool _919 = _562_fa_ambient.w > 4.5f;\n    int param_1 = _915;\n    float4 _923 = fa_light_texel(param_1);\n    int param_2 = _915 + 1;\n    float4 _928 = fa_light_texel(param_2);\n    float _931 = _928.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _943 = _919 && (_931 > 2.5f);\n    fa_light_is_area = _943;\n    bool _945 = _931 < 0.5f;\n    float3 l;\n    if (_945)\n    {\n        l = normalize(_923.xyz);\n        if (_919)\n        {\n            int param_3 = _915 + 6;\n            float4 _959 = fa_light_texel(param_3);\n            if (_959.z > 0.5f)\n            {\n                int param_4 = _915 + 4;\n                float4 _969 = fa_light_texel(param_4);\n                int param_5 = _915 + 5;\n                float4 _974 = fa_light_texel(param_5);\n                float2 param_6 = _959.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _969.xyz) * _969.w, (-dot(world_pos, _974.xyz)) * _974.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _1004 = _923.xyz;\n        float3 _1006 = _1004 - world_pos;\n        float3 to_light = _1006;\n        float _1009 = length(_1006);\n        float reach = _1009;\n        bool front = true;\n        if (_943)\n        {\n            int param_8 = _915 + 7;\n            reach = max(_1009 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _915 + 4;\n            float4 _1033 = fa_light_texel(param_9);\n            int param_10 = _915 + 5;\n            float4 _1038 = fa_light_texel(param_10);\n            int param_11 = _915 + 6;\n            float4 _1043 = fa_light_texel(param_11);\n            float _1044 = _1043.w;\n            int param_12 = _915 + 2;\n            float3 _1051 = normalize(fa_light_texel(param_12).xyz);\n            bool _1053 = _1044 > 1.5f;\n            bool _1061;\n            if (!_1053)\n            {\n                _1061 = dot(_1051, to_light) < 0.0f;\n            }\n            else\n            {\n                _1061 = _1053;\n            }\n            front = _1061;\n            float3 r = 0.0f.xxx;\n            float3 _1070 = _562_fa_camera_pos.xyz - world_pos;\n            bool _1074 = dot(n, n) > 0.5f;\n            bool _1082;\n            if (_1074)\n            {\n                _1082 = dot(_1070, _1070) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _1082 = _1074;\n            }\n            if (_1082)\n            {\n                r = reflect(-normalize(_1070), normalize(n));\n            }\n            float3 param_13 = _1004;\n            float3 param_14 = _1051;\n            float3 param_15 = _1033.xyz;\n            float3 param_16 = _1038.xyz;\n            float param_17 = _1033.w;\n            float param_18 = _1038.w;\n            float param_19 = _1044;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1118 = length(to_light);\n        dist = _1118;\n        l = to_light / max(_1118, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1132 = reach / max(_923.w, 0.001000000047497451305389404296875f);\n        float _1138 = clamp(1.0f - (_1132 * _1132), 0.0f, 1.0f);\n        float _1140;\n        if (front)\n        {\n            _1140 = _1138 * _1138;\n        }\n        else\n        {\n            _1140 = 0.0f;\n        }\n        atten = _1140;\n        bool _1151 = _931 < 2.5f;\n        if ((_931 > 1.5f) && _1151)\n        {\n            int param_22 = _915 + 2;\n            float4 _1159 = fa_light_texel(param_22);\n            float _1169 = _1159.w;\n            int param_23 = _915 + 3;\n            float4 _1174 = fa_light_texel(param_23);\n            float _1175 = _1174.x;\n            float cos_inner = _1175;\n            if (_1175 > 1.5f)\n            {\n                cos_inner = lerp(_1169, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1169, cos_inner, dot(-l, normalize(_1159.xyz)));\n        }\n        if (_919 && (_931 < 1.5f))\n        {\n            int param_24 = _915 + 6;\n            float4 _1199 = fa_light_texel(param_24);\n            if (_1199.z > 0.5f)\n            {\n                float3 _1207 = -to_light;\n                int param_25 = _915 + 4;\n                int param_26 = _915 + 5;\n                float3 _1221 = fa_light_texel(param_25).xyz;\n                float3 _1225 = fa_light_texel(param_26).xyz;\n                float3 _1234 = float3(dot(_1207, _1221), dot(_1207, _1225), dot(_1207, cross(_1221, _1225)));\n                float3 param_27 = _1234;\n                int _1238 = fa_cube_face(param_27);\n                int param_28 = _1238;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1265 = float2(dot(_1234, cross(param_29, param_30)), dot(_1234, param_30)) / max(dot(_1234, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1269 = _1238 / 3;\n                float2 param_31 = _1199.xy + (float2(float(_1238 - (_1269 * 3)), float(_1269)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1265.x), 0.5f - (0.5f * _1265.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _915 + 7;\n            float4 _1299 = fa_light_texel(param_33);\n            if (_1299.z > 0.5f)\n            {\n                int param_34 = _915 + 2;\n                int param_35 = _915 + 4;\n                int param_36 = _915 + 5;\n                float2 param_37 = _1299.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_919 && _1151)\n            {\n                int param_42 = _915 + 6;\n                float4 _1346 = fa_light_texel(param_42);\n                int param_43 = _915 + 7;\n                float4 _1351 = fa_light_texel(param_43);\n                bool _1354 = _1346.z > 0.5f;\n                bool _1361;\n                if (!_1354)\n                {\n                    _1361 = _1351.z > 0.5f;\n                }\n                else\n                {\n                    _1361 = _1354;\n                }\n                if (_1361)\n                {\n                    int param_44 = _915 + 2;\n                    float4 _1368 = fa_light_texel(param_44);\n                    float3 _1372 = normalize(_1368.xyz);\n                    int param_45 = _915 + 4;\n                    float4 _1377 = fa_light_texel(param_45);\n                    int param_46 = _915 + 5;\n                    float4 _1382 = fa_light_texel(param_46);\n                    if (_1354)\n                    {\n                        float3 _1390 = -to_light;\n                        float _1397 = _1368.w;\n                        float _1413 = 0.5f / max(dot(_1390, _1372) * (sqrt(max(1.0f - (_1397 * _1397), 0.0f)) / max(_1397, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1346.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1390, _1377.xyz) * _1413), 0.5f - (dot(_1390, _1382.xyz) * _1413));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1351.z > 0.5f)\n                    {\n                        float2 param_49 = _1351.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1372;\n                        float3 param_52 = _1377.xyz;\n                        float3 param_53 = _1382.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _7091 = _928.xyz * atten;\n    if (_919)\n    {\n        _7091 *= fa_light_tint;\n    }\n    int _1482;\n    if (_945)\n    {\n        _1482 = 0;\n    }\n    else\n    {\n        _1482 = ((_931 > 1.5f) && (_931 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _7102 = { l, _7091, atten, 1.0f, dist, _1482 };\n    return _7102;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2219;\n    if (i == 0)\n    {\n        _2219 = _2229_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2235;\n        if (i == 1)\n        {\n            _2235 = _2229_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2243;\n            if (i == 2)\n            {\n                _2243 = _2229_fa_shadow_split.z;\n            }\n            else\n            {\n                _2243 = _2229_fa_shadow_split.w;\n            }\n            _2235 = _2243;\n        }\n        _2219 = _2235;\n    }\n    return _2219;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2276 = fa_shadow_depth(param, param_1);\n    float _2280;\n    if (conv.x < 0.5f)\n    {\n        _2280 = _2276;\n    }\n    else\n    {\n        _2280 = (conv.y * conv.z) / (conv.z - (_2276 * (conv.z - conv.y)));\n    }\n    return _2280;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2207 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2207), sin(_2207)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2326 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2335;\n        if (k < 0.0f)\n        {\n            _2335 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2335 = k;\n        }\n        float _2355 = clamp((_2335 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2326;\n            float2 _2374 = fa_shadow_vogel(param_3, param_4, param_5) * _2355;\n            float2 param_6 = uv + (_2374 * _2229_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2386 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2386 < (zr - (length(_2374) * plane)))\n            {\n                sum += _2386;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2412 = sum / cnt;\n        float _2422;\n        if (k < 0.0f)\n        {\n            _2422 = (-k) / max(_2412, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2422 = k;\n        }\n        radius = clamp(((max(zr - _2412, 0.0f) * unit) * _2422) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2444 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2444; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2444;\n        float param_11 = _2326;\n        float2 _2463 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2463 * _2229_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2463) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2444);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2505 = max(_2229_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2510 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2516 = sqrt(1.0f - (_2510 * _2510));\n    float _2523 = min(_2516 / max(_2510, 0.20000000298023223876953125f), 4.0f);\n    float _2528;\n    if (_2229_fa_shadow_bias.y > 0.0f)\n    {\n        _2528 = _2229_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2528 = 1.5f * _2229_fa_shadow_info[ci].x;\n    }\n    float4 _2553 = mul(float4(world + (n * (_2528 * _2516)), 1.0f), _2229_fa_shadow_mat[ci]);\n    float _2560 = _2553.x;\n    bool _2563 = _2560 < _2229_fa_shadow_rect[ci].x;\n    bool _2572;\n    if (!_2563)\n    {\n        _2572 = _2560 > _2229_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2572 = _2563;\n    }\n    bool _2581;\n    if (!_2572)\n    {\n        _2581 = _2553.y < _2229_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2581 = _2572;\n    }\n    bool _2590;\n    if (!_2581)\n    {\n        _2590 = _2553.y > _2229_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2590 = _2581;\n    }\n    bool _2597;\n    if (!_2590)\n    {\n        _2597 = _2553.z > 1.0f;\n    }\n    else\n    {\n        _2597 = _2590;\n    }\n    if (_2597)\n    {\n        return -1.0f;\n    }\n    float _2605;\n    if (_2229_fa_shadow_bias.x > 0.0f)\n    {\n        _2605 = _2229_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2605 = 1.5f * _2229_fa_shadow_info[ci].x;\n    }\n    float2 param = _2553.xy;\n    float4 param_1 = _2229_fa_shadow_rect[ci];\n    float param_2 = _2553.z - ((_2605 * (1.0f + (0.5f * _2523))) / _2505);\n    float param_3 = _2229_fa_shadow_info[ci].x;\n    float param_4 = _2505;\n    float param_5 = _2505 * 0.25f;\n    float param_6 = ((_2229_fa_shadow_info[ci].x * min(_2523, 3.0f)) * 0.5f) / _2505;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2229_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2229_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_562_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2983 = int(_2229_fa_shadow_cfg.x + 0.5f);\n    if (_2983 < 1)\n    {\n        return 1.0f;\n    }\n    float _2998 = dot(world - _2229_fa_shadow_eye.xyz, _2229_fa_shadow_fwd.xyz);\n    int param = _2983 - 1;\n    if (_2998 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _3010 = _2983 > 1;\n    bool _3017;\n    if (_3010)\n    {\n        _3017 = _2998 > _2229_fa_shadow_split.x;\n    }\n    else\n    {\n        _3017 = _3010;\n    }\n    if (_3017)\n    {\n        ci = 1;\n    }\n    bool _3021 = _2983 > 2;\n    bool _3028;\n    if (_3021)\n    {\n        _3028 = _2998 > _2229_fa_shadow_split.y;\n    }\n    else\n    {\n        _3028 = _3021;\n    }\n    if (_3028)\n    {\n        ci = 2;\n    }\n    bool _3032 = _2983 > 3;\n    bool _3039;\n    if (_3032)\n    {\n        _3039 = _2998 > _2229_fa_shadow_split.z;\n    }\n    else\n    {\n        _3039 = _3032;\n    }\n    if (_3039)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2983)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _3065 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3065;\n        if (_3065 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2229_fa_shadow_cfg.y > 0.0f)\n    {\n        float _3090;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3090 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3090 = _2229_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _3109 = _2229_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3090, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _3120 = clamp((_2998 - (fa_shadow_split_at(param_7) - _3109)) / _3109, 0.0f, 1.0f);\n        if (_3120 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2983)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _3141 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3141;\n                if (_3141 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _3120);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2663 = _562_fa_pbr.z < 0.5f;\n    bool _2670;\n    if (!_2663)\n    {\n        _2670 = _2229_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2670 = _2663;\n    }\n    if (_2670)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2229_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2683 = fa_light_texel(param);\n    float _2684 = _2683.x;\n    if (_2684 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2693 = int(_2684 + 0.5f);\n    int param_1 = _2693;\n    float4 _2697 = fa_light_texel(param_1);\n    int param_2 = _2693 + 1;\n    float4 _2702 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2705 = _2697.y;\n    if (_2705 > 0.0f)\n    {\n        float _2722 = 1.0f - smoothstep(0.75f * _2705, _2705, length(world - _2229_fa_shadow_eye.xyz));\n        fade = _2722;\n        if (_2722 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2697.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2746 = (_2693 + 2) + (face * 6);\n    int param_4 = _2746;\n    int param_5 = _2746 + 1;\n    int param_6 = _2746 + 3;\n    float4 _2760 = fa_light_texel(param_6);\n    int param_7 = _2746 + 4;\n    float4 _2765 = fa_light_texel(param_7);\n    int param_8 = _2746 + 5;\n    float4 _2770 = fa_light_texel(param_8);\n    float _2782 = _2770.x * max(dot(_2760, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2787 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2810 = clamp(dot(n, _2760.xyz), -1.0f, 1.0f);\n    float _2829 = min(sqrt(1.0f - (_2810 * _2810)) / max(abs(dot(n, world - lpos)) / max(dot(_2760, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2832 = _2702.y;\n    float _2834;\n    if (_2832 > 0.0f)\n    {\n        _2834 = _2832;\n    }\n    else\n    {\n        _2834 = 1.5f * _2782;\n    }\n    float4 _2854 = float4(world + (n * (_2834 * sqrt(1.0f - (_2787 * _2787)))), 1.0f);\n    float _2858 = dot(_2760, _2854);\n    float _2861 = _2770.y;\n    if (_2858 < _2861)\n    {\n        return 1.0f;\n    }\n    float2 _2876 = float2(dot(fa_light_texel(param_4), _2854), dot(fa_light_texel(param_5), _2854)) / _2858.xx;\n    float _2878 = _2876.x;\n    bool _2881 = _2878 < _2765.x;\n    bool _2890;\n    if (!_2881)\n    {\n        _2890 = _2878 > _2765.z;\n    }\n    else\n    {\n        _2890 = _2881;\n    }\n    bool _2899;\n    if (!_2890)\n    {\n        _2899 = _2876.y < _2765.y;\n    }\n    else\n    {\n        _2899 = _2890;\n    }\n    bool _2908;\n    if (!_2899)\n    {\n        _2908 = _2876.y > _2765.w;\n    }\n    else\n    {\n        _2908 = _2899;\n    }\n    if (_2908)\n    {\n        return 1.0f;\n    }\n    float _2914 = _2702.x;\n    float _2916;\n    if (_2914 > 0.0f)\n    {\n        _2916 = _2914;\n    }\n    else\n    {\n        _2916 = 1.5f * _2782;\n    }\n    float2 param_9 = _2876;\n    float4 param_10 = _2765;\n    float param_11 = _2858 - (_2916 * (1.0f + (0.5f * _2829)));\n    float param_12 = _2782;\n    float param_13 = 1.0f;\n    float param_14 = _2770.z * 0.25f;\n    float param_15 = (_2782 * min(_2829, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2861, _2770.z);\n    int param_17 = int(_2697.z + 0.5f);\n    float param_18 = _2697.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _4471 = _562_fa_ct_a.x < 0.5f;\n    bool _4478;\n    if (!_4471)\n    {\n        _4478 = _2229_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _4478 = _4471;\n    }\n    if (_4478)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2229_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _4491 = fa_light_texel(param);\n    float _4492 = _4491.y;\n    float len = _4492;\n    if (_4492 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4504 = length(world - _562_fa_camera_pos.xyz);\n    float _4514 = 1.0f - smoothstep(0.5f * _562_fa_ct_b.x, _562_fa_ct_b.x, _4504);\n    if (_4514 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4520 = len;\n    float _4523 = min(_4520, 0.89999997615814208984375f * dist);\n    len = _4523;\n    float _4528 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _4504);\n    float _4533 = _4528 + (0.5f * _4523);\n    float3 _4539 = world + (gn * _4528);\n    float _4541 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _4605;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4556 = (float(k) + _4541) * 0.083333335816860198974609375f;\n        float3 _4564 = _4539 + (l * (_4556 * len));\n        float4 _4570 = float4(_4564, 1.0f);\n        float _4576 = dot(_562_fa_ct_vpw, _4570);\n        if (_4576 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _4596 = float2(dot(_562_fa_ct_vpx, _4570), dot(_562_fa_ct_vpy, _4570)) / _4576.xx;\n        float _4600 = _4596.x * 0.5f;\n        float _4601 = _4600 + 0.5f;\n        if (_562_fa_ct_a.y > 0.5f)\n        {\n            _4605 = (_4596.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _4605 = 0.5f - (_4596.y * 0.5f);\n        }\n        bool _4621 = _4601 < 0.0f;\n        bool _4628;\n        if (!_4621)\n        {\n            _4628 = _4601 >= 1.0f;\n        }\n        else\n        {\n            _4628 = _4621;\n        }\n        bool _4635;\n        if (!_4628)\n        {\n            _4635 = _4605 < 0.0f;\n        }\n        else\n        {\n            _4635 = _4628;\n        }\n        bool _4642;\n        if (!_4635)\n        {\n            _4642 = _4605 >= 1.0f;\n        }\n        else\n        {\n            _4642 = _4635;\n        }\n        if (_4642)\n        {\n            break;\n        }\n        float4 _4661 = fa_screen_tex.Load(int3(int2(float2(_4601, _4605) * _562_fa_ct_a.zw), 0));\n        if (_4661.w < 0.5f)\n        {\n            continue;\n        }\n        float _4680 = (dot(_562_fa_ct_fwd.xyz, _4564) + _562_fa_ct_fwd.w) - _4661.x;\n        if ((_4680 > _4528) && (_4680 < _4533))\n        {\n            occ = max(occ, (1.0f - (_4556 * _4556)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_4601, 0.5f - _4600), min(_4605, 1.0f - _4605))));\n        }\n    }\n    return 1.0f - (occ * _4514);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _4756 = fa_lm.z > 0.5f;\n    bool _4762;\n    if (_4756)\n    {\n        int param = li;\n        _4762 = fa_light_baked(param);\n    }\n    else\n    {\n        _4762 = _4756;\n    }\n    if (_4762)\n    {\n        int param_1 = li;\n        LightSample _7158 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _7158;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4786 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _7160 = _4786.color;\n    float _7162 = _4786.shadow;\n    bool _4789 = _4786.type == 0;\n    if (_4789 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4786.direction;\n        float _4800 = fa_shadow_factor(param_5, param_6);\n        _7162 = _4800;\n        _7160 *= _4800;\n    }\n    else\n    {\n        bool _4811 = _4786.type != 0;\n        bool _4817;\n        if (_4811)\n        {\n            _4817 = _4786.attenuation > 0.0f;\n        }\n        else\n        {\n            _4817 = _4811;\n        }\n        if (_4817)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _4786.direction;\n            float _4836 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _7162 = _4836;\n            _7160 *= _4836;\n        }\n    }\n    bool _4846 = _562_fa_ct_a.x > 0.5f;\n    bool _4852;\n    if (_4846)\n    {\n        _4852 = _4786.attenuation > 0.0f;\n    }\n    else\n    {\n        _4852 = _4846;\n    }\n    if (_4852)\n    {\n        float _4859;\n        if (_4789)\n        {\n            _4859 = 1000000000.0f;\n        }\n        else\n        {\n            _4859 = _4786._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _4786.direction;\n        float param_18 = _4859;\n        float _4877 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _7162 *= _4877;\n        _7160 *= _4877;\n    }\n    LightSample _7177 = { _4786.direction, _7160, _4786.attenuation, _7162, _4786._distance, _4786.type };\n    return _7177;\n}\n\nfloat3 fa_ltc_tangent(float3 n, float3 v)\n{\n    float3 _4920 = v - (n * dot(v, n));\n    float3 t = _4920;\n    float _4924 = dot(_4920, _4920);\n    float l2 = _4924;\n    if (_4924 < 1.0000000133514319600180897396058e-10f)\n    {\n        float3 _4934;\n        if (abs(n.z) < 0.999000012874603271484375f)\n        {\n            _4934 = cross(n, float3(0.0f, 0.0f, 1.0f));\n        }\n        else\n        {\n            _4934 = cross(n, float3(1.0f, 0.0f, 0.0f));\n        }\n        t = _4934;\n        l2 = dot(_4934, _4934);\n    }\n    return t * rsqrt(l2);\n}\n\nfloat3 fa_ltc_local(float3 t1, float3 n, float3 p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nfloat3 fa_ltc_edge_vector(float3 a, float3 b)\n{\n    float _4969 = dot(a, a);\n    float _4973 = dot(b, b);\n    if ((_4969 < 1.0000000195414813782625560981111e-24f) || (_4973 < 1.0000000195414813782625560981111e-24f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _4987 = a * rsqrt(_4969);\n    float3 _4992 = b * rsqrt(_4973);\n    float _4996 = dot(_4987, _4992);\n    float _4999 = abs(_4996);\n    float g = (((((((((((0.0416471660137176513671875f * _4999) - 0.1924748718738555908203125f) * _4999) + 0.4179156124591827392578125f) * _4999) - 0.616057217121124267578125f) * _4999) + 0.777722418308258056640625f) * _4999) - 0.999542415142059326171875f) * _4999) + 1.570791721343994140625f;\n    if (_4996 < 0.0f)\n    {\n        g = (3.1415927410125732421875f * rsqrt(max(1.0f - (_4996 * _4996), 1.0000000116860974230803549289703e-07f))) - g;\n    }\n    return cross(_4987, _4992) * g;\n}\n\nvoid fa_ltc_clip_edge(float3 a, float3 b, inout float3 sum, inout float3 leave, inout float3 enter, inout float2 seen)\n{\n    bool _5056 = a.z > 0.0f;\n    bool _5060 = b.z > 0.0f;\n    if (_5056 && _5060)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_5056 != _5060)\n        {\n            float3 _5095 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _5095.z = 0.0f;\n            if (_5056)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _5095;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _5095;\n                seen.x = 1.0f;\n            }\n            else\n            {\n                float3 param_4 = _5095;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _5095;\n                seen.y = 1.0f;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(float4 abcd, float3 p0, float3 p1, float3 p2, float3 p3)\n{\n    float3 _5144 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _5170 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _5196 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _5222 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = 0.0f.xxx;\n    float3 leave = 0.0f.xxx;\n    float3 enter = 0.0f.xxx;\n    float3 param = _5144;\n    float3 param_1 = _5170;\n    float3 param_2 = 0.0f.xxx;\n    float3 param_3 = 0.0f.xxx;\n    float3 param_4 = 0.0f.xxx;\n    float2 param_5 = 0.0f.xx;\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _5170;\n    float3 param_7 = _5196;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _5196;\n    float3 param_13 = _5222;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _5222;\n    float3 param_19 = _5144;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5f)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875f;\n}\n\nfloat fa_ltc_rect(float4 abcd, float3 center, float3 ex, float3 ey)\n{\n    float4 param = abcd;\n    float3 param_1 = (center - ex) - ey;\n    float3 param_2 = (center + ex) - ey;\n    float3 param_3 = (center + ex) + ey;\n    float3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(float4 m, float shape, float3 pc, float3 ex, float3 ey)\n{\n    if ((shape < 0.5f) || (shape > 1.5f))\n    {\n        float4 param = m;\n        float3 param_1 = pc;\n        float3 param_2 = ex;\n        float3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    float3 _5372 = (pc + (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _5396 = (pc - (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _5412 = (pc - (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float4 param_4 = m;\n    float3 param_5 = _5372;\n    float3 param_6 = (pc + (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_7 = (pc - (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_8 = _5396;\n    float4 param_9 = m;\n    float3 param_10 = _5372;\n    float3 param_11 = _5396;\n    float3 param_12 = (pc - (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    float3 param_13 = _5412;\n    float4 param_14 = m;\n    float3 param_15 = _5372;\n    float3 param_16 = _5412;\n    float3 param_17 = (pc + (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float3 param_18 = (pc + (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nfloat2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((float2(clamp((roughness - 0.0500000007450580596923828125f) * 1.0526316165924072265625f, 0.0f, 1.0f), sqrt(clamp(1.0f - ndv, 0.0f, 1.0f))) * 63.0f) + 0.5f.xx) * 0.015625f.xx;\n}\n\nfloat3 fa_area_shade(int li, float3 world_pos, float3 n, float3 v, float3 diffuse_color, float3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _5470 = fa_light_base(param);\n    int param_1 = _5470;\n    int param_2 = _5470 + 1;\n    int param_3 = _5470 + 2;\n    int param_4 = _5470 + 4;\n    float4 _5492 = fa_light_texel(param_4);\n    int param_5 = _5470 + 5;\n    float4 _5497 = fa_light_texel(param_5);\n    int param_6 = _5470 + 6;\n    float4 _5502 = fa_light_texel(param_6);\n    float _5503 = _5502.w;\n    float3 _5508 = fa_light_texel(param_1).xyz - world_pos;\n    bool _5510 = _5503 < 1.5f;\n    bool _5517;\n    if (_5510)\n    {\n        _5517 = dot(normalize(fa_light_texel(param_3).xyz), _5508) >= 0.0f;\n    }\n    else\n    {\n        _5517 = _5510;\n    }\n    if (_5517)\n    {\n        return 0.0f.xxx;\n    }\n    bool _5526 = (_5503 > 0.5f) && _5510;\n    float _5530 = _5526 ? 1.0539000034332275390625f : 1.0f;\n    float3 _5533 = _5492.xyz;\n    float _5535 = _5492.w;\n    float3 _5541 = _5497.xyz;\n    float _5543 = _5497.w;\n    float3 up = _5541 * (_5543 * _5530);\n    float _5549;\n    if (_5526)\n    {\n        _5549 = (3.1415927410125732421875f * _5535) * _5535;\n    }\n    else\n    {\n        _5549 = (4.0f * _5535) * _5543;\n    }\n    if (_5503 > 1.5f)\n    {\n        float3 _5575 = cross(_5533, -_5508);\n        float3 perp = _5575;\n        float _5579 = dot(_5575, _5575);\n        float3 _5582;\n        if (_5579 > 1.0000000133514319600180897396058e-10f)\n        {\n            _5582 = perp * rsqrt(_5579);\n        }\n        else\n        {\n            _5582 = _5541;\n        }\n        perp = _5582;\n        up = _5582 * _5543;\n    }\n    float _5603 = max(_5549, 9.9999999747524270787835121154785e-07f);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _5613 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _5613;\n    float3 param_10 = n;\n    float3 param_11 = _5508;\n    float3 _5621 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_12 = _5613;\n    float3 param_13 = n;\n    float3 param_14 = _5533 * (_5535 * _5530);\n    float3 _5629 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_15 = _5613;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float3 _5637 = fa_ltc_local(param_15, param_16, param_17);\n    float4 param_18 = float4(1.0f, 0.0f, 0.0f, 1.0f);\n    float param_19 = _5503;\n    float3 param_20 = _5621;\n    float3 param_21 = _5629;\n    float3 param_22 = _5637;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    float2 _5656 = fa_ltc_uv(param_23, param_24) * 64.0f;\n    float2 param_25 = _5656;\n    float2 param_26 = _5656 + float2(64.0f, 0.0f);\n    float4 _5666 = fa_atlas_fetch(param_26);\n    float4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _5503;\n    float3 param_29 = _5621;\n    float3 param_30 = _5629;\n    float3 param_31 = _5637;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _5666.x) + ((f90.xxx - f0) * _5666.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875f * dot(_5508, _5508)) + _5603) / _5603) * window);\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4208 = 1.0f / alpha;\n    return ((2.0f + _4208) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _4208)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat fa_layers_coat(FaLayers L, float3 l, float3 h, float vdh)\n{\n    float _4243 = max(dot(L.nc, l), 0.0f);\n    float _4249 = max(dot(L.nc, h), 0.0f);\n    float _4258 = ((_4249 * _4249) * (L.coat_a2 - 1.0f)) + 1.0f;\n    return (((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _4258) * _4258)) * (0.5f / max(lerp((2.0f * _4243) * L.coat_ndv, _4243 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _4243)) * _4243;\n}\n\nfloat3 fa_area_layers(FaLayers L, int li, float3 world_pos, float3 n, float3 v, float3 l, float3 diffuse_color, float3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    float3 param_2 = n;\n    float3 param_3 = v;\n    float3 param_4 = diffuse_color;\n    float3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _5734;\n    if (L.sheen_on)\n    {\n        _5734 = L.sheen_scale;\n    }\n    else\n    {\n        _5734 = 1.0f;\n    }\n    float3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _5734);\n    float3 _5747 = normalize(l + v);\n    int param_10 = li;\n    float3 _5758 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _5767 = max(dot(n, l), 0.0f);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _5747), 0.0f);\n        float param_13 = _5767;\n        float param_14 = ndv;\n        result += ((L.sheen * _5758) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875f) * step(9.9999997473787516355514526367188e-05f, _5767)) * _5767) * L.keep));\n    }\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_15 = L;\n        float3 param_16 = l;\n        float3 param_17 = _5747;\n        float param_18 = max(dot(v, _5747), 0.0f);\n        result += (_5758 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4111 = tdh / at;\n    float _4115 = bdh / ab;\n    float _4127 = ((_4111 * _4111) + (_4115 * _4115)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _4127) * _4127);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4307 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4386 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _4386) * _4386);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _4307);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _4307));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_17 = L;\n        float3 param_18 = l;\n        float3 param_19 = h;\n        float param_20 = vdh;\n        result += fa_layers_coat(param_17, param_18, param_19, param_20).xxx;\n    }\n    return result;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3517 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3520 = _3517.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3520 * _3520, exp2((-9.27999973297119140625f) * ndv)) * _3520) + _3517.y)) + _3517.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_562_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _562_fa_env_horizon.w).xyz;\n    }\n    float _3371 = rough * rough;\n    float _3401 = 0.60000002384185791015625f * _3371;\n    return lerp(lerp(_562_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_562_fa_env_horizon.xyz, _562_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3371)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3401, 0.0500000007450580596923828125f + _3401, d.y).xxx), ((_562_fa_env_sky.xyz + _562_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3371 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _3994;\n        if (L.aniso >= 0.0f)\n        {\n            _3994 = L.b;\n        }\n        else\n        {\n            _3994 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_3994, v), _3994), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4027 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _4027.x) + (L.f90.xxx * _4027.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _4082 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _4082.x) + _4082.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3559 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3559.x) + _3559.y.xxx);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2229_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3165 = int(_2229_fa_shadow_cfg.x + 0.5f);\n    float _3175 = dot(world - _2229_fa_shadow_eye.xyz, _2229_fa_shadow_fwd.xyz);\n    float3 tint_1 = 0.3499999940395355224609375f.xxx;\n    bool _3180 = _3165 > 0;\n    bool _3189;\n    if (_3180)\n    {\n        int param = _3165 - 1;\n        _3189 = _3175 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3189 = _3180;\n    }\n    if (_3189)\n    {\n        tint_1 = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3195 = _3165 > 1;\n        bool _3202;\n        if (_3195)\n        {\n            _3202 = _3175 > _2229_fa_shadow_split.x;\n        }\n        else\n        {\n            _3202 = _3195;\n        }\n        if (_3202)\n        {\n            tint_1 = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3208 = _3165 > 2;\n        bool _3215;\n        if (_3208)\n        {\n            _3215 = _3175 > _2229_fa_shadow_split.y;\n        }\n        else\n        {\n            _3215 = _3208;\n        }\n        if (_3215)\n        {\n            tint_1 = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3221 = _3165 > 3;\n        bool _3228;\n        if (_3221)\n        {\n            _3228 = _3175 > _2229_fa_shadow_split.z;\n        }\n        else\n        {\n            _3228 = _3221;\n        }\n        if (_3228)\n        {\n            tint_1 = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint_1, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _6860 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6860 = -_6860;\n    }\n    float3 _6218 = normalize(_562_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _6873 = { fa_world_pos, _6860, fa_world_tangent, fa_uv, fa_vertex_color, _6218, gl_FrontFacing };\n    SurfaceInput param_1 = _6873;\n    Surface _6226 = fa_standard_surface(param_1);\n    float3 _6891 = _6226.albedo;\n    float _6892 = _6226.alpha;\n    float3 _6893 = _6226.normal;\n    float _6894 = _6226.metallic;\n    float _6895 = _6226.roughness;\n    float _6896 = _6226.occlusion;\n    float3 _6897 = _6226.emission;\n    float _6898 = _6226.clearcoat;\n    float _6899 = _6226.clearcoat_roughness;\n    float3 _6900 = _6226.sheen_color;\n    float _6901 = _6226.sheen_roughness;\n    float _6902 = _6226.anisotropy;\n    float _6903 = _6226.anisotropy_rotation;\n    float _6904 = _6226.specular;\n    float _6905 = _6226.ior;\n    float3 _6906 = _6226.specular_color;\n    SurfaceInput _6881 = { fa_world_pos, _6860, fa_world_tangent, fa_uv, fa_vertex_color, _6218, gl_FrontFacing };\n    SurfaceInput param_2 = _6881;\n    Surface param_3 = _6226;\n    surface(param_2, param_3);\n    _6891 = param_3.albedo;\n    _6892 = param_3.alpha;\n    _6893 = param_3.normal;\n    _6894 = param_3.metallic;\n    _6895 = param_3.roughness;\n    _6896 = param_3.occlusion;\n    _6897 = param_3.emission;\n    _6898 = param_3.clearcoat;\n    _6899 = param_3.clearcoat_roughness;\n    _6900 = param_3.sheen_color;\n    _6901 = param_3.sheen_roughness;\n    _6902 = param_3.anisotropy;\n    _6903 = param_3.anisotropy_rotation;\n    _6904 = param_3.specular;\n    _6905 = param_3.ior;\n    _6906 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _6860;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6891 = param_6;\n    _6893 = param_7;\n    float3 result;\n    if (_562_fa_emissive.w > 0.5f)\n    {\n        result = _6891;\n    }\n    else\n    {\n        float3 _6265 = normalize(_6893);\n        float _6272 = clamp(_6894, 0.0f, 1.0f);\n        float _6276 = clamp(_6895, 0.0500000007450580596923828125f, 1.0f);\n        float _6280 = _6276 * _6276;\n        float _6284 = _6280 * _6280;\n        float _6289 = max(dot(_6265, _6218), 9.9999997473787516355514526367188e-05f);\n        float3 _6295 = _6891 * (1.0f - _6272);\n        float3 _6302 = lerp(0.039999999105930328369140625f.xxx, _6891, _6272.xxx);\n        float3 f0 = _6302;\n        SurfaceInput _6889 = { fa_world_pos, _6860, fa_world_tangent, fa_uv, fa_vertex_color, _6218, gl_FrontFacing };\n        SurfaceInput param_8 = _6889;\n        Surface _6972 = { _6891, _6892, _6893, _6894, _6895, _6896, _6897, _6898, _6899, _6900, _6901, _6902, _6903, _6904, _6905, _6906 };\n        Surface param_9 = _6972;\n        float3 param_10 = _6265;\n        float3 param_11 = _6218;\n        float param_12 = _6272;\n        float param_13 = _6276;\n        float3 param_14 = _6302;\n        FaLayers _6318 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _6265;\n        float3 lit = (fa_indirect_diffuse(param_15) * _6295) * _6896;\n        if (_6318.on)\n        {\n            lit *= _6318.base_scale;\n        }\n        int _6340 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6340; ln++)\n        {\n            int param_16 = ln;\n            int _6353 = fa_cl_light(param_16);\n            bool _6356 = fa_lm.z > 0.5f;\n            bool _6362;\n            if (_6356)\n            {\n                int param_17 = _6353;\n                _6362 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _6362 = _6356;\n            }\n            if (_6362)\n            {\n                continue;\n            }\n            int param_18 = _6353;\n            float3 param_19 = fa_world_pos;\n            float3 param_20 = _6860;\n            LightSample _6374 = fa_light_shadowed(param_18, param_19, param_20);\n            float _6382 = max(dot(_6265, _6374.direction), 0.0f);\n            float _6388 = _6374.attenuation * _6374.shadow;\n            float3 _6393 = normalize(_6374.direction + _6218);\n            float _6398 = max(dot(_6265, _6393), 0.0f);\n            float _6403 = max(dot(_6218, _6393), 0.0f);\n            bool _6410;\n            if (fa_light_is_area)\n            {\n                _6410 = !_6318.on;\n            }\n            else\n            {\n                _6410 = fa_light_is_area;\n            }\n            if (_6410)\n            {\n                int param_21 = _6353;\n                float3 param_22 = fa_world_pos;\n                float3 param_23 = _6265;\n                float3 param_24 = _6218;\n                float3 param_25 = _6295;\n                float3 param_26 = f0;\n                float param_27 = 1.0f;\n                float param_28 = _6276;\n                float param_29 = _6289;\n                float param_30 = _6388;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _6318;\n                    int param_32 = _6353;\n                    float3 param_33 = fa_world_pos;\n                    float3 param_34 = _6265;\n                    float3 param_35 = _6218;\n                    float3 param_36 = _6374.direction;\n                    float3 param_37 = _6295;\n                    float3 param_38 = f0;\n                    float param_39 = _6276;\n                    float param_40 = _6289;\n                    float param_41 = _6388;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_6318.on)\n                    {\n                        FaLayers param_42 = _6318;\n                        float3 param_43 = _6295;\n                        float3 param_44 = f0;\n                        float3 param_45 = _6265;\n                        float3 param_46 = _6218;\n                        float3 param_47 = _6374.direction;\n                        float3 param_48 = _6393;\n                        float param_49 = _6382;\n                        float param_50 = _6289;\n                        float param_51 = _6398;\n                        float param_52 = _6403;\n                        float param_53 = _6280;\n                        float param_54 = _6284;\n                        int param_55 = _6353;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _6388));\n                    }\n                    else\n                    {\n                        float _6516 = ((_6398 * _6398) * (_6284 - 1.0f)) + 1.0f;\n                        int param_56 = _6353;\n                        lit += (((_6295 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _6403, 5.0f))) * (((_6284 / ((3.1415927410125732421875f * _6516) * _6516)) * (0.5f / max(lerp((2.0f * _6382) * _6289, _6382 + _6289, _6280), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _6382))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_6382 * _6388));\n                    }\n                }\n            }\n        }\n        if (_6318.on)\n        {\n            FaLayers param_57 = _6318;\n            float3 param_58 = _6265;\n            float3 param_59 = _6218;\n            float3 param_60 = f0;\n            float param_61 = _6276;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _6896);\n        }\n        else\n        {\n            float3 param_62 = _6265;\n            float3 param_63 = _6218;\n            float3 param_64 = f0;\n            float param_65 = _6276;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _6896);\n        }\n        result = lit;\n    }\n    float3 _6611 = result;\n    float3 _6612 = _6611 + _6897;\n    result = _6612;\n    float3 param_66 = _6612;\n    float3 param_67 = fa_world_pos;\n    result = fa_shadow_debug(param_66, param_67);\n    bool _6621 = _562_fa_fog.w > 0.0f;\n    bool _6628;\n    if (!_6621)\n    {\n        _6628 = _562_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _6628 = _6621;\n    }\n    if (_6628)\n    {\n        float3 _6637 = fa_world_pos - _562_fa_camera_pos.xyz;\n        float _6643 = dot(_6637, _562_fa_fog_c.xyz);\n        bool _6647 = _562_fa_fog_c.w > 0.5f;\n        float _6648;\n        if (_6647)\n        {\n            _6648 = _6643;\n        }\n        else\n        {\n            _6648 = length(_6637);\n        }\n        float _6660 = _6648 - _562_fa_fog_b.x;\n        if (_6660 > 0.0f)\n        {\n            float _6669 = _562_fa_fog.w * _6660;\n            float tau = _6669 * _6669;\n            if (_562_fa_fog_b.y > 0.0f)\n            {\n                float _6685;\n                if (_6647)\n                {\n                    _6685 = fa_world_pos.y - (_562_fa_fog_c.y * _6643);\n                }\n                else\n                {\n                    _6685 = _562_fa_camera_pos.y;\n                }\n                float _6706 = lerp(_6685, fa_world_pos.y, clamp(_562_fa_fog_b.x / _6648, 0.0f, 1.0f));\n                float _6710 = fa_world_pos.y - _6706;\n                float _6715 = _6706 - _562_fa_fog_b.z;\n                float _6720 = fa_world_pos.y - _562_fa_fog_b.z;\n                bool _6723 = _6715 <= 0.0f;\n                bool _6724 = !_6723;\n                bool _6730;\n                if (_6724)\n                {\n                    _6730 = _562_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6730 = _6723;\n                }\n                float _6731;\n                if (_6730)\n                {\n                    _6731 = _562_fa_fog_b.y;\n                }\n                else\n                {\n                    _6731 = _562_fa_fog_b.y * exp(-min(_562_fa_fog_b.w * _6715, 80.0f));\n                }\n                bool _6758;\n                if (_6724)\n                {\n                    _6758 = _562_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6758 = _6723;\n                }\n                float _6759;\n                if (_6758)\n                {\n                    _6759 = _562_fa_fog_b.y * _6715;\n                }\n                else\n                {\n                    _6759 = (_562_fa_fog_b.y * (1.0f - exp(-min(_562_fa_fog_b.w * _6715, 80.0f)))) / _562_fa_fog_b.w;\n                }\n                bool _6784 = _6720 <= 0.0f;\n                bool _6791;\n                if (!_6784)\n                {\n                    _6791 = _562_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6791 = _6784;\n                }\n                float _6792;\n                if (_6791)\n                {\n                    _6792 = _562_fa_fog_b.y * _6720;\n                }\n                else\n                {\n                    _6792 = (_562_fa_fog_b.y * (1.0f - exp(-min(_562_fa_fog_b.w * _6720, 80.0f)))) / _562_fa_fog_b.w;\n                }\n                float _6819;\n                if (abs(_6710) < 0.001000000047497451305389404296875f)\n                {\n                    _6819 = _6731;\n                }\n                else\n                {\n                    _6819 = (_6792 - _6759) / _6710;\n                }\n                tau += (_6660 * max(_6819, 0.0f));\n            }\n            result = lerp(result, _562_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _6892);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_inst_v0 = stage_input.fa_inst_v0;\n    fa_inst_v1 = stage_input.fa_inst_v1;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_562",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2229",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_5836",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _153_fa_view_proj : packoffset(c0);\n    row_major float4x4 _153_fa_light_vp : packoffset(c4);\n    float4 _153_fa_uv_scale : packoffset(c8);\n    float4 _153_fa_time : packoffset(c9);\n    float4 _153_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_d0;\nstatic float4 fa_inst_d1;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_inst_d0 : TEXCOORD9;\n    float4 fa_inst_d1 : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float fa_pre_depth : TEXCOORD7;\n    float3 fa_pre_r0 : TEXCOORD8;\n    float3 fa_pre_r1 : TEXCOORD9;\n    float3 fa_pre_r2 : TEXCOORD10;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float raise;\nstatic float4 tint;\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _100 = (dot(model[0].xyz, _94) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _334 = { mul(float4(position, 1.0f), model).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _100, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _100), texcoord0 * _153_fa_uv_scale.xy, color, position };\n    return _334;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _197 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -mul(_197, _153_fa_light_vp).z;\n    fa_pre_r0 = float3(_153_fa_light_vp[0].x, _153_fa_light_vp[1].x, _153_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_153_fa_light_vp[0].y, _153_fa_light_vp[1].y, _153_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_153_fa_light_vp[0].z, _153_fa_light_vp[1].z, _153_fa_light_vp[2].z);\n    gl_Position = mul(_197, _153_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_d0 = stage_input.fa_inst_d0;\n    fa_inst_d1 = stage_input.fa_inst_d1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    stage_output.fa_inst_v0 = fa_inst_v0;\n    stage_output.fa_inst_v1 = fa_inst_v1;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _142_boost : packoffset(c0);\n    float _142_fa_pad0 : packoffset(c0.y);\n    float _142_fa_pad1 : packoffset(c0.z);\n    float _142_fa_pad2 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _253_fa_camera_pos : packoffset(c0);\n    float4 _253_fa_ambient : packoffset(c1);\n    float4 _253_fa_base_color : packoffset(c2);\n    float4 _253_fa_emissive : packoffset(c3);\n    float4 _253_fa_model_emissive : packoffset(c4);\n    float4 _253_fa_pbr : packoffset(c5);\n    float4 _253_fa_maps : packoffset(c6);\n    float4 _253_fa_fog : packoffset(c7);\n    float4 _253_fa_fog_b : packoffset(c8);\n    float4 _253_fa_fog_c : packoffset(c9);\n    float4 _253_fa_counts : packoffset(c10);\n    float4 _253_fa_env_sky : packoffset(c11);\n    float4 _253_fa_env_horizon : packoffset(c12);\n    float4 _253_fa_time : packoffset(c13);\n    float4 _253_fa_cl_vpx : packoffset(c14);\n    float4 _253_fa_cl_vpy : packoffset(c15);\n    float4 _253_fa_cl_vpw : packoffset(c16);\n    float4 _253_fa_cl_fwd : packoffset(c17);\n    float4 _253_fa_cl_grid : packoffset(c18);\n    float4 _253_fa_cl_info : packoffset(c19);\n    float4 _253_fa_layers_a : packoffset(c20);\n    float4 _253_fa_layers_b : packoffset(c21);\n    float4 _253_fa_layers_c : packoffset(c22);\n    float4 _253_fa_layers_d : packoffset(c23);\n    float4 _253_fa_ct_a : packoffset(c24);\n    float4 _253_fa_ct_b : packoffset(c25);\n    float4 _253_fa_ct_vpx : packoffset(c26);\n    float4 _253_fa_ct_vpy : packoffset(c27);\n    float4 _253_fa_ct_vpw : packoffset(c28);\n    float4 _253_fa_ct_fwd : packoffset(c29);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float fa_pre_depth : TEXCOORD7;\n    float3 fa_pre_r0 : TEXCOORD8;\n    float3 fa_pre_r1 : TEXCOORD9;\n    float3 fa_pre_r2 : TEXCOORD10;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float raise;\nstatic float4 tint;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    float3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    float3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    float3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _253_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _264 = fa_tex_fix(param_2, param_3);\n    float4 _772 = base_t;\n    _772.x = _264.x;\n    _772.y = _264.y;\n    _772.z = _264.z;\n    base_t = _772;\n    float4 _280 = (_772 * _253_fa_base_color) * i.vertex_color;\n    float3 _735 = i.world_normal;\n    if (_253_fa_maps.z > 0.5f)\n    {\n        float param_4 = _253_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _313 = fa_tex_fix(param_6, param_7);\n        float3 _317 = (_313 * 2.0f) - 1.0f.xxx;\n        float2 _322 = _317.xy * _253_fa_maps.x;\n        float3 _780 = _317;\n        _780.x = _322.x;\n        _780.y = _322.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _780;\n        _735 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _253_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _351 = fa_tex_fix(param_12, param_13);\n    float4 _783 = mrt;\n    _783.x = _351.x;\n    _783.y = _351.y;\n    _783.z = _351.z;\n    mrt = _783;\n    float4 _381 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _253_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _381.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _393 = fa_tex_fix(param_16, param_17);\n    float param_18 = _253_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _423 = fa_tex_fix(param_20, param_21);\n    float _740 = _253_fa_layers_a.x;\n    float _741 = _253_fa_layers_a.y;\n    float _744 = _253_fa_layers_a.z;\n    float _743 = _253_fa_layers_b.w;\n    float _746 = _253_fa_layers_c.x;\n    if (_253_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_253_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _740 *= _393.y;\n            _741 *= _393.z;\n            _743 *= _381.w;\n        }\n        if (_253_fa_layers_c.z > 1.5f)\n        {\n            _744 *= mrt.x;\n            _746 *= mrt.w;\n        }\n    }\n    Surface _765 = { _280.xyz, _280.w, _735, clamp(_253_fa_pbr.x * _351.z, 0.0f, 1.0f), clamp(_253_fa_pbr.y * _351.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_253_fa_maps.y * (_393.x - 1.0f)), _253_fa_emissive.xyz + (_253_fa_model_emissive.xyz * _423), _740, _741, _253_fa_layers_b.xyz, _743, _744, _253_fa_layers_a.w, _746, _253_fa_layers_c.y, _253_fa_layers_d.xyz };\n    return _765;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * _142_boost);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _646 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _646 = -_646;\n    }\n    float3 _556 = normalize(_253_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _659 = { fa_world_pos, _646, fa_world_tangent, fa_uv, fa_vertex_color, _556, gl_FrontFacing };\n    SurfaceInput param = _659;\n    SurfaceInput _667 = { fa_world_pos, _646, fa_world_tangent, fa_uv, fa_vertex_color, _556, gl_FrontFacing };\n    SurfaceInput param_1 = _667;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _571 = normalize(param_2.normal);\n    float3 _586 = normalize(float3(dot(fa_pre_r0, _571), dot(fa_pre_r1, _571), dot(fa_pre_r2, _571)));\n    float _598 = _586.z;\n    float2 e = _586.xy / ((abs(_586.x) + abs(_586.y)) + abs(_598)).xx;\n    if (_598 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_inst_v0 = stage_input.fa_inst_v0;\n    fa_inst_v1 = stage_input.fa_inst_v1;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 480,
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _142_boost : packoffset(c0);\n    float _142_fa_pad0 : packoffset(c0.y);\n    float _142_fa_pad1 : packoffset(c0.z);\n    float _142_fa_pad2 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _253_fa_camera_pos : packoffset(c0);\n    float4 _253_fa_ambient : packoffset(c1);\n    float4 _253_fa_base_color : packoffset(c2);\n    float4 _253_fa_emissive : packoffset(c3);\n    float4 _253_fa_model_emissive : packoffset(c4);\n    float4 _253_fa_pbr : packoffset(c5);\n    float4 _253_fa_maps : packoffset(c6);\n    float4 _253_fa_fog : packoffset(c7);\n    float4 _253_fa_fog_b : packoffset(c8);\n    float4 _253_fa_fog_c : packoffset(c9);\n    float4 _253_fa_counts : packoffset(c10);\n    float4 _253_fa_env_sky : packoffset(c11);\n    float4 _253_fa_env_horizon : packoffset(c12);\n    float4 _253_fa_time : packoffset(c13);\n    float4 _253_fa_cl_vpx : packoffset(c14);\n    float4 _253_fa_cl_vpy : packoffset(c15);\n    float4 _253_fa_cl_vpw : packoffset(c16);\n    float4 _253_fa_cl_fwd : packoffset(c17);\n    float4 _253_fa_cl_grid : packoffset(c18);\n    float4 _253_fa_cl_info : packoffset(c19);\n    float4 _253_fa_layers_a : packoffset(c20);\n    float4 _253_fa_layers_b : packoffset(c21);\n    float4 _253_fa_layers_c : packoffset(c22);\n    float4 _253_fa_layers_d : packoffset(c23);\n    float4 _253_fa_ct_a : packoffset(c24);\n    float4 _253_fa_ct_b : packoffset(c25);\n    float4 _253_fa_ct_vpx : packoffset(c26);\n    float4 _253_fa_ct_vpy : packoffset(c27);\n    float4 _253_fa_ct_vpw : packoffset(c28);\n    float4 _253_fa_ct_fwd : packoffset(c29);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float fa_pre_depth : TEXCOORD7;\n    float3 fa_pre_r0 : TEXCOORD8;\n    float3 fa_pre_r1 : TEXCOORD9;\n    float3 fa_pre_r2 : TEXCOORD10;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float raise;\nstatic float4 tint;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    float3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    float3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    float3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _253_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _264 = fa_tex_fix(param_2, param_3);\n    float4 _772 = base_t;\n    _772.x = _264.x;\n    _772.y = _264.y;\n    _772.z = _264.z;\n    base_t = _772;\n    float4 _280 = (_772 * _253_fa_base_color) * i.vertex_color;\n    float3 _735 = i.world_normal;\n    if (_253_fa_maps.z > 0.5f)\n    {\n        float param_4 = _253_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _313 = fa_tex_fix(param_6, param_7);\n        float3 _317 = (_313 * 2.0f) - 1.0f.xxx;\n        float2 _322 = _317.xy * _253_fa_maps.x;\n        float3 _780 = _317;\n        _780.x = _322.x;\n        _780.y = _322.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _780;\n        _735 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _253_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _351 = fa_tex_fix(param_12, param_13);\n    float4 _783 = mrt;\n    _783.x = _351.x;\n    _783.y = _351.y;\n    _783.z = _351.z;\n    mrt = _783;\n    float4 _381 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _253_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _381.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _393 = fa_tex_fix(param_16, param_17);\n    float param_18 = _253_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _423 = fa_tex_fix(param_20, param_21);\n    float _740 = _253_fa_layers_a.x;\n    float _741 = _253_fa_layers_a.y;\n    float _744 = _253_fa_layers_a.z;\n    float _743 = _253_fa_layers_b.w;\n    float _746 = _253_fa_layers_c.x;\n    if (_253_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_253_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _740 *= _393.y;\n            _741 *= _393.z;\n            _743 *= _381.w;\n        }\n        if (_253_fa_layers_c.z > 1.5f)\n        {\n            _744 *= mrt.x;\n            _746 *= mrt.w;\n        }\n    }\n    Surface _765 = { _280.xyz, _280.w, _735, clamp(_253_fa_pbr.x * _351.z, 0.0f, 1.0f), clamp(_253_fa_pbr.y * _351.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_253_fa_maps.y * (_393.x - 1.0f)), _253_fa_emissive.xyz + (_253_fa_model_emissive.xyz * _423), _740, _741, _253_fa_layers_b.xyz, _743, _744, _253_fa_layers_a.w, _746, _253_fa_layers_c.y, _253_fa_layers_d.xyz };\n    return _765;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * _142_boost);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _646 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _646 = -_646;\n    }\n    float3 _556 = normalize(_253_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _659 = { fa_world_pos, _646, fa_world_tangent, fa_uv, fa_vertex_color, _556, gl_FrontFacing };\n    SurfaceInput param = _659;\n    SurfaceInput _667 = { fa_world_pos, _646, fa_world_tangent, fa_uv, fa_vertex_color, _556, gl_FrontFacing };\n    SurfaceInput param_1 = _667;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _571 = normalize(param_2.normal);\n    float3 _586 = normalize(float3(dot(fa_pre_r0, _571), dot(fa_pre_r1, _571), dot(fa_pre_r2, _571)));\n    float _598 = _586.z;\n    float2 e = _586.xy / ((abs(_586.x) + abs(_586.y)) + abs(_598)).xx;\n    if (_598 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_inst_v0 = stage_input.fa_inst_v0;\n    fa_inst_v1 = stage_input.fa_inst_v1;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 480,
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
