{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "5c278b25d8ce4341984c8bf2a53e1ca7890b6a924713889b53c089df056597d0",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _260 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _260;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_267, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _452_fa_camera_pos : packoffset(c0);\n    float4 _452_fa_ambient : packoffset(c1);\n    float4 _452_fa_base_color : packoffset(c2);\n    float4 _452_fa_emissive : packoffset(c3);\n    float4 _452_fa_model_emissive : packoffset(c4);\n    float4 _452_fa_pbr : packoffset(c5);\n    float4 _452_fa_maps : packoffset(c6);\n    float4 _452_fa_fog : packoffset(c7);\n    float4 _452_fa_fog_b : packoffset(c8);\n    float4 _452_fa_fog_c : packoffset(c9);\n    float4 _452_fa_counts : packoffset(c10);\n    float4 _452_fa_env_sky : packoffset(c11);\n    float4 _452_fa_env_horizon : packoffset(c12);\n    float4 _452_fa_time : packoffset(c13);\n    float4 _452_fa_cl_vpx : packoffset(c14);\n    float4 _452_fa_cl_vpy : packoffset(c15);\n    float4 _452_fa_cl_vpw : packoffset(c16);\n    float4 _452_fa_cl_fwd : packoffset(c17);\n    float4 _452_fa_cl_grid : packoffset(c18);\n    float4 _452_fa_cl_info : packoffset(c19);\n    float4 _452_fa_layers_a : packoffset(c20);\n    float4 _452_fa_layers_b : packoffset(c21);\n    float4 _452_fa_layers_c : packoffset(c22);\n    float4 _452_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _1192_fa_shadow_mat[4] : packoffset(c0);\n    float4 _1192_fa_shadow_rect[4] : packoffset(c16);\n    float4 _1192_fa_shadow_info[4] : packoffset(c20);\n    float4 _1192_fa_shadow_split : packoffset(c24);\n    float4 _1192_fa_shadow_cfg : packoffset(c25);\n    float4 _1192_fa_shadow_bias : packoffset(c26);\n    float4 _1192_fa_shadow_eye : packoffset(c27);\n    float4 _1192_fa_shadow_fwd : packoffset(c28);\n    float4 _1192_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_decal_tex : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t8);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _457 = _452_fa_cl_info.x < 0.0f;\n    bool _464;\n    if (!_457)\n    {\n        _464 = _452_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _464 = _457;\n    }\n    bool _472;\n    if (!_464)\n    {\n        _472 = _452_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _472 = _464;\n    }\n    bool _479;\n    if (!_472)\n    {\n        _479 = _452_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _479 = _472;\n    }\n    bool _486;\n    if (!_479)\n    {\n        _486 = _452_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _486 = _479;\n    }\n    if (_486)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _496 = float4(world_pos, 1.0f);\n    float _503 = dot(_452_fa_cl_vpw, _496);\n    if (!(_503 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _525 = float2(dot(_452_fa_cl_vpx, _496), dot(_452_fa_cl_vpy, _496)) / _503.xx;\n    int _529 = int(_452_fa_cl_grid.x);\n    int _533 = int(_452_fa_cl_grid.y);\n    int param = (int(_452_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_452_fa_cl_fwd.xyz, world_pos) + _452_fa_cl_fwd.w, _452_fa_cl_grid.w) / _452_fa_cl_grid.w) * _452_fa_cl_grid.z)), 0, int(_452_fa_cl_info.y) - 1) * _533) + clamp(int(floor(((_525.y * 0.5f) + 0.5f) * _452_fa_cl_grid.y)), 0, _533 - 1)) * _529)) + clamp(int(floor(((_525.x * 0.5f) + 0.5f) * _452_fa_cl_grid.x)), 0, _529 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _609 = fa_cluster_texel(param);\n    return int2(int(_609.x), int(_609.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_452_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2414 = fa_cluster_lookup(param);\n    fa_cl_slot = _2414.x;\n    fa_cl_local = _2414.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _2562 = fa_linear_to_srgb(param);\n        c = _2562;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _2570 = fa_srgb_to_linear(param_1);\n            c = _2570;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _217;\n    if (i.front_facing)\n    {\n        _217 = i.world_normal;\n    }\n    else\n    {\n        _217 = -i.world_normal;\n    }\n    float3 _241 = normalize(i.world_tangent.xyz - (_217 * dot(_217, i.world_tangent.xyz)));\n    float3 _268 = normalize(((_241 * m.x) + ((cross(_217, _241) * i.world_tangent.w) * m.y)) + (_217 * m.z));\n    float3 _271;\n    if (i.front_facing)\n    {\n        _271 = _268;\n    }\n    else\n    {\n        _271 = -_268;\n    }\n    return _271;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _452_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2601 = fa_tex_fix(param_2, param_3);\n    float4 _3611 = base_t;\n    _3611.x = _2601.x;\n    _3611.y = _2601.y;\n    _3611.z = _2601.z;\n    base_t = _3611;\n    float4 _2615 = (_3611 * _452_fa_base_color) * i.vertex_color;\n    float3 _3491 = i.world_normal;\n    if (_452_fa_maps.z > 0.5f)\n    {\n        float param_4 = _452_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2647 = fa_tex_fix(param_6, param_7);\n        float3 _2650 = (_2647 * 2.0f) - 1.0f.xxx;\n        float2 _2655 = _2650.xy * _452_fa_maps.x;\n        float3 _3619 = _2650;\n        _3619.x = _2655.x;\n        _3619.y = _2655.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3619;\n        _3491 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _452_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2684 = fa_tex_fix(param_12, param_13);\n    float4 _3622 = mrt;\n    _3622.x = _2684.x;\n    _3622.y = _2684.y;\n    _3622.z = _2684.z;\n    mrt = _3622;\n    float4 _2712 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _452_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _2712.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2724 = fa_tex_fix(param_16, param_17);\n    float param_18 = _452_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2754 = fa_tex_fix(param_20, param_21);\n    float _3496 = _452_fa_layers_a.x;\n    float _3497 = _452_fa_layers_a.y;\n    float _3500 = _452_fa_layers_a.z;\n    float _3499 = _452_fa_layers_b.w;\n    float _3502 = _452_fa_layers_c.x;\n    if (_452_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_452_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _3496 *= _2724.y;\n            _3497 *= _2724.z;\n            _3499 *= _2712.w;\n        }\n        if (_452_fa_layers_c.z > 1.5f)\n        {\n            _3500 *= mrt.x;\n            _3502 *= mrt.w;\n        }\n    }\n    Surface _3521 = { _2615.xyz, _2615.w, _3491, clamp(_452_fa_pbr.x * _2684.z, 0.0f, 1.0f), clamp(_452_fa_pbr.y * _2684.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_452_fa_maps.y * (_2724.x - 1.0f)), _452_fa_emissive.xyz + (_452_fa_model_emissive.xyz * _2754), _3496, _3497, _452_fa_layers_b.xyz, _3499, _3500, _452_fa_layers_a.w, _3502, _452_fa_layers_c.y, _452_fa_layers_d.xyz };\n    return _3521;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _690 = rect.zw - rect.xy;\n    float2 _694 = _690 * atlas;\n    float2 _698 = ddx * _694;\n    float2 _702 = ddy * _694;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _690), clamp(0.5f * log2(max(max(dot(_698, _698), dot(_702, _702)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _737 = _452_fa_counts.y < 0.5f;\n    bool _744;\n    if (!_737)\n    {\n        _744 = _452_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _744 = _737;\n    }\n    if (_744)\n    {\n        return;\n    }\n    float3 _750 = ddx(world_pos);\n    float3 _753 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _757 = fa_cluster_texel(param);\n    int _761 = int(_757.w);\n    if (_761 < 1)\n    {\n        return;\n    }\n    int _771 = int(_452_fa_counts.y + 0.5f);\n    int param_1 = _771;\n    float4 _775 = fa_light_texel(param_1);\n    float2 _778 = _775.yz;\n    int _782 = int(_775.w);\n    int param_2 = _771 + 1;\n    float4 _787 = fa_light_texel(param_2);\n    float _788 = _787.x;\n    int _794 = int(_452_fa_counts.w + 0.5f) - 1;\n    int _798 = int(_757.z);\n    float3 _1064;\n    for (int k = 0; k < _761; k++)\n    {\n        int _811 = _798 + k;\n        int param_3 = _782 + (_811 >> 2);\n        int _829 = (_771 + 2) + (int(fa_light_texel(param_3)[_811 & 3]) * 7);\n        int param_4 = _829 + 6;\n        float4 _834 = fa_light_texel(param_4);\n        if (((int(_834.w + 0.5f) >> _794) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _829;\n        float4 _849 = fa_light_texel(param_5);\n        int param_6 = _829 + 1;\n        float4 _854 = fa_light_texel(param_6);\n        int param_7 = _829 + 2;\n        float4 _859 = fa_light_texel(param_7);\n        float3 _862 = _849.xyz;\n        float _867 = dot(_862, world_pos) + _849.w;\n        float3 _869 = _854.xyz;\n        float _874 = dot(_869, world_pos) + _854.w;\n        float3 _876 = _859.xyz;\n        float _881 = dot(_876, world_pos) + _859.w;\n        bool _886 = abs(_867) > 0.5f;\n        bool _894;\n        if (!_886)\n        {\n            _894 = abs(_874) > 0.5f;\n        }\n        else\n        {\n            _894 = _886;\n        }\n        bool _902;\n        if (!_894)\n        {\n            _902 = abs(_881) > 0.5f;\n        }\n        else\n        {\n            _902 = _894;\n        }\n        if (_902)\n        {\n            continue;\n        }\n        float _917 = clamp(dot(geo_normal, normalize(_876)) * _834.z, 0.0f, 1.0f);\n        if (_917 <= 0.0f)\n        {\n            continue;\n        }\n        float _937 = (clamp((0.5f - abs(_881)) * 10.0f, 0.0f, 1.0f) * _917) * _834.x;\n        float2 _945 = float2(_867 + 0.5f, 0.5f - _874);\n        float2 _955 = float2(dot(_862, _750), dot(_869, _750));\n        float2 _965 = float2(dot(_862, _753), dot(_869, _753));\n        int param_8 = _829 + 5;\n        float4 _970 = fa_light_texel(param_8);\n        int param_9 = _829 + 3;\n        float4 _975 = fa_light_texel(param_9);\n        int param_10 = _829 + 4;\n        float4 _980 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _970.xyz;\n        bool _990 = _975.z > _975.x;\n        if (_990)\n        {\n            float4 param_11 = _975;\n            float2 param_12 = _945;\n            float2 param_13 = _778;\n            float2 param_14 = _955;\n            float2 param_15 = _965;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_788 > 0.5f) && (_788 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1016 = fa_dc_to_linear(param_16);\n                float4 _3547 = tx;\n                _3547.x = _1016.x;\n                _3547.y = _1016.y;\n                _3547.z = _1016.z;\n                tx = _3547;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_937 * tex_a) * _970.w, 0.0f, 1.0f).xxx);\n        if (_980.z > _980.x)\n        {\n            float4 param_17 = _980;\n            float2 param_18 = _945;\n            float2 param_19 = _778;\n            float2 param_20 = _955;\n            float2 param_21 = _965;\n            float4 _1060 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_788 > 1.5f)\n            {\n                float3 param_22 = _1060.xyz;\n                float3 _1070 = fa_dc_to_srgb(param_22);\n                _1064 = _1070;\n            }\n            else\n            {\n                _1064 = _1060.xyz;\n            }\n            float3 _1080 = (_1064 * 2.0f) - 1.0f.xxx;\n            float2 _1085 = _1080.xy * _834.y;\n            float3 _1107 = (normalize(_862) * _1085.x) + (normalize(_869) * _1085.y);\n            float3 _1110 = normalize(normal);\n            normal = normalize(lerp(_1110, normalize((_1110 * max(_1080.z, 0.0500000007450580596923828125f)) + (_1107 - (_1110 * dot(_1110, _1107)))), clamp(_937 * (_990 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_sky_sh_coef(int k)\n{\n    float3 v = fa_env_tex.SampleLevel(fa_env_smp, float3(1.0f, 1.0f - (float((2 * (k >> 2)) + 1) * 0.25f), 1.0f - (float((2 * (k & 3)) + 1) * 0.25f)), 5.0f).xyz;\n    if (_452_fa_env_sky.w > 1.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _2327 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _2327;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_452_fa_env_sky.w > 0.5f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _452_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_452_fa_cl_info.x) + int(_452_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _327 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _333 = fa_light_texel(param_1);\n    float _336 = _333.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _342 = _336 < 0.5f;\n    float3 l;\n    if (_342)\n    {\n        l = normalize(_327.xyz);\n    }\n    else\n    {\n        float3 _354 = _327.xyz - world_pos;\n        float _356 = length(_354);\n        dist = _356;\n        l = _354 / max(_356, 9.9999997473787516355514526367188e-05f).xxx;\n        float _371 = _356 / max(_327.w, 0.001000000047497451305389404296875f);\n        float _377 = clamp(1.0f - (_371 * _371), 0.0f, 1.0f);\n        atten = _377 * _377;\n        if (_336 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _391 = fa_light_texel(param_2);\n            float _401 = _391.w;\n            int param_3 = (li * 4) + 3;\n            float4 _407 = fa_light_texel(param_3);\n            float _408 = _407.x;\n            float cos_inner = _408;\n            if (_408 > 1.5f)\n            {\n                cos_inner = lerp(_401, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_401, cos_inner, dot(-l, normalize(_391.xyz)));\n        }\n    }\n    int _438;\n    if (_342)\n    {\n        _438 = 0;\n    }\n    else\n    {\n        _438 = (_336 > 1.5f) ? 2 : 1;\n    }\n    LightSample _3456 = { l, _333.xyz * atten, atten, 1.0f, dist, _438 };\n    return _3456;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1182;\n    if (i == 0)\n    {\n        _1182 = _1192_fa_shadow_split.x;\n    }\n    else\n    {\n        float _1198;\n        if (i == 1)\n        {\n            _1198 = _1192_fa_shadow_split.y;\n        }\n        else\n        {\n            float _1206;\n            if (i == 2)\n            {\n                _1206 = _1192_fa_shadow_split.z;\n            }\n            else\n            {\n                _1206 = _1192_fa_shadow_split.w;\n            }\n            _1198 = _1206;\n        }\n        _1182 = _1198;\n    }\n    return _1182;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1239 = fa_shadow_depth(param, param_1);\n    float _1243;\n    if (conv.x < 0.5f)\n    {\n        _1243 = _1239;\n    }\n    else\n    {\n        _1243 = (conv.y * conv.z) / (conv.z - (_1239 * (conv.z - conv.y)));\n    }\n    return _1243;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1170 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_1170), sin(_1170)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1289 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _1303 = clamp((k * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1289;\n            float2 _1322 = fa_shadow_vogel(param_3, param_4, param_5) * _1303;\n            float2 param_6 = uv + (_1322 * _1192_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1334 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1334 < (zr - (length(_1322) * plane)))\n            {\n                sum += _1334;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0f) * unit) * k) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _1378 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1378; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1378;\n        float param_11 = _1289;\n        float2 _1397 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1397 * _1192_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1397) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1378);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _1439 = max(_1192_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _1444 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1450 = sqrt(1.0f - (_1444 * _1444));\n    float _1457 = min(_1450 / max(_1444, 0.20000000298023223876953125f), 4.0f);\n    float _1462;\n    if (_1192_fa_shadow_bias.y > 0.0f)\n    {\n        _1462 = _1192_fa_shadow_bias.y;\n    }\n    else\n    {\n        _1462 = 1.5f * _1192_fa_shadow_info[ci].x;\n    }\n    float4 _1487 = mul(float4(world + (n * (_1462 * _1450)), 1.0f), _1192_fa_shadow_mat[ci]);\n    float _1494 = _1487.x;\n    bool _1497 = _1494 < _1192_fa_shadow_rect[ci].x;\n    bool _1506;\n    if (!_1497)\n    {\n        _1506 = _1494 > _1192_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1506 = _1497;\n    }\n    bool _1515;\n    if (!_1506)\n    {\n        _1515 = _1487.y < _1192_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1515 = _1506;\n    }\n    bool _1524;\n    if (!_1515)\n    {\n        _1524 = _1487.y > _1192_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1524 = _1515;\n    }\n    bool _1531;\n    if (!_1524)\n    {\n        _1531 = _1487.z > 1.0f;\n    }\n    else\n    {\n        _1531 = _1524;\n    }\n    if (_1531)\n    {\n        return -1.0f;\n    }\n    float _1540;\n    if (_1192_fa_shadow_bias.x > 0.0f)\n    {\n        _1540 = _1192_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1540 = 1.5f * _1192_fa_shadow_info[ci].x;\n    }\n    float2 param = _1487.xy;\n    float4 param_1 = _1192_fa_shadow_rect[ci];\n    float param_2 = _1487.z - ((_1540 * (1.0f + (0.5f * _1457))) / _1439);\n    float param_3 = _1192_fa_shadow_info[ci].x;\n    float param_4 = _1439;\n    float param_5 = _1439 * 0.25f;\n    float param_6 = ((_1192_fa_shadow_info[ci].x * min(_1457, 3.0f)) * 0.5f) / _1439;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_1192_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _1192_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_452_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1967 = int(_1192_fa_shadow_cfg.x + 0.5f);\n    if (_1967 < 1)\n    {\n        return 1.0f;\n    }\n    float _1982 = dot(world - _1192_fa_shadow_eye.xyz, _1192_fa_shadow_fwd.xyz);\n    int param = _1967 - 1;\n    if (_1982 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1994 = _1967 > 1;\n    bool _2001;\n    if (_1994)\n    {\n        _2001 = _1982 > _1192_fa_shadow_split.x;\n    }\n    else\n    {\n        _2001 = _1994;\n    }\n    if (_2001)\n    {\n        ci = 1;\n    }\n    bool _2005 = _1967 > 2;\n    bool _2012;\n    if (_2005)\n    {\n        _2012 = _1982 > _1192_fa_shadow_split.y;\n    }\n    else\n    {\n        _2012 = _2005;\n    }\n    if (_2012)\n    {\n        ci = 2;\n    }\n    bool _2016 = _1967 > 3;\n    bool _2023;\n    if (_2016)\n    {\n        _2023 = _1982 > _1192_fa_shadow_split.z;\n    }\n    else\n    {\n        _2023 = _2016;\n    }\n    if (_2023)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1967)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2049 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2049;\n        if (_2049 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_1192_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2074;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2074 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2074 = _1192_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2093 = _1192_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2074, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2104 = clamp((_1982 - (fa_shadow_split_at(param_7) - _2093)) / _2093, 0.0f, 1.0f);\n        if (_2104 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1967)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2125 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2125;\n                if (_2125 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2104);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _1598 = _452_fa_pbr.z < 0.5f;\n    bool _1606;\n    if (!_1598)\n    {\n        _1606 = _1192_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _1606 = _1598;\n    }\n    if (_1606)\n    {\n        return 1.0f;\n    }\n    int param = (int(_1192_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _1619 = fa_light_texel(param);\n    float _1620 = _1619.x;\n    if (_1620 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _1629 = int(_1620 + 0.5f);\n    int param_1 = _1629;\n    float4 _1633 = fa_light_texel(param_1);\n    int param_2 = _1629 + 1;\n    float4 _1638 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _1641 = _1633.y;\n    if (_1641 > 0.0f)\n    {\n        float _1658 = 1.0f - smoothstep(0.75f * _1641, _1641, length(world - _1192_fa_shadow_eye.xyz));\n        fade = _1658;\n        if (_1658 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_1633.x > 1.5f)\n    {\n        int param_3 = li * 4;\n        float3 _1677 = world - fa_light_texel(param_3).xyz;\n        float3 _1680 = abs(_1677);\n        float _1682 = _1680.x;\n        float _1684 = _1680.y;\n        bool _1685 = _1682 >= _1684;\n        bool _1693;\n        if (_1685)\n        {\n            _1693 = _1682 >= _1680.z;\n        }\n        else\n        {\n            _1693 = _1685;\n        }\n        int _1694;\n        if (_1693)\n        {\n            _1694 = (_1677.x > 0.0f) ? 0 : 1;\n        }\n        else\n        {\n            int _1707;\n            if (_1684 >= _1680.z)\n            {\n                _1707 = (_1677.y > 0.0f) ? 2 : 3;\n            }\n            else\n            {\n                _1707 = (_1677.z > 0.0f) ? 4 : 5;\n            }\n            _1694 = _1707;\n        }\n        face = _1694;\n    }\n    int _1726 = (_1629 + 2) + (face * 6);\n    int param_4 = _1726;\n    int param_5 = _1726 + 1;\n    int param_6 = _1726 + 3;\n    float4 _1740 = fa_light_texel(param_6);\n    int param_7 = _1726 + 4;\n    float4 _1745 = fa_light_texel(param_7);\n    int param_8 = _1726 + 5;\n    float4 _1750 = fa_light_texel(param_8);\n    float _1762 = _1750.x * max(dot(_1740, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _1767 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1790 = clamp(dot(n, _1740.xyz), -1.0f, 1.0f);\n    int param_9 = li * 4;\n    float _1813 = min(sqrt(1.0f - (_1790 * _1790)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1740, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _1816 = _1638.y;\n    float _1818;\n    if (_1816 > 0.0f)\n    {\n        _1818 = _1816;\n    }\n    else\n    {\n        _1818 = 1.5f * _1762;\n    }\n    float4 _1838 = float4(world + (n * (_1818 * sqrt(1.0f - (_1767 * _1767)))), 1.0f);\n    float _1842 = dot(_1740, _1838);\n    float _1845 = _1750.y;\n    if (_1842 < _1845)\n    {\n        return 1.0f;\n    }\n    float2 _1860 = float2(dot(fa_light_texel(param_4), _1838), dot(fa_light_texel(param_5), _1838)) / _1842.xx;\n    float _1862 = _1860.x;\n    bool _1865 = _1862 < _1745.x;\n    bool _1874;\n    if (!_1865)\n    {\n        _1874 = _1862 > _1745.z;\n    }\n    else\n    {\n        _1874 = _1865;\n    }\n    bool _1883;\n    if (!_1874)\n    {\n        _1883 = _1860.y < _1745.y;\n    }\n    else\n    {\n        _1883 = _1874;\n    }\n    bool _1892;\n    if (!_1883)\n    {\n        _1892 = _1860.y > _1745.w;\n    }\n    else\n    {\n        _1892 = _1883;\n    }\n    if (_1892)\n    {\n        return 1.0f;\n    }\n    float _1898 = _1638.x;\n    float _1900;\n    if (_1898 > 0.0f)\n    {\n        _1900 = _1898;\n    }\n    else\n    {\n        _1900 = 1.5f * _1762;\n    }\n    float2 param_10 = _1860;\n    float4 param_11 = _1745;\n    float param_12 = _1842 - (_1900 * (1.0f + (0.5f * _1813)));\n    float param_13 = _1762;\n    float param_14 = 1.0f;\n    float param_15 = _1750.z * 0.25f;\n    float param_16 = (_1762 * min(_1813, 3.0f)) * 0.5f;\n    float3 param_17 = float3(1.0f, _1845, _1750.z);\n    int param_18 = int(_1633.z + 0.5f);\n    float param_19 = _1633.w;\n    return lerp(1.0f, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _2441 = fa_lm.z > 0.5f;\n    bool _2447;\n    if (_2441)\n    {\n        int param = li;\n        _2447 = fa_light_baked(param);\n    }\n    else\n    {\n        _2447 = _2441;\n    }\n    if (_2447)\n    {\n        int param_1 = li;\n        LightSample _3469 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _3469;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _2470 = fa_light_sample(param_2, param_3);\n    float3 _3476 = _2470.direction;\n    float3 _3471 = _2470.color;\n    float _3478 = _2470.attenuation;\n    float _3473 = _2470.shadow;\n    int _3481 = _2470.type;\n    if ((_3481 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _3476;\n        float _2484 = fa_shadow_factor(param_4, param_5);\n        _3473 = _2484;\n        _3471 *= _2484;\n    }\n    else\n    {\n        bool _2495 = _3481 != 0;\n        bool _2501;\n        if (_2495)\n        {\n            _2501 = _3478 > 0.0f;\n        }\n        else\n        {\n            _2501 = _2495;\n        }\n        if (_2501)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _3476;\n            float _2513 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _3473 = _2513;\n            _3471 *= _2513;\n        }\n    }\n    LightSample _3488 = { _3476, _3471, _3478, _3473, _2470._distance, _3481 };\n    return _3488;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_1192_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _2149 = int(_1192_fa_shadow_cfg.x + 0.5f);\n    float _2159 = dot(world - _1192_fa_shadow_eye.xyz, _1192_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _2164 = _2149 > 0;\n    bool _2173;\n    if (_2164)\n    {\n        int param = _2149 - 1;\n        _2173 = _2159 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2173 = _2164;\n    }\n    if (_2173)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _2180 = _2149 > 1;\n        bool _2187;\n        if (_2180)\n        {\n            _2187 = _2159 > _1192_fa_shadow_split.x;\n        }\n        else\n        {\n            _2187 = _2180;\n        }\n        if (_2187)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _2193 = _2149 > 2;\n        bool _2200;\n        if (_2193)\n        {\n            _2200 = _2159 > _1192_fa_shadow_split.y;\n        }\n        else\n        {\n            _2200 = _2193;\n        }\n        if (_2200)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _2206 = _2149 > 3;\n        bool _2213;\n        if (_2206)\n        {\n            _2213 = _2159 > _1192_fa_shadow_split.z;\n        }\n        else\n        {\n            _2213 = _2206;\n        }\n        if (_2213)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _3312 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3312 = -_3312;\n    }\n    float3 _2897 = normalize(_452_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _3325 = { fa_world_pos, _3312, fa_world_tangent, fa_uv, fa_vertex_color, _2897, gl_FrontFacing };\n    SurfaceInput param_1 = _3325;\n    Surface _2905 = fa_standard_surface(param_1);\n    float3 _3343 = _2905.albedo;\n    float _3344 = _2905.alpha;\n    float3 _3345 = _2905.normal;\n    float _3346 = _2905.metallic;\n    float _3347 = _2905.roughness;\n    float _3348 = _2905.occlusion;\n    float3 _3349 = _2905.emission;\n    float _3350 = _2905.clearcoat;\n    float _3351 = _2905.clearcoat_roughness;\n    float3 _3352 = _2905.sheen_color;\n    float _3353 = _2905.sheen_roughness;\n    float _3354 = _2905.anisotropy;\n    float _3355 = _2905.anisotropy_rotation;\n    float _3356 = _2905.specular;\n    float _3357 = _2905.ior;\n    float3 _3358 = _2905.specular_color;\n    SurfaceInput _3333 = { fa_world_pos, _3312, fa_world_tangent, fa_uv, fa_vertex_color, _2897, gl_FrontFacing };\n    SurfaceInput param_2 = _3333;\n    Surface param_3 = _2905;\n    surface(param_2, param_3);\n    _3343 = param_3.albedo;\n    _3344 = param_3.alpha;\n    _3345 = param_3.normal;\n    _3346 = param_3.metallic;\n    _3347 = param_3.roughness;\n    _3348 = param_3.occlusion;\n    _3349 = param_3.emission;\n    _3350 = param_3.clearcoat;\n    _3351 = param_3.clearcoat_roughness;\n    _3352 = param_3.sheen_color;\n    _3353 = param_3.sheen_roughness;\n    _3354 = param_3.anisotropy;\n    _3355 = param_3.anisotropy_rotation;\n    _3356 = param_3.specular;\n    _3357 = param_3.ior;\n    _3358 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _3312;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _3343 = param_6;\n    _3345 = param_7;\n    float3 result;\n    if (_452_fa_emissive.w > 0.5f)\n    {\n        result = _3343;\n    }\n    else\n    {\n        float3 _2943 = _3345;\n        float3 _2944 = normalize(_2943);\n        _3345 = _2944;\n        float3 param_8 = _2944;\n        float3 lit = (fa_indirect_diffuse(param_8) * _3343) * _3348;\n        int _2963 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2963; ln++)\n        {\n            int param_9 = ln;\n            int _2976 = fa_cl_light(param_9);\n            bool _2979 = fa_lm.z > 0.5f;\n            bool _2985;\n            if (_2979)\n            {\n                int param_10 = _2976;\n                _2985 = fa_light_baked(param_10);\n            }\n            else\n            {\n                _2985 = _2979;\n            }\n            if (_2985)\n            {\n                continue;\n            }\n            int param_11 = _2976;\n            float3 param_12 = fa_world_pos;\n            float3 param_13 = _3312;\n            SurfaceInput _3341 = { fa_world_pos, _3312, fa_world_tangent, fa_uv, fa_vertex_color, _2897, gl_FrontFacing };\n            SurfaceInput param_14 = _3341;\n            Surface _3424 = { _3343, _3344, _3345, _3346, _3347, _3348, _3349, _3350, _3351, _3352, _3353, _3354, _3355, _3356, _3357, _3358 };\n            Surface param_15 = _3424;\n            LightSample param_16 = fa_light_shadowed(param_11, param_12, param_13);\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    float3 _3012 = result;\n    float3 _3013 = _3012 + _3349;\n    result = _3013;\n    float3 param_17 = _3013;\n    float3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _3022 = _452_fa_fog.w > 0.0f;\n    bool _3029;\n    if (!_3022)\n    {\n        _3029 = _452_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _3029 = _3022;\n    }\n    if (_3029)\n    {\n        float3 _3038 = fa_world_pos - _452_fa_camera_pos.xyz;\n        float _3044 = dot(_3038, _452_fa_fog_c.xyz);\n        bool _3048 = _452_fa_fog_c.w > 0.5f;\n        float _3049;\n        if (_3048)\n        {\n            _3049 = _3044;\n        }\n        else\n        {\n            _3049 = length(_3038);\n        }\n        float _3061 = _3049 - _452_fa_fog_b.x;\n        if (_3061 > 0.0f)\n        {\n            float _3070 = _452_fa_fog.w * _3061;\n            float tau = _3070 * _3070;\n            if (_452_fa_fog_b.y > 0.0f)\n            {\n                float _3086;\n                if (_3048)\n                {\n                    _3086 = fa_world_pos.y - (_452_fa_fog_c.y * _3044);\n                }\n                else\n                {\n                    _3086 = _452_fa_camera_pos.y;\n                }\n                float _3107 = lerp(_3086, fa_world_pos.y, clamp(_452_fa_fog_b.x / _3049, 0.0f, 1.0f));\n                float _3111 = fa_world_pos.y - _3107;\n                float _3116 = _3107 - _452_fa_fog_b.z;\n                float _3121 = fa_world_pos.y - _452_fa_fog_b.z;\n                bool _3124 = _3116 <= 0.0f;\n                bool _3125 = !_3124;\n                bool _3131;\n                if (_3125)\n                {\n                    _3131 = _452_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3131 = _3124;\n                }\n                float _3132;\n                if (_3131)\n                {\n                    _3132 = _452_fa_fog_b.y;\n                }\n                else\n                {\n                    _3132 = _452_fa_fog_b.y * exp(-min(_452_fa_fog_b.w * _3116, 80.0f));\n                }\n                bool _3159;\n                if (_3125)\n                {\n                    _3159 = _452_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3159 = _3124;\n                }\n                float _3160;\n                if (_3159)\n                {\n                    _3160 = _452_fa_fog_b.y * _3116;\n                }\n                else\n                {\n                    _3160 = (_452_fa_fog_b.y * (1.0f - exp(-min(_452_fa_fog_b.w * _3116, 80.0f)))) / _452_fa_fog_b.w;\n                }\n                bool _3185 = _3121 <= 0.0f;\n                bool _3192;\n                if (!_3185)\n                {\n                    _3192 = _452_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3192 = _3185;\n                }\n                float _3193;\n                if (_3192)\n                {\n                    _3193 = _452_fa_fog_b.y * _3121;\n                }\n                else\n                {\n                    _3193 = (_452_fa_fog_b.y * (1.0f - exp(-min(_452_fa_fog_b.w * _3121, 80.0f)))) / _452_fa_fog_b.w;\n                }\n                float _3220;\n                if (abs(_3111) < 0.001000000047497451305389404296875f)\n                {\n                    _3220 = _3132;\n                }\n                else\n                {\n                    _3220 = (_3193 - _3160) / _3111;\n                }\n                tau += (_3061 * max(_3220, 0.0f));\n            }\n            result = lerp(result, _452_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _3344);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_452",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1192",
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
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _381 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _381;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _388 = _273.world_pos;\n    fa_world_pos = _388;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_388, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _452_fa_camera_pos : packoffset(c0);\n    float4 _452_fa_ambient : packoffset(c1);\n    float4 _452_fa_base_color : packoffset(c2);\n    float4 _452_fa_emissive : packoffset(c3);\n    float4 _452_fa_model_emissive : packoffset(c4);\n    float4 _452_fa_pbr : packoffset(c5);\n    float4 _452_fa_maps : packoffset(c6);\n    float4 _452_fa_fog : packoffset(c7);\n    float4 _452_fa_fog_b : packoffset(c8);\n    float4 _452_fa_fog_c : packoffset(c9);\n    float4 _452_fa_counts : packoffset(c10);\n    float4 _452_fa_env_sky : packoffset(c11);\n    float4 _452_fa_env_horizon : packoffset(c12);\n    float4 _452_fa_time : packoffset(c13);\n    float4 _452_fa_cl_vpx : packoffset(c14);\n    float4 _452_fa_cl_vpy : packoffset(c15);\n    float4 _452_fa_cl_vpw : packoffset(c16);\n    float4 _452_fa_cl_fwd : packoffset(c17);\n    float4 _452_fa_cl_grid : packoffset(c18);\n    float4 _452_fa_cl_info : packoffset(c19);\n    float4 _452_fa_layers_a : packoffset(c20);\n    float4 _452_fa_layers_b : packoffset(c21);\n    float4 _452_fa_layers_c : packoffset(c22);\n    float4 _452_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _1192_fa_shadow_mat[4] : packoffset(c0);\n    float4 _1192_fa_shadow_rect[4] : packoffset(c16);\n    float4 _1192_fa_shadow_info[4] : packoffset(c20);\n    float4 _1192_fa_shadow_split : packoffset(c24);\n    float4 _1192_fa_shadow_cfg : packoffset(c25);\n    float4 _1192_fa_shadow_bias : packoffset(c26);\n    float4 _1192_fa_shadow_eye : packoffset(c27);\n    float4 _1192_fa_shadow_fwd : packoffset(c28);\n    float4 _1192_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_decal_tex : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t8);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _457 = _452_fa_cl_info.x < 0.0f;\n    bool _464;\n    if (!_457)\n    {\n        _464 = _452_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _464 = _457;\n    }\n    bool _472;\n    if (!_464)\n    {\n        _472 = _452_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _472 = _464;\n    }\n    bool _479;\n    if (!_472)\n    {\n        _479 = _452_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _479 = _472;\n    }\n    bool _486;\n    if (!_479)\n    {\n        _486 = _452_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _486 = _479;\n    }\n    if (_486)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _496 = float4(world_pos, 1.0f);\n    float _503 = dot(_452_fa_cl_vpw, _496);\n    if (!(_503 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _525 = float2(dot(_452_fa_cl_vpx, _496), dot(_452_fa_cl_vpy, _496)) / _503.xx;\n    int _529 = int(_452_fa_cl_grid.x);\n    int _533 = int(_452_fa_cl_grid.y);\n    int param = (int(_452_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_452_fa_cl_fwd.xyz, world_pos) + _452_fa_cl_fwd.w, _452_fa_cl_grid.w) / _452_fa_cl_grid.w) * _452_fa_cl_grid.z)), 0, int(_452_fa_cl_info.y) - 1) * _533) + clamp(int(floor(((_525.y * 0.5f) + 0.5f) * _452_fa_cl_grid.y)), 0, _533 - 1)) * _529)) + clamp(int(floor(((_525.x * 0.5f) + 0.5f) * _452_fa_cl_grid.x)), 0, _529 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _609 = fa_cluster_texel(param);\n    return int2(int(_609.x), int(_609.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_452_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2414 = fa_cluster_lookup(param);\n    fa_cl_slot = _2414.x;\n    fa_cl_local = _2414.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _2562 = fa_linear_to_srgb(param);\n        c = _2562;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _2570 = fa_srgb_to_linear(param_1);\n            c = _2570;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _217;\n    if (i.front_facing)\n    {\n        _217 = i.world_normal;\n    }\n    else\n    {\n        _217 = -i.world_normal;\n    }\n    float3 _241 = normalize(i.world_tangent.xyz - (_217 * dot(_217, i.world_tangent.xyz)));\n    float3 _268 = normalize(((_241 * m.x) + ((cross(_217, _241) * i.world_tangent.w) * m.y)) + (_217 * m.z));\n    float3 _271;\n    if (i.front_facing)\n    {\n        _271 = _268;\n    }\n    else\n    {\n        _271 = -_268;\n    }\n    return _271;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _452_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2601 = fa_tex_fix(param_2, param_3);\n    float4 _3611 = base_t;\n    _3611.x = _2601.x;\n    _3611.y = _2601.y;\n    _3611.z = _2601.z;\n    base_t = _3611;\n    float4 _2615 = (_3611 * _452_fa_base_color) * i.vertex_color;\n    float3 _3491 = i.world_normal;\n    if (_452_fa_maps.z > 0.5f)\n    {\n        float param_4 = _452_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2647 = fa_tex_fix(param_6, param_7);\n        float3 _2650 = (_2647 * 2.0f) - 1.0f.xxx;\n        float2 _2655 = _2650.xy * _452_fa_maps.x;\n        float3 _3619 = _2650;\n        _3619.x = _2655.x;\n        _3619.y = _2655.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3619;\n        _3491 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _452_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2684 = fa_tex_fix(param_12, param_13);\n    float4 _3622 = mrt;\n    _3622.x = _2684.x;\n    _3622.y = _2684.y;\n    _3622.z = _2684.z;\n    mrt = _3622;\n    float4 _2712 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _452_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _2712.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2724 = fa_tex_fix(param_16, param_17);\n    float param_18 = _452_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2754 = fa_tex_fix(param_20, param_21);\n    float _3496 = _452_fa_layers_a.x;\n    float _3497 = _452_fa_layers_a.y;\n    float _3500 = _452_fa_layers_a.z;\n    float _3499 = _452_fa_layers_b.w;\n    float _3502 = _452_fa_layers_c.x;\n    if (_452_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_452_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _3496 *= _2724.y;\n            _3497 *= _2724.z;\n            _3499 *= _2712.w;\n        }\n        if (_452_fa_layers_c.z > 1.5f)\n        {\n            _3500 *= mrt.x;\n            _3502 *= mrt.w;\n        }\n    }\n    Surface _3521 = { _2615.xyz, _2615.w, _3491, clamp(_452_fa_pbr.x * _2684.z, 0.0f, 1.0f), clamp(_452_fa_pbr.y * _2684.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_452_fa_maps.y * (_2724.x - 1.0f)), _452_fa_emissive.xyz + (_452_fa_model_emissive.xyz * _2754), _3496, _3497, _452_fa_layers_b.xyz, _3499, _3500, _452_fa_layers_a.w, _3502, _452_fa_layers_c.y, _452_fa_layers_d.xyz };\n    return _3521;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _690 = rect.zw - rect.xy;\n    float2 _694 = _690 * atlas;\n    float2 _698 = ddx * _694;\n    float2 _702 = ddy * _694;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _690), clamp(0.5f * log2(max(max(dot(_698, _698), dot(_702, _702)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _737 = _452_fa_counts.y < 0.5f;\n    bool _744;\n    if (!_737)\n    {\n        _744 = _452_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _744 = _737;\n    }\n    if (_744)\n    {\n        return;\n    }\n    float3 _750 = ddx(world_pos);\n    float3 _753 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _757 = fa_cluster_texel(param);\n    int _761 = int(_757.w);\n    if (_761 < 1)\n    {\n        return;\n    }\n    int _771 = int(_452_fa_counts.y + 0.5f);\n    int param_1 = _771;\n    float4 _775 = fa_light_texel(param_1);\n    float2 _778 = _775.yz;\n    int _782 = int(_775.w);\n    int param_2 = _771 + 1;\n    float4 _787 = fa_light_texel(param_2);\n    float _788 = _787.x;\n    int _794 = int(_452_fa_counts.w + 0.5f) - 1;\n    int _798 = int(_757.z);\n    float3 _1064;\n    for (int k = 0; k < _761; k++)\n    {\n        int _811 = _798 + k;\n        int param_3 = _782 + (_811 >> 2);\n        int _829 = (_771 + 2) + (int(fa_light_texel(param_3)[_811 & 3]) * 7);\n        int param_4 = _829 + 6;\n        float4 _834 = fa_light_texel(param_4);\n        if (((int(_834.w + 0.5f) >> _794) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _829;\n        float4 _849 = fa_light_texel(param_5);\n        int param_6 = _829 + 1;\n        float4 _854 = fa_light_texel(param_6);\n        int param_7 = _829 + 2;\n        float4 _859 = fa_light_texel(param_7);\n        float3 _862 = _849.xyz;\n        float _867 = dot(_862, world_pos) + _849.w;\n        float3 _869 = _854.xyz;\n        float _874 = dot(_869, world_pos) + _854.w;\n        float3 _876 = _859.xyz;\n        float _881 = dot(_876, world_pos) + _859.w;\n        bool _886 = abs(_867) > 0.5f;\n        bool _894;\n        if (!_886)\n        {\n            _894 = abs(_874) > 0.5f;\n        }\n        else\n        {\n            _894 = _886;\n        }\n        bool _902;\n        if (!_894)\n        {\n            _902 = abs(_881) > 0.5f;\n        }\n        else\n        {\n            _902 = _894;\n        }\n        if (_902)\n        {\n            continue;\n        }\n        float _917 = clamp(dot(geo_normal, normalize(_876)) * _834.z, 0.0f, 1.0f);\n        if (_917 <= 0.0f)\n        {\n            continue;\n        }\n        float _937 = (clamp((0.5f - abs(_881)) * 10.0f, 0.0f, 1.0f) * _917) * _834.x;\n        float2 _945 = float2(_867 + 0.5f, 0.5f - _874);\n        float2 _955 = float2(dot(_862, _750), dot(_869, _750));\n        float2 _965 = float2(dot(_862, _753), dot(_869, _753));\n        int param_8 = _829 + 5;\n        float4 _970 = fa_light_texel(param_8);\n        int param_9 = _829 + 3;\n        float4 _975 = fa_light_texel(param_9);\n        int param_10 = _829 + 4;\n        float4 _980 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _970.xyz;\n        bool _990 = _975.z > _975.x;\n        if (_990)\n        {\n            float4 param_11 = _975;\n            float2 param_12 = _945;\n            float2 param_13 = _778;\n            float2 param_14 = _955;\n            float2 param_15 = _965;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_788 > 0.5f) && (_788 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1016 = fa_dc_to_linear(param_16);\n                float4 _3547 = tx;\n                _3547.x = _1016.x;\n                _3547.y = _1016.y;\n                _3547.z = _1016.z;\n                tx = _3547;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_937 * tex_a) * _970.w, 0.0f, 1.0f).xxx);\n        if (_980.z > _980.x)\n        {\n            float4 param_17 = _980;\n            float2 param_18 = _945;\n            float2 param_19 = _778;\n            float2 param_20 = _955;\n            float2 param_21 = _965;\n            float4 _1060 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_788 > 1.5f)\n            {\n                float3 param_22 = _1060.xyz;\n                float3 _1070 = fa_dc_to_srgb(param_22);\n                _1064 = _1070;\n            }\n            else\n            {\n                _1064 = _1060.xyz;\n            }\n            float3 _1080 = (_1064 * 2.0f) - 1.0f.xxx;\n            float2 _1085 = _1080.xy * _834.y;\n            float3 _1107 = (normalize(_862) * _1085.x) + (normalize(_869) * _1085.y);\n            float3 _1110 = normalize(normal);\n            normal = normalize(lerp(_1110, normalize((_1110 * max(_1080.z, 0.0500000007450580596923828125f)) + (_1107 - (_1110 * dot(_1110, _1107)))), clamp(_937 * (_990 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_sky_sh_coef(int k)\n{\n    float3 v = fa_env_tex.SampleLevel(fa_env_smp, float3(1.0f, 1.0f - (float((2 * (k >> 2)) + 1) * 0.25f), 1.0f - (float((2 * (k & 3)) + 1) * 0.25f)), 5.0f).xyz;\n    if (_452_fa_env_sky.w > 1.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _2327 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _2327;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_452_fa_env_sky.w > 0.5f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _452_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_452_fa_cl_info.x) + int(_452_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _327 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _333 = fa_light_texel(param_1);\n    float _336 = _333.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _342 = _336 < 0.5f;\n    float3 l;\n    if (_342)\n    {\n        l = normalize(_327.xyz);\n    }\n    else\n    {\n        float3 _354 = _327.xyz - world_pos;\n        float _356 = length(_354);\n        dist = _356;\n        l = _354 / max(_356, 9.9999997473787516355514526367188e-05f).xxx;\n        float _371 = _356 / max(_327.w, 0.001000000047497451305389404296875f);\n        float _377 = clamp(1.0f - (_371 * _371), 0.0f, 1.0f);\n        atten = _377 * _377;\n        if (_336 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _391 = fa_light_texel(param_2);\n            float _401 = _391.w;\n            int param_3 = (li * 4) + 3;\n            float4 _407 = fa_light_texel(param_3);\n            float _408 = _407.x;\n            float cos_inner = _408;\n            if (_408 > 1.5f)\n            {\n                cos_inner = lerp(_401, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_401, cos_inner, dot(-l, normalize(_391.xyz)));\n        }\n    }\n    int _438;\n    if (_342)\n    {\n        _438 = 0;\n    }\n    else\n    {\n        _438 = (_336 > 1.5f) ? 2 : 1;\n    }\n    LightSample _3456 = { l, _333.xyz * atten, atten, 1.0f, dist, _438 };\n    return _3456;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1182;\n    if (i == 0)\n    {\n        _1182 = _1192_fa_shadow_split.x;\n    }\n    else\n    {\n        float _1198;\n        if (i == 1)\n        {\n            _1198 = _1192_fa_shadow_split.y;\n        }\n        else\n        {\n            float _1206;\n            if (i == 2)\n            {\n                _1206 = _1192_fa_shadow_split.z;\n            }\n            else\n            {\n                _1206 = _1192_fa_shadow_split.w;\n            }\n            _1198 = _1206;\n        }\n        _1182 = _1198;\n    }\n    return _1182;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1239 = fa_shadow_depth(param, param_1);\n    float _1243;\n    if (conv.x < 0.5f)\n    {\n        _1243 = _1239;\n    }\n    else\n    {\n        _1243 = (conv.y * conv.z) / (conv.z - (_1239 * (conv.z - conv.y)));\n    }\n    return _1243;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1170 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_1170), sin(_1170)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1289 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _1303 = clamp((k * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1289;\n            float2 _1322 = fa_shadow_vogel(param_3, param_4, param_5) * _1303;\n            float2 param_6 = uv + (_1322 * _1192_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1334 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1334 < (zr - (length(_1322) * plane)))\n            {\n                sum += _1334;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0f) * unit) * k) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _1378 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1378; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1378;\n        float param_11 = _1289;\n        float2 _1397 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1397 * _1192_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1397) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1378);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _1439 = max(_1192_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _1444 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1450 = sqrt(1.0f - (_1444 * _1444));\n    float _1457 = min(_1450 / max(_1444, 0.20000000298023223876953125f), 4.0f);\n    float _1462;\n    if (_1192_fa_shadow_bias.y > 0.0f)\n    {\n        _1462 = _1192_fa_shadow_bias.y;\n    }\n    else\n    {\n        _1462 = 1.5f * _1192_fa_shadow_info[ci].x;\n    }\n    float4 _1487 = mul(float4(world + (n * (_1462 * _1450)), 1.0f), _1192_fa_shadow_mat[ci]);\n    float _1494 = _1487.x;\n    bool _1497 = _1494 < _1192_fa_shadow_rect[ci].x;\n    bool _1506;\n    if (!_1497)\n    {\n        _1506 = _1494 > _1192_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1506 = _1497;\n    }\n    bool _1515;\n    if (!_1506)\n    {\n        _1515 = _1487.y < _1192_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1515 = _1506;\n    }\n    bool _1524;\n    if (!_1515)\n    {\n        _1524 = _1487.y > _1192_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1524 = _1515;\n    }\n    bool _1531;\n    if (!_1524)\n    {\n        _1531 = _1487.z > 1.0f;\n    }\n    else\n    {\n        _1531 = _1524;\n    }\n    if (_1531)\n    {\n        return -1.0f;\n    }\n    float _1540;\n    if (_1192_fa_shadow_bias.x > 0.0f)\n    {\n        _1540 = _1192_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1540 = 1.5f * _1192_fa_shadow_info[ci].x;\n    }\n    float2 param = _1487.xy;\n    float4 param_1 = _1192_fa_shadow_rect[ci];\n    float param_2 = _1487.z - ((_1540 * (1.0f + (0.5f * _1457))) / _1439);\n    float param_3 = _1192_fa_shadow_info[ci].x;\n    float param_4 = _1439;\n    float param_5 = _1439 * 0.25f;\n    float param_6 = ((_1192_fa_shadow_info[ci].x * min(_1457, 3.0f)) * 0.5f) / _1439;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_1192_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _1192_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_452_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1967 = int(_1192_fa_shadow_cfg.x + 0.5f);\n    if (_1967 < 1)\n    {\n        return 1.0f;\n    }\n    float _1982 = dot(world - _1192_fa_shadow_eye.xyz, _1192_fa_shadow_fwd.xyz);\n    int param = _1967 - 1;\n    if (_1982 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1994 = _1967 > 1;\n    bool _2001;\n    if (_1994)\n    {\n        _2001 = _1982 > _1192_fa_shadow_split.x;\n    }\n    else\n    {\n        _2001 = _1994;\n    }\n    if (_2001)\n    {\n        ci = 1;\n    }\n    bool _2005 = _1967 > 2;\n    bool _2012;\n    if (_2005)\n    {\n        _2012 = _1982 > _1192_fa_shadow_split.y;\n    }\n    else\n    {\n        _2012 = _2005;\n    }\n    if (_2012)\n    {\n        ci = 2;\n    }\n    bool _2016 = _1967 > 3;\n    bool _2023;\n    if (_2016)\n    {\n        _2023 = _1982 > _1192_fa_shadow_split.z;\n    }\n    else\n    {\n        _2023 = _2016;\n    }\n    if (_2023)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1967)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2049 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2049;\n        if (_2049 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_1192_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2074;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2074 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2074 = _1192_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2093 = _1192_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2074, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2104 = clamp((_1982 - (fa_shadow_split_at(param_7) - _2093)) / _2093, 0.0f, 1.0f);\n        if (_2104 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1967)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2125 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2125;\n                if (_2125 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2104);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _1598 = _452_fa_pbr.z < 0.5f;\n    bool _1606;\n    if (!_1598)\n    {\n        _1606 = _1192_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _1606 = _1598;\n    }\n    if (_1606)\n    {\n        return 1.0f;\n    }\n    int param = (int(_1192_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _1619 = fa_light_texel(param);\n    float _1620 = _1619.x;\n    if (_1620 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _1629 = int(_1620 + 0.5f);\n    int param_1 = _1629;\n    float4 _1633 = fa_light_texel(param_1);\n    int param_2 = _1629 + 1;\n    float4 _1638 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _1641 = _1633.y;\n    if (_1641 > 0.0f)\n    {\n        float _1658 = 1.0f - smoothstep(0.75f * _1641, _1641, length(world - _1192_fa_shadow_eye.xyz));\n        fade = _1658;\n        if (_1658 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_1633.x > 1.5f)\n    {\n        int param_3 = li * 4;\n        float3 _1677 = world - fa_light_texel(param_3).xyz;\n        float3 _1680 = abs(_1677);\n        float _1682 = _1680.x;\n        float _1684 = _1680.y;\n        bool _1685 = _1682 >= _1684;\n        bool _1693;\n        if (_1685)\n        {\n            _1693 = _1682 >= _1680.z;\n        }\n        else\n        {\n            _1693 = _1685;\n        }\n        int _1694;\n        if (_1693)\n        {\n            _1694 = (_1677.x > 0.0f) ? 0 : 1;\n        }\n        else\n        {\n            int _1707;\n            if (_1684 >= _1680.z)\n            {\n                _1707 = (_1677.y > 0.0f) ? 2 : 3;\n            }\n            else\n            {\n                _1707 = (_1677.z > 0.0f) ? 4 : 5;\n            }\n            _1694 = _1707;\n        }\n        face = _1694;\n    }\n    int _1726 = (_1629 + 2) + (face * 6);\n    int param_4 = _1726;\n    int param_5 = _1726 + 1;\n    int param_6 = _1726 + 3;\n    float4 _1740 = fa_light_texel(param_6);\n    int param_7 = _1726 + 4;\n    float4 _1745 = fa_light_texel(param_7);\n    int param_8 = _1726 + 5;\n    float4 _1750 = fa_light_texel(param_8);\n    float _1762 = _1750.x * max(dot(_1740, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _1767 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1790 = clamp(dot(n, _1740.xyz), -1.0f, 1.0f);\n    int param_9 = li * 4;\n    float _1813 = min(sqrt(1.0f - (_1790 * _1790)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1740, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _1816 = _1638.y;\n    float _1818;\n    if (_1816 > 0.0f)\n    {\n        _1818 = _1816;\n    }\n    else\n    {\n        _1818 = 1.5f * _1762;\n    }\n    float4 _1838 = float4(world + (n * (_1818 * sqrt(1.0f - (_1767 * _1767)))), 1.0f);\n    float _1842 = dot(_1740, _1838);\n    float _1845 = _1750.y;\n    if (_1842 < _1845)\n    {\n        return 1.0f;\n    }\n    float2 _1860 = float2(dot(fa_light_texel(param_4), _1838), dot(fa_light_texel(param_5), _1838)) / _1842.xx;\n    float _1862 = _1860.x;\n    bool _1865 = _1862 < _1745.x;\n    bool _1874;\n    if (!_1865)\n    {\n        _1874 = _1862 > _1745.z;\n    }\n    else\n    {\n        _1874 = _1865;\n    }\n    bool _1883;\n    if (!_1874)\n    {\n        _1883 = _1860.y < _1745.y;\n    }\n    else\n    {\n        _1883 = _1874;\n    }\n    bool _1892;\n    if (!_1883)\n    {\n        _1892 = _1860.y > _1745.w;\n    }\n    else\n    {\n        _1892 = _1883;\n    }\n    if (_1892)\n    {\n        return 1.0f;\n    }\n    float _1898 = _1638.x;\n    float _1900;\n    if (_1898 > 0.0f)\n    {\n        _1900 = _1898;\n    }\n    else\n    {\n        _1900 = 1.5f * _1762;\n    }\n    float2 param_10 = _1860;\n    float4 param_11 = _1745;\n    float param_12 = _1842 - (_1900 * (1.0f + (0.5f * _1813)));\n    float param_13 = _1762;\n    float param_14 = 1.0f;\n    float param_15 = _1750.z * 0.25f;\n    float param_16 = (_1762 * min(_1813, 3.0f)) * 0.5f;\n    float3 param_17 = float3(1.0f, _1845, _1750.z);\n    int param_18 = int(_1633.z + 0.5f);\n    float param_19 = _1633.w;\n    return lerp(1.0f, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _2441 = fa_lm.z > 0.5f;\n    bool _2447;\n    if (_2441)\n    {\n        int param = li;\n        _2447 = fa_light_baked(param);\n    }\n    else\n    {\n        _2447 = _2441;\n    }\n    if (_2447)\n    {\n        int param_1 = li;\n        LightSample _3469 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _3469;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _2470 = fa_light_sample(param_2, param_3);\n    float3 _3476 = _2470.direction;\n    float3 _3471 = _2470.color;\n    float _3478 = _2470.attenuation;\n    float _3473 = _2470.shadow;\n    int _3481 = _2470.type;\n    if ((_3481 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _3476;\n        float _2484 = fa_shadow_factor(param_4, param_5);\n        _3473 = _2484;\n        _3471 *= _2484;\n    }\n    else\n    {\n        bool _2495 = _3481 != 0;\n        bool _2501;\n        if (_2495)\n        {\n            _2501 = _3478 > 0.0f;\n        }\n        else\n        {\n            _2501 = _2495;\n        }\n        if (_2501)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _3476;\n            float _2513 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _3473 = _2513;\n            _3471 *= _2513;\n        }\n    }\n    LightSample _3488 = { _3476, _3471, _3478, _3473, _2470._distance, _3481 };\n    return _3488;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_1192_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _2149 = int(_1192_fa_shadow_cfg.x + 0.5f);\n    float _2159 = dot(world - _1192_fa_shadow_eye.xyz, _1192_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _2164 = _2149 > 0;\n    bool _2173;\n    if (_2164)\n    {\n        int param = _2149 - 1;\n        _2173 = _2159 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2173 = _2164;\n    }\n    if (_2173)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _2180 = _2149 > 1;\n        bool _2187;\n        if (_2180)\n        {\n            _2187 = _2159 > _1192_fa_shadow_split.x;\n        }\n        else\n        {\n            _2187 = _2180;\n        }\n        if (_2187)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _2193 = _2149 > 2;\n        bool _2200;\n        if (_2193)\n        {\n            _2200 = _2159 > _1192_fa_shadow_split.y;\n        }\n        else\n        {\n            _2200 = _2193;\n        }\n        if (_2200)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _2206 = _2149 > 3;\n        bool _2213;\n        if (_2206)\n        {\n            _2213 = _2159 > _1192_fa_shadow_split.z;\n        }\n        else\n        {\n            _2213 = _2206;\n        }\n        if (_2213)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _3312 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3312 = -_3312;\n    }\n    float3 _2897 = normalize(_452_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _3325 = { fa_world_pos, _3312, fa_world_tangent, fa_uv, fa_vertex_color, _2897, gl_FrontFacing };\n    SurfaceInput param_1 = _3325;\n    Surface _2905 = fa_standard_surface(param_1);\n    float3 _3343 = _2905.albedo;\n    float _3344 = _2905.alpha;\n    float3 _3345 = _2905.normal;\n    float _3346 = _2905.metallic;\n    float _3347 = _2905.roughness;\n    float _3348 = _2905.occlusion;\n    float3 _3349 = _2905.emission;\n    float _3350 = _2905.clearcoat;\n    float _3351 = _2905.clearcoat_roughness;\n    float3 _3352 = _2905.sheen_color;\n    float _3353 = _2905.sheen_roughness;\n    float _3354 = _2905.anisotropy;\n    float _3355 = _2905.anisotropy_rotation;\n    float _3356 = _2905.specular;\n    float _3357 = _2905.ior;\n    float3 _3358 = _2905.specular_color;\n    SurfaceInput _3333 = { fa_world_pos, _3312, fa_world_tangent, fa_uv, fa_vertex_color, _2897, gl_FrontFacing };\n    SurfaceInput param_2 = _3333;\n    Surface param_3 = _2905;\n    surface(param_2, param_3);\n    _3343 = param_3.albedo;\n    _3344 = param_3.alpha;\n    _3345 = param_3.normal;\n    _3346 = param_3.metallic;\n    _3347 = param_3.roughness;\n    _3348 = param_3.occlusion;\n    _3349 = param_3.emission;\n    _3350 = param_3.clearcoat;\n    _3351 = param_3.clearcoat_roughness;\n    _3352 = param_3.sheen_color;\n    _3353 = param_3.sheen_roughness;\n    _3354 = param_3.anisotropy;\n    _3355 = param_3.anisotropy_rotation;\n    _3356 = param_3.specular;\n    _3357 = param_3.ior;\n    _3358 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _3312;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _3343 = param_6;\n    _3345 = param_7;\n    float3 result;\n    if (_452_fa_emissive.w > 0.5f)\n    {\n        result = _3343;\n    }\n    else\n    {\n        float3 _2943 = _3345;\n        float3 _2944 = normalize(_2943);\n        _3345 = _2944;\n        float3 param_8 = _2944;\n        float3 lit = (fa_indirect_diffuse(param_8) * _3343) * _3348;\n        int _2963 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2963; ln++)\n        {\n            int param_9 = ln;\n            int _2976 = fa_cl_light(param_9);\n            bool _2979 = fa_lm.z > 0.5f;\n            bool _2985;\n            if (_2979)\n            {\n                int param_10 = _2976;\n                _2985 = fa_light_baked(param_10);\n            }\n            else\n            {\n                _2985 = _2979;\n            }\n            if (_2985)\n            {\n                continue;\n            }\n            int param_11 = _2976;\n            float3 param_12 = fa_world_pos;\n            float3 param_13 = _3312;\n            SurfaceInput _3341 = { fa_world_pos, _3312, fa_world_tangent, fa_uv, fa_vertex_color, _2897, gl_FrontFacing };\n            SurfaceInput param_14 = _3341;\n            Surface _3424 = { _3343, _3344, _3345, _3346, _3347, _3348, _3349, _3350, _3351, _3352, _3353, _3354, _3355, _3356, _3357, _3358 };\n            Surface param_15 = _3424;\n            LightSample param_16 = fa_light_shadowed(param_11, param_12, param_13);\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    float3 _3012 = result;\n    float3 _3013 = _3012 + _3349;\n    result = _3013;\n    float3 param_17 = _3013;\n    float3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _3022 = _452_fa_fog.w > 0.0f;\n    bool _3029;\n    if (!_3022)\n    {\n        _3029 = _452_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _3029 = _3022;\n    }\n    if (_3029)\n    {\n        float3 _3038 = fa_world_pos - _452_fa_camera_pos.xyz;\n        float _3044 = dot(_3038, _452_fa_fog_c.xyz);\n        bool _3048 = _452_fa_fog_c.w > 0.5f;\n        float _3049;\n        if (_3048)\n        {\n            _3049 = _3044;\n        }\n        else\n        {\n            _3049 = length(_3038);\n        }\n        float _3061 = _3049 - _452_fa_fog_b.x;\n        if (_3061 > 0.0f)\n        {\n            float _3070 = _452_fa_fog.w * _3061;\n            float tau = _3070 * _3070;\n            if (_452_fa_fog_b.y > 0.0f)\n            {\n                float _3086;\n                if (_3048)\n                {\n                    _3086 = fa_world_pos.y - (_452_fa_fog_c.y * _3044);\n                }\n                else\n                {\n                    _3086 = _452_fa_camera_pos.y;\n                }\n                float _3107 = lerp(_3086, fa_world_pos.y, clamp(_452_fa_fog_b.x / _3049, 0.0f, 1.0f));\n                float _3111 = fa_world_pos.y - _3107;\n                float _3116 = _3107 - _452_fa_fog_b.z;\n                float _3121 = fa_world_pos.y - _452_fa_fog_b.z;\n                bool _3124 = _3116 <= 0.0f;\n                bool _3125 = !_3124;\n                bool _3131;\n                if (_3125)\n                {\n                    _3131 = _452_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3131 = _3124;\n                }\n                float _3132;\n                if (_3131)\n                {\n                    _3132 = _452_fa_fog_b.y;\n                }\n                else\n                {\n                    _3132 = _452_fa_fog_b.y * exp(-min(_452_fa_fog_b.w * _3116, 80.0f));\n                }\n                bool _3159;\n                if (_3125)\n                {\n                    _3159 = _452_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3159 = _3124;\n                }\n                float _3160;\n                if (_3159)\n                {\n                    _3160 = _452_fa_fog_b.y * _3116;\n                }\n                else\n                {\n                    _3160 = (_452_fa_fog_b.y * (1.0f - exp(-min(_452_fa_fog_b.w * _3116, 80.0f)))) / _452_fa_fog_b.w;\n                }\n                bool _3185 = _3121 <= 0.0f;\n                bool _3192;\n                if (!_3185)\n                {\n                    _3192 = _452_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3192 = _3185;\n                }\n                float _3193;\n                if (_3192)\n                {\n                    _3193 = _452_fa_fog_b.y * _3121;\n                }\n                else\n                {\n                    _3193 = (_452_fa_fog_b.y * (1.0f - exp(-min(_452_fa_fog_b.w * _3121, 80.0f)))) / _452_fa_fog_b.w;\n                }\n                float _3220;\n                if (abs(_3111) < 0.001000000047497451305389404296875f)\n                {\n                    _3220 = _3132;\n                }\n                else\n                {\n                    _3220 = (_3193 - _3160) / _3111;\n                }\n                tau += (_3061 * max(_3220, 0.0f));\n            }\n            result = lerp(result, _452_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _3344);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_452",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1192",
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
          }
        ]
      }
    },
    "prepass": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _292 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _292;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _299 = _160.world_pos;\n    float4 _171 = float4(_299, 1.0f);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -mul(_171, _131_fa_light_vp).z;\n    fa_pre_r0 = float3(_131_fa_light_vp[0].x, _131_fa_light_vp[1].x, _131_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131_fa_light_vp[0].y, _131_fa_light_vp[1].y, _131_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131_fa_light_vp[0].z, _131_fa_light_vp[1].z, _131_fa_light_vp[2].z);\n    gl_Position = mul(_171, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _783 = base_t;\n    _783.x = _225.x;\n    _783.y = _225.y;\n    _783.z = _225.z;\n    base_t = _783;\n    float4 _241 = (_783 * _213_fa_base_color) * i.vertex_color;\n    float3 _746 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _791 = _279;\n        _791.x = _284.x;\n        _791.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _791;\n        _746 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _794 = mrt;\n    _794.x = _313.x;\n    _794.y = _313.y;\n    _794.z = _313.z;\n    mrt = _794;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _751 = _213_fa_layers_a.x;\n    float _752 = _213_fa_layers_a.y;\n    float _755 = _213_fa_layers_a.z;\n    float _754 = _213_fa_layers_b.w;\n    float _757 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _751 *= _355.y;\n            _752 *= _355.z;\n            _754 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _755 *= mrt.x;\n            _757 *= mrt.w;\n        }\n    }\n    Surface _776 = { _241.xyz, _241.w, _746, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _751, _752, _213_fa_layers_b.xyz, _754, _755, _213_fa_layers_a.w, _757, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _776;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _657 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _657 = -_657;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _670 = { fa_world_pos, _657, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _670;\n    SurfaceInput _678 = { fa_world_pos, _657, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _678;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _783 = base_t;\n    _783.x = _225.x;\n    _783.y = _225.y;\n    _783.z = _225.z;\n    base_t = _783;\n    float4 _241 = (_783 * _213_fa_base_color) * i.vertex_color;\n    float3 _746 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _791 = _279;\n        _791.x = _284.x;\n        _791.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _791;\n        _746 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _794 = mrt;\n    _794.x = _313.x;\n    _794.y = _313.y;\n    _794.z = _313.z;\n    mrt = _794;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _751 = _213_fa_layers_a.x;\n    float _752 = _213_fa_layers_a.y;\n    float _755 = _213_fa_layers_a.z;\n    float _754 = _213_fa_layers_b.w;\n    float _757 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _751 *= _355.y;\n            _752 *= _355.z;\n            _754 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _755 *= mrt.x;\n            _757 *= mrt.w;\n        }\n    }\n    Surface _776 = { _241.xyz, _241.w, _746, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _751, _752, _213_fa_layers_b.xyz, _754, _755, _213_fa_layers_a.w, _757, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _776;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _657 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _657 = -_657;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _670 = { fa_world_pos, _657, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _670;\n    SurfaceInput _678 = { fa_world_pos, _657, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _678;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
