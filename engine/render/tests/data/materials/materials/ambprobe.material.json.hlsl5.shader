{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "21384afe6cb0557eed79a6c482a811939939d99108959ca6157b877697a348a6",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _260 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _260;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_267, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _396_fa_camera_pos : packoffset(c0);\n    float4 _396_fa_ambient : packoffset(c1);\n    float4 _396_fa_base_color : packoffset(c2);\n    float4 _396_fa_emissive : packoffset(c3);\n    float4 _396_fa_model_emissive : packoffset(c4);\n    float4 _396_fa_pbr : packoffset(c5);\n    float4 _396_fa_maps : packoffset(c6);\n    float4 _396_fa_fog : packoffset(c7);\n    float4 _396_fa_fog_b : packoffset(c8);\n    float4 _396_fa_fog_c : packoffset(c9);\n    float4 _396_fa_counts : packoffset(c10);\n    float4 _396_fa_env_sky : packoffset(c11);\n    float4 _396_fa_env_horizon : packoffset(c12);\n    float4 _396_fa_time : packoffset(c13);\n    float4 _396_fa_cl_vpx : packoffset(c14);\n    float4 _396_fa_cl_vpy : packoffset(c15);\n    float4 _396_fa_cl_vpw : packoffset(c16);\n    float4 _396_fa_cl_fwd : packoffset(c17);\n    float4 _396_fa_cl_grid : packoffset(c18);\n    float4 _396_fa_cl_info : packoffset(c19);\n    float4 _396_fa_layers_a : packoffset(c20);\n    float4 _396_fa_layers_b : packoffset(c21);\n    float4 _396_fa_layers_c : packoffset(c22);\n    float4 _396_fa_layers_d : packoffset(c23);\n    float4 _396_fa_ct_a : packoffset(c24);\n    float4 _396_fa_ct_b : packoffset(c25);\n    float4 _396_fa_ct_vpx : packoffset(c26);\n    float4 _396_fa_ct_vpy : packoffset(c27);\n    float4 _396_fa_ct_vpw : packoffset(c28);\n    float4 _396_fa_ct_fwd : packoffset(c29);\n    float4 _396_fa_probe_sh[9] : packoffset(c30);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2053_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2053_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2053_fa_shadow_info[4] : packoffset(c20);\n    float4 _2053_fa_shadow_split : packoffset(c24);\n    float4 _2053_fa_shadow_cfg : packoffset(c25);\n    float4 _2053_fa_shadow_bias : packoffset(c26);\n    float4 _2053_fa_shadow_eye : packoffset(c27);\n    float4 _2053_fa_shadow_fwd : packoffset(c28);\n    float4 _2053_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_screen_tex : register(t11);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1324 = _396_fa_cl_info.x < 0.0f;\n    bool _1331;\n    if (!_1324)\n    {\n        _1331 = _396_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1331 = _1324;\n    }\n    bool _1339;\n    if (!_1331)\n    {\n        _1339 = _396_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1339 = _1331;\n    }\n    bool _1346;\n    if (!_1339)\n    {\n        _1346 = _396_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1346 = _1339;\n    }\n    bool _1353;\n    if (!_1346)\n    {\n        _1353 = _396_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1353 = _1346;\n    }\n    if (_1353)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1363 = float4(world_pos, 1.0f);\n    float _1369 = dot(_396_fa_cl_vpw, _1363);\n    if (!(_1369 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1391 = float2(dot(_396_fa_cl_vpx, _1363), dot(_396_fa_cl_vpy, _1363)) / _1369.xx;\n    int _1395 = int(_396_fa_cl_grid.x);\n    int _1399 = int(_396_fa_cl_grid.y);\n    int param = (int(_396_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_396_fa_cl_fwd.xyz, world_pos) + _396_fa_cl_fwd.w, _396_fa_cl_grid.w) / _396_fa_cl_grid.w) * _396_fa_cl_grid.z)), 0, int(_396_fa_cl_info.y) - 1) * _1399) + clamp(int(floor(((_1391.y * 0.5f) + 0.5f) * _396_fa_cl_grid.y)), 0, _1399 - 1)) * _1395)) + clamp(int(floor(((_1391.x * 0.5f) + 0.5f) * _396_fa_cl_grid.x)), 0, _1395 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1475 = fa_cluster_texel(param);\n    return int2(int(_1475.x), int(_1475.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_396_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3534 = fa_cluster_lookup(param);\n    fa_cl_slot = _3534.x;\n    fa_cl_local = _3534.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _3742 = fa_linear_to_srgb(param);\n        c = _3742;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _3750 = fa_srgb_to_linear(param_1);\n            c = _3750;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _278;\n    if (i.front_facing)\n    {\n        _278 = i.world_normal;\n    }\n    else\n    {\n        _278 = -i.world_normal;\n    }\n    float3 _302 = normalize(i.world_tangent.xyz - (_278 * dot(_278, i.world_tangent.xyz)));\n    float3 _329 = normalize(((_302 * m.x) + ((cross(_278, _302) * i.world_tangent.w) * m.y)) + (_278 * m.z));\n    float3 _332;\n    if (i.front_facing)\n    {\n        _332 = _329;\n    }\n    else\n    {\n        _332 = -_329;\n    }\n    return _332;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _396_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3781 = fa_tex_fix(param_2, param_3);\n    float4 _4872 = base_t;\n    _4872.x = _3781.x;\n    _4872.y = _3781.y;\n    _4872.z = _3781.z;\n    base_t = _4872;\n    float4 _3795 = (_4872 * _396_fa_base_color) * i.vertex_color;\n    float3 _4724 = i.world_normal;\n    if (_396_fa_maps.z > 0.5f)\n    {\n        float param_4 = _396_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3827 = fa_tex_fix(param_6, param_7);\n        float3 _3830 = (_3827 * 2.0f) - 1.0f.xxx;\n        float2 _3835 = _3830.xy * _396_fa_maps.x;\n        float3 _4880 = _3830;\n        _4880.x = _3835.x;\n        _4880.y = _3835.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4880;\n        _4724 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _396_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3863 = fa_tex_fix(param_12, param_13);\n    float4 _4883 = mrt;\n    _4883.x = _3863.x;\n    _4883.y = _3863.y;\n    _4883.z = _3863.z;\n    mrt = _4883;\n    float4 _3891 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _396_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _3891.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3902 = fa_tex_fix(param_16, param_17);\n    float param_18 = _396_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3932 = fa_tex_fix(param_20, param_21);\n    float _4729 = _396_fa_layers_a.x;\n    float _4730 = _396_fa_layers_a.y;\n    float _4733 = _396_fa_layers_a.z;\n    float _4732 = _396_fa_layers_b.w;\n    float _4735 = _396_fa_layers_c.x;\n    if (_396_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_396_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _4729 *= _3902.y;\n            _4730 *= _3902.z;\n            _4732 *= _3891.w;\n        }\n        if (_396_fa_layers_c.z > 1.5f)\n        {\n            _4733 *= mrt.x;\n            _4735 *= mrt.w;\n        }\n    }\n    Surface _4754 = { _3795.xyz, _3795.w, _4724, clamp(_396_fa_pbr.x * _3863.z, 0.0f, 1.0f), clamp(_396_fa_pbr.y * _3863.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_396_fa_maps.y * (_3902.x - 1.0f)), _396_fa_emissive.xyz + (_396_fa_model_emissive.xyz * _3932), _4729, _4730, _396_fa_layers_b.xyz, _4732, _4733, _396_fa_layers_a.w, _4735, _396_fa_layers_c.y, _396_fa_layers_d.xyz };\n    return _4754;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1555 = rect.zw - rect.xy;\n    float2 _1559 = _1555 * atlas;\n    float2 _1563 = ddx * _1559;\n    float2 _1567 = ddy * _1559;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1555), clamp(0.5f * log2(max(max(dot(_1563, _1563), dot(_1567, _1567)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1600 = _396_fa_counts.y < 0.5f;\n    bool _1607;\n    if (!_1600)\n    {\n        _1607 = _396_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1607 = _1600;\n    }\n    if (_1607)\n    {\n        return;\n    }\n    float3 _1613 = ddx(world_pos);\n    float3 _1616 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1620 = fa_cluster_texel(param);\n    int _1624 = int(_1620.w);\n    if (_1624 < 1)\n    {\n        return;\n    }\n    int _1634 = int(_396_fa_counts.y + 0.5f);\n    int param_1 = _1634;\n    float4 _1638 = fa_light_texel(param_1);\n    float2 _1641 = _1638.yz;\n    int _1645 = int(_1638.w);\n    int param_2 = _1634 + 1;\n    float4 _1650 = fa_light_texel(param_2);\n    float _1651 = _1650.x;\n    int _1657 = int(_396_fa_counts.w + 0.5f) - 1;\n    int _1661 = int(_1620.z);\n    float3 _1926;\n    for (int k = 0; k < _1624; k++)\n    {\n        int _1674 = _1661 + k;\n        int param_3 = _1645 + (_1674 >> 2);\n        int _1691 = (_1634 + 2) + (int(fa_light_texel(param_3)[_1674 & 3]) * 7);\n        int param_4 = _1691 + 6;\n        float4 _1696 = fa_light_texel(param_4);\n        if (((int(_1696.w + 0.5f) >> _1657) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1691;\n        float4 _1711 = fa_light_texel(param_5);\n        int param_6 = _1691 + 1;\n        float4 _1716 = fa_light_texel(param_6);\n        int param_7 = _1691 + 2;\n        float4 _1721 = fa_light_texel(param_7);\n        float3 _1724 = _1711.xyz;\n        float _1729 = dot(_1724, world_pos) + _1711.w;\n        float3 _1731 = _1716.xyz;\n        float _1736 = dot(_1731, world_pos) + _1716.w;\n        float3 _1738 = _1721.xyz;\n        float _1743 = dot(_1738, world_pos) + _1721.w;\n        bool _1748 = abs(_1729) > 0.5f;\n        bool _1756;\n        if (!_1748)\n        {\n            _1756 = abs(_1736) > 0.5f;\n        }\n        else\n        {\n            _1756 = _1748;\n        }\n        bool _1764;\n        if (!_1756)\n        {\n            _1764 = abs(_1743) > 0.5f;\n        }\n        else\n        {\n            _1764 = _1756;\n        }\n        if (_1764)\n        {\n            continue;\n        }\n        float _1779 = clamp(dot(geo_normal, normalize(_1738)) * _1696.z, 0.0f, 1.0f);\n        if (_1779 <= 0.0f)\n        {\n            continue;\n        }\n        float _1799 = (clamp((0.5f - abs(_1743)) * 10.0f, 0.0f, 1.0f) * _1779) * _1696.x;\n        float2 _1807 = float2(_1729 + 0.5f, 0.5f - _1736);\n        float2 _1817 = float2(dot(_1724, _1613), dot(_1731, _1613));\n        float2 _1827 = float2(dot(_1724, _1616), dot(_1731, _1616));\n        int param_8 = _1691 + 5;\n        float4 _1832 = fa_light_texel(param_8);\n        int param_9 = _1691 + 3;\n        float4 _1837 = fa_light_texel(param_9);\n        int param_10 = _1691 + 4;\n        float4 _1842 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1832.xyz;\n        bool _1852 = _1837.z > _1837.x;\n        if (_1852)\n        {\n            float4 param_11 = _1837;\n            float2 param_12 = _1807;\n            float2 param_13 = _1641;\n            float2 param_14 = _1817;\n            float2 param_15 = _1827;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1651 > 0.5f) && (_1651 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1878 = fa_dc_to_linear(param_16);\n                float4 _4804 = tx;\n                _4804.x = _1878.x;\n                _4804.y = _1878.y;\n                _4804.z = _1878.z;\n                tx = _4804;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1799 * tex_a) * _1832.w, 0.0f, 1.0f).xxx);\n        if (_1842.z > _1842.x)\n        {\n            float4 param_17 = _1842;\n            float2 param_18 = _1807;\n            float2 param_19 = _1641;\n            float2 param_20 = _1817;\n            float2 param_21 = _1827;\n            float4 _1922 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1651 > 1.5f)\n            {\n                float3 param_22 = _1922.xyz;\n                float3 _1932 = fa_dc_to_srgb(param_22);\n                _1926 = _1932;\n            }\n            else\n            {\n                _1926 = _1922.xyz;\n            }\n            float3 _1941 = (_1926 * 2.0f) - 1.0f.xxx;\n            float2 _1946 = _1941.xy * _1696.y;\n            float3 _1968 = (normalize(_1724) * _1946.x) + (normalize(_1731) * _1946.y);\n            float3 _1971 = normalize(normal);\n            normal = normalize(lerp(_1971, normalize((_1971 * max(_1941.z, 0.0500000007450580596923828125f)) + (_1968 - (_1971 * dot(_1971, _1968)))), clamp(_1799 * (_1852 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_sky_sh_coef(int k)\n{\n    float3 v = fa_env_tex.SampleLevel(fa_env_smp, float3(1.0f, 1.0f - (float((2 * (k >> 2)) + 1) * 0.25f), 1.0f - (float((2 * (k & 3)) + 1) * 0.25f)), 5.0f).xyz;\n    if (_396_fa_env_sky.w > 1.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3166 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3166;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_396_fa_env_sky.w > 0.5f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _396_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_396_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _396_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_396_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    return ambientColor;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_396_fa_cl_info.x) + int(_396_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_396_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _3504;\n    if (fa_lm.z > 0.5f)\n    {\n        _3504 = 0.0f;\n    }\n    else\n    {\n        _3504 = 1.0f - clamp(_396_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _3515 = _3504 < 1.0f;\n    bool _3521;\n    if (_3515)\n    {\n        int param = li;\n        _3521 = fa_light_baked(param);\n    }\n    else\n    {\n        _3521 = _3515;\n    }\n    return _3521 ? _3504 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _455_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _455_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _574 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _587 = (c - (ru * hx)) - p;\n        float3 _593 = ru * (2.0f * hx);\n        float _599 = max(dot(_593, _593), 9.9999999392252902907785028219223e-09f);\n        float _603 = dot(_587, _593);\n        float t = clamp((-_603) / _599, 0.0f, 1.0f);\n        if (_574)\n        {\n            float _618 = dot(r, _593);\n            float _624 = _599 - (_618 * _618);\n            if (abs(_624) > (9.9999997473787516355514526367188e-06f * _599))\n            {\n                t = clamp(((dot(r, _587) * _618) - _603) / _624, 0.0f, 1.0f);\n            }\n        }\n        return (p + _587) + (_593 * t);\n    }\n    float3 q = p;\n    float _656 = dot(r, axis);\n    bool _664;\n    if (_574)\n    {\n        _664 = abs(_656) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _664 = _574;\n    }\n    if (_664)\n    {\n        float _674 = dot(c - p, axis) / _656;\n        if (_674 > 0.0f)\n        {\n            q = p + (r * _674);\n        }\n    }\n    float3 _687 = q - c;\n    float2 xy = float2(dot(_687, ru), dot(_687, uu));\n    if (shape > 0.5f)\n    {\n        float _702 = length(xy);\n        if (_702 > hx)\n        {\n            xy *= (hx / _702);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _344 = abs(d);\n    float _346 = _344.x;\n    float _348 = _344.y;\n    bool _349 = _346 >= _348;\n    bool _357;\n    if (_349)\n    {\n        _357 = _346 >= _344.z;\n    }\n    else\n    {\n        _357 = _349;\n    }\n    int _358;\n    if (_357)\n    {\n        _358 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _373;\n        if (_348 >= _344.z)\n        {\n            _373 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _373 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _358 = _373;\n    }\n    return _358;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _494 = dot(d, right);\n    float _498 = dot(d, up);\n    float _509;\n    if (((_494 * _494) + (_498 * _498)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _509 = atan2(_498, _494) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _509 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_509 - floor(_509)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _740 = fa_light_base(param);\n    bool _744 = _396_fa_ambient.w > 4.5f;\n    int param_1 = _740;\n    float4 _748 = fa_light_texel(param_1);\n    int param_2 = _740 + 1;\n    float4 _753 = fa_light_texel(param_2);\n    float _756 = _753.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _768 = _744 && (_756 > 2.5f);\n    fa_light_is_area = _768;\n    bool _770 = _756 < 0.5f;\n    float3 l;\n    if (_770)\n    {\n        l = normalize(_748.xyz);\n        if (_744)\n        {\n            int param_3 = _740 + 6;\n            float4 _784 = fa_light_texel(param_3);\n            if (_784.z > 0.5f)\n            {\n                int param_4 = _740 + 4;\n                float4 _794 = fa_light_texel(param_4);\n                int param_5 = _740 + 5;\n                float4 _799 = fa_light_texel(param_5);\n                float2 param_6 = _784.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _794.xyz) * _794.w, (-dot(world_pos, _799.xyz)) * _799.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _829 = _748.xyz;\n        float3 _831 = _829 - world_pos;\n        float3 to_light = _831;\n        float _834 = length(_831);\n        float reach = _834;\n        bool front = true;\n        if (_768)\n        {\n            int param_8 = _740 + 7;\n            reach = max(_834 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _740 + 4;\n            float4 _858 = fa_light_texel(param_9);\n            int param_10 = _740 + 5;\n            float4 _863 = fa_light_texel(param_10);\n            int param_11 = _740 + 6;\n            float4 _868 = fa_light_texel(param_11);\n            float _869 = _868.w;\n            int param_12 = _740 + 2;\n            float3 _876 = normalize(fa_light_texel(param_12).xyz);\n            bool _878 = _869 > 1.5f;\n            bool _886;\n            if (!_878)\n            {\n                _886 = dot(_876, to_light) < 0.0f;\n            }\n            else\n            {\n                _886 = _878;\n            }\n            front = _886;\n            float3 r = 0.0f.xxx;\n            float3 _895 = _396_fa_camera_pos.xyz - world_pos;\n            bool _899 = dot(n, n) > 0.5f;\n            bool _907;\n            if (_899)\n            {\n                _907 = dot(_895, _895) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _907 = _899;\n            }\n            if (_907)\n            {\n                r = reflect(-normalize(_895), normalize(n));\n            }\n            float3 param_13 = _829;\n            float3 param_14 = _876;\n            float3 param_15 = _858.xyz;\n            float3 param_16 = _863.xyz;\n            float param_17 = _858.w;\n            float param_18 = _863.w;\n            float param_19 = _869;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _943 = length(to_light);\n        dist = _943;\n        l = to_light / max(_943, 9.9999997473787516355514526367188e-05f).xxx;\n        float _957 = reach / max(_748.w, 0.001000000047497451305389404296875f);\n        float _963 = clamp(1.0f - (_957 * _957), 0.0f, 1.0f);\n        float _965;\n        if (front)\n        {\n            _965 = _963 * _963;\n        }\n        else\n        {\n            _965 = 0.0f;\n        }\n        atten = _965;\n        bool _976 = _756 < 2.5f;\n        if ((_756 > 1.5f) && _976)\n        {\n            int param_22 = _740 + 2;\n            float4 _984 = fa_light_texel(param_22);\n            float _994 = _984.w;\n            int param_23 = _740 + 3;\n            float4 _999 = fa_light_texel(param_23);\n            float _1000 = _999.x;\n            float cos_inner = _1000;\n            if (_1000 > 1.5f)\n            {\n                cos_inner = lerp(_994, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_994, cos_inner, dot(-l, normalize(_984.xyz)));\n        }\n        if (_744 && (_756 < 1.5f))\n        {\n            int param_24 = _740 + 6;\n            float4 _1024 = fa_light_texel(param_24);\n            if (_1024.z > 0.5f)\n            {\n                float3 _1032 = -to_light;\n                int param_25 = _740 + 4;\n                int param_26 = _740 + 5;\n                float3 _1046 = fa_light_texel(param_25).xyz;\n                float3 _1050 = fa_light_texel(param_26).xyz;\n                float3 _1059 = float3(dot(_1032, _1046), dot(_1032, _1050), dot(_1032, cross(_1046, _1050)));\n                float3 param_27 = _1059;\n                int _1063 = fa_cube_face(param_27);\n                int param_28 = _1063;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1090 = float2(dot(_1059, cross(param_29, param_30)), dot(_1059, param_30)) / max(dot(_1059, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1094 = _1063 / 3;\n                float2 param_31 = _1024.xy + (float2(float(_1063 - (_1094 * 3)), float(_1094)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1090.x), 0.5f - (0.5f * _1090.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _740 + 7;\n            float4 _1124 = fa_light_texel(param_33);\n            if (_1124.z > 0.5f)\n            {\n                int param_34 = _740 + 2;\n                int param_35 = _740 + 4;\n                int param_36 = _740 + 5;\n                float2 param_37 = _1124.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_744 && _976)\n            {\n                int param_42 = _740 + 6;\n                float4 _1171 = fa_light_texel(param_42);\n                int param_43 = _740 + 7;\n                float4 _1176 = fa_light_texel(param_43);\n                bool _1179 = _1171.z > 0.5f;\n                bool _1186;\n                if (!_1179)\n                {\n                    _1186 = _1176.z > 0.5f;\n                }\n                else\n                {\n                    _1186 = _1179;\n                }\n                if (_1186)\n                {\n                    int param_44 = _740 + 2;\n                    float4 _1193 = fa_light_texel(param_44);\n                    float3 _1197 = normalize(_1193.xyz);\n                    int param_45 = _740 + 4;\n                    float4 _1202 = fa_light_texel(param_45);\n                    int param_46 = _740 + 5;\n                    float4 _1207 = fa_light_texel(param_46);\n                    if (_1179)\n                    {\n                        float3 _1215 = -to_light;\n                        float _1222 = _1193.w;\n                        float _1238 = 0.5f / max(dot(_1215, _1197) * (sqrt(max(1.0f - (_1222 * _1222), 0.0f)) / max(_1222, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1171.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1215, _1202.xyz) * _1238), 0.5f - (dot(_1215, _1207.xyz) * _1238));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1176.z > 0.5f)\n                    {\n                        float2 param_49 = _1176.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1197;\n                        float3 param_52 = _1202.xyz;\n                        float3 param_53 = _1207.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4678 = _753.xyz * atten;\n    if (_744)\n    {\n        _4678 *= fa_light_tint;\n    }\n    int _1306;\n    if (_770)\n    {\n        _1306 = 0;\n    }\n    else\n    {\n        _1306 = ((_756 > 1.5f) && (_756 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _4689 = { l, _4678, atten, 1.0f, dist, _1306 };\n    return _4689;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2043;\n    if (i == 0)\n    {\n        _2043 = _2053_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2059;\n        if (i == 1)\n        {\n            _2059 = _2053_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2067;\n            if (i == 2)\n            {\n                _2067 = _2053_fa_shadow_split.z;\n            }\n            else\n            {\n                _2067 = _2053_fa_shadow_split.w;\n            }\n            _2059 = _2067;\n        }\n        _2043 = _2059;\n    }\n    return _2043;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2100 = fa_shadow_depth(param, param_1);\n    float _2104;\n    if (conv.x < 0.5f)\n    {\n        _2104 = _2100;\n    }\n    else\n    {\n        _2104 = (conv.y * conv.z) / (conv.z - (_2100 * (conv.z - conv.y)));\n    }\n    return _2104;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2031 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2031), sin(_2031)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2150 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2159;\n        if (k < 0.0f)\n        {\n            _2159 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2159 = k;\n        }\n        float _2179 = clamp((_2159 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2150;\n            float2 _2198 = fa_shadow_vogel(param_3, param_4, param_5) * _2179;\n            float2 param_6 = uv + (_2198 * _2053_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2210 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2210 < (zr - (length(_2198) * plane)))\n            {\n                sum += _2210;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2236 = sum / cnt;\n        float _2246;\n        if (k < 0.0f)\n        {\n            _2246 = (-k) / max(_2236, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2246 = k;\n        }\n        radius = clamp(((max(zr - _2236, 0.0f) * unit) * _2246) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2268 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2268; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2268;\n        float param_11 = _2150;\n        float2 _2287 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2287 * _2053_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2287) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2268);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2329 = max(_2053_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2334 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2340 = sqrt(1.0f - (_2334 * _2334));\n    float _2347 = min(_2340 / max(_2334, 0.20000000298023223876953125f), 4.0f);\n    float _2352;\n    if (_2053_fa_shadow_bias.y > 0.0f)\n    {\n        _2352 = _2053_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2352 = 1.5f * _2053_fa_shadow_info[ci].x;\n    }\n    float4 _2377 = mul(float4(world + (n * (_2352 * _2340)), 1.0f), _2053_fa_shadow_mat[ci]);\n    float _2384 = _2377.x;\n    bool _2387 = _2384 < _2053_fa_shadow_rect[ci].x;\n    bool _2396;\n    if (!_2387)\n    {\n        _2396 = _2384 > _2053_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2396 = _2387;\n    }\n    bool _2405;\n    if (!_2396)\n    {\n        _2405 = _2377.y < _2053_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2405 = _2396;\n    }\n    bool _2414;\n    if (!_2405)\n    {\n        _2414 = _2377.y > _2053_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2414 = _2405;\n    }\n    bool _2421;\n    if (!_2414)\n    {\n        _2421 = _2377.z > 1.0f;\n    }\n    else\n    {\n        _2421 = _2414;\n    }\n    if (_2421)\n    {\n        return -1.0f;\n    }\n    float _2429;\n    if (_2053_fa_shadow_bias.x > 0.0f)\n    {\n        _2429 = _2053_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2429 = 1.5f * _2053_fa_shadow_info[ci].x;\n    }\n    float2 param = _2377.xy;\n    float4 param_1 = _2053_fa_shadow_rect[ci];\n    float param_2 = _2377.z - ((_2429 * (1.0f + (0.5f * _2347))) / _2329);\n    float param_3 = _2053_fa_shadow_info[ci].x;\n    float param_4 = _2329;\n    float param_5 = _2329 * 0.25f;\n    float param_6 = ((_2053_fa_shadow_info[ci].x * min(_2347, 3.0f)) * 0.5f) / _2329;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2053_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2053_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_396_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2807 = int(_2053_fa_shadow_cfg.x + 0.5f);\n    if (_2807 < 1)\n    {\n        return 1.0f;\n    }\n    float _2822 = dot(world - _2053_fa_shadow_eye.xyz, _2053_fa_shadow_fwd.xyz);\n    int param = _2807 - 1;\n    if (_2822 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2834 = _2807 > 1;\n    bool _2841;\n    if (_2834)\n    {\n        _2841 = _2822 > _2053_fa_shadow_split.x;\n    }\n    else\n    {\n        _2841 = _2834;\n    }\n    if (_2841)\n    {\n        ci = 1;\n    }\n    bool _2845 = _2807 > 2;\n    bool _2852;\n    if (_2845)\n    {\n        _2852 = _2822 > _2053_fa_shadow_split.y;\n    }\n    else\n    {\n        _2852 = _2845;\n    }\n    if (_2852)\n    {\n        ci = 2;\n    }\n    bool _2856 = _2807 > 3;\n    bool _2863;\n    if (_2856)\n    {\n        _2863 = _2822 > _2053_fa_shadow_split.z;\n    }\n    else\n    {\n        _2863 = _2856;\n    }\n    if (_2863)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2807)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2889 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2889;\n        if (_2889 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2053_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2914;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2914 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2914 = _2053_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2933 = _2053_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2914, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2944 = clamp((_2822 - (fa_shadow_split_at(param_7) - _2933)) / _2933, 0.0f, 1.0f);\n        if (_2944 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2807)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2965 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2965;\n                if (_2965 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2944);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2487 = _396_fa_pbr.z < 0.5f;\n    bool _2494;\n    if (!_2487)\n    {\n        _2494 = _2053_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2494 = _2487;\n    }\n    if (_2494)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2053_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2507 = fa_light_texel(param);\n    float _2508 = _2507.x;\n    if (_2508 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2517 = int(_2508 + 0.5f);\n    int param_1 = _2517;\n    float4 _2521 = fa_light_texel(param_1);\n    int param_2 = _2517 + 1;\n    float4 _2526 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2529 = _2521.y;\n    if (_2529 > 0.0f)\n    {\n        float _2546 = 1.0f - smoothstep(0.75f * _2529, _2529, length(world - _2053_fa_shadow_eye.xyz));\n        fade = _2546;\n        if (_2546 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2521.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2570 = (_2517 + 2) + (face * 6);\n    int param_4 = _2570;\n    int param_5 = _2570 + 1;\n    int param_6 = _2570 + 3;\n    float4 _2584 = fa_light_texel(param_6);\n    int param_7 = _2570 + 4;\n    float4 _2589 = fa_light_texel(param_7);\n    int param_8 = _2570 + 5;\n    float4 _2594 = fa_light_texel(param_8);\n    float _2606 = _2594.x * max(dot(_2584, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2611 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2634 = clamp(dot(n, _2584.xyz), -1.0f, 1.0f);\n    float _2653 = min(sqrt(1.0f - (_2634 * _2634)) / max(abs(dot(n, world - lpos)) / max(dot(_2584, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2656 = _2526.y;\n    float _2658;\n    if (_2656 > 0.0f)\n    {\n        _2658 = _2656;\n    }\n    else\n    {\n        _2658 = 1.5f * _2606;\n    }\n    float4 _2678 = float4(world + (n * (_2658 * sqrt(1.0f - (_2611 * _2611)))), 1.0f);\n    float _2682 = dot(_2584, _2678);\n    float _2685 = _2594.y;\n    if (_2682 < _2685)\n    {\n        return 1.0f;\n    }\n    float2 _2700 = float2(dot(fa_light_texel(param_4), _2678), dot(fa_light_texel(param_5), _2678)) / _2682.xx;\n    float _2702 = _2700.x;\n    bool _2705 = _2702 < _2589.x;\n    bool _2714;\n    if (!_2705)\n    {\n        _2714 = _2702 > _2589.z;\n    }\n    else\n    {\n        _2714 = _2705;\n    }\n    bool _2723;\n    if (!_2714)\n    {\n        _2723 = _2700.y < _2589.y;\n    }\n    else\n    {\n        _2723 = _2714;\n    }\n    bool _2732;\n    if (!_2723)\n    {\n        _2732 = _2700.y > _2589.w;\n    }\n    else\n    {\n        _2732 = _2723;\n    }\n    if (_2732)\n    {\n        return 1.0f;\n    }\n    float _2738 = _2526.x;\n    float _2740;\n    if (_2738 > 0.0f)\n    {\n        _2740 = _2738;\n    }\n    else\n    {\n        _2740 = 1.5f * _2606;\n    }\n    float2 param_9 = _2700;\n    float4 param_10 = _2589;\n    float param_11 = _2682 - (_2740 * (1.0f + (0.5f * _2653)));\n    float param_12 = _2606;\n    float param_13 = 1.0f;\n    float param_14 = _2594.z * 0.25f;\n    float param_15 = (_2606 * min(_2653, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2685, _2594.z);\n    int param_17 = int(_2521.z + 0.5f);\n    float param_18 = _2521.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _3246 = _396_fa_ct_a.x < 0.5f;\n    bool _3253;\n    if (!_3246)\n    {\n        _3253 = _2053_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _3253 = _3246;\n    }\n    if (_3253)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2053_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _3266 = fa_light_texel(param);\n    float _3267 = _3266.y;\n    float len = _3267;\n    if (_3267 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3279 = length(world - _396_fa_camera_pos.xyz);\n    float _3289 = 1.0f - smoothstep(0.5f * _396_fa_ct_b.x, _396_fa_ct_b.x, _3279);\n    if (_3289 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3295 = len;\n    float _3298 = min(_3295, 0.89999997615814208984375f * dist);\n    len = _3298;\n    float _3304 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _3279);\n    float _3309 = _3304 + (0.5f * _3298);\n    float3 _3315 = world + (gn * _3304);\n    float _3317 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _3382;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3333 = (float(k) + _3317) * 0.083333335816860198974609375f;\n        float3 _3341 = _3315 + (l * (_3333 * len));\n        float4 _3347 = float4(_3341, 1.0f);\n        float _3353 = dot(_396_fa_ct_vpw, _3347);\n        if (_3353 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _3373 = float2(dot(_396_fa_ct_vpx, _3347), dot(_396_fa_ct_vpy, _3347)) / _3353.xx;\n        float _3377 = _3373.x * 0.5f;\n        float _3378 = _3377 + 0.5f;\n        if (_396_fa_ct_a.y > 0.5f)\n        {\n            _3382 = (_3373.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _3382 = 0.5f - (_3373.y * 0.5f);\n        }\n        bool _3398 = _3378 < 0.0f;\n        bool _3405;\n        if (!_3398)\n        {\n            _3405 = _3378 >= 1.0f;\n        }\n        else\n        {\n            _3405 = _3398;\n        }\n        bool _3412;\n        if (!_3405)\n        {\n            _3412 = _3382 < 0.0f;\n        }\n        else\n        {\n            _3412 = _3405;\n        }\n        bool _3419;\n        if (!_3412)\n        {\n            _3419 = _3382 >= 1.0f;\n        }\n        else\n        {\n            _3419 = _3412;\n        }\n        if (_3419)\n        {\n            break;\n        }\n        float4 _3438 = fa_screen_tex.Load(int3(int2(float2(_3378, _3382) * _396_fa_ct_a.zw), 0));\n        if (_3438.w < 0.5f)\n        {\n            continue;\n        }\n        float _3457 = (dot(_396_fa_ct_fwd.xyz, _3341) + _396_fa_ct_fwd.w) - _3438.x;\n        if ((_3457 > _3304) && (_3457 < _3309))\n        {\n            occ = max(occ, (1.0f - (_3333 * _3333)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_3378, 0.5f - _3377), min(_3382, 1.0f - _3382))));\n        }\n    }\n    return 1.0f - (occ * _3289);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _3560 = fa_baked_keep(param);\n    if (_3560 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _4702 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _4702;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3586 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _4704 = _3586.color;\n    float _4705 = _3586.attenuation;\n    float _4706 = _3586.shadow;\n    bool _3589 = _3586.type == 0;\n    if (_3589 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3586.direction;\n        float _3600 = fa_shadow_factor(param_5, param_6);\n        _4706 = _3600;\n        _4704 *= _3600;\n    }\n    else\n    {\n        bool _3611 = _3586.type != 0;\n        bool _3617;\n        if (_3611)\n        {\n            _3617 = _4705 > 0.0f;\n        }\n        else\n        {\n            _3617 = _3611;\n        }\n        if (_3617)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _3586.direction;\n            float _3636 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _4706 = _3636;\n            _4704 *= _3636;\n        }\n    }\n    bool _3646 = _396_fa_ct_a.x > 0.5f;\n    bool _3652;\n    if (_3646)\n    {\n        _3652 = _4705 > 0.0f;\n    }\n    else\n    {\n        _3652 = _3646;\n    }\n    if (_3652)\n    {\n        float _3659;\n        if (_3589)\n        {\n            _3659 = 1000000000.0f;\n        }\n        else\n        {\n            _3659 = _3586._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _3586.direction;\n        float param_18 = _3659;\n        float _3677 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _4706 *= _3677;\n        _4704 *= _3677;\n    }\n    float _3690 = _4705;\n    float _3691 = _3690 * _3560;\n    _4705 = _3691;\n    float3 _3695 = _4704;\n    float3 _3696 = _3695 * _3560;\n    _4704 = _3696;\n    LightSample _4721 = { _3586.direction, _3696, _3691, _4706, _3586._distance, _3586.type };\n    return _4721;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2053_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _2989 = int(_2053_fa_shadow_cfg.x + 0.5f);\n    float _2999 = dot(world - _2053_fa_shadow_eye.xyz, _2053_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3004 = _2989 > 0;\n    bool _3013;\n    if (_3004)\n    {\n        int param = _2989 - 1;\n        _3013 = _2999 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3013 = _3004;\n    }\n    if (_3013)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3019 = _2989 > 1;\n        bool _3026;\n        if (_3019)\n        {\n            _3026 = _2999 > _2053_fa_shadow_split.x;\n        }\n        else\n        {\n            _3026 = _3019;\n        }\n        if (_3026)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3032 = _2989 > 2;\n        bool _3039;\n        if (_3032)\n        {\n            _3039 = _2999 > _2053_fa_shadow_split.y;\n        }\n        else\n        {\n            _3039 = _3032;\n        }\n        if (_3039)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3045 = _2989 > 3;\n        bool _3052;\n        if (_3045)\n        {\n            _3052 = _2999 > _2053_fa_shadow_split.z;\n        }\n        else\n        {\n            _3052 = _3045;\n        }\n        if (_3052)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _4520 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4520 = -_4520;\n    }\n    float3 _4111 = normalize(_396_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _4533 = { fa_world_pos, _4520, fa_world_tangent, fa_uv, fa_vertex_color, _4111, gl_FrontFacing };\n    SurfaceInput param_1 = _4533;\n    Surface _4119 = fa_standard_surface(param_1);\n    float3 _4559 = _4119.albedo;\n    float _4560 = _4119.alpha;\n    float3 _4561 = _4119.normal;\n    float _4562 = _4119.metallic;\n    float _4563 = _4119.roughness;\n    float _4564 = _4119.occlusion;\n    float3 _4565 = _4119.emission;\n    float _4566 = _4119.clearcoat;\n    float _4567 = _4119.clearcoat_roughness;\n    float3 _4568 = _4119.sheen_color;\n    float _4569 = _4119.sheen_roughness;\n    float _4570 = _4119.anisotropy;\n    float _4571 = _4119.anisotropy_rotation;\n    float _4572 = _4119.specular;\n    float _4573 = _4119.ior;\n    float3 _4574 = _4119.specular_color;\n    SurfaceInput _4541 = { fa_world_pos, _4520, fa_world_tangent, fa_uv, fa_vertex_color, _4111, gl_FrontFacing };\n    SurfaceInput param_2 = _4541;\n    Surface param_3 = _4119;\n    surface(param_2, param_3);\n    _4559 = param_3.albedo;\n    _4560 = param_3.alpha;\n    _4561 = param_3.normal;\n    _4562 = param_3.metallic;\n    _4563 = param_3.roughness;\n    _4564 = param_3.occlusion;\n    _4565 = param_3.emission;\n    _4566 = param_3.clearcoat;\n    _4567 = param_3.clearcoat_roughness;\n    _4568 = param_3.sheen_color;\n    _4569 = param_3.sheen_roughness;\n    _4570 = param_3.anisotropy;\n    _4571 = param_3.anisotropy_rotation;\n    _4572 = param_3.specular;\n    _4573 = param_3.ior;\n    _4574 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _4520;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4559 = param_6;\n    _4561 = param_7;\n    float3 result;\n    if (_396_fa_emissive.w > 0.5f)\n    {\n        result = _4559;\n    }\n    else\n    {\n        float3 _4157 = _4561;\n        float3 _4158 = normalize(_4157);\n        _4561 = _4158;\n        float3 param_8 = _4158;\n        SurfaceInput _4549 = { fa_world_pos, _4520, fa_world_tangent, fa_uv, fa_vertex_color, _4111, gl_FrontFacing };\n        SurfaceInput param_9 = _4549;\n        Surface _4640 = { _4559, _4560, _4561, _4562, _4563, _4564, _4565, _4566, _4567, _4568, _4569, _4570, _4571, _4572, _4573, _4574 };\n        Surface param_10 = _4640;\n        float3 param_11 = fa_indirect_diffuse(param_8);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _4177 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4177; ln++)\n        {\n            int param_12 = ln;\n            int _4190 = fa_cl_light(param_12);\n            int param_13 = _4190;\n            if (fa_baked_keep(param_13) <= 0.0f)\n            {\n                continue;\n            }\n            int param_14 = _4190;\n            float3 param_15 = fa_world_pos;\n            float3 param_16 = _4520;\n            LightSample _4206 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput _4557 = { fa_world_pos, _4520, fa_world_tangent, fa_uv, fa_vertex_color, _4111, gl_FrontFacing };\n            SurfaceInput param_17 = _4557;\n            Surface _4657 = { _4559, _4560, _4561, _4562, _4563, _4564, _4565, _4566, _4567, _4568, _4569, _4570, _4571, _4572, _4573, _4574 };\n            Surface param_18 = _4657;\n            LightSample param_19 = _4206;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _4221 = result;\n    float3 _4222 = _4221 + _4565;\n    result = _4222;\n    float3 param_20 = _4222;\n    float3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _4231 = _396_fa_fog.w > 0.0f;\n    bool _4238;\n    if (!_4231)\n    {\n        _4238 = _396_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _4238 = _4231;\n    }\n    if (_4238)\n    {\n        float3 _4247 = fa_world_pos - _396_fa_camera_pos.xyz;\n        float _4253 = dot(_4247, _396_fa_fog_c.xyz);\n        bool _4257 = _396_fa_fog_c.w > 0.5f;\n        float _4258;\n        if (_4257)\n        {\n            _4258 = _4253;\n        }\n        else\n        {\n            _4258 = length(_4247);\n        }\n        float _4270 = _4258 - _396_fa_fog_b.x;\n        if (_4270 > 0.0f)\n        {\n            float _4279 = _396_fa_fog.w * _4270;\n            float tau = _4279 * _4279;\n            if (_396_fa_fog_b.y > 0.0f)\n            {\n                float _4295;\n                if (_4257)\n                {\n                    _4295 = fa_world_pos.y - (_396_fa_fog_c.y * _4253);\n                }\n                else\n                {\n                    _4295 = _396_fa_camera_pos.y;\n                }\n                float _4316 = lerp(_4295, fa_world_pos.y, clamp(_396_fa_fog_b.x / _4258, 0.0f, 1.0f));\n                float _4320 = fa_world_pos.y - _4316;\n                float _4325 = _4316 - _396_fa_fog_b.z;\n                float _4330 = fa_world_pos.y - _396_fa_fog_b.z;\n                bool _4333 = _4325 <= 0.0f;\n                bool _4334 = !_4333;\n                bool _4340;\n                if (_4334)\n                {\n                    _4340 = _396_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4340 = _4333;\n                }\n                float _4341;\n                if (_4340)\n                {\n                    _4341 = _396_fa_fog_b.y;\n                }\n                else\n                {\n                    _4341 = _396_fa_fog_b.y * exp(-min(_396_fa_fog_b.w * _4325, 80.0f));\n                }\n                bool _4368;\n                if (_4334)\n                {\n                    _4368 = _396_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4368 = _4333;\n                }\n                float _4369;\n                if (_4368)\n                {\n                    _4369 = _396_fa_fog_b.y * _4325;\n                }\n                else\n                {\n                    _4369 = (_396_fa_fog_b.y * (1.0f - exp(-min(_396_fa_fog_b.w * _4325, 80.0f)))) / _396_fa_fog_b.w;\n                }\n                bool _4394 = _4330 <= 0.0f;\n                bool _4401;\n                if (!_4394)\n                {\n                    _4401 = _396_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4401 = _4394;\n                }\n                float _4402;\n                if (_4401)\n                {\n                    _4402 = _396_fa_fog_b.y * _4330;\n                }\n                else\n                {\n                    _4402 = (_396_fa_fog_b.y * (1.0f - exp(-min(_396_fa_fog_b.w * _4330, 80.0f)))) / _396_fa_fog_b.w;\n                }\n                float _4429;\n                if (abs(_4320) < 0.001000000047497451305389404296875f)\n                {\n                    _4429 = _4341;\n                }\n                else\n                {\n                    _4429 = (_4402 - _4369) / _4320;\n                }\n                tau += (_4270 * max(_4429, 0.0f));\n            }\n            result = lerp(result, _396_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4560);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 624,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_396",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2053",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _381 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _381;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _388 = _273.world_pos;\n    fa_world_pos = _388;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_388, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _396_fa_camera_pos : packoffset(c0);\n    float4 _396_fa_ambient : packoffset(c1);\n    float4 _396_fa_base_color : packoffset(c2);\n    float4 _396_fa_emissive : packoffset(c3);\n    float4 _396_fa_model_emissive : packoffset(c4);\n    float4 _396_fa_pbr : packoffset(c5);\n    float4 _396_fa_maps : packoffset(c6);\n    float4 _396_fa_fog : packoffset(c7);\n    float4 _396_fa_fog_b : packoffset(c8);\n    float4 _396_fa_fog_c : packoffset(c9);\n    float4 _396_fa_counts : packoffset(c10);\n    float4 _396_fa_env_sky : packoffset(c11);\n    float4 _396_fa_env_horizon : packoffset(c12);\n    float4 _396_fa_time : packoffset(c13);\n    float4 _396_fa_cl_vpx : packoffset(c14);\n    float4 _396_fa_cl_vpy : packoffset(c15);\n    float4 _396_fa_cl_vpw : packoffset(c16);\n    float4 _396_fa_cl_fwd : packoffset(c17);\n    float4 _396_fa_cl_grid : packoffset(c18);\n    float4 _396_fa_cl_info : packoffset(c19);\n    float4 _396_fa_layers_a : packoffset(c20);\n    float4 _396_fa_layers_b : packoffset(c21);\n    float4 _396_fa_layers_c : packoffset(c22);\n    float4 _396_fa_layers_d : packoffset(c23);\n    float4 _396_fa_ct_a : packoffset(c24);\n    float4 _396_fa_ct_b : packoffset(c25);\n    float4 _396_fa_ct_vpx : packoffset(c26);\n    float4 _396_fa_ct_vpy : packoffset(c27);\n    float4 _396_fa_ct_vpw : packoffset(c28);\n    float4 _396_fa_ct_fwd : packoffset(c29);\n    float4 _396_fa_probe_sh[9] : packoffset(c30);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2053_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2053_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2053_fa_shadow_info[4] : packoffset(c20);\n    float4 _2053_fa_shadow_split : packoffset(c24);\n    float4 _2053_fa_shadow_cfg : packoffset(c25);\n    float4 _2053_fa_shadow_bias : packoffset(c26);\n    float4 _2053_fa_shadow_eye : packoffset(c27);\n    float4 _2053_fa_shadow_fwd : packoffset(c28);\n    float4 _2053_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_screen_tex : register(t11);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1324 = _396_fa_cl_info.x < 0.0f;\n    bool _1331;\n    if (!_1324)\n    {\n        _1331 = _396_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1331 = _1324;\n    }\n    bool _1339;\n    if (!_1331)\n    {\n        _1339 = _396_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1339 = _1331;\n    }\n    bool _1346;\n    if (!_1339)\n    {\n        _1346 = _396_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1346 = _1339;\n    }\n    bool _1353;\n    if (!_1346)\n    {\n        _1353 = _396_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1353 = _1346;\n    }\n    if (_1353)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1363 = float4(world_pos, 1.0f);\n    float _1369 = dot(_396_fa_cl_vpw, _1363);\n    if (!(_1369 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1391 = float2(dot(_396_fa_cl_vpx, _1363), dot(_396_fa_cl_vpy, _1363)) / _1369.xx;\n    int _1395 = int(_396_fa_cl_grid.x);\n    int _1399 = int(_396_fa_cl_grid.y);\n    int param = (int(_396_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_396_fa_cl_fwd.xyz, world_pos) + _396_fa_cl_fwd.w, _396_fa_cl_grid.w) / _396_fa_cl_grid.w) * _396_fa_cl_grid.z)), 0, int(_396_fa_cl_info.y) - 1) * _1399) + clamp(int(floor(((_1391.y * 0.5f) + 0.5f) * _396_fa_cl_grid.y)), 0, _1399 - 1)) * _1395)) + clamp(int(floor(((_1391.x * 0.5f) + 0.5f) * _396_fa_cl_grid.x)), 0, _1395 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1475 = fa_cluster_texel(param);\n    return int2(int(_1475.x), int(_1475.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_396_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3534 = fa_cluster_lookup(param);\n    fa_cl_slot = _3534.x;\n    fa_cl_local = _3534.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _3742 = fa_linear_to_srgb(param);\n        c = _3742;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _3750 = fa_srgb_to_linear(param_1);\n            c = _3750;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _278;\n    if (i.front_facing)\n    {\n        _278 = i.world_normal;\n    }\n    else\n    {\n        _278 = -i.world_normal;\n    }\n    float3 _302 = normalize(i.world_tangent.xyz - (_278 * dot(_278, i.world_tangent.xyz)));\n    float3 _329 = normalize(((_302 * m.x) + ((cross(_278, _302) * i.world_tangent.w) * m.y)) + (_278 * m.z));\n    float3 _332;\n    if (i.front_facing)\n    {\n        _332 = _329;\n    }\n    else\n    {\n        _332 = -_329;\n    }\n    return _332;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _396_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3781 = fa_tex_fix(param_2, param_3);\n    float4 _4872 = base_t;\n    _4872.x = _3781.x;\n    _4872.y = _3781.y;\n    _4872.z = _3781.z;\n    base_t = _4872;\n    float4 _3795 = (_4872 * _396_fa_base_color) * i.vertex_color;\n    float3 _4724 = i.world_normal;\n    if (_396_fa_maps.z > 0.5f)\n    {\n        float param_4 = _396_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3827 = fa_tex_fix(param_6, param_7);\n        float3 _3830 = (_3827 * 2.0f) - 1.0f.xxx;\n        float2 _3835 = _3830.xy * _396_fa_maps.x;\n        float3 _4880 = _3830;\n        _4880.x = _3835.x;\n        _4880.y = _3835.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4880;\n        _4724 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _396_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3863 = fa_tex_fix(param_12, param_13);\n    float4 _4883 = mrt;\n    _4883.x = _3863.x;\n    _4883.y = _3863.y;\n    _4883.z = _3863.z;\n    mrt = _4883;\n    float4 _3891 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _396_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _3891.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3902 = fa_tex_fix(param_16, param_17);\n    float param_18 = _396_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3932 = fa_tex_fix(param_20, param_21);\n    float _4729 = _396_fa_layers_a.x;\n    float _4730 = _396_fa_layers_a.y;\n    float _4733 = _396_fa_layers_a.z;\n    float _4732 = _396_fa_layers_b.w;\n    float _4735 = _396_fa_layers_c.x;\n    if (_396_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_396_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _4729 *= _3902.y;\n            _4730 *= _3902.z;\n            _4732 *= _3891.w;\n        }\n        if (_396_fa_layers_c.z > 1.5f)\n        {\n            _4733 *= mrt.x;\n            _4735 *= mrt.w;\n        }\n    }\n    Surface _4754 = { _3795.xyz, _3795.w, _4724, clamp(_396_fa_pbr.x * _3863.z, 0.0f, 1.0f), clamp(_396_fa_pbr.y * _3863.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_396_fa_maps.y * (_3902.x - 1.0f)), _396_fa_emissive.xyz + (_396_fa_model_emissive.xyz * _3932), _4729, _4730, _396_fa_layers_b.xyz, _4732, _4733, _396_fa_layers_a.w, _4735, _396_fa_layers_c.y, _396_fa_layers_d.xyz };\n    return _4754;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1555 = rect.zw - rect.xy;\n    float2 _1559 = _1555 * atlas;\n    float2 _1563 = ddx * _1559;\n    float2 _1567 = ddy * _1559;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1555), clamp(0.5f * log2(max(max(dot(_1563, _1563), dot(_1567, _1567)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1600 = _396_fa_counts.y < 0.5f;\n    bool _1607;\n    if (!_1600)\n    {\n        _1607 = _396_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1607 = _1600;\n    }\n    if (_1607)\n    {\n        return;\n    }\n    float3 _1613 = ddx(world_pos);\n    float3 _1616 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1620 = fa_cluster_texel(param);\n    int _1624 = int(_1620.w);\n    if (_1624 < 1)\n    {\n        return;\n    }\n    int _1634 = int(_396_fa_counts.y + 0.5f);\n    int param_1 = _1634;\n    float4 _1638 = fa_light_texel(param_1);\n    float2 _1641 = _1638.yz;\n    int _1645 = int(_1638.w);\n    int param_2 = _1634 + 1;\n    float4 _1650 = fa_light_texel(param_2);\n    float _1651 = _1650.x;\n    int _1657 = int(_396_fa_counts.w + 0.5f) - 1;\n    int _1661 = int(_1620.z);\n    float3 _1926;\n    for (int k = 0; k < _1624; k++)\n    {\n        int _1674 = _1661 + k;\n        int param_3 = _1645 + (_1674 >> 2);\n        int _1691 = (_1634 + 2) + (int(fa_light_texel(param_3)[_1674 & 3]) * 7);\n        int param_4 = _1691 + 6;\n        float4 _1696 = fa_light_texel(param_4);\n        if (((int(_1696.w + 0.5f) >> _1657) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1691;\n        float4 _1711 = fa_light_texel(param_5);\n        int param_6 = _1691 + 1;\n        float4 _1716 = fa_light_texel(param_6);\n        int param_7 = _1691 + 2;\n        float4 _1721 = fa_light_texel(param_7);\n        float3 _1724 = _1711.xyz;\n        float _1729 = dot(_1724, world_pos) + _1711.w;\n        float3 _1731 = _1716.xyz;\n        float _1736 = dot(_1731, world_pos) + _1716.w;\n        float3 _1738 = _1721.xyz;\n        float _1743 = dot(_1738, world_pos) + _1721.w;\n        bool _1748 = abs(_1729) > 0.5f;\n        bool _1756;\n        if (!_1748)\n        {\n            _1756 = abs(_1736) > 0.5f;\n        }\n        else\n        {\n            _1756 = _1748;\n        }\n        bool _1764;\n        if (!_1756)\n        {\n            _1764 = abs(_1743) > 0.5f;\n        }\n        else\n        {\n            _1764 = _1756;\n        }\n        if (_1764)\n        {\n            continue;\n        }\n        float _1779 = clamp(dot(geo_normal, normalize(_1738)) * _1696.z, 0.0f, 1.0f);\n        if (_1779 <= 0.0f)\n        {\n            continue;\n        }\n        float _1799 = (clamp((0.5f - abs(_1743)) * 10.0f, 0.0f, 1.0f) * _1779) * _1696.x;\n        float2 _1807 = float2(_1729 + 0.5f, 0.5f - _1736);\n        float2 _1817 = float2(dot(_1724, _1613), dot(_1731, _1613));\n        float2 _1827 = float2(dot(_1724, _1616), dot(_1731, _1616));\n        int param_8 = _1691 + 5;\n        float4 _1832 = fa_light_texel(param_8);\n        int param_9 = _1691 + 3;\n        float4 _1837 = fa_light_texel(param_9);\n        int param_10 = _1691 + 4;\n        float4 _1842 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1832.xyz;\n        bool _1852 = _1837.z > _1837.x;\n        if (_1852)\n        {\n            float4 param_11 = _1837;\n            float2 param_12 = _1807;\n            float2 param_13 = _1641;\n            float2 param_14 = _1817;\n            float2 param_15 = _1827;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1651 > 0.5f) && (_1651 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1878 = fa_dc_to_linear(param_16);\n                float4 _4804 = tx;\n                _4804.x = _1878.x;\n                _4804.y = _1878.y;\n                _4804.z = _1878.z;\n                tx = _4804;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1799 * tex_a) * _1832.w, 0.0f, 1.0f).xxx);\n        if (_1842.z > _1842.x)\n        {\n            float4 param_17 = _1842;\n            float2 param_18 = _1807;\n            float2 param_19 = _1641;\n            float2 param_20 = _1817;\n            float2 param_21 = _1827;\n            float4 _1922 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1651 > 1.5f)\n            {\n                float3 param_22 = _1922.xyz;\n                float3 _1932 = fa_dc_to_srgb(param_22);\n                _1926 = _1932;\n            }\n            else\n            {\n                _1926 = _1922.xyz;\n            }\n            float3 _1941 = (_1926 * 2.0f) - 1.0f.xxx;\n            float2 _1946 = _1941.xy * _1696.y;\n            float3 _1968 = (normalize(_1724) * _1946.x) + (normalize(_1731) * _1946.y);\n            float3 _1971 = normalize(normal);\n            normal = normalize(lerp(_1971, normalize((_1971 * max(_1941.z, 0.0500000007450580596923828125f)) + (_1968 - (_1971 * dot(_1971, _1968)))), clamp(_1799 * (_1852 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_sky_sh_coef(int k)\n{\n    float3 v = fa_env_tex.SampleLevel(fa_env_smp, float3(1.0f, 1.0f - (float((2 * (k >> 2)) + 1) * 0.25f), 1.0f - (float((2 * (k & 3)) + 1) * 0.25f)), 5.0f).xyz;\n    if (_396_fa_env_sky.w > 1.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3166 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3166;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_396_fa_env_sky.w > 0.5f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _396_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_396_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _396_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_396_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    return ambientColor;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_396_fa_cl_info.x) + int(_396_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_396_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _3504;\n    if (fa_lm.z > 0.5f)\n    {\n        _3504 = 0.0f;\n    }\n    else\n    {\n        _3504 = 1.0f - clamp(_396_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _3515 = _3504 < 1.0f;\n    bool _3521;\n    if (_3515)\n    {\n        int param = li;\n        _3521 = fa_light_baked(param);\n    }\n    else\n    {\n        _3521 = _3515;\n    }\n    return _3521 ? _3504 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _455_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _455_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _574 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _587 = (c - (ru * hx)) - p;\n        float3 _593 = ru * (2.0f * hx);\n        float _599 = max(dot(_593, _593), 9.9999999392252902907785028219223e-09f);\n        float _603 = dot(_587, _593);\n        float t = clamp((-_603) / _599, 0.0f, 1.0f);\n        if (_574)\n        {\n            float _618 = dot(r, _593);\n            float _624 = _599 - (_618 * _618);\n            if (abs(_624) > (9.9999997473787516355514526367188e-06f * _599))\n            {\n                t = clamp(((dot(r, _587) * _618) - _603) / _624, 0.0f, 1.0f);\n            }\n        }\n        return (p + _587) + (_593 * t);\n    }\n    float3 q = p;\n    float _656 = dot(r, axis);\n    bool _664;\n    if (_574)\n    {\n        _664 = abs(_656) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _664 = _574;\n    }\n    if (_664)\n    {\n        float _674 = dot(c - p, axis) / _656;\n        if (_674 > 0.0f)\n        {\n            q = p + (r * _674);\n        }\n    }\n    float3 _687 = q - c;\n    float2 xy = float2(dot(_687, ru), dot(_687, uu));\n    if (shape > 0.5f)\n    {\n        float _702 = length(xy);\n        if (_702 > hx)\n        {\n            xy *= (hx / _702);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _344 = abs(d);\n    float _346 = _344.x;\n    float _348 = _344.y;\n    bool _349 = _346 >= _348;\n    bool _357;\n    if (_349)\n    {\n        _357 = _346 >= _344.z;\n    }\n    else\n    {\n        _357 = _349;\n    }\n    int _358;\n    if (_357)\n    {\n        _358 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _373;\n        if (_348 >= _344.z)\n        {\n            _373 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _373 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _358 = _373;\n    }\n    return _358;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _494 = dot(d, right);\n    float _498 = dot(d, up);\n    float _509;\n    if (((_494 * _494) + (_498 * _498)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _509 = atan2(_498, _494) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _509 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_509 - floor(_509)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _740 = fa_light_base(param);\n    bool _744 = _396_fa_ambient.w > 4.5f;\n    int param_1 = _740;\n    float4 _748 = fa_light_texel(param_1);\n    int param_2 = _740 + 1;\n    float4 _753 = fa_light_texel(param_2);\n    float _756 = _753.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _768 = _744 && (_756 > 2.5f);\n    fa_light_is_area = _768;\n    bool _770 = _756 < 0.5f;\n    float3 l;\n    if (_770)\n    {\n        l = normalize(_748.xyz);\n        if (_744)\n        {\n            int param_3 = _740 + 6;\n            float4 _784 = fa_light_texel(param_3);\n            if (_784.z > 0.5f)\n            {\n                int param_4 = _740 + 4;\n                float4 _794 = fa_light_texel(param_4);\n                int param_5 = _740 + 5;\n                float4 _799 = fa_light_texel(param_5);\n                float2 param_6 = _784.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _794.xyz) * _794.w, (-dot(world_pos, _799.xyz)) * _799.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _829 = _748.xyz;\n        float3 _831 = _829 - world_pos;\n        float3 to_light = _831;\n        float _834 = length(_831);\n        float reach = _834;\n        bool front = true;\n        if (_768)\n        {\n            int param_8 = _740 + 7;\n            reach = max(_834 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _740 + 4;\n            float4 _858 = fa_light_texel(param_9);\n            int param_10 = _740 + 5;\n            float4 _863 = fa_light_texel(param_10);\n            int param_11 = _740 + 6;\n            float4 _868 = fa_light_texel(param_11);\n            float _869 = _868.w;\n            int param_12 = _740 + 2;\n            float3 _876 = normalize(fa_light_texel(param_12).xyz);\n            bool _878 = _869 > 1.5f;\n            bool _886;\n            if (!_878)\n            {\n                _886 = dot(_876, to_light) < 0.0f;\n            }\n            else\n            {\n                _886 = _878;\n            }\n            front = _886;\n            float3 r = 0.0f.xxx;\n            float3 _895 = _396_fa_camera_pos.xyz - world_pos;\n            bool _899 = dot(n, n) > 0.5f;\n            bool _907;\n            if (_899)\n            {\n                _907 = dot(_895, _895) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _907 = _899;\n            }\n            if (_907)\n            {\n                r = reflect(-normalize(_895), normalize(n));\n            }\n            float3 param_13 = _829;\n            float3 param_14 = _876;\n            float3 param_15 = _858.xyz;\n            float3 param_16 = _863.xyz;\n            float param_17 = _858.w;\n            float param_18 = _863.w;\n            float param_19 = _869;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _943 = length(to_light);\n        dist = _943;\n        l = to_light / max(_943, 9.9999997473787516355514526367188e-05f).xxx;\n        float _957 = reach / max(_748.w, 0.001000000047497451305389404296875f);\n        float _963 = clamp(1.0f - (_957 * _957), 0.0f, 1.0f);\n        float _965;\n        if (front)\n        {\n            _965 = _963 * _963;\n        }\n        else\n        {\n            _965 = 0.0f;\n        }\n        atten = _965;\n        bool _976 = _756 < 2.5f;\n        if ((_756 > 1.5f) && _976)\n        {\n            int param_22 = _740 + 2;\n            float4 _984 = fa_light_texel(param_22);\n            float _994 = _984.w;\n            int param_23 = _740 + 3;\n            float4 _999 = fa_light_texel(param_23);\n            float _1000 = _999.x;\n            float cos_inner = _1000;\n            if (_1000 > 1.5f)\n            {\n                cos_inner = lerp(_994, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_994, cos_inner, dot(-l, normalize(_984.xyz)));\n        }\n        if (_744 && (_756 < 1.5f))\n        {\n            int param_24 = _740 + 6;\n            float4 _1024 = fa_light_texel(param_24);\n            if (_1024.z > 0.5f)\n            {\n                float3 _1032 = -to_light;\n                int param_25 = _740 + 4;\n                int param_26 = _740 + 5;\n                float3 _1046 = fa_light_texel(param_25).xyz;\n                float3 _1050 = fa_light_texel(param_26).xyz;\n                float3 _1059 = float3(dot(_1032, _1046), dot(_1032, _1050), dot(_1032, cross(_1046, _1050)));\n                float3 param_27 = _1059;\n                int _1063 = fa_cube_face(param_27);\n                int param_28 = _1063;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1090 = float2(dot(_1059, cross(param_29, param_30)), dot(_1059, param_30)) / max(dot(_1059, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1094 = _1063 / 3;\n                float2 param_31 = _1024.xy + (float2(float(_1063 - (_1094 * 3)), float(_1094)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1090.x), 0.5f - (0.5f * _1090.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _740 + 7;\n            float4 _1124 = fa_light_texel(param_33);\n            if (_1124.z > 0.5f)\n            {\n                int param_34 = _740 + 2;\n                int param_35 = _740 + 4;\n                int param_36 = _740 + 5;\n                float2 param_37 = _1124.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_744 && _976)\n            {\n                int param_42 = _740 + 6;\n                float4 _1171 = fa_light_texel(param_42);\n                int param_43 = _740 + 7;\n                float4 _1176 = fa_light_texel(param_43);\n                bool _1179 = _1171.z > 0.5f;\n                bool _1186;\n                if (!_1179)\n                {\n                    _1186 = _1176.z > 0.5f;\n                }\n                else\n                {\n                    _1186 = _1179;\n                }\n                if (_1186)\n                {\n                    int param_44 = _740 + 2;\n                    float4 _1193 = fa_light_texel(param_44);\n                    float3 _1197 = normalize(_1193.xyz);\n                    int param_45 = _740 + 4;\n                    float4 _1202 = fa_light_texel(param_45);\n                    int param_46 = _740 + 5;\n                    float4 _1207 = fa_light_texel(param_46);\n                    if (_1179)\n                    {\n                        float3 _1215 = -to_light;\n                        float _1222 = _1193.w;\n                        float _1238 = 0.5f / max(dot(_1215, _1197) * (sqrt(max(1.0f - (_1222 * _1222), 0.0f)) / max(_1222, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1171.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1215, _1202.xyz) * _1238), 0.5f - (dot(_1215, _1207.xyz) * _1238));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1176.z > 0.5f)\n                    {\n                        float2 param_49 = _1176.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1197;\n                        float3 param_52 = _1202.xyz;\n                        float3 param_53 = _1207.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4678 = _753.xyz * atten;\n    if (_744)\n    {\n        _4678 *= fa_light_tint;\n    }\n    int _1306;\n    if (_770)\n    {\n        _1306 = 0;\n    }\n    else\n    {\n        _1306 = ((_756 > 1.5f) && (_756 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _4689 = { l, _4678, atten, 1.0f, dist, _1306 };\n    return _4689;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2043;\n    if (i == 0)\n    {\n        _2043 = _2053_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2059;\n        if (i == 1)\n        {\n            _2059 = _2053_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2067;\n            if (i == 2)\n            {\n                _2067 = _2053_fa_shadow_split.z;\n            }\n            else\n            {\n                _2067 = _2053_fa_shadow_split.w;\n            }\n            _2059 = _2067;\n        }\n        _2043 = _2059;\n    }\n    return _2043;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2100 = fa_shadow_depth(param, param_1);\n    float _2104;\n    if (conv.x < 0.5f)\n    {\n        _2104 = _2100;\n    }\n    else\n    {\n        _2104 = (conv.y * conv.z) / (conv.z - (_2100 * (conv.z - conv.y)));\n    }\n    return _2104;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2031 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2031), sin(_2031)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2150 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2159;\n        if (k < 0.0f)\n        {\n            _2159 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2159 = k;\n        }\n        float _2179 = clamp((_2159 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2150;\n            float2 _2198 = fa_shadow_vogel(param_3, param_4, param_5) * _2179;\n            float2 param_6 = uv + (_2198 * _2053_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2210 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2210 < (zr - (length(_2198) * plane)))\n            {\n                sum += _2210;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2236 = sum / cnt;\n        float _2246;\n        if (k < 0.0f)\n        {\n            _2246 = (-k) / max(_2236, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2246 = k;\n        }\n        radius = clamp(((max(zr - _2236, 0.0f) * unit) * _2246) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2268 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2268; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2268;\n        float param_11 = _2150;\n        float2 _2287 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2287 * _2053_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2287) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2268);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2329 = max(_2053_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2334 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2340 = sqrt(1.0f - (_2334 * _2334));\n    float _2347 = min(_2340 / max(_2334, 0.20000000298023223876953125f), 4.0f);\n    float _2352;\n    if (_2053_fa_shadow_bias.y > 0.0f)\n    {\n        _2352 = _2053_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2352 = 1.5f * _2053_fa_shadow_info[ci].x;\n    }\n    float4 _2377 = mul(float4(world + (n * (_2352 * _2340)), 1.0f), _2053_fa_shadow_mat[ci]);\n    float _2384 = _2377.x;\n    bool _2387 = _2384 < _2053_fa_shadow_rect[ci].x;\n    bool _2396;\n    if (!_2387)\n    {\n        _2396 = _2384 > _2053_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2396 = _2387;\n    }\n    bool _2405;\n    if (!_2396)\n    {\n        _2405 = _2377.y < _2053_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2405 = _2396;\n    }\n    bool _2414;\n    if (!_2405)\n    {\n        _2414 = _2377.y > _2053_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2414 = _2405;\n    }\n    bool _2421;\n    if (!_2414)\n    {\n        _2421 = _2377.z > 1.0f;\n    }\n    else\n    {\n        _2421 = _2414;\n    }\n    if (_2421)\n    {\n        return -1.0f;\n    }\n    float _2429;\n    if (_2053_fa_shadow_bias.x > 0.0f)\n    {\n        _2429 = _2053_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2429 = 1.5f * _2053_fa_shadow_info[ci].x;\n    }\n    float2 param = _2377.xy;\n    float4 param_1 = _2053_fa_shadow_rect[ci];\n    float param_2 = _2377.z - ((_2429 * (1.0f + (0.5f * _2347))) / _2329);\n    float param_3 = _2053_fa_shadow_info[ci].x;\n    float param_4 = _2329;\n    float param_5 = _2329 * 0.25f;\n    float param_6 = ((_2053_fa_shadow_info[ci].x * min(_2347, 3.0f)) * 0.5f) / _2329;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2053_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2053_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_396_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2807 = int(_2053_fa_shadow_cfg.x + 0.5f);\n    if (_2807 < 1)\n    {\n        return 1.0f;\n    }\n    float _2822 = dot(world - _2053_fa_shadow_eye.xyz, _2053_fa_shadow_fwd.xyz);\n    int param = _2807 - 1;\n    if (_2822 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2834 = _2807 > 1;\n    bool _2841;\n    if (_2834)\n    {\n        _2841 = _2822 > _2053_fa_shadow_split.x;\n    }\n    else\n    {\n        _2841 = _2834;\n    }\n    if (_2841)\n    {\n        ci = 1;\n    }\n    bool _2845 = _2807 > 2;\n    bool _2852;\n    if (_2845)\n    {\n        _2852 = _2822 > _2053_fa_shadow_split.y;\n    }\n    else\n    {\n        _2852 = _2845;\n    }\n    if (_2852)\n    {\n        ci = 2;\n    }\n    bool _2856 = _2807 > 3;\n    bool _2863;\n    if (_2856)\n    {\n        _2863 = _2822 > _2053_fa_shadow_split.z;\n    }\n    else\n    {\n        _2863 = _2856;\n    }\n    if (_2863)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2807)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2889 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2889;\n        if (_2889 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2053_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2914;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2914 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2914 = _2053_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2933 = _2053_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2914, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2944 = clamp((_2822 - (fa_shadow_split_at(param_7) - _2933)) / _2933, 0.0f, 1.0f);\n        if (_2944 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2807)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2965 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2965;\n                if (_2965 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2944);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2487 = _396_fa_pbr.z < 0.5f;\n    bool _2494;\n    if (!_2487)\n    {\n        _2494 = _2053_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2494 = _2487;\n    }\n    if (_2494)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2053_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2507 = fa_light_texel(param);\n    float _2508 = _2507.x;\n    if (_2508 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2517 = int(_2508 + 0.5f);\n    int param_1 = _2517;\n    float4 _2521 = fa_light_texel(param_1);\n    int param_2 = _2517 + 1;\n    float4 _2526 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2529 = _2521.y;\n    if (_2529 > 0.0f)\n    {\n        float _2546 = 1.0f - smoothstep(0.75f * _2529, _2529, length(world - _2053_fa_shadow_eye.xyz));\n        fade = _2546;\n        if (_2546 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2521.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2570 = (_2517 + 2) + (face * 6);\n    int param_4 = _2570;\n    int param_5 = _2570 + 1;\n    int param_6 = _2570 + 3;\n    float4 _2584 = fa_light_texel(param_6);\n    int param_7 = _2570 + 4;\n    float4 _2589 = fa_light_texel(param_7);\n    int param_8 = _2570 + 5;\n    float4 _2594 = fa_light_texel(param_8);\n    float _2606 = _2594.x * max(dot(_2584, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2611 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2634 = clamp(dot(n, _2584.xyz), -1.0f, 1.0f);\n    float _2653 = min(sqrt(1.0f - (_2634 * _2634)) / max(abs(dot(n, world - lpos)) / max(dot(_2584, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2656 = _2526.y;\n    float _2658;\n    if (_2656 > 0.0f)\n    {\n        _2658 = _2656;\n    }\n    else\n    {\n        _2658 = 1.5f * _2606;\n    }\n    float4 _2678 = float4(world + (n * (_2658 * sqrt(1.0f - (_2611 * _2611)))), 1.0f);\n    float _2682 = dot(_2584, _2678);\n    float _2685 = _2594.y;\n    if (_2682 < _2685)\n    {\n        return 1.0f;\n    }\n    float2 _2700 = float2(dot(fa_light_texel(param_4), _2678), dot(fa_light_texel(param_5), _2678)) / _2682.xx;\n    float _2702 = _2700.x;\n    bool _2705 = _2702 < _2589.x;\n    bool _2714;\n    if (!_2705)\n    {\n        _2714 = _2702 > _2589.z;\n    }\n    else\n    {\n        _2714 = _2705;\n    }\n    bool _2723;\n    if (!_2714)\n    {\n        _2723 = _2700.y < _2589.y;\n    }\n    else\n    {\n        _2723 = _2714;\n    }\n    bool _2732;\n    if (!_2723)\n    {\n        _2732 = _2700.y > _2589.w;\n    }\n    else\n    {\n        _2732 = _2723;\n    }\n    if (_2732)\n    {\n        return 1.0f;\n    }\n    float _2738 = _2526.x;\n    float _2740;\n    if (_2738 > 0.0f)\n    {\n        _2740 = _2738;\n    }\n    else\n    {\n        _2740 = 1.5f * _2606;\n    }\n    float2 param_9 = _2700;\n    float4 param_10 = _2589;\n    float param_11 = _2682 - (_2740 * (1.0f + (0.5f * _2653)));\n    float param_12 = _2606;\n    float param_13 = 1.0f;\n    float param_14 = _2594.z * 0.25f;\n    float param_15 = (_2606 * min(_2653, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2685, _2594.z);\n    int param_17 = int(_2521.z + 0.5f);\n    float param_18 = _2521.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _3246 = _396_fa_ct_a.x < 0.5f;\n    bool _3253;\n    if (!_3246)\n    {\n        _3253 = _2053_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _3253 = _3246;\n    }\n    if (_3253)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2053_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _3266 = fa_light_texel(param);\n    float _3267 = _3266.y;\n    float len = _3267;\n    if (_3267 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3279 = length(world - _396_fa_camera_pos.xyz);\n    float _3289 = 1.0f - smoothstep(0.5f * _396_fa_ct_b.x, _396_fa_ct_b.x, _3279);\n    if (_3289 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3295 = len;\n    float _3298 = min(_3295, 0.89999997615814208984375f * dist);\n    len = _3298;\n    float _3304 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _3279);\n    float _3309 = _3304 + (0.5f * _3298);\n    float3 _3315 = world + (gn * _3304);\n    float _3317 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _3382;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3333 = (float(k) + _3317) * 0.083333335816860198974609375f;\n        float3 _3341 = _3315 + (l * (_3333 * len));\n        float4 _3347 = float4(_3341, 1.0f);\n        float _3353 = dot(_396_fa_ct_vpw, _3347);\n        if (_3353 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _3373 = float2(dot(_396_fa_ct_vpx, _3347), dot(_396_fa_ct_vpy, _3347)) / _3353.xx;\n        float _3377 = _3373.x * 0.5f;\n        float _3378 = _3377 + 0.5f;\n        if (_396_fa_ct_a.y > 0.5f)\n        {\n            _3382 = (_3373.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _3382 = 0.5f - (_3373.y * 0.5f);\n        }\n        bool _3398 = _3378 < 0.0f;\n        bool _3405;\n        if (!_3398)\n        {\n            _3405 = _3378 >= 1.0f;\n        }\n        else\n        {\n            _3405 = _3398;\n        }\n        bool _3412;\n        if (!_3405)\n        {\n            _3412 = _3382 < 0.0f;\n        }\n        else\n        {\n            _3412 = _3405;\n        }\n        bool _3419;\n        if (!_3412)\n        {\n            _3419 = _3382 >= 1.0f;\n        }\n        else\n        {\n            _3419 = _3412;\n        }\n        if (_3419)\n        {\n            break;\n        }\n        float4 _3438 = fa_screen_tex.Load(int3(int2(float2(_3378, _3382) * _396_fa_ct_a.zw), 0));\n        if (_3438.w < 0.5f)\n        {\n            continue;\n        }\n        float _3457 = (dot(_396_fa_ct_fwd.xyz, _3341) + _396_fa_ct_fwd.w) - _3438.x;\n        if ((_3457 > _3304) && (_3457 < _3309))\n        {\n            occ = max(occ, (1.0f - (_3333 * _3333)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_3378, 0.5f - _3377), min(_3382, 1.0f - _3382))));\n        }\n    }\n    return 1.0f - (occ * _3289);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _3560 = fa_baked_keep(param);\n    if (_3560 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _4702 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _4702;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3586 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _4704 = _3586.color;\n    float _4705 = _3586.attenuation;\n    float _4706 = _3586.shadow;\n    bool _3589 = _3586.type == 0;\n    if (_3589 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3586.direction;\n        float _3600 = fa_shadow_factor(param_5, param_6);\n        _4706 = _3600;\n        _4704 *= _3600;\n    }\n    else\n    {\n        bool _3611 = _3586.type != 0;\n        bool _3617;\n        if (_3611)\n        {\n            _3617 = _4705 > 0.0f;\n        }\n        else\n        {\n            _3617 = _3611;\n        }\n        if (_3617)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _3586.direction;\n            float _3636 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _4706 = _3636;\n            _4704 *= _3636;\n        }\n    }\n    bool _3646 = _396_fa_ct_a.x > 0.5f;\n    bool _3652;\n    if (_3646)\n    {\n        _3652 = _4705 > 0.0f;\n    }\n    else\n    {\n        _3652 = _3646;\n    }\n    if (_3652)\n    {\n        float _3659;\n        if (_3589)\n        {\n            _3659 = 1000000000.0f;\n        }\n        else\n        {\n            _3659 = _3586._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _3586.direction;\n        float param_18 = _3659;\n        float _3677 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _4706 *= _3677;\n        _4704 *= _3677;\n    }\n    float _3690 = _4705;\n    float _3691 = _3690 * _3560;\n    _4705 = _3691;\n    float3 _3695 = _4704;\n    float3 _3696 = _3695 * _3560;\n    _4704 = _3696;\n    LightSample _4721 = { _3586.direction, _3696, _3691, _4706, _3586._distance, _3586.type };\n    return _4721;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2053_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _2989 = int(_2053_fa_shadow_cfg.x + 0.5f);\n    float _2999 = dot(world - _2053_fa_shadow_eye.xyz, _2053_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3004 = _2989 > 0;\n    bool _3013;\n    if (_3004)\n    {\n        int param = _2989 - 1;\n        _3013 = _2999 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3013 = _3004;\n    }\n    if (_3013)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3019 = _2989 > 1;\n        bool _3026;\n        if (_3019)\n        {\n            _3026 = _2999 > _2053_fa_shadow_split.x;\n        }\n        else\n        {\n            _3026 = _3019;\n        }\n        if (_3026)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3032 = _2989 > 2;\n        bool _3039;\n        if (_3032)\n        {\n            _3039 = _2999 > _2053_fa_shadow_split.y;\n        }\n        else\n        {\n            _3039 = _3032;\n        }\n        if (_3039)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3045 = _2989 > 3;\n        bool _3052;\n        if (_3045)\n        {\n            _3052 = _2999 > _2053_fa_shadow_split.z;\n        }\n        else\n        {\n            _3052 = _3045;\n        }\n        if (_3052)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _4520 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4520 = -_4520;\n    }\n    float3 _4111 = normalize(_396_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _4533 = { fa_world_pos, _4520, fa_world_tangent, fa_uv, fa_vertex_color, _4111, gl_FrontFacing };\n    SurfaceInput param_1 = _4533;\n    Surface _4119 = fa_standard_surface(param_1);\n    float3 _4559 = _4119.albedo;\n    float _4560 = _4119.alpha;\n    float3 _4561 = _4119.normal;\n    float _4562 = _4119.metallic;\n    float _4563 = _4119.roughness;\n    float _4564 = _4119.occlusion;\n    float3 _4565 = _4119.emission;\n    float _4566 = _4119.clearcoat;\n    float _4567 = _4119.clearcoat_roughness;\n    float3 _4568 = _4119.sheen_color;\n    float _4569 = _4119.sheen_roughness;\n    float _4570 = _4119.anisotropy;\n    float _4571 = _4119.anisotropy_rotation;\n    float _4572 = _4119.specular;\n    float _4573 = _4119.ior;\n    float3 _4574 = _4119.specular_color;\n    SurfaceInput _4541 = { fa_world_pos, _4520, fa_world_tangent, fa_uv, fa_vertex_color, _4111, gl_FrontFacing };\n    SurfaceInput param_2 = _4541;\n    Surface param_3 = _4119;\n    surface(param_2, param_3);\n    _4559 = param_3.albedo;\n    _4560 = param_3.alpha;\n    _4561 = param_3.normal;\n    _4562 = param_3.metallic;\n    _4563 = param_3.roughness;\n    _4564 = param_3.occlusion;\n    _4565 = param_3.emission;\n    _4566 = param_3.clearcoat;\n    _4567 = param_3.clearcoat_roughness;\n    _4568 = param_3.sheen_color;\n    _4569 = param_3.sheen_roughness;\n    _4570 = param_3.anisotropy;\n    _4571 = param_3.anisotropy_rotation;\n    _4572 = param_3.specular;\n    _4573 = param_3.ior;\n    _4574 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _4520;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4559 = param_6;\n    _4561 = param_7;\n    float3 result;\n    if (_396_fa_emissive.w > 0.5f)\n    {\n        result = _4559;\n    }\n    else\n    {\n        float3 _4157 = _4561;\n        float3 _4158 = normalize(_4157);\n        _4561 = _4158;\n        float3 param_8 = _4158;\n        SurfaceInput _4549 = { fa_world_pos, _4520, fa_world_tangent, fa_uv, fa_vertex_color, _4111, gl_FrontFacing };\n        SurfaceInput param_9 = _4549;\n        Surface _4640 = { _4559, _4560, _4561, _4562, _4563, _4564, _4565, _4566, _4567, _4568, _4569, _4570, _4571, _4572, _4573, _4574 };\n        Surface param_10 = _4640;\n        float3 param_11 = fa_indirect_diffuse(param_8);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _4177 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4177; ln++)\n        {\n            int param_12 = ln;\n            int _4190 = fa_cl_light(param_12);\n            int param_13 = _4190;\n            if (fa_baked_keep(param_13) <= 0.0f)\n            {\n                continue;\n            }\n            int param_14 = _4190;\n            float3 param_15 = fa_world_pos;\n            float3 param_16 = _4520;\n            LightSample _4206 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput _4557 = { fa_world_pos, _4520, fa_world_tangent, fa_uv, fa_vertex_color, _4111, gl_FrontFacing };\n            SurfaceInput param_17 = _4557;\n            Surface _4657 = { _4559, _4560, _4561, _4562, _4563, _4564, _4565, _4566, _4567, _4568, _4569, _4570, _4571, _4572, _4573, _4574 };\n            Surface param_18 = _4657;\n            LightSample param_19 = _4206;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _4221 = result;\n    float3 _4222 = _4221 + _4565;\n    result = _4222;\n    float3 param_20 = _4222;\n    float3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _4231 = _396_fa_fog.w > 0.0f;\n    bool _4238;\n    if (!_4231)\n    {\n        _4238 = _396_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _4238 = _4231;\n    }\n    if (_4238)\n    {\n        float3 _4247 = fa_world_pos - _396_fa_camera_pos.xyz;\n        float _4253 = dot(_4247, _396_fa_fog_c.xyz);\n        bool _4257 = _396_fa_fog_c.w > 0.5f;\n        float _4258;\n        if (_4257)\n        {\n            _4258 = _4253;\n        }\n        else\n        {\n            _4258 = length(_4247);\n        }\n        float _4270 = _4258 - _396_fa_fog_b.x;\n        if (_4270 > 0.0f)\n        {\n            float _4279 = _396_fa_fog.w * _4270;\n            float tau = _4279 * _4279;\n            if (_396_fa_fog_b.y > 0.0f)\n            {\n                float _4295;\n                if (_4257)\n                {\n                    _4295 = fa_world_pos.y - (_396_fa_fog_c.y * _4253);\n                }\n                else\n                {\n                    _4295 = _396_fa_camera_pos.y;\n                }\n                float _4316 = lerp(_4295, fa_world_pos.y, clamp(_396_fa_fog_b.x / _4258, 0.0f, 1.0f));\n                float _4320 = fa_world_pos.y - _4316;\n                float _4325 = _4316 - _396_fa_fog_b.z;\n                float _4330 = fa_world_pos.y - _396_fa_fog_b.z;\n                bool _4333 = _4325 <= 0.0f;\n                bool _4334 = !_4333;\n                bool _4340;\n                if (_4334)\n                {\n                    _4340 = _396_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4340 = _4333;\n                }\n                float _4341;\n                if (_4340)\n                {\n                    _4341 = _396_fa_fog_b.y;\n                }\n                else\n                {\n                    _4341 = _396_fa_fog_b.y * exp(-min(_396_fa_fog_b.w * _4325, 80.0f));\n                }\n                bool _4368;\n                if (_4334)\n                {\n                    _4368 = _396_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4368 = _4333;\n                }\n                float _4369;\n                if (_4368)\n                {\n                    _4369 = _396_fa_fog_b.y * _4325;\n                }\n                else\n                {\n                    _4369 = (_396_fa_fog_b.y * (1.0f - exp(-min(_396_fa_fog_b.w * _4325, 80.0f)))) / _396_fa_fog_b.w;\n                }\n                bool _4394 = _4330 <= 0.0f;\n                bool _4401;\n                if (!_4394)\n                {\n                    _4401 = _396_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4401 = _4394;\n                }\n                float _4402;\n                if (_4401)\n                {\n                    _4402 = _396_fa_fog_b.y * _4330;\n                }\n                else\n                {\n                    _4402 = (_396_fa_fog_b.y * (1.0f - exp(-min(_396_fa_fog_b.w * _4330, 80.0f)))) / _396_fa_fog_b.w;\n                }\n                float _4429;\n                if (abs(_4320) < 0.001000000047497451305389404296875f)\n                {\n                    _4429 = _4341;\n                }\n                else\n                {\n                    _4429 = (_4402 - _4369) / _4320;\n                }\n                tau += (_4270 * max(_4429, 0.0f));\n            }\n            result = lerp(result, _396_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4560);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 624,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_396",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2053",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _292 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _292;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _299 = _160.world_pos;\n    float4 _171 = float4(_299, 1.0f);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -mul(_171, _131_fa_light_vp).z;\n    fa_pre_r0 = float3(_131_fa_light_vp[0].x, _131_fa_light_vp[1].x, _131_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131_fa_light_vp[0].y, _131_fa_light_vp[1].y, _131_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131_fa_light_vp[0].z, _131_fa_light_vp[1].z, _131_fa_light_vp[2].z);\n    gl_Position = mul(_171, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _215_fa_camera_pos : packoffset(c0);\n    float4 _215_fa_ambient : packoffset(c1);\n    float4 _215_fa_base_color : packoffset(c2);\n    float4 _215_fa_emissive : packoffset(c3);\n    float4 _215_fa_model_emissive : packoffset(c4);\n    float4 _215_fa_pbr : packoffset(c5);\n    float4 _215_fa_maps : packoffset(c6);\n    float4 _215_fa_fog : packoffset(c7);\n    float4 _215_fa_fog_b : packoffset(c8);\n    float4 _215_fa_fog_c : packoffset(c9);\n    float4 _215_fa_counts : packoffset(c10);\n    float4 _215_fa_env_sky : packoffset(c11);\n    float4 _215_fa_env_horizon : packoffset(c12);\n    float4 _215_fa_time : packoffset(c13);\n    float4 _215_fa_cl_vpx : packoffset(c14);\n    float4 _215_fa_cl_vpy : packoffset(c15);\n    float4 _215_fa_cl_vpw : packoffset(c16);\n    float4 _215_fa_cl_fwd : packoffset(c17);\n    float4 _215_fa_cl_grid : packoffset(c18);\n    float4 _215_fa_cl_info : packoffset(c19);\n    float4 _215_fa_layers_a : packoffset(c20);\n    float4 _215_fa_layers_b : packoffset(c21);\n    float4 _215_fa_layers_c : packoffset(c22);\n    float4 _215_fa_layers_d : packoffset(c23);\n    float4 _215_fa_ct_a : packoffset(c24);\n    float4 _215_fa_ct_b : packoffset(c25);\n    float4 _215_fa_ct_vpx : packoffset(c26);\n    float4 _215_fa_ct_vpy : packoffset(c27);\n    float4 _215_fa_ct_vpw : packoffset(c28);\n    float4 _215_fa_ct_fwd : packoffset(c29);\n    float4 _215_fa_probe_sh[9] : packoffset(c30);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _215_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _227 = fa_tex_fix(param_2, param_3);\n    float4 _787 = base_t;\n    _787.x = _227.x;\n    _787.y = _227.y;\n    _787.z = _227.z;\n    base_t = _787;\n    float4 _243 = (_787 * _215_fa_base_color) * i.vertex_color;\n    float3 _750 = i.world_normal;\n    if (_215_fa_maps.z > 0.5f)\n    {\n        float param_4 = _215_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _277 = fa_tex_fix(param_6, param_7);\n        float3 _281 = (_277 * 2.0f) - 1.0f.xxx;\n        float2 _286 = _281.xy * _215_fa_maps.x;\n        float3 _795 = _281;\n        _795.x = _286.x;\n        _795.y = _286.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _795;\n        _750 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _215_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _315 = fa_tex_fix(param_12, param_13);\n    float4 _798 = mrt;\n    _798.x = _315.x;\n    _798.y = _315.y;\n    _798.z = _315.z;\n    mrt = _798;\n    float4 _345 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _215_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = _215_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _387 = fa_tex_fix(param_20, param_21);\n    float _755 = _215_fa_layers_a.x;\n    float _756 = _215_fa_layers_a.y;\n    float _759 = _215_fa_layers_a.z;\n    float _758 = _215_fa_layers_b.w;\n    float _761 = _215_fa_layers_c.x;\n    if (_215_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_215_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _755 *= _357.y;\n            _756 *= _357.z;\n            _758 *= _345.w;\n        }\n        if (_215_fa_layers_c.z > 1.5f)\n        {\n            _759 *= mrt.x;\n            _761 *= mrt.w;\n        }\n    }\n    Surface _780 = { _243.xyz, _243.w, _750, clamp(_215_fa_pbr.x * _315.z, 0.0f, 1.0f), clamp(_215_fa_pbr.y * _315.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_215_fa_maps.y * (_357.x - 1.0f)), _215_fa_emissive.xyz + (_215_fa_model_emissive.xyz * _387), _755, _756, _215_fa_layers_b.xyz, _758, _759, _215_fa_layers_a.w, _761, _215_fa_layers_c.y, _215_fa_layers_d.xyz };\n    return _780;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _661 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _661 = -_661;\n    }\n    float3 _521 = normalize(_215_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _674 = { fa_world_pos, _661, fa_world_tangent, fa_uv, fa_vertex_color, _521, gl_FrontFacing };\n    SurfaceInput param = _674;\n    SurfaceInput _682 = { fa_world_pos, _661, fa_world_tangent, fa_uv, fa_vertex_color, _521, gl_FrontFacing };\n    SurfaceInput param_1 = _682;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _536 = normalize(param_2.normal);\n    float3 _551 = normalize(float3(dot(fa_pre_r0, _536), dot(fa_pre_r1, _536), dot(fa_pre_r2, _536)));\n    float _563 = _551.z;\n    float2 e = _551.xy / ((abs(_551.x) + abs(_551.y)) + abs(_563)).xx;\n    if (_563 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 624,
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _215_fa_camera_pos : packoffset(c0);\n    float4 _215_fa_ambient : packoffset(c1);\n    float4 _215_fa_base_color : packoffset(c2);\n    float4 _215_fa_emissive : packoffset(c3);\n    float4 _215_fa_model_emissive : packoffset(c4);\n    float4 _215_fa_pbr : packoffset(c5);\n    float4 _215_fa_maps : packoffset(c6);\n    float4 _215_fa_fog : packoffset(c7);\n    float4 _215_fa_fog_b : packoffset(c8);\n    float4 _215_fa_fog_c : packoffset(c9);\n    float4 _215_fa_counts : packoffset(c10);\n    float4 _215_fa_env_sky : packoffset(c11);\n    float4 _215_fa_env_horizon : packoffset(c12);\n    float4 _215_fa_time : packoffset(c13);\n    float4 _215_fa_cl_vpx : packoffset(c14);\n    float4 _215_fa_cl_vpy : packoffset(c15);\n    float4 _215_fa_cl_vpw : packoffset(c16);\n    float4 _215_fa_cl_fwd : packoffset(c17);\n    float4 _215_fa_cl_grid : packoffset(c18);\n    float4 _215_fa_cl_info : packoffset(c19);\n    float4 _215_fa_layers_a : packoffset(c20);\n    float4 _215_fa_layers_b : packoffset(c21);\n    float4 _215_fa_layers_c : packoffset(c22);\n    float4 _215_fa_layers_d : packoffset(c23);\n    float4 _215_fa_ct_a : packoffset(c24);\n    float4 _215_fa_ct_b : packoffset(c25);\n    float4 _215_fa_ct_vpx : packoffset(c26);\n    float4 _215_fa_ct_vpy : packoffset(c27);\n    float4 _215_fa_ct_vpw : packoffset(c28);\n    float4 _215_fa_ct_fwd : packoffset(c29);\n    float4 _215_fa_probe_sh[9] : packoffset(c30);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _215_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _227 = fa_tex_fix(param_2, param_3);\n    float4 _787 = base_t;\n    _787.x = _227.x;\n    _787.y = _227.y;\n    _787.z = _227.z;\n    base_t = _787;\n    float4 _243 = (_787 * _215_fa_base_color) * i.vertex_color;\n    float3 _750 = i.world_normal;\n    if (_215_fa_maps.z > 0.5f)\n    {\n        float param_4 = _215_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _277 = fa_tex_fix(param_6, param_7);\n        float3 _281 = (_277 * 2.0f) - 1.0f.xxx;\n        float2 _286 = _281.xy * _215_fa_maps.x;\n        float3 _795 = _281;\n        _795.x = _286.x;\n        _795.y = _286.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _795;\n        _750 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _215_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _315 = fa_tex_fix(param_12, param_13);\n    float4 _798 = mrt;\n    _798.x = _315.x;\n    _798.y = _315.y;\n    _798.z = _315.z;\n    mrt = _798;\n    float4 _345 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _215_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = _215_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _387 = fa_tex_fix(param_20, param_21);\n    float _755 = _215_fa_layers_a.x;\n    float _756 = _215_fa_layers_a.y;\n    float _759 = _215_fa_layers_a.z;\n    float _758 = _215_fa_layers_b.w;\n    float _761 = _215_fa_layers_c.x;\n    if (_215_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_215_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _755 *= _357.y;\n            _756 *= _357.z;\n            _758 *= _345.w;\n        }\n        if (_215_fa_layers_c.z > 1.5f)\n        {\n            _759 *= mrt.x;\n            _761 *= mrt.w;\n        }\n    }\n    Surface _780 = { _243.xyz, _243.w, _750, clamp(_215_fa_pbr.x * _315.z, 0.0f, 1.0f), clamp(_215_fa_pbr.y * _315.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_215_fa_maps.y * (_357.x - 1.0f)), _215_fa_emissive.xyz + (_215_fa_model_emissive.xyz * _387), _755, _756, _215_fa_layers_b.xyz, _758, _759, _215_fa_layers_a.w, _761, _215_fa_layers_c.y, _215_fa_layers_d.xyz };\n    return _780;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _661 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _661 = -_661;\n    }\n    float3 _521 = normalize(_215_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _674 = { fa_world_pos, _661, fa_world_tangent, fa_uv, fa_vertex_color, _521, gl_FrontFacing };\n    SurfaceInput param = _674;\n    SurfaceInput _682 = { fa_world_pos, _661, fa_world_tangent, fa_uv, fa_vertex_color, _521, gl_FrontFacing };\n    SurfaceInput param_1 = _682;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _536 = normalize(param_2.normal);\n    float3 _551 = normalize(float3(dot(fa_pre_r0, _536), dot(fa_pre_r1, _536), dot(fa_pre_r2, _536)));\n    float _563 = _551.z;\n    float2 e = _551.xy / ((abs(_551.x) + abs(_551.y)) + abs(_563)).xx;\n    if (_563 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 624,
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
