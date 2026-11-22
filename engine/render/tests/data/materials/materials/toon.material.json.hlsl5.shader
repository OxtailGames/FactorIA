{
  "format": "factoria.shader/1",
  "engine": "0.34.0",
  "template": "d5ad4ba00a2086cd5c3d6440d2be629e3ce9b0f8ede644c9a19112677c2fea28",
  "slang": "hlsl5",
  "params": [
    "dark"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _263 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _263;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_270, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _366_fa_camera_pos : packoffset(c0);\n    float4 _366_fa_ambient : packoffset(c1);\n    float4 _366_fa_base_color : packoffset(c2);\n    float4 _366_fa_emissive : packoffset(c3);\n    float4 _366_fa_model_emissive : packoffset(c4);\n    float4 _366_fa_pbr : packoffset(c5);\n    float4 _366_fa_maps : packoffset(c6);\n    float4 _366_fa_fog : packoffset(c7);\n    float4 _366_fa_fog_b : packoffset(c8);\n    float4 _366_fa_fog_c : packoffset(c9);\n    float4 _366_fa_counts : packoffset(c10);\n    float4 _366_fa_env_sky : packoffset(c11);\n    float4 _366_fa_env_horizon : packoffset(c12);\n    float4 _366_fa_time : packoffset(c13);\n    float4 _366_fa_cl_vpx : packoffset(c14);\n    float4 _366_fa_cl_vpy : packoffset(c15);\n    float4 _366_fa_cl_vpw : packoffset(c16);\n    float4 _366_fa_cl_fwd : packoffset(c17);\n    float4 _366_fa_cl_grid : packoffset(c18);\n    float4 _366_fa_cl_info : packoffset(c19);\n    float4 _366_fa_layers_a : packoffset(c20);\n    float4 _366_fa_layers_b : packoffset(c21);\n    float4 _366_fa_layers_c : packoffset(c22);\n    float4 _366_fa_layers_d : packoffset(c23);\n    float4 _366_fa_ct_a : packoffset(c24);\n    float4 _366_fa_ct_b : packoffset(c25);\n    float4 _366_fa_ct_vpx : packoffset(c26);\n    float4 _366_fa_ct_vpy : packoffset(c27);\n    float4 _366_fa_ct_vpw : packoffset(c28);\n    float4 _366_fa_ct_fwd : packoffset(c29);\n    float4 _366_fa_tr_a : packoffset(c30);\n    float4 _366_fa_tr_b : packoffset(c31);\n    float4 _366_fa_probe_sh[9] : packoffset(c32);\n    float4 _366_fa_atlas : packoffset(c41);\n    float4 _366_fa_rpa_tile : packoffset(c42);\n    float4 _366_fa_rpa_pos : packoffset(c43);\n    float4 _366_fa_rpa_bx : packoffset(c44);\n    float4 _366_fa_rpa_by : packoffset(c45);\n    float4 _366_fa_rpa_bz : packoffset(c46);\n    float4 _366_fa_rpb_tile : packoffset(c47);\n    float4 _366_fa_rpb_pos : packoffset(c48);\n    float4 _366_fa_rpb_bx : packoffset(c49);\n    float4 _366_fa_rpb_by : packoffset(c50);\n    float4 _366_fa_rpb_bz : packoffset(c51);\n    float4 _366_fa_gi : packoffset(c52);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2100_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2100_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2100_fa_shadow_info[4] : packoffset(c20);\n    float4 _2100_fa_shadow_split : packoffset(c24);\n    float4 _2100_fa_shadow_cfg : packoffset(c25);\n    float4 _2100_fa_shadow_bias : packoffset(c26);\n    float4 _2100_fa_shadow_eye : packoffset(c27);\n    float4 _2100_fa_shadow_fwd : packoffset(c28);\n    float4 _2100_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _3964_dark : packoffset(c0);\n    float _3964_fa_pad0 : packoffset(c0.y);\n    float _3964_fa_pad1 : packoffset(c0.z);\n    float _3964_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_probe_atlas : register(t6);\nTexture2D<float4> fa_screen_tex : register(t11);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1382 = _366_fa_cl_info.x < 0.0f;\n    bool _1389;\n    if (!_1382)\n    {\n        _1389 = _366_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1389 = _1382;\n    }\n    bool _1397;\n    if (!_1389)\n    {\n        _1397 = _366_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1397 = _1389;\n    }\n    bool _1404;\n    if (!_1397)\n    {\n        _1404 = _366_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1404 = _1397;\n    }\n    bool _1411;\n    if (!_1404)\n    {\n        _1411 = _366_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1411 = _1404;\n    }\n    if (_1411)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1421 = float4(world_pos, 1.0f);\n    float _1427 = dot(_366_fa_cl_vpw, _1421);\n    if (!(_1427 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1449 = float2(dot(_366_fa_cl_vpx, _1421), dot(_366_fa_cl_vpy, _1421)) / _1427.xx;\n    int _1453 = int(_366_fa_cl_grid.x);\n    int _1457 = int(_366_fa_cl_grid.y);\n    int param = (int(_366_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_366_fa_cl_fwd.xyz, world_pos) + _366_fa_cl_fwd.w, _366_fa_cl_grid.w) / _366_fa_cl_grid.w) * _366_fa_cl_grid.z)), 0, int(_366_fa_cl_info.y) - 1) * _1457) + clamp(int(floor(((_1449.y * 0.5f) + 0.5f) * _366_fa_cl_grid.y)), 0, _1457 - 1)) * _1453)) + clamp(int(floor(((_1449.x * 0.5f) + 0.5f) * _366_fa_cl_grid.x)), 0, _1453 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1533 = fa_cluster_texel(param);\n    return int2(int(_1533.x), int(_1533.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_366_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3782 = fa_cluster_lookup(param);\n    fa_cl_slot = _3782.x;\n    fa_cl_local = _3782.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _4013 = fa_linear_to_srgb(param);\n        c = _4013;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _4021 = fa_srgb_to_linear(param_1);\n            c = _4021;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _298;\n    if (i.front_facing)\n    {\n        _298 = i.world_normal;\n    }\n    else\n    {\n        _298 = -i.world_normal;\n    }\n    float3 _322 = normalize(i.world_tangent.xyz - (_298 * dot(_298, i.world_tangent.xyz)));\n    float3 _349 = normalize(((_322 * m.x) + ((cross(_298, _322) * i.world_tangent.w) * m.y)) + (_298 * m.z));\n    float3 _352;\n    if (i.front_facing)\n    {\n        _352 = _349;\n    }\n    else\n    {\n        _352 = -_349;\n    }\n    return _352;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _366_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _4052 = fa_tex_fix(param_2, param_3);\n    float4 _5824 = base_t;\n    _5824.x = _4052.x;\n    _5824.y = _4052.y;\n    _5824.z = _4052.z;\n    base_t = _5824;\n    float4 _4066 = (_5824 * _366_fa_base_color) * i.vertex_color;\n    float3 _5661 = i.world_normal;\n    if (_366_fa_maps.z > 0.5f)\n    {\n        float param_4 = _366_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4098 = fa_tex_fix(param_6, param_7);\n        float3 _4101 = (_4098 * 2.0f) - 1.0f.xxx;\n        float2 _4106 = _4101.xy * _366_fa_maps.x;\n        float3 _5832 = _4101;\n        _5832.x = _4106.x;\n        _5832.y = _4106.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5832;\n        _5661 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _366_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4134 = fa_tex_fix(param_12, param_13);\n    float4 _5835 = mrt;\n    _5835.x = _4134.x;\n    _5835.y = _4134.y;\n    _5835.z = _4134.z;\n    mrt = _5835;\n    float4 _4162 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _366_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _4162.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4173 = fa_tex_fix(param_16, param_17);\n    float param_18 = _366_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4203 = fa_tex_fix(param_20, param_21);\n    float _5666 = _366_fa_layers_a.x;\n    float _5667 = _366_fa_layers_a.y;\n    float _5670 = _366_fa_layers_a.z;\n    float _5669 = _366_fa_layers_b.w;\n    float _5672 = _366_fa_layers_c.x;\n    if (_366_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_366_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _5666 *= _4173.y;\n            _5667 *= _4173.z;\n            _5669 *= _4162.w;\n        }\n        if (_366_fa_layers_c.z > 1.5f)\n        {\n            _5670 *= mrt.x;\n            _5672 *= mrt.w;\n        }\n    }\n    Surface _5699 = { _4066.xyz, _4066.w, _5661, clamp(_366_fa_pbr.x * _4134.z, 0.0f, 1.0f), clamp(_366_fa_pbr.y * _4134.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_366_fa_maps.y * (_4173.x - 1.0f)), _366_fa_emissive.xyz + (_366_fa_model_emissive.xyz * _4203), _5666, _5667, _366_fa_layers_b.xyz, _5669, _5670, _366_fa_layers_a.w, _5672, _366_fa_layers_c.y, _366_fa_layers_d.xyz, _366_fa_tr_a.x, _366_fa_tr_a.y, _366_fa_tr_b.xyz, _366_fa_tr_a.z };\n    return _5699;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1613 = rect.zw - rect.xy;\n    float2 _1617 = _1613 * atlas;\n    float2 _1621 = ddx * _1617;\n    float2 _1625 = ddy * _1617;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1613), clamp(0.5f * log2(max(max(dot(_1621, _1621), dot(_1625, _1625)), 9.9999999392252902907785028219223e-09f)), 0.0f, 3.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1658 = _366_fa_counts.y < 0.5f;\n    bool _1665;\n    if (!_1658)\n    {\n        _1665 = _366_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1665 = _1658;\n    }\n    if (_1665)\n    {\n        return;\n    }\n    float3 _1671 = ddx(world_pos);\n    float3 _1674 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1678 = fa_cluster_texel(param);\n    int _1682 = int(_1678.w);\n    if (_1682 < 1)\n    {\n        return;\n    }\n    int _1692 = int(_366_fa_counts.y + 0.5f);\n    int param_1 = _1692;\n    float4 _1696 = fa_light_texel(param_1);\n    float2 _1699 = _1696.yz;\n    int _1703 = int(_1696.w);\n    int param_2 = _1692 + 1;\n    float4 _1708 = fa_light_texel(param_2);\n    float _1709 = _1708.x;\n    int _1715 = int(_366_fa_counts.w + 0.5f) - 1;\n    int _1719 = int(_1678.z);\n    float3 _1984;\n    for (int k = 0; k < _1682; k++)\n    {\n        int _1732 = _1719 + k;\n        int param_3 = _1703 + (_1732 >> 2);\n        int _1749 = (_1692 + 2) + (int(fa_light_texel(param_3)[_1732 & 3]) * 7);\n        int param_4 = _1749 + 6;\n        float4 _1754 = fa_light_texel(param_4);\n        if (((int(_1754.w + 0.5f) >> _1715) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1749;\n        float4 _1769 = fa_light_texel(param_5);\n        int param_6 = _1749 + 1;\n        float4 _1774 = fa_light_texel(param_6);\n        int param_7 = _1749 + 2;\n        float4 _1779 = fa_light_texel(param_7);\n        float3 _1782 = _1769.xyz;\n        float _1787 = dot(_1782, world_pos) + _1769.w;\n        float3 _1789 = _1774.xyz;\n        float _1794 = dot(_1789, world_pos) + _1774.w;\n        float3 _1796 = _1779.xyz;\n        float _1801 = dot(_1796, world_pos) + _1779.w;\n        bool _1806 = abs(_1787) > 0.5f;\n        bool _1814;\n        if (!_1806)\n        {\n            _1814 = abs(_1794) > 0.5f;\n        }\n        else\n        {\n            _1814 = _1806;\n        }\n        bool _1822;\n        if (!_1814)\n        {\n            _1822 = abs(_1801) > 0.5f;\n        }\n        else\n        {\n            _1822 = _1814;\n        }\n        if (_1822)\n        {\n            continue;\n        }\n        float _1837 = clamp(dot(geo_normal, normalize(_1796)) * _1754.z, 0.0f, 1.0f);\n        if (_1837 <= 0.0f)\n        {\n            continue;\n        }\n        float _1857 = (clamp((0.5f - abs(_1801)) * 10.0f, 0.0f, 1.0f) * _1837) * _1754.x;\n        float2 _1865 = float2(_1787 + 0.5f, 0.5f - _1794);\n        float2 _1875 = float2(dot(_1782, _1671), dot(_1789, _1671));\n        float2 _1885 = float2(dot(_1782, _1674), dot(_1789, _1674));\n        int param_8 = _1749 + 5;\n        float4 _1890 = fa_light_texel(param_8);\n        int param_9 = _1749 + 3;\n        float4 _1895 = fa_light_texel(param_9);\n        int param_10 = _1749 + 4;\n        float4 _1900 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1890.xyz;\n        bool _1910 = _1895.z > _1895.x;\n        if (_1910)\n        {\n            float4 param_11 = _1895;\n            float2 param_12 = _1865;\n            float2 param_13 = _1699;\n            float2 param_14 = _1875;\n            float2 param_15 = _1885;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1709 > 0.5f) && (_1709 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1936 = fa_dc_to_linear(param_16);\n                float4 _5749 = tx;\n                _5749.x = _1936.x;\n                _5749.y = _1936.y;\n                _5749.z = _1936.z;\n                tx = _5749;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1857 * tex_a) * _1890.w, 0.0f, 1.0f).xxx);\n        if (_1900.z > _1900.x)\n        {\n            float4 param_17 = _1900;\n            float2 param_18 = _1865;\n            float2 param_19 = _1699;\n            float2 param_20 = _1875;\n            float2 param_21 = _1885;\n            float4 _1980 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1709 > 1.5f)\n            {\n                float3 param_22 = _1980.xyz;\n                float3 _1990 = fa_dc_to_srgb(param_22);\n                _1984 = _1990;\n            }\n            else\n            {\n                _1984 = _1980.xyz;\n            }\n            float3 _1999 = (_1984 * 2.0f) - 1.0f.xxx;\n            float2 _2004 = _1999.xy * _1754.y;\n            float3 _2026 = (normalize(_1782) * _2004.x) + (normalize(_1789) * _2004.y);\n            float3 _2029 = normalize(normal);\n            normal = normalize(lerp(_2029, normalize((_2029 * max(_1999.z, 0.0500000007450580596923828125f)) + (_2026 - (_2029 * dot(_2029, _2026)))), clamp(_1857 * (_1910 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nvoid fa_lod_dither()\n{\n    if (_366_fa_gi.w != 0.0f)\n    {\n        float _388 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n        bool _391;\n        if (_366_fa_gi.w > 0.0f)\n        {\n            _391 = _388 >= _366_fa_gi.w;\n        }\n        else\n        {\n            _391 = _388 < (-_366_fa_gi.w);\n        }\n        if (_391)\n        {\n            discard;\n        }\n    }\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3295_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3295_dummy_parameter)));\n}\n\nfloat3 fa_probe_sh_coef(float2 origin, float res, int k)\n{\n    float3 v = fa_probe_atlas.SampleLevel(fa_env_smp, (origin + float2(float(k) + 0.5f, res + 2.5f)) / fa_atlas_size(), 0.0f).xyz;\n    if (_366_fa_atlas.y > 0.5f)\n    {\n        v = ((v * 255.0f) - 128.0f.xxx) * 0.03149606287479400634765625f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3236 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3236;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    float _3346 = (1.0f - _366_fa_rpa_tile.w) - _366_fa_rpb_tile.w;\n    float3 amb = 0.0f.xxx;\n    bool _3352 = _366_fa_env_sky.w > 0.5f;\n    float3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = 0.0f.xxx;\n    }\n    if (_3346 > 0.0005000000237487256526947021484375f)\n    {\n        if (_3352)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _366_fa_atlas.zw;\n                float param_1 = 128.0f;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3346;\n            }\n        }\n        else\n        {\n            amb = _366_fa_ambient.xyz * _3346;\n        }\n    }\n    bool _3404 = _366_fa_rpa_tile.w > 0.0f;\n    if (_3404)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _366_fa_rpa_tile.xy;\n            float param_4 = _366_fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * _366_fa_rpa_tile.w);\n        }\n    }\n    bool _3435 = _366_fa_rpb_tile.w > 0.0f;\n    if (_3435)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _366_fa_rpb_tile.xy;\n            float param_7 = _366_fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * _366_fa_rpb_tile.w);\n        }\n    }\n    if ((_3352 || _3404) || _3435)\n    {\n        float3 param_9[9] = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nfloat4 fa_gi_fetch(float2 texel)\n{\n    return fa_probe_atlas.SampleLevel(fa_env_smp, texel / fa_atlas_size(), 0.0f);\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3256 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3259 = _3256.x;\n    float _3261 = _3256.z;\n    float2 e = float2(_3259, _3261);\n    if (_3256.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3261)) * ((_3259 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3259)) * ((_3261 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat3 fa_gi_grid(int rec, float3 n, float3 v, out float cover)\n{\n    cover = 0.0f;\n    int param = rec;\n    float4 _4317 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    float4 _4322 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    float4 _4327 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    float4 _4332 = fa_light_texel(param_3);\n    bool _4335 = _4332.z < 0.5f;\n    bool _4343;\n    if (!_4335)\n    {\n        _4343 = fa_atlas_size().y < 1155.0f;\n    }\n    else\n    {\n        _4343 = _4335;\n    }\n    if (_4343)\n    {\n        return 0.0f.xxx;\n    }\n    float _4350 = max(_4317.w, 9.9999997473787516355514526367188e-05f);\n    float3 _4353 = _4322.xyz;\n    float3 _4357 = _4317.xyz;\n    float3 _4361 = (fa_world_pos - _4357) / _4350.xxx;\n    float3 _4370 = min(_4361 + 0.5f.xxx, (_4353 - 0.5f.xxx) - _4361);\n    float _4379 = min(_4370.x, min(_4370.y, _4370.z));\n    if (!(_4379 > 0.0f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _4394 = _4353 - 1.0f.xxx;\n    float3 _4395 = clamp(_4361, 0.0f.xxx, _4394);\n    float3 _4403 = min(floor(_4395), max(_4353 - 2.0f.xxx, 0.0f.xxx));\n    float3 _4407 = _4395 - _4403;\n    float3 _4419 = fa_world_pos + (((n * 0.800000011920928955078125f) + (v * 0.20000000298023223876953125f)) * (0.20000000298023223876953125f * _4350));\n    int _4424 = int(_4327.y + 0.5f);\n    float _4429 = 0.3257350027561187744140625f * n.y;\n    float _4433 = 0.3257350027561187744140625f * n.z;\n    float _4437 = 0.3257350027561187744140625f * n.x;\n    float _4444 = (0.2731371223926544189453125f * n.x) * n.y;\n    float _4451 = (0.2731371223926544189453125f * n.y) * n.z;\n    float _4460 = 0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f);\n    float _4467 = (0.2731371223926544189453125f * n.x) * n.z;\n    float _4480 = 0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y));\n    float3 acc = 0.0f.xxx;\n    float wsum = 0.0f;\n    int _4487 = 8 + int(_4332.w);\n    float _4514;\n    float _4527;\n    float _4541;\n    for (int k = 0; k < _4487; k++)\n    {\n        float _4500 = float(k & 1);\n        float _4504 = float((k >> 1) & 1);\n        float _4508 = float((k >> 2) & 1);\n        if (_4500 > 0.5f)\n        {\n            _4514 = _4407.x;\n        }\n        else\n        {\n            _4514 = 1.0f - _4407.x;\n        }\n        if (_4504 > 0.5f)\n        {\n            _4527 = _4407.y;\n        }\n        else\n        {\n            _4527 = 1.0f - _4407.y;\n        }\n        if (_4508 > 0.5f)\n        {\n            _4541 = _4407.z;\n        }\n        else\n        {\n            _4541 = 1.0f - _4407.z;\n        }\n        float _4551 = (_4514 * _4527) * _4541;\n        if (!(_4551 > 0.0f))\n        {\n            continue;\n        }\n        float3 _4564 = min(_4403 + float3(_4500, _4504, _4508), _4394);\n        int _4584 = int(((_4327.x + _4564.x) + (_4322.x * (_4564.y + (_4322.y * _4564.z)))) + 0.5f);\n        float2 _4599 = float2(float(_4584 % _4424) * 10.0f, 1024.0f + (float(_4584 / _4424) * 11.0f));\n        float2 param_4 = _4599 + float2(9.5f, 10.5f);\n        float4 _4607 = fa_gi_fetch(param_4);\n        bool _4610 = _4607.y < 0.5f;\n        bool _4619;\n        if (!_4610)\n        {\n            _4619 = _4607.x > _4332.y;\n        }\n        else\n        {\n            _4619 = _4610;\n        }\n        if (_4619)\n        {\n            continue;\n        }\n        float3 _4631 = _4419 - (_4357 + (_4564 * _4350));\n        float _4634 = length(_4631);\n        float3 _4640 = _4631 / max(_4634, 9.9999997473787516355514526367188e-05f).xxx;\n        float _4650 = max(9.9999997473787516355514526367188e-05f, (dot(-_4640, n) + 1.0f) * 0.5f);\n        float w = _4551 * (_4650 * _4650);\n        float3 param_5 = _4640;\n        float2 param_6 = (_4599 + 1.0f.xx) + (((fa_oct_encode(param_5) * 0.5f) + 0.5f.xx) * 8.0f);\n        float4 _4670 = fa_gi_fetch(param_6);\n        float _4677 = _4634 / max(_4327.z, 9.9999997473787516355514526367188e-05f);\n        float _4680 = _4670.x;\n        if (_4677 > _4680)\n        {\n            float _4693 = max(_4670.y - (_4680 * _4680), 0.0f);\n            float _4698 = _4677 - _4680;\n            float _4707 = _4693 / max(_4693 + (_4698 * _4698), 9.9999999600419720025001879548654e-13f);\n            w *= ((_4707 * _4707) * _4707);\n        }\n        if (!(w > 0.0f))\n        {\n            continue;\n        }\n        float2 param_7 = _4599 + float2(0.5f, 10.5f);\n        float2 param_8 = _4599 + float2(1.5f, 10.5f);\n        float2 param_9 = _4599 + float2(2.5f, 10.5f);\n        float2 param_10 = _4599 + float2(3.5f, 10.5f);\n        float2 param_11 = _4599 + float2(4.5f, 10.5f);\n        float2 param_12 = _4599 + float2(5.5f, 10.5f);\n        float2 param_13 = _4599 + float2(6.5f, 10.5f);\n        float2 param_14 = _4599 + float2(7.5f, 10.5f);\n        float2 param_15 = _4599 + float2(8.5f, 10.5f);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375f) + (fa_gi_fetch(param_8).xyz * _4429)) + (fa_gi_fetch(param_9).xyz * _4433)) + (fa_gi_fetch(param_10).xyz * _4437)) + (fa_gi_fetch(param_11).xyz * _4444)) + (fa_gi_fetch(param_12).xyz * _4451)) + (fa_gi_fetch(param_13).xyz * _4460)) + (fa_gi_fetch(param_14).xyz * _4467)) + (fa_gi_fetch(param_15).xyz * _4480)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06f))\n    {\n        return 0.0f.xxx;\n    }\n    cover = smoothstep(0.0f, 1.0f, clamp(_4379 * 2.0f, 0.0f, 1.0f)) * smoothstep(0.0f, 0.0199999995529651641845703125f, wsum);\n    float _4834;\n    if (_366_fa_gi.z > 0.5f)\n    {\n        _4834 = _4332.x;\n    }\n    else\n    {\n        _4834 = 1.0f;\n    }\n    return max(acc / wsum.xxx, 0.0f.xxx) * (_4327.w * _4834);\n}\n\nfloat3 fa_gi_light(float3 n, inout float left)\n{\n    left = 1.0f;\n    float3 acc = 0.0f.xxx;\n    float3 _4858 = normalize(_366_fa_camera_pos.xyz - fa_world_pos);\n    int _4863 = int(_366_fa_gi.x + 0.5f);\n    int _4868 = int(_366_fa_gi.y + 0.5f);\n    float param_3;\n    for (int k = 0; (k < _4868) && (k < 8); k++)\n    {\n        int param = _4863 + (4 * k);\n        float3 param_1 = n;\n        float3 param_2 = _4858;\n        float3 _4893 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _4898 = param_3 * left;\n        acc += (_4893 * _4898);\n        left -= _4898;\n        if (left < 0.001000000047497451305389404296875f)\n        {\n            left = 0.0f;\n            break;\n        }\n    }\n    return acc;\n}\n\nfloat3 fa_realtime_or_ambient(float3 n)\n{\n    float3 gi = 0.0f.xxx;\n    float left = 1.0f;\n    if (_366_fa_gi.y > 0.5f)\n    {\n        float3 param = n;\n        float param_1;\n        float3 _4927 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _4927;\n    }\n    if (left <= 0.0f)\n    {\n        return gi;\n    }\n    float3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_366_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _366_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_366_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_366_fa_cl_info.x) + int(_366_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_366_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _3752;\n    if (fa_lm.z > 0.5f)\n    {\n        _3752 = 0.0f;\n    }\n    else\n    {\n        _3752 = 1.0f - clamp(_366_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _3763 = _3752 < 1.0f;\n    bool _3769;\n    if (_3763)\n    {\n        int param = li;\n        _3769 = fa_light_baked(param);\n    }\n    else\n    {\n        _3769 = _3763;\n    }\n    return _3769 ? _3752 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _632 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _645 = (c - (ru * hx)) - p;\n        float3 _651 = ru * (2.0f * hx);\n        float _657 = max(dot(_651, _651), 9.9999999392252902907785028219223e-09f);\n        float _661 = dot(_645, _651);\n        float t = clamp((-_661) / _657, 0.0f, 1.0f);\n        if (_632)\n        {\n            float _676 = dot(r, _651);\n            float _682 = _657 - (_676 * _676);\n            if (abs(_682) > (9.9999997473787516355514526367188e-06f * _657))\n            {\n                t = clamp(((dot(r, _645) * _676) - _661) / _682, 0.0f, 1.0f);\n            }\n        }\n        return (p + _645) + (_651 * t);\n    }\n    float3 q = p;\n    float _714 = dot(r, axis);\n    bool _722;\n    if (_632)\n    {\n        _722 = abs(_714) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _722 = _632;\n    }\n    if (_722)\n    {\n        float _732 = dot(c - p, axis) / _714;\n        if (_732 > 0.0f)\n        {\n            q = p + (r * _732);\n        }\n    }\n    float3 _745 = q - c;\n    float2 xy = float2(dot(_745, ru), dot(_745, uu));\n    if (shape > 0.5f)\n    {\n        float _760 = length(xy);\n        if (_760 > hx)\n        {\n            xy *= (hx / _760);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _513_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _513_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _552 = dot(d, right);\n    float _556 = dot(d, up);\n    float _567;\n    if (((_552 * _552) + (_556 * _556)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _567 = atan2(_556, _552) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _567 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_567 - floor(_567)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _408 = abs(d);\n    float _410 = _408.x;\n    float _412 = _408.y;\n    bool _413 = _410 >= _412;\n    bool _421;\n    if (_413)\n    {\n        _421 = _410 >= _408.z;\n    }\n    else\n    {\n        _421 = _413;\n    }\n    int _422;\n    if (_421)\n    {\n        _422 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _436;\n        if (_412 >= _408.z)\n        {\n            _436 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _436 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _422 = _436;\n    }\n    return _422;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _798 = fa_light_base(param);\n    bool _802 = _366_fa_ambient.w > 4.5f;\n    int param_1 = _798;\n    float4 _806 = fa_light_texel(param_1);\n    int param_2 = _798 + 1;\n    float4 _811 = fa_light_texel(param_2);\n    float _814 = _811.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _826 = _802 && (_814 > 2.5f);\n    fa_light_is_area = _826;\n    bool _828 = _814 < 0.5f;\n    float3 l;\n    if (_828)\n    {\n        l = normalize(_806.xyz);\n        if (_802)\n        {\n            int param_3 = _798 + 6;\n            float4 _842 = fa_light_texel(param_3);\n            if (_842.z > 0.5f)\n            {\n                int param_4 = _798 + 4;\n                float4 _852 = fa_light_texel(param_4);\n                int param_5 = _798 + 5;\n                float4 _857 = fa_light_texel(param_5);\n                float2 param_6 = _842.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _852.xyz) * _852.w, (-dot(world_pos, _857.xyz)) * _857.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _887 = _806.xyz;\n        float3 _889 = _887 - world_pos;\n        float3 to_light = _889;\n        float _892 = length(_889);\n        float reach = _892;\n        bool front = true;\n        if (_826)\n        {\n            int param_8 = _798 + 7;\n            reach = max(_892 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _798 + 4;\n            float4 _916 = fa_light_texel(param_9);\n            int param_10 = _798 + 5;\n            float4 _921 = fa_light_texel(param_10);\n            int param_11 = _798 + 6;\n            float4 _926 = fa_light_texel(param_11);\n            float _927 = _926.w;\n            int param_12 = _798 + 2;\n            float3 _934 = normalize(fa_light_texel(param_12).xyz);\n            bool _936 = _927 > 1.5f;\n            bool _944;\n            if (!_936)\n            {\n                _944 = dot(_934, to_light) < 0.0f;\n            }\n            else\n            {\n                _944 = _936;\n            }\n            front = _944;\n            float3 r = 0.0f.xxx;\n            float3 _953 = _366_fa_camera_pos.xyz - world_pos;\n            bool _957 = dot(n, n) > 0.5f;\n            bool _965;\n            if (_957)\n            {\n                _965 = dot(_953, _953) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _965 = _957;\n            }\n            if (_965)\n            {\n                r = reflect(-normalize(_953), normalize(n));\n            }\n            float3 param_13 = _887;\n            float3 param_14 = _934;\n            float3 param_15 = _916.xyz;\n            float3 param_16 = _921.xyz;\n            float param_17 = _916.w;\n            float param_18 = _921.w;\n            float param_19 = _927;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1001 = length(to_light);\n        dist = _1001;\n        l = to_light / max(_1001, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1015 = reach / max(_806.w, 0.001000000047497451305389404296875f);\n        float _1021 = clamp(1.0f - (_1015 * _1015), 0.0f, 1.0f);\n        float _1023;\n        if (front)\n        {\n            _1023 = _1021 * _1021;\n        }\n        else\n        {\n            _1023 = 0.0f;\n        }\n        atten = _1023;\n        bool _1034 = _814 < 2.5f;\n        if ((_814 > 1.5f) && _1034)\n        {\n            int param_22 = _798 + 2;\n            float4 _1042 = fa_light_texel(param_22);\n            float _1052 = _1042.w;\n            int param_23 = _798 + 3;\n            float4 _1057 = fa_light_texel(param_23);\n            float _1058 = _1057.x;\n            float cos_inner = _1058;\n            if (_1058 > 1.5f)\n            {\n                cos_inner = lerp(_1052, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1052, cos_inner, dot(-l, normalize(_1042.xyz)));\n        }\n        if (_802 && (_814 < 1.5f))\n        {\n            int param_24 = _798 + 6;\n            float4 _1082 = fa_light_texel(param_24);\n            if (_1082.z > 0.5f)\n            {\n                float3 _1090 = -to_light;\n                int param_25 = _798 + 4;\n                int param_26 = _798 + 5;\n                float3 _1104 = fa_light_texel(param_25).xyz;\n                float3 _1108 = fa_light_texel(param_26).xyz;\n                float3 _1117 = float3(dot(_1090, _1104), dot(_1090, _1108), dot(_1090, cross(_1104, _1108)));\n                float3 param_27 = _1117;\n                int _1121 = fa_cube_face(param_27);\n                int param_28 = _1121;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1148 = float2(dot(_1117, cross(param_29, param_30)), dot(_1117, param_30)) / max(dot(_1117, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1152 = _1121 / 3;\n                float2 param_31 = _1082.xy + (float2(float(_1121 - (_1152 * 3)), float(_1152)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1148.x), 0.5f - (0.5f * _1148.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _798 + 7;\n            float4 _1182 = fa_light_texel(param_33);\n            if (_1182.z > 0.5f)\n            {\n                int param_34 = _798 + 2;\n                int param_35 = _798 + 4;\n                int param_36 = _798 + 5;\n                float2 param_37 = _1182.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_802 && _1034)\n            {\n                int param_42 = _798 + 6;\n                float4 _1229 = fa_light_texel(param_42);\n                int param_43 = _798 + 7;\n                float4 _1234 = fa_light_texel(param_43);\n                bool _1237 = _1229.z > 0.5f;\n                bool _1244;\n                if (!_1237)\n                {\n                    _1244 = _1234.z > 0.5f;\n                }\n                else\n                {\n                    _1244 = _1237;\n                }\n                if (_1244)\n                {\n                    int param_44 = _798 + 2;\n                    float4 _1251 = fa_light_texel(param_44);\n                    float3 _1255 = normalize(_1251.xyz);\n                    int param_45 = _798 + 4;\n                    float4 _1260 = fa_light_texel(param_45);\n                    int param_46 = _798 + 5;\n                    float4 _1265 = fa_light_texel(param_46);\n                    if (_1237)\n                    {\n                        float3 _1273 = -to_light;\n                        float _1280 = _1251.w;\n                        float _1296 = 0.5f / max(dot(_1273, _1255) * (sqrt(max(1.0f - (_1280 * _1280), 0.0f)) / max(_1280, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1229.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1273, _1260.xyz) * _1296), 0.5f - (dot(_1273, _1265.xyz) * _1296));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1234.z > 0.5f)\n                    {\n                        float2 param_49 = _1234.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1255;\n                        float3 param_52 = _1260.xyz;\n                        float3 param_53 = _1265.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _5615 = _811.xyz * atten;\n    if (_802)\n    {\n        _5615 *= fa_light_tint;\n    }\n    int _1364;\n    if (_828)\n    {\n        _1364 = 0;\n    }\n    else\n    {\n        _1364 = ((_814 > 1.5f) && (_814 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _5626 = { l, _5615, atten, 1.0f, dist, _1364 };\n    return _5626;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2147 = fa_shadow_depth(param, param_1);\n    float _2151;\n    if (conv.x < 0.5f)\n    {\n        _2151 = _2147;\n    }\n    else\n    {\n        _2151 = (conv.y * conv.z) / (conv.z - (_2147 * (conv.z - conv.y)));\n    }\n    return _2151;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel_turn(float2 d)\n{\n    return float2((d.x * (-0.737368881702423095703125f)) - (d.y * 0.675490319728851318359375f), (d.y * (-0.737368881702423095703125f)) + (d.x * 0.675490319728851318359375f));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2197 = fa_shadow_noise() * 6.283185482025146484375f;\n    float2 _2203 = float2(cos(_2197), sin(_2197));\n    float2 dir = _2203;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2212;\n        if (k < 0.0f)\n        {\n            _2212 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2212 = k;\n        }\n        float _2231 = clamp((_2212 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2250 = sqrt((float(i) + 0.5f) * 0.0625f) * _2231;\n            float2 param_3 = uv + (dir * (_2100_fa_shadow_bias.zw * _2250));\n            float4 param_4 = rect;\n            float3 param_5 = conv;\n            float _2264 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2264 < (zr - (_2250 * plane)))\n            {\n                sum += _2264;\n                cnt += 1.0f;\n            }\n            float2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2292 = sum / cnt;\n        float _2302;\n        if (k < 0.0f)\n        {\n            _2302 = (-k) / max(_2292, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2302 = k;\n        }\n        radius = clamp(((max(zr - _2292, 0.0f) * unit) * _2302) / texel_m, 1.5f, 16.0f);\n        dir = _2203;\n    }\n    float lit = 0.0f;\n    int _2328 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2328; i_1++)\n    {\n        float _2347 = sqrt((float(i_1) + 0.5f) / float(_2328)) * radius;\n        float2 param_7 = uv + (dir * (_2100_fa_shadow_bias.zw * _2347));\n        float4 param_8 = rect;\n        float3 param_9 = conv;\n        lit += float((zr - (_2347 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        float2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2328);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2552 = _366_fa_pbr.z < 0.5f;\n    bool _2559;\n    if (!_2552)\n    {\n        _2559 = _2100_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2559 = _2552;\n    }\n    if (_2559)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2100_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2572 = fa_light_texel(param);\n    float _2573 = _2572.x;\n    if (_2573 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2582 = int(_2573 + 0.5f);\n    int param_1 = _2582;\n    float4 _2586 = fa_light_texel(param_1);\n    int param_2 = _2582 + 1;\n    float4 _2591 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2594 = _2586.y;\n    if (_2594 > 0.0f)\n    {\n        float _2611 = 1.0f - smoothstep(0.75f * _2594, _2594, length(world - _2100_fa_shadow_eye.xyz));\n        fade = _2611;\n        if (_2611 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2586.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2635 = (_2582 + 2) + (face * 6);\n    int param_4 = _2635;\n    int param_5 = _2635 + 1;\n    int param_6 = _2635 + 3;\n    float4 _2649 = fa_light_texel(param_6);\n    int param_7 = _2635 + 4;\n    float4 _2654 = fa_light_texel(param_7);\n    int param_8 = _2635 + 5;\n    float4 _2659 = fa_light_texel(param_8);\n    float _2671 = _2659.x * max(dot(_2649, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2676 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2699 = clamp(dot(n, _2649.xyz), -1.0f, 1.0f);\n    float _2718 = min(sqrt(1.0f - (_2699 * _2699)) / max(abs(dot(n, world - lpos)) / max(dot(_2649, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2721 = _2591.y;\n    float _2723;\n    if (_2721 > 0.0f)\n    {\n        _2723 = _2721;\n    }\n    else\n    {\n        _2723 = 1.5f * _2671;\n    }\n    float4 _2743 = float4(world + (n * (_2723 * sqrt(1.0f - (_2676 * _2676)))), 1.0f);\n    float _2747 = dot(_2649, _2743);\n    float _2750 = _2659.y;\n    if (_2747 < _2750)\n    {\n        return 1.0f;\n    }\n    float2 _2765 = float2(dot(fa_light_texel(param_4), _2743), dot(fa_light_texel(param_5), _2743)) / _2747.xx;\n    float _2767 = _2765.x;\n    bool _2770 = _2767 < _2654.x;\n    bool _2779;\n    if (!_2770)\n    {\n        _2779 = _2767 > _2654.z;\n    }\n    else\n    {\n        _2779 = _2770;\n    }\n    bool _2788;\n    if (!_2779)\n    {\n        _2788 = _2765.y < _2654.y;\n    }\n    else\n    {\n        _2788 = _2779;\n    }\n    bool _2797;\n    if (!_2788)\n    {\n        _2797 = _2765.y > _2654.w;\n    }\n    else\n    {\n        _2797 = _2788;\n    }\n    if (_2797)\n    {\n        return 1.0f;\n    }\n    float _2803 = _2591.x;\n    float _2805;\n    if (_2803 > 0.0f)\n    {\n        _2805 = _2803;\n    }\n    else\n    {\n        _2805 = 1.5f * _2671;\n    }\n    float2 param_9 = _2765;\n    float4 param_10 = _2654;\n    float param_11 = _2747 - (_2805 * (1.0f + (0.5f * _2718)));\n    float param_12 = _2671;\n    float param_13 = 1.0f;\n    float param_14 = _2659.z * 0.25f;\n    float param_15 = (_2671 * min(_2718, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2750, _2659.z);\n    int param_17 = int(_2586.z + 0.5f);\n    float param_18 = _2586.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2090;\n    if (i == 0)\n    {\n        _2090 = _2100_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2106;\n        if (i == 1)\n        {\n            _2106 = _2100_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2114;\n            if (i == 2)\n            {\n                _2114 = _2100_fa_shadow_split.z;\n            }\n            else\n            {\n                _2114 = _2100_fa_shadow_split.w;\n            }\n            _2106 = _2114;\n        }\n        _2090 = _2106;\n    }\n    return _2090;\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2393 = max(_2100_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2398 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2404 = sqrt(1.0f - (_2398 * _2398));\n    float _2412 = min(_2404 / max(_2398, 0.20000000298023223876953125f), 4.0f);\n    float _2417;\n    if (_2100_fa_shadow_bias.y > 0.0f)\n    {\n        _2417 = _2100_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2417 = 1.5f * _2100_fa_shadow_info[ci].x;\n    }\n    float4 _2442 = mul(float4(world + (n * (_2417 * _2404)), 1.0f), _2100_fa_shadow_mat[ci]);\n    float _2449 = _2442.x;\n    bool _2452 = _2449 < _2100_fa_shadow_rect[ci].x;\n    bool _2461;\n    if (!_2452)\n    {\n        _2461 = _2449 > _2100_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2461 = _2452;\n    }\n    bool _2470;\n    if (!_2461)\n    {\n        _2470 = _2442.y < _2100_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2470 = _2461;\n    }\n    bool _2479;\n    if (!_2470)\n    {\n        _2479 = _2442.y > _2100_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2479 = _2470;\n    }\n    bool _2486;\n    if (!_2479)\n    {\n        _2486 = _2442.z > 1.0f;\n    }\n    else\n    {\n        _2486 = _2479;\n    }\n    if (_2486)\n    {\n        return -1.0f;\n    }\n    float _2494;\n    if (_2100_fa_shadow_bias.x > 0.0f)\n    {\n        _2494 = _2100_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2494 = 1.5f * _2100_fa_shadow_info[ci].x;\n    }\n    float2 param = _2442.xy;\n    float4 param_1 = _2100_fa_shadow_rect[ci];\n    float param_2 = _2442.z - ((_2494 * (1.0f + (0.5f * _2412))) / _2393);\n    float param_3 = _2100_fa_shadow_info[ci].x;\n    float param_4 = _2393;\n    float param_5 = _2393 * 0.25f;\n    float param_6 = ((_2100_fa_shadow_info[ci].x * min(_2412, 3.0f)) * 0.5f) / _2393;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2100_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2100_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_366_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2872 = int(_2100_fa_shadow_cfg.x + 0.5f);\n    if (_2872 < 1)\n    {\n        return 1.0f;\n    }\n    float _2887 = dot(world - _2100_fa_shadow_eye.xyz, _2100_fa_shadow_fwd.xyz);\n    int param = _2872 - 1;\n    if (_2887 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2899 = _2872 > 1;\n    bool _2906;\n    if (_2899)\n    {\n        _2906 = _2887 > _2100_fa_shadow_split.x;\n    }\n    else\n    {\n        _2906 = _2899;\n    }\n    if (_2906)\n    {\n        ci = 1;\n    }\n    bool _2910 = _2872 > 2;\n    bool _2917;\n    if (_2910)\n    {\n        _2917 = _2887 > _2100_fa_shadow_split.y;\n    }\n    else\n    {\n        _2917 = _2910;\n    }\n    if (_2917)\n    {\n        ci = 2;\n    }\n    bool _2921 = _2872 > 3;\n    bool _2928;\n    if (_2921)\n    {\n        _2928 = _2887 > _2100_fa_shadow_split.z;\n    }\n    else\n    {\n        _2928 = _2921;\n    }\n    if (_2928)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    float s2 = -1.0f;\n    float t = 0.0f;\n    int _2939 = min(_2872, 4);\n    float _2980;\n    for (int c = ci; c < _2939; c++)\n    {\n        int param_1 = c;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2959 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0f)\n        {\n            s2 = _2959;\n            break;\n        }\n        if (_2959 < 0.0f)\n        {\n            continue;\n        }\n        s = _2959;\n        ci = c;\n        if (_2100_fa_shadow_cfg.y > 0.0f)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _2980 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _2980 = _2100_fa_shadow_fwd.w;\n            }\n            int param_6 = ci;\n            float _2999 = _2100_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2980, 9.9999997473787516355514526367188e-05f);\n            int param_7 = ci;\n            t = clamp((_2887 - (fa_shadow_split_at(param_7) - _2999)) / _2999, 0.0f, 1.0f);\n        }\n        if (t <= 0.0f)\n        {\n            break;\n        }\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (t > 0.0f)\n    {\n        float _3031;\n        if ((ci + 1) < _2872)\n        {\n            _3031 = (s2 < 0.0f) ? s : s2;\n        }\n        else\n        {\n            _3031 = 1.0f;\n        }\n        s = lerp(s, _3031, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _3486 = _366_fa_ct_a.x < 0.5f;\n    bool _3493;\n    if (!_3486)\n    {\n        _3493 = _2100_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _3493 = _3486;\n    }\n    if (_3493)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2100_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _3506 = fa_light_texel(param);\n    float _3507 = _3506.y;\n    float len = _3507;\n    if (_3507 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3519 = length(world - _366_fa_camera_pos.xyz);\n    float _3529 = 1.0f - smoothstep(0.5f * _366_fa_ct_b.x, _366_fa_ct_b.x, _3519);\n    if (_3529 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3535 = len;\n    float _3538 = min(_3535, 0.89999997615814208984375f * dist);\n    len = _3538;\n    float _3544 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _3519);\n    float _3549 = _3544 + (0.5f * _3538);\n    float3 _3555 = world + (gn * _3544);\n    float _3557 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _3622;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3573 = (float(k) + _3557) * 0.083333335816860198974609375f;\n        float3 _3581 = _3555 + (l * (_3573 * len));\n        float4 _3587 = float4(_3581, 1.0f);\n        float _3593 = dot(_366_fa_ct_vpw, _3587);\n        if (_3593 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _3613 = float2(dot(_366_fa_ct_vpx, _3587), dot(_366_fa_ct_vpy, _3587)) / _3593.xx;\n        float _3617 = _3613.x * 0.5f;\n        float _3618 = _3617 + 0.5f;\n        if (_366_fa_ct_a.y > 0.5f)\n        {\n            _3622 = (_3613.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _3622 = 0.5f - (_3613.y * 0.5f);\n        }\n        bool _3638 = _3618 < 0.0f;\n        bool _3645;\n        if (!_3638)\n        {\n            _3645 = _3618 >= 1.0f;\n        }\n        else\n        {\n            _3645 = _3638;\n        }\n        bool _3652;\n        if (!_3645)\n        {\n            _3652 = _3622 < 0.0f;\n        }\n        else\n        {\n            _3652 = _3645;\n        }\n        bool _3659;\n        if (!_3652)\n        {\n            _3659 = _3622 >= 1.0f;\n        }\n        else\n        {\n            _3659 = _3652;\n        }\n        if (_3659)\n        {\n            break;\n        }\n        float4 _3686 = fa_screen_tex.Load(int3(clamp(int2(float2(_3618, _3622) * _366_fa_ct_a.zw), int2(0, 0), int2(_366_fa_ct_a.zw) - int2(1, 1)), 0));\n        if (_3686.w < 0.5f)\n        {\n            continue;\n        }\n        float _3705 = (dot(_366_fa_ct_fwd.xyz, _3581) + _366_fa_ct_fwd.w) - _3686.x;\n        if ((_3705 > _3544) && (_3705 < _3549))\n        {\n            occ = max(occ, (1.0f - (_3573 * _3573)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_3618, 0.5f - _3617), min(_3622, 1.0f - _3622))));\n        }\n    }\n    return 1.0f - (occ * _3529);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _3808 = fa_baked_keep(param);\n    if (_3808 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _5639 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _5639;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3834 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _5641 = _3834.color;\n    float _5642 = _3834.attenuation;\n    float _5643 = _3834.shadow;\n    bool _3837 = _3834.type == 0;\n    if (_3837 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3834.direction;\n        float _3848 = fa_shadow_factor(param_5, param_6);\n        _5643 = _3848;\n        _5641 *= _3848;\n    }\n    else\n    {\n        bool _3859 = _3834.type != 0;\n        bool _3865;\n        if (_3859)\n        {\n            _3865 = _5642 > 0.0f;\n        }\n        else\n        {\n            _3865 = _3859;\n        }\n        if (_3865)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _3834.direction;\n            float _3884 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _5643 = _3884;\n            _5641 *= _3884;\n        }\n    }\n    bool _3894 = _366_fa_ct_a.x > 0.5f;\n    bool _3900;\n    if (_3894)\n    {\n        _3900 = _5642 > 0.0f;\n    }\n    else\n    {\n        _3900 = _3894;\n    }\n    if (_3900)\n    {\n        float _3907;\n        if (_3837)\n        {\n            _3907 = 1000000000.0f;\n        }\n        else\n        {\n            _3907 = _3834._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _3834.direction;\n        float param_18 = _3907;\n        float _3925 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _5643 *= _3925;\n        _5641 *= _3925;\n    }\n    float _3938 = _5642;\n    float _3939 = _3938 * _3808;\n    _5642 = _3939;\n    float3 _3943 = _5641;\n    float3 _3944 = _3943 * _3808;\n    _5641 = _3944;\n    LightSample _5658 = { _3834.direction, _3944, _3939, _5643, _3834._distance, _3834.type };\n    return _5658;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    float _3958;\n    if (dot(s.normal, l.direction) > 0.5f)\n    {\n        _3958 = 1.0f;\n    }\n    else\n    {\n        _3958 = _3964_dark;\n    }\n    return (s.albedo * l.color) * _3958;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2100_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3059 = int(_2100_fa_shadow_cfg.x + 0.5f);\n    float _3069 = dot(world - _2100_fa_shadow_eye.xyz, _2100_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3074 = _3059 > 0;\n    bool _3083;\n    if (_3074)\n    {\n        int param = _3059 - 1;\n        _3083 = _3069 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3083 = _3074;\n    }\n    if (_3083)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3089 = _3059 > 1;\n        bool _3096;\n        if (_3089)\n        {\n            _3096 = _3069 > _2100_fa_shadow_split.x;\n        }\n        else\n        {\n            _3096 = _3089;\n        }\n        if (_3096)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3102 = _3059 > 2;\n        bool _3109;\n        if (_3102)\n        {\n            _3109 = _3069 > _2100_fa_shadow_split.y;\n        }\n        else\n        {\n            _3109 = _3102;\n        }\n        if (_3109)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3115 = _3059 > 3;\n        bool _3122;\n        if (_3115)\n        {\n            _3122 = _3069 > _2100_fa_shadow_split.z;\n        }\n        else\n        {\n            _3122 = _3115;\n        }\n        if (_3122)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _5462 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5462 = -_5462;\n    }\n    float3 _5035 = normalize(_366_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _5475 = { fa_world_pos, _5462, fa_world_tangent, fa_uv, fa_vertex_color, _5035, gl_FrontFacing };\n    SurfaceInput param_1 = _5475;\n    Surface _5043 = fa_standard_surface(param_1);\n    float3 _5493 = _5043.albedo;\n    float _5494 = _5043.alpha;\n    float3 _5495 = _5043.normal;\n    float _5496 = _5043.metallic;\n    float _5497 = _5043.roughness;\n    float _5498 = _5043.occlusion;\n    float3 _5499 = _5043.emission;\n    float _5500 = _5043.clearcoat;\n    float _5501 = _5043.clearcoat_roughness;\n    float3 _5502 = _5043.sheen_color;\n    float _5503 = _5043.sheen_roughness;\n    float _5504 = _5043.anisotropy;\n    float _5505 = _5043.anisotropy_rotation;\n    float _5506 = _5043.specular;\n    float _5507 = _5043.ior;\n    float3 _5508 = _5043.specular_color;\n    float _5509 = _5043.transmission;\n    float _5510 = _5043.thickness;\n    float3 _5511 = _5043.attenuation_color;\n    float _5512 = _5043.attenuation_distance;\n    SurfaceInput _5483 = { fa_world_pos, _5462, fa_world_tangent, fa_uv, fa_vertex_color, _5035, gl_FrontFacing };\n    SurfaceInput param_2 = _5483;\n    Surface param_3 = _5043;\n    surface(param_2, param_3);\n    _5493 = param_3.albedo;\n    _5494 = param_3.alpha;\n    _5495 = param_3.normal;\n    _5496 = param_3.metallic;\n    _5497 = param_3.roughness;\n    _5498 = param_3.occlusion;\n    _5499 = param_3.emission;\n    _5500 = param_3.clearcoat;\n    _5501 = param_3.clearcoat_roughness;\n    _5502 = param_3.sheen_color;\n    _5503 = param_3.sheen_roughness;\n    _5504 = param_3.anisotropy;\n    _5505 = param_3.anisotropy_rotation;\n    _5506 = param_3.specular;\n    _5507 = param_3.ior;\n    _5508 = param_3.specular_color;\n    _5509 = param_3.transmission;\n    _5510 = param_3.thickness;\n    _5511 = param_3.attenuation_color;\n    _5512 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _5462;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5493 = param_6;\n    _5495 = param_7;\n    fa_lod_dither();\n    float3 result;\n    if (_366_fa_emissive.w > 0.5f)\n    {\n        result = _5493;\n    }\n    else\n    {\n        float3 _5083 = _5495;\n        float3 _5084 = normalize(_5083);\n        _5495 = _5084;\n        float3 param_8 = _5084;\n        float3 lit = (fa_indirect_diffuse(param_8) * _5493) * _5498;\n        int _5103 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5103; ln++)\n        {\n            int param_9 = ln;\n            int _5116 = fa_cl_light(param_9);\n            int param_10 = _5116;\n            if (fa_baked_keep(param_10) <= 0.0f)\n            {\n                continue;\n            }\n            int param_11 = _5116;\n            float3 param_12 = fa_world_pos;\n            float3 param_13 = _5462;\n            LightSample _5132 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput _5491 = { fa_world_pos, _5462, fa_world_tangent, fa_uv, fa_vertex_color, _5035, gl_FrontFacing };\n            SurfaceInput param_14 = _5491;\n            Surface _5594 = { _5493, _5494, _5495, _5496, _5497, _5498, _5499, _5500, _5501, _5502, _5503, _5504, _5505, _5506, _5507, _5508, _5509, _5510, _5511, _5512 };\n            Surface param_15 = _5594;\n            LightSample param_16 = _5132;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    float3 _5147 = result;\n    float3 _5148 = _5147 + _5499;\n    result = _5148;\n    float3 param_17 = _5148;\n    float3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _5157 = _366_fa_fog.w > 0.0f;\n    bool _5164;\n    if (!_5157)\n    {\n        _5164 = _366_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _5164 = _5157;\n    }\n    if (_5164)\n    {\n        float3 _5173 = fa_world_pos - _366_fa_camera_pos.xyz;\n        float _5179 = dot(_5173, _366_fa_fog_c.xyz);\n        bool _5183 = _366_fa_fog_c.w > 0.5f;\n        float _5184;\n        if (_5183)\n        {\n            _5184 = _5179;\n        }\n        else\n        {\n            _5184 = length(_5173);\n        }\n        float _5196 = _5184 - _366_fa_fog_b.x;\n        if (_5196 > 0.0f)\n        {\n            float _5205 = _366_fa_fog.w * _5196;\n            float tau = _5205 * _5205;\n            if (_366_fa_fog_b.y > 0.0f)\n            {\n                float _5221;\n                if (_5183)\n                {\n                    _5221 = fa_world_pos.y - (_366_fa_fog_c.y * _5179);\n                }\n                else\n                {\n                    _5221 = _366_fa_camera_pos.y;\n                }\n                float _5242 = lerp(_5221, fa_world_pos.y, clamp(_366_fa_fog_b.x / _5184, 0.0f, 1.0f));\n                float _5246 = fa_world_pos.y - _5242;\n                float _5251 = _5242 - _366_fa_fog_b.z;\n                float _5256 = fa_world_pos.y - _366_fa_fog_b.z;\n                bool _5259 = _5251 <= 0.0f;\n                bool _5260 = !_5259;\n                bool _5266;\n                if (_5260)\n                {\n                    _5266 = _366_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5266 = _5259;\n                }\n                float _5267;\n                if (_5266)\n                {\n                    _5267 = _366_fa_fog_b.y;\n                }\n                else\n                {\n                    _5267 = _366_fa_fog_b.y * exp(-min(_366_fa_fog_b.w * _5251, 80.0f));\n                }\n                bool _5294;\n                if (_5260)\n                {\n                    _5294 = _366_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5294 = _5259;\n                }\n                float _5295;\n                if (_5294)\n                {\n                    _5295 = _366_fa_fog_b.y * _5251;\n                }\n                else\n                {\n                    _5295 = (_366_fa_fog_b.y * (1.0f - exp(-min(_366_fa_fog_b.w * _5251, 80.0f)))) / _366_fa_fog_b.w;\n                }\n                bool _5320 = _5256 <= 0.0f;\n                bool _5327;\n                if (!_5320)\n                {\n                    _5327 = _366_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5327 = _5320;\n                }\n                float _5328;\n                if (_5327)\n                {\n                    _5328 = _366_fa_fog_b.y * _5256;\n                }\n                else\n                {\n                    _5328 = (_366_fa_fog_b.y * (1.0f - exp(-min(_366_fa_fog_b.w * _5256, 80.0f)))) / _366_fa_fog_b.w;\n                }\n                float _5355;\n                if (abs(_5246) < 0.001000000047497451305389404296875f)\n                {\n                    _5355 = _5267;\n                }\n                else\n                {\n                    _5355 = (_5328 - _5295) / _5246;\n                }\n                tau += (_5196 * max(_5355, 0.0f));\n            }\n            result = lerp(result, _366_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _5494);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_366",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2100",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_3964",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _384 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _384;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _391 = _273.world_pos;\n    fa_world_pos = _391;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_391, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _366_fa_camera_pos : packoffset(c0);\n    float4 _366_fa_ambient : packoffset(c1);\n    float4 _366_fa_base_color : packoffset(c2);\n    float4 _366_fa_emissive : packoffset(c3);\n    float4 _366_fa_model_emissive : packoffset(c4);\n    float4 _366_fa_pbr : packoffset(c5);\n    float4 _366_fa_maps : packoffset(c6);\n    float4 _366_fa_fog : packoffset(c7);\n    float4 _366_fa_fog_b : packoffset(c8);\n    float4 _366_fa_fog_c : packoffset(c9);\n    float4 _366_fa_counts : packoffset(c10);\n    float4 _366_fa_env_sky : packoffset(c11);\n    float4 _366_fa_env_horizon : packoffset(c12);\n    float4 _366_fa_time : packoffset(c13);\n    float4 _366_fa_cl_vpx : packoffset(c14);\n    float4 _366_fa_cl_vpy : packoffset(c15);\n    float4 _366_fa_cl_vpw : packoffset(c16);\n    float4 _366_fa_cl_fwd : packoffset(c17);\n    float4 _366_fa_cl_grid : packoffset(c18);\n    float4 _366_fa_cl_info : packoffset(c19);\n    float4 _366_fa_layers_a : packoffset(c20);\n    float4 _366_fa_layers_b : packoffset(c21);\n    float4 _366_fa_layers_c : packoffset(c22);\n    float4 _366_fa_layers_d : packoffset(c23);\n    float4 _366_fa_ct_a : packoffset(c24);\n    float4 _366_fa_ct_b : packoffset(c25);\n    float4 _366_fa_ct_vpx : packoffset(c26);\n    float4 _366_fa_ct_vpy : packoffset(c27);\n    float4 _366_fa_ct_vpw : packoffset(c28);\n    float4 _366_fa_ct_fwd : packoffset(c29);\n    float4 _366_fa_tr_a : packoffset(c30);\n    float4 _366_fa_tr_b : packoffset(c31);\n    float4 _366_fa_probe_sh[9] : packoffset(c32);\n    float4 _366_fa_atlas : packoffset(c41);\n    float4 _366_fa_rpa_tile : packoffset(c42);\n    float4 _366_fa_rpa_pos : packoffset(c43);\n    float4 _366_fa_rpa_bx : packoffset(c44);\n    float4 _366_fa_rpa_by : packoffset(c45);\n    float4 _366_fa_rpa_bz : packoffset(c46);\n    float4 _366_fa_rpb_tile : packoffset(c47);\n    float4 _366_fa_rpb_pos : packoffset(c48);\n    float4 _366_fa_rpb_bx : packoffset(c49);\n    float4 _366_fa_rpb_by : packoffset(c50);\n    float4 _366_fa_rpb_bz : packoffset(c51);\n    float4 _366_fa_gi : packoffset(c52);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2100_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2100_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2100_fa_shadow_info[4] : packoffset(c20);\n    float4 _2100_fa_shadow_split : packoffset(c24);\n    float4 _2100_fa_shadow_cfg : packoffset(c25);\n    float4 _2100_fa_shadow_bias : packoffset(c26);\n    float4 _2100_fa_shadow_eye : packoffset(c27);\n    float4 _2100_fa_shadow_fwd : packoffset(c28);\n    float4 _2100_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _3964_dark : packoffset(c0);\n    float _3964_fa_pad0 : packoffset(c0.y);\n    float _3964_fa_pad1 : packoffset(c0.z);\n    float _3964_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_probe_atlas : register(t6);\nTexture2D<float4> fa_screen_tex : register(t11);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1382 = _366_fa_cl_info.x < 0.0f;\n    bool _1389;\n    if (!_1382)\n    {\n        _1389 = _366_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1389 = _1382;\n    }\n    bool _1397;\n    if (!_1389)\n    {\n        _1397 = _366_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1397 = _1389;\n    }\n    bool _1404;\n    if (!_1397)\n    {\n        _1404 = _366_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1404 = _1397;\n    }\n    bool _1411;\n    if (!_1404)\n    {\n        _1411 = _366_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1411 = _1404;\n    }\n    if (_1411)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1421 = float4(world_pos, 1.0f);\n    float _1427 = dot(_366_fa_cl_vpw, _1421);\n    if (!(_1427 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1449 = float2(dot(_366_fa_cl_vpx, _1421), dot(_366_fa_cl_vpy, _1421)) / _1427.xx;\n    int _1453 = int(_366_fa_cl_grid.x);\n    int _1457 = int(_366_fa_cl_grid.y);\n    int param = (int(_366_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_366_fa_cl_fwd.xyz, world_pos) + _366_fa_cl_fwd.w, _366_fa_cl_grid.w) / _366_fa_cl_grid.w) * _366_fa_cl_grid.z)), 0, int(_366_fa_cl_info.y) - 1) * _1457) + clamp(int(floor(((_1449.y * 0.5f) + 0.5f) * _366_fa_cl_grid.y)), 0, _1457 - 1)) * _1453)) + clamp(int(floor(((_1449.x * 0.5f) + 0.5f) * _366_fa_cl_grid.x)), 0, _1453 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1533 = fa_cluster_texel(param);\n    return int2(int(_1533.x), int(_1533.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_366_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3782 = fa_cluster_lookup(param);\n    fa_cl_slot = _3782.x;\n    fa_cl_local = _3782.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _4013 = fa_linear_to_srgb(param);\n        c = _4013;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _4021 = fa_srgb_to_linear(param_1);\n            c = _4021;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _298;\n    if (i.front_facing)\n    {\n        _298 = i.world_normal;\n    }\n    else\n    {\n        _298 = -i.world_normal;\n    }\n    float3 _322 = normalize(i.world_tangent.xyz - (_298 * dot(_298, i.world_tangent.xyz)));\n    float3 _349 = normalize(((_322 * m.x) + ((cross(_298, _322) * i.world_tangent.w) * m.y)) + (_298 * m.z));\n    float3 _352;\n    if (i.front_facing)\n    {\n        _352 = _349;\n    }\n    else\n    {\n        _352 = -_349;\n    }\n    return _352;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _366_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _4052 = fa_tex_fix(param_2, param_3);\n    float4 _5824 = base_t;\n    _5824.x = _4052.x;\n    _5824.y = _4052.y;\n    _5824.z = _4052.z;\n    base_t = _5824;\n    float4 _4066 = (_5824 * _366_fa_base_color) * i.vertex_color;\n    float3 _5661 = i.world_normal;\n    if (_366_fa_maps.z > 0.5f)\n    {\n        float param_4 = _366_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4098 = fa_tex_fix(param_6, param_7);\n        float3 _4101 = (_4098 * 2.0f) - 1.0f.xxx;\n        float2 _4106 = _4101.xy * _366_fa_maps.x;\n        float3 _5832 = _4101;\n        _5832.x = _4106.x;\n        _5832.y = _4106.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5832;\n        _5661 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _366_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4134 = fa_tex_fix(param_12, param_13);\n    float4 _5835 = mrt;\n    _5835.x = _4134.x;\n    _5835.y = _4134.y;\n    _5835.z = _4134.z;\n    mrt = _5835;\n    float4 _4162 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _366_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _4162.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4173 = fa_tex_fix(param_16, param_17);\n    float param_18 = _366_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4203 = fa_tex_fix(param_20, param_21);\n    float _5666 = _366_fa_layers_a.x;\n    float _5667 = _366_fa_layers_a.y;\n    float _5670 = _366_fa_layers_a.z;\n    float _5669 = _366_fa_layers_b.w;\n    float _5672 = _366_fa_layers_c.x;\n    if (_366_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_366_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _5666 *= _4173.y;\n            _5667 *= _4173.z;\n            _5669 *= _4162.w;\n        }\n        if (_366_fa_layers_c.z > 1.5f)\n        {\n            _5670 *= mrt.x;\n            _5672 *= mrt.w;\n        }\n    }\n    Surface _5699 = { _4066.xyz, _4066.w, _5661, clamp(_366_fa_pbr.x * _4134.z, 0.0f, 1.0f), clamp(_366_fa_pbr.y * _4134.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_366_fa_maps.y * (_4173.x - 1.0f)), _366_fa_emissive.xyz + (_366_fa_model_emissive.xyz * _4203), _5666, _5667, _366_fa_layers_b.xyz, _5669, _5670, _366_fa_layers_a.w, _5672, _366_fa_layers_c.y, _366_fa_layers_d.xyz, _366_fa_tr_a.x, _366_fa_tr_a.y, _366_fa_tr_b.xyz, _366_fa_tr_a.z };\n    return _5699;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1613 = rect.zw - rect.xy;\n    float2 _1617 = _1613 * atlas;\n    float2 _1621 = ddx * _1617;\n    float2 _1625 = ddy * _1617;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1613), clamp(0.5f * log2(max(max(dot(_1621, _1621), dot(_1625, _1625)), 9.9999999392252902907785028219223e-09f)), 0.0f, 3.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1658 = _366_fa_counts.y < 0.5f;\n    bool _1665;\n    if (!_1658)\n    {\n        _1665 = _366_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1665 = _1658;\n    }\n    if (_1665)\n    {\n        return;\n    }\n    float3 _1671 = ddx(world_pos);\n    float3 _1674 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1678 = fa_cluster_texel(param);\n    int _1682 = int(_1678.w);\n    if (_1682 < 1)\n    {\n        return;\n    }\n    int _1692 = int(_366_fa_counts.y + 0.5f);\n    int param_1 = _1692;\n    float4 _1696 = fa_light_texel(param_1);\n    float2 _1699 = _1696.yz;\n    int _1703 = int(_1696.w);\n    int param_2 = _1692 + 1;\n    float4 _1708 = fa_light_texel(param_2);\n    float _1709 = _1708.x;\n    int _1715 = int(_366_fa_counts.w + 0.5f) - 1;\n    int _1719 = int(_1678.z);\n    float3 _1984;\n    for (int k = 0; k < _1682; k++)\n    {\n        int _1732 = _1719 + k;\n        int param_3 = _1703 + (_1732 >> 2);\n        int _1749 = (_1692 + 2) + (int(fa_light_texel(param_3)[_1732 & 3]) * 7);\n        int param_4 = _1749 + 6;\n        float4 _1754 = fa_light_texel(param_4);\n        if (((int(_1754.w + 0.5f) >> _1715) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1749;\n        float4 _1769 = fa_light_texel(param_5);\n        int param_6 = _1749 + 1;\n        float4 _1774 = fa_light_texel(param_6);\n        int param_7 = _1749 + 2;\n        float4 _1779 = fa_light_texel(param_7);\n        float3 _1782 = _1769.xyz;\n        float _1787 = dot(_1782, world_pos) + _1769.w;\n        float3 _1789 = _1774.xyz;\n        float _1794 = dot(_1789, world_pos) + _1774.w;\n        float3 _1796 = _1779.xyz;\n        float _1801 = dot(_1796, world_pos) + _1779.w;\n        bool _1806 = abs(_1787) > 0.5f;\n        bool _1814;\n        if (!_1806)\n        {\n            _1814 = abs(_1794) > 0.5f;\n        }\n        else\n        {\n            _1814 = _1806;\n        }\n        bool _1822;\n        if (!_1814)\n        {\n            _1822 = abs(_1801) > 0.5f;\n        }\n        else\n        {\n            _1822 = _1814;\n        }\n        if (_1822)\n        {\n            continue;\n        }\n        float _1837 = clamp(dot(geo_normal, normalize(_1796)) * _1754.z, 0.0f, 1.0f);\n        if (_1837 <= 0.0f)\n        {\n            continue;\n        }\n        float _1857 = (clamp((0.5f - abs(_1801)) * 10.0f, 0.0f, 1.0f) * _1837) * _1754.x;\n        float2 _1865 = float2(_1787 + 0.5f, 0.5f - _1794);\n        float2 _1875 = float2(dot(_1782, _1671), dot(_1789, _1671));\n        float2 _1885 = float2(dot(_1782, _1674), dot(_1789, _1674));\n        int param_8 = _1749 + 5;\n        float4 _1890 = fa_light_texel(param_8);\n        int param_9 = _1749 + 3;\n        float4 _1895 = fa_light_texel(param_9);\n        int param_10 = _1749 + 4;\n        float4 _1900 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1890.xyz;\n        bool _1910 = _1895.z > _1895.x;\n        if (_1910)\n        {\n            float4 param_11 = _1895;\n            float2 param_12 = _1865;\n            float2 param_13 = _1699;\n            float2 param_14 = _1875;\n            float2 param_15 = _1885;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1709 > 0.5f) && (_1709 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1936 = fa_dc_to_linear(param_16);\n                float4 _5749 = tx;\n                _5749.x = _1936.x;\n                _5749.y = _1936.y;\n                _5749.z = _1936.z;\n                tx = _5749;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1857 * tex_a) * _1890.w, 0.0f, 1.0f).xxx);\n        if (_1900.z > _1900.x)\n        {\n            float4 param_17 = _1900;\n            float2 param_18 = _1865;\n            float2 param_19 = _1699;\n            float2 param_20 = _1875;\n            float2 param_21 = _1885;\n            float4 _1980 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1709 > 1.5f)\n            {\n                float3 param_22 = _1980.xyz;\n                float3 _1990 = fa_dc_to_srgb(param_22);\n                _1984 = _1990;\n            }\n            else\n            {\n                _1984 = _1980.xyz;\n            }\n            float3 _1999 = (_1984 * 2.0f) - 1.0f.xxx;\n            float2 _2004 = _1999.xy * _1754.y;\n            float3 _2026 = (normalize(_1782) * _2004.x) + (normalize(_1789) * _2004.y);\n            float3 _2029 = normalize(normal);\n            normal = normalize(lerp(_2029, normalize((_2029 * max(_1999.z, 0.0500000007450580596923828125f)) + (_2026 - (_2029 * dot(_2029, _2026)))), clamp(_1857 * (_1910 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nvoid fa_lod_dither()\n{\n    if (_366_fa_gi.w != 0.0f)\n    {\n        float _388 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n        bool _391;\n        if (_366_fa_gi.w > 0.0f)\n        {\n            _391 = _388 >= _366_fa_gi.w;\n        }\n        else\n        {\n            _391 = _388 < (-_366_fa_gi.w);\n        }\n        if (_391)\n        {\n            discard;\n        }\n    }\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3295_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3295_dummy_parameter)));\n}\n\nfloat3 fa_probe_sh_coef(float2 origin, float res, int k)\n{\n    float3 v = fa_probe_atlas.SampleLevel(fa_env_smp, (origin + float2(float(k) + 0.5f, res + 2.5f)) / fa_atlas_size(), 0.0f).xyz;\n    if (_366_fa_atlas.y > 0.5f)\n    {\n        v = ((v * 255.0f) - 128.0f.xxx) * 0.03149606287479400634765625f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3236 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3236;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    float _3346 = (1.0f - _366_fa_rpa_tile.w) - _366_fa_rpb_tile.w;\n    float3 amb = 0.0f.xxx;\n    bool _3352 = _366_fa_env_sky.w > 0.5f;\n    float3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = 0.0f.xxx;\n    }\n    if (_3346 > 0.0005000000237487256526947021484375f)\n    {\n        if (_3352)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _366_fa_atlas.zw;\n                float param_1 = 128.0f;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3346;\n            }\n        }\n        else\n        {\n            amb = _366_fa_ambient.xyz * _3346;\n        }\n    }\n    bool _3404 = _366_fa_rpa_tile.w > 0.0f;\n    if (_3404)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _366_fa_rpa_tile.xy;\n            float param_4 = _366_fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * _366_fa_rpa_tile.w);\n        }\n    }\n    bool _3435 = _366_fa_rpb_tile.w > 0.0f;\n    if (_3435)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _366_fa_rpb_tile.xy;\n            float param_7 = _366_fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * _366_fa_rpb_tile.w);\n        }\n    }\n    if ((_3352 || _3404) || _3435)\n    {\n        float3 param_9[9] = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nfloat4 fa_gi_fetch(float2 texel)\n{\n    return fa_probe_atlas.SampleLevel(fa_env_smp, texel / fa_atlas_size(), 0.0f);\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3256 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3259 = _3256.x;\n    float _3261 = _3256.z;\n    float2 e = float2(_3259, _3261);\n    if (_3256.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3261)) * ((_3259 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3259)) * ((_3261 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat3 fa_gi_grid(int rec, float3 n, float3 v, out float cover)\n{\n    cover = 0.0f;\n    int param = rec;\n    float4 _4317 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    float4 _4322 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    float4 _4327 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    float4 _4332 = fa_light_texel(param_3);\n    bool _4335 = _4332.z < 0.5f;\n    bool _4343;\n    if (!_4335)\n    {\n        _4343 = fa_atlas_size().y < 1155.0f;\n    }\n    else\n    {\n        _4343 = _4335;\n    }\n    if (_4343)\n    {\n        return 0.0f.xxx;\n    }\n    float _4350 = max(_4317.w, 9.9999997473787516355514526367188e-05f);\n    float3 _4353 = _4322.xyz;\n    float3 _4357 = _4317.xyz;\n    float3 _4361 = (fa_world_pos - _4357) / _4350.xxx;\n    float3 _4370 = min(_4361 + 0.5f.xxx, (_4353 - 0.5f.xxx) - _4361);\n    float _4379 = min(_4370.x, min(_4370.y, _4370.z));\n    if (!(_4379 > 0.0f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _4394 = _4353 - 1.0f.xxx;\n    float3 _4395 = clamp(_4361, 0.0f.xxx, _4394);\n    float3 _4403 = min(floor(_4395), max(_4353 - 2.0f.xxx, 0.0f.xxx));\n    float3 _4407 = _4395 - _4403;\n    float3 _4419 = fa_world_pos + (((n * 0.800000011920928955078125f) + (v * 0.20000000298023223876953125f)) * (0.20000000298023223876953125f * _4350));\n    int _4424 = int(_4327.y + 0.5f);\n    float _4429 = 0.3257350027561187744140625f * n.y;\n    float _4433 = 0.3257350027561187744140625f * n.z;\n    float _4437 = 0.3257350027561187744140625f * n.x;\n    float _4444 = (0.2731371223926544189453125f * n.x) * n.y;\n    float _4451 = (0.2731371223926544189453125f * n.y) * n.z;\n    float _4460 = 0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f);\n    float _4467 = (0.2731371223926544189453125f * n.x) * n.z;\n    float _4480 = 0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y));\n    float3 acc = 0.0f.xxx;\n    float wsum = 0.0f;\n    int _4487 = 8 + int(_4332.w);\n    float _4514;\n    float _4527;\n    float _4541;\n    for (int k = 0; k < _4487; k++)\n    {\n        float _4500 = float(k & 1);\n        float _4504 = float((k >> 1) & 1);\n        float _4508 = float((k >> 2) & 1);\n        if (_4500 > 0.5f)\n        {\n            _4514 = _4407.x;\n        }\n        else\n        {\n            _4514 = 1.0f - _4407.x;\n        }\n        if (_4504 > 0.5f)\n        {\n            _4527 = _4407.y;\n        }\n        else\n        {\n            _4527 = 1.0f - _4407.y;\n        }\n        if (_4508 > 0.5f)\n        {\n            _4541 = _4407.z;\n        }\n        else\n        {\n            _4541 = 1.0f - _4407.z;\n        }\n        float _4551 = (_4514 * _4527) * _4541;\n        if (!(_4551 > 0.0f))\n        {\n            continue;\n        }\n        float3 _4564 = min(_4403 + float3(_4500, _4504, _4508), _4394);\n        int _4584 = int(((_4327.x + _4564.x) + (_4322.x * (_4564.y + (_4322.y * _4564.z)))) + 0.5f);\n        float2 _4599 = float2(float(_4584 % _4424) * 10.0f, 1024.0f + (float(_4584 / _4424) * 11.0f));\n        float2 param_4 = _4599 + float2(9.5f, 10.5f);\n        float4 _4607 = fa_gi_fetch(param_4);\n        bool _4610 = _4607.y < 0.5f;\n        bool _4619;\n        if (!_4610)\n        {\n            _4619 = _4607.x > _4332.y;\n        }\n        else\n        {\n            _4619 = _4610;\n        }\n        if (_4619)\n        {\n            continue;\n        }\n        float3 _4631 = _4419 - (_4357 + (_4564 * _4350));\n        float _4634 = length(_4631);\n        float3 _4640 = _4631 / max(_4634, 9.9999997473787516355514526367188e-05f).xxx;\n        float _4650 = max(9.9999997473787516355514526367188e-05f, (dot(-_4640, n) + 1.0f) * 0.5f);\n        float w = _4551 * (_4650 * _4650);\n        float3 param_5 = _4640;\n        float2 param_6 = (_4599 + 1.0f.xx) + (((fa_oct_encode(param_5) * 0.5f) + 0.5f.xx) * 8.0f);\n        float4 _4670 = fa_gi_fetch(param_6);\n        float _4677 = _4634 / max(_4327.z, 9.9999997473787516355514526367188e-05f);\n        float _4680 = _4670.x;\n        if (_4677 > _4680)\n        {\n            float _4693 = max(_4670.y - (_4680 * _4680), 0.0f);\n            float _4698 = _4677 - _4680;\n            float _4707 = _4693 / max(_4693 + (_4698 * _4698), 9.9999999600419720025001879548654e-13f);\n            w *= ((_4707 * _4707) * _4707);\n        }\n        if (!(w > 0.0f))\n        {\n            continue;\n        }\n        float2 param_7 = _4599 + float2(0.5f, 10.5f);\n        float2 param_8 = _4599 + float2(1.5f, 10.5f);\n        float2 param_9 = _4599 + float2(2.5f, 10.5f);\n        float2 param_10 = _4599 + float2(3.5f, 10.5f);\n        float2 param_11 = _4599 + float2(4.5f, 10.5f);\n        float2 param_12 = _4599 + float2(5.5f, 10.5f);\n        float2 param_13 = _4599 + float2(6.5f, 10.5f);\n        float2 param_14 = _4599 + float2(7.5f, 10.5f);\n        float2 param_15 = _4599 + float2(8.5f, 10.5f);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375f) + (fa_gi_fetch(param_8).xyz * _4429)) + (fa_gi_fetch(param_9).xyz * _4433)) + (fa_gi_fetch(param_10).xyz * _4437)) + (fa_gi_fetch(param_11).xyz * _4444)) + (fa_gi_fetch(param_12).xyz * _4451)) + (fa_gi_fetch(param_13).xyz * _4460)) + (fa_gi_fetch(param_14).xyz * _4467)) + (fa_gi_fetch(param_15).xyz * _4480)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06f))\n    {\n        return 0.0f.xxx;\n    }\n    cover = smoothstep(0.0f, 1.0f, clamp(_4379 * 2.0f, 0.0f, 1.0f)) * smoothstep(0.0f, 0.0199999995529651641845703125f, wsum);\n    float _4834;\n    if (_366_fa_gi.z > 0.5f)\n    {\n        _4834 = _4332.x;\n    }\n    else\n    {\n        _4834 = 1.0f;\n    }\n    return max(acc / wsum.xxx, 0.0f.xxx) * (_4327.w * _4834);\n}\n\nfloat3 fa_gi_light(float3 n, inout float left)\n{\n    left = 1.0f;\n    float3 acc = 0.0f.xxx;\n    float3 _4858 = normalize(_366_fa_camera_pos.xyz - fa_world_pos);\n    int _4863 = int(_366_fa_gi.x + 0.5f);\n    int _4868 = int(_366_fa_gi.y + 0.5f);\n    float param_3;\n    for (int k = 0; (k < _4868) && (k < 8); k++)\n    {\n        int param = _4863 + (4 * k);\n        float3 param_1 = n;\n        float3 param_2 = _4858;\n        float3 _4893 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _4898 = param_3 * left;\n        acc += (_4893 * _4898);\n        left -= _4898;\n        if (left < 0.001000000047497451305389404296875f)\n        {\n            left = 0.0f;\n            break;\n        }\n    }\n    return acc;\n}\n\nfloat3 fa_realtime_or_ambient(float3 n)\n{\n    float3 gi = 0.0f.xxx;\n    float left = 1.0f;\n    if (_366_fa_gi.y > 0.5f)\n    {\n        float3 param = n;\n        float param_1;\n        float3 _4927 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _4927;\n    }\n    if (left <= 0.0f)\n    {\n        return gi;\n    }\n    float3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_366_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _366_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_366_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_366_fa_cl_info.x) + int(_366_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_366_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _3752;\n    if (fa_lm.z > 0.5f)\n    {\n        _3752 = 0.0f;\n    }\n    else\n    {\n        _3752 = 1.0f - clamp(_366_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _3763 = _3752 < 1.0f;\n    bool _3769;\n    if (_3763)\n    {\n        int param = li;\n        _3769 = fa_light_baked(param);\n    }\n    else\n    {\n        _3769 = _3763;\n    }\n    return _3769 ? _3752 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _632 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _645 = (c - (ru * hx)) - p;\n        float3 _651 = ru * (2.0f * hx);\n        float _657 = max(dot(_651, _651), 9.9999999392252902907785028219223e-09f);\n        float _661 = dot(_645, _651);\n        float t = clamp((-_661) / _657, 0.0f, 1.0f);\n        if (_632)\n        {\n            float _676 = dot(r, _651);\n            float _682 = _657 - (_676 * _676);\n            if (abs(_682) > (9.9999997473787516355514526367188e-06f * _657))\n            {\n                t = clamp(((dot(r, _645) * _676) - _661) / _682, 0.0f, 1.0f);\n            }\n        }\n        return (p + _645) + (_651 * t);\n    }\n    float3 q = p;\n    float _714 = dot(r, axis);\n    bool _722;\n    if (_632)\n    {\n        _722 = abs(_714) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _722 = _632;\n    }\n    if (_722)\n    {\n        float _732 = dot(c - p, axis) / _714;\n        if (_732 > 0.0f)\n        {\n            q = p + (r * _732);\n        }\n    }\n    float3 _745 = q - c;\n    float2 xy = float2(dot(_745, ru), dot(_745, uu));\n    if (shape > 0.5f)\n    {\n        float _760 = length(xy);\n        if (_760 > hx)\n        {\n            xy *= (hx / _760);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _513_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _513_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _552 = dot(d, right);\n    float _556 = dot(d, up);\n    float _567;\n    if (((_552 * _552) + (_556 * _556)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _567 = atan2(_556, _552) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _567 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_567 - floor(_567)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _408 = abs(d);\n    float _410 = _408.x;\n    float _412 = _408.y;\n    bool _413 = _410 >= _412;\n    bool _421;\n    if (_413)\n    {\n        _421 = _410 >= _408.z;\n    }\n    else\n    {\n        _421 = _413;\n    }\n    int _422;\n    if (_421)\n    {\n        _422 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _436;\n        if (_412 >= _408.z)\n        {\n            _436 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _436 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _422 = _436;\n    }\n    return _422;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _798 = fa_light_base(param);\n    bool _802 = _366_fa_ambient.w > 4.5f;\n    int param_1 = _798;\n    float4 _806 = fa_light_texel(param_1);\n    int param_2 = _798 + 1;\n    float4 _811 = fa_light_texel(param_2);\n    float _814 = _811.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _826 = _802 && (_814 > 2.5f);\n    fa_light_is_area = _826;\n    bool _828 = _814 < 0.5f;\n    float3 l;\n    if (_828)\n    {\n        l = normalize(_806.xyz);\n        if (_802)\n        {\n            int param_3 = _798 + 6;\n            float4 _842 = fa_light_texel(param_3);\n            if (_842.z > 0.5f)\n            {\n                int param_4 = _798 + 4;\n                float4 _852 = fa_light_texel(param_4);\n                int param_5 = _798 + 5;\n                float4 _857 = fa_light_texel(param_5);\n                float2 param_6 = _842.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _852.xyz) * _852.w, (-dot(world_pos, _857.xyz)) * _857.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _887 = _806.xyz;\n        float3 _889 = _887 - world_pos;\n        float3 to_light = _889;\n        float _892 = length(_889);\n        float reach = _892;\n        bool front = true;\n        if (_826)\n        {\n            int param_8 = _798 + 7;\n            reach = max(_892 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _798 + 4;\n            float4 _916 = fa_light_texel(param_9);\n            int param_10 = _798 + 5;\n            float4 _921 = fa_light_texel(param_10);\n            int param_11 = _798 + 6;\n            float4 _926 = fa_light_texel(param_11);\n            float _927 = _926.w;\n            int param_12 = _798 + 2;\n            float3 _934 = normalize(fa_light_texel(param_12).xyz);\n            bool _936 = _927 > 1.5f;\n            bool _944;\n            if (!_936)\n            {\n                _944 = dot(_934, to_light) < 0.0f;\n            }\n            else\n            {\n                _944 = _936;\n            }\n            front = _944;\n            float3 r = 0.0f.xxx;\n            float3 _953 = _366_fa_camera_pos.xyz - world_pos;\n            bool _957 = dot(n, n) > 0.5f;\n            bool _965;\n            if (_957)\n            {\n                _965 = dot(_953, _953) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _965 = _957;\n            }\n            if (_965)\n            {\n                r = reflect(-normalize(_953), normalize(n));\n            }\n            float3 param_13 = _887;\n            float3 param_14 = _934;\n            float3 param_15 = _916.xyz;\n            float3 param_16 = _921.xyz;\n            float param_17 = _916.w;\n            float param_18 = _921.w;\n            float param_19 = _927;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1001 = length(to_light);\n        dist = _1001;\n        l = to_light / max(_1001, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1015 = reach / max(_806.w, 0.001000000047497451305389404296875f);\n        float _1021 = clamp(1.0f - (_1015 * _1015), 0.0f, 1.0f);\n        float _1023;\n        if (front)\n        {\n            _1023 = _1021 * _1021;\n        }\n        else\n        {\n            _1023 = 0.0f;\n        }\n        atten = _1023;\n        bool _1034 = _814 < 2.5f;\n        if ((_814 > 1.5f) && _1034)\n        {\n            int param_22 = _798 + 2;\n            float4 _1042 = fa_light_texel(param_22);\n            float _1052 = _1042.w;\n            int param_23 = _798 + 3;\n            float4 _1057 = fa_light_texel(param_23);\n            float _1058 = _1057.x;\n            float cos_inner = _1058;\n            if (_1058 > 1.5f)\n            {\n                cos_inner = lerp(_1052, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1052, cos_inner, dot(-l, normalize(_1042.xyz)));\n        }\n        if (_802 && (_814 < 1.5f))\n        {\n            int param_24 = _798 + 6;\n            float4 _1082 = fa_light_texel(param_24);\n            if (_1082.z > 0.5f)\n            {\n                float3 _1090 = -to_light;\n                int param_25 = _798 + 4;\n                int param_26 = _798 + 5;\n                float3 _1104 = fa_light_texel(param_25).xyz;\n                float3 _1108 = fa_light_texel(param_26).xyz;\n                float3 _1117 = float3(dot(_1090, _1104), dot(_1090, _1108), dot(_1090, cross(_1104, _1108)));\n                float3 param_27 = _1117;\n                int _1121 = fa_cube_face(param_27);\n                int param_28 = _1121;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1148 = float2(dot(_1117, cross(param_29, param_30)), dot(_1117, param_30)) / max(dot(_1117, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1152 = _1121 / 3;\n                float2 param_31 = _1082.xy + (float2(float(_1121 - (_1152 * 3)), float(_1152)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1148.x), 0.5f - (0.5f * _1148.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _798 + 7;\n            float4 _1182 = fa_light_texel(param_33);\n            if (_1182.z > 0.5f)\n            {\n                int param_34 = _798 + 2;\n                int param_35 = _798 + 4;\n                int param_36 = _798 + 5;\n                float2 param_37 = _1182.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_802 && _1034)\n            {\n                int param_42 = _798 + 6;\n                float4 _1229 = fa_light_texel(param_42);\n                int param_43 = _798 + 7;\n                float4 _1234 = fa_light_texel(param_43);\n                bool _1237 = _1229.z > 0.5f;\n                bool _1244;\n                if (!_1237)\n                {\n                    _1244 = _1234.z > 0.5f;\n                }\n                else\n                {\n                    _1244 = _1237;\n                }\n                if (_1244)\n                {\n                    int param_44 = _798 + 2;\n                    float4 _1251 = fa_light_texel(param_44);\n                    float3 _1255 = normalize(_1251.xyz);\n                    int param_45 = _798 + 4;\n                    float4 _1260 = fa_light_texel(param_45);\n                    int param_46 = _798 + 5;\n                    float4 _1265 = fa_light_texel(param_46);\n                    if (_1237)\n                    {\n                        float3 _1273 = -to_light;\n                        float _1280 = _1251.w;\n                        float _1296 = 0.5f / max(dot(_1273, _1255) * (sqrt(max(1.0f - (_1280 * _1280), 0.0f)) / max(_1280, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1229.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1273, _1260.xyz) * _1296), 0.5f - (dot(_1273, _1265.xyz) * _1296));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1234.z > 0.5f)\n                    {\n                        float2 param_49 = _1234.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1255;\n                        float3 param_52 = _1260.xyz;\n                        float3 param_53 = _1265.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _5615 = _811.xyz * atten;\n    if (_802)\n    {\n        _5615 *= fa_light_tint;\n    }\n    int _1364;\n    if (_828)\n    {\n        _1364 = 0;\n    }\n    else\n    {\n        _1364 = ((_814 > 1.5f) && (_814 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _5626 = { l, _5615, atten, 1.0f, dist, _1364 };\n    return _5626;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2147 = fa_shadow_depth(param, param_1);\n    float _2151;\n    if (conv.x < 0.5f)\n    {\n        _2151 = _2147;\n    }\n    else\n    {\n        _2151 = (conv.y * conv.z) / (conv.z - (_2147 * (conv.z - conv.y)));\n    }\n    return _2151;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel_turn(float2 d)\n{\n    return float2((d.x * (-0.737368881702423095703125f)) - (d.y * 0.675490319728851318359375f), (d.y * (-0.737368881702423095703125f)) + (d.x * 0.675490319728851318359375f));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2197 = fa_shadow_noise() * 6.283185482025146484375f;\n    float2 _2203 = float2(cos(_2197), sin(_2197));\n    float2 dir = _2203;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2212;\n        if (k < 0.0f)\n        {\n            _2212 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2212 = k;\n        }\n        float _2231 = clamp((_2212 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2250 = sqrt((float(i) + 0.5f) * 0.0625f) * _2231;\n            float2 param_3 = uv + (dir * (_2100_fa_shadow_bias.zw * _2250));\n            float4 param_4 = rect;\n            float3 param_5 = conv;\n            float _2264 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2264 < (zr - (_2250 * plane)))\n            {\n                sum += _2264;\n                cnt += 1.0f;\n            }\n            float2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2292 = sum / cnt;\n        float _2302;\n        if (k < 0.0f)\n        {\n            _2302 = (-k) / max(_2292, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2302 = k;\n        }\n        radius = clamp(((max(zr - _2292, 0.0f) * unit) * _2302) / texel_m, 1.5f, 16.0f);\n        dir = _2203;\n    }\n    float lit = 0.0f;\n    int _2328 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2328; i_1++)\n    {\n        float _2347 = sqrt((float(i_1) + 0.5f) / float(_2328)) * radius;\n        float2 param_7 = uv + (dir * (_2100_fa_shadow_bias.zw * _2347));\n        float4 param_8 = rect;\n        float3 param_9 = conv;\n        lit += float((zr - (_2347 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        float2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2328);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2552 = _366_fa_pbr.z < 0.5f;\n    bool _2559;\n    if (!_2552)\n    {\n        _2559 = _2100_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2559 = _2552;\n    }\n    if (_2559)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2100_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2572 = fa_light_texel(param);\n    float _2573 = _2572.x;\n    if (_2573 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2582 = int(_2573 + 0.5f);\n    int param_1 = _2582;\n    float4 _2586 = fa_light_texel(param_1);\n    int param_2 = _2582 + 1;\n    float4 _2591 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2594 = _2586.y;\n    if (_2594 > 0.0f)\n    {\n        float _2611 = 1.0f - smoothstep(0.75f * _2594, _2594, length(world - _2100_fa_shadow_eye.xyz));\n        fade = _2611;\n        if (_2611 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2586.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2635 = (_2582 + 2) + (face * 6);\n    int param_4 = _2635;\n    int param_5 = _2635 + 1;\n    int param_6 = _2635 + 3;\n    float4 _2649 = fa_light_texel(param_6);\n    int param_7 = _2635 + 4;\n    float4 _2654 = fa_light_texel(param_7);\n    int param_8 = _2635 + 5;\n    float4 _2659 = fa_light_texel(param_8);\n    float _2671 = _2659.x * max(dot(_2649, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2676 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2699 = clamp(dot(n, _2649.xyz), -1.0f, 1.0f);\n    float _2718 = min(sqrt(1.0f - (_2699 * _2699)) / max(abs(dot(n, world - lpos)) / max(dot(_2649, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2721 = _2591.y;\n    float _2723;\n    if (_2721 > 0.0f)\n    {\n        _2723 = _2721;\n    }\n    else\n    {\n        _2723 = 1.5f * _2671;\n    }\n    float4 _2743 = float4(world + (n * (_2723 * sqrt(1.0f - (_2676 * _2676)))), 1.0f);\n    float _2747 = dot(_2649, _2743);\n    float _2750 = _2659.y;\n    if (_2747 < _2750)\n    {\n        return 1.0f;\n    }\n    float2 _2765 = float2(dot(fa_light_texel(param_4), _2743), dot(fa_light_texel(param_5), _2743)) / _2747.xx;\n    float _2767 = _2765.x;\n    bool _2770 = _2767 < _2654.x;\n    bool _2779;\n    if (!_2770)\n    {\n        _2779 = _2767 > _2654.z;\n    }\n    else\n    {\n        _2779 = _2770;\n    }\n    bool _2788;\n    if (!_2779)\n    {\n        _2788 = _2765.y < _2654.y;\n    }\n    else\n    {\n        _2788 = _2779;\n    }\n    bool _2797;\n    if (!_2788)\n    {\n        _2797 = _2765.y > _2654.w;\n    }\n    else\n    {\n        _2797 = _2788;\n    }\n    if (_2797)\n    {\n        return 1.0f;\n    }\n    float _2803 = _2591.x;\n    float _2805;\n    if (_2803 > 0.0f)\n    {\n        _2805 = _2803;\n    }\n    else\n    {\n        _2805 = 1.5f * _2671;\n    }\n    float2 param_9 = _2765;\n    float4 param_10 = _2654;\n    float param_11 = _2747 - (_2805 * (1.0f + (0.5f * _2718)));\n    float param_12 = _2671;\n    float param_13 = 1.0f;\n    float param_14 = _2659.z * 0.25f;\n    float param_15 = (_2671 * min(_2718, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2750, _2659.z);\n    int param_17 = int(_2586.z + 0.5f);\n    float param_18 = _2586.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2090;\n    if (i == 0)\n    {\n        _2090 = _2100_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2106;\n        if (i == 1)\n        {\n            _2106 = _2100_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2114;\n            if (i == 2)\n            {\n                _2114 = _2100_fa_shadow_split.z;\n            }\n            else\n            {\n                _2114 = _2100_fa_shadow_split.w;\n            }\n            _2106 = _2114;\n        }\n        _2090 = _2106;\n    }\n    return _2090;\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2393 = max(_2100_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2398 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2404 = sqrt(1.0f - (_2398 * _2398));\n    float _2412 = min(_2404 / max(_2398, 0.20000000298023223876953125f), 4.0f);\n    float _2417;\n    if (_2100_fa_shadow_bias.y > 0.0f)\n    {\n        _2417 = _2100_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2417 = 1.5f * _2100_fa_shadow_info[ci].x;\n    }\n    float4 _2442 = mul(float4(world + (n * (_2417 * _2404)), 1.0f), _2100_fa_shadow_mat[ci]);\n    float _2449 = _2442.x;\n    bool _2452 = _2449 < _2100_fa_shadow_rect[ci].x;\n    bool _2461;\n    if (!_2452)\n    {\n        _2461 = _2449 > _2100_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2461 = _2452;\n    }\n    bool _2470;\n    if (!_2461)\n    {\n        _2470 = _2442.y < _2100_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2470 = _2461;\n    }\n    bool _2479;\n    if (!_2470)\n    {\n        _2479 = _2442.y > _2100_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2479 = _2470;\n    }\n    bool _2486;\n    if (!_2479)\n    {\n        _2486 = _2442.z > 1.0f;\n    }\n    else\n    {\n        _2486 = _2479;\n    }\n    if (_2486)\n    {\n        return -1.0f;\n    }\n    float _2494;\n    if (_2100_fa_shadow_bias.x > 0.0f)\n    {\n        _2494 = _2100_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2494 = 1.5f * _2100_fa_shadow_info[ci].x;\n    }\n    float2 param = _2442.xy;\n    float4 param_1 = _2100_fa_shadow_rect[ci];\n    float param_2 = _2442.z - ((_2494 * (1.0f + (0.5f * _2412))) / _2393);\n    float param_3 = _2100_fa_shadow_info[ci].x;\n    float param_4 = _2393;\n    float param_5 = _2393 * 0.25f;\n    float param_6 = ((_2100_fa_shadow_info[ci].x * min(_2412, 3.0f)) * 0.5f) / _2393;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2100_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2100_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_366_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2872 = int(_2100_fa_shadow_cfg.x + 0.5f);\n    if (_2872 < 1)\n    {\n        return 1.0f;\n    }\n    float _2887 = dot(world - _2100_fa_shadow_eye.xyz, _2100_fa_shadow_fwd.xyz);\n    int param = _2872 - 1;\n    if (_2887 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2899 = _2872 > 1;\n    bool _2906;\n    if (_2899)\n    {\n        _2906 = _2887 > _2100_fa_shadow_split.x;\n    }\n    else\n    {\n        _2906 = _2899;\n    }\n    if (_2906)\n    {\n        ci = 1;\n    }\n    bool _2910 = _2872 > 2;\n    bool _2917;\n    if (_2910)\n    {\n        _2917 = _2887 > _2100_fa_shadow_split.y;\n    }\n    else\n    {\n        _2917 = _2910;\n    }\n    if (_2917)\n    {\n        ci = 2;\n    }\n    bool _2921 = _2872 > 3;\n    bool _2928;\n    if (_2921)\n    {\n        _2928 = _2887 > _2100_fa_shadow_split.z;\n    }\n    else\n    {\n        _2928 = _2921;\n    }\n    if (_2928)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    float s2 = -1.0f;\n    float t = 0.0f;\n    int _2939 = min(_2872, 4);\n    float _2980;\n    for (int c = ci; c < _2939; c++)\n    {\n        int param_1 = c;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2959 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0f)\n        {\n            s2 = _2959;\n            break;\n        }\n        if (_2959 < 0.0f)\n        {\n            continue;\n        }\n        s = _2959;\n        ci = c;\n        if (_2100_fa_shadow_cfg.y > 0.0f)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _2980 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _2980 = _2100_fa_shadow_fwd.w;\n            }\n            int param_6 = ci;\n            float _2999 = _2100_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2980, 9.9999997473787516355514526367188e-05f);\n            int param_7 = ci;\n            t = clamp((_2887 - (fa_shadow_split_at(param_7) - _2999)) / _2999, 0.0f, 1.0f);\n        }\n        if (t <= 0.0f)\n        {\n            break;\n        }\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (t > 0.0f)\n    {\n        float _3031;\n        if ((ci + 1) < _2872)\n        {\n            _3031 = (s2 < 0.0f) ? s : s2;\n        }\n        else\n        {\n            _3031 = 1.0f;\n        }\n        s = lerp(s, _3031, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _3486 = _366_fa_ct_a.x < 0.5f;\n    bool _3493;\n    if (!_3486)\n    {\n        _3493 = _2100_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _3493 = _3486;\n    }\n    if (_3493)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2100_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _3506 = fa_light_texel(param);\n    float _3507 = _3506.y;\n    float len = _3507;\n    if (_3507 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3519 = length(world - _366_fa_camera_pos.xyz);\n    float _3529 = 1.0f - smoothstep(0.5f * _366_fa_ct_b.x, _366_fa_ct_b.x, _3519);\n    if (_3529 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3535 = len;\n    float _3538 = min(_3535, 0.89999997615814208984375f * dist);\n    len = _3538;\n    float _3544 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _3519);\n    float _3549 = _3544 + (0.5f * _3538);\n    float3 _3555 = world + (gn * _3544);\n    float _3557 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _3622;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3573 = (float(k) + _3557) * 0.083333335816860198974609375f;\n        float3 _3581 = _3555 + (l * (_3573 * len));\n        float4 _3587 = float4(_3581, 1.0f);\n        float _3593 = dot(_366_fa_ct_vpw, _3587);\n        if (_3593 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _3613 = float2(dot(_366_fa_ct_vpx, _3587), dot(_366_fa_ct_vpy, _3587)) / _3593.xx;\n        float _3617 = _3613.x * 0.5f;\n        float _3618 = _3617 + 0.5f;\n        if (_366_fa_ct_a.y > 0.5f)\n        {\n            _3622 = (_3613.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _3622 = 0.5f - (_3613.y * 0.5f);\n        }\n        bool _3638 = _3618 < 0.0f;\n        bool _3645;\n        if (!_3638)\n        {\n            _3645 = _3618 >= 1.0f;\n        }\n        else\n        {\n            _3645 = _3638;\n        }\n        bool _3652;\n        if (!_3645)\n        {\n            _3652 = _3622 < 0.0f;\n        }\n        else\n        {\n            _3652 = _3645;\n        }\n        bool _3659;\n        if (!_3652)\n        {\n            _3659 = _3622 >= 1.0f;\n        }\n        else\n        {\n            _3659 = _3652;\n        }\n        if (_3659)\n        {\n            break;\n        }\n        float4 _3686 = fa_screen_tex.Load(int3(clamp(int2(float2(_3618, _3622) * _366_fa_ct_a.zw), int2(0, 0), int2(_366_fa_ct_a.zw) - int2(1, 1)), 0));\n        if (_3686.w < 0.5f)\n        {\n            continue;\n        }\n        float _3705 = (dot(_366_fa_ct_fwd.xyz, _3581) + _366_fa_ct_fwd.w) - _3686.x;\n        if ((_3705 > _3544) && (_3705 < _3549))\n        {\n            occ = max(occ, (1.0f - (_3573 * _3573)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_3618, 0.5f - _3617), min(_3622, 1.0f - _3622))));\n        }\n    }\n    return 1.0f - (occ * _3529);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _3808 = fa_baked_keep(param);\n    if (_3808 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _5639 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _5639;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3834 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _5641 = _3834.color;\n    float _5642 = _3834.attenuation;\n    float _5643 = _3834.shadow;\n    bool _3837 = _3834.type == 0;\n    if (_3837 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3834.direction;\n        float _3848 = fa_shadow_factor(param_5, param_6);\n        _5643 = _3848;\n        _5641 *= _3848;\n    }\n    else\n    {\n        bool _3859 = _3834.type != 0;\n        bool _3865;\n        if (_3859)\n        {\n            _3865 = _5642 > 0.0f;\n        }\n        else\n        {\n            _3865 = _3859;\n        }\n        if (_3865)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _3834.direction;\n            float _3884 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _5643 = _3884;\n            _5641 *= _3884;\n        }\n    }\n    bool _3894 = _366_fa_ct_a.x > 0.5f;\n    bool _3900;\n    if (_3894)\n    {\n        _3900 = _5642 > 0.0f;\n    }\n    else\n    {\n        _3900 = _3894;\n    }\n    if (_3900)\n    {\n        float _3907;\n        if (_3837)\n        {\n            _3907 = 1000000000.0f;\n        }\n        else\n        {\n            _3907 = _3834._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _3834.direction;\n        float param_18 = _3907;\n        float _3925 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _5643 *= _3925;\n        _5641 *= _3925;\n    }\n    float _3938 = _5642;\n    float _3939 = _3938 * _3808;\n    _5642 = _3939;\n    float3 _3943 = _5641;\n    float3 _3944 = _3943 * _3808;\n    _5641 = _3944;\n    LightSample _5658 = { _3834.direction, _3944, _3939, _5643, _3834._distance, _3834.type };\n    return _5658;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    float _3958;\n    if (dot(s.normal, l.direction) > 0.5f)\n    {\n        _3958 = 1.0f;\n    }\n    else\n    {\n        _3958 = _3964_dark;\n    }\n    return (s.albedo * l.color) * _3958;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2100_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3059 = int(_2100_fa_shadow_cfg.x + 0.5f);\n    float _3069 = dot(world - _2100_fa_shadow_eye.xyz, _2100_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3074 = _3059 > 0;\n    bool _3083;\n    if (_3074)\n    {\n        int param = _3059 - 1;\n        _3083 = _3069 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3083 = _3074;\n    }\n    if (_3083)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3089 = _3059 > 1;\n        bool _3096;\n        if (_3089)\n        {\n            _3096 = _3069 > _2100_fa_shadow_split.x;\n        }\n        else\n        {\n            _3096 = _3089;\n        }\n        if (_3096)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3102 = _3059 > 2;\n        bool _3109;\n        if (_3102)\n        {\n            _3109 = _3069 > _2100_fa_shadow_split.y;\n        }\n        else\n        {\n            _3109 = _3102;\n        }\n        if (_3109)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3115 = _3059 > 3;\n        bool _3122;\n        if (_3115)\n        {\n            _3122 = _3069 > _2100_fa_shadow_split.z;\n        }\n        else\n        {\n            _3122 = _3115;\n        }\n        if (_3122)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _5462 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5462 = -_5462;\n    }\n    float3 _5035 = normalize(_366_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _5475 = { fa_world_pos, _5462, fa_world_tangent, fa_uv, fa_vertex_color, _5035, gl_FrontFacing };\n    SurfaceInput param_1 = _5475;\n    Surface _5043 = fa_standard_surface(param_1);\n    float3 _5493 = _5043.albedo;\n    float _5494 = _5043.alpha;\n    float3 _5495 = _5043.normal;\n    float _5496 = _5043.metallic;\n    float _5497 = _5043.roughness;\n    float _5498 = _5043.occlusion;\n    float3 _5499 = _5043.emission;\n    float _5500 = _5043.clearcoat;\n    float _5501 = _5043.clearcoat_roughness;\n    float3 _5502 = _5043.sheen_color;\n    float _5503 = _5043.sheen_roughness;\n    float _5504 = _5043.anisotropy;\n    float _5505 = _5043.anisotropy_rotation;\n    float _5506 = _5043.specular;\n    float _5507 = _5043.ior;\n    float3 _5508 = _5043.specular_color;\n    float _5509 = _5043.transmission;\n    float _5510 = _5043.thickness;\n    float3 _5511 = _5043.attenuation_color;\n    float _5512 = _5043.attenuation_distance;\n    SurfaceInput _5483 = { fa_world_pos, _5462, fa_world_tangent, fa_uv, fa_vertex_color, _5035, gl_FrontFacing };\n    SurfaceInput param_2 = _5483;\n    Surface param_3 = _5043;\n    surface(param_2, param_3);\n    _5493 = param_3.albedo;\n    _5494 = param_3.alpha;\n    _5495 = param_3.normal;\n    _5496 = param_3.metallic;\n    _5497 = param_3.roughness;\n    _5498 = param_3.occlusion;\n    _5499 = param_3.emission;\n    _5500 = param_3.clearcoat;\n    _5501 = param_3.clearcoat_roughness;\n    _5502 = param_3.sheen_color;\n    _5503 = param_3.sheen_roughness;\n    _5504 = param_3.anisotropy;\n    _5505 = param_3.anisotropy_rotation;\n    _5506 = param_3.specular;\n    _5507 = param_3.ior;\n    _5508 = param_3.specular_color;\n    _5509 = param_3.transmission;\n    _5510 = param_3.thickness;\n    _5511 = param_3.attenuation_color;\n    _5512 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _5462;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5493 = param_6;\n    _5495 = param_7;\n    fa_lod_dither();\n    float3 result;\n    if (_366_fa_emissive.w > 0.5f)\n    {\n        result = _5493;\n    }\n    else\n    {\n        float3 _5083 = _5495;\n        float3 _5084 = normalize(_5083);\n        _5495 = _5084;\n        float3 param_8 = _5084;\n        float3 lit = (fa_indirect_diffuse(param_8) * _5493) * _5498;\n        int _5103 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5103; ln++)\n        {\n            int param_9 = ln;\n            int _5116 = fa_cl_light(param_9);\n            int param_10 = _5116;\n            if (fa_baked_keep(param_10) <= 0.0f)\n            {\n                continue;\n            }\n            int param_11 = _5116;\n            float3 param_12 = fa_world_pos;\n            float3 param_13 = _5462;\n            LightSample _5132 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput _5491 = { fa_world_pos, _5462, fa_world_tangent, fa_uv, fa_vertex_color, _5035, gl_FrontFacing };\n            SurfaceInput param_14 = _5491;\n            Surface _5594 = { _5493, _5494, _5495, _5496, _5497, _5498, _5499, _5500, _5501, _5502, _5503, _5504, _5505, _5506, _5507, _5508, _5509, _5510, _5511, _5512 };\n            Surface param_15 = _5594;\n            LightSample param_16 = _5132;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    float3 _5147 = result;\n    float3 _5148 = _5147 + _5499;\n    result = _5148;\n    float3 param_17 = _5148;\n    float3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _5157 = _366_fa_fog.w > 0.0f;\n    bool _5164;\n    if (!_5157)\n    {\n        _5164 = _366_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _5164 = _5157;\n    }\n    if (_5164)\n    {\n        float3 _5173 = fa_world_pos - _366_fa_camera_pos.xyz;\n        float _5179 = dot(_5173, _366_fa_fog_c.xyz);\n        bool _5183 = _366_fa_fog_c.w > 0.5f;\n        float _5184;\n        if (_5183)\n        {\n            _5184 = _5179;\n        }\n        else\n        {\n            _5184 = length(_5173);\n        }\n        float _5196 = _5184 - _366_fa_fog_b.x;\n        if (_5196 > 0.0f)\n        {\n            float _5205 = _366_fa_fog.w * _5196;\n            float tau = _5205 * _5205;\n            if (_366_fa_fog_b.y > 0.0f)\n            {\n                float _5221;\n                if (_5183)\n                {\n                    _5221 = fa_world_pos.y - (_366_fa_fog_c.y * _5179);\n                }\n                else\n                {\n                    _5221 = _366_fa_camera_pos.y;\n                }\n                float _5242 = lerp(_5221, fa_world_pos.y, clamp(_366_fa_fog_b.x / _5184, 0.0f, 1.0f));\n                float _5246 = fa_world_pos.y - _5242;\n                float _5251 = _5242 - _366_fa_fog_b.z;\n                float _5256 = fa_world_pos.y - _366_fa_fog_b.z;\n                bool _5259 = _5251 <= 0.0f;\n                bool _5260 = !_5259;\n                bool _5266;\n                if (_5260)\n                {\n                    _5266 = _366_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5266 = _5259;\n                }\n                float _5267;\n                if (_5266)\n                {\n                    _5267 = _366_fa_fog_b.y;\n                }\n                else\n                {\n                    _5267 = _366_fa_fog_b.y * exp(-min(_366_fa_fog_b.w * _5251, 80.0f));\n                }\n                bool _5294;\n                if (_5260)\n                {\n                    _5294 = _366_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5294 = _5259;\n                }\n                float _5295;\n                if (_5294)\n                {\n                    _5295 = _366_fa_fog_b.y * _5251;\n                }\n                else\n                {\n                    _5295 = (_366_fa_fog_b.y * (1.0f - exp(-min(_366_fa_fog_b.w * _5251, 80.0f)))) / _366_fa_fog_b.w;\n                }\n                bool _5320 = _5256 <= 0.0f;\n                bool _5327;\n                if (!_5320)\n                {\n                    _5327 = _366_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5327 = _5320;\n                }\n                float _5328;\n                if (_5327)\n                {\n                    _5328 = _366_fa_fog_b.y * _5256;\n                }\n                else\n                {\n                    _5328 = (_366_fa_fog_b.y * (1.0f - exp(-min(_366_fa_fog_b.w * _5256, 80.0f)))) / _366_fa_fog_b.w;\n                }\n                float _5355;\n                if (abs(_5246) < 0.001000000047497451305389404296875f)\n                {\n                    _5355 = _5267;\n                }\n                else\n                {\n                    _5355 = (_5328 - _5295) / _5246;\n                }\n                tau += (_5196 * max(_5355, 0.0f));\n            }\n            result = lerp(result, _366_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _5494);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_366",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2100",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_3964",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _295 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _295;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _302 = _160.world_pos;\n    float4 _171 = float4(_302, 1.0f);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -mul(_171, _131_fa_light_vp).z;\n    fa_pre_r0 = float3(_131_fa_light_vp[0].x, _131_fa_light_vp[1].x, _131_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131_fa_light_vp[0].y, _131_fa_light_vp[1].y, _131_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131_fa_light_vp[0].z, _131_fa_light_vp[1].z, _131_fa_light_vp[2].z);\n    gl_Position = mul(_171, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _129_fa_camera_pos : packoffset(c0);\n    float4 _129_fa_ambient : packoffset(c1);\n    float4 _129_fa_base_color : packoffset(c2);\n    float4 _129_fa_emissive : packoffset(c3);\n    float4 _129_fa_model_emissive : packoffset(c4);\n    float4 _129_fa_pbr : packoffset(c5);\n    float4 _129_fa_maps : packoffset(c6);\n    float4 _129_fa_fog : packoffset(c7);\n    float4 _129_fa_fog_b : packoffset(c8);\n    float4 _129_fa_fog_c : packoffset(c9);\n    float4 _129_fa_counts : packoffset(c10);\n    float4 _129_fa_env_sky : packoffset(c11);\n    float4 _129_fa_env_horizon : packoffset(c12);\n    float4 _129_fa_time : packoffset(c13);\n    float4 _129_fa_cl_vpx : packoffset(c14);\n    float4 _129_fa_cl_vpy : packoffset(c15);\n    float4 _129_fa_cl_vpw : packoffset(c16);\n    float4 _129_fa_cl_fwd : packoffset(c17);\n    float4 _129_fa_cl_grid : packoffset(c18);\n    float4 _129_fa_cl_info : packoffset(c19);\n    float4 _129_fa_layers_a : packoffset(c20);\n    float4 _129_fa_layers_b : packoffset(c21);\n    float4 _129_fa_layers_c : packoffset(c22);\n    float4 _129_fa_layers_d : packoffset(c23);\n    float4 _129_fa_ct_a : packoffset(c24);\n    float4 _129_fa_ct_b : packoffset(c25);\n    float4 _129_fa_ct_vpx : packoffset(c26);\n    float4 _129_fa_ct_vpy : packoffset(c27);\n    float4 _129_fa_ct_vpw : packoffset(c28);\n    float4 _129_fa_ct_fwd : packoffset(c29);\n    float4 _129_fa_tr_a : packoffset(c30);\n    float4 _129_fa_tr_b : packoffset(c31);\n    float4 _129_fa_probe_sh[9] : packoffset(c32);\n    float4 _129_fa_atlas : packoffset(c41);\n    float4 _129_fa_rpa_tile : packoffset(c42);\n    float4 _129_fa_rpa_pos : packoffset(c43);\n    float4 _129_fa_rpa_bx : packoffset(c44);\n    float4 _129_fa_rpa_by : packoffset(c45);\n    float4 _129_fa_rpa_bz : packoffset(c46);\n    float4 _129_fa_rpb_tile : packoffset(c47);\n    float4 _129_fa_rpb_pos : packoffset(c48);\n    float4 _129_fa_rpb_bx : packoffset(c49);\n    float4 _129_fa_rpb_by : packoffset(c50);\n    float4 _129_fa_rpb_bz : packoffset(c51);\n    float4 _129_fa_gi : packoffset(c52);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _218 = fa_linear_to_srgb(param);\n        c = _218;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _227 = fa_srgb_to_linear(param_1);\n            c = _227;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _58;\n    if (i.front_facing)\n    {\n        _58 = i.world_normal;\n    }\n    else\n    {\n        _58 = -i.world_normal;\n    }\n    float3 _83 = normalize(i.world_tangent.xyz - (_58 * dot(_58, i.world_tangent.xyz)));\n    float3 _111 = normalize(((_83 * m.x) + ((cross(_58, _83) * i.world_tangent.w) * m.y)) + (_58 * m.z));\n    float3 _114;\n    if (i.front_facing)\n    {\n        _114 = _111;\n    }\n    else\n    {\n        _114 = -_111;\n    }\n    return _114;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _129_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _267 = fa_tex_fix(param_2, param_3);\n    float4 _871 = base_t;\n    _871.x = _267.x;\n    _871.y = _267.y;\n    _871.z = _267.z;\n    base_t = _871;\n    float4 _283 = (_871 * _129_fa_base_color) * i.vertex_color;\n    float3 _826 = i.world_normal;\n    if (_129_fa_maps.z > 0.5f)\n    {\n        float param_4 = _129_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _317 = fa_tex_fix(param_6, param_7);\n        float3 _321 = (_317 * 2.0f) - 1.0f.xxx;\n        float2 _326 = _321.xy * _129_fa_maps.x;\n        float3 _879 = _321;\n        _879.x = _326.x;\n        _879.y = _326.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _879;\n        _826 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _129_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _355 = fa_tex_fix(param_12, param_13);\n    float4 _882 = mrt;\n    _882.x = _355.x;\n    _882.y = _355.y;\n    _882.z = _355.z;\n    mrt = _882;\n    float4 _385 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _129_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _385.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _397 = fa_tex_fix(param_16, param_17);\n    float param_18 = _129_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _427 = fa_tex_fix(param_20, param_21);\n    float _831 = _129_fa_layers_a.x;\n    float _832 = _129_fa_layers_a.y;\n    float _835 = _129_fa_layers_a.z;\n    float _834 = _129_fa_layers_b.w;\n    float _837 = _129_fa_layers_c.x;\n    if (_129_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_129_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _831 *= _397.y;\n            _832 *= _397.z;\n            _834 *= _385.w;\n        }\n        if (_129_fa_layers_c.z > 1.5f)\n        {\n            _835 *= mrt.x;\n            _837 *= mrt.w;\n        }\n    }\n    Surface _864 = { _283.xyz, _283.w, _826, clamp(_129_fa_pbr.x * _355.z, 0.0f, 1.0f), clamp(_129_fa_pbr.y * _355.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_129_fa_maps.y * (_397.x - 1.0f)), _129_fa_emissive.xyz + (_129_fa_model_emissive.xyz * _427), _831, _832, _129_fa_layers_b.xyz, _834, _835, _129_fa_layers_a.w, _837, _129_fa_layers_c.y, _129_fa_layers_d.xyz, _129_fa_tr_a.x, _129_fa_tr_a.y, _129_fa_tr_b.xyz, _129_fa_tr_a.z };\n    return _864;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid fa_lod_dither()\n{\n    if (_129_fa_gi.w != 0.0f)\n    {\n        float _151 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n        bool _154;\n        if (_129_fa_gi.w > 0.0f)\n        {\n            _154 = _151 >= _129_fa_gi.w;\n        }\n        else\n        {\n            _154 = _151 < (-_129_fa_gi.w);\n        }\n        if (_154)\n        {\n            discard;\n        }\n    }\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _721 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _721 = -_721;\n    }\n    float3 _579 = normalize(_129_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _734 = { fa_world_pos, _721, fa_world_tangent, fa_uv, fa_vertex_color, _579, gl_FrontFacing };\n    SurfaceInput param = _734;\n    Surface _584 = fa_standard_surface(param);\n    float3 _745 = _584.normal;\n    SurfaceInput _742 = { fa_world_pos, _721, fa_world_tangent, fa_uv, fa_vertex_color, _579, gl_FrontFacing };\n    SurfaceInput param_1 = _742;\n    Surface param_2 = _584;\n    surface(param_1, param_2);\n    _745 = param_2.normal;\n    fa_lod_dither();\n    float3 _595 = normalize(_745);\n    float3 _610 = normalize(float3(dot(fa_pre_r0, _595), dot(fa_pre_r1, _595), dot(fa_pre_r2, _595)));\n    float _622 = _610.z;\n    float2 e = _610.xy / ((abs(_610.x) + abs(_610.y)) + abs(_622)).xx;\n    if (_622 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_129",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _416 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _416;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _423 = _273.world_pos;\n    float4 _284 = float4(_423, 1.0f);\n    fa_world_pos = _423;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -mul(_284, _136_fa_light_vp).z;\n    fa_pre_r0 = float3(_136_fa_light_vp[0].x, _136_fa_light_vp[1].x, _136_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136_fa_light_vp[0].y, _136_fa_light_vp[1].y, _136_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136_fa_light_vp[0].z, _136_fa_light_vp[1].z, _136_fa_light_vp[2].z);\n    gl_Position = mul(_284, _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _129_fa_camera_pos : packoffset(c0);\n    float4 _129_fa_ambient : packoffset(c1);\n    float4 _129_fa_base_color : packoffset(c2);\n    float4 _129_fa_emissive : packoffset(c3);\n    float4 _129_fa_model_emissive : packoffset(c4);\n    float4 _129_fa_pbr : packoffset(c5);\n    float4 _129_fa_maps : packoffset(c6);\n    float4 _129_fa_fog : packoffset(c7);\n    float4 _129_fa_fog_b : packoffset(c8);\n    float4 _129_fa_fog_c : packoffset(c9);\n    float4 _129_fa_counts : packoffset(c10);\n    float4 _129_fa_env_sky : packoffset(c11);\n    float4 _129_fa_env_horizon : packoffset(c12);\n    float4 _129_fa_time : packoffset(c13);\n    float4 _129_fa_cl_vpx : packoffset(c14);\n    float4 _129_fa_cl_vpy : packoffset(c15);\n    float4 _129_fa_cl_vpw : packoffset(c16);\n    float4 _129_fa_cl_fwd : packoffset(c17);\n    float4 _129_fa_cl_grid : packoffset(c18);\n    float4 _129_fa_cl_info : packoffset(c19);\n    float4 _129_fa_layers_a : packoffset(c20);\n    float4 _129_fa_layers_b : packoffset(c21);\n    float4 _129_fa_layers_c : packoffset(c22);\n    float4 _129_fa_layers_d : packoffset(c23);\n    float4 _129_fa_ct_a : packoffset(c24);\n    float4 _129_fa_ct_b : packoffset(c25);\n    float4 _129_fa_ct_vpx : packoffset(c26);\n    float4 _129_fa_ct_vpy : packoffset(c27);\n    float4 _129_fa_ct_vpw : packoffset(c28);\n    float4 _129_fa_ct_fwd : packoffset(c29);\n    float4 _129_fa_tr_a : packoffset(c30);\n    float4 _129_fa_tr_b : packoffset(c31);\n    float4 _129_fa_probe_sh[9] : packoffset(c32);\n    float4 _129_fa_atlas : packoffset(c41);\n    float4 _129_fa_rpa_tile : packoffset(c42);\n    float4 _129_fa_rpa_pos : packoffset(c43);\n    float4 _129_fa_rpa_bx : packoffset(c44);\n    float4 _129_fa_rpa_by : packoffset(c45);\n    float4 _129_fa_rpa_bz : packoffset(c46);\n    float4 _129_fa_rpb_tile : packoffset(c47);\n    float4 _129_fa_rpb_pos : packoffset(c48);\n    float4 _129_fa_rpb_bx : packoffset(c49);\n    float4 _129_fa_rpb_by : packoffset(c50);\n    float4 _129_fa_rpb_bz : packoffset(c51);\n    float4 _129_fa_gi : packoffset(c52);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _218 = fa_linear_to_srgb(param);\n        c = _218;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _227 = fa_srgb_to_linear(param_1);\n            c = _227;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _58;\n    if (i.front_facing)\n    {\n        _58 = i.world_normal;\n    }\n    else\n    {\n        _58 = -i.world_normal;\n    }\n    float3 _83 = normalize(i.world_tangent.xyz - (_58 * dot(_58, i.world_tangent.xyz)));\n    float3 _111 = normalize(((_83 * m.x) + ((cross(_58, _83) * i.world_tangent.w) * m.y)) + (_58 * m.z));\n    float3 _114;\n    if (i.front_facing)\n    {\n        _114 = _111;\n    }\n    else\n    {\n        _114 = -_111;\n    }\n    return _114;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _129_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _267 = fa_tex_fix(param_2, param_3);\n    float4 _871 = base_t;\n    _871.x = _267.x;\n    _871.y = _267.y;\n    _871.z = _267.z;\n    base_t = _871;\n    float4 _283 = (_871 * _129_fa_base_color) * i.vertex_color;\n    float3 _826 = i.world_normal;\n    if (_129_fa_maps.z > 0.5f)\n    {\n        float param_4 = _129_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _317 = fa_tex_fix(param_6, param_7);\n        float3 _321 = (_317 * 2.0f) - 1.0f.xxx;\n        float2 _326 = _321.xy * _129_fa_maps.x;\n        float3 _879 = _321;\n        _879.x = _326.x;\n        _879.y = _326.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _879;\n        _826 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _129_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _355 = fa_tex_fix(param_12, param_13);\n    float4 _882 = mrt;\n    _882.x = _355.x;\n    _882.y = _355.y;\n    _882.z = _355.z;\n    mrt = _882;\n    float4 _385 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _129_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _385.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _397 = fa_tex_fix(param_16, param_17);\n    float param_18 = _129_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _427 = fa_tex_fix(param_20, param_21);\n    float _831 = _129_fa_layers_a.x;\n    float _832 = _129_fa_layers_a.y;\n    float _835 = _129_fa_layers_a.z;\n    float _834 = _129_fa_layers_b.w;\n    float _837 = _129_fa_layers_c.x;\n    if (_129_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_129_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _831 *= _397.y;\n            _832 *= _397.z;\n            _834 *= _385.w;\n        }\n        if (_129_fa_layers_c.z > 1.5f)\n        {\n            _835 *= mrt.x;\n            _837 *= mrt.w;\n        }\n    }\n    Surface _864 = { _283.xyz, _283.w, _826, clamp(_129_fa_pbr.x * _355.z, 0.0f, 1.0f), clamp(_129_fa_pbr.y * _355.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_129_fa_maps.y * (_397.x - 1.0f)), _129_fa_emissive.xyz + (_129_fa_model_emissive.xyz * _427), _831, _832, _129_fa_layers_b.xyz, _834, _835, _129_fa_layers_a.w, _837, _129_fa_layers_c.y, _129_fa_layers_d.xyz, _129_fa_tr_a.x, _129_fa_tr_a.y, _129_fa_tr_b.xyz, _129_fa_tr_a.z };\n    return _864;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid fa_lod_dither()\n{\n    if (_129_fa_gi.w != 0.0f)\n    {\n        float _151 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n        bool _154;\n        if (_129_fa_gi.w > 0.0f)\n        {\n            _154 = _151 >= _129_fa_gi.w;\n        }\n        else\n        {\n            _154 = _151 < (-_129_fa_gi.w);\n        }\n        if (_154)\n        {\n            discard;\n        }\n    }\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _721 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _721 = -_721;\n    }\n    float3 _579 = normalize(_129_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _734 = { fa_world_pos, _721, fa_world_tangent, fa_uv, fa_vertex_color, _579, gl_FrontFacing };\n    SurfaceInput param = _734;\n    Surface _584 = fa_standard_surface(param);\n    float3 _745 = _584.normal;\n    SurfaceInput _742 = { fa_world_pos, _721, fa_world_tangent, fa_uv, fa_vertex_color, _579, gl_FrontFacing };\n    SurfaceInput param_1 = _742;\n    Surface param_2 = _584;\n    surface(param_1, param_2);\n    _745 = param_2.normal;\n    fa_lod_dither();\n    float3 _595 = normalize(_745);\n    float3 _610 = normalize(float3(dot(fa_pre_r0, _595), dot(fa_pre_r1, _595), dot(fa_pre_r2, _595)));\n    float _622 = _610.z;\n    float2 e = _610.xy / ((abs(_610.x) + abs(_610.y)) + abs(_622)).xx;\n    if (_622 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_129",
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
