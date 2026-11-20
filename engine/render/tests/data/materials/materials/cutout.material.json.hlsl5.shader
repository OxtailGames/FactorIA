{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "41c86c92dbb0093951c81b6ee249cbb5aa749f4b053c4954c67a5e43bd66f6f3",
  "slang": "hlsl5",
  "params": [
    "alphaCutoff"
  ],
  "textures": [
    "mask"
  ],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _267 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _267;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _274 = _160.world_pos;\n    fa_world_pos = _274;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_274, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _410_fa_camera_pos : packoffset(c0);\n    float4 _410_fa_ambient : packoffset(c1);\n    float4 _410_fa_base_color : packoffset(c2);\n    float4 _410_fa_emissive : packoffset(c3);\n    float4 _410_fa_model_emissive : packoffset(c4);\n    float4 _410_fa_pbr : packoffset(c5);\n    float4 _410_fa_maps : packoffset(c6);\n    float4 _410_fa_fog : packoffset(c7);\n    float4 _410_fa_fog_b : packoffset(c8);\n    float4 _410_fa_fog_c : packoffset(c9);\n    float4 _410_fa_counts : packoffset(c10);\n    float4 _410_fa_env_sky : packoffset(c11);\n    float4 _410_fa_env_horizon : packoffset(c12);\n    float4 _410_fa_time : packoffset(c13);\n    float4 _410_fa_cl_vpx : packoffset(c14);\n    float4 _410_fa_cl_vpy : packoffset(c15);\n    float4 _410_fa_cl_vpw : packoffset(c16);\n    float4 _410_fa_cl_fwd : packoffset(c17);\n    float4 _410_fa_cl_grid : packoffset(c18);\n    float4 _410_fa_cl_info : packoffset(c19);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _1150_fa_shadow_mat[4] : packoffset(c0);\n    float4 _1150_fa_shadow_rect[4] : packoffset(c16);\n    float4 _1150_fa_shadow_info[4] : packoffset(c20);\n    float4 _1150_fa_shadow_split : packoffset(c24);\n    float4 _1150_fa_shadow_cfg : packoffset(c25);\n    float4 _1150_fa_shadow_bias : packoffset(c26);\n    float4 _1150_fa_shadow_eye : packoffset(c27);\n    float4 _1150_fa_shadow_fwd : packoffset(c28);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _2332_alphaCutoff : packoffset(c0);\n    float _2332_fa_pad0 : packoffset(c0.y);\n    float _2332_fa_pad1 : packoffset(c0.z);\n    float _2332_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t9);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_decal_tex : register(t10);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t7);\nTextureCube<float4> fa_irr_tex : register(t8);\nTexture2D<float4> mask : register(t6);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _415 = _410_fa_cl_info.x < 0.0f;\n    bool _422;\n    if (!_415)\n    {\n        _422 = _410_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _422 = _415;\n    }\n    bool _430;\n    if (!_422)\n    {\n        _430 = _410_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _430 = _422;\n    }\n    bool _437;\n    if (!_430)\n    {\n        _437 = _410_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _437 = _430;\n    }\n    bool _444;\n    if (!_437)\n    {\n        _444 = _410_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _444 = _437;\n    }\n    if (_444)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _454 = float4(world_pos, 1.0f);\n    float _461 = dot(_410_fa_cl_vpw, _454);\n    if (!(_461 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _483 = float2(dot(_410_fa_cl_vpx, _454), dot(_410_fa_cl_vpy, _454)) / _461.xx;\n    int _487 = int(_410_fa_cl_grid.x);\n    int _491 = int(_410_fa_cl_grid.y);\n    int param = (int(_410_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_410_fa_cl_fwd.xyz, world_pos) + _410_fa_cl_fwd.w, _410_fa_cl_grid.w) / _410_fa_cl_grid.w) * _410_fa_cl_grid.z)), 0, int(_410_fa_cl_info.y) - 1) * _491) + clamp(int(floor(((_483.y * 0.5f) + 0.5f) * _410_fa_cl_grid.y)), 0, _491 - 1)) * _487)) + clamp(int(floor(((_483.x * 0.5f) + 0.5f) * _410_fa_cl_grid.x)), 0, _487 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _567 = fa_cluster_texel(param);\n    return int2(int(_567.x), int(_567.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_410_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1965 = fa_cluster_lookup(param);\n    fa_cl_slot = _1965.x;\n    fa_cl_local = _1965.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _2065 = fa_linear_to_srgb(param);\n        c = _2065;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _2073 = fa_srgb_to_linear(param_1);\n            c = _2073;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _182;\n    if (i.front_facing)\n    {\n        _182 = i.world_normal;\n    }\n    else\n    {\n        _182 = -i.world_normal;\n    }\n    float3 _206 = normalize(i.world_tangent.xyz - (_182 * dot(_182, i.world_tangent.xyz)));\n    float3 _234 = normalize(((_206 * m.x) + ((cross(_182, _206) * i.world_tangent.w) * m.y)) + (_182 * m.z));\n    float3 _237;\n    if (i.front_facing)\n    {\n        _237 = _234;\n    }\n    else\n    {\n        _237 = -_234;\n    }\n    return _237;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _410_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2104 = fa_tex_fix(param_2, param_3);\n    float4 _2960 = base_t;\n    _2960.x = _2104.x;\n    _2960.y = _2104.y;\n    _2960.z = _2104.z;\n    base_t = _2960;\n    float4 _2118 = (_2960 * _410_fa_base_color) * i.vertex_color;\n    float3 _2884 = i.world_normal;\n    if (_410_fa_maps.z > 0.5f)\n    {\n        float param_4 = _410_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2150 = fa_tex_fix(param_6, param_7);\n        float3 _2153 = (_2150 * 2.0f) - 1.0f.xxx;\n        float2 _2158 = _2153.xy * _410_fa_maps.x;\n        float3 _2968 = _2153;\n        _2968.x = _2158.x;\n        _2968.y = _2158.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2968;\n        _2884 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _410_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2187 = fa_tex_fix(param_12, param_13);\n    float4 _2971 = mrt;\n    _2971.x = _2187.x;\n    _2971.y = _2187.y;\n    _2971.z = _2187.z;\n    mrt = _2971;\n    float param_14 = _410_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2226 = fa_tex_fix(param_16, param_17);\n    float param_18 = _410_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2253 = fa_tex_fix(param_20, param_21);\n    Surface _2896 = { _2118.xyz, _2118.w, _2884, clamp(_410_fa_pbr.x * _2187.z, 0.0f, 1.0f), clamp(_410_fa_pbr.y * _2187.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_410_fa_maps.y * (_2226.x - 1.0f)), _410_fa_emissive.xyz + (_410_fa_model_emissive.xyz * _2253) };\n    return _2896;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _648 = rect.zw - rect.xy;\n    float2 _652 = _648 * atlas;\n    float2 _656 = ddx * _652;\n    float2 _660 = ddy * _652;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _648), clamp(0.5f * log2(max(max(dot(_656, _656), dot(_660, _660)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    float3 _695 = ddx(world_pos);\n    float3 _698 = ddy(world_pos);\n    bool _701 = _410_fa_counts.y < 0.5f;\n    bool _708;\n    if (!_701)\n    {\n        _708 = _410_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _708 = _701;\n    }\n    if (_708)\n    {\n        return;\n    }\n    float3 param = world_pos;\n    float4 _715 = fa_cluster_texel(param);\n    int _719 = int(_715.w);\n    if (_719 < 1)\n    {\n        return;\n    }\n    int _729 = int(_410_fa_counts.y + 0.5f);\n    int param_1 = _729;\n    float4 _733 = fa_light_texel(param_1);\n    float2 _736 = _733.yz;\n    int _740 = int(_733.w);\n    int param_2 = _729 + 1;\n    float4 _745 = fa_light_texel(param_2);\n    float _746 = _745.x;\n    int _752 = int(_410_fa_counts.w + 0.5f) - 1;\n    int _756 = int(_715.z);\n    float3 _1022;\n    for (int k = 0; k < _719; k++)\n    {\n        int _769 = _756 + k;\n        int param_3 = _740 + (_769 >> 2);\n        int _787 = (_729 + 2) + (int(fa_light_texel(param_3)[_769 & 3]) * 7);\n        int param_4 = _787 + 6;\n        float4 _792 = fa_light_texel(param_4);\n        if (((int(_792.w + 0.5f) >> _752) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _787;\n        float4 _807 = fa_light_texel(param_5);\n        int param_6 = _787 + 1;\n        float4 _812 = fa_light_texel(param_6);\n        int param_7 = _787 + 2;\n        float4 _817 = fa_light_texel(param_7);\n        float3 _820 = _807.xyz;\n        float _825 = dot(_820, world_pos) + _807.w;\n        float3 _827 = _812.xyz;\n        float _832 = dot(_827, world_pos) + _812.w;\n        float3 _834 = _817.xyz;\n        float _839 = dot(_834, world_pos) + _817.w;\n        bool _844 = abs(_825) > 0.5f;\n        bool _852;\n        if (!_844)\n        {\n            _852 = abs(_832) > 0.5f;\n        }\n        else\n        {\n            _852 = _844;\n        }\n        bool _860;\n        if (!_852)\n        {\n            _860 = abs(_839) > 0.5f;\n        }\n        else\n        {\n            _860 = _852;\n        }\n        if (_860)\n        {\n            continue;\n        }\n        float _875 = clamp(dot(geo_normal, normalize(_834)) * _792.z, 0.0f, 1.0f);\n        if (_875 <= 0.0f)\n        {\n            continue;\n        }\n        float _895 = (clamp((0.5f - abs(_839)) * 10.0f, 0.0f, 1.0f) * _875) * _792.x;\n        float2 _903 = float2(_825 + 0.5f, 0.5f - _832);\n        float2 _913 = float2(dot(_820, _695), dot(_827, _695));\n        float2 _923 = float2(dot(_820, _698), dot(_827, _698));\n        int param_8 = _787 + 5;\n        float4 _928 = fa_light_texel(param_8);\n        int param_9 = _787 + 3;\n        float4 _933 = fa_light_texel(param_9);\n        int param_10 = _787 + 4;\n        float4 _938 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _928.xyz;\n        bool _948 = _933.z > _933.x;\n        if (_948)\n        {\n            float4 param_11 = _933;\n            float2 param_12 = _903;\n            float2 param_13 = _736;\n            float2 param_14 = _913;\n            float2 param_15 = _923;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_746 > 0.5f) && (_746 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _974 = fa_dc_to_linear(param_16);\n                float4 _2922 = tx;\n                _2922.x = _974.x;\n                _2922.y = _974.y;\n                _2922.z = _974.z;\n                tx = _2922;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_895 * tex_a) * _928.w, 0.0f, 1.0f).xxx);\n        if (_938.z > _938.x)\n        {\n            float4 param_17 = _938;\n            float2 param_18 = _903;\n            float2 param_19 = _736;\n            float2 param_20 = _913;\n            float2 param_21 = _923;\n            float4 _1018 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_746 > 1.5f)\n            {\n                float3 param_22 = _1018.xyz;\n                float3 _1028 = fa_dc_to_srgb(param_22);\n                _1022 = _1028;\n            }\n            else\n            {\n                _1022 = _1018.xyz;\n            }\n            float3 _1038 = (_1022 * 2.0f) - 1.0f.xxx;\n            float2 _1043 = _1038.xy * _792.y;\n            float3 _1065 = (normalize(_820) * _1043.x) + (normalize(_827) * _1043.y);\n            float3 _1068 = normalize(normal);\n            normal = normalize(lerp(_1068, normalize((_1068 * max(_1038.z, 0.0500000007450580596923828125f)) + (_1065 - (_1068 * dot(_1068, _1065)))), clamp(_895 * (_948 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_410_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _410_fa_ambient.xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_410_fa_cl_info.x) + int(_410_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _282 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _288 = fa_light_texel(param_1);\n    float _291 = _288.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _298 = _291 < 0.5f;\n    float3 l;\n    if (_298)\n    {\n        l = normalize(_282.xyz);\n    }\n    else\n    {\n        float3 _310 = _282.xyz - world_pos;\n        float _312 = length(_310);\n        dist = _312;\n        l = _310 / max(_312, 9.9999997473787516355514526367188e-05f).xxx;\n        float _327 = _312 / max(_282.w, 0.001000000047497451305389404296875f);\n        float _333 = clamp(1.0f - (_327 * _327), 0.0f, 1.0f);\n        atten = _333 * _333;\n        if (_291 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _347 = fa_light_texel(param_2);\n            float _357 = _347.w;\n            int param_3 = (li * 4) + 3;\n            float4 _364 = fa_light_texel(param_3);\n            float _365 = _364.x;\n            float cos_inner = _365;\n            if (_365 > 1.5f)\n            {\n                cos_inner = lerp(_357, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_357, cos_inner, dot(-l, normalize(_347.xyz)));\n        }\n    }\n    int _396;\n    if (_298)\n    {\n        _396 = 0;\n    }\n    else\n    {\n        _396 = (_291 > 1.5f) ? 2 : 1;\n    }\n    LightSample _2862 = { l, _288.xyz * atten, atten, 1.0f, dist, _396 };\n    return _2862;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1140;\n    if (i == 0)\n    {\n        _1140 = _1150_fa_shadow_split.x;\n    }\n    else\n    {\n        float _1156;\n        if (i == 1)\n        {\n            _1156 = _1150_fa_shadow_split.y;\n        }\n        else\n        {\n            float _1164;\n            if (i == 2)\n            {\n                _1164 = _1150_fa_shadow_split.z;\n            }\n            else\n            {\n                _1164 = _1150_fa_shadow_split.w;\n            }\n            _1156 = _1164;\n        }\n        _1140 = _1156;\n    }\n    return _1140;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1128 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_1128), sin(_1128)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _1202 = max(_1150_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _1207 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1213 = sqrt(1.0f - (_1207 * _1207));\n    float _1220 = min(_1213 / max(_1207, 0.20000000298023223876953125f), 4.0f);\n    float _1225;\n    if (_1150_fa_shadow_bias.y > 0.0f)\n    {\n        _1225 = _1150_fa_shadow_bias.y;\n    }\n    else\n    {\n        _1225 = 1.5f * _1150_fa_shadow_info[ci].x;\n    }\n    float4 _1250 = mul(float4(world + (n * (_1225 * _1213)), 1.0f), _1150_fa_shadow_mat[ci]);\n    float _1257 = _1250.x;\n    bool _1260 = _1257 < _1150_fa_shadow_rect[ci].x;\n    bool _1269;\n    if (!_1260)\n    {\n        _1269 = _1257 > _1150_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1269 = _1260;\n    }\n    bool _1278;\n    if (!_1269)\n    {\n        _1278 = _1250.y < _1150_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1278 = _1269;\n    }\n    bool _1287;\n    if (!_1278)\n    {\n        _1287 = _1250.y > _1150_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1287 = _1278;\n    }\n    bool _1294;\n    if (!_1287)\n    {\n        _1294 = _1250.z > 1.0f;\n    }\n    else\n    {\n        _1294 = _1287;\n    }\n    if (_1294)\n    {\n        return -1.0f;\n    }\n    float _1303;\n    if (_1150_fa_shadow_bias.x > 0.0f)\n    {\n        _1303 = _1150_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1303 = 1.5f * _1150_fa_shadow_info[ci].x;\n    }\n    float _1322 = _1250.z - ((_1303 * (1.0f + (0.5f * _1220))) / _1202);\n    float _1331 = ((_1150_fa_shadow_info[ci].x * min(_1220, 3.0f)) * 0.5f) / _1202;\n    int _1340 = int(_1150_fa_shadow_cfg.z + 0.5f);\n    if (_1340 == 1)\n    {\n        float2 param = _1250.xy;\n        float4 param_1 = _1150_fa_shadow_rect[ci];\n        float _1351 = fa_shadow_depth(param, param_1);\n        return float(_1322 <= _1351);\n    }\n    float _1358 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _1361 = _1340 == 2;\n    if (_1361)\n    {\n        float _1375 = clamp(((_1150_fa_shadow_cfg.w * _1202) * 0.25f) / _1150_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1358;\n            float2 _1394 = fa_shadow_vogel(param_2, param_3, param_4) * _1375;\n            float2 param_5 = _1250.xy + (_1394 * _1150_fa_shadow_bias.zw);\n            float4 param_6 = _1150_fa_shadow_rect[ci];\n            float _1405 = fa_shadow_depth(param_5, param_6);\n            if (_1405 < (_1322 - (length(_1394) * _1331)))\n            {\n                sum += _1405;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_1322 - (sum / cnt), 0.0f) * _1202) * _1150_fa_shadow_cfg.w) / _1150_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _1449 = _1361 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1449; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1449;\n        float param_9 = _1358;\n        float2 _1468 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _1250.xy + (_1468 * _1150_fa_shadow_bias.zw);\n        float4 param_11 = _1150_fa_shadow_rect[ci];\n        float _1479 = fa_shadow_depth(param_10, param_11);\n        lit += float((_1322 - (length(_1468) * _1331)) <= _1479);\n    }\n    return lit / float(_1449);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_410_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1509 = int(_1150_fa_shadow_cfg.x + 0.5f);\n    if (_1509 < 1)\n    {\n        return 1.0f;\n    }\n    float _1524 = dot(world - _1150_fa_shadow_eye.xyz, _1150_fa_shadow_fwd.xyz);\n    int param = _1509 - 1;\n    if (_1524 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1536 = _1509 > 1;\n    bool _1543;\n    if (_1536)\n    {\n        _1543 = _1524 > _1150_fa_shadow_split.x;\n    }\n    else\n    {\n        _1543 = _1536;\n    }\n    if (_1543)\n    {\n        ci = 1;\n    }\n    bool _1547 = _1509 > 2;\n    bool _1554;\n    if (_1547)\n    {\n        _1554 = _1524 > _1150_fa_shadow_split.y;\n    }\n    else\n    {\n        _1554 = _1547;\n    }\n    if (_1554)\n    {\n        ci = 2;\n    }\n    bool _1558 = _1509 > 3;\n    bool _1565;\n    if (_1558)\n    {\n        _1565 = _1524 > _1150_fa_shadow_split.z;\n    }\n    else\n    {\n        _1565 = _1558;\n    }\n    if (_1565)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1509)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1591 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1591;\n        if (_1591 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_1150_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1616;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1616 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1616 = _1150_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1635 = _1150_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1616, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1646 = clamp((_1524 - (fa_shadow_split_at(param_7) - _1635)) / _1635, 0.0f, 1.0f);\n        if (_1646 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1509)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1667 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1667;\n                if (_1667 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1646);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1993 = fa_light_sample(param, param_1);\n    float3 _2869 = _1993.direction;\n    float3 _2864 = _1993.color;\n    float _2866 = _1993.shadow;\n    int _2874 = _1993.type;\n    if ((_2874 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2869;\n        float _2007 = fa_shadow_factor(param_2, param_3);\n        _2866 = _2007;\n        _2864 *= _2007;\n    }\n    LightSample _2881 = { _2869, _2864, _1993.attenuation, _2866, _1993._distance, _2874 };\n    return _2881;\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _1897 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _1900 = _1897.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_1900 * _1900, exp2((-9.27999973297119140625f) * ndv)) * _1900) + _1897.y)) + _1897.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_410_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _410_fa_env_horizon.w).xyz;\n    }\n    float _1803 = rough * rough;\n    float _1833 = 0.60000002384185791015625f * _1803;\n    return lerp(lerp(_410_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_410_fa_env_horizon.xyz, _410_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _1803)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _1833, 0.0500000007450580596923828125f + _1833, d.y).xxx), ((_410_fa_env_sky.xyz + _410_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_1803 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1939 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1939.x) + _1939.y.xxx);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_1150_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1691 = int(_1150_fa_shadow_cfg.x + 0.5f);\n    float _1701 = dot(world - _1150_fa_shadow_eye.xyz, _1150_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1706 = _1691 > 0;\n    bool _1715;\n    if (_1706)\n    {\n        int param = _1691 - 1;\n        _1715 = _1701 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1715 = _1706;\n    }\n    if (_1715)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1722 = _1691 > 1;\n        bool _1729;\n        if (_1722)\n        {\n            _1729 = _1701 > _1150_fa_shadow_split.x;\n        }\n        else\n        {\n            _1729 = _1722;\n        }\n        if (_1729)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1735 = _1691 > 2;\n        bool _1742;\n        if (_1735)\n        {\n            _1742 = _1701 > _1150_fa_shadow_split.y;\n        }\n        else\n        {\n            _1742 = _1735;\n        }\n        if (_1742)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1748 = _1691 > 3;\n        bool _1755;\n        if (_1748)\n        {\n            _1755 = _1701 > _1150_fa_shadow_split.z;\n        }\n        else\n        {\n            _1755 = _1748;\n        }\n        if (_1755)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _2789 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2789 = -_2789;\n    }\n    float3 _2296 = normalize(_410_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _2802 = { fa_world_pos, _2789, fa_world_tangent, fa_uv, fa_vertex_color, _2296, gl_FrontFacing };\n    SurfaceInput param_1 = _2802;\n    Surface _2304 = fa_standard_surface(param_1);\n    float3 _2812 = _2304.albedo;\n    float _2813 = _2304.alpha;\n    float3 _2814 = _2304.normal;\n    float _2815 = _2304.metallic;\n    float _2816 = _2304.roughness;\n    float _2817 = _2304.occlusion;\n    float3 _2818 = _2304.emission;\n    SurfaceInput _2810 = { fa_world_pos, _2789, fa_world_tangent, fa_uv, fa_vertex_color, _2296, gl_FrontFacing };\n    SurfaceInput param_2 = _2810;\n    Surface param_3 = _2304;\n    surface(param_2, param_3);\n    _2812 = param_3.albedo;\n    _2813 = param_3.alpha;\n    _2814 = param_3.normal;\n    _2815 = param_3.metallic;\n    _2816 = param_3.roughness;\n    _2817 = param_3.occlusion;\n    _2818 = param_3.emission;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _2789;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _2812 = param_6;\n    _2814 = param_7;\n    if (_2813 < _2332_alphaCutoff)\n    {\n        discard;\n    }\n    float3 result;\n    if (_410_fa_emissive.w > 0.5f)\n    {\n        result = _2812;\n    }\n    else\n    {\n        float3 _2354 = normalize(_2814);\n        float _2361 = clamp(_2815, 0.0f, 1.0f);\n        float _2365 = clamp(_2816, 0.0500000007450580596923828125f, 1.0f);\n        float _2369 = _2365 * _2365;\n        float _2373 = _2369 * _2369;\n        float _2378 = max(dot(_2354, _2296), 9.9999997473787516355514526367188e-05f);\n        float3 _2384 = _2812 * (1.0f - _2361);\n        float3 _2392 = lerp(0.039999999105930328369140625f.xxx, _2812, _2361.xxx);\n        float3 param_8 = _2354;\n        float3 lit = (fa_ambient_light(param_8) * _2384) * _2817;\n        int _2405 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2405; ln++)\n        {\n            int param_9 = ln;\n            int _2418 = fa_cl_light(param_9);\n            int param_10 = _2418;\n            float3 param_11 = fa_world_pos;\n            float3 param_12 = _2789;\n            LightSample _2427 = fa_light_shadowed(param_10, param_11, param_12);\n            float3 _2847 = _2427.direction;\n            float _2435 = max(dot(_2354, _2847), 0.0f);\n            float3 _2446 = normalize(_2847 + _2296);\n            float _2451 = max(dot(_2354, _2446), 0.0f);\n            float _2464 = ((_2451 * _2451) * (_2373 - 1.0f)) + 1.0f;\n            int param_13 = _2418;\n            lit += (((_2384 + (((_2392 + ((1.0f.xxx - _2392) * pow(1.0f - max(dot(_2296, _2446), 0.0f), 5.0f))) * (((_2373 / ((3.1415927410125732421875f * _2464) * _2464)) * (0.5f / max(lerp((2.0f * _2435) * _2378, _2435 + _2378, _2369), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _2435))) * fa_light_rgb(param_13)) * (_2435 * (_2427.attenuation * _2427.shadow)));\n        }\n        float3 param_14 = _2354;\n        float3 param_15 = _2296;\n        float3 param_16 = _2392;\n        float param_17 = _2365;\n        float3 _2533 = lit;\n        float3 _2534 = _2533 + (fa_sky_reflection(param_14, param_15, param_16, param_17) * _2817);\n        lit = _2534;\n        result = _2534;\n    }\n    float3 _2538 = result;\n    float3 _2539 = _2538 + _2818;\n    result = _2539;\n    float3 param_18 = _2539;\n    float3 param_19 = fa_world_pos;\n    result = fa_shadow_debug(param_18, param_19);\n    bool _2548 = _410_fa_fog.w > 0.0f;\n    bool _2556;\n    if (!_2548)\n    {\n        _2556 = _410_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2556 = _2548;\n    }\n    if (_2556)\n    {\n        float3 _2565 = fa_world_pos - _410_fa_camera_pos.xyz;\n        float _2572 = dot(_2565, _410_fa_fog_c.xyz);\n        bool _2576 = _410_fa_fog_c.w > 0.5f;\n        float _2577;\n        if (_2576)\n        {\n            _2577 = _2572;\n        }\n        else\n        {\n            _2577 = length(_2565);\n        }\n        float _2589 = _2577 - _410_fa_fog_b.x;\n        if (_2589 > 0.0f)\n        {\n            float _2598 = _410_fa_fog.w * _2589;\n            float tau = _2598 * _2598;\n            if (_410_fa_fog_b.y > 0.0f)\n            {\n                float _2614;\n                if (_2576)\n                {\n                    _2614 = fa_world_pos.y - (_410_fa_fog_c.y * _2572);\n                }\n                else\n                {\n                    _2614 = _410_fa_camera_pos.y;\n                }\n                float _2635 = lerp(_2614, fa_world_pos.y, clamp(_410_fa_fog_b.x / _2577, 0.0f, 1.0f));\n                float _2639 = fa_world_pos.y - _2635;\n                float _2644 = _2635 - _410_fa_fog_b.z;\n                float _2649 = fa_world_pos.y - _410_fa_fog_b.z;\n                bool _2652 = _2644 <= 0.0f;\n                bool _2653 = !_2652;\n                bool _2659;\n                if (_2653)\n                {\n                    _2659 = _410_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2659 = _2652;\n                }\n                float _2660;\n                if (_2659)\n                {\n                    _2660 = _410_fa_fog_b.y;\n                }\n                else\n                {\n                    _2660 = _410_fa_fog_b.y * exp(-min(_410_fa_fog_b.w * _2644, 80.0f));\n                }\n                bool _2687;\n                if (_2653)\n                {\n                    _2687 = _410_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2687 = _2652;\n                }\n                float _2688;\n                if (_2687)\n                {\n                    _2688 = _410_fa_fog_b.y * _2644;\n                }\n                else\n                {\n                    _2688 = (_410_fa_fog_b.y * (1.0f - exp(-min(_410_fa_fog_b.w * _2644, 80.0f)))) / _410_fa_fog_b.w;\n                }\n                bool _2713 = _2649 <= 0.0f;\n                bool _2720;\n                if (!_2713)\n                {\n                    _2720 = _410_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2720 = _2713;\n                }\n                float _2721;\n                if (_2720)\n                {\n                    _2721 = _410_fa_fog_b.y * _2649;\n                }\n                else\n                {\n                    _2721 = (_410_fa_fog_b.y * (1.0f - exp(-min(_410_fa_fog_b.w * _2649, 80.0f)))) / _410_fa_fog_b.w;\n                }\n                float _2748;\n                if (abs(_2639) < 0.001000000047497451305389404296875f)\n                {\n                    _2748 = _2660;\n                }\n                else\n                {\n                    _2748 = (_2721 - _2688) / _2639;\n                }\n                tau += (_2589 * max(_2748, 0.0f));\n            }\n            result = lerp(result, _410_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _2813);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_131",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_410",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_1150",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_2332",
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
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 6
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
              "hlsl_register_t_n": 7
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
              "hlsl_register_t_n": 8
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
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 2
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _388 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _388;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _395 = _273.world_pos;\n    fa_world_pos = _395;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_395, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _410_fa_camera_pos : packoffset(c0);\n    float4 _410_fa_ambient : packoffset(c1);\n    float4 _410_fa_base_color : packoffset(c2);\n    float4 _410_fa_emissive : packoffset(c3);\n    float4 _410_fa_model_emissive : packoffset(c4);\n    float4 _410_fa_pbr : packoffset(c5);\n    float4 _410_fa_maps : packoffset(c6);\n    float4 _410_fa_fog : packoffset(c7);\n    float4 _410_fa_fog_b : packoffset(c8);\n    float4 _410_fa_fog_c : packoffset(c9);\n    float4 _410_fa_counts : packoffset(c10);\n    float4 _410_fa_env_sky : packoffset(c11);\n    float4 _410_fa_env_horizon : packoffset(c12);\n    float4 _410_fa_time : packoffset(c13);\n    float4 _410_fa_cl_vpx : packoffset(c14);\n    float4 _410_fa_cl_vpy : packoffset(c15);\n    float4 _410_fa_cl_vpw : packoffset(c16);\n    float4 _410_fa_cl_fwd : packoffset(c17);\n    float4 _410_fa_cl_grid : packoffset(c18);\n    float4 _410_fa_cl_info : packoffset(c19);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _1150_fa_shadow_mat[4] : packoffset(c0);\n    float4 _1150_fa_shadow_rect[4] : packoffset(c16);\n    float4 _1150_fa_shadow_info[4] : packoffset(c20);\n    float4 _1150_fa_shadow_split : packoffset(c24);\n    float4 _1150_fa_shadow_cfg : packoffset(c25);\n    float4 _1150_fa_shadow_bias : packoffset(c26);\n    float4 _1150_fa_shadow_eye : packoffset(c27);\n    float4 _1150_fa_shadow_fwd : packoffset(c28);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _2332_alphaCutoff : packoffset(c0);\n    float _2332_fa_pad0 : packoffset(c0.y);\n    float _2332_fa_pad1 : packoffset(c0.z);\n    float _2332_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t9);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_decal_tex : register(t10);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t7);\nTextureCube<float4> fa_irr_tex : register(t8);\nTexture2D<float4> mask : register(t6);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _415 = _410_fa_cl_info.x < 0.0f;\n    bool _422;\n    if (!_415)\n    {\n        _422 = _410_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _422 = _415;\n    }\n    bool _430;\n    if (!_422)\n    {\n        _430 = _410_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _430 = _422;\n    }\n    bool _437;\n    if (!_430)\n    {\n        _437 = _410_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _437 = _430;\n    }\n    bool _444;\n    if (!_437)\n    {\n        _444 = _410_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _444 = _437;\n    }\n    if (_444)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _454 = float4(world_pos, 1.0f);\n    float _461 = dot(_410_fa_cl_vpw, _454);\n    if (!(_461 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _483 = float2(dot(_410_fa_cl_vpx, _454), dot(_410_fa_cl_vpy, _454)) / _461.xx;\n    int _487 = int(_410_fa_cl_grid.x);\n    int _491 = int(_410_fa_cl_grid.y);\n    int param = (int(_410_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_410_fa_cl_fwd.xyz, world_pos) + _410_fa_cl_fwd.w, _410_fa_cl_grid.w) / _410_fa_cl_grid.w) * _410_fa_cl_grid.z)), 0, int(_410_fa_cl_info.y) - 1) * _491) + clamp(int(floor(((_483.y * 0.5f) + 0.5f) * _410_fa_cl_grid.y)), 0, _491 - 1)) * _487)) + clamp(int(floor(((_483.x * 0.5f) + 0.5f) * _410_fa_cl_grid.x)), 0, _487 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _567 = fa_cluster_texel(param);\n    return int2(int(_567.x), int(_567.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_410_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1965 = fa_cluster_lookup(param);\n    fa_cl_slot = _1965.x;\n    fa_cl_local = _1965.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _2065 = fa_linear_to_srgb(param);\n        c = _2065;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _2073 = fa_srgb_to_linear(param_1);\n            c = _2073;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _182;\n    if (i.front_facing)\n    {\n        _182 = i.world_normal;\n    }\n    else\n    {\n        _182 = -i.world_normal;\n    }\n    float3 _206 = normalize(i.world_tangent.xyz - (_182 * dot(_182, i.world_tangent.xyz)));\n    float3 _234 = normalize(((_206 * m.x) + ((cross(_182, _206) * i.world_tangent.w) * m.y)) + (_182 * m.z));\n    float3 _237;\n    if (i.front_facing)\n    {\n        _237 = _234;\n    }\n    else\n    {\n        _237 = -_234;\n    }\n    return _237;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _410_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2104 = fa_tex_fix(param_2, param_3);\n    float4 _2960 = base_t;\n    _2960.x = _2104.x;\n    _2960.y = _2104.y;\n    _2960.z = _2104.z;\n    base_t = _2960;\n    float4 _2118 = (_2960 * _410_fa_base_color) * i.vertex_color;\n    float3 _2884 = i.world_normal;\n    if (_410_fa_maps.z > 0.5f)\n    {\n        float param_4 = _410_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2150 = fa_tex_fix(param_6, param_7);\n        float3 _2153 = (_2150 * 2.0f) - 1.0f.xxx;\n        float2 _2158 = _2153.xy * _410_fa_maps.x;\n        float3 _2968 = _2153;\n        _2968.x = _2158.x;\n        _2968.y = _2158.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2968;\n        _2884 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _410_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2187 = fa_tex_fix(param_12, param_13);\n    float4 _2971 = mrt;\n    _2971.x = _2187.x;\n    _2971.y = _2187.y;\n    _2971.z = _2187.z;\n    mrt = _2971;\n    float param_14 = _410_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2226 = fa_tex_fix(param_16, param_17);\n    float param_18 = _410_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2253 = fa_tex_fix(param_20, param_21);\n    Surface _2896 = { _2118.xyz, _2118.w, _2884, clamp(_410_fa_pbr.x * _2187.z, 0.0f, 1.0f), clamp(_410_fa_pbr.y * _2187.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_410_fa_maps.y * (_2226.x - 1.0f)), _410_fa_emissive.xyz + (_410_fa_model_emissive.xyz * _2253) };\n    return _2896;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _648 = rect.zw - rect.xy;\n    float2 _652 = _648 * atlas;\n    float2 _656 = ddx * _652;\n    float2 _660 = ddy * _652;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _648), clamp(0.5f * log2(max(max(dot(_656, _656), dot(_660, _660)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    float3 _695 = ddx(world_pos);\n    float3 _698 = ddy(world_pos);\n    bool _701 = _410_fa_counts.y < 0.5f;\n    bool _708;\n    if (!_701)\n    {\n        _708 = _410_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _708 = _701;\n    }\n    if (_708)\n    {\n        return;\n    }\n    float3 param = world_pos;\n    float4 _715 = fa_cluster_texel(param);\n    int _719 = int(_715.w);\n    if (_719 < 1)\n    {\n        return;\n    }\n    int _729 = int(_410_fa_counts.y + 0.5f);\n    int param_1 = _729;\n    float4 _733 = fa_light_texel(param_1);\n    float2 _736 = _733.yz;\n    int _740 = int(_733.w);\n    int param_2 = _729 + 1;\n    float4 _745 = fa_light_texel(param_2);\n    float _746 = _745.x;\n    int _752 = int(_410_fa_counts.w + 0.5f) - 1;\n    int _756 = int(_715.z);\n    float3 _1022;\n    for (int k = 0; k < _719; k++)\n    {\n        int _769 = _756 + k;\n        int param_3 = _740 + (_769 >> 2);\n        int _787 = (_729 + 2) + (int(fa_light_texel(param_3)[_769 & 3]) * 7);\n        int param_4 = _787 + 6;\n        float4 _792 = fa_light_texel(param_4);\n        if (((int(_792.w + 0.5f) >> _752) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _787;\n        float4 _807 = fa_light_texel(param_5);\n        int param_6 = _787 + 1;\n        float4 _812 = fa_light_texel(param_6);\n        int param_7 = _787 + 2;\n        float4 _817 = fa_light_texel(param_7);\n        float3 _820 = _807.xyz;\n        float _825 = dot(_820, world_pos) + _807.w;\n        float3 _827 = _812.xyz;\n        float _832 = dot(_827, world_pos) + _812.w;\n        float3 _834 = _817.xyz;\n        float _839 = dot(_834, world_pos) + _817.w;\n        bool _844 = abs(_825) > 0.5f;\n        bool _852;\n        if (!_844)\n        {\n            _852 = abs(_832) > 0.5f;\n        }\n        else\n        {\n            _852 = _844;\n        }\n        bool _860;\n        if (!_852)\n        {\n            _860 = abs(_839) > 0.5f;\n        }\n        else\n        {\n            _860 = _852;\n        }\n        if (_860)\n        {\n            continue;\n        }\n        float _875 = clamp(dot(geo_normal, normalize(_834)) * _792.z, 0.0f, 1.0f);\n        if (_875 <= 0.0f)\n        {\n            continue;\n        }\n        float _895 = (clamp((0.5f - abs(_839)) * 10.0f, 0.0f, 1.0f) * _875) * _792.x;\n        float2 _903 = float2(_825 + 0.5f, 0.5f - _832);\n        float2 _913 = float2(dot(_820, _695), dot(_827, _695));\n        float2 _923 = float2(dot(_820, _698), dot(_827, _698));\n        int param_8 = _787 + 5;\n        float4 _928 = fa_light_texel(param_8);\n        int param_9 = _787 + 3;\n        float4 _933 = fa_light_texel(param_9);\n        int param_10 = _787 + 4;\n        float4 _938 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _928.xyz;\n        bool _948 = _933.z > _933.x;\n        if (_948)\n        {\n            float4 param_11 = _933;\n            float2 param_12 = _903;\n            float2 param_13 = _736;\n            float2 param_14 = _913;\n            float2 param_15 = _923;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_746 > 0.5f) && (_746 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _974 = fa_dc_to_linear(param_16);\n                float4 _2922 = tx;\n                _2922.x = _974.x;\n                _2922.y = _974.y;\n                _2922.z = _974.z;\n                tx = _2922;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_895 * tex_a) * _928.w, 0.0f, 1.0f).xxx);\n        if (_938.z > _938.x)\n        {\n            float4 param_17 = _938;\n            float2 param_18 = _903;\n            float2 param_19 = _736;\n            float2 param_20 = _913;\n            float2 param_21 = _923;\n            float4 _1018 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_746 > 1.5f)\n            {\n                float3 param_22 = _1018.xyz;\n                float3 _1028 = fa_dc_to_srgb(param_22);\n                _1022 = _1028;\n            }\n            else\n            {\n                _1022 = _1018.xyz;\n            }\n            float3 _1038 = (_1022 * 2.0f) - 1.0f.xxx;\n            float2 _1043 = _1038.xy * _792.y;\n            float3 _1065 = (normalize(_820) * _1043.x) + (normalize(_827) * _1043.y);\n            float3 _1068 = normalize(normal);\n            normal = normalize(lerp(_1068, normalize((_1068 * max(_1038.z, 0.0500000007450580596923828125f)) + (_1065 - (_1068 * dot(_1068, _1065)))), clamp(_895 * (_948 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_410_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _410_fa_ambient.xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_410_fa_cl_info.x) + int(_410_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _282 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _288 = fa_light_texel(param_1);\n    float _291 = _288.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _298 = _291 < 0.5f;\n    float3 l;\n    if (_298)\n    {\n        l = normalize(_282.xyz);\n    }\n    else\n    {\n        float3 _310 = _282.xyz - world_pos;\n        float _312 = length(_310);\n        dist = _312;\n        l = _310 / max(_312, 9.9999997473787516355514526367188e-05f).xxx;\n        float _327 = _312 / max(_282.w, 0.001000000047497451305389404296875f);\n        float _333 = clamp(1.0f - (_327 * _327), 0.0f, 1.0f);\n        atten = _333 * _333;\n        if (_291 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _347 = fa_light_texel(param_2);\n            float _357 = _347.w;\n            int param_3 = (li * 4) + 3;\n            float4 _364 = fa_light_texel(param_3);\n            float _365 = _364.x;\n            float cos_inner = _365;\n            if (_365 > 1.5f)\n            {\n                cos_inner = lerp(_357, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_357, cos_inner, dot(-l, normalize(_347.xyz)));\n        }\n    }\n    int _396;\n    if (_298)\n    {\n        _396 = 0;\n    }\n    else\n    {\n        _396 = (_291 > 1.5f) ? 2 : 1;\n    }\n    LightSample _2862 = { l, _288.xyz * atten, atten, 1.0f, dist, _396 };\n    return _2862;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1140;\n    if (i == 0)\n    {\n        _1140 = _1150_fa_shadow_split.x;\n    }\n    else\n    {\n        float _1156;\n        if (i == 1)\n        {\n            _1156 = _1150_fa_shadow_split.y;\n        }\n        else\n        {\n            float _1164;\n            if (i == 2)\n            {\n                _1164 = _1150_fa_shadow_split.z;\n            }\n            else\n            {\n                _1164 = _1150_fa_shadow_split.w;\n            }\n            _1156 = _1164;\n        }\n        _1140 = _1156;\n    }\n    return _1140;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1128 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_1128), sin(_1128)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _1202 = max(_1150_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _1207 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1213 = sqrt(1.0f - (_1207 * _1207));\n    float _1220 = min(_1213 / max(_1207, 0.20000000298023223876953125f), 4.0f);\n    float _1225;\n    if (_1150_fa_shadow_bias.y > 0.0f)\n    {\n        _1225 = _1150_fa_shadow_bias.y;\n    }\n    else\n    {\n        _1225 = 1.5f * _1150_fa_shadow_info[ci].x;\n    }\n    float4 _1250 = mul(float4(world + (n * (_1225 * _1213)), 1.0f), _1150_fa_shadow_mat[ci]);\n    float _1257 = _1250.x;\n    bool _1260 = _1257 < _1150_fa_shadow_rect[ci].x;\n    bool _1269;\n    if (!_1260)\n    {\n        _1269 = _1257 > _1150_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1269 = _1260;\n    }\n    bool _1278;\n    if (!_1269)\n    {\n        _1278 = _1250.y < _1150_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1278 = _1269;\n    }\n    bool _1287;\n    if (!_1278)\n    {\n        _1287 = _1250.y > _1150_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1287 = _1278;\n    }\n    bool _1294;\n    if (!_1287)\n    {\n        _1294 = _1250.z > 1.0f;\n    }\n    else\n    {\n        _1294 = _1287;\n    }\n    if (_1294)\n    {\n        return -1.0f;\n    }\n    float _1303;\n    if (_1150_fa_shadow_bias.x > 0.0f)\n    {\n        _1303 = _1150_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1303 = 1.5f * _1150_fa_shadow_info[ci].x;\n    }\n    float _1322 = _1250.z - ((_1303 * (1.0f + (0.5f * _1220))) / _1202);\n    float _1331 = ((_1150_fa_shadow_info[ci].x * min(_1220, 3.0f)) * 0.5f) / _1202;\n    int _1340 = int(_1150_fa_shadow_cfg.z + 0.5f);\n    if (_1340 == 1)\n    {\n        float2 param = _1250.xy;\n        float4 param_1 = _1150_fa_shadow_rect[ci];\n        float _1351 = fa_shadow_depth(param, param_1);\n        return float(_1322 <= _1351);\n    }\n    float _1358 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _1361 = _1340 == 2;\n    if (_1361)\n    {\n        float _1375 = clamp(((_1150_fa_shadow_cfg.w * _1202) * 0.25f) / _1150_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1358;\n            float2 _1394 = fa_shadow_vogel(param_2, param_3, param_4) * _1375;\n            float2 param_5 = _1250.xy + (_1394 * _1150_fa_shadow_bias.zw);\n            float4 param_6 = _1150_fa_shadow_rect[ci];\n            float _1405 = fa_shadow_depth(param_5, param_6);\n            if (_1405 < (_1322 - (length(_1394) * _1331)))\n            {\n                sum += _1405;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_1322 - (sum / cnt), 0.0f) * _1202) * _1150_fa_shadow_cfg.w) / _1150_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _1449 = _1361 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1449; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1449;\n        float param_9 = _1358;\n        float2 _1468 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _1250.xy + (_1468 * _1150_fa_shadow_bias.zw);\n        float4 param_11 = _1150_fa_shadow_rect[ci];\n        float _1479 = fa_shadow_depth(param_10, param_11);\n        lit += float((_1322 - (length(_1468) * _1331)) <= _1479);\n    }\n    return lit / float(_1449);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_410_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1509 = int(_1150_fa_shadow_cfg.x + 0.5f);\n    if (_1509 < 1)\n    {\n        return 1.0f;\n    }\n    float _1524 = dot(world - _1150_fa_shadow_eye.xyz, _1150_fa_shadow_fwd.xyz);\n    int param = _1509 - 1;\n    if (_1524 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1536 = _1509 > 1;\n    bool _1543;\n    if (_1536)\n    {\n        _1543 = _1524 > _1150_fa_shadow_split.x;\n    }\n    else\n    {\n        _1543 = _1536;\n    }\n    if (_1543)\n    {\n        ci = 1;\n    }\n    bool _1547 = _1509 > 2;\n    bool _1554;\n    if (_1547)\n    {\n        _1554 = _1524 > _1150_fa_shadow_split.y;\n    }\n    else\n    {\n        _1554 = _1547;\n    }\n    if (_1554)\n    {\n        ci = 2;\n    }\n    bool _1558 = _1509 > 3;\n    bool _1565;\n    if (_1558)\n    {\n        _1565 = _1524 > _1150_fa_shadow_split.z;\n    }\n    else\n    {\n        _1565 = _1558;\n    }\n    if (_1565)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1509)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1591 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1591;\n        if (_1591 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_1150_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1616;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1616 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1616 = _1150_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1635 = _1150_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1616, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1646 = clamp((_1524 - (fa_shadow_split_at(param_7) - _1635)) / _1635, 0.0f, 1.0f);\n        if (_1646 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1509)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1667 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1667;\n                if (_1667 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1646);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1993 = fa_light_sample(param, param_1);\n    float3 _2869 = _1993.direction;\n    float3 _2864 = _1993.color;\n    float _2866 = _1993.shadow;\n    int _2874 = _1993.type;\n    if ((_2874 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2869;\n        float _2007 = fa_shadow_factor(param_2, param_3);\n        _2866 = _2007;\n        _2864 *= _2007;\n    }\n    LightSample _2881 = { _2869, _2864, _1993.attenuation, _2866, _1993._distance, _2874 };\n    return _2881;\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _1897 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _1900 = _1897.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_1900 * _1900, exp2((-9.27999973297119140625f) * ndv)) * _1900) + _1897.y)) + _1897.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_410_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _410_fa_env_horizon.w).xyz;\n    }\n    float _1803 = rough * rough;\n    float _1833 = 0.60000002384185791015625f * _1803;\n    return lerp(lerp(_410_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_410_fa_env_horizon.xyz, _410_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _1803)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _1833, 0.0500000007450580596923828125f + _1833, d.y).xxx), ((_410_fa_env_sky.xyz + _410_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_1803 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1939 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1939.x) + _1939.y.xxx);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_1150_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1691 = int(_1150_fa_shadow_cfg.x + 0.5f);\n    float _1701 = dot(world - _1150_fa_shadow_eye.xyz, _1150_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1706 = _1691 > 0;\n    bool _1715;\n    if (_1706)\n    {\n        int param = _1691 - 1;\n        _1715 = _1701 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1715 = _1706;\n    }\n    if (_1715)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1722 = _1691 > 1;\n        bool _1729;\n        if (_1722)\n        {\n            _1729 = _1701 > _1150_fa_shadow_split.x;\n        }\n        else\n        {\n            _1729 = _1722;\n        }\n        if (_1729)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1735 = _1691 > 2;\n        bool _1742;\n        if (_1735)\n        {\n            _1742 = _1701 > _1150_fa_shadow_split.y;\n        }\n        else\n        {\n            _1742 = _1735;\n        }\n        if (_1742)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1748 = _1691 > 3;\n        bool _1755;\n        if (_1748)\n        {\n            _1755 = _1701 > _1150_fa_shadow_split.z;\n        }\n        else\n        {\n            _1755 = _1748;\n        }\n        if (_1755)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _2789 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2789 = -_2789;\n    }\n    float3 _2296 = normalize(_410_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _2802 = { fa_world_pos, _2789, fa_world_tangent, fa_uv, fa_vertex_color, _2296, gl_FrontFacing };\n    SurfaceInput param_1 = _2802;\n    Surface _2304 = fa_standard_surface(param_1);\n    float3 _2812 = _2304.albedo;\n    float _2813 = _2304.alpha;\n    float3 _2814 = _2304.normal;\n    float _2815 = _2304.metallic;\n    float _2816 = _2304.roughness;\n    float _2817 = _2304.occlusion;\n    float3 _2818 = _2304.emission;\n    SurfaceInput _2810 = { fa_world_pos, _2789, fa_world_tangent, fa_uv, fa_vertex_color, _2296, gl_FrontFacing };\n    SurfaceInput param_2 = _2810;\n    Surface param_3 = _2304;\n    surface(param_2, param_3);\n    _2812 = param_3.albedo;\n    _2813 = param_3.alpha;\n    _2814 = param_3.normal;\n    _2815 = param_3.metallic;\n    _2816 = param_3.roughness;\n    _2817 = param_3.occlusion;\n    _2818 = param_3.emission;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _2789;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _2812 = param_6;\n    _2814 = param_7;\n    if (_2813 < _2332_alphaCutoff)\n    {\n        discard;\n    }\n    float3 result;\n    if (_410_fa_emissive.w > 0.5f)\n    {\n        result = _2812;\n    }\n    else\n    {\n        float3 _2354 = normalize(_2814);\n        float _2361 = clamp(_2815, 0.0f, 1.0f);\n        float _2365 = clamp(_2816, 0.0500000007450580596923828125f, 1.0f);\n        float _2369 = _2365 * _2365;\n        float _2373 = _2369 * _2369;\n        float _2378 = max(dot(_2354, _2296), 9.9999997473787516355514526367188e-05f);\n        float3 _2384 = _2812 * (1.0f - _2361);\n        float3 _2392 = lerp(0.039999999105930328369140625f.xxx, _2812, _2361.xxx);\n        float3 param_8 = _2354;\n        float3 lit = (fa_ambient_light(param_8) * _2384) * _2817;\n        int _2405 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2405; ln++)\n        {\n            int param_9 = ln;\n            int _2418 = fa_cl_light(param_9);\n            int param_10 = _2418;\n            float3 param_11 = fa_world_pos;\n            float3 param_12 = _2789;\n            LightSample _2427 = fa_light_shadowed(param_10, param_11, param_12);\n            float3 _2847 = _2427.direction;\n            float _2435 = max(dot(_2354, _2847), 0.0f);\n            float3 _2446 = normalize(_2847 + _2296);\n            float _2451 = max(dot(_2354, _2446), 0.0f);\n            float _2464 = ((_2451 * _2451) * (_2373 - 1.0f)) + 1.0f;\n            int param_13 = _2418;\n            lit += (((_2384 + (((_2392 + ((1.0f.xxx - _2392) * pow(1.0f - max(dot(_2296, _2446), 0.0f), 5.0f))) * (((_2373 / ((3.1415927410125732421875f * _2464) * _2464)) * (0.5f / max(lerp((2.0f * _2435) * _2378, _2435 + _2378, _2369), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _2435))) * fa_light_rgb(param_13)) * (_2435 * (_2427.attenuation * _2427.shadow)));\n        }\n        float3 param_14 = _2354;\n        float3 param_15 = _2296;\n        float3 param_16 = _2392;\n        float param_17 = _2365;\n        float3 _2533 = lit;\n        float3 _2534 = _2533 + (fa_sky_reflection(param_14, param_15, param_16, param_17) * _2817);\n        lit = _2534;\n        result = _2534;\n    }\n    float3 _2538 = result;\n    float3 _2539 = _2538 + _2818;\n    result = _2539;\n    float3 param_18 = _2539;\n    float3 param_19 = fa_world_pos;\n    result = fa_shadow_debug(param_18, param_19);\n    bool _2548 = _410_fa_fog.w > 0.0f;\n    bool _2556;\n    if (!_2548)\n    {\n        _2556 = _410_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2556 = _2548;\n    }\n    if (_2556)\n    {\n        float3 _2565 = fa_world_pos - _410_fa_camera_pos.xyz;\n        float _2572 = dot(_2565, _410_fa_fog_c.xyz);\n        bool _2576 = _410_fa_fog_c.w > 0.5f;\n        float _2577;\n        if (_2576)\n        {\n            _2577 = _2572;\n        }\n        else\n        {\n            _2577 = length(_2565);\n        }\n        float _2589 = _2577 - _410_fa_fog_b.x;\n        if (_2589 > 0.0f)\n        {\n            float _2598 = _410_fa_fog.w * _2589;\n            float tau = _2598 * _2598;\n            if (_410_fa_fog_b.y > 0.0f)\n            {\n                float _2614;\n                if (_2576)\n                {\n                    _2614 = fa_world_pos.y - (_410_fa_fog_c.y * _2572);\n                }\n                else\n                {\n                    _2614 = _410_fa_camera_pos.y;\n                }\n                float _2635 = lerp(_2614, fa_world_pos.y, clamp(_410_fa_fog_b.x / _2577, 0.0f, 1.0f));\n                float _2639 = fa_world_pos.y - _2635;\n                float _2644 = _2635 - _410_fa_fog_b.z;\n                float _2649 = fa_world_pos.y - _410_fa_fog_b.z;\n                bool _2652 = _2644 <= 0.0f;\n                bool _2653 = !_2652;\n                bool _2659;\n                if (_2653)\n                {\n                    _2659 = _410_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2659 = _2652;\n                }\n                float _2660;\n                if (_2659)\n                {\n                    _2660 = _410_fa_fog_b.y;\n                }\n                else\n                {\n                    _2660 = _410_fa_fog_b.y * exp(-min(_410_fa_fog_b.w * _2644, 80.0f));\n                }\n                bool _2687;\n                if (_2653)\n                {\n                    _2687 = _410_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2687 = _2652;\n                }\n                float _2688;\n                if (_2687)\n                {\n                    _2688 = _410_fa_fog_b.y * _2644;\n                }\n                else\n                {\n                    _2688 = (_410_fa_fog_b.y * (1.0f - exp(-min(_410_fa_fog_b.w * _2644, 80.0f)))) / _410_fa_fog_b.w;\n                }\n                bool _2713 = _2649 <= 0.0f;\n                bool _2720;\n                if (!_2713)\n                {\n                    _2720 = _410_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2720 = _2713;\n                }\n                float _2721;\n                if (_2720)\n                {\n                    _2721 = _410_fa_fog_b.y * _2649;\n                }\n                else\n                {\n                    _2721 = (_410_fa_fog_b.y * (1.0f - exp(-min(_410_fa_fog_b.w * _2649, 80.0f)))) / _410_fa_fog_b.w;\n                }\n                float _2748;\n                if (abs(_2639) < 0.001000000047497451305389404296875f)\n                {\n                    _2748 = _2660;\n                }\n                else\n                {\n                    _2748 = (_2721 - _2688) / _2639;\n                }\n                tau += (_2589 * max(_2748, 0.0f));\n            }\n            result = lerp(result, _410_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _2813);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 160,
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
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_410",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_1150",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_2332",
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
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 6
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
              "hlsl_register_t_n": 7
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
              "hlsl_register_t_n": 8
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
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 2
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          }
        ]
      }
    },
    "prepass": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _301 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _301;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _308 = _160.world_pos;\n    float4 _171 = float4(_308, 1.0f);\n    fa_world_pos = _308;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -mul(_171, _131_fa_light_vp).z;\n    fa_pre_r0 = float3(_131_fa_light_vp[0].x, _131_fa_light_vp[1].x, _131_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131_fa_light_vp[0].y, _131_fa_light_vp[1].y, _131_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131_fa_light_vp[0].z, _131_fa_light_vp[1].z, _131_fa_light_vp[2].z);\n    gl_Position = mul(_171, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _225_fa_camera_pos : packoffset(c0);\n    float4 _225_fa_ambient : packoffset(c1);\n    float4 _225_fa_base_color : packoffset(c2);\n    float4 _225_fa_emissive : packoffset(c3);\n    float4 _225_fa_model_emissive : packoffset(c4);\n    float4 _225_fa_pbr : packoffset(c5);\n    float4 _225_fa_maps : packoffset(c6);\n    float4 _225_fa_fog : packoffset(c7);\n    float4 _225_fa_fog_b : packoffset(c8);\n    float4 _225_fa_fog_c : packoffset(c9);\n    float4 _225_fa_counts : packoffset(c10);\n    float4 _225_fa_env_sky : packoffset(c11);\n    float4 _225_fa_env_horizon : packoffset(c12);\n    float4 _225_fa_time : packoffset(c13);\n    float4 _225_fa_cl_vpx : packoffset(c14);\n    float4 _225_fa_cl_vpy : packoffset(c15);\n    float4 _225_fa_cl_vpw : packoffset(c16);\n    float4 _225_fa_cl_fwd : packoffset(c17);\n    float4 _225_fa_cl_grid : packoffset(c18);\n    float4 _225_fa_cl_info : packoffset(c19);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _454_alphaCutoff : packoffset(c0);\n    float _454_fa_pad0 : packoffset(c0.y);\n    float _454_fa_pad1 : packoffset(c0.z);\n    float _454_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> mask : register(t5);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _225_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _237 = fa_tex_fix(param_2, param_3);\n    float4 _610 = base_t;\n    _610.x = _237.x;\n    _610.y = _237.y;\n    _610.z = _237.z;\n    base_t = _610;\n    float4 _253 = (_610 * _225_fa_base_color) * i.vertex_color;\n    float3 _591 = i.world_normal;\n    if (_225_fa_maps.z > 0.5f)\n    {\n        float param_4 = _225_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _287 = fa_tex_fix(param_6, param_7);\n        float3 _290 = (_287 * 2.0f) - 1.0f.xxx;\n        float2 _295 = _290.xy * _225_fa_maps.x;\n        float3 _618 = _290;\n        _618.x = _295.x;\n        _618.y = _295.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _618;\n        _591 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _225_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _324 = fa_tex_fix(param_12, param_13);\n    float4 _621 = mrt;\n    _621.x = _324.x;\n    _621.y = _324.y;\n    _621.z = _324.z;\n    mrt = _621;\n    float param_14 = _225_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _365 = fa_tex_fix(param_16, param_17);\n    float param_18 = _225_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _392 = fa_tex_fix(param_20, param_21);\n    Surface _603 = { _253.xyz, _253.w, _591, clamp(_225_fa_pbr.x * _324.z, 0.0f, 1.0f), clamp(_225_fa_pbr.y * _324.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_225_fa_maps.y * (_365.x - 1.0f)), _225_fa_emissive.xyz + (_225_fa_model_emissive.xyz * _392) };\n    return _603;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _538 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _538 = -_538;\n    }\n    float3 _438 = normalize(_225_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _551 = { fa_world_pos, _538, fa_world_tangent, fa_uv, fa_vertex_color, _438, gl_FrontFacing };\n    SurfaceInput param = _551;\n    Surface _443 = fa_standard_surface(param);\n    float3 _562 = _443.normal;\n    SurfaceInput _559 = { fa_world_pos, _538, fa_world_tangent, fa_uv, fa_vertex_color, _438, gl_FrontFacing };\n    SurfaceInput param_1 = _559;\n    Surface param_2 = _443;\n    surface(param_1, param_2);\n    _562 = param_2.normal;\n    if (param_2.alpha < _454_alphaCutoff)\n    {\n        discard;\n    }\n    float3 _464 = normalize(_562);\n    float3 _479 = normalize(float3(dot(fa_pre_r0, _464), dot(fa_pre_r1, _464), dot(fa_pre_r2, _464)));\n    float _491 = _479.z;\n    float2 e = _479.xy / ((abs(_479.x) + abs(_479.y)) + abs(_491)).xx;\n    if (_491 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_131",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_225",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_454",
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
          },
          {
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 5
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 2
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    },
    "prepass_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _422 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _422;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _429 = _273.world_pos;\n    float4 _284 = float4(_429, 1.0f);\n    fa_world_pos = _429;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -mul(_284, _136_fa_light_vp).z;\n    fa_pre_r0 = float3(_136_fa_light_vp[0].x, _136_fa_light_vp[1].x, _136_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136_fa_light_vp[0].y, _136_fa_light_vp[1].y, _136_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136_fa_light_vp[0].z, _136_fa_light_vp[1].z, _136_fa_light_vp[2].z);\n    gl_Position = mul(_284, _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _225_fa_camera_pos : packoffset(c0);\n    float4 _225_fa_ambient : packoffset(c1);\n    float4 _225_fa_base_color : packoffset(c2);\n    float4 _225_fa_emissive : packoffset(c3);\n    float4 _225_fa_model_emissive : packoffset(c4);\n    float4 _225_fa_pbr : packoffset(c5);\n    float4 _225_fa_maps : packoffset(c6);\n    float4 _225_fa_fog : packoffset(c7);\n    float4 _225_fa_fog_b : packoffset(c8);\n    float4 _225_fa_fog_c : packoffset(c9);\n    float4 _225_fa_counts : packoffset(c10);\n    float4 _225_fa_env_sky : packoffset(c11);\n    float4 _225_fa_env_horizon : packoffset(c12);\n    float4 _225_fa_time : packoffset(c13);\n    float4 _225_fa_cl_vpx : packoffset(c14);\n    float4 _225_fa_cl_vpy : packoffset(c15);\n    float4 _225_fa_cl_vpw : packoffset(c16);\n    float4 _225_fa_cl_fwd : packoffset(c17);\n    float4 _225_fa_cl_grid : packoffset(c18);\n    float4 _225_fa_cl_info : packoffset(c19);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _454_alphaCutoff : packoffset(c0);\n    float _454_fa_pad0 : packoffset(c0.y);\n    float _454_fa_pad1 : packoffset(c0.z);\n    float _454_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> mask : register(t5);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _225_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _237 = fa_tex_fix(param_2, param_3);\n    float4 _610 = base_t;\n    _610.x = _237.x;\n    _610.y = _237.y;\n    _610.z = _237.z;\n    base_t = _610;\n    float4 _253 = (_610 * _225_fa_base_color) * i.vertex_color;\n    float3 _591 = i.world_normal;\n    if (_225_fa_maps.z > 0.5f)\n    {\n        float param_4 = _225_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _287 = fa_tex_fix(param_6, param_7);\n        float3 _290 = (_287 * 2.0f) - 1.0f.xxx;\n        float2 _295 = _290.xy * _225_fa_maps.x;\n        float3 _618 = _290;\n        _618.x = _295.x;\n        _618.y = _295.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _618;\n        _591 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _225_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _324 = fa_tex_fix(param_12, param_13);\n    float4 _621 = mrt;\n    _621.x = _324.x;\n    _621.y = _324.y;\n    _621.z = _324.z;\n    mrt = _621;\n    float param_14 = _225_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _365 = fa_tex_fix(param_16, param_17);\n    float param_18 = _225_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _392 = fa_tex_fix(param_20, param_21);\n    Surface _603 = { _253.xyz, _253.w, _591, clamp(_225_fa_pbr.x * _324.z, 0.0f, 1.0f), clamp(_225_fa_pbr.y * _324.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_225_fa_maps.y * (_365.x - 1.0f)), _225_fa_emissive.xyz + (_225_fa_model_emissive.xyz * _392) };\n    return _603;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _538 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _538 = -_538;\n    }\n    float3 _438 = normalize(_225_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _551 = { fa_world_pos, _538, fa_world_tangent, fa_uv, fa_vertex_color, _438, gl_FrontFacing };\n    SurfaceInput param = _551;\n    Surface _443 = fa_standard_surface(param);\n    float3 _562 = _443.normal;\n    SurfaceInput _559 = { fa_world_pos, _538, fa_world_tangent, fa_uv, fa_vertex_color, _438, gl_FrontFacing };\n    SurfaceInput param_1 = _559;\n    Surface param_2 = _443;\n    surface(param_1, param_2);\n    _562 = param_2.normal;\n    if (param_2.alpha < _454_alphaCutoff)\n    {\n        discard;\n    }\n    float3 _464 = normalize(_562);\n    float3 _479 = normalize(float3(dot(fa_pre_r0, _464), dot(fa_pre_r1, _464), dot(fa_pre_r2, _464)));\n    float _491 = _479.z;\n    float2 e = _479.xy / ((abs(_479.x) + abs(_479.y)) + abs(_491)).xx;\n    if (_491 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 160,
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
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_225",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_454",
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
          },
          {
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 5
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 2
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    },
    "shadow": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _122_fa_view_proj : packoffset(c0);\n    row_major float4x4 _122_fa_light_vp : packoffset(c4);\n    float4 _122_fa_uv_scale : packoffset(c8);\n    float4 _122_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float3 fa_normal : TEXCOORD5;\n    float2 fa_texcoord0 : TEXCOORD6;\n    float4 fa_tangent : TEXCOORD7;\n    float4 fa_color : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _60 = cross(model[1].xyz, model[2].xyz);\n    float _66 = (dot(model[0].xyz, _60) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _256 = { mul(float4(position, 1.0f), model).xyz, (((_60 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _66, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _66), texcoord0 * _122_fa_uv_scale.xy, color, position };\n    return _256;\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    VertexData _190 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _239 = _190.world_pos;\n    fa_world_pos = _239;\n    fa_world_normal = _190.world_normal;\n    fa_world_tangent = _190.world_tangent;\n    fa_uv = _190.uv;\n    fa_vertex_color = _190.color;\n    gl_Position = mul(float4(_239, 1.0f), _122_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _225_fa_camera_pos : packoffset(c0);\n    float4 _225_fa_ambient : packoffset(c1);\n    float4 _225_fa_base_color : packoffset(c2);\n    float4 _225_fa_emissive : packoffset(c3);\n    float4 _225_fa_model_emissive : packoffset(c4);\n    float4 _225_fa_pbr : packoffset(c5);\n    float4 _225_fa_maps : packoffset(c6);\n    float4 _225_fa_fog : packoffset(c7);\n    float4 _225_fa_fog_b : packoffset(c8);\n    float4 _225_fa_fog_c : packoffset(c9);\n    float4 _225_fa_counts : packoffset(c10);\n    float4 _225_fa_env_sky : packoffset(c11);\n    float4 _225_fa_env_horizon : packoffset(c12);\n    float4 _225_fa_time : packoffset(c13);\n    float4 _225_fa_cl_vpx : packoffset(c14);\n    float4 _225_fa_cl_vpy : packoffset(c15);\n    float4 _225_fa_cl_vpw : packoffset(c16);\n    float4 _225_fa_cl_fwd : packoffset(c17);\n    float4 _225_fa_cl_grid : packoffset(c18);\n    float4 _225_fa_cl_info : packoffset(c19);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _454_alphaCutoff : packoffset(c0);\n    float _454_fa_pad0 : packoffset(c0.y);\n    float _454_fa_pad1 : packoffset(c0.z);\n    float _454_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> mask : register(t5);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _225_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _237 = fa_tex_fix(param_2, param_3);\n    float4 _544 = base_t;\n    _544.x = _237.x;\n    _544.y = _237.y;\n    _544.z = _237.z;\n    base_t = _544;\n    float4 _253 = (_544 * _225_fa_base_color) * i.vertex_color;\n    float3 _531 = i.world_normal;\n    if (_225_fa_maps.z > 0.5f)\n    {\n        float param_4 = _225_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _287 = fa_tex_fix(param_6, param_7);\n        float3 _290 = (_287 * 2.0f) - 1.0f.xxx;\n        float2 _295 = _290.xy * _225_fa_maps.x;\n        float3 _552 = _290;\n        _552.x = _295.x;\n        _552.y = _295.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _552;\n        _531 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _225_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _324 = fa_tex_fix(param_12, param_13);\n    float4 _555 = mrt;\n    _555.x = _324.x;\n    _555.y = _324.y;\n    _555.z = _324.z;\n    mrt = _555;\n    float param_14 = _225_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _365 = fa_tex_fix(param_16, param_17);\n    float param_18 = _225_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _392 = fa_tex_fix(param_20, param_21);\n    Surface _543 = { _253.xyz, _253.w, _531, clamp(_225_fa_pbr.x * _324.z, 0.0f, 1.0f), clamp(_225_fa_pbr.y * _324.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_225_fa_maps.y * (_365.x - 1.0f)), _225_fa_emissive.xyz + (_225_fa_model_emissive.xyz * _392) };\n    return _543;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _478 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _478 = -_478;\n    }\n    float3 _438 = normalize(_225_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _491 = { fa_world_pos, _478, fa_world_tangent, fa_uv, fa_vertex_color, _438, gl_FrontFacing };\n    SurfaceInput param = _491;\n    SurfaceInput _499 = { fa_world_pos, _478, fa_world_tangent, fa_uv, fa_vertex_color, _438, gl_FrontFacing };\n    SurfaceInput param_1 = _499;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    if (param_2.alpha < _454_alphaCutoff)\n    {\n        discard;\n    }\n    fa_frag_color = float4(gl_FragCoord.z, 0.0f, 0.0f, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 1
          },
          {
            "slot": 2,
            "type": "vec4",
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
            "type": "vec3",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 5
          },
          {
            "slot": 6,
            "type": "vec2",
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
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_122",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_225",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_454",
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
          },
          {
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 5
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 2
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _127_fa_view_proj : packoffset(c0);\n    row_major float4x4 _127_fa_light_vp : packoffset(c4);\n    float4 _127_fa_uv_scale : packoffset(c8);\n    float4 _127_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _174_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float4 fa_joints : TEXCOORD5;\n    float4 fa_weights : TEXCOORD6;\n    float3 fa_normal : TEXCOORD7;\n    float2 fa_texcoord0 : TEXCOORD8;\n    float4 fa_tangent : TEXCOORD9;\n    float4 fa_color : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _165 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_174_fa_joint_rows[_165] * weights[i]);\n        r1 += (_174_fa_joint_rows[_165 + 1] * weights[i]);\n        r2 += (_174_fa_joint_rows[_165 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _65 = cross(model[1].xyz, model[2].xyz);\n    float _71 = (dot(model[0].xyz, _65) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _377 = { mul(float4(position, 1.0f), model).xyz, (((_65 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _71, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _71), texcoord0 * _127_fa_uv_scale.xy, color, position };\n    return _377;\n}\n\nvoid vert_main()\n{\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    fa_inst_begin();\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    VertexData _311 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    float3 _360 = _311.world_pos;\n    fa_world_pos = _360;\n    fa_world_normal = _311.world_normal;\n    fa_world_tangent = _311.world_tangent;\n    fa_uv = _311.uv;\n    fa_vertex_color = _311.color;\n    gl_Position = mul(float4(_360, 1.0f), _127_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _225_fa_camera_pos : packoffset(c0);\n    float4 _225_fa_ambient : packoffset(c1);\n    float4 _225_fa_base_color : packoffset(c2);\n    float4 _225_fa_emissive : packoffset(c3);\n    float4 _225_fa_model_emissive : packoffset(c4);\n    float4 _225_fa_pbr : packoffset(c5);\n    float4 _225_fa_maps : packoffset(c6);\n    float4 _225_fa_fog : packoffset(c7);\n    float4 _225_fa_fog_b : packoffset(c8);\n    float4 _225_fa_fog_c : packoffset(c9);\n    float4 _225_fa_counts : packoffset(c10);\n    float4 _225_fa_env_sky : packoffset(c11);\n    float4 _225_fa_env_horizon : packoffset(c12);\n    float4 _225_fa_time : packoffset(c13);\n    float4 _225_fa_cl_vpx : packoffset(c14);\n    float4 _225_fa_cl_vpy : packoffset(c15);\n    float4 _225_fa_cl_vpw : packoffset(c16);\n    float4 _225_fa_cl_fwd : packoffset(c17);\n    float4 _225_fa_cl_grid : packoffset(c18);\n    float4 _225_fa_cl_info : packoffset(c19);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _454_alphaCutoff : packoffset(c0);\n    float _454_fa_pad0 : packoffset(c0.y);\n    float _454_fa_pad1 : packoffset(c0.z);\n    float _454_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> mask : register(t5);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _225_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _237 = fa_tex_fix(param_2, param_3);\n    float4 _544 = base_t;\n    _544.x = _237.x;\n    _544.y = _237.y;\n    _544.z = _237.z;\n    base_t = _544;\n    float4 _253 = (_544 * _225_fa_base_color) * i.vertex_color;\n    float3 _531 = i.world_normal;\n    if (_225_fa_maps.z > 0.5f)\n    {\n        float param_4 = _225_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _287 = fa_tex_fix(param_6, param_7);\n        float3 _290 = (_287 * 2.0f) - 1.0f.xxx;\n        float2 _295 = _290.xy * _225_fa_maps.x;\n        float3 _552 = _290;\n        _552.x = _295.x;\n        _552.y = _295.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _552;\n        _531 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _225_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _324 = fa_tex_fix(param_12, param_13);\n    float4 _555 = mrt;\n    _555.x = _324.x;\n    _555.y = _324.y;\n    _555.z = _324.z;\n    mrt = _555;\n    float param_14 = _225_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _365 = fa_tex_fix(param_16, param_17);\n    float param_18 = _225_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _392 = fa_tex_fix(param_20, param_21);\n    Surface _543 = { _253.xyz, _253.w, _531, clamp(_225_fa_pbr.x * _324.z, 0.0f, 1.0f), clamp(_225_fa_pbr.y * _324.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_225_fa_maps.y * (_365.x - 1.0f)), _225_fa_emissive.xyz + (_225_fa_model_emissive.xyz * _392) };\n    return _543;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _478 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _478 = -_478;\n    }\n    float3 _438 = normalize(_225_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _491 = { fa_world_pos, _478, fa_world_tangent, fa_uv, fa_vertex_color, _438, gl_FrontFacing };\n    SurfaceInput param = _491;\n    SurfaceInput _499 = { fa_world_pos, _478, fa_world_tangent, fa_uv, fa_vertex_color, _438, gl_FrontFacing };\n    SurfaceInput param_1 = _499;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    if (param_2.alpha < _454_alphaCutoff)\n    {\n        discard;\n    }\n    fa_frag_color = float4(gl_FragCoord.z, 0.0f, 0.0f, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 1
          },
          {
            "slot": 2,
            "type": "vec4",
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
            "type": "vec3",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 7
          },
          {
            "slot": 8,
            "type": "vec2",
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
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_127",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_174",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_225",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_454",
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
          },
          {
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 5
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 2
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    }
  }
}
