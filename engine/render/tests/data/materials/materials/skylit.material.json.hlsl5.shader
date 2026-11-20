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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _415_fa_camera_pos : packoffset(c0);\n    float4 _415_fa_ambient : packoffset(c1);\n    float4 _415_fa_base_color : packoffset(c2);\n    float4 _415_fa_emissive : packoffset(c3);\n    float4 _415_fa_model_emissive : packoffset(c4);\n    float4 _415_fa_pbr : packoffset(c5);\n    float4 _415_fa_maps : packoffset(c6);\n    float4 _415_fa_fog : packoffset(c7);\n    float4 _415_fa_fog_b : packoffset(c8);\n    float4 _415_fa_fog_c : packoffset(c9);\n    float4 _415_fa_counts : packoffset(c10);\n    float4 _415_fa_env_sky : packoffset(c11);\n    float4 _415_fa_env_horizon : packoffset(c12);\n    float4 _415_fa_time : packoffset(c13);\n    float4 _415_fa_cl_vpx : packoffset(c14);\n    float4 _415_fa_cl_vpy : packoffset(c15);\n    float4 _415_fa_cl_vpw : packoffset(c16);\n    float4 _415_fa_cl_fwd : packoffset(c17);\n    float4 _415_fa_cl_grid : packoffset(c18);\n    float4 _415_fa_cl_info : packoffset(c19);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _1155_fa_shadow_mat[4] : packoffset(c0);\n    float4 _1155_fa_shadow_rect[4] : packoffset(c16);\n    float4 _1155_fa_shadow_info[4] : packoffset(c20);\n    float4 _1155_fa_shadow_split : packoffset(c24);\n    float4 _1155_fa_shadow_cfg : packoffset(c25);\n    float4 _1155_fa_shadow_bias : packoffset(c26);\n    float4 _1155_fa_shadow_eye : packoffset(c27);\n    float4 _1155_fa_shadow_fwd : packoffset(c28);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_decal_tex : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _420 = _415_fa_cl_info.x < 0.0f;\n    bool _427;\n    if (!_420)\n    {\n        _427 = _415_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _427 = _420;\n    }\n    bool _435;\n    if (!_427)\n    {\n        _435 = _415_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _435 = _427;\n    }\n    bool _442;\n    if (!_435)\n    {\n        _442 = _415_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _442 = _435;\n    }\n    bool _449;\n    if (!_442)\n    {\n        _449 = _415_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _449 = _442;\n    }\n    if (_449)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _459 = float4(world_pos, 1.0f);\n    float _466 = dot(_415_fa_cl_vpw, _459);\n    if (!(_466 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _488 = float2(dot(_415_fa_cl_vpx, _459), dot(_415_fa_cl_vpy, _459)) / _466.xx;\n    int _492 = int(_415_fa_cl_grid.x);\n    int _496 = int(_415_fa_cl_grid.y);\n    int param = (int(_415_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_415_fa_cl_fwd.xyz, world_pos) + _415_fa_cl_fwd.w, _415_fa_cl_grid.w) / _415_fa_cl_grid.w) * _415_fa_cl_grid.z)), 0, int(_415_fa_cl_info.y) - 1) * _496) + clamp(int(floor(((_488.y * 0.5f) + 0.5f) * _415_fa_cl_grid.y)), 0, _496 - 1)) * _492)) + clamp(int(floor(((_488.x * 0.5f) + 0.5f) * _415_fa_cl_grid.x)), 0, _492 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _572 = fa_cluster_texel(param);\n    return int2(int(_572.x), int(_572.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_415_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2003 = fa_cluster_lookup(param);\n    fa_cl_slot = _2003.x;\n    fa_cl_local = _2003.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _2101 = fa_linear_to_srgb(param);\n        c = _2101;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _2109 = fa_srgb_to_linear(param_1);\n            c = _2109;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _196;\n    if (i.front_facing)\n    {\n        _196 = i.world_normal;\n    }\n    else\n    {\n        _196 = -i.world_normal;\n    }\n    float3 _220 = normalize(i.world_tangent.xyz - (_196 * dot(_196, i.world_tangent.xyz)));\n    float3 _248 = normalize(((_220 * m.x) + ((cross(_196, _220) * i.world_tangent.w) * m.y)) + (_196 * m.z));\n    float3 _251;\n    if (i.front_facing)\n    {\n        _251 = _248;\n    }\n    else\n    {\n        _251 = -_248;\n    }\n    return _251;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _415_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2140 = fa_tex_fix(param_2, param_3);\n    float4 _2900 = base_t;\n    _2900.x = _2140.x;\n    _2900.y = _2140.y;\n    _2900.z = _2140.z;\n    base_t = _2900;\n    float4 _2154 = (_2900 * _415_fa_base_color) * i.vertex_color;\n    float3 _2824 = i.world_normal;\n    if (_415_fa_maps.z > 0.5f)\n    {\n        float param_4 = _415_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2186 = fa_tex_fix(param_6, param_7);\n        float3 _2189 = (_2186 * 2.0f) - 1.0f.xxx;\n        float2 _2194 = _2189.xy * _415_fa_maps.x;\n        float3 _2908 = _2189;\n        _2908.x = _2194.x;\n        _2908.y = _2194.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2908;\n        _2824 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _415_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2223 = fa_tex_fix(param_12, param_13);\n    float4 _2911 = mrt;\n    _2911.x = _2223.x;\n    _2911.y = _2223.y;\n    _2911.z = _2223.z;\n    mrt = _2911;\n    float param_14 = _415_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2262 = fa_tex_fix(param_16, param_17);\n    float param_18 = _415_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2289 = fa_tex_fix(param_20, param_21);\n    Surface _2836 = { _2154.xyz, _2154.w, _2824, clamp(_415_fa_pbr.x * _2223.z, 0.0f, 1.0f), clamp(_415_fa_pbr.y * _2223.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_415_fa_maps.y * (_2262.x - 1.0f)), _415_fa_emissive.xyz + (_415_fa_model_emissive.xyz * _2289) };\n    return _2836;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _653 = rect.zw - rect.xy;\n    float2 _657 = _653 * atlas;\n    float2 _661 = ddx * _657;\n    float2 _665 = ddy * _657;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _653), clamp(0.5f * log2(max(max(dot(_661, _661), dot(_665, _665)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    float3 _700 = ddx(world_pos);\n    float3 _703 = ddy(world_pos);\n    bool _706 = _415_fa_counts.y < 0.5f;\n    bool _713;\n    if (!_706)\n    {\n        _713 = _415_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _713 = _706;\n    }\n    if (_713)\n    {\n        return;\n    }\n    float3 param = world_pos;\n    float4 _720 = fa_cluster_texel(param);\n    int _724 = int(_720.w);\n    if (_724 < 1)\n    {\n        return;\n    }\n    int _734 = int(_415_fa_counts.y + 0.5f);\n    int param_1 = _734;\n    float4 _738 = fa_light_texel(param_1);\n    float2 _741 = _738.yz;\n    int _745 = int(_738.w);\n    int param_2 = _734 + 1;\n    float4 _750 = fa_light_texel(param_2);\n    float _751 = _750.x;\n    int _757 = int(_415_fa_counts.w + 0.5f) - 1;\n    int _761 = int(_720.z);\n    float3 _1027;\n    for (int k = 0; k < _724; k++)\n    {\n        int _774 = _761 + k;\n        int param_3 = _745 + (_774 >> 2);\n        int _792 = (_734 + 2) + (int(fa_light_texel(param_3)[_774 & 3]) * 7);\n        int param_4 = _792 + 6;\n        float4 _797 = fa_light_texel(param_4);\n        if (((int(_797.w + 0.5f) >> _757) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _792;\n        float4 _812 = fa_light_texel(param_5);\n        int param_6 = _792 + 1;\n        float4 _817 = fa_light_texel(param_6);\n        int param_7 = _792 + 2;\n        float4 _822 = fa_light_texel(param_7);\n        float3 _825 = _812.xyz;\n        float _830 = dot(_825, world_pos) + _812.w;\n        float3 _832 = _817.xyz;\n        float _837 = dot(_832, world_pos) + _817.w;\n        float3 _839 = _822.xyz;\n        float _844 = dot(_839, world_pos) + _822.w;\n        bool _849 = abs(_830) > 0.5f;\n        bool _857;\n        if (!_849)\n        {\n            _857 = abs(_837) > 0.5f;\n        }\n        else\n        {\n            _857 = _849;\n        }\n        bool _865;\n        if (!_857)\n        {\n            _865 = abs(_844) > 0.5f;\n        }\n        else\n        {\n            _865 = _857;\n        }\n        if (_865)\n        {\n            continue;\n        }\n        float _880 = clamp(dot(geo_normal, normalize(_839)) * _797.z, 0.0f, 1.0f);\n        if (_880 <= 0.0f)\n        {\n            continue;\n        }\n        float _900 = (clamp((0.5f - abs(_844)) * 10.0f, 0.0f, 1.0f) * _880) * _797.x;\n        float2 _908 = float2(_830 + 0.5f, 0.5f - _837);\n        float2 _918 = float2(dot(_825, _700), dot(_832, _700));\n        float2 _928 = float2(dot(_825, _703), dot(_832, _703));\n        int param_8 = _792 + 5;\n        float4 _933 = fa_light_texel(param_8);\n        int param_9 = _792 + 3;\n        float4 _938 = fa_light_texel(param_9);\n        int param_10 = _792 + 4;\n        float4 _943 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _933.xyz;\n        bool _953 = _938.z > _938.x;\n        if (_953)\n        {\n            float4 param_11 = _938;\n            float2 param_12 = _908;\n            float2 param_13 = _741;\n            float2 param_14 = _918;\n            float2 param_15 = _928;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_751 > 0.5f) && (_751 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _979 = fa_dc_to_linear(param_16);\n                float4 _2862 = tx;\n                _2862.x = _979.x;\n                _2862.y = _979.y;\n                _2862.z = _979.z;\n                tx = _2862;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_900 * tex_a) * _933.w, 0.0f, 1.0f).xxx);\n        if (_943.z > _943.x)\n        {\n            float4 param_17 = _943;\n            float2 param_18 = _908;\n            float2 param_19 = _741;\n            float2 param_20 = _918;\n            float2 param_21 = _928;\n            float4 _1023 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_751 > 1.5f)\n            {\n                float3 param_22 = _1023.xyz;\n                float3 _1033 = fa_dc_to_srgb(param_22);\n                _1027 = _1033;\n            }\n            else\n            {\n                _1027 = _1023.xyz;\n            }\n            float3 _1043 = (_1027 * 2.0f) - 1.0f.xxx;\n            float2 _1048 = _1043.xy * _797.y;\n            float3 _1070 = (normalize(_825) * _1048.x) + (normalize(_832) * _1048.y);\n            float3 _1073 = normalize(normal);\n            normal = normalize(lerp(_1073, normalize((_1073 * max(_1043.z, 0.0500000007450580596923828125f)) + (_1070 - (_1073 * dot(_1073, _1070)))), clamp(_900 * (_953 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_415_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _415_fa_ambient.xyz;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _1902 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _1905 = _1902.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_1905 * _1905, exp2((-9.27999973297119140625f) * ndv)) * _1905) + _1902.y)) + _1902.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_415_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _415_fa_env_horizon.w).xyz;\n    }\n    float _1808 = rough * rough;\n    float _1838 = 0.60000002384185791015625f * _1808;\n    return lerp(lerp(_415_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_415_fa_env_horizon.xyz, _415_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _1808)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _1838, 0.0500000007450580596923828125f + _1838, d.y).xxx), ((_415_fa_env_sky.xyz + _415_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_1808 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1944 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1944.x) + _1944.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float3 param = normalize(s.normal);\n    float3 param_1 = i.view_dir;\n    float3 param_2 = lerp(0.039999999105930328369140625f.xxx, s.albedo, clamp(s.metallic, 0.0f, 1.0f).xxx);\n    float param_3 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    return fa_sky_reflection(param, param_1, param_2, param_3) * s.occlusion;\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_415_fa_cl_info.x) + int(_415_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _288 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _294 = fa_light_texel(param_1);\n    float _297 = _294.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _304 = _297 < 0.5f;\n    float3 l;\n    if (_304)\n    {\n        l = normalize(_288.xyz);\n    }\n    else\n    {\n        float3 _316 = _288.xyz - world_pos;\n        float _318 = length(_316);\n        dist = _318;\n        l = _316 / max(_318, 9.9999997473787516355514526367188e-05f).xxx;\n        float _333 = _318 / max(_288.w, 0.001000000047497451305389404296875f);\n        float _339 = clamp(1.0f - (_333 * _333), 0.0f, 1.0f);\n        atten = _339 * _339;\n        if (_297 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _353 = fa_light_texel(param_2);\n            float _363 = _353.w;\n            int param_3 = (li * 4) + 3;\n            float4 _370 = fa_light_texel(param_3);\n            float _371 = _370.x;\n            float cos_inner = _371;\n            if (_371 > 1.5f)\n            {\n                cos_inner = lerp(_363, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_363, cos_inner, dot(-l, normalize(_353.xyz)));\n        }\n    }\n    int _401;\n    if (_304)\n    {\n        _401 = 0;\n    }\n    else\n    {\n        _401 = (_297 > 1.5f) ? 2 : 1;\n    }\n    LightSample _2802 = { l, _294.xyz * atten, atten, 1.0f, dist, _401 };\n    return _2802;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1145;\n    if (i == 0)\n    {\n        _1145 = _1155_fa_shadow_split.x;\n    }\n    else\n    {\n        float _1161;\n        if (i == 1)\n        {\n            _1161 = _1155_fa_shadow_split.y;\n        }\n        else\n        {\n            float _1169;\n            if (i == 2)\n            {\n                _1169 = _1155_fa_shadow_split.z;\n            }\n            else\n            {\n                _1169 = _1155_fa_shadow_split.w;\n            }\n            _1161 = _1169;\n        }\n        _1145 = _1161;\n    }\n    return _1145;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1133 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_1133), sin(_1133)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _1207 = max(_1155_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _1212 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1218 = sqrt(1.0f - (_1212 * _1212));\n    float _1225 = min(_1218 / max(_1212, 0.20000000298023223876953125f), 4.0f);\n    float _1230;\n    if (_1155_fa_shadow_bias.y > 0.0f)\n    {\n        _1230 = _1155_fa_shadow_bias.y;\n    }\n    else\n    {\n        _1230 = 1.5f * _1155_fa_shadow_info[ci].x;\n    }\n    float4 _1255 = mul(float4(world + (n * (_1230 * _1218)), 1.0f), _1155_fa_shadow_mat[ci]);\n    float _1262 = _1255.x;\n    bool _1265 = _1262 < _1155_fa_shadow_rect[ci].x;\n    bool _1274;\n    if (!_1265)\n    {\n        _1274 = _1262 > _1155_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1274 = _1265;\n    }\n    bool _1283;\n    if (!_1274)\n    {\n        _1283 = _1255.y < _1155_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1283 = _1274;\n    }\n    bool _1292;\n    if (!_1283)\n    {\n        _1292 = _1255.y > _1155_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1292 = _1283;\n    }\n    bool _1299;\n    if (!_1292)\n    {\n        _1299 = _1255.z > 1.0f;\n    }\n    else\n    {\n        _1299 = _1292;\n    }\n    if (_1299)\n    {\n        return -1.0f;\n    }\n    float _1308;\n    if (_1155_fa_shadow_bias.x > 0.0f)\n    {\n        _1308 = _1155_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1308 = 1.5f * _1155_fa_shadow_info[ci].x;\n    }\n    float _1327 = _1255.z - ((_1308 * (1.0f + (0.5f * _1225))) / _1207);\n    float _1336 = ((_1155_fa_shadow_info[ci].x * min(_1225, 3.0f)) * 0.5f) / _1207;\n    int _1345 = int(_1155_fa_shadow_cfg.z + 0.5f);\n    if (_1345 == 1)\n    {\n        float2 param = _1255.xy;\n        float4 param_1 = _1155_fa_shadow_rect[ci];\n        float _1356 = fa_shadow_depth(param, param_1);\n        return float(_1327 <= _1356);\n    }\n    float _1363 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _1366 = _1345 == 2;\n    if (_1366)\n    {\n        float _1380 = clamp(((_1155_fa_shadow_cfg.w * _1207) * 0.25f) / _1155_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1363;\n            float2 _1399 = fa_shadow_vogel(param_2, param_3, param_4) * _1380;\n            float2 param_5 = _1255.xy + (_1399 * _1155_fa_shadow_bias.zw);\n            float4 param_6 = _1155_fa_shadow_rect[ci];\n            float _1410 = fa_shadow_depth(param_5, param_6);\n            if (_1410 < (_1327 - (length(_1399) * _1336)))\n            {\n                sum += _1410;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_1327 - (sum / cnt), 0.0f) * _1207) * _1155_fa_shadow_cfg.w) / _1155_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _1454 = _1366 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1454; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1454;\n        float param_9 = _1363;\n        float2 _1473 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _1255.xy + (_1473 * _1155_fa_shadow_bias.zw);\n        float4 param_11 = _1155_fa_shadow_rect[ci];\n        float _1484 = fa_shadow_depth(param_10, param_11);\n        lit += float((_1327 - (length(_1473) * _1336)) <= _1484);\n    }\n    return lit / float(_1454);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_415_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1514 = int(_1155_fa_shadow_cfg.x + 0.5f);\n    if (_1514 < 1)\n    {\n        return 1.0f;\n    }\n    float _1529 = dot(world - _1155_fa_shadow_eye.xyz, _1155_fa_shadow_fwd.xyz);\n    int param = _1514 - 1;\n    if (_1529 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1541 = _1514 > 1;\n    bool _1548;\n    if (_1541)\n    {\n        _1548 = _1529 > _1155_fa_shadow_split.x;\n    }\n    else\n    {\n        _1548 = _1541;\n    }\n    if (_1548)\n    {\n        ci = 1;\n    }\n    bool _1552 = _1514 > 2;\n    bool _1559;\n    if (_1552)\n    {\n        _1559 = _1529 > _1155_fa_shadow_split.y;\n    }\n    else\n    {\n        _1559 = _1552;\n    }\n    if (_1559)\n    {\n        ci = 2;\n    }\n    bool _1563 = _1514 > 3;\n    bool _1570;\n    if (_1563)\n    {\n        _1570 = _1529 > _1155_fa_shadow_split.z;\n    }\n    else\n    {\n        _1570 = _1563;\n    }\n    if (_1570)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1514)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1596 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1596;\n        if (_1596 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_1155_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1621;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1621 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1621 = _1155_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1640 = _1155_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1621, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1651 = clamp((_1529 - (fa_shadow_split_at(param_7) - _1640)) / _1640, 0.0f, 1.0f);\n        if (_1651 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1514)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1672 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1672;\n                if (_1672 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1651);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _2031 = fa_light_sample(param, param_1);\n    float3 _2809 = _2031.direction;\n    float3 _2804 = _2031.color;\n    float _2806 = _2031.shadow;\n    int _2814 = _2031.type;\n    if ((_2814 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2809;\n        float _2045 = fa_shadow_factor(param_2, param_3);\n        _2806 = _2045;\n        _2804 *= _2045;\n    }\n    LightSample _2821 = { _2809, _2804, _2031.attenuation, _2806, _2031._distance, _2814 };\n    return _2821;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_1155_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1696 = int(_1155_fa_shadow_cfg.x + 0.5f);\n    float _1706 = dot(world - _1155_fa_shadow_eye.xyz, _1155_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1711 = _1696 > 0;\n    bool _1720;\n    if (_1711)\n    {\n        int param = _1696 - 1;\n        _1720 = _1706 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1720 = _1711;\n    }\n    if (_1720)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1727 = _1696 > 1;\n        bool _1734;\n        if (_1727)\n        {\n            _1734 = _1706 > _1155_fa_shadow_split.x;\n        }\n        else\n        {\n            _1734 = _1727;\n        }\n        if (_1734)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1740 = _1696 > 2;\n        bool _1747;\n        if (_1740)\n        {\n            _1747 = _1706 > _1155_fa_shadow_split.y;\n        }\n        else\n        {\n            _1747 = _1740;\n        }\n        if (_1747)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1753 = _1696 > 3;\n        bool _1760;\n        if (_1753)\n        {\n            _1760 = _1706 > _1155_fa_shadow_split.z;\n        }\n        else\n        {\n            _1760 = _1753;\n        }\n        if (_1760)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _2687 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2687 = -_2687;\n    }\n    float3 _2332 = normalize(_415_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _2700 = { fa_world_pos, _2687, fa_world_tangent, fa_uv, fa_vertex_color, _2332, gl_FrontFacing };\n    SurfaceInput param_1 = _2700;\n    Surface _2340 = fa_standard_surface(param_1);\n    float3 _2726 = _2340.albedo;\n    float _2727 = _2340.alpha;\n    float3 _2728 = _2340.normal;\n    float _2729 = _2340.metallic;\n    float _2730 = _2340.roughness;\n    float _2731 = _2340.occlusion;\n    float3 _2732 = _2340.emission;\n    SurfaceInput _2708 = { fa_world_pos, _2687, fa_world_tangent, fa_uv, fa_vertex_color, _2332, gl_FrontFacing };\n    SurfaceInput param_2 = _2708;\n    Surface param_3 = _2340;\n    surface(param_2, param_3);\n    _2726 = param_3.albedo;\n    _2727 = param_3.alpha;\n    _2728 = param_3.normal;\n    _2729 = param_3.metallic;\n    _2730 = param_3.roughness;\n    _2731 = param_3.occlusion;\n    _2732 = param_3.emission;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _2687;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _2726 = param_6;\n    _2728 = param_7;\n    float3 result;\n    if (_415_fa_emissive.w > 0.5f)\n    {\n        result = _2726;\n    }\n    else\n    {\n        float3 _2378 = _2728;\n        float3 _2379 = normalize(_2378);\n        _2728 = _2379;\n        float3 param_8 = _2379;\n        SurfaceInput _2716 = { fa_world_pos, _2687, fa_world_tangent, fa_uv, fa_vertex_color, _2332, gl_FrontFacing };\n        SurfaceInput param_9 = _2716;\n        Surface _2762 = { _2726, _2727, _2728, _2729, _2730, _2731, _2732 };\n        Surface param_10 = _2762;\n        float3 param_11 = fa_ambient_light(param_8);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _2398 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2398; ln++)\n        {\n            int param_12 = ln;\n            int param_13 = fa_cl_light(param_12);\n            float3 param_14 = fa_world_pos;\n            float3 param_15 = _2687;\n            SurfaceInput _2724 = { fa_world_pos, _2687, fa_world_tangent, fa_uv, fa_vertex_color, _2332, gl_FrontFacing };\n            SurfaceInput param_16 = _2724;\n            Surface _2770 = { _2726, _2727, _2728, _2729, _2730, _2731, _2732 };\n            Surface param_17 = _2770;\n            LightSample param_18 = fa_light_shadowed(param_13, param_14, param_15);\n            lit += light(param_16, param_17, param_18);\n        }\n        result = lit;\n    }\n    float3 _2435 = result;\n    float3 _2436 = _2435 + _2732;\n    result = _2436;\n    float3 param_19 = _2436;\n    float3 param_20 = fa_world_pos;\n    result = fa_shadow_debug(param_19, param_20);\n    bool _2445 = _415_fa_fog.w > 0.0f;\n    bool _2453;\n    if (!_2445)\n    {\n        _2453 = _415_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2453 = _2445;\n    }\n    if (_2453)\n    {\n        float3 _2462 = fa_world_pos - _415_fa_camera_pos.xyz;\n        float _2469 = dot(_2462, _415_fa_fog_c.xyz);\n        bool _2473 = _415_fa_fog_c.w > 0.5f;\n        float _2474;\n        if (_2473)\n        {\n            _2474 = _2469;\n        }\n        else\n        {\n            _2474 = length(_2462);\n        }\n        float _2486 = _2474 - _415_fa_fog_b.x;\n        if (_2486 > 0.0f)\n        {\n            float _2495 = _415_fa_fog.w * _2486;\n            float tau = _2495 * _2495;\n            if (_415_fa_fog_b.y > 0.0f)\n            {\n                float _2511;\n                if (_2473)\n                {\n                    _2511 = fa_world_pos.y - (_415_fa_fog_c.y * _2469);\n                }\n                else\n                {\n                    _2511 = _415_fa_camera_pos.y;\n                }\n                float _2532 = lerp(_2511, fa_world_pos.y, clamp(_415_fa_fog_b.x / _2474, 0.0f, 1.0f));\n                float _2536 = fa_world_pos.y - _2532;\n                float _2541 = _2532 - _415_fa_fog_b.z;\n                float _2546 = fa_world_pos.y - _415_fa_fog_b.z;\n                bool _2549 = _2541 <= 0.0f;\n                bool _2550 = !_2549;\n                bool _2556;\n                if (_2550)\n                {\n                    _2556 = _415_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2556 = _2549;\n                }\n                float _2557;\n                if (_2556)\n                {\n                    _2557 = _415_fa_fog_b.y;\n                }\n                else\n                {\n                    _2557 = _415_fa_fog_b.y * exp(-min(_415_fa_fog_b.w * _2541, 80.0f));\n                }\n                bool _2584;\n                if (_2550)\n                {\n                    _2584 = _415_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2584 = _2549;\n                }\n                float _2585;\n                if (_2584)\n                {\n                    _2585 = _415_fa_fog_b.y * _2541;\n                }\n                else\n                {\n                    _2585 = (_415_fa_fog_b.y * (1.0f - exp(-min(_415_fa_fog_b.w * _2541, 80.0f)))) / _415_fa_fog_b.w;\n                }\n                bool _2610 = _2546 <= 0.0f;\n                bool _2617;\n                if (!_2610)\n                {\n                    _2617 = _415_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2617 = _2610;\n                }\n                float _2618;\n                if (_2617)\n                {\n                    _2618 = _415_fa_fog_b.y * _2546;\n                }\n                else\n                {\n                    _2618 = (_415_fa_fog_b.y * (1.0f - exp(-min(_415_fa_fog_b.w * _2546, 80.0f)))) / _415_fa_fog_b.w;\n                }\n                float _2645;\n                if (abs(_2536) < 0.001000000047497451305389404296875f)\n                {\n                    _2645 = _2557;\n                }\n                else\n                {\n                    _2645 = (_2618 - _2585) / _2536;\n                }\n                tau += (_2486 * max(_2645, 0.0f));\n            }\n            result = lerp(result, _415_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _2727);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_415",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_1155",
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
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float",
              "hlsl_register_t_n": 7
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _379 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _379;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _386 = _273.world_pos;\n    fa_world_pos = _386;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_386, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _415_fa_camera_pos : packoffset(c0);\n    float4 _415_fa_ambient : packoffset(c1);\n    float4 _415_fa_base_color : packoffset(c2);\n    float4 _415_fa_emissive : packoffset(c3);\n    float4 _415_fa_model_emissive : packoffset(c4);\n    float4 _415_fa_pbr : packoffset(c5);\n    float4 _415_fa_maps : packoffset(c6);\n    float4 _415_fa_fog : packoffset(c7);\n    float4 _415_fa_fog_b : packoffset(c8);\n    float4 _415_fa_fog_c : packoffset(c9);\n    float4 _415_fa_counts : packoffset(c10);\n    float4 _415_fa_env_sky : packoffset(c11);\n    float4 _415_fa_env_horizon : packoffset(c12);\n    float4 _415_fa_time : packoffset(c13);\n    float4 _415_fa_cl_vpx : packoffset(c14);\n    float4 _415_fa_cl_vpy : packoffset(c15);\n    float4 _415_fa_cl_vpw : packoffset(c16);\n    float4 _415_fa_cl_fwd : packoffset(c17);\n    float4 _415_fa_cl_grid : packoffset(c18);\n    float4 _415_fa_cl_info : packoffset(c19);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _1155_fa_shadow_mat[4] : packoffset(c0);\n    float4 _1155_fa_shadow_rect[4] : packoffset(c16);\n    float4 _1155_fa_shadow_info[4] : packoffset(c20);\n    float4 _1155_fa_shadow_split : packoffset(c24);\n    float4 _1155_fa_shadow_cfg : packoffset(c25);\n    float4 _1155_fa_shadow_bias : packoffset(c26);\n    float4 _1155_fa_shadow_eye : packoffset(c27);\n    float4 _1155_fa_shadow_fwd : packoffset(c28);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_decal_tex : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _420 = _415_fa_cl_info.x < 0.0f;\n    bool _427;\n    if (!_420)\n    {\n        _427 = _415_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _427 = _420;\n    }\n    bool _435;\n    if (!_427)\n    {\n        _435 = _415_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _435 = _427;\n    }\n    bool _442;\n    if (!_435)\n    {\n        _442 = _415_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _442 = _435;\n    }\n    bool _449;\n    if (!_442)\n    {\n        _449 = _415_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _449 = _442;\n    }\n    if (_449)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _459 = float4(world_pos, 1.0f);\n    float _466 = dot(_415_fa_cl_vpw, _459);\n    if (!(_466 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _488 = float2(dot(_415_fa_cl_vpx, _459), dot(_415_fa_cl_vpy, _459)) / _466.xx;\n    int _492 = int(_415_fa_cl_grid.x);\n    int _496 = int(_415_fa_cl_grid.y);\n    int param = (int(_415_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_415_fa_cl_fwd.xyz, world_pos) + _415_fa_cl_fwd.w, _415_fa_cl_grid.w) / _415_fa_cl_grid.w) * _415_fa_cl_grid.z)), 0, int(_415_fa_cl_info.y) - 1) * _496) + clamp(int(floor(((_488.y * 0.5f) + 0.5f) * _415_fa_cl_grid.y)), 0, _496 - 1)) * _492)) + clamp(int(floor(((_488.x * 0.5f) + 0.5f) * _415_fa_cl_grid.x)), 0, _492 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _572 = fa_cluster_texel(param);\n    return int2(int(_572.x), int(_572.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_415_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2003 = fa_cluster_lookup(param);\n    fa_cl_slot = _2003.x;\n    fa_cl_local = _2003.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _2101 = fa_linear_to_srgb(param);\n        c = _2101;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _2109 = fa_srgb_to_linear(param_1);\n            c = _2109;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _196;\n    if (i.front_facing)\n    {\n        _196 = i.world_normal;\n    }\n    else\n    {\n        _196 = -i.world_normal;\n    }\n    float3 _220 = normalize(i.world_tangent.xyz - (_196 * dot(_196, i.world_tangent.xyz)));\n    float3 _248 = normalize(((_220 * m.x) + ((cross(_196, _220) * i.world_tangent.w) * m.y)) + (_196 * m.z));\n    float3 _251;\n    if (i.front_facing)\n    {\n        _251 = _248;\n    }\n    else\n    {\n        _251 = -_248;\n    }\n    return _251;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _415_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2140 = fa_tex_fix(param_2, param_3);\n    float4 _2900 = base_t;\n    _2900.x = _2140.x;\n    _2900.y = _2140.y;\n    _2900.z = _2140.z;\n    base_t = _2900;\n    float4 _2154 = (_2900 * _415_fa_base_color) * i.vertex_color;\n    float3 _2824 = i.world_normal;\n    if (_415_fa_maps.z > 0.5f)\n    {\n        float param_4 = _415_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2186 = fa_tex_fix(param_6, param_7);\n        float3 _2189 = (_2186 * 2.0f) - 1.0f.xxx;\n        float2 _2194 = _2189.xy * _415_fa_maps.x;\n        float3 _2908 = _2189;\n        _2908.x = _2194.x;\n        _2908.y = _2194.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2908;\n        _2824 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _415_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2223 = fa_tex_fix(param_12, param_13);\n    float4 _2911 = mrt;\n    _2911.x = _2223.x;\n    _2911.y = _2223.y;\n    _2911.z = _2223.z;\n    mrt = _2911;\n    float param_14 = _415_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2262 = fa_tex_fix(param_16, param_17);\n    float param_18 = _415_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2289 = fa_tex_fix(param_20, param_21);\n    Surface _2836 = { _2154.xyz, _2154.w, _2824, clamp(_415_fa_pbr.x * _2223.z, 0.0f, 1.0f), clamp(_415_fa_pbr.y * _2223.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_415_fa_maps.y * (_2262.x - 1.0f)), _415_fa_emissive.xyz + (_415_fa_model_emissive.xyz * _2289) };\n    return _2836;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _653 = rect.zw - rect.xy;\n    float2 _657 = _653 * atlas;\n    float2 _661 = ddx * _657;\n    float2 _665 = ddy * _657;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _653), clamp(0.5f * log2(max(max(dot(_661, _661), dot(_665, _665)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    float3 _700 = ddx(world_pos);\n    float3 _703 = ddy(world_pos);\n    bool _706 = _415_fa_counts.y < 0.5f;\n    bool _713;\n    if (!_706)\n    {\n        _713 = _415_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _713 = _706;\n    }\n    if (_713)\n    {\n        return;\n    }\n    float3 param = world_pos;\n    float4 _720 = fa_cluster_texel(param);\n    int _724 = int(_720.w);\n    if (_724 < 1)\n    {\n        return;\n    }\n    int _734 = int(_415_fa_counts.y + 0.5f);\n    int param_1 = _734;\n    float4 _738 = fa_light_texel(param_1);\n    float2 _741 = _738.yz;\n    int _745 = int(_738.w);\n    int param_2 = _734 + 1;\n    float4 _750 = fa_light_texel(param_2);\n    float _751 = _750.x;\n    int _757 = int(_415_fa_counts.w + 0.5f) - 1;\n    int _761 = int(_720.z);\n    float3 _1027;\n    for (int k = 0; k < _724; k++)\n    {\n        int _774 = _761 + k;\n        int param_3 = _745 + (_774 >> 2);\n        int _792 = (_734 + 2) + (int(fa_light_texel(param_3)[_774 & 3]) * 7);\n        int param_4 = _792 + 6;\n        float4 _797 = fa_light_texel(param_4);\n        if (((int(_797.w + 0.5f) >> _757) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _792;\n        float4 _812 = fa_light_texel(param_5);\n        int param_6 = _792 + 1;\n        float4 _817 = fa_light_texel(param_6);\n        int param_7 = _792 + 2;\n        float4 _822 = fa_light_texel(param_7);\n        float3 _825 = _812.xyz;\n        float _830 = dot(_825, world_pos) + _812.w;\n        float3 _832 = _817.xyz;\n        float _837 = dot(_832, world_pos) + _817.w;\n        float3 _839 = _822.xyz;\n        float _844 = dot(_839, world_pos) + _822.w;\n        bool _849 = abs(_830) > 0.5f;\n        bool _857;\n        if (!_849)\n        {\n            _857 = abs(_837) > 0.5f;\n        }\n        else\n        {\n            _857 = _849;\n        }\n        bool _865;\n        if (!_857)\n        {\n            _865 = abs(_844) > 0.5f;\n        }\n        else\n        {\n            _865 = _857;\n        }\n        if (_865)\n        {\n            continue;\n        }\n        float _880 = clamp(dot(geo_normal, normalize(_839)) * _797.z, 0.0f, 1.0f);\n        if (_880 <= 0.0f)\n        {\n            continue;\n        }\n        float _900 = (clamp((0.5f - abs(_844)) * 10.0f, 0.0f, 1.0f) * _880) * _797.x;\n        float2 _908 = float2(_830 + 0.5f, 0.5f - _837);\n        float2 _918 = float2(dot(_825, _700), dot(_832, _700));\n        float2 _928 = float2(dot(_825, _703), dot(_832, _703));\n        int param_8 = _792 + 5;\n        float4 _933 = fa_light_texel(param_8);\n        int param_9 = _792 + 3;\n        float4 _938 = fa_light_texel(param_9);\n        int param_10 = _792 + 4;\n        float4 _943 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _933.xyz;\n        bool _953 = _938.z > _938.x;\n        if (_953)\n        {\n            float4 param_11 = _938;\n            float2 param_12 = _908;\n            float2 param_13 = _741;\n            float2 param_14 = _918;\n            float2 param_15 = _928;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_751 > 0.5f) && (_751 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _979 = fa_dc_to_linear(param_16);\n                float4 _2862 = tx;\n                _2862.x = _979.x;\n                _2862.y = _979.y;\n                _2862.z = _979.z;\n                tx = _2862;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_900 * tex_a) * _933.w, 0.0f, 1.0f).xxx);\n        if (_943.z > _943.x)\n        {\n            float4 param_17 = _943;\n            float2 param_18 = _908;\n            float2 param_19 = _741;\n            float2 param_20 = _918;\n            float2 param_21 = _928;\n            float4 _1023 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_751 > 1.5f)\n            {\n                float3 param_22 = _1023.xyz;\n                float3 _1033 = fa_dc_to_srgb(param_22);\n                _1027 = _1033;\n            }\n            else\n            {\n                _1027 = _1023.xyz;\n            }\n            float3 _1043 = (_1027 * 2.0f) - 1.0f.xxx;\n            float2 _1048 = _1043.xy * _797.y;\n            float3 _1070 = (normalize(_825) * _1048.x) + (normalize(_832) * _1048.y);\n            float3 _1073 = normalize(normal);\n            normal = normalize(lerp(_1073, normalize((_1073 * max(_1043.z, 0.0500000007450580596923828125f)) + (_1070 - (_1073 * dot(_1073, _1070)))), clamp(_900 * (_953 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_415_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _415_fa_ambient.xyz;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _1902 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _1905 = _1902.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_1905 * _1905, exp2((-9.27999973297119140625f) * ndv)) * _1905) + _1902.y)) + _1902.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_415_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _415_fa_env_horizon.w).xyz;\n    }\n    float _1808 = rough * rough;\n    float _1838 = 0.60000002384185791015625f * _1808;\n    return lerp(lerp(_415_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_415_fa_env_horizon.xyz, _415_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _1808)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _1838, 0.0500000007450580596923828125f + _1838, d.y).xxx), ((_415_fa_env_sky.xyz + _415_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_1808 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1944 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1944.x) + _1944.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float3 param = normalize(s.normal);\n    float3 param_1 = i.view_dir;\n    float3 param_2 = lerp(0.039999999105930328369140625f.xxx, s.albedo, clamp(s.metallic, 0.0f, 1.0f).xxx);\n    float param_3 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    return fa_sky_reflection(param, param_1, param_2, param_3) * s.occlusion;\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_415_fa_cl_info.x) + int(_415_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _288 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _294 = fa_light_texel(param_1);\n    float _297 = _294.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _304 = _297 < 0.5f;\n    float3 l;\n    if (_304)\n    {\n        l = normalize(_288.xyz);\n    }\n    else\n    {\n        float3 _316 = _288.xyz - world_pos;\n        float _318 = length(_316);\n        dist = _318;\n        l = _316 / max(_318, 9.9999997473787516355514526367188e-05f).xxx;\n        float _333 = _318 / max(_288.w, 0.001000000047497451305389404296875f);\n        float _339 = clamp(1.0f - (_333 * _333), 0.0f, 1.0f);\n        atten = _339 * _339;\n        if (_297 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _353 = fa_light_texel(param_2);\n            float _363 = _353.w;\n            int param_3 = (li * 4) + 3;\n            float4 _370 = fa_light_texel(param_3);\n            float _371 = _370.x;\n            float cos_inner = _371;\n            if (_371 > 1.5f)\n            {\n                cos_inner = lerp(_363, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_363, cos_inner, dot(-l, normalize(_353.xyz)));\n        }\n    }\n    int _401;\n    if (_304)\n    {\n        _401 = 0;\n    }\n    else\n    {\n        _401 = (_297 > 1.5f) ? 2 : 1;\n    }\n    LightSample _2802 = { l, _294.xyz * atten, atten, 1.0f, dist, _401 };\n    return _2802;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1145;\n    if (i == 0)\n    {\n        _1145 = _1155_fa_shadow_split.x;\n    }\n    else\n    {\n        float _1161;\n        if (i == 1)\n        {\n            _1161 = _1155_fa_shadow_split.y;\n        }\n        else\n        {\n            float _1169;\n            if (i == 2)\n            {\n                _1169 = _1155_fa_shadow_split.z;\n            }\n            else\n            {\n                _1169 = _1155_fa_shadow_split.w;\n            }\n            _1161 = _1169;\n        }\n        _1145 = _1161;\n    }\n    return _1145;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1133 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_1133), sin(_1133)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _1207 = max(_1155_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _1212 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1218 = sqrt(1.0f - (_1212 * _1212));\n    float _1225 = min(_1218 / max(_1212, 0.20000000298023223876953125f), 4.0f);\n    float _1230;\n    if (_1155_fa_shadow_bias.y > 0.0f)\n    {\n        _1230 = _1155_fa_shadow_bias.y;\n    }\n    else\n    {\n        _1230 = 1.5f * _1155_fa_shadow_info[ci].x;\n    }\n    float4 _1255 = mul(float4(world + (n * (_1230 * _1218)), 1.0f), _1155_fa_shadow_mat[ci]);\n    float _1262 = _1255.x;\n    bool _1265 = _1262 < _1155_fa_shadow_rect[ci].x;\n    bool _1274;\n    if (!_1265)\n    {\n        _1274 = _1262 > _1155_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1274 = _1265;\n    }\n    bool _1283;\n    if (!_1274)\n    {\n        _1283 = _1255.y < _1155_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1283 = _1274;\n    }\n    bool _1292;\n    if (!_1283)\n    {\n        _1292 = _1255.y > _1155_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1292 = _1283;\n    }\n    bool _1299;\n    if (!_1292)\n    {\n        _1299 = _1255.z > 1.0f;\n    }\n    else\n    {\n        _1299 = _1292;\n    }\n    if (_1299)\n    {\n        return -1.0f;\n    }\n    float _1308;\n    if (_1155_fa_shadow_bias.x > 0.0f)\n    {\n        _1308 = _1155_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1308 = 1.5f * _1155_fa_shadow_info[ci].x;\n    }\n    float _1327 = _1255.z - ((_1308 * (1.0f + (0.5f * _1225))) / _1207);\n    float _1336 = ((_1155_fa_shadow_info[ci].x * min(_1225, 3.0f)) * 0.5f) / _1207;\n    int _1345 = int(_1155_fa_shadow_cfg.z + 0.5f);\n    if (_1345 == 1)\n    {\n        float2 param = _1255.xy;\n        float4 param_1 = _1155_fa_shadow_rect[ci];\n        float _1356 = fa_shadow_depth(param, param_1);\n        return float(_1327 <= _1356);\n    }\n    float _1363 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _1366 = _1345 == 2;\n    if (_1366)\n    {\n        float _1380 = clamp(((_1155_fa_shadow_cfg.w * _1207) * 0.25f) / _1155_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1363;\n            float2 _1399 = fa_shadow_vogel(param_2, param_3, param_4) * _1380;\n            float2 param_5 = _1255.xy + (_1399 * _1155_fa_shadow_bias.zw);\n            float4 param_6 = _1155_fa_shadow_rect[ci];\n            float _1410 = fa_shadow_depth(param_5, param_6);\n            if (_1410 < (_1327 - (length(_1399) * _1336)))\n            {\n                sum += _1410;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_1327 - (sum / cnt), 0.0f) * _1207) * _1155_fa_shadow_cfg.w) / _1155_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _1454 = _1366 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1454; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1454;\n        float param_9 = _1363;\n        float2 _1473 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _1255.xy + (_1473 * _1155_fa_shadow_bias.zw);\n        float4 param_11 = _1155_fa_shadow_rect[ci];\n        float _1484 = fa_shadow_depth(param_10, param_11);\n        lit += float((_1327 - (length(_1473) * _1336)) <= _1484);\n    }\n    return lit / float(_1454);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_415_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1514 = int(_1155_fa_shadow_cfg.x + 0.5f);\n    if (_1514 < 1)\n    {\n        return 1.0f;\n    }\n    float _1529 = dot(world - _1155_fa_shadow_eye.xyz, _1155_fa_shadow_fwd.xyz);\n    int param = _1514 - 1;\n    if (_1529 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1541 = _1514 > 1;\n    bool _1548;\n    if (_1541)\n    {\n        _1548 = _1529 > _1155_fa_shadow_split.x;\n    }\n    else\n    {\n        _1548 = _1541;\n    }\n    if (_1548)\n    {\n        ci = 1;\n    }\n    bool _1552 = _1514 > 2;\n    bool _1559;\n    if (_1552)\n    {\n        _1559 = _1529 > _1155_fa_shadow_split.y;\n    }\n    else\n    {\n        _1559 = _1552;\n    }\n    if (_1559)\n    {\n        ci = 2;\n    }\n    bool _1563 = _1514 > 3;\n    bool _1570;\n    if (_1563)\n    {\n        _1570 = _1529 > _1155_fa_shadow_split.z;\n    }\n    else\n    {\n        _1570 = _1563;\n    }\n    if (_1570)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1514)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1596 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1596;\n        if (_1596 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_1155_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1621;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1621 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1621 = _1155_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1640 = _1155_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1621, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1651 = clamp((_1529 - (fa_shadow_split_at(param_7) - _1640)) / _1640, 0.0f, 1.0f);\n        if (_1651 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1514)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1672 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1672;\n                if (_1672 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1651);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _2031 = fa_light_sample(param, param_1);\n    float3 _2809 = _2031.direction;\n    float3 _2804 = _2031.color;\n    float _2806 = _2031.shadow;\n    int _2814 = _2031.type;\n    if ((_2814 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2809;\n        float _2045 = fa_shadow_factor(param_2, param_3);\n        _2806 = _2045;\n        _2804 *= _2045;\n    }\n    LightSample _2821 = { _2809, _2804, _2031.attenuation, _2806, _2031._distance, _2814 };\n    return _2821;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_1155_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1696 = int(_1155_fa_shadow_cfg.x + 0.5f);\n    float _1706 = dot(world - _1155_fa_shadow_eye.xyz, _1155_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1711 = _1696 > 0;\n    bool _1720;\n    if (_1711)\n    {\n        int param = _1696 - 1;\n        _1720 = _1706 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1720 = _1711;\n    }\n    if (_1720)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1727 = _1696 > 1;\n        bool _1734;\n        if (_1727)\n        {\n            _1734 = _1706 > _1155_fa_shadow_split.x;\n        }\n        else\n        {\n            _1734 = _1727;\n        }\n        if (_1734)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1740 = _1696 > 2;\n        bool _1747;\n        if (_1740)\n        {\n            _1747 = _1706 > _1155_fa_shadow_split.y;\n        }\n        else\n        {\n            _1747 = _1740;\n        }\n        if (_1747)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1753 = _1696 > 3;\n        bool _1760;\n        if (_1753)\n        {\n            _1760 = _1706 > _1155_fa_shadow_split.z;\n        }\n        else\n        {\n            _1760 = _1753;\n        }\n        if (_1760)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _2687 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2687 = -_2687;\n    }\n    float3 _2332 = normalize(_415_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _2700 = { fa_world_pos, _2687, fa_world_tangent, fa_uv, fa_vertex_color, _2332, gl_FrontFacing };\n    SurfaceInput param_1 = _2700;\n    Surface _2340 = fa_standard_surface(param_1);\n    float3 _2726 = _2340.albedo;\n    float _2727 = _2340.alpha;\n    float3 _2728 = _2340.normal;\n    float _2729 = _2340.metallic;\n    float _2730 = _2340.roughness;\n    float _2731 = _2340.occlusion;\n    float3 _2732 = _2340.emission;\n    SurfaceInput _2708 = { fa_world_pos, _2687, fa_world_tangent, fa_uv, fa_vertex_color, _2332, gl_FrontFacing };\n    SurfaceInput param_2 = _2708;\n    Surface param_3 = _2340;\n    surface(param_2, param_3);\n    _2726 = param_3.albedo;\n    _2727 = param_3.alpha;\n    _2728 = param_3.normal;\n    _2729 = param_3.metallic;\n    _2730 = param_3.roughness;\n    _2731 = param_3.occlusion;\n    _2732 = param_3.emission;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _2687;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _2726 = param_6;\n    _2728 = param_7;\n    float3 result;\n    if (_415_fa_emissive.w > 0.5f)\n    {\n        result = _2726;\n    }\n    else\n    {\n        float3 _2378 = _2728;\n        float3 _2379 = normalize(_2378);\n        _2728 = _2379;\n        float3 param_8 = _2379;\n        SurfaceInput _2716 = { fa_world_pos, _2687, fa_world_tangent, fa_uv, fa_vertex_color, _2332, gl_FrontFacing };\n        SurfaceInput param_9 = _2716;\n        Surface _2762 = { _2726, _2727, _2728, _2729, _2730, _2731, _2732 };\n        Surface param_10 = _2762;\n        float3 param_11 = fa_ambient_light(param_8);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _2398 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2398; ln++)\n        {\n            int param_12 = ln;\n            int param_13 = fa_cl_light(param_12);\n            float3 param_14 = fa_world_pos;\n            float3 param_15 = _2687;\n            SurfaceInput _2724 = { fa_world_pos, _2687, fa_world_tangent, fa_uv, fa_vertex_color, _2332, gl_FrontFacing };\n            SurfaceInput param_16 = _2724;\n            Surface _2770 = { _2726, _2727, _2728, _2729, _2730, _2731, _2732 };\n            Surface param_17 = _2770;\n            LightSample param_18 = fa_light_shadowed(param_13, param_14, param_15);\n            lit += light(param_16, param_17, param_18);\n        }\n        result = lit;\n    }\n    float3 _2435 = result;\n    float3 _2436 = _2435 + _2732;\n    result = _2436;\n    float3 param_19 = _2436;\n    float3 param_20 = fa_world_pos;\n    result = fa_shadow_debug(param_19, param_20);\n    bool _2445 = _415_fa_fog.w > 0.0f;\n    bool _2453;\n    if (!_2445)\n    {\n        _2453 = _415_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2453 = _2445;\n    }\n    if (_2453)\n    {\n        float3 _2462 = fa_world_pos - _415_fa_camera_pos.xyz;\n        float _2469 = dot(_2462, _415_fa_fog_c.xyz);\n        bool _2473 = _415_fa_fog_c.w > 0.5f;\n        float _2474;\n        if (_2473)\n        {\n            _2474 = _2469;\n        }\n        else\n        {\n            _2474 = length(_2462);\n        }\n        float _2486 = _2474 - _415_fa_fog_b.x;\n        if (_2486 > 0.0f)\n        {\n            float _2495 = _415_fa_fog.w * _2486;\n            float tau = _2495 * _2495;\n            if (_415_fa_fog_b.y > 0.0f)\n            {\n                float _2511;\n                if (_2473)\n                {\n                    _2511 = fa_world_pos.y - (_415_fa_fog_c.y * _2469);\n                }\n                else\n                {\n                    _2511 = _415_fa_camera_pos.y;\n                }\n                float _2532 = lerp(_2511, fa_world_pos.y, clamp(_415_fa_fog_b.x / _2474, 0.0f, 1.0f));\n                float _2536 = fa_world_pos.y - _2532;\n                float _2541 = _2532 - _415_fa_fog_b.z;\n                float _2546 = fa_world_pos.y - _415_fa_fog_b.z;\n                bool _2549 = _2541 <= 0.0f;\n                bool _2550 = !_2549;\n                bool _2556;\n                if (_2550)\n                {\n                    _2556 = _415_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2556 = _2549;\n                }\n                float _2557;\n                if (_2556)\n                {\n                    _2557 = _415_fa_fog_b.y;\n                }\n                else\n                {\n                    _2557 = _415_fa_fog_b.y * exp(-min(_415_fa_fog_b.w * _2541, 80.0f));\n                }\n                bool _2584;\n                if (_2550)\n                {\n                    _2584 = _415_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2584 = _2549;\n                }\n                float _2585;\n                if (_2584)\n                {\n                    _2585 = _415_fa_fog_b.y * _2541;\n                }\n                else\n                {\n                    _2585 = (_415_fa_fog_b.y * (1.0f - exp(-min(_415_fa_fog_b.w * _2541, 80.0f)))) / _415_fa_fog_b.w;\n                }\n                bool _2610 = _2546 <= 0.0f;\n                bool _2617;\n                if (!_2610)\n                {\n                    _2617 = _415_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2617 = _2610;\n                }\n                float _2618;\n                if (_2617)\n                {\n                    _2618 = _415_fa_fog_b.y * _2546;\n                }\n                else\n                {\n                    _2618 = (_415_fa_fog_b.y * (1.0f - exp(-min(_415_fa_fog_b.w * _2546, 80.0f)))) / _415_fa_fog_b.w;\n                }\n                float _2645;\n                if (abs(_2536) < 0.001000000047497451305389404296875f)\n                {\n                    _2645 = _2557;\n                }\n                else\n                {\n                    _2645 = (_2618 - _2585) / _2536;\n                }\n                tau += (_2486 * max(_2645, 0.0f));\n            }\n            result = lerp(result, _415_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _2727);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_415",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_1155",
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
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float",
              "hlsl_register_t_n": 7
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
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
