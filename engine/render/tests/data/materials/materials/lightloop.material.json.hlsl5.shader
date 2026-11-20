{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "7cd31c28ac6572768802838498bbbd3180b96e0a1bb1bab7ad49d1d6af9d528c",
  "slang": "hlsl5",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _261 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _261;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _268 = _160.world_pos;\n    fa_world_pos = _268;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_268, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _1938[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\nstatic const LightSample _3774 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, 0 };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _443_fa_camera_pos : packoffset(c0);\n    float4 _443_fa_ambient : packoffset(c1);\n    float4 _443_fa_base_color : packoffset(c2);\n    float4 _443_fa_emissive : packoffset(c3);\n    float4 _443_fa_model_emissive : packoffset(c4);\n    float4 _443_fa_pbr : packoffset(c5);\n    float4 _443_fa_maps : packoffset(c6);\n    float4 _443_fa_fog : packoffset(c7);\n    float4 _443_fa_fog_b : packoffset(c8);\n    float4 _443_fa_fog_c : packoffset(c9);\n    float4 _443_fa_counts : packoffset(c10);\n    float4 _443_fa_env_sky : packoffset(c11);\n    float4 _443_fa_env_horizon : packoffset(c12);\n    float4 _443_fa_time : packoffset(c13);\n    float4 _443_fa_cl_vpx : packoffset(c14);\n    float4 _443_fa_cl_vpy : packoffset(c15);\n    float4 _443_fa_cl_vpw : packoffset(c16);\n    float4 _443_fa_cl_fwd : packoffset(c17);\n    float4 _443_fa_cl_grid : packoffset(c18);\n    float4 _443_fa_cl_info : packoffset(c19);\n    float4 _443_fa_layers_a : packoffset(c20);\n    float4 _443_fa_layers_b : packoffset(c21);\n    float4 _443_fa_layers_c : packoffset(c22);\n    float4 _443_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _679_fa_shadow_mat[4] : packoffset(c0);\n    float4 _679_fa_shadow_rect[4] : packoffset(c16);\n    float4 _679_fa_shadow_info[4] : packoffset(c20);\n    float4 _679_fa_shadow_split : packoffset(c24);\n    float4 _679_fa_shadow_cfg : packoffset(c25);\n    float4 _679_fa_shadow_bias : packoffset(c26);\n    float4 _679_fa_shadow_eye : packoffset(c27);\n    float4 _679_fa_shadow_fwd : packoffset(c28);\n    float4 _679_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _2690_dark : packoffset(c0);\n    float _2690_fa_pad0 : packoffset(c0.y);\n    float _2690_fa_pad1 : packoffset(c0.z);\n    float _2690_fa_pad2 : packoffset(c0.w);\n    float _2690_skyAmount : packoffset(c1);\n    float _2690_fa_pad3 : packoffset(c1.y);\n    float _2690_fa_pad4 : packoffset(c1.z);\n    float _2690_fa_pad5 : packoffset(c1.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _448 = _443_fa_cl_info.x < 0.0f;\n    bool _455;\n    if (!_448)\n    {\n        _455 = _443_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _455 = _448;\n    }\n    bool _463;\n    if (!_455)\n    {\n        _463 = _443_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _463 = _455;\n    }\n    bool _470;\n    if (!_463)\n    {\n        _470 = _443_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _470 = _463;\n    }\n    bool _477;\n    if (!_470)\n    {\n        _477 = _443_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _477 = _470;\n    }\n    if (_477)\n    {\n        return int2(0, 0);\n    }\n    float4 _487 = float4(world_pos, 1.0f);\n    float _494 = dot(_443_fa_cl_vpw, _487);\n    if (!(_494 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _516 = float2(dot(_443_fa_cl_vpx, _487), dot(_443_fa_cl_vpy, _487)) / _494.xx;\n    int _520 = int(_443_fa_cl_grid.x);\n    int _524 = int(_443_fa_cl_grid.y);\n    int param = (int(_443_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_443_fa_cl_fwd.xyz, world_pos) + _443_fa_cl_fwd.w, _443_fa_cl_grid.w) / _443_fa_cl_grid.w) * _443_fa_cl_grid.z)), 0, int(_443_fa_cl_info.y) - 1) * _524) + clamp(int(floor(((_516.y * 0.5f) + 0.5f) * _443_fa_cl_grid.y)), 0, _524 - 1)) * _520)) + clamp(int(floor(((_516.x * 0.5f) + 0.5f) * _443_fa_cl_grid.x)), 0, _520 - 1);\n    float4 _595 = fa_light_texel(param);\n    return int2(int(_595.x), int(_595.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_443_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2486 = fa_cluster_lookup(param);\n    fa_cl_slot = _2486.x;\n    fa_cl_local = _2486.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _2762 = fa_linear_to_srgb(param);\n        c = _2762;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _2770 = fa_srgb_to_linear(param_1);\n            c = _2770;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _223;\n    if (i.front_facing)\n    {\n        _223 = i.world_normal;\n    }\n    else\n    {\n        _223 = -i.world_normal;\n    }\n    float3 _247 = normalize(i.world_tangent.xyz - (_223 * dot(_223, i.world_tangent.xyz)));\n    float3 _275 = normalize(((_247 * m.x) + ((cross(_223, _247) * i.world_tangent.w) * m.y)) + (_223 * m.z));\n    float3 _278;\n    if (i.front_facing)\n    {\n        _278 = _275;\n    }\n    else\n    {\n        _278 = -_275;\n    }\n    return _278;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _443_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2801 = fa_tex_fix(param_2, param_3);\n    float4 _3746 = base_t;\n    _3746.x = _2801.x;\n    _3746.y = _2801.y;\n    _3746.z = _2801.z;\n    base_t = _3746;\n    float4 _2815 = (_3746 * _443_fa_base_color) * i.vertex_color;\n    float3 _3648 = i.world_normal;\n    if (_443_fa_maps.z > 0.5f)\n    {\n        float param_4 = _443_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2847 = fa_tex_fix(param_6, param_7);\n        float3 _2851 = (_2847 * 2.0f) - 1.0f.xxx;\n        float2 _2856 = _2851.xy * _443_fa_maps.x;\n        float3 _3754 = _2851;\n        _3754.x = _2856.x;\n        _3754.y = _2856.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3754;\n        _3648 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _443_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2885 = fa_tex_fix(param_12, param_13);\n    float4 _3757 = mrt;\n    _3757.x = _2885.x;\n    _3757.y = _2885.y;\n    _3757.z = _2885.z;\n    mrt = _3757;\n    float4 _2913 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _443_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _2913.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2925 = fa_tex_fix(param_16, param_17);\n    float param_18 = _443_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2955 = fa_tex_fix(param_20, param_21);\n    float _3653 = _443_fa_layers_a.x;\n    float _3654 = _443_fa_layers_a.y;\n    float _3657 = _443_fa_layers_a.z;\n    float _3656 = _443_fa_layers_b.w;\n    float _3659 = _443_fa_layers_c.x;\n    if (_443_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_443_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _3653 *= _2925.y;\n            _3654 *= _2925.z;\n            _3656 *= _2913.w;\n        }\n        if (_443_fa_layers_c.z > 1.5f)\n        {\n            _3657 *= mrt.x;\n            _3659 *= mrt.w;\n        }\n    }\n    Surface _3678 = { _2815.xyz, _2815.w, _3648, clamp(_443_fa_pbr.x * _2885.z, 0.0f, 1.0f), clamp(_443_fa_pbr.y * _2885.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_443_fa_maps.y * (_2925.x - 1.0f)), _443_fa_emissive.xyz + (_443_fa_model_emissive.xyz * _2955), _3653, _3654, _443_fa_layers_b.xyz, _3656, _3657, _443_fa_layers_a.w, _3659, _443_fa_layers_c.y, _443_fa_layers_d.xyz };\n    return _3678;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return _3774;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_443_fa_cl_info.x) + int(_443_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _315 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _321 = fa_light_texel(param_1);\n    float _324 = _321.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _331 = _324 < 0.5f;\n    float3 l;\n    if (_331)\n    {\n        l = normalize(_315.xyz);\n    }\n    else\n    {\n        float3 _343 = _315.xyz - world_pos;\n        float _345 = length(_343);\n        dist = _345;\n        l = _343 / max(_345, 9.9999997473787516355514526367188e-05f).xxx;\n        float _360 = _345 / max(_315.w, 0.001000000047497451305389404296875f);\n        float _366 = clamp(1.0f - (_360 * _360), 0.0f, 1.0f);\n        atten = _366 * _366;\n        if (_324 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _380 = fa_light_texel(param_2);\n            float _390 = _380.w;\n            int param_3 = (li * 4) + 3;\n            float4 _397 = fa_light_texel(param_3);\n            float _398 = _397.x;\n            float cos_inner = _398;\n            if (_398 > 1.5f)\n            {\n                cos_inner = lerp(_390, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_390, cos_inner, dot(-l, normalize(_380.xyz)));\n        }\n    }\n    int _429;\n    if (_331)\n    {\n        _429 = 0;\n    }\n    else\n    {\n        _429 = (_324 > 1.5f) ? 2 : 1;\n    }\n    LightSample _3497 = { l, _321.xyz * atten, atten, 1.0f, dist, _429 };\n    return _3497;\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _2600 = n < 0;\n    bool _2607;\n    if (!_2600)\n    {\n        _2607 = n >= fa_light_count();\n    }\n    else\n    {\n        _2607 = _2600;\n    }\n    if (_2607)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    return fa_light_sample(param_1, param_2);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _669;\n    if (i == 0)\n    {\n        _669 = _679_fa_shadow_split.x;\n    }\n    else\n    {\n        float _685;\n        if (i == 1)\n        {\n            _685 = _679_fa_shadow_split.y;\n        }\n        else\n        {\n            float _693;\n            if (i == 2)\n            {\n                _693 = _679_fa_shadow_split.z;\n            }\n            else\n            {\n                _693 = _679_fa_shadow_split.w;\n            }\n            _685 = _693;\n        }\n        _669 = _685;\n    }\n    return _669;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _726 = fa_shadow_depth(param, param_1);\n    float _730;\n    if (conv.x < 0.5f)\n    {\n        _730 = _726;\n    }\n    else\n    {\n        _730 = (conv.y * conv.z) / (conv.z - (_726 * (conv.z - conv.y)));\n    }\n    return _730;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _657 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_657), sin(_657)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _776 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _790 = clamp((k * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _776;\n            float2 _809 = fa_shadow_vogel(param_3, param_4, param_5) * _790;\n            float2 param_6 = uv + (_809 * _679_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _821 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_821 < (zr - (length(_809) * plane)))\n            {\n                sum += _821;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0f) * unit) * k) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _865 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _865; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _865;\n        float param_11 = _776;\n        float2 _884 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_884 * _679_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_884) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_865);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _926 = max(_679_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _931 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _937 = sqrt(1.0f - (_931 * _931));\n    float _945 = min(_937 / max(_931, 0.20000000298023223876953125f), 4.0f);\n    float _950;\n    if (_679_fa_shadow_bias.y > 0.0f)\n    {\n        _950 = _679_fa_shadow_bias.y;\n    }\n    else\n    {\n        _950 = 1.5f * _679_fa_shadow_info[ci].x;\n    }\n    float4 _975 = mul(float4(world + (n * (_950 * _937)), 1.0f), _679_fa_shadow_mat[ci]);\n    float _982 = _975.x;\n    bool _985 = _982 < _679_fa_shadow_rect[ci].x;\n    bool _994;\n    if (!_985)\n    {\n        _994 = _982 > _679_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _994 = _985;\n    }\n    bool _1003;\n    if (!_994)\n    {\n        _1003 = _975.y < _679_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1003 = _994;\n    }\n    bool _1012;\n    if (!_1003)\n    {\n        _1012 = _975.y > _679_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1012 = _1003;\n    }\n    bool _1019;\n    if (!_1012)\n    {\n        _1019 = _975.z > 1.0f;\n    }\n    else\n    {\n        _1019 = _1012;\n    }\n    if (_1019)\n    {\n        return -1.0f;\n    }\n    float _1028;\n    if (_679_fa_shadow_bias.x > 0.0f)\n    {\n        _1028 = _679_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1028 = 1.5f * _679_fa_shadow_info[ci].x;\n    }\n    float2 param = _975.xy;\n    float4 param_1 = _679_fa_shadow_rect[ci];\n    float param_2 = _975.z - ((_1028 * (1.0f + (0.5f * _945))) / _926);\n    float param_3 = _679_fa_shadow_info[ci].x;\n    float param_4 = _926;\n    float param_5 = _926 * 0.25f;\n    float param_6 = ((_679_fa_shadow_info[ci].x * min(_945, 3.0f)) * 0.5f) / _926;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_679_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _679_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_443_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1422 = int(_679_fa_shadow_cfg.x + 0.5f);\n    if (_1422 < 1)\n    {\n        return 1.0f;\n    }\n    float _1438 = dot(world - _679_fa_shadow_eye.xyz, _679_fa_shadow_fwd.xyz);\n    int param = _1422 - 1;\n    if (_1438 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1450 = _1422 > 1;\n    bool _1457;\n    if (_1450)\n    {\n        _1457 = _1438 > _679_fa_shadow_split.x;\n    }\n    else\n    {\n        _1457 = _1450;\n    }\n    if (_1457)\n    {\n        ci = 1;\n    }\n    bool _1461 = _1422 > 2;\n    bool _1468;\n    if (_1461)\n    {\n        _1468 = _1438 > _679_fa_shadow_split.y;\n    }\n    else\n    {\n        _1468 = _1461;\n    }\n    if (_1468)\n    {\n        ci = 2;\n    }\n    bool _1472 = _1422 > 3;\n    bool _1479;\n    if (_1472)\n    {\n        _1479 = _1438 > _679_fa_shadow_split.z;\n    }\n    else\n    {\n        _1479 = _1472;\n    }\n    if (_1479)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1422)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1505 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1505;\n        if (_1505 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_679_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1530;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1530 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1530 = _679_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1549 = _679_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1530, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1560 = clamp((_1438 - (fa_shadow_split_at(param_7) - _1549)) / _1549, 0.0f, 1.0f);\n        if (_1560 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1422)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1581 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1581;\n                if (_1581 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1560);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _1087 = _443_fa_pbr.z < 0.5f;\n    bool _1095;\n    if (!_1087)\n    {\n        _1095 = _679_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _1095 = _1087;\n    }\n    if (_1095)\n    {\n        return 1.0f;\n    }\n    int param = (int(_679_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _1108 = fa_light_texel(param);\n    float _1109 = _1108.x;\n    if (_1109 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _1118 = int(_1109 + 0.5f);\n    int param_1 = _1118;\n    float4 _1122 = fa_light_texel(param_1);\n    int param_2 = _1118 + 1;\n    float4 _1127 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _1130 = _1122.y;\n    if (_1130 > 0.0f)\n    {\n        float _1147 = 1.0f - smoothstep(0.75f * _1130, _1130, length(world - _679_fa_shadow_eye.xyz));\n        fade = _1147;\n        if (_1147 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_1122.x > 1.5f)\n    {\n        int param_3 = li * 4;\n        float3 _1166 = world - fa_light_texel(param_3).xyz;\n        float3 _1169 = abs(_1166);\n        float _1171 = _1169.x;\n        float _1173 = _1169.y;\n        bool _1174 = _1171 >= _1173;\n        bool _1182;\n        if (_1174)\n        {\n            _1182 = _1171 >= _1169.z;\n        }\n        else\n        {\n            _1182 = _1174;\n        }\n        int _1183;\n        if (_1182)\n        {\n            _1183 = (_1166.x > 0.0f) ? 0 : 1;\n        }\n        else\n        {\n            int _1196;\n            if (_1173 >= _1169.z)\n            {\n                _1196 = (_1166.y > 0.0f) ? 2 : 3;\n            }\n            else\n            {\n                _1196 = (_1166.z > 0.0f) ? 4 : 5;\n            }\n            _1183 = _1196;\n        }\n        face = _1183;\n    }\n    int _1215 = (_1118 + 2) + (face * 6);\n    int param_4 = _1215;\n    int param_5 = _1215 + 1;\n    int param_6 = _1215 + 3;\n    float4 _1229 = fa_light_texel(param_6);\n    int param_7 = _1215 + 4;\n    float4 _1234 = fa_light_texel(param_7);\n    int param_8 = _1215 + 5;\n    float4 _1239 = fa_light_texel(param_8);\n    float _1251 = _1239.x * max(dot(_1229, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _1256 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1262 = sqrt(1.0f - (_1256 * _1256));\n    float _1268 = min(_1262 / max(_1256, 0.20000000298023223876953125f), 4.0f);\n    float _1271 = _1127.y;\n    float _1273;\n    if (_1271 > 0.0f)\n    {\n        _1273 = _1271;\n    }\n    else\n    {\n        _1273 = 1.5f * _1251;\n    }\n    float4 _1293 = float4(world + (n * (_1273 * _1262)), 1.0f);\n    float _1297 = dot(_1229, _1293);\n    float _1300 = _1239.y;\n    if (_1297 < _1300)\n    {\n        return 1.0f;\n    }\n    float2 _1315 = float2(dot(fa_light_texel(param_4), _1293), dot(fa_light_texel(param_5), _1293)) / _1297.xx;\n    float _1317 = _1315.x;\n    bool _1320 = _1317 < _1234.x;\n    bool _1329;\n    if (!_1320)\n    {\n        _1329 = _1317 > _1234.z;\n    }\n    else\n    {\n        _1329 = _1320;\n    }\n    bool _1338;\n    if (!_1329)\n    {\n        _1338 = _1315.y < _1234.y;\n    }\n    else\n    {\n        _1338 = _1329;\n    }\n    bool _1347;\n    if (!_1338)\n    {\n        _1347 = _1315.y > _1234.w;\n    }\n    else\n    {\n        _1347 = _1338;\n    }\n    if (_1347)\n    {\n        return 1.0f;\n    }\n    float _1353 = _1127.x;\n    float _1355;\n    if (_1353 > 0.0f)\n    {\n        _1355 = _1353;\n    }\n    else\n    {\n        _1355 = 1.5f * _1251;\n    }\n    float2 param_9 = _1315;\n    float4 param_10 = _1234;\n    float param_11 = _1297 - (_1355 * (1.0f + (0.5f * _1268)));\n    float param_12 = _1251;\n    float param_13 = 1.0f;\n    float param_14 = _1239.z * 0.25f;\n    float param_15 = (_1251 * min(_1268, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _1300, _1239.z);\n    int param_17 = int(_1122.z + 0.5f);\n    float param_18 = _1122.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _2514 = fa_light_sample(param, param_1);\n    float3 _3624 = _2514.direction;\n    float3 _3619 = _2514.color;\n    float _3626 = _2514.attenuation;\n    float _3621 = _2514.shadow;\n    int _3629 = _2514.type;\n    if ((_3629 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _3624;\n        float _2528 = fa_shadow_factor(param_2, param_3);\n        _3621 = _2528;\n        _3619 *= _2528;\n    }\n    else\n    {\n        bool _2539 = _3629 != 0;\n        bool _2545;\n        if (_2539)\n        {\n            _2545 = _3626 > 0.0f;\n        }\n        else\n        {\n            _2545 = _2539;\n        }\n        if (_2545)\n        {\n            int param_4 = li;\n            float3 param_5 = world_pos;\n            float3 param_6 = gn;\n            float3 param_7 = _3624;\n            float _2557 = fa_shadow_local(param_4, param_5, param_6, param_7);\n            _3621 = _2557;\n            _3619 *= _2557;\n        }\n    }\n    LightSample _3636 = { _3624, _3619, _3626, _3621, _2514._distance, _3629 };\n    return _3636;\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _2574 = n < 0;\n    bool _2581;\n    if (!_2574)\n    {\n        _2581 = n >= fa_light_count();\n    }\n    else\n    {\n        _2581 = _2574;\n    }\n    if (_2581)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    return fa_light_shadowed(param_1, param_2, param_3);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1863 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _1871 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _1874 = int(_1863);\n    int _1877 = int(_1871);\n    float _1887 = _1871 - float(_1877);\n    int _1943 = (_1874 * 9) + _1877;\n    int _1963 = ((_1874 + 1) * 9) + _1877;\n    return lerp(lerp(_1938[_1943], _1938[_1943 + 1], _1887), lerp(_1938[_1963], _1938[_1963 + 1], _1887), _1863 - float(_1874));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _3498 = false;\n    float _3499 = 1.0f;\n    float _3500 = 1.0f;\n    float _3501 = 1.0f;\n    float _3502 = 0.0f;\n    float _3503 = 0.0f;\n    float _3504 = 0.0f;\n    float _3505 = 0.0f;\n    float _3507 = 1.0f;\n    bool _3508 = false;\n    float3 _3509 = 0.0f.xxx;\n    float _3510 = 1.0f;\n    float _3511 = 1.0f;\n    float _3512 = 1.0f;\n    float _3513 = 0.0f;\n    float _3514 = 0.0f;\n    float3 _3515 = float3(1.0f, 0.0f, 0.0f);\n    float3 _3516 = float3(0.0f, 0.0f, 1.0f);\n    float _3517 = 1.0f;\n    float _3518 = 1.0f;\n    float _2016 = clamp(s.specular, 0.0f, 1.0f);\n    float _2020 = clamp(s.ior, 1.0f, 3.0f);\n    bool _2025 = (_2016 != 1.0f) || (_2020 != 1.5f);\n    bool _2035;\n    if (!_2025)\n    {\n        _2035 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _2035 = _2025;\n    }\n    if (_2035)\n    {\n        float _2043 = (_2020 - 1.0f) / (_2020 + 1.0f);\n        f0 = lerp(min((_2043 * _2043).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _2016, s.albedo, metallic.xxx);\n        _3499 = lerp(_2016, 1.0f, metallic);\n        _3498 = true;\n    }\n    float _2071 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_2071 > 0.0f)\n    {\n        float _2079 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _3502 = _2071;\n        _3503 = _2079;\n        float _2086 = _2079 * _2079;\n        _3504 = _2086;\n        _3505 = _2086 * _2086;\n        float _2098 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _3507 = _2098;\n        _3500 = 1.0f - (_2071 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _2098, 0.0f, 1.0f), 5.0f))));\n        _3498 = true;\n    }\n    float3 _2118 = max(s.sheen_color, 0.0f.xxx);\n    float _2127 = max(_2118.x, max(_2118.y, _2118.z));\n    if (_2127 > 0.0f)\n    {\n        float _2135 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _3508 = true;\n        _3509 = _2118;\n        _3510 = _2135;\n        _3511 = _2135 * _2135;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _2135;\n        float _2152 = fa_sheen_albedo(param, param_1);\n        _3513 = _2152;\n        _3512 = 1.0f - min(_2127 * _2152, 1.0f);\n        _3498 = true;\n    }\n    _3501 = _3500 * _3512;\n    float _2171 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_2171 != 0.0f)\n    {\n        float3 _2186 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2186;\n        if (dot(_2186, _2186) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _2200 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_2200.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _2200.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _2200.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _2204 = t;\n        float3 _2205 = normalize(_2204);\n        t = _2205;\n        float3 _2230 = normalize((_2205 * cos(s.anisotropy_rotation)) + ((cross(n, _2205) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _3515 = _2230;\n        _3516 = cross(n, _2230);\n        float _2240 = roughness * roughness;\n        float _2246 = lerp(_2240, 1.0f, _2171 * _2171);\n        bool _2248 = _2171 > 0.0f;\n        _3517 = _2248 ? _2246 : _2240;\n        _3518 = _2248 ? _2240 : _2246;\n        _3514 = _2171;\n        _3498 = true;\n    }\n    FaLayers _3540 = { _3498, _3499, _3500, _3501, _3502, _3503, _3504, _3505, i.world_normal, _3507, _3508, _3509, _3510, _3511, _3512, _3513, _3514, _3515, _3516, _3517, _3518 };\n    return _3540;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _1795 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _1798 = _1795.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_1798 * _1798, exp2((-9.27999973297119140625f) * ndv)) * _1798) + _1795.y)) + _1795.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_443_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _443_fa_env_horizon.w).xyz;\n    }\n    float _1718 = rough * rough;\n    float _1748 = 0.60000002384185791015625f * _1718;\n    return lerp(lerp(_443_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_443_fa_env_horizon.xyz, _443_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _1718)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _1748, 0.0500000007450580596923828125f + _1748, d.y).xxx), ((_443_fa_env_sky.xyz + _443_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_1718 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _2281;\n        if (L.aniso >= 0.0f)\n        {\n            _2281 = L.b;\n        }\n        else\n        {\n            _2281 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_2281, v), _2281), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _2314 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _2314.x) + (L.f90.xxx * _2314.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2369 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _2369.x) + _2369.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1837 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1837.x) + _1837.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _2408 = clamp(s.metallic, 0.0f, 1.0f);\n    float _2412 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _2419 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _2408.xxx);\n    float3 f0 = _2419;\n    float3 _2423 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _2423;\n    float3 param_3 = i.view_dir;\n    float param_4 = _2408;\n    float param_5 = _2412;\n    float3 param_6 = _2419;\n    FaLayers _2440 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_2440.on)\n    {\n        FaLayers param_7 = _2440;\n        float3 param_8 = _2423;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _2412;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _2423;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _2412;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0f;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _2647 = dot(fa_light_unshadowed(param, param_1).color, float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));\n        if (_2647 > bestPower)\n        {\n            bestPower = _2647;\n            best = n;\n        }\n    }\n    float3 lit = (_443_fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _2676 = fa_light(param_2, param_3);\n        float _2684;\n        if (dot(s.normal, _2676.direction) > 0.5f)\n        {\n            _2684 = 1.0f;\n        }\n        else\n        {\n            _2684 = _2690_dark;\n        }\n        lit += ((s.albedo * _2676.color) * _2684);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * _2690_skyAmount);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_679_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1605 = int(_679_fa_shadow_cfg.x + 0.5f);\n    float _1615 = dot(world - _679_fa_shadow_eye.xyz, _679_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1620 = _1605 > 0;\n    bool _1629;\n    if (_1620)\n    {\n        int param = _1605 - 1;\n        _1629 = _1615 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1629 = _1620;\n    }\n    if (_1629)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1636 = _1605 > 1;\n        bool _1643;\n        if (_1636)\n        {\n            _1643 = _1615 > _679_fa_shadow_split.x;\n        }\n        else\n        {\n            _1643 = _1636;\n        }\n        if (_1643)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1649 = _1605 > 2;\n        bool _1656;\n        if (_1649)\n        {\n            _1656 = _1615 > _679_fa_shadow_split.y;\n        }\n        else\n        {\n            _1656 = _1649;\n        }\n        if (_1656)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1662 = _1605 > 3;\n        bool _1669;\n        if (_1662)\n        {\n            _1669 = _1615 > _679_fa_shadow_split.z;\n        }\n        else\n        {\n            _1669 = _1662;\n        }\n        if (_1669)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _3372 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3372 = -_3372;\n    }\n    float3 _3076 = normalize(_443_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _3385 = { fa_world_pos, _3372, fa_world_tangent, fa_uv, fa_vertex_color, _3076, gl_FrontFacing };\n    SurfaceInput param_1 = _3385;\n    Surface _3084 = fa_standard_surface(param_1);\n    float3 _3403 = _3084.albedo;\n    float _3404 = _3084.alpha;\n    float3 _3405 = _3084.normal;\n    float _3406 = _3084.metallic;\n    float _3407 = _3084.roughness;\n    float _3408 = _3084.occlusion;\n    float3 _3409 = _3084.emission;\n    float _3410 = _3084.clearcoat;\n    float _3411 = _3084.clearcoat_roughness;\n    float3 _3412 = _3084.sheen_color;\n    float _3413 = _3084.sheen_roughness;\n    float _3414 = _3084.anisotropy;\n    float _3415 = _3084.anisotropy_rotation;\n    float _3416 = _3084.specular;\n    float _3417 = _3084.ior;\n    float3 _3418 = _3084.specular_color;\n    SurfaceInput _3393 = { fa_world_pos, _3372, fa_world_tangent, fa_uv, fa_vertex_color, _3076, gl_FrontFacing };\n    SurfaceInput param_2 = _3393;\n    Surface param_3 = _3084;\n    surface(param_2, param_3);\n    _3403 = param_3.albedo;\n    _3404 = param_3.alpha;\n    _3405 = param_3.normal;\n    _3406 = param_3.metallic;\n    _3407 = param_3.roughness;\n    _3408 = param_3.occlusion;\n    _3409 = param_3.emission;\n    _3410 = param_3.clearcoat;\n    _3411 = param_3.clearcoat_roughness;\n    _3412 = param_3.sheen_color;\n    _3413 = param_3.sheen_roughness;\n    _3414 = param_3.anisotropy;\n    _3415 = param_3.anisotropy_rotation;\n    _3416 = param_3.specular;\n    _3417 = param_3.ior;\n    _3418 = param_3.specular_color;\n    float3 result;\n    if (_443_fa_emissive.w > 0.5f)\n    {\n        result = _3403;\n    }\n    else\n    {\n        float3 _3105 = _3405;\n        float3 _3106 = normalize(_3105);\n        _3405 = _3106;\n        SurfaceInput _3401 = { fa_world_pos, _3372, fa_world_tangent, fa_uv, fa_vertex_color, _3076, gl_FrontFacing };\n        SurfaceInput param_4 = _3401;\n        Surface _3484 = { _3403, _3404, _3106, _3406, _3407, _3408, _3409, _3410, _3411, _3412, _3413, _3414, _3415, _3416, _3417, _3418 };\n        Surface param_5 = _3484;\n        result = lighting(param_4, param_5);\n    }\n    float3 _3121 = result;\n    float3 _3122 = _3121 + _3409;\n    result = _3122;\n    float3 param_6 = _3122;\n    float3 param_7 = fa_world_pos;\n    result = fa_shadow_debug(param_6, param_7);\n    bool _3131 = _443_fa_fog.w > 0.0f;\n    bool _3138;\n    if (!_3131)\n    {\n        _3138 = _443_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _3138 = _3131;\n    }\n    if (_3138)\n    {\n        float3 _3147 = fa_world_pos - _443_fa_camera_pos.xyz;\n        float _3153 = dot(_3147, _443_fa_fog_c.xyz);\n        bool _3157 = _443_fa_fog_c.w > 0.5f;\n        float _3158;\n        if (_3157)\n        {\n            _3158 = _3153;\n        }\n        else\n        {\n            _3158 = length(_3147);\n        }\n        float _3170 = _3158 - _443_fa_fog_b.x;\n        if (_3170 > 0.0f)\n        {\n            float _3179 = _443_fa_fog.w * _3170;\n            float tau = _3179 * _3179;\n            if (_443_fa_fog_b.y > 0.0f)\n            {\n                float _3195;\n                if (_3157)\n                {\n                    _3195 = fa_world_pos.y - (_443_fa_fog_c.y * _3153);\n                }\n                else\n                {\n                    _3195 = _443_fa_camera_pos.y;\n                }\n                float _3216 = lerp(_3195, fa_world_pos.y, clamp(_443_fa_fog_b.x / _3158, 0.0f, 1.0f));\n                float _3220 = fa_world_pos.y - _3216;\n                float _3225 = _3216 - _443_fa_fog_b.z;\n                float _3230 = fa_world_pos.y - _443_fa_fog_b.z;\n                bool _3233 = _3225 <= 0.0f;\n                bool _3234 = !_3233;\n                bool _3240;\n                if (_3234)\n                {\n                    _3240 = _443_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3240 = _3233;\n                }\n                float _3241;\n                if (_3240)\n                {\n                    _3241 = _443_fa_fog_b.y;\n                }\n                else\n                {\n                    _3241 = _443_fa_fog_b.y * exp(-min(_443_fa_fog_b.w * _3225, 80.0f));\n                }\n                bool _3268;\n                if (_3234)\n                {\n                    _3268 = _443_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3268 = _3233;\n                }\n                float _3269;\n                if (_3268)\n                {\n                    _3269 = _443_fa_fog_b.y * _3225;\n                }\n                else\n                {\n                    _3269 = (_443_fa_fog_b.y * (1.0f - exp(-min(_443_fa_fog_b.w * _3225, 80.0f)))) / _443_fa_fog_b.w;\n                }\n                bool _3294 = _3230 <= 0.0f;\n                bool _3301;\n                if (!_3294)\n                {\n                    _3301 = _443_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3301 = _3294;\n                }\n                float _3302;\n                if (_3301)\n                {\n                    _3302 = _443_fa_fog_b.y * _3230;\n                }\n                else\n                {\n                    _3302 = (_443_fa_fog_b.y * (1.0f - exp(-min(_443_fa_fog_b.w * _3230, 80.0f)))) / _443_fa_fog_b.w;\n                }\n                float _3329;\n                if (abs(_3220) < 0.001000000047497451305389404296875f)\n                {\n                    _3329 = _3241;\n                }\n                else\n                {\n                    _3329 = (_3302 - _3269) / _3220;\n                }\n                tau += (_3170 * max(_3329, 0.0f));\n            }\n            result = lerp(result, _443_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _3404);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_443",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_679",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_2690",
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 7,
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _1938[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\nstatic const LightSample _3774 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, 0 };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _443_fa_camera_pos : packoffset(c0);\n    float4 _443_fa_ambient : packoffset(c1);\n    float4 _443_fa_base_color : packoffset(c2);\n    float4 _443_fa_emissive : packoffset(c3);\n    float4 _443_fa_model_emissive : packoffset(c4);\n    float4 _443_fa_pbr : packoffset(c5);\n    float4 _443_fa_maps : packoffset(c6);\n    float4 _443_fa_fog : packoffset(c7);\n    float4 _443_fa_fog_b : packoffset(c8);\n    float4 _443_fa_fog_c : packoffset(c9);\n    float4 _443_fa_counts : packoffset(c10);\n    float4 _443_fa_env_sky : packoffset(c11);\n    float4 _443_fa_env_horizon : packoffset(c12);\n    float4 _443_fa_time : packoffset(c13);\n    float4 _443_fa_cl_vpx : packoffset(c14);\n    float4 _443_fa_cl_vpy : packoffset(c15);\n    float4 _443_fa_cl_vpw : packoffset(c16);\n    float4 _443_fa_cl_fwd : packoffset(c17);\n    float4 _443_fa_cl_grid : packoffset(c18);\n    float4 _443_fa_cl_info : packoffset(c19);\n    float4 _443_fa_layers_a : packoffset(c20);\n    float4 _443_fa_layers_b : packoffset(c21);\n    float4 _443_fa_layers_c : packoffset(c22);\n    float4 _443_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _679_fa_shadow_mat[4] : packoffset(c0);\n    float4 _679_fa_shadow_rect[4] : packoffset(c16);\n    float4 _679_fa_shadow_info[4] : packoffset(c20);\n    float4 _679_fa_shadow_split : packoffset(c24);\n    float4 _679_fa_shadow_cfg : packoffset(c25);\n    float4 _679_fa_shadow_bias : packoffset(c26);\n    float4 _679_fa_shadow_eye : packoffset(c27);\n    float4 _679_fa_shadow_fwd : packoffset(c28);\n    float4 _679_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _2690_dark : packoffset(c0);\n    float _2690_fa_pad0 : packoffset(c0.y);\n    float _2690_fa_pad1 : packoffset(c0.z);\n    float _2690_fa_pad2 : packoffset(c0.w);\n    float _2690_skyAmount : packoffset(c1);\n    float _2690_fa_pad3 : packoffset(c1.y);\n    float _2690_fa_pad4 : packoffset(c1.z);\n    float _2690_fa_pad5 : packoffset(c1.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _448 = _443_fa_cl_info.x < 0.0f;\n    bool _455;\n    if (!_448)\n    {\n        _455 = _443_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _455 = _448;\n    }\n    bool _463;\n    if (!_455)\n    {\n        _463 = _443_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _463 = _455;\n    }\n    bool _470;\n    if (!_463)\n    {\n        _470 = _443_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _470 = _463;\n    }\n    bool _477;\n    if (!_470)\n    {\n        _477 = _443_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _477 = _470;\n    }\n    if (_477)\n    {\n        return int2(0, 0);\n    }\n    float4 _487 = float4(world_pos, 1.0f);\n    float _494 = dot(_443_fa_cl_vpw, _487);\n    if (!(_494 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _516 = float2(dot(_443_fa_cl_vpx, _487), dot(_443_fa_cl_vpy, _487)) / _494.xx;\n    int _520 = int(_443_fa_cl_grid.x);\n    int _524 = int(_443_fa_cl_grid.y);\n    int param = (int(_443_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_443_fa_cl_fwd.xyz, world_pos) + _443_fa_cl_fwd.w, _443_fa_cl_grid.w) / _443_fa_cl_grid.w) * _443_fa_cl_grid.z)), 0, int(_443_fa_cl_info.y) - 1) * _524) + clamp(int(floor(((_516.y * 0.5f) + 0.5f) * _443_fa_cl_grid.y)), 0, _524 - 1)) * _520)) + clamp(int(floor(((_516.x * 0.5f) + 0.5f) * _443_fa_cl_grid.x)), 0, _520 - 1);\n    float4 _595 = fa_light_texel(param);\n    return int2(int(_595.x), int(_595.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_443_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2486 = fa_cluster_lookup(param);\n    fa_cl_slot = _2486.x;\n    fa_cl_local = _2486.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _2762 = fa_linear_to_srgb(param);\n        c = _2762;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _2770 = fa_srgb_to_linear(param_1);\n            c = _2770;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _223;\n    if (i.front_facing)\n    {\n        _223 = i.world_normal;\n    }\n    else\n    {\n        _223 = -i.world_normal;\n    }\n    float3 _247 = normalize(i.world_tangent.xyz - (_223 * dot(_223, i.world_tangent.xyz)));\n    float3 _275 = normalize(((_247 * m.x) + ((cross(_223, _247) * i.world_tangent.w) * m.y)) + (_223 * m.z));\n    float3 _278;\n    if (i.front_facing)\n    {\n        _278 = _275;\n    }\n    else\n    {\n        _278 = -_275;\n    }\n    return _278;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _443_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2801 = fa_tex_fix(param_2, param_3);\n    float4 _3746 = base_t;\n    _3746.x = _2801.x;\n    _3746.y = _2801.y;\n    _3746.z = _2801.z;\n    base_t = _3746;\n    float4 _2815 = (_3746 * _443_fa_base_color) * i.vertex_color;\n    float3 _3648 = i.world_normal;\n    if (_443_fa_maps.z > 0.5f)\n    {\n        float param_4 = _443_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2847 = fa_tex_fix(param_6, param_7);\n        float3 _2851 = (_2847 * 2.0f) - 1.0f.xxx;\n        float2 _2856 = _2851.xy * _443_fa_maps.x;\n        float3 _3754 = _2851;\n        _3754.x = _2856.x;\n        _3754.y = _2856.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3754;\n        _3648 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _443_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2885 = fa_tex_fix(param_12, param_13);\n    float4 _3757 = mrt;\n    _3757.x = _2885.x;\n    _3757.y = _2885.y;\n    _3757.z = _2885.z;\n    mrt = _3757;\n    float4 _2913 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _443_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _2913.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2925 = fa_tex_fix(param_16, param_17);\n    float param_18 = _443_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2955 = fa_tex_fix(param_20, param_21);\n    float _3653 = _443_fa_layers_a.x;\n    float _3654 = _443_fa_layers_a.y;\n    float _3657 = _443_fa_layers_a.z;\n    float _3656 = _443_fa_layers_b.w;\n    float _3659 = _443_fa_layers_c.x;\n    if (_443_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_443_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _3653 *= _2925.y;\n            _3654 *= _2925.z;\n            _3656 *= _2913.w;\n        }\n        if (_443_fa_layers_c.z > 1.5f)\n        {\n            _3657 *= mrt.x;\n            _3659 *= mrt.w;\n        }\n    }\n    Surface _3678 = { _2815.xyz, _2815.w, _3648, clamp(_443_fa_pbr.x * _2885.z, 0.0f, 1.0f), clamp(_443_fa_pbr.y * _2885.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_443_fa_maps.y * (_2925.x - 1.0f)), _443_fa_emissive.xyz + (_443_fa_model_emissive.xyz * _2955), _3653, _3654, _443_fa_layers_b.xyz, _3656, _3657, _443_fa_layers_a.w, _3659, _443_fa_layers_c.y, _443_fa_layers_d.xyz };\n    return _3678;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return _3774;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_443_fa_cl_info.x) + int(_443_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _315 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _321 = fa_light_texel(param_1);\n    float _324 = _321.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _331 = _324 < 0.5f;\n    float3 l;\n    if (_331)\n    {\n        l = normalize(_315.xyz);\n    }\n    else\n    {\n        float3 _343 = _315.xyz - world_pos;\n        float _345 = length(_343);\n        dist = _345;\n        l = _343 / max(_345, 9.9999997473787516355514526367188e-05f).xxx;\n        float _360 = _345 / max(_315.w, 0.001000000047497451305389404296875f);\n        float _366 = clamp(1.0f - (_360 * _360), 0.0f, 1.0f);\n        atten = _366 * _366;\n        if (_324 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _380 = fa_light_texel(param_2);\n            float _390 = _380.w;\n            int param_3 = (li * 4) + 3;\n            float4 _397 = fa_light_texel(param_3);\n            float _398 = _397.x;\n            float cos_inner = _398;\n            if (_398 > 1.5f)\n            {\n                cos_inner = lerp(_390, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_390, cos_inner, dot(-l, normalize(_380.xyz)));\n        }\n    }\n    int _429;\n    if (_331)\n    {\n        _429 = 0;\n    }\n    else\n    {\n        _429 = (_324 > 1.5f) ? 2 : 1;\n    }\n    LightSample _3497 = { l, _321.xyz * atten, atten, 1.0f, dist, _429 };\n    return _3497;\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _2600 = n < 0;\n    bool _2607;\n    if (!_2600)\n    {\n        _2607 = n >= fa_light_count();\n    }\n    else\n    {\n        _2607 = _2600;\n    }\n    if (_2607)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    return fa_light_sample(param_1, param_2);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _669;\n    if (i == 0)\n    {\n        _669 = _679_fa_shadow_split.x;\n    }\n    else\n    {\n        float _685;\n        if (i == 1)\n        {\n            _685 = _679_fa_shadow_split.y;\n        }\n        else\n        {\n            float _693;\n            if (i == 2)\n            {\n                _693 = _679_fa_shadow_split.z;\n            }\n            else\n            {\n                _693 = _679_fa_shadow_split.w;\n            }\n            _685 = _693;\n        }\n        _669 = _685;\n    }\n    return _669;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _726 = fa_shadow_depth(param, param_1);\n    float _730;\n    if (conv.x < 0.5f)\n    {\n        _730 = _726;\n    }\n    else\n    {\n        _730 = (conv.y * conv.z) / (conv.z - (_726 * (conv.z - conv.y)));\n    }\n    return _730;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _657 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_657), sin(_657)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _776 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _790 = clamp((k * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _776;\n            float2 _809 = fa_shadow_vogel(param_3, param_4, param_5) * _790;\n            float2 param_6 = uv + (_809 * _679_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _821 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_821 < (zr - (length(_809) * plane)))\n            {\n                sum += _821;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0f) * unit) * k) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _865 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _865; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _865;\n        float param_11 = _776;\n        float2 _884 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_884 * _679_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_884) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_865);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _926 = max(_679_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _931 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _937 = sqrt(1.0f - (_931 * _931));\n    float _945 = min(_937 / max(_931, 0.20000000298023223876953125f), 4.0f);\n    float _950;\n    if (_679_fa_shadow_bias.y > 0.0f)\n    {\n        _950 = _679_fa_shadow_bias.y;\n    }\n    else\n    {\n        _950 = 1.5f * _679_fa_shadow_info[ci].x;\n    }\n    float4 _975 = mul(float4(world + (n * (_950 * _937)), 1.0f), _679_fa_shadow_mat[ci]);\n    float _982 = _975.x;\n    bool _985 = _982 < _679_fa_shadow_rect[ci].x;\n    bool _994;\n    if (!_985)\n    {\n        _994 = _982 > _679_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _994 = _985;\n    }\n    bool _1003;\n    if (!_994)\n    {\n        _1003 = _975.y < _679_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1003 = _994;\n    }\n    bool _1012;\n    if (!_1003)\n    {\n        _1012 = _975.y > _679_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1012 = _1003;\n    }\n    bool _1019;\n    if (!_1012)\n    {\n        _1019 = _975.z > 1.0f;\n    }\n    else\n    {\n        _1019 = _1012;\n    }\n    if (_1019)\n    {\n        return -1.0f;\n    }\n    float _1028;\n    if (_679_fa_shadow_bias.x > 0.0f)\n    {\n        _1028 = _679_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1028 = 1.5f * _679_fa_shadow_info[ci].x;\n    }\n    float2 param = _975.xy;\n    float4 param_1 = _679_fa_shadow_rect[ci];\n    float param_2 = _975.z - ((_1028 * (1.0f + (0.5f * _945))) / _926);\n    float param_3 = _679_fa_shadow_info[ci].x;\n    float param_4 = _926;\n    float param_5 = _926 * 0.25f;\n    float param_6 = ((_679_fa_shadow_info[ci].x * min(_945, 3.0f)) * 0.5f) / _926;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_679_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _679_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_443_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1422 = int(_679_fa_shadow_cfg.x + 0.5f);\n    if (_1422 < 1)\n    {\n        return 1.0f;\n    }\n    float _1438 = dot(world - _679_fa_shadow_eye.xyz, _679_fa_shadow_fwd.xyz);\n    int param = _1422 - 1;\n    if (_1438 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1450 = _1422 > 1;\n    bool _1457;\n    if (_1450)\n    {\n        _1457 = _1438 > _679_fa_shadow_split.x;\n    }\n    else\n    {\n        _1457 = _1450;\n    }\n    if (_1457)\n    {\n        ci = 1;\n    }\n    bool _1461 = _1422 > 2;\n    bool _1468;\n    if (_1461)\n    {\n        _1468 = _1438 > _679_fa_shadow_split.y;\n    }\n    else\n    {\n        _1468 = _1461;\n    }\n    if (_1468)\n    {\n        ci = 2;\n    }\n    bool _1472 = _1422 > 3;\n    bool _1479;\n    if (_1472)\n    {\n        _1479 = _1438 > _679_fa_shadow_split.z;\n    }\n    else\n    {\n        _1479 = _1472;\n    }\n    if (_1479)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1422)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1505 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1505;\n        if (_1505 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_679_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1530;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1530 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1530 = _679_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1549 = _679_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1530, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1560 = clamp((_1438 - (fa_shadow_split_at(param_7) - _1549)) / _1549, 0.0f, 1.0f);\n        if (_1560 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1422)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1581 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1581;\n                if (_1581 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1560);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _1087 = _443_fa_pbr.z < 0.5f;\n    bool _1095;\n    if (!_1087)\n    {\n        _1095 = _679_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _1095 = _1087;\n    }\n    if (_1095)\n    {\n        return 1.0f;\n    }\n    int param = (int(_679_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _1108 = fa_light_texel(param);\n    float _1109 = _1108.x;\n    if (_1109 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _1118 = int(_1109 + 0.5f);\n    int param_1 = _1118;\n    float4 _1122 = fa_light_texel(param_1);\n    int param_2 = _1118 + 1;\n    float4 _1127 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _1130 = _1122.y;\n    if (_1130 > 0.0f)\n    {\n        float _1147 = 1.0f - smoothstep(0.75f * _1130, _1130, length(world - _679_fa_shadow_eye.xyz));\n        fade = _1147;\n        if (_1147 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_1122.x > 1.5f)\n    {\n        int param_3 = li * 4;\n        float3 _1166 = world - fa_light_texel(param_3).xyz;\n        float3 _1169 = abs(_1166);\n        float _1171 = _1169.x;\n        float _1173 = _1169.y;\n        bool _1174 = _1171 >= _1173;\n        bool _1182;\n        if (_1174)\n        {\n            _1182 = _1171 >= _1169.z;\n        }\n        else\n        {\n            _1182 = _1174;\n        }\n        int _1183;\n        if (_1182)\n        {\n            _1183 = (_1166.x > 0.0f) ? 0 : 1;\n        }\n        else\n        {\n            int _1196;\n            if (_1173 >= _1169.z)\n            {\n                _1196 = (_1166.y > 0.0f) ? 2 : 3;\n            }\n            else\n            {\n                _1196 = (_1166.z > 0.0f) ? 4 : 5;\n            }\n            _1183 = _1196;\n        }\n        face = _1183;\n    }\n    int _1215 = (_1118 + 2) + (face * 6);\n    int param_4 = _1215;\n    int param_5 = _1215 + 1;\n    int param_6 = _1215 + 3;\n    float4 _1229 = fa_light_texel(param_6);\n    int param_7 = _1215 + 4;\n    float4 _1234 = fa_light_texel(param_7);\n    int param_8 = _1215 + 5;\n    float4 _1239 = fa_light_texel(param_8);\n    float _1251 = _1239.x * max(dot(_1229, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _1256 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1262 = sqrt(1.0f - (_1256 * _1256));\n    float _1268 = min(_1262 / max(_1256, 0.20000000298023223876953125f), 4.0f);\n    float _1271 = _1127.y;\n    float _1273;\n    if (_1271 > 0.0f)\n    {\n        _1273 = _1271;\n    }\n    else\n    {\n        _1273 = 1.5f * _1251;\n    }\n    float4 _1293 = float4(world + (n * (_1273 * _1262)), 1.0f);\n    float _1297 = dot(_1229, _1293);\n    float _1300 = _1239.y;\n    if (_1297 < _1300)\n    {\n        return 1.0f;\n    }\n    float2 _1315 = float2(dot(fa_light_texel(param_4), _1293), dot(fa_light_texel(param_5), _1293)) / _1297.xx;\n    float _1317 = _1315.x;\n    bool _1320 = _1317 < _1234.x;\n    bool _1329;\n    if (!_1320)\n    {\n        _1329 = _1317 > _1234.z;\n    }\n    else\n    {\n        _1329 = _1320;\n    }\n    bool _1338;\n    if (!_1329)\n    {\n        _1338 = _1315.y < _1234.y;\n    }\n    else\n    {\n        _1338 = _1329;\n    }\n    bool _1347;\n    if (!_1338)\n    {\n        _1347 = _1315.y > _1234.w;\n    }\n    else\n    {\n        _1347 = _1338;\n    }\n    if (_1347)\n    {\n        return 1.0f;\n    }\n    float _1353 = _1127.x;\n    float _1355;\n    if (_1353 > 0.0f)\n    {\n        _1355 = _1353;\n    }\n    else\n    {\n        _1355 = 1.5f * _1251;\n    }\n    float2 param_9 = _1315;\n    float4 param_10 = _1234;\n    float param_11 = _1297 - (_1355 * (1.0f + (0.5f * _1268)));\n    float param_12 = _1251;\n    float param_13 = 1.0f;\n    float param_14 = _1239.z * 0.25f;\n    float param_15 = (_1251 * min(_1268, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _1300, _1239.z);\n    int param_17 = int(_1122.z + 0.5f);\n    float param_18 = _1122.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _2514 = fa_light_sample(param, param_1);\n    float3 _3624 = _2514.direction;\n    float3 _3619 = _2514.color;\n    float _3626 = _2514.attenuation;\n    float _3621 = _2514.shadow;\n    int _3629 = _2514.type;\n    if ((_3629 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _3624;\n        float _2528 = fa_shadow_factor(param_2, param_3);\n        _3621 = _2528;\n        _3619 *= _2528;\n    }\n    else\n    {\n        bool _2539 = _3629 != 0;\n        bool _2545;\n        if (_2539)\n        {\n            _2545 = _3626 > 0.0f;\n        }\n        else\n        {\n            _2545 = _2539;\n        }\n        if (_2545)\n        {\n            int param_4 = li;\n            float3 param_5 = world_pos;\n            float3 param_6 = gn;\n            float3 param_7 = _3624;\n            float _2557 = fa_shadow_local(param_4, param_5, param_6, param_7);\n            _3621 = _2557;\n            _3619 *= _2557;\n        }\n    }\n    LightSample _3636 = { _3624, _3619, _3626, _3621, _2514._distance, _3629 };\n    return _3636;\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _2574 = n < 0;\n    bool _2581;\n    if (!_2574)\n    {\n        _2581 = n >= fa_light_count();\n    }\n    else\n    {\n        _2581 = _2574;\n    }\n    if (_2581)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    return fa_light_shadowed(param_1, param_2, param_3);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1863 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _1871 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _1874 = int(_1863);\n    int _1877 = int(_1871);\n    float _1887 = _1871 - float(_1877);\n    int _1943 = (_1874 * 9) + _1877;\n    int _1963 = ((_1874 + 1) * 9) + _1877;\n    return lerp(lerp(_1938[_1943], _1938[_1943 + 1], _1887), lerp(_1938[_1963], _1938[_1963 + 1], _1887), _1863 - float(_1874));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _3498 = false;\n    float _3499 = 1.0f;\n    float _3500 = 1.0f;\n    float _3501 = 1.0f;\n    float _3502 = 0.0f;\n    float _3503 = 0.0f;\n    float _3504 = 0.0f;\n    float _3505 = 0.0f;\n    float _3507 = 1.0f;\n    bool _3508 = false;\n    float3 _3509 = 0.0f.xxx;\n    float _3510 = 1.0f;\n    float _3511 = 1.0f;\n    float _3512 = 1.0f;\n    float _3513 = 0.0f;\n    float _3514 = 0.0f;\n    float3 _3515 = float3(1.0f, 0.0f, 0.0f);\n    float3 _3516 = float3(0.0f, 0.0f, 1.0f);\n    float _3517 = 1.0f;\n    float _3518 = 1.0f;\n    float _2016 = clamp(s.specular, 0.0f, 1.0f);\n    float _2020 = clamp(s.ior, 1.0f, 3.0f);\n    bool _2025 = (_2016 != 1.0f) || (_2020 != 1.5f);\n    bool _2035;\n    if (!_2025)\n    {\n        _2035 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _2035 = _2025;\n    }\n    if (_2035)\n    {\n        float _2043 = (_2020 - 1.0f) / (_2020 + 1.0f);\n        f0 = lerp(min((_2043 * _2043).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _2016, s.albedo, metallic.xxx);\n        _3499 = lerp(_2016, 1.0f, metallic);\n        _3498 = true;\n    }\n    float _2071 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_2071 > 0.0f)\n    {\n        float _2079 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _3502 = _2071;\n        _3503 = _2079;\n        float _2086 = _2079 * _2079;\n        _3504 = _2086;\n        _3505 = _2086 * _2086;\n        float _2098 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _3507 = _2098;\n        _3500 = 1.0f - (_2071 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _2098, 0.0f, 1.0f), 5.0f))));\n        _3498 = true;\n    }\n    float3 _2118 = max(s.sheen_color, 0.0f.xxx);\n    float _2127 = max(_2118.x, max(_2118.y, _2118.z));\n    if (_2127 > 0.0f)\n    {\n        float _2135 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _3508 = true;\n        _3509 = _2118;\n        _3510 = _2135;\n        _3511 = _2135 * _2135;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _2135;\n        float _2152 = fa_sheen_albedo(param, param_1);\n        _3513 = _2152;\n        _3512 = 1.0f - min(_2127 * _2152, 1.0f);\n        _3498 = true;\n    }\n    _3501 = _3500 * _3512;\n    float _2171 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_2171 != 0.0f)\n    {\n        float3 _2186 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2186;\n        if (dot(_2186, _2186) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _2200 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_2200.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _2200.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _2200.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _2204 = t;\n        float3 _2205 = normalize(_2204);\n        t = _2205;\n        float3 _2230 = normalize((_2205 * cos(s.anisotropy_rotation)) + ((cross(n, _2205) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _3515 = _2230;\n        _3516 = cross(n, _2230);\n        float _2240 = roughness * roughness;\n        float _2246 = lerp(_2240, 1.0f, _2171 * _2171);\n        bool _2248 = _2171 > 0.0f;\n        _3517 = _2248 ? _2246 : _2240;\n        _3518 = _2248 ? _2240 : _2246;\n        _3514 = _2171;\n        _3498 = true;\n    }\n    FaLayers _3540 = { _3498, _3499, _3500, _3501, _3502, _3503, _3504, _3505, i.world_normal, _3507, _3508, _3509, _3510, _3511, _3512, _3513, _3514, _3515, _3516, _3517, _3518 };\n    return _3540;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _1795 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _1798 = _1795.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_1798 * _1798, exp2((-9.27999973297119140625f) * ndv)) * _1798) + _1795.y)) + _1795.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_443_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _443_fa_env_horizon.w).xyz;\n    }\n    float _1718 = rough * rough;\n    float _1748 = 0.60000002384185791015625f * _1718;\n    return lerp(lerp(_443_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_443_fa_env_horizon.xyz, _443_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _1718)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _1748, 0.0500000007450580596923828125f + _1748, d.y).xxx), ((_443_fa_env_sky.xyz + _443_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_1718 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _2281;\n        if (L.aniso >= 0.0f)\n        {\n            _2281 = L.b;\n        }\n        else\n        {\n            _2281 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_2281, v), _2281), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _2314 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _2314.x) + (L.f90.xxx * _2314.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2369 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _2369.x) + _2369.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1837 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1837.x) + _1837.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _2408 = clamp(s.metallic, 0.0f, 1.0f);\n    float _2412 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _2419 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _2408.xxx);\n    float3 f0 = _2419;\n    float3 _2423 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _2423;\n    float3 param_3 = i.view_dir;\n    float param_4 = _2408;\n    float param_5 = _2412;\n    float3 param_6 = _2419;\n    FaLayers _2440 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_2440.on)\n    {\n        FaLayers param_7 = _2440;\n        float3 param_8 = _2423;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _2412;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _2423;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _2412;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0f;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _2647 = dot(fa_light_unshadowed(param, param_1).color, float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));\n        if (_2647 > bestPower)\n        {\n            bestPower = _2647;\n            best = n;\n        }\n    }\n    float3 lit = (_443_fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _2676 = fa_light(param_2, param_3);\n        float _2684;\n        if (dot(s.normal, _2676.direction) > 0.5f)\n        {\n            _2684 = 1.0f;\n        }\n        else\n        {\n            _2684 = _2690_dark;\n        }\n        lit += ((s.albedo * _2676.color) * _2684);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * _2690_skyAmount);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_679_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1605 = int(_679_fa_shadow_cfg.x + 0.5f);\n    float _1615 = dot(world - _679_fa_shadow_eye.xyz, _679_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1620 = _1605 > 0;\n    bool _1629;\n    if (_1620)\n    {\n        int param = _1605 - 1;\n        _1629 = _1615 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1629 = _1620;\n    }\n    if (_1629)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1636 = _1605 > 1;\n        bool _1643;\n        if (_1636)\n        {\n            _1643 = _1615 > _679_fa_shadow_split.x;\n        }\n        else\n        {\n            _1643 = _1636;\n        }\n        if (_1643)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1649 = _1605 > 2;\n        bool _1656;\n        if (_1649)\n        {\n            _1656 = _1615 > _679_fa_shadow_split.y;\n        }\n        else\n        {\n            _1656 = _1649;\n        }\n        if (_1656)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1662 = _1605 > 3;\n        bool _1669;\n        if (_1662)\n        {\n            _1669 = _1615 > _679_fa_shadow_split.z;\n        }\n        else\n        {\n            _1669 = _1662;\n        }\n        if (_1669)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _3372 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3372 = -_3372;\n    }\n    float3 _3076 = normalize(_443_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _3385 = { fa_world_pos, _3372, fa_world_tangent, fa_uv, fa_vertex_color, _3076, gl_FrontFacing };\n    SurfaceInput param_1 = _3385;\n    Surface _3084 = fa_standard_surface(param_1);\n    float3 _3403 = _3084.albedo;\n    float _3404 = _3084.alpha;\n    float3 _3405 = _3084.normal;\n    float _3406 = _3084.metallic;\n    float _3407 = _3084.roughness;\n    float _3408 = _3084.occlusion;\n    float3 _3409 = _3084.emission;\n    float _3410 = _3084.clearcoat;\n    float _3411 = _3084.clearcoat_roughness;\n    float3 _3412 = _3084.sheen_color;\n    float _3413 = _3084.sheen_roughness;\n    float _3414 = _3084.anisotropy;\n    float _3415 = _3084.anisotropy_rotation;\n    float _3416 = _3084.specular;\n    float _3417 = _3084.ior;\n    float3 _3418 = _3084.specular_color;\n    SurfaceInput _3393 = { fa_world_pos, _3372, fa_world_tangent, fa_uv, fa_vertex_color, _3076, gl_FrontFacing };\n    SurfaceInput param_2 = _3393;\n    Surface param_3 = _3084;\n    surface(param_2, param_3);\n    _3403 = param_3.albedo;\n    _3404 = param_3.alpha;\n    _3405 = param_3.normal;\n    _3406 = param_3.metallic;\n    _3407 = param_3.roughness;\n    _3408 = param_3.occlusion;\n    _3409 = param_3.emission;\n    _3410 = param_3.clearcoat;\n    _3411 = param_3.clearcoat_roughness;\n    _3412 = param_3.sheen_color;\n    _3413 = param_3.sheen_roughness;\n    _3414 = param_3.anisotropy;\n    _3415 = param_3.anisotropy_rotation;\n    _3416 = param_3.specular;\n    _3417 = param_3.ior;\n    _3418 = param_3.specular_color;\n    float3 result;\n    if (_443_fa_emissive.w > 0.5f)\n    {\n        result = _3403;\n    }\n    else\n    {\n        float3 _3105 = _3405;\n        float3 _3106 = normalize(_3105);\n        _3405 = _3106;\n        SurfaceInput _3401 = { fa_world_pos, _3372, fa_world_tangent, fa_uv, fa_vertex_color, _3076, gl_FrontFacing };\n        SurfaceInput param_4 = _3401;\n        Surface _3484 = { _3403, _3404, _3106, _3406, _3407, _3408, _3409, _3410, _3411, _3412, _3413, _3414, _3415, _3416, _3417, _3418 };\n        Surface param_5 = _3484;\n        result = lighting(param_4, param_5);\n    }\n    float3 _3121 = result;\n    float3 _3122 = _3121 + _3409;\n    result = _3122;\n    float3 param_6 = _3122;\n    float3 param_7 = fa_world_pos;\n    result = fa_shadow_debug(param_6, param_7);\n    bool _3131 = _443_fa_fog.w > 0.0f;\n    bool _3138;\n    if (!_3131)\n    {\n        _3138 = _443_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _3138 = _3131;\n    }\n    if (_3138)\n    {\n        float3 _3147 = fa_world_pos - _443_fa_camera_pos.xyz;\n        float _3153 = dot(_3147, _443_fa_fog_c.xyz);\n        bool _3157 = _443_fa_fog_c.w > 0.5f;\n        float _3158;\n        if (_3157)\n        {\n            _3158 = _3153;\n        }\n        else\n        {\n            _3158 = length(_3147);\n        }\n        float _3170 = _3158 - _443_fa_fog_b.x;\n        if (_3170 > 0.0f)\n        {\n            float _3179 = _443_fa_fog.w * _3170;\n            float tau = _3179 * _3179;\n            if (_443_fa_fog_b.y > 0.0f)\n            {\n                float _3195;\n                if (_3157)\n                {\n                    _3195 = fa_world_pos.y - (_443_fa_fog_c.y * _3153);\n                }\n                else\n                {\n                    _3195 = _443_fa_camera_pos.y;\n                }\n                float _3216 = lerp(_3195, fa_world_pos.y, clamp(_443_fa_fog_b.x / _3158, 0.0f, 1.0f));\n                float _3220 = fa_world_pos.y - _3216;\n                float _3225 = _3216 - _443_fa_fog_b.z;\n                float _3230 = fa_world_pos.y - _443_fa_fog_b.z;\n                bool _3233 = _3225 <= 0.0f;\n                bool _3234 = !_3233;\n                bool _3240;\n                if (_3234)\n                {\n                    _3240 = _443_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3240 = _3233;\n                }\n                float _3241;\n                if (_3240)\n                {\n                    _3241 = _443_fa_fog_b.y;\n                }\n                else\n                {\n                    _3241 = _443_fa_fog_b.y * exp(-min(_443_fa_fog_b.w * _3225, 80.0f));\n                }\n                bool _3268;\n                if (_3234)\n                {\n                    _3268 = _443_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3268 = _3233;\n                }\n                float _3269;\n                if (_3268)\n                {\n                    _3269 = _443_fa_fog_b.y * _3225;\n                }\n                else\n                {\n                    _3269 = (_443_fa_fog_b.y * (1.0f - exp(-min(_443_fa_fog_b.w * _3225, 80.0f)))) / _443_fa_fog_b.w;\n                }\n                bool _3294 = _3230 <= 0.0f;\n                bool _3301;\n                if (!_3294)\n                {\n                    _3301 = _443_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3301 = _3294;\n                }\n                float _3302;\n                if (_3301)\n                {\n                    _3302 = _443_fa_fog_b.y * _3230;\n                }\n                else\n                {\n                    _3302 = (_443_fa_fog_b.y * (1.0f - exp(-min(_443_fa_fog_b.w * _3230, 80.0f)))) / _443_fa_fog_b.w;\n                }\n                float _3329;\n                if (abs(_3220) < 0.001000000047497451305389404296875f)\n                {\n                    _3329 = _3241;\n                }\n                else\n                {\n                    _3329 = (_3302 - _3269) / _3220;\n                }\n                tau += (_3170 * max(_3329, 0.0f));\n            }\n            result = lerp(result, _443_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _3404);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_443",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_679",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_2690",
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 7,
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _786 = base_t;\n    _786.x = _225.x;\n    _786.y = _225.y;\n    _786.z = _225.z;\n    base_t = _786;\n    float4 _241 = (_786 * _213_fa_base_color) * i.vertex_color;\n    float3 _749 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _794 = _279;\n        _794.x = _284.x;\n        _794.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _794;\n        _749 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _797 = mrt;\n    _797.x = _313.x;\n    _797.y = _313.y;\n    _797.z = _313.z;\n    mrt = _797;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _754 = _213_fa_layers_a.x;\n    float _755 = _213_fa_layers_a.y;\n    float _758 = _213_fa_layers_a.z;\n    float _757 = _213_fa_layers_b.w;\n    float _760 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _754 *= _355.y;\n            _755 *= _355.z;\n            _757 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _758 *= mrt.x;\n            _760 *= mrt.w;\n        }\n    }\n    Surface _779 = { _241.xyz, _241.w, _749, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _754, _755, _213_fa_layers_b.xyz, _757, _758, _213_fa_layers_a.w, _760, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _779;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _660 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _660 = -_660;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _673 = { fa_world_pos, _660, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _673;\n    SurfaceInput _681 = { fa_world_pos, _660, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _681;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _416 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _416;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _423 = _273.world_pos;\n    float4 _284 = float4(_423, 1.0f);\n    fa_world_pos = _423;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -mul(_284, _136_fa_light_vp).z;\n    fa_pre_r0 = float3(_136_fa_light_vp[0].x, _136_fa_light_vp[1].x, _136_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136_fa_light_vp[0].y, _136_fa_light_vp[1].y, _136_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136_fa_light_vp[0].z, _136_fa_light_vp[1].z, _136_fa_light_vp[2].z);\n    gl_Position = mul(_284, _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _786 = base_t;\n    _786.x = _225.x;\n    _786.y = _225.y;\n    _786.z = _225.z;\n    base_t = _786;\n    float4 _241 = (_786 * _213_fa_base_color) * i.vertex_color;\n    float3 _749 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _794 = _279;\n        _794.x = _284.x;\n        _794.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _794;\n        _749 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _797 = mrt;\n    _797.x = _313.x;\n    _797.y = _313.y;\n    _797.z = _313.z;\n    mrt = _797;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _754 = _213_fa_layers_a.x;\n    float _755 = _213_fa_layers_a.y;\n    float _758 = _213_fa_layers_a.z;\n    float _757 = _213_fa_layers_b.w;\n    float _760 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _754 *= _355.y;\n            _755 *= _355.z;\n            _757 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _758 *= mrt.x;\n            _760 *= mrt.w;\n        }\n    }\n    Surface _779 = { _241.xyz, _241.w, _749, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _754, _755, _213_fa_layers_b.xyz, _757, _758, _213_fa_layers_a.w, _760, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _779;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _660 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _660 = -_660;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _673 = { fa_world_pos, _660, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _673;\n    SurfaceInput _681 = { fa_world_pos, _660, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _681;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
