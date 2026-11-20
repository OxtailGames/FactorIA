{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "fc5698cd941e0af057040ef4c307a7106b1e2971cc74f7501935817daedb7ce8",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _260 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _260;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_267, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _314_fa_camera_pos : packoffset(c0);\n    float4 _314_fa_ambient : packoffset(c1);\n    float4 _314_fa_base_color : packoffset(c2);\n    float4 _314_fa_emissive : packoffset(c3);\n    float4 _314_fa_model_emissive : packoffset(c4);\n    float4 _314_fa_pbr : packoffset(c5);\n    float4 _314_fa_maps : packoffset(c6);\n    float4 _314_fa_fog : packoffset(c7);\n    float4 _314_fa_fog_b : packoffset(c8);\n    float4 _314_fa_fog_c : packoffset(c9);\n    float4 _314_fa_counts : packoffset(c10);\n    float4 _314_fa_env_sky : packoffset(c11);\n    float4 _314_fa_env_horizon : packoffset(c12);\n    float4 _314_fa_time : packoffset(c13);\n    float4 _314_fa_cl_vpx : packoffset(c14);\n    float4 _314_fa_cl_vpy : packoffset(c15);\n    float4 _314_fa_cl_vpw : packoffset(c16);\n    float4 _314_fa_cl_fwd : packoffset(c17);\n    float4 _314_fa_cl_grid : packoffset(c18);\n    float4 _314_fa_cl_info : packoffset(c19);\n    float4 _314_fa_layers_a : packoffset(c20);\n    float4 _314_fa_layers_b : packoffset(c21);\n    float4 _314_fa_layers_c : packoffset(c22);\n    float4 _314_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2021_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2021_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2021_fa_shadow_info[4] : packoffset(c20);\n    float4 _2021_fa_shadow_split : packoffset(c24);\n    float4 _2021_fa_shadow_cfg : packoffset(c25);\n    float4 _2021_fa_shadow_bias : packoffset(c26);\n    float4 _2021_fa_shadow_eye : packoffset(c27);\n    float4 _2021_fa_shadow_fwd : packoffset(c28);\n    float4 _2021_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_irr_tex : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1292 = _314_fa_cl_info.x < 0.0f;\n    bool _1299;\n    if (!_1292)\n    {\n        _1299 = _314_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1299 = _1292;\n    }\n    bool _1307;\n    if (!_1299)\n    {\n        _1307 = _314_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1307 = _1299;\n    }\n    bool _1314;\n    if (!_1307)\n    {\n        _1314 = _314_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1314 = _1307;\n    }\n    bool _1321;\n    if (!_1314)\n    {\n        _1321 = _314_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1321 = _1314;\n    }\n    if (_1321)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1331 = float4(world_pos, 1.0f);\n    float _1337 = dot(_314_fa_cl_vpw, _1331);\n    if (!(_1337 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1359 = float2(dot(_314_fa_cl_vpx, _1331), dot(_314_fa_cl_vpy, _1331)) / _1337.xx;\n    int _1363 = int(_314_fa_cl_grid.x);\n    int _1367 = int(_314_fa_cl_grid.y);\n    int param = (int(_314_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_314_fa_cl_fwd.xyz, world_pos) + _314_fa_cl_fwd.w, _314_fa_cl_grid.w) / _314_fa_cl_grid.w) * _314_fa_cl_grid.z)), 0, int(_314_fa_cl_info.y) - 1) * _1367) + clamp(int(floor(((_1359.y * 0.5f) + 0.5f) * _314_fa_cl_grid.y)), 0, _1367 - 1)) * _1363)) + clamp(int(floor(((_1359.x * 0.5f) + 0.5f) * _314_fa_cl_grid.x)), 0, _1363 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1443 = fa_cluster_texel(param);\n    return int2(int(_1443.x), int(_1443.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_314_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3083 = fa_cluster_lookup(param);\n    fa_cl_slot = _3083.x;\n    fa_cl_local = _3083.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _3232 = fa_linear_to_srgb(param);\n        c = _3232;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _3240 = fa_srgb_to_linear(param_1);\n            c = _3240;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _246;\n    if (i.front_facing)\n    {\n        _246 = i.world_normal;\n    }\n    else\n    {\n        _246 = -i.world_normal;\n    }\n    float3 _270 = normalize(i.world_tangent.xyz - (_246 * dot(_246, i.world_tangent.xyz)));\n    float3 _298 = normalize(((_270 * m.x) + ((cross(_246, _270) * i.world_tangent.w) * m.y)) + (_246 * m.z));\n    float3 _301;\n    if (i.front_facing)\n    {\n        _301 = _298;\n    }\n    else\n    {\n        _301 = -_298;\n    }\n    return _301;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _314_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3271 = fa_tex_fix(param_2, param_3);\n    float4 _4296 = base_t;\n    _4296.x = _3271.x;\n    _4296.y = _3271.y;\n    _4296.z = _3271.z;\n    base_t = _4296;\n    float4 _3285 = (_4296 * _314_fa_base_color) * i.vertex_color;\n    float3 _4161 = i.world_normal;\n    if (_314_fa_maps.z > 0.5f)\n    {\n        float param_4 = _314_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3317 = fa_tex_fix(param_6, param_7);\n        float3 _3320 = (_3317 * 2.0f) - 1.0f.xxx;\n        float2 _3325 = _3320.xy * _314_fa_maps.x;\n        float3 _4304 = _3320;\n        _4304.x = _3325.x;\n        _4304.y = _3325.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4304;\n        _4161 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _314_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3353 = fa_tex_fix(param_12, param_13);\n    float4 _4307 = mrt;\n    _4307.x = _3353.x;\n    _4307.y = _3353.y;\n    _4307.z = _3353.z;\n    mrt = _4307;\n    float4 _3381 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _314_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _3381.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3392 = fa_tex_fix(param_16, param_17);\n    float param_18 = _314_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3422 = fa_tex_fix(param_20, param_21);\n    float _4166 = _314_fa_layers_a.x;\n    float _4167 = _314_fa_layers_a.y;\n    float _4170 = _314_fa_layers_a.z;\n    float _4169 = _314_fa_layers_b.w;\n    float _4172 = _314_fa_layers_c.x;\n    if (_314_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_314_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _4166 *= _3392.y;\n            _4167 *= _3392.z;\n            _4169 *= _3381.w;\n        }\n        if (_314_fa_layers_c.z > 1.5f)\n        {\n            _4170 *= mrt.x;\n            _4172 *= mrt.w;\n        }\n    }\n    Surface _4191 = { _3285.xyz, _3285.w, _4161, clamp(_314_fa_pbr.x * _3353.z, 0.0f, 1.0f), clamp(_314_fa_pbr.y * _3353.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_314_fa_maps.y * (_3392.x - 1.0f)), _314_fa_emissive.xyz + (_314_fa_model_emissive.xyz * _3422), _4166, _4167, _314_fa_layers_b.xyz, _4169, _4170, _314_fa_layers_a.w, _4172, _314_fa_layers_c.y, _314_fa_layers_d.xyz };\n    return _4191;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1523 = rect.zw - rect.xy;\n    float2 _1527 = _1523 * atlas;\n    float2 _1531 = ddx * _1527;\n    float2 _1535 = ddy * _1527;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1523), clamp(0.5f * log2(max(max(dot(_1531, _1531), dot(_1535, _1535)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1568 = _314_fa_counts.y < 0.5f;\n    bool _1575;\n    if (!_1568)\n    {\n        _1575 = _314_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1575 = _1568;\n    }\n    if (_1575)\n    {\n        return;\n    }\n    float3 _1581 = ddx(world_pos);\n    float3 _1584 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1588 = fa_cluster_texel(param);\n    int _1592 = int(_1588.w);\n    if (_1592 < 1)\n    {\n        return;\n    }\n    int _1602 = int(_314_fa_counts.y + 0.5f);\n    int param_1 = _1602;\n    float4 _1606 = fa_light_texel(param_1);\n    float2 _1609 = _1606.yz;\n    int _1613 = int(_1606.w);\n    int param_2 = _1602 + 1;\n    float4 _1618 = fa_light_texel(param_2);\n    float _1619 = _1618.x;\n    int _1625 = int(_314_fa_counts.w + 0.5f) - 1;\n    int _1629 = int(_1588.z);\n    float3 _1894;\n    for (int k = 0; k < _1592; k++)\n    {\n        int _1642 = _1629 + k;\n        int param_3 = _1613 + (_1642 >> 2);\n        int _1659 = (_1602 + 2) + (int(fa_light_texel(param_3)[_1642 & 3]) * 7);\n        int param_4 = _1659 + 6;\n        float4 _1664 = fa_light_texel(param_4);\n        if (((int(_1664.w + 0.5f) >> _1625) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1659;\n        float4 _1679 = fa_light_texel(param_5);\n        int param_6 = _1659 + 1;\n        float4 _1684 = fa_light_texel(param_6);\n        int param_7 = _1659 + 2;\n        float4 _1689 = fa_light_texel(param_7);\n        float3 _1692 = _1679.xyz;\n        float _1697 = dot(_1692, world_pos) + _1679.w;\n        float3 _1699 = _1684.xyz;\n        float _1704 = dot(_1699, world_pos) + _1684.w;\n        float3 _1706 = _1689.xyz;\n        float _1711 = dot(_1706, world_pos) + _1689.w;\n        bool _1716 = abs(_1697) > 0.5f;\n        bool _1724;\n        if (!_1716)\n        {\n            _1724 = abs(_1704) > 0.5f;\n        }\n        else\n        {\n            _1724 = _1716;\n        }\n        bool _1732;\n        if (!_1724)\n        {\n            _1732 = abs(_1711) > 0.5f;\n        }\n        else\n        {\n            _1732 = _1724;\n        }\n        if (_1732)\n        {\n            continue;\n        }\n        float _1747 = clamp(dot(geo_normal, normalize(_1706)) * _1664.z, 0.0f, 1.0f);\n        if (_1747 <= 0.0f)\n        {\n            continue;\n        }\n        float _1767 = (clamp((0.5f - abs(_1711)) * 10.0f, 0.0f, 1.0f) * _1747) * _1664.x;\n        float2 _1775 = float2(_1697 + 0.5f, 0.5f - _1704);\n        float2 _1785 = float2(dot(_1692, _1581), dot(_1699, _1581));\n        float2 _1795 = float2(dot(_1692, _1584), dot(_1699, _1584));\n        int param_8 = _1659 + 5;\n        float4 _1800 = fa_light_texel(param_8);\n        int param_9 = _1659 + 3;\n        float4 _1805 = fa_light_texel(param_9);\n        int param_10 = _1659 + 4;\n        float4 _1810 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1800.xyz;\n        bool _1820 = _1805.z > _1805.x;\n        if (_1820)\n        {\n            float4 param_11 = _1805;\n            float2 param_12 = _1775;\n            float2 param_13 = _1609;\n            float2 param_14 = _1785;\n            float2 param_15 = _1795;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1619 > 0.5f) && (_1619 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1846 = fa_dc_to_linear(param_16);\n                float4 _4241 = tx;\n                _4241.x = _1846.x;\n                _4241.y = _1846.y;\n                _4241.z = _1846.z;\n                tx = _4241;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1767 * tex_a) * _1800.w, 0.0f, 1.0f).xxx);\n        if (_1810.z > _1810.x)\n        {\n            float4 param_17 = _1810;\n            float2 param_18 = _1775;\n            float2 param_19 = _1609;\n            float2 param_20 = _1785;\n            float2 param_21 = _1795;\n            float4 _1890 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1619 > 1.5f)\n            {\n                float3 param_22 = _1890.xyz;\n                float3 _1900 = fa_dc_to_srgb(param_22);\n                _1894 = _1900;\n            }\n            else\n            {\n                _1894 = _1890.xyz;\n            }\n            float3 _1909 = (_1894 * 2.0f) - 1.0f.xxx;\n            float2 _1914 = _1909.xy * _1664.y;\n            float3 _1936 = (normalize(_1692) * _1914.x) + (normalize(_1699) * _1914.y);\n            float3 _1939 = normalize(normal);\n            normal = normalize(lerp(_1939, normalize((_1939 * max(_1909.z, 0.0500000007450580596923828125f)) + (_1936 - (_1939 * dot(_1939, _1936)))), clamp(_1767 * (_1820 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_314_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _314_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_314_fa_cl_info.x) + int(_314_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_314_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _376_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _376_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _542 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _555 = (c - (ru * hx)) - p;\n        float3 _561 = ru * (2.0f * hx);\n        float _567 = max(dot(_561, _561), 9.9999999392252902907785028219223e-09f);\n        float _571 = dot(_555, _561);\n        float t = clamp((-_571) / _567, 0.0f, 1.0f);\n        if (_542)\n        {\n            float _586 = dot(r, _561);\n            float _592 = _567 - (_586 * _586);\n            if (abs(_592) > (9.9999997473787516355514526367188e-06f * _567))\n            {\n                t = clamp(((dot(r, _555) * _586) - _571) / _592, 0.0f, 1.0f);\n            }\n        }\n        return (p + _555) + (_561 * t);\n    }\n    float3 q = p;\n    float _624 = dot(r, axis);\n    bool _632;\n    if (_542)\n    {\n        _632 = abs(_624) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _632 = _542;\n    }\n    if (_632)\n    {\n        float _642 = dot(c - p, axis) / _624;\n        if (_642 > 0.0f)\n        {\n            q = p + (r * _642);\n        }\n    }\n    float3 _655 = q - c;\n    float2 xy = float2(dot(_655, ru), dot(_655, uu));\n    if (shape > 0.5f)\n    {\n        float _670 = length(xy);\n        if (_670 > hx)\n        {\n            xy *= (hx / _670);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _463 = abs(d);\n    float _465 = _463.x;\n    float _467 = _463.y;\n    bool _468 = _465 >= _467;\n    bool _476;\n    if (_468)\n    {\n        _476 = _465 >= _463.z;\n    }\n    else\n    {\n        _476 = _468;\n    }\n    int _477;\n    if (_476)\n    {\n        _477 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _490;\n        if (_467 >= _463.z)\n        {\n            _490 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _490 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _477 = _490;\n    }\n    return _477;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _416 = dot(d, right);\n    float _420 = dot(d, up);\n    float _431;\n    if (((_416 * _416) + (_420 * _420)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _431 = atan2(_420, _416) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _431 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_431 - floor(_431)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _708 = fa_light_base(param);\n    bool _712 = _314_fa_ambient.w > 4.5f;\n    int param_1 = _708;\n    float4 _716 = fa_light_texel(param_1);\n    int param_2 = _708 + 1;\n    float4 _721 = fa_light_texel(param_2);\n    float _724 = _721.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _736 = _712 && (_724 > 2.5f);\n    fa_light_is_area = _736;\n    bool _738 = _724 < 0.5f;\n    float3 l;\n    if (_738)\n    {\n        l = normalize(_716.xyz);\n        if (_712)\n        {\n            int param_3 = _708 + 6;\n            float4 _752 = fa_light_texel(param_3);\n            if (_752.z > 0.5f)\n            {\n                int param_4 = _708 + 4;\n                float4 _762 = fa_light_texel(param_4);\n                int param_5 = _708 + 5;\n                float4 _767 = fa_light_texel(param_5);\n                float2 param_6 = _752.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _762.xyz) * _762.w, (-dot(world_pos, _767.xyz)) * _767.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _797 = _716.xyz;\n        float3 _799 = _797 - world_pos;\n        float3 to_light = _799;\n        float _802 = length(_799);\n        float reach = _802;\n        bool front = true;\n        if (_736)\n        {\n            int param_8 = _708 + 7;\n            reach = max(_802 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _708 + 4;\n            float4 _826 = fa_light_texel(param_9);\n            int param_10 = _708 + 5;\n            float4 _831 = fa_light_texel(param_10);\n            int param_11 = _708 + 6;\n            float4 _836 = fa_light_texel(param_11);\n            float _837 = _836.w;\n            int param_12 = _708 + 2;\n            float3 _844 = normalize(fa_light_texel(param_12).xyz);\n            bool _846 = _837 > 1.5f;\n            bool _854;\n            if (!_846)\n            {\n                _854 = dot(_844, to_light) < 0.0f;\n            }\n            else\n            {\n                _854 = _846;\n            }\n            front = _854;\n            float3 r = 0.0f.xxx;\n            float3 _863 = _314_fa_camera_pos.xyz - world_pos;\n            bool _867 = dot(n, n) > 0.5f;\n            bool _875;\n            if (_867)\n            {\n                _875 = dot(_863, _863) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _875 = _867;\n            }\n            if (_875)\n            {\n                r = reflect(-normalize(_863), normalize(n));\n            }\n            float3 param_13 = _797;\n            float3 param_14 = _844;\n            float3 param_15 = _826.xyz;\n            float3 param_16 = _831.xyz;\n            float param_17 = _826.w;\n            float param_18 = _831.w;\n            float param_19 = _837;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _911 = length(to_light);\n        dist = _911;\n        l = to_light / max(_911, 9.9999997473787516355514526367188e-05f).xxx;\n        float _925 = reach / max(_716.w, 0.001000000047497451305389404296875f);\n        float _931 = clamp(1.0f - (_925 * _925), 0.0f, 1.0f);\n        float _933;\n        if (front)\n        {\n            _933 = _931 * _931;\n        }\n        else\n        {\n            _933 = 0.0f;\n        }\n        atten = _933;\n        bool _944 = _724 < 2.5f;\n        if ((_724 > 1.5f) && _944)\n        {\n            int param_22 = _708 + 2;\n            float4 _952 = fa_light_texel(param_22);\n            float _962 = _952.w;\n            int param_23 = _708 + 3;\n            float4 _967 = fa_light_texel(param_23);\n            float _968 = _967.x;\n            float cos_inner = _968;\n            if (_968 > 1.5f)\n            {\n                cos_inner = lerp(_962, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_962, cos_inner, dot(-l, normalize(_952.xyz)));\n        }\n        if (_712 && (_724 < 1.5f))\n        {\n            int param_24 = _708 + 6;\n            float4 _992 = fa_light_texel(param_24);\n            if (_992.z > 0.5f)\n            {\n                float3 _1000 = -to_light;\n                int param_25 = _708 + 4;\n                int param_26 = _708 + 5;\n                float3 _1014 = fa_light_texel(param_25).xyz;\n                float3 _1018 = fa_light_texel(param_26).xyz;\n                float3 _1027 = float3(dot(_1000, _1014), dot(_1000, _1018), dot(_1000, cross(_1014, _1018)));\n                float3 param_27 = _1027;\n                int _1031 = fa_cube_face(param_27);\n                int param_28 = _1031;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1058 = float2(dot(_1027, cross(param_29, param_30)), dot(_1027, param_30)) / max(dot(_1027, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1062 = _1031 / 3;\n                float2 param_31 = _992.xy + (float2(float(_1031 - (_1062 * 3)), float(_1062)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1058.x), 0.5f - (0.5f * _1058.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _708 + 7;\n            float4 _1092 = fa_light_texel(param_33);\n            if (_1092.z > 0.5f)\n            {\n                int param_34 = _708 + 2;\n                int param_35 = _708 + 4;\n                int param_36 = _708 + 5;\n                float2 param_37 = _1092.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_712 && _944)\n            {\n                int param_42 = _708 + 6;\n                float4 _1139 = fa_light_texel(param_42);\n                int param_43 = _708 + 7;\n                float4 _1144 = fa_light_texel(param_43);\n                bool _1147 = _1139.z > 0.5f;\n                bool _1154;\n                if (!_1147)\n                {\n                    _1154 = _1144.z > 0.5f;\n                }\n                else\n                {\n                    _1154 = _1147;\n                }\n                if (_1154)\n                {\n                    int param_44 = _708 + 2;\n                    float4 _1161 = fa_light_texel(param_44);\n                    float3 _1165 = normalize(_1161.xyz);\n                    int param_45 = _708 + 4;\n                    float4 _1170 = fa_light_texel(param_45);\n                    int param_46 = _708 + 5;\n                    float4 _1175 = fa_light_texel(param_46);\n                    if (_1147)\n                    {\n                        float3 _1183 = -to_light;\n                        float _1190 = _1161.w;\n                        float _1206 = 0.5f / max(dot(_1183, _1165) * (sqrt(max(1.0f - (_1190 * _1190), 0.0f)) / max(_1190, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1139.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1183, _1170.xyz) * _1206), 0.5f - (dot(_1183, _1175.xyz) * _1206));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1144.z > 0.5f)\n                    {\n                        float2 param_49 = _1144.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1165;\n                        float3 param_52 = _1170.xyz;\n                        float3 param_53 = _1175.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4115 = _721.xyz * atten;\n    if (_712)\n    {\n        _4115 *= fa_light_tint;\n    }\n    int _1274;\n    if (_738)\n    {\n        _1274 = 0;\n    }\n    else\n    {\n        _1274 = ((_724 > 1.5f) && (_724 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _4126 = { l, _4115, atten, 1.0f, dist, _1274 };\n    return _4126;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2011;\n    if (i == 0)\n    {\n        _2011 = _2021_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2027;\n        if (i == 1)\n        {\n            _2027 = _2021_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2035;\n            if (i == 2)\n            {\n                _2035 = _2021_fa_shadow_split.z;\n            }\n            else\n            {\n                _2035 = _2021_fa_shadow_split.w;\n            }\n            _2027 = _2035;\n        }\n        _2011 = _2027;\n    }\n    return _2011;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2068 = fa_shadow_depth(param, param_1);\n    float _2072;\n    if (conv.x < 0.5f)\n    {\n        _2072 = _2068;\n    }\n    else\n    {\n        _2072 = (conv.y * conv.z) / (conv.z - (_2068 * (conv.z - conv.y)));\n    }\n    return _2072;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1999 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_1999), sin(_1999)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2118 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2127;\n        if (k < 0.0f)\n        {\n            _2127 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2127 = k;\n        }\n        float _2147 = clamp((_2127 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2118;\n            float2 _2166 = fa_shadow_vogel(param_3, param_4, param_5) * _2147;\n            float2 param_6 = uv + (_2166 * _2021_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2178 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2178 < (zr - (length(_2166) * plane)))\n            {\n                sum += _2178;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2204 = sum / cnt;\n        float _2214;\n        if (k < 0.0f)\n        {\n            _2214 = (-k) / max(_2204, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2214 = k;\n        }\n        radius = clamp(((max(zr - _2204, 0.0f) * unit) * _2214) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2236 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2236; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2236;\n        float param_11 = _2118;\n        float2 _2255 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2255 * _2021_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2255) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2236);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2297 = max(_2021_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2302 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2308 = sqrt(1.0f - (_2302 * _2302));\n    float _2315 = min(_2308 / max(_2302, 0.20000000298023223876953125f), 4.0f);\n    float _2320;\n    if (_2021_fa_shadow_bias.y > 0.0f)\n    {\n        _2320 = _2021_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2320 = 1.5f * _2021_fa_shadow_info[ci].x;\n    }\n    float4 _2345 = mul(float4(world + (n * (_2320 * _2308)), 1.0f), _2021_fa_shadow_mat[ci]);\n    float _2352 = _2345.x;\n    bool _2355 = _2352 < _2021_fa_shadow_rect[ci].x;\n    bool _2364;\n    if (!_2355)\n    {\n        _2364 = _2352 > _2021_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2364 = _2355;\n    }\n    bool _2373;\n    if (!_2364)\n    {\n        _2373 = _2345.y < _2021_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2373 = _2364;\n    }\n    bool _2382;\n    if (!_2373)\n    {\n        _2382 = _2345.y > _2021_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2382 = _2373;\n    }\n    bool _2389;\n    if (!_2382)\n    {\n        _2389 = _2345.z > 1.0f;\n    }\n    else\n    {\n        _2389 = _2382;\n    }\n    if (_2389)\n    {\n        return -1.0f;\n    }\n    float _2397;\n    if (_2021_fa_shadow_bias.x > 0.0f)\n    {\n        _2397 = _2021_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2397 = 1.5f * _2021_fa_shadow_info[ci].x;\n    }\n    float2 param = _2345.xy;\n    float4 param_1 = _2021_fa_shadow_rect[ci];\n    float param_2 = _2345.z - ((_2397 * (1.0f + (0.5f * _2315))) / _2297);\n    float param_3 = _2021_fa_shadow_info[ci].x;\n    float param_4 = _2297;\n    float param_5 = _2297 * 0.25f;\n    float param_6 = ((_2021_fa_shadow_info[ci].x * min(_2315, 3.0f)) * 0.5f) / _2297;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2021_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2021_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_314_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2785 = int(_2021_fa_shadow_cfg.x + 0.5f);\n    if (_2785 < 1)\n    {\n        return 1.0f;\n    }\n    float _2800 = dot(world - _2021_fa_shadow_eye.xyz, _2021_fa_shadow_fwd.xyz);\n    int param = _2785 - 1;\n    if (_2800 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2812 = _2785 > 1;\n    bool _2819;\n    if (_2812)\n    {\n        _2819 = _2800 > _2021_fa_shadow_split.x;\n    }\n    else\n    {\n        _2819 = _2812;\n    }\n    if (_2819)\n    {\n        ci = 1;\n    }\n    bool _2823 = _2785 > 2;\n    bool _2830;\n    if (_2823)\n    {\n        _2830 = _2800 > _2021_fa_shadow_split.y;\n    }\n    else\n    {\n        _2830 = _2823;\n    }\n    if (_2830)\n    {\n        ci = 2;\n    }\n    bool _2834 = _2785 > 3;\n    bool _2841;\n    if (_2834)\n    {\n        _2841 = _2800 > _2021_fa_shadow_split.z;\n    }\n    else\n    {\n        _2841 = _2834;\n    }\n    if (_2841)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2785)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2867 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2867;\n        if (_2867 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2021_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2892;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2892 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2892 = _2021_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2911 = _2021_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2892, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2922 = clamp((_2800 - (fa_shadow_split_at(param_7) - _2911)) / _2911, 0.0f, 1.0f);\n        if (_2922 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2785)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2943 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2943;\n                if (_2943 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2922);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _2455 = _314_fa_pbr.z < 0.5f;\n    bool _2462;\n    if (!_2455)\n    {\n        _2462 = _2021_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2462 = _2455;\n    }\n    if (_2462)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2021_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2475 = fa_light_texel(param);\n    float _2476 = _2475.x;\n    if (_2476 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2485 = int(_2476 + 0.5f);\n    int param_1 = _2485;\n    float4 _2489 = fa_light_texel(param_1);\n    int param_2 = _2485 + 1;\n    float4 _2494 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2497 = _2489.y;\n    if (_2497 > 0.0f)\n    {\n        float _2514 = 1.0f - smoothstep(0.75f * _2497, _2497, length(world - _2021_fa_shadow_eye.xyz));\n        fade = _2514;\n        if (_2514 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2489.x > 1.5f)\n    {\n        int param_3 = li;\n        int param_4 = fa_light_base(param_3);\n        float3 param_5 = world - fa_light_texel(param_4).xyz;\n        face = fa_cube_face(param_5);\n    }\n    int _2543 = (_2485 + 2) + (face * 6);\n    int param_6 = _2543;\n    int param_7 = _2543 + 1;\n    int param_8 = _2543 + 3;\n    float4 _2557 = fa_light_texel(param_8);\n    int param_9 = _2543 + 4;\n    float4 _2562 = fa_light_texel(param_9);\n    int param_10 = _2543 + 5;\n    float4 _2567 = fa_light_texel(param_10);\n    float _2579 = _2567.x * max(dot(_2557, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2584 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2607 = clamp(dot(n, _2557.xyz), -1.0f, 1.0f);\n    int param_11 = li;\n    int param_12 = fa_light_base(param_11);\n    float _2631 = min(sqrt(1.0f - (_2607 * _2607)) / max(abs(dot(n, world - fa_light_texel(param_12).xyz)) / max(dot(_2557, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2634 = _2494.y;\n    float _2636;\n    if (_2634 > 0.0f)\n    {\n        _2636 = _2634;\n    }\n    else\n    {\n        _2636 = 1.5f * _2579;\n    }\n    float4 _2656 = float4(world + (n * (_2636 * sqrt(1.0f - (_2584 * _2584)))), 1.0f);\n    float _2660 = dot(_2557, _2656);\n    float _2663 = _2567.y;\n    if (_2660 < _2663)\n    {\n        return 1.0f;\n    }\n    float2 _2678 = float2(dot(fa_light_texel(param_6), _2656), dot(fa_light_texel(param_7), _2656)) / _2660.xx;\n    float _2680 = _2678.x;\n    bool _2683 = _2680 < _2562.x;\n    bool _2692;\n    if (!_2683)\n    {\n        _2692 = _2680 > _2562.z;\n    }\n    else\n    {\n        _2692 = _2683;\n    }\n    bool _2701;\n    if (!_2692)\n    {\n        _2701 = _2678.y < _2562.y;\n    }\n    else\n    {\n        _2701 = _2692;\n    }\n    bool _2710;\n    if (!_2701)\n    {\n        _2710 = _2678.y > _2562.w;\n    }\n    else\n    {\n        _2710 = _2701;\n    }\n    if (_2710)\n    {\n        return 1.0f;\n    }\n    float _2716 = _2494.x;\n    float _2718;\n    if (_2716 > 0.0f)\n    {\n        _2718 = _2716;\n    }\n    else\n    {\n        _2718 = 1.5f * _2579;\n    }\n    float2 param_13 = _2678;\n    float4 param_14 = _2562;\n    float param_15 = _2660 - (_2718 * (1.0f + (0.5f * _2631)));\n    float param_16 = _2579;\n    float param_17 = 1.0f;\n    float param_18 = _2567.z * 0.25f;\n    float param_19 = (_2579 * min(_2631, 3.0f)) * 0.5f;\n    float3 param_20 = float3(1.0f, _2663, _2567.z);\n    int param_21 = int(_2489.z + 0.5f);\n    float param_22 = _2489.w;\n    return lerp(1.0f, fa_shadow_filter(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _3110 = fa_lm.z > 0.5f;\n    bool _3116;\n    if (_3110)\n    {\n        int param = li;\n        _3116 = fa_light_baked(param);\n    }\n    else\n    {\n        _3116 = _3110;\n    }\n    if (_3116)\n    {\n        int param_1 = li;\n        LightSample _4139 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _4139;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3140 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _4141 = _3140.color;\n    float _4143 = _3140.shadow;\n    if ((_3140.type == 0) && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3140.direction;\n        float _3154 = fa_shadow_factor(param_5, param_6);\n        _4143 = _3154;\n        _4141 *= _3154;\n    }\n    else\n    {\n        bool _3165 = _3140.type != 0;\n        bool _3171;\n        if (_3165)\n        {\n            _3171 = _3140.attenuation > 0.0f;\n        }\n        else\n        {\n            _3171 = _3165;\n        }\n        if (_3171)\n        {\n            int param_7 = li;\n            float3 param_8 = world_pos;\n            float3 param_9 = gn;\n            float3 param_10 = _3140.direction;\n            float _3183 = fa_shadow_local(param_7, param_8, param_9, param_10);\n            _4143 = _3183;\n            _4141 *= _3183;\n        }\n    }\n    LightSample _4158 = { _3140.direction, _4141, _3140.attenuation, _4143, _3140._distance, _3140.type };\n    return _4158;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2021_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _2967 = int(_2021_fa_shadow_cfg.x + 0.5f);\n    float _2977 = dot(world - _2021_fa_shadow_eye.xyz, _2021_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _2982 = _2967 > 0;\n    bool _2991;\n    if (_2982)\n    {\n        int param = _2967 - 1;\n        _2991 = _2977 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2991 = _2982;\n    }\n    if (_2991)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _2997 = _2967 > 1;\n        bool _3004;\n        if (_2997)\n        {\n            _3004 = _2977 > _2021_fa_shadow_split.x;\n        }\n        else\n        {\n            _3004 = _2997;\n        }\n        if (_3004)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3010 = _2967 > 2;\n        bool _3017;\n        if (_3010)\n        {\n            _3017 = _2977 > _2021_fa_shadow_split.y;\n        }\n        else\n        {\n            _3017 = _3010;\n        }\n        if (_3017)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3023 = _2967 > 3;\n        bool _3030;\n        if (_3023)\n        {\n            _3030 = _2977 > _2021_fa_shadow_split.z;\n        }\n        else\n        {\n            _3030 = _3023;\n        }\n        if (_3030)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _3982 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3982 = -_3982;\n    }\n    float3 _3566 = normalize(_314_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _3995 = { fa_world_pos, _3982, fa_world_tangent, fa_uv, fa_vertex_color, _3566, gl_FrontFacing };\n    SurfaceInput param_1 = _3995;\n    Surface _3574 = fa_standard_surface(param_1);\n    float3 _4013 = _3574.albedo;\n    float _4014 = _3574.alpha;\n    float3 _4015 = _3574.normal;\n    float _4016 = _3574.metallic;\n    float _4017 = _3574.roughness;\n    float _4018 = _3574.occlusion;\n    float3 _4019 = _3574.emission;\n    float _4020 = _3574.clearcoat;\n    float _4021 = _3574.clearcoat_roughness;\n    float3 _4022 = _3574.sheen_color;\n    float _4023 = _3574.sheen_roughness;\n    float _4024 = _3574.anisotropy;\n    float _4025 = _3574.anisotropy_rotation;\n    float _4026 = _3574.specular;\n    float _4027 = _3574.ior;\n    float3 _4028 = _3574.specular_color;\n    SurfaceInput _4003 = { fa_world_pos, _3982, fa_world_tangent, fa_uv, fa_vertex_color, _3566, gl_FrontFacing };\n    SurfaceInput param_2 = _4003;\n    Surface param_3 = _3574;\n    surface(param_2, param_3);\n    _4013 = param_3.albedo;\n    _4014 = param_3.alpha;\n    _4015 = param_3.normal;\n    _4016 = param_3.metallic;\n    _4017 = param_3.roughness;\n    _4018 = param_3.occlusion;\n    _4019 = param_3.emission;\n    _4020 = param_3.clearcoat;\n    _4021 = param_3.clearcoat_roughness;\n    _4022 = param_3.sheen_color;\n    _4023 = param_3.sheen_roughness;\n    _4024 = param_3.anisotropy;\n    _4025 = param_3.anisotropy_rotation;\n    _4026 = param_3.specular;\n    _4027 = param_3.ior;\n    _4028 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _3982;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4013 = param_6;\n    _4015 = param_7;\n    float3 result;\n    if (_314_fa_emissive.w > 0.5f)\n    {\n        result = _4013;\n    }\n    else\n    {\n        float3 _3612 = _4015;\n        float3 _3613 = normalize(_3612);\n        _4015 = _3613;\n        float3 param_8 = _3613;\n        float3 lit = (fa_indirect_diffuse(param_8) * _4013) * _4018;\n        int _3632 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3632; ln++)\n        {\n            int param_9 = ln;\n            int _3645 = fa_cl_light(param_9);\n            bool _3648 = fa_lm.z > 0.5f;\n            bool _3654;\n            if (_3648)\n            {\n                int param_10 = _3645;\n                _3654 = fa_light_baked(param_10);\n            }\n            else\n            {\n                _3654 = _3648;\n            }\n            if (_3654)\n            {\n                continue;\n            }\n            int param_11 = _3645;\n            float3 param_12 = fa_world_pos;\n            float3 param_13 = _3982;\n            LightSample _3666 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput _4011 = { fa_world_pos, _3982, fa_world_tangent, fa_uv, fa_vertex_color, _3566, gl_FrontFacing };\n            SurfaceInput param_14 = _4011;\n            Surface _4094 = { _4013, _4014, _4015, _4016, _4017, _4018, _4019, _4020, _4021, _4022, _4023, _4024, _4025, _4026, _4027, _4028 };\n            Surface param_15 = _4094;\n            LightSample param_16 = _3666;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    float3 _3681 = result;\n    float3 _3682 = _3681 + _4019;\n    result = _3682;\n    float3 param_17 = _3682;\n    float3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _3691 = _314_fa_fog.w > 0.0f;\n    bool _3698;\n    if (!_3691)\n    {\n        _3698 = _314_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _3698 = _3691;\n    }\n    if (_3698)\n    {\n        float3 _3707 = fa_world_pos - _314_fa_camera_pos.xyz;\n        float _3713 = dot(_3707, _314_fa_fog_c.xyz);\n        bool _3717 = _314_fa_fog_c.w > 0.5f;\n        float _3718;\n        if (_3717)\n        {\n            _3718 = _3713;\n        }\n        else\n        {\n            _3718 = length(_3707);\n        }\n        float _3730 = _3718 - _314_fa_fog_b.x;\n        if (_3730 > 0.0f)\n        {\n            float _3739 = _314_fa_fog.w * _3730;\n            float tau = _3739 * _3739;\n            if (_314_fa_fog_b.y > 0.0f)\n            {\n                float _3755;\n                if (_3717)\n                {\n                    _3755 = fa_world_pos.y - (_314_fa_fog_c.y * _3713);\n                }\n                else\n                {\n                    _3755 = _314_fa_camera_pos.y;\n                }\n                float _3776 = lerp(_3755, fa_world_pos.y, clamp(_314_fa_fog_b.x / _3718, 0.0f, 1.0f));\n                float _3780 = fa_world_pos.y - _3776;\n                float _3785 = _3776 - _314_fa_fog_b.z;\n                float _3790 = fa_world_pos.y - _314_fa_fog_b.z;\n                bool _3793 = _3785 <= 0.0f;\n                bool _3794 = !_3793;\n                bool _3800;\n                if (_3794)\n                {\n                    _3800 = _314_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3800 = _3793;\n                }\n                float _3801;\n                if (_3800)\n                {\n                    _3801 = _314_fa_fog_b.y;\n                }\n                else\n                {\n                    _3801 = _314_fa_fog_b.y * exp(-min(_314_fa_fog_b.w * _3785, 80.0f));\n                }\n                bool _3828;\n                if (_3794)\n                {\n                    _3828 = _314_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3828 = _3793;\n                }\n                float _3829;\n                if (_3828)\n                {\n                    _3829 = _314_fa_fog_b.y * _3785;\n                }\n                else\n                {\n                    _3829 = (_314_fa_fog_b.y * (1.0f - exp(-min(_314_fa_fog_b.w * _3785, 80.0f)))) / _314_fa_fog_b.w;\n                }\n                bool _3854 = _3790 <= 0.0f;\n                bool _3861;\n                if (!_3854)\n                {\n                    _3861 = _314_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3861 = _3854;\n                }\n                float _3862;\n                if (_3861)\n                {\n                    _3862 = _314_fa_fog_b.y * _3790;\n                }\n                else\n                {\n                    _3862 = (_314_fa_fog_b.y * (1.0f - exp(-min(_314_fa_fog_b.w * _3790, 80.0f)))) / _314_fa_fog_b.w;\n                }\n                float _3889;\n                if (abs(_3780) < 0.001000000047497451305389404296875f)\n                {\n                    _3889 = _3801;\n                }\n                else\n                {\n                    _3889 = (_3862 - _3829) / _3780;\n                }\n                tau += (_3730 * max(_3889, 0.0f));\n            }\n            result = lerp(result, _314_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4014);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_2021",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _314_fa_camera_pos : packoffset(c0);\n    float4 _314_fa_ambient : packoffset(c1);\n    float4 _314_fa_base_color : packoffset(c2);\n    float4 _314_fa_emissive : packoffset(c3);\n    float4 _314_fa_model_emissive : packoffset(c4);\n    float4 _314_fa_pbr : packoffset(c5);\n    float4 _314_fa_maps : packoffset(c6);\n    float4 _314_fa_fog : packoffset(c7);\n    float4 _314_fa_fog_b : packoffset(c8);\n    float4 _314_fa_fog_c : packoffset(c9);\n    float4 _314_fa_counts : packoffset(c10);\n    float4 _314_fa_env_sky : packoffset(c11);\n    float4 _314_fa_env_horizon : packoffset(c12);\n    float4 _314_fa_time : packoffset(c13);\n    float4 _314_fa_cl_vpx : packoffset(c14);\n    float4 _314_fa_cl_vpy : packoffset(c15);\n    float4 _314_fa_cl_vpw : packoffset(c16);\n    float4 _314_fa_cl_fwd : packoffset(c17);\n    float4 _314_fa_cl_grid : packoffset(c18);\n    float4 _314_fa_cl_info : packoffset(c19);\n    float4 _314_fa_layers_a : packoffset(c20);\n    float4 _314_fa_layers_b : packoffset(c21);\n    float4 _314_fa_layers_c : packoffset(c22);\n    float4 _314_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2021_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2021_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2021_fa_shadow_info[4] : packoffset(c20);\n    float4 _2021_fa_shadow_split : packoffset(c24);\n    float4 _2021_fa_shadow_cfg : packoffset(c25);\n    float4 _2021_fa_shadow_bias : packoffset(c26);\n    float4 _2021_fa_shadow_eye : packoffset(c27);\n    float4 _2021_fa_shadow_fwd : packoffset(c28);\n    float4 _2021_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_irr_tex : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1292 = _314_fa_cl_info.x < 0.0f;\n    bool _1299;\n    if (!_1292)\n    {\n        _1299 = _314_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1299 = _1292;\n    }\n    bool _1307;\n    if (!_1299)\n    {\n        _1307 = _314_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1307 = _1299;\n    }\n    bool _1314;\n    if (!_1307)\n    {\n        _1314 = _314_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1314 = _1307;\n    }\n    bool _1321;\n    if (!_1314)\n    {\n        _1321 = _314_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1321 = _1314;\n    }\n    if (_1321)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1331 = float4(world_pos, 1.0f);\n    float _1337 = dot(_314_fa_cl_vpw, _1331);\n    if (!(_1337 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1359 = float2(dot(_314_fa_cl_vpx, _1331), dot(_314_fa_cl_vpy, _1331)) / _1337.xx;\n    int _1363 = int(_314_fa_cl_grid.x);\n    int _1367 = int(_314_fa_cl_grid.y);\n    int param = (int(_314_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_314_fa_cl_fwd.xyz, world_pos) + _314_fa_cl_fwd.w, _314_fa_cl_grid.w) / _314_fa_cl_grid.w) * _314_fa_cl_grid.z)), 0, int(_314_fa_cl_info.y) - 1) * _1367) + clamp(int(floor(((_1359.y * 0.5f) + 0.5f) * _314_fa_cl_grid.y)), 0, _1367 - 1)) * _1363)) + clamp(int(floor(((_1359.x * 0.5f) + 0.5f) * _314_fa_cl_grid.x)), 0, _1363 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1443 = fa_cluster_texel(param);\n    return int2(int(_1443.x), int(_1443.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_314_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3083 = fa_cluster_lookup(param);\n    fa_cl_slot = _3083.x;\n    fa_cl_local = _3083.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _3232 = fa_linear_to_srgb(param);\n        c = _3232;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _3240 = fa_srgb_to_linear(param_1);\n            c = _3240;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _246;\n    if (i.front_facing)\n    {\n        _246 = i.world_normal;\n    }\n    else\n    {\n        _246 = -i.world_normal;\n    }\n    float3 _270 = normalize(i.world_tangent.xyz - (_246 * dot(_246, i.world_tangent.xyz)));\n    float3 _298 = normalize(((_270 * m.x) + ((cross(_246, _270) * i.world_tangent.w) * m.y)) + (_246 * m.z));\n    float3 _301;\n    if (i.front_facing)\n    {\n        _301 = _298;\n    }\n    else\n    {\n        _301 = -_298;\n    }\n    return _301;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _314_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3271 = fa_tex_fix(param_2, param_3);\n    float4 _4296 = base_t;\n    _4296.x = _3271.x;\n    _4296.y = _3271.y;\n    _4296.z = _3271.z;\n    base_t = _4296;\n    float4 _3285 = (_4296 * _314_fa_base_color) * i.vertex_color;\n    float3 _4161 = i.world_normal;\n    if (_314_fa_maps.z > 0.5f)\n    {\n        float param_4 = _314_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3317 = fa_tex_fix(param_6, param_7);\n        float3 _3320 = (_3317 * 2.0f) - 1.0f.xxx;\n        float2 _3325 = _3320.xy * _314_fa_maps.x;\n        float3 _4304 = _3320;\n        _4304.x = _3325.x;\n        _4304.y = _3325.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4304;\n        _4161 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _314_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3353 = fa_tex_fix(param_12, param_13);\n    float4 _4307 = mrt;\n    _4307.x = _3353.x;\n    _4307.y = _3353.y;\n    _4307.z = _3353.z;\n    mrt = _4307;\n    float4 _3381 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _314_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _3381.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3392 = fa_tex_fix(param_16, param_17);\n    float param_18 = _314_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3422 = fa_tex_fix(param_20, param_21);\n    float _4166 = _314_fa_layers_a.x;\n    float _4167 = _314_fa_layers_a.y;\n    float _4170 = _314_fa_layers_a.z;\n    float _4169 = _314_fa_layers_b.w;\n    float _4172 = _314_fa_layers_c.x;\n    if (_314_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_314_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _4166 *= _3392.y;\n            _4167 *= _3392.z;\n            _4169 *= _3381.w;\n        }\n        if (_314_fa_layers_c.z > 1.5f)\n        {\n            _4170 *= mrt.x;\n            _4172 *= mrt.w;\n        }\n    }\n    Surface _4191 = { _3285.xyz, _3285.w, _4161, clamp(_314_fa_pbr.x * _3353.z, 0.0f, 1.0f), clamp(_314_fa_pbr.y * _3353.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_314_fa_maps.y * (_3392.x - 1.0f)), _314_fa_emissive.xyz + (_314_fa_model_emissive.xyz * _3422), _4166, _4167, _314_fa_layers_b.xyz, _4169, _4170, _314_fa_layers_a.w, _4172, _314_fa_layers_c.y, _314_fa_layers_d.xyz };\n    return _4191;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1523 = rect.zw - rect.xy;\n    float2 _1527 = _1523 * atlas;\n    float2 _1531 = ddx * _1527;\n    float2 _1535 = ddy * _1527;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1523), clamp(0.5f * log2(max(max(dot(_1531, _1531), dot(_1535, _1535)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1568 = _314_fa_counts.y < 0.5f;\n    bool _1575;\n    if (!_1568)\n    {\n        _1575 = _314_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1575 = _1568;\n    }\n    if (_1575)\n    {\n        return;\n    }\n    float3 _1581 = ddx(world_pos);\n    float3 _1584 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1588 = fa_cluster_texel(param);\n    int _1592 = int(_1588.w);\n    if (_1592 < 1)\n    {\n        return;\n    }\n    int _1602 = int(_314_fa_counts.y + 0.5f);\n    int param_1 = _1602;\n    float4 _1606 = fa_light_texel(param_1);\n    float2 _1609 = _1606.yz;\n    int _1613 = int(_1606.w);\n    int param_2 = _1602 + 1;\n    float4 _1618 = fa_light_texel(param_2);\n    float _1619 = _1618.x;\n    int _1625 = int(_314_fa_counts.w + 0.5f) - 1;\n    int _1629 = int(_1588.z);\n    float3 _1894;\n    for (int k = 0; k < _1592; k++)\n    {\n        int _1642 = _1629 + k;\n        int param_3 = _1613 + (_1642 >> 2);\n        int _1659 = (_1602 + 2) + (int(fa_light_texel(param_3)[_1642 & 3]) * 7);\n        int param_4 = _1659 + 6;\n        float4 _1664 = fa_light_texel(param_4);\n        if (((int(_1664.w + 0.5f) >> _1625) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1659;\n        float4 _1679 = fa_light_texel(param_5);\n        int param_6 = _1659 + 1;\n        float4 _1684 = fa_light_texel(param_6);\n        int param_7 = _1659 + 2;\n        float4 _1689 = fa_light_texel(param_7);\n        float3 _1692 = _1679.xyz;\n        float _1697 = dot(_1692, world_pos) + _1679.w;\n        float3 _1699 = _1684.xyz;\n        float _1704 = dot(_1699, world_pos) + _1684.w;\n        float3 _1706 = _1689.xyz;\n        float _1711 = dot(_1706, world_pos) + _1689.w;\n        bool _1716 = abs(_1697) > 0.5f;\n        bool _1724;\n        if (!_1716)\n        {\n            _1724 = abs(_1704) > 0.5f;\n        }\n        else\n        {\n            _1724 = _1716;\n        }\n        bool _1732;\n        if (!_1724)\n        {\n            _1732 = abs(_1711) > 0.5f;\n        }\n        else\n        {\n            _1732 = _1724;\n        }\n        if (_1732)\n        {\n            continue;\n        }\n        float _1747 = clamp(dot(geo_normal, normalize(_1706)) * _1664.z, 0.0f, 1.0f);\n        if (_1747 <= 0.0f)\n        {\n            continue;\n        }\n        float _1767 = (clamp((0.5f - abs(_1711)) * 10.0f, 0.0f, 1.0f) * _1747) * _1664.x;\n        float2 _1775 = float2(_1697 + 0.5f, 0.5f - _1704);\n        float2 _1785 = float2(dot(_1692, _1581), dot(_1699, _1581));\n        float2 _1795 = float2(dot(_1692, _1584), dot(_1699, _1584));\n        int param_8 = _1659 + 5;\n        float4 _1800 = fa_light_texel(param_8);\n        int param_9 = _1659 + 3;\n        float4 _1805 = fa_light_texel(param_9);\n        int param_10 = _1659 + 4;\n        float4 _1810 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1800.xyz;\n        bool _1820 = _1805.z > _1805.x;\n        if (_1820)\n        {\n            float4 param_11 = _1805;\n            float2 param_12 = _1775;\n            float2 param_13 = _1609;\n            float2 param_14 = _1785;\n            float2 param_15 = _1795;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1619 > 0.5f) && (_1619 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1846 = fa_dc_to_linear(param_16);\n                float4 _4241 = tx;\n                _4241.x = _1846.x;\n                _4241.y = _1846.y;\n                _4241.z = _1846.z;\n                tx = _4241;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1767 * tex_a) * _1800.w, 0.0f, 1.0f).xxx);\n        if (_1810.z > _1810.x)\n        {\n            float4 param_17 = _1810;\n            float2 param_18 = _1775;\n            float2 param_19 = _1609;\n            float2 param_20 = _1785;\n            float2 param_21 = _1795;\n            float4 _1890 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1619 > 1.5f)\n            {\n                float3 param_22 = _1890.xyz;\n                float3 _1900 = fa_dc_to_srgb(param_22);\n                _1894 = _1900;\n            }\n            else\n            {\n                _1894 = _1890.xyz;\n            }\n            float3 _1909 = (_1894 * 2.0f) - 1.0f.xxx;\n            float2 _1914 = _1909.xy * _1664.y;\n            float3 _1936 = (normalize(_1692) * _1914.x) + (normalize(_1699) * _1914.y);\n            float3 _1939 = normalize(normal);\n            normal = normalize(lerp(_1939, normalize((_1939 * max(_1909.z, 0.0500000007450580596923828125f)) + (_1936 - (_1939 * dot(_1939, _1936)))), clamp(_1767 * (_1820 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_314_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _314_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_314_fa_cl_info.x) + int(_314_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_314_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _376_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _376_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _542 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _555 = (c - (ru * hx)) - p;\n        float3 _561 = ru * (2.0f * hx);\n        float _567 = max(dot(_561, _561), 9.9999999392252902907785028219223e-09f);\n        float _571 = dot(_555, _561);\n        float t = clamp((-_571) / _567, 0.0f, 1.0f);\n        if (_542)\n        {\n            float _586 = dot(r, _561);\n            float _592 = _567 - (_586 * _586);\n            if (abs(_592) > (9.9999997473787516355514526367188e-06f * _567))\n            {\n                t = clamp(((dot(r, _555) * _586) - _571) / _592, 0.0f, 1.0f);\n            }\n        }\n        return (p + _555) + (_561 * t);\n    }\n    float3 q = p;\n    float _624 = dot(r, axis);\n    bool _632;\n    if (_542)\n    {\n        _632 = abs(_624) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _632 = _542;\n    }\n    if (_632)\n    {\n        float _642 = dot(c - p, axis) / _624;\n        if (_642 > 0.0f)\n        {\n            q = p + (r * _642);\n        }\n    }\n    float3 _655 = q - c;\n    float2 xy = float2(dot(_655, ru), dot(_655, uu));\n    if (shape > 0.5f)\n    {\n        float _670 = length(xy);\n        if (_670 > hx)\n        {\n            xy *= (hx / _670);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _463 = abs(d);\n    float _465 = _463.x;\n    float _467 = _463.y;\n    bool _468 = _465 >= _467;\n    bool _476;\n    if (_468)\n    {\n        _476 = _465 >= _463.z;\n    }\n    else\n    {\n        _476 = _468;\n    }\n    int _477;\n    if (_476)\n    {\n        _477 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _490;\n        if (_467 >= _463.z)\n        {\n            _490 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _490 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _477 = _490;\n    }\n    return _477;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _416 = dot(d, right);\n    float _420 = dot(d, up);\n    float _431;\n    if (((_416 * _416) + (_420 * _420)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _431 = atan2(_420, _416) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _431 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_431 - floor(_431)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _708 = fa_light_base(param);\n    bool _712 = _314_fa_ambient.w > 4.5f;\n    int param_1 = _708;\n    float4 _716 = fa_light_texel(param_1);\n    int param_2 = _708 + 1;\n    float4 _721 = fa_light_texel(param_2);\n    float _724 = _721.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _736 = _712 && (_724 > 2.5f);\n    fa_light_is_area = _736;\n    bool _738 = _724 < 0.5f;\n    float3 l;\n    if (_738)\n    {\n        l = normalize(_716.xyz);\n        if (_712)\n        {\n            int param_3 = _708 + 6;\n            float4 _752 = fa_light_texel(param_3);\n            if (_752.z > 0.5f)\n            {\n                int param_4 = _708 + 4;\n                float4 _762 = fa_light_texel(param_4);\n                int param_5 = _708 + 5;\n                float4 _767 = fa_light_texel(param_5);\n                float2 param_6 = _752.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _762.xyz) * _762.w, (-dot(world_pos, _767.xyz)) * _767.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _797 = _716.xyz;\n        float3 _799 = _797 - world_pos;\n        float3 to_light = _799;\n        float _802 = length(_799);\n        float reach = _802;\n        bool front = true;\n        if (_736)\n        {\n            int param_8 = _708 + 7;\n            reach = max(_802 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _708 + 4;\n            float4 _826 = fa_light_texel(param_9);\n            int param_10 = _708 + 5;\n            float4 _831 = fa_light_texel(param_10);\n            int param_11 = _708 + 6;\n            float4 _836 = fa_light_texel(param_11);\n            float _837 = _836.w;\n            int param_12 = _708 + 2;\n            float3 _844 = normalize(fa_light_texel(param_12).xyz);\n            bool _846 = _837 > 1.5f;\n            bool _854;\n            if (!_846)\n            {\n                _854 = dot(_844, to_light) < 0.0f;\n            }\n            else\n            {\n                _854 = _846;\n            }\n            front = _854;\n            float3 r = 0.0f.xxx;\n            float3 _863 = _314_fa_camera_pos.xyz - world_pos;\n            bool _867 = dot(n, n) > 0.5f;\n            bool _875;\n            if (_867)\n            {\n                _875 = dot(_863, _863) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _875 = _867;\n            }\n            if (_875)\n            {\n                r = reflect(-normalize(_863), normalize(n));\n            }\n            float3 param_13 = _797;\n            float3 param_14 = _844;\n            float3 param_15 = _826.xyz;\n            float3 param_16 = _831.xyz;\n            float param_17 = _826.w;\n            float param_18 = _831.w;\n            float param_19 = _837;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _911 = length(to_light);\n        dist = _911;\n        l = to_light / max(_911, 9.9999997473787516355514526367188e-05f).xxx;\n        float _925 = reach / max(_716.w, 0.001000000047497451305389404296875f);\n        float _931 = clamp(1.0f - (_925 * _925), 0.0f, 1.0f);\n        float _933;\n        if (front)\n        {\n            _933 = _931 * _931;\n        }\n        else\n        {\n            _933 = 0.0f;\n        }\n        atten = _933;\n        bool _944 = _724 < 2.5f;\n        if ((_724 > 1.5f) && _944)\n        {\n            int param_22 = _708 + 2;\n            float4 _952 = fa_light_texel(param_22);\n            float _962 = _952.w;\n            int param_23 = _708 + 3;\n            float4 _967 = fa_light_texel(param_23);\n            float _968 = _967.x;\n            float cos_inner = _968;\n            if (_968 > 1.5f)\n            {\n                cos_inner = lerp(_962, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_962, cos_inner, dot(-l, normalize(_952.xyz)));\n        }\n        if (_712 && (_724 < 1.5f))\n        {\n            int param_24 = _708 + 6;\n            float4 _992 = fa_light_texel(param_24);\n            if (_992.z > 0.5f)\n            {\n                float3 _1000 = -to_light;\n                int param_25 = _708 + 4;\n                int param_26 = _708 + 5;\n                float3 _1014 = fa_light_texel(param_25).xyz;\n                float3 _1018 = fa_light_texel(param_26).xyz;\n                float3 _1027 = float3(dot(_1000, _1014), dot(_1000, _1018), dot(_1000, cross(_1014, _1018)));\n                float3 param_27 = _1027;\n                int _1031 = fa_cube_face(param_27);\n                int param_28 = _1031;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1058 = float2(dot(_1027, cross(param_29, param_30)), dot(_1027, param_30)) / max(dot(_1027, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1062 = _1031 / 3;\n                float2 param_31 = _992.xy + (float2(float(_1031 - (_1062 * 3)), float(_1062)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1058.x), 0.5f - (0.5f * _1058.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _708 + 7;\n            float4 _1092 = fa_light_texel(param_33);\n            if (_1092.z > 0.5f)\n            {\n                int param_34 = _708 + 2;\n                int param_35 = _708 + 4;\n                int param_36 = _708 + 5;\n                float2 param_37 = _1092.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_712 && _944)\n            {\n                int param_42 = _708 + 6;\n                float4 _1139 = fa_light_texel(param_42);\n                int param_43 = _708 + 7;\n                float4 _1144 = fa_light_texel(param_43);\n                bool _1147 = _1139.z > 0.5f;\n                bool _1154;\n                if (!_1147)\n                {\n                    _1154 = _1144.z > 0.5f;\n                }\n                else\n                {\n                    _1154 = _1147;\n                }\n                if (_1154)\n                {\n                    int param_44 = _708 + 2;\n                    float4 _1161 = fa_light_texel(param_44);\n                    float3 _1165 = normalize(_1161.xyz);\n                    int param_45 = _708 + 4;\n                    float4 _1170 = fa_light_texel(param_45);\n                    int param_46 = _708 + 5;\n                    float4 _1175 = fa_light_texel(param_46);\n                    if (_1147)\n                    {\n                        float3 _1183 = -to_light;\n                        float _1190 = _1161.w;\n                        float _1206 = 0.5f / max(dot(_1183, _1165) * (sqrt(max(1.0f - (_1190 * _1190), 0.0f)) / max(_1190, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1139.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1183, _1170.xyz) * _1206), 0.5f - (dot(_1183, _1175.xyz) * _1206));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1144.z > 0.5f)\n                    {\n                        float2 param_49 = _1144.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1165;\n                        float3 param_52 = _1170.xyz;\n                        float3 param_53 = _1175.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4115 = _721.xyz * atten;\n    if (_712)\n    {\n        _4115 *= fa_light_tint;\n    }\n    int _1274;\n    if (_738)\n    {\n        _1274 = 0;\n    }\n    else\n    {\n        _1274 = ((_724 > 1.5f) && (_724 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _4126 = { l, _4115, atten, 1.0f, dist, _1274 };\n    return _4126;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2011;\n    if (i == 0)\n    {\n        _2011 = _2021_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2027;\n        if (i == 1)\n        {\n            _2027 = _2021_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2035;\n            if (i == 2)\n            {\n                _2035 = _2021_fa_shadow_split.z;\n            }\n            else\n            {\n                _2035 = _2021_fa_shadow_split.w;\n            }\n            _2027 = _2035;\n        }\n        _2011 = _2027;\n    }\n    return _2011;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2068 = fa_shadow_depth(param, param_1);\n    float _2072;\n    if (conv.x < 0.5f)\n    {\n        _2072 = _2068;\n    }\n    else\n    {\n        _2072 = (conv.y * conv.z) / (conv.z - (_2068 * (conv.z - conv.y)));\n    }\n    return _2072;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1999 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_1999), sin(_1999)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2118 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2127;\n        if (k < 0.0f)\n        {\n            _2127 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2127 = k;\n        }\n        float _2147 = clamp((_2127 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2118;\n            float2 _2166 = fa_shadow_vogel(param_3, param_4, param_5) * _2147;\n            float2 param_6 = uv + (_2166 * _2021_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2178 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2178 < (zr - (length(_2166) * plane)))\n            {\n                sum += _2178;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2204 = sum / cnt;\n        float _2214;\n        if (k < 0.0f)\n        {\n            _2214 = (-k) / max(_2204, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2214 = k;\n        }\n        radius = clamp(((max(zr - _2204, 0.0f) * unit) * _2214) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2236 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2236; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2236;\n        float param_11 = _2118;\n        float2 _2255 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2255 * _2021_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2255) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2236);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2297 = max(_2021_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2302 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2308 = sqrt(1.0f - (_2302 * _2302));\n    float _2315 = min(_2308 / max(_2302, 0.20000000298023223876953125f), 4.0f);\n    float _2320;\n    if (_2021_fa_shadow_bias.y > 0.0f)\n    {\n        _2320 = _2021_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2320 = 1.5f * _2021_fa_shadow_info[ci].x;\n    }\n    float4 _2345 = mul(float4(world + (n * (_2320 * _2308)), 1.0f), _2021_fa_shadow_mat[ci]);\n    float _2352 = _2345.x;\n    bool _2355 = _2352 < _2021_fa_shadow_rect[ci].x;\n    bool _2364;\n    if (!_2355)\n    {\n        _2364 = _2352 > _2021_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2364 = _2355;\n    }\n    bool _2373;\n    if (!_2364)\n    {\n        _2373 = _2345.y < _2021_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2373 = _2364;\n    }\n    bool _2382;\n    if (!_2373)\n    {\n        _2382 = _2345.y > _2021_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2382 = _2373;\n    }\n    bool _2389;\n    if (!_2382)\n    {\n        _2389 = _2345.z > 1.0f;\n    }\n    else\n    {\n        _2389 = _2382;\n    }\n    if (_2389)\n    {\n        return -1.0f;\n    }\n    float _2397;\n    if (_2021_fa_shadow_bias.x > 0.0f)\n    {\n        _2397 = _2021_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2397 = 1.5f * _2021_fa_shadow_info[ci].x;\n    }\n    float2 param = _2345.xy;\n    float4 param_1 = _2021_fa_shadow_rect[ci];\n    float param_2 = _2345.z - ((_2397 * (1.0f + (0.5f * _2315))) / _2297);\n    float param_3 = _2021_fa_shadow_info[ci].x;\n    float param_4 = _2297;\n    float param_5 = _2297 * 0.25f;\n    float param_6 = ((_2021_fa_shadow_info[ci].x * min(_2315, 3.0f)) * 0.5f) / _2297;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2021_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2021_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_314_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2785 = int(_2021_fa_shadow_cfg.x + 0.5f);\n    if (_2785 < 1)\n    {\n        return 1.0f;\n    }\n    float _2800 = dot(world - _2021_fa_shadow_eye.xyz, _2021_fa_shadow_fwd.xyz);\n    int param = _2785 - 1;\n    if (_2800 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2812 = _2785 > 1;\n    bool _2819;\n    if (_2812)\n    {\n        _2819 = _2800 > _2021_fa_shadow_split.x;\n    }\n    else\n    {\n        _2819 = _2812;\n    }\n    if (_2819)\n    {\n        ci = 1;\n    }\n    bool _2823 = _2785 > 2;\n    bool _2830;\n    if (_2823)\n    {\n        _2830 = _2800 > _2021_fa_shadow_split.y;\n    }\n    else\n    {\n        _2830 = _2823;\n    }\n    if (_2830)\n    {\n        ci = 2;\n    }\n    bool _2834 = _2785 > 3;\n    bool _2841;\n    if (_2834)\n    {\n        _2841 = _2800 > _2021_fa_shadow_split.z;\n    }\n    else\n    {\n        _2841 = _2834;\n    }\n    if (_2841)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2785)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2867 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2867;\n        if (_2867 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2021_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2892;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2892 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2892 = _2021_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2911 = _2021_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2892, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2922 = clamp((_2800 - (fa_shadow_split_at(param_7) - _2911)) / _2911, 0.0f, 1.0f);\n        if (_2922 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2785)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2943 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2943;\n                if (_2943 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2922);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _2455 = _314_fa_pbr.z < 0.5f;\n    bool _2462;\n    if (!_2455)\n    {\n        _2462 = _2021_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2462 = _2455;\n    }\n    if (_2462)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2021_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2475 = fa_light_texel(param);\n    float _2476 = _2475.x;\n    if (_2476 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2485 = int(_2476 + 0.5f);\n    int param_1 = _2485;\n    float4 _2489 = fa_light_texel(param_1);\n    int param_2 = _2485 + 1;\n    float4 _2494 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2497 = _2489.y;\n    if (_2497 > 0.0f)\n    {\n        float _2514 = 1.0f - smoothstep(0.75f * _2497, _2497, length(world - _2021_fa_shadow_eye.xyz));\n        fade = _2514;\n        if (_2514 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2489.x > 1.5f)\n    {\n        int param_3 = li;\n        int param_4 = fa_light_base(param_3);\n        float3 param_5 = world - fa_light_texel(param_4).xyz;\n        face = fa_cube_face(param_5);\n    }\n    int _2543 = (_2485 + 2) + (face * 6);\n    int param_6 = _2543;\n    int param_7 = _2543 + 1;\n    int param_8 = _2543 + 3;\n    float4 _2557 = fa_light_texel(param_8);\n    int param_9 = _2543 + 4;\n    float4 _2562 = fa_light_texel(param_9);\n    int param_10 = _2543 + 5;\n    float4 _2567 = fa_light_texel(param_10);\n    float _2579 = _2567.x * max(dot(_2557, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2584 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2607 = clamp(dot(n, _2557.xyz), -1.0f, 1.0f);\n    int param_11 = li;\n    int param_12 = fa_light_base(param_11);\n    float _2631 = min(sqrt(1.0f - (_2607 * _2607)) / max(abs(dot(n, world - fa_light_texel(param_12).xyz)) / max(dot(_2557, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2634 = _2494.y;\n    float _2636;\n    if (_2634 > 0.0f)\n    {\n        _2636 = _2634;\n    }\n    else\n    {\n        _2636 = 1.5f * _2579;\n    }\n    float4 _2656 = float4(world + (n * (_2636 * sqrt(1.0f - (_2584 * _2584)))), 1.0f);\n    float _2660 = dot(_2557, _2656);\n    float _2663 = _2567.y;\n    if (_2660 < _2663)\n    {\n        return 1.0f;\n    }\n    float2 _2678 = float2(dot(fa_light_texel(param_6), _2656), dot(fa_light_texel(param_7), _2656)) / _2660.xx;\n    float _2680 = _2678.x;\n    bool _2683 = _2680 < _2562.x;\n    bool _2692;\n    if (!_2683)\n    {\n        _2692 = _2680 > _2562.z;\n    }\n    else\n    {\n        _2692 = _2683;\n    }\n    bool _2701;\n    if (!_2692)\n    {\n        _2701 = _2678.y < _2562.y;\n    }\n    else\n    {\n        _2701 = _2692;\n    }\n    bool _2710;\n    if (!_2701)\n    {\n        _2710 = _2678.y > _2562.w;\n    }\n    else\n    {\n        _2710 = _2701;\n    }\n    if (_2710)\n    {\n        return 1.0f;\n    }\n    float _2716 = _2494.x;\n    float _2718;\n    if (_2716 > 0.0f)\n    {\n        _2718 = _2716;\n    }\n    else\n    {\n        _2718 = 1.5f * _2579;\n    }\n    float2 param_13 = _2678;\n    float4 param_14 = _2562;\n    float param_15 = _2660 - (_2718 * (1.0f + (0.5f * _2631)));\n    float param_16 = _2579;\n    float param_17 = 1.0f;\n    float param_18 = _2567.z * 0.25f;\n    float param_19 = (_2579 * min(_2631, 3.0f)) * 0.5f;\n    float3 param_20 = float3(1.0f, _2663, _2567.z);\n    int param_21 = int(_2489.z + 0.5f);\n    float param_22 = _2489.w;\n    return lerp(1.0f, fa_shadow_filter(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _3110 = fa_lm.z > 0.5f;\n    bool _3116;\n    if (_3110)\n    {\n        int param = li;\n        _3116 = fa_light_baked(param);\n    }\n    else\n    {\n        _3116 = _3110;\n    }\n    if (_3116)\n    {\n        int param_1 = li;\n        LightSample _4139 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _4139;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3140 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _4141 = _3140.color;\n    float _4143 = _3140.shadow;\n    if ((_3140.type == 0) && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3140.direction;\n        float _3154 = fa_shadow_factor(param_5, param_6);\n        _4143 = _3154;\n        _4141 *= _3154;\n    }\n    else\n    {\n        bool _3165 = _3140.type != 0;\n        bool _3171;\n        if (_3165)\n        {\n            _3171 = _3140.attenuation > 0.0f;\n        }\n        else\n        {\n            _3171 = _3165;\n        }\n        if (_3171)\n        {\n            int param_7 = li;\n            float3 param_8 = world_pos;\n            float3 param_9 = gn;\n            float3 param_10 = _3140.direction;\n            float _3183 = fa_shadow_local(param_7, param_8, param_9, param_10);\n            _4143 = _3183;\n            _4141 *= _3183;\n        }\n    }\n    LightSample _4158 = { _3140.direction, _4141, _3140.attenuation, _4143, _3140._distance, _3140.type };\n    return _4158;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2021_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _2967 = int(_2021_fa_shadow_cfg.x + 0.5f);\n    float _2977 = dot(world - _2021_fa_shadow_eye.xyz, _2021_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _2982 = _2967 > 0;\n    bool _2991;\n    if (_2982)\n    {\n        int param = _2967 - 1;\n        _2991 = _2977 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2991 = _2982;\n    }\n    if (_2991)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _2997 = _2967 > 1;\n        bool _3004;\n        if (_2997)\n        {\n            _3004 = _2977 > _2021_fa_shadow_split.x;\n        }\n        else\n        {\n            _3004 = _2997;\n        }\n        if (_3004)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3010 = _2967 > 2;\n        bool _3017;\n        if (_3010)\n        {\n            _3017 = _2977 > _2021_fa_shadow_split.y;\n        }\n        else\n        {\n            _3017 = _3010;\n        }\n        if (_3017)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3023 = _2967 > 3;\n        bool _3030;\n        if (_3023)\n        {\n            _3030 = _2977 > _2021_fa_shadow_split.z;\n        }\n        else\n        {\n            _3030 = _3023;\n        }\n        if (_3030)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _3982 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3982 = -_3982;\n    }\n    float3 _3566 = normalize(_314_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _3995 = { fa_world_pos, _3982, fa_world_tangent, fa_uv, fa_vertex_color, _3566, gl_FrontFacing };\n    SurfaceInput param_1 = _3995;\n    Surface _3574 = fa_standard_surface(param_1);\n    float3 _4013 = _3574.albedo;\n    float _4014 = _3574.alpha;\n    float3 _4015 = _3574.normal;\n    float _4016 = _3574.metallic;\n    float _4017 = _3574.roughness;\n    float _4018 = _3574.occlusion;\n    float3 _4019 = _3574.emission;\n    float _4020 = _3574.clearcoat;\n    float _4021 = _3574.clearcoat_roughness;\n    float3 _4022 = _3574.sheen_color;\n    float _4023 = _3574.sheen_roughness;\n    float _4024 = _3574.anisotropy;\n    float _4025 = _3574.anisotropy_rotation;\n    float _4026 = _3574.specular;\n    float _4027 = _3574.ior;\n    float3 _4028 = _3574.specular_color;\n    SurfaceInput _4003 = { fa_world_pos, _3982, fa_world_tangent, fa_uv, fa_vertex_color, _3566, gl_FrontFacing };\n    SurfaceInput param_2 = _4003;\n    Surface param_3 = _3574;\n    surface(param_2, param_3);\n    _4013 = param_3.albedo;\n    _4014 = param_3.alpha;\n    _4015 = param_3.normal;\n    _4016 = param_3.metallic;\n    _4017 = param_3.roughness;\n    _4018 = param_3.occlusion;\n    _4019 = param_3.emission;\n    _4020 = param_3.clearcoat;\n    _4021 = param_3.clearcoat_roughness;\n    _4022 = param_3.sheen_color;\n    _4023 = param_3.sheen_roughness;\n    _4024 = param_3.anisotropy;\n    _4025 = param_3.anisotropy_rotation;\n    _4026 = param_3.specular;\n    _4027 = param_3.ior;\n    _4028 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _3982;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4013 = param_6;\n    _4015 = param_7;\n    float3 result;\n    if (_314_fa_emissive.w > 0.5f)\n    {\n        result = _4013;\n    }\n    else\n    {\n        float3 _3612 = _4015;\n        float3 _3613 = normalize(_3612);\n        _4015 = _3613;\n        float3 param_8 = _3613;\n        float3 lit = (fa_indirect_diffuse(param_8) * _4013) * _4018;\n        int _3632 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3632; ln++)\n        {\n            int param_9 = ln;\n            int _3645 = fa_cl_light(param_9);\n            bool _3648 = fa_lm.z > 0.5f;\n            bool _3654;\n            if (_3648)\n            {\n                int param_10 = _3645;\n                _3654 = fa_light_baked(param_10);\n            }\n            else\n            {\n                _3654 = _3648;\n            }\n            if (_3654)\n            {\n                continue;\n            }\n            int param_11 = _3645;\n            float3 param_12 = fa_world_pos;\n            float3 param_13 = _3982;\n            LightSample _3666 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput _4011 = { fa_world_pos, _3982, fa_world_tangent, fa_uv, fa_vertex_color, _3566, gl_FrontFacing };\n            SurfaceInput param_14 = _4011;\n            Surface _4094 = { _4013, _4014, _4015, _4016, _4017, _4018, _4019, _4020, _4021, _4022, _4023, _4024, _4025, _4026, _4027, _4028 };\n            Surface param_15 = _4094;\n            LightSample param_16 = _3666;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    float3 _3681 = result;\n    float3 _3682 = _3681 + _4019;\n    result = _3682;\n    float3 param_17 = _3682;\n    float3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _3691 = _314_fa_fog.w > 0.0f;\n    bool _3698;\n    if (!_3691)\n    {\n        _3698 = _314_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _3698 = _3691;\n    }\n    if (_3698)\n    {\n        float3 _3707 = fa_world_pos - _314_fa_camera_pos.xyz;\n        float _3713 = dot(_3707, _314_fa_fog_c.xyz);\n        bool _3717 = _314_fa_fog_c.w > 0.5f;\n        float _3718;\n        if (_3717)\n        {\n            _3718 = _3713;\n        }\n        else\n        {\n            _3718 = length(_3707);\n        }\n        float _3730 = _3718 - _314_fa_fog_b.x;\n        if (_3730 > 0.0f)\n        {\n            float _3739 = _314_fa_fog.w * _3730;\n            float tau = _3739 * _3739;\n            if (_314_fa_fog_b.y > 0.0f)\n            {\n                float _3755;\n                if (_3717)\n                {\n                    _3755 = fa_world_pos.y - (_314_fa_fog_c.y * _3713);\n                }\n                else\n                {\n                    _3755 = _314_fa_camera_pos.y;\n                }\n                float _3776 = lerp(_3755, fa_world_pos.y, clamp(_314_fa_fog_b.x / _3718, 0.0f, 1.0f));\n                float _3780 = fa_world_pos.y - _3776;\n                float _3785 = _3776 - _314_fa_fog_b.z;\n                float _3790 = fa_world_pos.y - _314_fa_fog_b.z;\n                bool _3793 = _3785 <= 0.0f;\n                bool _3794 = !_3793;\n                bool _3800;\n                if (_3794)\n                {\n                    _3800 = _314_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3800 = _3793;\n                }\n                float _3801;\n                if (_3800)\n                {\n                    _3801 = _314_fa_fog_b.y;\n                }\n                else\n                {\n                    _3801 = _314_fa_fog_b.y * exp(-min(_314_fa_fog_b.w * _3785, 80.0f));\n                }\n                bool _3828;\n                if (_3794)\n                {\n                    _3828 = _314_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3828 = _3793;\n                }\n                float _3829;\n                if (_3828)\n                {\n                    _3829 = _314_fa_fog_b.y * _3785;\n                }\n                else\n                {\n                    _3829 = (_314_fa_fog_b.y * (1.0f - exp(-min(_314_fa_fog_b.w * _3785, 80.0f)))) / _314_fa_fog_b.w;\n                }\n                bool _3854 = _3790 <= 0.0f;\n                bool _3861;\n                if (!_3854)\n                {\n                    _3861 = _314_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3861 = _3854;\n                }\n                float _3862;\n                if (_3861)\n                {\n                    _3862 = _314_fa_fog_b.y * _3790;\n                }\n                else\n                {\n                    _3862 = (_314_fa_fog_b.y * (1.0f - exp(-min(_314_fa_fog_b.w * _3790, 80.0f)))) / _314_fa_fog_b.w;\n                }\n                float _3889;\n                if (abs(_3780) < 0.001000000047497451305389404296875f)\n                {\n                    _3889 = _3801;\n                }\n                else\n                {\n                    _3889 = (_3862 - _3829) / _3780;\n                }\n                tau += (_3730 * max(_3889, 0.0f));\n            }\n            result = lerp(result, _314_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4014);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_2021",
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
