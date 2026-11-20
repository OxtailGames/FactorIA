{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "41c86c92dbb0093951c81b6ee249cbb5aa749f4b053c4954c67a5e43bd66f6f3",
  "slang": "hlsl5",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _261 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _261;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _268 = _160.world_pos;\n    fa_world_pos = _268;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_268, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstatic const LightSample _3013 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, 0 };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _419_fa_camera_pos : packoffset(c0);\n    float4 _419_fa_ambient : packoffset(c1);\n    float4 _419_fa_base_color : packoffset(c2);\n    float4 _419_fa_emissive : packoffset(c3);\n    float4 _419_fa_model_emissive : packoffset(c4);\n    float4 _419_fa_pbr : packoffset(c5);\n    float4 _419_fa_maps : packoffset(c6);\n    float4 _419_fa_fog : packoffset(c7);\n    float4 _419_fa_fog_b : packoffset(c8);\n    float4 _419_fa_fog_c : packoffset(c9);\n    float4 _419_fa_counts : packoffset(c10);\n    float4 _419_fa_env_sky : packoffset(c11);\n    float4 _419_fa_env_horizon : packoffset(c12);\n    float4 _419_fa_time : packoffset(c13);\n    float4 _419_fa_cl_vpx : packoffset(c14);\n    float4 _419_fa_cl_vpy : packoffset(c15);\n    float4 _419_fa_cl_vpw : packoffset(c16);\n    float4 _419_fa_cl_fwd : packoffset(c17);\n    float4 _419_fa_cl_grid : packoffset(c18);\n    float4 _419_fa_cl_info : packoffset(c19);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _1159_fa_shadow_mat[4] : packoffset(c0);\n    float4 _1159_fa_shadow_rect[4] : packoffset(c16);\n    float4 _1159_fa_shadow_info[4] : packoffset(c20);\n    float4 _1159_fa_shadow_split : packoffset(c24);\n    float4 _1159_fa_shadow_cfg : packoffset(c25);\n    float4 _1159_fa_shadow_bias : packoffset(c26);\n    float4 _1159_fa_shadow_eye : packoffset(c27);\n    float4 _1159_fa_shadow_fwd : packoffset(c28);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _2175_dark : packoffset(c0);\n    float _2175_fa_pad0 : packoffset(c0.y);\n    float _2175_fa_pad1 : packoffset(c0.z);\n    float _2175_fa_pad2 : packoffset(c0.w);\n    float _2175_skyAmount : packoffset(c1);\n    float _2175_fa_pad3 : packoffset(c1.y);\n    float _2175_fa_pad4 : packoffset(c1.z);\n    float _2175_fa_pad5 : packoffset(c1.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_decal_tex : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _424 = _419_fa_cl_info.x < 0.0f;\n    bool _431;\n    if (!_424)\n    {\n        _431 = _419_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _431 = _424;\n    }\n    bool _439;\n    if (!_431)\n    {\n        _439 = _419_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _439 = _431;\n    }\n    bool _446;\n    if (!_439)\n    {\n        _446 = _419_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _446 = _439;\n    }\n    bool _453;\n    if (!_446)\n    {\n        _453 = _419_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _453 = _446;\n    }\n    if (_453)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _463 = float4(world_pos, 1.0f);\n    float _470 = dot(_419_fa_cl_vpw, _463);\n    if (!(_470 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _492 = float2(dot(_419_fa_cl_vpx, _463), dot(_419_fa_cl_vpy, _463)) / _470.xx;\n    int _496 = int(_419_fa_cl_grid.x);\n    int _500 = int(_419_fa_cl_grid.y);\n    int param = (int(_419_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_419_fa_cl_fwd.xyz, world_pos) + _419_fa_cl_fwd.w, _419_fa_cl_grid.w) / _419_fa_cl_grid.w) * _419_fa_cl_grid.z)), 0, int(_419_fa_cl_info.y) - 1) * _500) + clamp(int(floor(((_492.y * 0.5f) + 0.5f) * _419_fa_cl_grid.y)), 0, _500 - 1)) * _496)) + clamp(int(floor(((_492.x * 0.5f) + 0.5f) * _419_fa_cl_grid.x)), 0, _496 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _576 = fa_cluster_texel(param);\n    return int2(int(_576.x), int(_576.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_419_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2000 = fa_cluster_lookup(param);\n    fa_cl_slot = _2000.x;\n    fa_cl_local = _2000.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _2236 = fa_linear_to_srgb(param);\n        c = _2236;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _2244 = fa_srgb_to_linear(param_1);\n            c = _2244;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _199;\n    if (i.front_facing)\n    {\n        _199 = i.world_normal;\n    }\n    else\n    {\n        _199 = -i.world_normal;\n    }\n    float3 _223 = normalize(i.world_tangent.xyz - (_199 * dot(_199, i.world_tangent.xyz)));\n    float3 _251 = normalize(((_223 * m.x) + ((cross(_199, _223) * i.world_tangent.w) * m.y)) + (_199 * m.z));\n    float3 _254;\n    if (i.front_facing)\n    {\n        _254 = _251;\n    }\n    else\n    {\n        _254 = -_251;\n    }\n    return _254;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _419_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2275 = fa_tex_fix(param_2, param_3);\n    float4 _2982 = base_t;\n    _2982.x = _2275.x;\n    _2982.y = _2275.y;\n    _2982.z = _2275.z;\n    base_t = _2982;\n    float4 _2289 = (_2982 * _419_fa_base_color) * i.vertex_color;\n    float3 _2906 = i.world_normal;\n    if (_419_fa_maps.z > 0.5f)\n    {\n        float param_4 = _419_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2321 = fa_tex_fix(param_6, param_7);\n        float3 _2324 = (_2321 * 2.0f) - 1.0f.xxx;\n        float2 _2329 = _2324.xy * _419_fa_maps.x;\n        float3 _2990 = _2324;\n        _2990.x = _2329.x;\n        _2990.y = _2329.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2990;\n        _2906 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _419_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2358 = fa_tex_fix(param_12, param_13);\n    float4 _2993 = mrt;\n    _2993.x = _2358.x;\n    _2993.y = _2358.y;\n    _2993.z = _2358.z;\n    mrt = _2993;\n    float param_14 = _419_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2397 = fa_tex_fix(param_16, param_17);\n    float param_18 = _419_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2424 = fa_tex_fix(param_20, param_21);\n    Surface _2918 = { _2289.xyz, _2289.w, _2906, clamp(_419_fa_pbr.x * _2358.z, 0.0f, 1.0f), clamp(_419_fa_pbr.y * _2358.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_419_fa_maps.y * (_2397.x - 1.0f)), _419_fa_emissive.xyz + (_419_fa_model_emissive.xyz * _2424) };\n    return _2918;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _657 = rect.zw - rect.xy;\n    float2 _661 = _657 * atlas;\n    float2 _665 = ddx * _661;\n    float2 _669 = ddy * _661;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _657), clamp(0.5f * log2(max(max(dot(_665, _665), dot(_669, _669)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    float3 _704 = ddx(world_pos);\n    float3 _707 = ddy(world_pos);\n    bool _710 = _419_fa_counts.y < 0.5f;\n    bool _717;\n    if (!_710)\n    {\n        _717 = _419_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _717 = _710;\n    }\n    if (_717)\n    {\n        return;\n    }\n    float3 param = world_pos;\n    float4 _724 = fa_cluster_texel(param);\n    int _728 = int(_724.w);\n    if (_728 < 1)\n    {\n        return;\n    }\n    int _738 = int(_419_fa_counts.y + 0.5f);\n    int param_1 = _738;\n    float4 _742 = fa_light_texel(param_1);\n    float2 _745 = _742.yz;\n    int _749 = int(_742.w);\n    int param_2 = _738 + 1;\n    float4 _754 = fa_light_texel(param_2);\n    float _755 = _754.x;\n    int _761 = int(_419_fa_counts.w + 0.5f) - 1;\n    int _765 = int(_724.z);\n    float3 _1031;\n    for (int k = 0; k < _728; k++)\n    {\n        int _778 = _765 + k;\n        int param_3 = _749 + (_778 >> 2);\n        int _796 = (_738 + 2) + (int(fa_light_texel(param_3)[_778 & 3]) * 7);\n        int param_4 = _796 + 6;\n        float4 _801 = fa_light_texel(param_4);\n        if (((int(_801.w + 0.5f) >> _761) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _796;\n        float4 _816 = fa_light_texel(param_5);\n        int param_6 = _796 + 1;\n        float4 _821 = fa_light_texel(param_6);\n        int param_7 = _796 + 2;\n        float4 _826 = fa_light_texel(param_7);\n        float3 _829 = _816.xyz;\n        float _834 = dot(_829, world_pos) + _816.w;\n        float3 _836 = _821.xyz;\n        float _841 = dot(_836, world_pos) + _821.w;\n        float3 _843 = _826.xyz;\n        float _848 = dot(_843, world_pos) + _826.w;\n        bool _853 = abs(_834) > 0.5f;\n        bool _861;\n        if (!_853)\n        {\n            _861 = abs(_841) > 0.5f;\n        }\n        else\n        {\n            _861 = _853;\n        }\n        bool _869;\n        if (!_861)\n        {\n            _869 = abs(_848) > 0.5f;\n        }\n        else\n        {\n            _869 = _861;\n        }\n        if (_869)\n        {\n            continue;\n        }\n        float _884 = clamp(dot(geo_normal, normalize(_843)) * _801.z, 0.0f, 1.0f);\n        if (_884 <= 0.0f)\n        {\n            continue;\n        }\n        float _904 = (clamp((0.5f - abs(_848)) * 10.0f, 0.0f, 1.0f) * _884) * _801.x;\n        float2 _912 = float2(_834 + 0.5f, 0.5f - _841);\n        float2 _922 = float2(dot(_829, _704), dot(_836, _704));\n        float2 _932 = float2(dot(_829, _707), dot(_836, _707));\n        int param_8 = _796 + 5;\n        float4 _937 = fa_light_texel(param_8);\n        int param_9 = _796 + 3;\n        float4 _942 = fa_light_texel(param_9);\n        int param_10 = _796 + 4;\n        float4 _947 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _937.xyz;\n        bool _957 = _942.z > _942.x;\n        if (_957)\n        {\n            float4 param_11 = _942;\n            float2 param_12 = _912;\n            float2 param_13 = _745;\n            float2 param_14 = _922;\n            float2 param_15 = _932;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_755 > 0.5f) && (_755 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _983 = fa_dc_to_linear(param_16);\n                float4 _2944 = tx;\n                _2944.x = _983.x;\n                _2944.y = _983.y;\n                _2944.z = _983.z;\n                tx = _2944;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_904 * tex_a) * _937.w, 0.0f, 1.0f).xxx);\n        if (_947.z > _947.x)\n        {\n            float4 param_17 = _947;\n            float2 param_18 = _912;\n            float2 param_19 = _745;\n            float2 param_20 = _922;\n            float2 param_21 = _932;\n            float4 _1027 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_755 > 1.5f)\n            {\n                float3 param_22 = _1027.xyz;\n                float3 _1037 = fa_dc_to_srgb(param_22);\n                _1031 = _1037;\n            }\n            else\n            {\n                _1031 = _1027.xyz;\n            }\n            float3 _1047 = (_1031 * 2.0f) - 1.0f.xxx;\n            float2 _1052 = _1047.xy * _801.y;\n            float3 _1074 = (normalize(_829) * _1052.x) + (normalize(_836) * _1052.y);\n            float3 _1077 = normalize(normal);\n            normal = normalize(lerp(_1077, normalize((_1077 * max(_1047.z, 0.0500000007450580596923828125f)) + (_1074 - (_1077 * dot(_1077, _1074)))), clamp(_904 * (_957 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return _3013;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_419_fa_cl_info.x) + int(_419_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _291 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _297 = fa_light_texel(param_1);\n    float _300 = _297.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _307 = _300 < 0.5f;\n    float3 l;\n    if (_307)\n    {\n        l = normalize(_291.xyz);\n    }\n    else\n    {\n        float3 _319 = _291.xyz - world_pos;\n        float _321 = length(_319);\n        dist = _321;\n        l = _319 / max(_321, 9.9999997473787516355514526367188e-05f).xxx;\n        float _336 = _321 / max(_291.w, 0.001000000047497451305389404296875f);\n        float _342 = clamp(1.0f - (_336 * _336), 0.0f, 1.0f);\n        atten = _342 * _342;\n        if (_300 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _356 = fa_light_texel(param_2);\n            float _366 = _356.w;\n            int param_3 = (li * 4) + 3;\n            float4 _373 = fa_light_texel(param_3);\n            float _374 = _373.x;\n            float cos_inner = _374;\n            if (_374 > 1.5f)\n            {\n                cos_inner = lerp(_366, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_366, cos_inner, dot(-l, normalize(_356.xyz)));\n        }\n    }\n    int _405;\n    if (_307)\n    {\n        _405 = 0;\n    }\n    else\n    {\n        _405 = (_300 > 1.5f) ? 2 : 1;\n    }\n    LightSample _2862 = { l, _297.xyz * atten, atten, 1.0f, dist, _405 };\n    return _2862;\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _2085 = n < 0;\n    bool _2092;\n    if (!_2085)\n    {\n        _2092 = n >= fa_light_count();\n    }\n    else\n    {\n        _2092 = _2085;\n    }\n    if (_2092)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    return fa_light_sample(param_1, param_2);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1149;\n    if (i == 0)\n    {\n        _1149 = _1159_fa_shadow_split.x;\n    }\n    else\n    {\n        float _1165;\n        if (i == 1)\n        {\n            _1165 = _1159_fa_shadow_split.y;\n        }\n        else\n        {\n            float _1173;\n            if (i == 2)\n            {\n                _1173 = _1159_fa_shadow_split.z;\n            }\n            else\n            {\n                _1173 = _1159_fa_shadow_split.w;\n            }\n            _1165 = _1173;\n        }\n        _1149 = _1165;\n    }\n    return _1149;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1137 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_1137), sin(_1137)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _1211 = max(_1159_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _1216 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1222 = sqrt(1.0f - (_1216 * _1216));\n    float _1229 = min(_1222 / max(_1216, 0.20000000298023223876953125f), 4.0f);\n    float _1234;\n    if (_1159_fa_shadow_bias.y > 0.0f)\n    {\n        _1234 = _1159_fa_shadow_bias.y;\n    }\n    else\n    {\n        _1234 = 1.5f * _1159_fa_shadow_info[ci].x;\n    }\n    float4 _1259 = mul(float4(world + (n * (_1234 * _1222)), 1.0f), _1159_fa_shadow_mat[ci]);\n    float _1266 = _1259.x;\n    bool _1269 = _1266 < _1159_fa_shadow_rect[ci].x;\n    bool _1278;\n    if (!_1269)\n    {\n        _1278 = _1266 > _1159_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1278 = _1269;\n    }\n    bool _1287;\n    if (!_1278)\n    {\n        _1287 = _1259.y < _1159_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1287 = _1278;\n    }\n    bool _1296;\n    if (!_1287)\n    {\n        _1296 = _1259.y > _1159_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1296 = _1287;\n    }\n    bool _1303;\n    if (!_1296)\n    {\n        _1303 = _1259.z > 1.0f;\n    }\n    else\n    {\n        _1303 = _1296;\n    }\n    if (_1303)\n    {\n        return -1.0f;\n    }\n    float _1312;\n    if (_1159_fa_shadow_bias.x > 0.0f)\n    {\n        _1312 = _1159_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1312 = 1.5f * _1159_fa_shadow_info[ci].x;\n    }\n    float _1331 = _1259.z - ((_1312 * (1.0f + (0.5f * _1229))) / _1211);\n    float _1340 = ((_1159_fa_shadow_info[ci].x * min(_1229, 3.0f)) * 0.5f) / _1211;\n    int _1349 = int(_1159_fa_shadow_cfg.z + 0.5f);\n    if (_1349 == 1)\n    {\n        float2 param = _1259.xy;\n        float4 param_1 = _1159_fa_shadow_rect[ci];\n        float _1360 = fa_shadow_depth(param, param_1);\n        return float(_1331 <= _1360);\n    }\n    float _1367 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _1370 = _1349 == 2;\n    if (_1370)\n    {\n        float _1384 = clamp(((_1159_fa_shadow_cfg.w * _1211) * 0.25f) / _1159_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1367;\n            float2 _1403 = fa_shadow_vogel(param_2, param_3, param_4) * _1384;\n            float2 param_5 = _1259.xy + (_1403 * _1159_fa_shadow_bias.zw);\n            float4 param_6 = _1159_fa_shadow_rect[ci];\n            float _1414 = fa_shadow_depth(param_5, param_6);\n            if (_1414 < (_1331 - (length(_1403) * _1340)))\n            {\n                sum += _1414;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_1331 - (sum / cnt), 0.0f) * _1211) * _1159_fa_shadow_cfg.w) / _1159_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _1458 = _1370 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1458; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1458;\n        float param_9 = _1367;\n        float2 _1477 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _1259.xy + (_1477 * _1159_fa_shadow_bias.zw);\n        float4 param_11 = _1159_fa_shadow_rect[ci];\n        float _1488 = fa_shadow_depth(param_10, param_11);\n        lit += float((_1331 - (length(_1477) * _1340)) <= _1488);\n    }\n    return lit / float(_1458);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_419_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1518 = int(_1159_fa_shadow_cfg.x + 0.5f);\n    if (_1518 < 1)\n    {\n        return 1.0f;\n    }\n    float _1533 = dot(world - _1159_fa_shadow_eye.xyz, _1159_fa_shadow_fwd.xyz);\n    int param = _1518 - 1;\n    if (_1533 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1545 = _1518 > 1;\n    bool _1552;\n    if (_1545)\n    {\n        _1552 = _1533 > _1159_fa_shadow_split.x;\n    }\n    else\n    {\n        _1552 = _1545;\n    }\n    if (_1552)\n    {\n        ci = 1;\n    }\n    bool _1556 = _1518 > 2;\n    bool _1563;\n    if (_1556)\n    {\n        _1563 = _1533 > _1159_fa_shadow_split.y;\n    }\n    else\n    {\n        _1563 = _1556;\n    }\n    if (_1563)\n    {\n        ci = 2;\n    }\n    bool _1567 = _1518 > 3;\n    bool _1574;\n    if (_1567)\n    {\n        _1574 = _1533 > _1159_fa_shadow_split.z;\n    }\n    else\n    {\n        _1574 = _1567;\n    }\n    if (_1574)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1518)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1600 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1600;\n        if (_1600 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_1159_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1625;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1625 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1625 = _1159_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1644 = _1159_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1625, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1655 = clamp((_1533 - (fa_shadow_split_at(param_7) - _1644)) / _1644, 0.0f, 1.0f);\n        if (_1655 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1518)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1676 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1676;\n                if (_1676 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1655);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _2028 = fa_light_sample(param, param_1);\n    float3 _2882 = _2028.direction;\n    float3 _2877 = _2028.color;\n    float _2879 = _2028.shadow;\n    int _2887 = _2028.type;\n    if ((_2887 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2882;\n        float _2042 = fa_shadow_factor(param_2, param_3);\n        _2879 = _2042;\n        _2877 *= _2042;\n    }\n    LightSample _2894 = { _2882, _2877, _2028.attenuation, _2879, _2028._distance, _2887 };\n    return _2894;\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _2059 = n < 0;\n    bool _2066;\n    if (!_2059)\n    {\n        _2066 = n >= fa_light_count();\n    }\n    else\n    {\n        _2066 = _2059;\n    }\n    if (_2066)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    return fa_light_shadowed(param_1, param_2, param_3);\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _1888 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _1891 = _1888.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_1891 * _1891, exp2((-9.27999973297119140625f) * ndv)) * _1891) + _1888.y)) + _1888.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_419_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _419_fa_env_horizon.w).xyz;\n    }\n    float _1812 = rough * rough;\n    float _1842 = 0.60000002384185791015625f * _1812;\n    return lerp(lerp(_419_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_419_fa_env_horizon.xyz, _419_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _1812)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _1842, 0.0500000007450580596923828125f + _1842, d.y).xxx), ((_419_fa_env_sky.xyz + _419_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_1812 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1930 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1930.x) + _1930.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float3 param = normalize(s.normal);\n    float3 param_1 = i.view_dir;\n    float3 param_2 = lerp(0.039999999105930328369140625f.xxx, s.albedo, clamp(s.metallic, 0.0f, 1.0f).xxx);\n    float param_3 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    return fa_sky_reflection(param, param_1, param_2, param_3) * s.occlusion;\n}\n\nfloat3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0f;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _2132 = dot(fa_light_unshadowed(param, param_1).color, float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));\n        if (_2132 > bestPower)\n        {\n            bestPower = _2132;\n            best = n;\n        }\n    }\n    float3 lit = (_419_fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _2161 = fa_light(param_2, param_3);\n        float _2169;\n        if (dot(s.normal, _2161.direction) > 0.5f)\n        {\n            _2169 = 1.0f;\n        }\n        else\n        {\n            _2169 = _2175_dark;\n        }\n        lit += ((s.albedo * _2161.color) * _2169);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * _2175_skyAmount);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_1159_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1700 = int(_1159_fa_shadow_cfg.x + 0.5f);\n    float _1710 = dot(world - _1159_fa_shadow_eye.xyz, _1159_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1715 = _1700 > 0;\n    bool _1724;\n    if (_1715)\n    {\n        int param = _1700 - 1;\n        _1724 = _1710 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1724 = _1715;\n    }\n    if (_1724)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1731 = _1700 > 1;\n        bool _1738;\n        if (_1731)\n        {\n            _1738 = _1710 > _1159_fa_shadow_split.x;\n        }\n        else\n        {\n            _1738 = _1731;\n        }\n        if (_1738)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1744 = _1700 > 2;\n        bool _1751;\n        if (_1744)\n        {\n            _1751 = _1710 > _1159_fa_shadow_split.y;\n        }\n        else\n        {\n            _1751 = _1744;\n        }\n        if (_1751)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1757 = _1700 > 3;\n        bool _1764;\n        if (_1757)\n        {\n            _1764 = _1710 > _1159_fa_shadow_split.z;\n        }\n        else\n        {\n            _1764 = _1757;\n        }\n        if (_1764)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _2782 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2782 = -_2782;\n    }\n    float3 _2467 = normalize(_419_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _2795 = { fa_world_pos, _2782, fa_world_tangent, fa_uv, fa_vertex_color, _2467, gl_FrontFacing };\n    SurfaceInput param_1 = _2795;\n    Surface _2475 = fa_standard_surface(param_1);\n    float3 _2813 = _2475.albedo;\n    float _2814 = _2475.alpha;\n    float3 _2815 = _2475.normal;\n    float _2816 = _2475.metallic;\n    float _2817 = _2475.roughness;\n    float _2818 = _2475.occlusion;\n    float3 _2819 = _2475.emission;\n    SurfaceInput _2803 = { fa_world_pos, _2782, fa_world_tangent, fa_uv, fa_vertex_color, _2467, gl_FrontFacing };\n    SurfaceInput param_2 = _2803;\n    Surface param_3 = _2475;\n    surface(param_2, param_3);\n    _2813 = param_3.albedo;\n    _2814 = param_3.alpha;\n    _2815 = param_3.normal;\n    _2816 = param_3.metallic;\n    _2817 = param_3.roughness;\n    _2818 = param_3.occlusion;\n    _2819 = param_3.emission;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _2782;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _2813 = param_6;\n    _2815 = param_7;\n    float3 result;\n    if (_419_fa_emissive.w > 0.5f)\n    {\n        result = _2813;\n    }\n    else\n    {\n        float3 _2513 = _2815;\n        float3 _2514 = normalize(_2513);\n        _2815 = _2514;\n        SurfaceInput _2811 = { fa_world_pos, _2782, fa_world_tangent, fa_uv, fa_vertex_color, _2467, gl_FrontFacing };\n        SurfaceInput param_8 = _2811;\n        Surface _2849 = { _2813, _2814, _2514, _2816, _2817, _2818, _2819 };\n        Surface param_9 = _2849;\n        result = lighting(param_8, param_9);\n    }\n    float3 _2529 = result;\n    float3 _2530 = _2529 + _2819;\n    result = _2530;\n    float3 param_10 = _2530;\n    float3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _2539 = _419_fa_fog.w > 0.0f;\n    bool _2547;\n    if (!_2539)\n    {\n        _2547 = _419_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2547 = _2539;\n    }\n    if (_2547)\n    {\n        float3 _2556 = fa_world_pos - _419_fa_camera_pos.xyz;\n        float _2563 = dot(_2556, _419_fa_fog_c.xyz);\n        bool _2567 = _419_fa_fog_c.w > 0.5f;\n        float _2568;\n        if (_2567)\n        {\n            _2568 = _2563;\n        }\n        else\n        {\n            _2568 = length(_2556);\n        }\n        float _2580 = _2568 - _419_fa_fog_b.x;\n        if (_2580 > 0.0f)\n        {\n            float _2589 = _419_fa_fog.w * _2580;\n            float tau = _2589 * _2589;\n            if (_419_fa_fog_b.y > 0.0f)\n            {\n                float _2605;\n                if (_2567)\n                {\n                    _2605 = fa_world_pos.y - (_419_fa_fog_c.y * _2563);\n                }\n                else\n                {\n                    _2605 = _419_fa_camera_pos.y;\n                }\n                float _2626 = lerp(_2605, fa_world_pos.y, clamp(_419_fa_fog_b.x / _2568, 0.0f, 1.0f));\n                float _2630 = fa_world_pos.y - _2626;\n                float _2635 = _2626 - _419_fa_fog_b.z;\n                float _2640 = fa_world_pos.y - _419_fa_fog_b.z;\n                bool _2643 = _2635 <= 0.0f;\n                bool _2644 = !_2643;\n                bool _2650;\n                if (_2644)\n                {\n                    _2650 = _419_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2650 = _2643;\n                }\n                float _2651;\n                if (_2650)\n                {\n                    _2651 = _419_fa_fog_b.y;\n                }\n                else\n                {\n                    _2651 = _419_fa_fog_b.y * exp(-min(_419_fa_fog_b.w * _2635, 80.0f));\n                }\n                bool _2678;\n                if (_2644)\n                {\n                    _2678 = _419_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2678 = _2643;\n                }\n                float _2679;\n                if (_2678)\n                {\n                    _2679 = _419_fa_fog_b.y * _2635;\n                }\n                else\n                {\n                    _2679 = (_419_fa_fog_b.y * (1.0f - exp(-min(_419_fa_fog_b.w * _2635, 80.0f)))) / _419_fa_fog_b.w;\n                }\n                bool _2704 = _2640 <= 0.0f;\n                bool _2711;\n                if (!_2704)\n                {\n                    _2711 = _419_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2711 = _2704;\n                }\n                float _2712;\n                if (_2711)\n                {\n                    _2712 = _419_fa_fog_b.y * _2640;\n                }\n                else\n                {\n                    _2712 = (_419_fa_fog_b.y * (1.0f - exp(-min(_419_fa_fog_b.w * _2640, 80.0f)))) / _419_fa_fog_b.w;\n                }\n                float _2739;\n                if (abs(_2630) < 0.001000000047497451305389404296875f)\n                {\n                    _2739 = _2651;\n                }\n                else\n                {\n                    _2739 = (_2712 - _2679) / _2630;\n                }\n                tau += (_2580 * max(_2739, 0.0f));\n            }\n            result = lerp(result, _419_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _2814);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_419",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_1159",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_2175",
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 8,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _382 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _382;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _389 = _273.world_pos;\n    fa_world_pos = _389;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_389, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstatic const LightSample _3013 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, 0 };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _419_fa_camera_pos : packoffset(c0);\n    float4 _419_fa_ambient : packoffset(c1);\n    float4 _419_fa_base_color : packoffset(c2);\n    float4 _419_fa_emissive : packoffset(c3);\n    float4 _419_fa_model_emissive : packoffset(c4);\n    float4 _419_fa_pbr : packoffset(c5);\n    float4 _419_fa_maps : packoffset(c6);\n    float4 _419_fa_fog : packoffset(c7);\n    float4 _419_fa_fog_b : packoffset(c8);\n    float4 _419_fa_fog_c : packoffset(c9);\n    float4 _419_fa_counts : packoffset(c10);\n    float4 _419_fa_env_sky : packoffset(c11);\n    float4 _419_fa_env_horizon : packoffset(c12);\n    float4 _419_fa_time : packoffset(c13);\n    float4 _419_fa_cl_vpx : packoffset(c14);\n    float4 _419_fa_cl_vpy : packoffset(c15);\n    float4 _419_fa_cl_vpw : packoffset(c16);\n    float4 _419_fa_cl_fwd : packoffset(c17);\n    float4 _419_fa_cl_grid : packoffset(c18);\n    float4 _419_fa_cl_info : packoffset(c19);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _1159_fa_shadow_mat[4] : packoffset(c0);\n    float4 _1159_fa_shadow_rect[4] : packoffset(c16);\n    float4 _1159_fa_shadow_info[4] : packoffset(c20);\n    float4 _1159_fa_shadow_split : packoffset(c24);\n    float4 _1159_fa_shadow_cfg : packoffset(c25);\n    float4 _1159_fa_shadow_bias : packoffset(c26);\n    float4 _1159_fa_shadow_eye : packoffset(c27);\n    float4 _1159_fa_shadow_fwd : packoffset(c28);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _2175_dark : packoffset(c0);\n    float _2175_fa_pad0 : packoffset(c0.y);\n    float _2175_fa_pad1 : packoffset(c0.z);\n    float _2175_fa_pad2 : packoffset(c0.w);\n    float _2175_skyAmount : packoffset(c1);\n    float _2175_fa_pad3 : packoffset(c1.y);\n    float _2175_fa_pad4 : packoffset(c1.z);\n    float _2175_fa_pad5 : packoffset(c1.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_decal_tex : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _424 = _419_fa_cl_info.x < 0.0f;\n    bool _431;\n    if (!_424)\n    {\n        _431 = _419_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _431 = _424;\n    }\n    bool _439;\n    if (!_431)\n    {\n        _439 = _419_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _439 = _431;\n    }\n    bool _446;\n    if (!_439)\n    {\n        _446 = _419_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _446 = _439;\n    }\n    bool _453;\n    if (!_446)\n    {\n        _453 = _419_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _453 = _446;\n    }\n    if (_453)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _463 = float4(world_pos, 1.0f);\n    float _470 = dot(_419_fa_cl_vpw, _463);\n    if (!(_470 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _492 = float2(dot(_419_fa_cl_vpx, _463), dot(_419_fa_cl_vpy, _463)) / _470.xx;\n    int _496 = int(_419_fa_cl_grid.x);\n    int _500 = int(_419_fa_cl_grid.y);\n    int param = (int(_419_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_419_fa_cl_fwd.xyz, world_pos) + _419_fa_cl_fwd.w, _419_fa_cl_grid.w) / _419_fa_cl_grid.w) * _419_fa_cl_grid.z)), 0, int(_419_fa_cl_info.y) - 1) * _500) + clamp(int(floor(((_492.y * 0.5f) + 0.5f) * _419_fa_cl_grid.y)), 0, _500 - 1)) * _496)) + clamp(int(floor(((_492.x * 0.5f) + 0.5f) * _419_fa_cl_grid.x)), 0, _496 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _576 = fa_cluster_texel(param);\n    return int2(int(_576.x), int(_576.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_419_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2000 = fa_cluster_lookup(param);\n    fa_cl_slot = _2000.x;\n    fa_cl_local = _2000.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _2236 = fa_linear_to_srgb(param);\n        c = _2236;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _2244 = fa_srgb_to_linear(param_1);\n            c = _2244;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _199;\n    if (i.front_facing)\n    {\n        _199 = i.world_normal;\n    }\n    else\n    {\n        _199 = -i.world_normal;\n    }\n    float3 _223 = normalize(i.world_tangent.xyz - (_199 * dot(_199, i.world_tangent.xyz)));\n    float3 _251 = normalize(((_223 * m.x) + ((cross(_199, _223) * i.world_tangent.w) * m.y)) + (_199 * m.z));\n    float3 _254;\n    if (i.front_facing)\n    {\n        _254 = _251;\n    }\n    else\n    {\n        _254 = -_251;\n    }\n    return _254;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _419_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2275 = fa_tex_fix(param_2, param_3);\n    float4 _2982 = base_t;\n    _2982.x = _2275.x;\n    _2982.y = _2275.y;\n    _2982.z = _2275.z;\n    base_t = _2982;\n    float4 _2289 = (_2982 * _419_fa_base_color) * i.vertex_color;\n    float3 _2906 = i.world_normal;\n    if (_419_fa_maps.z > 0.5f)\n    {\n        float param_4 = _419_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2321 = fa_tex_fix(param_6, param_7);\n        float3 _2324 = (_2321 * 2.0f) - 1.0f.xxx;\n        float2 _2329 = _2324.xy * _419_fa_maps.x;\n        float3 _2990 = _2324;\n        _2990.x = _2329.x;\n        _2990.y = _2329.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2990;\n        _2906 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _419_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2358 = fa_tex_fix(param_12, param_13);\n    float4 _2993 = mrt;\n    _2993.x = _2358.x;\n    _2993.y = _2358.y;\n    _2993.z = _2358.z;\n    mrt = _2993;\n    float param_14 = _419_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2397 = fa_tex_fix(param_16, param_17);\n    float param_18 = _419_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2424 = fa_tex_fix(param_20, param_21);\n    Surface _2918 = { _2289.xyz, _2289.w, _2906, clamp(_419_fa_pbr.x * _2358.z, 0.0f, 1.0f), clamp(_419_fa_pbr.y * _2358.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_419_fa_maps.y * (_2397.x - 1.0f)), _419_fa_emissive.xyz + (_419_fa_model_emissive.xyz * _2424) };\n    return _2918;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _657 = rect.zw - rect.xy;\n    float2 _661 = _657 * atlas;\n    float2 _665 = ddx * _661;\n    float2 _669 = ddy * _661;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _657), clamp(0.5f * log2(max(max(dot(_665, _665), dot(_669, _669)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    float3 _704 = ddx(world_pos);\n    float3 _707 = ddy(world_pos);\n    bool _710 = _419_fa_counts.y < 0.5f;\n    bool _717;\n    if (!_710)\n    {\n        _717 = _419_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _717 = _710;\n    }\n    if (_717)\n    {\n        return;\n    }\n    float3 param = world_pos;\n    float4 _724 = fa_cluster_texel(param);\n    int _728 = int(_724.w);\n    if (_728 < 1)\n    {\n        return;\n    }\n    int _738 = int(_419_fa_counts.y + 0.5f);\n    int param_1 = _738;\n    float4 _742 = fa_light_texel(param_1);\n    float2 _745 = _742.yz;\n    int _749 = int(_742.w);\n    int param_2 = _738 + 1;\n    float4 _754 = fa_light_texel(param_2);\n    float _755 = _754.x;\n    int _761 = int(_419_fa_counts.w + 0.5f) - 1;\n    int _765 = int(_724.z);\n    float3 _1031;\n    for (int k = 0; k < _728; k++)\n    {\n        int _778 = _765 + k;\n        int param_3 = _749 + (_778 >> 2);\n        int _796 = (_738 + 2) + (int(fa_light_texel(param_3)[_778 & 3]) * 7);\n        int param_4 = _796 + 6;\n        float4 _801 = fa_light_texel(param_4);\n        if (((int(_801.w + 0.5f) >> _761) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _796;\n        float4 _816 = fa_light_texel(param_5);\n        int param_6 = _796 + 1;\n        float4 _821 = fa_light_texel(param_6);\n        int param_7 = _796 + 2;\n        float4 _826 = fa_light_texel(param_7);\n        float3 _829 = _816.xyz;\n        float _834 = dot(_829, world_pos) + _816.w;\n        float3 _836 = _821.xyz;\n        float _841 = dot(_836, world_pos) + _821.w;\n        float3 _843 = _826.xyz;\n        float _848 = dot(_843, world_pos) + _826.w;\n        bool _853 = abs(_834) > 0.5f;\n        bool _861;\n        if (!_853)\n        {\n            _861 = abs(_841) > 0.5f;\n        }\n        else\n        {\n            _861 = _853;\n        }\n        bool _869;\n        if (!_861)\n        {\n            _869 = abs(_848) > 0.5f;\n        }\n        else\n        {\n            _869 = _861;\n        }\n        if (_869)\n        {\n            continue;\n        }\n        float _884 = clamp(dot(geo_normal, normalize(_843)) * _801.z, 0.0f, 1.0f);\n        if (_884 <= 0.0f)\n        {\n            continue;\n        }\n        float _904 = (clamp((0.5f - abs(_848)) * 10.0f, 0.0f, 1.0f) * _884) * _801.x;\n        float2 _912 = float2(_834 + 0.5f, 0.5f - _841);\n        float2 _922 = float2(dot(_829, _704), dot(_836, _704));\n        float2 _932 = float2(dot(_829, _707), dot(_836, _707));\n        int param_8 = _796 + 5;\n        float4 _937 = fa_light_texel(param_8);\n        int param_9 = _796 + 3;\n        float4 _942 = fa_light_texel(param_9);\n        int param_10 = _796 + 4;\n        float4 _947 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _937.xyz;\n        bool _957 = _942.z > _942.x;\n        if (_957)\n        {\n            float4 param_11 = _942;\n            float2 param_12 = _912;\n            float2 param_13 = _745;\n            float2 param_14 = _922;\n            float2 param_15 = _932;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_755 > 0.5f) && (_755 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _983 = fa_dc_to_linear(param_16);\n                float4 _2944 = tx;\n                _2944.x = _983.x;\n                _2944.y = _983.y;\n                _2944.z = _983.z;\n                tx = _2944;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_904 * tex_a) * _937.w, 0.0f, 1.0f).xxx);\n        if (_947.z > _947.x)\n        {\n            float4 param_17 = _947;\n            float2 param_18 = _912;\n            float2 param_19 = _745;\n            float2 param_20 = _922;\n            float2 param_21 = _932;\n            float4 _1027 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_755 > 1.5f)\n            {\n                float3 param_22 = _1027.xyz;\n                float3 _1037 = fa_dc_to_srgb(param_22);\n                _1031 = _1037;\n            }\n            else\n            {\n                _1031 = _1027.xyz;\n            }\n            float3 _1047 = (_1031 * 2.0f) - 1.0f.xxx;\n            float2 _1052 = _1047.xy * _801.y;\n            float3 _1074 = (normalize(_829) * _1052.x) + (normalize(_836) * _1052.y);\n            float3 _1077 = normalize(normal);\n            normal = normalize(lerp(_1077, normalize((_1077 * max(_1047.z, 0.0500000007450580596923828125f)) + (_1074 - (_1077 * dot(_1077, _1074)))), clamp(_904 * (_957 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return _3013;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_419_fa_cl_info.x) + int(_419_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _291 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _297 = fa_light_texel(param_1);\n    float _300 = _297.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _307 = _300 < 0.5f;\n    float3 l;\n    if (_307)\n    {\n        l = normalize(_291.xyz);\n    }\n    else\n    {\n        float3 _319 = _291.xyz - world_pos;\n        float _321 = length(_319);\n        dist = _321;\n        l = _319 / max(_321, 9.9999997473787516355514526367188e-05f).xxx;\n        float _336 = _321 / max(_291.w, 0.001000000047497451305389404296875f);\n        float _342 = clamp(1.0f - (_336 * _336), 0.0f, 1.0f);\n        atten = _342 * _342;\n        if (_300 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _356 = fa_light_texel(param_2);\n            float _366 = _356.w;\n            int param_3 = (li * 4) + 3;\n            float4 _373 = fa_light_texel(param_3);\n            float _374 = _373.x;\n            float cos_inner = _374;\n            if (_374 > 1.5f)\n            {\n                cos_inner = lerp(_366, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_366, cos_inner, dot(-l, normalize(_356.xyz)));\n        }\n    }\n    int _405;\n    if (_307)\n    {\n        _405 = 0;\n    }\n    else\n    {\n        _405 = (_300 > 1.5f) ? 2 : 1;\n    }\n    LightSample _2862 = { l, _297.xyz * atten, atten, 1.0f, dist, _405 };\n    return _2862;\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _2085 = n < 0;\n    bool _2092;\n    if (!_2085)\n    {\n        _2092 = n >= fa_light_count();\n    }\n    else\n    {\n        _2092 = _2085;\n    }\n    if (_2092)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    return fa_light_sample(param_1, param_2);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1149;\n    if (i == 0)\n    {\n        _1149 = _1159_fa_shadow_split.x;\n    }\n    else\n    {\n        float _1165;\n        if (i == 1)\n        {\n            _1165 = _1159_fa_shadow_split.y;\n        }\n        else\n        {\n            float _1173;\n            if (i == 2)\n            {\n                _1173 = _1159_fa_shadow_split.z;\n            }\n            else\n            {\n                _1173 = _1159_fa_shadow_split.w;\n            }\n            _1165 = _1173;\n        }\n        _1149 = _1165;\n    }\n    return _1149;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1137 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_1137), sin(_1137)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _1211 = max(_1159_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _1216 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1222 = sqrt(1.0f - (_1216 * _1216));\n    float _1229 = min(_1222 / max(_1216, 0.20000000298023223876953125f), 4.0f);\n    float _1234;\n    if (_1159_fa_shadow_bias.y > 0.0f)\n    {\n        _1234 = _1159_fa_shadow_bias.y;\n    }\n    else\n    {\n        _1234 = 1.5f * _1159_fa_shadow_info[ci].x;\n    }\n    float4 _1259 = mul(float4(world + (n * (_1234 * _1222)), 1.0f), _1159_fa_shadow_mat[ci]);\n    float _1266 = _1259.x;\n    bool _1269 = _1266 < _1159_fa_shadow_rect[ci].x;\n    bool _1278;\n    if (!_1269)\n    {\n        _1278 = _1266 > _1159_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1278 = _1269;\n    }\n    bool _1287;\n    if (!_1278)\n    {\n        _1287 = _1259.y < _1159_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1287 = _1278;\n    }\n    bool _1296;\n    if (!_1287)\n    {\n        _1296 = _1259.y > _1159_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1296 = _1287;\n    }\n    bool _1303;\n    if (!_1296)\n    {\n        _1303 = _1259.z > 1.0f;\n    }\n    else\n    {\n        _1303 = _1296;\n    }\n    if (_1303)\n    {\n        return -1.0f;\n    }\n    float _1312;\n    if (_1159_fa_shadow_bias.x > 0.0f)\n    {\n        _1312 = _1159_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1312 = 1.5f * _1159_fa_shadow_info[ci].x;\n    }\n    float _1331 = _1259.z - ((_1312 * (1.0f + (0.5f * _1229))) / _1211);\n    float _1340 = ((_1159_fa_shadow_info[ci].x * min(_1229, 3.0f)) * 0.5f) / _1211;\n    int _1349 = int(_1159_fa_shadow_cfg.z + 0.5f);\n    if (_1349 == 1)\n    {\n        float2 param = _1259.xy;\n        float4 param_1 = _1159_fa_shadow_rect[ci];\n        float _1360 = fa_shadow_depth(param, param_1);\n        return float(_1331 <= _1360);\n    }\n    float _1367 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _1370 = _1349 == 2;\n    if (_1370)\n    {\n        float _1384 = clamp(((_1159_fa_shadow_cfg.w * _1211) * 0.25f) / _1159_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1367;\n            float2 _1403 = fa_shadow_vogel(param_2, param_3, param_4) * _1384;\n            float2 param_5 = _1259.xy + (_1403 * _1159_fa_shadow_bias.zw);\n            float4 param_6 = _1159_fa_shadow_rect[ci];\n            float _1414 = fa_shadow_depth(param_5, param_6);\n            if (_1414 < (_1331 - (length(_1403) * _1340)))\n            {\n                sum += _1414;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_1331 - (sum / cnt), 0.0f) * _1211) * _1159_fa_shadow_cfg.w) / _1159_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _1458 = _1370 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1458; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1458;\n        float param_9 = _1367;\n        float2 _1477 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _1259.xy + (_1477 * _1159_fa_shadow_bias.zw);\n        float4 param_11 = _1159_fa_shadow_rect[ci];\n        float _1488 = fa_shadow_depth(param_10, param_11);\n        lit += float((_1331 - (length(_1477) * _1340)) <= _1488);\n    }\n    return lit / float(_1458);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_419_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1518 = int(_1159_fa_shadow_cfg.x + 0.5f);\n    if (_1518 < 1)\n    {\n        return 1.0f;\n    }\n    float _1533 = dot(world - _1159_fa_shadow_eye.xyz, _1159_fa_shadow_fwd.xyz);\n    int param = _1518 - 1;\n    if (_1533 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1545 = _1518 > 1;\n    bool _1552;\n    if (_1545)\n    {\n        _1552 = _1533 > _1159_fa_shadow_split.x;\n    }\n    else\n    {\n        _1552 = _1545;\n    }\n    if (_1552)\n    {\n        ci = 1;\n    }\n    bool _1556 = _1518 > 2;\n    bool _1563;\n    if (_1556)\n    {\n        _1563 = _1533 > _1159_fa_shadow_split.y;\n    }\n    else\n    {\n        _1563 = _1556;\n    }\n    if (_1563)\n    {\n        ci = 2;\n    }\n    bool _1567 = _1518 > 3;\n    bool _1574;\n    if (_1567)\n    {\n        _1574 = _1533 > _1159_fa_shadow_split.z;\n    }\n    else\n    {\n        _1574 = _1567;\n    }\n    if (_1574)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1518)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1600 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1600;\n        if (_1600 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_1159_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1625;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1625 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1625 = _1159_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1644 = _1159_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1625, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1655 = clamp((_1533 - (fa_shadow_split_at(param_7) - _1644)) / _1644, 0.0f, 1.0f);\n        if (_1655 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1518)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1676 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1676;\n                if (_1676 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1655);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _2028 = fa_light_sample(param, param_1);\n    float3 _2882 = _2028.direction;\n    float3 _2877 = _2028.color;\n    float _2879 = _2028.shadow;\n    int _2887 = _2028.type;\n    if ((_2887 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2882;\n        float _2042 = fa_shadow_factor(param_2, param_3);\n        _2879 = _2042;\n        _2877 *= _2042;\n    }\n    LightSample _2894 = { _2882, _2877, _2028.attenuation, _2879, _2028._distance, _2887 };\n    return _2894;\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _2059 = n < 0;\n    bool _2066;\n    if (!_2059)\n    {\n        _2066 = n >= fa_light_count();\n    }\n    else\n    {\n        _2066 = _2059;\n    }\n    if (_2066)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    return fa_light_shadowed(param_1, param_2, param_3);\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _1888 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _1891 = _1888.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_1891 * _1891, exp2((-9.27999973297119140625f) * ndv)) * _1891) + _1888.y)) + _1888.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_419_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _419_fa_env_horizon.w).xyz;\n    }\n    float _1812 = rough * rough;\n    float _1842 = 0.60000002384185791015625f * _1812;\n    return lerp(lerp(_419_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_419_fa_env_horizon.xyz, _419_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _1812)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _1842, 0.0500000007450580596923828125f + _1842, d.y).xxx), ((_419_fa_env_sky.xyz + _419_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_1812 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1930 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1930.x) + _1930.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float3 param = normalize(s.normal);\n    float3 param_1 = i.view_dir;\n    float3 param_2 = lerp(0.039999999105930328369140625f.xxx, s.albedo, clamp(s.metallic, 0.0f, 1.0f).xxx);\n    float param_3 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    return fa_sky_reflection(param, param_1, param_2, param_3) * s.occlusion;\n}\n\nfloat3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0f;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _2132 = dot(fa_light_unshadowed(param, param_1).color, float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));\n        if (_2132 > bestPower)\n        {\n            bestPower = _2132;\n            best = n;\n        }\n    }\n    float3 lit = (_419_fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _2161 = fa_light(param_2, param_3);\n        float _2169;\n        if (dot(s.normal, _2161.direction) > 0.5f)\n        {\n            _2169 = 1.0f;\n        }\n        else\n        {\n            _2169 = _2175_dark;\n        }\n        lit += ((s.albedo * _2161.color) * _2169);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * _2175_skyAmount);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_1159_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1700 = int(_1159_fa_shadow_cfg.x + 0.5f);\n    float _1710 = dot(world - _1159_fa_shadow_eye.xyz, _1159_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1715 = _1700 > 0;\n    bool _1724;\n    if (_1715)\n    {\n        int param = _1700 - 1;\n        _1724 = _1710 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1724 = _1715;\n    }\n    if (_1724)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1731 = _1700 > 1;\n        bool _1738;\n        if (_1731)\n        {\n            _1738 = _1710 > _1159_fa_shadow_split.x;\n        }\n        else\n        {\n            _1738 = _1731;\n        }\n        if (_1738)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1744 = _1700 > 2;\n        bool _1751;\n        if (_1744)\n        {\n            _1751 = _1710 > _1159_fa_shadow_split.y;\n        }\n        else\n        {\n            _1751 = _1744;\n        }\n        if (_1751)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1757 = _1700 > 3;\n        bool _1764;\n        if (_1757)\n        {\n            _1764 = _1710 > _1159_fa_shadow_split.z;\n        }\n        else\n        {\n            _1764 = _1757;\n        }\n        if (_1764)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _2782 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2782 = -_2782;\n    }\n    float3 _2467 = normalize(_419_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _2795 = { fa_world_pos, _2782, fa_world_tangent, fa_uv, fa_vertex_color, _2467, gl_FrontFacing };\n    SurfaceInput param_1 = _2795;\n    Surface _2475 = fa_standard_surface(param_1);\n    float3 _2813 = _2475.albedo;\n    float _2814 = _2475.alpha;\n    float3 _2815 = _2475.normal;\n    float _2816 = _2475.metallic;\n    float _2817 = _2475.roughness;\n    float _2818 = _2475.occlusion;\n    float3 _2819 = _2475.emission;\n    SurfaceInput _2803 = { fa_world_pos, _2782, fa_world_tangent, fa_uv, fa_vertex_color, _2467, gl_FrontFacing };\n    SurfaceInput param_2 = _2803;\n    Surface param_3 = _2475;\n    surface(param_2, param_3);\n    _2813 = param_3.albedo;\n    _2814 = param_3.alpha;\n    _2815 = param_3.normal;\n    _2816 = param_3.metallic;\n    _2817 = param_3.roughness;\n    _2818 = param_3.occlusion;\n    _2819 = param_3.emission;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _2782;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _2813 = param_6;\n    _2815 = param_7;\n    float3 result;\n    if (_419_fa_emissive.w > 0.5f)\n    {\n        result = _2813;\n    }\n    else\n    {\n        float3 _2513 = _2815;\n        float3 _2514 = normalize(_2513);\n        _2815 = _2514;\n        SurfaceInput _2811 = { fa_world_pos, _2782, fa_world_tangent, fa_uv, fa_vertex_color, _2467, gl_FrontFacing };\n        SurfaceInput param_8 = _2811;\n        Surface _2849 = { _2813, _2814, _2514, _2816, _2817, _2818, _2819 };\n        Surface param_9 = _2849;\n        result = lighting(param_8, param_9);\n    }\n    float3 _2529 = result;\n    float3 _2530 = _2529 + _2819;\n    result = _2530;\n    float3 param_10 = _2530;\n    float3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _2539 = _419_fa_fog.w > 0.0f;\n    bool _2547;\n    if (!_2539)\n    {\n        _2547 = _419_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2547 = _2539;\n    }\n    if (_2547)\n    {\n        float3 _2556 = fa_world_pos - _419_fa_camera_pos.xyz;\n        float _2563 = dot(_2556, _419_fa_fog_c.xyz);\n        bool _2567 = _419_fa_fog_c.w > 0.5f;\n        float _2568;\n        if (_2567)\n        {\n            _2568 = _2563;\n        }\n        else\n        {\n            _2568 = length(_2556);\n        }\n        float _2580 = _2568 - _419_fa_fog_b.x;\n        if (_2580 > 0.0f)\n        {\n            float _2589 = _419_fa_fog.w * _2580;\n            float tau = _2589 * _2589;\n            if (_419_fa_fog_b.y > 0.0f)\n            {\n                float _2605;\n                if (_2567)\n                {\n                    _2605 = fa_world_pos.y - (_419_fa_fog_c.y * _2563);\n                }\n                else\n                {\n                    _2605 = _419_fa_camera_pos.y;\n                }\n                float _2626 = lerp(_2605, fa_world_pos.y, clamp(_419_fa_fog_b.x / _2568, 0.0f, 1.0f));\n                float _2630 = fa_world_pos.y - _2626;\n                float _2635 = _2626 - _419_fa_fog_b.z;\n                float _2640 = fa_world_pos.y - _419_fa_fog_b.z;\n                bool _2643 = _2635 <= 0.0f;\n                bool _2644 = !_2643;\n                bool _2650;\n                if (_2644)\n                {\n                    _2650 = _419_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2650 = _2643;\n                }\n                float _2651;\n                if (_2650)\n                {\n                    _2651 = _419_fa_fog_b.y;\n                }\n                else\n                {\n                    _2651 = _419_fa_fog_b.y * exp(-min(_419_fa_fog_b.w * _2635, 80.0f));\n                }\n                bool _2678;\n                if (_2644)\n                {\n                    _2678 = _419_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2678 = _2643;\n                }\n                float _2679;\n                if (_2678)\n                {\n                    _2679 = _419_fa_fog_b.y * _2635;\n                }\n                else\n                {\n                    _2679 = (_419_fa_fog_b.y * (1.0f - exp(-min(_419_fa_fog_b.w * _2635, 80.0f)))) / _419_fa_fog_b.w;\n                }\n                bool _2704 = _2640 <= 0.0f;\n                bool _2711;\n                if (!_2704)\n                {\n                    _2711 = _419_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2711 = _2704;\n                }\n                float _2712;\n                if (_2711)\n                {\n                    _2712 = _419_fa_fog_b.y * _2640;\n                }\n                else\n                {\n                    _2712 = (_419_fa_fog_b.y * (1.0f - exp(-min(_419_fa_fog_b.w * _2640, 80.0f)))) / _419_fa_fog_b.w;\n                }\n                float _2739;\n                if (abs(_2630) < 0.001000000047497451305389404296875f)\n                {\n                    _2739 = _2651;\n                }\n                else\n                {\n                    _2739 = (_2712 - _2679) / _2630;\n                }\n                tau += (_2580 * max(_2739, 0.0f));\n            }\n            result = lerp(result, _419_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _2814);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_419",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_1159",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_2175",
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 8,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _295 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _295;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _302 = _160.world_pos;\n    float4 _171 = float4(_302, 1.0f);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -mul(_171, _131_fa_light_vp).z;\n    fa_pre_r0 = float3(_131_fa_light_vp[0].x, _131_fa_light_vp[1].x, _131_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131_fa_light_vp[0].y, _131_fa_light_vp[1].y, _131_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131_fa_light_vp[0].z, _131_fa_light_vp[1].z, _131_fa_light_vp[2].z);\n    gl_Position = mul(_171, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _591 = base_t;\n    _591.x = _225.x;\n    _591.y = _225.y;\n    _591.z = _225.z;\n    base_t = _591;\n    float4 _241 = (_591 * _213_fa_base_color) * i.vertex_color;\n    float3 _572 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _599 = _279;\n        _599.x = _284.x;\n        _599.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _599;\n        _572 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _602 = mrt;\n    _602.x = _313.x;\n    _602.y = _313.y;\n    _602.z = _313.z;\n    mrt = _602;\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _354 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _381 = fa_tex_fix(param_20, param_21);\n    Surface _584 = { _241.xyz, _241.w, _572, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_354.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _381) };\n    return _584;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _519 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _519 = -_519;\n    }\n    float3 _427 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _532 = { fa_world_pos, _519, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing };\n    SurfaceInput param = _532;\n    SurfaceInput _540 = { fa_world_pos, _519, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing };\n    SurfaceInput param_1 = _540;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _442 = normalize(param_2.normal);\n    float3 _457 = normalize(float3(dot(fa_pre_r0, _442), dot(fa_pre_r1, _442), dot(fa_pre_r2, _442)));\n    float _469 = _457.z;\n    float2 e = _457.xy / ((abs(_457.x) + abs(_457.y)) + abs(_469)).xx;\n    if (_469 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _416 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _416;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _423 = _273.world_pos;\n    float4 _284 = float4(_423, 1.0f);\n    fa_world_pos = _423;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -mul(_284, _136_fa_light_vp).z;\n    fa_pre_r0 = float3(_136_fa_light_vp[0].x, _136_fa_light_vp[1].x, _136_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136_fa_light_vp[0].y, _136_fa_light_vp[1].y, _136_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136_fa_light_vp[0].z, _136_fa_light_vp[1].z, _136_fa_light_vp[2].z);\n    gl_Position = mul(_284, _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _591 = base_t;\n    _591.x = _225.x;\n    _591.y = _225.y;\n    _591.z = _225.z;\n    base_t = _591;\n    float4 _241 = (_591 * _213_fa_base_color) * i.vertex_color;\n    float3 _572 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _599 = _279;\n        _599.x = _284.x;\n        _599.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _599;\n        _572 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _602 = mrt;\n    _602.x = _313.x;\n    _602.y = _313.y;\n    _602.z = _313.z;\n    mrt = _602;\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _354 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _381 = fa_tex_fix(param_20, param_21);\n    Surface _584 = { _241.xyz, _241.w, _572, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_354.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _381) };\n    return _584;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _519 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _519 = -_519;\n    }\n    float3 _427 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _532 = { fa_world_pos, _519, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing };\n    SurfaceInput param = _532;\n    SurfaceInput _540 = { fa_world_pos, _519, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing };\n    SurfaceInput param_1 = _540;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _442 = normalize(param_2.normal);\n    float3 _457 = normalize(float3(dot(fa_pre_r0, _442), dot(fa_pre_r1, _442), dot(fa_pre_r2, _442)));\n    float _469 = _457.z;\n    float2 e = _457.xy / ((abs(_457.x) + abs(_457.y)) + abs(_469)).xx;\n    if (_469 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
