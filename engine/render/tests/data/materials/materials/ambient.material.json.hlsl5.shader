{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "41c86c92dbb0093951c81b6ee249cbb5aa749f4b053c4954c67a5e43bd66f6f3",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _258 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _258;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _265 = _160.world_pos;\n    fa_world_pos = _265;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_265, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _394_fa_camera_pos : packoffset(c0);\n    float4 _394_fa_ambient : packoffset(c1);\n    float4 _394_fa_base_color : packoffset(c2);\n    float4 _394_fa_emissive : packoffset(c3);\n    float4 _394_fa_model_emissive : packoffset(c4);\n    float4 _394_fa_pbr : packoffset(c5);\n    float4 _394_fa_maps : packoffset(c6);\n    float4 _394_fa_fog : packoffset(c7);\n    float4 _394_fa_fog_b : packoffset(c8);\n    float4 _394_fa_fog_c : packoffset(c9);\n    float4 _394_fa_counts : packoffset(c10);\n    float4 _394_fa_env_sky : packoffset(c11);\n    float4 _394_fa_env_horizon : packoffset(c12);\n    float4 _394_fa_time : packoffset(c13);\n    float4 _394_fa_cl_vpx : packoffset(c14);\n    float4 _394_fa_cl_vpy : packoffset(c15);\n    float4 _394_fa_cl_vpw : packoffset(c16);\n    float4 _394_fa_cl_fwd : packoffset(c17);\n    float4 _394_fa_cl_grid : packoffset(c18);\n    float4 _394_fa_cl_info : packoffset(c19);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _1134_fa_shadow_mat[4] : packoffset(c0);\n    float4 _1134_fa_shadow_rect[4] : packoffset(c16);\n    float4 _1134_fa_shadow_info[4] : packoffset(c20);\n    float4 _1134_fa_shadow_split : packoffset(c24);\n    float4 _1134_fa_shadow_cfg : packoffset(c25);\n    float4 _1134_fa_shadow_bias : packoffset(c26);\n    float4 _1134_fa_shadow_eye : packoffset(c27);\n    float4 _1134_fa_shadow_fwd : packoffset(c28);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_decal_tex : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_irr_tex : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _399 = _394_fa_cl_info.x < 0.0f;\n    bool _406;\n    if (!_399)\n    {\n        _406 = _394_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _406 = _399;\n    }\n    bool _414;\n    if (!_406)\n    {\n        _414 = _394_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _414 = _406;\n    }\n    bool _421;\n    if (!_414)\n    {\n        _421 = _394_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _421 = _414;\n    }\n    bool _428;\n    if (!_421)\n    {\n        _428 = _394_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _428 = _421;\n    }\n    if (_428)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _438 = float4(world_pos, 1.0f);\n    float _445 = dot(_394_fa_cl_vpw, _438);\n    if (!(_445 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _467 = float2(dot(_394_fa_cl_vpx, _438), dot(_394_fa_cl_vpy, _438)) / _445.xx;\n    int _471 = int(_394_fa_cl_grid.x);\n    int _475 = int(_394_fa_cl_grid.y);\n    int param = (int(_394_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_394_fa_cl_fwd.xyz, world_pos) + _394_fa_cl_fwd.w, _394_fa_cl_grid.w) / _394_fa_cl_grid.w) * _394_fa_cl_grid.z)), 0, int(_394_fa_cl_info.y) - 1) * _475) + clamp(int(floor(((_467.y * 0.5f) + 0.5f) * _394_fa_cl_grid.y)), 0, _475 - 1)) * _471)) + clamp(int(floor(((_467.x * 0.5f) + 0.5f) * _394_fa_cl_grid.x)), 0, _471 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _551 = fa_cluster_texel(param);\n    return int2(int(_551.x), int(_551.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_394_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1792 = fa_cluster_lookup(param);\n    fa_cl_slot = _1792.x;\n    fa_cl_local = _1792.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _1888 = fa_linear_to_srgb(param);\n        c = _1888;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _1896 = fa_srgb_to_linear(param_1);\n            c = _1896;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _175;\n    if (i.front_facing)\n    {\n        _175 = i.world_normal;\n    }\n    else\n    {\n        _175 = -i.world_normal;\n    }\n    float3 _199 = normalize(i.world_tangent.xyz - (_175 * dot(_175, i.world_tangent.xyz)));\n    float3 _227 = normalize(((_199 * m.x) + ((cross(_175, _199) * i.world_tangent.w) * m.y)) + (_175 * m.z));\n    float3 _230;\n    if (i.front_facing)\n    {\n        _230 = _227;\n    }\n    else\n    {\n        _230 = -_227;\n    }\n    return _230;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _394_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1927 = fa_tex_fix(param_2, param_3);\n    float4 _2682 = base_t;\n    _2682.x = _1927.x;\n    _2682.y = _1927.y;\n    _2682.z = _1927.z;\n    base_t = _2682;\n    float4 _1941 = (_2682 * _394_fa_base_color) * i.vertex_color;\n    float3 _2612 = i.world_normal;\n    if (_394_fa_maps.z > 0.5f)\n    {\n        float param_4 = _394_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1973 = fa_tex_fix(param_6, param_7);\n        float3 _1976 = (_1973 * 2.0f) - 1.0f.xxx;\n        float2 _1981 = _1976.xy * _394_fa_maps.x;\n        float3 _2690 = _1976;\n        _2690.x = _1981.x;\n        _2690.y = _1981.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2690;\n        _2612 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _394_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2010 = fa_tex_fix(param_12, param_13);\n    float4 _2693 = mrt;\n    _2693.x = _2010.x;\n    _2693.y = _2010.y;\n    _2693.z = _2010.z;\n    mrt = _2693;\n    float param_14 = _394_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2049 = fa_tex_fix(param_16, param_17);\n    float param_18 = _394_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2076 = fa_tex_fix(param_20, param_21);\n    Surface _2624 = { _1941.xyz, _1941.w, _2612, clamp(_394_fa_pbr.x * _2010.z, 0.0f, 1.0f), clamp(_394_fa_pbr.y * _2010.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_394_fa_maps.y * (_2049.x - 1.0f)), _394_fa_emissive.xyz + (_394_fa_model_emissive.xyz * _2076) };\n    return _2624;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _632 = rect.zw - rect.xy;\n    float2 _636 = _632 * atlas;\n    float2 _640 = ddx * _636;\n    float2 _644 = ddy * _636;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _632), clamp(0.5f * log2(max(max(dot(_640, _640), dot(_644, _644)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    float3 _679 = ddx(world_pos);\n    float3 _682 = ddy(world_pos);\n    bool _685 = _394_fa_counts.y < 0.5f;\n    bool _692;\n    if (!_685)\n    {\n        _692 = _394_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _692 = _685;\n    }\n    if (_692)\n    {\n        return;\n    }\n    float3 param = world_pos;\n    float4 _699 = fa_cluster_texel(param);\n    int _703 = int(_699.w);\n    if (_703 < 1)\n    {\n        return;\n    }\n    int _713 = int(_394_fa_counts.y + 0.5f);\n    int param_1 = _713;\n    float4 _717 = fa_light_texel(param_1);\n    float2 _720 = _717.yz;\n    int _724 = int(_717.w);\n    int param_2 = _713 + 1;\n    float4 _729 = fa_light_texel(param_2);\n    float _730 = _729.x;\n    int _736 = int(_394_fa_counts.w + 0.5f) - 1;\n    int _740 = int(_699.z);\n    float3 _1006;\n    for (int k = 0; k < _703; k++)\n    {\n        int _753 = _740 + k;\n        int param_3 = _724 + (_753 >> 2);\n        int _771 = (_713 + 2) + (int(fa_light_texel(param_3)[_753 & 3]) * 7);\n        int param_4 = _771 + 6;\n        float4 _776 = fa_light_texel(param_4);\n        if (((int(_776.w + 0.5f) >> _736) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _771;\n        float4 _791 = fa_light_texel(param_5);\n        int param_6 = _771 + 1;\n        float4 _796 = fa_light_texel(param_6);\n        int param_7 = _771 + 2;\n        float4 _801 = fa_light_texel(param_7);\n        float3 _804 = _791.xyz;\n        float _809 = dot(_804, world_pos) + _791.w;\n        float3 _811 = _796.xyz;\n        float _816 = dot(_811, world_pos) + _796.w;\n        float3 _818 = _801.xyz;\n        float _823 = dot(_818, world_pos) + _801.w;\n        bool _828 = abs(_809) > 0.5f;\n        bool _836;\n        if (!_828)\n        {\n            _836 = abs(_816) > 0.5f;\n        }\n        else\n        {\n            _836 = _828;\n        }\n        bool _844;\n        if (!_836)\n        {\n            _844 = abs(_823) > 0.5f;\n        }\n        else\n        {\n            _844 = _836;\n        }\n        if (_844)\n        {\n            continue;\n        }\n        float _859 = clamp(dot(geo_normal, normalize(_818)) * _776.z, 0.0f, 1.0f);\n        if (_859 <= 0.0f)\n        {\n            continue;\n        }\n        float _879 = (clamp((0.5f - abs(_823)) * 10.0f, 0.0f, 1.0f) * _859) * _776.x;\n        float2 _887 = float2(_809 + 0.5f, 0.5f - _816);\n        float2 _897 = float2(dot(_804, _679), dot(_811, _679));\n        float2 _907 = float2(dot(_804, _682), dot(_811, _682));\n        int param_8 = _771 + 5;\n        float4 _912 = fa_light_texel(param_8);\n        int param_9 = _771 + 3;\n        float4 _917 = fa_light_texel(param_9);\n        int param_10 = _771 + 4;\n        float4 _922 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _912.xyz;\n        bool _932 = _917.z > _917.x;\n        if (_932)\n        {\n            float4 param_11 = _917;\n            float2 param_12 = _887;\n            float2 param_13 = _720;\n            float2 param_14 = _897;\n            float2 param_15 = _907;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_730 > 0.5f) && (_730 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _958 = fa_dc_to_linear(param_16);\n                float4 _2650 = tx;\n                _2650.x = _958.x;\n                _2650.y = _958.y;\n                _2650.z = _958.z;\n                tx = _2650;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_879 * tex_a) * _912.w, 0.0f, 1.0f).xxx);\n        if (_922.z > _922.x)\n        {\n            float4 param_17 = _922;\n            float2 param_18 = _887;\n            float2 param_19 = _720;\n            float2 param_20 = _897;\n            float2 param_21 = _907;\n            float4 _1002 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_730 > 1.5f)\n            {\n                float3 param_22 = _1002.xyz;\n                float3 _1012 = fa_dc_to_srgb(param_22);\n                _1006 = _1012;\n            }\n            else\n            {\n                _1006 = _1002.xyz;\n            }\n            float3 _1022 = (_1006 * 2.0f) - 1.0f.xxx;\n            float2 _1027 = _1022.xy * _776.y;\n            float3 _1049 = (normalize(_804) * _1027.x) + (normalize(_811) * _1027.y);\n            float3 _1052 = normalize(normal);\n            normal = normalize(lerp(_1052, normalize((_1052 * max(_1022.z, 0.0500000007450580596923828125f)) + (_1049 - (_1052 * dot(_1052, _1049)))), clamp(_879 * (_932 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_394_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _394_fa_ambient.xyz;\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    return float3(0.0f, ambientColor.y, 0.0f);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_394_fa_cl_info.x) + int(_394_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _267 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _273 = fa_light_texel(param_1);\n    float _276 = _273.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _283 = _276 < 0.5f;\n    float3 l;\n    if (_283)\n    {\n        l = normalize(_267.xyz);\n    }\n    else\n    {\n        float3 _295 = _267.xyz - world_pos;\n        float _297 = length(_295);\n        dist = _297;\n        l = _295 / max(_297, 9.9999997473787516355514526367188e-05f).xxx;\n        float _312 = _297 / max(_267.w, 0.001000000047497451305389404296875f);\n        float _318 = clamp(1.0f - (_312 * _312), 0.0f, 1.0f);\n        atten = _318 * _318;\n        if (_276 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _332 = fa_light_texel(param_2);\n            float _342 = _332.w;\n            int param_3 = (li * 4) + 3;\n            float4 _349 = fa_light_texel(param_3);\n            float _350 = _349.x;\n            float cos_inner = _350;\n            if (_350 > 1.5f)\n            {\n                cos_inner = lerp(_342, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_342, cos_inner, dot(-l, normalize(_332.xyz)));\n        }\n    }\n    int _380;\n    if (_283)\n    {\n        _380 = 0;\n    }\n    else\n    {\n        _380 = (_276 > 1.5f) ? 2 : 1;\n    }\n    LightSample _2590 = { l, _273.xyz * atten, atten, 1.0f, dist, _380 };\n    return _2590;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1124;\n    if (i == 0)\n    {\n        _1124 = _1134_fa_shadow_split.x;\n    }\n    else\n    {\n        float _1140;\n        if (i == 1)\n        {\n            _1140 = _1134_fa_shadow_split.y;\n        }\n        else\n        {\n            float _1148;\n            if (i == 2)\n            {\n                _1148 = _1134_fa_shadow_split.z;\n            }\n            else\n            {\n                _1148 = _1134_fa_shadow_split.w;\n            }\n            _1140 = _1148;\n        }\n        _1124 = _1140;\n    }\n    return _1124;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1112 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_1112), sin(_1112)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _1186 = max(_1134_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _1191 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1197 = sqrt(1.0f - (_1191 * _1191));\n    float _1204 = min(_1197 / max(_1191, 0.20000000298023223876953125f), 4.0f);\n    float _1209;\n    if (_1134_fa_shadow_bias.y > 0.0f)\n    {\n        _1209 = _1134_fa_shadow_bias.y;\n    }\n    else\n    {\n        _1209 = 1.5f * _1134_fa_shadow_info[ci].x;\n    }\n    float4 _1234 = mul(float4(world + (n * (_1209 * _1197)), 1.0f), _1134_fa_shadow_mat[ci]);\n    float _1241 = _1234.x;\n    bool _1244 = _1241 < _1134_fa_shadow_rect[ci].x;\n    bool _1253;\n    if (!_1244)\n    {\n        _1253 = _1241 > _1134_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1253 = _1244;\n    }\n    bool _1262;\n    if (!_1253)\n    {\n        _1262 = _1234.y < _1134_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1262 = _1253;\n    }\n    bool _1271;\n    if (!_1262)\n    {\n        _1271 = _1234.y > _1134_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1271 = _1262;\n    }\n    bool _1278;\n    if (!_1271)\n    {\n        _1278 = _1234.z > 1.0f;\n    }\n    else\n    {\n        _1278 = _1271;\n    }\n    if (_1278)\n    {\n        return -1.0f;\n    }\n    float _1287;\n    if (_1134_fa_shadow_bias.x > 0.0f)\n    {\n        _1287 = _1134_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1287 = 1.5f * _1134_fa_shadow_info[ci].x;\n    }\n    float _1306 = _1234.z - ((_1287 * (1.0f + (0.5f * _1204))) / _1186);\n    float _1315 = ((_1134_fa_shadow_info[ci].x * min(_1204, 3.0f)) * 0.5f) / _1186;\n    int _1324 = int(_1134_fa_shadow_cfg.z + 0.5f);\n    if (_1324 == 1)\n    {\n        float2 param = _1234.xy;\n        float4 param_1 = _1134_fa_shadow_rect[ci];\n        float _1335 = fa_shadow_depth(param, param_1);\n        return float(_1306 <= _1335);\n    }\n    float _1342 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _1345 = _1324 == 2;\n    if (_1345)\n    {\n        float _1359 = clamp(((_1134_fa_shadow_cfg.w * _1186) * 0.25f) / _1134_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1342;\n            float2 _1378 = fa_shadow_vogel(param_2, param_3, param_4) * _1359;\n            float2 param_5 = _1234.xy + (_1378 * _1134_fa_shadow_bias.zw);\n            float4 param_6 = _1134_fa_shadow_rect[ci];\n            float _1389 = fa_shadow_depth(param_5, param_6);\n            if (_1389 < (_1306 - (length(_1378) * _1315)))\n            {\n                sum += _1389;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_1306 - (sum / cnt), 0.0f) * _1186) * _1134_fa_shadow_cfg.w) / _1134_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _1433 = _1345 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1433; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1433;\n        float param_9 = _1342;\n        float2 _1452 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _1234.xy + (_1452 * _1134_fa_shadow_bias.zw);\n        float4 param_11 = _1134_fa_shadow_rect[ci];\n        float _1463 = fa_shadow_depth(param_10, param_11);\n        lit += float((_1306 - (length(_1452) * _1315)) <= _1463);\n    }\n    return lit / float(_1433);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_394_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1493 = int(_1134_fa_shadow_cfg.x + 0.5f);\n    if (_1493 < 1)\n    {\n        return 1.0f;\n    }\n    float _1508 = dot(world - _1134_fa_shadow_eye.xyz, _1134_fa_shadow_fwd.xyz);\n    int param = _1493 - 1;\n    if (_1508 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1520 = _1493 > 1;\n    bool _1527;\n    if (_1520)\n    {\n        _1527 = _1508 > _1134_fa_shadow_split.x;\n    }\n    else\n    {\n        _1527 = _1520;\n    }\n    if (_1527)\n    {\n        ci = 1;\n    }\n    bool _1531 = _1493 > 2;\n    bool _1538;\n    if (_1531)\n    {\n        _1538 = _1508 > _1134_fa_shadow_split.y;\n    }\n    else\n    {\n        _1538 = _1531;\n    }\n    if (_1538)\n    {\n        ci = 2;\n    }\n    bool _1542 = _1493 > 3;\n    bool _1549;\n    if (_1542)\n    {\n        _1549 = _1508 > _1134_fa_shadow_split.z;\n    }\n    else\n    {\n        _1549 = _1542;\n    }\n    if (_1549)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1493)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1575 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1575;\n        if (_1575 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_1134_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1600;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1600 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1600 = _1134_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1619 = _1134_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1600, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1630 = clamp((_1508 - (fa_shadow_split_at(param_7) - _1619)) / _1619, 0.0f, 1.0f);\n        if (_1630 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1493)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1651 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1651;\n                if (_1651 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1630);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1820 = fa_light_sample(param, param_1);\n    float3 _2597 = _1820.direction;\n    float3 _2592 = _1820.color;\n    float _2594 = _1820.shadow;\n    int _2602 = _1820.type;\n    if ((_2602 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2597;\n        float _1834 = fa_shadow_factor(param_2, param_3);\n        _2594 = _1834;\n        _2592 *= _1834;\n    }\n    LightSample _2609 = { _2597, _2592, _1820.attenuation, _2594, _1820._distance, _2602 };\n    return _2609;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_1134_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1675 = int(_1134_fa_shadow_cfg.x + 0.5f);\n    float _1685 = dot(world - _1134_fa_shadow_eye.xyz, _1134_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1690 = _1675 > 0;\n    bool _1699;\n    if (_1690)\n    {\n        int param = _1675 - 1;\n        _1699 = _1685 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1699 = _1690;\n    }\n    if (_1699)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1706 = _1675 > 1;\n        bool _1713;\n        if (_1706)\n        {\n            _1713 = _1685 > _1134_fa_shadow_split.x;\n        }\n        else\n        {\n            _1713 = _1706;\n        }\n        if (_1713)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1719 = _1675 > 2;\n        bool _1726;\n        if (_1719)\n        {\n            _1726 = _1685 > _1134_fa_shadow_split.y;\n        }\n        else\n        {\n            _1726 = _1719;\n        }\n        if (_1726)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1732 = _1675 > 3;\n        bool _1739;\n        if (_1732)\n        {\n            _1739 = _1685 > _1134_fa_shadow_split.z;\n        }\n        else\n        {\n            _1739 = _1732;\n        }\n        if (_1739)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _2475 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2475 = -_2475;\n    }\n    float3 _2119 = normalize(_394_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _2488 = { fa_world_pos, _2475, fa_world_tangent, fa_uv, fa_vertex_color, _2119, gl_FrontFacing };\n    SurfaceInput param_1 = _2488;\n    Surface _2127 = fa_standard_surface(param_1);\n    float3 _2514 = _2127.albedo;\n    float _2515 = _2127.alpha;\n    float3 _2516 = _2127.normal;\n    float _2517 = _2127.metallic;\n    float _2518 = _2127.roughness;\n    float _2519 = _2127.occlusion;\n    float3 _2520 = _2127.emission;\n    SurfaceInput _2496 = { fa_world_pos, _2475, fa_world_tangent, fa_uv, fa_vertex_color, _2119, gl_FrontFacing };\n    SurfaceInput param_2 = _2496;\n    Surface param_3 = _2127;\n    surface(param_2, param_3);\n    _2514 = param_3.albedo;\n    _2515 = param_3.alpha;\n    _2516 = param_3.normal;\n    _2517 = param_3.metallic;\n    _2518 = param_3.roughness;\n    _2519 = param_3.occlusion;\n    _2520 = param_3.emission;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _2475;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _2514 = param_6;\n    _2516 = param_7;\n    float3 result;\n    if (_394_fa_emissive.w > 0.5f)\n    {\n        result = _2514;\n    }\n    else\n    {\n        float3 _2165 = _2516;\n        float3 _2166 = normalize(_2165);\n        _2516 = _2166;\n        float3 param_8 = _2166;\n        SurfaceInput _2504 = { fa_world_pos, _2475, fa_world_tangent, fa_uv, fa_vertex_color, _2119, gl_FrontFacing };\n        SurfaceInput param_9 = _2504;\n        Surface _2550 = { _2514, _2515, _2516, _2517, _2518, _2519, _2520 };\n        Surface param_10 = _2550;\n        float3 param_11 = fa_ambient_light(param_8);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _2185 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2185; ln++)\n        {\n            int param_12 = ln;\n            int param_13 = fa_cl_light(param_12);\n            float3 param_14 = fa_world_pos;\n            float3 param_15 = _2475;\n            SurfaceInput _2512 = { fa_world_pos, _2475, fa_world_tangent, fa_uv, fa_vertex_color, _2119, gl_FrontFacing };\n            SurfaceInput param_16 = _2512;\n            Surface _2558 = { _2514, _2515, _2516, _2517, _2518, _2519, _2520 };\n            Surface param_17 = _2558;\n            LightSample param_18 = fa_light_shadowed(param_13, param_14, param_15);\n            lit += light(param_16, param_17, param_18);\n        }\n        result = lit;\n    }\n    float3 _2222 = result;\n    float3 _2223 = _2222 + _2520;\n    result = _2223;\n    float3 param_19 = _2223;\n    float3 param_20 = fa_world_pos;\n    result = fa_shadow_debug(param_19, param_20);\n    bool _2232 = _394_fa_fog.w > 0.0f;\n    bool _2240;\n    if (!_2232)\n    {\n        _2240 = _394_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2240 = _2232;\n    }\n    if (_2240)\n    {\n        float3 _2249 = fa_world_pos - _394_fa_camera_pos.xyz;\n        float _2256 = dot(_2249, _394_fa_fog_c.xyz);\n        bool _2260 = _394_fa_fog_c.w > 0.5f;\n        float _2261;\n        if (_2260)\n        {\n            _2261 = _2256;\n        }\n        else\n        {\n            _2261 = length(_2249);\n        }\n        float _2273 = _2261 - _394_fa_fog_b.x;\n        if (_2273 > 0.0f)\n        {\n            float _2282 = _394_fa_fog.w * _2273;\n            float tau = _2282 * _2282;\n            if (_394_fa_fog_b.y > 0.0f)\n            {\n                float _2298;\n                if (_2260)\n                {\n                    _2298 = fa_world_pos.y - (_394_fa_fog_c.y * _2256);\n                }\n                else\n                {\n                    _2298 = _394_fa_camera_pos.y;\n                }\n                float _2319 = lerp(_2298, fa_world_pos.y, clamp(_394_fa_fog_b.x / _2261, 0.0f, 1.0f));\n                float _2323 = fa_world_pos.y - _2319;\n                float _2328 = _2319 - _394_fa_fog_b.z;\n                float _2333 = fa_world_pos.y - _394_fa_fog_b.z;\n                bool _2336 = _2328 <= 0.0f;\n                bool _2337 = !_2336;\n                bool _2343;\n                if (_2337)\n                {\n                    _2343 = _394_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2343 = _2336;\n                }\n                float _2344;\n                if (_2343)\n                {\n                    _2344 = _394_fa_fog_b.y;\n                }\n                else\n                {\n                    _2344 = _394_fa_fog_b.y * exp(-min(_394_fa_fog_b.w * _2328, 80.0f));\n                }\n                bool _2371;\n                if (_2337)\n                {\n                    _2371 = _394_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2371 = _2336;\n                }\n                float _2372;\n                if (_2371)\n                {\n                    _2372 = _394_fa_fog_b.y * _2328;\n                }\n                else\n                {\n                    _2372 = (_394_fa_fog_b.y * (1.0f - exp(-min(_394_fa_fog_b.w * _2328, 80.0f)))) / _394_fa_fog_b.w;\n                }\n                bool _2397 = _2333 <= 0.0f;\n                bool _2404;\n                if (!_2397)\n                {\n                    _2404 = _394_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2404 = _2397;\n                }\n                float _2405;\n                if (_2404)\n                {\n                    _2405 = _394_fa_fog_b.y * _2333;\n                }\n                else\n                {\n                    _2405 = (_394_fa_fog_b.y * (1.0f - exp(-min(_394_fa_fog_b.w * _2333, 80.0f)))) / _394_fa_fog_b.w;\n                }\n                float _2432;\n                if (abs(_2323) < 0.001000000047497451305389404296875f)\n                {\n                    _2432 = _2344;\n                }\n                else\n                {\n                    _2432 = (_2405 - _2372) / _2323;\n                }\n                tau += (_2273 * max(_2432, 0.0f));\n            }\n            result = lerp(result, _394_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _2515);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_394",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_1134",
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
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 8
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
          },
          {
            "slot": 8,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _379 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _379;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _386 = _273.world_pos;\n    fa_world_pos = _386;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_386, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _394_fa_camera_pos : packoffset(c0);\n    float4 _394_fa_ambient : packoffset(c1);\n    float4 _394_fa_base_color : packoffset(c2);\n    float4 _394_fa_emissive : packoffset(c3);\n    float4 _394_fa_model_emissive : packoffset(c4);\n    float4 _394_fa_pbr : packoffset(c5);\n    float4 _394_fa_maps : packoffset(c6);\n    float4 _394_fa_fog : packoffset(c7);\n    float4 _394_fa_fog_b : packoffset(c8);\n    float4 _394_fa_fog_c : packoffset(c9);\n    float4 _394_fa_counts : packoffset(c10);\n    float4 _394_fa_env_sky : packoffset(c11);\n    float4 _394_fa_env_horizon : packoffset(c12);\n    float4 _394_fa_time : packoffset(c13);\n    float4 _394_fa_cl_vpx : packoffset(c14);\n    float4 _394_fa_cl_vpy : packoffset(c15);\n    float4 _394_fa_cl_vpw : packoffset(c16);\n    float4 _394_fa_cl_fwd : packoffset(c17);\n    float4 _394_fa_cl_grid : packoffset(c18);\n    float4 _394_fa_cl_info : packoffset(c19);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _1134_fa_shadow_mat[4] : packoffset(c0);\n    float4 _1134_fa_shadow_rect[4] : packoffset(c16);\n    float4 _1134_fa_shadow_info[4] : packoffset(c20);\n    float4 _1134_fa_shadow_split : packoffset(c24);\n    float4 _1134_fa_shadow_cfg : packoffset(c25);\n    float4 _1134_fa_shadow_bias : packoffset(c26);\n    float4 _1134_fa_shadow_eye : packoffset(c27);\n    float4 _1134_fa_shadow_fwd : packoffset(c28);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_decal_tex : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_irr_tex : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _399 = _394_fa_cl_info.x < 0.0f;\n    bool _406;\n    if (!_399)\n    {\n        _406 = _394_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _406 = _399;\n    }\n    bool _414;\n    if (!_406)\n    {\n        _414 = _394_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _414 = _406;\n    }\n    bool _421;\n    if (!_414)\n    {\n        _421 = _394_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _421 = _414;\n    }\n    bool _428;\n    if (!_421)\n    {\n        _428 = _394_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _428 = _421;\n    }\n    if (_428)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _438 = float4(world_pos, 1.0f);\n    float _445 = dot(_394_fa_cl_vpw, _438);\n    if (!(_445 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _467 = float2(dot(_394_fa_cl_vpx, _438), dot(_394_fa_cl_vpy, _438)) / _445.xx;\n    int _471 = int(_394_fa_cl_grid.x);\n    int _475 = int(_394_fa_cl_grid.y);\n    int param = (int(_394_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_394_fa_cl_fwd.xyz, world_pos) + _394_fa_cl_fwd.w, _394_fa_cl_grid.w) / _394_fa_cl_grid.w) * _394_fa_cl_grid.z)), 0, int(_394_fa_cl_info.y) - 1) * _475) + clamp(int(floor(((_467.y * 0.5f) + 0.5f) * _394_fa_cl_grid.y)), 0, _475 - 1)) * _471)) + clamp(int(floor(((_467.x * 0.5f) + 0.5f) * _394_fa_cl_grid.x)), 0, _471 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _551 = fa_cluster_texel(param);\n    return int2(int(_551.x), int(_551.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_394_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1792 = fa_cluster_lookup(param);\n    fa_cl_slot = _1792.x;\n    fa_cl_local = _1792.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _1888 = fa_linear_to_srgb(param);\n        c = _1888;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _1896 = fa_srgb_to_linear(param_1);\n            c = _1896;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _175;\n    if (i.front_facing)\n    {\n        _175 = i.world_normal;\n    }\n    else\n    {\n        _175 = -i.world_normal;\n    }\n    float3 _199 = normalize(i.world_tangent.xyz - (_175 * dot(_175, i.world_tangent.xyz)));\n    float3 _227 = normalize(((_199 * m.x) + ((cross(_175, _199) * i.world_tangent.w) * m.y)) + (_175 * m.z));\n    float3 _230;\n    if (i.front_facing)\n    {\n        _230 = _227;\n    }\n    else\n    {\n        _230 = -_227;\n    }\n    return _230;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _394_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1927 = fa_tex_fix(param_2, param_3);\n    float4 _2682 = base_t;\n    _2682.x = _1927.x;\n    _2682.y = _1927.y;\n    _2682.z = _1927.z;\n    base_t = _2682;\n    float4 _1941 = (_2682 * _394_fa_base_color) * i.vertex_color;\n    float3 _2612 = i.world_normal;\n    if (_394_fa_maps.z > 0.5f)\n    {\n        float param_4 = _394_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1973 = fa_tex_fix(param_6, param_7);\n        float3 _1976 = (_1973 * 2.0f) - 1.0f.xxx;\n        float2 _1981 = _1976.xy * _394_fa_maps.x;\n        float3 _2690 = _1976;\n        _2690.x = _1981.x;\n        _2690.y = _1981.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2690;\n        _2612 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _394_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2010 = fa_tex_fix(param_12, param_13);\n    float4 _2693 = mrt;\n    _2693.x = _2010.x;\n    _2693.y = _2010.y;\n    _2693.z = _2010.z;\n    mrt = _2693;\n    float param_14 = _394_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2049 = fa_tex_fix(param_16, param_17);\n    float param_18 = _394_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2076 = fa_tex_fix(param_20, param_21);\n    Surface _2624 = { _1941.xyz, _1941.w, _2612, clamp(_394_fa_pbr.x * _2010.z, 0.0f, 1.0f), clamp(_394_fa_pbr.y * _2010.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_394_fa_maps.y * (_2049.x - 1.0f)), _394_fa_emissive.xyz + (_394_fa_model_emissive.xyz * _2076) };\n    return _2624;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _632 = rect.zw - rect.xy;\n    float2 _636 = _632 * atlas;\n    float2 _640 = ddx * _636;\n    float2 _644 = ddy * _636;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _632), clamp(0.5f * log2(max(max(dot(_640, _640), dot(_644, _644)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    float3 _679 = ddx(world_pos);\n    float3 _682 = ddy(world_pos);\n    bool _685 = _394_fa_counts.y < 0.5f;\n    bool _692;\n    if (!_685)\n    {\n        _692 = _394_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _692 = _685;\n    }\n    if (_692)\n    {\n        return;\n    }\n    float3 param = world_pos;\n    float4 _699 = fa_cluster_texel(param);\n    int _703 = int(_699.w);\n    if (_703 < 1)\n    {\n        return;\n    }\n    int _713 = int(_394_fa_counts.y + 0.5f);\n    int param_1 = _713;\n    float4 _717 = fa_light_texel(param_1);\n    float2 _720 = _717.yz;\n    int _724 = int(_717.w);\n    int param_2 = _713 + 1;\n    float4 _729 = fa_light_texel(param_2);\n    float _730 = _729.x;\n    int _736 = int(_394_fa_counts.w + 0.5f) - 1;\n    int _740 = int(_699.z);\n    float3 _1006;\n    for (int k = 0; k < _703; k++)\n    {\n        int _753 = _740 + k;\n        int param_3 = _724 + (_753 >> 2);\n        int _771 = (_713 + 2) + (int(fa_light_texel(param_3)[_753 & 3]) * 7);\n        int param_4 = _771 + 6;\n        float4 _776 = fa_light_texel(param_4);\n        if (((int(_776.w + 0.5f) >> _736) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _771;\n        float4 _791 = fa_light_texel(param_5);\n        int param_6 = _771 + 1;\n        float4 _796 = fa_light_texel(param_6);\n        int param_7 = _771 + 2;\n        float4 _801 = fa_light_texel(param_7);\n        float3 _804 = _791.xyz;\n        float _809 = dot(_804, world_pos) + _791.w;\n        float3 _811 = _796.xyz;\n        float _816 = dot(_811, world_pos) + _796.w;\n        float3 _818 = _801.xyz;\n        float _823 = dot(_818, world_pos) + _801.w;\n        bool _828 = abs(_809) > 0.5f;\n        bool _836;\n        if (!_828)\n        {\n            _836 = abs(_816) > 0.5f;\n        }\n        else\n        {\n            _836 = _828;\n        }\n        bool _844;\n        if (!_836)\n        {\n            _844 = abs(_823) > 0.5f;\n        }\n        else\n        {\n            _844 = _836;\n        }\n        if (_844)\n        {\n            continue;\n        }\n        float _859 = clamp(dot(geo_normal, normalize(_818)) * _776.z, 0.0f, 1.0f);\n        if (_859 <= 0.0f)\n        {\n            continue;\n        }\n        float _879 = (clamp((0.5f - abs(_823)) * 10.0f, 0.0f, 1.0f) * _859) * _776.x;\n        float2 _887 = float2(_809 + 0.5f, 0.5f - _816);\n        float2 _897 = float2(dot(_804, _679), dot(_811, _679));\n        float2 _907 = float2(dot(_804, _682), dot(_811, _682));\n        int param_8 = _771 + 5;\n        float4 _912 = fa_light_texel(param_8);\n        int param_9 = _771 + 3;\n        float4 _917 = fa_light_texel(param_9);\n        int param_10 = _771 + 4;\n        float4 _922 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _912.xyz;\n        bool _932 = _917.z > _917.x;\n        if (_932)\n        {\n            float4 param_11 = _917;\n            float2 param_12 = _887;\n            float2 param_13 = _720;\n            float2 param_14 = _897;\n            float2 param_15 = _907;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_730 > 0.5f) && (_730 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _958 = fa_dc_to_linear(param_16);\n                float4 _2650 = tx;\n                _2650.x = _958.x;\n                _2650.y = _958.y;\n                _2650.z = _958.z;\n                tx = _2650;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_879 * tex_a) * _912.w, 0.0f, 1.0f).xxx);\n        if (_922.z > _922.x)\n        {\n            float4 param_17 = _922;\n            float2 param_18 = _887;\n            float2 param_19 = _720;\n            float2 param_20 = _897;\n            float2 param_21 = _907;\n            float4 _1002 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_730 > 1.5f)\n            {\n                float3 param_22 = _1002.xyz;\n                float3 _1012 = fa_dc_to_srgb(param_22);\n                _1006 = _1012;\n            }\n            else\n            {\n                _1006 = _1002.xyz;\n            }\n            float3 _1022 = (_1006 * 2.0f) - 1.0f.xxx;\n            float2 _1027 = _1022.xy * _776.y;\n            float3 _1049 = (normalize(_804) * _1027.x) + (normalize(_811) * _1027.y);\n            float3 _1052 = normalize(normal);\n            normal = normalize(lerp(_1052, normalize((_1052 * max(_1022.z, 0.0500000007450580596923828125f)) + (_1049 - (_1052 * dot(_1052, _1049)))), clamp(_879 * (_932 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_394_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _394_fa_ambient.xyz;\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    return float3(0.0f, ambientColor.y, 0.0f);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_394_fa_cl_info.x) + int(_394_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _267 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _273 = fa_light_texel(param_1);\n    float _276 = _273.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _283 = _276 < 0.5f;\n    float3 l;\n    if (_283)\n    {\n        l = normalize(_267.xyz);\n    }\n    else\n    {\n        float3 _295 = _267.xyz - world_pos;\n        float _297 = length(_295);\n        dist = _297;\n        l = _295 / max(_297, 9.9999997473787516355514526367188e-05f).xxx;\n        float _312 = _297 / max(_267.w, 0.001000000047497451305389404296875f);\n        float _318 = clamp(1.0f - (_312 * _312), 0.0f, 1.0f);\n        atten = _318 * _318;\n        if (_276 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _332 = fa_light_texel(param_2);\n            float _342 = _332.w;\n            int param_3 = (li * 4) + 3;\n            float4 _349 = fa_light_texel(param_3);\n            float _350 = _349.x;\n            float cos_inner = _350;\n            if (_350 > 1.5f)\n            {\n                cos_inner = lerp(_342, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_342, cos_inner, dot(-l, normalize(_332.xyz)));\n        }\n    }\n    int _380;\n    if (_283)\n    {\n        _380 = 0;\n    }\n    else\n    {\n        _380 = (_276 > 1.5f) ? 2 : 1;\n    }\n    LightSample _2590 = { l, _273.xyz * atten, atten, 1.0f, dist, _380 };\n    return _2590;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1124;\n    if (i == 0)\n    {\n        _1124 = _1134_fa_shadow_split.x;\n    }\n    else\n    {\n        float _1140;\n        if (i == 1)\n        {\n            _1140 = _1134_fa_shadow_split.y;\n        }\n        else\n        {\n            float _1148;\n            if (i == 2)\n            {\n                _1148 = _1134_fa_shadow_split.z;\n            }\n            else\n            {\n                _1148 = _1134_fa_shadow_split.w;\n            }\n            _1140 = _1148;\n        }\n        _1124 = _1140;\n    }\n    return _1124;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1112 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_1112), sin(_1112)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _1186 = max(_1134_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _1191 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1197 = sqrt(1.0f - (_1191 * _1191));\n    float _1204 = min(_1197 / max(_1191, 0.20000000298023223876953125f), 4.0f);\n    float _1209;\n    if (_1134_fa_shadow_bias.y > 0.0f)\n    {\n        _1209 = _1134_fa_shadow_bias.y;\n    }\n    else\n    {\n        _1209 = 1.5f * _1134_fa_shadow_info[ci].x;\n    }\n    float4 _1234 = mul(float4(world + (n * (_1209 * _1197)), 1.0f), _1134_fa_shadow_mat[ci]);\n    float _1241 = _1234.x;\n    bool _1244 = _1241 < _1134_fa_shadow_rect[ci].x;\n    bool _1253;\n    if (!_1244)\n    {\n        _1253 = _1241 > _1134_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1253 = _1244;\n    }\n    bool _1262;\n    if (!_1253)\n    {\n        _1262 = _1234.y < _1134_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1262 = _1253;\n    }\n    bool _1271;\n    if (!_1262)\n    {\n        _1271 = _1234.y > _1134_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1271 = _1262;\n    }\n    bool _1278;\n    if (!_1271)\n    {\n        _1278 = _1234.z > 1.0f;\n    }\n    else\n    {\n        _1278 = _1271;\n    }\n    if (_1278)\n    {\n        return -1.0f;\n    }\n    float _1287;\n    if (_1134_fa_shadow_bias.x > 0.0f)\n    {\n        _1287 = _1134_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1287 = 1.5f * _1134_fa_shadow_info[ci].x;\n    }\n    float _1306 = _1234.z - ((_1287 * (1.0f + (0.5f * _1204))) / _1186);\n    float _1315 = ((_1134_fa_shadow_info[ci].x * min(_1204, 3.0f)) * 0.5f) / _1186;\n    int _1324 = int(_1134_fa_shadow_cfg.z + 0.5f);\n    if (_1324 == 1)\n    {\n        float2 param = _1234.xy;\n        float4 param_1 = _1134_fa_shadow_rect[ci];\n        float _1335 = fa_shadow_depth(param, param_1);\n        return float(_1306 <= _1335);\n    }\n    float _1342 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _1345 = _1324 == 2;\n    if (_1345)\n    {\n        float _1359 = clamp(((_1134_fa_shadow_cfg.w * _1186) * 0.25f) / _1134_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1342;\n            float2 _1378 = fa_shadow_vogel(param_2, param_3, param_4) * _1359;\n            float2 param_5 = _1234.xy + (_1378 * _1134_fa_shadow_bias.zw);\n            float4 param_6 = _1134_fa_shadow_rect[ci];\n            float _1389 = fa_shadow_depth(param_5, param_6);\n            if (_1389 < (_1306 - (length(_1378) * _1315)))\n            {\n                sum += _1389;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_1306 - (sum / cnt), 0.0f) * _1186) * _1134_fa_shadow_cfg.w) / _1134_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _1433 = _1345 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1433; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1433;\n        float param_9 = _1342;\n        float2 _1452 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _1234.xy + (_1452 * _1134_fa_shadow_bias.zw);\n        float4 param_11 = _1134_fa_shadow_rect[ci];\n        float _1463 = fa_shadow_depth(param_10, param_11);\n        lit += float((_1306 - (length(_1452) * _1315)) <= _1463);\n    }\n    return lit / float(_1433);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_394_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1493 = int(_1134_fa_shadow_cfg.x + 0.5f);\n    if (_1493 < 1)\n    {\n        return 1.0f;\n    }\n    float _1508 = dot(world - _1134_fa_shadow_eye.xyz, _1134_fa_shadow_fwd.xyz);\n    int param = _1493 - 1;\n    if (_1508 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1520 = _1493 > 1;\n    bool _1527;\n    if (_1520)\n    {\n        _1527 = _1508 > _1134_fa_shadow_split.x;\n    }\n    else\n    {\n        _1527 = _1520;\n    }\n    if (_1527)\n    {\n        ci = 1;\n    }\n    bool _1531 = _1493 > 2;\n    bool _1538;\n    if (_1531)\n    {\n        _1538 = _1508 > _1134_fa_shadow_split.y;\n    }\n    else\n    {\n        _1538 = _1531;\n    }\n    if (_1538)\n    {\n        ci = 2;\n    }\n    bool _1542 = _1493 > 3;\n    bool _1549;\n    if (_1542)\n    {\n        _1549 = _1508 > _1134_fa_shadow_split.z;\n    }\n    else\n    {\n        _1549 = _1542;\n    }\n    if (_1549)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1493)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1575 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1575;\n        if (_1575 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_1134_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1600;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1600 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1600 = _1134_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1619 = _1134_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1600, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1630 = clamp((_1508 - (fa_shadow_split_at(param_7) - _1619)) / _1619, 0.0f, 1.0f);\n        if (_1630 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1493)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1651 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1651;\n                if (_1651 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1630);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1820 = fa_light_sample(param, param_1);\n    float3 _2597 = _1820.direction;\n    float3 _2592 = _1820.color;\n    float _2594 = _1820.shadow;\n    int _2602 = _1820.type;\n    if ((_2602 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2597;\n        float _1834 = fa_shadow_factor(param_2, param_3);\n        _2594 = _1834;\n        _2592 *= _1834;\n    }\n    LightSample _2609 = { _2597, _2592, _1820.attenuation, _2594, _1820._distance, _2602 };\n    return _2609;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_1134_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1675 = int(_1134_fa_shadow_cfg.x + 0.5f);\n    float _1685 = dot(world - _1134_fa_shadow_eye.xyz, _1134_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1690 = _1675 > 0;\n    bool _1699;\n    if (_1690)\n    {\n        int param = _1675 - 1;\n        _1699 = _1685 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1699 = _1690;\n    }\n    if (_1699)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1706 = _1675 > 1;\n        bool _1713;\n        if (_1706)\n        {\n            _1713 = _1685 > _1134_fa_shadow_split.x;\n        }\n        else\n        {\n            _1713 = _1706;\n        }\n        if (_1713)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1719 = _1675 > 2;\n        bool _1726;\n        if (_1719)\n        {\n            _1726 = _1685 > _1134_fa_shadow_split.y;\n        }\n        else\n        {\n            _1726 = _1719;\n        }\n        if (_1726)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1732 = _1675 > 3;\n        bool _1739;\n        if (_1732)\n        {\n            _1739 = _1685 > _1134_fa_shadow_split.z;\n        }\n        else\n        {\n            _1739 = _1732;\n        }\n        if (_1739)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _2475 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2475 = -_2475;\n    }\n    float3 _2119 = normalize(_394_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _2488 = { fa_world_pos, _2475, fa_world_tangent, fa_uv, fa_vertex_color, _2119, gl_FrontFacing };\n    SurfaceInput param_1 = _2488;\n    Surface _2127 = fa_standard_surface(param_1);\n    float3 _2514 = _2127.albedo;\n    float _2515 = _2127.alpha;\n    float3 _2516 = _2127.normal;\n    float _2517 = _2127.metallic;\n    float _2518 = _2127.roughness;\n    float _2519 = _2127.occlusion;\n    float3 _2520 = _2127.emission;\n    SurfaceInput _2496 = { fa_world_pos, _2475, fa_world_tangent, fa_uv, fa_vertex_color, _2119, gl_FrontFacing };\n    SurfaceInput param_2 = _2496;\n    Surface param_3 = _2127;\n    surface(param_2, param_3);\n    _2514 = param_3.albedo;\n    _2515 = param_3.alpha;\n    _2516 = param_3.normal;\n    _2517 = param_3.metallic;\n    _2518 = param_3.roughness;\n    _2519 = param_3.occlusion;\n    _2520 = param_3.emission;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _2475;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _2514 = param_6;\n    _2516 = param_7;\n    float3 result;\n    if (_394_fa_emissive.w > 0.5f)\n    {\n        result = _2514;\n    }\n    else\n    {\n        float3 _2165 = _2516;\n        float3 _2166 = normalize(_2165);\n        _2516 = _2166;\n        float3 param_8 = _2166;\n        SurfaceInput _2504 = { fa_world_pos, _2475, fa_world_tangent, fa_uv, fa_vertex_color, _2119, gl_FrontFacing };\n        SurfaceInput param_9 = _2504;\n        Surface _2550 = { _2514, _2515, _2516, _2517, _2518, _2519, _2520 };\n        Surface param_10 = _2550;\n        float3 param_11 = fa_ambient_light(param_8);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _2185 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2185; ln++)\n        {\n            int param_12 = ln;\n            int param_13 = fa_cl_light(param_12);\n            float3 param_14 = fa_world_pos;\n            float3 param_15 = _2475;\n            SurfaceInput _2512 = { fa_world_pos, _2475, fa_world_tangent, fa_uv, fa_vertex_color, _2119, gl_FrontFacing };\n            SurfaceInput param_16 = _2512;\n            Surface _2558 = { _2514, _2515, _2516, _2517, _2518, _2519, _2520 };\n            Surface param_17 = _2558;\n            LightSample param_18 = fa_light_shadowed(param_13, param_14, param_15);\n            lit += light(param_16, param_17, param_18);\n        }\n        result = lit;\n    }\n    float3 _2222 = result;\n    float3 _2223 = _2222 + _2520;\n    result = _2223;\n    float3 param_19 = _2223;\n    float3 param_20 = fa_world_pos;\n    result = fa_shadow_debug(param_19, param_20);\n    bool _2232 = _394_fa_fog.w > 0.0f;\n    bool _2240;\n    if (!_2232)\n    {\n        _2240 = _394_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2240 = _2232;\n    }\n    if (_2240)\n    {\n        float3 _2249 = fa_world_pos - _394_fa_camera_pos.xyz;\n        float _2256 = dot(_2249, _394_fa_fog_c.xyz);\n        bool _2260 = _394_fa_fog_c.w > 0.5f;\n        float _2261;\n        if (_2260)\n        {\n            _2261 = _2256;\n        }\n        else\n        {\n            _2261 = length(_2249);\n        }\n        float _2273 = _2261 - _394_fa_fog_b.x;\n        if (_2273 > 0.0f)\n        {\n            float _2282 = _394_fa_fog.w * _2273;\n            float tau = _2282 * _2282;\n            if (_394_fa_fog_b.y > 0.0f)\n            {\n                float _2298;\n                if (_2260)\n                {\n                    _2298 = fa_world_pos.y - (_394_fa_fog_c.y * _2256);\n                }\n                else\n                {\n                    _2298 = _394_fa_camera_pos.y;\n                }\n                float _2319 = lerp(_2298, fa_world_pos.y, clamp(_394_fa_fog_b.x / _2261, 0.0f, 1.0f));\n                float _2323 = fa_world_pos.y - _2319;\n                float _2328 = _2319 - _394_fa_fog_b.z;\n                float _2333 = fa_world_pos.y - _394_fa_fog_b.z;\n                bool _2336 = _2328 <= 0.0f;\n                bool _2337 = !_2336;\n                bool _2343;\n                if (_2337)\n                {\n                    _2343 = _394_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2343 = _2336;\n                }\n                float _2344;\n                if (_2343)\n                {\n                    _2344 = _394_fa_fog_b.y;\n                }\n                else\n                {\n                    _2344 = _394_fa_fog_b.y * exp(-min(_394_fa_fog_b.w * _2328, 80.0f));\n                }\n                bool _2371;\n                if (_2337)\n                {\n                    _2371 = _394_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2371 = _2336;\n                }\n                float _2372;\n                if (_2371)\n                {\n                    _2372 = _394_fa_fog_b.y * _2328;\n                }\n                else\n                {\n                    _2372 = (_394_fa_fog_b.y * (1.0f - exp(-min(_394_fa_fog_b.w * _2328, 80.0f)))) / _394_fa_fog_b.w;\n                }\n                bool _2397 = _2333 <= 0.0f;\n                bool _2404;\n                if (!_2397)\n                {\n                    _2404 = _394_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2404 = _2397;\n                }\n                float _2405;\n                if (_2404)\n                {\n                    _2405 = _394_fa_fog_b.y * _2333;\n                }\n                else\n                {\n                    _2405 = (_394_fa_fog_b.y * (1.0f - exp(-min(_394_fa_fog_b.w * _2333, 80.0f)))) / _394_fa_fog_b.w;\n                }\n                float _2432;\n                if (abs(_2323) < 0.001000000047497451305389404296875f)\n                {\n                    _2432 = _2344;\n                }\n                else\n                {\n                    _2432 = (_2405 - _2372) / _2323;\n                }\n                tau += (_2273 * max(_2432, 0.0f));\n            }\n            result = lerp(result, _394_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _2515);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_394",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_1134",
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
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 8
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
          },
          {
            "slot": 8,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _292 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _292;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _299 = _160.world_pos;\n    float4 _171 = float4(_299, 1.0f);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -mul(_171, _131_fa_light_vp).z;\n    fa_pre_r0 = float3(_131_fa_light_vp[0].x, _131_fa_light_vp[1].x, _131_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131_fa_light_vp[0].y, _131_fa_light_vp[1].y, _131_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131_fa_light_vp[0].z, _131_fa_light_vp[1].z, _131_fa_light_vp[2].z);\n    gl_Position = mul(_171, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _588 = base_t;\n    _588.x = _225.x;\n    _588.y = _225.y;\n    _588.z = _225.z;\n    base_t = _588;\n    float4 _241 = (_588 * _213_fa_base_color) * i.vertex_color;\n    float3 _569 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _596 = _279;\n        _596.x = _284.x;\n        _596.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _596;\n        _569 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _599 = mrt;\n    _599.x = _313.x;\n    _599.y = _313.y;\n    _599.z = _313.z;\n    mrt = _599;\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _354 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _381 = fa_tex_fix(param_20, param_21);\n    Surface _581 = { _241.xyz, _241.w, _569, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_354.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _381) };\n    return _581;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _516 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _516 = -_516;\n    }\n    float3 _427 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _529 = { fa_world_pos, _516, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing };\n    SurfaceInput param = _529;\n    SurfaceInput _537 = { fa_world_pos, _516, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing };\n    SurfaceInput param_1 = _537;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _442 = normalize(param_2.normal);\n    float3 _457 = normalize(float3(dot(fa_pre_r0, _442), dot(fa_pre_r1, _442), dot(fa_pre_r2, _442)));\n    float _469 = _457.z;\n    float2 e = _457.xy / ((abs(_457.x) + abs(_457.y)) + abs(_469)).xx;\n    if (_469 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _413 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _413;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _420 = _273.world_pos;\n    float4 _284 = float4(_420, 1.0f);\n    fa_world_pos = _420;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -mul(_284, _136_fa_light_vp).z;\n    fa_pre_r0 = float3(_136_fa_light_vp[0].x, _136_fa_light_vp[1].x, _136_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136_fa_light_vp[0].y, _136_fa_light_vp[1].y, _136_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136_fa_light_vp[0].z, _136_fa_light_vp[1].z, _136_fa_light_vp[2].z);\n    gl_Position = mul(_284, _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _588 = base_t;\n    _588.x = _225.x;\n    _588.y = _225.y;\n    _588.z = _225.z;\n    base_t = _588;\n    float4 _241 = (_588 * _213_fa_base_color) * i.vertex_color;\n    float3 _569 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _596 = _279;\n        _596.x = _284.x;\n        _596.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _596;\n        _569 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _599 = mrt;\n    _599.x = _313.x;\n    _599.y = _313.y;\n    _599.z = _313.z;\n    mrt = _599;\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _354 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _381 = fa_tex_fix(param_20, param_21);\n    Surface _581 = { _241.xyz, _241.w, _569, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_354.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _381) };\n    return _581;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _516 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _516 = -_516;\n    }\n    float3 _427 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _529 = { fa_world_pos, _516, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing };\n    SurfaceInput param = _529;\n    SurfaceInput _537 = { fa_world_pos, _516, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing };\n    SurfaceInput param_1 = _537;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _442 = normalize(param_2.normal);\n    float3 _457 = normalize(float3(dot(fa_pre_r0, _442), dot(fa_pre_r1, _442), dot(fa_pre_r2, _442)));\n    float _469 = _457.z;\n    float2 e = _457.xy / ((abs(_457.x) + abs(_457.y)) + abs(_469)).xx;\n    if (_469 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
