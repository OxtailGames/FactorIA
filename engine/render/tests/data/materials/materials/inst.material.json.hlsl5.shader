{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "41c86c92dbb0093951c81b6ee249cbb5aa749f4b053c4954c67a5e43bd66f6f3",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _416_fa_camera_pos : packoffset(c0);\n    float4 _416_fa_ambient : packoffset(c1);\n    float4 _416_fa_base_color : packoffset(c2);\n    float4 _416_fa_emissive : packoffset(c3);\n    float4 _416_fa_model_emissive : packoffset(c4);\n    float4 _416_fa_pbr : packoffset(c5);\n    float4 _416_fa_maps : packoffset(c6);\n    float4 _416_fa_fog : packoffset(c7);\n    float4 _416_fa_fog_b : packoffset(c8);\n    float4 _416_fa_fog_c : packoffset(c9);\n    float4 _416_fa_counts : packoffset(c10);\n    float4 _416_fa_env_sky : packoffset(c11);\n    float4 _416_fa_env_horizon : packoffset(c12);\n    float4 _416_fa_time : packoffset(c13);\n    float4 _416_fa_cl_vpx : packoffset(c14);\n    float4 _416_fa_cl_vpy : packoffset(c15);\n    float4 _416_fa_cl_vpw : packoffset(c16);\n    float4 _416_fa_cl_fwd : packoffset(c17);\n    float4 _416_fa_cl_grid : packoffset(c18);\n    float4 _416_fa_cl_info : packoffset(c19);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _1156_fa_shadow_mat[4] : packoffset(c0);\n    float4 _1156_fa_shadow_rect[4] : packoffset(c16);\n    float4 _1156_fa_shadow_info[4] : packoffset(c20);\n    float4 _1156_fa_shadow_split : packoffset(c24);\n    float4 _1156_fa_shadow_cfg : packoffset(c25);\n    float4 _1156_fa_shadow_bias : packoffset(c26);\n    float4 _1156_fa_shadow_eye : packoffset(c27);\n    float4 _1156_fa_shadow_fwd : packoffset(c28);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _2038_boost : packoffset(c0);\n    float _2038_fa_pad0 : packoffset(c0.y);\n    float _2038_fa_pad1 : packoffset(c0.z);\n    float _2038_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_decal_tex : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\nstatic float raise;\nstatic float4 tint;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _421 = _416_fa_cl_info.x < 0.0f;\n    bool _428;\n    if (!_421)\n    {\n        _428 = _416_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _428 = _421;\n    }\n    bool _436;\n    if (!_428)\n    {\n        _436 = _416_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _436 = _428;\n    }\n    bool _443;\n    if (!_436)\n    {\n        _443 = _416_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _443 = _436;\n    }\n    bool _450;\n    if (!_443)\n    {\n        _450 = _416_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _450 = _443;\n    }\n    if (_450)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _460 = float4(world_pos, 1.0f);\n    float _467 = dot(_416_fa_cl_vpw, _460);\n    if (!(_467 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _489 = float2(dot(_416_fa_cl_vpx, _460), dot(_416_fa_cl_vpy, _460)) / _467.xx;\n    int _493 = int(_416_fa_cl_grid.x);\n    int _497 = int(_416_fa_cl_grid.y);\n    int param = (int(_416_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_416_fa_cl_fwd.xyz, world_pos) + _416_fa_cl_fwd.w, _416_fa_cl_grid.w) / _416_fa_cl_grid.w) * _416_fa_cl_grid.z)), 0, int(_416_fa_cl_info.y) - 1) * _497) + clamp(int(floor(((_489.y * 0.5f) + 0.5f) * _416_fa_cl_grid.y)), 0, _497 - 1)) * _493)) + clamp(int(floor(((_489.x * 0.5f) + 0.5f) * _416_fa_cl_grid.x)), 0, _493 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _573 = fa_cluster_texel(param);\n    return int2(int(_573.x), int(_573.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_416_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1971 = fa_cluster_lookup(param);\n    fa_cl_slot = _1971.x;\n    fa_cl_local = _1971.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _2090 = fa_linear_to_srgb(param);\n        c = _2090;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _2098 = fa_srgb_to_linear(param_1);\n            c = _2098;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _188;\n    if (i.front_facing)\n    {\n        _188 = i.world_normal;\n    }\n    else\n    {\n        _188 = -i.world_normal;\n    }\n    float3 _212 = normalize(i.world_tangent.xyz - (_188 * dot(_188, i.world_tangent.xyz)));\n    float3 _240 = normalize(((_212 * m.x) + ((cross(_188, _212) * i.world_tangent.w) * m.y)) + (_188 * m.z));\n    float3 _243;\n    if (i.front_facing)\n    {\n        _243 = _240;\n    }\n    else\n    {\n        _243 = -_240;\n    }\n    return _243;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _416_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2129 = fa_tex_fix(param_2, param_3);\n    float4 _2974 = base_t;\n    _2974.x = _2129.x;\n    _2974.y = _2129.y;\n    _2974.z = _2129.z;\n    base_t = _2974;\n    float4 _2143 = (_2974 * _416_fa_base_color) * i.vertex_color;\n    float3 _2898 = i.world_normal;\n    if (_416_fa_maps.z > 0.5f)\n    {\n        float param_4 = _416_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2175 = fa_tex_fix(param_6, param_7);\n        float3 _2178 = (_2175 * 2.0f) - 1.0f.xxx;\n        float2 _2183 = _2178.xy * _416_fa_maps.x;\n        float3 _2982 = _2178;\n        _2982.x = _2183.x;\n        _2982.y = _2183.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2982;\n        _2898 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _416_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2212 = fa_tex_fix(param_12, param_13);\n    float4 _2985 = mrt;\n    _2985.x = _2212.x;\n    _2985.y = _2212.y;\n    _2985.z = _2212.z;\n    mrt = _2985;\n    float param_14 = _416_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2251 = fa_tex_fix(param_16, param_17);\n    float param_18 = _416_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2278 = fa_tex_fix(param_20, param_21);\n    Surface _2910 = { _2143.xyz, _2143.w, _2898, clamp(_416_fa_pbr.x * _2212.z, 0.0f, 1.0f), clamp(_416_fa_pbr.y * _2212.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_416_fa_maps.y * (_2251.x - 1.0f)), _416_fa_emissive.xyz + (_416_fa_model_emissive.xyz * _2278) };\n    return _2910;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * _2038_boost);\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _654 = rect.zw - rect.xy;\n    float2 _658 = _654 * atlas;\n    float2 _662 = ddx * _658;\n    float2 _666 = ddy * _658;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _654), clamp(0.5f * log2(max(max(dot(_662, _662), dot(_666, _666)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    float3 _701 = ddx(world_pos);\n    float3 _704 = ddy(world_pos);\n    bool _707 = _416_fa_counts.y < 0.5f;\n    bool _714;\n    if (!_707)\n    {\n        _714 = _416_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _714 = _707;\n    }\n    if (_714)\n    {\n        return;\n    }\n    float3 param = world_pos;\n    float4 _721 = fa_cluster_texel(param);\n    int _725 = int(_721.w);\n    if (_725 < 1)\n    {\n        return;\n    }\n    int _735 = int(_416_fa_counts.y + 0.5f);\n    int param_1 = _735;\n    float4 _739 = fa_light_texel(param_1);\n    float2 _742 = _739.yz;\n    int _746 = int(_739.w);\n    int param_2 = _735 + 1;\n    float4 _751 = fa_light_texel(param_2);\n    float _752 = _751.x;\n    int _758 = int(_416_fa_counts.w + 0.5f) - 1;\n    int _762 = int(_721.z);\n    float3 _1028;\n    for (int k = 0; k < _725; k++)\n    {\n        int _775 = _762 + k;\n        int param_3 = _746 + (_775 >> 2);\n        int _793 = (_735 + 2) + (int(fa_light_texel(param_3)[_775 & 3]) * 7);\n        int param_4 = _793 + 6;\n        float4 _798 = fa_light_texel(param_4);\n        if (((int(_798.w + 0.5f) >> _758) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _793;\n        float4 _813 = fa_light_texel(param_5);\n        int param_6 = _793 + 1;\n        float4 _818 = fa_light_texel(param_6);\n        int param_7 = _793 + 2;\n        float4 _823 = fa_light_texel(param_7);\n        float3 _826 = _813.xyz;\n        float _831 = dot(_826, world_pos) + _813.w;\n        float3 _833 = _818.xyz;\n        float _838 = dot(_833, world_pos) + _818.w;\n        float3 _840 = _823.xyz;\n        float _845 = dot(_840, world_pos) + _823.w;\n        bool _850 = abs(_831) > 0.5f;\n        bool _858;\n        if (!_850)\n        {\n            _858 = abs(_838) > 0.5f;\n        }\n        else\n        {\n            _858 = _850;\n        }\n        bool _866;\n        if (!_858)\n        {\n            _866 = abs(_845) > 0.5f;\n        }\n        else\n        {\n            _866 = _858;\n        }\n        if (_866)\n        {\n            continue;\n        }\n        float _881 = clamp(dot(geo_normal, normalize(_840)) * _798.z, 0.0f, 1.0f);\n        if (_881 <= 0.0f)\n        {\n            continue;\n        }\n        float _901 = (clamp((0.5f - abs(_845)) * 10.0f, 0.0f, 1.0f) * _881) * _798.x;\n        float2 _909 = float2(_831 + 0.5f, 0.5f - _838);\n        float2 _919 = float2(dot(_826, _701), dot(_833, _701));\n        float2 _929 = float2(dot(_826, _704), dot(_833, _704));\n        int param_8 = _793 + 5;\n        float4 _934 = fa_light_texel(param_8);\n        int param_9 = _793 + 3;\n        float4 _939 = fa_light_texel(param_9);\n        int param_10 = _793 + 4;\n        float4 _944 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _934.xyz;\n        bool _954 = _939.z > _939.x;\n        if (_954)\n        {\n            float4 param_11 = _939;\n            float2 param_12 = _909;\n            float2 param_13 = _742;\n            float2 param_14 = _919;\n            float2 param_15 = _929;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_752 > 0.5f) && (_752 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _980 = fa_dc_to_linear(param_16);\n                float4 _2936 = tx;\n                _2936.x = _980.x;\n                _2936.y = _980.y;\n                _2936.z = _980.z;\n                tx = _2936;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_901 * tex_a) * _934.w, 0.0f, 1.0f).xxx);\n        if (_944.z > _944.x)\n        {\n            float4 param_17 = _944;\n            float2 param_18 = _909;\n            float2 param_19 = _742;\n            float2 param_20 = _919;\n            float2 param_21 = _929;\n            float4 _1024 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_752 > 1.5f)\n            {\n                float3 param_22 = _1024.xyz;\n                float3 _1034 = fa_dc_to_srgb(param_22);\n                _1028 = _1034;\n            }\n            else\n            {\n                _1028 = _1024.xyz;\n            }\n            float3 _1044 = (_1028 * 2.0f) - 1.0f.xxx;\n            float2 _1049 = _1044.xy * _798.y;\n            float3 _1071 = (normalize(_826) * _1049.x) + (normalize(_833) * _1049.y);\n            float3 _1074 = normalize(normal);\n            normal = normalize(lerp(_1074, normalize((_1074 * max(_1044.z, 0.0500000007450580596923828125f)) + (_1071 - (_1074 * dot(_1074, _1071)))), clamp(_901 * (_954 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_416_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _416_fa_ambient.xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_416_fa_cl_info.x) + int(_416_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _288 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _294 = fa_light_texel(param_1);\n    float _297 = _294.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _304 = _297 < 0.5f;\n    float3 l;\n    if (_304)\n    {\n        l = normalize(_288.xyz);\n    }\n    else\n    {\n        float3 _316 = _288.xyz - world_pos;\n        float _318 = length(_316);\n        dist = _318;\n        l = _316 / max(_318, 9.9999997473787516355514526367188e-05f).xxx;\n        float _333 = _318 / max(_288.w, 0.001000000047497451305389404296875f);\n        float _339 = clamp(1.0f - (_333 * _333), 0.0f, 1.0f);\n        atten = _339 * _339;\n        if (_297 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _353 = fa_light_texel(param_2);\n            float _363 = _353.w;\n            int param_3 = (li * 4) + 3;\n            float4 _370 = fa_light_texel(param_3);\n            float _371 = _370.x;\n            float cos_inner = _371;\n            if (_371 > 1.5f)\n            {\n                cos_inner = lerp(_363, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_363, cos_inner, dot(-l, normalize(_353.xyz)));\n        }\n    }\n    int _402;\n    if (_304)\n    {\n        _402 = 0;\n    }\n    else\n    {\n        _402 = (_297 > 1.5f) ? 2 : 1;\n    }\n    LightSample _2876 = { l, _294.xyz * atten, atten, 1.0f, dist, _402 };\n    return _2876;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1146;\n    if (i == 0)\n    {\n        _1146 = _1156_fa_shadow_split.x;\n    }\n    else\n    {\n        float _1162;\n        if (i == 1)\n        {\n            _1162 = _1156_fa_shadow_split.y;\n        }\n        else\n        {\n            float _1170;\n            if (i == 2)\n            {\n                _1170 = _1156_fa_shadow_split.z;\n            }\n            else\n            {\n                _1170 = _1156_fa_shadow_split.w;\n            }\n            _1162 = _1170;\n        }\n        _1146 = _1162;\n    }\n    return _1146;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1134 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_1134), sin(_1134)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _1208 = max(_1156_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _1213 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1219 = sqrt(1.0f - (_1213 * _1213));\n    float _1226 = min(_1219 / max(_1213, 0.20000000298023223876953125f), 4.0f);\n    float _1231;\n    if (_1156_fa_shadow_bias.y > 0.0f)\n    {\n        _1231 = _1156_fa_shadow_bias.y;\n    }\n    else\n    {\n        _1231 = 1.5f * _1156_fa_shadow_info[ci].x;\n    }\n    float4 _1256 = mul(float4(world + (n * (_1231 * _1219)), 1.0f), _1156_fa_shadow_mat[ci]);\n    float _1263 = _1256.x;\n    bool _1266 = _1263 < _1156_fa_shadow_rect[ci].x;\n    bool _1275;\n    if (!_1266)\n    {\n        _1275 = _1263 > _1156_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1275 = _1266;\n    }\n    bool _1284;\n    if (!_1275)\n    {\n        _1284 = _1256.y < _1156_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1284 = _1275;\n    }\n    bool _1293;\n    if (!_1284)\n    {\n        _1293 = _1256.y > _1156_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1293 = _1284;\n    }\n    bool _1300;\n    if (!_1293)\n    {\n        _1300 = _1256.z > 1.0f;\n    }\n    else\n    {\n        _1300 = _1293;\n    }\n    if (_1300)\n    {\n        return -1.0f;\n    }\n    float _1309;\n    if (_1156_fa_shadow_bias.x > 0.0f)\n    {\n        _1309 = _1156_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1309 = 1.5f * _1156_fa_shadow_info[ci].x;\n    }\n    float _1328 = _1256.z - ((_1309 * (1.0f + (0.5f * _1226))) / _1208);\n    float _1337 = ((_1156_fa_shadow_info[ci].x * min(_1226, 3.0f)) * 0.5f) / _1208;\n    int _1346 = int(_1156_fa_shadow_cfg.z + 0.5f);\n    if (_1346 == 1)\n    {\n        float2 param = _1256.xy;\n        float4 param_1 = _1156_fa_shadow_rect[ci];\n        float _1357 = fa_shadow_depth(param, param_1);\n        return float(_1328 <= _1357);\n    }\n    float _1364 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _1367 = _1346 == 2;\n    if (_1367)\n    {\n        float _1381 = clamp(((_1156_fa_shadow_cfg.w * _1208) * 0.25f) / _1156_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1364;\n            float2 _1400 = fa_shadow_vogel(param_2, param_3, param_4) * _1381;\n            float2 param_5 = _1256.xy + (_1400 * _1156_fa_shadow_bias.zw);\n            float4 param_6 = _1156_fa_shadow_rect[ci];\n            float _1411 = fa_shadow_depth(param_5, param_6);\n            if (_1411 < (_1328 - (length(_1400) * _1337)))\n            {\n                sum += _1411;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_1328 - (sum / cnt), 0.0f) * _1208) * _1156_fa_shadow_cfg.w) / _1156_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _1455 = _1367 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1455; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1455;\n        float param_9 = _1364;\n        float2 _1474 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _1256.xy + (_1474 * _1156_fa_shadow_bias.zw);\n        float4 param_11 = _1156_fa_shadow_rect[ci];\n        float _1485 = fa_shadow_depth(param_10, param_11);\n        lit += float((_1328 - (length(_1474) * _1337)) <= _1485);\n    }\n    return lit / float(_1455);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_416_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1515 = int(_1156_fa_shadow_cfg.x + 0.5f);\n    if (_1515 < 1)\n    {\n        return 1.0f;\n    }\n    float _1530 = dot(world - _1156_fa_shadow_eye.xyz, _1156_fa_shadow_fwd.xyz);\n    int param = _1515 - 1;\n    if (_1530 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1542 = _1515 > 1;\n    bool _1549;\n    if (_1542)\n    {\n        _1549 = _1530 > _1156_fa_shadow_split.x;\n    }\n    else\n    {\n        _1549 = _1542;\n    }\n    if (_1549)\n    {\n        ci = 1;\n    }\n    bool _1553 = _1515 > 2;\n    bool _1560;\n    if (_1553)\n    {\n        _1560 = _1530 > _1156_fa_shadow_split.y;\n    }\n    else\n    {\n        _1560 = _1553;\n    }\n    if (_1560)\n    {\n        ci = 2;\n    }\n    bool _1564 = _1515 > 3;\n    bool _1571;\n    if (_1564)\n    {\n        _1571 = _1530 > _1156_fa_shadow_split.z;\n    }\n    else\n    {\n        _1571 = _1564;\n    }\n    if (_1571)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1515)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1597 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1597;\n        if (_1597 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_1156_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1622;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1622 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1622 = _1156_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1641 = _1156_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1622, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1652 = clamp((_1530 - (fa_shadow_split_at(param_7) - _1641)) / _1641, 0.0f, 1.0f);\n        if (_1652 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1515)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1673 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1673;\n                if (_1673 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1652);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1999 = fa_light_sample(param, param_1);\n    float3 _2883 = _1999.direction;\n    float3 _2878 = _1999.color;\n    float _2880 = _1999.shadow;\n    int _2888 = _1999.type;\n    if ((_2888 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2883;\n        float _2013 = fa_shadow_factor(param_2, param_3);\n        _2880 = _2013;\n        _2878 *= _2013;\n    }\n    LightSample _2895 = { _2883, _2878, _1999.attenuation, _2880, _1999._distance, _2888 };\n    return _2895;\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _1903 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _1906 = _1903.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_1906 * _1906, exp2((-9.27999973297119140625f) * ndv)) * _1906) + _1903.y)) + _1903.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_416_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _416_fa_env_horizon.w).xyz;\n    }\n    float _1809 = rough * rough;\n    float _1839 = 0.60000002384185791015625f * _1809;\n    return lerp(lerp(_416_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_416_fa_env_horizon.xyz, _416_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _1809)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _1839, 0.0500000007450580596923828125f + _1839, d.y).xxx), ((_416_fa_env_sky.xyz + _416_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_1809 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1945 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1945.x) + _1945.y.xxx);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_1156_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1697 = int(_1156_fa_shadow_cfg.x + 0.5f);\n    float _1707 = dot(world - _1156_fa_shadow_eye.xyz, _1156_fa_shadow_fwd.xyz);\n    float3 tint_1 = 0.3499999940395355224609375f.xxx;\n    bool _1712 = _1697 > 0;\n    bool _1721;\n    if (_1712)\n    {\n        int param = _1697 - 1;\n        _1721 = _1707 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1721 = _1712;\n    }\n    if (_1721)\n    {\n        tint_1 = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1728 = _1697 > 1;\n        bool _1735;\n        if (_1728)\n        {\n            _1735 = _1707 > _1156_fa_shadow_split.x;\n        }\n        else\n        {\n            _1735 = _1728;\n        }\n        if (_1735)\n        {\n            tint_1 = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1741 = _1697 > 2;\n        bool _1748;\n        if (_1741)\n        {\n            _1748 = _1707 > _1156_fa_shadow_split.y;\n        }\n        else\n        {\n            _1748 = _1741;\n        }\n        if (_1748)\n        {\n            tint_1 = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1754 = _1697 > 3;\n        bool _1761;\n        if (_1754)\n        {\n            _1761 = _1707 > _1156_fa_shadow_split.z;\n        }\n        else\n        {\n            _1761 = _1754;\n        }\n        if (_1761)\n        {\n            tint_1 = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint_1, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _2803 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2803 = -_2803;\n    }\n    float3 _2321 = normalize(_416_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _2816 = { fa_world_pos, _2803, fa_world_tangent, fa_uv, fa_vertex_color, _2321, gl_FrontFacing };\n    SurfaceInput param_1 = _2816;\n    Surface _2329 = fa_standard_surface(param_1);\n    float3 _2826 = _2329.albedo;\n    float _2827 = _2329.alpha;\n    float3 _2828 = _2329.normal;\n    float _2829 = _2329.metallic;\n    float _2830 = _2329.roughness;\n    float _2831 = _2329.occlusion;\n    float3 _2832 = _2329.emission;\n    SurfaceInput _2824 = { fa_world_pos, _2803, fa_world_tangent, fa_uv, fa_vertex_color, _2321, gl_FrontFacing };\n    SurfaceInput param_2 = _2824;\n    Surface param_3 = _2329;\n    surface(param_2, param_3);\n    _2826 = param_3.albedo;\n    _2827 = param_3.alpha;\n    _2828 = param_3.normal;\n    _2829 = param_3.metallic;\n    _2830 = param_3.roughness;\n    _2831 = param_3.occlusion;\n    _2832 = param_3.emission;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _2803;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _2826 = param_6;\n    _2828 = param_7;\n    float3 result;\n    if (_416_fa_emissive.w > 0.5f)\n    {\n        result = _2826;\n    }\n    else\n    {\n        float3 _2368 = normalize(_2828);\n        float _2375 = clamp(_2829, 0.0f, 1.0f);\n        float _2379 = clamp(_2830, 0.0500000007450580596923828125f, 1.0f);\n        float _2383 = _2379 * _2379;\n        float _2387 = _2383 * _2383;\n        float _2392 = max(dot(_2368, _2321), 9.9999997473787516355514526367188e-05f);\n        float3 _2398 = _2826 * (1.0f - _2375);\n        float3 _2406 = lerp(0.039999999105930328369140625f.xxx, _2826, _2375.xxx);\n        float3 param_8 = _2368;\n        float3 lit = (fa_ambient_light(param_8) * _2398) * _2831;\n        int _2419 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2419; ln++)\n        {\n            int param_9 = ln;\n            int _2432 = fa_cl_light(param_9);\n            int param_10 = _2432;\n            float3 param_11 = fa_world_pos;\n            float3 param_12 = _2803;\n            LightSample _2441 = fa_light_shadowed(param_10, param_11, param_12);\n            float3 _2861 = _2441.direction;\n            float _2449 = max(dot(_2368, _2861), 0.0f);\n            float3 _2460 = normalize(_2861 + _2321);\n            float _2465 = max(dot(_2368, _2460), 0.0f);\n            float _2478 = ((_2465 * _2465) * (_2387 - 1.0f)) + 1.0f;\n            int param_13 = _2432;\n            lit += (((_2398 + (((_2406 + ((1.0f.xxx - _2406) * pow(1.0f - max(dot(_2321, _2460), 0.0f), 5.0f))) * (((_2387 / ((3.1415927410125732421875f * _2478) * _2478)) * (0.5f / max(lerp((2.0f * _2449) * _2392, _2449 + _2392, _2383), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _2449))) * fa_light_rgb(param_13)) * (_2449 * (_2441.attenuation * _2441.shadow)));\n        }\n        float3 param_14 = _2368;\n        float3 param_15 = _2321;\n        float3 param_16 = _2406;\n        float param_17 = _2379;\n        float3 _2547 = lit;\n        float3 _2548 = _2547 + (fa_sky_reflection(param_14, param_15, param_16, param_17) * _2831);\n        lit = _2548;\n        result = _2548;\n    }\n    float3 _2552 = result;\n    float3 _2553 = _2552 + _2832;\n    result = _2553;\n    float3 param_18 = _2553;\n    float3 param_19 = fa_world_pos;\n    result = fa_shadow_debug(param_18, param_19);\n    bool _2562 = _416_fa_fog.w > 0.0f;\n    bool _2570;\n    if (!_2562)\n    {\n        _2570 = _416_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2570 = _2562;\n    }\n    if (_2570)\n    {\n        float3 _2579 = fa_world_pos - _416_fa_camera_pos.xyz;\n        float _2586 = dot(_2579, _416_fa_fog_c.xyz);\n        bool _2590 = _416_fa_fog_c.w > 0.5f;\n        float _2591;\n        if (_2590)\n        {\n            _2591 = _2586;\n        }\n        else\n        {\n            _2591 = length(_2579);\n        }\n        float _2603 = _2591 - _416_fa_fog_b.x;\n        if (_2603 > 0.0f)\n        {\n            float _2612 = _416_fa_fog.w * _2603;\n            float tau = _2612 * _2612;\n            if (_416_fa_fog_b.y > 0.0f)\n            {\n                float _2628;\n                if (_2590)\n                {\n                    _2628 = fa_world_pos.y - (_416_fa_fog_c.y * _2586);\n                }\n                else\n                {\n                    _2628 = _416_fa_camera_pos.y;\n                }\n                float _2649 = lerp(_2628, fa_world_pos.y, clamp(_416_fa_fog_b.x / _2591, 0.0f, 1.0f));\n                float _2653 = fa_world_pos.y - _2649;\n                float _2658 = _2649 - _416_fa_fog_b.z;\n                float _2663 = fa_world_pos.y - _416_fa_fog_b.z;\n                bool _2666 = _2658 <= 0.0f;\n                bool _2667 = !_2666;\n                bool _2673;\n                if (_2667)\n                {\n                    _2673 = _416_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2673 = _2666;\n                }\n                float _2674;\n                if (_2673)\n                {\n                    _2674 = _416_fa_fog_b.y;\n                }\n                else\n                {\n                    _2674 = _416_fa_fog_b.y * exp(-min(_416_fa_fog_b.w * _2658, 80.0f));\n                }\n                bool _2701;\n                if (_2667)\n                {\n                    _2701 = _416_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2701 = _2666;\n                }\n                float _2702;\n                if (_2701)\n                {\n                    _2702 = _416_fa_fog_b.y * _2658;\n                }\n                else\n                {\n                    _2702 = (_416_fa_fog_b.y * (1.0f - exp(-min(_416_fa_fog_b.w * _2658, 80.0f)))) / _416_fa_fog_b.w;\n                }\n                bool _2727 = _2663 <= 0.0f;\n                bool _2734;\n                if (!_2727)\n                {\n                    _2734 = _416_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2734 = _2727;\n                }\n                float _2735;\n                if (_2734)\n                {\n                    _2735 = _416_fa_fog_b.y * _2663;\n                }\n                else\n                {\n                    _2735 = (_416_fa_fog_b.y * (1.0f - exp(-min(_416_fa_fog_b.w * _2663, 80.0f)))) / _416_fa_fog_b.w;\n                }\n                float _2762;\n                if (abs(_2653) < 0.001000000047497451305389404296875f)\n                {\n                    _2762 = _2674;\n                }\n                else\n                {\n                    _2762 = (_2735 - _2702) / _2653;\n                }\n                tau += (_2603 * max(_2762, 0.0f));\n            }\n            result = lerp(result, _416_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _2827);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_inst_v0 = stage_input.fa_inst_v0;\n    fa_inst_v1 = stage_input.fa_inst_v1;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_416",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_1156",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_2038",
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _158_fa_view_proj : packoffset(c0);\n    row_major float4x4 _158_fa_light_vp : packoffset(c4);\n    float4 _158_fa_uv_scale : packoffset(c8);\n    float4 _158_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _205_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_d0;\nstatic float4 fa_inst_d1;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n    float4 fa_inst_d0 : TEXCOORD11;\n    float4 fa_inst_d1 : TEXCOORD12;\n};\n\nstruct SPIRV_Cross_Output\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float raise;\nstatic float4 tint;\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_205_fa_joint_rows[_196] * weights[i]);\n        r1 += (_205_fa_joint_rows[_196 + 1] * weights[i]);\n        r2 += (_205_fa_joint_rows[_196 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _420 = { mul(float4(position, 1.0f), model).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * _158_fa_uv_scale.xy, color, position };\n    return _420;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _158_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_d0 = stage_input.fa_inst_d0;\n    fa_inst_d1 = stage_input.fa_inst_d1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_inst_v0 = fa_inst_v0;\n    stage_output.fa_inst_v1 = fa_inst_v1;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _416_fa_camera_pos : packoffset(c0);\n    float4 _416_fa_ambient : packoffset(c1);\n    float4 _416_fa_base_color : packoffset(c2);\n    float4 _416_fa_emissive : packoffset(c3);\n    float4 _416_fa_model_emissive : packoffset(c4);\n    float4 _416_fa_pbr : packoffset(c5);\n    float4 _416_fa_maps : packoffset(c6);\n    float4 _416_fa_fog : packoffset(c7);\n    float4 _416_fa_fog_b : packoffset(c8);\n    float4 _416_fa_fog_c : packoffset(c9);\n    float4 _416_fa_counts : packoffset(c10);\n    float4 _416_fa_env_sky : packoffset(c11);\n    float4 _416_fa_env_horizon : packoffset(c12);\n    float4 _416_fa_time : packoffset(c13);\n    float4 _416_fa_cl_vpx : packoffset(c14);\n    float4 _416_fa_cl_vpy : packoffset(c15);\n    float4 _416_fa_cl_vpw : packoffset(c16);\n    float4 _416_fa_cl_fwd : packoffset(c17);\n    float4 _416_fa_cl_grid : packoffset(c18);\n    float4 _416_fa_cl_info : packoffset(c19);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _1156_fa_shadow_mat[4] : packoffset(c0);\n    float4 _1156_fa_shadow_rect[4] : packoffset(c16);\n    float4 _1156_fa_shadow_info[4] : packoffset(c20);\n    float4 _1156_fa_shadow_split : packoffset(c24);\n    float4 _1156_fa_shadow_cfg : packoffset(c25);\n    float4 _1156_fa_shadow_bias : packoffset(c26);\n    float4 _1156_fa_shadow_eye : packoffset(c27);\n    float4 _1156_fa_shadow_fwd : packoffset(c28);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _2038_boost : packoffset(c0);\n    float _2038_fa_pad0 : packoffset(c0.y);\n    float _2038_fa_pad1 : packoffset(c0.z);\n    float _2038_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_decal_tex : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\nstatic float raise;\nstatic float4 tint;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _421 = _416_fa_cl_info.x < 0.0f;\n    bool _428;\n    if (!_421)\n    {\n        _428 = _416_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _428 = _421;\n    }\n    bool _436;\n    if (!_428)\n    {\n        _436 = _416_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _436 = _428;\n    }\n    bool _443;\n    if (!_436)\n    {\n        _443 = _416_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _443 = _436;\n    }\n    bool _450;\n    if (!_443)\n    {\n        _450 = _416_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _450 = _443;\n    }\n    if (_450)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _460 = float4(world_pos, 1.0f);\n    float _467 = dot(_416_fa_cl_vpw, _460);\n    if (!(_467 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _489 = float2(dot(_416_fa_cl_vpx, _460), dot(_416_fa_cl_vpy, _460)) / _467.xx;\n    int _493 = int(_416_fa_cl_grid.x);\n    int _497 = int(_416_fa_cl_grid.y);\n    int param = (int(_416_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_416_fa_cl_fwd.xyz, world_pos) + _416_fa_cl_fwd.w, _416_fa_cl_grid.w) / _416_fa_cl_grid.w) * _416_fa_cl_grid.z)), 0, int(_416_fa_cl_info.y) - 1) * _497) + clamp(int(floor(((_489.y * 0.5f) + 0.5f) * _416_fa_cl_grid.y)), 0, _497 - 1)) * _493)) + clamp(int(floor(((_489.x * 0.5f) + 0.5f) * _416_fa_cl_grid.x)), 0, _493 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _573 = fa_cluster_texel(param);\n    return int2(int(_573.x), int(_573.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_416_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1971 = fa_cluster_lookup(param);\n    fa_cl_slot = _1971.x;\n    fa_cl_local = _1971.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _2090 = fa_linear_to_srgb(param);\n        c = _2090;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _2098 = fa_srgb_to_linear(param_1);\n            c = _2098;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _188;\n    if (i.front_facing)\n    {\n        _188 = i.world_normal;\n    }\n    else\n    {\n        _188 = -i.world_normal;\n    }\n    float3 _212 = normalize(i.world_tangent.xyz - (_188 * dot(_188, i.world_tangent.xyz)));\n    float3 _240 = normalize(((_212 * m.x) + ((cross(_188, _212) * i.world_tangent.w) * m.y)) + (_188 * m.z));\n    float3 _243;\n    if (i.front_facing)\n    {\n        _243 = _240;\n    }\n    else\n    {\n        _243 = -_240;\n    }\n    return _243;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _416_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2129 = fa_tex_fix(param_2, param_3);\n    float4 _2974 = base_t;\n    _2974.x = _2129.x;\n    _2974.y = _2129.y;\n    _2974.z = _2129.z;\n    base_t = _2974;\n    float4 _2143 = (_2974 * _416_fa_base_color) * i.vertex_color;\n    float3 _2898 = i.world_normal;\n    if (_416_fa_maps.z > 0.5f)\n    {\n        float param_4 = _416_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2175 = fa_tex_fix(param_6, param_7);\n        float3 _2178 = (_2175 * 2.0f) - 1.0f.xxx;\n        float2 _2183 = _2178.xy * _416_fa_maps.x;\n        float3 _2982 = _2178;\n        _2982.x = _2183.x;\n        _2982.y = _2183.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2982;\n        _2898 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _416_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2212 = fa_tex_fix(param_12, param_13);\n    float4 _2985 = mrt;\n    _2985.x = _2212.x;\n    _2985.y = _2212.y;\n    _2985.z = _2212.z;\n    mrt = _2985;\n    float param_14 = _416_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2251 = fa_tex_fix(param_16, param_17);\n    float param_18 = _416_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2278 = fa_tex_fix(param_20, param_21);\n    Surface _2910 = { _2143.xyz, _2143.w, _2898, clamp(_416_fa_pbr.x * _2212.z, 0.0f, 1.0f), clamp(_416_fa_pbr.y * _2212.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_416_fa_maps.y * (_2251.x - 1.0f)), _416_fa_emissive.xyz + (_416_fa_model_emissive.xyz * _2278) };\n    return _2910;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * _2038_boost);\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _654 = rect.zw - rect.xy;\n    float2 _658 = _654 * atlas;\n    float2 _662 = ddx * _658;\n    float2 _666 = ddy * _658;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _654), clamp(0.5f * log2(max(max(dot(_662, _662), dot(_666, _666)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    float3 _701 = ddx(world_pos);\n    float3 _704 = ddy(world_pos);\n    bool _707 = _416_fa_counts.y < 0.5f;\n    bool _714;\n    if (!_707)\n    {\n        _714 = _416_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _714 = _707;\n    }\n    if (_714)\n    {\n        return;\n    }\n    float3 param = world_pos;\n    float4 _721 = fa_cluster_texel(param);\n    int _725 = int(_721.w);\n    if (_725 < 1)\n    {\n        return;\n    }\n    int _735 = int(_416_fa_counts.y + 0.5f);\n    int param_1 = _735;\n    float4 _739 = fa_light_texel(param_1);\n    float2 _742 = _739.yz;\n    int _746 = int(_739.w);\n    int param_2 = _735 + 1;\n    float4 _751 = fa_light_texel(param_2);\n    float _752 = _751.x;\n    int _758 = int(_416_fa_counts.w + 0.5f) - 1;\n    int _762 = int(_721.z);\n    float3 _1028;\n    for (int k = 0; k < _725; k++)\n    {\n        int _775 = _762 + k;\n        int param_3 = _746 + (_775 >> 2);\n        int _793 = (_735 + 2) + (int(fa_light_texel(param_3)[_775 & 3]) * 7);\n        int param_4 = _793 + 6;\n        float4 _798 = fa_light_texel(param_4);\n        if (((int(_798.w + 0.5f) >> _758) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _793;\n        float4 _813 = fa_light_texel(param_5);\n        int param_6 = _793 + 1;\n        float4 _818 = fa_light_texel(param_6);\n        int param_7 = _793 + 2;\n        float4 _823 = fa_light_texel(param_7);\n        float3 _826 = _813.xyz;\n        float _831 = dot(_826, world_pos) + _813.w;\n        float3 _833 = _818.xyz;\n        float _838 = dot(_833, world_pos) + _818.w;\n        float3 _840 = _823.xyz;\n        float _845 = dot(_840, world_pos) + _823.w;\n        bool _850 = abs(_831) > 0.5f;\n        bool _858;\n        if (!_850)\n        {\n            _858 = abs(_838) > 0.5f;\n        }\n        else\n        {\n            _858 = _850;\n        }\n        bool _866;\n        if (!_858)\n        {\n            _866 = abs(_845) > 0.5f;\n        }\n        else\n        {\n            _866 = _858;\n        }\n        if (_866)\n        {\n            continue;\n        }\n        float _881 = clamp(dot(geo_normal, normalize(_840)) * _798.z, 0.0f, 1.0f);\n        if (_881 <= 0.0f)\n        {\n            continue;\n        }\n        float _901 = (clamp((0.5f - abs(_845)) * 10.0f, 0.0f, 1.0f) * _881) * _798.x;\n        float2 _909 = float2(_831 + 0.5f, 0.5f - _838);\n        float2 _919 = float2(dot(_826, _701), dot(_833, _701));\n        float2 _929 = float2(dot(_826, _704), dot(_833, _704));\n        int param_8 = _793 + 5;\n        float4 _934 = fa_light_texel(param_8);\n        int param_9 = _793 + 3;\n        float4 _939 = fa_light_texel(param_9);\n        int param_10 = _793 + 4;\n        float4 _944 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _934.xyz;\n        bool _954 = _939.z > _939.x;\n        if (_954)\n        {\n            float4 param_11 = _939;\n            float2 param_12 = _909;\n            float2 param_13 = _742;\n            float2 param_14 = _919;\n            float2 param_15 = _929;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_752 > 0.5f) && (_752 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _980 = fa_dc_to_linear(param_16);\n                float4 _2936 = tx;\n                _2936.x = _980.x;\n                _2936.y = _980.y;\n                _2936.z = _980.z;\n                tx = _2936;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_901 * tex_a) * _934.w, 0.0f, 1.0f).xxx);\n        if (_944.z > _944.x)\n        {\n            float4 param_17 = _944;\n            float2 param_18 = _909;\n            float2 param_19 = _742;\n            float2 param_20 = _919;\n            float2 param_21 = _929;\n            float4 _1024 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_752 > 1.5f)\n            {\n                float3 param_22 = _1024.xyz;\n                float3 _1034 = fa_dc_to_srgb(param_22);\n                _1028 = _1034;\n            }\n            else\n            {\n                _1028 = _1024.xyz;\n            }\n            float3 _1044 = (_1028 * 2.0f) - 1.0f.xxx;\n            float2 _1049 = _1044.xy * _798.y;\n            float3 _1071 = (normalize(_826) * _1049.x) + (normalize(_833) * _1049.y);\n            float3 _1074 = normalize(normal);\n            normal = normalize(lerp(_1074, normalize((_1074 * max(_1044.z, 0.0500000007450580596923828125f)) + (_1071 - (_1074 * dot(_1074, _1071)))), clamp(_901 * (_954 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_416_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _416_fa_ambient.xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_416_fa_cl_info.x) + int(_416_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _288 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _294 = fa_light_texel(param_1);\n    float _297 = _294.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _304 = _297 < 0.5f;\n    float3 l;\n    if (_304)\n    {\n        l = normalize(_288.xyz);\n    }\n    else\n    {\n        float3 _316 = _288.xyz - world_pos;\n        float _318 = length(_316);\n        dist = _318;\n        l = _316 / max(_318, 9.9999997473787516355514526367188e-05f).xxx;\n        float _333 = _318 / max(_288.w, 0.001000000047497451305389404296875f);\n        float _339 = clamp(1.0f - (_333 * _333), 0.0f, 1.0f);\n        atten = _339 * _339;\n        if (_297 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _353 = fa_light_texel(param_2);\n            float _363 = _353.w;\n            int param_3 = (li * 4) + 3;\n            float4 _370 = fa_light_texel(param_3);\n            float _371 = _370.x;\n            float cos_inner = _371;\n            if (_371 > 1.5f)\n            {\n                cos_inner = lerp(_363, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_363, cos_inner, dot(-l, normalize(_353.xyz)));\n        }\n    }\n    int _402;\n    if (_304)\n    {\n        _402 = 0;\n    }\n    else\n    {\n        _402 = (_297 > 1.5f) ? 2 : 1;\n    }\n    LightSample _2876 = { l, _294.xyz * atten, atten, 1.0f, dist, _402 };\n    return _2876;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1146;\n    if (i == 0)\n    {\n        _1146 = _1156_fa_shadow_split.x;\n    }\n    else\n    {\n        float _1162;\n        if (i == 1)\n        {\n            _1162 = _1156_fa_shadow_split.y;\n        }\n        else\n        {\n            float _1170;\n            if (i == 2)\n            {\n                _1170 = _1156_fa_shadow_split.z;\n            }\n            else\n            {\n                _1170 = _1156_fa_shadow_split.w;\n            }\n            _1162 = _1170;\n        }\n        _1146 = _1162;\n    }\n    return _1146;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1134 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_1134), sin(_1134)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _1208 = max(_1156_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _1213 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1219 = sqrt(1.0f - (_1213 * _1213));\n    float _1226 = min(_1219 / max(_1213, 0.20000000298023223876953125f), 4.0f);\n    float _1231;\n    if (_1156_fa_shadow_bias.y > 0.0f)\n    {\n        _1231 = _1156_fa_shadow_bias.y;\n    }\n    else\n    {\n        _1231 = 1.5f * _1156_fa_shadow_info[ci].x;\n    }\n    float4 _1256 = mul(float4(world + (n * (_1231 * _1219)), 1.0f), _1156_fa_shadow_mat[ci]);\n    float _1263 = _1256.x;\n    bool _1266 = _1263 < _1156_fa_shadow_rect[ci].x;\n    bool _1275;\n    if (!_1266)\n    {\n        _1275 = _1263 > _1156_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1275 = _1266;\n    }\n    bool _1284;\n    if (!_1275)\n    {\n        _1284 = _1256.y < _1156_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1284 = _1275;\n    }\n    bool _1293;\n    if (!_1284)\n    {\n        _1293 = _1256.y > _1156_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1293 = _1284;\n    }\n    bool _1300;\n    if (!_1293)\n    {\n        _1300 = _1256.z > 1.0f;\n    }\n    else\n    {\n        _1300 = _1293;\n    }\n    if (_1300)\n    {\n        return -1.0f;\n    }\n    float _1309;\n    if (_1156_fa_shadow_bias.x > 0.0f)\n    {\n        _1309 = _1156_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1309 = 1.5f * _1156_fa_shadow_info[ci].x;\n    }\n    float _1328 = _1256.z - ((_1309 * (1.0f + (0.5f * _1226))) / _1208);\n    float _1337 = ((_1156_fa_shadow_info[ci].x * min(_1226, 3.0f)) * 0.5f) / _1208;\n    int _1346 = int(_1156_fa_shadow_cfg.z + 0.5f);\n    if (_1346 == 1)\n    {\n        float2 param = _1256.xy;\n        float4 param_1 = _1156_fa_shadow_rect[ci];\n        float _1357 = fa_shadow_depth(param, param_1);\n        return float(_1328 <= _1357);\n    }\n    float _1364 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _1367 = _1346 == 2;\n    if (_1367)\n    {\n        float _1381 = clamp(((_1156_fa_shadow_cfg.w * _1208) * 0.25f) / _1156_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1364;\n            float2 _1400 = fa_shadow_vogel(param_2, param_3, param_4) * _1381;\n            float2 param_5 = _1256.xy + (_1400 * _1156_fa_shadow_bias.zw);\n            float4 param_6 = _1156_fa_shadow_rect[ci];\n            float _1411 = fa_shadow_depth(param_5, param_6);\n            if (_1411 < (_1328 - (length(_1400) * _1337)))\n            {\n                sum += _1411;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_1328 - (sum / cnt), 0.0f) * _1208) * _1156_fa_shadow_cfg.w) / _1156_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _1455 = _1367 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1455; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1455;\n        float param_9 = _1364;\n        float2 _1474 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _1256.xy + (_1474 * _1156_fa_shadow_bias.zw);\n        float4 param_11 = _1156_fa_shadow_rect[ci];\n        float _1485 = fa_shadow_depth(param_10, param_11);\n        lit += float((_1328 - (length(_1474) * _1337)) <= _1485);\n    }\n    return lit / float(_1455);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_416_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1515 = int(_1156_fa_shadow_cfg.x + 0.5f);\n    if (_1515 < 1)\n    {\n        return 1.0f;\n    }\n    float _1530 = dot(world - _1156_fa_shadow_eye.xyz, _1156_fa_shadow_fwd.xyz);\n    int param = _1515 - 1;\n    if (_1530 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1542 = _1515 > 1;\n    bool _1549;\n    if (_1542)\n    {\n        _1549 = _1530 > _1156_fa_shadow_split.x;\n    }\n    else\n    {\n        _1549 = _1542;\n    }\n    if (_1549)\n    {\n        ci = 1;\n    }\n    bool _1553 = _1515 > 2;\n    bool _1560;\n    if (_1553)\n    {\n        _1560 = _1530 > _1156_fa_shadow_split.y;\n    }\n    else\n    {\n        _1560 = _1553;\n    }\n    if (_1560)\n    {\n        ci = 2;\n    }\n    bool _1564 = _1515 > 3;\n    bool _1571;\n    if (_1564)\n    {\n        _1571 = _1530 > _1156_fa_shadow_split.z;\n    }\n    else\n    {\n        _1571 = _1564;\n    }\n    if (_1571)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1515)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1597 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1597;\n        if (_1597 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_1156_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1622;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1622 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1622 = _1156_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1641 = _1156_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1622, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1652 = clamp((_1530 - (fa_shadow_split_at(param_7) - _1641)) / _1641, 0.0f, 1.0f);\n        if (_1652 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1515)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1673 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1673;\n                if (_1673 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1652);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1999 = fa_light_sample(param, param_1);\n    float3 _2883 = _1999.direction;\n    float3 _2878 = _1999.color;\n    float _2880 = _1999.shadow;\n    int _2888 = _1999.type;\n    if ((_2888 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2883;\n        float _2013 = fa_shadow_factor(param_2, param_3);\n        _2880 = _2013;\n        _2878 *= _2013;\n    }\n    LightSample _2895 = { _2883, _2878, _1999.attenuation, _2880, _1999._distance, _2888 };\n    return _2895;\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _1903 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _1906 = _1903.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_1906 * _1906, exp2((-9.27999973297119140625f) * ndv)) * _1906) + _1903.y)) + _1903.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_416_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _416_fa_env_horizon.w).xyz;\n    }\n    float _1809 = rough * rough;\n    float _1839 = 0.60000002384185791015625f * _1809;\n    return lerp(lerp(_416_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_416_fa_env_horizon.xyz, _416_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _1809)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _1839, 0.0500000007450580596923828125f + _1839, d.y).xxx), ((_416_fa_env_sky.xyz + _416_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_1809 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1945 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1945.x) + _1945.y.xxx);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_1156_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1697 = int(_1156_fa_shadow_cfg.x + 0.5f);\n    float _1707 = dot(world - _1156_fa_shadow_eye.xyz, _1156_fa_shadow_fwd.xyz);\n    float3 tint_1 = 0.3499999940395355224609375f.xxx;\n    bool _1712 = _1697 > 0;\n    bool _1721;\n    if (_1712)\n    {\n        int param = _1697 - 1;\n        _1721 = _1707 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1721 = _1712;\n    }\n    if (_1721)\n    {\n        tint_1 = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1728 = _1697 > 1;\n        bool _1735;\n        if (_1728)\n        {\n            _1735 = _1707 > _1156_fa_shadow_split.x;\n        }\n        else\n        {\n            _1735 = _1728;\n        }\n        if (_1735)\n        {\n            tint_1 = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1741 = _1697 > 2;\n        bool _1748;\n        if (_1741)\n        {\n            _1748 = _1707 > _1156_fa_shadow_split.y;\n        }\n        else\n        {\n            _1748 = _1741;\n        }\n        if (_1748)\n        {\n            tint_1 = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1754 = _1697 > 3;\n        bool _1761;\n        if (_1754)\n        {\n            _1761 = _1707 > _1156_fa_shadow_split.z;\n        }\n        else\n        {\n            _1761 = _1754;\n        }\n        if (_1761)\n        {\n            tint_1 = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint_1, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _2803 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2803 = -_2803;\n    }\n    float3 _2321 = normalize(_416_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _2816 = { fa_world_pos, _2803, fa_world_tangent, fa_uv, fa_vertex_color, _2321, gl_FrontFacing };\n    SurfaceInput param_1 = _2816;\n    Surface _2329 = fa_standard_surface(param_1);\n    float3 _2826 = _2329.albedo;\n    float _2827 = _2329.alpha;\n    float3 _2828 = _2329.normal;\n    float _2829 = _2329.metallic;\n    float _2830 = _2329.roughness;\n    float _2831 = _2329.occlusion;\n    float3 _2832 = _2329.emission;\n    SurfaceInput _2824 = { fa_world_pos, _2803, fa_world_tangent, fa_uv, fa_vertex_color, _2321, gl_FrontFacing };\n    SurfaceInput param_2 = _2824;\n    Surface param_3 = _2329;\n    surface(param_2, param_3);\n    _2826 = param_3.albedo;\n    _2827 = param_3.alpha;\n    _2828 = param_3.normal;\n    _2829 = param_3.metallic;\n    _2830 = param_3.roughness;\n    _2831 = param_3.occlusion;\n    _2832 = param_3.emission;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _2803;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _2826 = param_6;\n    _2828 = param_7;\n    float3 result;\n    if (_416_fa_emissive.w > 0.5f)\n    {\n        result = _2826;\n    }\n    else\n    {\n        float3 _2368 = normalize(_2828);\n        float _2375 = clamp(_2829, 0.0f, 1.0f);\n        float _2379 = clamp(_2830, 0.0500000007450580596923828125f, 1.0f);\n        float _2383 = _2379 * _2379;\n        float _2387 = _2383 * _2383;\n        float _2392 = max(dot(_2368, _2321), 9.9999997473787516355514526367188e-05f);\n        float3 _2398 = _2826 * (1.0f - _2375);\n        float3 _2406 = lerp(0.039999999105930328369140625f.xxx, _2826, _2375.xxx);\n        float3 param_8 = _2368;\n        float3 lit = (fa_ambient_light(param_8) * _2398) * _2831;\n        int _2419 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2419; ln++)\n        {\n            int param_9 = ln;\n            int _2432 = fa_cl_light(param_9);\n            int param_10 = _2432;\n            float3 param_11 = fa_world_pos;\n            float3 param_12 = _2803;\n            LightSample _2441 = fa_light_shadowed(param_10, param_11, param_12);\n            float3 _2861 = _2441.direction;\n            float _2449 = max(dot(_2368, _2861), 0.0f);\n            float3 _2460 = normalize(_2861 + _2321);\n            float _2465 = max(dot(_2368, _2460), 0.0f);\n            float _2478 = ((_2465 * _2465) * (_2387 - 1.0f)) + 1.0f;\n            int param_13 = _2432;\n            lit += (((_2398 + (((_2406 + ((1.0f.xxx - _2406) * pow(1.0f - max(dot(_2321, _2460), 0.0f), 5.0f))) * (((_2387 / ((3.1415927410125732421875f * _2478) * _2478)) * (0.5f / max(lerp((2.0f * _2449) * _2392, _2449 + _2392, _2383), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _2449))) * fa_light_rgb(param_13)) * (_2449 * (_2441.attenuation * _2441.shadow)));\n        }\n        float3 param_14 = _2368;\n        float3 param_15 = _2321;\n        float3 param_16 = _2406;\n        float param_17 = _2379;\n        float3 _2547 = lit;\n        float3 _2548 = _2547 + (fa_sky_reflection(param_14, param_15, param_16, param_17) * _2831);\n        lit = _2548;\n        result = _2548;\n    }\n    float3 _2552 = result;\n    float3 _2553 = _2552 + _2832;\n    result = _2553;\n    float3 param_18 = _2553;\n    float3 param_19 = fa_world_pos;\n    result = fa_shadow_debug(param_18, param_19);\n    bool _2562 = _416_fa_fog.w > 0.0f;\n    bool _2570;\n    if (!_2562)\n    {\n        _2570 = _416_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2570 = _2562;\n    }\n    if (_2570)\n    {\n        float3 _2579 = fa_world_pos - _416_fa_camera_pos.xyz;\n        float _2586 = dot(_2579, _416_fa_fog_c.xyz);\n        bool _2590 = _416_fa_fog_c.w > 0.5f;\n        float _2591;\n        if (_2590)\n        {\n            _2591 = _2586;\n        }\n        else\n        {\n            _2591 = length(_2579);\n        }\n        float _2603 = _2591 - _416_fa_fog_b.x;\n        if (_2603 > 0.0f)\n        {\n            float _2612 = _416_fa_fog.w * _2603;\n            float tau = _2612 * _2612;\n            if (_416_fa_fog_b.y > 0.0f)\n            {\n                float _2628;\n                if (_2590)\n                {\n                    _2628 = fa_world_pos.y - (_416_fa_fog_c.y * _2586);\n                }\n                else\n                {\n                    _2628 = _416_fa_camera_pos.y;\n                }\n                float _2649 = lerp(_2628, fa_world_pos.y, clamp(_416_fa_fog_b.x / _2591, 0.0f, 1.0f));\n                float _2653 = fa_world_pos.y - _2649;\n                float _2658 = _2649 - _416_fa_fog_b.z;\n                float _2663 = fa_world_pos.y - _416_fa_fog_b.z;\n                bool _2666 = _2658 <= 0.0f;\n                bool _2667 = !_2666;\n                bool _2673;\n                if (_2667)\n                {\n                    _2673 = _416_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2673 = _2666;\n                }\n                float _2674;\n                if (_2673)\n                {\n                    _2674 = _416_fa_fog_b.y;\n                }\n                else\n                {\n                    _2674 = _416_fa_fog_b.y * exp(-min(_416_fa_fog_b.w * _2658, 80.0f));\n                }\n                bool _2701;\n                if (_2667)\n                {\n                    _2701 = _416_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2701 = _2666;\n                }\n                float _2702;\n                if (_2701)\n                {\n                    _2702 = _416_fa_fog_b.y * _2658;\n                }\n                else\n                {\n                    _2702 = (_416_fa_fog_b.y * (1.0f - exp(-min(_416_fa_fog_b.w * _2658, 80.0f)))) / _416_fa_fog_b.w;\n                }\n                bool _2727 = _2663 <= 0.0f;\n                bool _2734;\n                if (!_2727)\n                {\n                    _2734 = _416_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2734 = _2727;\n                }\n                float _2735;\n                if (_2734)\n                {\n                    _2735 = _416_fa_fog_b.y * _2663;\n                }\n                else\n                {\n                    _2735 = (_416_fa_fog_b.y * (1.0f - exp(-min(_416_fa_fog_b.w * _2663, 80.0f)))) / _416_fa_fog_b.w;\n                }\n                float _2762;\n                if (abs(_2653) < 0.001000000047497451305389404296875f)\n                {\n                    _2762 = _2674;\n                }\n                else\n                {\n                    _2762 = (_2735 - _2702) / _2653;\n                }\n                tau += (_2603 * max(_2762, 0.0f));\n            }\n            result = lerp(result, _416_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _2827);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_inst_v0 = stage_input.fa_inst_v0;\n    fa_inst_v1 = stage_input.fa_inst_v1;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_416",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_1156",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_2038",
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _153_fa_view_proj : packoffset(c0);\n    row_major float4x4 _153_fa_light_vp : packoffset(c4);\n    float4 _153_fa_uv_scale : packoffset(c8);\n    float4 _153_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_d0;\nstatic float4 fa_inst_d1;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_inst_d0 : TEXCOORD9;\n    float4 fa_inst_d1 : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float fa_pre_depth : TEXCOORD7;\n    float3 fa_pre_r0 : TEXCOORD8;\n    float3 fa_pre_r1 : TEXCOORD9;\n    float3 fa_pre_r2 : TEXCOORD10;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float raise;\nstatic float4 tint;\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _100 = (dot(model[0].xyz, _94) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _334 = { mul(float4(position, 1.0f), model).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _100, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _100), texcoord0 * _153_fa_uv_scale.xy, color, position };\n    return _334;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _197 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -mul(_197, _153_fa_light_vp).z;\n    fa_pre_r0 = float3(_153_fa_light_vp[0].x, _153_fa_light_vp[1].x, _153_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_153_fa_light_vp[0].y, _153_fa_light_vp[1].y, _153_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_153_fa_light_vp[0].z, _153_fa_light_vp[1].z, _153_fa_light_vp[2].z);\n    gl_Position = mul(_197, _153_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_d0 = stage_input.fa_inst_d0;\n    fa_inst_d1 = stage_input.fa_inst_d1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    stage_output.fa_inst_v0 = fa_inst_v0;\n    stage_output.fa_inst_v1 = fa_inst_v1;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _142_boost : packoffset(c0);\n    float _142_fa_pad0 : packoffset(c0.y);\n    float _142_fa_pad1 : packoffset(c0.z);\n    float _142_fa_pad2 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _253_fa_camera_pos : packoffset(c0);\n    float4 _253_fa_ambient : packoffset(c1);\n    float4 _253_fa_base_color : packoffset(c2);\n    float4 _253_fa_emissive : packoffset(c3);\n    float4 _253_fa_model_emissive : packoffset(c4);\n    float4 _253_fa_pbr : packoffset(c5);\n    float4 _253_fa_maps : packoffset(c6);\n    float4 _253_fa_fog : packoffset(c7);\n    float4 _253_fa_fog_b : packoffset(c8);\n    float4 _253_fa_fog_c : packoffset(c9);\n    float4 _253_fa_counts : packoffset(c10);\n    float4 _253_fa_env_sky : packoffset(c11);\n    float4 _253_fa_env_horizon : packoffset(c12);\n    float4 _253_fa_time : packoffset(c13);\n    float4 _253_fa_cl_vpx : packoffset(c14);\n    float4 _253_fa_cl_vpy : packoffset(c15);\n    float4 _253_fa_cl_vpw : packoffset(c16);\n    float4 _253_fa_cl_fwd : packoffset(c17);\n    float4 _253_fa_cl_grid : packoffset(c18);\n    float4 _253_fa_cl_info : packoffset(c19);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float fa_pre_depth : TEXCOORD7;\n    float3 fa_pre_r0 : TEXCOORD8;\n    float3 fa_pre_r1 : TEXCOORD9;\n    float3 fa_pre_r2 : TEXCOORD10;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float raise;\nstatic float4 tint;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    float3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    float3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    float3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _253_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _264 = fa_tex_fix(param_2, param_3);\n    float4 _625 = base_t;\n    _625.x = _264.x;\n    _625.y = _264.y;\n    _625.z = _264.z;\n    base_t = _625;\n    float4 _280 = (_625 * _253_fa_base_color) * i.vertex_color;\n    float3 _606 = i.world_normal;\n    if (_253_fa_maps.z > 0.5f)\n    {\n        float param_4 = _253_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _313 = fa_tex_fix(param_6, param_7);\n        float3 _317 = (_313 * 2.0f) - 1.0f.xxx;\n        float2 _322 = _317.xy * _253_fa_maps.x;\n        float3 _633 = _317;\n        _633.x = _322.x;\n        _633.y = _322.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _633;\n        _606 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _253_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _351 = fa_tex_fix(param_12, param_13);\n    float4 _636 = mrt;\n    _636.x = _351.x;\n    _636.y = _351.y;\n    _636.z = _351.z;\n    mrt = _636;\n    float param_14 = _253_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _392 = fa_tex_fix(param_16, param_17);\n    float param_18 = _253_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _419 = fa_tex_fix(param_20, param_21);\n    Surface _618 = { _280.xyz, _280.w, _606, clamp(_253_fa_pbr.x * _351.z, 0.0f, 1.0f), clamp(_253_fa_pbr.y * _351.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_253_fa_maps.y * (_392.x - 1.0f)), _253_fa_emissive.xyz + (_253_fa_model_emissive.xyz * _419) };\n    return _618;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * _142_boost);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _553 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _553 = -_553;\n    }\n    float3 _464 = normalize(_253_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _566 = { fa_world_pos, _553, fa_world_tangent, fa_uv, fa_vertex_color, _464, gl_FrontFacing };\n    SurfaceInput param = _566;\n    SurfaceInput _574 = { fa_world_pos, _553, fa_world_tangent, fa_uv, fa_vertex_color, _464, gl_FrontFacing };\n    SurfaceInput param_1 = _574;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _479 = normalize(param_2.normal);\n    float3 _494 = normalize(float3(dot(fa_pre_r0, _479), dot(fa_pre_r1, _479), dot(fa_pre_r2, _479)));\n    float _506 = _494.z;\n    float2 e = _494.xy / ((abs(_494.x) + abs(_494.y)) + abs(_506)).xx;\n    if (_506 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_inst_v0 = stage_input.fa_inst_v0;\n    fa_inst_v1 = stage_input.fa_inst_v1;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 320,
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _142_boost : packoffset(c0);\n    float _142_fa_pad0 : packoffset(c0.y);\n    float _142_fa_pad1 : packoffset(c0.z);\n    float _142_fa_pad2 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _253_fa_camera_pos : packoffset(c0);\n    float4 _253_fa_ambient : packoffset(c1);\n    float4 _253_fa_base_color : packoffset(c2);\n    float4 _253_fa_emissive : packoffset(c3);\n    float4 _253_fa_model_emissive : packoffset(c4);\n    float4 _253_fa_pbr : packoffset(c5);\n    float4 _253_fa_maps : packoffset(c6);\n    float4 _253_fa_fog : packoffset(c7);\n    float4 _253_fa_fog_b : packoffset(c8);\n    float4 _253_fa_fog_c : packoffset(c9);\n    float4 _253_fa_counts : packoffset(c10);\n    float4 _253_fa_env_sky : packoffset(c11);\n    float4 _253_fa_env_horizon : packoffset(c12);\n    float4 _253_fa_time : packoffset(c13);\n    float4 _253_fa_cl_vpx : packoffset(c14);\n    float4 _253_fa_cl_vpy : packoffset(c15);\n    float4 _253_fa_cl_vpw : packoffset(c16);\n    float4 _253_fa_cl_fwd : packoffset(c17);\n    float4 _253_fa_cl_grid : packoffset(c18);\n    float4 _253_fa_cl_info : packoffset(c19);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float fa_pre_depth : TEXCOORD7;\n    float3 fa_pre_r0 : TEXCOORD8;\n    float3 fa_pre_r1 : TEXCOORD9;\n    float3 fa_pre_r2 : TEXCOORD10;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float raise;\nstatic float4 tint;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    float3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    float3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    float3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _253_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _264 = fa_tex_fix(param_2, param_3);\n    float4 _625 = base_t;\n    _625.x = _264.x;\n    _625.y = _264.y;\n    _625.z = _264.z;\n    base_t = _625;\n    float4 _280 = (_625 * _253_fa_base_color) * i.vertex_color;\n    float3 _606 = i.world_normal;\n    if (_253_fa_maps.z > 0.5f)\n    {\n        float param_4 = _253_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _313 = fa_tex_fix(param_6, param_7);\n        float3 _317 = (_313 * 2.0f) - 1.0f.xxx;\n        float2 _322 = _317.xy * _253_fa_maps.x;\n        float3 _633 = _317;\n        _633.x = _322.x;\n        _633.y = _322.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _633;\n        _606 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _253_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _351 = fa_tex_fix(param_12, param_13);\n    float4 _636 = mrt;\n    _636.x = _351.x;\n    _636.y = _351.y;\n    _636.z = _351.z;\n    mrt = _636;\n    float param_14 = _253_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _392 = fa_tex_fix(param_16, param_17);\n    float param_18 = _253_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _419 = fa_tex_fix(param_20, param_21);\n    Surface _618 = { _280.xyz, _280.w, _606, clamp(_253_fa_pbr.x * _351.z, 0.0f, 1.0f), clamp(_253_fa_pbr.y * _351.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_253_fa_maps.y * (_392.x - 1.0f)), _253_fa_emissive.xyz + (_253_fa_model_emissive.xyz * _419) };\n    return _618;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * _142_boost);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _553 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _553 = -_553;\n    }\n    float3 _464 = normalize(_253_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _566 = { fa_world_pos, _553, fa_world_tangent, fa_uv, fa_vertex_color, _464, gl_FrontFacing };\n    SurfaceInput param = _566;\n    SurfaceInput _574 = { fa_world_pos, _553, fa_world_tangent, fa_uv, fa_vertex_color, _464, gl_FrontFacing };\n    SurfaceInput param_1 = _574;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _479 = normalize(param_2.normal);\n    float3 _494 = normalize(float3(dot(fa_pre_r0, _479), dot(fa_pre_r1, _479), dot(fa_pre_r2, _479)));\n    float _506 = _494.z;\n    float2 e = _494.xy / ((abs(_494.x) + abs(_494.y)) + abs(_506)).xx;\n    if (_506 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_inst_v0 = stage_input.fa_inst_v0;\n    fa_inst_v1 = stage_input.fa_inst_v1;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 320,
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
