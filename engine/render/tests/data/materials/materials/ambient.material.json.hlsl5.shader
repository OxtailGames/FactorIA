{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "cdeb0668828214c74f0c30d588a05ff792b9d23c1a6a8d04f213c29c73527515",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _260 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _260;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_267, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _466_fa_camera_pos : packoffset(c0);\n    float4 _466_fa_ambient : packoffset(c1);\n    float4 _466_fa_base_color : packoffset(c2);\n    float4 _466_fa_emissive : packoffset(c3);\n    float4 _466_fa_model_emissive : packoffset(c4);\n    float4 _466_fa_pbr : packoffset(c5);\n    float4 _466_fa_maps : packoffset(c6);\n    float4 _466_fa_fog : packoffset(c7);\n    float4 _466_fa_fog_b : packoffset(c8);\n    float4 _466_fa_fog_c : packoffset(c9);\n    float4 _466_fa_counts : packoffset(c10);\n    float4 _466_fa_env_sky : packoffset(c11);\n    float4 _466_fa_env_horizon : packoffset(c12);\n    float4 _466_fa_time : packoffset(c13);\n    float4 _466_fa_cl_vpx : packoffset(c14);\n    float4 _466_fa_cl_vpy : packoffset(c15);\n    float4 _466_fa_cl_vpw : packoffset(c16);\n    float4 _466_fa_cl_fwd : packoffset(c17);\n    float4 _466_fa_cl_grid : packoffset(c18);\n    float4 _466_fa_cl_info : packoffset(c19);\n    float4 _466_fa_layers_a : packoffset(c20);\n    float4 _466_fa_layers_b : packoffset(c21);\n    float4 _466_fa_layers_c : packoffset(c22);\n    float4 _466_fa_layers_d : packoffset(c23);\n    float4 _466_fa_ct_a : packoffset(c24);\n    float4 _466_fa_ct_b : packoffset(c25);\n    float4 _466_fa_ct_vpx : packoffset(c26);\n    float4 _466_fa_ct_vpy : packoffset(c27);\n    float4 _466_fa_ct_vpw : packoffset(c28);\n    float4 _466_fa_ct_fwd : packoffset(c29);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _1206_fa_shadow_mat[4] : packoffset(c0);\n    float4 _1206_fa_shadow_rect[4] : packoffset(c16);\n    float4 _1206_fa_shadow_info[4] : packoffset(c20);\n    float4 _1206_fa_shadow_split : packoffset(c24);\n    float4 _1206_fa_shadow_cfg : packoffset(c25);\n    float4 _1206_fa_shadow_bias : packoffset(c26);\n    float4 _1206_fa_shadow_eye : packoffset(c27);\n    float4 _1206_fa_shadow_fwd : packoffset(c28);\n    float4 _1206_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_decal_tex : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_screen_tex : register(t10);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t8);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _471 = _466_fa_cl_info.x < 0.0f;\n    bool _478;\n    if (!_471)\n    {\n        _478 = _466_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _478 = _471;\n    }\n    bool _486;\n    if (!_478)\n    {\n        _486 = _466_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _486 = _478;\n    }\n    bool _493;\n    if (!_486)\n    {\n        _493 = _466_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _493 = _486;\n    }\n    bool _500;\n    if (!_493)\n    {\n        _500 = _466_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _500 = _493;\n    }\n    if (_500)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _510 = float4(world_pos, 1.0f);\n    float _517 = dot(_466_fa_cl_vpw, _510);\n    if (!(_517 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _539 = float2(dot(_466_fa_cl_vpx, _510), dot(_466_fa_cl_vpy, _510)) / _517.xx;\n    int _543 = int(_466_fa_cl_grid.x);\n    int _547 = int(_466_fa_cl_grid.y);\n    int param = (int(_466_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_466_fa_cl_fwd.xyz, world_pos) + _466_fa_cl_fwd.w, _466_fa_cl_grid.w) / _466_fa_cl_grid.w) * _466_fa_cl_grid.z)), 0, int(_466_fa_cl_info.y) - 1) * _547) + clamp(int(floor(((_539.y * 0.5f) + 0.5f) * _466_fa_cl_grid.y)), 0, _547 - 1)) * _543)) + clamp(int(floor(((_539.x * 0.5f) + 0.5f) * _466_fa_cl_grid.x)), 0, _543 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _623 = fa_cluster_texel(param);\n    return int2(int(_623.x), int(_623.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_466_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2681 = fa_cluster_lookup(param);\n    fa_cl_slot = _2681.x;\n    fa_cl_local = _2681.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _2878 = fa_linear_to_srgb(param);\n        c = _2878;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _2886 = fa_srgb_to_linear(param_1);\n            c = _2886;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _231;\n    if (i.front_facing)\n    {\n        _231 = i.world_normal;\n    }\n    else\n    {\n        _231 = -i.world_normal;\n    }\n    float3 _255 = normalize(i.world_tangent.xyz - (_231 * dot(_231, i.world_tangent.xyz)));\n    float3 _282 = normalize(((_255 * m.x) + ((cross(_231, _255) * i.world_tangent.w) * m.y)) + (_231 * m.z));\n    float3 _285;\n    if (i.front_facing)\n    {\n        _285 = _282;\n    }\n    else\n    {\n        _285 = -_282;\n    }\n    return _285;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _466_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2917 = fa_tex_fix(param_2, param_3);\n    float4 _3963 = base_t;\n    _3963.x = _2917.x;\n    _3963.y = _2917.y;\n    _3963.z = _2917.z;\n    base_t = _3963;\n    float4 _2931 = (_3963 * _466_fa_base_color) * i.vertex_color;\n    float3 _3830 = i.world_normal;\n    if (_466_fa_maps.z > 0.5f)\n    {\n        float param_4 = _466_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2963 = fa_tex_fix(param_6, param_7);\n        float3 _2966 = (_2963 * 2.0f) - 1.0f.xxx;\n        float2 _2971 = _2966.xy * _466_fa_maps.x;\n        float3 _3971 = _2966;\n        _3971.x = _2971.x;\n        _3971.y = _2971.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3971;\n        _3830 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _466_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3000 = fa_tex_fix(param_12, param_13);\n    float4 _3974 = mrt;\n    _3974.x = _3000.x;\n    _3974.y = _3000.y;\n    _3974.z = _3000.z;\n    mrt = _3974;\n    float4 _3028 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _466_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _3028.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3040 = fa_tex_fix(param_16, param_17);\n    float param_18 = _466_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3070 = fa_tex_fix(param_20, param_21);\n    float _3835 = _466_fa_layers_a.x;\n    float _3836 = _466_fa_layers_a.y;\n    float _3839 = _466_fa_layers_a.z;\n    float _3838 = _466_fa_layers_b.w;\n    float _3841 = _466_fa_layers_c.x;\n    if (_466_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_466_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _3835 *= _3040.y;\n            _3836 *= _3040.z;\n            _3838 *= _3028.w;\n        }\n        if (_466_fa_layers_c.z > 1.5f)\n        {\n            _3839 *= mrt.x;\n            _3841 *= mrt.w;\n        }\n    }\n    Surface _3860 = { _2931.xyz, _2931.w, _3830, clamp(_466_fa_pbr.x * _3000.z, 0.0f, 1.0f), clamp(_466_fa_pbr.y * _3000.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_466_fa_maps.y * (_3040.x - 1.0f)), _466_fa_emissive.xyz + (_466_fa_model_emissive.xyz * _3070), _3835, _3836, _466_fa_layers_b.xyz, _3838, _3839, _466_fa_layers_a.w, _3841, _466_fa_layers_c.y, _466_fa_layers_d.xyz };\n    return _3860;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _704 = rect.zw - rect.xy;\n    float2 _708 = _704 * atlas;\n    float2 _712 = ddx * _708;\n    float2 _716 = ddy * _708;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _704), clamp(0.5f * log2(max(max(dot(_712, _712), dot(_716, _716)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _751 = _466_fa_counts.y < 0.5f;\n    bool _758;\n    if (!_751)\n    {\n        _758 = _466_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _758 = _751;\n    }\n    if (_758)\n    {\n        return;\n    }\n    float3 _764 = ddx(world_pos);\n    float3 _767 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _771 = fa_cluster_texel(param);\n    int _775 = int(_771.w);\n    if (_775 < 1)\n    {\n        return;\n    }\n    int _785 = int(_466_fa_counts.y + 0.5f);\n    int param_1 = _785;\n    float4 _789 = fa_light_texel(param_1);\n    float2 _792 = _789.yz;\n    int _796 = int(_789.w);\n    int param_2 = _785 + 1;\n    float4 _801 = fa_light_texel(param_2);\n    float _802 = _801.x;\n    int _808 = int(_466_fa_counts.w + 0.5f) - 1;\n    int _812 = int(_771.z);\n    float3 _1078;\n    for (int k = 0; k < _775; k++)\n    {\n        int _825 = _812 + k;\n        int param_3 = _796 + (_825 >> 2);\n        int _843 = (_785 + 2) + (int(fa_light_texel(param_3)[_825 & 3]) * 7);\n        int param_4 = _843 + 6;\n        float4 _848 = fa_light_texel(param_4);\n        if (((int(_848.w + 0.5f) >> _808) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _843;\n        float4 _863 = fa_light_texel(param_5);\n        int param_6 = _843 + 1;\n        float4 _868 = fa_light_texel(param_6);\n        int param_7 = _843 + 2;\n        float4 _873 = fa_light_texel(param_7);\n        float3 _876 = _863.xyz;\n        float _881 = dot(_876, world_pos) + _863.w;\n        float3 _883 = _868.xyz;\n        float _888 = dot(_883, world_pos) + _868.w;\n        float3 _890 = _873.xyz;\n        float _895 = dot(_890, world_pos) + _873.w;\n        bool _900 = abs(_881) > 0.5f;\n        bool _908;\n        if (!_900)\n        {\n            _908 = abs(_888) > 0.5f;\n        }\n        else\n        {\n            _908 = _900;\n        }\n        bool _916;\n        if (!_908)\n        {\n            _916 = abs(_895) > 0.5f;\n        }\n        else\n        {\n            _916 = _908;\n        }\n        if (_916)\n        {\n            continue;\n        }\n        float _931 = clamp(dot(geo_normal, normalize(_890)) * _848.z, 0.0f, 1.0f);\n        if (_931 <= 0.0f)\n        {\n            continue;\n        }\n        float _951 = (clamp((0.5f - abs(_895)) * 10.0f, 0.0f, 1.0f) * _931) * _848.x;\n        float2 _959 = float2(_881 + 0.5f, 0.5f - _888);\n        float2 _969 = float2(dot(_876, _764), dot(_883, _764));\n        float2 _979 = float2(dot(_876, _767), dot(_883, _767));\n        int param_8 = _843 + 5;\n        float4 _984 = fa_light_texel(param_8);\n        int param_9 = _843 + 3;\n        float4 _989 = fa_light_texel(param_9);\n        int param_10 = _843 + 4;\n        float4 _994 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _984.xyz;\n        bool _1004 = _989.z > _989.x;\n        if (_1004)\n        {\n            float4 param_11 = _989;\n            float2 param_12 = _959;\n            float2 param_13 = _792;\n            float2 param_14 = _969;\n            float2 param_15 = _979;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_802 > 0.5f) && (_802 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1030 = fa_dc_to_linear(param_16);\n                float4 _3886 = tx;\n                _3886.x = _1030.x;\n                _3886.y = _1030.y;\n                _3886.z = _1030.z;\n                tx = _3886;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_951 * tex_a) * _984.w, 0.0f, 1.0f).xxx);\n        if (_994.z > _994.x)\n        {\n            float4 param_17 = _994;\n            float2 param_18 = _959;\n            float2 param_19 = _792;\n            float2 param_20 = _969;\n            float2 param_21 = _979;\n            float4 _1074 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_802 > 1.5f)\n            {\n                float3 param_22 = _1074.xyz;\n                float3 _1084 = fa_dc_to_srgb(param_22);\n                _1078 = _1084;\n            }\n            else\n            {\n                _1078 = _1074.xyz;\n            }\n            float3 _1094 = (_1078 * 2.0f) - 1.0f.xxx;\n            float2 _1099 = _1094.xy * _848.y;\n            float3 _1121 = (normalize(_876) * _1099.x) + (normalize(_883) * _1099.y);\n            float3 _1124 = normalize(normal);\n            normal = normalize(lerp(_1124, normalize((_1124 * max(_1094.z, 0.0500000007450580596923828125f)) + (_1121 - (_1124 * dot(_1124, _1121)))), clamp(_951 * (_1004 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_sky_sh_coef(int k)\n{\n    float3 v = fa_env_tex.SampleLevel(fa_env_smp, float3(1.0f, 1.0f - (float((2 * (k >> 2)) + 1) * 0.25f), 1.0f - (float((2 * (k & 3)) + 1) * 0.25f)), 5.0f).xyz;\n    if (_466_fa_env_sky.w > 1.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _2341 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _2341;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_466_fa_env_sky.w > 0.5f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _466_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    return float3(0.0f, ambientColor.y, 0.0f);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_466_fa_cl_info.x) + int(_466_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _341 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _347 = fa_light_texel(param_1);\n    float _350 = _347.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _356 = _350 < 0.5f;\n    float3 l;\n    if (_356)\n    {\n        l = normalize(_341.xyz);\n    }\n    else\n    {\n        float3 _368 = _341.xyz - world_pos;\n        float _370 = length(_368);\n        dist = _370;\n        l = _368 / max(_370, 9.9999997473787516355514526367188e-05f).xxx;\n        float _385 = _370 / max(_341.w, 0.001000000047497451305389404296875f);\n        float _391 = clamp(1.0f - (_385 * _385), 0.0f, 1.0f);\n        atten = _391 * _391;\n        if (_350 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _405 = fa_light_texel(param_2);\n            float _415 = _405.w;\n            int param_3 = (li * 4) + 3;\n            float4 _421 = fa_light_texel(param_3);\n            float _422 = _421.x;\n            float cos_inner = _422;\n            if (_422 > 1.5f)\n            {\n                cos_inner = lerp(_415, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_415, cos_inner, dot(-l, normalize(_405.xyz)));\n        }\n    }\n    int _452;\n    if (_356)\n    {\n        _452 = 0;\n    }\n    else\n    {\n        _452 = (_350 > 1.5f) ? 2 : 1;\n    }\n    LightSample _3795 = { l, _347.xyz * atten, atten, 1.0f, dist, _452 };\n    return _3795;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1196;\n    if (i == 0)\n    {\n        _1196 = _1206_fa_shadow_split.x;\n    }\n    else\n    {\n        float _1212;\n        if (i == 1)\n        {\n            _1212 = _1206_fa_shadow_split.y;\n        }\n        else\n        {\n            float _1220;\n            if (i == 2)\n            {\n                _1220 = _1206_fa_shadow_split.z;\n            }\n            else\n            {\n                _1220 = _1206_fa_shadow_split.w;\n            }\n            _1212 = _1220;\n        }\n        _1196 = _1212;\n    }\n    return _1196;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1253 = fa_shadow_depth(param, param_1);\n    float _1257;\n    if (conv.x < 0.5f)\n    {\n        _1257 = _1253;\n    }\n    else\n    {\n        _1257 = (conv.y * conv.z) / (conv.z - (_1253 * (conv.z - conv.y)));\n    }\n    return _1257;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1184 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_1184), sin(_1184)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1303 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _1317 = clamp((k * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1303;\n            float2 _1336 = fa_shadow_vogel(param_3, param_4, param_5) * _1317;\n            float2 param_6 = uv + (_1336 * _1206_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1348 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1348 < (zr - (length(_1336) * plane)))\n            {\n                sum += _1348;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0f) * unit) * k) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _1392 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1392; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1392;\n        float param_11 = _1303;\n        float2 _1411 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1411 * _1206_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1411) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1392);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _1453 = max(_1206_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _1458 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1464 = sqrt(1.0f - (_1458 * _1458));\n    float _1471 = min(_1464 / max(_1458, 0.20000000298023223876953125f), 4.0f);\n    float _1476;\n    if (_1206_fa_shadow_bias.y > 0.0f)\n    {\n        _1476 = _1206_fa_shadow_bias.y;\n    }\n    else\n    {\n        _1476 = 1.5f * _1206_fa_shadow_info[ci].x;\n    }\n    float4 _1501 = mul(float4(world + (n * (_1476 * _1464)), 1.0f), _1206_fa_shadow_mat[ci]);\n    float _1508 = _1501.x;\n    bool _1511 = _1508 < _1206_fa_shadow_rect[ci].x;\n    bool _1520;\n    if (!_1511)\n    {\n        _1520 = _1508 > _1206_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1520 = _1511;\n    }\n    bool _1529;\n    if (!_1520)\n    {\n        _1529 = _1501.y < _1206_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1529 = _1520;\n    }\n    bool _1538;\n    if (!_1529)\n    {\n        _1538 = _1501.y > _1206_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1538 = _1529;\n    }\n    bool _1545;\n    if (!_1538)\n    {\n        _1545 = _1501.z > 1.0f;\n    }\n    else\n    {\n        _1545 = _1538;\n    }\n    if (_1545)\n    {\n        return -1.0f;\n    }\n    float _1554;\n    if (_1206_fa_shadow_bias.x > 0.0f)\n    {\n        _1554 = _1206_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1554 = 1.5f * _1206_fa_shadow_info[ci].x;\n    }\n    float2 param = _1501.xy;\n    float4 param_1 = _1206_fa_shadow_rect[ci];\n    float param_2 = _1501.z - ((_1554 * (1.0f + (0.5f * _1471))) / _1453);\n    float param_3 = _1206_fa_shadow_info[ci].x;\n    float param_4 = _1453;\n    float param_5 = _1453 * 0.25f;\n    float param_6 = ((_1206_fa_shadow_info[ci].x * min(_1471, 3.0f)) * 0.5f) / _1453;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_1206_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _1206_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_466_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1981 = int(_1206_fa_shadow_cfg.x + 0.5f);\n    if (_1981 < 1)\n    {\n        return 1.0f;\n    }\n    float _1996 = dot(world - _1206_fa_shadow_eye.xyz, _1206_fa_shadow_fwd.xyz);\n    int param = _1981 - 1;\n    if (_1996 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2008 = _1981 > 1;\n    bool _2015;\n    if (_2008)\n    {\n        _2015 = _1996 > _1206_fa_shadow_split.x;\n    }\n    else\n    {\n        _2015 = _2008;\n    }\n    if (_2015)\n    {\n        ci = 1;\n    }\n    bool _2019 = _1981 > 2;\n    bool _2026;\n    if (_2019)\n    {\n        _2026 = _1996 > _1206_fa_shadow_split.y;\n    }\n    else\n    {\n        _2026 = _2019;\n    }\n    if (_2026)\n    {\n        ci = 2;\n    }\n    bool _2030 = _1981 > 3;\n    bool _2037;\n    if (_2030)\n    {\n        _2037 = _1996 > _1206_fa_shadow_split.z;\n    }\n    else\n    {\n        _2037 = _2030;\n    }\n    if (_2037)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1981)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2063 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2063;\n        if (_2063 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_1206_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2088;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2088 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2088 = _1206_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2107 = _1206_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2088, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2118 = clamp((_1996 - (fa_shadow_split_at(param_7) - _2107)) / _2107, 0.0f, 1.0f);\n        if (_2118 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1981)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2139 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2139;\n                if (_2139 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2118);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _1612 = _466_fa_pbr.z < 0.5f;\n    bool _1620;\n    if (!_1612)\n    {\n        _1620 = _1206_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _1620 = _1612;\n    }\n    if (_1620)\n    {\n        return 1.0f;\n    }\n    int param = (int(_1206_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _1633 = fa_light_texel(param);\n    float _1634 = _1633.x;\n    if (_1634 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _1643 = int(_1634 + 0.5f);\n    int param_1 = _1643;\n    float4 _1647 = fa_light_texel(param_1);\n    int param_2 = _1643 + 1;\n    float4 _1652 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _1655 = _1647.y;\n    if (_1655 > 0.0f)\n    {\n        float _1672 = 1.0f - smoothstep(0.75f * _1655, _1655, length(world - _1206_fa_shadow_eye.xyz));\n        fade = _1672;\n        if (_1672 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_1647.x > 1.5f)\n    {\n        int param_3 = li * 4;\n        float3 _1691 = world - fa_light_texel(param_3).xyz;\n        float3 _1694 = abs(_1691);\n        float _1696 = _1694.x;\n        float _1698 = _1694.y;\n        bool _1699 = _1696 >= _1698;\n        bool _1707;\n        if (_1699)\n        {\n            _1707 = _1696 >= _1694.z;\n        }\n        else\n        {\n            _1707 = _1699;\n        }\n        int _1708;\n        if (_1707)\n        {\n            _1708 = (_1691.x > 0.0f) ? 0 : 1;\n        }\n        else\n        {\n            int _1721;\n            if (_1698 >= _1694.z)\n            {\n                _1721 = (_1691.y > 0.0f) ? 2 : 3;\n            }\n            else\n            {\n                _1721 = (_1691.z > 0.0f) ? 4 : 5;\n            }\n            _1708 = _1721;\n        }\n        face = _1708;\n    }\n    int _1740 = (_1643 + 2) + (face * 6);\n    int param_4 = _1740;\n    int param_5 = _1740 + 1;\n    int param_6 = _1740 + 3;\n    float4 _1754 = fa_light_texel(param_6);\n    int param_7 = _1740 + 4;\n    float4 _1759 = fa_light_texel(param_7);\n    int param_8 = _1740 + 5;\n    float4 _1764 = fa_light_texel(param_8);\n    float _1776 = _1764.x * max(dot(_1754, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _1781 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1804 = clamp(dot(n, _1754.xyz), -1.0f, 1.0f);\n    int param_9 = li * 4;\n    float _1827 = min(sqrt(1.0f - (_1804 * _1804)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1754, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _1830 = _1652.y;\n    float _1832;\n    if (_1830 > 0.0f)\n    {\n        _1832 = _1830;\n    }\n    else\n    {\n        _1832 = 1.5f * _1776;\n    }\n    float4 _1852 = float4(world + (n * (_1832 * sqrt(1.0f - (_1781 * _1781)))), 1.0f);\n    float _1856 = dot(_1754, _1852);\n    float _1859 = _1764.y;\n    if (_1856 < _1859)\n    {\n        return 1.0f;\n    }\n    float2 _1874 = float2(dot(fa_light_texel(param_4), _1852), dot(fa_light_texel(param_5), _1852)) / _1856.xx;\n    float _1876 = _1874.x;\n    bool _1879 = _1876 < _1759.x;\n    bool _1888;\n    if (!_1879)\n    {\n        _1888 = _1876 > _1759.z;\n    }\n    else\n    {\n        _1888 = _1879;\n    }\n    bool _1897;\n    if (!_1888)\n    {\n        _1897 = _1874.y < _1759.y;\n    }\n    else\n    {\n        _1897 = _1888;\n    }\n    bool _1906;\n    if (!_1897)\n    {\n        _1906 = _1874.y > _1759.w;\n    }\n    else\n    {\n        _1906 = _1897;\n    }\n    if (_1906)\n    {\n        return 1.0f;\n    }\n    float _1912 = _1652.x;\n    float _1914;\n    if (_1912 > 0.0f)\n    {\n        _1914 = _1912;\n    }\n    else\n    {\n        _1914 = 1.5f * _1776;\n    }\n    float2 param_10 = _1874;\n    float4 param_11 = _1759;\n    float param_12 = _1856 - (_1914 * (1.0f + (0.5f * _1827)));\n    float param_13 = _1776;\n    float param_14 = 1.0f;\n    float param_15 = _1764.z * 0.25f;\n    float param_16 = (_1776 * min(_1827, 3.0f)) * 0.5f;\n    float3 param_17 = float3(1.0f, _1859, _1764.z);\n    int param_18 = int(_1647.z + 0.5f);\n    float param_19 = _1647.w;\n    return lerp(1.0f, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _2421 = _466_fa_ct_a.x < 0.5f;\n    bool _2428;\n    if (!_2421)\n    {\n        _2428 = _1206_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2428 = _2421;\n    }\n    if (_2428)\n    {\n        return 1.0f;\n    }\n    int param = (int(_1206_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2441 = fa_light_texel(param);\n    float _2442 = _2441.y;\n    float len = _2442;\n    if (_2442 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _2454 = length(world - _466_fa_camera_pos.xyz);\n    float _2464 = 1.0f - smoothstep(0.5f * _466_fa_ct_b.x, _466_fa_ct_b.x, _2454);\n    if (_2464 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _2470 = len;\n    float _2473 = min(_2470, 0.89999997615814208984375f * dist);\n    len = _2473;\n    float _2479 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _2454);\n    float _2484 = _2479 + (0.5f * _2473);\n    float3 _2490 = world + (gn * _2479);\n    float _2492 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _2557;\n    for (int k = 0; k < 12; k++)\n    {\n        float _2508 = (float(k) + _2492) * 0.083333335816860198974609375f;\n        float3 _2516 = _2490 + (l * (_2508 * len));\n        float4 _2522 = float4(_2516, 1.0f);\n        float _2528 = dot(_466_fa_ct_vpw, _2522);\n        if (_2528 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _2548 = float2(dot(_466_fa_ct_vpx, _2522), dot(_466_fa_ct_vpy, _2522)) / _2528.xx;\n        float _2552 = _2548.x * 0.5f;\n        float _2553 = _2552 + 0.5f;\n        if (_466_fa_ct_a.y > 0.5f)\n        {\n            _2557 = (_2548.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _2557 = 0.5f - (_2548.y * 0.5f);\n        }\n        bool _2573 = _2553 < 0.0f;\n        bool _2580;\n        if (!_2573)\n        {\n            _2580 = _2553 >= 1.0f;\n        }\n        else\n        {\n            _2580 = _2573;\n        }\n        bool _2587;\n        if (!_2580)\n        {\n            _2587 = _2557 < 0.0f;\n        }\n        else\n        {\n            _2587 = _2580;\n        }\n        bool _2594;\n        if (!_2587)\n        {\n            _2594 = _2557 >= 1.0f;\n        }\n        else\n        {\n            _2594 = _2587;\n        }\n        if (_2594)\n        {\n            break;\n        }\n        float4 _2613 = fa_screen_tex.Load(int3(int2(float2(_2553, _2557) * _466_fa_ct_a.zw), 0));\n        if (_2613.w < 0.5f)\n        {\n            continue;\n        }\n        float _2632 = (dot(_466_fa_ct_fwd.xyz, _2516) + _466_fa_ct_fwd.w) - _2613.x;\n        if ((_2632 > _2479) && (_2632 < _2484))\n        {\n            occ = max(occ, (1.0f - (_2508 * _2508)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_2553, 0.5f - _2552), min(_2557, 1.0f - _2557))));\n        }\n    }\n    return 1.0f - (occ * _2464);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _2708 = fa_lm.z > 0.5f;\n    bool _2714;\n    if (_2708)\n    {\n        int param = li;\n        _2714 = fa_light_baked(param);\n    }\n    else\n    {\n        _2714 = _2708;\n    }\n    if (_2714)\n    {\n        int param_1 = li;\n        LightSample _3808 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _3808;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _2737 = fa_light_sample(param_2, param_3);\n    float3 _3815 = _2737.direction;\n    float3 _3810 = _2737.color;\n    float _3817 = _2737.attenuation;\n    float _3812 = _2737.shadow;\n    float _3819 = _2737._distance;\n    int _3820 = _2737.type;\n    bool _2740 = _3820 == 0;\n    if (_2740 && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _3815;\n        float _2751 = fa_shadow_factor(param_4, param_5);\n        _3812 = _2751;\n        _3810 *= _2751;\n    }\n    else\n    {\n        bool _2762 = _3820 != 0;\n        bool _2768;\n        if (_2762)\n        {\n            _2768 = _3817 > 0.0f;\n        }\n        else\n        {\n            _2768 = _2762;\n        }\n        if (_2768)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _3815;\n            float _2780 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _3812 = _2780;\n            _3810 *= _2780;\n        }\n    }\n    bool _2790 = _466_fa_ct_a.x > 0.5f;\n    bool _2796;\n    if (_2790)\n    {\n        _2796 = _3817 > 0.0f;\n    }\n    else\n    {\n        _2796 = _2790;\n    }\n    if (_2796)\n    {\n        float _2803;\n        if (_2740)\n        {\n            _2803 = 1000000000.0f;\n        }\n        else\n        {\n            _2803 = _3819;\n        }\n        int param_10 = li;\n        float3 param_11 = world_pos;\n        float3 param_12 = gn;\n        float3 param_13 = _3815;\n        float param_14 = _2803;\n        float _2821 = fa_contact_shadow(param_10, param_11, param_12, param_13, param_14);\n        _3812 *= _2821;\n        _3810 *= _2821;\n    }\n    LightSample _3827 = { _3815, _3810, _3817, _3812, _3819, _3820 };\n    return _3827;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_1206_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _2163 = int(_1206_fa_shadow_cfg.x + 0.5f);\n    float _2173 = dot(world - _1206_fa_shadow_eye.xyz, _1206_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _2178 = _2163 > 0;\n    bool _2187;\n    if (_2178)\n    {\n        int param = _2163 - 1;\n        _2187 = _2173 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2187 = _2178;\n    }\n    if (_2187)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _2194 = _2163 > 1;\n        bool _2201;\n        if (_2194)\n        {\n            _2201 = _2173 > _1206_fa_shadow_split.x;\n        }\n        else\n        {\n            _2201 = _2194;\n        }\n        if (_2201)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _2207 = _2163 > 2;\n        bool _2214;\n        if (_2207)\n        {\n            _2214 = _2173 > _1206_fa_shadow_split.y;\n        }\n        else\n        {\n            _2214 = _2207;\n        }\n        if (_2214)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _2220 = _2163 > 3;\n        bool _2227;\n        if (_2220)\n        {\n            _2227 = _2173 > _1206_fa_shadow_split.z;\n        }\n        else\n        {\n            _2227 = _2220;\n        }\n        if (_2227)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _3626 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3626 = -_3626;\n    }\n    float3 _3212 = normalize(_466_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _3639 = { fa_world_pos, _3626, fa_world_tangent, fa_uv, fa_vertex_color, _3212, gl_FrontFacing };\n    SurfaceInput param_1 = _3639;\n    Surface _3220 = fa_standard_surface(param_1);\n    float3 _3665 = _3220.albedo;\n    float _3666 = _3220.alpha;\n    float3 _3667 = _3220.normal;\n    float _3668 = _3220.metallic;\n    float _3669 = _3220.roughness;\n    float _3670 = _3220.occlusion;\n    float3 _3671 = _3220.emission;\n    float _3672 = _3220.clearcoat;\n    float _3673 = _3220.clearcoat_roughness;\n    float3 _3674 = _3220.sheen_color;\n    float _3675 = _3220.sheen_roughness;\n    float _3676 = _3220.anisotropy;\n    float _3677 = _3220.anisotropy_rotation;\n    float _3678 = _3220.specular;\n    float _3679 = _3220.ior;\n    float3 _3680 = _3220.specular_color;\n    SurfaceInput _3647 = { fa_world_pos, _3626, fa_world_tangent, fa_uv, fa_vertex_color, _3212, gl_FrontFacing };\n    SurfaceInput param_2 = _3647;\n    Surface param_3 = _3220;\n    surface(param_2, param_3);\n    _3665 = param_3.albedo;\n    _3666 = param_3.alpha;\n    _3667 = param_3.normal;\n    _3668 = param_3.metallic;\n    _3669 = param_3.roughness;\n    _3670 = param_3.occlusion;\n    _3671 = param_3.emission;\n    _3672 = param_3.clearcoat;\n    _3673 = param_3.clearcoat_roughness;\n    _3674 = param_3.sheen_color;\n    _3675 = param_3.sheen_roughness;\n    _3676 = param_3.anisotropy;\n    _3677 = param_3.anisotropy_rotation;\n    _3678 = param_3.specular;\n    _3679 = param_3.ior;\n    _3680 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _3626;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _3665 = param_6;\n    _3667 = param_7;\n    float3 result;\n    if (_466_fa_emissive.w > 0.5f)\n    {\n        result = _3665;\n    }\n    else\n    {\n        float3 _3258 = _3667;\n        float3 _3259 = normalize(_3258);\n        _3667 = _3259;\n        float3 param_8 = _3259;\n        SurfaceInput _3655 = { fa_world_pos, _3626, fa_world_tangent, fa_uv, fa_vertex_color, _3212, gl_FrontFacing };\n        SurfaceInput param_9 = _3655;\n        Surface _3746 = { _3665, _3666, _3667, _3668, _3669, _3670, _3671, _3672, _3673, _3674, _3675, _3676, _3677, _3678, _3679, _3680 };\n        Surface param_10 = _3746;\n        float3 param_11 = fa_indirect_diffuse(param_8);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _3278 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3278; ln++)\n        {\n            int param_12 = ln;\n            int _3291 = fa_cl_light(param_12);\n            bool _3294 = fa_lm.z > 0.5f;\n            bool _3300;\n            if (_3294)\n            {\n                int param_13 = _3291;\n                _3300 = fa_light_baked(param_13);\n            }\n            else\n            {\n                _3300 = _3294;\n            }\n            if (_3300)\n            {\n                continue;\n            }\n            int param_14 = _3291;\n            float3 param_15 = fa_world_pos;\n            float3 param_16 = _3626;\n            SurfaceInput _3663 = { fa_world_pos, _3626, fa_world_tangent, fa_uv, fa_vertex_color, _3212, gl_FrontFacing };\n            SurfaceInput param_17 = _3663;\n            Surface _3763 = { _3665, _3666, _3667, _3668, _3669, _3670, _3671, _3672, _3673, _3674, _3675, _3676, _3677, _3678, _3679, _3680 };\n            Surface param_18 = _3763;\n            LightSample param_19 = fa_light_shadowed(param_14, param_15, param_16);\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _3327 = result;\n    float3 _3328 = _3327 + _3671;\n    result = _3328;\n    float3 param_20 = _3328;\n    float3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _3337 = _466_fa_fog.w > 0.0f;\n    bool _3344;\n    if (!_3337)\n    {\n        _3344 = _466_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _3344 = _3337;\n    }\n    if (_3344)\n    {\n        float3 _3353 = fa_world_pos - _466_fa_camera_pos.xyz;\n        float _3359 = dot(_3353, _466_fa_fog_c.xyz);\n        bool _3363 = _466_fa_fog_c.w > 0.5f;\n        float _3364;\n        if (_3363)\n        {\n            _3364 = _3359;\n        }\n        else\n        {\n            _3364 = length(_3353);\n        }\n        float _3376 = _3364 - _466_fa_fog_b.x;\n        if (_3376 > 0.0f)\n        {\n            float _3385 = _466_fa_fog.w * _3376;\n            float tau = _3385 * _3385;\n            if (_466_fa_fog_b.y > 0.0f)\n            {\n                float _3401;\n                if (_3363)\n                {\n                    _3401 = fa_world_pos.y - (_466_fa_fog_c.y * _3359);\n                }\n                else\n                {\n                    _3401 = _466_fa_camera_pos.y;\n                }\n                float _3422 = lerp(_3401, fa_world_pos.y, clamp(_466_fa_fog_b.x / _3364, 0.0f, 1.0f));\n                float _3426 = fa_world_pos.y - _3422;\n                float _3431 = _3422 - _466_fa_fog_b.z;\n                float _3436 = fa_world_pos.y - _466_fa_fog_b.z;\n                bool _3439 = _3431 <= 0.0f;\n                bool _3440 = !_3439;\n                bool _3446;\n                if (_3440)\n                {\n                    _3446 = _466_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3446 = _3439;\n                }\n                float _3447;\n                if (_3446)\n                {\n                    _3447 = _466_fa_fog_b.y;\n                }\n                else\n                {\n                    _3447 = _466_fa_fog_b.y * exp(-min(_466_fa_fog_b.w * _3431, 80.0f));\n                }\n                bool _3474;\n                if (_3440)\n                {\n                    _3474 = _466_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3474 = _3439;\n                }\n                float _3475;\n                if (_3474)\n                {\n                    _3475 = _466_fa_fog_b.y * _3431;\n                }\n                else\n                {\n                    _3475 = (_466_fa_fog_b.y * (1.0f - exp(-min(_466_fa_fog_b.w * _3431, 80.0f)))) / _466_fa_fog_b.w;\n                }\n                bool _3500 = _3436 <= 0.0f;\n                bool _3507;\n                if (!_3500)\n                {\n                    _3507 = _466_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3507 = _3500;\n                }\n                float _3508;\n                if (_3507)\n                {\n                    _3508 = _466_fa_fog_b.y * _3436;\n                }\n                else\n                {\n                    _3508 = (_466_fa_fog_b.y * (1.0f - exp(-min(_466_fa_fog_b.w * _3436, 80.0f)))) / _466_fa_fog_b.w;\n                }\n                float _3535;\n                if (abs(_3426) < 0.001000000047497451305389404296875f)\n                {\n                    _3535 = _3447;\n                }\n                else\n                {\n                    _3535 = (_3508 - _3475) / _3426;\n                }\n                tau += (_3376 * max(_3535, 0.0f));\n            }\n            result = lerp(result, _466_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _3666);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_466",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1206",
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
              "slot": 26,
              "stage": "fragment",
              "name": "fa_lightmap",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
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
          },
          {
            "texture": {
              "slot": 28,
              "stage": "fragment",
              "name": "fa_screen_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 10,
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _466_fa_camera_pos : packoffset(c0);\n    float4 _466_fa_ambient : packoffset(c1);\n    float4 _466_fa_base_color : packoffset(c2);\n    float4 _466_fa_emissive : packoffset(c3);\n    float4 _466_fa_model_emissive : packoffset(c4);\n    float4 _466_fa_pbr : packoffset(c5);\n    float4 _466_fa_maps : packoffset(c6);\n    float4 _466_fa_fog : packoffset(c7);\n    float4 _466_fa_fog_b : packoffset(c8);\n    float4 _466_fa_fog_c : packoffset(c9);\n    float4 _466_fa_counts : packoffset(c10);\n    float4 _466_fa_env_sky : packoffset(c11);\n    float4 _466_fa_env_horizon : packoffset(c12);\n    float4 _466_fa_time : packoffset(c13);\n    float4 _466_fa_cl_vpx : packoffset(c14);\n    float4 _466_fa_cl_vpy : packoffset(c15);\n    float4 _466_fa_cl_vpw : packoffset(c16);\n    float4 _466_fa_cl_fwd : packoffset(c17);\n    float4 _466_fa_cl_grid : packoffset(c18);\n    float4 _466_fa_cl_info : packoffset(c19);\n    float4 _466_fa_layers_a : packoffset(c20);\n    float4 _466_fa_layers_b : packoffset(c21);\n    float4 _466_fa_layers_c : packoffset(c22);\n    float4 _466_fa_layers_d : packoffset(c23);\n    float4 _466_fa_ct_a : packoffset(c24);\n    float4 _466_fa_ct_b : packoffset(c25);\n    float4 _466_fa_ct_vpx : packoffset(c26);\n    float4 _466_fa_ct_vpy : packoffset(c27);\n    float4 _466_fa_ct_vpw : packoffset(c28);\n    float4 _466_fa_ct_fwd : packoffset(c29);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _1206_fa_shadow_mat[4] : packoffset(c0);\n    float4 _1206_fa_shadow_rect[4] : packoffset(c16);\n    float4 _1206_fa_shadow_info[4] : packoffset(c20);\n    float4 _1206_fa_shadow_split : packoffset(c24);\n    float4 _1206_fa_shadow_cfg : packoffset(c25);\n    float4 _1206_fa_shadow_bias : packoffset(c26);\n    float4 _1206_fa_shadow_eye : packoffset(c27);\n    float4 _1206_fa_shadow_fwd : packoffset(c28);\n    float4 _1206_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_decal_tex : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_screen_tex : register(t10);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t8);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _471 = _466_fa_cl_info.x < 0.0f;\n    bool _478;\n    if (!_471)\n    {\n        _478 = _466_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _478 = _471;\n    }\n    bool _486;\n    if (!_478)\n    {\n        _486 = _466_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _486 = _478;\n    }\n    bool _493;\n    if (!_486)\n    {\n        _493 = _466_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _493 = _486;\n    }\n    bool _500;\n    if (!_493)\n    {\n        _500 = _466_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _500 = _493;\n    }\n    if (_500)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _510 = float4(world_pos, 1.0f);\n    float _517 = dot(_466_fa_cl_vpw, _510);\n    if (!(_517 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _539 = float2(dot(_466_fa_cl_vpx, _510), dot(_466_fa_cl_vpy, _510)) / _517.xx;\n    int _543 = int(_466_fa_cl_grid.x);\n    int _547 = int(_466_fa_cl_grid.y);\n    int param = (int(_466_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_466_fa_cl_fwd.xyz, world_pos) + _466_fa_cl_fwd.w, _466_fa_cl_grid.w) / _466_fa_cl_grid.w) * _466_fa_cl_grid.z)), 0, int(_466_fa_cl_info.y) - 1) * _547) + clamp(int(floor(((_539.y * 0.5f) + 0.5f) * _466_fa_cl_grid.y)), 0, _547 - 1)) * _543)) + clamp(int(floor(((_539.x * 0.5f) + 0.5f) * _466_fa_cl_grid.x)), 0, _543 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _623 = fa_cluster_texel(param);\n    return int2(int(_623.x), int(_623.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_466_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2681 = fa_cluster_lookup(param);\n    fa_cl_slot = _2681.x;\n    fa_cl_local = _2681.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _2878 = fa_linear_to_srgb(param);\n        c = _2878;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _2886 = fa_srgb_to_linear(param_1);\n            c = _2886;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _231;\n    if (i.front_facing)\n    {\n        _231 = i.world_normal;\n    }\n    else\n    {\n        _231 = -i.world_normal;\n    }\n    float3 _255 = normalize(i.world_tangent.xyz - (_231 * dot(_231, i.world_tangent.xyz)));\n    float3 _282 = normalize(((_255 * m.x) + ((cross(_231, _255) * i.world_tangent.w) * m.y)) + (_231 * m.z));\n    float3 _285;\n    if (i.front_facing)\n    {\n        _285 = _282;\n    }\n    else\n    {\n        _285 = -_282;\n    }\n    return _285;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _466_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2917 = fa_tex_fix(param_2, param_3);\n    float4 _3963 = base_t;\n    _3963.x = _2917.x;\n    _3963.y = _2917.y;\n    _3963.z = _2917.z;\n    base_t = _3963;\n    float4 _2931 = (_3963 * _466_fa_base_color) * i.vertex_color;\n    float3 _3830 = i.world_normal;\n    if (_466_fa_maps.z > 0.5f)\n    {\n        float param_4 = _466_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2963 = fa_tex_fix(param_6, param_7);\n        float3 _2966 = (_2963 * 2.0f) - 1.0f.xxx;\n        float2 _2971 = _2966.xy * _466_fa_maps.x;\n        float3 _3971 = _2966;\n        _3971.x = _2971.x;\n        _3971.y = _2971.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3971;\n        _3830 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _466_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3000 = fa_tex_fix(param_12, param_13);\n    float4 _3974 = mrt;\n    _3974.x = _3000.x;\n    _3974.y = _3000.y;\n    _3974.z = _3000.z;\n    mrt = _3974;\n    float4 _3028 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _466_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _3028.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3040 = fa_tex_fix(param_16, param_17);\n    float param_18 = _466_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3070 = fa_tex_fix(param_20, param_21);\n    float _3835 = _466_fa_layers_a.x;\n    float _3836 = _466_fa_layers_a.y;\n    float _3839 = _466_fa_layers_a.z;\n    float _3838 = _466_fa_layers_b.w;\n    float _3841 = _466_fa_layers_c.x;\n    if (_466_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_466_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _3835 *= _3040.y;\n            _3836 *= _3040.z;\n            _3838 *= _3028.w;\n        }\n        if (_466_fa_layers_c.z > 1.5f)\n        {\n            _3839 *= mrt.x;\n            _3841 *= mrt.w;\n        }\n    }\n    Surface _3860 = { _2931.xyz, _2931.w, _3830, clamp(_466_fa_pbr.x * _3000.z, 0.0f, 1.0f), clamp(_466_fa_pbr.y * _3000.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_466_fa_maps.y * (_3040.x - 1.0f)), _466_fa_emissive.xyz + (_466_fa_model_emissive.xyz * _3070), _3835, _3836, _466_fa_layers_b.xyz, _3838, _3839, _466_fa_layers_a.w, _3841, _466_fa_layers_c.y, _466_fa_layers_d.xyz };\n    return _3860;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _704 = rect.zw - rect.xy;\n    float2 _708 = _704 * atlas;\n    float2 _712 = ddx * _708;\n    float2 _716 = ddy * _708;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _704), clamp(0.5f * log2(max(max(dot(_712, _712), dot(_716, _716)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _751 = _466_fa_counts.y < 0.5f;\n    bool _758;\n    if (!_751)\n    {\n        _758 = _466_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _758 = _751;\n    }\n    if (_758)\n    {\n        return;\n    }\n    float3 _764 = ddx(world_pos);\n    float3 _767 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _771 = fa_cluster_texel(param);\n    int _775 = int(_771.w);\n    if (_775 < 1)\n    {\n        return;\n    }\n    int _785 = int(_466_fa_counts.y + 0.5f);\n    int param_1 = _785;\n    float4 _789 = fa_light_texel(param_1);\n    float2 _792 = _789.yz;\n    int _796 = int(_789.w);\n    int param_2 = _785 + 1;\n    float4 _801 = fa_light_texel(param_2);\n    float _802 = _801.x;\n    int _808 = int(_466_fa_counts.w + 0.5f) - 1;\n    int _812 = int(_771.z);\n    float3 _1078;\n    for (int k = 0; k < _775; k++)\n    {\n        int _825 = _812 + k;\n        int param_3 = _796 + (_825 >> 2);\n        int _843 = (_785 + 2) + (int(fa_light_texel(param_3)[_825 & 3]) * 7);\n        int param_4 = _843 + 6;\n        float4 _848 = fa_light_texel(param_4);\n        if (((int(_848.w + 0.5f) >> _808) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _843;\n        float4 _863 = fa_light_texel(param_5);\n        int param_6 = _843 + 1;\n        float4 _868 = fa_light_texel(param_6);\n        int param_7 = _843 + 2;\n        float4 _873 = fa_light_texel(param_7);\n        float3 _876 = _863.xyz;\n        float _881 = dot(_876, world_pos) + _863.w;\n        float3 _883 = _868.xyz;\n        float _888 = dot(_883, world_pos) + _868.w;\n        float3 _890 = _873.xyz;\n        float _895 = dot(_890, world_pos) + _873.w;\n        bool _900 = abs(_881) > 0.5f;\n        bool _908;\n        if (!_900)\n        {\n            _908 = abs(_888) > 0.5f;\n        }\n        else\n        {\n            _908 = _900;\n        }\n        bool _916;\n        if (!_908)\n        {\n            _916 = abs(_895) > 0.5f;\n        }\n        else\n        {\n            _916 = _908;\n        }\n        if (_916)\n        {\n            continue;\n        }\n        float _931 = clamp(dot(geo_normal, normalize(_890)) * _848.z, 0.0f, 1.0f);\n        if (_931 <= 0.0f)\n        {\n            continue;\n        }\n        float _951 = (clamp((0.5f - abs(_895)) * 10.0f, 0.0f, 1.0f) * _931) * _848.x;\n        float2 _959 = float2(_881 + 0.5f, 0.5f - _888);\n        float2 _969 = float2(dot(_876, _764), dot(_883, _764));\n        float2 _979 = float2(dot(_876, _767), dot(_883, _767));\n        int param_8 = _843 + 5;\n        float4 _984 = fa_light_texel(param_8);\n        int param_9 = _843 + 3;\n        float4 _989 = fa_light_texel(param_9);\n        int param_10 = _843 + 4;\n        float4 _994 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _984.xyz;\n        bool _1004 = _989.z > _989.x;\n        if (_1004)\n        {\n            float4 param_11 = _989;\n            float2 param_12 = _959;\n            float2 param_13 = _792;\n            float2 param_14 = _969;\n            float2 param_15 = _979;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_802 > 0.5f) && (_802 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1030 = fa_dc_to_linear(param_16);\n                float4 _3886 = tx;\n                _3886.x = _1030.x;\n                _3886.y = _1030.y;\n                _3886.z = _1030.z;\n                tx = _3886;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_951 * tex_a) * _984.w, 0.0f, 1.0f).xxx);\n        if (_994.z > _994.x)\n        {\n            float4 param_17 = _994;\n            float2 param_18 = _959;\n            float2 param_19 = _792;\n            float2 param_20 = _969;\n            float2 param_21 = _979;\n            float4 _1074 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_802 > 1.5f)\n            {\n                float3 param_22 = _1074.xyz;\n                float3 _1084 = fa_dc_to_srgb(param_22);\n                _1078 = _1084;\n            }\n            else\n            {\n                _1078 = _1074.xyz;\n            }\n            float3 _1094 = (_1078 * 2.0f) - 1.0f.xxx;\n            float2 _1099 = _1094.xy * _848.y;\n            float3 _1121 = (normalize(_876) * _1099.x) + (normalize(_883) * _1099.y);\n            float3 _1124 = normalize(normal);\n            normal = normalize(lerp(_1124, normalize((_1124 * max(_1094.z, 0.0500000007450580596923828125f)) + (_1121 - (_1124 * dot(_1124, _1121)))), clamp(_951 * (_1004 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_sky_sh_coef(int k)\n{\n    float3 v = fa_env_tex.SampleLevel(fa_env_smp, float3(1.0f, 1.0f - (float((2 * (k >> 2)) + 1) * 0.25f), 1.0f - (float((2 * (k & 3)) + 1) * 0.25f)), 5.0f).xyz;\n    if (_466_fa_env_sky.w > 1.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _2341 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _2341;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_466_fa_env_sky.w > 0.5f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _466_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    return float3(0.0f, ambientColor.y, 0.0f);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_466_fa_cl_info.x) + int(_466_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _341 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _347 = fa_light_texel(param_1);\n    float _350 = _347.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _356 = _350 < 0.5f;\n    float3 l;\n    if (_356)\n    {\n        l = normalize(_341.xyz);\n    }\n    else\n    {\n        float3 _368 = _341.xyz - world_pos;\n        float _370 = length(_368);\n        dist = _370;\n        l = _368 / max(_370, 9.9999997473787516355514526367188e-05f).xxx;\n        float _385 = _370 / max(_341.w, 0.001000000047497451305389404296875f);\n        float _391 = clamp(1.0f - (_385 * _385), 0.0f, 1.0f);\n        atten = _391 * _391;\n        if (_350 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _405 = fa_light_texel(param_2);\n            float _415 = _405.w;\n            int param_3 = (li * 4) + 3;\n            float4 _421 = fa_light_texel(param_3);\n            float _422 = _421.x;\n            float cos_inner = _422;\n            if (_422 > 1.5f)\n            {\n                cos_inner = lerp(_415, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_415, cos_inner, dot(-l, normalize(_405.xyz)));\n        }\n    }\n    int _452;\n    if (_356)\n    {\n        _452 = 0;\n    }\n    else\n    {\n        _452 = (_350 > 1.5f) ? 2 : 1;\n    }\n    LightSample _3795 = { l, _347.xyz * atten, atten, 1.0f, dist, _452 };\n    return _3795;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1196;\n    if (i == 0)\n    {\n        _1196 = _1206_fa_shadow_split.x;\n    }\n    else\n    {\n        float _1212;\n        if (i == 1)\n        {\n            _1212 = _1206_fa_shadow_split.y;\n        }\n        else\n        {\n            float _1220;\n            if (i == 2)\n            {\n                _1220 = _1206_fa_shadow_split.z;\n            }\n            else\n            {\n                _1220 = _1206_fa_shadow_split.w;\n            }\n            _1212 = _1220;\n        }\n        _1196 = _1212;\n    }\n    return _1196;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1253 = fa_shadow_depth(param, param_1);\n    float _1257;\n    if (conv.x < 0.5f)\n    {\n        _1257 = _1253;\n    }\n    else\n    {\n        _1257 = (conv.y * conv.z) / (conv.z - (_1253 * (conv.z - conv.y)));\n    }\n    return _1257;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1184 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_1184), sin(_1184)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1303 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _1317 = clamp((k * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1303;\n            float2 _1336 = fa_shadow_vogel(param_3, param_4, param_5) * _1317;\n            float2 param_6 = uv + (_1336 * _1206_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1348 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1348 < (zr - (length(_1336) * plane)))\n            {\n                sum += _1348;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0f) * unit) * k) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _1392 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1392; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1392;\n        float param_11 = _1303;\n        float2 _1411 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1411 * _1206_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1411) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1392);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _1453 = max(_1206_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _1458 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1464 = sqrt(1.0f - (_1458 * _1458));\n    float _1471 = min(_1464 / max(_1458, 0.20000000298023223876953125f), 4.0f);\n    float _1476;\n    if (_1206_fa_shadow_bias.y > 0.0f)\n    {\n        _1476 = _1206_fa_shadow_bias.y;\n    }\n    else\n    {\n        _1476 = 1.5f * _1206_fa_shadow_info[ci].x;\n    }\n    float4 _1501 = mul(float4(world + (n * (_1476 * _1464)), 1.0f), _1206_fa_shadow_mat[ci]);\n    float _1508 = _1501.x;\n    bool _1511 = _1508 < _1206_fa_shadow_rect[ci].x;\n    bool _1520;\n    if (!_1511)\n    {\n        _1520 = _1508 > _1206_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1520 = _1511;\n    }\n    bool _1529;\n    if (!_1520)\n    {\n        _1529 = _1501.y < _1206_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1529 = _1520;\n    }\n    bool _1538;\n    if (!_1529)\n    {\n        _1538 = _1501.y > _1206_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1538 = _1529;\n    }\n    bool _1545;\n    if (!_1538)\n    {\n        _1545 = _1501.z > 1.0f;\n    }\n    else\n    {\n        _1545 = _1538;\n    }\n    if (_1545)\n    {\n        return -1.0f;\n    }\n    float _1554;\n    if (_1206_fa_shadow_bias.x > 0.0f)\n    {\n        _1554 = _1206_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1554 = 1.5f * _1206_fa_shadow_info[ci].x;\n    }\n    float2 param = _1501.xy;\n    float4 param_1 = _1206_fa_shadow_rect[ci];\n    float param_2 = _1501.z - ((_1554 * (1.0f + (0.5f * _1471))) / _1453);\n    float param_3 = _1206_fa_shadow_info[ci].x;\n    float param_4 = _1453;\n    float param_5 = _1453 * 0.25f;\n    float param_6 = ((_1206_fa_shadow_info[ci].x * min(_1471, 3.0f)) * 0.5f) / _1453;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_1206_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _1206_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_466_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1981 = int(_1206_fa_shadow_cfg.x + 0.5f);\n    if (_1981 < 1)\n    {\n        return 1.0f;\n    }\n    float _1996 = dot(world - _1206_fa_shadow_eye.xyz, _1206_fa_shadow_fwd.xyz);\n    int param = _1981 - 1;\n    if (_1996 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2008 = _1981 > 1;\n    bool _2015;\n    if (_2008)\n    {\n        _2015 = _1996 > _1206_fa_shadow_split.x;\n    }\n    else\n    {\n        _2015 = _2008;\n    }\n    if (_2015)\n    {\n        ci = 1;\n    }\n    bool _2019 = _1981 > 2;\n    bool _2026;\n    if (_2019)\n    {\n        _2026 = _1996 > _1206_fa_shadow_split.y;\n    }\n    else\n    {\n        _2026 = _2019;\n    }\n    if (_2026)\n    {\n        ci = 2;\n    }\n    bool _2030 = _1981 > 3;\n    bool _2037;\n    if (_2030)\n    {\n        _2037 = _1996 > _1206_fa_shadow_split.z;\n    }\n    else\n    {\n        _2037 = _2030;\n    }\n    if (_2037)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1981)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2063 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2063;\n        if (_2063 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_1206_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2088;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2088 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2088 = _1206_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2107 = _1206_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2088, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2118 = clamp((_1996 - (fa_shadow_split_at(param_7) - _2107)) / _2107, 0.0f, 1.0f);\n        if (_2118 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1981)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2139 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2139;\n                if (_2139 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2118);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _1612 = _466_fa_pbr.z < 0.5f;\n    bool _1620;\n    if (!_1612)\n    {\n        _1620 = _1206_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _1620 = _1612;\n    }\n    if (_1620)\n    {\n        return 1.0f;\n    }\n    int param = (int(_1206_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _1633 = fa_light_texel(param);\n    float _1634 = _1633.x;\n    if (_1634 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _1643 = int(_1634 + 0.5f);\n    int param_1 = _1643;\n    float4 _1647 = fa_light_texel(param_1);\n    int param_2 = _1643 + 1;\n    float4 _1652 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _1655 = _1647.y;\n    if (_1655 > 0.0f)\n    {\n        float _1672 = 1.0f - smoothstep(0.75f * _1655, _1655, length(world - _1206_fa_shadow_eye.xyz));\n        fade = _1672;\n        if (_1672 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_1647.x > 1.5f)\n    {\n        int param_3 = li * 4;\n        float3 _1691 = world - fa_light_texel(param_3).xyz;\n        float3 _1694 = abs(_1691);\n        float _1696 = _1694.x;\n        float _1698 = _1694.y;\n        bool _1699 = _1696 >= _1698;\n        bool _1707;\n        if (_1699)\n        {\n            _1707 = _1696 >= _1694.z;\n        }\n        else\n        {\n            _1707 = _1699;\n        }\n        int _1708;\n        if (_1707)\n        {\n            _1708 = (_1691.x > 0.0f) ? 0 : 1;\n        }\n        else\n        {\n            int _1721;\n            if (_1698 >= _1694.z)\n            {\n                _1721 = (_1691.y > 0.0f) ? 2 : 3;\n            }\n            else\n            {\n                _1721 = (_1691.z > 0.0f) ? 4 : 5;\n            }\n            _1708 = _1721;\n        }\n        face = _1708;\n    }\n    int _1740 = (_1643 + 2) + (face * 6);\n    int param_4 = _1740;\n    int param_5 = _1740 + 1;\n    int param_6 = _1740 + 3;\n    float4 _1754 = fa_light_texel(param_6);\n    int param_7 = _1740 + 4;\n    float4 _1759 = fa_light_texel(param_7);\n    int param_8 = _1740 + 5;\n    float4 _1764 = fa_light_texel(param_8);\n    float _1776 = _1764.x * max(dot(_1754, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _1781 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1804 = clamp(dot(n, _1754.xyz), -1.0f, 1.0f);\n    int param_9 = li * 4;\n    float _1827 = min(sqrt(1.0f - (_1804 * _1804)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1754, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _1830 = _1652.y;\n    float _1832;\n    if (_1830 > 0.0f)\n    {\n        _1832 = _1830;\n    }\n    else\n    {\n        _1832 = 1.5f * _1776;\n    }\n    float4 _1852 = float4(world + (n * (_1832 * sqrt(1.0f - (_1781 * _1781)))), 1.0f);\n    float _1856 = dot(_1754, _1852);\n    float _1859 = _1764.y;\n    if (_1856 < _1859)\n    {\n        return 1.0f;\n    }\n    float2 _1874 = float2(dot(fa_light_texel(param_4), _1852), dot(fa_light_texel(param_5), _1852)) / _1856.xx;\n    float _1876 = _1874.x;\n    bool _1879 = _1876 < _1759.x;\n    bool _1888;\n    if (!_1879)\n    {\n        _1888 = _1876 > _1759.z;\n    }\n    else\n    {\n        _1888 = _1879;\n    }\n    bool _1897;\n    if (!_1888)\n    {\n        _1897 = _1874.y < _1759.y;\n    }\n    else\n    {\n        _1897 = _1888;\n    }\n    bool _1906;\n    if (!_1897)\n    {\n        _1906 = _1874.y > _1759.w;\n    }\n    else\n    {\n        _1906 = _1897;\n    }\n    if (_1906)\n    {\n        return 1.0f;\n    }\n    float _1912 = _1652.x;\n    float _1914;\n    if (_1912 > 0.0f)\n    {\n        _1914 = _1912;\n    }\n    else\n    {\n        _1914 = 1.5f * _1776;\n    }\n    float2 param_10 = _1874;\n    float4 param_11 = _1759;\n    float param_12 = _1856 - (_1914 * (1.0f + (0.5f * _1827)));\n    float param_13 = _1776;\n    float param_14 = 1.0f;\n    float param_15 = _1764.z * 0.25f;\n    float param_16 = (_1776 * min(_1827, 3.0f)) * 0.5f;\n    float3 param_17 = float3(1.0f, _1859, _1764.z);\n    int param_18 = int(_1647.z + 0.5f);\n    float param_19 = _1647.w;\n    return lerp(1.0f, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _2421 = _466_fa_ct_a.x < 0.5f;\n    bool _2428;\n    if (!_2421)\n    {\n        _2428 = _1206_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2428 = _2421;\n    }\n    if (_2428)\n    {\n        return 1.0f;\n    }\n    int param = (int(_1206_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2441 = fa_light_texel(param);\n    float _2442 = _2441.y;\n    float len = _2442;\n    if (_2442 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _2454 = length(world - _466_fa_camera_pos.xyz);\n    float _2464 = 1.0f - smoothstep(0.5f * _466_fa_ct_b.x, _466_fa_ct_b.x, _2454);\n    if (_2464 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _2470 = len;\n    float _2473 = min(_2470, 0.89999997615814208984375f * dist);\n    len = _2473;\n    float _2479 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _2454);\n    float _2484 = _2479 + (0.5f * _2473);\n    float3 _2490 = world + (gn * _2479);\n    float _2492 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _2557;\n    for (int k = 0; k < 12; k++)\n    {\n        float _2508 = (float(k) + _2492) * 0.083333335816860198974609375f;\n        float3 _2516 = _2490 + (l * (_2508 * len));\n        float4 _2522 = float4(_2516, 1.0f);\n        float _2528 = dot(_466_fa_ct_vpw, _2522);\n        if (_2528 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _2548 = float2(dot(_466_fa_ct_vpx, _2522), dot(_466_fa_ct_vpy, _2522)) / _2528.xx;\n        float _2552 = _2548.x * 0.5f;\n        float _2553 = _2552 + 0.5f;\n        if (_466_fa_ct_a.y > 0.5f)\n        {\n            _2557 = (_2548.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _2557 = 0.5f - (_2548.y * 0.5f);\n        }\n        bool _2573 = _2553 < 0.0f;\n        bool _2580;\n        if (!_2573)\n        {\n            _2580 = _2553 >= 1.0f;\n        }\n        else\n        {\n            _2580 = _2573;\n        }\n        bool _2587;\n        if (!_2580)\n        {\n            _2587 = _2557 < 0.0f;\n        }\n        else\n        {\n            _2587 = _2580;\n        }\n        bool _2594;\n        if (!_2587)\n        {\n            _2594 = _2557 >= 1.0f;\n        }\n        else\n        {\n            _2594 = _2587;\n        }\n        if (_2594)\n        {\n            break;\n        }\n        float4 _2613 = fa_screen_tex.Load(int3(int2(float2(_2553, _2557) * _466_fa_ct_a.zw), 0));\n        if (_2613.w < 0.5f)\n        {\n            continue;\n        }\n        float _2632 = (dot(_466_fa_ct_fwd.xyz, _2516) + _466_fa_ct_fwd.w) - _2613.x;\n        if ((_2632 > _2479) && (_2632 < _2484))\n        {\n            occ = max(occ, (1.0f - (_2508 * _2508)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_2553, 0.5f - _2552), min(_2557, 1.0f - _2557))));\n        }\n    }\n    return 1.0f - (occ * _2464);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _2708 = fa_lm.z > 0.5f;\n    bool _2714;\n    if (_2708)\n    {\n        int param = li;\n        _2714 = fa_light_baked(param);\n    }\n    else\n    {\n        _2714 = _2708;\n    }\n    if (_2714)\n    {\n        int param_1 = li;\n        LightSample _3808 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _3808;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _2737 = fa_light_sample(param_2, param_3);\n    float3 _3815 = _2737.direction;\n    float3 _3810 = _2737.color;\n    float _3817 = _2737.attenuation;\n    float _3812 = _2737.shadow;\n    float _3819 = _2737._distance;\n    int _3820 = _2737.type;\n    bool _2740 = _3820 == 0;\n    if (_2740 && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _3815;\n        float _2751 = fa_shadow_factor(param_4, param_5);\n        _3812 = _2751;\n        _3810 *= _2751;\n    }\n    else\n    {\n        bool _2762 = _3820 != 0;\n        bool _2768;\n        if (_2762)\n        {\n            _2768 = _3817 > 0.0f;\n        }\n        else\n        {\n            _2768 = _2762;\n        }\n        if (_2768)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _3815;\n            float _2780 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _3812 = _2780;\n            _3810 *= _2780;\n        }\n    }\n    bool _2790 = _466_fa_ct_a.x > 0.5f;\n    bool _2796;\n    if (_2790)\n    {\n        _2796 = _3817 > 0.0f;\n    }\n    else\n    {\n        _2796 = _2790;\n    }\n    if (_2796)\n    {\n        float _2803;\n        if (_2740)\n        {\n            _2803 = 1000000000.0f;\n        }\n        else\n        {\n            _2803 = _3819;\n        }\n        int param_10 = li;\n        float3 param_11 = world_pos;\n        float3 param_12 = gn;\n        float3 param_13 = _3815;\n        float param_14 = _2803;\n        float _2821 = fa_contact_shadow(param_10, param_11, param_12, param_13, param_14);\n        _3812 *= _2821;\n        _3810 *= _2821;\n    }\n    LightSample _3827 = { _3815, _3810, _3817, _3812, _3819, _3820 };\n    return _3827;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_1206_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _2163 = int(_1206_fa_shadow_cfg.x + 0.5f);\n    float _2173 = dot(world - _1206_fa_shadow_eye.xyz, _1206_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _2178 = _2163 > 0;\n    bool _2187;\n    if (_2178)\n    {\n        int param = _2163 - 1;\n        _2187 = _2173 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2187 = _2178;\n    }\n    if (_2187)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _2194 = _2163 > 1;\n        bool _2201;\n        if (_2194)\n        {\n            _2201 = _2173 > _1206_fa_shadow_split.x;\n        }\n        else\n        {\n            _2201 = _2194;\n        }\n        if (_2201)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _2207 = _2163 > 2;\n        bool _2214;\n        if (_2207)\n        {\n            _2214 = _2173 > _1206_fa_shadow_split.y;\n        }\n        else\n        {\n            _2214 = _2207;\n        }\n        if (_2214)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _2220 = _2163 > 3;\n        bool _2227;\n        if (_2220)\n        {\n            _2227 = _2173 > _1206_fa_shadow_split.z;\n        }\n        else\n        {\n            _2227 = _2220;\n        }\n        if (_2227)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _3626 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3626 = -_3626;\n    }\n    float3 _3212 = normalize(_466_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _3639 = { fa_world_pos, _3626, fa_world_tangent, fa_uv, fa_vertex_color, _3212, gl_FrontFacing };\n    SurfaceInput param_1 = _3639;\n    Surface _3220 = fa_standard_surface(param_1);\n    float3 _3665 = _3220.albedo;\n    float _3666 = _3220.alpha;\n    float3 _3667 = _3220.normal;\n    float _3668 = _3220.metallic;\n    float _3669 = _3220.roughness;\n    float _3670 = _3220.occlusion;\n    float3 _3671 = _3220.emission;\n    float _3672 = _3220.clearcoat;\n    float _3673 = _3220.clearcoat_roughness;\n    float3 _3674 = _3220.sheen_color;\n    float _3675 = _3220.sheen_roughness;\n    float _3676 = _3220.anisotropy;\n    float _3677 = _3220.anisotropy_rotation;\n    float _3678 = _3220.specular;\n    float _3679 = _3220.ior;\n    float3 _3680 = _3220.specular_color;\n    SurfaceInput _3647 = { fa_world_pos, _3626, fa_world_tangent, fa_uv, fa_vertex_color, _3212, gl_FrontFacing };\n    SurfaceInput param_2 = _3647;\n    Surface param_3 = _3220;\n    surface(param_2, param_3);\n    _3665 = param_3.albedo;\n    _3666 = param_3.alpha;\n    _3667 = param_3.normal;\n    _3668 = param_3.metallic;\n    _3669 = param_3.roughness;\n    _3670 = param_3.occlusion;\n    _3671 = param_3.emission;\n    _3672 = param_3.clearcoat;\n    _3673 = param_3.clearcoat_roughness;\n    _3674 = param_3.sheen_color;\n    _3675 = param_3.sheen_roughness;\n    _3676 = param_3.anisotropy;\n    _3677 = param_3.anisotropy_rotation;\n    _3678 = param_3.specular;\n    _3679 = param_3.ior;\n    _3680 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _3626;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _3665 = param_6;\n    _3667 = param_7;\n    float3 result;\n    if (_466_fa_emissive.w > 0.5f)\n    {\n        result = _3665;\n    }\n    else\n    {\n        float3 _3258 = _3667;\n        float3 _3259 = normalize(_3258);\n        _3667 = _3259;\n        float3 param_8 = _3259;\n        SurfaceInput _3655 = { fa_world_pos, _3626, fa_world_tangent, fa_uv, fa_vertex_color, _3212, gl_FrontFacing };\n        SurfaceInput param_9 = _3655;\n        Surface _3746 = { _3665, _3666, _3667, _3668, _3669, _3670, _3671, _3672, _3673, _3674, _3675, _3676, _3677, _3678, _3679, _3680 };\n        Surface param_10 = _3746;\n        float3 param_11 = fa_indirect_diffuse(param_8);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _3278 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3278; ln++)\n        {\n            int param_12 = ln;\n            int _3291 = fa_cl_light(param_12);\n            bool _3294 = fa_lm.z > 0.5f;\n            bool _3300;\n            if (_3294)\n            {\n                int param_13 = _3291;\n                _3300 = fa_light_baked(param_13);\n            }\n            else\n            {\n                _3300 = _3294;\n            }\n            if (_3300)\n            {\n                continue;\n            }\n            int param_14 = _3291;\n            float3 param_15 = fa_world_pos;\n            float3 param_16 = _3626;\n            SurfaceInput _3663 = { fa_world_pos, _3626, fa_world_tangent, fa_uv, fa_vertex_color, _3212, gl_FrontFacing };\n            SurfaceInput param_17 = _3663;\n            Surface _3763 = { _3665, _3666, _3667, _3668, _3669, _3670, _3671, _3672, _3673, _3674, _3675, _3676, _3677, _3678, _3679, _3680 };\n            Surface param_18 = _3763;\n            LightSample param_19 = fa_light_shadowed(param_14, param_15, param_16);\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _3327 = result;\n    float3 _3328 = _3327 + _3671;\n    result = _3328;\n    float3 param_20 = _3328;\n    float3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _3337 = _466_fa_fog.w > 0.0f;\n    bool _3344;\n    if (!_3337)\n    {\n        _3344 = _466_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _3344 = _3337;\n    }\n    if (_3344)\n    {\n        float3 _3353 = fa_world_pos - _466_fa_camera_pos.xyz;\n        float _3359 = dot(_3353, _466_fa_fog_c.xyz);\n        bool _3363 = _466_fa_fog_c.w > 0.5f;\n        float _3364;\n        if (_3363)\n        {\n            _3364 = _3359;\n        }\n        else\n        {\n            _3364 = length(_3353);\n        }\n        float _3376 = _3364 - _466_fa_fog_b.x;\n        if (_3376 > 0.0f)\n        {\n            float _3385 = _466_fa_fog.w * _3376;\n            float tau = _3385 * _3385;\n            if (_466_fa_fog_b.y > 0.0f)\n            {\n                float _3401;\n                if (_3363)\n                {\n                    _3401 = fa_world_pos.y - (_466_fa_fog_c.y * _3359);\n                }\n                else\n                {\n                    _3401 = _466_fa_camera_pos.y;\n                }\n                float _3422 = lerp(_3401, fa_world_pos.y, clamp(_466_fa_fog_b.x / _3364, 0.0f, 1.0f));\n                float _3426 = fa_world_pos.y - _3422;\n                float _3431 = _3422 - _466_fa_fog_b.z;\n                float _3436 = fa_world_pos.y - _466_fa_fog_b.z;\n                bool _3439 = _3431 <= 0.0f;\n                bool _3440 = !_3439;\n                bool _3446;\n                if (_3440)\n                {\n                    _3446 = _466_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3446 = _3439;\n                }\n                float _3447;\n                if (_3446)\n                {\n                    _3447 = _466_fa_fog_b.y;\n                }\n                else\n                {\n                    _3447 = _466_fa_fog_b.y * exp(-min(_466_fa_fog_b.w * _3431, 80.0f));\n                }\n                bool _3474;\n                if (_3440)\n                {\n                    _3474 = _466_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3474 = _3439;\n                }\n                float _3475;\n                if (_3474)\n                {\n                    _3475 = _466_fa_fog_b.y * _3431;\n                }\n                else\n                {\n                    _3475 = (_466_fa_fog_b.y * (1.0f - exp(-min(_466_fa_fog_b.w * _3431, 80.0f)))) / _466_fa_fog_b.w;\n                }\n                bool _3500 = _3436 <= 0.0f;\n                bool _3507;\n                if (!_3500)\n                {\n                    _3507 = _466_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3507 = _3500;\n                }\n                float _3508;\n                if (_3507)\n                {\n                    _3508 = _466_fa_fog_b.y * _3436;\n                }\n                else\n                {\n                    _3508 = (_466_fa_fog_b.y * (1.0f - exp(-min(_466_fa_fog_b.w * _3436, 80.0f)))) / _466_fa_fog_b.w;\n                }\n                float _3535;\n                if (abs(_3426) < 0.001000000047497451305389404296875f)\n                {\n                    _3535 = _3447;\n                }\n                else\n                {\n                    _3535 = (_3508 - _3475) / _3426;\n                }\n                tau += (_3376 * max(_3535, 0.0f));\n            }\n            result = lerp(result, _466_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _3666);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_466",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1206",
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
              "slot": 26,
              "stage": "fragment",
              "name": "fa_lightmap",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
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
          },
          {
            "texture": {
              "slot": 28,
              "stage": "fragment",
              "name": "fa_screen_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 10,
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n    float4 _213_fa_ct_a : packoffset(c24);\n    float4 _213_fa_ct_b : packoffset(c25);\n    float4 _213_fa_ct_vpx : packoffset(c26);\n    float4 _213_fa_ct_vpy : packoffset(c27);\n    float4 _213_fa_ct_vpw : packoffset(c28);\n    float4 _213_fa_ct_fwd : packoffset(c29);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _784 = base_t;\n    _784.x = _225.x;\n    _784.y = _225.y;\n    _784.z = _225.z;\n    base_t = _784;\n    float4 _241 = (_784 * _213_fa_base_color) * i.vertex_color;\n    float3 _747 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _792 = _279;\n        _792.x = _284.x;\n        _792.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _792;\n        _747 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _795 = mrt;\n    _795.x = _313.x;\n    _795.y = _313.y;\n    _795.z = _313.z;\n    mrt = _795;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _752 = _213_fa_layers_a.x;\n    float _753 = _213_fa_layers_a.y;\n    float _756 = _213_fa_layers_a.z;\n    float _755 = _213_fa_layers_b.w;\n    float _758 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _752 *= _355.y;\n            _753 *= _355.z;\n            _755 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _756 *= mrt.x;\n            _758 *= mrt.w;\n        }\n    }\n    Surface _777 = { _241.xyz, _241.w, _747, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _752, _753, _213_fa_layers_b.xyz, _755, _756, _213_fa_layers_a.w, _758, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _777;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _658 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _658 = -_658;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _671 = { fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _671;\n    SurfaceInput _679 = { fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _679;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 480,
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n    float4 _213_fa_ct_a : packoffset(c24);\n    float4 _213_fa_ct_b : packoffset(c25);\n    float4 _213_fa_ct_vpx : packoffset(c26);\n    float4 _213_fa_ct_vpy : packoffset(c27);\n    float4 _213_fa_ct_vpw : packoffset(c28);\n    float4 _213_fa_ct_fwd : packoffset(c29);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _784 = base_t;\n    _784.x = _225.x;\n    _784.y = _225.y;\n    _784.z = _225.z;\n    base_t = _784;\n    float4 _241 = (_784 * _213_fa_base_color) * i.vertex_color;\n    float3 _747 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _792 = _279;\n        _792.x = _284.x;\n        _792.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _792;\n        _747 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _795 = mrt;\n    _795.x = _313.x;\n    _795.y = _313.y;\n    _795.z = _313.z;\n    mrt = _795;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _752 = _213_fa_layers_a.x;\n    float _753 = _213_fa_layers_a.y;\n    float _756 = _213_fa_layers_a.z;\n    float _755 = _213_fa_layers_b.w;\n    float _758 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _752 *= _355.y;\n            _753 *= _355.z;\n            _755 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _756 *= mrt.x;\n            _758 *= mrt.w;\n        }\n    }\n    Surface _777 = { _241.xyz, _241.w, _747, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _752, _753, _213_fa_layers_b.xyz, _755, _756, _213_fa_layers_a.w, _758, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _777;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _658 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _658 = -_658;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _671 = { fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _671;\n    SurfaceInput _679 = { fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _679;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 480,
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
