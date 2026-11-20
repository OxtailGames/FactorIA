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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _401_fa_camera_pos : packoffset(c0);\n    float4 _401_fa_ambient : packoffset(c1);\n    float4 _401_fa_base_color : packoffset(c2);\n    float4 _401_fa_emissive : packoffset(c3);\n    float4 _401_fa_model_emissive : packoffset(c4);\n    float4 _401_fa_pbr : packoffset(c5);\n    float4 _401_fa_maps : packoffset(c6);\n    float4 _401_fa_fog : packoffset(c7);\n    float4 _401_fa_fog_b : packoffset(c8);\n    float4 _401_fa_fog_c : packoffset(c9);\n    float4 _401_fa_counts : packoffset(c10);\n    float4 _401_fa_env_sky : packoffset(c11);\n    float4 _401_fa_env_horizon : packoffset(c12);\n    float4 _401_fa_time : packoffset(c13);\n    float4 _401_fa_cl_vpx : packoffset(c14);\n    float4 _401_fa_cl_vpy : packoffset(c15);\n    float4 _401_fa_cl_vpw : packoffset(c16);\n    float4 _401_fa_cl_fwd : packoffset(c17);\n    float4 _401_fa_cl_grid : packoffset(c18);\n    float4 _401_fa_cl_info : packoffset(c19);\n    float4 _401_fa_layers_a : packoffset(c20);\n    float4 _401_fa_layers_b : packoffset(c21);\n    float4 _401_fa_layers_c : packoffset(c22);\n    float4 _401_fa_layers_d : packoffset(c23);\n    float4 _401_fa_ct_a : packoffset(c24);\n    float4 _401_fa_ct_b : packoffset(c25);\n    float4 _401_fa_ct_vpx : packoffset(c26);\n    float4 _401_fa_ct_vpy : packoffset(c27);\n    float4 _401_fa_ct_vpw : packoffset(c28);\n    float4 _401_fa_ct_fwd : packoffset(c29);\n    float4 _401_fa_probe_sh[9] : packoffset(c30);\n    float4 _401_fa_atlas : packoffset(c39);\n    float4 _401_fa_rpa_tile : packoffset(c40);\n    float4 _401_fa_rpa_pos : packoffset(c41);\n    float4 _401_fa_rpa_bx : packoffset(c42);\n    float4 _401_fa_rpa_by : packoffset(c43);\n    float4 _401_fa_rpa_bz : packoffset(c44);\n    float4 _401_fa_rpb_tile : packoffset(c45);\n    float4 _401_fa_rpb_pos : packoffset(c46);\n    float4 _401_fa_rpb_bx : packoffset(c47);\n    float4 _401_fa_rpb_by : packoffset(c48);\n    float4 _401_fa_rpb_bz : packoffset(c49);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2058_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2058_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2058_fa_shadow_info[4] : packoffset(c20);\n    float4 _2058_fa_shadow_split : packoffset(c24);\n    float4 _2058_fa_shadow_cfg : packoffset(c25);\n    float4 _2058_fa_shadow_bias : packoffset(c26);\n    float4 _2058_fa_shadow_eye : packoffset(c27);\n    float4 _2058_fa_shadow_fwd : packoffset(c28);\n    float4 _2058_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_probe_atlas : register(t6);\nTexture2D<float4> fa_screen_tex : register(t11);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1329 = _401_fa_cl_info.x < 0.0f;\n    bool _1336;\n    if (!_1329)\n    {\n        _1336 = _401_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1336 = _1329;\n    }\n    bool _1344;\n    if (!_1336)\n    {\n        _1344 = _401_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1344 = _1336;\n    }\n    bool _1351;\n    if (!_1344)\n    {\n        _1351 = _401_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1351 = _1344;\n    }\n    bool _1358;\n    if (!_1351)\n    {\n        _1358 = _401_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1358 = _1351;\n    }\n    if (_1358)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1368 = float4(world_pos, 1.0f);\n    float _1374 = dot(_401_fa_cl_vpw, _1368);\n    if (!(_1374 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1396 = float2(dot(_401_fa_cl_vpx, _1368), dot(_401_fa_cl_vpy, _1368)) / _1374.xx;\n    int _1400 = int(_401_fa_cl_grid.x);\n    int _1404 = int(_401_fa_cl_grid.y);\n    int param = (int(_401_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_401_fa_cl_fwd.xyz, world_pos) + _401_fa_cl_fwd.w, _401_fa_cl_grid.w) / _401_fa_cl_grid.w) * _401_fa_cl_grid.z)), 0, int(_401_fa_cl_info.y) - 1) * _1404) + clamp(int(floor(((_1396.y * 0.5f) + 0.5f) * _401_fa_cl_grid.y)), 0, _1404 - 1)) * _1400)) + clamp(int(floor(((_1396.x * 0.5f) + 0.5f) * _401_fa_cl_grid.x)), 0, _1400 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1480 = fa_cluster_texel(param);\n    return int2(int(_1480.x), int(_1480.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_401_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3656 = fa_cluster_lookup(param);\n    fa_cl_slot = _3656.x;\n    fa_cl_local = _3656.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _3866 = fa_linear_to_srgb(param);\n        c = _3866;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _3874 = fa_srgb_to_linear(param_1);\n            c = _3874;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _283;\n    if (i.front_facing)\n    {\n        _283 = i.world_normal;\n    }\n    else\n    {\n        _283 = -i.world_normal;\n    }\n    float3 _307 = normalize(i.world_tangent.xyz - (_283 * dot(_283, i.world_tangent.xyz)));\n    float3 _334 = normalize(((_307 * m.x) + ((cross(_283, _307) * i.world_tangent.w) * m.y)) + (_283 * m.z));\n    float3 _337;\n    if (i.front_facing)\n    {\n        _337 = _334;\n    }\n    else\n    {\n        _337 = -_334;\n    }\n    return _337;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _401_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3905 = fa_tex_fix(param_2, param_3);\n    float4 _4996 = base_t;\n    _4996.x = _3905.x;\n    _4996.y = _3905.y;\n    _4996.z = _3905.z;\n    base_t = _4996;\n    float4 _3919 = (_4996 * _401_fa_base_color) * i.vertex_color;\n    float3 _4848 = i.world_normal;\n    if (_401_fa_maps.z > 0.5f)\n    {\n        float param_4 = _401_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3951 = fa_tex_fix(param_6, param_7);\n        float3 _3954 = (_3951 * 2.0f) - 1.0f.xxx;\n        float2 _3959 = _3954.xy * _401_fa_maps.x;\n        float3 _5004 = _3954;\n        _5004.x = _3959.x;\n        _5004.y = _3959.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5004;\n        _4848 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _401_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3987 = fa_tex_fix(param_12, param_13);\n    float4 _5007 = mrt;\n    _5007.x = _3987.x;\n    _5007.y = _3987.y;\n    _5007.z = _3987.z;\n    mrt = _5007;\n    float4 _4015 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _401_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _4015.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4026 = fa_tex_fix(param_16, param_17);\n    float param_18 = _401_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4056 = fa_tex_fix(param_20, param_21);\n    float _4853 = _401_fa_layers_a.x;\n    float _4854 = _401_fa_layers_a.y;\n    float _4857 = _401_fa_layers_a.z;\n    float _4856 = _401_fa_layers_b.w;\n    float _4859 = _401_fa_layers_c.x;\n    if (_401_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_401_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _4853 *= _4026.y;\n            _4854 *= _4026.z;\n            _4856 *= _4015.w;\n        }\n        if (_401_fa_layers_c.z > 1.5f)\n        {\n            _4857 *= mrt.x;\n            _4859 *= mrt.w;\n        }\n    }\n    Surface _4878 = { _3919.xyz, _3919.w, _4848, clamp(_401_fa_pbr.x * _3987.z, 0.0f, 1.0f), clamp(_401_fa_pbr.y * _3987.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_401_fa_maps.y * (_4026.x - 1.0f)), _401_fa_emissive.xyz + (_401_fa_model_emissive.xyz * _4056), _4853, _4854, _401_fa_layers_b.xyz, _4856, _4857, _401_fa_layers_a.w, _4859, _401_fa_layers_c.y, _401_fa_layers_d.xyz };\n    return _4878;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1560 = rect.zw - rect.xy;\n    float2 _1564 = _1560 * atlas;\n    float2 _1568 = ddx * _1564;\n    float2 _1572 = ddy * _1564;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1560), clamp(0.5f * log2(max(max(dot(_1568, _1568), dot(_1572, _1572)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1605 = _401_fa_counts.y < 0.5f;\n    bool _1612;\n    if (!_1605)\n    {\n        _1612 = _401_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1612 = _1605;\n    }\n    if (_1612)\n    {\n        return;\n    }\n    float3 _1618 = ddx(world_pos);\n    float3 _1621 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1625 = fa_cluster_texel(param);\n    int _1629 = int(_1625.w);\n    if (_1629 < 1)\n    {\n        return;\n    }\n    int _1639 = int(_401_fa_counts.y + 0.5f);\n    int param_1 = _1639;\n    float4 _1643 = fa_light_texel(param_1);\n    float2 _1646 = _1643.yz;\n    int _1650 = int(_1643.w);\n    int param_2 = _1639 + 1;\n    float4 _1655 = fa_light_texel(param_2);\n    float _1656 = _1655.x;\n    int _1662 = int(_401_fa_counts.w + 0.5f) - 1;\n    int _1666 = int(_1625.z);\n    float3 _1931;\n    for (int k = 0; k < _1629; k++)\n    {\n        int _1679 = _1666 + k;\n        int param_3 = _1650 + (_1679 >> 2);\n        int _1696 = (_1639 + 2) + (int(fa_light_texel(param_3)[_1679 & 3]) * 7);\n        int param_4 = _1696 + 6;\n        float4 _1701 = fa_light_texel(param_4);\n        if (((int(_1701.w + 0.5f) >> _1662) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1696;\n        float4 _1716 = fa_light_texel(param_5);\n        int param_6 = _1696 + 1;\n        float4 _1721 = fa_light_texel(param_6);\n        int param_7 = _1696 + 2;\n        float4 _1726 = fa_light_texel(param_7);\n        float3 _1729 = _1716.xyz;\n        float _1734 = dot(_1729, world_pos) + _1716.w;\n        float3 _1736 = _1721.xyz;\n        float _1741 = dot(_1736, world_pos) + _1721.w;\n        float3 _1743 = _1726.xyz;\n        float _1748 = dot(_1743, world_pos) + _1726.w;\n        bool _1753 = abs(_1734) > 0.5f;\n        bool _1761;\n        if (!_1753)\n        {\n            _1761 = abs(_1741) > 0.5f;\n        }\n        else\n        {\n            _1761 = _1753;\n        }\n        bool _1769;\n        if (!_1761)\n        {\n            _1769 = abs(_1748) > 0.5f;\n        }\n        else\n        {\n            _1769 = _1761;\n        }\n        if (_1769)\n        {\n            continue;\n        }\n        float _1784 = clamp(dot(geo_normal, normalize(_1743)) * _1701.z, 0.0f, 1.0f);\n        if (_1784 <= 0.0f)\n        {\n            continue;\n        }\n        float _1804 = (clamp((0.5f - abs(_1748)) * 10.0f, 0.0f, 1.0f) * _1784) * _1701.x;\n        float2 _1812 = float2(_1734 + 0.5f, 0.5f - _1741);\n        float2 _1822 = float2(dot(_1729, _1618), dot(_1736, _1618));\n        float2 _1832 = float2(dot(_1729, _1621), dot(_1736, _1621));\n        int param_8 = _1696 + 5;\n        float4 _1837 = fa_light_texel(param_8);\n        int param_9 = _1696 + 3;\n        float4 _1842 = fa_light_texel(param_9);\n        int param_10 = _1696 + 4;\n        float4 _1847 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1837.xyz;\n        bool _1857 = _1842.z > _1842.x;\n        if (_1857)\n        {\n            float4 param_11 = _1842;\n            float2 param_12 = _1812;\n            float2 param_13 = _1646;\n            float2 param_14 = _1822;\n            float2 param_15 = _1832;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1656 > 0.5f) && (_1656 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1883 = fa_dc_to_linear(param_16);\n                float4 _4928 = tx;\n                _4928.x = _1883.x;\n                _4928.y = _1883.y;\n                _4928.z = _1883.z;\n                tx = _4928;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1804 * tex_a) * _1837.w, 0.0f, 1.0f).xxx);\n        if (_1847.z > _1847.x)\n        {\n            float4 param_17 = _1847;\n            float2 param_18 = _1812;\n            float2 param_19 = _1646;\n            float2 param_20 = _1822;\n            float2 param_21 = _1832;\n            float4 _1927 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1656 > 1.5f)\n            {\n                float3 param_22 = _1927.xyz;\n                float3 _1937 = fa_dc_to_srgb(param_22);\n                _1931 = _1937;\n            }\n            else\n            {\n                _1931 = _1927.xyz;\n            }\n            float3 _1946 = (_1931 * 2.0f) - 1.0f.xxx;\n            float2 _1951 = _1946.xy * _1701.y;\n            float3 _1973 = (normalize(_1729) * _1951.x) + (normalize(_1736) * _1951.y);\n            float3 _1976 = normalize(normal);\n            normal = normalize(lerp(_1976, normalize((_1976 * max(_1946.z, 0.0500000007450580596923828125f)) + (_1973 - (_1976 * dot(_1976, _1973)))), clamp(_1804 * (_1857 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3179_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3179_dummy_parameter)));\n}\n\nfloat3 fa_probe_sh_coef(float2 origin, float res, int k)\n{\n    float3 v = fa_probe_atlas.SampleLevel(fa_env_smp, (origin + float2(float(k) + 0.5f, res + 2.5f)) / fa_atlas_size(), 0.0f).xyz;\n    if (_401_fa_atlas.y > 0.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3171 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3171;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    float _3227 = (1.0f - _401_fa_rpa_tile.w) - _401_fa_rpb_tile.w;\n    float3 amb = 0.0f.xxx;\n    bool _3233 = _401_fa_env_sky.w > 0.5f;\n    float3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = 0.0f.xxx;\n    }\n    if (_3227 > 0.0005000000237487256526947021484375f)\n    {\n        if (_3233)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _401_fa_atlas.zw;\n                float param_1 = 128.0f;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3227;\n            }\n        }\n        else\n        {\n            amb = _401_fa_ambient.xyz * _3227;\n        }\n    }\n    bool _3286 = _401_fa_rpa_tile.w > 0.0f;\n    if (_3286)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _401_fa_rpa_tile.xy;\n            float param_4 = _401_fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * _401_fa_rpa_tile.w);\n        }\n    }\n    bool _3317 = _401_fa_rpb_tile.w > 0.0f;\n    if (_3317)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _401_fa_rpb_tile.xy;\n            float param_7 = _401_fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * _401_fa_rpb_tile.w);\n        }\n    }\n    if ((_3233 || _3286) || _3317)\n    {\n        float3 param_9[9] = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_401_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _401_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_401_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    return float3(0.0f, ambientColor.y, 0.0f);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_401_fa_cl_info.x) + int(_401_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_401_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _3626;\n    if (fa_lm.z > 0.5f)\n    {\n        _3626 = 0.0f;\n    }\n    else\n    {\n        _3626 = 1.0f - clamp(_401_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _3637 = _3626 < 1.0f;\n    bool _3643;\n    if (_3637)\n    {\n        int param = li;\n        _3643 = fa_light_baked(param);\n    }\n    else\n    {\n        _3643 = _3637;\n    }\n    return _3643 ? _3626 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _460_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _460_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _579 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _592 = (c - (ru * hx)) - p;\n        float3 _598 = ru * (2.0f * hx);\n        float _604 = max(dot(_598, _598), 9.9999999392252902907785028219223e-09f);\n        float _608 = dot(_592, _598);\n        float t = clamp((-_608) / _604, 0.0f, 1.0f);\n        if (_579)\n        {\n            float _623 = dot(r, _598);\n            float _629 = _604 - (_623 * _623);\n            if (abs(_629) > (9.9999997473787516355514526367188e-06f * _604))\n            {\n                t = clamp(((dot(r, _592) * _623) - _608) / _629, 0.0f, 1.0f);\n            }\n        }\n        return (p + _592) + (_598 * t);\n    }\n    float3 q = p;\n    float _661 = dot(r, axis);\n    bool _669;\n    if (_579)\n    {\n        _669 = abs(_661) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _669 = _579;\n    }\n    if (_669)\n    {\n        float _679 = dot(c - p, axis) / _661;\n        if (_679 > 0.0f)\n        {\n            q = p + (r * _679);\n        }\n    }\n    float3 _692 = q - c;\n    float2 xy = float2(dot(_692, ru), dot(_692, uu));\n    if (shape > 0.5f)\n    {\n        float _707 = length(xy);\n        if (_707 > hx)\n        {\n            xy *= (hx / _707);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _349 = abs(d);\n    float _351 = _349.x;\n    float _353 = _349.y;\n    bool _354 = _351 >= _353;\n    bool _362;\n    if (_354)\n    {\n        _362 = _351 >= _349.z;\n    }\n    else\n    {\n        _362 = _354;\n    }\n    int _363;\n    if (_362)\n    {\n        _363 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _378;\n        if (_353 >= _349.z)\n        {\n            _378 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _378 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _363 = _378;\n    }\n    return _363;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _499 = dot(d, right);\n    float _503 = dot(d, up);\n    float _514;\n    if (((_499 * _499) + (_503 * _503)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _514 = atan2(_503, _499) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _514 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_514 - floor(_514)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _745 = fa_light_base(param);\n    bool _749 = _401_fa_ambient.w > 4.5f;\n    int param_1 = _745;\n    float4 _753 = fa_light_texel(param_1);\n    int param_2 = _745 + 1;\n    float4 _758 = fa_light_texel(param_2);\n    float _761 = _758.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _773 = _749 && (_761 > 2.5f);\n    fa_light_is_area = _773;\n    bool _775 = _761 < 0.5f;\n    float3 l;\n    if (_775)\n    {\n        l = normalize(_753.xyz);\n        if (_749)\n        {\n            int param_3 = _745 + 6;\n            float4 _789 = fa_light_texel(param_3);\n            if (_789.z > 0.5f)\n            {\n                int param_4 = _745 + 4;\n                float4 _799 = fa_light_texel(param_4);\n                int param_5 = _745 + 5;\n                float4 _804 = fa_light_texel(param_5);\n                float2 param_6 = _789.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _799.xyz) * _799.w, (-dot(world_pos, _804.xyz)) * _804.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _834 = _753.xyz;\n        float3 _836 = _834 - world_pos;\n        float3 to_light = _836;\n        float _839 = length(_836);\n        float reach = _839;\n        bool front = true;\n        if (_773)\n        {\n            int param_8 = _745 + 7;\n            reach = max(_839 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _745 + 4;\n            float4 _863 = fa_light_texel(param_9);\n            int param_10 = _745 + 5;\n            float4 _868 = fa_light_texel(param_10);\n            int param_11 = _745 + 6;\n            float4 _873 = fa_light_texel(param_11);\n            float _874 = _873.w;\n            int param_12 = _745 + 2;\n            float3 _881 = normalize(fa_light_texel(param_12).xyz);\n            bool _883 = _874 > 1.5f;\n            bool _891;\n            if (!_883)\n            {\n                _891 = dot(_881, to_light) < 0.0f;\n            }\n            else\n            {\n                _891 = _883;\n            }\n            front = _891;\n            float3 r = 0.0f.xxx;\n            float3 _900 = _401_fa_camera_pos.xyz - world_pos;\n            bool _904 = dot(n, n) > 0.5f;\n            bool _912;\n            if (_904)\n            {\n                _912 = dot(_900, _900) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _912 = _904;\n            }\n            if (_912)\n            {\n                r = reflect(-normalize(_900), normalize(n));\n            }\n            float3 param_13 = _834;\n            float3 param_14 = _881;\n            float3 param_15 = _863.xyz;\n            float3 param_16 = _868.xyz;\n            float param_17 = _863.w;\n            float param_18 = _868.w;\n            float param_19 = _874;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _948 = length(to_light);\n        dist = _948;\n        l = to_light / max(_948, 9.9999997473787516355514526367188e-05f).xxx;\n        float _962 = reach / max(_753.w, 0.001000000047497451305389404296875f);\n        float _968 = clamp(1.0f - (_962 * _962), 0.0f, 1.0f);\n        float _970;\n        if (front)\n        {\n            _970 = _968 * _968;\n        }\n        else\n        {\n            _970 = 0.0f;\n        }\n        atten = _970;\n        bool _981 = _761 < 2.5f;\n        if ((_761 > 1.5f) && _981)\n        {\n            int param_22 = _745 + 2;\n            float4 _989 = fa_light_texel(param_22);\n            float _999 = _989.w;\n            int param_23 = _745 + 3;\n            float4 _1004 = fa_light_texel(param_23);\n            float _1005 = _1004.x;\n            float cos_inner = _1005;\n            if (_1005 > 1.5f)\n            {\n                cos_inner = lerp(_999, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_999, cos_inner, dot(-l, normalize(_989.xyz)));\n        }\n        if (_749 && (_761 < 1.5f))\n        {\n            int param_24 = _745 + 6;\n            float4 _1029 = fa_light_texel(param_24);\n            if (_1029.z > 0.5f)\n            {\n                float3 _1037 = -to_light;\n                int param_25 = _745 + 4;\n                int param_26 = _745 + 5;\n                float3 _1051 = fa_light_texel(param_25).xyz;\n                float3 _1055 = fa_light_texel(param_26).xyz;\n                float3 _1064 = float3(dot(_1037, _1051), dot(_1037, _1055), dot(_1037, cross(_1051, _1055)));\n                float3 param_27 = _1064;\n                int _1068 = fa_cube_face(param_27);\n                int param_28 = _1068;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1095 = float2(dot(_1064, cross(param_29, param_30)), dot(_1064, param_30)) / max(dot(_1064, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1099 = _1068 / 3;\n                float2 param_31 = _1029.xy + (float2(float(_1068 - (_1099 * 3)), float(_1099)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1095.x), 0.5f - (0.5f * _1095.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _745 + 7;\n            float4 _1129 = fa_light_texel(param_33);\n            if (_1129.z > 0.5f)\n            {\n                int param_34 = _745 + 2;\n                int param_35 = _745 + 4;\n                int param_36 = _745 + 5;\n                float2 param_37 = _1129.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_749 && _981)\n            {\n                int param_42 = _745 + 6;\n                float4 _1176 = fa_light_texel(param_42);\n                int param_43 = _745 + 7;\n                float4 _1181 = fa_light_texel(param_43);\n                bool _1184 = _1176.z > 0.5f;\n                bool _1191;\n                if (!_1184)\n                {\n                    _1191 = _1181.z > 0.5f;\n                }\n                else\n                {\n                    _1191 = _1184;\n                }\n                if (_1191)\n                {\n                    int param_44 = _745 + 2;\n                    float4 _1198 = fa_light_texel(param_44);\n                    float3 _1202 = normalize(_1198.xyz);\n                    int param_45 = _745 + 4;\n                    float4 _1207 = fa_light_texel(param_45);\n                    int param_46 = _745 + 5;\n                    float4 _1212 = fa_light_texel(param_46);\n                    if (_1184)\n                    {\n                        float3 _1220 = -to_light;\n                        float _1227 = _1198.w;\n                        float _1243 = 0.5f / max(dot(_1220, _1202) * (sqrt(max(1.0f - (_1227 * _1227), 0.0f)) / max(_1227, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1176.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1220, _1207.xyz) * _1243), 0.5f - (dot(_1220, _1212.xyz) * _1243));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1181.z > 0.5f)\n                    {\n                        float2 param_49 = _1181.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1202;\n                        float3 param_52 = _1207.xyz;\n                        float3 param_53 = _1212.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4802 = _758.xyz * atten;\n    if (_749)\n    {\n        _4802 *= fa_light_tint;\n    }\n    int _1311;\n    if (_775)\n    {\n        _1311 = 0;\n    }\n    else\n    {\n        _1311 = ((_761 > 1.5f) && (_761 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _4813 = { l, _4802, atten, 1.0f, dist, _1311 };\n    return _4813;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2048;\n    if (i == 0)\n    {\n        _2048 = _2058_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2064;\n        if (i == 1)\n        {\n            _2064 = _2058_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2072;\n            if (i == 2)\n            {\n                _2072 = _2058_fa_shadow_split.z;\n            }\n            else\n            {\n                _2072 = _2058_fa_shadow_split.w;\n            }\n            _2064 = _2072;\n        }\n        _2048 = _2064;\n    }\n    return _2048;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2105 = fa_shadow_depth(param, param_1);\n    float _2109;\n    if (conv.x < 0.5f)\n    {\n        _2109 = _2105;\n    }\n    else\n    {\n        _2109 = (conv.y * conv.z) / (conv.z - (_2105 * (conv.z - conv.y)));\n    }\n    return _2109;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2036 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2036), sin(_2036)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2155 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2164;\n        if (k < 0.0f)\n        {\n            _2164 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2164 = k;\n        }\n        float _2184 = clamp((_2164 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2155;\n            float2 _2203 = fa_shadow_vogel(param_3, param_4, param_5) * _2184;\n            float2 param_6 = uv + (_2203 * _2058_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2215 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2215 < (zr - (length(_2203) * plane)))\n            {\n                sum += _2215;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2241 = sum / cnt;\n        float _2251;\n        if (k < 0.0f)\n        {\n            _2251 = (-k) / max(_2241, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2251 = k;\n        }\n        radius = clamp(((max(zr - _2241, 0.0f) * unit) * _2251) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2273 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2273; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2273;\n        float param_11 = _2155;\n        float2 _2292 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2292 * _2058_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2292) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2273);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2334 = max(_2058_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2339 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2345 = sqrt(1.0f - (_2339 * _2339));\n    float _2352 = min(_2345 / max(_2339, 0.20000000298023223876953125f), 4.0f);\n    float _2357;\n    if (_2058_fa_shadow_bias.y > 0.0f)\n    {\n        _2357 = _2058_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2357 = 1.5f * _2058_fa_shadow_info[ci].x;\n    }\n    float4 _2382 = mul(float4(world + (n * (_2357 * _2345)), 1.0f), _2058_fa_shadow_mat[ci]);\n    float _2389 = _2382.x;\n    bool _2392 = _2389 < _2058_fa_shadow_rect[ci].x;\n    bool _2401;\n    if (!_2392)\n    {\n        _2401 = _2389 > _2058_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2401 = _2392;\n    }\n    bool _2410;\n    if (!_2401)\n    {\n        _2410 = _2382.y < _2058_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2410 = _2401;\n    }\n    bool _2419;\n    if (!_2410)\n    {\n        _2419 = _2382.y > _2058_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2419 = _2410;\n    }\n    bool _2426;\n    if (!_2419)\n    {\n        _2426 = _2382.z > 1.0f;\n    }\n    else\n    {\n        _2426 = _2419;\n    }\n    if (_2426)\n    {\n        return -1.0f;\n    }\n    float _2434;\n    if (_2058_fa_shadow_bias.x > 0.0f)\n    {\n        _2434 = _2058_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2434 = 1.5f * _2058_fa_shadow_info[ci].x;\n    }\n    float2 param = _2382.xy;\n    float4 param_1 = _2058_fa_shadow_rect[ci];\n    float param_2 = _2382.z - ((_2434 * (1.0f + (0.5f * _2352))) / _2334);\n    float param_3 = _2058_fa_shadow_info[ci].x;\n    float param_4 = _2334;\n    float param_5 = _2334 * 0.25f;\n    float param_6 = ((_2058_fa_shadow_info[ci].x * min(_2352, 3.0f)) * 0.5f) / _2334;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2058_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2058_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_401_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2812 = int(_2058_fa_shadow_cfg.x + 0.5f);\n    if (_2812 < 1)\n    {\n        return 1.0f;\n    }\n    float _2827 = dot(world - _2058_fa_shadow_eye.xyz, _2058_fa_shadow_fwd.xyz);\n    int param = _2812 - 1;\n    if (_2827 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2839 = _2812 > 1;\n    bool _2846;\n    if (_2839)\n    {\n        _2846 = _2827 > _2058_fa_shadow_split.x;\n    }\n    else\n    {\n        _2846 = _2839;\n    }\n    if (_2846)\n    {\n        ci = 1;\n    }\n    bool _2850 = _2812 > 2;\n    bool _2857;\n    if (_2850)\n    {\n        _2857 = _2827 > _2058_fa_shadow_split.y;\n    }\n    else\n    {\n        _2857 = _2850;\n    }\n    if (_2857)\n    {\n        ci = 2;\n    }\n    bool _2861 = _2812 > 3;\n    bool _2868;\n    if (_2861)\n    {\n        _2868 = _2827 > _2058_fa_shadow_split.z;\n    }\n    else\n    {\n        _2868 = _2861;\n    }\n    if (_2868)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2812)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2894 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2894;\n        if (_2894 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2058_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2919;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2919 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2919 = _2058_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2938 = _2058_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2919, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2949 = clamp((_2827 - (fa_shadow_split_at(param_7) - _2938)) / _2938, 0.0f, 1.0f);\n        if (_2949 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2812)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2970 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2970;\n                if (_2970 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2949);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2492 = _401_fa_pbr.z < 0.5f;\n    bool _2499;\n    if (!_2492)\n    {\n        _2499 = _2058_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2499 = _2492;\n    }\n    if (_2499)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2058_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2512 = fa_light_texel(param);\n    float _2513 = _2512.x;\n    if (_2513 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2522 = int(_2513 + 0.5f);\n    int param_1 = _2522;\n    float4 _2526 = fa_light_texel(param_1);\n    int param_2 = _2522 + 1;\n    float4 _2531 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2534 = _2526.y;\n    if (_2534 > 0.0f)\n    {\n        float _2551 = 1.0f - smoothstep(0.75f * _2534, _2534, length(world - _2058_fa_shadow_eye.xyz));\n        fade = _2551;\n        if (_2551 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2526.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2575 = (_2522 + 2) + (face * 6);\n    int param_4 = _2575;\n    int param_5 = _2575 + 1;\n    int param_6 = _2575 + 3;\n    float4 _2589 = fa_light_texel(param_6);\n    int param_7 = _2575 + 4;\n    float4 _2594 = fa_light_texel(param_7);\n    int param_8 = _2575 + 5;\n    float4 _2599 = fa_light_texel(param_8);\n    float _2611 = _2599.x * max(dot(_2589, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2616 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2639 = clamp(dot(n, _2589.xyz), -1.0f, 1.0f);\n    float _2658 = min(sqrt(1.0f - (_2639 * _2639)) / max(abs(dot(n, world - lpos)) / max(dot(_2589, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2661 = _2531.y;\n    float _2663;\n    if (_2661 > 0.0f)\n    {\n        _2663 = _2661;\n    }\n    else\n    {\n        _2663 = 1.5f * _2611;\n    }\n    float4 _2683 = float4(world + (n * (_2663 * sqrt(1.0f - (_2616 * _2616)))), 1.0f);\n    float _2687 = dot(_2589, _2683);\n    float _2690 = _2599.y;\n    if (_2687 < _2690)\n    {\n        return 1.0f;\n    }\n    float2 _2705 = float2(dot(fa_light_texel(param_4), _2683), dot(fa_light_texel(param_5), _2683)) / _2687.xx;\n    float _2707 = _2705.x;\n    bool _2710 = _2707 < _2594.x;\n    bool _2719;\n    if (!_2710)\n    {\n        _2719 = _2707 > _2594.z;\n    }\n    else\n    {\n        _2719 = _2710;\n    }\n    bool _2728;\n    if (!_2719)\n    {\n        _2728 = _2705.y < _2594.y;\n    }\n    else\n    {\n        _2728 = _2719;\n    }\n    bool _2737;\n    if (!_2728)\n    {\n        _2737 = _2705.y > _2594.w;\n    }\n    else\n    {\n        _2737 = _2728;\n    }\n    if (_2737)\n    {\n        return 1.0f;\n    }\n    float _2743 = _2531.x;\n    float _2745;\n    if (_2743 > 0.0f)\n    {\n        _2745 = _2743;\n    }\n    else\n    {\n        _2745 = 1.5f * _2611;\n    }\n    float2 param_9 = _2705;\n    float4 param_10 = _2594;\n    float param_11 = _2687 - (_2745 * (1.0f + (0.5f * _2658)));\n    float param_12 = _2611;\n    float param_13 = 1.0f;\n    float param_14 = _2599.z * 0.25f;\n    float param_15 = (_2611 * min(_2658, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2690, _2599.z);\n    int param_17 = int(_2526.z + 0.5f);\n    float param_18 = _2526.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _3368 = _401_fa_ct_a.x < 0.5f;\n    bool _3375;\n    if (!_3368)\n    {\n        _3375 = _2058_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _3375 = _3368;\n    }\n    if (_3375)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2058_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _3388 = fa_light_texel(param);\n    float _3389 = _3388.y;\n    float len = _3389;\n    if (_3389 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3401 = length(world - _401_fa_camera_pos.xyz);\n    float _3411 = 1.0f - smoothstep(0.5f * _401_fa_ct_b.x, _401_fa_ct_b.x, _3401);\n    if (_3411 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3417 = len;\n    float _3420 = min(_3417, 0.89999997615814208984375f * dist);\n    len = _3420;\n    float _3426 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _3401);\n    float _3431 = _3426 + (0.5f * _3420);\n    float3 _3437 = world + (gn * _3426);\n    float _3439 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _3504;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3455 = (float(k) + _3439) * 0.083333335816860198974609375f;\n        float3 _3463 = _3437 + (l * (_3455 * len));\n        float4 _3469 = float4(_3463, 1.0f);\n        float _3475 = dot(_401_fa_ct_vpw, _3469);\n        if (_3475 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _3495 = float2(dot(_401_fa_ct_vpx, _3469), dot(_401_fa_ct_vpy, _3469)) / _3475.xx;\n        float _3499 = _3495.x * 0.5f;\n        float _3500 = _3499 + 0.5f;\n        if (_401_fa_ct_a.y > 0.5f)\n        {\n            _3504 = (_3495.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _3504 = 0.5f - (_3495.y * 0.5f);\n        }\n        bool _3520 = _3500 < 0.0f;\n        bool _3527;\n        if (!_3520)\n        {\n            _3527 = _3500 >= 1.0f;\n        }\n        else\n        {\n            _3527 = _3520;\n        }\n        bool _3534;\n        if (!_3527)\n        {\n            _3534 = _3504 < 0.0f;\n        }\n        else\n        {\n            _3534 = _3527;\n        }\n        bool _3541;\n        if (!_3534)\n        {\n            _3541 = _3504 >= 1.0f;\n        }\n        else\n        {\n            _3541 = _3534;\n        }\n        if (_3541)\n        {\n            break;\n        }\n        float4 _3560 = fa_screen_tex.Load(int3(int2(float2(_3500, _3504) * _401_fa_ct_a.zw), 0));\n        if (_3560.w < 0.5f)\n        {\n            continue;\n        }\n        float _3579 = (dot(_401_fa_ct_fwd.xyz, _3463) + _401_fa_ct_fwd.w) - _3560.x;\n        if ((_3579 > _3426) && (_3579 < _3431))\n        {\n            occ = max(occ, (1.0f - (_3455 * _3455)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_3500, 0.5f - _3499), min(_3504, 1.0f - _3504))));\n        }\n    }\n    return 1.0f - (occ * _3411);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _3682 = fa_baked_keep(param);\n    if (_3682 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _4826 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _4826;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3708 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _4828 = _3708.color;\n    float _4829 = _3708.attenuation;\n    float _4830 = _3708.shadow;\n    bool _3711 = _3708.type == 0;\n    if (_3711 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3708.direction;\n        float _3722 = fa_shadow_factor(param_5, param_6);\n        _4830 = _3722;\n        _4828 *= _3722;\n    }\n    else\n    {\n        bool _3733 = _3708.type != 0;\n        bool _3739;\n        if (_3733)\n        {\n            _3739 = _4829 > 0.0f;\n        }\n        else\n        {\n            _3739 = _3733;\n        }\n        if (_3739)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _3708.direction;\n            float _3758 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _4830 = _3758;\n            _4828 *= _3758;\n        }\n    }\n    bool _3768 = _401_fa_ct_a.x > 0.5f;\n    bool _3774;\n    if (_3768)\n    {\n        _3774 = _4829 > 0.0f;\n    }\n    else\n    {\n        _3774 = _3768;\n    }\n    if (_3774)\n    {\n        float _3781;\n        if (_3711)\n        {\n            _3781 = 1000000000.0f;\n        }\n        else\n        {\n            _3781 = _3708._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _3708.direction;\n        float param_18 = _3781;\n        float _3799 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _4830 *= _3799;\n        _4828 *= _3799;\n    }\n    float _3812 = _4829;\n    float _3813 = _3812 * _3682;\n    _4829 = _3813;\n    float3 _3817 = _4828;\n    float3 _3818 = _3817 * _3682;\n    _4828 = _3818;\n    LightSample _4845 = { _3708.direction, _3818, _3813, _4830, _3708._distance, _3708.type };\n    return _4845;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2058_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _2994 = int(_2058_fa_shadow_cfg.x + 0.5f);\n    float _3004 = dot(world - _2058_fa_shadow_eye.xyz, _2058_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3009 = _2994 > 0;\n    bool _3018;\n    if (_3009)\n    {\n        int param = _2994 - 1;\n        _3018 = _3004 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3018 = _3009;\n    }\n    if (_3018)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3024 = _2994 > 1;\n        bool _3031;\n        if (_3024)\n        {\n            _3031 = _3004 > _2058_fa_shadow_split.x;\n        }\n        else\n        {\n            _3031 = _3024;\n        }\n        if (_3031)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3037 = _2994 > 2;\n        bool _3044;\n        if (_3037)\n        {\n            _3044 = _3004 > _2058_fa_shadow_split.y;\n        }\n        else\n        {\n            _3044 = _3037;\n        }\n        if (_3044)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3050 = _2994 > 3;\n        bool _3057;\n        if (_3050)\n        {\n            _3057 = _3004 > _2058_fa_shadow_split.z;\n        }\n        else\n        {\n            _3057 = _3050;\n        }\n        if (_3057)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _4644 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4644 = -_4644;\n    }\n    float3 _4235 = normalize(_401_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _4657 = { fa_world_pos, _4644, fa_world_tangent, fa_uv, fa_vertex_color, _4235, gl_FrontFacing };\n    SurfaceInput param_1 = _4657;\n    Surface _4243 = fa_standard_surface(param_1);\n    float3 _4683 = _4243.albedo;\n    float _4684 = _4243.alpha;\n    float3 _4685 = _4243.normal;\n    float _4686 = _4243.metallic;\n    float _4687 = _4243.roughness;\n    float _4688 = _4243.occlusion;\n    float3 _4689 = _4243.emission;\n    float _4690 = _4243.clearcoat;\n    float _4691 = _4243.clearcoat_roughness;\n    float3 _4692 = _4243.sheen_color;\n    float _4693 = _4243.sheen_roughness;\n    float _4694 = _4243.anisotropy;\n    float _4695 = _4243.anisotropy_rotation;\n    float _4696 = _4243.specular;\n    float _4697 = _4243.ior;\n    float3 _4698 = _4243.specular_color;\n    SurfaceInput _4665 = { fa_world_pos, _4644, fa_world_tangent, fa_uv, fa_vertex_color, _4235, gl_FrontFacing };\n    SurfaceInput param_2 = _4665;\n    Surface param_3 = _4243;\n    surface(param_2, param_3);\n    _4683 = param_3.albedo;\n    _4684 = param_3.alpha;\n    _4685 = param_3.normal;\n    _4686 = param_3.metallic;\n    _4687 = param_3.roughness;\n    _4688 = param_3.occlusion;\n    _4689 = param_3.emission;\n    _4690 = param_3.clearcoat;\n    _4691 = param_3.clearcoat_roughness;\n    _4692 = param_3.sheen_color;\n    _4693 = param_3.sheen_roughness;\n    _4694 = param_3.anisotropy;\n    _4695 = param_3.anisotropy_rotation;\n    _4696 = param_3.specular;\n    _4697 = param_3.ior;\n    _4698 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _4644;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4683 = param_6;\n    _4685 = param_7;\n    float3 result;\n    if (_401_fa_emissive.w > 0.5f)\n    {\n        result = _4683;\n    }\n    else\n    {\n        float3 _4281 = _4685;\n        float3 _4282 = normalize(_4281);\n        _4685 = _4282;\n        float3 param_8 = _4282;\n        SurfaceInput _4673 = { fa_world_pos, _4644, fa_world_tangent, fa_uv, fa_vertex_color, _4235, gl_FrontFacing };\n        SurfaceInput param_9 = _4673;\n        Surface _4764 = { _4683, _4684, _4685, _4686, _4687, _4688, _4689, _4690, _4691, _4692, _4693, _4694, _4695, _4696, _4697, _4698 };\n        Surface param_10 = _4764;\n        float3 param_11 = fa_indirect_diffuse(param_8);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _4301 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4301; ln++)\n        {\n            int param_12 = ln;\n            int _4314 = fa_cl_light(param_12);\n            int param_13 = _4314;\n            if (fa_baked_keep(param_13) <= 0.0f)\n            {\n                continue;\n            }\n            int param_14 = _4314;\n            float3 param_15 = fa_world_pos;\n            float3 param_16 = _4644;\n            LightSample _4330 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput _4681 = { fa_world_pos, _4644, fa_world_tangent, fa_uv, fa_vertex_color, _4235, gl_FrontFacing };\n            SurfaceInput param_17 = _4681;\n            Surface _4781 = { _4683, _4684, _4685, _4686, _4687, _4688, _4689, _4690, _4691, _4692, _4693, _4694, _4695, _4696, _4697, _4698 };\n            Surface param_18 = _4781;\n            LightSample param_19 = _4330;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _4345 = result;\n    float3 _4346 = _4345 + _4689;\n    result = _4346;\n    float3 param_20 = _4346;\n    float3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _4355 = _401_fa_fog.w > 0.0f;\n    bool _4362;\n    if (!_4355)\n    {\n        _4362 = _401_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _4362 = _4355;\n    }\n    if (_4362)\n    {\n        float3 _4371 = fa_world_pos - _401_fa_camera_pos.xyz;\n        float _4377 = dot(_4371, _401_fa_fog_c.xyz);\n        bool _4381 = _401_fa_fog_c.w > 0.5f;\n        float _4382;\n        if (_4381)\n        {\n            _4382 = _4377;\n        }\n        else\n        {\n            _4382 = length(_4371);\n        }\n        float _4394 = _4382 - _401_fa_fog_b.x;\n        if (_4394 > 0.0f)\n        {\n            float _4403 = _401_fa_fog.w * _4394;\n            float tau = _4403 * _4403;\n            if (_401_fa_fog_b.y > 0.0f)\n            {\n                float _4419;\n                if (_4381)\n                {\n                    _4419 = fa_world_pos.y - (_401_fa_fog_c.y * _4377);\n                }\n                else\n                {\n                    _4419 = _401_fa_camera_pos.y;\n                }\n                float _4440 = lerp(_4419, fa_world_pos.y, clamp(_401_fa_fog_b.x / _4382, 0.0f, 1.0f));\n                float _4444 = fa_world_pos.y - _4440;\n                float _4449 = _4440 - _401_fa_fog_b.z;\n                float _4454 = fa_world_pos.y - _401_fa_fog_b.z;\n                bool _4457 = _4449 <= 0.0f;\n                bool _4458 = !_4457;\n                bool _4464;\n                if (_4458)\n                {\n                    _4464 = _401_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4464 = _4457;\n                }\n                float _4465;\n                if (_4464)\n                {\n                    _4465 = _401_fa_fog_b.y;\n                }\n                else\n                {\n                    _4465 = _401_fa_fog_b.y * exp(-min(_401_fa_fog_b.w * _4449, 80.0f));\n                }\n                bool _4492;\n                if (_4458)\n                {\n                    _4492 = _401_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4492 = _4457;\n                }\n                float _4493;\n                if (_4492)\n                {\n                    _4493 = _401_fa_fog_b.y * _4449;\n                }\n                else\n                {\n                    _4493 = (_401_fa_fog_b.y * (1.0f - exp(-min(_401_fa_fog_b.w * _4449, 80.0f)))) / _401_fa_fog_b.w;\n                }\n                bool _4518 = _4454 <= 0.0f;\n                bool _4525;\n                if (!_4518)\n                {\n                    _4525 = _401_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4525 = _4518;\n                }\n                float _4526;\n                if (_4525)\n                {\n                    _4526 = _401_fa_fog_b.y * _4454;\n                }\n                else\n                {\n                    _4526 = (_401_fa_fog_b.y * (1.0f - exp(-min(_401_fa_fog_b.w * _4454, 80.0f)))) / _401_fa_fog_b.w;\n                }\n                float _4553;\n                if (abs(_4444) < 0.001000000047497451305389404296875f)\n                {\n                    _4553 = _4465;\n                }\n                else\n                {\n                    _4553 = (_4526 - _4493) / _4444;\n                }\n                tau += (_4394 * max(_4553, 0.0f));\n            }\n            result = lerp(result, _401_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4684);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_401",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2058",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _401_fa_camera_pos : packoffset(c0);\n    float4 _401_fa_ambient : packoffset(c1);\n    float4 _401_fa_base_color : packoffset(c2);\n    float4 _401_fa_emissive : packoffset(c3);\n    float4 _401_fa_model_emissive : packoffset(c4);\n    float4 _401_fa_pbr : packoffset(c5);\n    float4 _401_fa_maps : packoffset(c6);\n    float4 _401_fa_fog : packoffset(c7);\n    float4 _401_fa_fog_b : packoffset(c8);\n    float4 _401_fa_fog_c : packoffset(c9);\n    float4 _401_fa_counts : packoffset(c10);\n    float4 _401_fa_env_sky : packoffset(c11);\n    float4 _401_fa_env_horizon : packoffset(c12);\n    float4 _401_fa_time : packoffset(c13);\n    float4 _401_fa_cl_vpx : packoffset(c14);\n    float4 _401_fa_cl_vpy : packoffset(c15);\n    float4 _401_fa_cl_vpw : packoffset(c16);\n    float4 _401_fa_cl_fwd : packoffset(c17);\n    float4 _401_fa_cl_grid : packoffset(c18);\n    float4 _401_fa_cl_info : packoffset(c19);\n    float4 _401_fa_layers_a : packoffset(c20);\n    float4 _401_fa_layers_b : packoffset(c21);\n    float4 _401_fa_layers_c : packoffset(c22);\n    float4 _401_fa_layers_d : packoffset(c23);\n    float4 _401_fa_ct_a : packoffset(c24);\n    float4 _401_fa_ct_b : packoffset(c25);\n    float4 _401_fa_ct_vpx : packoffset(c26);\n    float4 _401_fa_ct_vpy : packoffset(c27);\n    float4 _401_fa_ct_vpw : packoffset(c28);\n    float4 _401_fa_ct_fwd : packoffset(c29);\n    float4 _401_fa_probe_sh[9] : packoffset(c30);\n    float4 _401_fa_atlas : packoffset(c39);\n    float4 _401_fa_rpa_tile : packoffset(c40);\n    float4 _401_fa_rpa_pos : packoffset(c41);\n    float4 _401_fa_rpa_bx : packoffset(c42);\n    float4 _401_fa_rpa_by : packoffset(c43);\n    float4 _401_fa_rpa_bz : packoffset(c44);\n    float4 _401_fa_rpb_tile : packoffset(c45);\n    float4 _401_fa_rpb_pos : packoffset(c46);\n    float4 _401_fa_rpb_bx : packoffset(c47);\n    float4 _401_fa_rpb_by : packoffset(c48);\n    float4 _401_fa_rpb_bz : packoffset(c49);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2058_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2058_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2058_fa_shadow_info[4] : packoffset(c20);\n    float4 _2058_fa_shadow_split : packoffset(c24);\n    float4 _2058_fa_shadow_cfg : packoffset(c25);\n    float4 _2058_fa_shadow_bias : packoffset(c26);\n    float4 _2058_fa_shadow_eye : packoffset(c27);\n    float4 _2058_fa_shadow_fwd : packoffset(c28);\n    float4 _2058_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_probe_atlas : register(t6);\nTexture2D<float4> fa_screen_tex : register(t11);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1329 = _401_fa_cl_info.x < 0.0f;\n    bool _1336;\n    if (!_1329)\n    {\n        _1336 = _401_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1336 = _1329;\n    }\n    bool _1344;\n    if (!_1336)\n    {\n        _1344 = _401_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1344 = _1336;\n    }\n    bool _1351;\n    if (!_1344)\n    {\n        _1351 = _401_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1351 = _1344;\n    }\n    bool _1358;\n    if (!_1351)\n    {\n        _1358 = _401_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1358 = _1351;\n    }\n    if (_1358)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1368 = float4(world_pos, 1.0f);\n    float _1374 = dot(_401_fa_cl_vpw, _1368);\n    if (!(_1374 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1396 = float2(dot(_401_fa_cl_vpx, _1368), dot(_401_fa_cl_vpy, _1368)) / _1374.xx;\n    int _1400 = int(_401_fa_cl_grid.x);\n    int _1404 = int(_401_fa_cl_grid.y);\n    int param = (int(_401_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_401_fa_cl_fwd.xyz, world_pos) + _401_fa_cl_fwd.w, _401_fa_cl_grid.w) / _401_fa_cl_grid.w) * _401_fa_cl_grid.z)), 0, int(_401_fa_cl_info.y) - 1) * _1404) + clamp(int(floor(((_1396.y * 0.5f) + 0.5f) * _401_fa_cl_grid.y)), 0, _1404 - 1)) * _1400)) + clamp(int(floor(((_1396.x * 0.5f) + 0.5f) * _401_fa_cl_grid.x)), 0, _1400 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1480 = fa_cluster_texel(param);\n    return int2(int(_1480.x), int(_1480.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_401_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3656 = fa_cluster_lookup(param);\n    fa_cl_slot = _3656.x;\n    fa_cl_local = _3656.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _3866 = fa_linear_to_srgb(param);\n        c = _3866;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _3874 = fa_srgb_to_linear(param_1);\n            c = _3874;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _283;\n    if (i.front_facing)\n    {\n        _283 = i.world_normal;\n    }\n    else\n    {\n        _283 = -i.world_normal;\n    }\n    float3 _307 = normalize(i.world_tangent.xyz - (_283 * dot(_283, i.world_tangent.xyz)));\n    float3 _334 = normalize(((_307 * m.x) + ((cross(_283, _307) * i.world_tangent.w) * m.y)) + (_283 * m.z));\n    float3 _337;\n    if (i.front_facing)\n    {\n        _337 = _334;\n    }\n    else\n    {\n        _337 = -_334;\n    }\n    return _337;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _401_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3905 = fa_tex_fix(param_2, param_3);\n    float4 _4996 = base_t;\n    _4996.x = _3905.x;\n    _4996.y = _3905.y;\n    _4996.z = _3905.z;\n    base_t = _4996;\n    float4 _3919 = (_4996 * _401_fa_base_color) * i.vertex_color;\n    float3 _4848 = i.world_normal;\n    if (_401_fa_maps.z > 0.5f)\n    {\n        float param_4 = _401_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3951 = fa_tex_fix(param_6, param_7);\n        float3 _3954 = (_3951 * 2.0f) - 1.0f.xxx;\n        float2 _3959 = _3954.xy * _401_fa_maps.x;\n        float3 _5004 = _3954;\n        _5004.x = _3959.x;\n        _5004.y = _3959.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5004;\n        _4848 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _401_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3987 = fa_tex_fix(param_12, param_13);\n    float4 _5007 = mrt;\n    _5007.x = _3987.x;\n    _5007.y = _3987.y;\n    _5007.z = _3987.z;\n    mrt = _5007;\n    float4 _4015 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _401_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _4015.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4026 = fa_tex_fix(param_16, param_17);\n    float param_18 = _401_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4056 = fa_tex_fix(param_20, param_21);\n    float _4853 = _401_fa_layers_a.x;\n    float _4854 = _401_fa_layers_a.y;\n    float _4857 = _401_fa_layers_a.z;\n    float _4856 = _401_fa_layers_b.w;\n    float _4859 = _401_fa_layers_c.x;\n    if (_401_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_401_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _4853 *= _4026.y;\n            _4854 *= _4026.z;\n            _4856 *= _4015.w;\n        }\n        if (_401_fa_layers_c.z > 1.5f)\n        {\n            _4857 *= mrt.x;\n            _4859 *= mrt.w;\n        }\n    }\n    Surface _4878 = { _3919.xyz, _3919.w, _4848, clamp(_401_fa_pbr.x * _3987.z, 0.0f, 1.0f), clamp(_401_fa_pbr.y * _3987.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_401_fa_maps.y * (_4026.x - 1.0f)), _401_fa_emissive.xyz + (_401_fa_model_emissive.xyz * _4056), _4853, _4854, _401_fa_layers_b.xyz, _4856, _4857, _401_fa_layers_a.w, _4859, _401_fa_layers_c.y, _401_fa_layers_d.xyz };\n    return _4878;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1560 = rect.zw - rect.xy;\n    float2 _1564 = _1560 * atlas;\n    float2 _1568 = ddx * _1564;\n    float2 _1572 = ddy * _1564;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1560), clamp(0.5f * log2(max(max(dot(_1568, _1568), dot(_1572, _1572)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1605 = _401_fa_counts.y < 0.5f;\n    bool _1612;\n    if (!_1605)\n    {\n        _1612 = _401_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1612 = _1605;\n    }\n    if (_1612)\n    {\n        return;\n    }\n    float3 _1618 = ddx(world_pos);\n    float3 _1621 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1625 = fa_cluster_texel(param);\n    int _1629 = int(_1625.w);\n    if (_1629 < 1)\n    {\n        return;\n    }\n    int _1639 = int(_401_fa_counts.y + 0.5f);\n    int param_1 = _1639;\n    float4 _1643 = fa_light_texel(param_1);\n    float2 _1646 = _1643.yz;\n    int _1650 = int(_1643.w);\n    int param_2 = _1639 + 1;\n    float4 _1655 = fa_light_texel(param_2);\n    float _1656 = _1655.x;\n    int _1662 = int(_401_fa_counts.w + 0.5f) - 1;\n    int _1666 = int(_1625.z);\n    float3 _1931;\n    for (int k = 0; k < _1629; k++)\n    {\n        int _1679 = _1666 + k;\n        int param_3 = _1650 + (_1679 >> 2);\n        int _1696 = (_1639 + 2) + (int(fa_light_texel(param_3)[_1679 & 3]) * 7);\n        int param_4 = _1696 + 6;\n        float4 _1701 = fa_light_texel(param_4);\n        if (((int(_1701.w + 0.5f) >> _1662) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1696;\n        float4 _1716 = fa_light_texel(param_5);\n        int param_6 = _1696 + 1;\n        float4 _1721 = fa_light_texel(param_6);\n        int param_7 = _1696 + 2;\n        float4 _1726 = fa_light_texel(param_7);\n        float3 _1729 = _1716.xyz;\n        float _1734 = dot(_1729, world_pos) + _1716.w;\n        float3 _1736 = _1721.xyz;\n        float _1741 = dot(_1736, world_pos) + _1721.w;\n        float3 _1743 = _1726.xyz;\n        float _1748 = dot(_1743, world_pos) + _1726.w;\n        bool _1753 = abs(_1734) > 0.5f;\n        bool _1761;\n        if (!_1753)\n        {\n            _1761 = abs(_1741) > 0.5f;\n        }\n        else\n        {\n            _1761 = _1753;\n        }\n        bool _1769;\n        if (!_1761)\n        {\n            _1769 = abs(_1748) > 0.5f;\n        }\n        else\n        {\n            _1769 = _1761;\n        }\n        if (_1769)\n        {\n            continue;\n        }\n        float _1784 = clamp(dot(geo_normal, normalize(_1743)) * _1701.z, 0.0f, 1.0f);\n        if (_1784 <= 0.0f)\n        {\n            continue;\n        }\n        float _1804 = (clamp((0.5f - abs(_1748)) * 10.0f, 0.0f, 1.0f) * _1784) * _1701.x;\n        float2 _1812 = float2(_1734 + 0.5f, 0.5f - _1741);\n        float2 _1822 = float2(dot(_1729, _1618), dot(_1736, _1618));\n        float2 _1832 = float2(dot(_1729, _1621), dot(_1736, _1621));\n        int param_8 = _1696 + 5;\n        float4 _1837 = fa_light_texel(param_8);\n        int param_9 = _1696 + 3;\n        float4 _1842 = fa_light_texel(param_9);\n        int param_10 = _1696 + 4;\n        float4 _1847 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1837.xyz;\n        bool _1857 = _1842.z > _1842.x;\n        if (_1857)\n        {\n            float4 param_11 = _1842;\n            float2 param_12 = _1812;\n            float2 param_13 = _1646;\n            float2 param_14 = _1822;\n            float2 param_15 = _1832;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1656 > 0.5f) && (_1656 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1883 = fa_dc_to_linear(param_16);\n                float4 _4928 = tx;\n                _4928.x = _1883.x;\n                _4928.y = _1883.y;\n                _4928.z = _1883.z;\n                tx = _4928;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1804 * tex_a) * _1837.w, 0.0f, 1.0f).xxx);\n        if (_1847.z > _1847.x)\n        {\n            float4 param_17 = _1847;\n            float2 param_18 = _1812;\n            float2 param_19 = _1646;\n            float2 param_20 = _1822;\n            float2 param_21 = _1832;\n            float4 _1927 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1656 > 1.5f)\n            {\n                float3 param_22 = _1927.xyz;\n                float3 _1937 = fa_dc_to_srgb(param_22);\n                _1931 = _1937;\n            }\n            else\n            {\n                _1931 = _1927.xyz;\n            }\n            float3 _1946 = (_1931 * 2.0f) - 1.0f.xxx;\n            float2 _1951 = _1946.xy * _1701.y;\n            float3 _1973 = (normalize(_1729) * _1951.x) + (normalize(_1736) * _1951.y);\n            float3 _1976 = normalize(normal);\n            normal = normalize(lerp(_1976, normalize((_1976 * max(_1946.z, 0.0500000007450580596923828125f)) + (_1973 - (_1976 * dot(_1976, _1973)))), clamp(_1804 * (_1857 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3179_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3179_dummy_parameter)));\n}\n\nfloat3 fa_probe_sh_coef(float2 origin, float res, int k)\n{\n    float3 v = fa_probe_atlas.SampleLevel(fa_env_smp, (origin + float2(float(k) + 0.5f, res + 2.5f)) / fa_atlas_size(), 0.0f).xyz;\n    if (_401_fa_atlas.y > 0.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3171 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3171;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    float _3227 = (1.0f - _401_fa_rpa_tile.w) - _401_fa_rpb_tile.w;\n    float3 amb = 0.0f.xxx;\n    bool _3233 = _401_fa_env_sky.w > 0.5f;\n    float3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = 0.0f.xxx;\n    }\n    if (_3227 > 0.0005000000237487256526947021484375f)\n    {\n        if (_3233)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _401_fa_atlas.zw;\n                float param_1 = 128.0f;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3227;\n            }\n        }\n        else\n        {\n            amb = _401_fa_ambient.xyz * _3227;\n        }\n    }\n    bool _3286 = _401_fa_rpa_tile.w > 0.0f;\n    if (_3286)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _401_fa_rpa_tile.xy;\n            float param_4 = _401_fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * _401_fa_rpa_tile.w);\n        }\n    }\n    bool _3317 = _401_fa_rpb_tile.w > 0.0f;\n    if (_3317)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _401_fa_rpb_tile.xy;\n            float param_7 = _401_fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * _401_fa_rpb_tile.w);\n        }\n    }\n    if ((_3233 || _3286) || _3317)\n    {\n        float3 param_9[9] = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_401_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _401_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_401_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    return float3(0.0f, ambientColor.y, 0.0f);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_401_fa_cl_info.x) + int(_401_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_401_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _3626;\n    if (fa_lm.z > 0.5f)\n    {\n        _3626 = 0.0f;\n    }\n    else\n    {\n        _3626 = 1.0f - clamp(_401_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _3637 = _3626 < 1.0f;\n    bool _3643;\n    if (_3637)\n    {\n        int param = li;\n        _3643 = fa_light_baked(param);\n    }\n    else\n    {\n        _3643 = _3637;\n    }\n    return _3643 ? _3626 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _460_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _460_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _579 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _592 = (c - (ru * hx)) - p;\n        float3 _598 = ru * (2.0f * hx);\n        float _604 = max(dot(_598, _598), 9.9999999392252902907785028219223e-09f);\n        float _608 = dot(_592, _598);\n        float t = clamp((-_608) / _604, 0.0f, 1.0f);\n        if (_579)\n        {\n            float _623 = dot(r, _598);\n            float _629 = _604 - (_623 * _623);\n            if (abs(_629) > (9.9999997473787516355514526367188e-06f * _604))\n            {\n                t = clamp(((dot(r, _592) * _623) - _608) / _629, 0.0f, 1.0f);\n            }\n        }\n        return (p + _592) + (_598 * t);\n    }\n    float3 q = p;\n    float _661 = dot(r, axis);\n    bool _669;\n    if (_579)\n    {\n        _669 = abs(_661) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _669 = _579;\n    }\n    if (_669)\n    {\n        float _679 = dot(c - p, axis) / _661;\n        if (_679 > 0.0f)\n        {\n            q = p + (r * _679);\n        }\n    }\n    float3 _692 = q - c;\n    float2 xy = float2(dot(_692, ru), dot(_692, uu));\n    if (shape > 0.5f)\n    {\n        float _707 = length(xy);\n        if (_707 > hx)\n        {\n            xy *= (hx / _707);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _349 = abs(d);\n    float _351 = _349.x;\n    float _353 = _349.y;\n    bool _354 = _351 >= _353;\n    bool _362;\n    if (_354)\n    {\n        _362 = _351 >= _349.z;\n    }\n    else\n    {\n        _362 = _354;\n    }\n    int _363;\n    if (_362)\n    {\n        _363 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _378;\n        if (_353 >= _349.z)\n        {\n            _378 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _378 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _363 = _378;\n    }\n    return _363;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _499 = dot(d, right);\n    float _503 = dot(d, up);\n    float _514;\n    if (((_499 * _499) + (_503 * _503)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _514 = atan2(_503, _499) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _514 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_514 - floor(_514)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _745 = fa_light_base(param);\n    bool _749 = _401_fa_ambient.w > 4.5f;\n    int param_1 = _745;\n    float4 _753 = fa_light_texel(param_1);\n    int param_2 = _745 + 1;\n    float4 _758 = fa_light_texel(param_2);\n    float _761 = _758.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _773 = _749 && (_761 > 2.5f);\n    fa_light_is_area = _773;\n    bool _775 = _761 < 0.5f;\n    float3 l;\n    if (_775)\n    {\n        l = normalize(_753.xyz);\n        if (_749)\n        {\n            int param_3 = _745 + 6;\n            float4 _789 = fa_light_texel(param_3);\n            if (_789.z > 0.5f)\n            {\n                int param_4 = _745 + 4;\n                float4 _799 = fa_light_texel(param_4);\n                int param_5 = _745 + 5;\n                float4 _804 = fa_light_texel(param_5);\n                float2 param_6 = _789.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _799.xyz) * _799.w, (-dot(world_pos, _804.xyz)) * _804.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _834 = _753.xyz;\n        float3 _836 = _834 - world_pos;\n        float3 to_light = _836;\n        float _839 = length(_836);\n        float reach = _839;\n        bool front = true;\n        if (_773)\n        {\n            int param_8 = _745 + 7;\n            reach = max(_839 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _745 + 4;\n            float4 _863 = fa_light_texel(param_9);\n            int param_10 = _745 + 5;\n            float4 _868 = fa_light_texel(param_10);\n            int param_11 = _745 + 6;\n            float4 _873 = fa_light_texel(param_11);\n            float _874 = _873.w;\n            int param_12 = _745 + 2;\n            float3 _881 = normalize(fa_light_texel(param_12).xyz);\n            bool _883 = _874 > 1.5f;\n            bool _891;\n            if (!_883)\n            {\n                _891 = dot(_881, to_light) < 0.0f;\n            }\n            else\n            {\n                _891 = _883;\n            }\n            front = _891;\n            float3 r = 0.0f.xxx;\n            float3 _900 = _401_fa_camera_pos.xyz - world_pos;\n            bool _904 = dot(n, n) > 0.5f;\n            bool _912;\n            if (_904)\n            {\n                _912 = dot(_900, _900) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _912 = _904;\n            }\n            if (_912)\n            {\n                r = reflect(-normalize(_900), normalize(n));\n            }\n            float3 param_13 = _834;\n            float3 param_14 = _881;\n            float3 param_15 = _863.xyz;\n            float3 param_16 = _868.xyz;\n            float param_17 = _863.w;\n            float param_18 = _868.w;\n            float param_19 = _874;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _948 = length(to_light);\n        dist = _948;\n        l = to_light / max(_948, 9.9999997473787516355514526367188e-05f).xxx;\n        float _962 = reach / max(_753.w, 0.001000000047497451305389404296875f);\n        float _968 = clamp(1.0f - (_962 * _962), 0.0f, 1.0f);\n        float _970;\n        if (front)\n        {\n            _970 = _968 * _968;\n        }\n        else\n        {\n            _970 = 0.0f;\n        }\n        atten = _970;\n        bool _981 = _761 < 2.5f;\n        if ((_761 > 1.5f) && _981)\n        {\n            int param_22 = _745 + 2;\n            float4 _989 = fa_light_texel(param_22);\n            float _999 = _989.w;\n            int param_23 = _745 + 3;\n            float4 _1004 = fa_light_texel(param_23);\n            float _1005 = _1004.x;\n            float cos_inner = _1005;\n            if (_1005 > 1.5f)\n            {\n                cos_inner = lerp(_999, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_999, cos_inner, dot(-l, normalize(_989.xyz)));\n        }\n        if (_749 && (_761 < 1.5f))\n        {\n            int param_24 = _745 + 6;\n            float4 _1029 = fa_light_texel(param_24);\n            if (_1029.z > 0.5f)\n            {\n                float3 _1037 = -to_light;\n                int param_25 = _745 + 4;\n                int param_26 = _745 + 5;\n                float3 _1051 = fa_light_texel(param_25).xyz;\n                float3 _1055 = fa_light_texel(param_26).xyz;\n                float3 _1064 = float3(dot(_1037, _1051), dot(_1037, _1055), dot(_1037, cross(_1051, _1055)));\n                float3 param_27 = _1064;\n                int _1068 = fa_cube_face(param_27);\n                int param_28 = _1068;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1095 = float2(dot(_1064, cross(param_29, param_30)), dot(_1064, param_30)) / max(dot(_1064, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1099 = _1068 / 3;\n                float2 param_31 = _1029.xy + (float2(float(_1068 - (_1099 * 3)), float(_1099)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1095.x), 0.5f - (0.5f * _1095.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _745 + 7;\n            float4 _1129 = fa_light_texel(param_33);\n            if (_1129.z > 0.5f)\n            {\n                int param_34 = _745 + 2;\n                int param_35 = _745 + 4;\n                int param_36 = _745 + 5;\n                float2 param_37 = _1129.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_749 && _981)\n            {\n                int param_42 = _745 + 6;\n                float4 _1176 = fa_light_texel(param_42);\n                int param_43 = _745 + 7;\n                float4 _1181 = fa_light_texel(param_43);\n                bool _1184 = _1176.z > 0.5f;\n                bool _1191;\n                if (!_1184)\n                {\n                    _1191 = _1181.z > 0.5f;\n                }\n                else\n                {\n                    _1191 = _1184;\n                }\n                if (_1191)\n                {\n                    int param_44 = _745 + 2;\n                    float4 _1198 = fa_light_texel(param_44);\n                    float3 _1202 = normalize(_1198.xyz);\n                    int param_45 = _745 + 4;\n                    float4 _1207 = fa_light_texel(param_45);\n                    int param_46 = _745 + 5;\n                    float4 _1212 = fa_light_texel(param_46);\n                    if (_1184)\n                    {\n                        float3 _1220 = -to_light;\n                        float _1227 = _1198.w;\n                        float _1243 = 0.5f / max(dot(_1220, _1202) * (sqrt(max(1.0f - (_1227 * _1227), 0.0f)) / max(_1227, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1176.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1220, _1207.xyz) * _1243), 0.5f - (dot(_1220, _1212.xyz) * _1243));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1181.z > 0.5f)\n                    {\n                        float2 param_49 = _1181.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1202;\n                        float3 param_52 = _1207.xyz;\n                        float3 param_53 = _1212.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4802 = _758.xyz * atten;\n    if (_749)\n    {\n        _4802 *= fa_light_tint;\n    }\n    int _1311;\n    if (_775)\n    {\n        _1311 = 0;\n    }\n    else\n    {\n        _1311 = ((_761 > 1.5f) && (_761 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _4813 = { l, _4802, atten, 1.0f, dist, _1311 };\n    return _4813;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2048;\n    if (i == 0)\n    {\n        _2048 = _2058_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2064;\n        if (i == 1)\n        {\n            _2064 = _2058_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2072;\n            if (i == 2)\n            {\n                _2072 = _2058_fa_shadow_split.z;\n            }\n            else\n            {\n                _2072 = _2058_fa_shadow_split.w;\n            }\n            _2064 = _2072;\n        }\n        _2048 = _2064;\n    }\n    return _2048;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2105 = fa_shadow_depth(param, param_1);\n    float _2109;\n    if (conv.x < 0.5f)\n    {\n        _2109 = _2105;\n    }\n    else\n    {\n        _2109 = (conv.y * conv.z) / (conv.z - (_2105 * (conv.z - conv.y)));\n    }\n    return _2109;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2036 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2036), sin(_2036)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2155 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2164;\n        if (k < 0.0f)\n        {\n            _2164 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2164 = k;\n        }\n        float _2184 = clamp((_2164 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2155;\n            float2 _2203 = fa_shadow_vogel(param_3, param_4, param_5) * _2184;\n            float2 param_6 = uv + (_2203 * _2058_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2215 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2215 < (zr - (length(_2203) * plane)))\n            {\n                sum += _2215;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2241 = sum / cnt;\n        float _2251;\n        if (k < 0.0f)\n        {\n            _2251 = (-k) / max(_2241, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2251 = k;\n        }\n        radius = clamp(((max(zr - _2241, 0.0f) * unit) * _2251) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2273 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2273; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2273;\n        float param_11 = _2155;\n        float2 _2292 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2292 * _2058_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2292) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2273);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2334 = max(_2058_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2339 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2345 = sqrt(1.0f - (_2339 * _2339));\n    float _2352 = min(_2345 / max(_2339, 0.20000000298023223876953125f), 4.0f);\n    float _2357;\n    if (_2058_fa_shadow_bias.y > 0.0f)\n    {\n        _2357 = _2058_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2357 = 1.5f * _2058_fa_shadow_info[ci].x;\n    }\n    float4 _2382 = mul(float4(world + (n * (_2357 * _2345)), 1.0f), _2058_fa_shadow_mat[ci]);\n    float _2389 = _2382.x;\n    bool _2392 = _2389 < _2058_fa_shadow_rect[ci].x;\n    bool _2401;\n    if (!_2392)\n    {\n        _2401 = _2389 > _2058_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2401 = _2392;\n    }\n    bool _2410;\n    if (!_2401)\n    {\n        _2410 = _2382.y < _2058_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2410 = _2401;\n    }\n    bool _2419;\n    if (!_2410)\n    {\n        _2419 = _2382.y > _2058_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2419 = _2410;\n    }\n    bool _2426;\n    if (!_2419)\n    {\n        _2426 = _2382.z > 1.0f;\n    }\n    else\n    {\n        _2426 = _2419;\n    }\n    if (_2426)\n    {\n        return -1.0f;\n    }\n    float _2434;\n    if (_2058_fa_shadow_bias.x > 0.0f)\n    {\n        _2434 = _2058_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2434 = 1.5f * _2058_fa_shadow_info[ci].x;\n    }\n    float2 param = _2382.xy;\n    float4 param_1 = _2058_fa_shadow_rect[ci];\n    float param_2 = _2382.z - ((_2434 * (1.0f + (0.5f * _2352))) / _2334);\n    float param_3 = _2058_fa_shadow_info[ci].x;\n    float param_4 = _2334;\n    float param_5 = _2334 * 0.25f;\n    float param_6 = ((_2058_fa_shadow_info[ci].x * min(_2352, 3.0f)) * 0.5f) / _2334;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2058_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2058_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_401_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2812 = int(_2058_fa_shadow_cfg.x + 0.5f);\n    if (_2812 < 1)\n    {\n        return 1.0f;\n    }\n    float _2827 = dot(world - _2058_fa_shadow_eye.xyz, _2058_fa_shadow_fwd.xyz);\n    int param = _2812 - 1;\n    if (_2827 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2839 = _2812 > 1;\n    bool _2846;\n    if (_2839)\n    {\n        _2846 = _2827 > _2058_fa_shadow_split.x;\n    }\n    else\n    {\n        _2846 = _2839;\n    }\n    if (_2846)\n    {\n        ci = 1;\n    }\n    bool _2850 = _2812 > 2;\n    bool _2857;\n    if (_2850)\n    {\n        _2857 = _2827 > _2058_fa_shadow_split.y;\n    }\n    else\n    {\n        _2857 = _2850;\n    }\n    if (_2857)\n    {\n        ci = 2;\n    }\n    bool _2861 = _2812 > 3;\n    bool _2868;\n    if (_2861)\n    {\n        _2868 = _2827 > _2058_fa_shadow_split.z;\n    }\n    else\n    {\n        _2868 = _2861;\n    }\n    if (_2868)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2812)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2894 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2894;\n        if (_2894 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2058_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2919;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2919 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2919 = _2058_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2938 = _2058_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2919, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2949 = clamp((_2827 - (fa_shadow_split_at(param_7) - _2938)) / _2938, 0.0f, 1.0f);\n        if (_2949 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2812)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2970 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2970;\n                if (_2970 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2949);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2492 = _401_fa_pbr.z < 0.5f;\n    bool _2499;\n    if (!_2492)\n    {\n        _2499 = _2058_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2499 = _2492;\n    }\n    if (_2499)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2058_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2512 = fa_light_texel(param);\n    float _2513 = _2512.x;\n    if (_2513 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2522 = int(_2513 + 0.5f);\n    int param_1 = _2522;\n    float4 _2526 = fa_light_texel(param_1);\n    int param_2 = _2522 + 1;\n    float4 _2531 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2534 = _2526.y;\n    if (_2534 > 0.0f)\n    {\n        float _2551 = 1.0f - smoothstep(0.75f * _2534, _2534, length(world - _2058_fa_shadow_eye.xyz));\n        fade = _2551;\n        if (_2551 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2526.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2575 = (_2522 + 2) + (face * 6);\n    int param_4 = _2575;\n    int param_5 = _2575 + 1;\n    int param_6 = _2575 + 3;\n    float4 _2589 = fa_light_texel(param_6);\n    int param_7 = _2575 + 4;\n    float4 _2594 = fa_light_texel(param_7);\n    int param_8 = _2575 + 5;\n    float4 _2599 = fa_light_texel(param_8);\n    float _2611 = _2599.x * max(dot(_2589, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2616 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2639 = clamp(dot(n, _2589.xyz), -1.0f, 1.0f);\n    float _2658 = min(sqrt(1.0f - (_2639 * _2639)) / max(abs(dot(n, world - lpos)) / max(dot(_2589, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2661 = _2531.y;\n    float _2663;\n    if (_2661 > 0.0f)\n    {\n        _2663 = _2661;\n    }\n    else\n    {\n        _2663 = 1.5f * _2611;\n    }\n    float4 _2683 = float4(world + (n * (_2663 * sqrt(1.0f - (_2616 * _2616)))), 1.0f);\n    float _2687 = dot(_2589, _2683);\n    float _2690 = _2599.y;\n    if (_2687 < _2690)\n    {\n        return 1.0f;\n    }\n    float2 _2705 = float2(dot(fa_light_texel(param_4), _2683), dot(fa_light_texel(param_5), _2683)) / _2687.xx;\n    float _2707 = _2705.x;\n    bool _2710 = _2707 < _2594.x;\n    bool _2719;\n    if (!_2710)\n    {\n        _2719 = _2707 > _2594.z;\n    }\n    else\n    {\n        _2719 = _2710;\n    }\n    bool _2728;\n    if (!_2719)\n    {\n        _2728 = _2705.y < _2594.y;\n    }\n    else\n    {\n        _2728 = _2719;\n    }\n    bool _2737;\n    if (!_2728)\n    {\n        _2737 = _2705.y > _2594.w;\n    }\n    else\n    {\n        _2737 = _2728;\n    }\n    if (_2737)\n    {\n        return 1.0f;\n    }\n    float _2743 = _2531.x;\n    float _2745;\n    if (_2743 > 0.0f)\n    {\n        _2745 = _2743;\n    }\n    else\n    {\n        _2745 = 1.5f * _2611;\n    }\n    float2 param_9 = _2705;\n    float4 param_10 = _2594;\n    float param_11 = _2687 - (_2745 * (1.0f + (0.5f * _2658)));\n    float param_12 = _2611;\n    float param_13 = 1.0f;\n    float param_14 = _2599.z * 0.25f;\n    float param_15 = (_2611 * min(_2658, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2690, _2599.z);\n    int param_17 = int(_2526.z + 0.5f);\n    float param_18 = _2526.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _3368 = _401_fa_ct_a.x < 0.5f;\n    bool _3375;\n    if (!_3368)\n    {\n        _3375 = _2058_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _3375 = _3368;\n    }\n    if (_3375)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2058_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _3388 = fa_light_texel(param);\n    float _3389 = _3388.y;\n    float len = _3389;\n    if (_3389 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3401 = length(world - _401_fa_camera_pos.xyz);\n    float _3411 = 1.0f - smoothstep(0.5f * _401_fa_ct_b.x, _401_fa_ct_b.x, _3401);\n    if (_3411 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3417 = len;\n    float _3420 = min(_3417, 0.89999997615814208984375f * dist);\n    len = _3420;\n    float _3426 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _3401);\n    float _3431 = _3426 + (0.5f * _3420);\n    float3 _3437 = world + (gn * _3426);\n    float _3439 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _3504;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3455 = (float(k) + _3439) * 0.083333335816860198974609375f;\n        float3 _3463 = _3437 + (l * (_3455 * len));\n        float4 _3469 = float4(_3463, 1.0f);\n        float _3475 = dot(_401_fa_ct_vpw, _3469);\n        if (_3475 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _3495 = float2(dot(_401_fa_ct_vpx, _3469), dot(_401_fa_ct_vpy, _3469)) / _3475.xx;\n        float _3499 = _3495.x * 0.5f;\n        float _3500 = _3499 + 0.5f;\n        if (_401_fa_ct_a.y > 0.5f)\n        {\n            _3504 = (_3495.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _3504 = 0.5f - (_3495.y * 0.5f);\n        }\n        bool _3520 = _3500 < 0.0f;\n        bool _3527;\n        if (!_3520)\n        {\n            _3527 = _3500 >= 1.0f;\n        }\n        else\n        {\n            _3527 = _3520;\n        }\n        bool _3534;\n        if (!_3527)\n        {\n            _3534 = _3504 < 0.0f;\n        }\n        else\n        {\n            _3534 = _3527;\n        }\n        bool _3541;\n        if (!_3534)\n        {\n            _3541 = _3504 >= 1.0f;\n        }\n        else\n        {\n            _3541 = _3534;\n        }\n        if (_3541)\n        {\n            break;\n        }\n        float4 _3560 = fa_screen_tex.Load(int3(int2(float2(_3500, _3504) * _401_fa_ct_a.zw), 0));\n        if (_3560.w < 0.5f)\n        {\n            continue;\n        }\n        float _3579 = (dot(_401_fa_ct_fwd.xyz, _3463) + _401_fa_ct_fwd.w) - _3560.x;\n        if ((_3579 > _3426) && (_3579 < _3431))\n        {\n            occ = max(occ, (1.0f - (_3455 * _3455)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_3500, 0.5f - _3499), min(_3504, 1.0f - _3504))));\n        }\n    }\n    return 1.0f - (occ * _3411);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _3682 = fa_baked_keep(param);\n    if (_3682 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _4826 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _4826;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3708 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _4828 = _3708.color;\n    float _4829 = _3708.attenuation;\n    float _4830 = _3708.shadow;\n    bool _3711 = _3708.type == 0;\n    if (_3711 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3708.direction;\n        float _3722 = fa_shadow_factor(param_5, param_6);\n        _4830 = _3722;\n        _4828 *= _3722;\n    }\n    else\n    {\n        bool _3733 = _3708.type != 0;\n        bool _3739;\n        if (_3733)\n        {\n            _3739 = _4829 > 0.0f;\n        }\n        else\n        {\n            _3739 = _3733;\n        }\n        if (_3739)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _3708.direction;\n            float _3758 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _4830 = _3758;\n            _4828 *= _3758;\n        }\n    }\n    bool _3768 = _401_fa_ct_a.x > 0.5f;\n    bool _3774;\n    if (_3768)\n    {\n        _3774 = _4829 > 0.0f;\n    }\n    else\n    {\n        _3774 = _3768;\n    }\n    if (_3774)\n    {\n        float _3781;\n        if (_3711)\n        {\n            _3781 = 1000000000.0f;\n        }\n        else\n        {\n            _3781 = _3708._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _3708.direction;\n        float param_18 = _3781;\n        float _3799 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _4830 *= _3799;\n        _4828 *= _3799;\n    }\n    float _3812 = _4829;\n    float _3813 = _3812 * _3682;\n    _4829 = _3813;\n    float3 _3817 = _4828;\n    float3 _3818 = _3817 * _3682;\n    _4828 = _3818;\n    LightSample _4845 = { _3708.direction, _3818, _3813, _4830, _3708._distance, _3708.type };\n    return _4845;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2058_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _2994 = int(_2058_fa_shadow_cfg.x + 0.5f);\n    float _3004 = dot(world - _2058_fa_shadow_eye.xyz, _2058_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3009 = _2994 > 0;\n    bool _3018;\n    if (_3009)\n    {\n        int param = _2994 - 1;\n        _3018 = _3004 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3018 = _3009;\n    }\n    if (_3018)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3024 = _2994 > 1;\n        bool _3031;\n        if (_3024)\n        {\n            _3031 = _3004 > _2058_fa_shadow_split.x;\n        }\n        else\n        {\n            _3031 = _3024;\n        }\n        if (_3031)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3037 = _2994 > 2;\n        bool _3044;\n        if (_3037)\n        {\n            _3044 = _3004 > _2058_fa_shadow_split.y;\n        }\n        else\n        {\n            _3044 = _3037;\n        }\n        if (_3044)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3050 = _2994 > 3;\n        bool _3057;\n        if (_3050)\n        {\n            _3057 = _3004 > _2058_fa_shadow_split.z;\n        }\n        else\n        {\n            _3057 = _3050;\n        }\n        if (_3057)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _4644 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4644 = -_4644;\n    }\n    float3 _4235 = normalize(_401_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _4657 = { fa_world_pos, _4644, fa_world_tangent, fa_uv, fa_vertex_color, _4235, gl_FrontFacing };\n    SurfaceInput param_1 = _4657;\n    Surface _4243 = fa_standard_surface(param_1);\n    float3 _4683 = _4243.albedo;\n    float _4684 = _4243.alpha;\n    float3 _4685 = _4243.normal;\n    float _4686 = _4243.metallic;\n    float _4687 = _4243.roughness;\n    float _4688 = _4243.occlusion;\n    float3 _4689 = _4243.emission;\n    float _4690 = _4243.clearcoat;\n    float _4691 = _4243.clearcoat_roughness;\n    float3 _4692 = _4243.sheen_color;\n    float _4693 = _4243.sheen_roughness;\n    float _4694 = _4243.anisotropy;\n    float _4695 = _4243.anisotropy_rotation;\n    float _4696 = _4243.specular;\n    float _4697 = _4243.ior;\n    float3 _4698 = _4243.specular_color;\n    SurfaceInput _4665 = { fa_world_pos, _4644, fa_world_tangent, fa_uv, fa_vertex_color, _4235, gl_FrontFacing };\n    SurfaceInput param_2 = _4665;\n    Surface param_3 = _4243;\n    surface(param_2, param_3);\n    _4683 = param_3.albedo;\n    _4684 = param_3.alpha;\n    _4685 = param_3.normal;\n    _4686 = param_3.metallic;\n    _4687 = param_3.roughness;\n    _4688 = param_3.occlusion;\n    _4689 = param_3.emission;\n    _4690 = param_3.clearcoat;\n    _4691 = param_3.clearcoat_roughness;\n    _4692 = param_3.sheen_color;\n    _4693 = param_3.sheen_roughness;\n    _4694 = param_3.anisotropy;\n    _4695 = param_3.anisotropy_rotation;\n    _4696 = param_3.specular;\n    _4697 = param_3.ior;\n    _4698 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _4644;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4683 = param_6;\n    _4685 = param_7;\n    float3 result;\n    if (_401_fa_emissive.w > 0.5f)\n    {\n        result = _4683;\n    }\n    else\n    {\n        float3 _4281 = _4685;\n        float3 _4282 = normalize(_4281);\n        _4685 = _4282;\n        float3 param_8 = _4282;\n        SurfaceInput _4673 = { fa_world_pos, _4644, fa_world_tangent, fa_uv, fa_vertex_color, _4235, gl_FrontFacing };\n        SurfaceInput param_9 = _4673;\n        Surface _4764 = { _4683, _4684, _4685, _4686, _4687, _4688, _4689, _4690, _4691, _4692, _4693, _4694, _4695, _4696, _4697, _4698 };\n        Surface param_10 = _4764;\n        float3 param_11 = fa_indirect_diffuse(param_8);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _4301 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4301; ln++)\n        {\n            int param_12 = ln;\n            int _4314 = fa_cl_light(param_12);\n            int param_13 = _4314;\n            if (fa_baked_keep(param_13) <= 0.0f)\n            {\n                continue;\n            }\n            int param_14 = _4314;\n            float3 param_15 = fa_world_pos;\n            float3 param_16 = _4644;\n            LightSample _4330 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput _4681 = { fa_world_pos, _4644, fa_world_tangent, fa_uv, fa_vertex_color, _4235, gl_FrontFacing };\n            SurfaceInput param_17 = _4681;\n            Surface _4781 = { _4683, _4684, _4685, _4686, _4687, _4688, _4689, _4690, _4691, _4692, _4693, _4694, _4695, _4696, _4697, _4698 };\n            Surface param_18 = _4781;\n            LightSample param_19 = _4330;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _4345 = result;\n    float3 _4346 = _4345 + _4689;\n    result = _4346;\n    float3 param_20 = _4346;\n    float3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _4355 = _401_fa_fog.w > 0.0f;\n    bool _4362;\n    if (!_4355)\n    {\n        _4362 = _401_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _4362 = _4355;\n    }\n    if (_4362)\n    {\n        float3 _4371 = fa_world_pos - _401_fa_camera_pos.xyz;\n        float _4377 = dot(_4371, _401_fa_fog_c.xyz);\n        bool _4381 = _401_fa_fog_c.w > 0.5f;\n        float _4382;\n        if (_4381)\n        {\n            _4382 = _4377;\n        }\n        else\n        {\n            _4382 = length(_4371);\n        }\n        float _4394 = _4382 - _401_fa_fog_b.x;\n        if (_4394 > 0.0f)\n        {\n            float _4403 = _401_fa_fog.w * _4394;\n            float tau = _4403 * _4403;\n            if (_401_fa_fog_b.y > 0.0f)\n            {\n                float _4419;\n                if (_4381)\n                {\n                    _4419 = fa_world_pos.y - (_401_fa_fog_c.y * _4377);\n                }\n                else\n                {\n                    _4419 = _401_fa_camera_pos.y;\n                }\n                float _4440 = lerp(_4419, fa_world_pos.y, clamp(_401_fa_fog_b.x / _4382, 0.0f, 1.0f));\n                float _4444 = fa_world_pos.y - _4440;\n                float _4449 = _4440 - _401_fa_fog_b.z;\n                float _4454 = fa_world_pos.y - _401_fa_fog_b.z;\n                bool _4457 = _4449 <= 0.0f;\n                bool _4458 = !_4457;\n                bool _4464;\n                if (_4458)\n                {\n                    _4464 = _401_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4464 = _4457;\n                }\n                float _4465;\n                if (_4464)\n                {\n                    _4465 = _401_fa_fog_b.y;\n                }\n                else\n                {\n                    _4465 = _401_fa_fog_b.y * exp(-min(_401_fa_fog_b.w * _4449, 80.0f));\n                }\n                bool _4492;\n                if (_4458)\n                {\n                    _4492 = _401_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4492 = _4457;\n                }\n                float _4493;\n                if (_4492)\n                {\n                    _4493 = _401_fa_fog_b.y * _4449;\n                }\n                else\n                {\n                    _4493 = (_401_fa_fog_b.y * (1.0f - exp(-min(_401_fa_fog_b.w * _4449, 80.0f)))) / _401_fa_fog_b.w;\n                }\n                bool _4518 = _4454 <= 0.0f;\n                bool _4525;\n                if (!_4518)\n                {\n                    _4525 = _401_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4525 = _4518;\n                }\n                float _4526;\n                if (_4525)\n                {\n                    _4526 = _401_fa_fog_b.y * _4454;\n                }\n                else\n                {\n                    _4526 = (_401_fa_fog_b.y * (1.0f - exp(-min(_401_fa_fog_b.w * _4454, 80.0f)))) / _401_fa_fog_b.w;\n                }\n                float _4553;\n                if (abs(_4444) < 0.001000000047497451305389404296875f)\n                {\n                    _4553 = _4465;\n                }\n                else\n                {\n                    _4553 = (_4526 - _4493) / _4444;\n                }\n                tau += (_4394 * max(_4553, 0.0f));\n            }\n            result = lerp(result, _401_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4684);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_401",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2058",
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
