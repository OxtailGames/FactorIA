{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "63c8ed9ef72f0fba56beb38b3018a9ae9876604a67ae71ca005757f89f9b9e64",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _260 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _260;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_267, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _320_fa_camera_pos : packoffset(c0);\n    float4 _320_fa_ambient : packoffset(c1);\n    float4 _320_fa_base_color : packoffset(c2);\n    float4 _320_fa_emissive : packoffset(c3);\n    float4 _320_fa_model_emissive : packoffset(c4);\n    float4 _320_fa_pbr : packoffset(c5);\n    float4 _320_fa_maps : packoffset(c6);\n    float4 _320_fa_fog : packoffset(c7);\n    float4 _320_fa_fog_b : packoffset(c8);\n    float4 _320_fa_fog_c : packoffset(c9);\n    float4 _320_fa_counts : packoffset(c10);\n    float4 _320_fa_env_sky : packoffset(c11);\n    float4 _320_fa_env_horizon : packoffset(c12);\n    float4 _320_fa_time : packoffset(c13);\n    float4 _320_fa_cl_vpx : packoffset(c14);\n    float4 _320_fa_cl_vpy : packoffset(c15);\n    float4 _320_fa_cl_vpw : packoffset(c16);\n    float4 _320_fa_cl_fwd : packoffset(c17);\n    float4 _320_fa_cl_grid : packoffset(c18);\n    float4 _320_fa_cl_info : packoffset(c19);\n    float4 _320_fa_layers_a : packoffset(c20);\n    float4 _320_fa_layers_b : packoffset(c21);\n    float4 _320_fa_layers_c : packoffset(c22);\n    float4 _320_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2017_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2017_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2017_fa_shadow_info[4] : packoffset(c20);\n    float4 _2017_fa_shadow_split : packoffset(c24);\n    float4 _2017_fa_shadow_cfg : packoffset(c25);\n    float4 _2017_fa_shadow_bias : packoffset(c26);\n    float4 _2017_fa_shadow_eye : packoffset(c27);\n    float4 _2017_fa_shadow_fwd : packoffset(c28);\n    float4 _2017_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_irr_tex : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1288 = _320_fa_cl_info.x < 0.0f;\n    bool _1295;\n    if (!_1288)\n    {\n        _1295 = _320_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1295 = _1288;\n    }\n    bool _1303;\n    if (!_1295)\n    {\n        _1303 = _320_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1303 = _1295;\n    }\n    bool _1310;\n    if (!_1303)\n    {\n        _1310 = _320_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1310 = _1303;\n    }\n    bool _1317;\n    if (!_1310)\n    {\n        _1317 = _320_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1317 = _1310;\n    }\n    if (_1317)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1327 = float4(world_pos, 1.0f);\n    float _1333 = dot(_320_fa_cl_vpw, _1327);\n    if (!(_1333 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1355 = float2(dot(_320_fa_cl_vpx, _1327), dot(_320_fa_cl_vpy, _1327)) / _1333.xx;\n    int _1359 = int(_320_fa_cl_grid.x);\n    int _1363 = int(_320_fa_cl_grid.y);\n    int param = (int(_320_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_320_fa_cl_fwd.xyz, world_pos) + _320_fa_cl_fwd.w, _320_fa_cl_grid.w) / _320_fa_cl_grid.w) * _320_fa_cl_grid.z)), 0, int(_320_fa_cl_info.y) - 1) * _1363) + clamp(int(floor(((_1355.y * 0.5f) + 0.5f) * _320_fa_cl_grid.y)), 0, _1363 - 1)) * _1359)) + clamp(int(floor(((_1355.x * 0.5f) + 0.5f) * _320_fa_cl_grid.x)), 0, _1359 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1439 = fa_cluster_texel(param);\n    return int2(int(_1439.x), int(_1439.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_320_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3079 = fa_cluster_lookup(param);\n    fa_cl_slot = _3079.x;\n    fa_cl_local = _3079.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _3233 = fa_linear_to_srgb(param);\n        c = _3233;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _3241 = fa_srgb_to_linear(param_1);\n            c = _3241;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _252;\n    if (i.front_facing)\n    {\n        _252 = i.world_normal;\n    }\n    else\n    {\n        _252 = -i.world_normal;\n    }\n    float3 _276 = normalize(i.world_tangent.xyz - (_252 * dot(_252, i.world_tangent.xyz)));\n    float3 _304 = normalize(((_276 * m.x) + ((cross(_252, _276) * i.world_tangent.w) * m.y)) + (_252 * m.z));\n    float3 _307;\n    if (i.front_facing)\n    {\n        _307 = _304;\n    }\n    else\n    {\n        _307 = -_304;\n    }\n    return _307;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _320_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3272 = fa_tex_fix(param_2, param_3);\n    float4 _4322 = base_t;\n    _4322.x = _3272.x;\n    _4322.y = _3272.y;\n    _4322.z = _3272.z;\n    base_t = _4322;\n    float4 _3286 = (_4322 * _320_fa_base_color) * i.vertex_color;\n    float3 _4187 = i.world_normal;\n    if (_320_fa_maps.z > 0.5f)\n    {\n        float param_4 = _320_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3318 = fa_tex_fix(param_6, param_7);\n        float3 _3321 = (_3318 * 2.0f) - 1.0f.xxx;\n        float2 _3326 = _3321.xy * _320_fa_maps.x;\n        float3 _4330 = _3321;\n        _4330.x = _3326.x;\n        _4330.y = _3326.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4330;\n        _4187 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _320_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3354 = fa_tex_fix(param_12, param_13);\n    float4 _4333 = mrt;\n    _4333.x = _3354.x;\n    _4333.y = _3354.y;\n    _4333.z = _3354.z;\n    mrt = _4333;\n    float4 _3382 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _320_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _3382.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3393 = fa_tex_fix(param_16, param_17);\n    float param_18 = _320_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3423 = fa_tex_fix(param_20, param_21);\n    float _4192 = _320_fa_layers_a.x;\n    float _4193 = _320_fa_layers_a.y;\n    float _4196 = _320_fa_layers_a.z;\n    float _4195 = _320_fa_layers_b.w;\n    float _4198 = _320_fa_layers_c.x;\n    if (_320_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_320_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _4192 *= _3393.y;\n            _4193 *= _3393.z;\n            _4195 *= _3382.w;\n        }\n        if (_320_fa_layers_c.z > 1.5f)\n        {\n            _4196 *= mrt.x;\n            _4198 *= mrt.w;\n        }\n    }\n    Surface _4217 = { _3286.xyz, _3286.w, _4187, clamp(_320_fa_pbr.x * _3354.z, 0.0f, 1.0f), clamp(_320_fa_pbr.y * _3354.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_320_fa_maps.y * (_3393.x - 1.0f)), _320_fa_emissive.xyz + (_320_fa_model_emissive.xyz * _3423), _4192, _4193, _320_fa_layers_b.xyz, _4195, _4196, _320_fa_layers_a.w, _4198, _320_fa_layers_c.y, _320_fa_layers_d.xyz };\n    return _4217;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1519 = rect.zw - rect.xy;\n    float2 _1523 = _1519 * atlas;\n    float2 _1527 = ddx * _1523;\n    float2 _1531 = ddy * _1523;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1519), clamp(0.5f * log2(max(max(dot(_1527, _1527), dot(_1531, _1531)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1564 = _320_fa_counts.y < 0.5f;\n    bool _1571;\n    if (!_1564)\n    {\n        _1571 = _320_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1571 = _1564;\n    }\n    if (_1571)\n    {\n        return;\n    }\n    float3 _1577 = ddx(world_pos);\n    float3 _1580 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1584 = fa_cluster_texel(param);\n    int _1588 = int(_1584.w);\n    if (_1588 < 1)\n    {\n        return;\n    }\n    int _1598 = int(_320_fa_counts.y + 0.5f);\n    int param_1 = _1598;\n    float4 _1602 = fa_light_texel(param_1);\n    float2 _1605 = _1602.yz;\n    int _1609 = int(_1602.w);\n    int param_2 = _1598 + 1;\n    float4 _1614 = fa_light_texel(param_2);\n    float _1615 = _1614.x;\n    int _1621 = int(_320_fa_counts.w + 0.5f) - 1;\n    int _1625 = int(_1584.z);\n    float3 _1890;\n    for (int k = 0; k < _1588; k++)\n    {\n        int _1638 = _1625 + k;\n        int param_3 = _1609 + (_1638 >> 2);\n        int _1655 = (_1598 + 2) + (int(fa_light_texel(param_3)[_1638 & 3]) * 7);\n        int param_4 = _1655 + 6;\n        float4 _1660 = fa_light_texel(param_4);\n        if (((int(_1660.w + 0.5f) >> _1621) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1655;\n        float4 _1675 = fa_light_texel(param_5);\n        int param_6 = _1655 + 1;\n        float4 _1680 = fa_light_texel(param_6);\n        int param_7 = _1655 + 2;\n        float4 _1685 = fa_light_texel(param_7);\n        float3 _1688 = _1675.xyz;\n        float _1693 = dot(_1688, world_pos) + _1675.w;\n        float3 _1695 = _1680.xyz;\n        float _1700 = dot(_1695, world_pos) + _1680.w;\n        float3 _1702 = _1685.xyz;\n        float _1707 = dot(_1702, world_pos) + _1685.w;\n        bool _1712 = abs(_1693) > 0.5f;\n        bool _1720;\n        if (!_1712)\n        {\n            _1720 = abs(_1700) > 0.5f;\n        }\n        else\n        {\n            _1720 = _1712;\n        }\n        bool _1728;\n        if (!_1720)\n        {\n            _1728 = abs(_1707) > 0.5f;\n        }\n        else\n        {\n            _1728 = _1720;\n        }\n        if (_1728)\n        {\n            continue;\n        }\n        float _1743 = clamp(dot(geo_normal, normalize(_1702)) * _1660.z, 0.0f, 1.0f);\n        if (_1743 <= 0.0f)\n        {\n            continue;\n        }\n        float _1763 = (clamp((0.5f - abs(_1707)) * 10.0f, 0.0f, 1.0f) * _1743) * _1660.x;\n        float2 _1771 = float2(_1693 + 0.5f, 0.5f - _1700);\n        float2 _1781 = float2(dot(_1688, _1577), dot(_1695, _1577));\n        float2 _1791 = float2(dot(_1688, _1580), dot(_1695, _1580));\n        int param_8 = _1655 + 5;\n        float4 _1796 = fa_light_texel(param_8);\n        int param_9 = _1655 + 3;\n        float4 _1801 = fa_light_texel(param_9);\n        int param_10 = _1655 + 4;\n        float4 _1806 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1796.xyz;\n        bool _1816 = _1801.z > _1801.x;\n        if (_1816)\n        {\n            float4 param_11 = _1801;\n            float2 param_12 = _1771;\n            float2 param_13 = _1605;\n            float2 param_14 = _1781;\n            float2 param_15 = _1791;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1615 > 0.5f) && (_1615 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1842 = fa_dc_to_linear(param_16);\n                float4 _4267 = tx;\n                _4267.x = _1842.x;\n                _4267.y = _1842.y;\n                _4267.z = _1842.z;\n                tx = _4267;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1763 * tex_a) * _1796.w, 0.0f, 1.0f).xxx);\n        if (_1806.z > _1806.x)\n        {\n            float4 param_17 = _1806;\n            float2 param_18 = _1771;\n            float2 param_19 = _1605;\n            float2 param_20 = _1781;\n            float2 param_21 = _1791;\n            float4 _1886 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1615 > 1.5f)\n            {\n                float3 param_22 = _1886.xyz;\n                float3 _1896 = fa_dc_to_srgb(param_22);\n                _1890 = _1896;\n            }\n            else\n            {\n                _1890 = _1886.xyz;\n            }\n            float3 _1905 = (_1890 * 2.0f) - 1.0f.xxx;\n            float2 _1910 = _1905.xy * _1660.y;\n            float3 _1932 = (normalize(_1688) * _1910.x) + (normalize(_1695) * _1910.y);\n            float3 _1935 = normalize(normal);\n            normal = normalize(lerp(_1935, normalize((_1935 * max(_1905.z, 0.0500000007450580596923828125f)) + (_1932 - (_1935 * dot(_1935, _1932)))), clamp(_1763 * (_1816 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_320_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _320_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    return float3(0.0f, ambientColor.y, 0.0f);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_320_fa_cl_info.x) + int(_320_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_320_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _382_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _382_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _548 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _561 = (c - (ru * hx)) - p;\n        float3 _567 = ru * (2.0f * hx);\n        float _573 = max(dot(_567, _567), 9.9999999392252902907785028219223e-09f);\n        float _577 = dot(_561, _567);\n        float t = clamp((-_577) / _573, 0.0f, 1.0f);\n        if (_548)\n        {\n            float _592 = dot(r, _567);\n            float _598 = _573 - (_592 * _592);\n            if (abs(_598) > (9.9999997473787516355514526367188e-06f * _573))\n            {\n                t = clamp(((dot(r, _561) * _592) - _577) / _598, 0.0f, 1.0f);\n            }\n        }\n        return (p + _561) + (_567 * t);\n    }\n    float3 q = p;\n    float _630 = dot(r, axis);\n    bool _638;\n    if (_548)\n    {\n        _638 = abs(_630) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _638 = _548;\n    }\n    if (_638)\n    {\n        float _648 = dot(c - p, axis) / _630;\n        if (_648 > 0.0f)\n        {\n            q = p + (r * _648);\n        }\n    }\n    float3 _661 = q - c;\n    float2 xy = float2(dot(_661, ru), dot(_661, uu));\n    if (shape > 0.5f)\n    {\n        float _676 = length(xy);\n        if (_676 > hx)\n        {\n            xy *= (hx / _676);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _469 = abs(d);\n    float _471 = _469.x;\n    float _473 = _469.y;\n    bool _474 = _471 >= _473;\n    bool _482;\n    if (_474)\n    {\n        _482 = _471 >= _469.z;\n    }\n    else\n    {\n        _482 = _474;\n    }\n    int _483;\n    if (_482)\n    {\n        _483 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _496;\n        if (_473 >= _469.z)\n        {\n            _496 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _496 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _483 = _496;\n    }\n    return _483;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _422 = dot(d, right);\n    float _426 = dot(d, up);\n    float _437;\n    if (((_422 * _422) + (_426 * _426)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _437 = atan2(_426, _422) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _437 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_437 - floor(_437)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _714 = fa_light_base(param);\n    bool _718 = _320_fa_ambient.w > 4.5f;\n    int param_1 = _714;\n    float4 _722 = fa_light_texel(param_1);\n    int param_2 = _714 + 1;\n    float4 _727 = fa_light_texel(param_2);\n    float _730 = _727.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _742 = _718 && (_730 > 2.5f);\n    fa_light_is_area = _742;\n    bool _744 = _730 < 0.5f;\n    float3 l;\n    if (_744)\n    {\n        l = normalize(_722.xyz);\n        if (_718)\n        {\n            int param_3 = _714 + 6;\n            float4 _758 = fa_light_texel(param_3);\n            if (_758.z > 0.5f)\n            {\n                int param_4 = _714 + 4;\n                float4 _768 = fa_light_texel(param_4);\n                int param_5 = _714 + 5;\n                float4 _773 = fa_light_texel(param_5);\n                float2 param_6 = _758.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _768.xyz) * _768.w, (-dot(world_pos, _773.xyz)) * _773.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _803 = _722.xyz;\n        float3 _805 = _803 - world_pos;\n        float3 to_light = _805;\n        float _808 = length(_805);\n        float reach = _808;\n        bool front = true;\n        if (_742)\n        {\n            int param_8 = _714 + 7;\n            reach = max(_808 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _714 + 4;\n            float4 _832 = fa_light_texel(param_9);\n            int param_10 = _714 + 5;\n            float4 _837 = fa_light_texel(param_10);\n            int param_11 = _714 + 6;\n            float4 _842 = fa_light_texel(param_11);\n            float _843 = _842.w;\n            int param_12 = _714 + 2;\n            float3 _850 = normalize(fa_light_texel(param_12).xyz);\n            bool _852 = _843 > 1.5f;\n            bool _860;\n            if (!_852)\n            {\n                _860 = dot(_850, to_light) < 0.0f;\n            }\n            else\n            {\n                _860 = _852;\n            }\n            front = _860;\n            float3 r = 0.0f.xxx;\n            if (dot(n, n) > 0.5f)\n            {\n                r = reflect(-normalize(_320_fa_camera_pos.xyz - world_pos), normalize(n));\n            }\n            float3 param_13 = _803;\n            float3 param_14 = _850;\n            float3 param_15 = _832.xyz;\n            float3 param_16 = _837.xyz;\n            float param_17 = _832.w;\n            float param_18 = _837.w;\n            float param_19 = _843;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _907 = length(to_light);\n        dist = _907;\n        l = to_light / max(_907, 9.9999997473787516355514526367188e-05f).xxx;\n        float _921 = reach / max(_722.w, 0.001000000047497451305389404296875f);\n        float _927 = clamp(1.0f - (_921 * _921), 0.0f, 1.0f);\n        float _929;\n        if (front)\n        {\n            _929 = _927 * _927;\n        }\n        else\n        {\n            _929 = 0.0f;\n        }\n        atten = _929;\n        bool _940 = _730 < 2.5f;\n        if ((_730 > 1.5f) && _940)\n        {\n            int param_22 = _714 + 2;\n            float4 _948 = fa_light_texel(param_22);\n            float _958 = _948.w;\n            int param_23 = _714 + 3;\n            float4 _963 = fa_light_texel(param_23);\n            float _964 = _963.x;\n            float cos_inner = _964;\n            if (_964 > 1.5f)\n            {\n                cos_inner = lerp(_958, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_958, cos_inner, dot(-l, normalize(_948.xyz)));\n        }\n        if (_718 && (_730 < 1.5f))\n        {\n            int param_24 = _714 + 6;\n            float4 _988 = fa_light_texel(param_24);\n            if (_988.z > 0.5f)\n            {\n                float3 _996 = -to_light;\n                int param_25 = _714 + 4;\n                int param_26 = _714 + 5;\n                float3 _1010 = fa_light_texel(param_25).xyz;\n                float3 _1014 = fa_light_texel(param_26).xyz;\n                float3 _1023 = float3(dot(_996, _1010), dot(_996, _1014), dot(_996, cross(_1010, _1014)));\n                float3 param_27 = _1023;\n                int _1027 = fa_cube_face(param_27);\n                int param_28 = _1027;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1054 = float2(dot(_1023, cross(param_29, param_30)), dot(_1023, param_30)) / max(dot(_1023, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1058 = _1027 / 3;\n                float2 param_31 = _988.xy + (float2(float(_1027 - (_1058 * 3)), float(_1058)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1054.x), 0.5f - (0.5f * _1054.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _714 + 7;\n            float4 _1088 = fa_light_texel(param_33);\n            if (_1088.z > 0.5f)\n            {\n                int param_34 = _714 + 2;\n                int param_35 = _714 + 4;\n                int param_36 = _714 + 5;\n                float2 param_37 = _1088.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_718 && _940)\n            {\n                int param_42 = _714 + 6;\n                float4 _1135 = fa_light_texel(param_42);\n                int param_43 = _714 + 7;\n                float4 _1140 = fa_light_texel(param_43);\n                bool _1143 = _1135.z > 0.5f;\n                bool _1150;\n                if (!_1143)\n                {\n                    _1150 = _1140.z > 0.5f;\n                }\n                else\n                {\n                    _1150 = _1143;\n                }\n                if (_1150)\n                {\n                    int param_44 = _714 + 2;\n                    float4 _1157 = fa_light_texel(param_44);\n                    float3 _1161 = normalize(_1157.xyz);\n                    int param_45 = _714 + 4;\n                    float4 _1166 = fa_light_texel(param_45);\n                    int param_46 = _714 + 5;\n                    float4 _1171 = fa_light_texel(param_46);\n                    if (_1143)\n                    {\n                        float3 _1179 = -to_light;\n                        float _1186 = _1157.w;\n                        float _1202 = 0.5f / max(dot(_1179, _1161) * (sqrt(max(1.0f - (_1186 * _1186), 0.0f)) / max(_1186, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1135.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1179, _1166.xyz) * _1202), 0.5f - (dot(_1179, _1171.xyz) * _1202));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1140.z > 0.5f)\n                    {\n                        float2 param_49 = _1140.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1161;\n                        float3 param_52 = _1166.xyz;\n                        float3 param_53 = _1171.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4141 = _727.xyz * atten;\n    if (_718)\n    {\n        _4141 *= fa_light_tint;\n    }\n    int _1270;\n    if (_744)\n    {\n        _1270 = 0;\n    }\n    else\n    {\n        _1270 = ((_730 > 1.5f) && (_730 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _4152 = { l, _4141, atten, 1.0f, dist, _1270 };\n    return _4152;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2007;\n    if (i == 0)\n    {\n        _2007 = _2017_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2023;\n        if (i == 1)\n        {\n            _2023 = _2017_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2031;\n            if (i == 2)\n            {\n                _2031 = _2017_fa_shadow_split.z;\n            }\n            else\n            {\n                _2031 = _2017_fa_shadow_split.w;\n            }\n            _2023 = _2031;\n        }\n        _2007 = _2023;\n    }\n    return _2007;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2064 = fa_shadow_depth(param, param_1);\n    float _2068;\n    if (conv.x < 0.5f)\n    {\n        _2068 = _2064;\n    }\n    else\n    {\n        _2068 = (conv.y * conv.z) / (conv.z - (_2064 * (conv.z - conv.y)));\n    }\n    return _2068;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1995 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_1995), sin(_1995)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2114 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2123;\n        if (k < 0.0f)\n        {\n            _2123 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2123 = k;\n        }\n        float _2143 = clamp((_2123 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2114;\n            float2 _2162 = fa_shadow_vogel(param_3, param_4, param_5) * _2143;\n            float2 param_6 = uv + (_2162 * _2017_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2174 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2174 < (zr - (length(_2162) * plane)))\n            {\n                sum += _2174;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2200 = sum / cnt;\n        float _2210;\n        if (k < 0.0f)\n        {\n            _2210 = (-k) / max(_2200, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2210 = k;\n        }\n        radius = clamp(((max(zr - _2200, 0.0f) * unit) * _2210) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2232 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2232; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2232;\n        float param_11 = _2114;\n        float2 _2251 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2251 * _2017_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2251) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2232);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2293 = max(_2017_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2298 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2304 = sqrt(1.0f - (_2298 * _2298));\n    float _2311 = min(_2304 / max(_2298, 0.20000000298023223876953125f), 4.0f);\n    float _2316;\n    if (_2017_fa_shadow_bias.y > 0.0f)\n    {\n        _2316 = _2017_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2316 = 1.5f * _2017_fa_shadow_info[ci].x;\n    }\n    float4 _2341 = mul(float4(world + (n * (_2316 * _2304)), 1.0f), _2017_fa_shadow_mat[ci]);\n    float _2348 = _2341.x;\n    bool _2351 = _2348 < _2017_fa_shadow_rect[ci].x;\n    bool _2360;\n    if (!_2351)\n    {\n        _2360 = _2348 > _2017_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2360 = _2351;\n    }\n    bool _2369;\n    if (!_2360)\n    {\n        _2369 = _2341.y < _2017_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2369 = _2360;\n    }\n    bool _2378;\n    if (!_2369)\n    {\n        _2378 = _2341.y > _2017_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2378 = _2369;\n    }\n    bool _2385;\n    if (!_2378)\n    {\n        _2385 = _2341.z > 1.0f;\n    }\n    else\n    {\n        _2385 = _2378;\n    }\n    if (_2385)\n    {\n        return -1.0f;\n    }\n    float _2393;\n    if (_2017_fa_shadow_bias.x > 0.0f)\n    {\n        _2393 = _2017_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2393 = 1.5f * _2017_fa_shadow_info[ci].x;\n    }\n    float2 param = _2341.xy;\n    float4 param_1 = _2017_fa_shadow_rect[ci];\n    float param_2 = _2341.z - ((_2393 * (1.0f + (0.5f * _2311))) / _2293);\n    float param_3 = _2017_fa_shadow_info[ci].x;\n    float param_4 = _2293;\n    float param_5 = _2293 * 0.25f;\n    float param_6 = ((_2017_fa_shadow_info[ci].x * min(_2311, 3.0f)) * 0.5f) / _2293;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2017_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2017_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_320_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2781 = int(_2017_fa_shadow_cfg.x + 0.5f);\n    if (_2781 < 1)\n    {\n        return 1.0f;\n    }\n    float _2796 = dot(world - _2017_fa_shadow_eye.xyz, _2017_fa_shadow_fwd.xyz);\n    int param = _2781 - 1;\n    if (_2796 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2808 = _2781 > 1;\n    bool _2815;\n    if (_2808)\n    {\n        _2815 = _2796 > _2017_fa_shadow_split.x;\n    }\n    else\n    {\n        _2815 = _2808;\n    }\n    if (_2815)\n    {\n        ci = 1;\n    }\n    bool _2819 = _2781 > 2;\n    bool _2826;\n    if (_2819)\n    {\n        _2826 = _2796 > _2017_fa_shadow_split.y;\n    }\n    else\n    {\n        _2826 = _2819;\n    }\n    if (_2826)\n    {\n        ci = 2;\n    }\n    bool _2830 = _2781 > 3;\n    bool _2837;\n    if (_2830)\n    {\n        _2837 = _2796 > _2017_fa_shadow_split.z;\n    }\n    else\n    {\n        _2837 = _2830;\n    }\n    if (_2837)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2781)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2863 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2863;\n        if (_2863 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2017_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2888;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2888 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2888 = _2017_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2907 = _2017_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2888, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2918 = clamp((_2796 - (fa_shadow_split_at(param_7) - _2907)) / _2907, 0.0f, 1.0f);\n        if (_2918 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2781)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2939 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2939;\n                if (_2939 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2918);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _2451 = _320_fa_pbr.z < 0.5f;\n    bool _2458;\n    if (!_2451)\n    {\n        _2458 = _2017_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2458 = _2451;\n    }\n    if (_2458)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2017_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2471 = fa_light_texel(param);\n    float _2472 = _2471.x;\n    if (_2472 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2481 = int(_2472 + 0.5f);\n    int param_1 = _2481;\n    float4 _2485 = fa_light_texel(param_1);\n    int param_2 = _2481 + 1;\n    float4 _2490 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2493 = _2485.y;\n    if (_2493 > 0.0f)\n    {\n        float _2510 = 1.0f - smoothstep(0.75f * _2493, _2493, length(world - _2017_fa_shadow_eye.xyz));\n        fade = _2510;\n        if (_2510 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2485.x > 1.5f)\n    {\n        int param_3 = li;\n        int param_4 = fa_light_base(param_3);\n        float3 param_5 = world - fa_light_texel(param_4).xyz;\n        face = fa_cube_face(param_5);\n    }\n    int _2539 = (_2481 + 2) + (face * 6);\n    int param_6 = _2539;\n    int param_7 = _2539 + 1;\n    int param_8 = _2539 + 3;\n    float4 _2553 = fa_light_texel(param_8);\n    int param_9 = _2539 + 4;\n    float4 _2558 = fa_light_texel(param_9);\n    int param_10 = _2539 + 5;\n    float4 _2563 = fa_light_texel(param_10);\n    float _2575 = _2563.x * max(dot(_2553, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2580 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2603 = clamp(dot(n, _2553.xyz), -1.0f, 1.0f);\n    int param_11 = li;\n    int param_12 = fa_light_base(param_11);\n    float _2627 = min(sqrt(1.0f - (_2603 * _2603)) / max(abs(dot(n, world - fa_light_texel(param_12).xyz)) / max(dot(_2553, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2630 = _2490.y;\n    float _2632;\n    if (_2630 > 0.0f)\n    {\n        _2632 = _2630;\n    }\n    else\n    {\n        _2632 = 1.5f * _2575;\n    }\n    float4 _2652 = float4(world + (n * (_2632 * sqrt(1.0f - (_2580 * _2580)))), 1.0f);\n    float _2656 = dot(_2553, _2652);\n    float _2659 = _2563.y;\n    if (_2656 < _2659)\n    {\n        return 1.0f;\n    }\n    float2 _2674 = float2(dot(fa_light_texel(param_6), _2652), dot(fa_light_texel(param_7), _2652)) / _2656.xx;\n    float _2676 = _2674.x;\n    bool _2679 = _2676 < _2558.x;\n    bool _2688;\n    if (!_2679)\n    {\n        _2688 = _2676 > _2558.z;\n    }\n    else\n    {\n        _2688 = _2679;\n    }\n    bool _2697;\n    if (!_2688)\n    {\n        _2697 = _2674.y < _2558.y;\n    }\n    else\n    {\n        _2697 = _2688;\n    }\n    bool _2706;\n    if (!_2697)\n    {\n        _2706 = _2674.y > _2558.w;\n    }\n    else\n    {\n        _2706 = _2697;\n    }\n    if (_2706)\n    {\n        return 1.0f;\n    }\n    float _2712 = _2490.x;\n    float _2714;\n    if (_2712 > 0.0f)\n    {\n        _2714 = _2712;\n    }\n    else\n    {\n        _2714 = 1.5f * _2575;\n    }\n    float2 param_13 = _2674;\n    float4 param_14 = _2558;\n    float param_15 = _2656 - (_2714 * (1.0f + (0.5f * _2627)));\n    float param_16 = _2575;\n    float param_17 = 1.0f;\n    float param_18 = _2563.z * 0.25f;\n    float param_19 = (_2575 * min(_2627, 3.0f)) * 0.5f;\n    float3 param_20 = float3(1.0f, _2659, _2563.z);\n    int param_21 = int(_2485.z + 0.5f);\n    float param_22 = _2485.w;\n    return lerp(1.0f, fa_shadow_filter(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _3106 = fa_lm.z > 0.5f;\n    bool _3112;\n    if (_3106)\n    {\n        int param = li;\n        _3112 = fa_light_baked(param);\n    }\n    else\n    {\n        _3112 = _3106;\n    }\n    if (_3112)\n    {\n        int param_1 = li;\n        LightSample _4165 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _4165;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3136 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _4167 = _3136.color;\n    float _4169 = _3136.shadow;\n    if ((_3136.type == 0) && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3136.direction;\n        float _3150 = fa_shadow_factor(param_5, param_6);\n        _4169 = _3150;\n        _4167 *= _3150;\n    }\n    else\n    {\n        bool _3161 = _3136.type != 0;\n        bool _3167;\n        if (_3161)\n        {\n            _3167 = _3136.attenuation > 0.0f;\n        }\n        else\n        {\n            _3167 = _3161;\n        }\n        if (_3167)\n        {\n            int param_7 = li;\n            float3 param_8 = world_pos;\n            float3 param_9 = gn;\n            float3 param_10 = _3136.direction;\n            float _3179 = fa_shadow_local(param_7, param_8, param_9, param_10);\n            _4169 = _3179;\n            _4167 *= _3179;\n        }\n    }\n    LightSample _4184 = { _3136.direction, _4167, _3136.attenuation, _4169, _3136._distance, _3136.type };\n    return _4184;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2017_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _2963 = int(_2017_fa_shadow_cfg.x + 0.5f);\n    float _2973 = dot(world - _2017_fa_shadow_eye.xyz, _2017_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _2978 = _2963 > 0;\n    bool _2987;\n    if (_2978)\n    {\n        int param = _2963 - 1;\n        _2987 = _2973 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2987 = _2978;\n    }\n    if (_2987)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _2993 = _2963 > 1;\n        bool _3000;\n        if (_2993)\n        {\n            _3000 = _2973 > _2017_fa_shadow_split.x;\n        }\n        else\n        {\n            _3000 = _2993;\n        }\n        if (_3000)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3006 = _2963 > 2;\n        bool _3013;\n        if (_3006)\n        {\n            _3013 = _2973 > _2017_fa_shadow_split.y;\n        }\n        else\n        {\n            _3013 = _3006;\n        }\n        if (_3013)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3019 = _2963 > 3;\n        bool _3026;\n        if (_3019)\n        {\n            _3026 = _2973 > _2017_fa_shadow_split.z;\n        }\n        else\n        {\n            _3026 = _3019;\n        }\n        if (_3026)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _3983 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3983 = -_3983;\n    }\n    float3 _3567 = normalize(_320_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _3996 = { fa_world_pos, _3983, fa_world_tangent, fa_uv, fa_vertex_color, _3567, gl_FrontFacing };\n    SurfaceInput param_1 = _3996;\n    Surface _3575 = fa_standard_surface(param_1);\n    float3 _4022 = _3575.albedo;\n    float _4023 = _3575.alpha;\n    float3 _4024 = _3575.normal;\n    float _4025 = _3575.metallic;\n    float _4026 = _3575.roughness;\n    float _4027 = _3575.occlusion;\n    float3 _4028 = _3575.emission;\n    float _4029 = _3575.clearcoat;\n    float _4030 = _3575.clearcoat_roughness;\n    float3 _4031 = _3575.sheen_color;\n    float _4032 = _3575.sheen_roughness;\n    float _4033 = _3575.anisotropy;\n    float _4034 = _3575.anisotropy_rotation;\n    float _4035 = _3575.specular;\n    float _4036 = _3575.ior;\n    float3 _4037 = _3575.specular_color;\n    SurfaceInput _4004 = { fa_world_pos, _3983, fa_world_tangent, fa_uv, fa_vertex_color, _3567, gl_FrontFacing };\n    SurfaceInput param_2 = _4004;\n    Surface param_3 = _3575;\n    surface(param_2, param_3);\n    _4022 = param_3.albedo;\n    _4023 = param_3.alpha;\n    _4024 = param_3.normal;\n    _4025 = param_3.metallic;\n    _4026 = param_3.roughness;\n    _4027 = param_3.occlusion;\n    _4028 = param_3.emission;\n    _4029 = param_3.clearcoat;\n    _4030 = param_3.clearcoat_roughness;\n    _4031 = param_3.sheen_color;\n    _4032 = param_3.sheen_roughness;\n    _4033 = param_3.anisotropy;\n    _4034 = param_3.anisotropy_rotation;\n    _4035 = param_3.specular;\n    _4036 = param_3.ior;\n    _4037 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _3983;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4022 = param_6;\n    _4024 = param_7;\n    float3 result;\n    if (_320_fa_emissive.w > 0.5f)\n    {\n        result = _4022;\n    }\n    else\n    {\n        float3 _3613 = _4024;\n        float3 _3614 = normalize(_3613);\n        _4024 = _3614;\n        float3 param_8 = _3614;\n        SurfaceInput _4012 = { fa_world_pos, _3983, fa_world_tangent, fa_uv, fa_vertex_color, _3567, gl_FrontFacing };\n        SurfaceInput param_9 = _4012;\n        Surface _4103 = { _4022, _4023, _4024, _4025, _4026, _4027, _4028, _4029, _4030, _4031, _4032, _4033, _4034, _4035, _4036, _4037 };\n        Surface param_10 = _4103;\n        float3 param_11 = fa_indirect_diffuse(param_8);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _3633 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3633; ln++)\n        {\n            int param_12 = ln;\n            int _3646 = fa_cl_light(param_12);\n            bool _3649 = fa_lm.z > 0.5f;\n            bool _3655;\n            if (_3649)\n            {\n                int param_13 = _3646;\n                _3655 = fa_light_baked(param_13);\n            }\n            else\n            {\n                _3655 = _3649;\n            }\n            if (_3655)\n            {\n                continue;\n            }\n            int param_14 = _3646;\n            float3 param_15 = fa_world_pos;\n            float3 param_16 = _3983;\n            LightSample _3667 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput _4020 = { fa_world_pos, _3983, fa_world_tangent, fa_uv, fa_vertex_color, _3567, gl_FrontFacing };\n            SurfaceInput param_17 = _4020;\n            Surface _4120 = { _4022, _4023, _4024, _4025, _4026, _4027, _4028, _4029, _4030, _4031, _4032, _4033, _4034, _4035, _4036, _4037 };\n            Surface param_18 = _4120;\n            LightSample param_19 = _3667;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _3682 = result;\n    float3 _3683 = _3682 + _4028;\n    result = _3683;\n    float3 param_20 = _3683;\n    float3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _3692 = _320_fa_fog.w > 0.0f;\n    bool _3699;\n    if (!_3692)\n    {\n        _3699 = _320_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _3699 = _3692;\n    }\n    if (_3699)\n    {\n        float3 _3708 = fa_world_pos - _320_fa_camera_pos.xyz;\n        float _3714 = dot(_3708, _320_fa_fog_c.xyz);\n        bool _3718 = _320_fa_fog_c.w > 0.5f;\n        float _3719;\n        if (_3718)\n        {\n            _3719 = _3714;\n        }\n        else\n        {\n            _3719 = length(_3708);\n        }\n        float _3731 = _3719 - _320_fa_fog_b.x;\n        if (_3731 > 0.0f)\n        {\n            float _3740 = _320_fa_fog.w * _3731;\n            float tau = _3740 * _3740;\n            if (_320_fa_fog_b.y > 0.0f)\n            {\n                float _3756;\n                if (_3718)\n                {\n                    _3756 = fa_world_pos.y - (_320_fa_fog_c.y * _3714);\n                }\n                else\n                {\n                    _3756 = _320_fa_camera_pos.y;\n                }\n                float _3777 = lerp(_3756, fa_world_pos.y, clamp(_320_fa_fog_b.x / _3719, 0.0f, 1.0f));\n                float _3781 = fa_world_pos.y - _3777;\n                float _3786 = _3777 - _320_fa_fog_b.z;\n                float _3791 = fa_world_pos.y - _320_fa_fog_b.z;\n                bool _3794 = _3786 <= 0.0f;\n                bool _3795 = !_3794;\n                bool _3801;\n                if (_3795)\n                {\n                    _3801 = _320_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3801 = _3794;\n                }\n                float _3802;\n                if (_3801)\n                {\n                    _3802 = _320_fa_fog_b.y;\n                }\n                else\n                {\n                    _3802 = _320_fa_fog_b.y * exp(-min(_320_fa_fog_b.w * _3786, 80.0f));\n                }\n                bool _3829;\n                if (_3795)\n                {\n                    _3829 = _320_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3829 = _3794;\n                }\n                float _3830;\n                if (_3829)\n                {\n                    _3830 = _320_fa_fog_b.y * _3786;\n                }\n                else\n                {\n                    _3830 = (_320_fa_fog_b.y * (1.0f - exp(-min(_320_fa_fog_b.w * _3786, 80.0f)))) / _320_fa_fog_b.w;\n                }\n                bool _3855 = _3791 <= 0.0f;\n                bool _3862;\n                if (!_3855)\n                {\n                    _3862 = _320_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3862 = _3855;\n                }\n                float _3863;\n                if (_3862)\n                {\n                    _3863 = _320_fa_fog_b.y * _3791;\n                }\n                else\n                {\n                    _3863 = (_320_fa_fog_b.y * (1.0f - exp(-min(_320_fa_fog_b.w * _3791, 80.0f)))) / _320_fa_fog_b.w;\n                }\n                float _3890;\n                if (abs(_3781) < 0.001000000047497451305389404296875f)\n                {\n                    _3890 = _3802;\n                }\n                else\n                {\n                    _3890 = (_3863 - _3830) / _3781;\n                }\n                tau += (_3731 * max(_3890, 0.0f));\n            }\n            result = lerp(result, _320_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4023);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_320",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2017",
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
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
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
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _381 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _381;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _388 = _273.world_pos;\n    fa_world_pos = _388;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_388, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _320_fa_camera_pos : packoffset(c0);\n    float4 _320_fa_ambient : packoffset(c1);\n    float4 _320_fa_base_color : packoffset(c2);\n    float4 _320_fa_emissive : packoffset(c3);\n    float4 _320_fa_model_emissive : packoffset(c4);\n    float4 _320_fa_pbr : packoffset(c5);\n    float4 _320_fa_maps : packoffset(c6);\n    float4 _320_fa_fog : packoffset(c7);\n    float4 _320_fa_fog_b : packoffset(c8);\n    float4 _320_fa_fog_c : packoffset(c9);\n    float4 _320_fa_counts : packoffset(c10);\n    float4 _320_fa_env_sky : packoffset(c11);\n    float4 _320_fa_env_horizon : packoffset(c12);\n    float4 _320_fa_time : packoffset(c13);\n    float4 _320_fa_cl_vpx : packoffset(c14);\n    float4 _320_fa_cl_vpy : packoffset(c15);\n    float4 _320_fa_cl_vpw : packoffset(c16);\n    float4 _320_fa_cl_fwd : packoffset(c17);\n    float4 _320_fa_cl_grid : packoffset(c18);\n    float4 _320_fa_cl_info : packoffset(c19);\n    float4 _320_fa_layers_a : packoffset(c20);\n    float4 _320_fa_layers_b : packoffset(c21);\n    float4 _320_fa_layers_c : packoffset(c22);\n    float4 _320_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2017_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2017_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2017_fa_shadow_info[4] : packoffset(c20);\n    float4 _2017_fa_shadow_split : packoffset(c24);\n    float4 _2017_fa_shadow_cfg : packoffset(c25);\n    float4 _2017_fa_shadow_bias : packoffset(c26);\n    float4 _2017_fa_shadow_eye : packoffset(c27);\n    float4 _2017_fa_shadow_fwd : packoffset(c28);\n    float4 _2017_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_irr_tex : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1288 = _320_fa_cl_info.x < 0.0f;\n    bool _1295;\n    if (!_1288)\n    {\n        _1295 = _320_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1295 = _1288;\n    }\n    bool _1303;\n    if (!_1295)\n    {\n        _1303 = _320_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1303 = _1295;\n    }\n    bool _1310;\n    if (!_1303)\n    {\n        _1310 = _320_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1310 = _1303;\n    }\n    bool _1317;\n    if (!_1310)\n    {\n        _1317 = _320_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1317 = _1310;\n    }\n    if (_1317)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1327 = float4(world_pos, 1.0f);\n    float _1333 = dot(_320_fa_cl_vpw, _1327);\n    if (!(_1333 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1355 = float2(dot(_320_fa_cl_vpx, _1327), dot(_320_fa_cl_vpy, _1327)) / _1333.xx;\n    int _1359 = int(_320_fa_cl_grid.x);\n    int _1363 = int(_320_fa_cl_grid.y);\n    int param = (int(_320_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_320_fa_cl_fwd.xyz, world_pos) + _320_fa_cl_fwd.w, _320_fa_cl_grid.w) / _320_fa_cl_grid.w) * _320_fa_cl_grid.z)), 0, int(_320_fa_cl_info.y) - 1) * _1363) + clamp(int(floor(((_1355.y * 0.5f) + 0.5f) * _320_fa_cl_grid.y)), 0, _1363 - 1)) * _1359)) + clamp(int(floor(((_1355.x * 0.5f) + 0.5f) * _320_fa_cl_grid.x)), 0, _1359 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1439 = fa_cluster_texel(param);\n    return int2(int(_1439.x), int(_1439.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_320_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3079 = fa_cluster_lookup(param);\n    fa_cl_slot = _3079.x;\n    fa_cl_local = _3079.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _3233 = fa_linear_to_srgb(param);\n        c = _3233;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _3241 = fa_srgb_to_linear(param_1);\n            c = _3241;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _252;\n    if (i.front_facing)\n    {\n        _252 = i.world_normal;\n    }\n    else\n    {\n        _252 = -i.world_normal;\n    }\n    float3 _276 = normalize(i.world_tangent.xyz - (_252 * dot(_252, i.world_tangent.xyz)));\n    float3 _304 = normalize(((_276 * m.x) + ((cross(_252, _276) * i.world_tangent.w) * m.y)) + (_252 * m.z));\n    float3 _307;\n    if (i.front_facing)\n    {\n        _307 = _304;\n    }\n    else\n    {\n        _307 = -_304;\n    }\n    return _307;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _320_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3272 = fa_tex_fix(param_2, param_3);\n    float4 _4322 = base_t;\n    _4322.x = _3272.x;\n    _4322.y = _3272.y;\n    _4322.z = _3272.z;\n    base_t = _4322;\n    float4 _3286 = (_4322 * _320_fa_base_color) * i.vertex_color;\n    float3 _4187 = i.world_normal;\n    if (_320_fa_maps.z > 0.5f)\n    {\n        float param_4 = _320_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3318 = fa_tex_fix(param_6, param_7);\n        float3 _3321 = (_3318 * 2.0f) - 1.0f.xxx;\n        float2 _3326 = _3321.xy * _320_fa_maps.x;\n        float3 _4330 = _3321;\n        _4330.x = _3326.x;\n        _4330.y = _3326.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4330;\n        _4187 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _320_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3354 = fa_tex_fix(param_12, param_13);\n    float4 _4333 = mrt;\n    _4333.x = _3354.x;\n    _4333.y = _3354.y;\n    _4333.z = _3354.z;\n    mrt = _4333;\n    float4 _3382 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _320_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _3382.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3393 = fa_tex_fix(param_16, param_17);\n    float param_18 = _320_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3423 = fa_tex_fix(param_20, param_21);\n    float _4192 = _320_fa_layers_a.x;\n    float _4193 = _320_fa_layers_a.y;\n    float _4196 = _320_fa_layers_a.z;\n    float _4195 = _320_fa_layers_b.w;\n    float _4198 = _320_fa_layers_c.x;\n    if (_320_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_320_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _4192 *= _3393.y;\n            _4193 *= _3393.z;\n            _4195 *= _3382.w;\n        }\n        if (_320_fa_layers_c.z > 1.5f)\n        {\n            _4196 *= mrt.x;\n            _4198 *= mrt.w;\n        }\n    }\n    Surface _4217 = { _3286.xyz, _3286.w, _4187, clamp(_320_fa_pbr.x * _3354.z, 0.0f, 1.0f), clamp(_320_fa_pbr.y * _3354.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_320_fa_maps.y * (_3393.x - 1.0f)), _320_fa_emissive.xyz + (_320_fa_model_emissive.xyz * _3423), _4192, _4193, _320_fa_layers_b.xyz, _4195, _4196, _320_fa_layers_a.w, _4198, _320_fa_layers_c.y, _320_fa_layers_d.xyz };\n    return _4217;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1519 = rect.zw - rect.xy;\n    float2 _1523 = _1519 * atlas;\n    float2 _1527 = ddx * _1523;\n    float2 _1531 = ddy * _1523;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1519), clamp(0.5f * log2(max(max(dot(_1527, _1527), dot(_1531, _1531)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1564 = _320_fa_counts.y < 0.5f;\n    bool _1571;\n    if (!_1564)\n    {\n        _1571 = _320_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1571 = _1564;\n    }\n    if (_1571)\n    {\n        return;\n    }\n    float3 _1577 = ddx(world_pos);\n    float3 _1580 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1584 = fa_cluster_texel(param);\n    int _1588 = int(_1584.w);\n    if (_1588 < 1)\n    {\n        return;\n    }\n    int _1598 = int(_320_fa_counts.y + 0.5f);\n    int param_1 = _1598;\n    float4 _1602 = fa_light_texel(param_1);\n    float2 _1605 = _1602.yz;\n    int _1609 = int(_1602.w);\n    int param_2 = _1598 + 1;\n    float4 _1614 = fa_light_texel(param_2);\n    float _1615 = _1614.x;\n    int _1621 = int(_320_fa_counts.w + 0.5f) - 1;\n    int _1625 = int(_1584.z);\n    float3 _1890;\n    for (int k = 0; k < _1588; k++)\n    {\n        int _1638 = _1625 + k;\n        int param_3 = _1609 + (_1638 >> 2);\n        int _1655 = (_1598 + 2) + (int(fa_light_texel(param_3)[_1638 & 3]) * 7);\n        int param_4 = _1655 + 6;\n        float4 _1660 = fa_light_texel(param_4);\n        if (((int(_1660.w + 0.5f) >> _1621) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1655;\n        float4 _1675 = fa_light_texel(param_5);\n        int param_6 = _1655 + 1;\n        float4 _1680 = fa_light_texel(param_6);\n        int param_7 = _1655 + 2;\n        float4 _1685 = fa_light_texel(param_7);\n        float3 _1688 = _1675.xyz;\n        float _1693 = dot(_1688, world_pos) + _1675.w;\n        float3 _1695 = _1680.xyz;\n        float _1700 = dot(_1695, world_pos) + _1680.w;\n        float3 _1702 = _1685.xyz;\n        float _1707 = dot(_1702, world_pos) + _1685.w;\n        bool _1712 = abs(_1693) > 0.5f;\n        bool _1720;\n        if (!_1712)\n        {\n            _1720 = abs(_1700) > 0.5f;\n        }\n        else\n        {\n            _1720 = _1712;\n        }\n        bool _1728;\n        if (!_1720)\n        {\n            _1728 = abs(_1707) > 0.5f;\n        }\n        else\n        {\n            _1728 = _1720;\n        }\n        if (_1728)\n        {\n            continue;\n        }\n        float _1743 = clamp(dot(geo_normal, normalize(_1702)) * _1660.z, 0.0f, 1.0f);\n        if (_1743 <= 0.0f)\n        {\n            continue;\n        }\n        float _1763 = (clamp((0.5f - abs(_1707)) * 10.0f, 0.0f, 1.0f) * _1743) * _1660.x;\n        float2 _1771 = float2(_1693 + 0.5f, 0.5f - _1700);\n        float2 _1781 = float2(dot(_1688, _1577), dot(_1695, _1577));\n        float2 _1791 = float2(dot(_1688, _1580), dot(_1695, _1580));\n        int param_8 = _1655 + 5;\n        float4 _1796 = fa_light_texel(param_8);\n        int param_9 = _1655 + 3;\n        float4 _1801 = fa_light_texel(param_9);\n        int param_10 = _1655 + 4;\n        float4 _1806 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1796.xyz;\n        bool _1816 = _1801.z > _1801.x;\n        if (_1816)\n        {\n            float4 param_11 = _1801;\n            float2 param_12 = _1771;\n            float2 param_13 = _1605;\n            float2 param_14 = _1781;\n            float2 param_15 = _1791;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1615 > 0.5f) && (_1615 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1842 = fa_dc_to_linear(param_16);\n                float4 _4267 = tx;\n                _4267.x = _1842.x;\n                _4267.y = _1842.y;\n                _4267.z = _1842.z;\n                tx = _4267;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1763 * tex_a) * _1796.w, 0.0f, 1.0f).xxx);\n        if (_1806.z > _1806.x)\n        {\n            float4 param_17 = _1806;\n            float2 param_18 = _1771;\n            float2 param_19 = _1605;\n            float2 param_20 = _1781;\n            float2 param_21 = _1791;\n            float4 _1886 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1615 > 1.5f)\n            {\n                float3 param_22 = _1886.xyz;\n                float3 _1896 = fa_dc_to_srgb(param_22);\n                _1890 = _1896;\n            }\n            else\n            {\n                _1890 = _1886.xyz;\n            }\n            float3 _1905 = (_1890 * 2.0f) - 1.0f.xxx;\n            float2 _1910 = _1905.xy * _1660.y;\n            float3 _1932 = (normalize(_1688) * _1910.x) + (normalize(_1695) * _1910.y);\n            float3 _1935 = normalize(normal);\n            normal = normalize(lerp(_1935, normalize((_1935 * max(_1905.z, 0.0500000007450580596923828125f)) + (_1932 - (_1935 * dot(_1935, _1932)))), clamp(_1763 * (_1816 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_320_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _320_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    return float3(0.0f, ambientColor.y, 0.0f);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_320_fa_cl_info.x) + int(_320_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_320_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _382_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _382_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _548 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _561 = (c - (ru * hx)) - p;\n        float3 _567 = ru * (2.0f * hx);\n        float _573 = max(dot(_567, _567), 9.9999999392252902907785028219223e-09f);\n        float _577 = dot(_561, _567);\n        float t = clamp((-_577) / _573, 0.0f, 1.0f);\n        if (_548)\n        {\n            float _592 = dot(r, _567);\n            float _598 = _573 - (_592 * _592);\n            if (abs(_598) > (9.9999997473787516355514526367188e-06f * _573))\n            {\n                t = clamp(((dot(r, _561) * _592) - _577) / _598, 0.0f, 1.0f);\n            }\n        }\n        return (p + _561) + (_567 * t);\n    }\n    float3 q = p;\n    float _630 = dot(r, axis);\n    bool _638;\n    if (_548)\n    {\n        _638 = abs(_630) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _638 = _548;\n    }\n    if (_638)\n    {\n        float _648 = dot(c - p, axis) / _630;\n        if (_648 > 0.0f)\n        {\n            q = p + (r * _648);\n        }\n    }\n    float3 _661 = q - c;\n    float2 xy = float2(dot(_661, ru), dot(_661, uu));\n    if (shape > 0.5f)\n    {\n        float _676 = length(xy);\n        if (_676 > hx)\n        {\n            xy *= (hx / _676);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _469 = abs(d);\n    float _471 = _469.x;\n    float _473 = _469.y;\n    bool _474 = _471 >= _473;\n    bool _482;\n    if (_474)\n    {\n        _482 = _471 >= _469.z;\n    }\n    else\n    {\n        _482 = _474;\n    }\n    int _483;\n    if (_482)\n    {\n        _483 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _496;\n        if (_473 >= _469.z)\n        {\n            _496 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _496 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _483 = _496;\n    }\n    return _483;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _422 = dot(d, right);\n    float _426 = dot(d, up);\n    float _437;\n    if (((_422 * _422) + (_426 * _426)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _437 = atan2(_426, _422) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _437 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_437 - floor(_437)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _714 = fa_light_base(param);\n    bool _718 = _320_fa_ambient.w > 4.5f;\n    int param_1 = _714;\n    float4 _722 = fa_light_texel(param_1);\n    int param_2 = _714 + 1;\n    float4 _727 = fa_light_texel(param_2);\n    float _730 = _727.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _742 = _718 && (_730 > 2.5f);\n    fa_light_is_area = _742;\n    bool _744 = _730 < 0.5f;\n    float3 l;\n    if (_744)\n    {\n        l = normalize(_722.xyz);\n        if (_718)\n        {\n            int param_3 = _714 + 6;\n            float4 _758 = fa_light_texel(param_3);\n            if (_758.z > 0.5f)\n            {\n                int param_4 = _714 + 4;\n                float4 _768 = fa_light_texel(param_4);\n                int param_5 = _714 + 5;\n                float4 _773 = fa_light_texel(param_5);\n                float2 param_6 = _758.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _768.xyz) * _768.w, (-dot(world_pos, _773.xyz)) * _773.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _803 = _722.xyz;\n        float3 _805 = _803 - world_pos;\n        float3 to_light = _805;\n        float _808 = length(_805);\n        float reach = _808;\n        bool front = true;\n        if (_742)\n        {\n            int param_8 = _714 + 7;\n            reach = max(_808 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _714 + 4;\n            float4 _832 = fa_light_texel(param_9);\n            int param_10 = _714 + 5;\n            float4 _837 = fa_light_texel(param_10);\n            int param_11 = _714 + 6;\n            float4 _842 = fa_light_texel(param_11);\n            float _843 = _842.w;\n            int param_12 = _714 + 2;\n            float3 _850 = normalize(fa_light_texel(param_12).xyz);\n            bool _852 = _843 > 1.5f;\n            bool _860;\n            if (!_852)\n            {\n                _860 = dot(_850, to_light) < 0.0f;\n            }\n            else\n            {\n                _860 = _852;\n            }\n            front = _860;\n            float3 r = 0.0f.xxx;\n            if (dot(n, n) > 0.5f)\n            {\n                r = reflect(-normalize(_320_fa_camera_pos.xyz - world_pos), normalize(n));\n            }\n            float3 param_13 = _803;\n            float3 param_14 = _850;\n            float3 param_15 = _832.xyz;\n            float3 param_16 = _837.xyz;\n            float param_17 = _832.w;\n            float param_18 = _837.w;\n            float param_19 = _843;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _907 = length(to_light);\n        dist = _907;\n        l = to_light / max(_907, 9.9999997473787516355514526367188e-05f).xxx;\n        float _921 = reach / max(_722.w, 0.001000000047497451305389404296875f);\n        float _927 = clamp(1.0f - (_921 * _921), 0.0f, 1.0f);\n        float _929;\n        if (front)\n        {\n            _929 = _927 * _927;\n        }\n        else\n        {\n            _929 = 0.0f;\n        }\n        atten = _929;\n        bool _940 = _730 < 2.5f;\n        if ((_730 > 1.5f) && _940)\n        {\n            int param_22 = _714 + 2;\n            float4 _948 = fa_light_texel(param_22);\n            float _958 = _948.w;\n            int param_23 = _714 + 3;\n            float4 _963 = fa_light_texel(param_23);\n            float _964 = _963.x;\n            float cos_inner = _964;\n            if (_964 > 1.5f)\n            {\n                cos_inner = lerp(_958, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_958, cos_inner, dot(-l, normalize(_948.xyz)));\n        }\n        if (_718 && (_730 < 1.5f))\n        {\n            int param_24 = _714 + 6;\n            float4 _988 = fa_light_texel(param_24);\n            if (_988.z > 0.5f)\n            {\n                float3 _996 = -to_light;\n                int param_25 = _714 + 4;\n                int param_26 = _714 + 5;\n                float3 _1010 = fa_light_texel(param_25).xyz;\n                float3 _1014 = fa_light_texel(param_26).xyz;\n                float3 _1023 = float3(dot(_996, _1010), dot(_996, _1014), dot(_996, cross(_1010, _1014)));\n                float3 param_27 = _1023;\n                int _1027 = fa_cube_face(param_27);\n                int param_28 = _1027;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1054 = float2(dot(_1023, cross(param_29, param_30)), dot(_1023, param_30)) / max(dot(_1023, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1058 = _1027 / 3;\n                float2 param_31 = _988.xy + (float2(float(_1027 - (_1058 * 3)), float(_1058)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1054.x), 0.5f - (0.5f * _1054.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _714 + 7;\n            float4 _1088 = fa_light_texel(param_33);\n            if (_1088.z > 0.5f)\n            {\n                int param_34 = _714 + 2;\n                int param_35 = _714 + 4;\n                int param_36 = _714 + 5;\n                float2 param_37 = _1088.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_718 && _940)\n            {\n                int param_42 = _714 + 6;\n                float4 _1135 = fa_light_texel(param_42);\n                int param_43 = _714 + 7;\n                float4 _1140 = fa_light_texel(param_43);\n                bool _1143 = _1135.z > 0.5f;\n                bool _1150;\n                if (!_1143)\n                {\n                    _1150 = _1140.z > 0.5f;\n                }\n                else\n                {\n                    _1150 = _1143;\n                }\n                if (_1150)\n                {\n                    int param_44 = _714 + 2;\n                    float4 _1157 = fa_light_texel(param_44);\n                    float3 _1161 = normalize(_1157.xyz);\n                    int param_45 = _714 + 4;\n                    float4 _1166 = fa_light_texel(param_45);\n                    int param_46 = _714 + 5;\n                    float4 _1171 = fa_light_texel(param_46);\n                    if (_1143)\n                    {\n                        float3 _1179 = -to_light;\n                        float _1186 = _1157.w;\n                        float _1202 = 0.5f / max(dot(_1179, _1161) * (sqrt(max(1.0f - (_1186 * _1186), 0.0f)) / max(_1186, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1135.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1179, _1166.xyz) * _1202), 0.5f - (dot(_1179, _1171.xyz) * _1202));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1140.z > 0.5f)\n                    {\n                        float2 param_49 = _1140.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1161;\n                        float3 param_52 = _1166.xyz;\n                        float3 param_53 = _1171.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4141 = _727.xyz * atten;\n    if (_718)\n    {\n        _4141 *= fa_light_tint;\n    }\n    int _1270;\n    if (_744)\n    {\n        _1270 = 0;\n    }\n    else\n    {\n        _1270 = ((_730 > 1.5f) && (_730 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _4152 = { l, _4141, atten, 1.0f, dist, _1270 };\n    return _4152;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2007;\n    if (i == 0)\n    {\n        _2007 = _2017_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2023;\n        if (i == 1)\n        {\n            _2023 = _2017_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2031;\n            if (i == 2)\n            {\n                _2031 = _2017_fa_shadow_split.z;\n            }\n            else\n            {\n                _2031 = _2017_fa_shadow_split.w;\n            }\n            _2023 = _2031;\n        }\n        _2007 = _2023;\n    }\n    return _2007;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2064 = fa_shadow_depth(param, param_1);\n    float _2068;\n    if (conv.x < 0.5f)\n    {\n        _2068 = _2064;\n    }\n    else\n    {\n        _2068 = (conv.y * conv.z) / (conv.z - (_2064 * (conv.z - conv.y)));\n    }\n    return _2068;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1995 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_1995), sin(_1995)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2114 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2123;\n        if (k < 0.0f)\n        {\n            _2123 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2123 = k;\n        }\n        float _2143 = clamp((_2123 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2114;\n            float2 _2162 = fa_shadow_vogel(param_3, param_4, param_5) * _2143;\n            float2 param_6 = uv + (_2162 * _2017_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2174 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2174 < (zr - (length(_2162) * plane)))\n            {\n                sum += _2174;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2200 = sum / cnt;\n        float _2210;\n        if (k < 0.0f)\n        {\n            _2210 = (-k) / max(_2200, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2210 = k;\n        }\n        radius = clamp(((max(zr - _2200, 0.0f) * unit) * _2210) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2232 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2232; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2232;\n        float param_11 = _2114;\n        float2 _2251 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2251 * _2017_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2251) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2232);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2293 = max(_2017_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2298 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2304 = sqrt(1.0f - (_2298 * _2298));\n    float _2311 = min(_2304 / max(_2298, 0.20000000298023223876953125f), 4.0f);\n    float _2316;\n    if (_2017_fa_shadow_bias.y > 0.0f)\n    {\n        _2316 = _2017_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2316 = 1.5f * _2017_fa_shadow_info[ci].x;\n    }\n    float4 _2341 = mul(float4(world + (n * (_2316 * _2304)), 1.0f), _2017_fa_shadow_mat[ci]);\n    float _2348 = _2341.x;\n    bool _2351 = _2348 < _2017_fa_shadow_rect[ci].x;\n    bool _2360;\n    if (!_2351)\n    {\n        _2360 = _2348 > _2017_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2360 = _2351;\n    }\n    bool _2369;\n    if (!_2360)\n    {\n        _2369 = _2341.y < _2017_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2369 = _2360;\n    }\n    bool _2378;\n    if (!_2369)\n    {\n        _2378 = _2341.y > _2017_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2378 = _2369;\n    }\n    bool _2385;\n    if (!_2378)\n    {\n        _2385 = _2341.z > 1.0f;\n    }\n    else\n    {\n        _2385 = _2378;\n    }\n    if (_2385)\n    {\n        return -1.0f;\n    }\n    float _2393;\n    if (_2017_fa_shadow_bias.x > 0.0f)\n    {\n        _2393 = _2017_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2393 = 1.5f * _2017_fa_shadow_info[ci].x;\n    }\n    float2 param = _2341.xy;\n    float4 param_1 = _2017_fa_shadow_rect[ci];\n    float param_2 = _2341.z - ((_2393 * (1.0f + (0.5f * _2311))) / _2293);\n    float param_3 = _2017_fa_shadow_info[ci].x;\n    float param_4 = _2293;\n    float param_5 = _2293 * 0.25f;\n    float param_6 = ((_2017_fa_shadow_info[ci].x * min(_2311, 3.0f)) * 0.5f) / _2293;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2017_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2017_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_320_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2781 = int(_2017_fa_shadow_cfg.x + 0.5f);\n    if (_2781 < 1)\n    {\n        return 1.0f;\n    }\n    float _2796 = dot(world - _2017_fa_shadow_eye.xyz, _2017_fa_shadow_fwd.xyz);\n    int param = _2781 - 1;\n    if (_2796 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2808 = _2781 > 1;\n    bool _2815;\n    if (_2808)\n    {\n        _2815 = _2796 > _2017_fa_shadow_split.x;\n    }\n    else\n    {\n        _2815 = _2808;\n    }\n    if (_2815)\n    {\n        ci = 1;\n    }\n    bool _2819 = _2781 > 2;\n    bool _2826;\n    if (_2819)\n    {\n        _2826 = _2796 > _2017_fa_shadow_split.y;\n    }\n    else\n    {\n        _2826 = _2819;\n    }\n    if (_2826)\n    {\n        ci = 2;\n    }\n    bool _2830 = _2781 > 3;\n    bool _2837;\n    if (_2830)\n    {\n        _2837 = _2796 > _2017_fa_shadow_split.z;\n    }\n    else\n    {\n        _2837 = _2830;\n    }\n    if (_2837)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2781)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2863 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2863;\n        if (_2863 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2017_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2888;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2888 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2888 = _2017_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2907 = _2017_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2888, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2918 = clamp((_2796 - (fa_shadow_split_at(param_7) - _2907)) / _2907, 0.0f, 1.0f);\n        if (_2918 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2781)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2939 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2939;\n                if (_2939 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2918);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _2451 = _320_fa_pbr.z < 0.5f;\n    bool _2458;\n    if (!_2451)\n    {\n        _2458 = _2017_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2458 = _2451;\n    }\n    if (_2458)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2017_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2471 = fa_light_texel(param);\n    float _2472 = _2471.x;\n    if (_2472 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2481 = int(_2472 + 0.5f);\n    int param_1 = _2481;\n    float4 _2485 = fa_light_texel(param_1);\n    int param_2 = _2481 + 1;\n    float4 _2490 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2493 = _2485.y;\n    if (_2493 > 0.0f)\n    {\n        float _2510 = 1.0f - smoothstep(0.75f * _2493, _2493, length(world - _2017_fa_shadow_eye.xyz));\n        fade = _2510;\n        if (_2510 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2485.x > 1.5f)\n    {\n        int param_3 = li;\n        int param_4 = fa_light_base(param_3);\n        float3 param_5 = world - fa_light_texel(param_4).xyz;\n        face = fa_cube_face(param_5);\n    }\n    int _2539 = (_2481 + 2) + (face * 6);\n    int param_6 = _2539;\n    int param_7 = _2539 + 1;\n    int param_8 = _2539 + 3;\n    float4 _2553 = fa_light_texel(param_8);\n    int param_9 = _2539 + 4;\n    float4 _2558 = fa_light_texel(param_9);\n    int param_10 = _2539 + 5;\n    float4 _2563 = fa_light_texel(param_10);\n    float _2575 = _2563.x * max(dot(_2553, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2580 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2603 = clamp(dot(n, _2553.xyz), -1.0f, 1.0f);\n    int param_11 = li;\n    int param_12 = fa_light_base(param_11);\n    float _2627 = min(sqrt(1.0f - (_2603 * _2603)) / max(abs(dot(n, world - fa_light_texel(param_12).xyz)) / max(dot(_2553, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2630 = _2490.y;\n    float _2632;\n    if (_2630 > 0.0f)\n    {\n        _2632 = _2630;\n    }\n    else\n    {\n        _2632 = 1.5f * _2575;\n    }\n    float4 _2652 = float4(world + (n * (_2632 * sqrt(1.0f - (_2580 * _2580)))), 1.0f);\n    float _2656 = dot(_2553, _2652);\n    float _2659 = _2563.y;\n    if (_2656 < _2659)\n    {\n        return 1.0f;\n    }\n    float2 _2674 = float2(dot(fa_light_texel(param_6), _2652), dot(fa_light_texel(param_7), _2652)) / _2656.xx;\n    float _2676 = _2674.x;\n    bool _2679 = _2676 < _2558.x;\n    bool _2688;\n    if (!_2679)\n    {\n        _2688 = _2676 > _2558.z;\n    }\n    else\n    {\n        _2688 = _2679;\n    }\n    bool _2697;\n    if (!_2688)\n    {\n        _2697 = _2674.y < _2558.y;\n    }\n    else\n    {\n        _2697 = _2688;\n    }\n    bool _2706;\n    if (!_2697)\n    {\n        _2706 = _2674.y > _2558.w;\n    }\n    else\n    {\n        _2706 = _2697;\n    }\n    if (_2706)\n    {\n        return 1.0f;\n    }\n    float _2712 = _2490.x;\n    float _2714;\n    if (_2712 > 0.0f)\n    {\n        _2714 = _2712;\n    }\n    else\n    {\n        _2714 = 1.5f * _2575;\n    }\n    float2 param_13 = _2674;\n    float4 param_14 = _2558;\n    float param_15 = _2656 - (_2714 * (1.0f + (0.5f * _2627)));\n    float param_16 = _2575;\n    float param_17 = 1.0f;\n    float param_18 = _2563.z * 0.25f;\n    float param_19 = (_2575 * min(_2627, 3.0f)) * 0.5f;\n    float3 param_20 = float3(1.0f, _2659, _2563.z);\n    int param_21 = int(_2485.z + 0.5f);\n    float param_22 = _2485.w;\n    return lerp(1.0f, fa_shadow_filter(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _3106 = fa_lm.z > 0.5f;\n    bool _3112;\n    if (_3106)\n    {\n        int param = li;\n        _3112 = fa_light_baked(param);\n    }\n    else\n    {\n        _3112 = _3106;\n    }\n    if (_3112)\n    {\n        int param_1 = li;\n        LightSample _4165 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _4165;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3136 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _4167 = _3136.color;\n    float _4169 = _3136.shadow;\n    if ((_3136.type == 0) && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3136.direction;\n        float _3150 = fa_shadow_factor(param_5, param_6);\n        _4169 = _3150;\n        _4167 *= _3150;\n    }\n    else\n    {\n        bool _3161 = _3136.type != 0;\n        bool _3167;\n        if (_3161)\n        {\n            _3167 = _3136.attenuation > 0.0f;\n        }\n        else\n        {\n            _3167 = _3161;\n        }\n        if (_3167)\n        {\n            int param_7 = li;\n            float3 param_8 = world_pos;\n            float3 param_9 = gn;\n            float3 param_10 = _3136.direction;\n            float _3179 = fa_shadow_local(param_7, param_8, param_9, param_10);\n            _4169 = _3179;\n            _4167 *= _3179;\n        }\n    }\n    LightSample _4184 = { _3136.direction, _4167, _3136.attenuation, _4169, _3136._distance, _3136.type };\n    return _4184;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2017_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _2963 = int(_2017_fa_shadow_cfg.x + 0.5f);\n    float _2973 = dot(world - _2017_fa_shadow_eye.xyz, _2017_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _2978 = _2963 > 0;\n    bool _2987;\n    if (_2978)\n    {\n        int param = _2963 - 1;\n        _2987 = _2973 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2987 = _2978;\n    }\n    if (_2987)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _2993 = _2963 > 1;\n        bool _3000;\n        if (_2993)\n        {\n            _3000 = _2973 > _2017_fa_shadow_split.x;\n        }\n        else\n        {\n            _3000 = _2993;\n        }\n        if (_3000)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3006 = _2963 > 2;\n        bool _3013;\n        if (_3006)\n        {\n            _3013 = _2973 > _2017_fa_shadow_split.y;\n        }\n        else\n        {\n            _3013 = _3006;\n        }\n        if (_3013)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3019 = _2963 > 3;\n        bool _3026;\n        if (_3019)\n        {\n            _3026 = _2973 > _2017_fa_shadow_split.z;\n        }\n        else\n        {\n            _3026 = _3019;\n        }\n        if (_3026)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _3983 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3983 = -_3983;\n    }\n    float3 _3567 = normalize(_320_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _3996 = { fa_world_pos, _3983, fa_world_tangent, fa_uv, fa_vertex_color, _3567, gl_FrontFacing };\n    SurfaceInput param_1 = _3996;\n    Surface _3575 = fa_standard_surface(param_1);\n    float3 _4022 = _3575.albedo;\n    float _4023 = _3575.alpha;\n    float3 _4024 = _3575.normal;\n    float _4025 = _3575.metallic;\n    float _4026 = _3575.roughness;\n    float _4027 = _3575.occlusion;\n    float3 _4028 = _3575.emission;\n    float _4029 = _3575.clearcoat;\n    float _4030 = _3575.clearcoat_roughness;\n    float3 _4031 = _3575.sheen_color;\n    float _4032 = _3575.sheen_roughness;\n    float _4033 = _3575.anisotropy;\n    float _4034 = _3575.anisotropy_rotation;\n    float _4035 = _3575.specular;\n    float _4036 = _3575.ior;\n    float3 _4037 = _3575.specular_color;\n    SurfaceInput _4004 = { fa_world_pos, _3983, fa_world_tangent, fa_uv, fa_vertex_color, _3567, gl_FrontFacing };\n    SurfaceInput param_2 = _4004;\n    Surface param_3 = _3575;\n    surface(param_2, param_3);\n    _4022 = param_3.albedo;\n    _4023 = param_3.alpha;\n    _4024 = param_3.normal;\n    _4025 = param_3.metallic;\n    _4026 = param_3.roughness;\n    _4027 = param_3.occlusion;\n    _4028 = param_3.emission;\n    _4029 = param_3.clearcoat;\n    _4030 = param_3.clearcoat_roughness;\n    _4031 = param_3.sheen_color;\n    _4032 = param_3.sheen_roughness;\n    _4033 = param_3.anisotropy;\n    _4034 = param_3.anisotropy_rotation;\n    _4035 = param_3.specular;\n    _4036 = param_3.ior;\n    _4037 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _3983;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4022 = param_6;\n    _4024 = param_7;\n    float3 result;\n    if (_320_fa_emissive.w > 0.5f)\n    {\n        result = _4022;\n    }\n    else\n    {\n        float3 _3613 = _4024;\n        float3 _3614 = normalize(_3613);\n        _4024 = _3614;\n        float3 param_8 = _3614;\n        SurfaceInput _4012 = { fa_world_pos, _3983, fa_world_tangent, fa_uv, fa_vertex_color, _3567, gl_FrontFacing };\n        SurfaceInput param_9 = _4012;\n        Surface _4103 = { _4022, _4023, _4024, _4025, _4026, _4027, _4028, _4029, _4030, _4031, _4032, _4033, _4034, _4035, _4036, _4037 };\n        Surface param_10 = _4103;\n        float3 param_11 = fa_indirect_diffuse(param_8);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _3633 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3633; ln++)\n        {\n            int param_12 = ln;\n            int _3646 = fa_cl_light(param_12);\n            bool _3649 = fa_lm.z > 0.5f;\n            bool _3655;\n            if (_3649)\n            {\n                int param_13 = _3646;\n                _3655 = fa_light_baked(param_13);\n            }\n            else\n            {\n                _3655 = _3649;\n            }\n            if (_3655)\n            {\n                continue;\n            }\n            int param_14 = _3646;\n            float3 param_15 = fa_world_pos;\n            float3 param_16 = _3983;\n            LightSample _3667 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput _4020 = { fa_world_pos, _3983, fa_world_tangent, fa_uv, fa_vertex_color, _3567, gl_FrontFacing };\n            SurfaceInput param_17 = _4020;\n            Surface _4120 = { _4022, _4023, _4024, _4025, _4026, _4027, _4028, _4029, _4030, _4031, _4032, _4033, _4034, _4035, _4036, _4037 };\n            Surface param_18 = _4120;\n            LightSample param_19 = _3667;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _3682 = result;\n    float3 _3683 = _3682 + _4028;\n    result = _3683;\n    float3 param_20 = _3683;\n    float3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _3692 = _320_fa_fog.w > 0.0f;\n    bool _3699;\n    if (!_3692)\n    {\n        _3699 = _320_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _3699 = _3692;\n    }\n    if (_3699)\n    {\n        float3 _3708 = fa_world_pos - _320_fa_camera_pos.xyz;\n        float _3714 = dot(_3708, _320_fa_fog_c.xyz);\n        bool _3718 = _320_fa_fog_c.w > 0.5f;\n        float _3719;\n        if (_3718)\n        {\n            _3719 = _3714;\n        }\n        else\n        {\n            _3719 = length(_3708);\n        }\n        float _3731 = _3719 - _320_fa_fog_b.x;\n        if (_3731 > 0.0f)\n        {\n            float _3740 = _320_fa_fog.w * _3731;\n            float tau = _3740 * _3740;\n            if (_320_fa_fog_b.y > 0.0f)\n            {\n                float _3756;\n                if (_3718)\n                {\n                    _3756 = fa_world_pos.y - (_320_fa_fog_c.y * _3714);\n                }\n                else\n                {\n                    _3756 = _320_fa_camera_pos.y;\n                }\n                float _3777 = lerp(_3756, fa_world_pos.y, clamp(_320_fa_fog_b.x / _3719, 0.0f, 1.0f));\n                float _3781 = fa_world_pos.y - _3777;\n                float _3786 = _3777 - _320_fa_fog_b.z;\n                float _3791 = fa_world_pos.y - _320_fa_fog_b.z;\n                bool _3794 = _3786 <= 0.0f;\n                bool _3795 = !_3794;\n                bool _3801;\n                if (_3795)\n                {\n                    _3801 = _320_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3801 = _3794;\n                }\n                float _3802;\n                if (_3801)\n                {\n                    _3802 = _320_fa_fog_b.y;\n                }\n                else\n                {\n                    _3802 = _320_fa_fog_b.y * exp(-min(_320_fa_fog_b.w * _3786, 80.0f));\n                }\n                bool _3829;\n                if (_3795)\n                {\n                    _3829 = _320_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3829 = _3794;\n                }\n                float _3830;\n                if (_3829)\n                {\n                    _3830 = _320_fa_fog_b.y * _3786;\n                }\n                else\n                {\n                    _3830 = (_320_fa_fog_b.y * (1.0f - exp(-min(_320_fa_fog_b.w * _3786, 80.0f)))) / _320_fa_fog_b.w;\n                }\n                bool _3855 = _3791 <= 0.0f;\n                bool _3862;\n                if (!_3855)\n                {\n                    _3862 = _320_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3862 = _3855;\n                }\n                float _3863;\n                if (_3862)\n                {\n                    _3863 = _320_fa_fog_b.y * _3791;\n                }\n                else\n                {\n                    _3863 = (_320_fa_fog_b.y * (1.0f - exp(-min(_320_fa_fog_b.w * _3791, 80.0f)))) / _320_fa_fog_b.w;\n                }\n                float _3890;\n                if (abs(_3781) < 0.001000000047497451305389404296875f)\n                {\n                    _3890 = _3802;\n                }\n                else\n                {\n                    _3890 = (_3863 - _3830) / _3781;\n                }\n                tau += (_3731 * max(_3890, 0.0f));\n            }\n            result = lerp(result, _320_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4023);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_320",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2017",
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
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
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
          }
        ]
      }
    },
    "prepass": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _292 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _292;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _299 = _160.world_pos;\n    float4 _171 = float4(_299, 1.0f);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -mul(_171, _131_fa_light_vp).z;\n    fa_pre_r0 = float3(_131_fa_light_vp[0].x, _131_fa_light_vp[1].x, _131_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131_fa_light_vp[0].y, _131_fa_light_vp[1].y, _131_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131_fa_light_vp[0].z, _131_fa_light_vp[1].z, _131_fa_light_vp[2].z);\n    gl_Position = mul(_171, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _785 = base_t;\n    _785.x = _225.x;\n    _785.y = _225.y;\n    _785.z = _225.z;\n    base_t = _785;\n    float4 _241 = (_785 * _213_fa_base_color) * i.vertex_color;\n    float3 _748 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _793 = _279;\n        _793.x = _284.x;\n        _793.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _793;\n        _748 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _796 = mrt;\n    _796.x = _313.x;\n    _796.y = _313.y;\n    _796.z = _313.z;\n    mrt = _796;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _753 = _213_fa_layers_a.x;\n    float _754 = _213_fa_layers_a.y;\n    float _757 = _213_fa_layers_a.z;\n    float _756 = _213_fa_layers_b.w;\n    float _759 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _753 *= _355.y;\n            _754 *= _355.z;\n            _756 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _757 *= mrt.x;\n            _759 *= mrt.w;\n        }\n    }\n    Surface _778 = { _241.xyz, _241.w, _748, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _753, _754, _213_fa_layers_b.xyz, _756, _757, _213_fa_layers_a.w, _759, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _778;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _659 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _659 = -_659;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _672 = { fa_world_pos, _659, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _672;\n    SurfaceInput _680 = { fa_world_pos, _659, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _680;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _785 = base_t;\n    _785.x = _225.x;\n    _785.y = _225.y;\n    _785.z = _225.z;\n    base_t = _785;\n    float4 _241 = (_785 * _213_fa_base_color) * i.vertex_color;\n    float3 _748 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _793 = _279;\n        _793.x = _284.x;\n        _793.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _793;\n        _748 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _796 = mrt;\n    _796.x = _313.x;\n    _796.y = _313.y;\n    _796.z = _313.z;\n    mrt = _796;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _753 = _213_fa_layers_a.x;\n    float _754 = _213_fa_layers_a.y;\n    float _757 = _213_fa_layers_a.z;\n    float _756 = _213_fa_layers_b.w;\n    float _759 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _753 *= _355.y;\n            _754 *= _355.z;\n            _756 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _757 *= mrt.x;\n            _759 *= mrt.w;\n        }\n    }\n    Surface _778 = { _241.xyz, _241.w, _748, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _753, _754, _213_fa_layers_b.xyz, _756, _757, _213_fa_layers_a.w, _759, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _778;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _659 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _659 = -_659;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _672 = { fa_world_pos, _659, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _672;\n    SurfaceInput _680 = { fa_world_pos, _659, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _680;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
