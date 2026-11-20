{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "5f457c7d0bc8edbcdea422ba00c093c613745eefd8db6d8c8f93fc5e235db1e8",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _260 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _260;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_267, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _384_fa_camera_pos : packoffset(c0);\n    float4 _384_fa_ambient : packoffset(c1);\n    float4 _384_fa_base_color : packoffset(c2);\n    float4 _384_fa_emissive : packoffset(c3);\n    float4 _384_fa_model_emissive : packoffset(c4);\n    float4 _384_fa_pbr : packoffset(c5);\n    float4 _384_fa_maps : packoffset(c6);\n    float4 _384_fa_fog : packoffset(c7);\n    float4 _384_fa_fog_b : packoffset(c8);\n    float4 _384_fa_fog_c : packoffset(c9);\n    float4 _384_fa_counts : packoffset(c10);\n    float4 _384_fa_env_sky : packoffset(c11);\n    float4 _384_fa_env_horizon : packoffset(c12);\n    float4 _384_fa_time : packoffset(c13);\n    float4 _384_fa_cl_vpx : packoffset(c14);\n    float4 _384_fa_cl_vpy : packoffset(c15);\n    float4 _384_fa_cl_vpw : packoffset(c16);\n    float4 _384_fa_cl_fwd : packoffset(c17);\n    float4 _384_fa_cl_grid : packoffset(c18);\n    float4 _384_fa_cl_info : packoffset(c19);\n    float4 _384_fa_layers_a : packoffset(c20);\n    float4 _384_fa_layers_b : packoffset(c21);\n    float4 _384_fa_layers_c : packoffset(c22);\n    float4 _384_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2041_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2041_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2041_fa_shadow_info[4] : packoffset(c20);\n    float4 _2041_fa_shadow_split : packoffset(c24);\n    float4 _2041_fa_shadow_cfg : packoffset(c25);\n    float4 _2041_fa_shadow_bias : packoffset(c26);\n    float4 _2041_fa_shadow_eye : packoffset(c27);\n    float4 _2041_fa_shadow_fwd : packoffset(c28);\n    float4 _2041_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1312 = _384_fa_cl_info.x < 0.0f;\n    bool _1319;\n    if (!_1312)\n    {\n        _1319 = _384_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1319 = _1312;\n    }\n    bool _1327;\n    if (!_1319)\n    {\n        _1327 = _384_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1327 = _1319;\n    }\n    bool _1334;\n    if (!_1327)\n    {\n        _1334 = _384_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1334 = _1327;\n    }\n    bool _1341;\n    if (!_1334)\n    {\n        _1341 = _384_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1341 = _1334;\n    }\n    if (_1341)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1351 = float4(world_pos, 1.0f);\n    float _1357 = dot(_384_fa_cl_vpw, _1351);\n    if (!(_1357 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1379 = float2(dot(_384_fa_cl_vpx, _1351), dot(_384_fa_cl_vpy, _1351)) / _1357.xx;\n    int _1383 = int(_384_fa_cl_grid.x);\n    int _1387 = int(_384_fa_cl_grid.y);\n    int param = (int(_384_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_384_fa_cl_fwd.xyz, world_pos) + _384_fa_cl_fwd.w, _384_fa_cl_grid.w) / _384_fa_cl_grid.w) * _384_fa_cl_grid.z)), 0, int(_384_fa_cl_info.y) - 1) * _1387) + clamp(int(floor(((_1379.y * 0.5f) + 0.5f) * _384_fa_cl_grid.y)), 0, _1387 - 1)) * _1383)) + clamp(int(floor(((_1379.x * 0.5f) + 0.5f) * _384_fa_cl_grid.x)), 0, _1383 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1463 = fa_cluster_texel(param);\n    return int2(int(_1463.x), int(_1463.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_384_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3241 = fa_cluster_lookup(param);\n    fa_cl_slot = _3241.x;\n    fa_cl_local = _3241.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _3402 = fa_linear_to_srgb(param);\n        c = _3402;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _3410 = fa_srgb_to_linear(param_1);\n            c = _3410;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _267;\n    if (i.front_facing)\n    {\n        _267 = i.world_normal;\n    }\n    else\n    {\n        _267 = -i.world_normal;\n    }\n    float3 _291 = normalize(i.world_tangent.xyz - (_267 * dot(_267, i.world_tangent.xyz)));\n    float3 _318 = normalize(((_291 * m.x) + ((cross(_267, _291) * i.world_tangent.w) * m.y)) + (_267 * m.z));\n    float3 _321;\n    if (i.front_facing)\n    {\n        _321 = _318;\n    }\n    else\n    {\n        _321 = -_318;\n    }\n    return _321;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _384_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3441 = fa_tex_fix(param_2, param_3);\n    float4 _4489 = base_t;\n    _4489.x = _3441.x;\n    _4489.y = _3441.y;\n    _4489.z = _3441.z;\n    base_t = _4489;\n    float4 _3455 = (_4489 * _384_fa_base_color) * i.vertex_color;\n    float3 _4354 = i.world_normal;\n    if (_384_fa_maps.z > 0.5f)\n    {\n        float param_4 = _384_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3487 = fa_tex_fix(param_6, param_7);\n        float3 _3490 = (_3487 * 2.0f) - 1.0f.xxx;\n        float2 _3495 = _3490.xy * _384_fa_maps.x;\n        float3 _4497 = _3490;\n        _4497.x = _3495.x;\n        _4497.y = _3495.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4497;\n        _4354 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _384_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3523 = fa_tex_fix(param_12, param_13);\n    float4 _4500 = mrt;\n    _4500.x = _3523.x;\n    _4500.y = _3523.y;\n    _4500.z = _3523.z;\n    mrt = _4500;\n    float4 _3551 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _384_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _3551.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3562 = fa_tex_fix(param_16, param_17);\n    float param_18 = _384_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3592 = fa_tex_fix(param_20, param_21);\n    float _4359 = _384_fa_layers_a.x;\n    float _4360 = _384_fa_layers_a.y;\n    float _4363 = _384_fa_layers_a.z;\n    float _4362 = _384_fa_layers_b.w;\n    float _4365 = _384_fa_layers_c.x;\n    if (_384_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_384_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _4359 *= _3562.y;\n            _4360 *= _3562.z;\n            _4362 *= _3551.w;\n        }\n        if (_384_fa_layers_c.z > 1.5f)\n        {\n            _4363 *= mrt.x;\n            _4365 *= mrt.w;\n        }\n    }\n    Surface _4384 = { _3455.xyz, _3455.w, _4354, clamp(_384_fa_pbr.x * _3523.z, 0.0f, 1.0f), clamp(_384_fa_pbr.y * _3523.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_384_fa_maps.y * (_3562.x - 1.0f)), _384_fa_emissive.xyz + (_384_fa_model_emissive.xyz * _3592), _4359, _4360, _384_fa_layers_b.xyz, _4362, _4363, _384_fa_layers_a.w, _4365, _384_fa_layers_c.y, _384_fa_layers_d.xyz };\n    return _4384;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1543 = rect.zw - rect.xy;\n    float2 _1547 = _1543 * atlas;\n    float2 _1551 = ddx * _1547;\n    float2 _1555 = ddy * _1547;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1543), clamp(0.5f * log2(max(max(dot(_1551, _1551), dot(_1555, _1555)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1588 = _384_fa_counts.y < 0.5f;\n    bool _1595;\n    if (!_1588)\n    {\n        _1595 = _384_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1595 = _1588;\n    }\n    if (_1595)\n    {\n        return;\n    }\n    float3 _1601 = ddx(world_pos);\n    float3 _1604 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1608 = fa_cluster_texel(param);\n    int _1612 = int(_1608.w);\n    if (_1612 < 1)\n    {\n        return;\n    }\n    int _1622 = int(_384_fa_counts.y + 0.5f);\n    int param_1 = _1622;\n    float4 _1626 = fa_light_texel(param_1);\n    float2 _1629 = _1626.yz;\n    int _1633 = int(_1626.w);\n    int param_2 = _1622 + 1;\n    float4 _1638 = fa_light_texel(param_2);\n    float _1639 = _1638.x;\n    int _1645 = int(_384_fa_counts.w + 0.5f) - 1;\n    int _1649 = int(_1608.z);\n    float3 _1914;\n    for (int k = 0; k < _1612; k++)\n    {\n        int _1662 = _1649 + k;\n        int param_3 = _1633 + (_1662 >> 2);\n        int _1679 = (_1622 + 2) + (int(fa_light_texel(param_3)[_1662 & 3]) * 7);\n        int param_4 = _1679 + 6;\n        float4 _1684 = fa_light_texel(param_4);\n        if (((int(_1684.w + 0.5f) >> _1645) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1679;\n        float4 _1699 = fa_light_texel(param_5);\n        int param_6 = _1679 + 1;\n        float4 _1704 = fa_light_texel(param_6);\n        int param_7 = _1679 + 2;\n        float4 _1709 = fa_light_texel(param_7);\n        float3 _1712 = _1699.xyz;\n        float _1717 = dot(_1712, world_pos) + _1699.w;\n        float3 _1719 = _1704.xyz;\n        float _1724 = dot(_1719, world_pos) + _1704.w;\n        float3 _1726 = _1709.xyz;\n        float _1731 = dot(_1726, world_pos) + _1709.w;\n        bool _1736 = abs(_1717) > 0.5f;\n        bool _1744;\n        if (!_1736)\n        {\n            _1744 = abs(_1724) > 0.5f;\n        }\n        else\n        {\n            _1744 = _1736;\n        }\n        bool _1752;\n        if (!_1744)\n        {\n            _1752 = abs(_1731) > 0.5f;\n        }\n        else\n        {\n            _1752 = _1744;\n        }\n        if (_1752)\n        {\n            continue;\n        }\n        float _1767 = clamp(dot(geo_normal, normalize(_1726)) * _1684.z, 0.0f, 1.0f);\n        if (_1767 <= 0.0f)\n        {\n            continue;\n        }\n        float _1787 = (clamp((0.5f - abs(_1731)) * 10.0f, 0.0f, 1.0f) * _1767) * _1684.x;\n        float2 _1795 = float2(_1717 + 0.5f, 0.5f - _1724);\n        float2 _1805 = float2(dot(_1712, _1601), dot(_1719, _1601));\n        float2 _1815 = float2(dot(_1712, _1604), dot(_1719, _1604));\n        int param_8 = _1679 + 5;\n        float4 _1820 = fa_light_texel(param_8);\n        int param_9 = _1679 + 3;\n        float4 _1825 = fa_light_texel(param_9);\n        int param_10 = _1679 + 4;\n        float4 _1830 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1820.xyz;\n        bool _1840 = _1825.z > _1825.x;\n        if (_1840)\n        {\n            float4 param_11 = _1825;\n            float2 param_12 = _1795;\n            float2 param_13 = _1629;\n            float2 param_14 = _1805;\n            float2 param_15 = _1815;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1639 > 0.5f) && (_1639 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1866 = fa_dc_to_linear(param_16);\n                float4 _4434 = tx;\n                _4434.x = _1866.x;\n                _4434.y = _1866.y;\n                _4434.z = _1866.z;\n                tx = _4434;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1787 * tex_a) * _1820.w, 0.0f, 1.0f).xxx);\n        if (_1830.z > _1830.x)\n        {\n            float4 param_17 = _1830;\n            float2 param_18 = _1795;\n            float2 param_19 = _1629;\n            float2 param_20 = _1805;\n            float2 param_21 = _1815;\n            float4 _1910 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1639 > 1.5f)\n            {\n                float3 param_22 = _1910.xyz;\n                float3 _1920 = fa_dc_to_srgb(param_22);\n                _1914 = _1920;\n            }\n            else\n            {\n                _1914 = _1910.xyz;\n            }\n            float3 _1929 = (_1914 * 2.0f) - 1.0f.xxx;\n            float2 _1934 = _1929.xy * _1684.y;\n            float3 _1956 = (normalize(_1712) * _1934.x) + (normalize(_1719) * _1934.y);\n            float3 _1959 = normalize(normal);\n            normal = normalize(lerp(_1959, normalize((_1959 * max(_1929.z, 0.0500000007450580596923828125f)) + (_1956 - (_1959 * dot(_1959, _1956)))), clamp(_1787 * (_1840 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_sky_sh_coef(int k)\n{\n    float3 v = fa_env_tex.SampleLevel(fa_env_smp, float3(1.0f, 1.0f - (float((2 * (k >> 2)) + 1) * 0.25f), 1.0f - (float((2 * (k & 3)) + 1) * 0.25f)), 5.0f).xyz;\n    if (_384_fa_env_sky.w > 1.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3154 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3154;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_384_fa_env_sky.w > 0.5f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _384_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    return float3(0.0f, ambientColor.y, 0.0f);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_384_fa_cl_info.x) + int(_384_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_384_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _443_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _443_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _562 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _575 = (c - (ru * hx)) - p;\n        float3 _581 = ru * (2.0f * hx);\n        float _587 = max(dot(_581, _581), 9.9999999392252902907785028219223e-09f);\n        float _591 = dot(_575, _581);\n        float t = clamp((-_591) / _587, 0.0f, 1.0f);\n        if (_562)\n        {\n            float _606 = dot(r, _581);\n            float _612 = _587 - (_606 * _606);\n            if (abs(_612) > (9.9999997473787516355514526367188e-06f * _587))\n            {\n                t = clamp(((dot(r, _575) * _606) - _591) / _612, 0.0f, 1.0f);\n            }\n        }\n        return (p + _575) + (_581 * t);\n    }\n    float3 q = p;\n    float _644 = dot(r, axis);\n    bool _652;\n    if (_562)\n    {\n        _652 = abs(_644) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _652 = _562;\n    }\n    if (_652)\n    {\n        float _662 = dot(c - p, axis) / _644;\n        if (_662 > 0.0f)\n        {\n            q = p + (r * _662);\n        }\n    }\n    float3 _675 = q - c;\n    float2 xy = float2(dot(_675, ru), dot(_675, uu));\n    if (shape > 0.5f)\n    {\n        float _690 = length(xy);\n        if (_690 > hx)\n        {\n            xy *= (hx / _690);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _333 = abs(d);\n    float _335 = _333.x;\n    float _337 = _333.y;\n    bool _338 = _335 >= _337;\n    bool _346;\n    if (_338)\n    {\n        _346 = _335 >= _333.z;\n    }\n    else\n    {\n        _346 = _338;\n    }\n    int _347;\n    if (_346)\n    {\n        _347 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _362;\n        if (_337 >= _333.z)\n        {\n            _362 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _362 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _347 = _362;\n    }\n    return _347;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _482 = dot(d, right);\n    float _486 = dot(d, up);\n    float _497;\n    if (((_482 * _482) + (_486 * _486)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _497 = atan2(_486, _482) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _497 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_497 - floor(_497)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _728 = fa_light_base(param);\n    bool _732 = _384_fa_ambient.w > 4.5f;\n    int param_1 = _728;\n    float4 _736 = fa_light_texel(param_1);\n    int param_2 = _728 + 1;\n    float4 _741 = fa_light_texel(param_2);\n    float _744 = _741.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _756 = _732 && (_744 > 2.5f);\n    fa_light_is_area = _756;\n    bool _758 = _744 < 0.5f;\n    float3 l;\n    if (_758)\n    {\n        l = normalize(_736.xyz);\n        if (_732)\n        {\n            int param_3 = _728 + 6;\n            float4 _772 = fa_light_texel(param_3);\n            if (_772.z > 0.5f)\n            {\n                int param_4 = _728 + 4;\n                float4 _782 = fa_light_texel(param_4);\n                int param_5 = _728 + 5;\n                float4 _787 = fa_light_texel(param_5);\n                float2 param_6 = _772.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _782.xyz) * _782.w, (-dot(world_pos, _787.xyz)) * _787.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _817 = _736.xyz;\n        float3 _819 = _817 - world_pos;\n        float3 to_light = _819;\n        float _822 = length(_819);\n        float reach = _822;\n        bool front = true;\n        if (_756)\n        {\n            int param_8 = _728 + 7;\n            reach = max(_822 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _728 + 4;\n            float4 _846 = fa_light_texel(param_9);\n            int param_10 = _728 + 5;\n            float4 _851 = fa_light_texel(param_10);\n            int param_11 = _728 + 6;\n            float4 _856 = fa_light_texel(param_11);\n            float _857 = _856.w;\n            int param_12 = _728 + 2;\n            float3 _864 = normalize(fa_light_texel(param_12).xyz);\n            bool _866 = _857 > 1.5f;\n            bool _874;\n            if (!_866)\n            {\n                _874 = dot(_864, to_light) < 0.0f;\n            }\n            else\n            {\n                _874 = _866;\n            }\n            front = _874;\n            float3 r = 0.0f.xxx;\n            float3 _883 = _384_fa_camera_pos.xyz - world_pos;\n            bool _887 = dot(n, n) > 0.5f;\n            bool _895;\n            if (_887)\n            {\n                _895 = dot(_883, _883) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _895 = _887;\n            }\n            if (_895)\n            {\n                r = reflect(-normalize(_883), normalize(n));\n            }\n            float3 param_13 = _817;\n            float3 param_14 = _864;\n            float3 param_15 = _846.xyz;\n            float3 param_16 = _851.xyz;\n            float param_17 = _846.w;\n            float param_18 = _851.w;\n            float param_19 = _857;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _931 = length(to_light);\n        dist = _931;\n        l = to_light / max(_931, 9.9999997473787516355514526367188e-05f).xxx;\n        float _945 = reach / max(_736.w, 0.001000000047497451305389404296875f);\n        float _951 = clamp(1.0f - (_945 * _945), 0.0f, 1.0f);\n        float _953;\n        if (front)\n        {\n            _953 = _951 * _951;\n        }\n        else\n        {\n            _953 = 0.0f;\n        }\n        atten = _953;\n        bool _964 = _744 < 2.5f;\n        if ((_744 > 1.5f) && _964)\n        {\n            int param_22 = _728 + 2;\n            float4 _972 = fa_light_texel(param_22);\n            float _982 = _972.w;\n            int param_23 = _728 + 3;\n            float4 _987 = fa_light_texel(param_23);\n            float _988 = _987.x;\n            float cos_inner = _988;\n            if (_988 > 1.5f)\n            {\n                cos_inner = lerp(_982, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_982, cos_inner, dot(-l, normalize(_972.xyz)));\n        }\n        if (_732 && (_744 < 1.5f))\n        {\n            int param_24 = _728 + 6;\n            float4 _1012 = fa_light_texel(param_24);\n            if (_1012.z > 0.5f)\n            {\n                float3 _1020 = -to_light;\n                int param_25 = _728 + 4;\n                int param_26 = _728 + 5;\n                float3 _1034 = fa_light_texel(param_25).xyz;\n                float3 _1038 = fa_light_texel(param_26).xyz;\n                float3 _1047 = float3(dot(_1020, _1034), dot(_1020, _1038), dot(_1020, cross(_1034, _1038)));\n                float3 param_27 = _1047;\n                int _1051 = fa_cube_face(param_27);\n                int param_28 = _1051;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1078 = float2(dot(_1047, cross(param_29, param_30)), dot(_1047, param_30)) / max(dot(_1047, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1082 = _1051 / 3;\n                float2 param_31 = _1012.xy + (float2(float(_1051 - (_1082 * 3)), float(_1082)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1078.x), 0.5f - (0.5f * _1078.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _728 + 7;\n            float4 _1112 = fa_light_texel(param_33);\n            if (_1112.z > 0.5f)\n            {\n                int param_34 = _728 + 2;\n                int param_35 = _728 + 4;\n                int param_36 = _728 + 5;\n                float2 param_37 = _1112.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_732 && _964)\n            {\n                int param_42 = _728 + 6;\n                float4 _1159 = fa_light_texel(param_42);\n                int param_43 = _728 + 7;\n                float4 _1164 = fa_light_texel(param_43);\n                bool _1167 = _1159.z > 0.5f;\n                bool _1174;\n                if (!_1167)\n                {\n                    _1174 = _1164.z > 0.5f;\n                }\n                else\n                {\n                    _1174 = _1167;\n                }\n                if (_1174)\n                {\n                    int param_44 = _728 + 2;\n                    float4 _1181 = fa_light_texel(param_44);\n                    float3 _1185 = normalize(_1181.xyz);\n                    int param_45 = _728 + 4;\n                    float4 _1190 = fa_light_texel(param_45);\n                    int param_46 = _728 + 5;\n                    float4 _1195 = fa_light_texel(param_46);\n                    if (_1167)\n                    {\n                        float3 _1203 = -to_light;\n                        float _1210 = _1181.w;\n                        float _1226 = 0.5f / max(dot(_1203, _1185) * (sqrt(max(1.0f - (_1210 * _1210), 0.0f)) / max(_1210, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1159.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1203, _1190.xyz) * _1226), 0.5f - (dot(_1203, _1195.xyz) * _1226));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1164.z > 0.5f)\n                    {\n                        float2 param_49 = _1164.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1185;\n                        float3 param_52 = _1190.xyz;\n                        float3 param_53 = _1195.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4308 = _741.xyz * atten;\n    if (_732)\n    {\n        _4308 *= fa_light_tint;\n    }\n    int _1294;\n    if (_758)\n    {\n        _1294 = 0;\n    }\n    else\n    {\n        _1294 = ((_744 > 1.5f) && (_744 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _4319 = { l, _4308, atten, 1.0f, dist, _1294 };\n    return _4319;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2031;\n    if (i == 0)\n    {\n        _2031 = _2041_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2047;\n        if (i == 1)\n        {\n            _2047 = _2041_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2055;\n            if (i == 2)\n            {\n                _2055 = _2041_fa_shadow_split.z;\n            }\n            else\n            {\n                _2055 = _2041_fa_shadow_split.w;\n            }\n            _2047 = _2055;\n        }\n        _2031 = _2047;\n    }\n    return _2031;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2088 = fa_shadow_depth(param, param_1);\n    float _2092;\n    if (conv.x < 0.5f)\n    {\n        _2092 = _2088;\n    }\n    else\n    {\n        _2092 = (conv.y * conv.z) / (conv.z - (_2088 * (conv.z - conv.y)));\n    }\n    return _2092;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2019 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2019), sin(_2019)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2138 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2147;\n        if (k < 0.0f)\n        {\n            _2147 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2147 = k;\n        }\n        float _2167 = clamp((_2147 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2138;\n            float2 _2186 = fa_shadow_vogel(param_3, param_4, param_5) * _2167;\n            float2 param_6 = uv + (_2186 * _2041_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2198 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2198 < (zr - (length(_2186) * plane)))\n            {\n                sum += _2198;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2224 = sum / cnt;\n        float _2234;\n        if (k < 0.0f)\n        {\n            _2234 = (-k) / max(_2224, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2234 = k;\n        }\n        radius = clamp(((max(zr - _2224, 0.0f) * unit) * _2234) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2256 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2256; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2256;\n        float param_11 = _2138;\n        float2 _2275 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2275 * _2041_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2275) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2256);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2317 = max(_2041_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2322 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2328 = sqrt(1.0f - (_2322 * _2322));\n    float _2335 = min(_2328 / max(_2322, 0.20000000298023223876953125f), 4.0f);\n    float _2340;\n    if (_2041_fa_shadow_bias.y > 0.0f)\n    {\n        _2340 = _2041_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2340 = 1.5f * _2041_fa_shadow_info[ci].x;\n    }\n    float4 _2365 = mul(float4(world + (n * (_2340 * _2328)), 1.0f), _2041_fa_shadow_mat[ci]);\n    float _2372 = _2365.x;\n    bool _2375 = _2372 < _2041_fa_shadow_rect[ci].x;\n    bool _2384;\n    if (!_2375)\n    {\n        _2384 = _2372 > _2041_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2384 = _2375;\n    }\n    bool _2393;\n    if (!_2384)\n    {\n        _2393 = _2365.y < _2041_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2393 = _2384;\n    }\n    bool _2402;\n    if (!_2393)\n    {\n        _2402 = _2365.y > _2041_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2402 = _2393;\n    }\n    bool _2409;\n    if (!_2402)\n    {\n        _2409 = _2365.z > 1.0f;\n    }\n    else\n    {\n        _2409 = _2402;\n    }\n    if (_2409)\n    {\n        return -1.0f;\n    }\n    float _2417;\n    if (_2041_fa_shadow_bias.x > 0.0f)\n    {\n        _2417 = _2041_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2417 = 1.5f * _2041_fa_shadow_info[ci].x;\n    }\n    float2 param = _2365.xy;\n    float4 param_1 = _2041_fa_shadow_rect[ci];\n    float param_2 = _2365.z - ((_2417 * (1.0f + (0.5f * _2335))) / _2317);\n    float param_3 = _2041_fa_shadow_info[ci].x;\n    float param_4 = _2317;\n    float param_5 = _2317 * 0.25f;\n    float param_6 = ((_2041_fa_shadow_info[ci].x * min(_2335, 3.0f)) * 0.5f) / _2317;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2041_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2041_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_384_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2795 = int(_2041_fa_shadow_cfg.x + 0.5f);\n    if (_2795 < 1)\n    {\n        return 1.0f;\n    }\n    float _2810 = dot(world - _2041_fa_shadow_eye.xyz, _2041_fa_shadow_fwd.xyz);\n    int param = _2795 - 1;\n    if (_2810 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2822 = _2795 > 1;\n    bool _2829;\n    if (_2822)\n    {\n        _2829 = _2810 > _2041_fa_shadow_split.x;\n    }\n    else\n    {\n        _2829 = _2822;\n    }\n    if (_2829)\n    {\n        ci = 1;\n    }\n    bool _2833 = _2795 > 2;\n    bool _2840;\n    if (_2833)\n    {\n        _2840 = _2810 > _2041_fa_shadow_split.y;\n    }\n    else\n    {\n        _2840 = _2833;\n    }\n    if (_2840)\n    {\n        ci = 2;\n    }\n    bool _2844 = _2795 > 3;\n    bool _2851;\n    if (_2844)\n    {\n        _2851 = _2810 > _2041_fa_shadow_split.z;\n    }\n    else\n    {\n        _2851 = _2844;\n    }\n    if (_2851)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2795)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2877 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2877;\n        if (_2877 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2041_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2902;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2902 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2902 = _2041_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2921 = _2041_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2902, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2932 = clamp((_2810 - (fa_shadow_split_at(param_7) - _2921)) / _2921, 0.0f, 1.0f);\n        if (_2932 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2795)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2953 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2953;\n                if (_2953 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2932);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2475 = _384_fa_pbr.z < 0.5f;\n    bool _2482;\n    if (!_2475)\n    {\n        _2482 = _2041_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2482 = _2475;\n    }\n    if (_2482)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2041_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2495 = fa_light_texel(param);\n    float _2496 = _2495.x;\n    if (_2496 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2505 = int(_2496 + 0.5f);\n    int param_1 = _2505;\n    float4 _2509 = fa_light_texel(param_1);\n    int param_2 = _2505 + 1;\n    float4 _2514 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2517 = _2509.y;\n    if (_2517 > 0.0f)\n    {\n        float _2534 = 1.0f - smoothstep(0.75f * _2517, _2517, length(world - _2041_fa_shadow_eye.xyz));\n        fade = _2534;\n        if (_2534 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2509.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2558 = (_2505 + 2) + (face * 6);\n    int param_4 = _2558;\n    int param_5 = _2558 + 1;\n    int param_6 = _2558 + 3;\n    float4 _2572 = fa_light_texel(param_6);\n    int param_7 = _2558 + 4;\n    float4 _2577 = fa_light_texel(param_7);\n    int param_8 = _2558 + 5;\n    float4 _2582 = fa_light_texel(param_8);\n    float _2594 = _2582.x * max(dot(_2572, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2599 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2622 = clamp(dot(n, _2572.xyz), -1.0f, 1.0f);\n    float _2641 = min(sqrt(1.0f - (_2622 * _2622)) / max(abs(dot(n, world - lpos)) / max(dot(_2572, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2644 = _2514.y;\n    float _2646;\n    if (_2644 > 0.0f)\n    {\n        _2646 = _2644;\n    }\n    else\n    {\n        _2646 = 1.5f * _2594;\n    }\n    float4 _2666 = float4(world + (n * (_2646 * sqrt(1.0f - (_2599 * _2599)))), 1.0f);\n    float _2670 = dot(_2572, _2666);\n    float _2673 = _2582.y;\n    if (_2670 < _2673)\n    {\n        return 1.0f;\n    }\n    float2 _2688 = float2(dot(fa_light_texel(param_4), _2666), dot(fa_light_texel(param_5), _2666)) / _2670.xx;\n    float _2690 = _2688.x;\n    bool _2693 = _2690 < _2577.x;\n    bool _2702;\n    if (!_2693)\n    {\n        _2702 = _2690 > _2577.z;\n    }\n    else\n    {\n        _2702 = _2693;\n    }\n    bool _2711;\n    if (!_2702)\n    {\n        _2711 = _2688.y < _2577.y;\n    }\n    else\n    {\n        _2711 = _2702;\n    }\n    bool _2720;\n    if (!_2711)\n    {\n        _2720 = _2688.y > _2577.w;\n    }\n    else\n    {\n        _2720 = _2711;\n    }\n    if (_2720)\n    {\n        return 1.0f;\n    }\n    float _2726 = _2514.x;\n    float _2728;\n    if (_2726 > 0.0f)\n    {\n        _2728 = _2726;\n    }\n    else\n    {\n        _2728 = 1.5f * _2594;\n    }\n    float2 param_9 = _2688;\n    float4 param_10 = _2577;\n    float param_11 = _2670 - (_2728 * (1.0f + (0.5f * _2641)));\n    float param_12 = _2594;\n    float param_13 = 1.0f;\n    float param_14 = _2582.z * 0.25f;\n    float param_15 = (_2594 * min(_2641, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2673, _2582.z);\n    int param_17 = int(_2509.z + 0.5f);\n    float param_18 = _2509.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _3268 = fa_lm.z > 0.5f;\n    bool _3274;\n    if (_3268)\n    {\n        int param = li;\n        _3274 = fa_light_baked(param);\n    }\n    else\n    {\n        _3274 = _3268;\n    }\n    if (_3274)\n    {\n        int param_1 = li;\n        LightSample _4332 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _4332;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3298 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _4334 = _3298.color;\n    float _4336 = _3298.shadow;\n    if ((_3298.type == 0) && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3298.direction;\n        float _3312 = fa_shadow_factor(param_5, param_6);\n        _4336 = _3312;\n        _4334 *= _3312;\n    }\n    else\n    {\n        bool _3323 = _3298.type != 0;\n        bool _3329;\n        if (_3323)\n        {\n            _3329 = _3298.attenuation > 0.0f;\n        }\n        else\n        {\n            _3329 = _3323;\n        }\n        if (_3329)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _3298.direction;\n            float _3348 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _4336 = _3348;\n            _4334 *= _3348;\n        }\n    }\n    LightSample _4351 = { _3298.direction, _4334, _3298.attenuation, _4336, _3298._distance, _3298.type };\n    return _4351;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2041_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _2977 = int(_2041_fa_shadow_cfg.x + 0.5f);\n    float _2987 = dot(world - _2041_fa_shadow_eye.xyz, _2041_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _2992 = _2977 > 0;\n    bool _3001;\n    if (_2992)\n    {\n        int param = _2977 - 1;\n        _3001 = _2987 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3001 = _2992;\n    }\n    if (_3001)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3007 = _2977 > 1;\n        bool _3014;\n        if (_3007)\n        {\n            _3014 = _2987 > _2041_fa_shadow_split.x;\n        }\n        else\n        {\n            _3014 = _3007;\n        }\n        if (_3014)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3020 = _2977 > 2;\n        bool _3027;\n        if (_3020)\n        {\n            _3027 = _2987 > _2041_fa_shadow_split.y;\n        }\n        else\n        {\n            _3027 = _3020;\n        }\n        if (_3027)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3033 = _2977 > 3;\n        bool _3040;\n        if (_3033)\n        {\n            _3040 = _2987 > _2041_fa_shadow_split.z;\n        }\n        else\n        {\n            _3040 = _3033;\n        }\n        if (_3040)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _4150 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4150 = -_4150;\n    }\n    float3 _3735 = normalize(_384_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _4163 = { fa_world_pos, _4150, fa_world_tangent, fa_uv, fa_vertex_color, _3735, gl_FrontFacing };\n    SurfaceInput param_1 = _4163;\n    Surface _3743 = fa_standard_surface(param_1);\n    float3 _4189 = _3743.albedo;\n    float _4190 = _3743.alpha;\n    float3 _4191 = _3743.normal;\n    float _4192 = _3743.metallic;\n    float _4193 = _3743.roughness;\n    float _4194 = _3743.occlusion;\n    float3 _4195 = _3743.emission;\n    float _4196 = _3743.clearcoat;\n    float _4197 = _3743.clearcoat_roughness;\n    float3 _4198 = _3743.sheen_color;\n    float _4199 = _3743.sheen_roughness;\n    float _4200 = _3743.anisotropy;\n    float _4201 = _3743.anisotropy_rotation;\n    float _4202 = _3743.specular;\n    float _4203 = _3743.ior;\n    float3 _4204 = _3743.specular_color;\n    SurfaceInput _4171 = { fa_world_pos, _4150, fa_world_tangent, fa_uv, fa_vertex_color, _3735, gl_FrontFacing };\n    SurfaceInput param_2 = _4171;\n    Surface param_3 = _3743;\n    surface(param_2, param_3);\n    _4189 = param_3.albedo;\n    _4190 = param_3.alpha;\n    _4191 = param_3.normal;\n    _4192 = param_3.metallic;\n    _4193 = param_3.roughness;\n    _4194 = param_3.occlusion;\n    _4195 = param_3.emission;\n    _4196 = param_3.clearcoat;\n    _4197 = param_3.clearcoat_roughness;\n    _4198 = param_3.sheen_color;\n    _4199 = param_3.sheen_roughness;\n    _4200 = param_3.anisotropy;\n    _4201 = param_3.anisotropy_rotation;\n    _4202 = param_3.specular;\n    _4203 = param_3.ior;\n    _4204 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _4150;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4189 = param_6;\n    _4191 = param_7;\n    float3 result;\n    if (_384_fa_emissive.w > 0.5f)\n    {\n        result = _4189;\n    }\n    else\n    {\n        float3 _3781 = _4191;\n        float3 _3782 = normalize(_3781);\n        _4191 = _3782;\n        float3 param_8 = _3782;\n        SurfaceInput _4179 = { fa_world_pos, _4150, fa_world_tangent, fa_uv, fa_vertex_color, _3735, gl_FrontFacing };\n        SurfaceInput param_9 = _4179;\n        Surface _4270 = { _4189, _4190, _4191, _4192, _4193, _4194, _4195, _4196, _4197, _4198, _4199, _4200, _4201, _4202, _4203, _4204 };\n        Surface param_10 = _4270;\n        float3 param_11 = fa_indirect_diffuse(param_8);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _3801 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3801; ln++)\n        {\n            int param_12 = ln;\n            int _3814 = fa_cl_light(param_12);\n            bool _3817 = fa_lm.z > 0.5f;\n            bool _3823;\n            if (_3817)\n            {\n                int param_13 = _3814;\n                _3823 = fa_light_baked(param_13);\n            }\n            else\n            {\n                _3823 = _3817;\n            }\n            if (_3823)\n            {\n                continue;\n            }\n            int param_14 = _3814;\n            float3 param_15 = fa_world_pos;\n            float3 param_16 = _4150;\n            LightSample _3835 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput _4187 = { fa_world_pos, _4150, fa_world_tangent, fa_uv, fa_vertex_color, _3735, gl_FrontFacing };\n            SurfaceInput param_17 = _4187;\n            Surface _4287 = { _4189, _4190, _4191, _4192, _4193, _4194, _4195, _4196, _4197, _4198, _4199, _4200, _4201, _4202, _4203, _4204 };\n            Surface param_18 = _4287;\n            LightSample param_19 = _3835;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _3850 = result;\n    float3 _3851 = _3850 + _4195;\n    result = _3851;\n    float3 param_20 = _3851;\n    float3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _3860 = _384_fa_fog.w > 0.0f;\n    bool _3867;\n    if (!_3860)\n    {\n        _3867 = _384_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _3867 = _3860;\n    }\n    if (_3867)\n    {\n        float3 _3876 = fa_world_pos - _384_fa_camera_pos.xyz;\n        float _3882 = dot(_3876, _384_fa_fog_c.xyz);\n        bool _3886 = _384_fa_fog_c.w > 0.5f;\n        float _3887;\n        if (_3886)\n        {\n            _3887 = _3882;\n        }\n        else\n        {\n            _3887 = length(_3876);\n        }\n        float _3899 = _3887 - _384_fa_fog_b.x;\n        if (_3899 > 0.0f)\n        {\n            float _3908 = _384_fa_fog.w * _3899;\n            float tau = _3908 * _3908;\n            if (_384_fa_fog_b.y > 0.0f)\n            {\n                float _3924;\n                if (_3886)\n                {\n                    _3924 = fa_world_pos.y - (_384_fa_fog_c.y * _3882);\n                }\n                else\n                {\n                    _3924 = _384_fa_camera_pos.y;\n                }\n                float _3945 = lerp(_3924, fa_world_pos.y, clamp(_384_fa_fog_b.x / _3887, 0.0f, 1.0f));\n                float _3949 = fa_world_pos.y - _3945;\n                float _3954 = _3945 - _384_fa_fog_b.z;\n                float _3959 = fa_world_pos.y - _384_fa_fog_b.z;\n                bool _3962 = _3954 <= 0.0f;\n                bool _3963 = !_3962;\n                bool _3969;\n                if (_3963)\n                {\n                    _3969 = _384_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3969 = _3962;\n                }\n                float _3970;\n                if (_3969)\n                {\n                    _3970 = _384_fa_fog_b.y;\n                }\n                else\n                {\n                    _3970 = _384_fa_fog_b.y * exp(-min(_384_fa_fog_b.w * _3954, 80.0f));\n                }\n                bool _3997;\n                if (_3963)\n                {\n                    _3997 = _384_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3997 = _3962;\n                }\n                float _3998;\n                if (_3997)\n                {\n                    _3998 = _384_fa_fog_b.y * _3954;\n                }\n                else\n                {\n                    _3998 = (_384_fa_fog_b.y * (1.0f - exp(-min(_384_fa_fog_b.w * _3954, 80.0f)))) / _384_fa_fog_b.w;\n                }\n                bool _4023 = _3959 <= 0.0f;\n                bool _4030;\n                if (!_4023)\n                {\n                    _4030 = _384_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4030 = _4023;\n                }\n                float _4031;\n                if (_4030)\n                {\n                    _4031 = _384_fa_fog_b.y * _3959;\n                }\n                else\n                {\n                    _4031 = (_384_fa_fog_b.y * (1.0f - exp(-min(_384_fa_fog_b.w * _3959, 80.0f)))) / _384_fa_fog_b.w;\n                }\n                float _4058;\n                if (abs(_3949) < 0.001000000047497451305389404296875f)\n                {\n                    _4058 = _3970;\n                }\n                else\n                {\n                    _4058 = (_4031 - _3998) / _3949;\n                }\n                tau += (_3899 * max(_4058, 0.0f));\n            }\n            result = lerp(result, _384_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4190);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_384",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2041",
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
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _381 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _381;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _388 = _273.world_pos;\n    fa_world_pos = _388;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_388, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _384_fa_camera_pos : packoffset(c0);\n    float4 _384_fa_ambient : packoffset(c1);\n    float4 _384_fa_base_color : packoffset(c2);\n    float4 _384_fa_emissive : packoffset(c3);\n    float4 _384_fa_model_emissive : packoffset(c4);\n    float4 _384_fa_pbr : packoffset(c5);\n    float4 _384_fa_maps : packoffset(c6);\n    float4 _384_fa_fog : packoffset(c7);\n    float4 _384_fa_fog_b : packoffset(c8);\n    float4 _384_fa_fog_c : packoffset(c9);\n    float4 _384_fa_counts : packoffset(c10);\n    float4 _384_fa_env_sky : packoffset(c11);\n    float4 _384_fa_env_horizon : packoffset(c12);\n    float4 _384_fa_time : packoffset(c13);\n    float4 _384_fa_cl_vpx : packoffset(c14);\n    float4 _384_fa_cl_vpy : packoffset(c15);\n    float4 _384_fa_cl_vpw : packoffset(c16);\n    float4 _384_fa_cl_fwd : packoffset(c17);\n    float4 _384_fa_cl_grid : packoffset(c18);\n    float4 _384_fa_cl_info : packoffset(c19);\n    float4 _384_fa_layers_a : packoffset(c20);\n    float4 _384_fa_layers_b : packoffset(c21);\n    float4 _384_fa_layers_c : packoffset(c22);\n    float4 _384_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2041_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2041_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2041_fa_shadow_info[4] : packoffset(c20);\n    float4 _2041_fa_shadow_split : packoffset(c24);\n    float4 _2041_fa_shadow_cfg : packoffset(c25);\n    float4 _2041_fa_shadow_bias : packoffset(c26);\n    float4 _2041_fa_shadow_eye : packoffset(c27);\n    float4 _2041_fa_shadow_fwd : packoffset(c28);\n    float4 _2041_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1312 = _384_fa_cl_info.x < 0.0f;\n    bool _1319;\n    if (!_1312)\n    {\n        _1319 = _384_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1319 = _1312;\n    }\n    bool _1327;\n    if (!_1319)\n    {\n        _1327 = _384_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1327 = _1319;\n    }\n    bool _1334;\n    if (!_1327)\n    {\n        _1334 = _384_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1334 = _1327;\n    }\n    bool _1341;\n    if (!_1334)\n    {\n        _1341 = _384_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1341 = _1334;\n    }\n    if (_1341)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1351 = float4(world_pos, 1.0f);\n    float _1357 = dot(_384_fa_cl_vpw, _1351);\n    if (!(_1357 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1379 = float2(dot(_384_fa_cl_vpx, _1351), dot(_384_fa_cl_vpy, _1351)) / _1357.xx;\n    int _1383 = int(_384_fa_cl_grid.x);\n    int _1387 = int(_384_fa_cl_grid.y);\n    int param = (int(_384_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_384_fa_cl_fwd.xyz, world_pos) + _384_fa_cl_fwd.w, _384_fa_cl_grid.w) / _384_fa_cl_grid.w) * _384_fa_cl_grid.z)), 0, int(_384_fa_cl_info.y) - 1) * _1387) + clamp(int(floor(((_1379.y * 0.5f) + 0.5f) * _384_fa_cl_grid.y)), 0, _1387 - 1)) * _1383)) + clamp(int(floor(((_1379.x * 0.5f) + 0.5f) * _384_fa_cl_grid.x)), 0, _1383 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1463 = fa_cluster_texel(param);\n    return int2(int(_1463.x), int(_1463.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_384_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3241 = fa_cluster_lookup(param);\n    fa_cl_slot = _3241.x;\n    fa_cl_local = _3241.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _3402 = fa_linear_to_srgb(param);\n        c = _3402;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _3410 = fa_srgb_to_linear(param_1);\n            c = _3410;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _267;\n    if (i.front_facing)\n    {\n        _267 = i.world_normal;\n    }\n    else\n    {\n        _267 = -i.world_normal;\n    }\n    float3 _291 = normalize(i.world_tangent.xyz - (_267 * dot(_267, i.world_tangent.xyz)));\n    float3 _318 = normalize(((_291 * m.x) + ((cross(_267, _291) * i.world_tangent.w) * m.y)) + (_267 * m.z));\n    float3 _321;\n    if (i.front_facing)\n    {\n        _321 = _318;\n    }\n    else\n    {\n        _321 = -_318;\n    }\n    return _321;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _384_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3441 = fa_tex_fix(param_2, param_3);\n    float4 _4489 = base_t;\n    _4489.x = _3441.x;\n    _4489.y = _3441.y;\n    _4489.z = _3441.z;\n    base_t = _4489;\n    float4 _3455 = (_4489 * _384_fa_base_color) * i.vertex_color;\n    float3 _4354 = i.world_normal;\n    if (_384_fa_maps.z > 0.5f)\n    {\n        float param_4 = _384_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3487 = fa_tex_fix(param_6, param_7);\n        float3 _3490 = (_3487 * 2.0f) - 1.0f.xxx;\n        float2 _3495 = _3490.xy * _384_fa_maps.x;\n        float3 _4497 = _3490;\n        _4497.x = _3495.x;\n        _4497.y = _3495.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4497;\n        _4354 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _384_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3523 = fa_tex_fix(param_12, param_13);\n    float4 _4500 = mrt;\n    _4500.x = _3523.x;\n    _4500.y = _3523.y;\n    _4500.z = _3523.z;\n    mrt = _4500;\n    float4 _3551 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _384_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _3551.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3562 = fa_tex_fix(param_16, param_17);\n    float param_18 = _384_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3592 = fa_tex_fix(param_20, param_21);\n    float _4359 = _384_fa_layers_a.x;\n    float _4360 = _384_fa_layers_a.y;\n    float _4363 = _384_fa_layers_a.z;\n    float _4362 = _384_fa_layers_b.w;\n    float _4365 = _384_fa_layers_c.x;\n    if (_384_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_384_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _4359 *= _3562.y;\n            _4360 *= _3562.z;\n            _4362 *= _3551.w;\n        }\n        if (_384_fa_layers_c.z > 1.5f)\n        {\n            _4363 *= mrt.x;\n            _4365 *= mrt.w;\n        }\n    }\n    Surface _4384 = { _3455.xyz, _3455.w, _4354, clamp(_384_fa_pbr.x * _3523.z, 0.0f, 1.0f), clamp(_384_fa_pbr.y * _3523.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_384_fa_maps.y * (_3562.x - 1.0f)), _384_fa_emissive.xyz + (_384_fa_model_emissive.xyz * _3592), _4359, _4360, _384_fa_layers_b.xyz, _4362, _4363, _384_fa_layers_a.w, _4365, _384_fa_layers_c.y, _384_fa_layers_d.xyz };\n    return _4384;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1543 = rect.zw - rect.xy;\n    float2 _1547 = _1543 * atlas;\n    float2 _1551 = ddx * _1547;\n    float2 _1555 = ddy * _1547;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1543), clamp(0.5f * log2(max(max(dot(_1551, _1551), dot(_1555, _1555)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1588 = _384_fa_counts.y < 0.5f;\n    bool _1595;\n    if (!_1588)\n    {\n        _1595 = _384_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1595 = _1588;\n    }\n    if (_1595)\n    {\n        return;\n    }\n    float3 _1601 = ddx(world_pos);\n    float3 _1604 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1608 = fa_cluster_texel(param);\n    int _1612 = int(_1608.w);\n    if (_1612 < 1)\n    {\n        return;\n    }\n    int _1622 = int(_384_fa_counts.y + 0.5f);\n    int param_1 = _1622;\n    float4 _1626 = fa_light_texel(param_1);\n    float2 _1629 = _1626.yz;\n    int _1633 = int(_1626.w);\n    int param_2 = _1622 + 1;\n    float4 _1638 = fa_light_texel(param_2);\n    float _1639 = _1638.x;\n    int _1645 = int(_384_fa_counts.w + 0.5f) - 1;\n    int _1649 = int(_1608.z);\n    float3 _1914;\n    for (int k = 0; k < _1612; k++)\n    {\n        int _1662 = _1649 + k;\n        int param_3 = _1633 + (_1662 >> 2);\n        int _1679 = (_1622 + 2) + (int(fa_light_texel(param_3)[_1662 & 3]) * 7);\n        int param_4 = _1679 + 6;\n        float4 _1684 = fa_light_texel(param_4);\n        if (((int(_1684.w + 0.5f) >> _1645) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1679;\n        float4 _1699 = fa_light_texel(param_5);\n        int param_6 = _1679 + 1;\n        float4 _1704 = fa_light_texel(param_6);\n        int param_7 = _1679 + 2;\n        float4 _1709 = fa_light_texel(param_7);\n        float3 _1712 = _1699.xyz;\n        float _1717 = dot(_1712, world_pos) + _1699.w;\n        float3 _1719 = _1704.xyz;\n        float _1724 = dot(_1719, world_pos) + _1704.w;\n        float3 _1726 = _1709.xyz;\n        float _1731 = dot(_1726, world_pos) + _1709.w;\n        bool _1736 = abs(_1717) > 0.5f;\n        bool _1744;\n        if (!_1736)\n        {\n            _1744 = abs(_1724) > 0.5f;\n        }\n        else\n        {\n            _1744 = _1736;\n        }\n        bool _1752;\n        if (!_1744)\n        {\n            _1752 = abs(_1731) > 0.5f;\n        }\n        else\n        {\n            _1752 = _1744;\n        }\n        if (_1752)\n        {\n            continue;\n        }\n        float _1767 = clamp(dot(geo_normal, normalize(_1726)) * _1684.z, 0.0f, 1.0f);\n        if (_1767 <= 0.0f)\n        {\n            continue;\n        }\n        float _1787 = (clamp((0.5f - abs(_1731)) * 10.0f, 0.0f, 1.0f) * _1767) * _1684.x;\n        float2 _1795 = float2(_1717 + 0.5f, 0.5f - _1724);\n        float2 _1805 = float2(dot(_1712, _1601), dot(_1719, _1601));\n        float2 _1815 = float2(dot(_1712, _1604), dot(_1719, _1604));\n        int param_8 = _1679 + 5;\n        float4 _1820 = fa_light_texel(param_8);\n        int param_9 = _1679 + 3;\n        float4 _1825 = fa_light_texel(param_9);\n        int param_10 = _1679 + 4;\n        float4 _1830 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1820.xyz;\n        bool _1840 = _1825.z > _1825.x;\n        if (_1840)\n        {\n            float4 param_11 = _1825;\n            float2 param_12 = _1795;\n            float2 param_13 = _1629;\n            float2 param_14 = _1805;\n            float2 param_15 = _1815;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1639 > 0.5f) && (_1639 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1866 = fa_dc_to_linear(param_16);\n                float4 _4434 = tx;\n                _4434.x = _1866.x;\n                _4434.y = _1866.y;\n                _4434.z = _1866.z;\n                tx = _4434;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1787 * tex_a) * _1820.w, 0.0f, 1.0f).xxx);\n        if (_1830.z > _1830.x)\n        {\n            float4 param_17 = _1830;\n            float2 param_18 = _1795;\n            float2 param_19 = _1629;\n            float2 param_20 = _1805;\n            float2 param_21 = _1815;\n            float4 _1910 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1639 > 1.5f)\n            {\n                float3 param_22 = _1910.xyz;\n                float3 _1920 = fa_dc_to_srgb(param_22);\n                _1914 = _1920;\n            }\n            else\n            {\n                _1914 = _1910.xyz;\n            }\n            float3 _1929 = (_1914 * 2.0f) - 1.0f.xxx;\n            float2 _1934 = _1929.xy * _1684.y;\n            float3 _1956 = (normalize(_1712) * _1934.x) + (normalize(_1719) * _1934.y);\n            float3 _1959 = normalize(normal);\n            normal = normalize(lerp(_1959, normalize((_1959 * max(_1929.z, 0.0500000007450580596923828125f)) + (_1956 - (_1959 * dot(_1959, _1956)))), clamp(_1787 * (_1840 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_sky_sh_coef(int k)\n{\n    float3 v = fa_env_tex.SampleLevel(fa_env_smp, float3(1.0f, 1.0f - (float((2 * (k >> 2)) + 1) * 0.25f), 1.0f - (float((2 * (k & 3)) + 1) * 0.25f)), 5.0f).xyz;\n    if (_384_fa_env_sky.w > 1.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3154 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3154;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_384_fa_env_sky.w > 0.5f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _384_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    return float3(0.0f, ambientColor.y, 0.0f);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_384_fa_cl_info.x) + int(_384_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_384_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _443_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _443_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _562 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _575 = (c - (ru * hx)) - p;\n        float3 _581 = ru * (2.0f * hx);\n        float _587 = max(dot(_581, _581), 9.9999999392252902907785028219223e-09f);\n        float _591 = dot(_575, _581);\n        float t = clamp((-_591) / _587, 0.0f, 1.0f);\n        if (_562)\n        {\n            float _606 = dot(r, _581);\n            float _612 = _587 - (_606 * _606);\n            if (abs(_612) > (9.9999997473787516355514526367188e-06f * _587))\n            {\n                t = clamp(((dot(r, _575) * _606) - _591) / _612, 0.0f, 1.0f);\n            }\n        }\n        return (p + _575) + (_581 * t);\n    }\n    float3 q = p;\n    float _644 = dot(r, axis);\n    bool _652;\n    if (_562)\n    {\n        _652 = abs(_644) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _652 = _562;\n    }\n    if (_652)\n    {\n        float _662 = dot(c - p, axis) / _644;\n        if (_662 > 0.0f)\n        {\n            q = p + (r * _662);\n        }\n    }\n    float3 _675 = q - c;\n    float2 xy = float2(dot(_675, ru), dot(_675, uu));\n    if (shape > 0.5f)\n    {\n        float _690 = length(xy);\n        if (_690 > hx)\n        {\n            xy *= (hx / _690);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _333 = abs(d);\n    float _335 = _333.x;\n    float _337 = _333.y;\n    bool _338 = _335 >= _337;\n    bool _346;\n    if (_338)\n    {\n        _346 = _335 >= _333.z;\n    }\n    else\n    {\n        _346 = _338;\n    }\n    int _347;\n    if (_346)\n    {\n        _347 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _362;\n        if (_337 >= _333.z)\n        {\n            _362 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _362 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _347 = _362;\n    }\n    return _347;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _482 = dot(d, right);\n    float _486 = dot(d, up);\n    float _497;\n    if (((_482 * _482) + (_486 * _486)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _497 = atan2(_486, _482) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _497 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_497 - floor(_497)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _728 = fa_light_base(param);\n    bool _732 = _384_fa_ambient.w > 4.5f;\n    int param_1 = _728;\n    float4 _736 = fa_light_texel(param_1);\n    int param_2 = _728 + 1;\n    float4 _741 = fa_light_texel(param_2);\n    float _744 = _741.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _756 = _732 && (_744 > 2.5f);\n    fa_light_is_area = _756;\n    bool _758 = _744 < 0.5f;\n    float3 l;\n    if (_758)\n    {\n        l = normalize(_736.xyz);\n        if (_732)\n        {\n            int param_3 = _728 + 6;\n            float4 _772 = fa_light_texel(param_3);\n            if (_772.z > 0.5f)\n            {\n                int param_4 = _728 + 4;\n                float4 _782 = fa_light_texel(param_4);\n                int param_5 = _728 + 5;\n                float4 _787 = fa_light_texel(param_5);\n                float2 param_6 = _772.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _782.xyz) * _782.w, (-dot(world_pos, _787.xyz)) * _787.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _817 = _736.xyz;\n        float3 _819 = _817 - world_pos;\n        float3 to_light = _819;\n        float _822 = length(_819);\n        float reach = _822;\n        bool front = true;\n        if (_756)\n        {\n            int param_8 = _728 + 7;\n            reach = max(_822 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _728 + 4;\n            float4 _846 = fa_light_texel(param_9);\n            int param_10 = _728 + 5;\n            float4 _851 = fa_light_texel(param_10);\n            int param_11 = _728 + 6;\n            float4 _856 = fa_light_texel(param_11);\n            float _857 = _856.w;\n            int param_12 = _728 + 2;\n            float3 _864 = normalize(fa_light_texel(param_12).xyz);\n            bool _866 = _857 > 1.5f;\n            bool _874;\n            if (!_866)\n            {\n                _874 = dot(_864, to_light) < 0.0f;\n            }\n            else\n            {\n                _874 = _866;\n            }\n            front = _874;\n            float3 r = 0.0f.xxx;\n            float3 _883 = _384_fa_camera_pos.xyz - world_pos;\n            bool _887 = dot(n, n) > 0.5f;\n            bool _895;\n            if (_887)\n            {\n                _895 = dot(_883, _883) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _895 = _887;\n            }\n            if (_895)\n            {\n                r = reflect(-normalize(_883), normalize(n));\n            }\n            float3 param_13 = _817;\n            float3 param_14 = _864;\n            float3 param_15 = _846.xyz;\n            float3 param_16 = _851.xyz;\n            float param_17 = _846.w;\n            float param_18 = _851.w;\n            float param_19 = _857;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _931 = length(to_light);\n        dist = _931;\n        l = to_light / max(_931, 9.9999997473787516355514526367188e-05f).xxx;\n        float _945 = reach / max(_736.w, 0.001000000047497451305389404296875f);\n        float _951 = clamp(1.0f - (_945 * _945), 0.0f, 1.0f);\n        float _953;\n        if (front)\n        {\n            _953 = _951 * _951;\n        }\n        else\n        {\n            _953 = 0.0f;\n        }\n        atten = _953;\n        bool _964 = _744 < 2.5f;\n        if ((_744 > 1.5f) && _964)\n        {\n            int param_22 = _728 + 2;\n            float4 _972 = fa_light_texel(param_22);\n            float _982 = _972.w;\n            int param_23 = _728 + 3;\n            float4 _987 = fa_light_texel(param_23);\n            float _988 = _987.x;\n            float cos_inner = _988;\n            if (_988 > 1.5f)\n            {\n                cos_inner = lerp(_982, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_982, cos_inner, dot(-l, normalize(_972.xyz)));\n        }\n        if (_732 && (_744 < 1.5f))\n        {\n            int param_24 = _728 + 6;\n            float4 _1012 = fa_light_texel(param_24);\n            if (_1012.z > 0.5f)\n            {\n                float3 _1020 = -to_light;\n                int param_25 = _728 + 4;\n                int param_26 = _728 + 5;\n                float3 _1034 = fa_light_texel(param_25).xyz;\n                float3 _1038 = fa_light_texel(param_26).xyz;\n                float3 _1047 = float3(dot(_1020, _1034), dot(_1020, _1038), dot(_1020, cross(_1034, _1038)));\n                float3 param_27 = _1047;\n                int _1051 = fa_cube_face(param_27);\n                int param_28 = _1051;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1078 = float2(dot(_1047, cross(param_29, param_30)), dot(_1047, param_30)) / max(dot(_1047, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1082 = _1051 / 3;\n                float2 param_31 = _1012.xy + (float2(float(_1051 - (_1082 * 3)), float(_1082)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1078.x), 0.5f - (0.5f * _1078.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _728 + 7;\n            float4 _1112 = fa_light_texel(param_33);\n            if (_1112.z > 0.5f)\n            {\n                int param_34 = _728 + 2;\n                int param_35 = _728 + 4;\n                int param_36 = _728 + 5;\n                float2 param_37 = _1112.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_732 && _964)\n            {\n                int param_42 = _728 + 6;\n                float4 _1159 = fa_light_texel(param_42);\n                int param_43 = _728 + 7;\n                float4 _1164 = fa_light_texel(param_43);\n                bool _1167 = _1159.z > 0.5f;\n                bool _1174;\n                if (!_1167)\n                {\n                    _1174 = _1164.z > 0.5f;\n                }\n                else\n                {\n                    _1174 = _1167;\n                }\n                if (_1174)\n                {\n                    int param_44 = _728 + 2;\n                    float4 _1181 = fa_light_texel(param_44);\n                    float3 _1185 = normalize(_1181.xyz);\n                    int param_45 = _728 + 4;\n                    float4 _1190 = fa_light_texel(param_45);\n                    int param_46 = _728 + 5;\n                    float4 _1195 = fa_light_texel(param_46);\n                    if (_1167)\n                    {\n                        float3 _1203 = -to_light;\n                        float _1210 = _1181.w;\n                        float _1226 = 0.5f / max(dot(_1203, _1185) * (sqrt(max(1.0f - (_1210 * _1210), 0.0f)) / max(_1210, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1159.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1203, _1190.xyz) * _1226), 0.5f - (dot(_1203, _1195.xyz) * _1226));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1164.z > 0.5f)\n                    {\n                        float2 param_49 = _1164.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1185;\n                        float3 param_52 = _1190.xyz;\n                        float3 param_53 = _1195.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4308 = _741.xyz * atten;\n    if (_732)\n    {\n        _4308 *= fa_light_tint;\n    }\n    int _1294;\n    if (_758)\n    {\n        _1294 = 0;\n    }\n    else\n    {\n        _1294 = ((_744 > 1.5f) && (_744 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _4319 = { l, _4308, atten, 1.0f, dist, _1294 };\n    return _4319;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2031;\n    if (i == 0)\n    {\n        _2031 = _2041_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2047;\n        if (i == 1)\n        {\n            _2047 = _2041_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2055;\n            if (i == 2)\n            {\n                _2055 = _2041_fa_shadow_split.z;\n            }\n            else\n            {\n                _2055 = _2041_fa_shadow_split.w;\n            }\n            _2047 = _2055;\n        }\n        _2031 = _2047;\n    }\n    return _2031;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2088 = fa_shadow_depth(param, param_1);\n    float _2092;\n    if (conv.x < 0.5f)\n    {\n        _2092 = _2088;\n    }\n    else\n    {\n        _2092 = (conv.y * conv.z) / (conv.z - (_2088 * (conv.z - conv.y)));\n    }\n    return _2092;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2019 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2019), sin(_2019)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2138 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2147;\n        if (k < 0.0f)\n        {\n            _2147 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2147 = k;\n        }\n        float _2167 = clamp((_2147 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2138;\n            float2 _2186 = fa_shadow_vogel(param_3, param_4, param_5) * _2167;\n            float2 param_6 = uv + (_2186 * _2041_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2198 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2198 < (zr - (length(_2186) * plane)))\n            {\n                sum += _2198;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2224 = sum / cnt;\n        float _2234;\n        if (k < 0.0f)\n        {\n            _2234 = (-k) / max(_2224, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2234 = k;\n        }\n        radius = clamp(((max(zr - _2224, 0.0f) * unit) * _2234) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2256 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2256; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2256;\n        float param_11 = _2138;\n        float2 _2275 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2275 * _2041_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2275) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2256);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2317 = max(_2041_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2322 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2328 = sqrt(1.0f - (_2322 * _2322));\n    float _2335 = min(_2328 / max(_2322, 0.20000000298023223876953125f), 4.0f);\n    float _2340;\n    if (_2041_fa_shadow_bias.y > 0.0f)\n    {\n        _2340 = _2041_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2340 = 1.5f * _2041_fa_shadow_info[ci].x;\n    }\n    float4 _2365 = mul(float4(world + (n * (_2340 * _2328)), 1.0f), _2041_fa_shadow_mat[ci]);\n    float _2372 = _2365.x;\n    bool _2375 = _2372 < _2041_fa_shadow_rect[ci].x;\n    bool _2384;\n    if (!_2375)\n    {\n        _2384 = _2372 > _2041_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2384 = _2375;\n    }\n    bool _2393;\n    if (!_2384)\n    {\n        _2393 = _2365.y < _2041_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2393 = _2384;\n    }\n    bool _2402;\n    if (!_2393)\n    {\n        _2402 = _2365.y > _2041_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2402 = _2393;\n    }\n    bool _2409;\n    if (!_2402)\n    {\n        _2409 = _2365.z > 1.0f;\n    }\n    else\n    {\n        _2409 = _2402;\n    }\n    if (_2409)\n    {\n        return -1.0f;\n    }\n    float _2417;\n    if (_2041_fa_shadow_bias.x > 0.0f)\n    {\n        _2417 = _2041_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2417 = 1.5f * _2041_fa_shadow_info[ci].x;\n    }\n    float2 param = _2365.xy;\n    float4 param_1 = _2041_fa_shadow_rect[ci];\n    float param_2 = _2365.z - ((_2417 * (1.0f + (0.5f * _2335))) / _2317);\n    float param_3 = _2041_fa_shadow_info[ci].x;\n    float param_4 = _2317;\n    float param_5 = _2317 * 0.25f;\n    float param_6 = ((_2041_fa_shadow_info[ci].x * min(_2335, 3.0f)) * 0.5f) / _2317;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2041_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2041_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_384_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2795 = int(_2041_fa_shadow_cfg.x + 0.5f);\n    if (_2795 < 1)\n    {\n        return 1.0f;\n    }\n    float _2810 = dot(world - _2041_fa_shadow_eye.xyz, _2041_fa_shadow_fwd.xyz);\n    int param = _2795 - 1;\n    if (_2810 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2822 = _2795 > 1;\n    bool _2829;\n    if (_2822)\n    {\n        _2829 = _2810 > _2041_fa_shadow_split.x;\n    }\n    else\n    {\n        _2829 = _2822;\n    }\n    if (_2829)\n    {\n        ci = 1;\n    }\n    bool _2833 = _2795 > 2;\n    bool _2840;\n    if (_2833)\n    {\n        _2840 = _2810 > _2041_fa_shadow_split.y;\n    }\n    else\n    {\n        _2840 = _2833;\n    }\n    if (_2840)\n    {\n        ci = 2;\n    }\n    bool _2844 = _2795 > 3;\n    bool _2851;\n    if (_2844)\n    {\n        _2851 = _2810 > _2041_fa_shadow_split.z;\n    }\n    else\n    {\n        _2851 = _2844;\n    }\n    if (_2851)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2795)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2877 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2877;\n        if (_2877 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2041_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2902;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2902 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2902 = _2041_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2921 = _2041_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2902, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2932 = clamp((_2810 - (fa_shadow_split_at(param_7) - _2921)) / _2921, 0.0f, 1.0f);\n        if (_2932 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2795)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2953 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2953;\n                if (_2953 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2932);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2475 = _384_fa_pbr.z < 0.5f;\n    bool _2482;\n    if (!_2475)\n    {\n        _2482 = _2041_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2482 = _2475;\n    }\n    if (_2482)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2041_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2495 = fa_light_texel(param);\n    float _2496 = _2495.x;\n    if (_2496 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2505 = int(_2496 + 0.5f);\n    int param_1 = _2505;\n    float4 _2509 = fa_light_texel(param_1);\n    int param_2 = _2505 + 1;\n    float4 _2514 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2517 = _2509.y;\n    if (_2517 > 0.0f)\n    {\n        float _2534 = 1.0f - smoothstep(0.75f * _2517, _2517, length(world - _2041_fa_shadow_eye.xyz));\n        fade = _2534;\n        if (_2534 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2509.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2558 = (_2505 + 2) + (face * 6);\n    int param_4 = _2558;\n    int param_5 = _2558 + 1;\n    int param_6 = _2558 + 3;\n    float4 _2572 = fa_light_texel(param_6);\n    int param_7 = _2558 + 4;\n    float4 _2577 = fa_light_texel(param_7);\n    int param_8 = _2558 + 5;\n    float4 _2582 = fa_light_texel(param_8);\n    float _2594 = _2582.x * max(dot(_2572, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2599 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2622 = clamp(dot(n, _2572.xyz), -1.0f, 1.0f);\n    float _2641 = min(sqrt(1.0f - (_2622 * _2622)) / max(abs(dot(n, world - lpos)) / max(dot(_2572, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2644 = _2514.y;\n    float _2646;\n    if (_2644 > 0.0f)\n    {\n        _2646 = _2644;\n    }\n    else\n    {\n        _2646 = 1.5f * _2594;\n    }\n    float4 _2666 = float4(world + (n * (_2646 * sqrt(1.0f - (_2599 * _2599)))), 1.0f);\n    float _2670 = dot(_2572, _2666);\n    float _2673 = _2582.y;\n    if (_2670 < _2673)\n    {\n        return 1.0f;\n    }\n    float2 _2688 = float2(dot(fa_light_texel(param_4), _2666), dot(fa_light_texel(param_5), _2666)) / _2670.xx;\n    float _2690 = _2688.x;\n    bool _2693 = _2690 < _2577.x;\n    bool _2702;\n    if (!_2693)\n    {\n        _2702 = _2690 > _2577.z;\n    }\n    else\n    {\n        _2702 = _2693;\n    }\n    bool _2711;\n    if (!_2702)\n    {\n        _2711 = _2688.y < _2577.y;\n    }\n    else\n    {\n        _2711 = _2702;\n    }\n    bool _2720;\n    if (!_2711)\n    {\n        _2720 = _2688.y > _2577.w;\n    }\n    else\n    {\n        _2720 = _2711;\n    }\n    if (_2720)\n    {\n        return 1.0f;\n    }\n    float _2726 = _2514.x;\n    float _2728;\n    if (_2726 > 0.0f)\n    {\n        _2728 = _2726;\n    }\n    else\n    {\n        _2728 = 1.5f * _2594;\n    }\n    float2 param_9 = _2688;\n    float4 param_10 = _2577;\n    float param_11 = _2670 - (_2728 * (1.0f + (0.5f * _2641)));\n    float param_12 = _2594;\n    float param_13 = 1.0f;\n    float param_14 = _2582.z * 0.25f;\n    float param_15 = (_2594 * min(_2641, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2673, _2582.z);\n    int param_17 = int(_2509.z + 0.5f);\n    float param_18 = _2509.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _3268 = fa_lm.z > 0.5f;\n    bool _3274;\n    if (_3268)\n    {\n        int param = li;\n        _3274 = fa_light_baked(param);\n    }\n    else\n    {\n        _3274 = _3268;\n    }\n    if (_3274)\n    {\n        int param_1 = li;\n        LightSample _4332 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _4332;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3298 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _4334 = _3298.color;\n    float _4336 = _3298.shadow;\n    if ((_3298.type == 0) && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3298.direction;\n        float _3312 = fa_shadow_factor(param_5, param_6);\n        _4336 = _3312;\n        _4334 *= _3312;\n    }\n    else\n    {\n        bool _3323 = _3298.type != 0;\n        bool _3329;\n        if (_3323)\n        {\n            _3329 = _3298.attenuation > 0.0f;\n        }\n        else\n        {\n            _3329 = _3323;\n        }\n        if (_3329)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _3298.direction;\n            float _3348 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _4336 = _3348;\n            _4334 *= _3348;\n        }\n    }\n    LightSample _4351 = { _3298.direction, _4334, _3298.attenuation, _4336, _3298._distance, _3298.type };\n    return _4351;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2041_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _2977 = int(_2041_fa_shadow_cfg.x + 0.5f);\n    float _2987 = dot(world - _2041_fa_shadow_eye.xyz, _2041_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _2992 = _2977 > 0;\n    bool _3001;\n    if (_2992)\n    {\n        int param = _2977 - 1;\n        _3001 = _2987 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3001 = _2992;\n    }\n    if (_3001)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3007 = _2977 > 1;\n        bool _3014;\n        if (_3007)\n        {\n            _3014 = _2987 > _2041_fa_shadow_split.x;\n        }\n        else\n        {\n            _3014 = _3007;\n        }\n        if (_3014)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3020 = _2977 > 2;\n        bool _3027;\n        if (_3020)\n        {\n            _3027 = _2987 > _2041_fa_shadow_split.y;\n        }\n        else\n        {\n            _3027 = _3020;\n        }\n        if (_3027)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3033 = _2977 > 3;\n        bool _3040;\n        if (_3033)\n        {\n            _3040 = _2987 > _2041_fa_shadow_split.z;\n        }\n        else\n        {\n            _3040 = _3033;\n        }\n        if (_3040)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _4150 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4150 = -_4150;\n    }\n    float3 _3735 = normalize(_384_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _4163 = { fa_world_pos, _4150, fa_world_tangent, fa_uv, fa_vertex_color, _3735, gl_FrontFacing };\n    SurfaceInput param_1 = _4163;\n    Surface _3743 = fa_standard_surface(param_1);\n    float3 _4189 = _3743.albedo;\n    float _4190 = _3743.alpha;\n    float3 _4191 = _3743.normal;\n    float _4192 = _3743.metallic;\n    float _4193 = _3743.roughness;\n    float _4194 = _3743.occlusion;\n    float3 _4195 = _3743.emission;\n    float _4196 = _3743.clearcoat;\n    float _4197 = _3743.clearcoat_roughness;\n    float3 _4198 = _3743.sheen_color;\n    float _4199 = _3743.sheen_roughness;\n    float _4200 = _3743.anisotropy;\n    float _4201 = _3743.anisotropy_rotation;\n    float _4202 = _3743.specular;\n    float _4203 = _3743.ior;\n    float3 _4204 = _3743.specular_color;\n    SurfaceInput _4171 = { fa_world_pos, _4150, fa_world_tangent, fa_uv, fa_vertex_color, _3735, gl_FrontFacing };\n    SurfaceInput param_2 = _4171;\n    Surface param_3 = _3743;\n    surface(param_2, param_3);\n    _4189 = param_3.albedo;\n    _4190 = param_3.alpha;\n    _4191 = param_3.normal;\n    _4192 = param_3.metallic;\n    _4193 = param_3.roughness;\n    _4194 = param_3.occlusion;\n    _4195 = param_3.emission;\n    _4196 = param_3.clearcoat;\n    _4197 = param_3.clearcoat_roughness;\n    _4198 = param_3.sheen_color;\n    _4199 = param_3.sheen_roughness;\n    _4200 = param_3.anisotropy;\n    _4201 = param_3.anisotropy_rotation;\n    _4202 = param_3.specular;\n    _4203 = param_3.ior;\n    _4204 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _4150;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4189 = param_6;\n    _4191 = param_7;\n    float3 result;\n    if (_384_fa_emissive.w > 0.5f)\n    {\n        result = _4189;\n    }\n    else\n    {\n        float3 _3781 = _4191;\n        float3 _3782 = normalize(_3781);\n        _4191 = _3782;\n        float3 param_8 = _3782;\n        SurfaceInput _4179 = { fa_world_pos, _4150, fa_world_tangent, fa_uv, fa_vertex_color, _3735, gl_FrontFacing };\n        SurfaceInput param_9 = _4179;\n        Surface _4270 = { _4189, _4190, _4191, _4192, _4193, _4194, _4195, _4196, _4197, _4198, _4199, _4200, _4201, _4202, _4203, _4204 };\n        Surface param_10 = _4270;\n        float3 param_11 = fa_indirect_diffuse(param_8);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _3801 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3801; ln++)\n        {\n            int param_12 = ln;\n            int _3814 = fa_cl_light(param_12);\n            bool _3817 = fa_lm.z > 0.5f;\n            bool _3823;\n            if (_3817)\n            {\n                int param_13 = _3814;\n                _3823 = fa_light_baked(param_13);\n            }\n            else\n            {\n                _3823 = _3817;\n            }\n            if (_3823)\n            {\n                continue;\n            }\n            int param_14 = _3814;\n            float3 param_15 = fa_world_pos;\n            float3 param_16 = _4150;\n            LightSample _3835 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput _4187 = { fa_world_pos, _4150, fa_world_tangent, fa_uv, fa_vertex_color, _3735, gl_FrontFacing };\n            SurfaceInput param_17 = _4187;\n            Surface _4287 = { _4189, _4190, _4191, _4192, _4193, _4194, _4195, _4196, _4197, _4198, _4199, _4200, _4201, _4202, _4203, _4204 };\n            Surface param_18 = _4287;\n            LightSample param_19 = _3835;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _3850 = result;\n    float3 _3851 = _3850 + _4195;\n    result = _3851;\n    float3 param_20 = _3851;\n    float3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _3860 = _384_fa_fog.w > 0.0f;\n    bool _3867;\n    if (!_3860)\n    {\n        _3867 = _384_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _3867 = _3860;\n    }\n    if (_3867)\n    {\n        float3 _3876 = fa_world_pos - _384_fa_camera_pos.xyz;\n        float _3882 = dot(_3876, _384_fa_fog_c.xyz);\n        bool _3886 = _384_fa_fog_c.w > 0.5f;\n        float _3887;\n        if (_3886)\n        {\n            _3887 = _3882;\n        }\n        else\n        {\n            _3887 = length(_3876);\n        }\n        float _3899 = _3887 - _384_fa_fog_b.x;\n        if (_3899 > 0.0f)\n        {\n            float _3908 = _384_fa_fog.w * _3899;\n            float tau = _3908 * _3908;\n            if (_384_fa_fog_b.y > 0.0f)\n            {\n                float _3924;\n                if (_3886)\n                {\n                    _3924 = fa_world_pos.y - (_384_fa_fog_c.y * _3882);\n                }\n                else\n                {\n                    _3924 = _384_fa_camera_pos.y;\n                }\n                float _3945 = lerp(_3924, fa_world_pos.y, clamp(_384_fa_fog_b.x / _3887, 0.0f, 1.0f));\n                float _3949 = fa_world_pos.y - _3945;\n                float _3954 = _3945 - _384_fa_fog_b.z;\n                float _3959 = fa_world_pos.y - _384_fa_fog_b.z;\n                bool _3962 = _3954 <= 0.0f;\n                bool _3963 = !_3962;\n                bool _3969;\n                if (_3963)\n                {\n                    _3969 = _384_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3969 = _3962;\n                }\n                float _3970;\n                if (_3969)\n                {\n                    _3970 = _384_fa_fog_b.y;\n                }\n                else\n                {\n                    _3970 = _384_fa_fog_b.y * exp(-min(_384_fa_fog_b.w * _3954, 80.0f));\n                }\n                bool _3997;\n                if (_3963)\n                {\n                    _3997 = _384_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3997 = _3962;\n                }\n                float _3998;\n                if (_3997)\n                {\n                    _3998 = _384_fa_fog_b.y * _3954;\n                }\n                else\n                {\n                    _3998 = (_384_fa_fog_b.y * (1.0f - exp(-min(_384_fa_fog_b.w * _3954, 80.0f)))) / _384_fa_fog_b.w;\n                }\n                bool _4023 = _3959 <= 0.0f;\n                bool _4030;\n                if (!_4023)\n                {\n                    _4030 = _384_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4030 = _4023;\n                }\n                float _4031;\n                if (_4030)\n                {\n                    _4031 = _384_fa_fog_b.y * _3959;\n                }\n                else\n                {\n                    _4031 = (_384_fa_fog_b.y * (1.0f - exp(-min(_384_fa_fog_b.w * _3959, 80.0f)))) / _384_fa_fog_b.w;\n                }\n                float _4058;\n                if (abs(_3949) < 0.001000000047497451305389404296875f)\n                {\n                    _4058 = _3970;\n                }\n                else\n                {\n                    _4058 = (_4031 - _3998) / _3949;\n                }\n                tau += (_3899 * max(_4058, 0.0f));\n            }\n            result = lerp(result, _384_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4190);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_384",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2041",
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
          }
        ]
      }
    },
    "prepass": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _292 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _292;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _299 = _160.world_pos;\n    float4 _171 = float4(_299, 1.0f);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -mul(_171, _131_fa_light_vp).z;\n    fa_pre_r0 = float3(_131_fa_light_vp[0].x, _131_fa_light_vp[1].x, _131_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131_fa_light_vp[0].y, _131_fa_light_vp[1].y, _131_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131_fa_light_vp[0].z, _131_fa_light_vp[1].z, _131_fa_light_vp[2].z);\n    gl_Position = mul(_171, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _784 = base_t;\n    _784.x = _225.x;\n    _784.y = _225.y;\n    _784.z = _225.z;\n    base_t = _784;\n    float4 _241 = (_784 * _213_fa_base_color) * i.vertex_color;\n    float3 _747 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _792 = _279;\n        _792.x = _284.x;\n        _792.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _792;\n        _747 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _795 = mrt;\n    _795.x = _313.x;\n    _795.y = _313.y;\n    _795.z = _313.z;\n    mrt = _795;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _752 = _213_fa_layers_a.x;\n    float _753 = _213_fa_layers_a.y;\n    float _756 = _213_fa_layers_a.z;\n    float _755 = _213_fa_layers_b.w;\n    float _758 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _752 *= _355.y;\n            _753 *= _355.z;\n            _755 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _756 *= mrt.x;\n            _758 *= mrt.w;\n        }\n    }\n    Surface _777 = { _241.xyz, _241.w, _747, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _752, _753, _213_fa_layers_b.xyz, _755, _756, _213_fa_layers_a.w, _758, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _777;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _658 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _658 = -_658;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _671 = { fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _671;\n    SurfaceInput _679 = { fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _679;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _784 = base_t;\n    _784.x = _225.x;\n    _784.y = _225.y;\n    _784.z = _225.z;\n    base_t = _784;\n    float4 _241 = (_784 * _213_fa_base_color) * i.vertex_color;\n    float3 _747 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _792 = _279;\n        _792.x = _284.x;\n        _792.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _792;\n        _747 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _795 = mrt;\n    _795.x = _313.x;\n    _795.y = _313.y;\n    _795.z = _313.z;\n    mrt = _795;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _752 = _213_fa_layers_a.x;\n    float _753 = _213_fa_layers_a.y;\n    float _756 = _213_fa_layers_a.z;\n    float _755 = _213_fa_layers_b.w;\n    float _758 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _752 *= _355.y;\n            _753 *= _355.z;\n            _755 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _756 *= mrt.x;\n            _758 *= mrt.w;\n        }\n    }\n    Surface _777 = { _241.xyz, _241.w, _747, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _752, _753, _213_fa_layers_b.xyz, _755, _756, _213_fa_layers_a.w, _758, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _777;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _658 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _658 = -_658;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _671 = { fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _671;\n    SurfaceInput _679 = { fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _679;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
