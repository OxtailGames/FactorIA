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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _458_fa_camera_pos : packoffset(c0);\n    float4 _458_fa_ambient : packoffset(c1);\n    float4 _458_fa_base_color : packoffset(c2);\n    float4 _458_fa_emissive : packoffset(c3);\n    float4 _458_fa_model_emissive : packoffset(c4);\n    float4 _458_fa_pbr : packoffset(c5);\n    float4 _458_fa_maps : packoffset(c6);\n    float4 _458_fa_fog : packoffset(c7);\n    float4 _458_fa_fog_b : packoffset(c8);\n    float4 _458_fa_fog_c : packoffset(c9);\n    float4 _458_fa_counts : packoffset(c10);\n    float4 _458_fa_env_sky : packoffset(c11);\n    float4 _458_fa_env_horizon : packoffset(c12);\n    float4 _458_fa_time : packoffset(c13);\n    float4 _458_fa_cl_vpx : packoffset(c14);\n    float4 _458_fa_cl_vpy : packoffset(c15);\n    float4 _458_fa_cl_vpw : packoffset(c16);\n    float4 _458_fa_cl_fwd : packoffset(c17);\n    float4 _458_fa_cl_grid : packoffset(c18);\n    float4 _458_fa_cl_info : packoffset(c19);\n    float4 _458_fa_layers_a : packoffset(c20);\n    float4 _458_fa_layers_b : packoffset(c21);\n    float4 _458_fa_layers_c : packoffset(c22);\n    float4 _458_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _1198_fa_shadow_mat[4] : packoffset(c0);\n    float4 _1198_fa_shadow_rect[4] : packoffset(c16);\n    float4 _1198_fa_shadow_info[4] : packoffset(c20);\n    float4 _1198_fa_shadow_split : packoffset(c24);\n    float4 _1198_fa_shadow_cfg : packoffset(c25);\n    float4 _1198_fa_shadow_bias : packoffset(c26);\n    float4 _1198_fa_shadow_eye : packoffset(c27);\n    float4 _1198_fa_shadow_fwd : packoffset(c28);\n    float4 _1198_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_decal_tex : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t8);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _463 = _458_fa_cl_info.x < 0.0f;\n    bool _470;\n    if (!_463)\n    {\n        _470 = _458_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _470 = _463;\n    }\n    bool _478;\n    if (!_470)\n    {\n        _478 = _458_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _478 = _470;\n    }\n    bool _485;\n    if (!_478)\n    {\n        _485 = _458_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _485 = _478;\n    }\n    bool _492;\n    if (!_485)\n    {\n        _492 = _458_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _492 = _485;\n    }\n    if (_492)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _502 = float4(world_pos, 1.0f);\n    float _509 = dot(_458_fa_cl_vpw, _502);\n    if (!(_509 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _531 = float2(dot(_458_fa_cl_vpx, _502), dot(_458_fa_cl_vpy, _502)) / _509.xx;\n    int _535 = int(_458_fa_cl_grid.x);\n    int _539 = int(_458_fa_cl_grid.y);\n    int param = (int(_458_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_458_fa_cl_fwd.xyz, world_pos) + _458_fa_cl_fwd.w, _458_fa_cl_grid.w) / _458_fa_cl_grid.w) * _458_fa_cl_grid.z)), 0, int(_458_fa_cl_info.y) - 1) * _539) + clamp(int(floor(((_531.y * 0.5f) + 0.5f) * _458_fa_cl_grid.y)), 0, _539 - 1)) * _535)) + clamp(int(floor(((_531.x * 0.5f) + 0.5f) * _458_fa_cl_grid.x)), 0, _535 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _615 = fa_cluster_texel(param);\n    return int2(int(_615.x), int(_615.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_458_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2420 = fa_cluster_lookup(param);\n    fa_cl_slot = _2420.x;\n    fa_cl_local = _2420.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _2571 = fa_linear_to_srgb(param);\n        c = _2571;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _2579 = fa_srgb_to_linear(param_1);\n            c = _2579;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _223;\n    if (i.front_facing)\n    {\n        _223 = i.world_normal;\n    }\n    else\n    {\n        _223 = -i.world_normal;\n    }\n    float3 _247 = normalize(i.world_tangent.xyz - (_223 * dot(_223, i.world_tangent.xyz)));\n    float3 _274 = normalize(((_247 * m.x) + ((cross(_223, _247) * i.world_tangent.w) * m.y)) + (_223 * m.z));\n    float3 _277;\n    if (i.front_facing)\n    {\n        _277 = _274;\n    }\n    else\n    {\n        _277 = -_274;\n    }\n    return _277;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _458_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2610 = fa_tex_fix(param_2, param_3);\n    float4 _3645 = base_t;\n    _3645.x = _2610.x;\n    _3645.y = _2610.y;\n    _3645.z = _2610.z;\n    base_t = _3645;\n    float4 _2624 = (_3645 * _458_fa_base_color) * i.vertex_color;\n    float3 _3525 = i.world_normal;\n    if (_458_fa_maps.z > 0.5f)\n    {\n        float param_4 = _458_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2656 = fa_tex_fix(param_6, param_7);\n        float3 _2659 = (_2656 * 2.0f) - 1.0f.xxx;\n        float2 _2664 = _2659.xy * _458_fa_maps.x;\n        float3 _3653 = _2659;\n        _3653.x = _2664.x;\n        _3653.y = _2664.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3653;\n        _3525 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _458_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2693 = fa_tex_fix(param_12, param_13);\n    float4 _3656 = mrt;\n    _3656.x = _2693.x;\n    _3656.y = _2693.y;\n    _3656.z = _2693.z;\n    mrt = _3656;\n    float4 _2721 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _458_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _2721.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2733 = fa_tex_fix(param_16, param_17);\n    float param_18 = _458_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2763 = fa_tex_fix(param_20, param_21);\n    float _3530 = _458_fa_layers_a.x;\n    float _3531 = _458_fa_layers_a.y;\n    float _3534 = _458_fa_layers_a.z;\n    float _3533 = _458_fa_layers_b.w;\n    float _3536 = _458_fa_layers_c.x;\n    if (_458_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_458_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _3530 *= _2733.y;\n            _3531 *= _2733.z;\n            _3533 *= _2721.w;\n        }\n        if (_458_fa_layers_c.z > 1.5f)\n        {\n            _3534 *= mrt.x;\n            _3536 *= mrt.w;\n        }\n    }\n    Surface _3555 = { _2624.xyz, _2624.w, _3525, clamp(_458_fa_pbr.x * _2693.z, 0.0f, 1.0f), clamp(_458_fa_pbr.y * _2693.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_458_fa_maps.y * (_2733.x - 1.0f)), _458_fa_emissive.xyz + (_458_fa_model_emissive.xyz * _2763), _3530, _3531, _458_fa_layers_b.xyz, _3533, _3534, _458_fa_layers_a.w, _3536, _458_fa_layers_c.y, _458_fa_layers_d.xyz };\n    return _3555;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _696 = rect.zw - rect.xy;\n    float2 _700 = _696 * atlas;\n    float2 _704 = ddx * _700;\n    float2 _708 = ddy * _700;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _696), clamp(0.5f * log2(max(max(dot(_704, _704), dot(_708, _708)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _743 = _458_fa_counts.y < 0.5f;\n    bool _750;\n    if (!_743)\n    {\n        _750 = _458_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _750 = _743;\n    }\n    if (_750)\n    {\n        return;\n    }\n    float3 _756 = ddx(world_pos);\n    float3 _759 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _763 = fa_cluster_texel(param);\n    int _767 = int(_763.w);\n    if (_767 < 1)\n    {\n        return;\n    }\n    int _777 = int(_458_fa_counts.y + 0.5f);\n    int param_1 = _777;\n    float4 _781 = fa_light_texel(param_1);\n    float2 _784 = _781.yz;\n    int _788 = int(_781.w);\n    int param_2 = _777 + 1;\n    float4 _793 = fa_light_texel(param_2);\n    float _794 = _793.x;\n    int _800 = int(_458_fa_counts.w + 0.5f) - 1;\n    int _804 = int(_763.z);\n    float3 _1070;\n    for (int k = 0; k < _767; k++)\n    {\n        int _817 = _804 + k;\n        int param_3 = _788 + (_817 >> 2);\n        int _835 = (_777 + 2) + (int(fa_light_texel(param_3)[_817 & 3]) * 7);\n        int param_4 = _835 + 6;\n        float4 _840 = fa_light_texel(param_4);\n        if (((int(_840.w + 0.5f) >> _800) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _835;\n        float4 _855 = fa_light_texel(param_5);\n        int param_6 = _835 + 1;\n        float4 _860 = fa_light_texel(param_6);\n        int param_7 = _835 + 2;\n        float4 _865 = fa_light_texel(param_7);\n        float3 _868 = _855.xyz;\n        float _873 = dot(_868, world_pos) + _855.w;\n        float3 _875 = _860.xyz;\n        float _880 = dot(_875, world_pos) + _860.w;\n        float3 _882 = _865.xyz;\n        float _887 = dot(_882, world_pos) + _865.w;\n        bool _892 = abs(_873) > 0.5f;\n        bool _900;\n        if (!_892)\n        {\n            _900 = abs(_880) > 0.5f;\n        }\n        else\n        {\n            _900 = _892;\n        }\n        bool _908;\n        if (!_900)\n        {\n            _908 = abs(_887) > 0.5f;\n        }\n        else\n        {\n            _908 = _900;\n        }\n        if (_908)\n        {\n            continue;\n        }\n        float _923 = clamp(dot(geo_normal, normalize(_882)) * _840.z, 0.0f, 1.0f);\n        if (_923 <= 0.0f)\n        {\n            continue;\n        }\n        float _943 = (clamp((0.5f - abs(_887)) * 10.0f, 0.0f, 1.0f) * _923) * _840.x;\n        float2 _951 = float2(_873 + 0.5f, 0.5f - _880);\n        float2 _961 = float2(dot(_868, _756), dot(_875, _756));\n        float2 _971 = float2(dot(_868, _759), dot(_875, _759));\n        int param_8 = _835 + 5;\n        float4 _976 = fa_light_texel(param_8);\n        int param_9 = _835 + 3;\n        float4 _981 = fa_light_texel(param_9);\n        int param_10 = _835 + 4;\n        float4 _986 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _976.xyz;\n        bool _996 = _981.z > _981.x;\n        if (_996)\n        {\n            float4 param_11 = _981;\n            float2 param_12 = _951;\n            float2 param_13 = _784;\n            float2 param_14 = _961;\n            float2 param_15 = _971;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_794 > 0.5f) && (_794 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1022 = fa_dc_to_linear(param_16);\n                float4 _3581 = tx;\n                _3581.x = _1022.x;\n                _3581.y = _1022.y;\n                _3581.z = _1022.z;\n                tx = _3581;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_943 * tex_a) * _976.w, 0.0f, 1.0f).xxx);\n        if (_986.z > _986.x)\n        {\n            float4 param_17 = _986;\n            float2 param_18 = _951;\n            float2 param_19 = _784;\n            float2 param_20 = _961;\n            float2 param_21 = _971;\n            float4 _1066 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_794 > 1.5f)\n            {\n                float3 param_22 = _1066.xyz;\n                float3 _1076 = fa_dc_to_srgb(param_22);\n                _1070 = _1076;\n            }\n            else\n            {\n                _1070 = _1066.xyz;\n            }\n            float3 _1086 = (_1070 * 2.0f) - 1.0f.xxx;\n            float2 _1091 = _1086.xy * _840.y;\n            float3 _1113 = (normalize(_868) * _1091.x) + (normalize(_875) * _1091.y);\n            float3 _1116 = normalize(normal);\n            normal = normalize(lerp(_1116, normalize((_1116 * max(_1086.z, 0.0500000007450580596923828125f)) + (_1113 - (_1116 * dot(_1116, _1113)))), clamp(_943 * (_996 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_sky_sh_coef(int k)\n{\n    float3 v = fa_env_tex.SampleLevel(fa_env_smp, float3(1.0f, 1.0f - (float((2 * (k >> 2)) + 1) * 0.25f), 1.0f - (float((2 * (k & 3)) + 1) * 0.25f)), 5.0f).xyz;\n    if (_458_fa_env_sky.w > 1.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _2333 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _2333;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_458_fa_env_sky.w > 0.5f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _458_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    return ambientColor;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_458_fa_cl_info.x) + int(_458_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _333 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _339 = fa_light_texel(param_1);\n    float _342 = _339.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _348 = _342 < 0.5f;\n    float3 l;\n    if (_348)\n    {\n        l = normalize(_333.xyz);\n    }\n    else\n    {\n        float3 _360 = _333.xyz - world_pos;\n        float _362 = length(_360);\n        dist = _362;\n        l = _360 / max(_362, 9.9999997473787516355514526367188e-05f).xxx;\n        float _377 = _362 / max(_333.w, 0.001000000047497451305389404296875f);\n        float _383 = clamp(1.0f - (_377 * _377), 0.0f, 1.0f);\n        atten = _383 * _383;\n        if (_342 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _397 = fa_light_texel(param_2);\n            float _407 = _397.w;\n            int param_3 = (li * 4) + 3;\n            float4 _413 = fa_light_texel(param_3);\n            float _414 = _413.x;\n            float cos_inner = _414;\n            if (_414 > 1.5f)\n            {\n                cos_inner = lerp(_407, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_407, cos_inner, dot(-l, normalize(_397.xyz)));\n        }\n    }\n    int _444;\n    if (_348)\n    {\n        _444 = 0;\n    }\n    else\n    {\n        _444 = (_342 > 1.5f) ? 2 : 1;\n    }\n    LightSample _3490 = { l, _339.xyz * atten, atten, 1.0f, dist, _444 };\n    return _3490;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1188;\n    if (i == 0)\n    {\n        _1188 = _1198_fa_shadow_split.x;\n    }\n    else\n    {\n        float _1204;\n        if (i == 1)\n        {\n            _1204 = _1198_fa_shadow_split.y;\n        }\n        else\n        {\n            float _1212;\n            if (i == 2)\n            {\n                _1212 = _1198_fa_shadow_split.z;\n            }\n            else\n            {\n                _1212 = _1198_fa_shadow_split.w;\n            }\n            _1204 = _1212;\n        }\n        _1188 = _1204;\n    }\n    return _1188;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1245 = fa_shadow_depth(param, param_1);\n    float _1249;\n    if (conv.x < 0.5f)\n    {\n        _1249 = _1245;\n    }\n    else\n    {\n        _1249 = (conv.y * conv.z) / (conv.z - (_1245 * (conv.z - conv.y)));\n    }\n    return _1249;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1176 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_1176), sin(_1176)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1295 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _1309 = clamp((k * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1295;\n            float2 _1328 = fa_shadow_vogel(param_3, param_4, param_5) * _1309;\n            float2 param_6 = uv + (_1328 * _1198_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1340 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1340 < (zr - (length(_1328) * plane)))\n            {\n                sum += _1340;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0f) * unit) * k) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _1384 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1384; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1384;\n        float param_11 = _1295;\n        float2 _1403 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1403 * _1198_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1403) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1384);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _1445 = max(_1198_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _1450 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1456 = sqrt(1.0f - (_1450 * _1450));\n    float _1463 = min(_1456 / max(_1450, 0.20000000298023223876953125f), 4.0f);\n    float _1468;\n    if (_1198_fa_shadow_bias.y > 0.0f)\n    {\n        _1468 = _1198_fa_shadow_bias.y;\n    }\n    else\n    {\n        _1468 = 1.5f * _1198_fa_shadow_info[ci].x;\n    }\n    float4 _1493 = mul(float4(world + (n * (_1468 * _1456)), 1.0f), _1198_fa_shadow_mat[ci]);\n    float _1500 = _1493.x;\n    bool _1503 = _1500 < _1198_fa_shadow_rect[ci].x;\n    bool _1512;\n    if (!_1503)\n    {\n        _1512 = _1500 > _1198_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1512 = _1503;\n    }\n    bool _1521;\n    if (!_1512)\n    {\n        _1521 = _1493.y < _1198_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1521 = _1512;\n    }\n    bool _1530;\n    if (!_1521)\n    {\n        _1530 = _1493.y > _1198_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1530 = _1521;\n    }\n    bool _1537;\n    if (!_1530)\n    {\n        _1537 = _1493.z > 1.0f;\n    }\n    else\n    {\n        _1537 = _1530;\n    }\n    if (_1537)\n    {\n        return -1.0f;\n    }\n    float _1546;\n    if (_1198_fa_shadow_bias.x > 0.0f)\n    {\n        _1546 = _1198_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1546 = 1.5f * _1198_fa_shadow_info[ci].x;\n    }\n    float2 param = _1493.xy;\n    float4 param_1 = _1198_fa_shadow_rect[ci];\n    float param_2 = _1493.z - ((_1546 * (1.0f + (0.5f * _1463))) / _1445);\n    float param_3 = _1198_fa_shadow_info[ci].x;\n    float param_4 = _1445;\n    float param_5 = _1445 * 0.25f;\n    float param_6 = ((_1198_fa_shadow_info[ci].x * min(_1463, 3.0f)) * 0.5f) / _1445;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_1198_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _1198_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_458_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1973 = int(_1198_fa_shadow_cfg.x + 0.5f);\n    if (_1973 < 1)\n    {\n        return 1.0f;\n    }\n    float _1988 = dot(world - _1198_fa_shadow_eye.xyz, _1198_fa_shadow_fwd.xyz);\n    int param = _1973 - 1;\n    if (_1988 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2000 = _1973 > 1;\n    bool _2007;\n    if (_2000)\n    {\n        _2007 = _1988 > _1198_fa_shadow_split.x;\n    }\n    else\n    {\n        _2007 = _2000;\n    }\n    if (_2007)\n    {\n        ci = 1;\n    }\n    bool _2011 = _1973 > 2;\n    bool _2018;\n    if (_2011)\n    {\n        _2018 = _1988 > _1198_fa_shadow_split.y;\n    }\n    else\n    {\n        _2018 = _2011;\n    }\n    if (_2018)\n    {\n        ci = 2;\n    }\n    bool _2022 = _1973 > 3;\n    bool _2029;\n    if (_2022)\n    {\n        _2029 = _1988 > _1198_fa_shadow_split.z;\n    }\n    else\n    {\n        _2029 = _2022;\n    }\n    if (_2029)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1973)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2055 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2055;\n        if (_2055 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_1198_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2080;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2080 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2080 = _1198_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2099 = _1198_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2080, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2110 = clamp((_1988 - (fa_shadow_split_at(param_7) - _2099)) / _2099, 0.0f, 1.0f);\n        if (_2110 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1973)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2131 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2131;\n                if (_2131 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2110);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _1604 = _458_fa_pbr.z < 0.5f;\n    bool _1612;\n    if (!_1604)\n    {\n        _1612 = _1198_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _1612 = _1604;\n    }\n    if (_1612)\n    {\n        return 1.0f;\n    }\n    int param = (int(_1198_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _1625 = fa_light_texel(param);\n    float _1626 = _1625.x;\n    if (_1626 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _1635 = int(_1626 + 0.5f);\n    int param_1 = _1635;\n    float4 _1639 = fa_light_texel(param_1);\n    int param_2 = _1635 + 1;\n    float4 _1644 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _1647 = _1639.y;\n    if (_1647 > 0.0f)\n    {\n        float _1664 = 1.0f - smoothstep(0.75f * _1647, _1647, length(world - _1198_fa_shadow_eye.xyz));\n        fade = _1664;\n        if (_1664 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_1639.x > 1.5f)\n    {\n        int param_3 = li * 4;\n        float3 _1683 = world - fa_light_texel(param_3).xyz;\n        float3 _1686 = abs(_1683);\n        float _1688 = _1686.x;\n        float _1690 = _1686.y;\n        bool _1691 = _1688 >= _1690;\n        bool _1699;\n        if (_1691)\n        {\n            _1699 = _1688 >= _1686.z;\n        }\n        else\n        {\n            _1699 = _1691;\n        }\n        int _1700;\n        if (_1699)\n        {\n            _1700 = (_1683.x > 0.0f) ? 0 : 1;\n        }\n        else\n        {\n            int _1713;\n            if (_1690 >= _1686.z)\n            {\n                _1713 = (_1683.y > 0.0f) ? 2 : 3;\n            }\n            else\n            {\n                _1713 = (_1683.z > 0.0f) ? 4 : 5;\n            }\n            _1700 = _1713;\n        }\n        face = _1700;\n    }\n    int _1732 = (_1635 + 2) + (face * 6);\n    int param_4 = _1732;\n    int param_5 = _1732 + 1;\n    int param_6 = _1732 + 3;\n    float4 _1746 = fa_light_texel(param_6);\n    int param_7 = _1732 + 4;\n    float4 _1751 = fa_light_texel(param_7);\n    int param_8 = _1732 + 5;\n    float4 _1756 = fa_light_texel(param_8);\n    float _1768 = _1756.x * max(dot(_1746, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _1773 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1796 = clamp(dot(n, _1746.xyz), -1.0f, 1.0f);\n    int param_9 = li * 4;\n    float _1819 = min(sqrt(1.0f - (_1796 * _1796)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1746, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _1822 = _1644.y;\n    float _1824;\n    if (_1822 > 0.0f)\n    {\n        _1824 = _1822;\n    }\n    else\n    {\n        _1824 = 1.5f * _1768;\n    }\n    float4 _1844 = float4(world + (n * (_1824 * sqrt(1.0f - (_1773 * _1773)))), 1.0f);\n    float _1848 = dot(_1746, _1844);\n    float _1851 = _1756.y;\n    if (_1848 < _1851)\n    {\n        return 1.0f;\n    }\n    float2 _1866 = float2(dot(fa_light_texel(param_4), _1844), dot(fa_light_texel(param_5), _1844)) / _1848.xx;\n    float _1868 = _1866.x;\n    bool _1871 = _1868 < _1751.x;\n    bool _1880;\n    if (!_1871)\n    {\n        _1880 = _1868 > _1751.z;\n    }\n    else\n    {\n        _1880 = _1871;\n    }\n    bool _1889;\n    if (!_1880)\n    {\n        _1889 = _1866.y < _1751.y;\n    }\n    else\n    {\n        _1889 = _1880;\n    }\n    bool _1898;\n    if (!_1889)\n    {\n        _1898 = _1866.y > _1751.w;\n    }\n    else\n    {\n        _1898 = _1889;\n    }\n    if (_1898)\n    {\n        return 1.0f;\n    }\n    float _1904 = _1644.x;\n    float _1906;\n    if (_1904 > 0.0f)\n    {\n        _1906 = _1904;\n    }\n    else\n    {\n        _1906 = 1.5f * _1768;\n    }\n    float2 param_10 = _1866;\n    float4 param_11 = _1751;\n    float param_12 = _1848 - (_1906 * (1.0f + (0.5f * _1819)));\n    float param_13 = _1768;\n    float param_14 = 1.0f;\n    float param_15 = _1756.z * 0.25f;\n    float param_16 = (_1768 * min(_1819, 3.0f)) * 0.5f;\n    float3 param_17 = float3(1.0f, _1851, _1756.z);\n    int param_18 = int(_1639.z + 0.5f);\n    float param_19 = _1639.w;\n    return lerp(1.0f, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _2447 = fa_lm.z > 0.5f;\n    bool _2453;\n    if (_2447)\n    {\n        int param = li;\n        _2453 = fa_light_baked(param);\n    }\n    else\n    {\n        _2453 = _2447;\n    }\n    if (_2453)\n    {\n        int param_1 = li;\n        LightSample _3503 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _3503;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _2476 = fa_light_sample(param_2, param_3);\n    float3 _3510 = _2476.direction;\n    float3 _3505 = _2476.color;\n    float _3512 = _2476.attenuation;\n    float _3507 = _2476.shadow;\n    int _3515 = _2476.type;\n    if ((_3515 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _3510;\n        float _2490 = fa_shadow_factor(param_4, param_5);\n        _3507 = _2490;\n        _3505 *= _2490;\n    }\n    else\n    {\n        bool _2501 = _3515 != 0;\n        bool _2507;\n        if (_2501)\n        {\n            _2507 = _3512 > 0.0f;\n        }\n        else\n        {\n            _2507 = _2501;\n        }\n        if (_2507)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _3510;\n            float _2519 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _3507 = _2519;\n            _3505 *= _2519;\n        }\n    }\n    LightSample _3522 = { _3510, _3505, _3512, _3507, _2476._distance, _3515 };\n    return _3522;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_1198_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _2155 = int(_1198_fa_shadow_cfg.x + 0.5f);\n    float _2165 = dot(world - _1198_fa_shadow_eye.xyz, _1198_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _2170 = _2155 > 0;\n    bool _2179;\n    if (_2170)\n    {\n        int param = _2155 - 1;\n        _2179 = _2165 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2179 = _2170;\n    }\n    if (_2179)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _2186 = _2155 > 1;\n        bool _2193;\n        if (_2186)\n        {\n            _2193 = _2165 > _1198_fa_shadow_split.x;\n        }\n        else\n        {\n            _2193 = _2186;\n        }\n        if (_2193)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _2199 = _2155 > 2;\n        bool _2206;\n        if (_2199)\n        {\n            _2206 = _2165 > _1198_fa_shadow_split.y;\n        }\n        else\n        {\n            _2206 = _2199;\n        }\n        if (_2206)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _2212 = _2155 > 3;\n        bool _2219;\n        if (_2212)\n        {\n            _2219 = _2165 > _1198_fa_shadow_split.z;\n        }\n        else\n        {\n            _2219 = _2212;\n        }\n        if (_2219)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _3321 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3321 = -_3321;\n    }\n    float3 _2906 = normalize(_458_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _3334 = { fa_world_pos, _3321, fa_world_tangent, fa_uv, fa_vertex_color, _2906, gl_FrontFacing };\n    SurfaceInput param_1 = _3334;\n    Surface _2914 = fa_standard_surface(param_1);\n    float3 _3360 = _2914.albedo;\n    float _3361 = _2914.alpha;\n    float3 _3362 = _2914.normal;\n    float _3363 = _2914.metallic;\n    float _3364 = _2914.roughness;\n    float _3365 = _2914.occlusion;\n    float3 _3366 = _2914.emission;\n    float _3367 = _2914.clearcoat;\n    float _3368 = _2914.clearcoat_roughness;\n    float3 _3369 = _2914.sheen_color;\n    float _3370 = _2914.sheen_roughness;\n    float _3371 = _2914.anisotropy;\n    float _3372 = _2914.anisotropy_rotation;\n    float _3373 = _2914.specular;\n    float _3374 = _2914.ior;\n    float3 _3375 = _2914.specular_color;\n    SurfaceInput _3342 = { fa_world_pos, _3321, fa_world_tangent, fa_uv, fa_vertex_color, _2906, gl_FrontFacing };\n    SurfaceInput param_2 = _3342;\n    Surface param_3 = _2914;\n    surface(param_2, param_3);\n    _3360 = param_3.albedo;\n    _3361 = param_3.alpha;\n    _3362 = param_3.normal;\n    _3363 = param_3.metallic;\n    _3364 = param_3.roughness;\n    _3365 = param_3.occlusion;\n    _3366 = param_3.emission;\n    _3367 = param_3.clearcoat;\n    _3368 = param_3.clearcoat_roughness;\n    _3369 = param_3.sheen_color;\n    _3370 = param_3.sheen_roughness;\n    _3371 = param_3.anisotropy;\n    _3372 = param_3.anisotropy_rotation;\n    _3373 = param_3.specular;\n    _3374 = param_3.ior;\n    _3375 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _3321;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _3360 = param_6;\n    _3362 = param_7;\n    float3 result;\n    if (_458_fa_emissive.w > 0.5f)\n    {\n        result = _3360;\n    }\n    else\n    {\n        float3 _2952 = _3362;\n        float3 _2953 = normalize(_2952);\n        _3362 = _2953;\n        float3 param_8 = _2953;\n        SurfaceInput _3350 = { fa_world_pos, _3321, fa_world_tangent, fa_uv, fa_vertex_color, _2906, gl_FrontFacing };\n        SurfaceInput param_9 = _3350;\n        Surface _3441 = { _3360, _3361, _3362, _3363, _3364, _3365, _3366, _3367, _3368, _3369, _3370, _3371, _3372, _3373, _3374, _3375 };\n        Surface param_10 = _3441;\n        float3 param_11 = fa_indirect_diffuse(param_8);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _2972 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2972; ln++)\n        {\n            int param_12 = ln;\n            int _2985 = fa_cl_light(param_12);\n            bool _2988 = fa_lm.z > 0.5f;\n            bool _2994;\n            if (_2988)\n            {\n                int param_13 = _2985;\n                _2994 = fa_light_baked(param_13);\n            }\n            else\n            {\n                _2994 = _2988;\n            }\n            if (_2994)\n            {\n                continue;\n            }\n            int param_14 = _2985;\n            float3 param_15 = fa_world_pos;\n            float3 param_16 = _3321;\n            SurfaceInput _3358 = { fa_world_pos, _3321, fa_world_tangent, fa_uv, fa_vertex_color, _2906, gl_FrontFacing };\n            SurfaceInput param_17 = _3358;\n            Surface _3458 = { _3360, _3361, _3362, _3363, _3364, _3365, _3366, _3367, _3368, _3369, _3370, _3371, _3372, _3373, _3374, _3375 };\n            Surface param_18 = _3458;\n            LightSample param_19 = fa_light_shadowed(param_14, param_15, param_16);\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _3021 = result;\n    float3 _3022 = _3021 + _3366;\n    result = _3022;\n    float3 param_20 = _3022;\n    float3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _3031 = _458_fa_fog.w > 0.0f;\n    bool _3038;\n    if (!_3031)\n    {\n        _3038 = _458_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _3038 = _3031;\n    }\n    if (_3038)\n    {\n        float3 _3047 = fa_world_pos - _458_fa_camera_pos.xyz;\n        float _3053 = dot(_3047, _458_fa_fog_c.xyz);\n        bool _3057 = _458_fa_fog_c.w > 0.5f;\n        float _3058;\n        if (_3057)\n        {\n            _3058 = _3053;\n        }\n        else\n        {\n            _3058 = length(_3047);\n        }\n        float _3070 = _3058 - _458_fa_fog_b.x;\n        if (_3070 > 0.0f)\n        {\n            float _3079 = _458_fa_fog.w * _3070;\n            float tau = _3079 * _3079;\n            if (_458_fa_fog_b.y > 0.0f)\n            {\n                float _3095;\n                if (_3057)\n                {\n                    _3095 = fa_world_pos.y - (_458_fa_fog_c.y * _3053);\n                }\n                else\n                {\n                    _3095 = _458_fa_camera_pos.y;\n                }\n                float _3116 = lerp(_3095, fa_world_pos.y, clamp(_458_fa_fog_b.x / _3058, 0.0f, 1.0f));\n                float _3120 = fa_world_pos.y - _3116;\n                float _3125 = _3116 - _458_fa_fog_b.z;\n                float _3130 = fa_world_pos.y - _458_fa_fog_b.z;\n                bool _3133 = _3125 <= 0.0f;\n                bool _3134 = !_3133;\n                bool _3140;\n                if (_3134)\n                {\n                    _3140 = _458_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3140 = _3133;\n                }\n                float _3141;\n                if (_3140)\n                {\n                    _3141 = _458_fa_fog_b.y;\n                }\n                else\n                {\n                    _3141 = _458_fa_fog_b.y * exp(-min(_458_fa_fog_b.w * _3125, 80.0f));\n                }\n                bool _3168;\n                if (_3134)\n                {\n                    _3168 = _458_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3168 = _3133;\n                }\n                float _3169;\n                if (_3168)\n                {\n                    _3169 = _458_fa_fog_b.y * _3125;\n                }\n                else\n                {\n                    _3169 = (_458_fa_fog_b.y * (1.0f - exp(-min(_458_fa_fog_b.w * _3125, 80.0f)))) / _458_fa_fog_b.w;\n                }\n                bool _3194 = _3130 <= 0.0f;\n                bool _3201;\n                if (!_3194)\n                {\n                    _3201 = _458_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3201 = _3194;\n                }\n                float _3202;\n                if (_3201)\n                {\n                    _3202 = _458_fa_fog_b.y * _3130;\n                }\n                else\n                {\n                    _3202 = (_458_fa_fog_b.y * (1.0f - exp(-min(_458_fa_fog_b.w * _3130, 80.0f)))) / _458_fa_fog_b.w;\n                }\n                float _3229;\n                if (abs(_3120) < 0.001000000047497451305389404296875f)\n                {\n                    _3229 = _3141;\n                }\n                else\n                {\n                    _3229 = (_3202 - _3169) / _3120;\n                }\n                tau += (_3070 * max(_3229, 0.0f));\n            }\n            result = lerp(result, _458_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _3361);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_458",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1198",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _458_fa_camera_pos : packoffset(c0);\n    float4 _458_fa_ambient : packoffset(c1);\n    float4 _458_fa_base_color : packoffset(c2);\n    float4 _458_fa_emissive : packoffset(c3);\n    float4 _458_fa_model_emissive : packoffset(c4);\n    float4 _458_fa_pbr : packoffset(c5);\n    float4 _458_fa_maps : packoffset(c6);\n    float4 _458_fa_fog : packoffset(c7);\n    float4 _458_fa_fog_b : packoffset(c8);\n    float4 _458_fa_fog_c : packoffset(c9);\n    float4 _458_fa_counts : packoffset(c10);\n    float4 _458_fa_env_sky : packoffset(c11);\n    float4 _458_fa_env_horizon : packoffset(c12);\n    float4 _458_fa_time : packoffset(c13);\n    float4 _458_fa_cl_vpx : packoffset(c14);\n    float4 _458_fa_cl_vpy : packoffset(c15);\n    float4 _458_fa_cl_vpw : packoffset(c16);\n    float4 _458_fa_cl_fwd : packoffset(c17);\n    float4 _458_fa_cl_grid : packoffset(c18);\n    float4 _458_fa_cl_info : packoffset(c19);\n    float4 _458_fa_layers_a : packoffset(c20);\n    float4 _458_fa_layers_b : packoffset(c21);\n    float4 _458_fa_layers_c : packoffset(c22);\n    float4 _458_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _1198_fa_shadow_mat[4] : packoffset(c0);\n    float4 _1198_fa_shadow_rect[4] : packoffset(c16);\n    float4 _1198_fa_shadow_info[4] : packoffset(c20);\n    float4 _1198_fa_shadow_split : packoffset(c24);\n    float4 _1198_fa_shadow_cfg : packoffset(c25);\n    float4 _1198_fa_shadow_bias : packoffset(c26);\n    float4 _1198_fa_shadow_eye : packoffset(c27);\n    float4 _1198_fa_shadow_fwd : packoffset(c28);\n    float4 _1198_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_decal_tex : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t8);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _463 = _458_fa_cl_info.x < 0.0f;\n    bool _470;\n    if (!_463)\n    {\n        _470 = _458_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _470 = _463;\n    }\n    bool _478;\n    if (!_470)\n    {\n        _478 = _458_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _478 = _470;\n    }\n    bool _485;\n    if (!_478)\n    {\n        _485 = _458_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _485 = _478;\n    }\n    bool _492;\n    if (!_485)\n    {\n        _492 = _458_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _492 = _485;\n    }\n    if (_492)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _502 = float4(world_pos, 1.0f);\n    float _509 = dot(_458_fa_cl_vpw, _502);\n    if (!(_509 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _531 = float2(dot(_458_fa_cl_vpx, _502), dot(_458_fa_cl_vpy, _502)) / _509.xx;\n    int _535 = int(_458_fa_cl_grid.x);\n    int _539 = int(_458_fa_cl_grid.y);\n    int param = (int(_458_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_458_fa_cl_fwd.xyz, world_pos) + _458_fa_cl_fwd.w, _458_fa_cl_grid.w) / _458_fa_cl_grid.w) * _458_fa_cl_grid.z)), 0, int(_458_fa_cl_info.y) - 1) * _539) + clamp(int(floor(((_531.y * 0.5f) + 0.5f) * _458_fa_cl_grid.y)), 0, _539 - 1)) * _535)) + clamp(int(floor(((_531.x * 0.5f) + 0.5f) * _458_fa_cl_grid.x)), 0, _535 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _615 = fa_cluster_texel(param);\n    return int2(int(_615.x), int(_615.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_458_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2420 = fa_cluster_lookup(param);\n    fa_cl_slot = _2420.x;\n    fa_cl_local = _2420.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _2571 = fa_linear_to_srgb(param);\n        c = _2571;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _2579 = fa_srgb_to_linear(param_1);\n            c = _2579;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _223;\n    if (i.front_facing)\n    {\n        _223 = i.world_normal;\n    }\n    else\n    {\n        _223 = -i.world_normal;\n    }\n    float3 _247 = normalize(i.world_tangent.xyz - (_223 * dot(_223, i.world_tangent.xyz)));\n    float3 _274 = normalize(((_247 * m.x) + ((cross(_223, _247) * i.world_tangent.w) * m.y)) + (_223 * m.z));\n    float3 _277;\n    if (i.front_facing)\n    {\n        _277 = _274;\n    }\n    else\n    {\n        _277 = -_274;\n    }\n    return _277;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _458_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2610 = fa_tex_fix(param_2, param_3);\n    float4 _3645 = base_t;\n    _3645.x = _2610.x;\n    _3645.y = _2610.y;\n    _3645.z = _2610.z;\n    base_t = _3645;\n    float4 _2624 = (_3645 * _458_fa_base_color) * i.vertex_color;\n    float3 _3525 = i.world_normal;\n    if (_458_fa_maps.z > 0.5f)\n    {\n        float param_4 = _458_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2656 = fa_tex_fix(param_6, param_7);\n        float3 _2659 = (_2656 * 2.0f) - 1.0f.xxx;\n        float2 _2664 = _2659.xy * _458_fa_maps.x;\n        float3 _3653 = _2659;\n        _3653.x = _2664.x;\n        _3653.y = _2664.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3653;\n        _3525 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _458_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2693 = fa_tex_fix(param_12, param_13);\n    float4 _3656 = mrt;\n    _3656.x = _2693.x;\n    _3656.y = _2693.y;\n    _3656.z = _2693.z;\n    mrt = _3656;\n    float4 _2721 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _458_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _2721.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2733 = fa_tex_fix(param_16, param_17);\n    float param_18 = _458_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2763 = fa_tex_fix(param_20, param_21);\n    float _3530 = _458_fa_layers_a.x;\n    float _3531 = _458_fa_layers_a.y;\n    float _3534 = _458_fa_layers_a.z;\n    float _3533 = _458_fa_layers_b.w;\n    float _3536 = _458_fa_layers_c.x;\n    if (_458_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_458_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _3530 *= _2733.y;\n            _3531 *= _2733.z;\n            _3533 *= _2721.w;\n        }\n        if (_458_fa_layers_c.z > 1.5f)\n        {\n            _3534 *= mrt.x;\n            _3536 *= mrt.w;\n        }\n    }\n    Surface _3555 = { _2624.xyz, _2624.w, _3525, clamp(_458_fa_pbr.x * _2693.z, 0.0f, 1.0f), clamp(_458_fa_pbr.y * _2693.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_458_fa_maps.y * (_2733.x - 1.0f)), _458_fa_emissive.xyz + (_458_fa_model_emissive.xyz * _2763), _3530, _3531, _458_fa_layers_b.xyz, _3533, _3534, _458_fa_layers_a.w, _3536, _458_fa_layers_c.y, _458_fa_layers_d.xyz };\n    return _3555;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _696 = rect.zw - rect.xy;\n    float2 _700 = _696 * atlas;\n    float2 _704 = ddx * _700;\n    float2 _708 = ddy * _700;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _696), clamp(0.5f * log2(max(max(dot(_704, _704), dot(_708, _708)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _743 = _458_fa_counts.y < 0.5f;\n    bool _750;\n    if (!_743)\n    {\n        _750 = _458_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _750 = _743;\n    }\n    if (_750)\n    {\n        return;\n    }\n    float3 _756 = ddx(world_pos);\n    float3 _759 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _763 = fa_cluster_texel(param);\n    int _767 = int(_763.w);\n    if (_767 < 1)\n    {\n        return;\n    }\n    int _777 = int(_458_fa_counts.y + 0.5f);\n    int param_1 = _777;\n    float4 _781 = fa_light_texel(param_1);\n    float2 _784 = _781.yz;\n    int _788 = int(_781.w);\n    int param_2 = _777 + 1;\n    float4 _793 = fa_light_texel(param_2);\n    float _794 = _793.x;\n    int _800 = int(_458_fa_counts.w + 0.5f) - 1;\n    int _804 = int(_763.z);\n    float3 _1070;\n    for (int k = 0; k < _767; k++)\n    {\n        int _817 = _804 + k;\n        int param_3 = _788 + (_817 >> 2);\n        int _835 = (_777 + 2) + (int(fa_light_texel(param_3)[_817 & 3]) * 7);\n        int param_4 = _835 + 6;\n        float4 _840 = fa_light_texel(param_4);\n        if (((int(_840.w + 0.5f) >> _800) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _835;\n        float4 _855 = fa_light_texel(param_5);\n        int param_6 = _835 + 1;\n        float4 _860 = fa_light_texel(param_6);\n        int param_7 = _835 + 2;\n        float4 _865 = fa_light_texel(param_7);\n        float3 _868 = _855.xyz;\n        float _873 = dot(_868, world_pos) + _855.w;\n        float3 _875 = _860.xyz;\n        float _880 = dot(_875, world_pos) + _860.w;\n        float3 _882 = _865.xyz;\n        float _887 = dot(_882, world_pos) + _865.w;\n        bool _892 = abs(_873) > 0.5f;\n        bool _900;\n        if (!_892)\n        {\n            _900 = abs(_880) > 0.5f;\n        }\n        else\n        {\n            _900 = _892;\n        }\n        bool _908;\n        if (!_900)\n        {\n            _908 = abs(_887) > 0.5f;\n        }\n        else\n        {\n            _908 = _900;\n        }\n        if (_908)\n        {\n            continue;\n        }\n        float _923 = clamp(dot(geo_normal, normalize(_882)) * _840.z, 0.0f, 1.0f);\n        if (_923 <= 0.0f)\n        {\n            continue;\n        }\n        float _943 = (clamp((0.5f - abs(_887)) * 10.0f, 0.0f, 1.0f) * _923) * _840.x;\n        float2 _951 = float2(_873 + 0.5f, 0.5f - _880);\n        float2 _961 = float2(dot(_868, _756), dot(_875, _756));\n        float2 _971 = float2(dot(_868, _759), dot(_875, _759));\n        int param_8 = _835 + 5;\n        float4 _976 = fa_light_texel(param_8);\n        int param_9 = _835 + 3;\n        float4 _981 = fa_light_texel(param_9);\n        int param_10 = _835 + 4;\n        float4 _986 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _976.xyz;\n        bool _996 = _981.z > _981.x;\n        if (_996)\n        {\n            float4 param_11 = _981;\n            float2 param_12 = _951;\n            float2 param_13 = _784;\n            float2 param_14 = _961;\n            float2 param_15 = _971;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_794 > 0.5f) && (_794 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1022 = fa_dc_to_linear(param_16);\n                float4 _3581 = tx;\n                _3581.x = _1022.x;\n                _3581.y = _1022.y;\n                _3581.z = _1022.z;\n                tx = _3581;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_943 * tex_a) * _976.w, 0.0f, 1.0f).xxx);\n        if (_986.z > _986.x)\n        {\n            float4 param_17 = _986;\n            float2 param_18 = _951;\n            float2 param_19 = _784;\n            float2 param_20 = _961;\n            float2 param_21 = _971;\n            float4 _1066 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_794 > 1.5f)\n            {\n                float3 param_22 = _1066.xyz;\n                float3 _1076 = fa_dc_to_srgb(param_22);\n                _1070 = _1076;\n            }\n            else\n            {\n                _1070 = _1066.xyz;\n            }\n            float3 _1086 = (_1070 * 2.0f) - 1.0f.xxx;\n            float2 _1091 = _1086.xy * _840.y;\n            float3 _1113 = (normalize(_868) * _1091.x) + (normalize(_875) * _1091.y);\n            float3 _1116 = normalize(normal);\n            normal = normalize(lerp(_1116, normalize((_1116 * max(_1086.z, 0.0500000007450580596923828125f)) + (_1113 - (_1116 * dot(_1116, _1113)))), clamp(_943 * (_996 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_sky_sh_coef(int k)\n{\n    float3 v = fa_env_tex.SampleLevel(fa_env_smp, float3(1.0f, 1.0f - (float((2 * (k >> 2)) + 1) * 0.25f), 1.0f - (float((2 * (k & 3)) + 1) * 0.25f)), 5.0f).xyz;\n    if (_458_fa_env_sky.w > 1.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _2333 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _2333;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_458_fa_env_sky.w > 0.5f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _458_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    return ambientColor;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_458_fa_cl_info.x) + int(_458_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _333 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _339 = fa_light_texel(param_1);\n    float _342 = _339.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _348 = _342 < 0.5f;\n    float3 l;\n    if (_348)\n    {\n        l = normalize(_333.xyz);\n    }\n    else\n    {\n        float3 _360 = _333.xyz - world_pos;\n        float _362 = length(_360);\n        dist = _362;\n        l = _360 / max(_362, 9.9999997473787516355514526367188e-05f).xxx;\n        float _377 = _362 / max(_333.w, 0.001000000047497451305389404296875f);\n        float _383 = clamp(1.0f - (_377 * _377), 0.0f, 1.0f);\n        atten = _383 * _383;\n        if (_342 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _397 = fa_light_texel(param_2);\n            float _407 = _397.w;\n            int param_3 = (li * 4) + 3;\n            float4 _413 = fa_light_texel(param_3);\n            float _414 = _413.x;\n            float cos_inner = _414;\n            if (_414 > 1.5f)\n            {\n                cos_inner = lerp(_407, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_407, cos_inner, dot(-l, normalize(_397.xyz)));\n        }\n    }\n    int _444;\n    if (_348)\n    {\n        _444 = 0;\n    }\n    else\n    {\n        _444 = (_342 > 1.5f) ? 2 : 1;\n    }\n    LightSample _3490 = { l, _339.xyz * atten, atten, 1.0f, dist, _444 };\n    return _3490;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1188;\n    if (i == 0)\n    {\n        _1188 = _1198_fa_shadow_split.x;\n    }\n    else\n    {\n        float _1204;\n        if (i == 1)\n        {\n            _1204 = _1198_fa_shadow_split.y;\n        }\n        else\n        {\n            float _1212;\n            if (i == 2)\n            {\n                _1212 = _1198_fa_shadow_split.z;\n            }\n            else\n            {\n                _1212 = _1198_fa_shadow_split.w;\n            }\n            _1204 = _1212;\n        }\n        _1188 = _1204;\n    }\n    return _1188;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1245 = fa_shadow_depth(param, param_1);\n    float _1249;\n    if (conv.x < 0.5f)\n    {\n        _1249 = _1245;\n    }\n    else\n    {\n        _1249 = (conv.y * conv.z) / (conv.z - (_1245 * (conv.z - conv.y)));\n    }\n    return _1249;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1176 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_1176), sin(_1176)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1295 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _1309 = clamp((k * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1295;\n            float2 _1328 = fa_shadow_vogel(param_3, param_4, param_5) * _1309;\n            float2 param_6 = uv + (_1328 * _1198_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1340 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1340 < (zr - (length(_1328) * plane)))\n            {\n                sum += _1340;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0f) * unit) * k) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _1384 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1384; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1384;\n        float param_11 = _1295;\n        float2 _1403 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1403 * _1198_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1403) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1384);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _1445 = max(_1198_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _1450 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1456 = sqrt(1.0f - (_1450 * _1450));\n    float _1463 = min(_1456 / max(_1450, 0.20000000298023223876953125f), 4.0f);\n    float _1468;\n    if (_1198_fa_shadow_bias.y > 0.0f)\n    {\n        _1468 = _1198_fa_shadow_bias.y;\n    }\n    else\n    {\n        _1468 = 1.5f * _1198_fa_shadow_info[ci].x;\n    }\n    float4 _1493 = mul(float4(world + (n * (_1468 * _1456)), 1.0f), _1198_fa_shadow_mat[ci]);\n    float _1500 = _1493.x;\n    bool _1503 = _1500 < _1198_fa_shadow_rect[ci].x;\n    bool _1512;\n    if (!_1503)\n    {\n        _1512 = _1500 > _1198_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1512 = _1503;\n    }\n    bool _1521;\n    if (!_1512)\n    {\n        _1521 = _1493.y < _1198_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1521 = _1512;\n    }\n    bool _1530;\n    if (!_1521)\n    {\n        _1530 = _1493.y > _1198_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1530 = _1521;\n    }\n    bool _1537;\n    if (!_1530)\n    {\n        _1537 = _1493.z > 1.0f;\n    }\n    else\n    {\n        _1537 = _1530;\n    }\n    if (_1537)\n    {\n        return -1.0f;\n    }\n    float _1546;\n    if (_1198_fa_shadow_bias.x > 0.0f)\n    {\n        _1546 = _1198_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1546 = 1.5f * _1198_fa_shadow_info[ci].x;\n    }\n    float2 param = _1493.xy;\n    float4 param_1 = _1198_fa_shadow_rect[ci];\n    float param_2 = _1493.z - ((_1546 * (1.0f + (0.5f * _1463))) / _1445);\n    float param_3 = _1198_fa_shadow_info[ci].x;\n    float param_4 = _1445;\n    float param_5 = _1445 * 0.25f;\n    float param_6 = ((_1198_fa_shadow_info[ci].x * min(_1463, 3.0f)) * 0.5f) / _1445;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_1198_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _1198_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_458_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1973 = int(_1198_fa_shadow_cfg.x + 0.5f);\n    if (_1973 < 1)\n    {\n        return 1.0f;\n    }\n    float _1988 = dot(world - _1198_fa_shadow_eye.xyz, _1198_fa_shadow_fwd.xyz);\n    int param = _1973 - 1;\n    if (_1988 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2000 = _1973 > 1;\n    bool _2007;\n    if (_2000)\n    {\n        _2007 = _1988 > _1198_fa_shadow_split.x;\n    }\n    else\n    {\n        _2007 = _2000;\n    }\n    if (_2007)\n    {\n        ci = 1;\n    }\n    bool _2011 = _1973 > 2;\n    bool _2018;\n    if (_2011)\n    {\n        _2018 = _1988 > _1198_fa_shadow_split.y;\n    }\n    else\n    {\n        _2018 = _2011;\n    }\n    if (_2018)\n    {\n        ci = 2;\n    }\n    bool _2022 = _1973 > 3;\n    bool _2029;\n    if (_2022)\n    {\n        _2029 = _1988 > _1198_fa_shadow_split.z;\n    }\n    else\n    {\n        _2029 = _2022;\n    }\n    if (_2029)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1973)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2055 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2055;\n        if (_2055 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_1198_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2080;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2080 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2080 = _1198_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2099 = _1198_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2080, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2110 = clamp((_1988 - (fa_shadow_split_at(param_7) - _2099)) / _2099, 0.0f, 1.0f);\n        if (_2110 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1973)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2131 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2131;\n                if (_2131 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2110);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _1604 = _458_fa_pbr.z < 0.5f;\n    bool _1612;\n    if (!_1604)\n    {\n        _1612 = _1198_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _1612 = _1604;\n    }\n    if (_1612)\n    {\n        return 1.0f;\n    }\n    int param = (int(_1198_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _1625 = fa_light_texel(param);\n    float _1626 = _1625.x;\n    if (_1626 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _1635 = int(_1626 + 0.5f);\n    int param_1 = _1635;\n    float4 _1639 = fa_light_texel(param_1);\n    int param_2 = _1635 + 1;\n    float4 _1644 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _1647 = _1639.y;\n    if (_1647 > 0.0f)\n    {\n        float _1664 = 1.0f - smoothstep(0.75f * _1647, _1647, length(world - _1198_fa_shadow_eye.xyz));\n        fade = _1664;\n        if (_1664 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_1639.x > 1.5f)\n    {\n        int param_3 = li * 4;\n        float3 _1683 = world - fa_light_texel(param_3).xyz;\n        float3 _1686 = abs(_1683);\n        float _1688 = _1686.x;\n        float _1690 = _1686.y;\n        bool _1691 = _1688 >= _1690;\n        bool _1699;\n        if (_1691)\n        {\n            _1699 = _1688 >= _1686.z;\n        }\n        else\n        {\n            _1699 = _1691;\n        }\n        int _1700;\n        if (_1699)\n        {\n            _1700 = (_1683.x > 0.0f) ? 0 : 1;\n        }\n        else\n        {\n            int _1713;\n            if (_1690 >= _1686.z)\n            {\n                _1713 = (_1683.y > 0.0f) ? 2 : 3;\n            }\n            else\n            {\n                _1713 = (_1683.z > 0.0f) ? 4 : 5;\n            }\n            _1700 = _1713;\n        }\n        face = _1700;\n    }\n    int _1732 = (_1635 + 2) + (face * 6);\n    int param_4 = _1732;\n    int param_5 = _1732 + 1;\n    int param_6 = _1732 + 3;\n    float4 _1746 = fa_light_texel(param_6);\n    int param_7 = _1732 + 4;\n    float4 _1751 = fa_light_texel(param_7);\n    int param_8 = _1732 + 5;\n    float4 _1756 = fa_light_texel(param_8);\n    float _1768 = _1756.x * max(dot(_1746, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _1773 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1796 = clamp(dot(n, _1746.xyz), -1.0f, 1.0f);\n    int param_9 = li * 4;\n    float _1819 = min(sqrt(1.0f - (_1796 * _1796)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1746, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _1822 = _1644.y;\n    float _1824;\n    if (_1822 > 0.0f)\n    {\n        _1824 = _1822;\n    }\n    else\n    {\n        _1824 = 1.5f * _1768;\n    }\n    float4 _1844 = float4(world + (n * (_1824 * sqrt(1.0f - (_1773 * _1773)))), 1.0f);\n    float _1848 = dot(_1746, _1844);\n    float _1851 = _1756.y;\n    if (_1848 < _1851)\n    {\n        return 1.0f;\n    }\n    float2 _1866 = float2(dot(fa_light_texel(param_4), _1844), dot(fa_light_texel(param_5), _1844)) / _1848.xx;\n    float _1868 = _1866.x;\n    bool _1871 = _1868 < _1751.x;\n    bool _1880;\n    if (!_1871)\n    {\n        _1880 = _1868 > _1751.z;\n    }\n    else\n    {\n        _1880 = _1871;\n    }\n    bool _1889;\n    if (!_1880)\n    {\n        _1889 = _1866.y < _1751.y;\n    }\n    else\n    {\n        _1889 = _1880;\n    }\n    bool _1898;\n    if (!_1889)\n    {\n        _1898 = _1866.y > _1751.w;\n    }\n    else\n    {\n        _1898 = _1889;\n    }\n    if (_1898)\n    {\n        return 1.0f;\n    }\n    float _1904 = _1644.x;\n    float _1906;\n    if (_1904 > 0.0f)\n    {\n        _1906 = _1904;\n    }\n    else\n    {\n        _1906 = 1.5f * _1768;\n    }\n    float2 param_10 = _1866;\n    float4 param_11 = _1751;\n    float param_12 = _1848 - (_1906 * (1.0f + (0.5f * _1819)));\n    float param_13 = _1768;\n    float param_14 = 1.0f;\n    float param_15 = _1756.z * 0.25f;\n    float param_16 = (_1768 * min(_1819, 3.0f)) * 0.5f;\n    float3 param_17 = float3(1.0f, _1851, _1756.z);\n    int param_18 = int(_1639.z + 0.5f);\n    float param_19 = _1639.w;\n    return lerp(1.0f, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _2447 = fa_lm.z > 0.5f;\n    bool _2453;\n    if (_2447)\n    {\n        int param = li;\n        _2453 = fa_light_baked(param);\n    }\n    else\n    {\n        _2453 = _2447;\n    }\n    if (_2453)\n    {\n        int param_1 = li;\n        LightSample _3503 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _3503;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _2476 = fa_light_sample(param_2, param_3);\n    float3 _3510 = _2476.direction;\n    float3 _3505 = _2476.color;\n    float _3512 = _2476.attenuation;\n    float _3507 = _2476.shadow;\n    int _3515 = _2476.type;\n    if ((_3515 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _3510;\n        float _2490 = fa_shadow_factor(param_4, param_5);\n        _3507 = _2490;\n        _3505 *= _2490;\n    }\n    else\n    {\n        bool _2501 = _3515 != 0;\n        bool _2507;\n        if (_2501)\n        {\n            _2507 = _3512 > 0.0f;\n        }\n        else\n        {\n            _2507 = _2501;\n        }\n        if (_2507)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _3510;\n            float _2519 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _3507 = _2519;\n            _3505 *= _2519;\n        }\n    }\n    LightSample _3522 = { _3510, _3505, _3512, _3507, _2476._distance, _3515 };\n    return _3522;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_1198_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _2155 = int(_1198_fa_shadow_cfg.x + 0.5f);\n    float _2165 = dot(world - _1198_fa_shadow_eye.xyz, _1198_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _2170 = _2155 > 0;\n    bool _2179;\n    if (_2170)\n    {\n        int param = _2155 - 1;\n        _2179 = _2165 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2179 = _2170;\n    }\n    if (_2179)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _2186 = _2155 > 1;\n        bool _2193;\n        if (_2186)\n        {\n            _2193 = _2165 > _1198_fa_shadow_split.x;\n        }\n        else\n        {\n            _2193 = _2186;\n        }\n        if (_2193)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _2199 = _2155 > 2;\n        bool _2206;\n        if (_2199)\n        {\n            _2206 = _2165 > _1198_fa_shadow_split.y;\n        }\n        else\n        {\n            _2206 = _2199;\n        }\n        if (_2206)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _2212 = _2155 > 3;\n        bool _2219;\n        if (_2212)\n        {\n            _2219 = _2165 > _1198_fa_shadow_split.z;\n        }\n        else\n        {\n            _2219 = _2212;\n        }\n        if (_2219)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _3321 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3321 = -_3321;\n    }\n    float3 _2906 = normalize(_458_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _3334 = { fa_world_pos, _3321, fa_world_tangent, fa_uv, fa_vertex_color, _2906, gl_FrontFacing };\n    SurfaceInput param_1 = _3334;\n    Surface _2914 = fa_standard_surface(param_1);\n    float3 _3360 = _2914.albedo;\n    float _3361 = _2914.alpha;\n    float3 _3362 = _2914.normal;\n    float _3363 = _2914.metallic;\n    float _3364 = _2914.roughness;\n    float _3365 = _2914.occlusion;\n    float3 _3366 = _2914.emission;\n    float _3367 = _2914.clearcoat;\n    float _3368 = _2914.clearcoat_roughness;\n    float3 _3369 = _2914.sheen_color;\n    float _3370 = _2914.sheen_roughness;\n    float _3371 = _2914.anisotropy;\n    float _3372 = _2914.anisotropy_rotation;\n    float _3373 = _2914.specular;\n    float _3374 = _2914.ior;\n    float3 _3375 = _2914.specular_color;\n    SurfaceInput _3342 = { fa_world_pos, _3321, fa_world_tangent, fa_uv, fa_vertex_color, _2906, gl_FrontFacing };\n    SurfaceInput param_2 = _3342;\n    Surface param_3 = _2914;\n    surface(param_2, param_3);\n    _3360 = param_3.albedo;\n    _3361 = param_3.alpha;\n    _3362 = param_3.normal;\n    _3363 = param_3.metallic;\n    _3364 = param_3.roughness;\n    _3365 = param_3.occlusion;\n    _3366 = param_3.emission;\n    _3367 = param_3.clearcoat;\n    _3368 = param_3.clearcoat_roughness;\n    _3369 = param_3.sheen_color;\n    _3370 = param_3.sheen_roughness;\n    _3371 = param_3.anisotropy;\n    _3372 = param_3.anisotropy_rotation;\n    _3373 = param_3.specular;\n    _3374 = param_3.ior;\n    _3375 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _3321;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _3360 = param_6;\n    _3362 = param_7;\n    float3 result;\n    if (_458_fa_emissive.w > 0.5f)\n    {\n        result = _3360;\n    }\n    else\n    {\n        float3 _2952 = _3362;\n        float3 _2953 = normalize(_2952);\n        _3362 = _2953;\n        float3 param_8 = _2953;\n        SurfaceInput _3350 = { fa_world_pos, _3321, fa_world_tangent, fa_uv, fa_vertex_color, _2906, gl_FrontFacing };\n        SurfaceInput param_9 = _3350;\n        Surface _3441 = { _3360, _3361, _3362, _3363, _3364, _3365, _3366, _3367, _3368, _3369, _3370, _3371, _3372, _3373, _3374, _3375 };\n        Surface param_10 = _3441;\n        float3 param_11 = fa_indirect_diffuse(param_8);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _2972 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2972; ln++)\n        {\n            int param_12 = ln;\n            int _2985 = fa_cl_light(param_12);\n            bool _2988 = fa_lm.z > 0.5f;\n            bool _2994;\n            if (_2988)\n            {\n                int param_13 = _2985;\n                _2994 = fa_light_baked(param_13);\n            }\n            else\n            {\n                _2994 = _2988;\n            }\n            if (_2994)\n            {\n                continue;\n            }\n            int param_14 = _2985;\n            float3 param_15 = fa_world_pos;\n            float3 param_16 = _3321;\n            SurfaceInput _3358 = { fa_world_pos, _3321, fa_world_tangent, fa_uv, fa_vertex_color, _2906, gl_FrontFacing };\n            SurfaceInput param_17 = _3358;\n            Surface _3458 = { _3360, _3361, _3362, _3363, _3364, _3365, _3366, _3367, _3368, _3369, _3370, _3371, _3372, _3373, _3374, _3375 };\n            Surface param_18 = _3458;\n            LightSample param_19 = fa_light_shadowed(param_14, param_15, param_16);\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _3021 = result;\n    float3 _3022 = _3021 + _3366;\n    result = _3022;\n    float3 param_20 = _3022;\n    float3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _3031 = _458_fa_fog.w > 0.0f;\n    bool _3038;\n    if (!_3031)\n    {\n        _3038 = _458_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _3038 = _3031;\n    }\n    if (_3038)\n    {\n        float3 _3047 = fa_world_pos - _458_fa_camera_pos.xyz;\n        float _3053 = dot(_3047, _458_fa_fog_c.xyz);\n        bool _3057 = _458_fa_fog_c.w > 0.5f;\n        float _3058;\n        if (_3057)\n        {\n            _3058 = _3053;\n        }\n        else\n        {\n            _3058 = length(_3047);\n        }\n        float _3070 = _3058 - _458_fa_fog_b.x;\n        if (_3070 > 0.0f)\n        {\n            float _3079 = _458_fa_fog.w * _3070;\n            float tau = _3079 * _3079;\n            if (_458_fa_fog_b.y > 0.0f)\n            {\n                float _3095;\n                if (_3057)\n                {\n                    _3095 = fa_world_pos.y - (_458_fa_fog_c.y * _3053);\n                }\n                else\n                {\n                    _3095 = _458_fa_camera_pos.y;\n                }\n                float _3116 = lerp(_3095, fa_world_pos.y, clamp(_458_fa_fog_b.x / _3058, 0.0f, 1.0f));\n                float _3120 = fa_world_pos.y - _3116;\n                float _3125 = _3116 - _458_fa_fog_b.z;\n                float _3130 = fa_world_pos.y - _458_fa_fog_b.z;\n                bool _3133 = _3125 <= 0.0f;\n                bool _3134 = !_3133;\n                bool _3140;\n                if (_3134)\n                {\n                    _3140 = _458_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3140 = _3133;\n                }\n                float _3141;\n                if (_3140)\n                {\n                    _3141 = _458_fa_fog_b.y;\n                }\n                else\n                {\n                    _3141 = _458_fa_fog_b.y * exp(-min(_458_fa_fog_b.w * _3125, 80.0f));\n                }\n                bool _3168;\n                if (_3134)\n                {\n                    _3168 = _458_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3168 = _3133;\n                }\n                float _3169;\n                if (_3168)\n                {\n                    _3169 = _458_fa_fog_b.y * _3125;\n                }\n                else\n                {\n                    _3169 = (_458_fa_fog_b.y * (1.0f - exp(-min(_458_fa_fog_b.w * _3125, 80.0f)))) / _458_fa_fog_b.w;\n                }\n                bool _3194 = _3130 <= 0.0f;\n                bool _3201;\n                if (!_3194)\n                {\n                    _3201 = _458_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3201 = _3194;\n                }\n                float _3202;\n                if (_3201)\n                {\n                    _3202 = _458_fa_fog_b.y * _3130;\n                }\n                else\n                {\n                    _3202 = (_458_fa_fog_b.y * (1.0f - exp(-min(_458_fa_fog_b.w * _3130, 80.0f)))) / _458_fa_fog_b.w;\n                }\n                float _3229;\n                if (abs(_3120) < 0.001000000047497451305389404296875f)\n                {\n                    _3229 = _3141;\n                }\n                else\n                {\n                    _3229 = (_3202 - _3169) / _3120;\n                }\n                tau += (_3070 * max(_3229, 0.0f));\n            }\n            result = lerp(result, _458_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _3361);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_458",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1198",
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
