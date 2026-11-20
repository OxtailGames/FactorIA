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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _314_fa_camera_pos : packoffset(c0);\n    float4 _314_fa_ambient : packoffset(c1);\n    float4 _314_fa_base_color : packoffset(c2);\n    float4 _314_fa_emissive : packoffset(c3);\n    float4 _314_fa_model_emissive : packoffset(c4);\n    float4 _314_fa_pbr : packoffset(c5);\n    float4 _314_fa_maps : packoffset(c6);\n    float4 _314_fa_fog : packoffset(c7);\n    float4 _314_fa_fog_b : packoffset(c8);\n    float4 _314_fa_fog_c : packoffset(c9);\n    float4 _314_fa_counts : packoffset(c10);\n    float4 _314_fa_env_sky : packoffset(c11);\n    float4 _314_fa_env_horizon : packoffset(c12);\n    float4 _314_fa_time : packoffset(c13);\n    float4 _314_fa_cl_vpx : packoffset(c14);\n    float4 _314_fa_cl_vpy : packoffset(c15);\n    float4 _314_fa_cl_vpw : packoffset(c16);\n    float4 _314_fa_cl_fwd : packoffset(c17);\n    float4 _314_fa_cl_grid : packoffset(c18);\n    float4 _314_fa_cl_info : packoffset(c19);\n    float4 _314_fa_layers_a : packoffset(c20);\n    float4 _314_fa_layers_b : packoffset(c21);\n    float4 _314_fa_layers_c : packoffset(c22);\n    float4 _314_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2011_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2011_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2011_fa_shadow_info[4] : packoffset(c20);\n    float4 _2011_fa_shadow_split : packoffset(c24);\n    float4 _2011_fa_shadow_cfg : packoffset(c25);\n    float4 _2011_fa_shadow_bias : packoffset(c26);\n    float4 _2011_fa_shadow_eye : packoffset(c27);\n    float4 _2011_fa_shadow_fwd : packoffset(c28);\n    float4 _2011_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_irr_tex : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1282 = _314_fa_cl_info.x < 0.0f;\n    bool _1289;\n    if (!_1282)\n    {\n        _1289 = _314_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1289 = _1282;\n    }\n    bool _1297;\n    if (!_1289)\n    {\n        _1297 = _314_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1297 = _1289;\n    }\n    bool _1304;\n    if (!_1297)\n    {\n        _1304 = _314_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1304 = _1297;\n    }\n    bool _1311;\n    if (!_1304)\n    {\n        _1311 = _314_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1311 = _1304;\n    }\n    if (_1311)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1321 = float4(world_pos, 1.0f);\n    float _1327 = dot(_314_fa_cl_vpw, _1321);\n    if (!(_1327 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1349 = float2(dot(_314_fa_cl_vpx, _1321), dot(_314_fa_cl_vpy, _1321)) / _1327.xx;\n    int _1353 = int(_314_fa_cl_grid.x);\n    int _1357 = int(_314_fa_cl_grid.y);\n    int param = (int(_314_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_314_fa_cl_fwd.xyz, world_pos) + _314_fa_cl_fwd.w, _314_fa_cl_grid.w) / _314_fa_cl_grid.w) * _314_fa_cl_grid.z)), 0, int(_314_fa_cl_info.y) - 1) * _1357) + clamp(int(floor(((_1349.y * 0.5f) + 0.5f) * _314_fa_cl_grid.y)), 0, _1357 - 1)) * _1353)) + clamp(int(floor(((_1349.x * 0.5f) + 0.5f) * _314_fa_cl_grid.x)), 0, _1353 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1433 = fa_cluster_texel(param);\n    return int2(int(_1433.x), int(_1433.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_314_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3073 = fa_cluster_lookup(param);\n    fa_cl_slot = _3073.x;\n    fa_cl_local = _3073.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _3222 = fa_linear_to_srgb(param);\n        c = _3222;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _3230 = fa_srgb_to_linear(param_1);\n            c = _3230;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _246;\n    if (i.front_facing)\n    {\n        _246 = i.world_normal;\n    }\n    else\n    {\n        _246 = -i.world_normal;\n    }\n    float3 _270 = normalize(i.world_tangent.xyz - (_246 * dot(_246, i.world_tangent.xyz)));\n    float3 _298 = normalize(((_270 * m.x) + ((cross(_246, _270) * i.world_tangent.w) * m.y)) + (_246 * m.z));\n    float3 _301;\n    if (i.front_facing)\n    {\n        _301 = _298;\n    }\n    else\n    {\n        _301 = -_298;\n    }\n    return _301;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _314_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3261 = fa_tex_fix(param_2, param_3);\n    float4 _4286 = base_t;\n    _4286.x = _3261.x;\n    _4286.y = _3261.y;\n    _4286.z = _3261.z;\n    base_t = _4286;\n    float4 _3275 = (_4286 * _314_fa_base_color) * i.vertex_color;\n    float3 _4151 = i.world_normal;\n    if (_314_fa_maps.z > 0.5f)\n    {\n        float param_4 = _314_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3307 = fa_tex_fix(param_6, param_7);\n        float3 _3310 = (_3307 * 2.0f) - 1.0f.xxx;\n        float2 _3315 = _3310.xy * _314_fa_maps.x;\n        float3 _4294 = _3310;\n        _4294.x = _3315.x;\n        _4294.y = _3315.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4294;\n        _4151 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _314_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3343 = fa_tex_fix(param_12, param_13);\n    float4 _4297 = mrt;\n    _4297.x = _3343.x;\n    _4297.y = _3343.y;\n    _4297.z = _3343.z;\n    mrt = _4297;\n    float4 _3371 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _314_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _3371.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3382 = fa_tex_fix(param_16, param_17);\n    float param_18 = _314_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3412 = fa_tex_fix(param_20, param_21);\n    float _4156 = _314_fa_layers_a.x;\n    float _4157 = _314_fa_layers_a.y;\n    float _4160 = _314_fa_layers_a.z;\n    float _4159 = _314_fa_layers_b.w;\n    float _4162 = _314_fa_layers_c.x;\n    if (_314_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_314_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _4156 *= _3382.y;\n            _4157 *= _3382.z;\n            _4159 *= _3371.w;\n        }\n        if (_314_fa_layers_c.z > 1.5f)\n        {\n            _4160 *= mrt.x;\n            _4162 *= mrt.w;\n        }\n    }\n    Surface _4181 = { _3275.xyz, _3275.w, _4151, clamp(_314_fa_pbr.x * _3343.z, 0.0f, 1.0f), clamp(_314_fa_pbr.y * _3343.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_314_fa_maps.y * (_3382.x - 1.0f)), _314_fa_emissive.xyz + (_314_fa_model_emissive.xyz * _3412), _4156, _4157, _314_fa_layers_b.xyz, _4159, _4160, _314_fa_layers_a.w, _4162, _314_fa_layers_c.y, _314_fa_layers_d.xyz };\n    return _4181;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1513 = rect.zw - rect.xy;\n    float2 _1517 = _1513 * atlas;\n    float2 _1521 = ddx * _1517;\n    float2 _1525 = ddy * _1517;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1513), clamp(0.5f * log2(max(max(dot(_1521, _1521), dot(_1525, _1525)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1558 = _314_fa_counts.y < 0.5f;\n    bool _1565;\n    if (!_1558)\n    {\n        _1565 = _314_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1565 = _1558;\n    }\n    if (_1565)\n    {\n        return;\n    }\n    float3 _1571 = ddx(world_pos);\n    float3 _1574 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1578 = fa_cluster_texel(param);\n    int _1582 = int(_1578.w);\n    if (_1582 < 1)\n    {\n        return;\n    }\n    int _1592 = int(_314_fa_counts.y + 0.5f);\n    int param_1 = _1592;\n    float4 _1596 = fa_light_texel(param_1);\n    float2 _1599 = _1596.yz;\n    int _1603 = int(_1596.w);\n    int param_2 = _1592 + 1;\n    float4 _1608 = fa_light_texel(param_2);\n    float _1609 = _1608.x;\n    int _1615 = int(_314_fa_counts.w + 0.5f) - 1;\n    int _1619 = int(_1578.z);\n    float3 _1884;\n    for (int k = 0; k < _1582; k++)\n    {\n        int _1632 = _1619 + k;\n        int param_3 = _1603 + (_1632 >> 2);\n        int _1649 = (_1592 + 2) + (int(fa_light_texel(param_3)[_1632 & 3]) * 7);\n        int param_4 = _1649 + 6;\n        float4 _1654 = fa_light_texel(param_4);\n        if (((int(_1654.w + 0.5f) >> _1615) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1649;\n        float4 _1669 = fa_light_texel(param_5);\n        int param_6 = _1649 + 1;\n        float4 _1674 = fa_light_texel(param_6);\n        int param_7 = _1649 + 2;\n        float4 _1679 = fa_light_texel(param_7);\n        float3 _1682 = _1669.xyz;\n        float _1687 = dot(_1682, world_pos) + _1669.w;\n        float3 _1689 = _1674.xyz;\n        float _1694 = dot(_1689, world_pos) + _1674.w;\n        float3 _1696 = _1679.xyz;\n        float _1701 = dot(_1696, world_pos) + _1679.w;\n        bool _1706 = abs(_1687) > 0.5f;\n        bool _1714;\n        if (!_1706)\n        {\n            _1714 = abs(_1694) > 0.5f;\n        }\n        else\n        {\n            _1714 = _1706;\n        }\n        bool _1722;\n        if (!_1714)\n        {\n            _1722 = abs(_1701) > 0.5f;\n        }\n        else\n        {\n            _1722 = _1714;\n        }\n        if (_1722)\n        {\n            continue;\n        }\n        float _1737 = clamp(dot(geo_normal, normalize(_1696)) * _1654.z, 0.0f, 1.0f);\n        if (_1737 <= 0.0f)\n        {\n            continue;\n        }\n        float _1757 = (clamp((0.5f - abs(_1701)) * 10.0f, 0.0f, 1.0f) * _1737) * _1654.x;\n        float2 _1765 = float2(_1687 + 0.5f, 0.5f - _1694);\n        float2 _1775 = float2(dot(_1682, _1571), dot(_1689, _1571));\n        float2 _1785 = float2(dot(_1682, _1574), dot(_1689, _1574));\n        int param_8 = _1649 + 5;\n        float4 _1790 = fa_light_texel(param_8);\n        int param_9 = _1649 + 3;\n        float4 _1795 = fa_light_texel(param_9);\n        int param_10 = _1649 + 4;\n        float4 _1800 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1790.xyz;\n        bool _1810 = _1795.z > _1795.x;\n        if (_1810)\n        {\n            float4 param_11 = _1795;\n            float2 param_12 = _1765;\n            float2 param_13 = _1599;\n            float2 param_14 = _1775;\n            float2 param_15 = _1785;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1609 > 0.5f) && (_1609 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1836 = fa_dc_to_linear(param_16);\n                float4 _4231 = tx;\n                _4231.x = _1836.x;\n                _4231.y = _1836.y;\n                _4231.z = _1836.z;\n                tx = _4231;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1757 * tex_a) * _1790.w, 0.0f, 1.0f).xxx);\n        if (_1800.z > _1800.x)\n        {\n            float4 param_17 = _1800;\n            float2 param_18 = _1765;\n            float2 param_19 = _1599;\n            float2 param_20 = _1775;\n            float2 param_21 = _1785;\n            float4 _1880 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1609 > 1.5f)\n            {\n                float3 param_22 = _1880.xyz;\n                float3 _1890 = fa_dc_to_srgb(param_22);\n                _1884 = _1890;\n            }\n            else\n            {\n                _1884 = _1880.xyz;\n            }\n            float3 _1899 = (_1884 * 2.0f) - 1.0f.xxx;\n            float2 _1904 = _1899.xy * _1654.y;\n            float3 _1926 = (normalize(_1682) * _1904.x) + (normalize(_1689) * _1904.y);\n            float3 _1929 = normalize(normal);\n            normal = normalize(lerp(_1929, normalize((_1929 * max(_1899.z, 0.0500000007450580596923828125f)) + (_1926 - (_1929 * dot(_1929, _1926)))), clamp(_1757 * (_1810 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_314_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _314_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_314_fa_cl_info.x) + int(_314_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_314_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _376_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _376_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _542 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _555 = (c - (ru * hx)) - p;\n        float3 _561 = ru * (2.0f * hx);\n        float _567 = max(dot(_561, _561), 9.9999999392252902907785028219223e-09f);\n        float _571 = dot(_555, _561);\n        float t = clamp((-_571) / _567, 0.0f, 1.0f);\n        if (_542)\n        {\n            float _586 = dot(r, _561);\n            float _592 = _567 - (_586 * _586);\n            if (abs(_592) > (9.9999997473787516355514526367188e-06f * _567))\n            {\n                t = clamp(((dot(r, _555) * _586) - _571) / _592, 0.0f, 1.0f);\n            }\n        }\n        return (p + _555) + (_561 * t);\n    }\n    float3 q = p;\n    float _624 = dot(r, axis);\n    bool _632;\n    if (_542)\n    {\n        _632 = abs(_624) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _632 = _542;\n    }\n    if (_632)\n    {\n        float _642 = dot(c - p, axis) / _624;\n        if (_642 > 0.0f)\n        {\n            q = p + (r * _642);\n        }\n    }\n    float3 _655 = q - c;\n    float2 xy = float2(dot(_655, ru), dot(_655, uu));\n    if (shape > 0.5f)\n    {\n        float _670 = length(xy);\n        if (_670 > hx)\n        {\n            xy *= (hx / _670);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _463 = abs(d);\n    float _465 = _463.x;\n    float _467 = _463.y;\n    bool _468 = _465 >= _467;\n    bool _476;\n    if (_468)\n    {\n        _476 = _465 >= _463.z;\n    }\n    else\n    {\n        _476 = _468;\n    }\n    int _477;\n    if (_476)\n    {\n        _477 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _490;\n        if (_467 >= _463.z)\n        {\n            _490 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _490 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _477 = _490;\n    }\n    return _477;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _416 = dot(d, right);\n    float _420 = dot(d, up);\n    float _431;\n    if (((_416 * _416) + (_420 * _420)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _431 = atan2(_420, _416) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _431 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_431 - floor(_431)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _708 = fa_light_base(param);\n    bool _712 = _314_fa_ambient.w > 4.5f;\n    int param_1 = _708;\n    float4 _716 = fa_light_texel(param_1);\n    int param_2 = _708 + 1;\n    float4 _721 = fa_light_texel(param_2);\n    float _724 = _721.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _736 = _712 && (_724 > 2.5f);\n    fa_light_is_area = _736;\n    bool _738 = _724 < 0.5f;\n    float3 l;\n    if (_738)\n    {\n        l = normalize(_716.xyz);\n        if (_712)\n        {\n            int param_3 = _708 + 6;\n            float4 _752 = fa_light_texel(param_3);\n            if (_752.z > 0.5f)\n            {\n                int param_4 = _708 + 4;\n                float4 _762 = fa_light_texel(param_4);\n                int param_5 = _708 + 5;\n                float4 _767 = fa_light_texel(param_5);\n                float2 param_6 = _752.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _762.xyz) * _762.w, (-dot(world_pos, _767.xyz)) * _767.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _797 = _716.xyz;\n        float3 _799 = _797 - world_pos;\n        float3 to_light = _799;\n        float _802 = length(_799);\n        float reach = _802;\n        bool front = true;\n        if (_736)\n        {\n            int param_8 = _708 + 7;\n            reach = max(_802 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _708 + 4;\n            float4 _826 = fa_light_texel(param_9);\n            int param_10 = _708 + 5;\n            float4 _831 = fa_light_texel(param_10);\n            int param_11 = _708 + 6;\n            float4 _836 = fa_light_texel(param_11);\n            float _837 = _836.w;\n            int param_12 = _708 + 2;\n            float3 _844 = normalize(fa_light_texel(param_12).xyz);\n            bool _846 = _837 > 1.5f;\n            bool _854;\n            if (!_846)\n            {\n                _854 = dot(_844, to_light) < 0.0f;\n            }\n            else\n            {\n                _854 = _846;\n            }\n            front = _854;\n            float3 r = 0.0f.xxx;\n            if (dot(n, n) > 0.5f)\n            {\n                r = reflect(-normalize(_314_fa_camera_pos.xyz - world_pos), normalize(n));\n            }\n            float3 param_13 = _797;\n            float3 param_14 = _844;\n            float3 param_15 = _826.xyz;\n            float3 param_16 = _831.xyz;\n            float param_17 = _826.w;\n            float param_18 = _831.w;\n            float param_19 = _837;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _901 = length(to_light);\n        dist = _901;\n        l = to_light / max(_901, 9.9999997473787516355514526367188e-05f).xxx;\n        float _915 = reach / max(_716.w, 0.001000000047497451305389404296875f);\n        float _921 = clamp(1.0f - (_915 * _915), 0.0f, 1.0f);\n        float _923;\n        if (front)\n        {\n            _923 = _921 * _921;\n        }\n        else\n        {\n            _923 = 0.0f;\n        }\n        atten = _923;\n        bool _934 = _724 < 2.5f;\n        if ((_724 > 1.5f) && _934)\n        {\n            int param_22 = _708 + 2;\n            float4 _942 = fa_light_texel(param_22);\n            float _952 = _942.w;\n            int param_23 = _708 + 3;\n            float4 _957 = fa_light_texel(param_23);\n            float _958 = _957.x;\n            float cos_inner = _958;\n            if (_958 > 1.5f)\n            {\n                cos_inner = lerp(_952, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_952, cos_inner, dot(-l, normalize(_942.xyz)));\n        }\n        if (_712 && (_724 < 1.5f))\n        {\n            int param_24 = _708 + 6;\n            float4 _982 = fa_light_texel(param_24);\n            if (_982.z > 0.5f)\n            {\n                float3 _990 = -to_light;\n                int param_25 = _708 + 4;\n                int param_26 = _708 + 5;\n                float3 _1004 = fa_light_texel(param_25).xyz;\n                float3 _1008 = fa_light_texel(param_26).xyz;\n                float3 _1017 = float3(dot(_990, _1004), dot(_990, _1008), dot(_990, cross(_1004, _1008)));\n                float3 param_27 = _1017;\n                int _1021 = fa_cube_face(param_27);\n                int param_28 = _1021;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1048 = float2(dot(_1017, cross(param_29, param_30)), dot(_1017, param_30)) / max(dot(_1017, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1052 = _1021 / 3;\n                float2 param_31 = _982.xy + (float2(float(_1021 - (_1052 * 3)), float(_1052)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1048.x), 0.5f - (0.5f * _1048.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _708 + 7;\n            float4 _1082 = fa_light_texel(param_33);\n            if (_1082.z > 0.5f)\n            {\n                int param_34 = _708 + 2;\n                int param_35 = _708 + 4;\n                int param_36 = _708 + 5;\n                float2 param_37 = _1082.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_712 && _934)\n            {\n                int param_42 = _708 + 6;\n                float4 _1129 = fa_light_texel(param_42);\n                int param_43 = _708 + 7;\n                float4 _1134 = fa_light_texel(param_43);\n                bool _1137 = _1129.z > 0.5f;\n                bool _1144;\n                if (!_1137)\n                {\n                    _1144 = _1134.z > 0.5f;\n                }\n                else\n                {\n                    _1144 = _1137;\n                }\n                if (_1144)\n                {\n                    int param_44 = _708 + 2;\n                    float4 _1151 = fa_light_texel(param_44);\n                    float3 _1155 = normalize(_1151.xyz);\n                    int param_45 = _708 + 4;\n                    float4 _1160 = fa_light_texel(param_45);\n                    int param_46 = _708 + 5;\n                    float4 _1165 = fa_light_texel(param_46);\n                    if (_1137)\n                    {\n                        float3 _1173 = -to_light;\n                        float _1180 = _1151.w;\n                        float _1196 = 0.5f / max(dot(_1173, _1155) * (sqrt(max(1.0f - (_1180 * _1180), 0.0f)) / max(_1180, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1129.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1173, _1160.xyz) * _1196), 0.5f - (dot(_1173, _1165.xyz) * _1196));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1134.z > 0.5f)\n                    {\n                        float2 param_49 = _1134.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1155;\n                        float3 param_52 = _1160.xyz;\n                        float3 param_53 = _1165.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4105 = _721.xyz * atten;\n    if (_712)\n    {\n        _4105 *= fa_light_tint;\n    }\n    int _1264;\n    if (_738)\n    {\n        _1264 = 0;\n    }\n    else\n    {\n        _1264 = ((_724 > 1.5f) && (_724 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _4116 = { l, _4105, atten, 1.0f, dist, _1264 };\n    return _4116;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2001;\n    if (i == 0)\n    {\n        _2001 = _2011_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2017;\n        if (i == 1)\n        {\n            _2017 = _2011_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2025;\n            if (i == 2)\n            {\n                _2025 = _2011_fa_shadow_split.z;\n            }\n            else\n            {\n                _2025 = _2011_fa_shadow_split.w;\n            }\n            _2017 = _2025;\n        }\n        _2001 = _2017;\n    }\n    return _2001;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2058 = fa_shadow_depth(param, param_1);\n    float _2062;\n    if (conv.x < 0.5f)\n    {\n        _2062 = _2058;\n    }\n    else\n    {\n        _2062 = (conv.y * conv.z) / (conv.z - (_2058 * (conv.z - conv.y)));\n    }\n    return _2062;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1989 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_1989), sin(_1989)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2108 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2117;\n        if (k < 0.0f)\n        {\n            _2117 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2117 = k;\n        }\n        float _2137 = clamp((_2117 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2108;\n            float2 _2156 = fa_shadow_vogel(param_3, param_4, param_5) * _2137;\n            float2 param_6 = uv + (_2156 * _2011_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2168 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2168 < (zr - (length(_2156) * plane)))\n            {\n                sum += _2168;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2194 = sum / cnt;\n        float _2204;\n        if (k < 0.0f)\n        {\n            _2204 = (-k) / max(_2194, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2204 = k;\n        }\n        radius = clamp(((max(zr - _2194, 0.0f) * unit) * _2204) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2226 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2226; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2226;\n        float param_11 = _2108;\n        float2 _2245 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2245 * _2011_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2245) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2226);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2287 = max(_2011_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2292 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2298 = sqrt(1.0f - (_2292 * _2292));\n    float _2305 = min(_2298 / max(_2292, 0.20000000298023223876953125f), 4.0f);\n    float _2310;\n    if (_2011_fa_shadow_bias.y > 0.0f)\n    {\n        _2310 = _2011_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2310 = 1.5f * _2011_fa_shadow_info[ci].x;\n    }\n    float4 _2335 = mul(float4(world + (n * (_2310 * _2298)), 1.0f), _2011_fa_shadow_mat[ci]);\n    float _2342 = _2335.x;\n    bool _2345 = _2342 < _2011_fa_shadow_rect[ci].x;\n    bool _2354;\n    if (!_2345)\n    {\n        _2354 = _2342 > _2011_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2354 = _2345;\n    }\n    bool _2363;\n    if (!_2354)\n    {\n        _2363 = _2335.y < _2011_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2363 = _2354;\n    }\n    bool _2372;\n    if (!_2363)\n    {\n        _2372 = _2335.y > _2011_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2372 = _2363;\n    }\n    bool _2379;\n    if (!_2372)\n    {\n        _2379 = _2335.z > 1.0f;\n    }\n    else\n    {\n        _2379 = _2372;\n    }\n    if (_2379)\n    {\n        return -1.0f;\n    }\n    float _2387;\n    if (_2011_fa_shadow_bias.x > 0.0f)\n    {\n        _2387 = _2011_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2387 = 1.5f * _2011_fa_shadow_info[ci].x;\n    }\n    float2 param = _2335.xy;\n    float4 param_1 = _2011_fa_shadow_rect[ci];\n    float param_2 = _2335.z - ((_2387 * (1.0f + (0.5f * _2305))) / _2287);\n    float param_3 = _2011_fa_shadow_info[ci].x;\n    float param_4 = _2287;\n    float param_5 = _2287 * 0.25f;\n    float param_6 = ((_2011_fa_shadow_info[ci].x * min(_2305, 3.0f)) * 0.5f) / _2287;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2011_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2011_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_314_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2775 = int(_2011_fa_shadow_cfg.x + 0.5f);\n    if (_2775 < 1)\n    {\n        return 1.0f;\n    }\n    float _2790 = dot(world - _2011_fa_shadow_eye.xyz, _2011_fa_shadow_fwd.xyz);\n    int param = _2775 - 1;\n    if (_2790 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2802 = _2775 > 1;\n    bool _2809;\n    if (_2802)\n    {\n        _2809 = _2790 > _2011_fa_shadow_split.x;\n    }\n    else\n    {\n        _2809 = _2802;\n    }\n    if (_2809)\n    {\n        ci = 1;\n    }\n    bool _2813 = _2775 > 2;\n    bool _2820;\n    if (_2813)\n    {\n        _2820 = _2790 > _2011_fa_shadow_split.y;\n    }\n    else\n    {\n        _2820 = _2813;\n    }\n    if (_2820)\n    {\n        ci = 2;\n    }\n    bool _2824 = _2775 > 3;\n    bool _2831;\n    if (_2824)\n    {\n        _2831 = _2790 > _2011_fa_shadow_split.z;\n    }\n    else\n    {\n        _2831 = _2824;\n    }\n    if (_2831)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2775)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2857 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2857;\n        if (_2857 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2011_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2882;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2882 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2882 = _2011_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2901 = _2011_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2882, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2912 = clamp((_2790 - (fa_shadow_split_at(param_7) - _2901)) / _2901, 0.0f, 1.0f);\n        if (_2912 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2775)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2933 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2933;\n                if (_2933 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2912);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _2445 = _314_fa_pbr.z < 0.5f;\n    bool _2452;\n    if (!_2445)\n    {\n        _2452 = _2011_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2452 = _2445;\n    }\n    if (_2452)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2011_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2465 = fa_light_texel(param);\n    float _2466 = _2465.x;\n    if (_2466 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2475 = int(_2466 + 0.5f);\n    int param_1 = _2475;\n    float4 _2479 = fa_light_texel(param_1);\n    int param_2 = _2475 + 1;\n    float4 _2484 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2487 = _2479.y;\n    if (_2487 > 0.0f)\n    {\n        float _2504 = 1.0f - smoothstep(0.75f * _2487, _2487, length(world - _2011_fa_shadow_eye.xyz));\n        fade = _2504;\n        if (_2504 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2479.x > 1.5f)\n    {\n        int param_3 = li;\n        int param_4 = fa_light_base(param_3);\n        float3 param_5 = world - fa_light_texel(param_4).xyz;\n        face = fa_cube_face(param_5);\n    }\n    int _2533 = (_2475 + 2) + (face * 6);\n    int param_6 = _2533;\n    int param_7 = _2533 + 1;\n    int param_8 = _2533 + 3;\n    float4 _2547 = fa_light_texel(param_8);\n    int param_9 = _2533 + 4;\n    float4 _2552 = fa_light_texel(param_9);\n    int param_10 = _2533 + 5;\n    float4 _2557 = fa_light_texel(param_10);\n    float _2569 = _2557.x * max(dot(_2547, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2574 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2597 = clamp(dot(n, _2547.xyz), -1.0f, 1.0f);\n    int param_11 = li;\n    int param_12 = fa_light_base(param_11);\n    float _2621 = min(sqrt(1.0f - (_2597 * _2597)) / max(abs(dot(n, world - fa_light_texel(param_12).xyz)) / max(dot(_2547, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2624 = _2484.y;\n    float _2626;\n    if (_2624 > 0.0f)\n    {\n        _2626 = _2624;\n    }\n    else\n    {\n        _2626 = 1.5f * _2569;\n    }\n    float4 _2646 = float4(world + (n * (_2626 * sqrt(1.0f - (_2574 * _2574)))), 1.0f);\n    float _2650 = dot(_2547, _2646);\n    float _2653 = _2557.y;\n    if (_2650 < _2653)\n    {\n        return 1.0f;\n    }\n    float2 _2668 = float2(dot(fa_light_texel(param_6), _2646), dot(fa_light_texel(param_7), _2646)) / _2650.xx;\n    float _2670 = _2668.x;\n    bool _2673 = _2670 < _2552.x;\n    bool _2682;\n    if (!_2673)\n    {\n        _2682 = _2670 > _2552.z;\n    }\n    else\n    {\n        _2682 = _2673;\n    }\n    bool _2691;\n    if (!_2682)\n    {\n        _2691 = _2668.y < _2552.y;\n    }\n    else\n    {\n        _2691 = _2682;\n    }\n    bool _2700;\n    if (!_2691)\n    {\n        _2700 = _2668.y > _2552.w;\n    }\n    else\n    {\n        _2700 = _2691;\n    }\n    if (_2700)\n    {\n        return 1.0f;\n    }\n    float _2706 = _2484.x;\n    float _2708;\n    if (_2706 > 0.0f)\n    {\n        _2708 = _2706;\n    }\n    else\n    {\n        _2708 = 1.5f * _2569;\n    }\n    float2 param_13 = _2668;\n    float4 param_14 = _2552;\n    float param_15 = _2650 - (_2708 * (1.0f + (0.5f * _2621)));\n    float param_16 = _2569;\n    float param_17 = 1.0f;\n    float param_18 = _2557.z * 0.25f;\n    float param_19 = (_2569 * min(_2621, 3.0f)) * 0.5f;\n    float3 param_20 = float3(1.0f, _2653, _2557.z);\n    int param_21 = int(_2479.z + 0.5f);\n    float param_22 = _2479.w;\n    return lerp(1.0f, fa_shadow_filter(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _3100 = fa_lm.z > 0.5f;\n    bool _3106;\n    if (_3100)\n    {\n        int param = li;\n        _3106 = fa_light_baked(param);\n    }\n    else\n    {\n        _3106 = _3100;\n    }\n    if (_3106)\n    {\n        int param_1 = li;\n        LightSample _4129 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _4129;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3130 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _4131 = _3130.color;\n    float _4133 = _3130.shadow;\n    if ((_3130.type == 0) && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3130.direction;\n        float _3144 = fa_shadow_factor(param_5, param_6);\n        _4133 = _3144;\n        _4131 *= _3144;\n    }\n    else\n    {\n        bool _3155 = _3130.type != 0;\n        bool _3161;\n        if (_3155)\n        {\n            _3161 = _3130.attenuation > 0.0f;\n        }\n        else\n        {\n            _3161 = _3155;\n        }\n        if (_3161)\n        {\n            int param_7 = li;\n            float3 param_8 = world_pos;\n            float3 param_9 = gn;\n            float3 param_10 = _3130.direction;\n            float _3173 = fa_shadow_local(param_7, param_8, param_9, param_10);\n            _4133 = _3173;\n            _4131 *= _3173;\n        }\n    }\n    LightSample _4148 = { _3130.direction, _4131, _3130.attenuation, _4133, _3130._distance, _3130.type };\n    return _4148;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2011_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _2957 = int(_2011_fa_shadow_cfg.x + 0.5f);\n    float _2967 = dot(world - _2011_fa_shadow_eye.xyz, _2011_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _2972 = _2957 > 0;\n    bool _2981;\n    if (_2972)\n    {\n        int param = _2957 - 1;\n        _2981 = _2967 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2981 = _2972;\n    }\n    if (_2981)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _2987 = _2957 > 1;\n        bool _2994;\n        if (_2987)\n        {\n            _2994 = _2967 > _2011_fa_shadow_split.x;\n        }\n        else\n        {\n            _2994 = _2987;\n        }\n        if (_2994)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3000 = _2957 > 2;\n        bool _3007;\n        if (_3000)\n        {\n            _3007 = _2967 > _2011_fa_shadow_split.y;\n        }\n        else\n        {\n            _3007 = _3000;\n        }\n        if (_3007)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3013 = _2957 > 3;\n        bool _3020;\n        if (_3013)\n        {\n            _3020 = _2967 > _2011_fa_shadow_split.z;\n        }\n        else\n        {\n            _3020 = _3013;\n        }\n        if (_3020)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _3972 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3972 = -_3972;\n    }\n    float3 _3556 = normalize(_314_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _3985 = { fa_world_pos, _3972, fa_world_tangent, fa_uv, fa_vertex_color, _3556, gl_FrontFacing };\n    SurfaceInput param_1 = _3985;\n    Surface _3564 = fa_standard_surface(param_1);\n    float3 _4003 = _3564.albedo;\n    float _4004 = _3564.alpha;\n    float3 _4005 = _3564.normal;\n    float _4006 = _3564.metallic;\n    float _4007 = _3564.roughness;\n    float _4008 = _3564.occlusion;\n    float3 _4009 = _3564.emission;\n    float _4010 = _3564.clearcoat;\n    float _4011 = _3564.clearcoat_roughness;\n    float3 _4012 = _3564.sheen_color;\n    float _4013 = _3564.sheen_roughness;\n    float _4014 = _3564.anisotropy;\n    float _4015 = _3564.anisotropy_rotation;\n    float _4016 = _3564.specular;\n    float _4017 = _3564.ior;\n    float3 _4018 = _3564.specular_color;\n    SurfaceInput _3993 = { fa_world_pos, _3972, fa_world_tangent, fa_uv, fa_vertex_color, _3556, gl_FrontFacing };\n    SurfaceInput param_2 = _3993;\n    Surface param_3 = _3564;\n    surface(param_2, param_3);\n    _4003 = param_3.albedo;\n    _4004 = param_3.alpha;\n    _4005 = param_3.normal;\n    _4006 = param_3.metallic;\n    _4007 = param_3.roughness;\n    _4008 = param_3.occlusion;\n    _4009 = param_3.emission;\n    _4010 = param_3.clearcoat;\n    _4011 = param_3.clearcoat_roughness;\n    _4012 = param_3.sheen_color;\n    _4013 = param_3.sheen_roughness;\n    _4014 = param_3.anisotropy;\n    _4015 = param_3.anisotropy_rotation;\n    _4016 = param_3.specular;\n    _4017 = param_3.ior;\n    _4018 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _3972;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4003 = param_6;\n    _4005 = param_7;\n    float3 result;\n    if (_314_fa_emissive.w > 0.5f)\n    {\n        result = _4003;\n    }\n    else\n    {\n        float3 _3602 = _4005;\n        float3 _3603 = normalize(_3602);\n        _4005 = _3603;\n        float3 param_8 = _3603;\n        float3 lit = (fa_indirect_diffuse(param_8) * _4003) * _4008;\n        int _3622 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3622; ln++)\n        {\n            int param_9 = ln;\n            int _3635 = fa_cl_light(param_9);\n            bool _3638 = fa_lm.z > 0.5f;\n            bool _3644;\n            if (_3638)\n            {\n                int param_10 = _3635;\n                _3644 = fa_light_baked(param_10);\n            }\n            else\n            {\n                _3644 = _3638;\n            }\n            if (_3644)\n            {\n                continue;\n            }\n            int param_11 = _3635;\n            float3 param_12 = fa_world_pos;\n            float3 param_13 = _3972;\n            LightSample _3656 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput _4001 = { fa_world_pos, _3972, fa_world_tangent, fa_uv, fa_vertex_color, _3556, gl_FrontFacing };\n            SurfaceInput param_14 = _4001;\n            Surface _4084 = { _4003, _4004, _4005, _4006, _4007, _4008, _4009, _4010, _4011, _4012, _4013, _4014, _4015, _4016, _4017, _4018 };\n            Surface param_15 = _4084;\n            LightSample param_16 = _3656;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    float3 _3671 = result;\n    float3 _3672 = _3671 + _4009;\n    result = _3672;\n    float3 param_17 = _3672;\n    float3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _3681 = _314_fa_fog.w > 0.0f;\n    bool _3688;\n    if (!_3681)\n    {\n        _3688 = _314_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _3688 = _3681;\n    }\n    if (_3688)\n    {\n        float3 _3697 = fa_world_pos - _314_fa_camera_pos.xyz;\n        float _3703 = dot(_3697, _314_fa_fog_c.xyz);\n        bool _3707 = _314_fa_fog_c.w > 0.5f;\n        float _3708;\n        if (_3707)\n        {\n            _3708 = _3703;\n        }\n        else\n        {\n            _3708 = length(_3697);\n        }\n        float _3720 = _3708 - _314_fa_fog_b.x;\n        if (_3720 > 0.0f)\n        {\n            float _3729 = _314_fa_fog.w * _3720;\n            float tau = _3729 * _3729;\n            if (_314_fa_fog_b.y > 0.0f)\n            {\n                float _3745;\n                if (_3707)\n                {\n                    _3745 = fa_world_pos.y - (_314_fa_fog_c.y * _3703);\n                }\n                else\n                {\n                    _3745 = _314_fa_camera_pos.y;\n                }\n                float _3766 = lerp(_3745, fa_world_pos.y, clamp(_314_fa_fog_b.x / _3708, 0.0f, 1.0f));\n                float _3770 = fa_world_pos.y - _3766;\n                float _3775 = _3766 - _314_fa_fog_b.z;\n                float _3780 = fa_world_pos.y - _314_fa_fog_b.z;\n                bool _3783 = _3775 <= 0.0f;\n                bool _3784 = !_3783;\n                bool _3790;\n                if (_3784)\n                {\n                    _3790 = _314_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3790 = _3783;\n                }\n                float _3791;\n                if (_3790)\n                {\n                    _3791 = _314_fa_fog_b.y;\n                }\n                else\n                {\n                    _3791 = _314_fa_fog_b.y * exp(-min(_314_fa_fog_b.w * _3775, 80.0f));\n                }\n                bool _3818;\n                if (_3784)\n                {\n                    _3818 = _314_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3818 = _3783;\n                }\n                float _3819;\n                if (_3818)\n                {\n                    _3819 = _314_fa_fog_b.y * _3775;\n                }\n                else\n                {\n                    _3819 = (_314_fa_fog_b.y * (1.0f - exp(-min(_314_fa_fog_b.w * _3775, 80.0f)))) / _314_fa_fog_b.w;\n                }\n                bool _3844 = _3780 <= 0.0f;\n                bool _3851;\n                if (!_3844)\n                {\n                    _3851 = _314_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3851 = _3844;\n                }\n                float _3852;\n                if (_3851)\n                {\n                    _3852 = _314_fa_fog_b.y * _3780;\n                }\n                else\n                {\n                    _3852 = (_314_fa_fog_b.y * (1.0f - exp(-min(_314_fa_fog_b.w * _3780, 80.0f)))) / _314_fa_fog_b.w;\n                }\n                float _3879;\n                if (abs(_3770) < 0.001000000047497451305389404296875f)\n                {\n                    _3879 = _3791;\n                }\n                else\n                {\n                    _3879 = (_3852 - _3819) / _3770;\n                }\n                tau += (_3720 * max(_3879, 0.0f));\n            }\n            result = lerp(result, _314_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4004);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_314",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2011",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _314_fa_camera_pos : packoffset(c0);\n    float4 _314_fa_ambient : packoffset(c1);\n    float4 _314_fa_base_color : packoffset(c2);\n    float4 _314_fa_emissive : packoffset(c3);\n    float4 _314_fa_model_emissive : packoffset(c4);\n    float4 _314_fa_pbr : packoffset(c5);\n    float4 _314_fa_maps : packoffset(c6);\n    float4 _314_fa_fog : packoffset(c7);\n    float4 _314_fa_fog_b : packoffset(c8);\n    float4 _314_fa_fog_c : packoffset(c9);\n    float4 _314_fa_counts : packoffset(c10);\n    float4 _314_fa_env_sky : packoffset(c11);\n    float4 _314_fa_env_horizon : packoffset(c12);\n    float4 _314_fa_time : packoffset(c13);\n    float4 _314_fa_cl_vpx : packoffset(c14);\n    float4 _314_fa_cl_vpy : packoffset(c15);\n    float4 _314_fa_cl_vpw : packoffset(c16);\n    float4 _314_fa_cl_fwd : packoffset(c17);\n    float4 _314_fa_cl_grid : packoffset(c18);\n    float4 _314_fa_cl_info : packoffset(c19);\n    float4 _314_fa_layers_a : packoffset(c20);\n    float4 _314_fa_layers_b : packoffset(c21);\n    float4 _314_fa_layers_c : packoffset(c22);\n    float4 _314_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2011_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2011_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2011_fa_shadow_info[4] : packoffset(c20);\n    float4 _2011_fa_shadow_split : packoffset(c24);\n    float4 _2011_fa_shadow_cfg : packoffset(c25);\n    float4 _2011_fa_shadow_bias : packoffset(c26);\n    float4 _2011_fa_shadow_eye : packoffset(c27);\n    float4 _2011_fa_shadow_fwd : packoffset(c28);\n    float4 _2011_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_irr_tex : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1282 = _314_fa_cl_info.x < 0.0f;\n    bool _1289;\n    if (!_1282)\n    {\n        _1289 = _314_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1289 = _1282;\n    }\n    bool _1297;\n    if (!_1289)\n    {\n        _1297 = _314_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1297 = _1289;\n    }\n    bool _1304;\n    if (!_1297)\n    {\n        _1304 = _314_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1304 = _1297;\n    }\n    bool _1311;\n    if (!_1304)\n    {\n        _1311 = _314_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1311 = _1304;\n    }\n    if (_1311)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1321 = float4(world_pos, 1.0f);\n    float _1327 = dot(_314_fa_cl_vpw, _1321);\n    if (!(_1327 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1349 = float2(dot(_314_fa_cl_vpx, _1321), dot(_314_fa_cl_vpy, _1321)) / _1327.xx;\n    int _1353 = int(_314_fa_cl_grid.x);\n    int _1357 = int(_314_fa_cl_grid.y);\n    int param = (int(_314_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_314_fa_cl_fwd.xyz, world_pos) + _314_fa_cl_fwd.w, _314_fa_cl_grid.w) / _314_fa_cl_grid.w) * _314_fa_cl_grid.z)), 0, int(_314_fa_cl_info.y) - 1) * _1357) + clamp(int(floor(((_1349.y * 0.5f) + 0.5f) * _314_fa_cl_grid.y)), 0, _1357 - 1)) * _1353)) + clamp(int(floor(((_1349.x * 0.5f) + 0.5f) * _314_fa_cl_grid.x)), 0, _1353 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1433 = fa_cluster_texel(param);\n    return int2(int(_1433.x), int(_1433.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_314_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3073 = fa_cluster_lookup(param);\n    fa_cl_slot = _3073.x;\n    fa_cl_local = _3073.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _3222 = fa_linear_to_srgb(param);\n        c = _3222;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _3230 = fa_srgb_to_linear(param_1);\n            c = _3230;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _246;\n    if (i.front_facing)\n    {\n        _246 = i.world_normal;\n    }\n    else\n    {\n        _246 = -i.world_normal;\n    }\n    float3 _270 = normalize(i.world_tangent.xyz - (_246 * dot(_246, i.world_tangent.xyz)));\n    float3 _298 = normalize(((_270 * m.x) + ((cross(_246, _270) * i.world_tangent.w) * m.y)) + (_246 * m.z));\n    float3 _301;\n    if (i.front_facing)\n    {\n        _301 = _298;\n    }\n    else\n    {\n        _301 = -_298;\n    }\n    return _301;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _314_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3261 = fa_tex_fix(param_2, param_3);\n    float4 _4286 = base_t;\n    _4286.x = _3261.x;\n    _4286.y = _3261.y;\n    _4286.z = _3261.z;\n    base_t = _4286;\n    float4 _3275 = (_4286 * _314_fa_base_color) * i.vertex_color;\n    float3 _4151 = i.world_normal;\n    if (_314_fa_maps.z > 0.5f)\n    {\n        float param_4 = _314_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3307 = fa_tex_fix(param_6, param_7);\n        float3 _3310 = (_3307 * 2.0f) - 1.0f.xxx;\n        float2 _3315 = _3310.xy * _314_fa_maps.x;\n        float3 _4294 = _3310;\n        _4294.x = _3315.x;\n        _4294.y = _3315.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4294;\n        _4151 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _314_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3343 = fa_tex_fix(param_12, param_13);\n    float4 _4297 = mrt;\n    _4297.x = _3343.x;\n    _4297.y = _3343.y;\n    _4297.z = _3343.z;\n    mrt = _4297;\n    float4 _3371 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _314_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _3371.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3382 = fa_tex_fix(param_16, param_17);\n    float param_18 = _314_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3412 = fa_tex_fix(param_20, param_21);\n    float _4156 = _314_fa_layers_a.x;\n    float _4157 = _314_fa_layers_a.y;\n    float _4160 = _314_fa_layers_a.z;\n    float _4159 = _314_fa_layers_b.w;\n    float _4162 = _314_fa_layers_c.x;\n    if (_314_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_314_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _4156 *= _3382.y;\n            _4157 *= _3382.z;\n            _4159 *= _3371.w;\n        }\n        if (_314_fa_layers_c.z > 1.5f)\n        {\n            _4160 *= mrt.x;\n            _4162 *= mrt.w;\n        }\n    }\n    Surface _4181 = { _3275.xyz, _3275.w, _4151, clamp(_314_fa_pbr.x * _3343.z, 0.0f, 1.0f), clamp(_314_fa_pbr.y * _3343.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_314_fa_maps.y * (_3382.x - 1.0f)), _314_fa_emissive.xyz + (_314_fa_model_emissive.xyz * _3412), _4156, _4157, _314_fa_layers_b.xyz, _4159, _4160, _314_fa_layers_a.w, _4162, _314_fa_layers_c.y, _314_fa_layers_d.xyz };\n    return _4181;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1513 = rect.zw - rect.xy;\n    float2 _1517 = _1513 * atlas;\n    float2 _1521 = ddx * _1517;\n    float2 _1525 = ddy * _1517;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1513), clamp(0.5f * log2(max(max(dot(_1521, _1521), dot(_1525, _1525)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1558 = _314_fa_counts.y < 0.5f;\n    bool _1565;\n    if (!_1558)\n    {\n        _1565 = _314_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1565 = _1558;\n    }\n    if (_1565)\n    {\n        return;\n    }\n    float3 _1571 = ddx(world_pos);\n    float3 _1574 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1578 = fa_cluster_texel(param);\n    int _1582 = int(_1578.w);\n    if (_1582 < 1)\n    {\n        return;\n    }\n    int _1592 = int(_314_fa_counts.y + 0.5f);\n    int param_1 = _1592;\n    float4 _1596 = fa_light_texel(param_1);\n    float2 _1599 = _1596.yz;\n    int _1603 = int(_1596.w);\n    int param_2 = _1592 + 1;\n    float4 _1608 = fa_light_texel(param_2);\n    float _1609 = _1608.x;\n    int _1615 = int(_314_fa_counts.w + 0.5f) - 1;\n    int _1619 = int(_1578.z);\n    float3 _1884;\n    for (int k = 0; k < _1582; k++)\n    {\n        int _1632 = _1619 + k;\n        int param_3 = _1603 + (_1632 >> 2);\n        int _1649 = (_1592 + 2) + (int(fa_light_texel(param_3)[_1632 & 3]) * 7);\n        int param_4 = _1649 + 6;\n        float4 _1654 = fa_light_texel(param_4);\n        if (((int(_1654.w + 0.5f) >> _1615) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1649;\n        float4 _1669 = fa_light_texel(param_5);\n        int param_6 = _1649 + 1;\n        float4 _1674 = fa_light_texel(param_6);\n        int param_7 = _1649 + 2;\n        float4 _1679 = fa_light_texel(param_7);\n        float3 _1682 = _1669.xyz;\n        float _1687 = dot(_1682, world_pos) + _1669.w;\n        float3 _1689 = _1674.xyz;\n        float _1694 = dot(_1689, world_pos) + _1674.w;\n        float3 _1696 = _1679.xyz;\n        float _1701 = dot(_1696, world_pos) + _1679.w;\n        bool _1706 = abs(_1687) > 0.5f;\n        bool _1714;\n        if (!_1706)\n        {\n            _1714 = abs(_1694) > 0.5f;\n        }\n        else\n        {\n            _1714 = _1706;\n        }\n        bool _1722;\n        if (!_1714)\n        {\n            _1722 = abs(_1701) > 0.5f;\n        }\n        else\n        {\n            _1722 = _1714;\n        }\n        if (_1722)\n        {\n            continue;\n        }\n        float _1737 = clamp(dot(geo_normal, normalize(_1696)) * _1654.z, 0.0f, 1.0f);\n        if (_1737 <= 0.0f)\n        {\n            continue;\n        }\n        float _1757 = (clamp((0.5f - abs(_1701)) * 10.0f, 0.0f, 1.0f) * _1737) * _1654.x;\n        float2 _1765 = float2(_1687 + 0.5f, 0.5f - _1694);\n        float2 _1775 = float2(dot(_1682, _1571), dot(_1689, _1571));\n        float2 _1785 = float2(dot(_1682, _1574), dot(_1689, _1574));\n        int param_8 = _1649 + 5;\n        float4 _1790 = fa_light_texel(param_8);\n        int param_9 = _1649 + 3;\n        float4 _1795 = fa_light_texel(param_9);\n        int param_10 = _1649 + 4;\n        float4 _1800 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1790.xyz;\n        bool _1810 = _1795.z > _1795.x;\n        if (_1810)\n        {\n            float4 param_11 = _1795;\n            float2 param_12 = _1765;\n            float2 param_13 = _1599;\n            float2 param_14 = _1775;\n            float2 param_15 = _1785;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1609 > 0.5f) && (_1609 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1836 = fa_dc_to_linear(param_16);\n                float4 _4231 = tx;\n                _4231.x = _1836.x;\n                _4231.y = _1836.y;\n                _4231.z = _1836.z;\n                tx = _4231;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1757 * tex_a) * _1790.w, 0.0f, 1.0f).xxx);\n        if (_1800.z > _1800.x)\n        {\n            float4 param_17 = _1800;\n            float2 param_18 = _1765;\n            float2 param_19 = _1599;\n            float2 param_20 = _1775;\n            float2 param_21 = _1785;\n            float4 _1880 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1609 > 1.5f)\n            {\n                float3 param_22 = _1880.xyz;\n                float3 _1890 = fa_dc_to_srgb(param_22);\n                _1884 = _1890;\n            }\n            else\n            {\n                _1884 = _1880.xyz;\n            }\n            float3 _1899 = (_1884 * 2.0f) - 1.0f.xxx;\n            float2 _1904 = _1899.xy * _1654.y;\n            float3 _1926 = (normalize(_1682) * _1904.x) + (normalize(_1689) * _1904.y);\n            float3 _1929 = normalize(normal);\n            normal = normalize(lerp(_1929, normalize((_1929 * max(_1899.z, 0.0500000007450580596923828125f)) + (_1926 - (_1929 * dot(_1929, _1926)))), clamp(_1757 * (_1810 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_314_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _314_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_314_fa_cl_info.x) + int(_314_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_314_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _376_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _376_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _542 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _555 = (c - (ru * hx)) - p;\n        float3 _561 = ru * (2.0f * hx);\n        float _567 = max(dot(_561, _561), 9.9999999392252902907785028219223e-09f);\n        float _571 = dot(_555, _561);\n        float t = clamp((-_571) / _567, 0.0f, 1.0f);\n        if (_542)\n        {\n            float _586 = dot(r, _561);\n            float _592 = _567 - (_586 * _586);\n            if (abs(_592) > (9.9999997473787516355514526367188e-06f * _567))\n            {\n                t = clamp(((dot(r, _555) * _586) - _571) / _592, 0.0f, 1.0f);\n            }\n        }\n        return (p + _555) + (_561 * t);\n    }\n    float3 q = p;\n    float _624 = dot(r, axis);\n    bool _632;\n    if (_542)\n    {\n        _632 = abs(_624) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _632 = _542;\n    }\n    if (_632)\n    {\n        float _642 = dot(c - p, axis) / _624;\n        if (_642 > 0.0f)\n        {\n            q = p + (r * _642);\n        }\n    }\n    float3 _655 = q - c;\n    float2 xy = float2(dot(_655, ru), dot(_655, uu));\n    if (shape > 0.5f)\n    {\n        float _670 = length(xy);\n        if (_670 > hx)\n        {\n            xy *= (hx / _670);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _463 = abs(d);\n    float _465 = _463.x;\n    float _467 = _463.y;\n    bool _468 = _465 >= _467;\n    bool _476;\n    if (_468)\n    {\n        _476 = _465 >= _463.z;\n    }\n    else\n    {\n        _476 = _468;\n    }\n    int _477;\n    if (_476)\n    {\n        _477 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _490;\n        if (_467 >= _463.z)\n        {\n            _490 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _490 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _477 = _490;\n    }\n    return _477;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _416 = dot(d, right);\n    float _420 = dot(d, up);\n    float _431;\n    if (((_416 * _416) + (_420 * _420)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _431 = atan2(_420, _416) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _431 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_431 - floor(_431)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _708 = fa_light_base(param);\n    bool _712 = _314_fa_ambient.w > 4.5f;\n    int param_1 = _708;\n    float4 _716 = fa_light_texel(param_1);\n    int param_2 = _708 + 1;\n    float4 _721 = fa_light_texel(param_2);\n    float _724 = _721.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _736 = _712 && (_724 > 2.5f);\n    fa_light_is_area = _736;\n    bool _738 = _724 < 0.5f;\n    float3 l;\n    if (_738)\n    {\n        l = normalize(_716.xyz);\n        if (_712)\n        {\n            int param_3 = _708 + 6;\n            float4 _752 = fa_light_texel(param_3);\n            if (_752.z > 0.5f)\n            {\n                int param_4 = _708 + 4;\n                float4 _762 = fa_light_texel(param_4);\n                int param_5 = _708 + 5;\n                float4 _767 = fa_light_texel(param_5);\n                float2 param_6 = _752.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _762.xyz) * _762.w, (-dot(world_pos, _767.xyz)) * _767.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _797 = _716.xyz;\n        float3 _799 = _797 - world_pos;\n        float3 to_light = _799;\n        float _802 = length(_799);\n        float reach = _802;\n        bool front = true;\n        if (_736)\n        {\n            int param_8 = _708 + 7;\n            reach = max(_802 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _708 + 4;\n            float4 _826 = fa_light_texel(param_9);\n            int param_10 = _708 + 5;\n            float4 _831 = fa_light_texel(param_10);\n            int param_11 = _708 + 6;\n            float4 _836 = fa_light_texel(param_11);\n            float _837 = _836.w;\n            int param_12 = _708 + 2;\n            float3 _844 = normalize(fa_light_texel(param_12).xyz);\n            bool _846 = _837 > 1.5f;\n            bool _854;\n            if (!_846)\n            {\n                _854 = dot(_844, to_light) < 0.0f;\n            }\n            else\n            {\n                _854 = _846;\n            }\n            front = _854;\n            float3 r = 0.0f.xxx;\n            if (dot(n, n) > 0.5f)\n            {\n                r = reflect(-normalize(_314_fa_camera_pos.xyz - world_pos), normalize(n));\n            }\n            float3 param_13 = _797;\n            float3 param_14 = _844;\n            float3 param_15 = _826.xyz;\n            float3 param_16 = _831.xyz;\n            float param_17 = _826.w;\n            float param_18 = _831.w;\n            float param_19 = _837;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _901 = length(to_light);\n        dist = _901;\n        l = to_light / max(_901, 9.9999997473787516355514526367188e-05f).xxx;\n        float _915 = reach / max(_716.w, 0.001000000047497451305389404296875f);\n        float _921 = clamp(1.0f - (_915 * _915), 0.0f, 1.0f);\n        float _923;\n        if (front)\n        {\n            _923 = _921 * _921;\n        }\n        else\n        {\n            _923 = 0.0f;\n        }\n        atten = _923;\n        bool _934 = _724 < 2.5f;\n        if ((_724 > 1.5f) && _934)\n        {\n            int param_22 = _708 + 2;\n            float4 _942 = fa_light_texel(param_22);\n            float _952 = _942.w;\n            int param_23 = _708 + 3;\n            float4 _957 = fa_light_texel(param_23);\n            float _958 = _957.x;\n            float cos_inner = _958;\n            if (_958 > 1.5f)\n            {\n                cos_inner = lerp(_952, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_952, cos_inner, dot(-l, normalize(_942.xyz)));\n        }\n        if (_712 && (_724 < 1.5f))\n        {\n            int param_24 = _708 + 6;\n            float4 _982 = fa_light_texel(param_24);\n            if (_982.z > 0.5f)\n            {\n                float3 _990 = -to_light;\n                int param_25 = _708 + 4;\n                int param_26 = _708 + 5;\n                float3 _1004 = fa_light_texel(param_25).xyz;\n                float3 _1008 = fa_light_texel(param_26).xyz;\n                float3 _1017 = float3(dot(_990, _1004), dot(_990, _1008), dot(_990, cross(_1004, _1008)));\n                float3 param_27 = _1017;\n                int _1021 = fa_cube_face(param_27);\n                int param_28 = _1021;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1048 = float2(dot(_1017, cross(param_29, param_30)), dot(_1017, param_30)) / max(dot(_1017, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1052 = _1021 / 3;\n                float2 param_31 = _982.xy + (float2(float(_1021 - (_1052 * 3)), float(_1052)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1048.x), 0.5f - (0.5f * _1048.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _708 + 7;\n            float4 _1082 = fa_light_texel(param_33);\n            if (_1082.z > 0.5f)\n            {\n                int param_34 = _708 + 2;\n                int param_35 = _708 + 4;\n                int param_36 = _708 + 5;\n                float2 param_37 = _1082.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_712 && _934)\n            {\n                int param_42 = _708 + 6;\n                float4 _1129 = fa_light_texel(param_42);\n                int param_43 = _708 + 7;\n                float4 _1134 = fa_light_texel(param_43);\n                bool _1137 = _1129.z > 0.5f;\n                bool _1144;\n                if (!_1137)\n                {\n                    _1144 = _1134.z > 0.5f;\n                }\n                else\n                {\n                    _1144 = _1137;\n                }\n                if (_1144)\n                {\n                    int param_44 = _708 + 2;\n                    float4 _1151 = fa_light_texel(param_44);\n                    float3 _1155 = normalize(_1151.xyz);\n                    int param_45 = _708 + 4;\n                    float4 _1160 = fa_light_texel(param_45);\n                    int param_46 = _708 + 5;\n                    float4 _1165 = fa_light_texel(param_46);\n                    if (_1137)\n                    {\n                        float3 _1173 = -to_light;\n                        float _1180 = _1151.w;\n                        float _1196 = 0.5f / max(dot(_1173, _1155) * (sqrt(max(1.0f - (_1180 * _1180), 0.0f)) / max(_1180, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1129.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1173, _1160.xyz) * _1196), 0.5f - (dot(_1173, _1165.xyz) * _1196));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1134.z > 0.5f)\n                    {\n                        float2 param_49 = _1134.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1155;\n                        float3 param_52 = _1160.xyz;\n                        float3 param_53 = _1165.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4105 = _721.xyz * atten;\n    if (_712)\n    {\n        _4105 *= fa_light_tint;\n    }\n    int _1264;\n    if (_738)\n    {\n        _1264 = 0;\n    }\n    else\n    {\n        _1264 = ((_724 > 1.5f) && (_724 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _4116 = { l, _4105, atten, 1.0f, dist, _1264 };\n    return _4116;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2001;\n    if (i == 0)\n    {\n        _2001 = _2011_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2017;\n        if (i == 1)\n        {\n            _2017 = _2011_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2025;\n            if (i == 2)\n            {\n                _2025 = _2011_fa_shadow_split.z;\n            }\n            else\n            {\n                _2025 = _2011_fa_shadow_split.w;\n            }\n            _2017 = _2025;\n        }\n        _2001 = _2017;\n    }\n    return _2001;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2058 = fa_shadow_depth(param, param_1);\n    float _2062;\n    if (conv.x < 0.5f)\n    {\n        _2062 = _2058;\n    }\n    else\n    {\n        _2062 = (conv.y * conv.z) / (conv.z - (_2058 * (conv.z - conv.y)));\n    }\n    return _2062;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1989 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_1989), sin(_1989)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2108 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2117;\n        if (k < 0.0f)\n        {\n            _2117 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2117 = k;\n        }\n        float _2137 = clamp((_2117 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2108;\n            float2 _2156 = fa_shadow_vogel(param_3, param_4, param_5) * _2137;\n            float2 param_6 = uv + (_2156 * _2011_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2168 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2168 < (zr - (length(_2156) * plane)))\n            {\n                sum += _2168;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2194 = sum / cnt;\n        float _2204;\n        if (k < 0.0f)\n        {\n            _2204 = (-k) / max(_2194, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2204 = k;\n        }\n        radius = clamp(((max(zr - _2194, 0.0f) * unit) * _2204) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2226 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2226; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2226;\n        float param_11 = _2108;\n        float2 _2245 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2245 * _2011_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2245) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2226);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2287 = max(_2011_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2292 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2298 = sqrt(1.0f - (_2292 * _2292));\n    float _2305 = min(_2298 / max(_2292, 0.20000000298023223876953125f), 4.0f);\n    float _2310;\n    if (_2011_fa_shadow_bias.y > 0.0f)\n    {\n        _2310 = _2011_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2310 = 1.5f * _2011_fa_shadow_info[ci].x;\n    }\n    float4 _2335 = mul(float4(world + (n * (_2310 * _2298)), 1.0f), _2011_fa_shadow_mat[ci]);\n    float _2342 = _2335.x;\n    bool _2345 = _2342 < _2011_fa_shadow_rect[ci].x;\n    bool _2354;\n    if (!_2345)\n    {\n        _2354 = _2342 > _2011_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2354 = _2345;\n    }\n    bool _2363;\n    if (!_2354)\n    {\n        _2363 = _2335.y < _2011_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2363 = _2354;\n    }\n    bool _2372;\n    if (!_2363)\n    {\n        _2372 = _2335.y > _2011_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2372 = _2363;\n    }\n    bool _2379;\n    if (!_2372)\n    {\n        _2379 = _2335.z > 1.0f;\n    }\n    else\n    {\n        _2379 = _2372;\n    }\n    if (_2379)\n    {\n        return -1.0f;\n    }\n    float _2387;\n    if (_2011_fa_shadow_bias.x > 0.0f)\n    {\n        _2387 = _2011_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2387 = 1.5f * _2011_fa_shadow_info[ci].x;\n    }\n    float2 param = _2335.xy;\n    float4 param_1 = _2011_fa_shadow_rect[ci];\n    float param_2 = _2335.z - ((_2387 * (1.0f + (0.5f * _2305))) / _2287);\n    float param_3 = _2011_fa_shadow_info[ci].x;\n    float param_4 = _2287;\n    float param_5 = _2287 * 0.25f;\n    float param_6 = ((_2011_fa_shadow_info[ci].x * min(_2305, 3.0f)) * 0.5f) / _2287;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2011_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2011_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_314_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2775 = int(_2011_fa_shadow_cfg.x + 0.5f);\n    if (_2775 < 1)\n    {\n        return 1.0f;\n    }\n    float _2790 = dot(world - _2011_fa_shadow_eye.xyz, _2011_fa_shadow_fwd.xyz);\n    int param = _2775 - 1;\n    if (_2790 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2802 = _2775 > 1;\n    bool _2809;\n    if (_2802)\n    {\n        _2809 = _2790 > _2011_fa_shadow_split.x;\n    }\n    else\n    {\n        _2809 = _2802;\n    }\n    if (_2809)\n    {\n        ci = 1;\n    }\n    bool _2813 = _2775 > 2;\n    bool _2820;\n    if (_2813)\n    {\n        _2820 = _2790 > _2011_fa_shadow_split.y;\n    }\n    else\n    {\n        _2820 = _2813;\n    }\n    if (_2820)\n    {\n        ci = 2;\n    }\n    bool _2824 = _2775 > 3;\n    bool _2831;\n    if (_2824)\n    {\n        _2831 = _2790 > _2011_fa_shadow_split.z;\n    }\n    else\n    {\n        _2831 = _2824;\n    }\n    if (_2831)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2775)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2857 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2857;\n        if (_2857 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2011_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2882;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2882 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2882 = _2011_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2901 = _2011_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2882, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2912 = clamp((_2790 - (fa_shadow_split_at(param_7) - _2901)) / _2901, 0.0f, 1.0f);\n        if (_2912 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2775)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2933 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2933;\n                if (_2933 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2912);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _2445 = _314_fa_pbr.z < 0.5f;\n    bool _2452;\n    if (!_2445)\n    {\n        _2452 = _2011_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2452 = _2445;\n    }\n    if (_2452)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2011_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2465 = fa_light_texel(param);\n    float _2466 = _2465.x;\n    if (_2466 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2475 = int(_2466 + 0.5f);\n    int param_1 = _2475;\n    float4 _2479 = fa_light_texel(param_1);\n    int param_2 = _2475 + 1;\n    float4 _2484 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2487 = _2479.y;\n    if (_2487 > 0.0f)\n    {\n        float _2504 = 1.0f - smoothstep(0.75f * _2487, _2487, length(world - _2011_fa_shadow_eye.xyz));\n        fade = _2504;\n        if (_2504 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2479.x > 1.5f)\n    {\n        int param_3 = li;\n        int param_4 = fa_light_base(param_3);\n        float3 param_5 = world - fa_light_texel(param_4).xyz;\n        face = fa_cube_face(param_5);\n    }\n    int _2533 = (_2475 + 2) + (face * 6);\n    int param_6 = _2533;\n    int param_7 = _2533 + 1;\n    int param_8 = _2533 + 3;\n    float4 _2547 = fa_light_texel(param_8);\n    int param_9 = _2533 + 4;\n    float4 _2552 = fa_light_texel(param_9);\n    int param_10 = _2533 + 5;\n    float4 _2557 = fa_light_texel(param_10);\n    float _2569 = _2557.x * max(dot(_2547, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2574 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2597 = clamp(dot(n, _2547.xyz), -1.0f, 1.0f);\n    int param_11 = li;\n    int param_12 = fa_light_base(param_11);\n    float _2621 = min(sqrt(1.0f - (_2597 * _2597)) / max(abs(dot(n, world - fa_light_texel(param_12).xyz)) / max(dot(_2547, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2624 = _2484.y;\n    float _2626;\n    if (_2624 > 0.0f)\n    {\n        _2626 = _2624;\n    }\n    else\n    {\n        _2626 = 1.5f * _2569;\n    }\n    float4 _2646 = float4(world + (n * (_2626 * sqrt(1.0f - (_2574 * _2574)))), 1.0f);\n    float _2650 = dot(_2547, _2646);\n    float _2653 = _2557.y;\n    if (_2650 < _2653)\n    {\n        return 1.0f;\n    }\n    float2 _2668 = float2(dot(fa_light_texel(param_6), _2646), dot(fa_light_texel(param_7), _2646)) / _2650.xx;\n    float _2670 = _2668.x;\n    bool _2673 = _2670 < _2552.x;\n    bool _2682;\n    if (!_2673)\n    {\n        _2682 = _2670 > _2552.z;\n    }\n    else\n    {\n        _2682 = _2673;\n    }\n    bool _2691;\n    if (!_2682)\n    {\n        _2691 = _2668.y < _2552.y;\n    }\n    else\n    {\n        _2691 = _2682;\n    }\n    bool _2700;\n    if (!_2691)\n    {\n        _2700 = _2668.y > _2552.w;\n    }\n    else\n    {\n        _2700 = _2691;\n    }\n    if (_2700)\n    {\n        return 1.0f;\n    }\n    float _2706 = _2484.x;\n    float _2708;\n    if (_2706 > 0.0f)\n    {\n        _2708 = _2706;\n    }\n    else\n    {\n        _2708 = 1.5f * _2569;\n    }\n    float2 param_13 = _2668;\n    float4 param_14 = _2552;\n    float param_15 = _2650 - (_2708 * (1.0f + (0.5f * _2621)));\n    float param_16 = _2569;\n    float param_17 = 1.0f;\n    float param_18 = _2557.z * 0.25f;\n    float param_19 = (_2569 * min(_2621, 3.0f)) * 0.5f;\n    float3 param_20 = float3(1.0f, _2653, _2557.z);\n    int param_21 = int(_2479.z + 0.5f);\n    float param_22 = _2479.w;\n    return lerp(1.0f, fa_shadow_filter(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _3100 = fa_lm.z > 0.5f;\n    bool _3106;\n    if (_3100)\n    {\n        int param = li;\n        _3106 = fa_light_baked(param);\n    }\n    else\n    {\n        _3106 = _3100;\n    }\n    if (_3106)\n    {\n        int param_1 = li;\n        LightSample _4129 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _4129;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3130 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _4131 = _3130.color;\n    float _4133 = _3130.shadow;\n    if ((_3130.type == 0) && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3130.direction;\n        float _3144 = fa_shadow_factor(param_5, param_6);\n        _4133 = _3144;\n        _4131 *= _3144;\n    }\n    else\n    {\n        bool _3155 = _3130.type != 0;\n        bool _3161;\n        if (_3155)\n        {\n            _3161 = _3130.attenuation > 0.0f;\n        }\n        else\n        {\n            _3161 = _3155;\n        }\n        if (_3161)\n        {\n            int param_7 = li;\n            float3 param_8 = world_pos;\n            float3 param_9 = gn;\n            float3 param_10 = _3130.direction;\n            float _3173 = fa_shadow_local(param_7, param_8, param_9, param_10);\n            _4133 = _3173;\n            _4131 *= _3173;\n        }\n    }\n    LightSample _4148 = { _3130.direction, _4131, _3130.attenuation, _4133, _3130._distance, _3130.type };\n    return _4148;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2011_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _2957 = int(_2011_fa_shadow_cfg.x + 0.5f);\n    float _2967 = dot(world - _2011_fa_shadow_eye.xyz, _2011_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _2972 = _2957 > 0;\n    bool _2981;\n    if (_2972)\n    {\n        int param = _2957 - 1;\n        _2981 = _2967 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2981 = _2972;\n    }\n    if (_2981)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _2987 = _2957 > 1;\n        bool _2994;\n        if (_2987)\n        {\n            _2994 = _2967 > _2011_fa_shadow_split.x;\n        }\n        else\n        {\n            _2994 = _2987;\n        }\n        if (_2994)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3000 = _2957 > 2;\n        bool _3007;\n        if (_3000)\n        {\n            _3007 = _2967 > _2011_fa_shadow_split.y;\n        }\n        else\n        {\n            _3007 = _3000;\n        }\n        if (_3007)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3013 = _2957 > 3;\n        bool _3020;\n        if (_3013)\n        {\n            _3020 = _2967 > _2011_fa_shadow_split.z;\n        }\n        else\n        {\n            _3020 = _3013;\n        }\n        if (_3020)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _3972 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3972 = -_3972;\n    }\n    float3 _3556 = normalize(_314_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _3985 = { fa_world_pos, _3972, fa_world_tangent, fa_uv, fa_vertex_color, _3556, gl_FrontFacing };\n    SurfaceInput param_1 = _3985;\n    Surface _3564 = fa_standard_surface(param_1);\n    float3 _4003 = _3564.albedo;\n    float _4004 = _3564.alpha;\n    float3 _4005 = _3564.normal;\n    float _4006 = _3564.metallic;\n    float _4007 = _3564.roughness;\n    float _4008 = _3564.occlusion;\n    float3 _4009 = _3564.emission;\n    float _4010 = _3564.clearcoat;\n    float _4011 = _3564.clearcoat_roughness;\n    float3 _4012 = _3564.sheen_color;\n    float _4013 = _3564.sheen_roughness;\n    float _4014 = _3564.anisotropy;\n    float _4015 = _3564.anisotropy_rotation;\n    float _4016 = _3564.specular;\n    float _4017 = _3564.ior;\n    float3 _4018 = _3564.specular_color;\n    SurfaceInput _3993 = { fa_world_pos, _3972, fa_world_tangent, fa_uv, fa_vertex_color, _3556, gl_FrontFacing };\n    SurfaceInput param_2 = _3993;\n    Surface param_3 = _3564;\n    surface(param_2, param_3);\n    _4003 = param_3.albedo;\n    _4004 = param_3.alpha;\n    _4005 = param_3.normal;\n    _4006 = param_3.metallic;\n    _4007 = param_3.roughness;\n    _4008 = param_3.occlusion;\n    _4009 = param_3.emission;\n    _4010 = param_3.clearcoat;\n    _4011 = param_3.clearcoat_roughness;\n    _4012 = param_3.sheen_color;\n    _4013 = param_3.sheen_roughness;\n    _4014 = param_3.anisotropy;\n    _4015 = param_3.anisotropy_rotation;\n    _4016 = param_3.specular;\n    _4017 = param_3.ior;\n    _4018 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _3972;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4003 = param_6;\n    _4005 = param_7;\n    float3 result;\n    if (_314_fa_emissive.w > 0.5f)\n    {\n        result = _4003;\n    }\n    else\n    {\n        float3 _3602 = _4005;\n        float3 _3603 = normalize(_3602);\n        _4005 = _3603;\n        float3 param_8 = _3603;\n        float3 lit = (fa_indirect_diffuse(param_8) * _4003) * _4008;\n        int _3622 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3622; ln++)\n        {\n            int param_9 = ln;\n            int _3635 = fa_cl_light(param_9);\n            bool _3638 = fa_lm.z > 0.5f;\n            bool _3644;\n            if (_3638)\n            {\n                int param_10 = _3635;\n                _3644 = fa_light_baked(param_10);\n            }\n            else\n            {\n                _3644 = _3638;\n            }\n            if (_3644)\n            {\n                continue;\n            }\n            int param_11 = _3635;\n            float3 param_12 = fa_world_pos;\n            float3 param_13 = _3972;\n            LightSample _3656 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput _4001 = { fa_world_pos, _3972, fa_world_tangent, fa_uv, fa_vertex_color, _3556, gl_FrontFacing };\n            SurfaceInput param_14 = _4001;\n            Surface _4084 = { _4003, _4004, _4005, _4006, _4007, _4008, _4009, _4010, _4011, _4012, _4013, _4014, _4015, _4016, _4017, _4018 };\n            Surface param_15 = _4084;\n            LightSample param_16 = _3656;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    float3 _3671 = result;\n    float3 _3672 = _3671 + _4009;\n    result = _3672;\n    float3 param_17 = _3672;\n    float3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _3681 = _314_fa_fog.w > 0.0f;\n    bool _3688;\n    if (!_3681)\n    {\n        _3688 = _314_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _3688 = _3681;\n    }\n    if (_3688)\n    {\n        float3 _3697 = fa_world_pos - _314_fa_camera_pos.xyz;\n        float _3703 = dot(_3697, _314_fa_fog_c.xyz);\n        bool _3707 = _314_fa_fog_c.w > 0.5f;\n        float _3708;\n        if (_3707)\n        {\n            _3708 = _3703;\n        }\n        else\n        {\n            _3708 = length(_3697);\n        }\n        float _3720 = _3708 - _314_fa_fog_b.x;\n        if (_3720 > 0.0f)\n        {\n            float _3729 = _314_fa_fog.w * _3720;\n            float tau = _3729 * _3729;\n            if (_314_fa_fog_b.y > 0.0f)\n            {\n                float _3745;\n                if (_3707)\n                {\n                    _3745 = fa_world_pos.y - (_314_fa_fog_c.y * _3703);\n                }\n                else\n                {\n                    _3745 = _314_fa_camera_pos.y;\n                }\n                float _3766 = lerp(_3745, fa_world_pos.y, clamp(_314_fa_fog_b.x / _3708, 0.0f, 1.0f));\n                float _3770 = fa_world_pos.y - _3766;\n                float _3775 = _3766 - _314_fa_fog_b.z;\n                float _3780 = fa_world_pos.y - _314_fa_fog_b.z;\n                bool _3783 = _3775 <= 0.0f;\n                bool _3784 = !_3783;\n                bool _3790;\n                if (_3784)\n                {\n                    _3790 = _314_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3790 = _3783;\n                }\n                float _3791;\n                if (_3790)\n                {\n                    _3791 = _314_fa_fog_b.y;\n                }\n                else\n                {\n                    _3791 = _314_fa_fog_b.y * exp(-min(_314_fa_fog_b.w * _3775, 80.0f));\n                }\n                bool _3818;\n                if (_3784)\n                {\n                    _3818 = _314_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3818 = _3783;\n                }\n                float _3819;\n                if (_3818)\n                {\n                    _3819 = _314_fa_fog_b.y * _3775;\n                }\n                else\n                {\n                    _3819 = (_314_fa_fog_b.y * (1.0f - exp(-min(_314_fa_fog_b.w * _3775, 80.0f)))) / _314_fa_fog_b.w;\n                }\n                bool _3844 = _3780 <= 0.0f;\n                bool _3851;\n                if (!_3844)\n                {\n                    _3851 = _314_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3851 = _3844;\n                }\n                float _3852;\n                if (_3851)\n                {\n                    _3852 = _314_fa_fog_b.y * _3780;\n                }\n                else\n                {\n                    _3852 = (_314_fa_fog_b.y * (1.0f - exp(-min(_314_fa_fog_b.w * _3780, 80.0f)))) / _314_fa_fog_b.w;\n                }\n                float _3879;\n                if (abs(_3770) < 0.001000000047497451305389404296875f)\n                {\n                    _3879 = _3791;\n                }\n                else\n                {\n                    _3879 = (_3852 - _3819) / _3770;\n                }\n                tau += (_3720 * max(_3879, 0.0f));\n            }\n            result = lerp(result, _314_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4004);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_314",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2011",
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
