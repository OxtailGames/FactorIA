{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "bccfdbb53ee48b05b8dde63187158cf27ea0b93537445c8a05fdc4dbc713dc01",
  "slang": "hlsl5",
  "params": [
    "dark"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _263 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _263;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_270, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _440_fa_camera_pos : packoffset(c0);\n    float4 _440_fa_ambient : packoffset(c1);\n    float4 _440_fa_base_color : packoffset(c2);\n    float4 _440_fa_emissive : packoffset(c3);\n    float4 _440_fa_model_emissive : packoffset(c4);\n    float4 _440_fa_pbr : packoffset(c5);\n    float4 _440_fa_maps : packoffset(c6);\n    float4 _440_fa_fog : packoffset(c7);\n    float4 _440_fa_fog_b : packoffset(c8);\n    float4 _440_fa_fog_c : packoffset(c9);\n    float4 _440_fa_counts : packoffset(c10);\n    float4 _440_fa_env_sky : packoffset(c11);\n    float4 _440_fa_env_horizon : packoffset(c12);\n    float4 _440_fa_time : packoffset(c13);\n    float4 _440_fa_cl_vpx : packoffset(c14);\n    float4 _440_fa_cl_vpy : packoffset(c15);\n    float4 _440_fa_cl_vpw : packoffset(c16);\n    float4 _440_fa_cl_fwd : packoffset(c17);\n    float4 _440_fa_cl_grid : packoffset(c18);\n    float4 _440_fa_cl_info : packoffset(c19);\n    float4 _440_fa_layers_a : packoffset(c20);\n    float4 _440_fa_layers_b : packoffset(c21);\n    float4 _440_fa_layers_c : packoffset(c22);\n    float4 _440_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _1180_fa_shadow_mat[4] : packoffset(c0);\n    float4 _1180_fa_shadow_rect[4] : packoffset(c16);\n    float4 _1180_fa_shadow_info[4] : packoffset(c20);\n    float4 _1180_fa_shadow_split : packoffset(c24);\n    float4 _1180_fa_shadow_cfg : packoffset(c25);\n    float4 _1180_fa_shadow_bias : packoffset(c26);\n    float4 _1180_fa_shadow_eye : packoffset(c27);\n    float4 _1180_fa_shadow_fwd : packoffset(c28);\n    float4 _1180_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _2379_dark : packoffset(c0);\n    float _2379_fa_pad0 : packoffset(c0.y);\n    float _2379_fa_pad1 : packoffset(c0.z);\n    float _2379_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_decal_tex : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_irr_tex : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t8);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _445 = _440_fa_cl_info.x < 0.0f;\n    bool _452;\n    if (!_445)\n    {\n        _452 = _440_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _452 = _445;\n    }\n    bool _460;\n    if (!_452)\n    {\n        _460 = _440_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _460 = _452;\n    }\n    bool _467;\n    if (!_460)\n    {\n        _467 = _440_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _467 = _460;\n    }\n    bool _474;\n    if (!_467)\n    {\n        _474 = _440_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _474 = _467;\n    }\n    if (_474)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _484 = float4(world_pos, 1.0f);\n    float _491 = dot(_440_fa_cl_vpw, _484);\n    if (!(_491 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _513 = float2(dot(_440_fa_cl_vpx, _484), dot(_440_fa_cl_vpy, _484)) / _491.xx;\n    int _517 = int(_440_fa_cl_grid.x);\n    int _521 = int(_440_fa_cl_grid.y);\n    int param = (int(_440_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_440_fa_cl_fwd.xyz, world_pos) + _440_fa_cl_fwd.w, _440_fa_cl_grid.w) / _440_fa_cl_grid.w) * _440_fa_cl_grid.z)), 0, int(_440_fa_cl_info.y) - 1) * _521) + clamp(int(floor(((_513.y * 0.5f) + 0.5f) * _440_fa_cl_grid.y)), 0, _521 - 1)) * _517)) + clamp(int(floor(((_513.x * 0.5f) + 0.5f) * _440_fa_cl_grid.x)), 0, _517 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _597 = fa_cluster_texel(param);\n    return int2(int(_597.x), int(_597.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_440_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2254 = fa_cluster_lookup(param);\n    fa_cl_slot = _2254.x;\n    fa_cl_local = _2254.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _2428 = fa_linear_to_srgb(param);\n        c = _2428;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _2436 = fa_srgb_to_linear(param_1);\n            c = _2436;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _204;\n    if (i.front_facing)\n    {\n        _204 = i.world_normal;\n    }\n    else\n    {\n        _204 = -i.world_normal;\n    }\n    float3 _228 = normalize(i.world_tangent.xyz - (_204 * dot(_204, i.world_tangent.xyz)));\n    float3 _256 = normalize(((_228 * m.x) + ((cross(_204, _228) * i.world_tangent.w) * m.y)) + (_204 * m.z));\n    float3 _259;\n    if (i.front_facing)\n    {\n        _259 = _256;\n    }\n    else\n    {\n        _259 = -_256;\n    }\n    return _259;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _440_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2467 = fa_tex_fix(param_2, param_3);\n    float4 _3479 = base_t;\n    _3479.x = _2467.x;\n    _3479.y = _2467.y;\n    _3479.z = _2467.z;\n    base_t = _3479;\n    float4 _2481 = (_3479 * _440_fa_base_color) * i.vertex_color;\n    float3 _3359 = i.world_normal;\n    if (_440_fa_maps.z > 0.5f)\n    {\n        float param_4 = _440_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2513 = fa_tex_fix(param_6, param_7);\n        float3 _2516 = (_2513 * 2.0f) - 1.0f.xxx;\n        float2 _2521 = _2516.xy * _440_fa_maps.x;\n        float3 _3487 = _2516;\n        _3487.x = _2521.x;\n        _3487.y = _2521.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3487;\n        _3359 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _440_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2550 = fa_tex_fix(param_12, param_13);\n    float4 _3490 = mrt;\n    _3490.x = _2550.x;\n    _3490.y = _2550.y;\n    _3490.z = _2550.z;\n    mrt = _3490;\n    float4 _2578 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _440_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _2578.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2590 = fa_tex_fix(param_16, param_17);\n    float param_18 = _440_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2620 = fa_tex_fix(param_20, param_21);\n    float _3364 = _440_fa_layers_a.x;\n    float _3365 = _440_fa_layers_a.y;\n    float _3368 = _440_fa_layers_a.z;\n    float _3367 = _440_fa_layers_b.w;\n    float _3370 = _440_fa_layers_c.x;\n    if (_440_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_440_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _3364 *= _2590.y;\n            _3365 *= _2590.z;\n            _3367 *= _2578.w;\n        }\n        if (_440_fa_layers_c.z > 1.5f)\n        {\n            _3368 *= mrt.x;\n            _3370 *= mrt.w;\n        }\n    }\n    Surface _3389 = { _2481.xyz, _2481.w, _3359, clamp(_440_fa_pbr.x * _2550.z, 0.0f, 1.0f), clamp(_440_fa_pbr.y * _2550.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_440_fa_maps.y * (_2590.x - 1.0f)), _440_fa_emissive.xyz + (_440_fa_model_emissive.xyz * _2620), _3364, _3365, _440_fa_layers_b.xyz, _3367, _3368, _440_fa_layers_a.w, _3370, _440_fa_layers_c.y, _440_fa_layers_d.xyz };\n    return _3389;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _678 = rect.zw - rect.xy;\n    float2 _682 = _678 * atlas;\n    float2 _686 = ddx * _682;\n    float2 _690 = ddy * _682;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _678), clamp(0.5f * log2(max(max(dot(_686, _686), dot(_690, _690)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _725 = _440_fa_counts.y < 0.5f;\n    bool _732;\n    if (!_725)\n    {\n        _732 = _440_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _732 = _725;\n    }\n    if (_732)\n    {\n        return;\n    }\n    float3 _738 = ddx(world_pos);\n    float3 _741 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _745 = fa_cluster_texel(param);\n    int _749 = int(_745.w);\n    if (_749 < 1)\n    {\n        return;\n    }\n    int _759 = int(_440_fa_counts.y + 0.5f);\n    int param_1 = _759;\n    float4 _763 = fa_light_texel(param_1);\n    float2 _766 = _763.yz;\n    int _770 = int(_763.w);\n    int param_2 = _759 + 1;\n    float4 _775 = fa_light_texel(param_2);\n    float _776 = _775.x;\n    int _782 = int(_440_fa_counts.w + 0.5f) - 1;\n    int _786 = int(_745.z);\n    float3 _1052;\n    for (int k = 0; k < _749; k++)\n    {\n        int _799 = _786 + k;\n        int param_3 = _770 + (_799 >> 2);\n        int _817 = (_759 + 2) + (int(fa_light_texel(param_3)[_799 & 3]) * 7);\n        int param_4 = _817 + 6;\n        float4 _822 = fa_light_texel(param_4);\n        if (((int(_822.w + 0.5f) >> _782) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _817;\n        float4 _837 = fa_light_texel(param_5);\n        int param_6 = _817 + 1;\n        float4 _842 = fa_light_texel(param_6);\n        int param_7 = _817 + 2;\n        float4 _847 = fa_light_texel(param_7);\n        float3 _850 = _837.xyz;\n        float _855 = dot(_850, world_pos) + _837.w;\n        float3 _857 = _842.xyz;\n        float _862 = dot(_857, world_pos) + _842.w;\n        float3 _864 = _847.xyz;\n        float _869 = dot(_864, world_pos) + _847.w;\n        bool _874 = abs(_855) > 0.5f;\n        bool _882;\n        if (!_874)\n        {\n            _882 = abs(_862) > 0.5f;\n        }\n        else\n        {\n            _882 = _874;\n        }\n        bool _890;\n        if (!_882)\n        {\n            _890 = abs(_869) > 0.5f;\n        }\n        else\n        {\n            _890 = _882;\n        }\n        if (_890)\n        {\n            continue;\n        }\n        float _905 = clamp(dot(geo_normal, normalize(_864)) * _822.z, 0.0f, 1.0f);\n        if (_905 <= 0.0f)\n        {\n            continue;\n        }\n        float _925 = (clamp((0.5f - abs(_869)) * 10.0f, 0.0f, 1.0f) * _905) * _822.x;\n        float2 _933 = float2(_855 + 0.5f, 0.5f - _862);\n        float2 _943 = float2(dot(_850, _738), dot(_857, _738));\n        float2 _953 = float2(dot(_850, _741), dot(_857, _741));\n        int param_8 = _817 + 5;\n        float4 _958 = fa_light_texel(param_8);\n        int param_9 = _817 + 3;\n        float4 _963 = fa_light_texel(param_9);\n        int param_10 = _817 + 4;\n        float4 _968 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _958.xyz;\n        bool _978 = _963.z > _963.x;\n        if (_978)\n        {\n            float4 param_11 = _963;\n            float2 param_12 = _933;\n            float2 param_13 = _766;\n            float2 param_14 = _943;\n            float2 param_15 = _953;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_776 > 0.5f) && (_776 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1004 = fa_dc_to_linear(param_16);\n                float4 _3415 = tx;\n                _3415.x = _1004.x;\n                _3415.y = _1004.y;\n                _3415.z = _1004.z;\n                tx = _3415;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_925 * tex_a) * _958.w, 0.0f, 1.0f).xxx);\n        if (_968.z > _968.x)\n        {\n            float4 param_17 = _968;\n            float2 param_18 = _933;\n            float2 param_19 = _766;\n            float2 param_20 = _943;\n            float2 param_21 = _953;\n            float4 _1048 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_776 > 1.5f)\n            {\n                float3 param_22 = _1048.xyz;\n                float3 _1058 = fa_dc_to_srgb(param_22);\n                _1052 = _1058;\n            }\n            else\n            {\n                _1052 = _1048.xyz;\n            }\n            float3 _1068 = (_1052 * 2.0f) - 1.0f.xxx;\n            float2 _1073 = _1068.xy * _822.y;\n            float3 _1095 = (normalize(_850) * _1073.x) + (normalize(_857) * _1073.y);\n            float3 _1098 = normalize(normal);\n            normal = normalize(lerp(_1098, normalize((_1098 * max(_1068.z, 0.0500000007450580596923828125f)) + (_1095 - (_1098 * dot(_1098, _1095)))), clamp(_925 * (_978 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_440_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _440_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_440_fa_cl_info.x) + int(_440_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _315 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _321 = fa_light_texel(param_1);\n    float _324 = _321.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _330 = _324 < 0.5f;\n    float3 l;\n    if (_330)\n    {\n        l = normalize(_315.xyz);\n    }\n    else\n    {\n        float3 _342 = _315.xyz - world_pos;\n        float _344 = length(_342);\n        dist = _344;\n        l = _342 / max(_344, 9.9999997473787516355514526367188e-05f).xxx;\n        float _359 = _344 / max(_315.w, 0.001000000047497451305389404296875f);\n        float _365 = clamp(1.0f - (_359 * _359), 0.0f, 1.0f);\n        atten = _365 * _365;\n        if (_324 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _379 = fa_light_texel(param_2);\n            float _389 = _379.w;\n            int param_3 = (li * 4) + 3;\n            float4 _395 = fa_light_texel(param_3);\n            float _396 = _395.x;\n            float cos_inner = _396;\n            if (_396 > 1.5f)\n            {\n                cos_inner = lerp(_389, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_389, cos_inner, dot(-l, normalize(_379.xyz)));\n        }\n    }\n    int _426;\n    if (_330)\n    {\n        _426 = 0;\n    }\n    else\n    {\n        _426 = (_324 > 1.5f) ? 2 : 1;\n    }\n    LightSample _3324 = { l, _321.xyz * atten, atten, 1.0f, dist, _426 };\n    return _3324;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1170;\n    if (i == 0)\n    {\n        _1170 = _1180_fa_shadow_split.x;\n    }\n    else\n    {\n        float _1186;\n        if (i == 1)\n        {\n            _1186 = _1180_fa_shadow_split.y;\n        }\n        else\n        {\n            float _1194;\n            if (i == 2)\n            {\n                _1194 = _1180_fa_shadow_split.z;\n            }\n            else\n            {\n                _1194 = _1180_fa_shadow_split.w;\n            }\n            _1186 = _1194;\n        }\n        _1170 = _1186;\n    }\n    return _1170;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1227 = fa_shadow_depth(param, param_1);\n    float _1231;\n    if (conv.x < 0.5f)\n    {\n        _1231 = _1227;\n    }\n    else\n    {\n        _1231 = (conv.y * conv.z) / (conv.z - (_1227 * (conv.z - conv.y)));\n    }\n    return _1231;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1158 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_1158), sin(_1158)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1277 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _1291 = clamp((k * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1277;\n            float2 _1310 = fa_shadow_vogel(param_3, param_4, param_5) * _1291;\n            float2 param_6 = uv + (_1310 * _1180_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1322 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1322 < (zr - (length(_1310) * plane)))\n            {\n                sum += _1322;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0f) * unit) * k) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _1366 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1366; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1366;\n        float param_11 = _1277;\n        float2 _1385 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1385 * _1180_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1385) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1366);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _1427 = max(_1180_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _1432 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1438 = sqrt(1.0f - (_1432 * _1432));\n    float _1445 = min(_1438 / max(_1432, 0.20000000298023223876953125f), 4.0f);\n    float _1450;\n    if (_1180_fa_shadow_bias.y > 0.0f)\n    {\n        _1450 = _1180_fa_shadow_bias.y;\n    }\n    else\n    {\n        _1450 = 1.5f * _1180_fa_shadow_info[ci].x;\n    }\n    float4 _1475 = mul(float4(world + (n * (_1450 * _1438)), 1.0f), _1180_fa_shadow_mat[ci]);\n    float _1482 = _1475.x;\n    bool _1485 = _1482 < _1180_fa_shadow_rect[ci].x;\n    bool _1494;\n    if (!_1485)\n    {\n        _1494 = _1482 > _1180_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1494 = _1485;\n    }\n    bool _1503;\n    if (!_1494)\n    {\n        _1503 = _1475.y < _1180_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1503 = _1494;\n    }\n    bool _1512;\n    if (!_1503)\n    {\n        _1512 = _1475.y > _1180_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1512 = _1503;\n    }\n    bool _1519;\n    if (!_1512)\n    {\n        _1519 = _1475.z > 1.0f;\n    }\n    else\n    {\n        _1519 = _1512;\n    }\n    if (_1519)\n    {\n        return -1.0f;\n    }\n    float _1528;\n    if (_1180_fa_shadow_bias.x > 0.0f)\n    {\n        _1528 = _1180_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1528 = 1.5f * _1180_fa_shadow_info[ci].x;\n    }\n    float2 param = _1475.xy;\n    float4 param_1 = _1180_fa_shadow_rect[ci];\n    float param_2 = _1475.z - ((_1528 * (1.0f + (0.5f * _1445))) / _1427);\n    float param_3 = _1180_fa_shadow_info[ci].x;\n    float param_4 = _1427;\n    float param_5 = _1427 * 0.25f;\n    float param_6 = ((_1180_fa_shadow_info[ci].x * min(_1445, 3.0f)) * 0.5f) / _1427;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_1180_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _1180_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_440_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1955 = int(_1180_fa_shadow_cfg.x + 0.5f);\n    if (_1955 < 1)\n    {\n        return 1.0f;\n    }\n    float _1970 = dot(world - _1180_fa_shadow_eye.xyz, _1180_fa_shadow_fwd.xyz);\n    int param = _1955 - 1;\n    if (_1970 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1982 = _1955 > 1;\n    bool _1989;\n    if (_1982)\n    {\n        _1989 = _1970 > _1180_fa_shadow_split.x;\n    }\n    else\n    {\n        _1989 = _1982;\n    }\n    if (_1989)\n    {\n        ci = 1;\n    }\n    bool _1993 = _1955 > 2;\n    bool _2000;\n    if (_1993)\n    {\n        _2000 = _1970 > _1180_fa_shadow_split.y;\n    }\n    else\n    {\n        _2000 = _1993;\n    }\n    if (_2000)\n    {\n        ci = 2;\n    }\n    bool _2004 = _1955 > 3;\n    bool _2011;\n    if (_2004)\n    {\n        _2011 = _1970 > _1180_fa_shadow_split.z;\n    }\n    else\n    {\n        _2011 = _2004;\n    }\n    if (_2011)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1955)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2037 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2037;\n        if (_2037 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_1180_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2062;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2062 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2062 = _1180_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2081 = _1180_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2062, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2092 = clamp((_1970 - (fa_shadow_split_at(param_7) - _2081)) / _2081, 0.0f, 1.0f);\n        if (_2092 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1955)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2113 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2113;\n                if (_2113 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2092);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _1586 = _440_fa_pbr.z < 0.5f;\n    bool _1594;\n    if (!_1586)\n    {\n        _1594 = _1180_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _1594 = _1586;\n    }\n    if (_1594)\n    {\n        return 1.0f;\n    }\n    int param = (int(_1180_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _1607 = fa_light_texel(param);\n    float _1608 = _1607.x;\n    if (_1608 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _1617 = int(_1608 + 0.5f);\n    int param_1 = _1617;\n    float4 _1621 = fa_light_texel(param_1);\n    int param_2 = _1617 + 1;\n    float4 _1626 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _1629 = _1621.y;\n    if (_1629 > 0.0f)\n    {\n        float _1646 = 1.0f - smoothstep(0.75f * _1629, _1629, length(world - _1180_fa_shadow_eye.xyz));\n        fade = _1646;\n        if (_1646 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_1621.x > 1.5f)\n    {\n        int param_3 = li * 4;\n        float3 _1665 = world - fa_light_texel(param_3).xyz;\n        float3 _1668 = abs(_1665);\n        float _1670 = _1668.x;\n        float _1672 = _1668.y;\n        bool _1673 = _1670 >= _1672;\n        bool _1681;\n        if (_1673)\n        {\n            _1681 = _1670 >= _1668.z;\n        }\n        else\n        {\n            _1681 = _1673;\n        }\n        int _1682;\n        if (_1681)\n        {\n            _1682 = (_1665.x > 0.0f) ? 0 : 1;\n        }\n        else\n        {\n            int _1695;\n            if (_1672 >= _1668.z)\n            {\n                _1695 = (_1665.y > 0.0f) ? 2 : 3;\n            }\n            else\n            {\n                _1695 = (_1665.z > 0.0f) ? 4 : 5;\n            }\n            _1682 = _1695;\n        }\n        face = _1682;\n    }\n    int _1714 = (_1617 + 2) + (face * 6);\n    int param_4 = _1714;\n    int param_5 = _1714 + 1;\n    int param_6 = _1714 + 3;\n    float4 _1728 = fa_light_texel(param_6);\n    int param_7 = _1714 + 4;\n    float4 _1733 = fa_light_texel(param_7);\n    int param_8 = _1714 + 5;\n    float4 _1738 = fa_light_texel(param_8);\n    float _1750 = _1738.x * max(dot(_1728, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _1755 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1778 = clamp(dot(n, _1728.xyz), -1.0f, 1.0f);\n    int param_9 = li * 4;\n    float _1801 = min(sqrt(1.0f - (_1778 * _1778)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1728, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _1804 = _1626.y;\n    float _1806;\n    if (_1804 > 0.0f)\n    {\n        _1806 = _1804;\n    }\n    else\n    {\n        _1806 = 1.5f * _1750;\n    }\n    float4 _1826 = float4(world + (n * (_1806 * sqrt(1.0f - (_1755 * _1755)))), 1.0f);\n    float _1830 = dot(_1728, _1826);\n    float _1833 = _1738.y;\n    if (_1830 < _1833)\n    {\n        return 1.0f;\n    }\n    float2 _1848 = float2(dot(fa_light_texel(param_4), _1826), dot(fa_light_texel(param_5), _1826)) / _1830.xx;\n    float _1850 = _1848.x;\n    bool _1853 = _1850 < _1733.x;\n    bool _1862;\n    if (!_1853)\n    {\n        _1862 = _1850 > _1733.z;\n    }\n    else\n    {\n        _1862 = _1853;\n    }\n    bool _1871;\n    if (!_1862)\n    {\n        _1871 = _1848.y < _1733.y;\n    }\n    else\n    {\n        _1871 = _1862;\n    }\n    bool _1880;\n    if (!_1871)\n    {\n        _1880 = _1848.y > _1733.w;\n    }\n    else\n    {\n        _1880 = _1871;\n    }\n    if (_1880)\n    {\n        return 1.0f;\n    }\n    float _1886 = _1626.x;\n    float _1888;\n    if (_1886 > 0.0f)\n    {\n        _1888 = _1886;\n    }\n    else\n    {\n        _1888 = 1.5f * _1750;\n    }\n    float2 param_10 = _1848;\n    float4 param_11 = _1733;\n    float param_12 = _1830 - (_1888 * (1.0f + (0.5f * _1801)));\n    float param_13 = _1750;\n    float param_14 = 1.0f;\n    float param_15 = _1738.z * 0.25f;\n    float param_16 = (_1750 * min(_1801, 3.0f)) * 0.5f;\n    float3 param_17 = float3(1.0f, _1833, _1738.z);\n    int param_18 = int(_1621.z + 0.5f);\n    float param_19 = _1621.w;\n    return lerp(1.0f, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _2281 = fa_lm.z > 0.5f;\n    bool _2287;\n    if (_2281)\n    {\n        int param = li;\n        _2287 = fa_light_baked(param);\n    }\n    else\n    {\n        _2287 = _2281;\n    }\n    if (_2287)\n    {\n        int param_1 = li;\n        LightSample _3337 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _3337;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _2310 = fa_light_sample(param_2, param_3);\n    float3 _3344 = _2310.direction;\n    float3 _3339 = _2310.color;\n    float _3346 = _2310.attenuation;\n    float _3341 = _2310.shadow;\n    int _3349 = _2310.type;\n    if ((_3349 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _3344;\n        float _2324 = fa_shadow_factor(param_4, param_5);\n        _3341 = _2324;\n        _3339 *= _2324;\n    }\n    else\n    {\n        bool _2335 = _3349 != 0;\n        bool _2341;\n        if (_2335)\n        {\n            _2341 = _3346 > 0.0f;\n        }\n        else\n        {\n            _2341 = _2335;\n        }\n        if (_2341)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _3344;\n            float _2353 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _3341 = _2353;\n            _3339 *= _2353;\n        }\n    }\n    LightSample _3356 = { _3344, _3339, _3346, _3341, _2310._distance, _3349 };\n    return _3356;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    float _2373;\n    if (dot(s.normal, l.direction) > 0.5f)\n    {\n        _2373 = 1.0f;\n    }\n    else\n    {\n        _2373 = _2379_dark;\n    }\n    return (s.albedo * l.color) * _2373;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_1180_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _2137 = int(_1180_fa_shadow_cfg.x + 0.5f);\n    float _2147 = dot(world - _1180_fa_shadow_eye.xyz, _1180_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _2152 = _2137 > 0;\n    bool _2161;\n    if (_2152)\n    {\n        int param = _2137 - 1;\n        _2161 = _2147 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2161 = _2152;\n    }\n    if (_2161)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _2168 = _2137 > 1;\n        bool _2175;\n        if (_2168)\n        {\n            _2175 = _2147 > _1180_fa_shadow_split.x;\n        }\n        else\n        {\n            _2175 = _2168;\n        }\n        if (_2175)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _2181 = _2137 > 2;\n        bool _2188;\n        if (_2181)\n        {\n            _2188 = _2147 > _1180_fa_shadow_split.y;\n        }\n        else\n        {\n            _2188 = _2181;\n        }\n        if (_2188)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _2194 = _2137 > 3;\n        bool _2201;\n        if (_2194)\n        {\n            _2201 = _2147 > _1180_fa_shadow_split.z;\n        }\n        else\n        {\n            _2201 = _2194;\n        }\n        if (_2201)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _3180 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3180 = -_3180;\n    }\n    float3 _2764 = normalize(_440_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _3193 = { fa_world_pos, _3180, fa_world_tangent, fa_uv, fa_vertex_color, _2764, gl_FrontFacing };\n    SurfaceInput param_1 = _3193;\n    Surface _2772 = fa_standard_surface(param_1);\n    float3 _3211 = _2772.albedo;\n    float _3212 = _2772.alpha;\n    float3 _3213 = _2772.normal;\n    float _3214 = _2772.metallic;\n    float _3215 = _2772.roughness;\n    float _3216 = _2772.occlusion;\n    float3 _3217 = _2772.emission;\n    float _3218 = _2772.clearcoat;\n    float _3219 = _2772.clearcoat_roughness;\n    float3 _3220 = _2772.sheen_color;\n    float _3221 = _2772.sheen_roughness;\n    float _3222 = _2772.anisotropy;\n    float _3223 = _2772.anisotropy_rotation;\n    float _3224 = _2772.specular;\n    float _3225 = _2772.ior;\n    float3 _3226 = _2772.specular_color;\n    SurfaceInput _3201 = { fa_world_pos, _3180, fa_world_tangent, fa_uv, fa_vertex_color, _2764, gl_FrontFacing };\n    SurfaceInput param_2 = _3201;\n    Surface param_3 = _2772;\n    surface(param_2, param_3);\n    _3211 = param_3.albedo;\n    _3212 = param_3.alpha;\n    _3213 = param_3.normal;\n    _3214 = param_3.metallic;\n    _3215 = param_3.roughness;\n    _3216 = param_3.occlusion;\n    _3217 = param_3.emission;\n    _3218 = param_3.clearcoat;\n    _3219 = param_3.clearcoat_roughness;\n    _3220 = param_3.sheen_color;\n    _3221 = param_3.sheen_roughness;\n    _3222 = param_3.anisotropy;\n    _3223 = param_3.anisotropy_rotation;\n    _3224 = param_3.specular;\n    _3225 = param_3.ior;\n    _3226 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _3180;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _3211 = param_6;\n    _3213 = param_7;\n    float3 result;\n    if (_440_fa_emissive.w > 0.5f)\n    {\n        result = _3211;\n    }\n    else\n    {\n        float3 _2810 = _3213;\n        float3 _2811 = normalize(_2810);\n        _3213 = _2811;\n        float3 param_8 = _2811;\n        float3 lit = (fa_indirect_diffuse(param_8) * _3211) * _3216;\n        int _2830 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2830; ln++)\n        {\n            int param_9 = ln;\n            int _2843 = fa_cl_light(param_9);\n            bool _2846 = fa_lm.z > 0.5f;\n            bool _2852;\n            if (_2846)\n            {\n                int param_10 = _2843;\n                _2852 = fa_light_baked(param_10);\n            }\n            else\n            {\n                _2852 = _2846;\n            }\n            if (_2852)\n            {\n                continue;\n            }\n            int param_11 = _2843;\n            float3 param_12 = fa_world_pos;\n            float3 param_13 = _3180;\n            SurfaceInput _3209 = { fa_world_pos, _3180, fa_world_tangent, fa_uv, fa_vertex_color, _2764, gl_FrontFacing };\n            SurfaceInput param_14 = _3209;\n            Surface _3292 = { _3211, _3212, _3213, _3214, _3215, _3216, _3217, _3218, _3219, _3220, _3221, _3222, _3223, _3224, _3225, _3226 };\n            Surface param_15 = _3292;\n            LightSample param_16 = fa_light_shadowed(param_11, param_12, param_13);\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    float3 _2879 = result;\n    float3 _2880 = _2879 + _3217;\n    result = _2880;\n    float3 param_17 = _2880;\n    float3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _2889 = _440_fa_fog.w > 0.0f;\n    bool _2896;\n    if (!_2889)\n    {\n        _2896 = _440_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2896 = _2889;\n    }\n    if (_2896)\n    {\n        float3 _2905 = fa_world_pos - _440_fa_camera_pos.xyz;\n        float _2911 = dot(_2905, _440_fa_fog_c.xyz);\n        bool _2915 = _440_fa_fog_c.w > 0.5f;\n        float _2916;\n        if (_2915)\n        {\n            _2916 = _2911;\n        }\n        else\n        {\n            _2916 = length(_2905);\n        }\n        float _2928 = _2916 - _440_fa_fog_b.x;\n        if (_2928 > 0.0f)\n        {\n            float _2937 = _440_fa_fog.w * _2928;\n            float tau = _2937 * _2937;\n            if (_440_fa_fog_b.y > 0.0f)\n            {\n                float _2953;\n                if (_2915)\n                {\n                    _2953 = fa_world_pos.y - (_440_fa_fog_c.y * _2911);\n                }\n                else\n                {\n                    _2953 = _440_fa_camera_pos.y;\n                }\n                float _2974 = lerp(_2953, fa_world_pos.y, clamp(_440_fa_fog_b.x / _2916, 0.0f, 1.0f));\n                float _2978 = fa_world_pos.y - _2974;\n                float _2983 = _2974 - _440_fa_fog_b.z;\n                float _2988 = fa_world_pos.y - _440_fa_fog_b.z;\n                bool _2991 = _2983 <= 0.0f;\n                bool _2992 = !_2991;\n                bool _2998;\n                if (_2992)\n                {\n                    _2998 = _440_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2998 = _2991;\n                }\n                float _2999;\n                if (_2998)\n                {\n                    _2999 = _440_fa_fog_b.y;\n                }\n                else\n                {\n                    _2999 = _440_fa_fog_b.y * exp(-min(_440_fa_fog_b.w * _2983, 80.0f));\n                }\n                bool _3026;\n                if (_2992)\n                {\n                    _3026 = _440_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3026 = _2991;\n                }\n                float _3027;\n                if (_3026)\n                {\n                    _3027 = _440_fa_fog_b.y * _2983;\n                }\n                else\n                {\n                    _3027 = (_440_fa_fog_b.y * (1.0f - exp(-min(_440_fa_fog_b.w * _2983, 80.0f)))) / _440_fa_fog_b.w;\n                }\n                bool _3052 = _2988 <= 0.0f;\n                bool _3059;\n                if (!_3052)\n                {\n                    _3059 = _440_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3059 = _3052;\n                }\n                float _3060;\n                if (_3059)\n                {\n                    _3060 = _440_fa_fog_b.y * _2988;\n                }\n                else\n                {\n                    _3060 = (_440_fa_fog_b.y * (1.0f - exp(-min(_440_fa_fog_b.w * _2988, 80.0f)))) / _440_fa_fog_b.w;\n                }\n                float _3087;\n                if (abs(_2978) < 0.001000000047497451305389404296875f)\n                {\n                    _3087 = _2999;\n                }\n                else\n                {\n                    _3087 = (_3060 - _3027) / _2978;\n                }\n                tau += (_2928 * max(_3087, 0.0f));\n            }\n            result = lerp(result, _440_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _3212);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_440",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1180",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_2379",
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
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _384 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _384;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _391 = _273.world_pos;\n    fa_world_pos = _391;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_391, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _440_fa_camera_pos : packoffset(c0);\n    float4 _440_fa_ambient : packoffset(c1);\n    float4 _440_fa_base_color : packoffset(c2);\n    float4 _440_fa_emissive : packoffset(c3);\n    float4 _440_fa_model_emissive : packoffset(c4);\n    float4 _440_fa_pbr : packoffset(c5);\n    float4 _440_fa_maps : packoffset(c6);\n    float4 _440_fa_fog : packoffset(c7);\n    float4 _440_fa_fog_b : packoffset(c8);\n    float4 _440_fa_fog_c : packoffset(c9);\n    float4 _440_fa_counts : packoffset(c10);\n    float4 _440_fa_env_sky : packoffset(c11);\n    float4 _440_fa_env_horizon : packoffset(c12);\n    float4 _440_fa_time : packoffset(c13);\n    float4 _440_fa_cl_vpx : packoffset(c14);\n    float4 _440_fa_cl_vpy : packoffset(c15);\n    float4 _440_fa_cl_vpw : packoffset(c16);\n    float4 _440_fa_cl_fwd : packoffset(c17);\n    float4 _440_fa_cl_grid : packoffset(c18);\n    float4 _440_fa_cl_info : packoffset(c19);\n    float4 _440_fa_layers_a : packoffset(c20);\n    float4 _440_fa_layers_b : packoffset(c21);\n    float4 _440_fa_layers_c : packoffset(c22);\n    float4 _440_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _1180_fa_shadow_mat[4] : packoffset(c0);\n    float4 _1180_fa_shadow_rect[4] : packoffset(c16);\n    float4 _1180_fa_shadow_info[4] : packoffset(c20);\n    float4 _1180_fa_shadow_split : packoffset(c24);\n    float4 _1180_fa_shadow_cfg : packoffset(c25);\n    float4 _1180_fa_shadow_bias : packoffset(c26);\n    float4 _1180_fa_shadow_eye : packoffset(c27);\n    float4 _1180_fa_shadow_fwd : packoffset(c28);\n    float4 _1180_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _2379_dark : packoffset(c0);\n    float _2379_fa_pad0 : packoffset(c0.y);\n    float _2379_fa_pad1 : packoffset(c0.z);\n    float _2379_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_decal_tex : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_irr_tex : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t8);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _445 = _440_fa_cl_info.x < 0.0f;\n    bool _452;\n    if (!_445)\n    {\n        _452 = _440_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _452 = _445;\n    }\n    bool _460;\n    if (!_452)\n    {\n        _460 = _440_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _460 = _452;\n    }\n    bool _467;\n    if (!_460)\n    {\n        _467 = _440_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _467 = _460;\n    }\n    bool _474;\n    if (!_467)\n    {\n        _474 = _440_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _474 = _467;\n    }\n    if (_474)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _484 = float4(world_pos, 1.0f);\n    float _491 = dot(_440_fa_cl_vpw, _484);\n    if (!(_491 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _513 = float2(dot(_440_fa_cl_vpx, _484), dot(_440_fa_cl_vpy, _484)) / _491.xx;\n    int _517 = int(_440_fa_cl_grid.x);\n    int _521 = int(_440_fa_cl_grid.y);\n    int param = (int(_440_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_440_fa_cl_fwd.xyz, world_pos) + _440_fa_cl_fwd.w, _440_fa_cl_grid.w) / _440_fa_cl_grid.w) * _440_fa_cl_grid.z)), 0, int(_440_fa_cl_info.y) - 1) * _521) + clamp(int(floor(((_513.y * 0.5f) + 0.5f) * _440_fa_cl_grid.y)), 0, _521 - 1)) * _517)) + clamp(int(floor(((_513.x * 0.5f) + 0.5f) * _440_fa_cl_grid.x)), 0, _517 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _597 = fa_cluster_texel(param);\n    return int2(int(_597.x), int(_597.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_440_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2254 = fa_cluster_lookup(param);\n    fa_cl_slot = _2254.x;\n    fa_cl_local = _2254.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _2428 = fa_linear_to_srgb(param);\n        c = _2428;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _2436 = fa_srgb_to_linear(param_1);\n            c = _2436;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _204;\n    if (i.front_facing)\n    {\n        _204 = i.world_normal;\n    }\n    else\n    {\n        _204 = -i.world_normal;\n    }\n    float3 _228 = normalize(i.world_tangent.xyz - (_204 * dot(_204, i.world_tangent.xyz)));\n    float3 _256 = normalize(((_228 * m.x) + ((cross(_204, _228) * i.world_tangent.w) * m.y)) + (_204 * m.z));\n    float3 _259;\n    if (i.front_facing)\n    {\n        _259 = _256;\n    }\n    else\n    {\n        _259 = -_256;\n    }\n    return _259;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _440_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2467 = fa_tex_fix(param_2, param_3);\n    float4 _3479 = base_t;\n    _3479.x = _2467.x;\n    _3479.y = _2467.y;\n    _3479.z = _2467.z;\n    base_t = _3479;\n    float4 _2481 = (_3479 * _440_fa_base_color) * i.vertex_color;\n    float3 _3359 = i.world_normal;\n    if (_440_fa_maps.z > 0.5f)\n    {\n        float param_4 = _440_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2513 = fa_tex_fix(param_6, param_7);\n        float3 _2516 = (_2513 * 2.0f) - 1.0f.xxx;\n        float2 _2521 = _2516.xy * _440_fa_maps.x;\n        float3 _3487 = _2516;\n        _3487.x = _2521.x;\n        _3487.y = _2521.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3487;\n        _3359 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _440_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2550 = fa_tex_fix(param_12, param_13);\n    float4 _3490 = mrt;\n    _3490.x = _2550.x;\n    _3490.y = _2550.y;\n    _3490.z = _2550.z;\n    mrt = _3490;\n    float4 _2578 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _440_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _2578.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2590 = fa_tex_fix(param_16, param_17);\n    float param_18 = _440_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2620 = fa_tex_fix(param_20, param_21);\n    float _3364 = _440_fa_layers_a.x;\n    float _3365 = _440_fa_layers_a.y;\n    float _3368 = _440_fa_layers_a.z;\n    float _3367 = _440_fa_layers_b.w;\n    float _3370 = _440_fa_layers_c.x;\n    if (_440_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_440_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _3364 *= _2590.y;\n            _3365 *= _2590.z;\n            _3367 *= _2578.w;\n        }\n        if (_440_fa_layers_c.z > 1.5f)\n        {\n            _3368 *= mrt.x;\n            _3370 *= mrt.w;\n        }\n    }\n    Surface _3389 = { _2481.xyz, _2481.w, _3359, clamp(_440_fa_pbr.x * _2550.z, 0.0f, 1.0f), clamp(_440_fa_pbr.y * _2550.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_440_fa_maps.y * (_2590.x - 1.0f)), _440_fa_emissive.xyz + (_440_fa_model_emissive.xyz * _2620), _3364, _3365, _440_fa_layers_b.xyz, _3367, _3368, _440_fa_layers_a.w, _3370, _440_fa_layers_c.y, _440_fa_layers_d.xyz };\n    return _3389;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _678 = rect.zw - rect.xy;\n    float2 _682 = _678 * atlas;\n    float2 _686 = ddx * _682;\n    float2 _690 = ddy * _682;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _678), clamp(0.5f * log2(max(max(dot(_686, _686), dot(_690, _690)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _725 = _440_fa_counts.y < 0.5f;\n    bool _732;\n    if (!_725)\n    {\n        _732 = _440_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _732 = _725;\n    }\n    if (_732)\n    {\n        return;\n    }\n    float3 _738 = ddx(world_pos);\n    float3 _741 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _745 = fa_cluster_texel(param);\n    int _749 = int(_745.w);\n    if (_749 < 1)\n    {\n        return;\n    }\n    int _759 = int(_440_fa_counts.y + 0.5f);\n    int param_1 = _759;\n    float4 _763 = fa_light_texel(param_1);\n    float2 _766 = _763.yz;\n    int _770 = int(_763.w);\n    int param_2 = _759 + 1;\n    float4 _775 = fa_light_texel(param_2);\n    float _776 = _775.x;\n    int _782 = int(_440_fa_counts.w + 0.5f) - 1;\n    int _786 = int(_745.z);\n    float3 _1052;\n    for (int k = 0; k < _749; k++)\n    {\n        int _799 = _786 + k;\n        int param_3 = _770 + (_799 >> 2);\n        int _817 = (_759 + 2) + (int(fa_light_texel(param_3)[_799 & 3]) * 7);\n        int param_4 = _817 + 6;\n        float4 _822 = fa_light_texel(param_4);\n        if (((int(_822.w + 0.5f) >> _782) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _817;\n        float4 _837 = fa_light_texel(param_5);\n        int param_6 = _817 + 1;\n        float4 _842 = fa_light_texel(param_6);\n        int param_7 = _817 + 2;\n        float4 _847 = fa_light_texel(param_7);\n        float3 _850 = _837.xyz;\n        float _855 = dot(_850, world_pos) + _837.w;\n        float3 _857 = _842.xyz;\n        float _862 = dot(_857, world_pos) + _842.w;\n        float3 _864 = _847.xyz;\n        float _869 = dot(_864, world_pos) + _847.w;\n        bool _874 = abs(_855) > 0.5f;\n        bool _882;\n        if (!_874)\n        {\n            _882 = abs(_862) > 0.5f;\n        }\n        else\n        {\n            _882 = _874;\n        }\n        bool _890;\n        if (!_882)\n        {\n            _890 = abs(_869) > 0.5f;\n        }\n        else\n        {\n            _890 = _882;\n        }\n        if (_890)\n        {\n            continue;\n        }\n        float _905 = clamp(dot(geo_normal, normalize(_864)) * _822.z, 0.0f, 1.0f);\n        if (_905 <= 0.0f)\n        {\n            continue;\n        }\n        float _925 = (clamp((0.5f - abs(_869)) * 10.0f, 0.0f, 1.0f) * _905) * _822.x;\n        float2 _933 = float2(_855 + 0.5f, 0.5f - _862);\n        float2 _943 = float2(dot(_850, _738), dot(_857, _738));\n        float2 _953 = float2(dot(_850, _741), dot(_857, _741));\n        int param_8 = _817 + 5;\n        float4 _958 = fa_light_texel(param_8);\n        int param_9 = _817 + 3;\n        float4 _963 = fa_light_texel(param_9);\n        int param_10 = _817 + 4;\n        float4 _968 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _958.xyz;\n        bool _978 = _963.z > _963.x;\n        if (_978)\n        {\n            float4 param_11 = _963;\n            float2 param_12 = _933;\n            float2 param_13 = _766;\n            float2 param_14 = _943;\n            float2 param_15 = _953;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_776 > 0.5f) && (_776 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1004 = fa_dc_to_linear(param_16);\n                float4 _3415 = tx;\n                _3415.x = _1004.x;\n                _3415.y = _1004.y;\n                _3415.z = _1004.z;\n                tx = _3415;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_925 * tex_a) * _958.w, 0.0f, 1.0f).xxx);\n        if (_968.z > _968.x)\n        {\n            float4 param_17 = _968;\n            float2 param_18 = _933;\n            float2 param_19 = _766;\n            float2 param_20 = _943;\n            float2 param_21 = _953;\n            float4 _1048 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_776 > 1.5f)\n            {\n                float3 param_22 = _1048.xyz;\n                float3 _1058 = fa_dc_to_srgb(param_22);\n                _1052 = _1058;\n            }\n            else\n            {\n                _1052 = _1048.xyz;\n            }\n            float3 _1068 = (_1052 * 2.0f) - 1.0f.xxx;\n            float2 _1073 = _1068.xy * _822.y;\n            float3 _1095 = (normalize(_850) * _1073.x) + (normalize(_857) * _1073.y);\n            float3 _1098 = normalize(normal);\n            normal = normalize(lerp(_1098, normalize((_1098 * max(_1068.z, 0.0500000007450580596923828125f)) + (_1095 - (_1098 * dot(_1098, _1095)))), clamp(_925 * (_978 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_440_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _440_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_440_fa_cl_info.x) + int(_440_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _315 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _321 = fa_light_texel(param_1);\n    float _324 = _321.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _330 = _324 < 0.5f;\n    float3 l;\n    if (_330)\n    {\n        l = normalize(_315.xyz);\n    }\n    else\n    {\n        float3 _342 = _315.xyz - world_pos;\n        float _344 = length(_342);\n        dist = _344;\n        l = _342 / max(_344, 9.9999997473787516355514526367188e-05f).xxx;\n        float _359 = _344 / max(_315.w, 0.001000000047497451305389404296875f);\n        float _365 = clamp(1.0f - (_359 * _359), 0.0f, 1.0f);\n        atten = _365 * _365;\n        if (_324 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _379 = fa_light_texel(param_2);\n            float _389 = _379.w;\n            int param_3 = (li * 4) + 3;\n            float4 _395 = fa_light_texel(param_3);\n            float _396 = _395.x;\n            float cos_inner = _396;\n            if (_396 > 1.5f)\n            {\n                cos_inner = lerp(_389, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_389, cos_inner, dot(-l, normalize(_379.xyz)));\n        }\n    }\n    int _426;\n    if (_330)\n    {\n        _426 = 0;\n    }\n    else\n    {\n        _426 = (_324 > 1.5f) ? 2 : 1;\n    }\n    LightSample _3324 = { l, _321.xyz * atten, atten, 1.0f, dist, _426 };\n    return _3324;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1170;\n    if (i == 0)\n    {\n        _1170 = _1180_fa_shadow_split.x;\n    }\n    else\n    {\n        float _1186;\n        if (i == 1)\n        {\n            _1186 = _1180_fa_shadow_split.y;\n        }\n        else\n        {\n            float _1194;\n            if (i == 2)\n            {\n                _1194 = _1180_fa_shadow_split.z;\n            }\n            else\n            {\n                _1194 = _1180_fa_shadow_split.w;\n            }\n            _1186 = _1194;\n        }\n        _1170 = _1186;\n    }\n    return _1170;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1227 = fa_shadow_depth(param, param_1);\n    float _1231;\n    if (conv.x < 0.5f)\n    {\n        _1231 = _1227;\n    }\n    else\n    {\n        _1231 = (conv.y * conv.z) / (conv.z - (_1227 * (conv.z - conv.y)));\n    }\n    return _1231;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1158 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_1158), sin(_1158)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1277 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _1291 = clamp((k * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1277;\n            float2 _1310 = fa_shadow_vogel(param_3, param_4, param_5) * _1291;\n            float2 param_6 = uv + (_1310 * _1180_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1322 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1322 < (zr - (length(_1310) * plane)))\n            {\n                sum += _1322;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0f) * unit) * k) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _1366 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1366; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1366;\n        float param_11 = _1277;\n        float2 _1385 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1385 * _1180_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1385) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1366);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _1427 = max(_1180_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _1432 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1438 = sqrt(1.0f - (_1432 * _1432));\n    float _1445 = min(_1438 / max(_1432, 0.20000000298023223876953125f), 4.0f);\n    float _1450;\n    if (_1180_fa_shadow_bias.y > 0.0f)\n    {\n        _1450 = _1180_fa_shadow_bias.y;\n    }\n    else\n    {\n        _1450 = 1.5f * _1180_fa_shadow_info[ci].x;\n    }\n    float4 _1475 = mul(float4(world + (n * (_1450 * _1438)), 1.0f), _1180_fa_shadow_mat[ci]);\n    float _1482 = _1475.x;\n    bool _1485 = _1482 < _1180_fa_shadow_rect[ci].x;\n    bool _1494;\n    if (!_1485)\n    {\n        _1494 = _1482 > _1180_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1494 = _1485;\n    }\n    bool _1503;\n    if (!_1494)\n    {\n        _1503 = _1475.y < _1180_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1503 = _1494;\n    }\n    bool _1512;\n    if (!_1503)\n    {\n        _1512 = _1475.y > _1180_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1512 = _1503;\n    }\n    bool _1519;\n    if (!_1512)\n    {\n        _1519 = _1475.z > 1.0f;\n    }\n    else\n    {\n        _1519 = _1512;\n    }\n    if (_1519)\n    {\n        return -1.0f;\n    }\n    float _1528;\n    if (_1180_fa_shadow_bias.x > 0.0f)\n    {\n        _1528 = _1180_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1528 = 1.5f * _1180_fa_shadow_info[ci].x;\n    }\n    float2 param = _1475.xy;\n    float4 param_1 = _1180_fa_shadow_rect[ci];\n    float param_2 = _1475.z - ((_1528 * (1.0f + (0.5f * _1445))) / _1427);\n    float param_3 = _1180_fa_shadow_info[ci].x;\n    float param_4 = _1427;\n    float param_5 = _1427 * 0.25f;\n    float param_6 = ((_1180_fa_shadow_info[ci].x * min(_1445, 3.0f)) * 0.5f) / _1427;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_1180_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _1180_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_440_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1955 = int(_1180_fa_shadow_cfg.x + 0.5f);\n    if (_1955 < 1)\n    {\n        return 1.0f;\n    }\n    float _1970 = dot(world - _1180_fa_shadow_eye.xyz, _1180_fa_shadow_fwd.xyz);\n    int param = _1955 - 1;\n    if (_1970 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1982 = _1955 > 1;\n    bool _1989;\n    if (_1982)\n    {\n        _1989 = _1970 > _1180_fa_shadow_split.x;\n    }\n    else\n    {\n        _1989 = _1982;\n    }\n    if (_1989)\n    {\n        ci = 1;\n    }\n    bool _1993 = _1955 > 2;\n    bool _2000;\n    if (_1993)\n    {\n        _2000 = _1970 > _1180_fa_shadow_split.y;\n    }\n    else\n    {\n        _2000 = _1993;\n    }\n    if (_2000)\n    {\n        ci = 2;\n    }\n    bool _2004 = _1955 > 3;\n    bool _2011;\n    if (_2004)\n    {\n        _2011 = _1970 > _1180_fa_shadow_split.z;\n    }\n    else\n    {\n        _2011 = _2004;\n    }\n    if (_2011)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1955)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2037 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2037;\n        if (_2037 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_1180_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2062;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2062 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2062 = _1180_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2081 = _1180_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2062, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2092 = clamp((_1970 - (fa_shadow_split_at(param_7) - _2081)) / _2081, 0.0f, 1.0f);\n        if (_2092 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1955)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2113 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2113;\n                if (_2113 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2092);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _1586 = _440_fa_pbr.z < 0.5f;\n    bool _1594;\n    if (!_1586)\n    {\n        _1594 = _1180_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _1594 = _1586;\n    }\n    if (_1594)\n    {\n        return 1.0f;\n    }\n    int param = (int(_1180_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _1607 = fa_light_texel(param);\n    float _1608 = _1607.x;\n    if (_1608 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _1617 = int(_1608 + 0.5f);\n    int param_1 = _1617;\n    float4 _1621 = fa_light_texel(param_1);\n    int param_2 = _1617 + 1;\n    float4 _1626 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _1629 = _1621.y;\n    if (_1629 > 0.0f)\n    {\n        float _1646 = 1.0f - smoothstep(0.75f * _1629, _1629, length(world - _1180_fa_shadow_eye.xyz));\n        fade = _1646;\n        if (_1646 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_1621.x > 1.5f)\n    {\n        int param_3 = li * 4;\n        float3 _1665 = world - fa_light_texel(param_3).xyz;\n        float3 _1668 = abs(_1665);\n        float _1670 = _1668.x;\n        float _1672 = _1668.y;\n        bool _1673 = _1670 >= _1672;\n        bool _1681;\n        if (_1673)\n        {\n            _1681 = _1670 >= _1668.z;\n        }\n        else\n        {\n            _1681 = _1673;\n        }\n        int _1682;\n        if (_1681)\n        {\n            _1682 = (_1665.x > 0.0f) ? 0 : 1;\n        }\n        else\n        {\n            int _1695;\n            if (_1672 >= _1668.z)\n            {\n                _1695 = (_1665.y > 0.0f) ? 2 : 3;\n            }\n            else\n            {\n                _1695 = (_1665.z > 0.0f) ? 4 : 5;\n            }\n            _1682 = _1695;\n        }\n        face = _1682;\n    }\n    int _1714 = (_1617 + 2) + (face * 6);\n    int param_4 = _1714;\n    int param_5 = _1714 + 1;\n    int param_6 = _1714 + 3;\n    float4 _1728 = fa_light_texel(param_6);\n    int param_7 = _1714 + 4;\n    float4 _1733 = fa_light_texel(param_7);\n    int param_8 = _1714 + 5;\n    float4 _1738 = fa_light_texel(param_8);\n    float _1750 = _1738.x * max(dot(_1728, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _1755 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1778 = clamp(dot(n, _1728.xyz), -1.0f, 1.0f);\n    int param_9 = li * 4;\n    float _1801 = min(sqrt(1.0f - (_1778 * _1778)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1728, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _1804 = _1626.y;\n    float _1806;\n    if (_1804 > 0.0f)\n    {\n        _1806 = _1804;\n    }\n    else\n    {\n        _1806 = 1.5f * _1750;\n    }\n    float4 _1826 = float4(world + (n * (_1806 * sqrt(1.0f - (_1755 * _1755)))), 1.0f);\n    float _1830 = dot(_1728, _1826);\n    float _1833 = _1738.y;\n    if (_1830 < _1833)\n    {\n        return 1.0f;\n    }\n    float2 _1848 = float2(dot(fa_light_texel(param_4), _1826), dot(fa_light_texel(param_5), _1826)) / _1830.xx;\n    float _1850 = _1848.x;\n    bool _1853 = _1850 < _1733.x;\n    bool _1862;\n    if (!_1853)\n    {\n        _1862 = _1850 > _1733.z;\n    }\n    else\n    {\n        _1862 = _1853;\n    }\n    bool _1871;\n    if (!_1862)\n    {\n        _1871 = _1848.y < _1733.y;\n    }\n    else\n    {\n        _1871 = _1862;\n    }\n    bool _1880;\n    if (!_1871)\n    {\n        _1880 = _1848.y > _1733.w;\n    }\n    else\n    {\n        _1880 = _1871;\n    }\n    if (_1880)\n    {\n        return 1.0f;\n    }\n    float _1886 = _1626.x;\n    float _1888;\n    if (_1886 > 0.0f)\n    {\n        _1888 = _1886;\n    }\n    else\n    {\n        _1888 = 1.5f * _1750;\n    }\n    float2 param_10 = _1848;\n    float4 param_11 = _1733;\n    float param_12 = _1830 - (_1888 * (1.0f + (0.5f * _1801)));\n    float param_13 = _1750;\n    float param_14 = 1.0f;\n    float param_15 = _1738.z * 0.25f;\n    float param_16 = (_1750 * min(_1801, 3.0f)) * 0.5f;\n    float3 param_17 = float3(1.0f, _1833, _1738.z);\n    int param_18 = int(_1621.z + 0.5f);\n    float param_19 = _1621.w;\n    return lerp(1.0f, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _2281 = fa_lm.z > 0.5f;\n    bool _2287;\n    if (_2281)\n    {\n        int param = li;\n        _2287 = fa_light_baked(param);\n    }\n    else\n    {\n        _2287 = _2281;\n    }\n    if (_2287)\n    {\n        int param_1 = li;\n        LightSample _3337 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _3337;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _2310 = fa_light_sample(param_2, param_3);\n    float3 _3344 = _2310.direction;\n    float3 _3339 = _2310.color;\n    float _3346 = _2310.attenuation;\n    float _3341 = _2310.shadow;\n    int _3349 = _2310.type;\n    if ((_3349 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _3344;\n        float _2324 = fa_shadow_factor(param_4, param_5);\n        _3341 = _2324;\n        _3339 *= _2324;\n    }\n    else\n    {\n        bool _2335 = _3349 != 0;\n        bool _2341;\n        if (_2335)\n        {\n            _2341 = _3346 > 0.0f;\n        }\n        else\n        {\n            _2341 = _2335;\n        }\n        if (_2341)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _3344;\n            float _2353 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _3341 = _2353;\n            _3339 *= _2353;\n        }\n    }\n    LightSample _3356 = { _3344, _3339, _3346, _3341, _2310._distance, _3349 };\n    return _3356;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    float _2373;\n    if (dot(s.normal, l.direction) > 0.5f)\n    {\n        _2373 = 1.0f;\n    }\n    else\n    {\n        _2373 = _2379_dark;\n    }\n    return (s.albedo * l.color) * _2373;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_1180_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _2137 = int(_1180_fa_shadow_cfg.x + 0.5f);\n    float _2147 = dot(world - _1180_fa_shadow_eye.xyz, _1180_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _2152 = _2137 > 0;\n    bool _2161;\n    if (_2152)\n    {\n        int param = _2137 - 1;\n        _2161 = _2147 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2161 = _2152;\n    }\n    if (_2161)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _2168 = _2137 > 1;\n        bool _2175;\n        if (_2168)\n        {\n            _2175 = _2147 > _1180_fa_shadow_split.x;\n        }\n        else\n        {\n            _2175 = _2168;\n        }\n        if (_2175)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _2181 = _2137 > 2;\n        bool _2188;\n        if (_2181)\n        {\n            _2188 = _2147 > _1180_fa_shadow_split.y;\n        }\n        else\n        {\n            _2188 = _2181;\n        }\n        if (_2188)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _2194 = _2137 > 3;\n        bool _2201;\n        if (_2194)\n        {\n            _2201 = _2147 > _1180_fa_shadow_split.z;\n        }\n        else\n        {\n            _2201 = _2194;\n        }\n        if (_2201)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _3180 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3180 = -_3180;\n    }\n    float3 _2764 = normalize(_440_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _3193 = { fa_world_pos, _3180, fa_world_tangent, fa_uv, fa_vertex_color, _2764, gl_FrontFacing };\n    SurfaceInput param_1 = _3193;\n    Surface _2772 = fa_standard_surface(param_1);\n    float3 _3211 = _2772.albedo;\n    float _3212 = _2772.alpha;\n    float3 _3213 = _2772.normal;\n    float _3214 = _2772.metallic;\n    float _3215 = _2772.roughness;\n    float _3216 = _2772.occlusion;\n    float3 _3217 = _2772.emission;\n    float _3218 = _2772.clearcoat;\n    float _3219 = _2772.clearcoat_roughness;\n    float3 _3220 = _2772.sheen_color;\n    float _3221 = _2772.sheen_roughness;\n    float _3222 = _2772.anisotropy;\n    float _3223 = _2772.anisotropy_rotation;\n    float _3224 = _2772.specular;\n    float _3225 = _2772.ior;\n    float3 _3226 = _2772.specular_color;\n    SurfaceInput _3201 = { fa_world_pos, _3180, fa_world_tangent, fa_uv, fa_vertex_color, _2764, gl_FrontFacing };\n    SurfaceInput param_2 = _3201;\n    Surface param_3 = _2772;\n    surface(param_2, param_3);\n    _3211 = param_3.albedo;\n    _3212 = param_3.alpha;\n    _3213 = param_3.normal;\n    _3214 = param_3.metallic;\n    _3215 = param_3.roughness;\n    _3216 = param_3.occlusion;\n    _3217 = param_3.emission;\n    _3218 = param_3.clearcoat;\n    _3219 = param_3.clearcoat_roughness;\n    _3220 = param_3.sheen_color;\n    _3221 = param_3.sheen_roughness;\n    _3222 = param_3.anisotropy;\n    _3223 = param_3.anisotropy_rotation;\n    _3224 = param_3.specular;\n    _3225 = param_3.ior;\n    _3226 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _3180;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _3211 = param_6;\n    _3213 = param_7;\n    float3 result;\n    if (_440_fa_emissive.w > 0.5f)\n    {\n        result = _3211;\n    }\n    else\n    {\n        float3 _2810 = _3213;\n        float3 _2811 = normalize(_2810);\n        _3213 = _2811;\n        float3 param_8 = _2811;\n        float3 lit = (fa_indirect_diffuse(param_8) * _3211) * _3216;\n        int _2830 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2830; ln++)\n        {\n            int param_9 = ln;\n            int _2843 = fa_cl_light(param_9);\n            bool _2846 = fa_lm.z > 0.5f;\n            bool _2852;\n            if (_2846)\n            {\n                int param_10 = _2843;\n                _2852 = fa_light_baked(param_10);\n            }\n            else\n            {\n                _2852 = _2846;\n            }\n            if (_2852)\n            {\n                continue;\n            }\n            int param_11 = _2843;\n            float3 param_12 = fa_world_pos;\n            float3 param_13 = _3180;\n            SurfaceInput _3209 = { fa_world_pos, _3180, fa_world_tangent, fa_uv, fa_vertex_color, _2764, gl_FrontFacing };\n            SurfaceInput param_14 = _3209;\n            Surface _3292 = { _3211, _3212, _3213, _3214, _3215, _3216, _3217, _3218, _3219, _3220, _3221, _3222, _3223, _3224, _3225, _3226 };\n            Surface param_15 = _3292;\n            LightSample param_16 = fa_light_shadowed(param_11, param_12, param_13);\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    float3 _2879 = result;\n    float3 _2880 = _2879 + _3217;\n    result = _2880;\n    float3 param_17 = _2880;\n    float3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _2889 = _440_fa_fog.w > 0.0f;\n    bool _2896;\n    if (!_2889)\n    {\n        _2896 = _440_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2896 = _2889;\n    }\n    if (_2896)\n    {\n        float3 _2905 = fa_world_pos - _440_fa_camera_pos.xyz;\n        float _2911 = dot(_2905, _440_fa_fog_c.xyz);\n        bool _2915 = _440_fa_fog_c.w > 0.5f;\n        float _2916;\n        if (_2915)\n        {\n            _2916 = _2911;\n        }\n        else\n        {\n            _2916 = length(_2905);\n        }\n        float _2928 = _2916 - _440_fa_fog_b.x;\n        if (_2928 > 0.0f)\n        {\n            float _2937 = _440_fa_fog.w * _2928;\n            float tau = _2937 * _2937;\n            if (_440_fa_fog_b.y > 0.0f)\n            {\n                float _2953;\n                if (_2915)\n                {\n                    _2953 = fa_world_pos.y - (_440_fa_fog_c.y * _2911);\n                }\n                else\n                {\n                    _2953 = _440_fa_camera_pos.y;\n                }\n                float _2974 = lerp(_2953, fa_world_pos.y, clamp(_440_fa_fog_b.x / _2916, 0.0f, 1.0f));\n                float _2978 = fa_world_pos.y - _2974;\n                float _2983 = _2974 - _440_fa_fog_b.z;\n                float _2988 = fa_world_pos.y - _440_fa_fog_b.z;\n                bool _2991 = _2983 <= 0.0f;\n                bool _2992 = !_2991;\n                bool _2998;\n                if (_2992)\n                {\n                    _2998 = _440_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2998 = _2991;\n                }\n                float _2999;\n                if (_2998)\n                {\n                    _2999 = _440_fa_fog_b.y;\n                }\n                else\n                {\n                    _2999 = _440_fa_fog_b.y * exp(-min(_440_fa_fog_b.w * _2983, 80.0f));\n                }\n                bool _3026;\n                if (_2992)\n                {\n                    _3026 = _440_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3026 = _2991;\n                }\n                float _3027;\n                if (_3026)\n                {\n                    _3027 = _440_fa_fog_b.y * _2983;\n                }\n                else\n                {\n                    _3027 = (_440_fa_fog_b.y * (1.0f - exp(-min(_440_fa_fog_b.w * _2983, 80.0f)))) / _440_fa_fog_b.w;\n                }\n                bool _3052 = _2988 <= 0.0f;\n                bool _3059;\n                if (!_3052)\n                {\n                    _3059 = _440_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3059 = _3052;\n                }\n                float _3060;\n                if (_3059)\n                {\n                    _3060 = _440_fa_fog_b.y * _2988;\n                }\n                else\n                {\n                    _3060 = (_440_fa_fog_b.y * (1.0f - exp(-min(_440_fa_fog_b.w * _2988, 80.0f)))) / _440_fa_fog_b.w;\n                }\n                float _3087;\n                if (abs(_2978) < 0.001000000047497451305389404296875f)\n                {\n                    _3087 = _2999;\n                }\n                else\n                {\n                    _3087 = (_3060 - _3027) / _2978;\n                }\n                tau += (_2928 * max(_3087, 0.0f));\n            }\n            result = lerp(result, _440_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _3212);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_440",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1180",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_2379",
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
          }
        ]
      }
    },
    "prepass": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _295 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _295;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _302 = _160.world_pos;\n    float4 _171 = float4(_302, 1.0f);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -mul(_171, _131_fa_light_vp).z;\n    fa_pre_r0 = float3(_131_fa_light_vp[0].x, _131_fa_light_vp[1].x, _131_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131_fa_light_vp[0].y, _131_fa_light_vp[1].y, _131_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131_fa_light_vp[0].z, _131_fa_light_vp[1].z, _131_fa_light_vp[2].z);\n    gl_Position = mul(_171, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _787 = base_t;\n    _787.x = _225.x;\n    _787.y = _225.y;\n    _787.z = _225.z;\n    base_t = _787;\n    float4 _241 = (_787 * _213_fa_base_color) * i.vertex_color;\n    float3 _750 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _795 = _279;\n        _795.x = _284.x;\n        _795.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _795;\n        _750 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _798 = mrt;\n    _798.x = _313.x;\n    _798.y = _313.y;\n    _798.z = _313.z;\n    mrt = _798;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _755 = _213_fa_layers_a.x;\n    float _756 = _213_fa_layers_a.y;\n    float _759 = _213_fa_layers_a.z;\n    float _758 = _213_fa_layers_b.w;\n    float _761 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _755 *= _355.y;\n            _756 *= _355.z;\n            _758 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _759 *= mrt.x;\n            _761 *= mrt.w;\n        }\n    }\n    Surface _780 = { _241.xyz, _241.w, _750, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _755, _756, _213_fa_layers_b.xyz, _758, _759, _213_fa_layers_a.w, _761, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _780;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _661 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _661 = -_661;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _674 = { fa_world_pos, _661, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _674;\n    SurfaceInput _682 = { fa_world_pos, _661, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _682;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _416 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _416;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _423 = _273.world_pos;\n    float4 _284 = float4(_423, 1.0f);\n    fa_world_pos = _423;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -mul(_284, _136_fa_light_vp).z;\n    fa_pre_r0 = float3(_136_fa_light_vp[0].x, _136_fa_light_vp[1].x, _136_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136_fa_light_vp[0].y, _136_fa_light_vp[1].y, _136_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136_fa_light_vp[0].z, _136_fa_light_vp[1].z, _136_fa_light_vp[2].z);\n    gl_Position = mul(_284, _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _787 = base_t;\n    _787.x = _225.x;\n    _787.y = _225.y;\n    _787.z = _225.z;\n    base_t = _787;\n    float4 _241 = (_787 * _213_fa_base_color) * i.vertex_color;\n    float3 _750 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _795 = _279;\n        _795.x = _284.x;\n        _795.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _795;\n        _750 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _798 = mrt;\n    _798.x = _313.x;\n    _798.y = _313.y;\n    _798.z = _313.z;\n    mrt = _798;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _755 = _213_fa_layers_a.x;\n    float _756 = _213_fa_layers_a.y;\n    float _759 = _213_fa_layers_a.z;\n    float _758 = _213_fa_layers_b.w;\n    float _761 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _755 *= _355.y;\n            _756 *= _355.z;\n            _758 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _759 *= mrt.x;\n            _761 *= mrt.w;\n        }\n    }\n    Surface _780 = { _241.xyz, _241.w, _750, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _755, _756, _213_fa_layers_b.xyz, _758, _759, _213_fa_layers_a.w, _761, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _780;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _661 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _661 = -_661;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _674 = { fa_world_pos, _661, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _674;\n    SurfaceInput _682 = { fa_world_pos, _661, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _682;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
